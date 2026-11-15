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

  /// 每次 start/stop 递增:VPN 授权与启动是异步的,若用户中途点了停止,
  /// 旧的那次启动必须作废,否则停止后 VPN 才真正起来,表现为「已停止仍在抓包」。
  int _generation = 0;
  bool _disposed = false;

  @override
  void notifyListeners() {
    // 页面退出后代理仍有在途请求,继续通知会抛「used after being disposed」。
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<CaptureState> start({int port = 8888, int maxFlows = 500}) async {
    final generation = ++_generation;
    try {
      store.maxFlows = maxFlows;

      // 不阻塞在 CA 初始化上:首次要现场生成 2048 位 RSA(已在后台 isolate 里跑)。
      unawaited(ca.warmUp().then((_) {
        if (_disposed || generation != _generation) return;
        if (ca.ready) {
          _state = _state.copyWith(caReady: true);
          notifyListeners();
        }
      }));

      // 代理监听成功即视为已开始抓包:先把状态抛给 UI,VPN 授权/启动在后面继续。
      // 否则要等系统 VPN 授权弹框与 startForegroundService 全部完成才能把
      // running 置为 true,用户会觉得点了很久都没反应。
      final actualPort = await server.start(port: port);
      if (_disposed || generation != _generation) {
        // 启动过程中已被停止:把刚绑定的监听收回去。
        await server.stop();
        return _state;
      }
      _state = _state.copyWith(
        running: true,
        port: actualPort,
        caReady: ca.ready,
        flowCount: store.count,
        error: () => null,
      );
      notifyListeners();
      // VPN 启动放到后台:授权弹框与 startForegroundService 都可能耗时,
      // 不能卡在按钮的异步回调里,否则每次点开始都要等一两秒才恢复可点。
      unawaited(_startVpn(generation, actualPort));
    } catch (e) {
      _state = _state.copyWith(running: false, error: () => '$e');
      notifyListeners();
    }
    return _state;
  }

  Future<void> _startVpn(int generation, int port) async {
    if (!Platform.isAndroid) return;
    try {
      final perm = await CaptureChannel.requestVpnPermission();
      if (_disposed || generation != _generation) {
        // 等待授权期间用户已点停止:授权结果已经拿到,把 VPN 收掉即可。
        if (perm == 'granted') await CaptureChannel.stopVpn();
        return;
      }
      if (perm != 'granted') {
        await _fail('${perm == 'denied' ? 'VPN permission denied' : 'VPN permission required'}');
        return;
      }
      final vpnOk = await CaptureChannel.startVpn(port);
      if (_disposed || generation != _generation) {
        if (vpnOk) await CaptureChannel.stopVpn();
        return;
      }
      if (!vpnOk) {
        final reason = await CaptureChannel.vpnLastError();
        await _fail(reason == null || reason.isEmpty
            ? 'VPN 启动失败，请检查系统的 VPN 授权后重试'
            : 'VPN 启动失败：$reason');
        return;
      }
      if (_disposed || generation != _generation) return;
      // CA 若已就绪,补上证书路径供「安装 CA」按钮直接使用。
      _state = _state.copyWith(
        caReady: ca.ready,
        caPath: ca.ready ? (await ca.exportCaCertFile()).path : null,
      );
      notifyListeners();
    } catch (e) {
      await _fail('$e');
    }
  }

  /// VPN 起不来时把代理一并停掉,避免界面显示「运行中」却一条流量都抓不到。
  Future<void> _fail(String message) async {
    if (_disposed) return;
    ++_generation;
    await server.stop();
    _state = _state.copyWith(running: false, error: () => message);
    notifyListeners();
  }

  Future<CaptureState> stop() async {
    // 让在途的 start 立即作废(尤其是还停在授权弹框上的那次)。
    ++_generation;
    _state = _state.copyWith(running: false, flowCount: store.count);
    notifyListeners();

    // 顺序很重要:先拆 VPN 再关代理。反过来会让 VPN 在代理关闭后的窗口期
    // 继续把连接转进来,看起来像「停止后仍在抓包」。
    if (Platform.isAndroid) {
      try {
        await CaptureChannel.stopVpn();
      } catch (_) {}
    }
    try {
      await server.stop();
    } catch (_) {}

    _state = _state.copyWith(running: false, flowCount: store.count);
    notifyListeners();
    return _state;
  }

  CaptureState status() {
    // 注意：这里会被 build 直接调用，不能 notifyListeners（会触发
    // setState() called during build，界面表现就是列表一直不刷新）。
    _state = _state.copyWith(
      running: server.running,
      port: server.port,
      flowCount: store.count,
      caReady: ca.ready,
    );
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
    _disposed = true;
    ++_generation;
    // 只关代理不拆 VPN,会让 VPN 接口一直挂着:界面显示已停止,系统代理却还指向
    // 已经关闭的 127.0.0.1 端口,设备整体断网,重进页面也看不到任何流量。
    unawaited(() async {
      if (Platform.isAndroid) {
        try {
          await CaptureChannel.stopVpn();
        } catch (_) {}
      }
      try {
        await server.stop();
      } catch (_) {}
    }());
    super.dispose();
  }
}

final captureManagerProvider = ChangeNotifierProvider<CaptureManager>((ref) {
  final manager = CaptureManager();
  ref.onDispose(manager.dispose);
  return manager;
});
