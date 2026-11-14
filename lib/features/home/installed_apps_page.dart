
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/installed_apps.dart';
import '../../l10n/app_localizations.dart';

/// 「应用逆向」新建流程第二步:从已安装应用里选目标。
///
/// 行布局对齐参考样式:48dp 圆角图标 + 加粗应用名 + 包名 + `版本 (code)`。
/// 只展示公开的应用元数据;选中后返回给调用方建项目。
class InstalledAppsPage extends ConsumerStatefulWidget {
  const InstalledAppsPage({super.key});

  @override
  ConsumerState<InstalledAppsPage> createState() => _InstalledAppsPageState();
}

class _InstalledAppsPageState extends ConsumerState<InstalledAppsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appsAsync = ref.watch(installedAppsProvider);
    return Scaffold(
      backgroundColor: context.semantic.pageBackground,
      appBar: AppBar(
        backgroundColor: context.semantic.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.installedAppsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Iconfont.search, size: 18),
                hintText: l10n.installedAppsSearch,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
        data: (apps) {
          final filtered = _query.isEmpty
              ? apps
              : apps
                  .where((app) =>
                      app.label.toLowerCase().contains(_query) ||
                      app.packageName.toLowerCase().contains(_query))
                  .toList();
          if (filtered.isEmpty) {
            return Center(
              child: Text(
                l10n.installedAppsEmpty,
                style: TextStyle(color: context.semantic.subtleText),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final app = filtered[index];
              return _AppRow(
                app: app,
                onTap: () => Navigator.pop(context, app),
              );
            },
          );
        },
      ),
    );
  }
}

/// 应用行:图标 + 三行文字(名称 / 包名 / 版本),对齐参考样式。
class _AppRow extends ConsumerWidget {
  const _AppRow({required this.app, required this.onTap});

  final InstalledApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconAsync = ref.watch(appIconProvider(app.packageName));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: _AppIcon(bytes: iconAsync.valueOrNull, label: app.label),
      title: Text(
        app.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.packageName,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            app.versionLabel,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 圆角应用图标;加载中/失败时用首字母占位。
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.bytes, required this.label});

  final Uint8List? bytes;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: bytes == null
          ? Center(
              child: Text(
                label.isEmpty ? '?' : label.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}