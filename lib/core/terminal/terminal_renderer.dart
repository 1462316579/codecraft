/// 终端渲染器：CustomPainter，将终端缓冲区绘制到 Flutter Canvas。
/// 参考 Termux TerminalRenderer.java。
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/painting.dart' as painting;

import 'text_style.dart';
import 'terminal_buffer.dart';
import 'terminal_colors.dart';
import 'terminal_emulator.dart';
import 'wc_width.dart';

enum TerminalCursorRenderStyle { block, underline, bar }

/// 终端字体配置
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

/// 终端渲染器：CustomPainter
class TerminalRenderer extends CustomPainter {
  final TerminalBuffer buffer;
  final TerminalFontConfig fontConfig;
  final Color foreground;
  final Color background;
  final Color cursorColor;
  final Color selectionColor;
  final TerminalCursorRenderStyle cursorRenderStyle;
  final bool cursorVisible;
  final bool cursorEnabled;
  final List<int>? selection;
  final double scrollOffset;
  final double fontScale;

  painting.TextStyle? _textStyleCache;
  double? _cellWidthCache;
  double? _cellHeightCache;

  TerminalRenderer({
    required this.buffer,
    required this.fontConfig,
    required this.foreground,
    required this.background,
    required this.cursorColor,
    required this.selectionColor,
    this.cursorRenderStyle = TerminalCursorRenderStyle.block,
    this.cursorVisible = true,
    this.cursorEnabled = true,
    this.selection,
    this.scrollOffset = 0.0,
    this.fontScale = 1.0,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (buffer.visibleCols <= 0 || buffer.visibleRows <= 0) return;

    _ensureTextStyle(size);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = background,
    );

    final cellWidth = _cellWidthCache ?? 10.0;
    final cellHeight = _cellHeightCache ?? 20.0;
    final cols = buffer.visibleCols;
    final rows = buffer.visibleRows;

    final startRow = (scrollOffset / cellHeight).floor().clamp(0, rows - 1);
    final endRow = ((scrollOffset + size.height) / cellHeight)
        .ceil()
        .clamp(0, rows);

    for (var row = startRow; row < endRow; row++) {
      final terminalRow = buffer.getLine(row);
      if (terminalRow == null) continue;

      final y = row * cellHeight - scrollOffset;
      if (y + cellHeight < 0 || y > size.height) continue;

      _drawSelectionBackground(canvas, row, y, cellWidth, cellHeight, size);

      var col = 0;
      while (col < cols) {
        final codePoint = terminalRow.getChar(col);
        final style = terminalRow.getStyle(col);

        if (TextStyle.isWideCharRight(style)) {
          col++;
          continue;
        }

        if (codePoint == 0x20 &&
            !TextStyle.isReverse(style) &&
            !TextStyle.isBold(style) &&
            !TextStyle.isUnderline(style)) {
          col++;
          continue;
        }

        final x = col * cellWidth;
        final width = WcWidth.wcwidth(codePoint);
        final drawWidth = width > 0 ? width * cellWidth : cellWidth;

        _drawChar(canvas, codePoint, style, x, y, drawWidth, cellHeight);

        col += width;
      }
    }

    if (cursorEnabled && cursorVisible) {
      _drawCursor(canvas, cellWidth, cellHeight, size);
    }
  }

  void _ensureTextStyle(ui.Size size) {
    if (_textStyleCache != null) return;
    _textStyleCache = painting.TextStyle(
      fontSize: fontConfig.fontSize * fontScale,
      fontFamily: fontConfig.fontFamily,
      color: foreground,
      height: fontConfig.height,
    );
    final textPainter = painting.TextPainter(
      text: TextSpan(text: 'W', style: _textStyleCache),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    final computedWidth = textPainter.width > 0 ? textPainter.width : 10.0;
    final computedHeight = textPainter.height > 0 ? textPainter.height : 20.0;
    _cellWidthCache = computedWidth * 1.1;
    _cellHeightCache = computedHeight * 1.2;
  }

  void _drawChar(
    ui.Canvas canvas,
    int codePoint,
    int style,
    double x,
    double y,
    double width,
    double height,
  ) {
    final char = String.fromCharCode(codePoint);

    final foreColor = TerminalColors.resolveForeground(
      style,
      foreground.value,
      background.value,
    );
    final backColor = TerminalColors.resolveBackground(
      style,
      foreground.value,
      background.value,
    );

    Color drawFore = Color(foreColor);
    Color drawBack = Color(backColor);
    if (TextStyle.isReverse(style)) {
      drawFore = Color(backColor);
      drawBack = Color(foreColor);
    }

    if (TextStyle.isConceal(style)) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = drawBack,
      );
      return;
    }

