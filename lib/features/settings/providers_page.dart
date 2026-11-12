import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/provider_logo.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/providers/provider_config.dart';
import '../../data/providers/provider_presets.dart';
import '../../data/providers/provider_store.dart';
import '../../l10n/app_localizations.dart';

/// 供应商列表(对齐上游 ProvidersSection):圆角 14 卡片列表、左侧品牌 logo、
/// 名称 + 类型/模型数 pills、右侧状态 pill + 箭头;左滑删除、长按拖拽排序。
class ProvidersPage extends ConsumerWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final providers = ref.watch(providersProvider);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.providers),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addProvider,
            onPressed: () => _addProvider(context, ref),
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
        child: providers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Text(
                  l10n.emptyProviders,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.semantic.subtleText),
                ),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.md,
              Spacing.lg,
              Spacing.xl,
            ),
            // 关闭默认拖拽手柄(整行长按拖动),否则会和 Dismissible 的横向手势竞争;
            // 改由卡片右侧的显式手柄触发拖动。
            buildDefaultDragHandles: false,
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.selectionClick();
              ref.read(providersProvider.notifier).reorder(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeOut.transform(animation.value);
                return Transform.scale(
                  scale: 1 - 0.05 * t,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8 * t,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    child: child,
                  ),
                );
              },
            ),
            itemBuilder: (context, index) {
              final provider = list[index];
              return Padding(
                key: ValueKey(provider.id),
                padding: EdgeInsets.only(bottom: index == list.length - 1 ? 0 : 8),
                child: SwipeToDeleteRow(
                  onDelete: () => _confirmDelete(context, ref, provider),
                  decorateChild: false,
                  child: _ProviderCard(provider: provider, dragIndex: index),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  /// 右划露出的删除按钮点击后的二次确认(对齐上游删除渠道的二次确认)。
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProviderConfig provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProviderConfirm),
        content: Text(provider.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(providersProvider.notifier).remove(provider.id);
  }

  /// 添加供应商(对齐上游 ProviderPresetSheet):自定义排在最前,其后是官方预设,
  /// 每行 28dp 品牌 logo + 名称 + 协议 pill + 标签 + 官网入口。
  Future<void> _addProvider(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
                child: Text(
                  l10n.addProvider,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xs),
                  children: [
                    _PresetRow(
                      name: l10n.customProvider,
                      typeLabel: ProviderType.openai.shortLabel,
                      logo: const ModelLogoIcon(modelName: 'openai', size: 28),
                      onTap: () => _create(context, sheetContext, ref, instantiateCustomProvider()),
                    ),
                    for (final preset in providerPresets)
                      _PresetRow(
                        name: preset.name,
                        typeLabel: preset.type.name,
                        logo: ModelLogoIcon(modelName: preset.name, size: 28),
                        tags: preset.tags,
                        recommended: preset.isRecommended,
                        websiteUrl: preset.websiteUrl,
                        onTap: () =>
                            _create(context, sheetContext, ref, instantiatePreset(preset)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    BuildContext sheetContext,
    WidgetRef ref,
    ProviderConfig provider,
  ) async {
    await ref.read(providersProvider.notifier).save(provider);
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (context.mounted) context.push('/settings/providers/${provider.id}');
  }
}

/// 预设行(上游 ProviderPresetSheet 的行样式):浅底圆角 12 卡片。
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.name,
    required this.typeLabel,
    required this.logo,
    required this.onTap,
    this.tags = const [],
    this.recommended = false,
    this.websiteUrl = '',
  });

  final String name;
  final String typeLabel;
  final Widget logo;
  final VoidCallback onTap;
  final List<String> tags;
  final bool recommended;
  final String websiteUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
            child: Row(
              children: [
                logo,
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: Spacing.xs),
                            ProviderPill(
                              text: '推荐',
                              color: theme.colorScheme.primary,
                              background: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ProviderPill(text: typeLabel),
                          for (final tag in tags) ...[
                            const SizedBox(width: Spacing.xs),
                            _TagPill(text: tag),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 注册入口标签(上游 provider_register_now 的描边胶囊)。
class _TagPill extends StatelessWidget {
  const _TagPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        border: Border.all(width: 1, color: primary.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: primary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.dragIndex});

  final ProviderConfig provider;
  final int dragIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final statusColor = provider.isEnabled
        ? semantic.success
        : Theme.of(context).colorScheme.outline;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.light ? Colors.white : semantic.cardSurface).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              width: 0.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.lg),
            child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: () => context.push('/settings/providers/${provider.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
          child: Row(
            children: [
              // 左侧品牌 logo(对齐上游:40dp 圆角 8 方块 + 22dp logo)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: ProviderLogoIcon(provider: provider),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ProviderPill(text: provider.type.shortLabel),
                        const SizedBox(width: 6),
                        Flexible(
                          child: ProviderPill(
                            text: l10n.providerModelsCountTag(provider.models.length),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              ProviderPill(
                text: provider.isEnabled ? l10n.enabled : l10n.disabled,
                color: statusColor,
                background: statusColor.withValues(alpha: 0.12),
              ),
              const SizedBox(width: Spacing.xs),
              // 拖拽手柄:仅在按住此图标时触发重排,横向滑动则交给 Dismissible 删除。
              ReorderableDragStartListener(
                index: dragIndex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.drag_handle,
                    size: 18,
                    color: semantic.subtleText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: semantic.subtleText),
            ],
          ),
        ),
      ),
    ),
  ),
),
);
  }
}

/// 列表行内的小胶囊标签(上游 McpPill):弱底 + 弱字,6 号圆角内含 2dp 垂直内边距。
class ProviderPill extends StatelessWidget {
  const ProviderPill({super.key, required this.text, this.color, this.background});

  final String text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}