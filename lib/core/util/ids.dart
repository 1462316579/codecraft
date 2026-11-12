import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

int nowMs() => DateTime.now().millisecondsSinceEpoch;

/// 会话默认标题:截取首条用户消息(移植原仓库的命名习惯)。
String titleFromText(String text, {int max = 30}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return '';
  return flat.length <= max ? flat : flat.substring(0, max);
}

String formatClock(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatDate(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    return formatClock(ms);
  }
  if (dt.year == now.year) {
    return '${two(dt.month)}-${two(dt.day)}';
  }
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
}