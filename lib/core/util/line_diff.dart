/// 逐行差异(对照上游 `core/util/LineDiff.kt`):LCS 动态规划求最长公共子序列后回溯产出
/// 上下文/新增/删除三类行,供差异查看器与提交信息生成使用。
class LineDiff {
  const LineDiff._();

  static List<DiffLine> diff(String oldText, String newText) {
    final a = oldText.split('\n');
    final b = newText.split('\n');
    final n = a.length;
    final m = b.length;

    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = a[i] == b[j]
            ? dp[i + 1][j + 1] + 1
            : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    final out = <DiffLine>[];
    var i = 0;
    var j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        out.add(DiffLine(DiffLineType.context, a[i]));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        out.add(DiffLine(DiffLineType.remove, a[i]));
        i++;
      } else {
        out.add(DiffLine(DiffLineType.add, b[j]));
        j++;
      }
    }
    while (i < n) {
      out.add(DiffLine(DiffLineType.remove, a[i]));
      i++;
    }
    while (j < m) {
      out.add(DiffLine(DiffLineType.add, b[j]));
      j++;
    }
    return out;
  }

  /// 统一差异文本(每行前缀 `+` / `-` / 空格),供 AI 生成提交信息等纯文本场景。
  static String toUnified(String oldText, String newText) =>
      diff(oldText, newText).map((line) {
        switch (line.type) {
          case DiffLineType.add:
            return '+${line.text}';
          case DiffLineType.remove:
            return '-${line.text}';
          case DiffLineType.context:
            return ' ${line.text}';
        }
      }).join('\n');
}

enum DiffLineType { add, remove, context }

class DiffLine {
  const DiffLine(this.type, this.text);

  final DiffLineType type;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DiffLine && other.type == type && other.text == text;

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => 'DiffLine($type, $text)';
}