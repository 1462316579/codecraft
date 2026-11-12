import 'dart:convert';

/// 工具参数类型(对齐上游 ParameterType)。
enum ParameterType { string, integer, boolean, array, object }

/// 工具参数(对齐上游 ToolParameter)。
class ToolParameter {
  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
    this.enumValues,
    this.itemsSchema,
  });

  final String name;
  final ParameterType type;
  final String description;
  final bool required;
  final List<String>? enumValues;

  /// 当 [type] 为 [ParameterType.array] 时,描述数组元素的 JSON Schema(原样并入
  /// function-calling 的 items 字段)。例如元素是对象时传
  /// `{"type":"object","properties":{...},"required":[...]}`。为空则兜底为字符串数组 schema
  /// 以满足 Gemini / OpenAPI 对 array 必须有 items 字段的要求。
  final Map<String, dynamic>? itemsSchema;
}

/// 一次工具调用(对齐上游 ToolCall)。
class ToolCall {
  const ToolCall({required this.id, required this.name, required this.arguments});

  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'arguments': arguments};

  static ToolCall? fromJson(Map<String, Object?> map) {
    final name = map['name'] as String?;
    if (name == null || name.isEmpty) return null;
    final rawArgs = map['arguments'];
    return ToolCall(
      id: (map['id'] as String?) ?? 'call',
      name: name,
      arguments: rawArgs is Map ? rawArgs.cast<String, dynamic>() : const {},
    );
  }

  static String encodeList(List<ToolCall> calls) =>
      jsonEncode(calls.map((c) => c.toJson()).toList());

  static List<ToolCall> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ToolCall.fromJson(m.cast<String, Object?>()))
          .whereType<ToolCall>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// 工具执行结果(对齐上游 ToolResult):以 `{status: success|error|partial, ...}` 回传给模型。
sealed class ToolResult {
  const ToolResult();

  String toTransportString();
}

class ToolSuccess extends ToolResult {
  const ToolSuccess(this.data);

  /// 工具结果负载:通常是结构化 map,MCP 等外部工具直接回传文本。
  final Object data;

  @override
  String toTransportString() => jsonEncode({'status': 'success', 'data': data});
}

class ToolError extends ToolResult {
  const ToolError(this.message, {this.code = 'UNKNOWN'});

  final String message;
  final String code;

  @override
  String toTransportString() =>
      jsonEncode({'status': 'error', 'message': message, 'code': code});
}

class ToolPartial extends ToolResult {
  const ToolPartial(this.data, this.message);

  final Map<String, dynamic> data;
  final String message;

  @override
  String toTransportString() =>
      jsonEncode({'status': 'partial', 'data': data, 'message': message});
}

/// 工具权限策略(对齐上游 ToolPermissionPolicy)。
enum ToolPermissionPolicy {
  /// 直接放行(只读类工具)。
  autoApprove,

  /// 需要用户确认(写类工具)。
  ask,
}

/// 工具能力(对齐上游 ToolCapability 的子集)。
enum ToolCapability {
  readWorkspace,
  writeWorkspace,
  networkRead,
  readAgentConfig,
  modifyTodoState,

  /// 通过 MCP 调用外部服务的工具。
  externalTool,

  /// 会修改 Agent 自身配置(MCP 服务列表等)。
  modifyAgentConfig,

  /// 在容器内执行 shell 命令。
  executeCommands,

  /// 会修改容器环境(安装包、改镜像配置等)。
  modifyContainerEnv,
}

/// 授权请求文案(对齐上游 PendingToolPermission 的标题/摘要/详情三段)。
class PermissionRequestText {
  const PermissionRequestText({
    required this.title,
    required this.summary,
    required this.details,
  });

  final String title;
  final String summary;
  final String details;
}

/// 一个可被模型调用的工具(对齐上游 AgentTool)。
abstract class AgentTool {
  String get name;
  String get description;
  Map<String, ToolParameter> get parameters;
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.autoApprove;
  Set<ToolCapability> get capabilities => const {};

  /// 生成 function-calling 用的 JSON Schema(OpenAI function.parameters / Anthropic input_schema)。
  Map<String, dynamic> toJsonSchema() {
    final properties = <String, dynamic>{};
    final required = <String>[];
    parameters.forEach((key, parameter) {
      final property = <String, dynamic>{
        'type': parameter.type.name,
        'description': parameter.description,
      };
      if (parameter.enumValues != null) property['enum'] = parameter.enumValues;
      if (parameter.type == ParameterType.array) {
        property['items'] = parameter.itemsSchema ?? {'type': 'string'};
      }
      properties[key] = property;
      if (parameter.required) required.add(key);
    });
    return {'type': 'object', 'properties': properties, 'required': required};
  }

  /// 授权弹窗文案;需要更具体的上下文(如 MCP 工具)时由工具覆写。
  PermissionRequestText permissionRequest(Map<String, dynamic> args, String argsPreview) =>
      PermissionRequestText(
        title: '确认执行工具',
        summary: 'AI 请求执行 $name',
        details: argsPreview,
      );

  /// 执行工具。参数为已解码的 JSON 对象;[sessionId] 供需要会话上下文的工具(如待办)使用。
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId});
}