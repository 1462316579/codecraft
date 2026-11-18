import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../agent/chat_controller.dart';
import '../../agent/models/agent_message.dart';
import '../../agent/models/agent_ui_state.dart';
import '../../agent/models/chat_session.dart';
import '../../agent/sessions_controller.dart';
import '../../app/shell.dart';
import '../../core/icons/iconfont.dart';
import '../../core/util/window_size.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/attachment_store.dart';
import '../../data/providers/provider_config.dart';
import '../../data/providers/provider_store.dart';
import '../../data/workspaces.dart';
import '../../agent/models/model_metadata.dart';
import '../../core/ui/provider_logo.dart';
import '../../data/model_api_service.dart';
import '../../data/model_catalog.dart';
import '../../data/model_metadata_store.dart';
import '../settings/model_sheets.dart';
import '../../core/util/ids.dart';
import '../../data/db/app_database.dart';
import '../../data/db/checkpoint_dao.dart';
import 'widgets/rewind_options_sheet.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/edit_message_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../core/ui/settings_group.dart';
import 'chat_welcome.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_header.dart';
import 'widgets/message_bubble.dart';
import 'widgets/permission_panel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  int _uploadingCount = 0;
  /// 输入栏实测高度:欢迎页用它把文案向上抬(对齐上游 inputBarReservePx)。
  double _composerHeight = 0;
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _scrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 应用进入后台或不可交互状态:停止当前流式响应,避免后台继续请求并报错中断。
      ref.read(chatControllerProvider(widget.sessionId).notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(chatControllerProvider(widget.sessionId));
    final session = ref.watch(sessionByIdProvider(widget.sessionId)).valueOrNull;
    final controller = ref.read(chatControllerProvider(widget.sessionId).notifier);
    final title = (session?.title.trim().isEmpty ?? true) ? l10n.untitled : session!.title;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 与首页一致的柔光玻璃渐变底
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.light
                      ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                      : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
                ),
              ),
            ),
          ),
          Column(
        children: [
          ChatHeader(
            title: title,
            modelName: session?.model,
            mode: session?.mode ?? AgentMode.build,
            onOpenDrawer: ShellScope.maybeOf(context)?.openDrawer,
            onNewChat: _newSession,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(
                      width: 0.5,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: !state.loaded
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty && !state.streaming
                    ? ChatWelcomeMessage(bottomReserve: _composerHeight)
                    : Stack(
                        children: [
                          _messageList(context, state),
                          // 回到底部按钮(对齐上游 AIChatPanel 的 ScrollToBottomButton):
                          // 悬浮在输入框右上方,离底超半屏时出现,滚动时淡出。
                          Positioned(
                            right: Spacing.lg,
                            bottom: Spacing.sm,
                            child: IgnorePointer(
                              ignoring: !_showScrollToBottom,
                              child: AnimatedOpacity(
                                opacity:
                                    !_showScrollToBottom ? 0 : (_scrolling ? 0.4 : 1),
                                duration: const Duration(milliseconds: 160),
                                child: _ScrollToBottomButton(
                                  label: l10n.commonScrollToBottom,
                                  onTap: _scrollToBottom,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
          if (state.compacting)
            _StatusBanner(
              icon: Icons.compress,
              color: context.semantic.warning,
              text: l10n.chatCompressingContext,
            ),
          if (state.retry != null)
            _StatusBanner(
              icon: Icons.sync,
              color: context.semantic.warning,
              text:
                  '${l10n.retrying} (${state.retry!.attempt}/${state.retry!.maxRetries}) · ${state.retry!.error}',
            ),
          if (state.errorCode != null)
            _StatusBanner(
              icon: Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              text: _errorText(l10n, state),
              onDismiss: controller.clearError,
            ),
          // 回滚时有文件因「存在本会话未见过的改动」被跳过——必须告诉用户,
          // 静默跳过等于把数据丢失换成了无声的失败。
          if (state.rewindConflicts.isNotEmpty)
            _StatusBanner(
              icon: Icons.info_outline,
              color: context.semantic.warning,
              text: l10n.checkpointRewindSkipped(state.rewindConflicts.length),
              onDismiss: controller.clearRewindConflicts,
            ),
          if (state.pendingPermission != null)
            PermissionPanel(
              permission: state.pendingPermission!,
              onChoice: controller.resolvePermission,
            ),
          ChatComposer(
            state: state,
            session: session,
            input: _input,
            onSend: (text) async {
              final accepted = await controller.send(text);
              if (accepted && mounted) {
                _input.clear();
                // 发送后立即滚到底部,让刚发出的用户消息与 AI 的流式回复
                // 在当前视野内,而不是需要用户手动拉或退出重进才能看到。
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scrollToBottom();
                });
              }
            },
            // 发送后清空输入框;但被拒绝(无供应商/无模型/正在生成)时保留内容,
            // 否则用户刚打的字会连同错误提示一起消失。

            onStop: controller.stop,
            onPickModel: () => _pickModel(session),
            onPickEffort: (effort) => _updateSession(session, reasoningEffort: effort),
            onRemoveAttachment: controller.removeAttachment,
            onUploadFile: _pickFiles,
            onAttachImage: _pickImages,
            onTakePhoto: _takePhoto,
            onHeightChanged: (height) {
              if ((height - _composerHeight).abs() > 0.5) {
                setState(() => _composerHeight = height);
              }
            },
          ),
        ],
          ),
        ],
      ),
    );
  }

  /// 消息列:大屏下收窄到可读宽度并居中(上游 readableContentMaxWidth)。
  Widget _messageList(BuildContext context, ChatViewState state) {
    // 已压缩的历史消息不再渲染(marker 与接手摘要卡片替代它们的展示)。
    final visibleMessages = state.messages.where((m) => !m.isCompacted).toList();
    final list = NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        itemCount: visibleMessages.length + (state.streaming ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.streaming && index == 0) {
            return MessageBubble(
              role: MessageRole.assistant,
              content: state.streamingText,
              reasoning:
                  state.streamingReasoning.isEmpty ? null : state.streamingReasoning,
              streaming: true,
              runningTool: state.runningToolName,
            );
          }
          final offset = state.streaming ? 1 : 0;
          final messageIndex = visibleMessages.length - 1 - (index - offset);
          final message = visibleMessages[messageIndex];
          return MessageBubble.fromMessage(
            message,
            showActions: messageIndex == visibleMessages.length - 1,
            durationMs: _taskDurationMs(messageIndex, visibleMessages),
            // 用户消息挂「回退」;回退只在有对应检查点时才真正能还原代码。
            onRewind: message.role == MessageRole.user && !message.isCompactionMarker
                ? () => _openRewindMenu(message)
                : null,
            onMore: () => _openMessageActions(message),
          );
        },
      ),
    );
    if (!isWideLayout(context)) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ChatStyle.readable),
        child: list,
      ),
    );
  }

  /// 离底超过半屏时显示「回到底部」(对齐上游 isFarFromBottom:不看滚动方向——
  /// 往上翻历史后停住恰恰是最需要一键回底的时刻)。reverse 列表 offset 0 = 视觉底部。
  void _onScroll() {
    final pos = _scrollController.position;
    // 反向列表:extentAfter 是视口上方(更早消息方向)的剩余内容,趋 0 = 到达视觉
    // 顶部。对齐上游补载触发(顶部 3 条内且 hasMore 且非加载中);补载完成后仍在
    // 顶部会自动连续补载(上游把分页上限纳入触发信号,这里经 state 重建体现)。
    final chatState = ref.read(chatControllerProvider(widget.sessionId));
    if (pos.extentAfter <= pos.viewportDimension &&
        chatState.hasMore &&
        !chatState.isLoadingMore) {
      ref.read(chatControllerProvider(widget.sessionId).notifier).loadMoreMessages();
    }
    final far = pos.maxScrollExtent > 0 && pos.pixels > pos.viewportDimension / 2;
    if (far != _showScrollToBottom) setState(() => _showScrollToBottom = far);
  }

  /// 跟踪滚动状态:滚动中按钮淡出(对齐上游 isScrollInProgress → alpha 0.4)。
  bool _onScrollNotification(ScrollNotification notification) {
    final scrolling = notification is ScrollStartNotification;
    final ended = notification is ScrollEndNotification;
    if ((scrolling && !_scrolling) || (ended && _scrolling)) {
      setState(() => _scrolling = scrolling);
    }
    return false;
  }

  /// 一键回到底部(对齐上游 snapToBottom:瞬移到底部锚点,reverse 列表即 offset 0)。
  void _scrollToBottom() => _scrollController.jumpTo(0);

  /// 本轮耗时(上游 computeTaskDurations):轮末助手消息时间戳 − 该轮用户消息时间戳。
  int? _taskDurationMs(int index, List<AgentMessage> messages) {
    final message = messages[index];
    if (message.role != MessageRole.assistant) return null;
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        final duration = message.timestamp - messages[i].timestamp;
        return duration > 0 ? duration : null;
      }
    }
    return null;
  }

  String _errorText(AppLocalizations l10n, ChatViewState state) => switch (state.errorCode!) {
        ChatErrorCode.noProvider => l10n.errorNoProvider,
        ChatErrorCode.noModel => l10n.errorNoModel,
        ChatErrorCode.emptyResponse => l10n.errorEmptyResponse,
        ChatErrorCode.generic => state.errorDetail ?? l10n.errorGeneric,
      };

  /// 选文件(多选)→ 上传到当前工作区(对齐上游 OpenMultipleDocuments + "*/*")。
  Future<void> _pickFiles() async {
    final picked = await file_selector.openFiles();
    await _handlePicked(
      [for (final file in picked) (path: file.path, name: file.name, mimeType: file.mimeType)],
      images: false,
    );
  }

  /// 选图(多选)→ 上传到当前工作区,并随图片块发送。
  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
    await _handlePicked(
      [for (final image in picked) (path: image.path, name: image.name, mimeType: image.mimeType)],
      images: true,
    );
  }

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    await _handlePicked(
      [(path: picked.path, name: picked.name, mimeType: picked.mimeType)],
      images: true,
    );
  }

  /// 上传选中的附件(对齐上游 handlePickedAttachments):超出上限的先截断,
  /// 逐个上传并汇总提示;失败项不影响其余附件。
  Future<void> _handlePicked(
    List<({String path, String name, String? mimeType})> files, {
    required bool images,
  }) async {
    if (files.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(chatControllerProvider(widget.sessionId).notifier);
    final pending = ref.read(chatControllerProvider(widget.sessionId)).pendingAttachments;
    if (pending.length >= AttachmentStore.maxPendingAttachments) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.attachmentMax(AttachmentStore.maxPendingAttachments)),
      ));
      return;
    }

    final slots = AttachmentStore.maxPendingAttachments - pending.length;
    final selected = files.take(slots).toList();
    var success = 0;
    final failures = <String>[];
    final workspace = ref.read(currentWorkspaceProvider);
    setState(() => _uploadingCount = selected.length);
    try {
      for (final file in selected) {
        try {
          final attachment = await AttachmentStore.copyToWorkspace(
            workspace: workspace,
            sourcePath: file.path,
            fileName: file.name,
            mimeTypeHint: file.mimeType,
            includeImageData: images,
          );
          if (!mounted) return;
          controller.addAttachment(attachment);
          success++;
        } on AttachmentUploadException catch (error) {
          failures.add(_uploadErrorText(l10n, error));
        } catch (_) {
          failures.add(l10n.attachmentUploadFailed);
        }
      }
    } finally {
      if (mounted) setState(() => _uploadingCount = 0);
    }
    if (!mounted) return;

    final skipped = files.length - selected.length;
    final text = success == 0 && failures.isNotEmpty
        ? failures.first
        : skipped > 0 || failures.isNotEmpty
            ? l10n.attachmentUploadedPartial(success)
            : l10n.attachmentUploaded(success);
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  String _uploadErrorText(AppLocalizations l10n, AttachmentUploadException error) =>
      switch (error.error) {
        AttachmentUploadError.imageTooLarge =>
          l10n.attachmentImageTooLarge(formatBytes(error.limitBytes)),
        AttachmentUploadError.unsupportedImageType => l10n.attachmentUnsupportedImageType,
        AttachmentUploadError.unreadableFile => l10n.attachmentReadFileFailed,
      };

  /// 打开某条用户消息的回退弹层,并按选择执行回退。
  ///
  /// 「回退」= 回到那条消息发出前的状态:可还原代码、删除其后会话,或两者都做;
  /// 被回退掉的提问会回填到输入框,方便改一改再发。
  Future<void> _openRewindMenu(AgentMessage message) async {
    // 有检查点才能给出提示词摘要,也才谈得上还原代码。
    Checkpoint? checkpoint;
    try {
      final db = ref.read(databaseProvider);
      checkpoint = await db.checkpointDao.findByMessage(message.sessionId, message.id);
    } catch (_) {}
    if (!mounted) return;
    final option = await showRewindOptionsSheet(
      context,
      promptSnippet: checkpoint?.promptSnippet ?? titleFromText(message.content, max: 60),
    );
    if (option == null || !mounted) return;
    final controller = ref.read(chatControllerProvider(message.sessionId).notifier);
    await controller.executeRewindOption(
      message.id,
      option,
      onFillPrompt: (text, attachments) {
        _input.text = text;
        _input.selection = TextSelection.collapsed(offset: text.length);
        if (attachments.isNotEmpty) {
          for (final attachment in attachments) {
            controller.addAttachment(attachment);
          }
        }
      },
    );
    if (!mounted) return;
    // 回退后消息列表已重置,滚动到底部,避免底部内容空白需等待才显示。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });
  }

  /// 「更多选项」:编辑 / 删除。复制已在气泡下方常驻,不在这里重复。
  Future<void> _openMessageActions(AgentMessage message) async {
    final action = await showMessageActionsSheet(context);
    if (action == null || !mounted) return;
    final controller = ref.read(chatControllerProvider(message.sessionId).notifier);
    switch (action) {
      case MessageAction.edit:
        final updated = await showEditMessageDialog(context, initialText: message.content);
        if (updated == null) return;
        await controller.updateMessageContent(message.id, updated);
      case MessageAction.delete:
        await controller.deleteMessage(message.id);
    }
  }

  /// 顶栏加号:在当前项目里新开一个会话。
  ///
  /// 只建会话、不建项目:项目由项目页的加号创建,这里永远不产生新项目。
  Future<void> _newSession() async {
    final current = ref.read(sessionByIdProvider(widget.sessionId)).valueOrNull;
    final projectId = current?.projectId ?? ref.read(selectedProjectProvider);
    final session = await ref.read(sessionsProvider.notifier).create(
          mode: current?.mode ?? AgentMode.build,
          projectId: projectId,
        );
    if (!mounted) return;
    openSession(context, ref, session.id);
  }

  Future<void> _updateSession(
    ChatSession? session, {
    String? providerId,
    String? model,
    ReasoningEffort? reasoningEffort,
  }) async {
    if (session == null) return;
    await ref.read(sessionsProvider.notifier).upsert(session.copyWith(
          providerId: providerId == null ? null : () => providerId,
          model: model == null ? null : () => model,
          reasoningEffort: reasoningEffort,
        ));
  }

  Future<void> _pickModel(ChatSession? session) async {
    if (session == null) return;
    final l10n = AppLocalizations.of(context);
    // 必须 await:providersProvider 要读数据库,启动初期还没就绪。
    // 之前用 valueOrNull 同步取,冷启动时会拿到空列表 → 弹层显示「没有模型」,
    // 等一会儿数据加载完又恢复正常,看起来就像「配置好的模型丢了」。
    List<ProviderConfig> allProviders;
    try {
      allProviders = await ref.read(providersProvider.future);
    } catch (_) {
      allProviders = const [];
    }
    final providers = allProviders
        .where((p) => p.isEnabled && p.hasUsableApiKey)
        .toList();
    if (!mounted) return;
    if (providers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorNoProvider)));
      return;
    }
    final selected = await showModalBottomSheet<(String?, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ModelPickerSheet(
        providers: providers,
        currentProviderId: session.providerId ?? '',
        currentModel: session.model ?? '',
      ),
    );
    if (selected == null) return;
    await _updateSession(session, providerId: selected.$1, model: selected.$2);
  }
}

