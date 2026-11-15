/// 终端核心模块导出。
library;

/// 终端引擎版本标识：显示在会话抽屉底部，用于确认手机上实际安装的构建。
const String kTerminalEngineTag = 'v3 · 2026-11-15';

export 'terminal_style.dart';
export 'wc_width.dart';
export 'terminal_row.dart';
export 'terminal_screen.dart';
export 'terminal_parser.dart';
export 'terminal_controller.dart';
export 'terminal_renderer.dart';
export 'terminal_view.dart';
