import '../../core/util/ids.dart';
import '../../data/db/daos.dart';
import '../models/todo_item.dart';
import 'tool.dart';

/// 管理 AI Agent 当前会话的任务清单(待办列表)。
///
/// 工具采用快照式接口:每次传入当前完整 items 列表,工具用它替换会话里的待办清单。
/// AI 不需要查询或记忆 todo_id,也不需要区分创建、更新、删除动作。
class TodoTool extends AgentTool {
  TodoTool(this._dao);

  final TodoDao _dao;

  /// items 数组中单个待办项的 JSON Schema。
  static const Map<String, dynamic> _itemSchema = {
    'type': 'object',
    'properties': {
      'subject': {'type': 'string', 'description': '简短的待办标题(祈使句,如「分析项目结构」)'},
      'description': {'type': 'string', 'description': '详细说明(可选)'},
      'status': {
        'type': 'string',
        'enum': ['pending', 'in_progress', 'completed'],
        'description': '状态,默认 pending。in_progress 表示正在处理,completed 表示已完成。',
      },
      'priority': {'type': 'integer', 'description': '优先级,0=普通,越大越优先'},
    },
    'required': ['subject'],
  };

  @override
  String get name => 'todo';

  @override
  String get description =>
      '用当前完整 items 列表替换会话任务清单。只需提交完整列表,'
      '无需 action、todo_id 或单项更新。items 可为空数组表示清空;每项为 '
      '{subject, description, status, priority}。status 可为 pending、in_progress、completed。';

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.modifyTodoState};

  @override
  Map<String, ToolParameter> get parameters => const {
        'items': ToolParameter(
          name: 'items',
          type: ParameterType.array,
          description: '当前完整待办列表。传空数组会清空任务清单;每项为含 subject 的对象。',
          itemsSchema: _itemSchema,
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    if (sessionId == null) return const ToolError('未关联会话', code: 'NO_SESSION');
    final rawItems = args['items'];
    if (rawItems is! List) {
      return const ToolError('缺少必需参数:items', code: 'MISSING_ITEMS');
    }
    try {
      return await _replaceTodos(rawItems, sessionId);
    } on FormatException catch (error) {
      return ToolError('待办操作失败:${error.message}');
    } catch (error) {
      return ToolError('待办操作失败:$error');
    }
  }

  /// 快照式替换:按「标题归一化」复用旧条目的 id 与创建时间,其余字段以本次提交为准。
  Future<ToolResult> _replaceTodos(List<dynamic> rawItems, String sessionId) async {
    final existing = <String, List<TodoItem>>{};
    for (final item in await _dao.listBySession(sessionId)) {
      existing.putIfAbsent(_normalizeSubject(item.subject), () => []).add(item);
    }
    final now = nowMs();
    final items = <TodoItem>[];
    for (var index = 0; index < rawItems.length; index++) {
      final draft = _parseDraft(rawItems[index], index);
      if (draft == null) {
        return ToolError(
          '第 ${index + 1} 项缺少字符串标题或 subject 字段',
          code: 'INVALID_ITEM',
        );
      }
      final bucket = existing[_normalizeSubject(draft.subject)];
      final previous = bucket == null || bucket.isEmpty ? null : bucket.removeAt(0);
      items.add(TodoItem(
        id: previous?.id ?? newId(),
        sessionId: sessionId,
        subject: draft.subject,
        description: draft.description,
        status: draft.status,
        priority: draft.priority,
        order: index,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      ));
    }
    await _dao.replaceAll(sessionId, items);
    return _listTodos(sessionId);
  }

  /// 替换后读回清单(对齐上游 listTodos 的字段与顺序)。
  Future<ToolResult> _listTodos(String sessionId) async {
    final items = await _dao.listBySession(sessionId);
    return ToolSuccess({
      'total': items.length,
      'completed': items.where((item) => item.status == TodoStatus.completed).length,
      'items': [
        for (final item in items)
          {
            'id': item.id,
            'subject': item.subject,
            'description': item.description,
            'status': item.status.wireName,
            'priority': item.priority,
            'order': item.order,
          },
      ],
    });
  }

  /// 单项解析:字符串(或数字/布尔)视为只有标题;对象取 subject/description/status/priority。
  /// 标题缺失返回 null;status 写法无效抛 [FormatException](沿用上游报错文案)。
  _TodoDraft? _parseDraft(Object? element, int index) {
    if (element is String || element is num || element is bool) {
      final subject = element.toString().trim();
      return subject.isEmpty ? null : _TodoDraft(subject: subject);
    }
    if (element is! Map) return null;
    final subject = _primitiveString(element['subject'])?.trim() ?? '';
    if (subject.isEmpty) return null;
    final status = TodoStatus.parse(_primitiveString(element['status']));
    if (status == null) throw FormatException('第 ${index + 1} 项 status 无效');
    final priority = element['priority'];
    return _TodoDraft(
      subject: subject,
      description: _primitiveString(element['description'])?.trim() ?? '',
      status: status,
      priority: priority is num ? priority.toInt() : int.tryParse('$priority') ?? 0,
    );
  }

  /// 形如上游 `jsonPrimitive.contentOrNull`:对象/数组取不到内容,返回 null。
  String? _primitiveString(Object? value) {
    if (value == null || value is Map || value is List) return null;
    return value.toString();
  }

  String _normalizeSubject(String subject) => subject.trim().toLowerCase();
}

class _TodoDraft {
  const _TodoDraft({
    required this.subject,
    this.description = '',
    this.status = TodoStatus.pending,
    this.priority = 0,
  });

  final String subject;
  final String description;
  final TodoStatus status;
  final int priority;
}