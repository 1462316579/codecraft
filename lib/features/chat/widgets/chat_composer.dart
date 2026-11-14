import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent/models/agent_attachment.dart';
import '../../../agent/models/agent_ui_state.dart';
import '../../../agent/models/chat_session.dart';
import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/attachment_store.dart';
import '../../../data/settings/general_settings.dart';
import '../../../agent/models/skill.dart';
import '../../../data/skills.dart';
import '../../../core/ui/provider_logo.dart';
import '../../../agent/models/auto_model.dart';
import '../../../data/providers/provider_config.dart';
import '../../../data/providers/provider_store.dart';
import '../../../data/model_metadata_store.dart';
import '../../../data/model_catalog.dart';
import '../../../data/workspace_files.dart';
import '../../../data/workspaces.dart';
import '../../../data/run_mode_provider.dart';
import '../../../agent/models/run_mode.dart';
import '../../../l10n/app_localizations.dart';
import 'image_preview.dart';
import 'mention_controller.dart';
import 'todo_views.dart';

/// 测量子树高度并回报给上层(对齐上游 onGloballyPositioned 量输入栏高度)。
///
/// 用实际渲染尺寸(而非 LayoutBuilder 的 maxHeight 上限)上报:输入栏内部是
/// Wrap/Column 自适应高度,LayoutBuilder 传下来的约束常常是无穷或屏幕高,
/// 用 maxHeight 会把欢迎页文案抬到键盘上方之外,导致底部溢出。
class _HeightReporter extends StatefulWidget {
  const _HeightReporter({required this.child, this.onHeightChanged});

  final Widget child;
  final ValueChanged<double>? onHeightChanged;

  @override
  State<_HeightReporter> createState() => _HeightReporterState();
}

class _HeightReporterState extends State<_HeightReporter> {
  final _key = GlobalKey();

  void _report() {
    final callback = widget.onHeightChanged;
    if (callback == null) return;
    final render = _key.currentContext?.findRenderObject() as RenderBox?;
    final size = render?.size;
    callback(size?.height.isFinite == true ? size!.height : 0);
  }

  @override
  Widget build(BuildContext context) {
    final callback = widget.onHeightChanged;
    if (callback == null) return widget.child;
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _report();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        key: _key,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _report();
            });
            return widget.child;
          },
        ),
      ),
    );
  }
}

