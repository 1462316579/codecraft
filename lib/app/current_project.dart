import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/chat_session.dart';
import '../agent/models/project.dart';
import '../agent/projects_controller.dart';
import '../agent/sessions_controller.dart';

/// 当前打开的会话(侧栏据此高亮)。
final selectedSessionProvider = StateProvider<String?>((ref) => null);

/// 当前打开的项目:决定侧栏列哪一组会话、聊天页新建会话归到哪里。
final selectedProjectProvider = StateProvider<String?>((ref) => null);

/// 当前会话的工作模式(开发 / 写作)。
///
/// 优先取当前项目的 mode(项目决定模式,其下会话继承);
/// 没有打开项目时退回选中会话的 mode。
final currentAgentModeProvider = Provider<AgentMode>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project != null) return project.mode;
  final sessionId = ref.watch(selectedSessionProvider);
  if (sessionId == null) return AgentMode.build;
  final sessions = ref.watch(sessionsProvider).valueOrNull;
  if (sessions == null) return AgentMode.build;
  for (final session in sessions) {
    if (session.id == sessionId) return session.mode;
  }
  return AgentMode.build;
});

/// 当前项目。
///
/// 先按「选中的项目」解析;没有时退回「选中会话所属的项目」——冷启动直接进
/// 聊天页(或从通知进入)时选中项目为空,只看前者会让工作区判定退回默认值。
final currentProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).valueOrNull;
  if (projects == null) return null;

  Project? find(String? id) {
    if (id == null) return null;
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  final bySelection = find(ref.watch(selectedProjectProvider));
  if (bySelection != null) return bySelection;

  final sessionId = ref.watch(selectedSessionProvider);
  if (sessionId == null) return null;
  final sessions = ref.watch(sessionsProvider).valueOrNull;
  if (sessions == null) return null;
  for (final session in sessions) {
    if (session.id == sessionId) return find(session.projectId);
  }
  return null;
});