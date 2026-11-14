import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'command_engine.dart';
import 'pty_command_engine.dart';

/// 命令执行后端(当前为自研 PTY 终端，不依赖 Termux)。
final containerEngineProvider = Provider<PtyCommandEngine>((ref) {
  return PtyCommandEngine();
});
