import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/blank_glyph.dart';
import '../core/util/ids.dart';
import '../data/db/app_database.dart';
import '../data/db/checkpoint_dao.dart';
import '../data/db/daos.dart';
import '../data/db/llm_call_records.dart';
import 'checkpoint_manager.dart';
import 'context_compactor.dart';
import '../app/current_project.dart';
import 'models/project.dart';
import 'projects_controller.dart';
import 'file_version_registry.dart';
import '../core/log/ai_logger.dart';
import '../core/log/file_logger.dart';
import '../core/log/log_store.dart';
import '../data/container/container_engine_provider.dart';
import '../data/workspace_files.dart';
import '../data/mcp/mcp_config.dart';
import '../data/mcp/mcp_manager.dart';
import '../data/permissions.dart';
import '../data/providers/provider_config.dart';
import '../data/providers/provider_store.dart';
import '../data/provider_keys.dart';
import 'models/run_mode.dart';
import '../data/run_mode_provider.dart';
import '../data/settings/app_settings.dart';
import '../data/terminal/terminal_manager.dart';
import '../data/settings/general_settings.dart';
import '../data/skills.dart';
import '../data/todos.dart';
import '../data/workspaces.dart';
import '../data/prompts.dart';
import 'models/agent_attachment.dart';
import 'models/agent_message.dart';
import 'models/agent_ui_state.dart';
import '../data/model_catalog.dart';
import '../data/model_metadata_store.dart';
import 'models/chat_session.dart';
import 'permissions/tool_permission_engine.dart';
import 'prompts.dart';
import 'protocols/errors.dart';
import 'protocols/http_transport.dart';
import 'protocols/llm_client.dart';
import 'protocols/llm_client_factory.dart';
import 'protocols/url_utils.dart';
import 'sessions_controller.dart';
import 'tools/command_tools.dart';
import 'tools/browser_tool.dart';
import 'tools/capture_tool.dart';
import 'tools/explorer_tools.dart';
import 'tools/file_tools.dart';
import 'tools/manage_mcp_tool.dart';
import 'tools/skill_tool.dart';
import 'tools/terminal_tool.dart';
import 'tools/todo_tool.dart';
import 'tools/tool.dart';

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, ChatViewState, String>(
  (ref, sessionId) => ChatController(ref, sessionId),
);

/// 协议层传输实现;测试中可覆盖为假实现。
final sseTransportProvider = Provider<SseTransport>((ref) => HttpTransport());

/// 一轮对话的编排:落库用户消息 → 循环「流式补全 → 执行工具 → 回放结果」→ 落库全部消息。
/// 单轮内最多执行 [ChatController.maxToolSteps] 步工具调用(对齐上游的循环上限语义)。
class ChatController extends StateNotifier<ChatViewState> {
  ChatController(this._ref, String sessionId) : super(ChatViewState(sessionId: sessionId)) {
    _load();
  }

  static const int maxToolSteps = 25;

  final Ref _ref;
  StreamSubscription<AiStreamChunk>? _subscription;

  /// 当前流式请求的取消令牌。
  ///
  /// 只靠取消订阅不足以中断连接:传输层是 `async*` 生成器,静默等待数据时
  /// 它不会响应订阅取消,底层 HTTP 请求会一直挂着。取消令牌直接打断这次请求。
  CancelToken? _cancelToken;

  /// 当前在等的流式调用;用户点停止时用它收尾,避免 completer 永不完成导致漏记统计。
  Completer<AiResponse?>? _pendingCallCompleter;

  /// 首条消息的 LLM 标题请求:延后到主请求收到首个内容(或本轮收尾)再发,
  /// 避免并发槽很少的本地模型让主请求在服务端排在标题请求之后(对齐上游 56386744)。
  void Function()? _pendingTitleRequest;

  void _startPendingTitle() {
    final start = _pendingTitleRequest;
    if (start == null) return;
    _pendingTitleRequest = null;
    start();
  }

  /// 标题生成请求的订阅:stop/dispose 时可取消。
  StreamSubscription<AiStreamChunk>? _titleSubscription;

  /// 子代理自主执行标志:运行期间工具调用自动放行(后台无 UI 可弹授权)。
  bool _autonomous = false;

  /// 被用户取消的那次调用的 generation(用于区分 cancelled 与正常结束)。
  int? _cancelledGeneration;
  int _generation = 0;
  bool _disposed = false;
  Completer<PermissionChoice>? _permissionCompleter;
  Map<String, AgentTool> _toolsByName = const {};

  String get _sessionId => state.sessionId!;

  /// 首次加载的消息条数上限(对齐上游 defaultLimit):超过则只加载最新的,其余向上补载。
  static const int initialMessageLimit = 50;

  Future<void> _load() async {
    final db = _ref.read(databaseProvider);
    final count = await db.messageDao.countBySession(_sessionId);
    final limit = count > initialMessageLimit ? initialMessageLimit : 0;
    final messages = await db.messageDao.listBySession(
      _sessionId,
      limit: limit == 0 ? null : limit,
    );
    if (_disposed) return;
    state = state.copyWith(
      messages: messages,
      loaded: true,
      messageLimit: limit,
      hasMore: limit > 0,
    );
  }

