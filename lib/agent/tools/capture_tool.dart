import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/capture/capture_manager.dart';
import '../../data/workspaces.dart';
import 'tool.dart';

/// 抓包工具：供 AI 分析/爬虫使用（仅 reverse/coding 项目注册）。
class CaptureTool extends AgentTool {
  CaptureTool(this._ref);

  final Ref _ref;

  static const List<String> actions = [
    'status',
    'start',
    'stop',
    'list',
    'get',
    'search',
    'clear',
    'export',
    'ca_info',
  ];

  @override
  String get name => 'capture';

  @override
  String get description =>
      '本地 HTTP(S) 代理抓包（用于应用逆向/接口分析/授权调试）。'
      '先 start 获取代理端口并安装/信任 CA，再将目标流量代理到 127.0.0.1:<port>；'
      '用 list/get/search 查看流量，export 导出 HAR/JSON。'
      '注意：Android 7+ 多数应用不信任用户 CA、证书锁定应用无法 MITM；仅抓取经代理且可解密的流量。';

  @override
  Map<String, ToolParameter> get parameters => const {
        'action': ToolParameter(
          name: 'action',
          type: ParameterType.string,
          description: 'status/start/stop/list/get/search/clear/export/ca_info',
          enumValues: actions,
        ),
        'port': ToolParameter(
          name: 'port',
          type: ParameterType.integer,
          description: 'start: 代理端口，默认 8888，0 为随机',
          required: false,
        ),
        'maxFlows': ToolParameter(
          name: 'maxFlows',
          type: ParameterType.integer,
          description: 'start: 内存保留最大条数，默认 500',
          required: false,
        ),
        'id': ToolParameter(
          name: 'id',
          type: ParameterType.string,
          description: 'get: flow id',
          required: false,
        ),
        'query': ToolParameter(
          name: 'query',
          type: ParameterType.string,
          description: 'search: 关键词（URL/method/body/status）',
          required: false,
        ),
        'host': ToolParameter(
          name: 'host',
          type: ParameterType.string,
          description: 'search: host 过滤',
          required: false,
        ),
        'limit': ToolParameter(
          name: 'limit',
          type: ParameterType.integer,
          description: 'list/search: 返回条数，默认 50',
          required: false,
        ),
        'offset': ToolParameter(
          name: 'offset',
          type: ParameterType.integer,
          description: 'list: 偏移',
          required: false,
        ),
        'format': ToolParameter(
          name: 'format',
          type: ParameterType.string,
          description: 'export: har 或 json，默认 har',
          required: false,
          enumValues: ['har', 'json'],
        ),
        'includeBodies': ToolParameter(
          name: 'includeBodies',
          type: ParameterType.boolean,
          description: 'export: 是否包含 body，默认 true',
          required: false,
        ),
      };

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {
        ToolCapability.networkRead,
        ToolCapability.writeWorkspace,
      };

  @override
  PermissionRequestText permissionRequest(Map<String, dynamic> args, String argsPreview) {
    final action = args['action'];
    return PermissionRequestText(
      title: '抓包工具',
      summary: 'AI 请求执行 capture.$action',
      details: argsPreview,
    );
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final action = (args['action'] as String?)?.trim() ?? '';
    final manager = _ref.read(captureManagerProvider);
    switch (action) {
      case 'status':
        final s = manager.status();
        return ToolSuccess(_stateMap(s));
      case 'start':
        final port = (args['port'] as num?)?.toInt() ?? 8888;
        final maxFlows = (args['maxFlows'] as num?)?.toInt() ?? 500;
        final s = await manager.start(port: port, maxFlows: maxFlows);
        return ToolSuccess({
          ..._stateMap(s),
          'proxy': '127.0.0.1:${s.port}',
          'note': '请将设备/目标应用的 HTTP 代理设为 127.0.0.1:${s.port}，并安装信任 CA 后再抓 HTTPS。'
              'Android 7+ 普通应用默认不信任用户 CA；证书锁定应用需 root/Frida/Xposed 等方式。',
        });
      case 'stop':
        final s = await manager.stop();
        return ToolSuccess(_stateMap(s));
      case 'list':
        final limit = (args['limit'] as num?)?.toInt() ?? 50;
        final offset = (args['offset'] as num?)?.toInt() ?? 0;
        final flows = manager.list(limit: limit, offset: offset);
        return ToolSuccess({
          'count': manager.status().flowCount,
          'items': flows.map(_flowSummary).toList(),
        });
      case 'get':
        final id = args['id'] as String? ?? '';
        if (id.isEmpty) return const ToolError('get 需要 id 参数');
        final flow = manager.get(id);
        if (flow == null) return ToolError('未找到 flow: $id');
        return ToolSuccess(flow.toJson());
      case 'search':
        final q = args['query'] as String?;
        final host = args['host'] as String?;
        final limit = (args['limit'] as num?)?.toInt() ?? 50;
        final flows = manager.search(query: q, host: host, limit: limit);
        return ToolSuccess({'items': flows.map(_flowSummary).toList()});
      case 'clear':
        manager.clear();
        return ToolSuccess({'ok': true, ..._stateMap(manager.status())});
      case 'export':
        final format = (args['format'] as String?) ?? 'har';
        final includeBodies = args['includeBodies'] != false;
        final root = _ref.read(currentWorkspaceProvider).rootPath;
        final path = await manager.export(
          rootPath: root,
          format: format,
          includeBodies: includeBodies,
        );
        return ToolSuccess({'path': path, 'format': format});
      case 'ca_info':
        return ToolSuccess(await manager.caInfo());
      default:
        return ToolError('未知 action: $action');
    }
  }

  Map<String, Object?> _stateMap(s) => {
        'running': s.running,
        'port': s.port,
        'flowCount': s.flowCount,
        'caReady': s.caReady,
        'caPath': s.caPath,
        'error': s.error,
      };

  Map<String, Object?> _flowSummary(f) => {
        'id': f.id,
        'time': f.startedAt.toIso8601String(),
        'method': f.method,
        'url': f.url,
        'host': f.host,
        'statusCode': f.statusCode,
        'durationMs': f.durationMs,
        'tls': f.tls,
        'error': f.error,
        'bodyTruncated': f.bodyTruncated,
      };
}

final captureToolProvider = Provider<CaptureTool>((ref) => CaptureTool(ref));