/// 模型选择弹层(对齐上游 ModelSelectionSheet 的骨架):
/// 标题 + 胶囊搜索框 + 按供应商分组的模型行(选中打勾)。
/// 模型选择弹层(对齐上游 ModelSelectionSheet):
/// 标题行 + 胶囊搜索 + 「Auto Model」卡片 + 按供应商折叠分组(组头带模型数、行内品牌 logo 与能力标签)。
class _ModelPickerSheet extends ConsumerStatefulWidget {
  const _ModelPickerSheet({
    required this.providers,
    required this.currentProviderId,
    required this.currentModel,
  });

  final List<ProviderConfig> providers;
  final String currentProviderId;
  final String currentModel;

  @override
  ConsumerState<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<_ModelPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  /// 已折叠的供应商(搜索时强制展开:搜到名字却看不到结果会让人困惑)。
  final _collapsed = <String>{};
  final _testing = <String>{};
  final _testResults = <String, ModelTestResult>{};

  String _key(String providerId, String model) => '$providerId\u0000$model';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ModelMetadata? _metadataOf(
    ModelCatalog catalog,
    Map<String, ModelMetadata> custom,
    ProviderConfig provider,
    String model,
  ) {
    // 目录/自定义元数据在 build 开头 watch 一次,这里只做查表:
    // 原来每行都 ref.watch 两个 Provider,471 个模型就是近千次订阅与重算。
    return resolveModelMetadata(
      catalog,
      custom,
      providerId: provider.id,
      model: model,
    );
  }

