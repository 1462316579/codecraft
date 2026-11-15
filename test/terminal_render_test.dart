import 'dart:ui' as ui;

import 'package:codecraft/core/terminal/terminal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('终端渲染器能把字符画到画布上', (tester) async {
    final controller = TerminalController(columns: 20, rows: 3);
    controller.writeString('HELLO\r\nWORLD');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    TerminalRenderer(
      screen: controller.screen,
      fontConfig: const TerminalFontConfig(fontSize: 14),
      foreground: const Color(0xFFD4D4D4),
      background: const Color(0xFF1E1E1E),
      cursorColor: const Color(0xFF00FF00),
      selectionColor: const Color(0xFF444444),
    ).paint(canvas, const Size(200, 60));

    var nonBackground = 0;
    await tester.runAsync(() async {
      final image = await recorder.endRecording().toImage(200, 60);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      for (var i = 0; i < data!.lengthInBytes; i += 4) {
        final r = data.getUint8(i);
        final g = data.getUint8(i + 1);
        final b = data.getUint8(i + 2);
        if (r != 0x1E || g != 0x1E || b != 0x1E) nonBackground++;
      }
    });
    // 两行文本 + 光标，非背景像素必然是一个可观的数量
    expect(nonBackground, greaterThan(50));
  });

  test('解析器写入文本后屏幕可读回', () {
    final controller = TerminalController(columns: 20, rows: 3);
    controller.writeString('abc\x1b[31mRED\x1b[0m\r\nsecond');
    final screen = controller.screen;
    expect(screen.rowAt(0)!.getText(0, 10), 'abcRED');
    expect(screen.rowAt(1)!.getText(0, 10), 'second');
    expect(screen.cursorY, 1);
    expect(screen.cursorX, 6);
  });

  test('resize 变大后内容保持在上方，光标不跳到底部', () {
    final controller = TerminalController(columns: 20, rows: 3);
    controller.writeString('one\r\ntwo');
    final screen = controller.screen;
    expect(screen.cursorY, 1);

    controller.resize(20, 10);
    expect(screen.rowAt(0)!.getText(0, 20), 'one');
    expect(screen.rowAt(1)!.getText(0, 20), 'two');
    expect(screen.cursorY, 1);
  });

  test('满屏滚动后历史可回看', () {
    final controller = TerminalController(columns: 10, rows: 3);
    for (var i = 0; i < 6; i++) {
      controller.writeString('line$i\r\n');
    }
    final screen = controller.screen;
    expect(screen.scrollbackLength, greaterThan(0));
    expect(screen.rowAt(0)!.getText(0, 10), 'line4');
    expect(screen.rowAt(-1)!.getText(0, 10), 'line3');
  });
}
