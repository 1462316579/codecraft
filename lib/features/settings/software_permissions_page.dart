import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/container/external_storage.dart';
import '../../data/container/runtime_permissions.dart';
import '../../data/container/software_permissions.dart';
import '../../data/installed_apps.dart';
import '../../l10n/app_localizations.dart';

/// 「软件权限」页:逐项列出系统权限,点击时由**系统自己**弹授权框。
///
/// 存储与通知有原生运行时弹窗,交给 [RuntimePermissions];
/// 全文件访问、电池优化、自启动、Shizuku 系统不提供应用内弹窗,只能跳对应系统页面。
class SoftwarePermissionsPage extends ConsumerStatefulWidget {
  const SoftwarePermissionsPage({super.key});

  @override
  ConsumerState<SoftwarePermissionsPage> createState() => _SoftwarePermissionsPageState();
}

class _SoftwarePermissionsPageState extends ConsumerState<SoftwarePermissionsPage>
    with WidgetsBindingObserver {
  bool _storage = false;
  bool _appList = false;
  SoftwarePermissionStatus _status = const SoftwarePermissionStatus();

  /// 首次进入时用 FutureBuilder 等待拉取完成,避免先渲染未授权再闪烁成已授权。
  late final Future<void> _initialLoad = _refresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 从系统设置页返回时状态会变(全文件访问、电池优化都只能这样拿到结果)。
  /// 应用列表枚举较重,resume 只刷新轻量状态,避免返回时卡顿;force 时重新查询权限。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(includeAppList: false, force: true);
  }

  Future<void> _refresh({bool includeAppList = true, bool force = false}) async {
    final futures = <Future<Object?>>[
      ExternalStorage.hasAccess(),
      SoftwarePermissions.status(),
      if (includeAppList) InstalledAppsService.warmUp(force: force),
    ];
    final results = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _storage = results[0] as bool;
      _status = results[1] as SoftwarePermissionStatus;
      if (includeAppList) _appList = (results[2] as int) > 0;
    });
  }

  Future<void> _requestStorage() async {
    if (await RuntimePermissions.hasPending()) {
      await RuntimePermissions.requestStartup();
    }
    // 全文件访问没有应用内弹窗,只能去系统页面开。
    if (!await ExternalStorage.hasAccess()) {
      await ExternalStorage.requestAllFilesAccess();
    }
    await _refresh(includeAppList: false);
  }

  Future<void> _requestBattery() async {
    await SoftwarePermissions.requestIgnoreBattery();
    await _refresh(includeAppList: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.light
                    ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                    : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
              ),
            ),
            child: ListView(
            padding: const EdgeInsets.only(top: 80, bottom: 140),
        children: [
          SettingsPageHeader(
            title: l10n.softwarePermissionsTitle,
            subtitle: l10n.softwarePermissionsSubtitle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsGroupHeader(text: l10n.systemPermissionsGroup),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: LucideIcons.folderOpen,
                      title: l10n.permissionStorageTitle,
                      subtitle: '读写工作区文件',
                      trailing: _statusText(_storage ? l10n.permissionAllowed : l10n.permissionNotAllowed),
                      onTap: _requestStorage,
                    ),
                    SettingsDivider(indent: SettingsRow.textIndent),
                    SettingsRow(
                      icon: LucideIcons.appWindow,
                      title: l10n.permissionAppsTitle,
                      subtitle: l10n.permissionAppsDesc,
                      trailing: _statusText(_appList ? l10n.permissionAllowed : l10n.permissionNotAllowed),
                      onTap: _refresh,
                    ),
                    SettingsDivider(indent: SettingsRow.textIndent),
                    SettingsRow(
                      icon: LucideIcons.zap,
                      title: l10n.permissionBatteryTitle,
                      subtitle: l10n.permissionBatteryDesc,
                      trailing: _statusText(_status.battery ? l10n.permissionAllowed : l10n.permissionNotAllowed),
                      onTap: _requestBattery,
                    ),
                    SettingsDivider(indent: SettingsRow.textIndent),
                    SettingsRow(
                      icon: LucideIcons.power,
                      title: l10n.permissionAutoStartTitle,
                      subtitle: l10n.permissionAutoStartDesc,
                      onTap: SoftwarePermissions.openAutoStart,
                    ),
                    SettingsDivider(indent: SettingsRow.textIndent),
                    SettingsRow(
                      icon: LucideIcons.terminal,
                      title: l10n.permissionShizukuTitle,
                      subtitle: l10n.permissionShizukuDesc,
                      trailing: _statusText(
                        _status.shizuku ? l10n.permissionInstalled : l10n.permissionNotInstalled,
                      ),
                      onTap: SoftwarePermissions.openShizuku,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
          );
        },
      ),
    );
  }

  Widget _statusText(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: context.semantic.subtleText,
        ),
      );
}