import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agent/models/run_mode.dart';

/// 当前会话的权限运行模式。
final runModeProvider = StateProvider<AgentRunMode>((ref) => AgentRunMode.build);
