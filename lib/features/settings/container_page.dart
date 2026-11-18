import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/container/container_launcher.dart';
import '../../data/container/container_manager.dart';
import '../../l10n/app_localizations.dart';

/// 容器与镜像页：只展示已安装容器，镜像目录放在独立的下载页。
class ContainerPage extends ConsumerStatefulWidget {
  const ContainerPage({super.key});

  @override
  ConsumerState<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends ConsumerState<ContainerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(containerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(containerProvider);
    final notifier = ref.read(containerProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.containerPageTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.containerDownloadTooltip,
            icon: const Icon(Iconfont.download, size: 22),
            onPressed: () => context.push('/settings/container/download'),
          ),
          IconButton(
            tooltip: l10n.containerRefreshTooltip,
            icon: const Icon(Iconfont.refreshCw, size: 22),
            onPressed: state.busy ? null : notifier.refresh,
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
                ? const [
                    Color(0xFFEDE9FE),
                    Color(0xFFDBEAFE),
                    Color(0xFFFCE7F3)
                  ]
                : const [
                    Color(0xFF1E1B4B),
                    Color(0xFF1E3A8A),
                    Color(0xFF4C1D95)
                  ],
          ),
        ),
        child: state.containers.isEmpty
            ? const _EmptyContainers()
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      Spacing.sm,
                  Spacing.lg,
                  Spacing.xl + 60,
                ),
                children: [
                  SettingsGroupHeader(text: l10n.containerInstalledSection),
                  SettingsGroup(
                    children: [
                      for (var i = 0; i < state.containers.length; i++) ...[
                        if (i > 0)
                          const SettingsDivider(indent: SettingsRow.textIndent),
                        _buildContainerRow(
                          context,
                          state,
                          notifier,
                          state.containers[i],
                          l10n,
                        ),
                      ],
                    ],
                  ),
                  _FootNote(
                    text: l10n.containerDeleteFootnote,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContainerRow(
    BuildContext context,
    ContainerState state,
    ContainerNotifier notifier,
    ContainerInfo container,
    AppLocalizations l10n,
  ) {
    final isDefault = state.defaultId == container.id ||
        (state.defaultId == null && state.containers.first.id == container.id);

    return SettingsRow(
      icon: Iconfont.box,
      title: container.name,
      subtitle: isDefault
          ? l10n.containerDefaultSubtitle(_formatBytes(container.sizeBytes))
          : _formatBytes(container.sizeBytes),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDefault)
            TextButton(
              onPressed:
                  state.busy ? null : () => notifier.setDefault(container.id),
              child: Text(l10n.containerSetDefault),
            ),
          IconButton(
            tooltip: l10n.containerDeleteTitle,
            icon: const Icon(Iconfont.trash, size: 18),
            onPressed: state.busy
                ? null
                : () => _confirmRemove(context, notifier, container, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ContainerNotifier notifier,
    ContainerInfo container,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.containerDeleteTitle),
        content: Text(l10n.containerDeleteContent(container.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.remove(container.id);
    }
  }
}

/// 容器下载页：只负责镜像目录和下载状态，不与已安装容器混排。
class ContainerDownloadPage extends ConsumerWidget {
  const ContainerDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(containerProvider);
    final notifier = ref.read(containerProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.containerDownloadPageTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [
                    Color(0xFFEDE9FE),
                    Color(0xFFDBEAFE),
                    Color(0xFFFCE7F3)
                  ]
                : const [
                    Color(0xFF1E1B4B),
                    Color(0xFF1E3A8A),
                    Color(0xFF4C1D95)
                  ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg,
            MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.sm,
            Spacing.lg,
            Spacing.xl + 60,
          ),
          children: [
            _HintCard(
              text: l10n.containerDownloadHint,
            ),
            if (state.busy) ...[
              const SizedBox(height: Spacing.md),
              _ProgressCard(
                label: state.busyStage ?? l10n.containerInstallingStage,
                progress: state.busyProgress,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: Spacing.md),
              _ErrorCard(
                message: state.error!,
                onDismiss: notifier.clearError,
              ),
            ],
            SettingsGroupHeader(text: l10n.containerAvailableImages),
            SettingsGroup(
              children: [
                for (var i = 0; i < kContainerImages.length; i++) ...[
                  if (i > 0)
                    const SettingsDivider(indent: SettingsRow.textIndent),
                  _buildImageRow(
                    context,
                    state,
                    notifier,
                    kContainerImages[i],
                    l10n,
                  ),
                ],
              ],
            ),
            _FootNote(
              text: l10n.containerDownloadAfter,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildImageRow(
  BuildContext context,
  ContainerState state,
  ContainerNotifier notifier,
  ContainerImage image,
  AppLocalizations l10n,
) {
  final installing = state.busyImageId == image.id;
  final installedCount =
      state.containers.where((c) => c.imageId == image.id).length;

  return SettingsRow(
    icon: Iconfont.download,
    title: image.name,
    subtitle: installedCount > 0
        ? '${image.description} · ${image.sizeLabel} · ${installedCount} 已安装'
        : '${image.description} · ${image.sizeLabel}',
    trailing: installing
        ? Text(
            '${(state.busyProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelLarge,
          )
        : FilledButton.tonal(
            onPressed: state.busy ? null : () => notifier.install(image),
            child: Text(l10n.containerDownloadButton),
          ),
  );
}

class _EmptyContainers extends StatelessWidget {
  const _EmptyContainers();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.semantic.subtleText;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconfont.box, size: 56, color: color),
            const SizedBox(height: Spacing.lg),
            Text(
              l10n.containerNoContainers,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.containerNoContainersDesc,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.mdLarge),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.semantic.subtleText,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.mdLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress > 0 && progress < 1 ? progress : null,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.md, Spacing.sm, Spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.mdLarge),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconfont.alertCircle, size: 18, color: color),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          IconButton(
            icon: const Icon(Iconfont.x, size: 16),
            onPressed: onDismiss,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.semantic.subtleText,
              height: 1.5,
            ),
      ),
    );
  }
}
