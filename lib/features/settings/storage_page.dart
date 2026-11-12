import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/storage.dart';
import '../../data/storage_controller.dart';

/// 分类色点(对齐上游 StorageUsagePalette)。
Color _categoryColor(StorageCategory category) => switch (category) {
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
        if (mounted) _confirmClean(pending, state, controller);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('存储空间'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: '重新统计',
            icon: const Icon(LucideIcons.refreshCw, size: 22),
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
                const SettingsGroupHeader(text: '占用明细'),
                SettingsGroup(
                  children: [
                    for (var index = 0; index < StorageCategory.values.length; index++) ...[
                      if (index > 0) const SettingsDivider(),
                      _buildCategoryRow(context, state, controller, StorageCategory.values[index]),
                    ],
                  ],
                ),
                const _FootNote(
                  text: '点击带箭头的分类可展开明细。删会话可减小聊天记录。',
                ),
                if (state.freedBytes != null)
                  _FootNote(text: '已释放 ${formatStorageSize(state.freedBytes!)}'),
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
              : Text('清理选中项 · ${formatStorageSize(state.selectedBytes)}'),
        ),
      ),
    );
  }

  Future<void> _confirmClean(
    List<CleanupKind> kinds,
    StorageUiState state,
    StorageController controller,
  ) async {
    final total = kinds.fold(0, (sum, kind) => sum + (state.cleanableSizes[kind] ?? 0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认清理'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('将清理以下选中项,共约 ${formatStorageSize(total)}。此操作不可恢复。'),
              const SizedBox(height: Spacing.md),
              for (final kind in kinds) ...[
                Text(kind.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  kind.description,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.sm),
              ],
              Text(
                '仅清理本机应用缓存、日志及全局目录中的所选数据,可能影响多个工作区的历史输出读取或识图追问;'
                '不会删除聊天记录、工作区文件、AI 配置或远程服务器数据。',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清理'),
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
            '应用占用',
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
                  '统计中…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),
          _StackedBar(entries: state.entries),
          const SizedBox(height: Spacing.sm),
          Text(
            '设备可用 ${formatStorageSize(state.deviceSpace.availableBytes)} / 共 ${formatStorageSize(state.deviceSpace.totalBytes)}',
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
                    category.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expandable) ...[
                  const SizedBox(width: Spacing.xs),
                  Icon(
                    expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
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
                    kind?.label ?? detail.label,
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
