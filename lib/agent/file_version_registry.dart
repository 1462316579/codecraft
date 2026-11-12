import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 「本会话最后看到的文件版本」登记表(对齐上游 FileVersionRegistry)。
///
/// 回滚代码时用它区分两种「文件被改过」:
/// - **本会话自己的改动** —— 正是用户要撤销的东西,必须照常回滚;
/// - **外部(其他会话/用户)叠加的改动** —— 必须保留,只跳过该文件。
///
/// 判据不能是「快照时记的指纹」:那个指纹只在拍快照那一刻算过一次,本会话其后的写入
/// 不会刷新它,拿它比对会把本会话自己的正常改动误判成外部改动,回滚就永远拒绝执行。
/// 因此这里记录的是「本会话每次读写之后的最新指纹」。
class FileVersionRegistry {
  final Map<String, Map<String, String>> _bySession = {};

  /// 记录本会话刚写入或刚读到某文件的版本。
  void record(String sessionId, String displayPath, String fingerprint) {
    (_bySession[sessionId] ??= {})[displayPath] = fingerprint;
  }

  /// 本会话最后看到该文件的版本;从未见过则返回 null(回滚时按未知版本放行)。
  String? get(String sessionId, String displayPath) => _bySession[sessionId]?[displayPath];

  /// 回滚写回后调用:这次写入对所有会话都是外部改动,本会话的记录也一并更新。
  void recordExternal(String displayPath, String fingerprint) {
    for (final versions in _bySession.values) {
      if (versions.containsKey(displayPath)) versions[displayPath] = fingerprint;
    }
  }

  /// 本会话删除了该文件:忘掉记录,避免后续误判。
  void forget(String sessionId, String displayPath) {
    _bySession[sessionId]?.remove(displayPath);
  }

  void clearSession(String sessionId) => _bySession.remove(sessionId);

  /// 内容指纹:sha1。内容过大或无法编码时返回 null,调用方按「未知版本」处理。
  static String? fingerprintOf(String content) {
    try {
      return sha1.convert(utf8.encode(content)).toString();
    } catch (_) {
      return null;
    }
  }
}
