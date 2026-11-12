import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:codecraft/data/mcp/mcp_auth_models.dart';
import 'package:codecraft/data/mcp/mcp_config.dart';
import 'package:codecraft/data/mcp/mcp_oauth.dart';
import 'package:codecraft/data/mcp/mcp_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 假 dio 适配器:按 URL 片段匹配响应(Auth/Token 交换各走不同端点)。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handlers);

  /// key 为路径片段,value 为响应体(Map → JSON,String → 原文)。
  final Map<String, Object> handlers;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    for (final entry in handlers.entries) {
      if (options.uri.toString().contains(entry.key)) {
        final body = entry.value;
        return Future.value(ResponseBody.fromString(
          body is String ? body : jsonEncode(body),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ));
      }
    }
    return Future.value(ResponseBody.fromString('{}', 404, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    }));
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(Map<String, Object> handlers) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = _FakeAdapter(handlers);
  return dio;
}

void main() {
  group('WWW-Authenticate 解析', () {
    test('带引号的值(含空格与逗号)与未带引号的值都能取', () {
      final parsed = WwwAuthenticateParser.parse(
        'Bearer resource_metadata="https://m.example/.well-known/oauth-protected-resource/mcp", '
        'scope="read write", error=insufficient_scope',
      );
      expect(parsed.resourceMetadataUrl,
          'https://m.example/.well-known/oauth-protected-resource/mcp');
      expect(parsed.scope, 'read write');
      expect(parsed.error, 'insufficient_scope');
    });

    test('转义引号与转义反斜杠按原值解析;非 Bearer 方案返回空', () {
      final parsed = WwwAuthenticateParser.parse('Bearer error="a\\"b", error_description="x\\\\y"');
      expect(parsed.error, 'a"b');
      expect(parsed.errorDescription, r'x\y');
      expect(WwwAuthenticateParser.parse('Basic realm="x"').resourceMetadataUrl, isNull);
      expect(WwwAuthenticateParser.parse(null).error, isNull);
    });
  });

  group('PKCE 与 well-known 地址', () {
    test('code_verifier 43 个 unreserved 字符;challenge = base64url(sha256(verifier))', () {
      final verifier = McpPkce.generateCodeVerifier();
      expect(verifier.length, 43);
      expect(verifier, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      // RFC 7636 附录 B 的示例向量
      expect(
        McpPkce.codeChallengeS256('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
      expect(McpPkce.generateState().length, 43);
    });

    test('well-known:RFC 8414 插在 host 后;OIDC 两种写法都给出;issuer 比对大小写不敏感', () {
      expect(
        McpOAuthDiscovery.wellKnownUrls('https://auth.example.com/tenant'),
        [
          'https://auth.example.com/.well-known/oauth-authorization-server/tenant',
          'https://auth.example.com/.well-known/openid-configuration/tenant',
          'https://auth.example.com/tenant/.well-known/openid-configuration',
        ],
      );
      expect(
        McpOAuthDiscovery.wellKnownResourceMetadataUrls('https://mcp.example.com/mcp'),
        ['https://mcp.example.com/.well-known/oauth-protected-resource/mcp'],
      );
      expect(McpOAuthDiscovery.issuerMatches('https://Auth.Example.com', 'https://auth.example.com'),
          isTrue);
      expect(McpOAuthDiscovery.issuerMatches('https://a.example', 'https://b.example'), isFalse);
    });
  });

  group('令牌存储', () {
    test('客户端/令牌/映射往返,文件不是明文;clear 连带清映射', () async {
      final dir = Directory.systemTemp.createTempSync('mcp_oauth_store');
      addTearDown(() => dir.delete(recursive: true));
      final store = McpTokenStore(File(p.join(dir.path, 'mcp-oauth.json')));

      await store.putClient(const OAuthClientRegistration(
        issuer: 'https://auth.example',
        clientId: 'client-1',
        redirectUri: 'http://127.0.0.1:8765/callback',
      ));
      await store.putTokens(
        'https://auth.example',
        const OAuthTokens(accessToken: 'tok-1', refreshToken: 'ref-1', expiresAtEpochSeconds: 123),
      );
      await store.putServerIssuer('demo', 'https://auth.example');

      final client = await store.getClient('https://auth.example');
      expect(client!.clientId, 'client-1');
      expect((await store.getTokens('https://auth.example'))!.accessToken, 'tok-1');
      expect(await store.getIssuerForServer('demo'), 'https://auth.example');

      final raw = File(p.join(dir.path, 'mcp-oauth.json')).readAsStringSync();
      expect(raw.contains('tok-1'), isFalse, reason: '令牌不落明文');

      await store.clear('https://auth.example');
      expect(await store.getClient('https://auth.example'), isNull);
      expect(await store.getTokens('https://auth.example'), isNull);
      expect(await store.getIssuerForServer('demo'), isNull);
    });
  });

  group('回调服务器', () {
    test('接收一次回调:解析 query 并回 200 页面;路径不匹配时 query 为空', () async {
      final server = await McpLoopbackServer(0, path: '/callback').bind();
      final port = server.boundPort;
      final future = server.awaitCallback(const Duration(seconds: 5));
      final http = HttpClient();
      final request = await http
          .getUrl(Uri.parse('http://127.0.0.1:$port/callback?code=abc&state=xyz&iss=https://a.b'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      http.close();

      expect(response.statusCode, 200);
      expect(body, contains('授权完成'));
      final callback = await future;
      expect(callback.code, 'abc');
      expect(callback.state, 'xyz');
      expect(callback.iss, 'https://a.b');
    });
  });

  group('发现与注册', () {
    test('发现:从 401 指向的 PRM 取授权服务器,再取 ASM(issuer 不符时跳下一个候选)', () async {
      final dio = _dioWith({
        '/oauth-protected-resource': {
          'resource': 'https://mcp.example/mcp',
          'authorization_servers': ['https://auth.example'],
        },
        '/.well-known/oauth-authorization-server': {
          'issuer': 'https://auth.example',
          'authorization_endpoint': 'https://auth.example/authorize',
          'token_endpoint': 'https://auth.example/token',
          'registration_endpoint': 'https://auth.example/register',
        },
      });
      final discovery = McpOAuthDiscovery(dio);
      final prm = await discovery.fetchProtectedResourceMetadata(
          'https://mcp.example/.well-known/oauth-protected-resource/mcp');
      expect(prm.authorizationServers.single, 'https://auth.example');
      final asm = await discovery.fetchAuthorizationServerMetadata('https://auth.example');
      expect(asm.tokenEndpoint, 'https://auth.example/token');
      expect(asm.registrationEndpoint, 'https://auth.example/register');
    });

    test('注册:预注册 client_id 优先;无预注册且已缓存则用缓存;都没有时报错由 UI 填', () async {
      final dir = Directory.systemTemp.createTempSync('mcp_oauth_reg');
      addTearDown(() => dir.delete(recursive: true));
      final store = McpTokenStore(File(p.join(dir.path, 'oauth.json')));
      final dio = _dioWith({});
      final registrar = McpClientRegistrar(dio, store);

      final preRegistered = await registrar.resolveClient(
        issuer: 'https://auth.example',
        metadata: const AuthorizationServerMetadata(issuer: 'https://auth.example'),
        redirectUri: 'http://127.0.0.1:8765/callback',
        preRegisteredClientId: 'given-id',
      );
      expect(preRegistered!.clientId, 'given-id');

      final cached = await registrar.resolveClient(
        issuer: 'https://auth.example',
        metadata: const AuthorizationServerMetadata(issuer: 'https://auth.example'),
        redirectUri: 'http://127.0.0.1:1234/callback',
      );
      expect(cached!.clientId, 'given-id', reason: '已有注册直接复用');

      final none = await registrar.resolveClient(
        issuer: 'https://other.example',
        metadata: const AuthorizationServerMetadata(issuer: 'https://other.example'),
        redirectUri: 'http://127.0.0.1:8765/callback',
      );
      expect(none, isNull, reason: '既无预注册也不支持 DCR');
    });
  });

  group('授权全流程(本地回调)', () {
    test('PKCE 授权:发现 → 注册 → 浏览器 → 回调 → 换令牌 → 落库', () async {
      final dir = Directory.systemTemp.createTempSync('mcp_oauth_flow');
      addTearDown(() => dir.delete(recursive: true));
      final store = McpTokenStore(File(p.join(dir.path, 'oauth.json')));
      final dio = _dioWith({
        '/oauth-protected-resource': {
          'resource': 'https://mcp.example/mcp',
          'authorization_servers': ['https://auth.example'],
          'scopes_supported': ['read'],
        },
        '/.well-known/oauth-authorization-server': {
          'issuer': 'https://auth.example',
          'authorization_endpoint': 'https://auth.example/authorize',
          'token_endpoint': 'https://auth.example/token',
          'registration_endpoint': 'https://auth.example/register',
        },
        '/register': {'client_id': 'dyn-client'},
        '/token': {'access_token': 'access-1', 'refresh_token': 'refresh-1', 'expires_in': 3600},
        // 探测挑战:未带 token 的 initialize 返回 401 + resource_metadata
      });
      // 让 initialize 探测返回 401(带挑战头):包一层响应
      final challengeAdapter = _ChallengeAdapter(dio.httpClientAdapter as _FakeAdapter);
      dio.httpClientAdapter = challengeAdapter;

      String? launchedUrl;
      late final McpOAuthManager manager;
      manager = McpOAuthManager(
        discovery: McpOAuthDiscovery(dio),
        registrar: McpClientRegistrar(dio, store),
        tokenStore: store,
        dio: dio,
        callbackPort: 0,
        browserLauncher: (url) async {
          launchedUrl = url;
          // 模拟用户在浏览器完成授权:回调到 loopback(state 从授权 URL 里取)
          final uri = Uri.parse(url);
          final state = uri.queryParameters['state']!;
          final redirect = Uri.parse(uri.queryParameters['redirect_uri']!);
          final client = HttpClient();
          final request = await client.getUrl(redirect.replace(
            queryParameters: {'code': 'auth-code', 'state': state},
          ));
          final response = await request.close();
          await response.drain<void>();
          client.close();
        },
      );

      final config = const McpServerConfig(
        name: 'demo',
        url: 'https://mcp.example/mcp',
        auth: McpAuthConfig(),
      );
      final tokens = await manager.authorize(config);

      expect(tokens.accessToken, 'access-1');
      expect(manager.cachedToken('demo'), 'access-1');
      expect(manager.isAuthorized('demo'), isTrue);
      expect(launchedUrl, contains('code_challenge_method=S256'));
      expect(launchedUrl, contains('client_id=dyn-client'));
      expect(launchedUrl, contains('resource=${Uri.encodeQueryComponent('https://mcp.example/mcp')}'));

      // 落库:重启后 prepare 能恢复
      expect((await store.getTokens('https://auth.example'))!.accessToken, 'access-1');
      expect(await store.getIssuerForServer('demo'), 'https://auth.example');

      final restored = McpOAuthManager(
        discovery: McpOAuthDiscovery(dio),
        registrar: McpClientRegistrar(dio, store),
        tokenStore: store,
        dio: dio,
      );
      await restored.prepare(config);
      expect(restored.cachedToken('demo'), 'access-1');

      await restored.logout(config);
      expect(restored.cachedToken('demo'), isNull);
      expect(await store.getTokens('https://auth.example'), isNull);
    });
  });

  group('配置保留 auth 字段', () {
    test('mcp.json 往返保留 auth(clientId / authServer / scopes)', () {
      final json = McpConfigRepository.serialize(const [
        McpServerConfig(
          name: 'demo',
          url: 'https://mcp.example/mcp',
          auth: McpAuthConfig(clientId: 'cid', authServer: 'https://auth.example', scopes: ['a']),
        ),
      ]);
      final parsed = McpConfigRepository.parse(json);
      expect(parsed.single.auth, isNotNull);
      expect(parsed.single.auth!.clientId, 'cid');
      expect(parsed.single.auth!.authServer, 'https://auth.example');
      expect(parsed.single.auth!.scopes, ['a']);
      expect(json, contains('"auth"'));
    });
  });
}

/// 让 initialize 探测返回 401 + WWW-Authenticate(其余请求转发给内层适配器)。
class _ChallengeAdapter implements HttpClientAdapter {
  _ChallengeAdapter(this._inner);

  final _FakeAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final body = '${options.data ?? ''}';
    if (body.contains('"initialize"')) {
      return Future.value(ResponseBody.fromString(
        '{"error":"unauthorized"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'www-authenticate': [
            'Bearer resource_metadata="https://mcp.example/.well-known/oauth-protected-resource/mcp"',
          ],
        },
      ));
    }
    return _inner.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}