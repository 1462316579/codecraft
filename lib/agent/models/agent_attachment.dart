import 'dart:convert';

/// 一条消息附件(对齐上游 AgentAttachment):
/// [containerPath] 是模型看到的 `~/workspace/.codecraft/attachments/...` 写法,[localPath] 是本地实际文件。
class AgentAttachment {
  const AgentAttachment({
    required this.fileName,
    this.containerPath = '',
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    this.isImage = true,
  });

  final String fileName;
  final String containerPath;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final bool isImage;

  Map<String, Object?> toJson() => {
        'fileName': fileName,
        'containerPath': containerPath,
        'localPath': localPath,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'isImage': isImage,
      };

  static AgentAttachment fromJson(Map<String, Object?> map) => AgentAttachment(
        fileName: (map['fileName'] as String?) ?? '',
        containerPath: (map['containerPath'] as String?) ?? '',
        localPath: (map['localPath'] as String?) ?? '',
        mimeType: (map['mimeType'] as String?) ?? 'image/png',
        sizeBytes: (map['sizeBytes'] as int?) ?? 0,
        isImage: (map['isImage'] as bool?) ?? true,
      );

  static String encodeList(List<AgentAttachment> attachments) =>
      jsonEncode(attachments.map((a) => a.toJson()).toList());

  static List<AgentAttachment> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => AgentAttachment.fromJson(m.cast<String, Object?>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// 把附件清单(`附件:\n- 名称:容器路径`)追加到请求正文(对齐上游 appendAttachmentsToRequest);
/// 空正文时只留清单。
String appendAttachmentsToRequest(
  String request,
  List<AgentAttachment> attachments,
  String prefix,
) {
  if (attachments.isEmpty) return request;
  final list = [
    prefix,
    for (final attachment in attachments)
      '- ${attachment.fileName}:${attachment.containerPath}',
  ].join('\n');
  if (request.isEmpty) return list;
  return '${request.trimRight()}\n\n$list';
}