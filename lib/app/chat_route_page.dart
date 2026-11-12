import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/models/chat_session.dart';
import '../../agent/sessions_controller.dart';
import '../../core/util/window_size.dart';
import '../../data/workbench.dart';
import '../../features/chat/chat_page.dart';
import '../../features/sessions/sessions_drawer.dart';
import 'shell.dart';

/// 聊天页的路由外壳:聊天是独立页面(从项目列表 push 进来)。
///
/// 布局与首页一致——宽屏常驻侧栏 + 聊天并排(可再拖出右栏),窄屏单栏 + 抽屉;
/// 顶栏左侧是「侧边栏」(与首页相同),返回靠系统返回手势/返回键。
class ChatRoutePage extends ConsumerStatefulWidget {
  const ChatRoutePage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatRoutePage> createState() => _ChatRoutePageState();
}

class _ChatRoutePageState extends ConsumerState<ChatRoutePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 写作会话没有 Git / 终端:若当前右栏正停在这两者之一,进页面时收起来。
  void _closeCodePaneForWriting(AgentMode mode) {
    if (mode != AgentMode.write) return;
    final workbench = ref.read(workbenchProvider);
    if (workbench.kind == WorkbenchPaneKind.git ||
        workbench.kind == WorkbenchPaneKind.terminal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(workbenchProvider.notifier).close();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 抽屉里换会话:当前路由得跟着换,否则顶栏和内容还停在上一个会话。
    ref.listen(selectedSessionProvider, (previous, next) {
      if (next != null && next != widget.sessionId) {
        context.pushReplacement('/chat/$next');
      }
    });

    final mode = ref.watch(sessionByIdProvider(widget.sessionId)).valueOrNull?.mode;
    if (mode != null) _closeCodePaneForWriting(mode);

    final chat = ChatPage(
      key: ValueKey(widget.sessionId),
      sessionId: widget.sessionId,
    );

    if (isWideLayout(context)) {
      final workbench = ref.watch(workbenchProvider);
      final paneOpen = workbench.open;
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              const SizedBox(width: 320, child: SessionsDrawer()),
              const VerticalDivider(width: 1),
              Expanded(
                flex: (workbench.split * 1000).round(),
                child: chat,
              ),
              if (paneOpen) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    final width = MediaQuery.sizeOf(context).width;
                    if (width <= 0) return;
                    ref
                        .read(workbenchProvider.notifier)
                        .setSplit(workbench.split + details.delta.dx / width);
                  },
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: SizedBox(width: 8, child: VerticalDivider(width: 8)),
                  ),
                ),
                Expanded(
                  flex: ((1 - workbench.split) * 1000).round(),
                  child: WorkbenchPane(kind: workbench.kind),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ShellScope(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      closeDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        drawer: const Drawer(
          width: 300,
          child: SafeArea(child: SessionsDrawer()),
        ),
        body: chat,
      ),
    );
  }
}
