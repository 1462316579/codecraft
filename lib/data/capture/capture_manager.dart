import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'capture_models.dart';
import 'capture_store.dart';
import 'certificate_authority.dart';
import 'proxy_server.dart';
import 'capture_channel.dart';

class CaptureManager extends ChangeNotifier {
  CaptureManager() : ca = CaptureCertificateAuthority() {
    store = CaptureStore();
    server = CaptureProxyServer(ca: ca, store: store, onChanged: notifyListeners);
  }

  final CaptureCertificateAuthority ca;
  late final CaptureStore store;
  late final CaptureProxyServer server;
  CaptureState _state = const CaptureState();
  CaptureState get state => _state;

  Future<CaptureState> start({int port = 8888, int maxFlows = 500}) async {
    try {
      store.maxFlows = maxFlows;

      // 不阻塞在 CA 初始化上:首次要现场生成 2048 位 RSA(已在后台 isolate 里跑)。
      unawaited(ca.warmUp().then((_) {
        if (ca.ready) {
          _state = _state.copyWith(caReady: true);
          notifyListeners();
        }
      }));

      // 代理监听成功即视为已开始抓包:先把状态抛给 UI,VPN 授权/启动在后面继续。
      // 否则要等系统 VPN 授权弹框与 startForegroundService 全部完成才能把
      // running 置为 true,用户会觉得点了很久都没反应。
      final actualPort = await server.start(port: port);
      _state = _state.copyWith(
        running: true,
        port: actualPort,
        caReady: ca.ready,
        flowCount: store.count,
        error: () => null,
      );
      notifyListeners();

      // 启动 VPN 服务(Android)
      if (Platform.isAndroid) {
        final perm = await CaptureChannel.requestVpnPermission();
        if (perm != "granted") {
          await server.stop();
          _state = _state.copyWith(
            running: false,
            error: () => perm == "denied" ? 'VPN permission denied' : 'VPN permission required',
          );
          notifyListeners();
          return _state;
        }
        // 已授权，启动 VPN
        final vpnOk = await CaptureChannel.startVpn(actualPort);
        if (!vpnOk) {
          await server.stop();
          _state = _state.copyWith(
            running: false,
            error: () => 'Failed to start VPN service',
          );
          notifyListeners();
          return _state;
        }
      }

      // CA 若已就绪,补上证书路径供「安装 CA」按钮直接使用。
      _state = _state.copyWith(
        caReady: ca.ready,
        caPath: ca.ready ? (await ca.exportCaCertFile()).path : null,
      );
    } catch (e) {
      _state = _state.copyWith(running: false, error: () => '$e');
    }
    notifyListeners();
    return _state;
  }

  Future<CaptureState> stop() async {
    await server.stop();
    if (Platform.isAndroid) {
      await CaptureChannel.stopVpn();
    }
    _state = _state.copyWith(running: false, flowCount: store.count);
    notifyListeners();
    return _state;
  }

  CaptureState status() {
    _state = _state.copyWith(
      running: server.running,
      port: server.port,
      flowCount: store.count,
      caReady: ca.ready,
    );
    notifyListeners();
    return _state;
  }

  List<CaptureFlow> list({int limit = 100, int offset = 0}) {
    final all = store.flows;
    final end = (offset + limit).clamp(0, all.length);
    final start = offset.clamp(0, end);
    return all.sublist(start, end);
  }

  CaptureFlow? get(String id) => store.get(id);

  List<CaptureFlow> search({String? query, String? host, int? limit = 100}) =>
      store.search(query: query, host: host, limit: limit);

  void clear() {
    store.clear();
    _state = _state.copyWith(flowCount: 0);
    notifyListeners();
  }

  void removeHost(String host) {
    store.removeWhere((flow) => flow.host == host);
    _state = _state.copyWith(flowCount: store.count);
    notifyListeners();
  }

  /// 域名维度的汇总，按最近一次请求时间倒序。
  List<CaptureHostSummary> hosts({String? query}) {
    final q = query?.trim().toLowerCase() ?? '';
    final counts = store.hostCounts;
    final map = <String, CaptureHostSummary>{};
    for (final entry in counts.entries) {
      if (q.isNotEmpty && !entry.key.toLowerCase().contains(q)) continue;
      map[entry.key] = CaptureHostSummary(
        host: entry.key,
        count: entry.value,
        lastAt: DateTime.now(), // Note: we don't track lastAt per host incrementally
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return list;
  }

  Future<String> export({required String rootPath, String format = 'har', bool includeBodies = true}) async {
    final dir = Directory(p.join(rootPath, '.codecraft', 'captures'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'capture-$ts.${format == 'json' ? 'json' : 'har'}'));
    final content = format == 'json'
        ? () { final l = store.flows.toList(); l.sort((a,b)=>a.startedAt.compareTo(b.startedAt)); return CaptureFlow.encodeList(l, includeBodies: includeBodies); }()
        : store.exportHar(includeBodies: includeBodies);
    await file.writeAsString(content);
    return file.path;
  }

  Future<Map<String, Object?>> caInfo() async {
    await ca.ensureInitialized();
    return {
      'ready': ca.ready,
      'certPath': (await ca.exportCaCertFile()).path,
      'pem': ca.caCertPem,
    };
  }

  @override
  void dispose() {
    unawaited(server.stop());
    super.dispose();
  }
}

final captureManagerProvider = ChangeNotifierProvider<CaptureManager>((ref) {
  final manager = CaptureManager();
  ref.onDispose(manager.dispose);
  return manager;
});
