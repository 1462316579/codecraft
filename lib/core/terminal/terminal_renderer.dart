import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/painting.dart' as painting;

import 'terminal_row.dart';
import 'terminal_screen.dart';
import 'terminal_style.dart';
import 'wc_width.dart';

enum TerminalCursorRenderStyle { block, underline, bar }

/// 终端字体配置。
class TerminalFontConfig {
  final double fontSize;
  final String fontFamily;
  final double height;

  const TerminalFontConfig({
    this.fontSize = 14.0,
    this.fontFamily = 'monospace',
    this.height = 1.35,
  });
}

/// 字体度量：单元格宽高（终端是按字符网格排布的）。
class TerminalFontMetrics {
  TerminalFontMetrics._();

  static Size cellSize(TerminalFontConfig config, {double scale = 1.0}) {
    final fontSize = config.fontSize * scale;
    final painter = painting.TextPainter(
      text: painting.TextSpan(
        text: 'M',
        style: painting.TextStyle(
          fontSize: fontSize,
          fontFamily: config.fontFamily,
          height: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    if (width <= 0) {
      // 字体尚未加载时的兜底，避免除零
      return Size(fontSize * 0.62, fontSize * config.height);
    }
    return Size(width, fontSize * config.height);
  }
}

/// 选区：行坐标与 [TerminalScreen.rowAt] 一致（负数代表历史行）。
class TerminalSelection {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  const TerminalSelection({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });
}

/// 终端绘制器。
///
/// 按「同一样式的连续字符」批量绘制文本，而不是逐字符创建 TextPainter，
/// 长输出时性能差距非常明显。
class TerminalRenderer extends CustomPainter {
  final TerminalScreen screen;
  final TerminalFontConfig fontConfig;
  final Color foreground;
  final Color background;
  final Color cursorColor;
  final Color selectionColor;
  final TerminalCursorRenderStyle cursorRenderStyle;
  final bool cursorVisible;
  final bool cursorEnabled;
  final int scrollOffset;
  final TerminalSelection? selection;
  final double fontScale;

  /// 构造时的内容版本号。必须存快照：新旧 delegate 引用同一个 screen 对象，
  /// 直接比较 `screen.version` 永远是相等，导致内容更新后不重绘。
  final int snapshotVersion;

  TerminalRenderer({
    required this.screen,
    required this.fontConfig,
    required this.foreground,
    required this.background,
    required this.cursorColor,
    required this.selectionColor,
    this.cursorRenderStyle = TerminalCursorRenderStyle.block,
    this.cursorVisible = true,
    this.cursorEnabled = true,
    this.scrollOffset = 0,
    this.selection,
    this.fontScale = 1.0,
  }) : snapshotVersion = screen.version;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final cell = TerminalFontMetrics.cellSize(fontConfig, scale: fontScale);
    final cellWidth = cell.width;
    final cellHeight = cell.height;
    if (cellWidth <= 0 || cellHeight <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final rows = screen.rows;
    for (var viewRow = -scrollOffset; viewRow < rows; viewRow++) {
      final y = (viewRow + scrollOffset) * cellHeight;
      if (y >= size.height) break;
      if (y + cellHeight <= 0) continue;
      final row = screen.rowAt(viewRow);
      if (row == null) continue;
      _paintSelection(canvas, viewRow, y, cellWidth, cellHeight);
      _paintRow(canvas, row, y, cellWidth, cellHeight);
    }

    if (cursorEnabled && cursorVisible && scrollOffset == 0) {
      _paintCursor(canvas, cellWidth, cellHeight, size);
    }

    canvas.restore();
  }

  void _paintRow(
    ui.Canvas canvas,
    TerminalRow row,
    double y,
    double cellWidth,
    double cellHeight,
  ) {
    final cols = row.columns;
    var col = 0;
    while (col < cols) {
      final attrs = row.getAttrs(col);
      if (CellAttr.has(attrs, CellAttr.wideTail)) {
        col++;
        continue;
      }
      final fg = row.getFg(col);
      final bg = row.getBg(col);
      final codePoint = row.getChar(col);
      final width = WcWidth.wcwidth(codePoint);
      if (width <= 0) {
        col++;
        continue;
      }
      if (width == 2) {
        _paintRun(
          canvas,
          String.fromCharCode(codePoint),
          col,
          y,
          2 * cellWidth,
          cellHeight,
          fg,
          bg,
          attrs,
          cellWidth,
        );
        col += 2;
        continue;
      }

      // 聚合样式相同的连续单宽字符
      final buffer = StringBuffer();
      var end = col;
      while (end < cols) {
        final otherAttrs = row.getAttrs(end);
        if (CellAttr.has(otherAttrs, CellAttr.wideTail)) break;
        if (row.getFg(end) != fg || row.getBg(end) != bg) break;
        if (otherAttrs != attrs) break;
        final other = row.getChar(end);
        if (WcWidth.wcwidth(other) != 1) break;
        buffer.writeCharCode(other);
        end++;
      }
      if (end == col) {
        col++;
        continue;
      }
      _paintRun(
        canvas,
        buffer.toString(),
        col,
        y,
        (end - col) * cellWidth,
        cellHeight,
        fg,
        bg,
        attrs,
        cellWidth,
      );
      col = end;
    }
  }

  void _paintRun(
    ui.Canvas canvas,
    String text,
    int col,
    double y,
    double width,
    double height,
    int fg,
    int bg,
    int attrs,
    double cellWidth,
  ) {
    if (text.isEmpty) return;
    final x = col * cellWidth;

    var fore = fg == kDefaultColor ? foreground : Color(0xFF000000 | fg);
    var back = bg == kDefaultColor ? background : Color(0xFF000000 | bg);
    if (CellAttr.has(attrs, CellAttr.reverse)) {
      final tmp = fore;
      fore = back;
      back = tmp;
    }
    if (CellAttr.has(attrs, CellAttr.hidden)) {
      fore = back;
    }
    if (CellAttr.has(attrs, CellAttr.faint)) {
      fore = fore.withValues(alpha: 0.6);
    }

    if (back != background) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = back,
      );
    }

    final hasVisibleText = text.trim().isNotEmpty ||
        CellAttr.has(attrs, CellAttr.underline) ||
        CellAttr.has(attrs, CellAttr.strike);
    if (!hasVisibleText) return;

    if (text.trim().isNotEmpty) {
      final painter = painting.TextPainter(
        text: painting.TextSpan(
          text: text,
          style: painting.TextStyle(
            fontSize: fontConfig.fontSize * fontScale,
            fontFamily: fontConfig.fontFamily,
            color: fore,
            height: fontConfig.height,
            fontWeight: CellAttr.has(attrs, CellAttr.bold)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: CellAttr.has(attrs, CellAttr.italic)
                ? FontStyle.italic
                : FontStyle.normal,
            decoration: CellAttr.has(attrs, CellAttr.underline)
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: fore,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout();
      painter.paint(canvas, Offset(x, y + (height - painter.height) / 2));
      painter.dispose();
    }

    if (CellAttr.has(attrs, CellAttr.strike)) {
      canvas.drawLine(
        Offset(x, y + height / 2),
        Offset(x + width, y + height / 2),
        Paint()
          ..color = fore
          ..strokeWidth = 1,
      );
    }
  }

  void _paintSelection(
    ui.Canvas canvas,
    int viewRow,
    double y,
    double cellWidth,
    double cellHeight,
  ) {
    final sel = selection;
    if (sel == null) return;
    final startRow = sel.startRow;
    final endRow = sel.endRow;
    if (viewRow < startRow || viewRow > endRow) return;

    var from = viewRow == startRow ? sel.startCol : 0;
    var to = viewRow == endRow ? sel.endCol + 1 : screen.columns;
    if (to <= from) return;
    if (from < 0) from = 0;
    if (to > screen.columns) to = screen.columns;

    canvas.drawRect(
      Rect.fromLTWH(from * cellWidth, y, (to - from) * cellWidth, cellHeight),
      Paint()..color = selectionColor,
    );
  }

  void _paintCursor(
    ui.Canvas canvas,
    double cellWidth,
    double cellHeight,
    ui.Size size,
  ) {
    final x = screen.cursorX * cellWidth;
    final y = screen.cursorY * cellHeight;
    if (x >= size.width || y >= size.height) return;

    switch (cursorRenderStyle) {
      case TerminalCursorRenderStyle.block:
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellWidth, cellHeight),
          Paint()..color = cursorColor.withValues(alpha: 0.75),
        );
        break;
      case TerminalCursorRenderStyle.underline:
        canvas.drawRect(
          Rect.fromLTWH(x, y + cellHeight - 2, cellWidth, 2),
          Paint()..color = cursorColor,
        );
        break;
      case TerminalCursorRenderStyle.bar:
        canvas.drawRect(
          Rect.fromLTWH(x, y, 2, cellHeight),
          Paint()..color = cursorColor,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(TerminalRenderer oldDelegate) {
    return oldDelegate.screen != screen ||
        oldDelegate.snapshotVersion != snapshotVersion ||
        oldDelegate.fontConfig != fontConfig ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background ||
        oldDelegate.cursorColor != cursorColor ||
        oldDelegate.selectionColor != selectionColor ||
        oldDelegate.cursorRenderStyle != cursorRenderStyle ||
        oldDelegate.cursorVisible != cursorVisible ||
        oldDelegate.cursorEnabled != cursorEnabled ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.selection != selection ||
        oldDelegate.fontScale != fontScale;
  }
}
