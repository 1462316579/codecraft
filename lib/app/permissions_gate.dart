import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/capture/capture_manager.dart';
import '../data/container/external_storage.dart';
import '../data/container/runtime_permissions.dart';
import '../data/installed_apps.dart';
import '../data/settings/app_settings.dart';

/// 首次启动的权限引导。
///
/// 三个动作:
/// 1. 用系统原生的运行时权限弹窗([RuntimePermissions.requestStartup])申请;
/// 2. 触发一次已安装应用查询——部分 ROM 会为它弹自己的授权框,把它挪到启动时,
///    免得用户点「应用逆向」时才冒出来闪一下;
/// 3. 引导「所有文件访问权限」:写作项目要直接读写共享存储的 `AI小说` 目录,
///    缺这个权限时文件树只能列出目录、读不到文件(表现为「目录是空的」)。
///
/// 申请完就结束,不跳任何页面;其余特殊权限留给「软件权限」页由用户按需处理。
///
/// 只跑一次:标记持久化到偏好设置,且进程内另有一次性守卫——否则弹窗可能在用户
/// 已经开始操作时才冒出来(例如正要点「应用逆向」),打断手上的事。
class PermissionsGate extends ConsumerStatefulWidget {
  const PermissionsGate({super.key, required this.child});

  final Widget child;

  /// 已引导过的标记键。
  static const String onboardedKey = 'permissionsOnboarded';

  /// 旧版本用的单权限标记,升级时视为已引导(不重复打扰)。
  static const String legacyPromptedKey = 'storagePermission.prompted';

  /// 「所有文件访问权限」已引导过的标记键(该权限没有运行时弹窗,只能跳设置页)。
  static const String allFilesAccessPromptedKey = 'allFilesAccessPrompted';

  @override
  ConsumerState<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends ConsumerState<PermissionsGate> {
  /// 进程内守卫:即便本 State 被重建,也不再把授权框拖到用户操作中途弹出。
  static bool _askedThisRun = false;

  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // 抓包 CA 预热与应用启动并行:首次要生成 2048 位 RSA,提前在后台做完,
    // 用户点「启动抓包」时才不会卡在证书初始化上。
    unawaited(ref.read(captureManagerProvider).ca.warmUp());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    if (_checked || _askedThisRun) return;
    _checked = true;
    _askedThisRun = true;
    final prefs = ref.read(sharedPreferencesProvider);
    // 已安装应用查询:部分 ROM 会为此弹「获取应用列表」授权框,放在启动时触发,
    // 免得用户点「应用逆向」时才冒出来闪一下。
    await InstalledAppsService.warmUp();
    if (prefs.getBool(PermissionsGate.onboardedKey) ?? false) {
      // 已完成首次引导的用户仍可能缺「所有文件访问权限」(升级前的老版本没引导过),
      // 这里补一次,否则写作项目的文件树会一直读不到内容。
      await _ensureAllFilesAccess(prefs);
      return;
    }
    // 老版本只引导过存储权限:视为已完成引导,不让升级用户再被拦一次。
    if (prefs.getBool(PermissionsGate.legacyPromptedKey) ?? false) {
      await prefs.setBool(PermissionsGate.onboardedKey, true);
      await _ensureAllFilesAccess(prefs);
      return;
    }

    // 系统原生授权框:13+ 是媒体权限 + 通知,12 及以下是存储读写。
    if (await RuntimePermissions.hasPending()) {
      await RuntimePermissions.requestStartup();
      // ROM 的应用列表授权框随查询结束消失,等系统弹窗收干净再查,
      // 否则两个系统框会互相顶掉。
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await prefs.setBool(PermissionsGate.onboardedKey, true);
    await _ensureAllFilesAccess(prefs);
  }

  /// 引导「所有文件访问权限」。
  ///
  /// 写作项目直接读写共享存储的 `AI小说` 目录;Android 11+ 没有该权限时目录能列出、
  /// 文件却读不到,表现就是「目录是空的」。
  ///
  /// 该权限没有运行时弹窗,只能跳系统设置页由用户打开开关,所以安装后引导一次;
  /// 用户若取消,文件面板顶部还有常驻的「去授权」入口。
  Future<void> _ensureAllFilesAccess(SharedPreferences prefs) async {
    if (!Platform.isAndroid) return;
    if (prefs.getBool(PermissionsGate.allFilesAccessPromptedKey) ?? false) return;
    if (await ExternalStorage.hasAccess()) return;
    await prefs.setBool(PermissionsGate.allFilesAccessPromptedKey, true);
    if (!mounted) return;
    await ExternalStorage.requestAllFilesAccess();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
/// 测试用:重置进程内的一次性守卫。
void resetPermissionsGateGuardForTest() => _PermissionsGateState._askedThisRun = false;
