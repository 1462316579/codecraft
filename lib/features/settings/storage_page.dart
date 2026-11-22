import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../g11n/app_globalizations.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/storage.dart';
import '../../data/storage_controller.dart';

/// 分类色点(对齐上游 StorageUsagePalette)。
Color _categoryColor(StorageCategory category) => switch (category) {
      StorageCategory.container => const Color(0xFF8B5CF6),
      StorageCategory.containerImage => const Color(0xFFA78BFA),
      StorageCategory.chat => const Color(0xFF3B82F6),
      StorageCategory.workspaces => const Color(0xFF22C55E),
      StorageCategory.aiConfig => const Color(0xFF14B8A6),
      StorageCategory.checkpoints => const Color(0xFFF59E0B),
      StorageCategory.logs => const Color(0xFFF97316),
      StorageCategory.caches => const Color(0xFF94A3B8),
      StorageCategory.other => const Color(0xFFCBD5E1),
      StorageCategory.apk => const Color(0xFF64748B),
    };

/// 分类色点缩进宽度:色点 10dp + 与标题的间距,明细行据此与标题左对齐。
const double _detailIndent = 10 + Spacing.md;
const double _selectionWidth = 48;

/// 存储空间页:总览、分类明细与选中项清理。
///
/// 统计逐项到达(大目录慢),未算出的分类先占位显示「—」,不阻塞已算出的部分。
class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  List<CleanupKind>? _pendingCleanup;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storageProvider);
    final controller = ref.read(storageProvider.notifier);
    final theme = Theme.of(context);

    final pending = _pendingCleanup;
    if (pending != null) {
      _pendingCleanup = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmClean(context, pending, state, controller);
      });
    }

    final g11n = AppGlobalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(g11n.storageTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: g11n.storageRefresh,
            icon: const Icon(Iconfont.refreshCw, size: 22),
            onPressed: state.cleaning ? null : () => controller.refresh(),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.sm,
                Spacing.lg,
                Spacing.xl + 60,
              ),
              children: [
                _OverviewCard(state: state),
                const SizedBox(height: Spacing.xs),
                SettingsGroupHeader(text: g11n.storageCategoryDetail),
                SettingsGroup(
                  children: [
                    for (var index = 0; index < StorageCategory.values.length; index++) ...[
                      if (index > 0) const SettingsDivider(),
                      _buildCategoryRow(context, state, controller, StorageCategory.values[index]),
                    ],
                  ],
                ),
                _FootNote(
                  text: g11n.storageFootnote,
                ),
                if (state.freedBytes != null)
                  _FootNote(text: g11n.storageFreedBytes(formatStorageSize(state.freedBytes!))),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCleanBar(context, state, controller),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    StorageUiState state,
    StorageController controller,
    StorageCategory category,
  ) {
    final entry = state.entries[category];
    final details = (entry?.details ?? const <StorageDetail>[]).where((detail) {
      // AI 配置只把可清理的两项单独列出。
      if (category != StorageCategory.aiConfig) return true;
      return detail.key == StorageDetailKey.toolOutput ||
          detail.key == StorageDetailKey.visionSessions;
    }).toList();
    final cleanupKind = switch (category) {
      StorageCategory.logs => CleanupKind.logs,
      StorageCategory.caches => CleanupKind.caches,
      _ => null,
    };
    final expanded = state.expanded.contains(category);

    return Column(
      children: [
        _CategoryRow(
          category: category,
          bytes: entry?.bytes,
          expandable: details.isNotEmpty,
          expanded: expanded,
          onToggle: () => controller.toggleExpanded(category),
          cleanupKind: cleanupKind,
          selected: cleanupKind != null && state.selectedCleanup.contains(cleanupKind),
          cleaning: state.cleaning,
          onSelect: () {
            if (cleanupKind != null) controller.toggleCleanup(cleanupKind);
          },
        ),
        if (expanded)
          for (final detail in details)
            _DetailRow(
              detail: detail,
              cleanupKind: switch (detail.key) {
                StorageDetailKey.toolOutput => CleanupKind.toolOutput,
                StorageDetailKey.visionSessions => CleanupKind.visionSessions,
                _ => null,
              },
              selected: state.selectedCleanup.contains(
                detail.key == StorageDetailKey.toolOutput
                    ? CleanupKind.toolOutput
                    : CleanupKind.visionSessions,
              ),
              cleaning: state.cleaning,
              onSelect: (kind) => controller.toggleCleanup(kind),
            ),
      ],
    );
  }

  Widget _buildCleanBar(
    BuildContext context,
    StorageUiState state,
    StorageController controller,
  ) {
    final g11n = AppGlobalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: state.selectedBytes > 0 && !state.cleaning
              ? () {
                  setState(() {
                    _pendingCleanup = CleanupKind.values
                        .where((kind) =>
                            state.selectedCleanup.contains(kind) &&
                            (state.cleanableSizes[kind] ?? 0) > 0)
                        .toList();
                  });
                }
              : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: state.cleaning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(g11n.storageCleanSelect(formatStorageSize(state.selectedBytes))),
        ),
      ),
    );
  }

  Future<void> _confirmClean(
    BuildContext context,
    List<CleanupKind> kinds,
    StorageUiState state,
    StorageController controller,
  ) async {
    final g11n = AppGlobalizations.of(context);
    final total = kinds.fold(0, (sum, kind) => sum + (state.cleanableSizes[kind] ?? 0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.storageConfirmClean),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                g11n.storageConfirmContent(formatStorageSize(total)),
              ),
              const SizedBox(height: Spacing.md),
              for (final kind in kinds) ...[
                Text(_cleanupKindLabel(kind, g11n), style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  _cleanupKindDesc(kind, g11n),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.sm),
              ],
              Text(
                g11n.storageConfirmDetail,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(g11n.storageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(g11n.storageClean),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.clean(kinds);
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.state});

  final StorageUiState state;

  @override
  Widget build(BuildContext context) {
    final subtle = context.semantic.subtleText;
    final g11n = AppGlobalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.light ? Colors.white : context.semantic.cardSurface)
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            g11n.storageAppUsage,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontSize: 13, color: subtle),
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Text(
                formatStorageSize(state.totalBytes),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (state.scanning) ...[
                const SizedBox(width: Spacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  g11n.storageComputing,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),
          _StackedBar(entries: state.entries),
          const SizedBox(height: Spacing.sm),
          Text(
            g11n.storageDeviceSpace(formatStorageSize(state.deviceSpace.availableBytes), formatStorageSize(state.deviceSpace.totalBytes)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
          ),
        ],
      ),
    ),
  ),
  );
  }
}

