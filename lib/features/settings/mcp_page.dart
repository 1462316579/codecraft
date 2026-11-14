import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/mcp/mcp_config.dart';
import '../../data/mcp/mcp_manager.dart';
import '../../l10n/app_localizations.dart';
import 'mcp_sheets.dart';

/// MCP 服务器列表(对齐上游 McpSection):
/// 分组卡片内每台 server 一行(图标 + 名称 + 作用域/类型/摘要 pills + 状态胶囊 + 箭头),
/// 左滑删除;≥3 台时显示搜索框;右上角 + 添加、刷新重连。
class McpPage extends ConsumerStatefulWidget {
  const McpPage({super.key});

  @override
  ConsumerState<McpPage> createState() => _McpPageState();
}

class _McpPageState extends ConsumerState<McpPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(mcpEntriesProvider);
    final mcpState = ref.watch(mcpManagerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.mcpTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: mcpState.reloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconfont.refreshCw, size: 22),
            tooltip: l10n.settingsReconnect,
            onPressed: mcpState.reloading
                ? null
                : () => ref.read(mcpManagerProvider.notifier).reload(),
          ),
          IconButton(
            icon: const Icon(Iconfont.plus, size: 22),
            tooltip: l10n.settingsAddMcpServer,
            onPressed: () => showMcpAddSheet(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
        data: (entries) {
          if (entries.isEmpty) return _EmptyState(l10n: l10n);
          final filtered = _query.trim().isEmpty
              ? entries
              : [
                  for (final entry in entries)
                    if (entry.server.name.toLowerCase().contains(_query.toLowerCase()) ||
                        entry.server.url.toLowerCase().contains(_query.toLowerCase()) ||
                        entry.server.command.toLowerCase().contains(_query.toLowerCase()))
                      entry,
                ];
          return ListView(
            padding: const EdgeInsets.only(top: 80, bottom: 140),
            children: [
              const SizedBox(height: Spacing.sm),
              if (entries.length >= 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
                  child: CapsuleSearchField(
                    controller: _searchController,
                    hint: l10n.mcpSearchPlaceholder,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Iconfont.search,
                                size: 28,
                                color: context.semantic.subtleText.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                l10n.mcpSearchEmpty,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: context.semantic.subtleText),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SettingsGroup(
                        children: [
                          for (var index = 0; index < filtered.length; index++) ...[
                            if (index > 0) const SettingsDivider(indent: Spacing.lg),
                            _McpServerRow(
                              entry: filtered[index],
                              status: mcpState.statuses
                                  .where((item) => item.name == filtered[index].server.name)
                                  .firstOrNull,
                              onDelete: () => _delete(filtered[index]),
                              onTap: () => showMcpEditorSheet(context, ref, entry: filtered[index]),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Future<void> _delete(McpServerEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(mcpManagerProvider.notifier).removeServer(entry.server.name);
    ref.invalidate(mcpEntriesProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.mcpRemoved)));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconfont.terminal,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(l10n.mcpEmpty, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.mcpEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: context.semantic.subtleText),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单台 server 一行:图标块 + 名称 / 作用域、类型、摘要 pills + 状态胶囊 + 箭头。
class _McpServerRow extends StatelessWidget {
  const _McpServerRow({
    required this.entry,
    required this.status,
    required this.onTap,
    required this.onDelete,
  });

  final McpServerEntry entry;
  final McpServerStatus? status;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final server = entry.server;
    final isConnected = server.enabled && status?.state == McpServerState.connected;

    final statusText = switch (status?.state) {
      null => l10n.mcpStatusNotConnected,
      McpServerState.connected => l10n.mcpStatusConnected,
      McpServerState.connecting => l10n.mcpStatusConnecting,
      McpServerState.needsAuth => l10n.mcpStatusNeedsAuth,
      McpServerState.failed => l10n.mcpStatusFailed,
      McpServerState.disabled => l10n.mcpStatusDisabled,
    };
    final statusColor = switch (status?.state) {
      null || McpServerState.disabled => semantic.subtleText,
      McpServerState.connected => semantic.success,
      McpServerState.connecting || McpServerState.needsAuth => theme.colorScheme.primary,
      McpServerState.failed => theme.colorScheme.error,
    };
    final typeText = server.isStdio ? l10n.mcpTypeStdio : 'HTTP';
    final infoText = isConnected
        ? l10n.mcpToolsCount(status?.toolCount ?? 0)
        : (server.isStdio ? (server.command.isEmpty ? 'stdio' : server.command) : null);

    return SwipeToDeleteRow(
      onDelete: onDelete,
      onTap: onTap,
      decorateChild: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconfont.box,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(
                        text: entry.scope == McpScope.project
                            ? l10n.mcpScopeProject
                            : l10n.mcpScopeGlobal,
                        textColor: entry.scope == McpScope.project
                            ? theme.colorScheme.primary
                            : semantic.subtleText,
                        background: entry.scope == McpScope.project
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : semantic.mutedSurface,
                      ),
                      const SizedBox(width: 6),
                      _Pill(text: typeText, textColor: semantic.subtleText, background: semantic.mutedSurface),
                      if (infoText != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _Pill(
                            text: infoText,
                            textColor: semantic.subtleText,
                            background: semantic.mutedSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            _Pill(
              text: statusText,
              textColor: statusColor,
              background: statusColor.withValues(alpha: 0.12),
            ),
            const SizedBox(width: Spacing.xs),
            Icon(Iconfont.chevronRight, size: 18, color: semantic.subtleText),
          ],
        ),
      ),
    );
  }
}

/// 紧凑胶囊标签:状态 / 类型 / 摘要用。
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.textColor, required this.background});

  final String text;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: textColor),
      ),
    );
  }
}