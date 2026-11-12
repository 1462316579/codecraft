import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/todo_item.dart';
import 'db/app_database.dart';
import 'db/daos.dart';

/// 会话待办清单;`todo` 工具执行后由控制器 invalidate 刷新。
final sessionTodosProvider = FutureProvider.family<List<TodoItem>, String>(
  (ref, sessionId) => ref.watch(databaseProvider).todoDao.listBySession(sessionId),
);