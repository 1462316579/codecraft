import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../agent/models/agent_attachment.dart';
import '../agent/tools/workspace.dart';
import '../core/util/image_downscaler.dart';

/// 附件上传失败的原因;文案由 UI 侧映射(对齐上游那几条报错文案)。
enum AttachmentUploadError { imageTooLarge, unsupportedImageType, unreadableFile }

class AttachmentUploadException implements Exception {
  const AttachmentUploadException(
    this.error, {
    this.limitBytes = AttachmentStore.maxImageUploadBytes,
  });

  final AttachmentUploadError error;

  /// 触发该错误的尺寸上限(字节),用于错误提示文案。
  final int limitBytes;

  @override
  String toString() => 'AttachmentUploadException($error)';
}

/// 附件落盘(对齐上游 copyUriToWorkspace):所有附件都进工作区的 `.codecraft/attachments/`;
/// 图片整份读入(发送时随图片块给出),其它文件直接复制。
class AttachmentStore {
  AttachmentStore._();

  /// 一次最多同时挂 8 个附件(上游 MAX_PENDING_ATTACHMENTS)。
  static const int maxPendingAttachments = 8;

  /// 缩小后的副本上限 5MB(上游 MAX_IMAGE_UPLOAD_BYTES)。
  static const int maxImageUploadBytes = 5 * 1024 * 1024;

  /// 原图读入上限 40MB(上游 MAX_IMAGE_SOURCE_BYTES):原图要整份读进内存再
  /// 缩小,这里只拦会顶爆堆的超大文件;发给模型的副本在缩小时再按 5MB 校验。
  static const int maxImageSourceBytes = 40 * 1024 * 1024;

  static const List<String> _supportedImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static Future<AgentAttachment> copyToWorkspace({
    required Workspace workspace,
    required String sourcePath,
    required String fileName,
    String? mimeTypeHint,
    required bool includeImageData,
  }) async {
    final source = File(sourcePath);
    final name = _uniqueUploadName(workspace, _sanitizeUploadFileName(fileName));
    final containerPath = '${_attachmentsDir(workspace)}/$name';
    final target = File(workspace.resolve(containerPath));
    final mimeType = includeImageData
        ? _resolveImageMimeType(mimeTypeHint, name)
        : _resolveFileMimeType(mimeTypeHint, name);

    final int sizeBytes;
    if (includeImageData) {
      // 原图整份读进内存再缩小,这里只拦会顶爆堆的超大文件;发给模型的副本在
      // 缩小时再按 5MB 上限校验(上游同样两道判断 + 缩小后校验)。
      if (await _length(source) > maxImageSourceBytes) {
        throw AttachmentUploadException(
          AttachmentUploadError.imageTooLarge,
          limitBytes: maxImageSourceBytes,
        );
      }
      final bytes = await _readBytes(source);
      if (bytes.length > maxImageSourceBytes) {
        throw AttachmentUploadException(
          AttachmentUploadError.imageTooLarge,
          limitBytes: maxImageSourceBytes,
        );
      }
      // 工作区保存原图;发给模型的副本在 attachmentPayload 里同样会缩小,这里
      // 先按缩小后的大小拦一道,避免存进去却发不出去的图。
      final scaled = ImageDownscaler.downscale(bytes, mimeType);
      if (scaled.bytes.length > maxImageUploadBytes) {
        throw const AttachmentUploadException(AttachmentUploadError.imageTooLarge);
      }
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes);
      sizeBytes = bytes.length;
    } else {
      await target.parent.create(recursive: true);
      try {
        await source.copy(target.path);
      } catch (_) {
        throw const AttachmentUploadException(AttachmentUploadError.unreadableFile);
      }
      sizeBytes = await target.length();
    }

    return AgentAttachment(
      fileName: name,
      containerPath: containerPath,
      localPath: target.path,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      isImage: includeImageData,
    );
  }

  static String _attachmentsDir(Workspace workspace) =>
      '${workspace.display(workspace.rootPath)}/.codecraft/attachments';

  static Future<int> _length(File file) async {
    try {
      return await file.length();
    } catch (_) {
      throw const AttachmentUploadException(AttachmentUploadError.unreadableFile);
    }
  }

  static Future<Uint8List> _readBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      throw const AttachmentUploadException(AttachmentUploadError.unreadableFile);
    }
  }

  /// 图片类型:先用选择器给的 MIME,认不出再按扩展名,仍认不出则报错(上游 resolveImageMimeType)。
  static String _resolveImageMimeType(String? hint, String fileName) {
    final mime = hint?.toLowerCase();
    if (mime != null && _supportedImageMimeTypes.contains(mime)) return mime;
    final byExtension = switch (p.extension(fileName).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      _ => null,
    };
    if (byExtension != null) return byExtension;
    throw const AttachmentUploadException(AttachmentUploadError.unsupportedImageType);
  }

  /// 普通附件类型:先用选择器给的 MIME,认不出按扩展名推断(上游 fileMimeType)。
  static String _resolveFileMimeType(String? hint, String fileName) {
    if (hint != null && hint.isNotEmpty) return hint.toLowerCase();
    return switch (p.extension(fileName).toLowerCase()) {
      '.txt' ||
      '.md' ||
      '.kt' ||
      '.java' ||
      '.js' ||
      '.ts' ||
      '.json' ||
      '.xml' ||
      '.html' ||
      '.css' ||
      '.py' ||
      '.sh' ||
      '.gradle' ||
      '.kts' =>
        'text/plain',
      '.pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  /// 文件名清洗(上游 sanitizeUploadFileName):控制字符与路径分隔符等换成下划线,
  /// 去掉首尾空白与句点,空名回落 `upload`,最长 160 字符。
  static String _sanitizeUploadFileName(String name) {
    final cleaned = name
        .split('')
        .map((ch) => ch.codeUnitAt(0) < 32 || r'\/:*?"<>|'.contains(ch) ? '_' : ch)
        .join()
        .trim()
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (cleaned.isEmpty) return 'upload';
    return cleaned.length <= 160 ? cleaned : cleaned.substring(0, 160);
  }

  /// 同名文件加序号:`name-1.ext`、`name-2.ext`……(上游 uniqueUploadName)。
  static String _uniqueUploadName(Workspace workspace, String fileName) {
    final dir = workspace.resolve(_attachmentsDir(workspace));
    if (!File(p.join(dir, fileName)).existsSync()) return fileName;
    final extension = p.extension(fileName);
    final stem =
        extension.isEmpty ? fileName : fileName.substring(0, fileName.length - extension.length);
    var index = 1;
    while (File(p.join(dir, '$stem-$index$extension')).existsSync()) {
      index += 1;
    }
    return '$stem-$index$extension';
  }
}

/// 文件大小简写(上游 formatBytes):1.2 MB / 240 KB / 512 B。
String formatBytes(int bytes) {
  const kb = 1024.0;
  const mb = kb * 1024.0;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  return '$bytes B';
}