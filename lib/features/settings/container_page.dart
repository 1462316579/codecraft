import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/container/container_launcher.dart';
import '../../data/container/container_manager.dart';

/// 容器与镜像页：PRoot 运行环境状态、镜像下载安装、已安装容器管理。
///
/// 终端与 AI 命令都跑在默认容器里，所以这里既是「安装入口」也是「修复入口」。
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('容器与镜像'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: '刷新',
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
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
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
              text: '终端与 AI 命令都在默认容器里执行。'
                  '镜像为官方 aarch64 rootfs，解压后由 PRoot 提供隔离的文件系统。',
            ),
            if (state.busy) ...[
              const SizedBox(height: Spacing.md),
              _ProgressCard(
                label: state.busyStage ?? '正在安装…',
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
            const SettingsGroupHeader(text: '运行环境'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Iconfont.cpu,
                  title: 'PRoot 运行环境',
                  subtitle: state.runtimeInstalled
                      ? '已就绪（内置资产，离线安装）'
                      : (state.runtimeStage.isEmpty
                          ? '未安装 · 首次使用终端时自动安装'
                          : state.runtimeStage),
                  trailing: state.runtimeInstalled
                      ? Icon(Iconfont.checkCircle,
                          size: 20, color: theme.colorScheme.primary)
                      : FilledButton.tonal(
                          onPressed: state.busy
                              ? null
                              : () => notifier.ensureRuntime(),
                          child: const Text('安装'),
                        ),
                ),
              ],
            ),
            const SettingsGroupHeader(text: '可用镜像'),
            SettingsGroup(
              children: [
                for (var i = 0; i < kContainerImages.length; i++) ...[
                  if (i > 0) const SettingsDivider(indent: SettingsRow.textIndent),
                  _buildImageRow(context, state, notifier, kContainerImages[i]),
                ],
              ],
            ),
            const SettingsGroupHeader(text: '已安装容器'),
            SettingsGroup(
              children: state.containers.isEmpty
                  ? [
                      SettingsRow(
                        icon: Iconfont.box,
                        title: '暂无容器',
                        subtitle: '从上面的镜像列表下载一个即可开始使用终端',
                      ),
                    ]
                  : [
                      for (var i = 0; i < state.containers.length; i++) ...[
                        if (i > 0)
                          const SettingsDivider(indent: SettingsRow.textIndent),
                        _buildContainerRow(
                          context,
                          state,
                          notifier,
                          state.containers[i],
                        ),
                      ],
                    ],
            ),
            const _FootNote(
              text: '删除容器会同时删除容器内安装的软件包；工作区文件不受影响。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageRow(
    BuildContext context,
    ContainerState state,
    ContainerNotifier notifier,
    ContainerImage image,
  ) {
    final installing = state.busyImageId == image.id;
    final installedCount =
        state.containers.where((c) => c.imageId == image.id).length;

    return SettingsRow(
      icon: Iconfont.download,
      title: image.name,
      subtitle: installedCount > 0
          ? '${image.description} · ${image.sizeLabel} · 已安装 $installedCount 个'
          : '${image.description} · ${image.sizeLabel}',
      trailing: installing
          ? Text(
              '${(state.busyProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelLarge,
            )
          : FilledButton.tonal(
              onPressed: state.busy ? null : () => notifier.install(image),
              child: const Text('下载'),
            ),
    );
  }

  Widget _buildContainerRow(
    BuildContext context,
    ContainerState state,
    ContainerNotifier notifier,
    ContainerInfo container,
  ) {
    final isDefault = state.defaultId == container.id ||
        (state.defaultId == null && state.containers.first.id == container.id);

    return SettingsRow(
      icon: Iconfont.box,
      title: container.name,
      subtitle: isDefault
          ? '默认容器 · ${_formatBytes(container.sizeBytes)}'
          : _formatBytes(container.sizeBytes),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDefault)
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => notifier.setDefault(container.id),
              child: const Text('设为默认'),
            ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Iconfont.trash, size: 18),
            onPressed: state.busy
                ? null
                : () => _confirmRemove(context, notifier, container),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ContainerNotifier notifier,
    ContainerInfo container,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除容器'),
        content: Text('确定删除「${container.name}」吗？容器内安装的软件会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.remove(container.id);
    }
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
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.sm, Spacing.sm),
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