  /// 补载更早的消息(对齐上游 loadMoreMessages):步长取当前上限的一半,夹在 30 到 90
  /// 之间——一轮长过程折叠后可见项很少,定步长要补载很多次才能翻过它;单次步长封顶 90,
  /// 避免上限无界增长后单次补载越来越卡。到达全部历史后转为全量加载(limit 归 0)。
  Future<void> loadMoreMessages() async {
    final currentLimit = state.messageLimit;
    if (currentLimit <= 0 || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final db = _ref.read(databaseProvider);
    final count = await db.messageDao.countBySession(_sessionId);
    final newLimit = currentLimit + (currentLimit / 2).round().clamp(30, 90);
    final limit = newLimit >= count ? 0 : newLimit;
    final messages = await db.messageDao.listBySession(
      _sessionId,
      limit: limit == 0 ? null : limit,
    );
    if (_disposed) return;
    state = state.copyWith(
      messages: messages,
      messageLimit: limit,
      hasMore: limit > 0,
      isLoadingMore: false,
    );
  }

  /// 按当前分页上限重查消息(删除/回退后刷新用):保持已加载范围与 hasMore 语义,
  /// 删除后剩余不足上限时放宽为全量。
  Future<void> _reloadMessages() async {
    final db = _ref.read(databaseProvider);
    final count = await db.messageDao.countBySession(_sessionId);
    final limit = state.messageLimit > 0 && state.messageLimit < count ? state.messageLimit : 0;
    final messages = await db.messageDao.listBySession(
      _sessionId,
      limit: limit == 0 ? null : limit,
    );
    if (_disposed) return;
    state = state.copyWith(
      messages: messages,
      messageLimit: limit,
      hasMore: limit > 0,
    );
  }

  /// 本轮可用工具:每次发送时按当前工作区构建(工具直接可用,无需缓存)。
  /// MCP 工具来自已连接的 server;未连上的会在后台补一次重连,不阻塞本轮发送。
  /// [session] 为父会话时注册 task(子代理不可嵌套派发,对齐上游 NESTED_TOOL 剔除)。
  List<AgentTool> _toolsForCurrentWorkspace(ChatSession session) {
    final workspace = _ref.read(currentWorkspaceProvider);
    final mcpManager = _ref.read(mcpManagerProvider.notifier);
    mcpManager.reconnectUnconnectedAsync();
    // 文件工具走宿主 File API:本地容器的工作区是 bind 挂载,宿主路径与容器内一致。
    Future<WorkspaceFiles> files() => _ref.read(workspaceFilesProvider.future);
    // 写作项目的工作区是外部目录,容器里看不到,也不该起容器:不给命令工具。
    final projectKind = _ref.read(currentProjectProvider)?.kind;
    final writing = projectKind == ProjectKind.writing;
    final tools = <AgentTool>[
      ReadFileTool(workspace, files),
      WriteFileTool(workspace, files),
      EditFileTool(workspace, files),
      ListTool(workspace, files),
      SearchTool(workspace, files),
      TodoTool(_ref.read(databaseProvider).todoDao),
      LoadSkillTool(_ref.read(skillsStoreProvider)),
      ManageMcpTool(_ref.read(mcpConfigRepositoryProvider)),
      if (!writing)
        // 命令同时镜像到终端标签:用户在终端页能看到 AI 实际跑了什么、输出了什么。
        BashTool(
          engine: () async => _ref.read(containerEngineProvider),
          workdir: workspace.rootPath,
          onStart: (command) => _ref
              .read(terminalTabsProvider.notifier)
              .mirrorCommand(_ref.read(appGlobalizationsProvider).terminalAgentTab, command),
          onFinish: (output, exitCode) => _ref
              .read(terminalTabsProvider.notifier)
              .mirrorOutput(output, exitCode: exitCode),
        ),
      if (!writing) TerminalTool(_ref),
      if (projectKind == ProjectKind.coding || projectKind == ProjectKind.reverse)
        CaptureTool(_ref),
      BrowserTool(_ref),
      ...mcpManager.activeTools,
    ];
    _toolsByName = {for (final tool in tools) tool.name: tool};
    return tools;
  }

  /// 系统提示词:静态基线片段 + 项目类型场景提示词 + 会话模式段落 + 技能清单。
  Future<String> _systemPrompt(ChatSession session) async {
    // 项目类型决定场景提示词(写作 / 编程 / 应用逆向),注入前先解析。
    final projectKind = await _projectKind(session);
    final catalog = _ref.read(promptCatalogProvider);
    final projectRoot = _ref.read(currentWorkspaceProvider).rootPath;
    final builtinIndex = await loadBuiltinPromptIndex();
    final scenario = loadScenarioPrompt(catalog, projectKind);
    try {
      return buildSystemPrompt(
        catalog: catalog,
        projectRoot: projectRoot,
        skills: await _ref.read(skillsStoreProvider).listEnabled(),
        mode: session.mode,
        builtinIndex: builtinIndex,
        scenarioPrompt: scenario,
      );
    } catch (_) {
      return buildSystemPrompt(
        catalog: catalog,
        projectRoot: projectRoot,
        skills: [],
        mode: session.mode,
        builtinIndex: builtinIndex,
        scenarioPrompt: scenario,
      );
    }
  }

  /// 会话所属项目的类型;取不到时按普通项目处理。
  Future<ProjectKind?> _projectKind(ChatSession session) async {
    final projectId = session.projectId;
    if (projectId == null || projectId.isEmpty) return null;
    try {
      return (await _ref.read(projectByIdProvider(projectId).future))?.kind;
    } catch (_) {
      return null;
    }
  }

  /// 粗略估算输入 token:中文按 1 字 ≈ 1 token、其余按 4 字符 ≈ 1 token。
  static int _approxInputTokens(List<AgentMessage> messages, String pending) {
    var chars = pending.length;
    var cjk = pending.runes.where((rune) => rune > 0x2E80).length;
    for (final message in messages) {
      chars += message.content.length;
      cjk += message.content.runes.where((rune) => rune > 0x2E80).length;
    }
    return cjk + (chars - cjk) ~/ 4;
  }

  /// 发送一条消息。
  ///
  /// 返回**是否已接受**:false 表示被拒绝(空内容、正在生成、无供应商/无模型、会话不存在)。
  /// 接受即表示用户消息已落库、本轮已进入执行态——**调用方此时就该清空输入框**,
  /// 不要等整轮对话结束(对齐上游 `sendMessage`:先 `enqueueAgentRequest` 再同步 `clearInputDraft`)。
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    final attachments = state.pendingAttachments;
    if ((trimmed.isEmpty && attachments.isEmpty) || state.streaming) return false;

    final db = _ref.read(databaseProvider);
    final session = await db.sessionDao.get(_sessionId);
    if (session == null) return false;

    final providers = await _providerList();
    var provider = _pickProvider(providers, session);
    if (provider == null) {
      state = state.copyWith(errorCode: () => ChatErrorCode.noProvider);
      return false;
    }
    var model = (session.model?.trim().isNotEmpty == true
            ? session.model!
            : provider.effectiveModel)
        .trim();
    if (model.isEmpty) {
      state = state.copyWith(errorCode: () => ChatErrorCode.noModel);
      return false;
    }

    // 图片随图片块发给模型,正文里只列文件附件(对齐上游 vision 分支的 promptAttachments)。
    final content = appendAttachmentsToRequest(
      trimmed,
      attachments.where((attachment) => !attachment.isImage).toList(),
      _ref.read(appGlobalizationsProvider).attachmentPrefix,
    );
    final userMessage = AgentMessage(
      id: newId(),
      sessionId: _sessionId,
      role: MessageRole.user,
      content: content,
      timestamp: nowMs(),
      attachmentsJson: attachments.isEmpty ? null : AgentAttachment.encodeList(attachments),
    );
    await db.messageDao.insert(userMessage);

    // 检查点:记录这条用户消息发出前的工作区状态,供「回退到此处」使用。
    try {
      final checkpointManager = await _ref.read(checkpointManagerProvider.future);
      await checkpointManager.createCheckpoint(
        sessionId: _sessionId,
        userMessageId: userMessage.id,
        prompt: trimmed.isNotEmpty ? trimmed : attachments.first.fileName,
      );
    } catch (error) {
      // 建不上检查点不该拦住这次发送:只是这次无法回退代码。
      unawaited(_ref
          .read(fileLoggerProvider.future)
          .then((logger) => logger.w('Checkpoint', '创建检查点失败: $error'))
          .catchError((_) {}));
    }

    if (session.title.trim().isEmpty) {
      final title = trimmed.isNotEmpty
          ? titleFromText(trimmed)
          : titleFromText(attachments.first.fileName, max: 20);
      await db.sessionDao.upsert(session.copyWith(title: title, updatedAt: nowMs()));
      _ref.invalidate(sessionsProvider);
      // LLM 标题请求延后到主请求产出首个内容(或本轮收尾)再发(见 _startPendingTitle)。
      final titleSource = trimmed.isNotEmpty ? trimmed : attachments.first.fileName;
      _pendingTitleRequest = () => unawaited(_generateTitle(session, titleSource));
    }

    final history = _replayHistory([...state.messages, userMessage]);
    final generation = ++_generation;
    final tools = _toolsForCurrentWorkspace(session);

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      pendingAttachments: const [],
      streaming: true,
      streamingText: '',
      streamingReasoning: '',
      retry: () => null,
      errorCode: () => null,
      errorDetail: () => null,
    );

