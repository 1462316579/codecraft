import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent/models/chat_session.dart';
import '../../../agent/models/project.dart';
import '../../../app/shell.dart';
import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/window_size.dart';
import '../../../data/workbench.dart';
import '../../../g11n/app_globalizations.dart';

/// 聊天页顶栏(移植自上游 ChatHeaderComponents.kt 的视觉结构):
/// 左:抽屉菜单(窄屏);中:会话标题 + 模型名两行;右:新建会话 + Git 入口。
class ChatHeader extends ConsumerWidget {
  const ChatHeader({
    super.key,
    required this.title,
    this.modelName,
    this.mode = AgentMode.build,
    this.onOpenDrawer,
    this.onNewChat,
  });

  final String title;
  final String? modelName;

  /// 会话的工作模式:写作模式不显示 Git / 终端入口(它不碰代码仓库与命令行)。
  final AgentMode mode;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNewChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g11n = AppGlobalizations.of(context);
    final semantic = context.semantic;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.light
                  ? [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)]
                  : [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            Spacing.sm,
            MediaQuery.of(context).padding.top,
            Spacing.sm,
            Spacing.xs,
          ),
      child: Row(
        children: [
          if (onOpenDrawer != null)
            IconButton(
              icon: Icon(Icons.menu, color: semantic.subtleText),
              tooltip: g11n.openSidebar,
              onPressed: onOpenDrawer,
            )
          else
            const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.memory, size: 14, color: semantic.subtleText),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        modelName?.isNotEmpty == true ? modelName! : g11n.noModelSelected,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: semantic.subtleText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onNewChat != null)
            IconButton(
              icon: Icon(Icons.add, color: semantic.subtleText),
              tooltip: g11n.newSession,
              onPressed: onNewChat,
            ),
          // 写作模式不显示这两个入口;Git 对逆向项目也没有意义(看的是别人装好的 APK)。
          if (mode != AgentMode.write) ...[
          if (ref.watch(currentProjectProvider)?.kind != ProjectKind.reverse)
          // Git 入口(对齐上游 chat_open_git):大屏开工作台右栏,窄屏跳整屏路由
          IconButton(
            icon: Icon(
              Iconfont.gitBranch,
              color: ref.watch(workbenchProvider).kind == WorkbenchPaneKind.git
                  ? Theme.of(context).colorScheme.primary
                  : semantic.subtleText,
            ),
            tooltip: g11n.chatOpenGit,
            onPressed: () => openWorkbench(
              context,
              ref,
              WorkbenchPaneKind.git,
              isWideLayout(context),
            ),
          ),
          // 终端入口(对齐上游 chat_open_terminal)
          // 终端入口:大屏开工作台右栏,窄屏跳整屏路由(对齐上游 openWorkbench)
          IconButton(
            icon: Icon(
              Iconfont.terminal,
              color: ref.watch(workbenchProvider).kind == WorkbenchPaneKind.terminal
                  ? Theme.of(context).colorScheme.primary
                  : semantic.subtleText,
            ),
            tooltip: g11n.chatOpenTerminal,
            onPressed: () => openWorkbench(
              context,
              ref,
              WorkbenchPaneKind.terminal,
              isWideLayout(context),
            ),
          ),
          ],
          // 浏览器入口在会话抽屉里(设置项的上面),顶栏不放。
        ],
      ),
    ),
  ),
  );
  }
}