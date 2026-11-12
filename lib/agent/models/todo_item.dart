import 'dart:convert';

/// 待办项状态(对齐上游 TodoStatus);数据库与工具协议里沿用上游的写法。
enum TodoStatus {
  pending,
  inProgress,
  completed;

  /// 数据库存储写法(上游 Kotlin 枚举名)。
  String get storageName => switch (this) {
        TodoStatus.pending => 'PENDING',
        TodoStatus.inProgress => 'IN_PROGRESS',
        TodoStatus.completed => 'COMPLETED',
      };

  /// 工具结果里的写法(上游用 `status.lowercase()`)。
  String get wireName => switch (this) {
        TodoStatus.pending => 'pending',
        TodoStatus.inProgress => 'in_progress',
        TodoStatus.completed => 'completed',
      };

  /// 解析模型给出的状态:未提供(null)落下为 pending;空串或未知写法返回 null(上游视为无效)。
  static TodoStatus? parse(String? raw) {
    if (raw == null) return TodoStatus.pending;
    final normalized =
        raw.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
    for (final status in TodoStatus.values) {
      if (status.storageName == normalized) return status;
    }
    return null;
  }

  static TodoStatus fromStorage(String? raw) {
    for (final status in TodoStatus.values) {
      if (status.storageName == raw) return status;
    }
    return TodoStatus.pending;
  }
}

/// 会话内的一条待办(对齐上游 TodoItem)。
class TodoItem {
  const TodoItem({
    required this.id,
    required this.sessionId,
    required this.subject,
    this.description = '',
    this.status = TodoStatus.pending,
    this.priority = 0,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String subject;
  final String description;
  final TodoStatus status;
  final int priority;
  final int order;
  final int createdAt;
  final int updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'subject': subject,
        'description': description,
        'status': status.storageName,
        'priority': priority,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static TodoItem fromMap(Map<String, Object?> map) => TodoItem(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        subject: map['subject'] as String,
        description: (map['description'] as String?) ?? '',
        status: TodoStatus.fromStorage(map['status'] as String?),
        priority: (map['priority'] as int?) ?? 0,
        order: (map['order'] as int?) ?? 0,
        createdAt: (map['createdAt'] as int?) ?? 0,
        updatedAt: (map['updatedAt'] as int?) ?? 0,
      );

  TodoSnapshotItem toSnapshotItem() => TodoSnapshotItem(
        id: id,
        subject: subject,
        description: description,
        status: status,
        priority: priority,
        order: order,
      );
}

/// 工具结果里的一条待办(无会话与时间戳字段)。
class TodoSnapshotItem {
  const TodoSnapshotItem({
    required this.id,
    required this.subject,
    this.description = '',
    this.status = TodoStatus.pending,
    this.priority = 0,
    this.order = 0,
  });

  final String id;
  final String subject;
  final String description;
  final TodoStatus status;
  final int priority;
  final int order;
}

/// 一次 `todo` 工具调用后的清单快照(对齐上游 ParsedTodoResult)。
class TodoSnapshot {
  const TodoSnapshot({
    required this.total,
    required this.completed,
    required this.items,
  });

  final int total;
  final int completed;
  final List<TodoSnapshotItem> items;

  /// 从工具结果文本解析快照;解析失败返回 null,UI 回退到普通文本。
  static TodoSnapshot? parseToolResult(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return null;
      final status = decoded['status'];
      if (status == 'error') return null;
      final body = status == 'success' || status == 'partial' ? decoded['data'] : decoded;
      if (body is! Map) return null;
      final total = body['total'];
      final rawItems = body['items'];
      if (total is! num || rawItems is! List) return null;
      final items = <TodoSnapshotItem>[];
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final id = raw['id'];
        final subject = raw['subject'];
        if (id is! String || subject is! String) continue;
        items.add(TodoSnapshotItem(
          id: id,
          subject: subject,
          description: raw['description'] is String ? raw['description'] as String : '',
          status: TodoStatus.parse('${raw['status']}') ?? TodoStatus.pending,
          priority: raw['priority'] is num ? (raw['priority'] as num).toInt() : 0,
          order: raw['order'] is num ? (raw['order'] as num).toInt() : 0,
        ));
      }
      items.sort((a, b) => a.order.compareTo(b.order));
      return TodoSnapshot(
        total: total.toInt(),
        completed: body['completed'] is num ? (body['completed'] as num).toInt() : 0,
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}