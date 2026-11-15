import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/models/chat_session.dart';
import '../../agent/models/model_metadata.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/provider_logo.dart';
import '../../core/ui/settings_group.dart';
import '../../data/model_api_service.dart';
import '../../data/model_catalog.dart';
import '../../data/model_metadata_store.dart';
import '../../data/providers/provider_config.dart';
import '../../l10n/app_localizations.dart';

/// 模型能力 / 窗口标签(对齐上游 ModelMetadataTags):
/// 「图片」「工具」胶囊在前,输入(窗口或输入上限)与输出上限合并的胶囊在后。
class ModelMetadataTags extends StatelessWidget {
  const ModelMetadataTags({super.key, required this.metadata, this.trailing = const []});

  final ModelMetadata? metadata;

  /// 追加在能力标签之后的额外胶囊(如「当前」)。
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final data = metadata;
    final pills = <Widget>[];
    if (data != null) {
      // 顺序对齐上游 ModelMetadataTags:图片 / 工具在前,token 上下限在后。
      if (data.supportsVision) pills.add(ModelTagPill(texts: ['图片']));
      if (data.supportsTools) pills.add(ModelTagPill(texts: ['工具']));
      // 窗口是兜底推断值时不展示:否则所有未知模型都是同一个 ↑128k ↓64k,反而误导。
      if (!data.estimated) {
        final input = data.inputTokens != null && data.inputTokens! > 0
            ? data.inputTokens!
            : data.contextTokens;
        final output =
            data.outputTokens != null && data.outputTokens! > 0 ? data.outputTokens! : 0;
        final tokens = [
          if (input > 0) '↑${formatTokenLimit(input)}',
          if (output > 0) '↓${formatTokenLimit(output)}',
        ];
        if (tokens.isNotEmpty) pills.add(ModelTagPill(texts: tokens));
      }
    }
    if (pills.isEmpty && trailing.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [...pills, ...trailing],
      ),
    );
  }
}

