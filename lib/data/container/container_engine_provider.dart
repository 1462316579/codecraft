import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'command_engine.dart';
import 'termux_command_engine.dart';

/// 命令执行后端(当前为 Termux 直接执行，无容器)。
final containerEngineProvider =
    FutureProvider<CommandEngine>((ref) async {
  return await ref.watch(termuxEngineProvider.future);
});