/// 各分类占比条:整条宽度代表 App 总占用,按分类颜色分段。
class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.entries});

  final Map<StorageCategory, StorageEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.values.fold(0, (sum, entry) => sum + entry.bytes);
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 10,
        color: context.semantic.capsuleSurface,
        child: total <= 0
            ? null
            : Row(
                // 无子节点的色块在 Row 里会被压成零高,必须撑满交叉轴。
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in StorageCategory.values)
                    if ((entries[category]?.bytes ?? 0) > 0)
                      Expanded(
                        flex: entries[category]!.bytes,
                        child: ColoredBox(color: _categoryColor(category)),
                      ),
                ],
              ),
      ),
    );
  }
}

/// 分类标签的本地化映射。
String _categoryLabel(StorageCategory category, AppGlobalizations g11n) {
  return switch (category) {
    StorageCategory.container => g11n.storageCategoryContainer,
    StorageCategory.containerImage => g11n.storageCategoryContainerImage,
    StorageCategory.chat => g11n.storageCategoryChat,
    StorageCategory.workspaces => g11n.storageCategoryWorkspaces,
    StorageCategory.aiConfig => g11n.storageCategoryAiConfig,
    StorageCategory.checkpoints => g11n.storageCategoryCheckpoints,
    StorageCategory.logs => g11n.storageCategoryLogs,
    StorageCategory.caches => g11n.storageCategoryCaches,
    StorageCategory.other => g11n.storageCategoryOther,
    StorageCategory.apk => g11n.storageCategoryApk,
  };
}

/// CleanupKind 标签的本地化映射。
String _cleanupKindLabel(CleanupKind kind, AppGlobalizations g11n) {
  return switch (kind) {
    CleanupKind.caches => g11n.cleanupCaches,
    CleanupKind.logs => g11n.cleanupLogs,
    CleanupKind.toolOutput => g11n.cleanupToolOutput,
    CleanupKind.visionSessions => g11n.cleanupVisionSessions,
  };
}

/// CleanupKind 描述的本地化映射。
String _cleanupKindDesc(CleanupKind kind, AppGlobalizations g11n) {
  return switch (kind) {
    CleanupKind.caches => g11n.cleanupCachesDesc,
    CleanupKind.logs => g11n.cleanupLogsDesc,
    CleanupKind.toolOutput => g11n.cleanupToolOutputDesc,
    CleanupKind.visionSessions => g11n.cleanupVisionSessionsDesc,
  };
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.bytes,
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.cleanupKind,
    required this.selected,
    required this.cleaning,
    required this.onSelect,
  });

  final StorageCategory category;
  final int? bytes;
  final bool expandable;
  final bool expanded;
  final VoidCallback onToggle;
  final CleanupKind? cleanupKind;
  final bool selected;
  final bool cleaning;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final subtle = context.semantic.subtleText;
    final g11n = AppGlobalizations.of(context);
    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _categoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _categoryLabel(category, g11n),
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expandable) ...[
                  const SizedBox(width: Spacing.xs),
                  Icon(
                    expanded ? Iconfont.chevronDown : Iconfont.chevronRight,
                    size: 18,
                    color: subtle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            bytes == null ? '—' : formatStorageSize(bytes!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtle),
          ),
          if (cleanupKind != null)
            Checkbox(
              value: selected && (bytes ?? 0) > 0,
              onChanged: (bytes ?? 0) > 0 && !cleaning ? (_) => onSelect() : null,
            )
          else
            const SizedBox(width: _selectionWidth),
        ],
      ),
    );

    if (!expandable) return content;
    return InkWell(onTap: onToggle, child: content);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.detail,
    required this.cleanupKind,
    required this.selected,
    required this.cleaning,
    required this.onSelect,
  });

  final StorageDetail detail;
  final CleanupKind? cleanupKind;
  final bool selected;
  final bool cleaning;
  final ValueChanged<CleanupKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final subtle = context.semantic.subtleText;
    final kind = cleanupKind;
    final g11n = AppGlobalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg + _detailIndent + (detail.indent ? Spacing.lg : 0),
        right: Spacing.lg,
        top: Spacing.xs,
        bottom: Spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _selectionWidth),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    kind == null ? detail.label : _cleanupKindLabel(kind, g11n),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: kind == null ? 1 : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  formatStorageSize(detail.bytes),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
                ),
                if (kind != null)
                  Checkbox(
                    value: selected && detail.bytes > 0,
                    onChanged: detail.bytes > 0 && !cleaning ? (_) => onSelect(kind) : null,
                  )
                else
                  const SizedBox(width: _selectionWidth),
              ],
            ),
          ),
          if (detail.note != null)
            Text(
              detail.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// 分组下方的灰色小字说明。
class _FootNote extends StatelessWidget {
  const _FootNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: context.semantic.subtleText),
      ),
    );
  }
}


