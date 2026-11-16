import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../agent/models/project.dart';
import '../agent/sessions_controller.dart';
import '../data/db/app_database.dart';
import '../data/db/daos.dart';
import '../data/apk_workspace.dart';
import '../data/container/container_manager.dart';
import '../core/log/file_logger.dart';
import '../core/util/window_size.dart';
import '../features/home/home_bottom_nav.dart';
import '../features/home/projects_page.dart';
import '../features/settings/settings_page.dart';

import 'current_project.dart';

export 'current_project.dart';

/// 底部导航当前页签:项目 / 设置。
final homeTabProvider = StateProvider<HomeTab>((ref) => HomeTab.projects);

/// 宽屏布局(≥840dp):常驻侧栏 + 聊天并排;否则单栏 + 抽屉。判定函数在 core/util/window_size.dart。

/// 让后代(聊天顶栏)能够开/关所在 Scaffold 的抽屉。
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openDrawer,
    required this.closeDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

/// 切换选中会话(侧栏据此高亮)。
void selectSession(WidgetRef ref, String sessionId) {
  ref.read(selectedSessionProvider.notifier).state = sessionId;
}

/// 打开会话:切换选中项;窄屏下顺带收起抽屉。
void openSession(BuildContext context, WidgetRef ref, String sessionId) {
  selectSession(ref, sessionId);
  if (!isWideLayout(context)) {
    ShellScope.maybeOf(context)?.closeDrawer();
  }
}

/// 首页外壳(对齐上游:窄屏 = 聊天页 + 左抽屉;宽屏 = 常驻侧栏 + 聊天并排)。
/// 启动即保证选中一个当前会话:有会话时选最近一条,没有则自动新建;
/// 空会话由聊天页呈现欢迎文案,输入栏的模式/模型/思考强度按钮因此始终可用。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // 启动即触发容器管理：首次运行时自动解压安装内置 Ubuntu 26.04，
    // 用户打开终端/设置时无需再下载。
    ref.read(containerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(homeTabProvider);
    if (tab == HomeTab.settings) {
      return Scaffold(
        extendBody: true,
        body: const SettingsPage(),
        bottomNavigationBar: HomeBottomNav(
          current: tab,
          onSelect: (next) => ref.read(homeTabProvider.notifier).state = next,
        ),
      );
    }
    // 「项目」页签恒为项目列表
    // 启动一律停在项目列表——不自动跳进上次的聊天页。
    return Scaffold(
      extendBody: true,
      body: ProjectsPage(onOpenProject: _openProject),
      bottomNavigationBar: HomeBottomNav(
        current: tab,
        onSelect: (next) => ref.read(homeTabProvider.notifier).state = next,
      ),
    );
  }

  /// 打开项目:切到它的会话(优先已选的,否则最近一条,都没有就新开一条)。
  ///
  /// 新建的会话属于当前项目,不产生新项目。
  Future<void> _openProject(Project project) async {
    ref.read(selectedProjectProvider.notifier).state = project.id;
    // 工作区随项目类型派生(写作 → 外部「AI小说」目录,编程 → 容器内目录),
    // 不在这里切换;逆向项目的工作区是目标 APK 解出来的目录,首次进入时解包(幂等)。
    if (project.kind == ProjectKind.reverse) {
      unawaited(_extractApkQuietly(project));
    }
    final sessions = await ref.read(databaseProvider).sessionDao.listByProject(project.id);
    if (!mounted) return;
    if (sessions.isEmpty) {
      final created = await ref.read(sessionsProvider.notifier).create(
            mode: project.mode,
            projectId: project.id,
          );
      if (!mounted) return;
      selectSession(ref, created.id);
      context.push('/chat/${created.id}');
      return;
    }
    final selected = ref.read(selectedSessionProvider);
    final session = sessions.any((s) => s.id == selected) ? selected! : sessions.first.id;
    selectSession(ref, session);
    context.push('/chat/$session');
  }

  /// 逆向项目解包:失败不打断进入流程,由文件面板展示具体错误。
  Future<void> _extractApkQuietly(Project project) async {
    try {
      await ref.read(apkWorkspaceProvider).ensureExtracted(project);
    } catch (error) {
      // 界面由文件面板给出具体提示;这里落一份日志便于排查(解包失败常因读不到安装包)。
      AppLog.w('ApkWorkspace', '解包失败 project=${project.id}: $error');
    } finally {
      ref.invalidate(apkWorkspaceReadyProvider(project.id));
    }
  }
}
