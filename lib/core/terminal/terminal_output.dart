/// 终端输出回调接口。
///
/// 由 [TerminalEmulator] 调用，将解析后的结果（写回 PTY 的字节、标题变更、
/// 铃声、剪贴板等）通知宿主。
abstract class TerminalOutput {
  /// 将 [data] 的 [offset..offset+count) 字节写回 PTY。
  void write(List<int> data, int offset, int count);

  /// 标题变更（OSC 0/2）。
  void titleChanged(String oldTitle, String newTitle);

  /// 复制文本到剪贴板（OSC 52）。
  void onCopyTextToClipboard(String text);

  /// 从剪贴板粘贴文本。
  void onPasteTextFromClipboard();

  /// 铃声（BEL）。
  void onBell();

  /// 颜色变更。
  void onColorsChanged();
}