/// 聊天输入栏(逐值移植自上游 ChatInputBar.kt 的 Phase 1 子集):
/// 圆角 14 的输入卡片(1px 描边 + surface@98%)内是透明 TextField + 底部一行
/// 「模式胶囊 / 模型按钮 / 思考强度按钮 / 发送(停止)按钮」。
/// 附件、工作区、斜杠命令等按钮属后续阶段。
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    super.key,
    required this.state,
    required this.session,
    required this.input,
    required this.onSend,
    required this.onStop,
    required this.onPickModel,
    required this.onPickEffort,
    required this.onRemoveAttachment,
    required this.onUploadFile,
    required this.onAttachImage,
    required this.onTakePhoto,
    this.uploadingCount,
    this.onHeightChanged,
  });

  final ChatViewState state;
  final ChatSession? session;
  final TextEditingController input;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final VoidCallback onPickModel;
  final ValueChanged<ReasoningEffort> onPickEffort;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onUploadFile;
  final VoidCallback onAttachImage;
  final VoidCallback onTakePhoto;

  /// 正在上传的附件数(>0 时输入框上方挂上传提示条)。
  final int uploadingCount = 0;

  /// 整栏高度变化回调:欢迎页用它把文案向上抬(对齐上游 inputBarReservePx)。
  final ValueChanged<double>? onHeightChanged;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  MentionController? _mention;

  /// 按钮打开面板时预置 `@` 的位置(确认时兜底用;手动输入触发的会话为 null)。
  int? _mentionAnchor;

  /// 提及面板的来源:null = 不显示;'skill' / 'file' 决定列出什么。
  /// 从按钮打开时也走同一面板(预填 `@` 到输入框,行为与手动输入一致)。
  String? _mentionPanelKind;

  @override
  void initState() {
    super.initState();
    _mention = MentionController(widget.input);
    widget.input.addListener(_onInputChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      oldWidget.input.removeListener(_onInputChanged);
      widget.input.addListener(_onInputChanged);
      _mention = MentionController(widget.input);
    }
  }

  @override
  void dispose() {
    widget.input.removeListener(_onInputChanged);
    super.dispose();
  }

  /// 输入框内容变化:跟随光标前缀同步面板——
  /// 出现 `@` 前缀就按按钮同款方式开面板(未指定 kind 时默认技能),前缀消失则收回。
  void _onInputChanged() {
    if (!mounted) return;
    final query = _mention?.current();
    if (query == null) {
      if (_mentionPanelKind != null) setState(() => _mentionPanelKind = null);
      return;
    }
    // `@`/`#` 还在:面板保持;正在输入筛选词时也要 setState 让面板拿到新 filter。
    final kind = query.trigger == '#' ? 'file' : 'skill';
    setState(() => _mentionPanelKind ??= kind);
  }

  ChatViewState get state => widget.state;
  ChatSession? get session => widget.session;
  TextEditingController get input => widget.input;
  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.streaming;
    final enterToSend = ref.watch(generalSettingsProvider).enterToSend;
    return _HeightReporter(
      onHeightChanged: widget.onHeightChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 键盘弹起后可用高度被压缩;提及面板固定 240 会把输入栏顶出屏幕。
          // 按剩余高度动态收窄面板:给输入卡片留 ~140dp,最多仍显示 240。
          final available =
              constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity;
          final panelMax = (available - 140).clamp(0, 240).toDouble();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.uploadingCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xs),
            child: _UploadingBanner(count: widget.uploadingCount),
          ),
        // 待办面板:与输入卡片同宽、位于其上方(上游 ChatInputBar 内的 TodoDashboardBar)。
        if (widget.session != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TodoDashboardBar(
              sessionId: widget.session!.id,
              forceCollapse: widget.state.pendingPermission != null,
            ),
          ),
        // @ 提及面板(对齐截图:输入框上方浮出,条目 = @ 图标 + 标题 + 描述,底部筛选提示)。
        if (_mentionPanelKind != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xs),
            child: _MentionPanel(
              kind: _mentionPanelKind!,
              query: _mention?.current(),
              onConfirm: _confirmMention,
              onClose: _closeMentionPanel,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.light
                        ? [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)]
                        : [
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(width: 0.5, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.state.pendingAttachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.xs, Spacing.xs, Spacing.xs, 0),
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.state.pendingAttachments.length,
                        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
                        itemBuilder: (context, index) => _PendingAttachmentTile(
                          attachment: widget.state.pendingAttachments[index],
                          onRemove: () => widget.onRemoveAttachment(index),
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: widget.input,
                  minLines: 1,
                  maxLines: 5,
                  // 回车语义:面板开着 = 确认首条候选(textInputAction 相应升级为 done,
                  // 否则 newline 会让系统插换行而不走 onSubmitted);否则按发送设置走
                  //(开启时 send 键发送,关闭时保留换行,对齐上游 ChatInputBar)。
                  textInputAction: _mentionPanelKind != null
                      ? TextInputAction.done
                      : (enterToSend ? TextInputAction.send : TextInputAction.newline),
                  onSubmitted: (value) async {
                    if (_mentionPanelKind != null) {
                      final first = await _firstCandidate();
                      if (first != null) {
                        await _confirmMention(first);
                        return;
                      }
                    }
                    if (enterToSend) widget.onSend(value);
                  },
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: busy ? l10n.chatQueueHint : l10n.chatInputPlaceholder,
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.xs),
                  child: Row(
                    children: [
                      // 运行模式切换:点击循环切换 BUILD → PLAN → AUTO → BUILD
                      Builder(
                        builder: (context) {
                          final current = ref.watch(runModeProvider);
                          final semantic = context.semantic;
                          final bgColor = switch (current) {
                            AgentRunMode.plan => Theme.of(context).colorScheme.primaryContainer,
                            AgentRunMode.auto => Theme.of(context).colorScheme.error,
                            AgentRunMode.build => semantic.successContainer,
                          };
                          final textColor = switch (current) {
                            AgentRunMode.plan => Theme.of(context).colorScheme.onPrimaryContainer,
                            AgentRunMode.auto => Theme.of(context).colorScheme.onError,
                            AgentRunMode.build => semantic.onSuccessContainer,
                          };
                          final label = switch (current) {
                            AgentRunMode.auto => l10n.runModeAuto,
                            AgentRunMode.build => l10n.runModeBuild,
                            AgentRunMode.plan => l10n.runModePlan,
                          };
                          return GestureDetector(
                            onTap: () {
                              final next = switch (current) {
                                AgentRunMode.build => AgentRunMode.plan,
                                AgentRunMode.plan => AgentRunMode.auto,
                                AgentRunMode.auto => AgentRunMode.build,
                              };
                              ref.read(runModeProvider.notifier).state = next;
                            },
                            child: Container(
                              width: 46,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: Spacing.xs),
                      // 工具按钮组:紧凑左对齐(对齐上游 weight(1f) 的排布)。
                      // 窄屏放不下时组内横向滚动(而不是整行溢出),附件与发送键始终贴右可见。
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _IconAction(
                              icon: Iconfont.atSign,
                              tooltip: l10n.chatMentionSkill,
                              onTap: () => _openMention('skill'),
                            ),
                            _IconAction(
                              icon: Iconfont.filePlus,
                              tooltip: l10n.chatPickFile,
                              onTap: () => _openMention('file'),
                            ),
                            // 模型按钮显示当前模型的品牌 logo(对齐上游 ModelIconButton);
                            // Auto 时没有具体模型,用通用芯片图标。
                            _ModelIconAction(
                              modelName: _currentModelName(),
                              tooltip: l10n.model,
                              onTap: widget.onPickModel,
                            ),
                            // 思考强度:紧跟工作区按钮之后(对齐上游顺序),固定可见、不参与滚动。
                            _IconAction(
                              icon: Iconfont.zap,
                              tooltip: l10n.reasoningEffort,
                              enabled: !busy,
                              onTap: () => _pickEffort(
                                context,
                                widget.session?.reasoningEffort ?? ReasoningEffort.medium,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                      _IconAction(
                        icon: Iconfont.plus,
                        tooltip: l10n.chatAddAttachment,
                        enabled: !busy,
                        onTap: () => _pickAttachment(context),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.input,
                        builder: (context, value, _) => _SendButton(
                          // 附件本身即内容:只传了文件/图片、没打字时也要能直接发送
                          //(send() 本就允许空正文 + 附件,这里只差按钮的可点态)。
                          hasContent: value.text.trim().isNotEmpty ||
                              widget.state.pendingAttachments.isNotEmpty,
                          busy: busy,
                          onSend: () => widget.onSend(value.text),
                          onStop: widget.onStop,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        ),
            ],
          );
        }
      )
    );
  }

  /// 打开提及面板(kind = 'skill' | 'file')。
  ///
  /// 与手动在输入框里敲 `@` 同一套状态:先把 `@` 写进输入框(光标处),面板随之出现;
  /// 选中后 MentionController 把 `@` 换成完整提及;关闭面板则把未完成的 `@` 撤掉。
  void _openMention(String kind) {
    final controller = _mention;
    if (controller == null) return;
    _mentionAnchor = controller.current()?.anchor;
    if (_mentionAnchor == null) {
      // 光标处补一个 `@`,让面板与手动输入走同一条路径。
      final trigger = kind == 'file' ? '#' : '@';
      final value = controller.input.value;
      final caret = value.selection.isValid
          ? value.selection.baseOffset
          : value.text.length;
      controller.input.value = TextEditingValue(
        text: '${value.text.substring(0, caret)}$trigger${value.text.substring(caret)}',
        selection: TextSelection.collapsed(offset: caret + 1),
      );
      _mentionAnchor = caret;
    }
    setState(() => _mentionPanelKind = kind);
  }

  /// 当前面板的首条候选(回车确认目标);拿不到时返回 null(面板随会话自动收回)。
  Future<String?> _firstCandidate() async {
    if (_mentionPanelKind == 'skill') {
      final skills = ref.read(_mentionSkillsProvider);
      return skills.isEmpty ? null : skills.first.token;
    }
    if (_mentionPanelKind == 'file') {
      final filter = _mention?.current()?.filter ?? '';
      final files = await ref.read(_mentionFilesProvider(filter).future);
      return files.isEmpty ? null : files.first.token;
    }
    return null;
  }

  void _closeMentionPanel({required bool cancelToken}) {
    if (cancelToken) _mention?.cancel();
    if (mounted) setState(() => _mentionPanelKind = null);
  }

  Future<void> _confirmMention(String name) async {
    // 按钮预置的 `@` 前面若是非空白字符(如「请用@」),confirm 的空白检查会拒识,
    // 这里把打开面板时的 anchor 传下去兜底。
    final trigger = _mentionPanelKind == 'file' ? '#' : '@';
    await _mention?.confirm(name, forceAnchor: _mentionAnchor, trigger: trigger);
    if (mounted) setState(() => _mentionPanelKind = null);
  }

  /// 添加附件弹层(对齐上游 AttachmentSheet):标题 + 上传文件 / 上传图片 / 拍照。
  Future<void> _pickAttachment(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(
                  l10n.chatAddAttachment,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _SheetItem(
                icon: Iconfont.fileText,
                title: l10n.chatUploadFile,
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onUploadFile();
                },
              ),
              _SheetItem(
                icon: Iconfont.image,
                title: l10n.chatUploadImage,
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onAttachImage();
                },
              ),
              _SheetItem(
                icon: Iconfont.camera,
                title: l10n.chatTakePhoto,
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onTakePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 输入区按钮要显示的模型名:Auto / 未指定时为空(用通用图标)。
  String _currentModelName() {
    final session = widget.session;
    if (session == null) return '';
    final model = session.model?.trim() ?? '';
    if (isAutoModel(model)) return '';
    if (model.isNotEmpty) return model;
    // 同上:watch 以便供应商数据就绪后按钮能立即显示模型 logo。
    for (final provider in ref.watch(providersProvider).valueOrNull ?? const <ProviderConfig>[]) {
      if (provider.id == session.providerId) return provider.effectiveModel;
    }
    return '';
  }

  /// 当前会话可用模型支持哪些思考强度档位(对齐上游):
  /// 有 `reasoningEffortOptions` 就按它过滤,没有则回退到全部档位。
  List<ReasoningEffort> _availableEfforts() {
    final session = widget.session;
    if (session == null) return ReasoningEffort.values;
    // 用 watch:供应商列表是异步加载的,冷启动时若用 read 会拿到空列表,
    // 档位就会错误地回退成「全部档位」;watch 能在数据就绪后自动刷新。
    final providers = ref.watch(providersProvider).valueOrNull ?? const <ProviderConfig>[];
    ProviderConfig? provider;
    for (final candidate in providers) {
      if (candidate.id == session.providerId) {
        provider = candidate;
        break;
      }
    }
    provider ??= providers.where((p) => p.isEnabled).firstOrNull;
    if (provider == null) return ReasoningEffort.values;
    final model = (session.model?.trim().isNotEmpty == true
            ? session.model!
            : provider.effectiveModel)
        .trim();
    if (model.isEmpty) return ReasoningEffort.values;
    final catalog = ref.watch(modelCatalogProvider).valueOrNull;
    final custom = ref.watch(customModelMetadataProvider).valueOrNull ?? const {};
    final metadata = resolveModelMetadata(
      catalog ?? ModelCatalog.empty,
      custom,
      providerId: provider.id,
      model: model,
    );
    final options = metadata?.reasoningEffortOptions;
    if (options == null || options.isEmpty) return ReasoningEffort.values;
    final parsed = ReasoningEffort.fromValues(options);
    return parsed.isEmpty ? ReasoningEffort.values : parsed;
  }

  /// 当前档位是否在可用档位里;不在时选最接近的一档(避免显示一个模型不支持的档位)。
  static ReasoningEffort _effectiveEffort(
    ReasoningEffort current,
    List<ReasoningEffort> available,
  ) {
    if (available.contains(current)) return current;
    if (available.isEmpty) return current;
    // 按枚举顺序找最近的档位。
    var best = available.first;
    var bestDistance = (best.index - current.index).abs();
    for (final effort in available) {
      final distance = (effort.index - current.index).abs();
      if (distance < bestDistance) {
        best = effort;
        bestDistance = distance;
      }
    }
    return best;
  }

  Future<void> _pickEffort(BuildContext context, ReasoningEffort current) async {
    final l10n = AppLocalizations.of(context);
    final available = _availableEfforts();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
                child: Text(
                  l10n.reasoningEffort,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: Spacing.xl),
                  children: [
                    for (final effort in available)
                      _EffortRow(
                        label: effortLabel(l10n, effort),
                        selected: effort == _effectiveEffort(current, available),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          widget.onPickEffort(effort);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 思考强度档位文案(上游 chat_reasoning_effort_*)。
String effortLabel(AppLocalizations l10n, ReasoningEffort effort) => switch (effort) {
      ReasoningEffort.none => l10n.chatEffortNone,
      ReasoningEffort.minimal => l10n.chatEffortMinimal,
      ReasoningEffort.low => l10n.chatEffortLow,
      ReasoningEffort.medium => l10n.chatEffortMedium,
      ReasoningEffort.high => l10n.chatEffortHigh,
      ReasoningEffort.xhigh => l10n.chatEffortXHigh,
      ReasoningEffort.max => l10n.chatEffortMax,
    };

/// 36dp 图标按钮(上游 ModelIconButton / ReasoningEffortSelector):图标 20dp、onSurfaceVariant。
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tint = enabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    // 用 36dp 定尺寸(对齐上游 IconButton 的 size(36.dp)):
    // IconButton 默认最小点击区是 48dp,只给 constraints 下限时实际仍占 48dp,
    // 按钮之间就会多出 12dp 空隙、窄屏还会把末尾的思考强度挤出可视区。
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 20,
        color: tint,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

/// 发送按钮(上游 SendButton):44dp 外框 + 36dp 圆钮;
/// 空闲可发=成功绿,流式中=红色停止方块。
///
/// 流式中**始终**显示停止键:早先只在输入框为空时才是停止键,用户打了字就只剩
/// 一个点不动的发送键(流式期间 `send` 直接返回 false),等于没法中断对话。
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.hasContent,
    required this.busy,
    required this.onSend,
    required this.onStop,
  });

  final bool hasContent;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final showStop = busy;
    final canSend = !busy && hasContent;
    final clickable = showStop || canSend;
    final Color buttonColor;
    if (showStop) {
      buttonColor = Theme.of(context).colorScheme.error;
    } else if (canSend) {
      buttonColor = semantic.success;
    } else {
      buttonColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    final Color iconTint;
    if (!clickable) {
      iconTint = Theme.of(context).colorScheme.onSurfaceVariant;
    } else {
      iconTint = buttonColor.computeLuminance() > 0.5 ? const Color(0xFF1C1C1E) : Colors.white;
    }
    return Padding(
      padding: const EdgeInsets.all(Spacing.xs),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: clickable ? (showStop ? onStop : onSend) : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                showStop ? Icons.square : Iconfont.arrowUp,
                size: 18,
                color: iconTint,
                semanticLabel: showStop ? l10n.stop : l10n.send,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 待发送附件的小方块(上游 PendingAttachmentPreviewItem):76dp、圆角 md、
/// 浅色胶囊底色;图片显示缩略图(可点开全屏),其它文件显示图标 + 名称 + 大小。
class _PendingAttachmentTile extends StatelessWidget {
  const _PendingAttachmentTile({required this.attachment, required this.onRemove});

  final AgentAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: 76,
      height: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: attachment.isImage ? _imageTile(context) : _fileTile(context),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                  iconSize: 14,
                  color: theme.colorScheme.onSurface,
                  tooltip: l10n.removeAttachment,
                  icon: const Icon(Iconfont.x),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile(BuildContext context) {
    return InkWell(
      onTap: () => showImagePreview(
        context,
        path: attachment.localPath,
        title: attachment.fileName,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Image.file(
          File(attachment.localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholder(context, Iconfont.image),
        ),
      ),
    );
  }

  Widget _fileTile(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fileText, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            attachment.fileName,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            formatBytes(attachment.sizeBytes),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.72),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon) {
    return ColoredBox(
      color: context.semantic.mutedSurface,
      child: Center(
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// 上传进行中的提示条(上游 UploadingBanner):大文件传输耗时较久,没有反馈会像卡死。
class _UploadingBanner extends StatelessWidget {
  const _UploadingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            l10n.attachmentUploading(count),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// 底部弹层的功能行(上游 AttachmentSheetItem):图标 20dp(primary 色)+ 12dp 间隔 + bodyLarge。
class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 思考强度档位行(上游 ReasoningEffortSelector 的底部弹层行)。
class _EffortRow extends StatelessWidget {
  const _EffortRow({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final subtle = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        child: Row(
          children: [
            Icon(Iconfont.zap, size: 20, color: selected ? primary : subtle),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected ? primary : Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected) Icon(Icons.check, size: 20, color: primary),
          ],
        ),
      ),
    );
  }
}

/// @ 提及面板:浮在输入框上方(不挡键盘),kind 决定列技能还是列文件。
///
/// 交互对齐截图:条目 = @ 图标 + 加粗标题 + 一行描述;底部一行「继续输入可筛选」。
/// 筛选词来自输入框里 `@` 之后的光标前缀([MentionQuery.filter]),由父级 setState 驱动刷新。
class _MentionPanel extends ConsumerWidget {
  const _MentionPanel({
    required this.kind,
    required this.query,
    required this.onConfirm,
    required this.onClose,
  });

  final String kind;
  final MentionQuery? query;
  final ValueChanged<String> onConfirm;
  final void Function({required bool cancelToken}) onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filter = query?.filter ?? '';

    final hint = kind == 'skill' ? l10n.mentionHintSkill : l10n.mentionHintFile;
    // 技能清单同步可得,按筛选词就地过滤;文件清单走远端引擎,按 filter 参数化。
    final itemsAsync = kind == 'skill'
        ? AsyncValue.data([
            for (final item in ref.watch(_mentionSkillsProvider))
              if (filter.isEmpty ||
                  item.title.toLowerCase().contains(filter) ||
                  item.subtitle.toLowerCase().contains(filter))
                item,
          ])
        : ref.watch(_mentionFilesProvider(filter));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: itemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(
                    '$error',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Row(
                        children: [
                          Icon(Iconfont.info, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              kind == 'skill'
                                  ? l10n.chatMentionSkillEmpty
                                  : l10n.chatPickFileEmpty,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => onClose(cancelToken: true),
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = index == 0;
                      return InkWell(
                        onTap: () => onConfirm(item.token),
                        child: Container(
                          color: selected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                kind == 'file' ? Iconfont.hash : Iconfont.atSign,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    if (item.subtitle.isNotEmpty)
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Text(
                '$hint「$filter」',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 面板条目:[token] 是确认后写进输入框的提及文本(`writer` 或 `~/workspace/lib/main.dart`)。
class MentionItem {
  const MentionItem({required this.token, required this.title, this.subtitle = ''});

  final String token;
  final String title;
  final String subtitle;
}

/// 启用的技能清单(面板数据源;与系统提示注入的口径一致)。
///
/// 从 [skillsProvider] 派生而不是重新扫盘:同一份数据两个用途,禁用过滤用
/// [disabledSkillsProvider](未加载完时视为全启用,只影响排序不出错)。
final _mentionSkillsProvider = Provider.autoDispose<List<MentionItem>>((ref) {
  final skills = ref.watch(skillsProvider).valueOrNull ?? const <SkillEntry>[];
  final disabled = ref.watch(disabledSkillsProvider).valueOrNull ?? const <String>{};
  return [
    for (final entry in skills)
      if (!disabled.contains(entry.skill.name.toLowerCase()))
        MentionItem(
          token: entry.skill.name,
          title: entry.skill.name,
          subtitle: entry.skill.description,
        ),
  ];
});

/// 按筛选词过滤的文件清单(相对工作区根;上限 50 条避免巨树卡顿)。
final _mentionFilesProvider = FutureProvider.autoDispose.family<List<MentionItem>, String>(
  (ref, filter) async {
    final files = await ref.watch(workspaceFilesProvider.future);
    final root = ref.watch(currentWorkspaceProvider).rootPath;

    final results = <MentionItem>[];
    Future<void> walk(String dir, String prefix) async {
      if (results.length >= 50) return;
      final entries = await files.listDir(dir);
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      for (final entry in entries) {
        if (results.length >= 50) return;
        if (entry.name.startsWith('.')) continue;
        final relative = prefix.isEmpty ? entry.name : '$prefix/${entry.name}';
        if (entry.isDirectory) {
          await walk('$dir${Platform.pathSeparator}${entry.name}', relative);
        }
        // 文件一律列出;目录只有带内容(递归里有文件)或非空时由子层给出——
        // 空目录单独列出,否则用户没法提一个空目录。
        if (filter.isEmpty || relative.toLowerCase().contains(filter)) {
          results.add(MentionItem(
            token: relative,
            title: relative,
          ));
        }
      }
    }

    await walk(root, '');
    return results;
  },
);

/// 模型按钮:有具体模型时显示品牌 logo,Auto/未知时显示通用芯片图标。
class _ModelIconAction extends StatelessWidget {
  const _ModelIconAction({
    required this.modelName,
    required this.tooltip,
    required this.onTap,
  });

  final String modelName;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: modelName.trim().isEmpty
            ? Icon(Icons.memory, size: 20, color: tint)
            : ModelLogoIcon(modelName: modelName, size: 20),
      ),
    );
  }
}