    // 执行不阻塞返回值:`_runLoop` 内部的流式订阅已由 controller 自己管理(stop 走 _subscription),
    // 这里 `unawaited` 让 send 立即返回,输入框才能在消息发出的瞬间清空。
    // 之前 `await` 到整轮结束,导致输入框要等对话跑完才清空。
    // 兜底:不 await 之后,_runLoop 抛出的异常不会再有调用方接收,必须自己收口,
    // 否则会变成未捕获异常(进程级错误)而不是界面上的错误提示。
    unawaited(
      _runLoop(
        generation,
        session,
        provider,
        model,
        history,
        tools,
        await _systemPrompt(session),
      ).catchError((Object error) {
        if (_disposed) return;
        state = state.copyWith(
          streaming: false,
          errorCode: () => ChatErrorCode.generic,
          errorDetail: () => '$error',
        );
        AppLog.e('Chat', '对话循环异常:$error');
      }),
    );
    return true;
  }

  /// 工具循环:流式补全 → 若有工具调用则逐个执行并回放 → 继续下一轮,直到无工具调用或达到步数上限。
  Future<void> _runLoop(
    int generation,
    ChatSession session,
    ProviderConfig provider,
    String model,
    List<AgentMessage> history,
    List<AgentTool> tools,
    String systemPrompt,
  ) async {
    // 自动压缩:首轮请求前估算上下文,超触发线时把早期历史摘要成接手摘要
    // (对齐上游自动压缩;失败保留原历史,本轮继续)。
    history = await _compactHistoryIfNeeded(
      session: session,
      provider: provider,
      model: model,
      history: history,
      tools: tools,
      systemPrompt: systemPrompt,
    );
    var step = 0;
    while (step < maxToolSteps) {
      if (generation != _generation || _disposed) return;
      step++;

      final buffer = StringBuffer();
      final reasoningBuffer = StringBuffer();
      state = state.copyWith(
        streaming: true,
        streamingText: '',
        streamingReasoning: '',
        retry: () => null,
      );

      final response = await _streamOnce(
        generation,
        session,
        provider,
        model,
        history,
        tools,
        systemPrompt,
        buffer,
        reasoningBuffer,
      );
      if (response == null) {
        // 中断/出错时已经流下来的内容不能丢:落库保留,用户至少能看到拿到了什么。
        final partial = buffer.toString().replaceAll(RegExp(r'\s+$'), '');
        final partialReasoning = reasoningBuffer.toString();
        if (generation == _generation &&
            !_disposed &&
            hasVisibleContent(partial)) {
          final message = AgentMessage(
            id: newId(),
            sessionId: _sessionId,
            role: MessageRole.assistant,
            content: partial,
            timestamp: nowMs(),
            reasoning: partialReasoning.isEmpty ? null : partialReasoning,
          );
          try {
            await _ref.read(databaseProvider).messageDao.insert(message);
            if (!_disposed) {
              state = state.copyWith(messages: [...state.messages, message]);
            }
          } catch (error) {
            AppLog.w('Chat', '保存被中断的部分回复失败:$error');
          }
        }
        // 错误与取消各自已在对应路径收尾;这里再兜一层,
        // 保证任何遗漏都不会让界面停在「正在思考」。
        if (generation == _generation && !_disposed && state.streaming) {
          state = state.copyWith(streaming: false, streamingText: '', streamingReasoning: '');
        }
        return;
      }

      final hasContent = hasVisibleContent(response.content);
      final reasoning = reasoningBuffer.toString();
      final assistant = AgentMessage(
        id: newId(),
        sessionId: _sessionId,
        role: MessageRole.assistant,
        content: hasContent ? response.content : '',
        timestamp: nowMs(),
        reasoning: reasoning.isEmpty ? null : reasoning,
        toolCallsJson:
            response.toolCalls.isEmpty ? null : ToolCall.encodeList(response.toolCalls),
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
        cachedInputTokens: response.cachedInputTokens,
      );

      if (hasContent || response.toolCalls.isNotEmpty || reasoning.isNotEmpty) {
        final db = _ref.read(databaseProvider);
        await db.messageDao.insert(assistant);
        if (_disposed) return;
        state = state.copyWith(messages: [...state.messages, assistant]);
      } else if (response.toolCalls.isEmpty) {
        state = state.copyWith(
          streaming: false,
          streamingText: '',
          streamingReasoning: '',
          errorCode: () => ChatErrorCode.emptyResponse,
        );
        return;
      }

      // 本轮用量并入会话统计
      final db = _ref.read(databaseProvider);
      final latest = await db.sessionDao.get(_sessionId) ?? session;
      await db.sessionDao.upsert(latest.copyWith(
        updatedAt: nowMs(),
        totalInputTokens: latest.totalInputTokens + response.inputTokens,
        totalOutputTokens: latest.totalOutputTokens + response.outputTokens,
        lastInputTokens: response.inputTokens,
      ));
      _ref.invalidate(sessionsProvider);

      if (response.toolCalls.isEmpty) {
        state = state.copyWith(
          streaming: false,
          streamingText: '',
          streamingReasoning: '',
          retry: () => null,
        );
        return;
      }

      history = [...history, assistant];
      final toolMessages = await _executeTools(generation, session, response.toolCalls);
      if (toolMessages == null) return;
      if (_disposed) return;
      state = state.copyWith(messages: [...state.messages, ...toolMessages]);
      history = [...history, ...toolMessages];
    }

    state = state.copyWith(
      streaming: false,
      streamingText: '',
      streamingReasoning: '',
      errorCode: () => ChatErrorCode.generic,
      errorDetail: () => '达到工具调用步数上限($maxToolSteps)',
    );
  }

  /// 单次流式补全,返回聚合结果;错误与取消返回 null(状态已设置)。
  Future<AiResponse?> _streamOnce(
    int generation,
    ChatSession session,
    ProviderConfig provider,
    String model,
    List<AgentMessage> history,
    List<AgentTool> tools,
    String systemPrompt,
    StringBuffer buffer,
    StringBuffer reasoningBuffer,
  ) async {
    // 多 Key:本次请求用哪把 Key(顺序取第一个未冷却 / 轮询按会话粘住)。
    final rotator = _ref.read(keyRotatorProvider);
    final picked = rotator.pick(provider, _sessionId);
    final apiKey = picked.isEmpty ? provider.apiKey : picked;
    final general = _ref.read(generalSettingsProvider);
    final client = createLlmClient(
      type: provider.type,
      transport: _ref.read(sseTransportProvider),
      config: LlmClientConfig(
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: model,
        useFullUrl: provider.useFullUrl,
        temperature: fixedTemperature(model),
        // 超时 0 秒 = 不限制(传 null 即不设超时)。
        firstByteTimeout: general.firstByteTimeoutSec <= 0
            ? null
            : Duration(seconds: general.firstByteTimeoutSec),
        idleTimeout: general.streamIdleTimeoutSec <= 0
            ? null
            : Duration(seconds: general.streamIdleTimeoutSec),
        maxRetries: general.maxNetworkRetries,
        customHeaders: provider.resolvedHeaders(sessionId: _sessionId),
      ),
    );

    final completer = Completer<AiResponse?>();
    // 埋点:首字延迟/总耗时/重试次数/成败,结束后写入 llm_call_records 供 Token 统计页使用。
    final stopwatch = Stopwatch()..start();
    int? ttfbMillis;
    var retryCount = 0;
    String? errorMessage;
    // 上游在 finally 里无条件落库,取消也要记一条(status = cancelled)。
    var cancelled = false;
    // AI 请求日志按会话归档:流式期间把会话 id 放进环境值,传输层据此落盘。
    AiLog.currentSessionId = _sessionId;
    AppLog.i('Chat', '开始流式请求 session=$_sessionId model=$model');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    _subscription = client
        .completeStream(
      systemPrompt: systemPrompt,
      messages: history,
      tools: tools,
      effort: session.reasoningEffort,
      cancelToken: cancelToken,
    )
        .listen(
      (chunk) {
        // 取消后不再更新 UI,但仍要收下 FinalChunk 的 usage 用于统计。
        if (generation != _generation || _disposed) return;
        switch (chunk) {
          case TextDelta(:final text):
            _startPendingTitle();
            ttfbMillis ??= stopwatch.elapsedMilliseconds;
            buffer.write(text);
            state = state.copyWith(streamingText: buffer.toString());
          case ReasoningDelta(:final text):
            _startPendingTitle();
            reasoningBuffer.write(text);
            state = state.copyWith(streamingReasoning: reasoningBuffer.toString());
          case Retrying(:final attempt, :final maxRetries, :final error):
            retryCount = attempt;
            state = state.copyWith(
              retry: () => RetryState(attempt: attempt, maxRetries: maxRetries, error: error),
            );
          case FinalChunk(:final response):
            if (!completer.isCompleted) completer.complete(response);
        }
      },
      onError: (Object error) {
        // 多 Key:命中切换状态码就把这把 Key 打入冷却,下次发送自动换下一把。
        if (error is LlmHttpException) {
          rotator.reportStatus(provider, apiKey, error.statusCode);
        }
        if (generation != _generation || _disposed) return;
        errorMessage = describeError(error);
        state = state.copyWith(
          streaming: false,
          errorCode: () => ChatErrorCode.generic,
          errorDetail: () => errorMessage,
          retry: () => null,
        );
        if (!completer.isCompleted) completer.complete(null);
      },
      onDone: () {
        AiLog.currentSessionId = null;
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    // 用户点停止会先 cancel 订阅,onDone 不会触发,completer 将永远不完成;
    // 这里在取消时主动收尾,保证这一笔调用能进统计(对齐上游 cancelled 口径)。
    _pendingCallCompleter = completer;
    final response = await completer.future;
    _pendingCallCompleter = null;
    // 标题请求兜底:本轮没产出任何内容事件(如空响应)时随本轮收尾发起。
    _startPendingTitle();
    stopwatch.stop();
    cancelled = _cancelledGeneration == generation;
    // 流在没给出收尾块的情况下结束了(连接被中断、服务端没发 [DONE]、解析提前收尾等)。
    // 这条路径既不走 onError 也不走 stop(),若不在这里收尾,
    // streaming 会一直是 true——界面就永远停在「正在思考」。
    if (response == null &&
        !cancelled &&
        errorMessage == null &&
        !_disposed &&
        generation == _generation) {
      errorMessage = '响应中断:连接已结束但没有收到完整结果';
      state = state.copyWith(
        streaming: false,
        streamingText: '',
        streamingReasoning: '',
        retry: () => null,
        errorCode: () => ChatErrorCode.generic,
        errorDetail: () => errorMessage,
      );
    }
    await _recordLlmCall(
      session: session,
      provider: provider,
      model: model,
      response: response,
      ttfbMillis: ttfbMillis,
      durationMillis: stopwatch.elapsedMilliseconds,
      retryCount: retryCount,
      errorMessage: errorMessage,
      cancelled: cancelled,
    );
    return response;
  }

  /// 写一条 LLM 调用记录(对齐上游在 workflow 主循环的埋点口径)。
  Future<void> _recordLlmCall({
    required ChatSession session,
    required ProviderConfig provider,
    required String model,
    required AiResponse? response,
    required int? ttfbMillis,
    required int durationMillis,
    required int retryCount,
    String? errorMessage,
    bool cancelled = false,
    String kind = 'chat',
  }) async {
    try {
      await _ref.read(databaseProvider).llmCallDao.insert(
            LlmCallRecord(
              sessionId: _sessionId,
              providerId: provider.id,
              model: model,
              reasoningEffort: session.reasoningEffort.apiValue,
              kind: kind,
              inputTokens: response?.inputTokens ?? 0,
              outputTokens: response?.outputTokens ?? 0,
              cachedInputTokens: response?.cachedInputTokens ?? 0,
              cacheCreationTokens: response?.cacheCreationTokens ?? 0,
              ttfbMillis: ttfbMillis,
              durationMillis: durationMillis,
              // 三态对齐上游:completed → success,有错误 → error,否则 → cancelled。
              status: cancelled
                  ? 'cancelled'
                  : (errorMessage == null ? 'success' : 'error'),
              errorMessage: errorMessage,
              stopReason: response?.stopReason,
              retryCount: retryCount,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } catch (_) {
      // 统计埋点失败不能影响对话主流程。
    }
  }

  /// 自动压缩入口(对齐上游 workflow 的压缩挂载点):每轮工具循环开始前估算,
  /// 超触发线则压缩。压缩期间状态行提示;无论成败都返回可用历史。
  Future<List<AgentMessage>> _compactHistoryIfNeeded({
    required ChatSession session,
    required ProviderConfig provider,
    required String model,
    required List<AgentMessage> history,
    required List<AgentTool> tools,
    required String systemPrompt,
  }) async {
    try {
      final db = _ref.read(databaseProvider);
      final sessionRow = await db.sessionDao.get(_sessionId);
      final currentInputTokens = sessionRow?.lastInputTokens ?? 0;
      final compactor = ContextCompactor(
        database: db,
        catalog: await _ref.read(modelCatalogProvider.future),
        customMetadata: await _ref.read(customModelMetadataProvider.future),
        compactionThresholdPercent: _ref.read(generalSettingsProvider).compactionThresholdPercent,
        summaryPromptTemplate: await rootBundle.loadString(
          'assets/prompts/agent/compact-summary.md',
        ),
        summarize: (systemPrompt, request, maxOutputTokens) => _summarizeForCompaction(
          session,
          provider,
          model,
          systemPrompt,
          request,
          maxOutputTokens,
        ),
      );
      state = state.copyWith(compacting: true);
      try {
        final result = await compactor.compactIfNeeded(
          messages: history,
          provider: provider,
          model: model,
          sessionId: _sessionId,
          systemPrompt: systemPrompt,
          tools: tools,
          currentInputTokens: currentInputTokens,
        );
        if (!result.compacted) return history;
        // 落库已在压缩器内完成(head 标记 + marker/摘要插入);UI 重查展示。
        await _reloadMessages();
        return result.messages;
      } finally {
        if (!_disposed) state = state.copyWith(compacting: false);
      }
    } catch (error) {
      AppLog.w('Chat', '自动压缩跳过:$error');
      return history;
    }
  }

  /// 压缩摘要调用(对齐上游 summarize):跟随主模型与 Key 轮转口径,输出上限由
  /// 压缩器给定;结果非空、无工具调用、未截断才接受,失败抛异常由压缩器兜底。
  Future<String> _summarizeForCompaction(
    ChatSession session,
    ProviderConfig provider,
    String model,
    String systemPrompt,
    List<AgentMessage> request,
    int maxOutputTokens,
  ) async {
    final stopwatch = Stopwatch()..start();
    AiResponse? response;
    String? error;
    try {
      final rotator = _ref.read(keyRotatorProvider);
      final picked = rotator.pick(provider, _sessionId);
      final apiKey = picked.isEmpty ? provider.apiKey : picked;
      final general = _ref.read(generalSettingsProvider);
      final client = createLlmClient(
        type: provider.type,
        transport: _ref.read(sseTransportProvider),
        config: LlmClientConfig(
          apiKey: apiKey,
          baseUrl: provider.baseUrl,
          model: model,
          useFullUrl: provider.useFullUrl,
          temperature: fixedTemperature(model),
          firstByteTimeout: general.firstByteTimeoutSec <= 0
              ? null
              : Duration(seconds: general.firstByteTimeoutSec),
          idleTimeout: general.streamIdleTimeoutSec <= 0
              ? null
              : Duration(seconds: general.streamIdleTimeoutSec),
          maxRetries: general.maxNetworkRetries,
          maxOutputTokens: maxOutputTokens,
          customHeaders: provider.resolvedHeaders(sessionId: _sessionId),
        ),
      );
      final buffer = StringBuffer();
      await for (final chunk in client.completeStream(
        systemPrompt: systemPrompt,
        messages: request,
        tools: const [],
      )) {
        if (chunk is TextDelta) buffer.write(chunk.text);
        if (chunk is FinalChunk) response = chunk.response;
      }
      final content = buffer.toString();
      if (content.trim().isEmpty ||
          (response?.toolCalls ?? const <ToolCall>[]).isNotEmpty ||
          response?.stopReason == 'max_tokens' ||
          response?.stopReason == 'length' ||
          response?.stopReason == 'MAX_TOKENS') {
        throw StateError('Incomplete summary response: ${response?.stopReason ?? "empty"}');
      }
      return content;
    } catch (e) {
      error = '$e';
      rethrow;
    } finally {
      // 压缩调用单独记一条统计(kind=compaction),不混入对话口径。
      await _recordLlmCall(
        session: session,
        provider: provider,
        model: model,
        response: response,
        ttfbMillis: null,
        durationMillis: stopwatch.elapsedMilliseconds,
        retryCount: 0,
        errorMessage: error,
        kind: 'compaction',
      );
    }
  }



  /// 顺序执行本轮全部工具调用,落库为 tool 消息;返回 null 表示已取消/已销毁。
  /// 每次调用先过权限引擎:放行 → 执行;拒绝 → 落一条 PERMISSION_DENIED;询问 → 挂起等用户选择。
  /// 写文件工具执行前拍快照。失败只记日志:拍不了快照不该拦住工具执行。
  /// 校验工具必填参数是否缺失。模型偶尔漏填参数(如 Bash 漏掉 command),
  /// 返回缺失的参数名列表,由调用方生成引导性错误,让模型下一轮补全。
  List<String> _missingRequiredArgs(AgentTool tool, Map<String, dynamic> args) {
    final missing = <String>[];
    tool.parameters.forEach((name, param) {
      if (!param.required) return;
      final value = args[name];
      if (value == null) {
        missing.add(name);
      } else if (value is String && value.trim().isEmpty) {
        missing.add(name);
      } else if (value is List && value.isEmpty) {
        missing.add(name);
      }
    });
    return missing;
  }

  Future<void> _snapshotBeforeWrite(ToolCall call) async {
    if (call.name != 'writeFile' && call.name != 'editFile') return;
    final rawPath = call.arguments['path'];
    if (rawPath is! String || rawPath.trim().isEmpty) return;
    try {
      final manager = await _ref.read(checkpointManagerProvider.future);
      final workspace = _ref.read(currentWorkspaceProvider);
      await manager.beforeFileModified(_sessionId, workspace.resolve(rawPath));
    } catch (error) {
      unawaited(_ref
          .read(fileLoggerProvider.future)
          .then((logger) => logger.w('Checkpoint', '拍摄快照失败: $error'))
          .catchError((_) {}));
    }
  }

  /// 写文件工具成功后,记下本会话写出的内容版本(回滚时据此区分「自己改的」和「别人改的」)。
  Future<void> _rememberWrittenFile(String sessionId, ToolCall call, ToolResult result) async {
    if (result is! ToolSuccess) return;
    if (call.name != 'writeFile' && call.name != 'editFile') return;
    final rawPath = call.arguments['path'];
    if (rawPath is! String || rawPath.trim().isEmpty) return;
    try {
      final manager = await _ref.read(checkpointManagerProvider.future);
      final files = await _ref.read(workspaceFilesProvider.future);
      final workspace = _ref.read(currentWorkspaceProvider);
      final absolute = workspace.resolve(rawPath);
      final content = await files.readText(absolute);
      final fingerprint = FileVersionRegistry.fingerprintOf(content);
      if (fingerprint == null) return;
      manager.versions.record(sessionId, workspace.display(absolute), fingerprint);
    } catch (_) {
      // 记不上版本只会让回滚更保守(按未知版本放行),不影响主流程。
    }
  }

  Future<List<AgentMessage>?> _executeTools(
    int generation,
    ChatSession session,
    List<ToolCall> calls,
  ) async {
    final db = _ref.read(databaseProvider);
    final messages = <AgentMessage>[];
    try {
      for (final call in calls) {
        if (generation != _generation || _disposed) return null;
        // 工具名在执行前就已确定,状态行据此说「正在整理待办」这类场景文案。
        state = state.copyWith(runningToolName: () => call.name);
        final tool = _toolsByName[call.name];
        ToolResult result;
        if (tool == null) {
          result = ToolError('未知工具:${call.name}', code: 'UNKNOWN_TOOL');
        } else {
          // 参数完整性校验:模型偶尔漏填必填参数(如 Bash 漏掉 command),
          // 此时返回引导性错误而非系统异常,让模型下一轮自动补全。
          final missing = _missingRequiredArgs(tool, call.arguments);
          if (missing.isNotEmpty) {
            final paramHints = missing
                .map((n) {
                  final p = tool.parameters[n]!;
                  return '  - $n: ${p.type.name}类型, ${p.description}';
                })
                .join('\n');
            result = ToolError(
              '调用工具 ${tool.name} 时缺少以下必需参数:\n$paramHints\n'
              '请在下一次调用中补全这些参数(值不能是空字符串或空数组),然后重新调用。',
              code: 'MISSING_ARGS',
            );
          } else {
          final engine = _ref.read(toolPermissionEngineProvider);
          final eval = await engine.evaluate(
            tool: tool,
            toolName: call.name,
            mode: session.mode,
            args: call.arguments,
          );
          if (generation != _generation || _disposed) return null;
          if (eval.verdict == PermissionVerdict.deny) {
            result = ToolError(
              eval.denyReason ?? '该工具被项目安全规则策略禁止执行',
              code: 'SYSTEM_DENIED',
            );
          } else if (_ref.read(runModeProvider) == AgentRunMode.plan &&
              tool.capabilities.contains(ToolCapability.writeWorkspace)) {
            // 计划模式:所有写操作被拦截,仅允许读取和分析。
            result = ToolError(
              _ref.read(appGlobalizationsProvider).runModePlanIntercept,
              code: 'PLAN_MODE_INTERCEPT',
            );
          } else if (_ref.read(runModeProvider) == AgentRunMode.auto &&
              eval.verdict != PermissionVerdict.ask) {
            // 自动模式:引擎已放行(allow)或已拒绝(deny)的直接执行,不弹窗。
            await _snapshotBeforeWrite(call);
            result = await tool.execute(call.arguments, sessionId: session.id);
          } else if (tool.permissionPolicy == ToolPermissionPolicy.autoApprove) {
            // 与上游同点:真正执行前拍快照(editFile/writeFile 是会改工作区的工具)。
            await _snapshotBeforeWrite(call);
            result = await tool.execute(call.arguments, sessionId: session.id);
          } else if (eval.verdict == PermissionVerdict.allow || _autonomous) {
            // 子代理自主执行时无 UI 可弹授权,派发即视为同意(对齐上游子代理自治语义);
            // deny 判定在其上,不受该标志影响。
            await _snapshotBeforeWrite(call);
            result = await tool.execute(call.arguments, sessionId: session.id);
          } else {
            final argsPreview = const JsonEncoder.withIndent('  ').convert(call.arguments);
            final choice = await _requestPermission(tool, call, argsPreview, eval);
            if (generation != _generation || _disposed) return null;
            if (choice == PermissionChoice.reject) {
              result = const ToolError('用户拒绝执行该工具', code: 'USER_REJECTED');
            } else {
              if (choice == PermissionChoice.always && eval.rememberable) {
                await engine.remember(call.name, eval.rememberablePatterns);
              }
              await _snapshotBeforeWrite(call);
              result = await tool.execute(call.arguments, sessionId: session.id);
            }
          }
          }
        }

        final message = AgentMessage(
          id: newId(),
          sessionId: _sessionId,
          role: MessageRole.tool,
          content: result.toTransportString(),
          timestamp: nowMs(),
          toolCallId: call.id,
          toolName: call.name,
          toolArgs: jsonEncode(call.arguments),
          isError: result is ToolError,
        );
        await db.messageDao.insert(message);
        await _rememberWrittenFile(session.id, call, result);
        if (call.name == 'todo') {
          _ref.invalidate(sessionTodosProvider(_sessionId));
        } else if (call.name == 'manageMcp') {
          // MCP 配置被改写:刷新列表,并后台把新增的 server 连上(不打断已连接的)。
          _ref.invalidate(mcpEntriesProvider);
          _ref.read(mcpManagerProvider.notifier).reconnectUnconnectedAsync();
        }
        messages.add(message);
      }
      return messages;
    } finally {
      // 取消/异常路径也要收回场景文案,否则状态行会一直停在「正在整理待办」。
      if (!_disposed) state = state.copyWith(runningToolName: () => null);
    }
  }

  /// 请求用户授权:状态里挂起待确认项,UI 通过 [resolvePermission] 回传三选一。
  Future<PermissionChoice> _requestPermission(
    AgentTool tool,
    ToolCall call,
    String argsPreview,
    PermissionEval eval,
  ) async {
    final completer = Completer<PermissionChoice>();
    _permissionCompleter = completer;
    final text = tool.permissionRequest(call.arguments, argsPreview);
    state = state.copyWith(
      pendingPermission: () => PendingPermission(
        id: call.id,
        toolName: tool.name,
        // 引擎可覆盖标题(如高危提权确认),对齐上游 eval.askTitle ?: base.title。
        title: eval.askTitle ?? text.title,
        summary: text.summary,
        details: text.details,
        argsPreview: argsPreview,
        rememberablePatterns: eval.rememberablePatterns,
        rememberDisabledReason: eval.rememberDisabledReason,
      ),
    );
    final choice = await completer.future;
    _permissionCompleter = null;
    if (!_disposed) {
      state = state.copyWith(pendingPermission: () => null);
    }
    return choice;
  }

  /// UI 侧确认结果;未在等待授权时无副作用。
  void resolvePermission(PermissionChoice choice) {
    final completer = _permissionCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(choice);
  }

  /// 用户点击停止:取消流并保留已接收的部分内容。
  ///
  /// 状态必须**先同步收尾再拆除连接**:订阅挂在 `async*` 生成器上时,
  /// `cancel()` 要等生成器从当前 `await`(正在等网络数据)恢复才会返回;
  /// 若先 await 它,停止按钮就会「点了没反应」——反馈速度取决于网络拆除速度。
  Future<void> stop() async {
    if (!state.streaming) return;
    final partial = state.streamingText.replaceAll(RegExp(r'\s+$'), '');
    final reasoning = state.streamingReasoning;

    // 1) 同步翻转状态:界面立刻退出「正在思考」,不再等任何异步操作。
    _generation++;
    // 标记这次调用被取消,并唤醒正在等结果的 _streamOnce 去落统计记录。
    _cancelledGeneration = _generation - 1;
    state = state.copyWith(
      streaming: false,
      streamingText: '',
      streamingReasoning: '',
      retry: () => null,
    );
    final pending = _pendingCallCompleter;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    resolvePermission(PermissionChoice.reject);

    // 2) 拆连接放到后台:取消可能迟迟不返回,不能挡住上面已经完成的界面更新。
    //    先取消令牌打断底层 HTTP 请求,否则 `async*` 传输层会一直等数据。
    final token = _cancelToken;
    _cancelToken = null;
    if (token != null && !token.isCancelled) {
      token.cancel('用户停止');
    }
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object error) {
        AppLog.w('Chat', '取消流失败:$error');
      }));
    }
    // 取消路径不会触发 onDone,这里兜底清掉环境会话,避免后续日志错记到本会话。
    AiLog.currentSessionId = null;

    if (!hasVisibleContent(partial)) return;
    final message = AgentMessage(
      id: newId(),
      sessionId: _sessionId,
      role: MessageRole.assistant,
      content: partial,
      timestamp: nowMs(),
      reasoning: reasoning.isEmpty ? null : reasoning,
    );
    try {
      await _ref.read(databaseProvider).messageDao.insert(message);
    } catch (error) {
      // 落库失败不该让界面停不下来:状态在上面已经收尾,这里只记日志。
      AppLog.w('Chat', '保存被中断的部分回复失败:$error');
      return;
    }
    if (_disposed) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  /// 重试上一条用户消息:重新发送最近的一条用户消息(含附件)。
  Future<bool> retry() async {
    if (state.streaming) return false;
    final messages = state.messages;
    // 从后往前找最近的一条用户消息。
    AgentMessage? lastUser;
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        lastUser = messages[i];
        break;
      }
    }
    if (lastUser == null) return false;
    // 将该条消息的附件放入待发列表,随重试一起发送。
    state = state.copyWith(
      pendingAttachments: [...state.pendingAttachments, ...lastUser.attachments],
    );
    // 移除重试消息之后的所有消息(包括被中断的助手回复)。
    final trimmedMessages =
        messages.takeWhile((m) => m.id != lastUser!.id).toList()..add(lastUser!);
    state = state.copyWith(
      messages: trimmedMessages,
      errorCode: () => null,
      errorDetail: () => null,
      streaming: false,
      streamingText: '',
      streamingReasoning: '',
      retry: () => null,
    );
    return send(lastUser.content);
  }

  /// 附加一个附件(待随下一条消息发送)。
  void addAttachment(AgentAttachment attachment) {
    state = state.copyWith(pendingAttachments: [...state.pendingAttachments, attachment]);
  }

  void removeAttachment(int index) {
    final list = [...state.pendingAttachments];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    state = state.copyWith(pendingAttachments: list);
  }

  void clearError() => state = state.copyWith(
        errorCode: () => null,
        errorDetail: () => null,
      );

  // ---------------------------------------------------------------------------
  // 检查点回退(对齐上游 executeRewindOption)
  // ---------------------------------------------------------------------------

  /// 打开某条用户消息的回退选项弹层。
  void openRewindMenu(String messageId) =>
      state = state.copyWith(rewindTargetMessageId: () => messageId);

  void dismissRewindMenu() =>
      state = state.copyWith(rewindTargetMessageId: () => null);

  /// UI 已展示过冲突提示,清空以免重复弹。
  void clearRewindConflicts() => state = state.copyWith(rewindConflicts: const []);

  /// 执行回退:先把会话停稳,再按选项回滚代码 / 会话 / 两者,最后回填输入框。
  ///
  /// [onFillPrompt] 把被回退的那条用户消息的正文与附件交回输入框,让用户改一改再发。
  Future<void> executeRewindOption(
    String messageId,
    RewindOption option, {
    void Function(String text, List<AgentAttachment> attachments)? onFillPrompt,
  }) async {
    final target = state.messages.where((message) => message.id == messageId).firstOrNull;
    if (target == null) return;
    dismissRewindMenu();

    // 1. 停止当前任务:否则回滚刚做完就会被在跑的流程又改回去。
    if (state.streaming) await stop();
    state = state.copyWith(
      streaming: false,
      streamingText: '',
      streamingReasoning: '',
      retry: () => null,
      pendingPermission: () => null,
      runningToolName: () => null,
    );

    // 2. 清掉活动检查点:后续工具调用不该再往这次回退的检查点里拍快照。
    try {
      final manager = await _ref.read(checkpointManagerProvider.future);
      manager.setActiveCheckpoint(_sessionId, null);
    } catch (_) {}

    final db = _ref.read(databaseProvider);
    final checkpoint = await db.checkpointDao.findByMessage(_sessionId, messageId);
    final attachments = target.attachments;

    switch (option) {
      case RewindOption.codeAndConversation:
        if (checkpoint != null) {
          final result = await _restoreCode(checkpoint.id);
          state = state.copyWith(rewindConflicts: result.skipped);
        }
        await _rewindConversation(target.timestamp);
        onFillPrompt?.call(target.content, attachments);
      case RewindOption.conversation:
        await _rewindConversation(target.timestamp);
        onFillPrompt?.call(target.content, attachments);
      case RewindOption.code:
        if (checkpoint != null) {
          final result = await _restoreCode(checkpoint.id);
          state = state.copyWith(rewindConflicts: result.skipped);
        }
    }
  }

  Future<CheckpointRestoreResult> _restoreCode(String checkpointId) async {
    try {
      final manager = await _ref.read(checkpointManagerProvider.future);
      return await manager.restoreCodeToCheckpoint(_sessionId, checkpointId);
    } catch (error) {
      unawaited(_ref
          .read(fileLoggerProvider.future)
          .then((logger) => logger.w('Checkpoint', '回滚代码失败: $error'))
          .catchError((_) {}));
      return CheckpointRestoreResult.empty;
    }
  }

  /// 删掉该时间点及其之后的全部消息(回退会话)。
  Future<void> _rewindConversation(int timestamp) async {
    final db = _ref.read(databaseProvider);
    await db.messageDao.deleteFromTimestamp(_sessionId, timestamp);
    await _reloadMessages();
  }

  /// 删除一条消息。用户消息连带删除其后所有消息(对齐上游 deleteMessage):
  /// 只删提问会留下没有上下文的回答,反而更难理解。
  Future<void> deleteMessage(String messageId) async {
    final target = state.messages.where((message) => message.id == messageId).firstOrNull;
    if (target == null) return;
    final db = _ref.read(databaseProvider);
    if (target.role == MessageRole.user) {
      await db.messageDao.deleteFromTimestamp(_sessionId, target.timestamp);
    }
    await db.messageDao.delete(messageId);
    await _reloadMessages();
  }

  /// 改写一条消息的正文(只改内容,不动时间戳与顺序)。
  Future<void> updateMessageContent(String messageId, String content) async {
    final target = state.messages.where((message) => message.id == messageId).firstOrNull;
    if (target == null) return;
    final updated = target.copyWith(content: content);
    await _ref.read(databaseProvider).messageDao.update(updated);
    if (_disposed) return;
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == messageId) updated else message,
      ],
    );
  }

  /// 读取供应商列表;尚未加载完成时等待其首帧,避免把「加载中」误判为「无供应商」。
  Future<List<ProviderConfig>> _providerList() async {
    try {
      return await _ref.read(providersProvider.future);
    } catch (_) {
      return const [];
    }
  }

  ProviderConfig? _pickProvider(List<ProviderConfig> providers, ChatSession session) {
    final usable = providers.where((p) => p.isEnabled && p.hasUsableApiKey).toList();
    if (usable.isEmpty) return null;
    if (session.providerId != null) {
      for (final provider in usable) {
        if (provider.id == session.providerId) return provider;
      }
    }
    return usable.first;
  }

  /// 回放给模型的历史:跳过压缩消息与「不出墨」的助手消息;
  /// 带工具调用的助手消息(正文可能为空)与工具结果消息必须保留,否则配对断裂。
  List<AgentMessage> _replayHistory(List<AgentMessage> messages) => messages.where((m) {
        if (m.isCompacted) return false;
        if (m.role == MessageRole.tool) return true;
        if (m.role == MessageRole.assistant) {
          return hasVisibleContent(m.content) ||
              ToolCall.decodeList(m.toolCallsJson).isNotEmpty;
        }
        return m.content.trim().isNotEmpty || m.attachments.isNotEmpty;
      }).toList();

  /// 标题生成请求的系统提示词(对齐上游 generateTitle 语义:简洁标题,直接输出)。
  static const String _titleSystemPrompt =
      '你是会话标题生成器。根据用户的消息生成一个简洁标题,直接输出标题文本:不超过 30 字,不加引号,不加结尾标点,不解释。';

  /// 用 LLM 为首条消息生成更贴切的标题(对齐上游 generateTitle):跟随当前会话模型,
  /// 失败或取不到时保留临时标题。
  Future<void> _generateTitle(ChatSession session, String request) async {
    try {
      final providers = await _providerList();
      var provider = _pickProvider(providers, session);
      if (provider == null) return;
      var model = (session.model?.trim().isNotEmpty == true
              ? session.model!
              : provider.effectiveModel)
          .trim();
      if (model.isEmpty) return;

      final rotator = _ref.read(keyRotatorProvider);
      final picked = rotator.pick(provider, _sessionId);
      final apiKey = picked.isEmpty ? provider.apiKey : picked;
      final general = _ref.read(generalSettingsProvider);
      final client = createLlmClient(
        type: provider.type,
        transport: _ref.read(sseTransportProvider),
        config: LlmClientConfig(
          apiKey: apiKey,
          baseUrl: provider.baseUrl,
          model: model,
          useFullUrl: provider.useFullUrl,
          temperature: fixedTemperature(model),
          firstByteTimeout: general.firstByteTimeoutSec <= 0
              ? null
              : Duration(seconds: general.firstByteTimeoutSec),
          idleTimeout: general.streamIdleTimeoutSec <= 0
              ? null
              : Duration(seconds: general.streamIdleTimeoutSec),
          maxRetries: general.maxNetworkRetries,
          customHeaders: provider.resolvedHeaders(sessionId: _sessionId),
        ),
      );

      final buffer = StringBuffer();
      _titleSubscription = client
          .completeStream(
            systemPrompt: _titleSystemPrompt,
            messages: [
              AgentMessage(
                id: newId(),
                sessionId: _sessionId,
                role: MessageRole.user,
                content: request,
                timestamp: nowMs(),
              ),
            ],
            cancelToken: CancelToken(),
          )
          .listen((chunk) {
            if (chunk is TextDelta) buffer.write(chunk.text);
          });
      await _titleSubscription!.asFuture();

      // 与临时标题同口径:折叠空白、截断 30 字;空结果保留临时标题。
      final generated = titleFromText(buffer.toString());
      if (generated.isEmpty || _disposed) return;
      final db = _ref.read(databaseProvider);
      final latest = await db.sessionDao.get(_sessionId);
      if (latest == null) return;
      await db.sessionDao.upsert(latest.copyWith(title: generated, updatedAt: nowMs()));
      _ref.invalidate(sessionsProvider);
    } catch (error) {
      // 标题生成失败只保留临时标题,不影响本轮对话(对齐上游语义)。
      AppLog.w('Chat', 'LLM 标题生成失败:$error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _permissionCompleter = null;
    _subscription?.cancel();
    _titleSubscription?.cancel();
    super.dispose();
  }
}