/// 单个标签胶囊(可含多个文本片段,如 ↑128k ↓32k)。
class ModelTagPill extends StatelessWidget {
  const ModelTagPill({super.key, required this.texts});

  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < texts.length; index++) ...[
            if (index > 0) const SizedBox(width: Spacing.xs),
            Text(
              texts[index],
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 上下文长度简写(对齐上游 formatTokenLimit):128K / 1.2M;小数位截断而非四舍五入。
String formatTokenLimit(int tokens) {
  String trimDecimal(String text) {
    final replaced = text.replaceAllMapped(
      RegExp(r'(\.\d)\d+'),
      (match) => match.group(1)!,
    );
    return replaced.endsWith('.0') ? replaced.substring(0, replaced.length - 2) : replaced;
  }

  if (tokens >= 1000000 && tokens % 1000000 == 0) return '${tokens ~/ 1000000}M';
  if (tokens >= 1000000) return '${trimDecimal((tokens / 1000000).toString())}M';
  if (tokens >= 1000 && tokens % 1000 == 0) return '${tokens ~/ 1000}k';
  if (tokens >= 1000) return '${trimDecimal((tokens / 1000).toString())}k';
  return '$tokens';
}

/// 拉取模型弹层(对齐上游 FetchModelsDialog):进来自动请求一次,
/// 按品牌分组展示可新增的模型,支持搜索、单个添加与全部添加;
/// 新增的模型通过 [onAddModels] 回给编辑页(由编辑页统一保存),
/// [onFetched] 在拉取成功时回传远端模型全集(供编辑页对齐本地列表)。
Future<void> showFetchModelsSheet(
  BuildContext context, {
  required ProviderConfig provider,
  required ValueChanged<List<String>> onAddModels,
  required ValueChanged<List<String>> onFetched,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _FetchModelsSheet(provider: provider, onAddModels: onAddModels, onFetched: onFetched),
  );
}

class _FetchModelsSheet extends ConsumerStatefulWidget {
  const _FetchModelsSheet({
    required this.provider,
    required this.onAddModels,
    required this.onFetched,
  });

  final ProviderConfig provider;
  final ValueChanged<List<String>> onAddModels;
  final ValueChanged<List<String>> onFetched;

  @override
  ConsumerState<_FetchModelsSheet> createState() => _FetchModelsSheetState();
}

class _FetchModelsSheetState extends ConsumerState<_FetchModelsSheet> {
  final _search = TextEditingController();
  final _added = <String>[];
  List<String>? _models;
  ModelTestResult? _debug;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    // 等弹层动画稳定后再发请求(对齐上游 delay(300))。
    Timer(const Duration(milliseconds: 300), _fetch);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(modelApiProvider).fetchModels(
            provider: widget.provider,
            apiKey: widget.provider.firstUsableApiKey,
            messageForKeyMissing: l10n.providerApiKeyRequired,
            messageMissingFields: l10n.providerFetchMissingFields,
            messageFailed: l10n.providerFetchFailed,
          );
      if (!mounted) return;
      // 服务端在 /models 里声明的窗口落盘,模型行才能显示真实 ↑/↓;
      // 没声明的模型不再用兜底值伪装真实数据(标签会隐藏)。
      await _persistFetchedMetadata(result);
      if (!mounted) return;
      setState(() {
        _models = result.models;
        _debug = result.debugInfo;
        _loading = false;
      });
      widget.onFetched(result.models);
    } on FetchModelsException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _debug = error.debugInfo;
        _loading = false;
      });
    } catch (error) {
      // 未预期异常也要收尾,否则弹层会永远停在加载中。
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  /// 把服务端声明的窗口写进自定义元数据:能力标签沿用目录识别结果,避免把
  /// 「服务端没声明」误判成「不支持工具」。
  Future<void> _persistFetchedMetadata(FetchModelsResult result) async {
    if (result.metadata.isEmpty) return;
    // 等目录加载完再取能力标签:目录没就绪时会把「不支持图片/思考」的默认值写进自定义
    // 元数据,之后这些模型就只剩兜底的「工具」标签,再也匹配不上目录里的真实能力。
    final catalog = await ref.read(modelCatalogProvider.future);
    final custom = ref.read(customModelMetadataProvider).valueOrNull ?? const {};
    final entries = <String, ModelMetadata>{};
    for (final entry in result.metadata.entries) {
      final base = resolveModelMetadata(
        catalog,
        custom,
        providerId: widget.provider.id,
        model: entry.key,
        type: widget.provider.type,
      );
      entries[entry.key] = ModelMetadata(
        id: entry.key,
        providerId: widget.provider.id,
        displayName: base.displayName,
        contextTokens: entry.value.contextTokens,
        inputTokens: entry.value.inputTokens,
        outputTokens: entry.value.outputTokens,
        supportsTools: base.supportsTools,
        supportsVision: base.supportsVision,
        supportsReasoning: base.supportsReasoning,
        supportsImageOutput: base.supportsImageOutput,
        reasoningCanDisable: base.reasoningCanDisable,
        reasoningEffortOptions: base.reasoningEffortOptions,
      );
    }
    await ref.read(modelMetadataStoreProvider).putAll(widget.provider.id, entries);
    ref.invalidate(customModelMetadataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = [...widget.provider.models, ..._added];
    final available = [
      for (final model in _models ?? const <String>[])
        if (!existing.contains(model)) model,
    ];
    final query = _search.text.trim().toLowerCase();
    final filtered = [
      for (final model in available)
        if (query.isEmpty || model.toLowerCase().contains(query)) model,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.providerFetchModels,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (available.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _addAll(l10n, available),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.providerAddAllModels),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.providerFilterModelsHint,
                prefixIcon: const Icon(Iconfont.search, size: 16),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              height: 380,
              child: _body(context, l10n, filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, List<String> filtered) {
    if (_loading) return const _FetchSkeleton();
    if (_error != null) {
      final code = _debug?.responseCode ?? 0;
      final message = code > 0
          ? l10n.providerFetchHttpError(code, _debug?.latencyMs ?? 0)
          : _error!;
      return Center(
        child: TextButton.icon(
          onPressed: _debug == null
              ? null
              : () => showModelTestSheet(
                    context,
                    title: l10n.providerFetchModels,
                    result: _debug!,
                  ),
          icon: Icon(Iconfont.alertCircle, size: 16, color: Theme.of(context).colorScheme.error),
          label: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.providerNoMatchingModels,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.semantic.subtleText),
        ),
      );
    }

    // 按品牌分组,「other」永远排最后,其余按显示名排序。
    final grouped = <String, List<String>>{};
    for (final model in filtered) {
      grouped.putIfAbsent(modelBrandKey(model), () => []).add(model);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'other') return 1;
        if (b == 'other') return -1;
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      children: [
        for (final key in keys) ...[
          SettingsGroupHeader(text: '$key (${grouped[key]!.length})'),
          SettingsGroup(
            children: [
              for (var index = 0; index < grouped[key]!.length; index++) ...[
                if (index > 0) const SettingsDivider(),
                _fetchRow(context, l10n, grouped[key]![index]),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _fetchRow(BuildContext context, AppLocalizations l10n, String model) {
    final theme = Theme.of(context);
    // 拉取结果同样解析能力标签(对齐上游 FetchModelRow:目录 + 自定义元数据)。
    final catalog = ref.watch(modelCatalogProvider).valueOrNull ?? ModelCatalog.empty;
    final custom = ref.watch(customModelMetadataProvider).valueOrNull ?? const {};
    final metadata = resolveModelMetadata(
      catalog,
      custom,
      providerId: widget.provider.id,
      model: model,
      type: widget.provider.type,
    );
    return InkWell(
      onTap: () => _add(l10n, model),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
        child: Row(
          children: [
            ModelLogoIcon(modelName: model, size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ModelMetadataTags(metadata: metadata),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _add(l10n, model),
              icon: Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
              tooltip: l10n.commonAdd,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(AppLocalizations l10n, String model) async {
    await _addModels([model]);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.providerModelAdded(model))));
  }

  Future<void> _addAll(AppLocalizations l10n, List<String> models) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.providerAddAllModelsTitle),
        content: Text(l10n.providerAddAllModelsConfirm(models.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.providerAddAllModels),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _addModels(models);
    if (!mounted) return;
    Navigator.pop(context);
  }
  /// 新增的模型交回编辑页(由编辑页统一并入配置并保存)。
  Future<void> _addModels(List<String> models) async {
    final fresh = [
      for (final model in models)
        if (!_added.contains(model)) model,
    ];
    if (fresh.isEmpty) return;
    setState(() => _added.addAll(fresh));
    widget.onAddModels(fresh);
  }
}

/// 拉取中骨架屏(对齐上游 FetchModelsSkeleton):品牌标题 + 模型行占位块。
class _FetchSkeleton extends StatelessWidget {
  const _FetchSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = context.semantic.subtleBorder;
    Widget block({double width = double.infinity, double height = 14}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        block(width: 120, height: 12),
        const SizedBox(height: Spacing.sm),
        SettingsGroup(
          children: [
            for (var index = 0; index < 6; index++) ...[
              if (index > 0) const SettingsDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 14),
                child: Row(
                  children: [
                    block(width: 22, height: 22),
                    const SizedBox(width: Spacing.md),
                    Expanded(child: block(width: 160)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 模型编辑弹层(对齐上游 AddModelSheet):名称 + 窗口/上限 + 价格 + 能力开关 + 思考档位;
/// [title] 区分添加/编辑,[existingModels] 用于重复校验,[confirmLabel] 覆盖保存按钮文案。
Future<ModelMetadata?> showModelEditSheet(
  BuildContext context, {
  required String model,
  ModelMetadata? metadata,
  bool canEditName = true,
  String? title,
  String? confirmLabel,
  List<String> existingModels = const [],
}) {
  return showModalBottomSheet<ModelMetadata>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ModelEditSheet(
      model: model,
      metadata: metadata,
      canEditName: canEditName,
      title: title,
      confirmLabel: confirmLabel,
      existingModels: existingModels,
    ),
  );
}

class _ModelEditSheet extends StatefulWidget {
  const _ModelEditSheet({
    required this.model,
    this.metadata,
    this.canEditName = true,
    this.title,
    this.confirmLabel,
    this.existingModels = const [],
  });

  final String model;
  final ModelMetadata? metadata;
  final bool canEditName;
  final String? title;
  final String? confirmLabel;
  final List<String> existingModels;

  @override
  State<_ModelEditSheet> createState() => _ModelEditSheetState();
}

class _ModelEditSheetState extends State<_ModelEditSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.model);
  late final TextEditingController _context =
      TextEditingController(text: _number(widget.metadata?.contextTokens));
  late final TextEditingController _input =
      TextEditingController(text: _number(widget.metadata?.inputTokens));
  late final TextEditingController _output =
      TextEditingController(text: _number(widget.metadata?.outputTokens));
  late final TextEditingController _priceIn =
      TextEditingController(text: _number(widget.metadata?.inputCostUsdPerM));
  late final TextEditingController _priceOut =
      TextEditingController(text: _number(widget.metadata?.outputCostUsdPerM));
  late final TextEditingController _priceCacheRead =
      TextEditingController(text: _number(widget.metadata?.cacheReadCostUsdPerM));
  late final TextEditingController _priceCacheWrite =
      TextEditingController(text: _number(widget.metadata?.cacheWriteCostUsdPerM));
  late bool _vision = widget.metadata?.supportsVision ?? false;
  late bool _imageOutput = widget.metadata?.supportsImageOutput ?? false;
  late bool _tools = widget.metadata?.supportsTools ?? false;
  late bool _reasoning = widget.metadata?.supportsReasoning ?? false;
  // 思考档位(对齐上游 AddModelSheet):勾选写进自定义元数据,全部不勾则回退目录自动判断。
  late bool _reasoningCanDisable = widget.metadata?.reasoningCanDisable ?? false;
  late final Set<String> _reasoningLevels = {
    ...?widget.metadata?.reasoningEffortOptions,
  };

  /// 可手动标注的思考档位(不含「不思考」:能否关闭由单独开关表达)。
  static const _editableLevels = [
    ReasoningEffort.minimal,
    ReasoningEffort.low,
    ReasoningEffort.medium,
    ReasoningEffort.high,
    ReasoningEffort.xhigh,
    ReasoningEffort.max,
  ];

  static String _number(Object? value) {
    if (value == null) return '';
    if (value is int) return value == 0 ? '' : '$value';
    return '$value';
  }

  String get _trimmedName => _name.text.trim();

  bool get _duplicate =>
      widget.existingModels.any((m) => m == _trimmedName && m != widget.model);

  bool get _contextError => _intError(_context.text);
  bool get _inputError => _intError(_input.text);
  bool get _outputError => _intError(_output.text);

  bool get _canSave =>
      _trimmedName.isNotEmpty && !_duplicate && !_contextError && !_inputError && !_outputError;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _context,
      _input,
      _output,
      _priceIn,
      _priceOut,
      _priceCacheRead,
      _priceCacheWrite,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 居中标题栏(对齐上游 AddModelSheet:仿 MCP 编辑对话框)。
            Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    widget.title ?? l10n.providerAddModel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      label: l10n.providerModelName,
                      controller: _name,
                      enabled: widget.canEditName,
                    ),
                    if (_duplicate)
                      Text(
                        l10n.providerModelAlreadyAdded,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelContext,
                      controller: _context,
                      keyboardType: TextInputType.number,
                      isError: _contextError,
                    ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelContextInput,
                      controller: _input,
                      keyboardType: TextInputType.number,
                      isError: _inputError,
                    ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelContextOutput,
                      controller: _output,
                      keyboardType: TextInputType.number,
                      isError: _outputError,
                    ),
                    const SizedBox(height: Spacing.md),
                    _sectionLabel(context, l10n.providerModelSectionPrice),
                    _field(
                      label: l10n.providerModelPriceInput,
                      controller: _priceIn,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelPriceOutput,
                      controller: _priceOut,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelPriceCacheRead,
                      controller: _priceCacheRead,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _field(
                      label: l10n.providerModelPriceCacheWrite,
                      controller: _priceCacheWrite,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: Spacing.md),
                    _sectionLabel(context, l10n.providerModelCapabilities),
                    // 能力开关卡片(对齐上游:mutedSurface 圆角 12,避免 surfaceVariant 偏蓝)。
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.semantic.mutedSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _capability(l10n.providerModelCapVision, _vision,
                              (v) => setState(() => _vision = v)),
                          const SettingsDivider(),
                          _capability(l10n.providerModelCapImageOutput, _imageOutput,
                              (v) => setState(() => _imageOutput = v)),
                          const SettingsDivider(),
                          _capability(l10n.providerModelCapTools, _tools,
                              (v) => setState(() => _tools = v)),
                          const SettingsDivider(),
                          _capability(l10n.providerModelCapReasoning, _reasoning,
                              (v) => setState(() => _reasoning = v)),
                        ],
                      ),
                    ),
                    if (_reasoning) ...[
                      const SizedBox(height: Spacing.md),
                      _sectionLabel(context, l10n.providerModelSectionReasoning),
                      Text(
                        l10n.providerModelReasoningHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      // 思考档位卡片:可关闭开关 + 手动标注档位(对齐上游 ReasoningLevelRow)。
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.semantic.mutedSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _capability(
                              l10n.providerModelReasoningCanDisable,
                              _reasoningCanDisable,
                              (v) => setState(() => _reasoningCanDisable = v),
                            ),
                            for (final level in _editableLevels) ...[
                              const SettingsDivider(),
                              _levelRow(l10n, level),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconfont.check, size: 18),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      widget.confirmLabel ?? l10n.save,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      ModelMetadata(
        id: _trimmedName,
        displayName: _trimmedName,
        contextTokens: int.tryParse(_context.text.trim()) ?? 0,
        inputTokens: int.tryParse(_input.text.trim()),
        outputTokens: int.tryParse(_output.text.trim()),
        inputCostUsdPerM: double.tryParse(_priceIn.text.trim()),
        outputCostUsdPerM: double.tryParse(_priceOut.text.trim()),
        cacheReadCostUsdPerM: double.tryParse(_priceCacheRead.text.trim()),
        cacheWriteCostUsdPerM: double.tryParse(_priceCacheWrite.text.trim()),
        supportsVision: _vision,
        supportsImageOutput: _imageOutput,
        supportsTools: _tools,
        supportsReasoning: _reasoning,
        reasoningCanDisable: _reasoningCanDisable,
        reasoningEffortOptions:
            _reasoningLevels.isEmpty ? null : _reasoningLevels.toList(),
      ),
    );
  }

  /// 数字字段校验:非空时必须为大于 0 的整数(对齐上游 canSave 逻辑)。
  bool _intError(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final value = int.tryParse(trimmed);
    return value == null || value <= 0;
  }

  /// 思考档位勾选行(对齐上游 ReasoningLevelRow):标题 + 勾选图标,点击切换。
  Widget _levelRow(AppLocalizations l10n, ReasoningEffort level) {
    final checked = _reasoningLevels.contains(level.apiValue);
    return InkWell(
      onTap: () => setState(() {
        if (checked) {
          _reasoningLevels.remove(level.apiValue);
        } else {
          _reasoningLevels.add(level.apiValue);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.commonLabelWithApi(_levelLabel(l10n, level), level.apiValue),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (checked)
              Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _levelLabel(AppLocalizations l10n, ReasoningEffort level) => switch (level) {
        ReasoningEffort.minimal => l10n.chatEffortMinimal,
        ReasoningEffort.low => l10n.chatEffortLow,
        ReasoningEffort.medium => l10n.chatEffortMedium,
        ReasoningEffort.high => l10n.chatEffortHigh,
        ReasoningEffort.xhigh => l10n.chatEffortXHigh,
        ReasoningEffort.max => l10n.chatEffortMax,
        _ => level.apiValue,
      };

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xs),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: context.semantic.subtleText),
        ),
      );

  Widget _capability(String title, bool value, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    bool isError = false,
  }) =>
      TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: isError ? AppLocalizations.of(context).providerModelWindowInvalid : null,
        ),
      );
}

/// 模型测试 / 拉取调试详情(对齐上游 ModelTestDetailBottomSheet)。
Future<void> showModelTestSheet(
  BuildContext context, {
  required String title,
  required ModelTestResult result,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ModelTestSheet(title: title, result: result),
  );
}

class _ModelTestSheet extends StatelessWidget {
  const _ModelTestSheet({required this.title, required this.result});

  final String title;
  final ModelTestResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusColor = result.success ? context.semantic.success : theme.colorScheme.error;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Iconfont.checkCircle : Iconfont.alertCircle,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${result.latencyMs}ms',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: context.semantic.subtleText),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.message.isNotEmpty)
                      Text(
                        result.message,
                        style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                      ),
                    const SizedBox(height: Spacing.sm),
                    _section(context, l10n.providerTestRequestUrl, result.requestUrl),
                    _section(
                      context,
                      l10n.providerTestRequestHeaders,
                      result.requestHeaders.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                    ),
                    if (result.requestBody.isNotEmpty)
                      _section(context, l10n.providerTestRequestBody, result.requestBody),
                    _section(
                      context,
                      l10n.providerTestResponse,
                      'HTTP ${result.responseCode}\n${result.responseBody}',
                    ),
                    if (result.errorDetail.isNotEmpty)
                      _section(context, l10n.providerTestError, result.errorDetail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: context.semantic.subtleText),
          ),
          const SizedBox(height: 2),
          SelectableText(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

/// 模型测试结果行(对齐上游 ModelTestResultLine):成功/失败图标 + 摘要文案,
/// 点击打开调试详情弹层。失败时只展示 HTTP 状态码等关键片段,全文进详情。
/// 编辑商模型页与聊天模型选择弹层共用。
class ModelTestResultLine extends StatelessWidget {
  const ModelTestResultLine({super.key, required this.model, required this.result});

  final String model;
  final ModelTestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.success ? context.semantic.success : theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: InkWell(
        onTap: () => showModelTestSheet(context, title: model, result: result),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(
                result.success ? Iconfont.checkCircle : Iconfont.alertCircle,
                size: 14,
                color: color,
              ),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  summarizeTestMessage(result),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Iconfont.chevronRight,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 测试结果摘要(对齐上游 ModelTestResultLine 的 displayMsg 逻辑):
/// 成功显示完整消息;失败优先提取 HTTP 状态码 / code,否则首行截断 20 字符。
String summarizeTestMessage(ModelTestResult result) {
  if (result.success) return result.message;
  final match = RegExp(
          r'HTTP\s*\d{3}|code[:\s]+[a-zA-Z0-9_]+',
          caseSensitive: false)
      .firstMatch(result.message);
  if (match != null) return match.group(0) ?? result.message;
  final first = result.message.split('\n').first;
  if (first.isEmpty) return 'Error';
  return first.length > 20 ? '${first.substring(0, 20)}...' : first;
}