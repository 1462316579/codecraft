/// 累积命令输出但限制内存占用:保留「开头 headLimit 个字符」与「结尾 tailLimit 个字符」,
/// 丢弃中间并标注省略了多少字符(对齐上游 BoundedOutput)。
///
/// 开头通常含命令意图与起始信息、结尾含错误与最终结果,二者对模型与用户最有价值;
/// 中间的海量重复输出(安装日志等)可安全省略。
class BoundedOutput {
  BoundedOutput({this.headLimit = defaultHead, this.tailLimit = defaultTail});

  static const int defaultHead = 20000;
  static const int defaultTail = 20000;

  final int headLimit;
  final int tailLimit;

  final StringBuffer _head = StringBuffer();
  final StringBuffer _tail = StringBuffer();
  int _total = 0;

  /// 已接收的原始字符总数(截断之前)。
  int get totalChars => _total;

  /// 是否发生了中间截断。
  bool get truncated => _total > _head.length + _tail.length;

  void append(String text) {
    if (text.isEmpty) return;
    _total += text.length;
    if (_head.length < headLimit) {
      final room = headLimit - _head.length;
      if (text.length <= room) {
        _head.write(text);
        return;
      }
      _head.write(text.substring(0, room));
      _appendTail(text.substring(room));
    } else {
      _appendTail(text);
    }
  }

  void _appendTail(String text) {
    _tail.write(text);
    if (_tail.length > tailLimit) {
      final overflow = _tail.length - tailLimit;
      final kept = _tail.toString().substring(overflow);
      _tail
        ..clear()
        ..write(kept);
    }
  }

  /// 组装最终文本:未截断即完整输出;截断时为 head + 省略提示 + tail。
  String build() {
    if (!truncated) return '${_head.toString()}${_tail.toString()}';
    final omitted = _total - _head.length - _tail.length;
    final head = _head.toString();
    final tail = _tail.toString();
    if (tail.isEmpty) {
      return '$head\n\n…[输出过长,已省略后续 $omitted 个字符]…';
    }
    return '$head\n\n…[输出过长,已省略中间 $omitted 个字符;仅保留开头与结尾]…\n\n$tail';
  }

  /// 只保留开头、到 [maxChars] 为止的硬上限模式(不插入中间省略提示,便于按行解析)。
  static BoundedOutput hardCapped(int maxChars) => BoundedOutput(headLimit: maxChars, tailLimit: 0);
}