  Future<void> _testModel(ProviderConfig provider, String model) async {
    final key = _key(provider.id, model);
    if (_testing.contains(key)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _testing.add(key));
    final result = await ref.read(modelApiProvider).testModel(
          provider: provider,
          apiKey: provider.firstUsableApiKey,
          model: model,
          messageForKeyMissing: l10n.providerApiKeyRequired,
        );
    if (!mounted) return;
    setState(() {
      _testing.remove(key);
      _testResults[key] = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    // 与上游一致:只列「已启用且已配置模型」的供应商。
    final active = [
      for (final provider in widget.providers)
        if (provider.isEnabled && provider.models.isNotEmpty) provider,
    ];
    final groups = <(ProviderConfig, List<String>)>[];
    for (final provider in active) {
      final matched = [
        for (final model in provider.models)
          if (query.isEmpty ||
              model.toLowerCase().contains(query) ||
              provider.name.toLowerCase().contains(query))
            model,
      ];
      if (matched.isNotEmpty) groups.add((provider, matched));
    }

    final catalog = ref.watch(modelCatalogProvider).valueOrNull ?? ModelCatalog.empty;
    final custom =
        ref.watch(customModelMetadataProvider).valueOrNull ?? const <String, ModelMetadata>{};

    // 扁平化成「按需构建」的条目:一个供应商几百个模型时,原来整块
    // SettingsGroup(children: [...]) 会在弹层打开的瞬间全部 build 一遍,
    // 造成明显卡顿;改成 ListView.builder 后只构建可视区域内的行。
    final items = <_PickerItem>[];
    for (final (provider, models) in groups) {
      final expanded = query.isNotEmpty || !_collapsed.contains(provider.id);
      items.add(_HeaderItem(provider, models.length, expanded));
      if (expanded) {
        for (var index = 0; index < models.length; index++) {
          items.add(_ModelItem(
            provider,
            models[index],
            firstInCard: index == 0,
            lastInCard: index == models.length - 1,
          ));
        }
      }
    }
    if (groups.isEmpty) items.add(const _EmptyItem());

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
              child: Text(
                l10n.model,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: CapsuleSearchField(
                controller: _search,
                hint: l10n.searchModels,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is _HeaderItem) {
                    return Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: CollapsibleGroupHeader(
                        // 组头带模型数量(对齐上游)。
                        text: '${item.provider.name} (${item.count})',
                        expanded: item.expanded,
                        onToggle: () => setState(() {
                          if (!_collapsed.remove(item.provider.id)) {
                            _collapsed.add(item.provider.id);
                          }
                        }),
                      ),
                    );
                  }
                  if (item is _ModelItem) {
                    final provider = item.provider;
                    final model = item.model;
                    return _ModelCardSegment(
                      first: item.firstInCard,
                      last: item.lastInCard,
                      child: _ModelRow(
                        model: model,
                        selected: provider.id == widget.currentProviderId &&
                            model == widget.currentModel,
                        leading: ModelLogoIcon(modelName: model, size: 20),
                        metadata: _metadataOf(catalog, custom, provider, model),
                        testing: _testing.contains(_key(provider.id, model)),
                        testResult: _testResults[_key(provider.id, model)],
                        onTest: () => _testModel(provider, model),
                        onTap: () => Navigator.pop(context, (provider.id, model)),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                    child: Center(
                      child: Text(
                        l10n.emptyModels,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.semantic.subtleText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 模型选择弹层的扁平条目:Auto / 分组头 / 模型行 / 空态。
sealed class _PickerItem {
  const _PickerItem();
}

class _HeaderItem extends _PickerItem {
  const _HeaderItem(this.provider, this.count, this.expanded);

  final ProviderConfig provider;
  final int count;
  final bool expanded;
}

class _ModelItem extends _PickerItem {
  const _ModelItem(
    this.provider,
    this.model, {
    required this.firstInCard,
    required this.lastInCard,
  });

  final ProviderConfig provider;
  final String model;
  final bool firstInCard;
  final bool lastInCard;
}

class _EmptyItem extends _PickerItem {
  const _EmptyItem();
}

/// 模型行卡片切片:同组模型共用一张玻璃卡片,但按行懒加载。
///
/// 用首/中/末三段的圆角、边框与分隔线拼出整卡外观——这比让
/// [SettingsGroup] 一次性构建几百行便宜得多,滚动时每帧只构建屏幕内的行。
class _ModelCardSegment extends StatelessWidget {
  const _ModelCardSegment({
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bright = theme.brightness == Brightness.light;
    final radius = BorderRadius.vertical(
      top: Radius.circular(first ? Radii.xl : 0),
      bottom: Radius.circular(last ? Radii.xl : 0),
    );
    final edge = BorderSide(
      width: 1,
      color: Colors.white.withValues(alpha: bright ? 0.70 : 0.18),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: bright ? 0.55 : 0.12),
            Colors.white.withValues(alpha: bright ? 0.22 : 0.05),
          ],
        ),
        borderRadius: radius,
        border: Border(
          top: first ? edge : BorderSide.none,
          bottom: last ? edge : BorderSide.none,
          left: edge,
          right: edge,
        ),
        boxShadow: last
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: bright ? 0.06 : 0.28),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (!first) const SettingsDivider(indent: SettingsRow.textIndent),
          child,
        ],
      ),
    );
  }
}

/// 模型行(对齐上游 ModelSelectionRow):品牌 logo + 名称 + 能力标签,选中时名称变主色并打勾。
class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.model,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.metadata,
    this.testing = false,
    this.testResult,
    this.onTest,
  });

  final String model;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? leading;
  final ModelMetadata? metadata;
  final bool testing;
  final ModelTestResult? testResult;
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: leading!,
              ),
              const SizedBox(width: Spacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ModelMetadataTags(metadata: metadata),
                  if (testResult != null)
                    ModelTestResultLine(model: model, result: testResult!),
                ],
              ),
            ),
            if (onTest != null) ...[
              const SizedBox(width: Spacing.xs),
              // 与「编辑供应商」模型行保持一致:文字「测试」按钮 + 固定 56x36 占位,
              // 而不是只有图标的烧瓶,避免两处交互看起来不是同一个功能。
              SizedBox(
                width: 56,
                height: 36,
                child: testing
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onTest,
                        child: Text(
                          l10n.providerTestModel,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
              ),
            ] else if (selected) ...[
              const SizedBox(width: Spacing.sm),
              Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}

/// 状态条:重试提示 / 错误提示(可关闭),挂在消息列表与输入区之间。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
    this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.mdLarge),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 16, color: color),
            ),
        ],
      ),
    );
  }
}

/// 回到底部按钮(对齐上游 AIChatPanel 的 ScrollToBottomButton):
/// 34dp 圆形、surface 底 + outlineVariant 描边 + 阴影,ArrowDown 图标;
/// 悬浮在输入框右上方,离底超半屏时出现,滚动时淡出。
class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          shape: CircleBorder(
            side: BorderSide(width: 1, color: theme.colorScheme.outlineVariant),
          ),
          color: theme.colorScheme.surface,
          elevation: 6,
          shadowColor: theme.colorScheme.shadow,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                Iconfont.arrowDown,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
