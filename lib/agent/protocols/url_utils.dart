// URL 拼接与采样温度:移植自原仓库 feature/agent/domain/provider/AIProvider.kt。

final _versionSegment = RegExp(r'^v\d+.*$', caseSensitive: false);

/// 由用户配置的 baseUrl 与 API 路径(如 `v1/chat/completions`)拼出完整请求 URL。
/// 容忍尾部斜杠、以及 base 已以版本段结尾(`/v1`、`/api/v3`、`/v1beta`)的情况:
/// base 末尾与路径首段相同则去重;base 末尾是版本段且路径也以版本段开头时,以 base 的版本为准。
String joinUrl(String baseUrl, String path) {
  final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final cleanPath = path.trim().replaceAll(RegExp(r'^/+'), '');
  final lastSegment = base.contains('/') ? base.substring(base.lastIndexOf('/') + 1) : '';

  if (lastSegment.isNotEmpty &&
      cleanPath.toLowerCase().startsWith('${lastSegment.toLowerCase()}/')) {
    return '$base/${cleanPath.substring(lastSegment.length + 1)}';
  }

  if (_versionSegment.hasMatch(lastSegment)) {
    final firstSegment = cleanPath.contains('/') ? cleanPath.split('/').first : cleanPath;
    if (_versionSegment.hasMatch(firstSegment)) {
      final remaining = cleanPath.contains('/') ? cleanPath.substring(cleanPath.indexOf('/') + 1) : '';
      return remaining.isEmpty ? base : '$base/$remaining';
    }
  }

  return '$base/$cleanPath';
}

final _geminiSamplingDefault = [
  RegExp(r'gemini-2[.-]5([.-]|$)'),
  RegExp(r'gemini-3-(flash|pro)([.-]|$)'),
  RegExp(r'gemini-3[.-]1([.-]|$)'),
  RegExp(r'gemini-3[.-]5-flash(?!-lite)([.-]|$)'),
];

/// 服务端钉死采样温度的模型(或官方明确要求的取值),按模型 id 返回其固定温度;表外返回 null。
double? fixedTemperature(String modelId) {
  final id = modelId.toLowerCase();
  if (id.contains('glm-4.6') || id.contains('glm-4.7')) return 1.0;
  if (id.contains('minimax-m2')) return 1.0;
  if (id.contains('gemini')) {
    return _geminiSamplingDefault.any((re) => re.hasMatch(id)) ? 1.0 : null;
  }
  if (id.contains('kimi-k2')) {
    final thinking = ['thinking', 'k2.', 'k2p', 'k2-5'].any(id.contains);
    return thinking ? 1.0 : 0.6;
  }
  return null;
}