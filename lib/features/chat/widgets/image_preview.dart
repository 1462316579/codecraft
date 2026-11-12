import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// 全屏图片查看器(对齐上游 ImageViewerHost):近黑背板 + 可缩放图片;
/// 点图片或右上角关闭按钮退出。
Future<void> showImagePreview(
  BuildContext context, {
  required String path,
  String title = '',
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) => _ImagePreviewDialog(
      path: path,
      title: title.isEmpty ? l10n.imagePreview : title,
    ),
  );
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              maxScale: 6,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                semanticLabel: title,
                errorBuilder: (context, error, stack) => Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.image, size: 40, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        l10n.imageLoadFailed,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: l10n.close,
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}