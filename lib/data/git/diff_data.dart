import '../../core/util/code_highlight.dart';
import '../../core/util/line_diff.dart';

/// 差异查看器的数据模型(对照上游 `presentation/component/DiffViewer.kt` 的 `DiffData`/`DiffRow`)。
class DiffData {
  const DiffData({
    required this.filePath,
    required this.oldRef,
    required this.newRef,
    this.rows = const [],
    this.addedCount = 0,
    this.removedCount = 0,
    this.isBinary = false,
    this.isLarge = false,
  });

  final String filePath;

  /// 对比左侧的引用(`HEAD` / `<hash>^` / `empty` / `worktree` / `index`)。
  final String oldRef;

  /// 对比右侧的引用。
  final String newRef;

  final List<DiffRow> rows;
  final int addedCount;
  final int removedCount;

  /// 二进制文件(含 NUL 字节):不做行级差异,只提示。
  final bool isBinary;

  /// 行数或单行长度超限,仅提示不渲染(避免主线程卡死)。
  final bool isLarge;
}

/// 差异中的一行:类型 + 原文 + 新旧行号(缺失侧为 null)+ 该行的高亮区间(行内偏移)。
class DiffRow {
  const DiffRow({
    required this.type,
    required this.text,
    this.oldLineNum,
    this.newLineNum,
    this.spans = const [],
  });

  final DiffLineType type;
  final String text;
  final int? oldLineNum;
  final int? newLineNum;

  /// 语法高亮区间;空表示纯文本渲染。
  final List<CodeHighlightSpan> spans;
}

/// 差异管线(对照上游 `GitViewModel.computeDiff`)。引用常量与上游一致。
class DiffPipeline {
  const DiffPipeline._();

  static const String refWorktree = 'worktree';
  static const String refIndex = 'index';
  static const String refEmpty = 'empty';

  /// 行数上限:超过即视为超大文件,不再逐行渲染。
  static const int maxDiffLines = 2000;

  /// 单行长度上限:压缩过的单行文件(min.js 等)会撑爆渲染。
  static const int maxDiffLineLength = 2000;

  /// 用旧/新文本算差异:二进制与超限降级,否则逐行比对、编新旧行号并切片高亮。
  static DiffData build({
    required String path,
    required String oldRef,
    required String newRef,
    required String oldContent,
    required String newContent,
    bool dark = false,
  }) {
    // 二进制检测:git show 对二进制文件返回乱码,直接看是否含 NUL。
    if (oldContent.contains('\u0000') || newContent.contains('\u0000')) {
      return DiffData(filePath: path, oldRef: oldRef, newRef: newRef, isBinary: true);
    }

    final oldLines = oldContent.split('\n');
    final newLines = newContent.split('\n');
    if (oldLines.length > maxDiffLines ||
        newLines.length > maxDiffLines ||
        oldLines.any((line) => line.length > maxDiffLineLength) ||
        newLines.any((line) => line.length > maxDiffLineLength)) {
      return DiffData(filePath: path, oldRef: oldRef, newRef: newRef, isLarge: true);
    }

    final language = syntaxLanguageFor(path);
    final oldSpans = highlightSpans(oldContent, language, dark: dark);
    final newSpans = highlightSpans(newContent, language, dark: dark);
    final oldOffsets = lineStartOffsets(oldContent);
    final newOffsets = lineStartOffsets(newContent);

    var oldNum = 0;
    var newNum = 0;
    final rows = <DiffRow>[];
    for (final line in LineDiff.diff(oldContent, newContent)) {
      switch (line.type) {
        case DiffLineType.context:
          oldNum++;
          newNum++;
          rows.add(DiffRow(
            type: line.type,
            text: line.text,
            oldLineNum: oldNum,
            newLineNum: newNum,
            // 上下文行两侧相同,用旧侧高亮切片。
            spans: _slice(oldSpans, oldOffsets, oldNum),
          ));
        case DiffLineType.remove:
          oldNum++;
          rows.add(DiffRow(
            type: line.type,
            text: line.text,
            oldLineNum: oldNum,
            spans: _slice(oldSpans, oldOffsets, oldNum),
          ));
        case DiffLineType.add:
          newNum++;
          rows.add(DiffRow(
            type: line.type,
            text: line.text,
            newLineNum: newNum,
            spans: _slice(newSpans, newOffsets, newNum),
          ));
      }
    }

    return DiffData(
      filePath: path,
      oldRef: oldRef,
      newRef: newRef,
      rows: rows,
      addedCount: rows.where((row) => row.type == DiffLineType.add).length,
      removedCount: rows.where((row) => row.type == DiffLineType.remove).length,
    );
  }

  /// 取第 [lineNum] 行(1 起)的高亮区间。
  static List<CodeHighlightSpan> _slice(
    List<CodeHighlightSpan> spans,
    List<int> offsets,
    int lineNum,
  ) {
    final index = lineNum - 1;
    if (index < 0 || index + 1 >= offsets.length) return const [];
    return sliceSpansForLine(spans, offsets[index], offsets[index + 1]);
  }
}