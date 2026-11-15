import 'dart:convert';

import 'terminal_parser.dart';
import 'terminal_screen.dart';

/// 终端控制器：把 PTY 字节流喂给解析器，并暴露屏幕模型给 UI。
class TerminalController {
  final TerminalScreen screen;
  final TerminalParser parser;

  /// 屏幕内容变化（需要重绘）时回调，由 UI 层设置。
  void Function()? onScreenUpdated;

  /// 解析器需要回写给 PTY 的应答（例如光标位置查询）。
  void Function(String data)? onResponse;

  late final ByteConversionSink _decoder;

  int _lastVersion = 0;

  TerminalController._(
    this.screen,
    this.parser, {
    this.onResponse,
  }) {
    _lastVersion = screen.version;
    _decoder = const Utf8Decoder(allowMalformed: true)
        .startChunkedConversion(_StringSink(parser.write));
  }

  factory TerminalController({
    int columns = 80,
    int rows = 24,
    int scrollback = 5000,
    void Function(String data)? onResponse,
    void Function(String title)? onTitle,
    void Function(String text)? onClipboard,
    void Function()? onBell,
    void Function()? onScreenUpdated,
  }) {
    final screen = TerminalScreen(
      columns: columns,
      rows: rows,
      scrollbackLimit: scrollback,
    );
    late final TerminalController instance;
    final parser = TerminalParser(
      screen,
      // 通过闭包转发，允许创建之后再补上 onResponse（PTY 要等控制器建好才有）
      onResponse: (data) => instance.onResponse?.call(data),
      onTitle: onTitle,
      onClipboard: onClipboard,
      onBell: onBell,
    );
    instance = TerminalController._(screen, parser, onResponse: onResponse);
    instance.onScreenUpdated = onScreenUpdated;
    return instance;
  }

  void feed(List<int> bytes) {
    _decoder.add(bytes);
    _notifyIfChanged();
  }

  /// 本地写字符串（不经 PTY，用于启动诊断信息）。
  void writeString(String data) {
    parser.write(data);
    _notifyIfChanged();
  }

  void resize(int columns, int rows) {
    screen.resize(columns, rows);
    _notifyIfChanged();
  }

  void clear() {
    screen.reset();
    _notifyIfChanged();
  }

  void _notifyIfChanged() {
    if (screen.version == _lastVersion) return;
    _lastVersion = screen.version;
    onScreenUpdated?.call();
  }
}

/// 把解码后的字符串转交给解析器。
class _StringSink implements Sink<String> {
  _StringSink(this._onText);

  final void Function(String text) _onText;

  @override
  void add(String data) => _onText(data);

  @override
  void close() {}
}
