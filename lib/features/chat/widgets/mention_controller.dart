import 'dart:async';

import 'package:flutter/material.dart' show TextEditingController, TextEditingValue, TextSelection;

/// 输入框里 `@` 提及会话的状态机:触发 → 筛选 → 确认。
///
/// 触发条件(对齐上游 ChatInputBar 的 fileMentionQuery):光标前紧邻的 `@`,
/// 且 `@` 之前是行首或空白;`@` 到光标之间的文本是筛选词,**空格结束筛选**(去空格会打断词组)。
class MentionQuery {
  const MentionQuery({required this.anchor, required this.filter, required this.trigger});

  /// 触发字符(`@` 技能 / `#` 文件)在文本中的下标(删除时从这里整段撤掉)。
  final int anchor;

  /// 触发字符之后的筛选词(小写)。
  final String filter;

  /// 触发字符: `@` 为技能, `#` 为文件。
  final String trigger;

  /// 从文本与光标位置解析当前提及;不在提及会话中时返回 null。
  static MentionQuery? of(String text, int caret) {
    if (caret <= 0 || caret > text.length) return null;
    final at = text.lastIndexOf('@', caret - 1);
    final hash = text.lastIndexOf('#', caret - 1);
    // 取更近的触发符。
    final int idx;
    final String trigger;
    if (at > hash) {
      idx = at;
      trigger = '@';
    } else if (hash > at) {
      idx = hash;
      trigger = '#';
    } else {
      return null;
    }
    if (idx < 0) return null;
    // 触发符必须紧邻光标前这段文本(中间不能有空格,否则会话已结束)。
    final segment = text.substring(idx + 1, caret);
    if (segment.contains(' ') || segment.contains('\n')) return null;
    // 触发符之前必须是行首或空白,避免邮箱/Markdown 标题等误触。
    if (idx > 0) {
      final before = text[idx - 1];
      if (before != ' ' && before != '\n' && before != '\t') return null;
    }
    return MentionQuery(anchor: idx, filter: segment.toLowerCase(), trigger: trigger);
  }
}

/// 一次提及确认要写回输入框的内容。
class MentionInsertion {
  const MentionInsertion({required this.replacement, required this.newCaret});

  /// 替换 `@筛选词` 这段的文本(不含首尾空格,由调用方按需补)。
  final String replacement;

  /// 写回后的光标位置。
  final int newCaret;
}

/// 输入控制器上的提及扩展:解析当前会话、筛选、确认与整段撤销。
class MentionController {
  MentionController(this.input);

  final TextEditingController input;

  /// 当前提及会话;不在会话中返回 null。
  MentionQuery? current() => MentionQuery.of(input.value.text, input.selection.baseOffset);

  /// 确认提及:把 `@筛选词` 整段替换为 `@名字 `。
  ///
  /// [forceAnchor] 兜底「按钮预置 @ 但前缀不是空白」的场景——按钮触发不经过
  /// 「光标前是空白」的误触检查,确认时以预置的 anchor 为准;null 时按 current() 解析。
  Future<MentionInsertion?> confirm(String name, {int? forceAnchor, String? trigger}) async {
    final resolvedTrigger = trigger ??
        (forceAnchor != null
            ? (name.startsWith('#') ? '#' : '@')
            : (current()?.trigger ?? '@'));
    final query = forceAnchor != null
        ? MentionQuery(
            anchor: forceAnchor,
            filter: input.value.text
                .substring(forceAnchor + 1, input.selection.baseOffset)
                .toLowerCase(),
            trigger: resolvedTrigger,
          )
        : current();
    if (query == null) return null;
    final effectiveTrigger = query.trigger;
    final value = input.value;
    // 「所有主机」类前缀(`*`)不必转义;文件路径里的 `/`、`.`、`-` 都是安全字符。
    final token = '$effectiveTrigger$name';
    final before = value.text.substring(0, query.anchor);
    final after = value.text.substring(value.selection.baseOffset);
    final prefix = before.isEmpty || before.endsWith(' ') ? '' : ' ';
    final text = '$before$prefix$token $after';
    final caret = before.length + prefix.length + token.length + 1;
    input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );
    return MentionInsertion(replacement: token, newCaret: caret);
  }

  /// 撤销整个未完成的提及(含 `@` 与筛选词);无会话时不动作。
  void cancel() {
    final query = current();
    if (query == null) return;
    final value = input.value;
    final caret = value.selection.baseOffset;
    input.value = TextEditingValue(
      text: value.text.replaceRange(query.anchor, caret, ''),
      selection: TextSelection.collapsed(offset: query.anchor),
    );
  }
}

/// 防抖器:键盘快速输入时避免每敲一个字符都扫一遍文件树。
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 200)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

/// 让调用方把「输入框内容变化」转成提及状态的便捷钩子。
TextEditingValue trackMention(TextEditingValue value) => value;
