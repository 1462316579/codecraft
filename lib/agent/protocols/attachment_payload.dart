import 'dart:convert';
import 'dart:io';

import '../../core/util/image_downscaler.dart';
import '../models/agent_attachment.dart';

/// 内嵌图片 base64 的 LRU 缓存:key = path:size:lastModified,避免工具循环中
/// 每轮 LLM 调用都重读文件 + 解码 + 缩小 + 重新编码。带条目与总字节双重上限,
/// 缓存连缩小后的 mime 一起存(对齐上游 MessagePersistenceUseCase.imageBase64Cache)。
class _CachedImage {
  const _CachedImage(this.mimeType, this.base64);

  final String mimeType;
  final String base64;
}

const int _maxCacheEntries = 16;
const int _maxCacheBytes = 32 * 1024 * 1024;

final Map<String, _CachedImage> _imagePayloadCache = {};
var _imageCacheBytes = 0;

/// 图片附件 → 缩小后的 base64 与实际 mime(供三家协议构造图片负载)。
///
/// 发给模型的是长边不超过 1568px 的副本,工作区里保存的仍是原图;mime 跟随
/// 缩小结果(透明图会保持 PNG),不再沿用附件原 mime。
/// 读盘失败(文件被删等)返回 null,调用方跳过该附件。
({String mimeType, String base64})? attachmentPayload(AgentAttachment attachment) {
  final file = File(attachment.localPath);
  String key;
  try {
    key = '${file.path}:${file.lengthSync()}:${file.lastModifiedSync().microsecondsSinceEpoch}';
  } catch (_) {
    key = file.path;
  }
  final hit = _imagePayloadCache.remove(key);
  if (hit != null) {
    _imagePayloadCache[key] = hit;
    return (mimeType: hit.mimeType, base64: hit.base64);
  }
  try {
    final bytes = file.readAsBytesSync();
    final downscaled = ImageDownscaler.downscale(
      bytes,
      attachment.mimeType.isEmpty ? 'image/jpeg' : attachment.mimeType,
    );
    final base64 = base64Encode(downscaled.bytes);
    final cached = _CachedImage(downscaled.mimeType, base64);
    _imagePayloadCache[key] = cached;
    _imageCacheBytes += base64.length;
    while (_imageCacheBytes > _maxCacheBytes && _imagePayloadCache.length > 1) {
      final eldestKey = _imagePayloadCache.keys.first;
      _imageCacheBytes -= _imagePayloadCache.remove(eldestKey)!.base64.length;
    }
    if (_imagePayloadCache.length > _maxCacheEntries) {
      _imageCacheBytes -= _imagePayloadCache.remove(_imagePayloadCache.keys.first)!.base64.length;
    }
    return (mimeType: cached.mimeType, base64: cached.base64);
  } catch (_) {
    return null;
  }
}