    final backIndex = TextStyle.decodeBackColor(style);
    if (backIndex != TextStyle.COLOR_INDEX_BACKGROUND ||
        TextStyle.isBackgroundTrueColor(style)) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = drawBack,
      );
    }

    final textSpan = TextSpan(
      text: char,
      style: painting.TextStyle(
        fontSize: (fontConfig.fontSize * fontScale).clamp(8, 72),
        fontFamily: fontConfig.fontFamily,
        color: drawFore,
        fontWeight: TextStyle.isBold(style)
            ? FontWeight.bold
            : FontWeight.normal,
        decoration: TextStyle.isUnderline(style)
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: drawFore,
        height: fontConfig.height,
      ),
    );

    final textPainter = painting.TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(minWidth: width, maxWidth: width);

    final textX = x + (width - textPainter.width) / 2;
    final textY = y + (height - textPainter.height) / 2 +
        textPainter.height * 0.75;

    textPainter.paint(canvas, Offset(textX, textY));

    if (TextStyle.isStrikethrough(style)) {
      canvas.drawLine(
        Offset(x, y + height / 2),
        Offset(x + width, y + height / 2),
        Paint()
          ..color = drawFore
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawSelectionBackground(
    ui.Canvas canvas,
    int row,
    double y,
    double cellWidth,
    double cellHeight,
    ui.Size size,
  ) {
    if (selection == null || selection!.length < 4) return;

    final selX1 = selection![0];
    final selY1 = selection![1];
    final selX2 = selection![2];
    final selY2 = selection![3];

    if (row < selY1 || row > selY2) return;

    final startCol = row == selY1 ? selX1 : 0;
    final endCol = row == selY2 ? selX2 + 1 : buffer.visibleCols;

    if (endCol <= startCol) return;

    final x = startCol * cellWidth;
    final w = (endCol - startCol) * cellWidth;

    canvas.drawRect(
      Rect.fromLTWH(x, y, w, cellHeight),
      Paint()..color = selectionColor,
    );
  }

  void _drawCursor(
    ui.Canvas canvas,
    double cellWidth,
    double cellHeight,
    ui.Size size,
  ) {
    final cx = buffer.cursorX;
    final cy = buffer.cursorY;

    if (cx < 0 || cx >= buffer.visibleCols || cy < 0 || cy >= buffer.visibleRows) {
      return;
    }

    final x = cx * cellWidth;
    final y = cy * cellHeight - scrollOffset;

    if (y + cellHeight < 0 || y > size.height) return;

    switch (cursorRenderStyle) {
      case TerminalCursorRenderStyle.block:
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellWidth, cellHeight),
          Paint()..color = cursorColor,
        );
        break;
      case TerminalCursorRenderStyle.underline:
        canvas.drawLine(
          Offset(x, y + cellHeight - 2),
          Offset(x + cellWidth, y + cellHeight - 2),
          Paint()..color = cursorColor..strokeWidth = 2.0,
        );
        break;
      case TerminalCursorRenderStyle.bar:
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + cellHeight),
          Paint()..color = cursorColor..strokeWidth = 2.0,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(TerminalRenderer oldDelegate) {
    return oldDelegate.buffer != buffer ||
        oldDelegate.fontConfig != fontConfig ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background ||
        oldDelegate.cursorColor != cursorColor ||
        oldDelegate.selectionColor != selectionColor ||
        oldDelegate.cursorRenderStyle != cursorRenderStyle ||
        oldDelegate.cursorVisible != cursorVisible ||
        oldDelegate.cursorEnabled != cursorEnabled ||
        oldDelegate.selection != selection ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.fontScale != fontScale;
  }
}

/// 终端控制器：管理 TerminalEmulator 的生命周期和输入输出
class TerminalController {
  final TerminalEmulator emulator;
  final TerminalBuffer buffer;
  void Function()? onScreenUpdated;
  final void Function(List<int> bytes)? onEmulatorOutput;

  TerminalController({
    required this.emulator,
    required this.buffer,
    this.onScreenUpdated,
    this.onEmulatorOutput,
  }) {
    emulator.onScreenUpdated = onScreenUpdated;
  }

  void write(List<int> bytes) {
    emulator.append(bytes);
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void writeString(String data) {
    write(utf8.encode(data));
  }

  void feedOutput(List<int> bytes) {
    emulator.append(bytes);
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void _forwardEmulatorOutput(List<int> bytes) {
    if (onEmulatorOutput != null) onEmulatorOutput!(bytes);
  }

  void resize(int columns, int rows) {
    emulator.resize(columns, rows);
  }

  List<int> drainOutput() => emulator.drainOutput();
}
