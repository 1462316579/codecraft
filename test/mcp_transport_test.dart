import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:codecraft/data/mcp/mcp_client.dart';
import 'package:codecraft/data/mcp/mcp_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假适配器:按请求返回预置响应,并记录收到的请求(校验会话头与请求体)。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object body, {int status = 200, Map<String, List<String>>? headers}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...?headers,
      },
    );

ResponseBody _sseBody(String payload) => ResponseBody.fromString(
      'event: message\ndata: $payload\n\n',
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );

McpHttpTransport _transport(
  Future<ResponseBody> Function(RequestOptions options) respond, {
  Duration timeout = const Duration(seconds: 5),
}) {
  final adapter = _FakeAdapter(respond);
  final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
  return McpHttpTransport(
    endpoint: 'https://mcp.test/mcp',
    headers: const {'X-Token': 'abc'},
    dio: dio,
    requestTimeout: timeout,
  );
}

void main() {
  group('MCP HTTP 传输', () {
    test('JSON 响应:解析 result,带上自定义请求头与 JSON-RPC 体', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody({
            'jsonrpc': '2.0',
            'id': 1,
            'result': {
              'tools': [
                {'name': 'echo'},
              ],
            },
          }));
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      final transport = McpHttpTransport(
        endpoint: 'https://mcp.test/mcp',
        headers: const {'X-Token': 'abc'},
        dio: dio,
      );

      final result = await transport.request('tools/list');
      expect((result!['tools'] as List).single, {'name': 'echo'});

      final body = jsonDecode(adapter.requests.single.data as String) as Map<String, dynamic>;
      expect(body['jsonrpc'], '2.0');
      expect(body['method'], 'tools/list');
      expect(body['id'], 1);
      expect(adapter.requests.single.headers['X-Token'], 'abc');
    });

    test('initialize 下发的 Mcp-Session-Id 会在后续请求带上', () async {
      final adapter = _FakeAdapter((options) async {
        if (options.headers['Mcp-Session-Id'] == null) {
          return _jsonBody(
            {'jsonrpc': '2.0', 'id': 1, 'result': {}},
            headers: {
              'mcp-session-id': ['sess-42'],
            },
          );
        }
        return _jsonBody({'jsonrpc': '2.0', 'id': 2, 'result': {'ok': true}});
      });
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      final transport = McpHttpTransport(
        endpoint: 'https://mcp.test/mcp',
        headers: const {'X-Token': 'abc'},
        dio: dio,
      );

      await transport.request('initialize', {'protocolVersion': 'x'});
      expect(adapter.requests.first.headers['X-Token'], 'abc');
      expect(adapter.requests.first.headers['Accept'], 'application/json, text/event-stream');

      await transport.request('tools/list');
      expect(adapter.requests.last.headers['Mcp-Session-Id'], 'sess-42');
      expect(adapter.requests.last.headers['X-Token'], 'abc');
    });

    test('SSE 响应:取第一个 data 事件作为 JSON-RPC 消息', () async {
      final transport = _transport(
        (options) async => _sseBody(
          jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {'value': 7}}),
        ),
      );
      final result = await transport.request('tools/call', {'name': 'x'});
      expect(result!['value'], 7);
    });

    test('401 抛鉴权异常;其它非 2xx 抛普通异常', () async {
      final unauthorized = _transport((options) async => _jsonBody({'error': 'nope'}, status: 401));
      await expectLater(
        unauthorized.request('tools/list'),
        throwsA(isA<McpAuthRequiredException>()),
      );

      final serverError = _transport((options) async => _jsonBody({}, status: 502));
      await expectLater(
        serverError.request('tools/list'),
        throwsA(isA<McpException>().having((e) => e.message, 'message', contains('502'))),
      );
    });

    test('JSON-RPC error 字段:抛异常并带上错误码', () async {
      final transport = _transport((options) async => _jsonBody({
            'jsonrpc': '2.0',
            'id': 1,
            'error': {'code': -32601, 'message': 'Method not found'},
          }));
      await expectLater(
        transport.request('tools/list'),
        throwsA(isA<McpException>()
            .having((e) => e.rpcCode, 'rpcCode', -32601)
            .having((e) => e.message, 'message', contains('Method not found'))),
      );
    });

    test('响应非法 JSON 时抛错(不落地半截数据)', () async {
      final transport = _transport((options) async => ResponseBody.fromString(
            '<html>bad gateway</html>',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ));
      await expectLater(transport.request('tools/list'), throwsA(isA<McpException>()));
    });

    test('网络卡住:到点抛超时,不会无限等待', () async {
      final transport = _transport(
        (options) => Completer<ResponseBody>().future,
        timeout: const Duration(milliseconds: 80),
      );
      await expectLater(
        transport.request('tools/list'),
        throwsA(isA<McpException>().having((e) => e.message, 'message', contains('超时'))),
      );
    });

    test('notify 通知失败不抛错', () async {
      final transport = _transport((options) async => _jsonBody({}, status: 500));
      await transport.notify('notifications/initialized');
    });
  });

  group('MCP 客户端', () {
    test('connect:initialize → initialized → tools/list,工具描述解析正确', () async {
      final methods = <String>[];
      final transport = _transport((options) async {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        methods.add('${body['method']}');
        switch (body['method']) {
          case 'initialize':
            return _jsonBody({'jsonrpc': '2.0', 'result': {'protocolVersion': '2025-06-18'}});
          case 'tools/list':
            return _jsonBody({
              'jsonrpc': '2.0',
              'result': {
                'tools': [
                  {
                    'name': 'search',
                    'description': '搜一搜',
                    'inputSchema': {
                      'type': 'object',
                      'properties': {
                        'q': {'type': 'string'},
                      },
                    },
                  },
                  {'description': '没有名字'},
                ],
              },
            });
          default:
            return _jsonBody({}, status: 202);
        }
      });

      final client = McpClient(serverName: 'demo', transport: transport);
      final count = await client.connect();

      expect(count, 1);
      expect(methods, ['initialize', 'notifications/initialized', 'tools/list']);
      expect(client.tools.single.name, 'search');
      expect(client.tools.single.description, '搜一搜');
      expect((client.tools.single.inputSchema!['properties'] as Map).keys, ['q']);
    });

    test('callTool:content 数组拍平成文本,isError 决定成败', () async {
      final transport = _transport((options) async {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        expect(body['method'], 'tools/call');
        expect((body['params'] as Map)['name'], 'search');
        expect(((body['params'] as Map)['arguments'] as Map)['q'], 'x');
        return _jsonBody({
          'jsonrpc': '2.0',
          'result': {
            'content': [
              {'type': 'text', 'text': '第一段'},
              {'type': 'image', 'data': 'xxx'},
              {'type': 'text', 'text': '第二段'},
            ],
            'isError': true,
          },
        });
      });

      final client = McpClient(serverName: 'demo', transport: transport);
      final result = await client.callTool('search', {'q': 'x'});
      expect(result.isError, isTrue);
      expect(result.text, contains('第一段'));
      expect(result.text, contains('[image content]'));
      expect(result.text, contains('第二段'));
    });
  });
}