import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/models/model_metadata.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/floating_tab_bar.dart';
import '../../core/ui/provider_logo.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/model_api_service.dart';
import '../../data/model_catalog.dart';
import '../../data/model_metadata_store.dart';
import '../../data/providers/provider_config.dart';
import '../../data/providers/provider_store.dart';
import '../../data/settings/general_settings.dart';
import '../../g11n/app_globalizations.dart';
import 'model_sheets.dart';
import 'provider_keys_page.dart';

/// 供应商编辑页(对齐上游 ProviderEditorScreen):两页横滑(配置 / 模型),
/// 底部悬浮切换条;顶部返回时保存并回到列表。
class ProviderEditPage extends ConsumerStatefulWidget {
  const ProviderEditPage({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<ProviderEditPage> createState() => _ProviderEditPageState();
}

class _ProviderEditPageState extends ConsumerState<ProviderEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;  late ProviderType _type;
  late bool _useFullUrl;
  late bool _isEnabled;
  late List<String> _models;
  late String _selectedModel;
  late Map<String, String> _headers;
  Map<String, ModelMetadata> _customMetadata = const {};
  final Set<String> _testing = {};
  late bool _multiKeyEnabled;
  late List<ProviderKey> _apiKeys;
  late KeyRotationStrategy _keyStrategy;
  late int _keyCooldown;
  late List<int> _keyCodes;
  bool _apiKeyVisible = false;
  bool _saving = false;
  bool _selectionMode = false;
  final Set<String> _selectedModels = {};
  final Map<String, ModelTestResult> _testResults = {};

  final _page = PageController();
  int _pageIndex = 0;

  ProviderConfig? get _provider => _find();

  @override
  void initState() {
    super.initState();
    final provider = _find();
    _name = TextEditingController(text: provider?.name ?? '');
    _baseUrl = TextEditingController(text: provider?.baseUrl ?? '');
    _apiKey = TextEditingController(text: provider?.apiKey ?? '');
    _type = provider?.type ?? ProviderType.openai;
    _useFullUrl = provider?.useFullUrl ?? false;
    _isEnabled = provider?.isEnabled ?? true;
    _models = List.of(provider?.models ?? const []);
    _selectedModel = provider?.selectedModel ?? '';
    _headers = Map.of(provider?.customHeaders ?? const {});
    _customMetadata = ref.read(customModelMetadataProvider).valueOrNull ?? const {};
    _multiKeyEnabled = provider?.multiKeyEnabled ?? false;
    _apiKeys = List.of(provider?.apiKeys ?? const []);
    _keyStrategy = provider?.keyRotationStrategy ?? KeyRotationStrategy.sequential;
    _keyCooldown = provider?.keyCooldownMinutes ?? 5;
    _keyCodes = List.of(provider?.keySwitchStatusCodes ?? const []);
  }

  ProviderConfig? _find() {
    final list = ref.read(providersProvider).valueOrNull ?? const <ProviderConfig>[];
    for (final provider in list) {
      if (provider.id == widget.providerId) return provider;
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final provider = _provider;
    if (provider == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectionMode) {
          setState(() {
            _selectionMode = false;
            _selectedModels.clear();
          });
          return;
        }
        _saveAndClose(provider);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(g11n.providerEdit),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            if (_pageIndex == 1 && _models.isNotEmpty)
              IconButton(
                tooltip: g11n.providerModelsSelect,
                icon: Icon(
                  Iconfont.checkSquare,
                  color: _selectionMode
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() {
                  _selectionMode = !_selectionMode;
                  if (!_selectionMode) _selectedModels.clear();
                }),
              ),
            IconButton(
              tooltip: g11n.providerAddModel,
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_pageIndex != 1) {
                  _page.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  );
                }
                _addModel(provider);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
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
            PageView(
              controller: _page,
              onPageChanged: (index) => setState(() {
                _pageIndex = index;
                if (index == 0 && _selectionMode) {
                  _selectionMode = false;
                  _selectedModels.clear();
                }
              }),
              children: [
                _configPage(context, g11n, provider),
                _modelsPage(context, g11n, provider),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: Spacing.lg,
              child: Center(
                child: FloatingTabBar(
                  controller: _page,
                  page: _pageIndex,
                  items: [
                    FloatingTabItem(icon: Iconfont.sliders, label: g11n.providerConfig),
                    FloatingTabItem(icon: Iconfont.cpu, label: g11n.model),
                  ],
                  maskColor: context.semantic.pageBackground,
                  onSelect: (index) => _page.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                  isScrolling: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 第 1 页:基本信息 / 选项。
  Widget _configPage(BuildContext context, AppGlobalizations g11n, ProviderConfig provider) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 100, Spacing.lg, 90),
      children: [
        SettingsGroupHeader(text: g11n.providerSectionBasic),
        SettingsGroup(
          children: [
            _textFieldRow(
              label: g11n.providerName,
              controller: _name,
            ),
            const SettingsDivider(),
            if (!_multiKeyEnabled)
              _textFieldRow(
                label: g11n.apiKey,
                controller: _apiKey,
                obscure: !_apiKeyVisible,
                trailing: IconButton(
                  onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                  iconSize: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: _apiKeyVisible ? g11n.providerHideApiKey : g11n.providerShowApiKey,
                  icon: Icon(_apiKeyVisible ? Iconfont.eyeOff : Iconfont.eye),
                ),
              ),
            if (!_multiKeyEnabled) const SettingsDivider(),
            _textFieldRow(
              label: g11n.baseUrl,
              controller: _baseUrl,
              hint: _type.defaultBaseUrl,
            ),
            const SettingsDivider(),
            SettingsRow(
              title: g11n.providerHeadersTitle,
              subtitle: _headers.isEmpty
                  ? g11n.providerHeadersDesc
                  : g11n.providerHeadersCount(_headers.length),
              trailing: Text(
                _headers.isEmpty ? g11n.providerHeadersAdd : g11n.providerHeadersManage,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: () => _editHeaders(provider),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: g11n.providerSectionType,
              trailing: Text(
                _type.shortLabel,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: _pickType,
            ),
          ],
        ),
        SettingsGroupHeader(text: g11n.providerSectionOptions),
        SettingsGroup(
          children: [
            _switchRow(
              title: g11n.enabled,
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SettingsDivider(),
            _switchRow(
              title: g11n.providerFullUrl,
              subtitle: g11n.providerFullUrlDesc,
              value: _useFullUrl,
              onChanged: (value) => setState(() => _useFullUrl = value),
            ),
            const SettingsDivider(),
            _switchRow(
              title: g11n.providerMultiKeyTitle,
              subtitle: g11n.providerMultiKeySubtitle,
              value: _multiKeyEnabled,
              onChanged: (value) => setState(() {
                _multiKeyEnabled = value;
                // 开启时把已填的单 Key 带进列表,避免输入框隐藏后看起来「刚填的 Key 丢了」。
                if (value && _apiKeys.isEmpty && _apiKey.text.trim().isNotEmpty) {
                  _apiKeys.add(ProviderKey(_apiKey.text.trim()));
                }
              }),
            ),
            if (_multiKeyEnabled) ...[
              const SettingsDivider(),
              SettingsRow(
                title: g11n.providerMultiKeyManage,
                subtitle: g11n.providerMultiKeySummary(
                  _apiKeys.where((key) => key.value.trim().isNotEmpty).length,
                  _keyStrategy == KeyRotationStrategy.sequential
                      ? g11n.providerMultiKeyStrategySequential
                      : g11n.providerMultiKeyStrategyRoundRobin,
                ),
                onTap: () => _editKeys(provider),
              ),
            ],
            const SettingsDivider(),
            SettingsRow(
              icon: Iconfont.trash2,
              title: g11n.delete,
              onTap: () => _delete(provider),
            ),
          ],
        ),
      ],
    );
  }

  /// 第 2 页:模型列表(模型(N)标题 + 拉取模型;选择模式下换成批量操作条)。
  /// 行内能力标签、测试结果行、左滑删除,对齐上游 ProviderEditorScreen 的模型页。
  Widget _modelsPage(BuildContext context, AppGlobalizations g11n, ProviderConfig provider) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Column(
      children: [
        SizedBox(height: topInset),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.xs, Spacing.sm),
          child: Row(
            children: [
              if (_selectionMode) ...[
                Expanded(
                  child: Text(
                    g11n.providerModelsSelectedCount(_selectedModels.length),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                _batchAction(
                  label: _isAllSelected ? g11n.providerModelsDeselectAll : g11n.providerModelsSelectAll,
                  onTap: _toggleSelectAll,
                ),
                _batchAction(
                  label: g11n.providerModelsBatchTest,
                  icon: Iconfont.play,
                  color: theme.colorScheme.primary,
                  enabled: _selectedModels.isNotEmpty,
                  onTap: () => _testSelected(provider),
                ),
                _batchAction(
                  label: g11n.providerModelsBatchDelete,
                  icon: Iconfont.trash2,
                  color: theme.colorScheme.error,
                  enabled: _selectedModels.isNotEmpty,
                  onTap: () => _batchDelete(provider),
                ),
                _batchAction(
                  label: g11n.commonCancel,
                  onTap: _exitSelectionMode,
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    g11n.providerModelsCount('${_models.length}'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: context.semantic.subtleText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _fetchModels(provider),
                  icon: const Icon(Iconfont.download, size: 18),
                  label: Text(g11n.providerFetchModels),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _models.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        g11n.providerNoModels,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.semantic.subtleText,
                        ),
                      ),
                      Text(
                        g11n.providerNoModelsHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.semantic.subtleText,
                        ),
                      ),
                    ],
                  ),
                )
              : _modelList(context, g11n, provider),
        ),
      ],
    );
  }

  /// 选择模式下的批量操作按钮(对齐上游 TextButton:全选/批量测试/批量删除/取消)。
  Widget _batchAction({
    required String label,
    IconData? icon,
    Color? color,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color ?? theme.colorScheme.onSurfaceVariant,
        disabledForegroundColor: (color ?? theme.colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// 模型列表:长按拖拽排序(对齐上游 ProviderEditorScreen 的 ReorderableItem),
  /// 整列表套一层液态柔光玻璃面板,行本身透明(逐行模糊会让 471 行掉帧)。
  Widget _modelList(BuildContext context, AppGlobalizations g11n, ProviderConfig provider) {
    Widget card(int index) => _modelCard(context, g11n, provider, _models[index], index);
    const listPadding = EdgeInsets.only(top: Spacing.xs, bottom: 110);
    final list = _selectionMode
        // 选择模式禁用拖拽排序(对齐上游:选择模式下 dragModifier 置空)。
        ? ListView.builder(
            padding: listPadding,
            itemCount: _models.length,
            itemBuilder: (context, index) => card(index),
          )
        : ReorderableListView.builder(
            padding: listPadding,
            itemCount: _models.length,
            onReorder: (oldIndex, newIndex) async {
              HapticFeedback.selectionClick();
              setState(() {
                final moved = _models.removeAt(oldIndex);
                _models.insert(newIndex.clamp(0, _models.length), moved);
              });
              await _save(provider);
            },
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeOut.transform(animation.value);
                return Transform.scale(
                  scale: 1 - 0.05 * t,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8 * t,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    child: child,
                  ),
                );
              },
            ),
            itemBuilder: (context, index) => card(index),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: GlassPanel(child: list),
    );
  }

  /// 单个模型卡片:行背景透明,由外层玻璃面板统一提供材质与圆角。
  Widget _modelCard(
    BuildContext context,
    AppGlobalizations g11n,
    ProviderConfig provider,
    String model,
    int index,
  ) {
    return Container(
      key: ValueKey('model-$model'),
      child: Column(
        children: [
          if (index != 0) const SettingsDivider(),
          _modelRow(context, g11n, provider, model),
        ],
      ),
    );
  }

  Widget _modelRow(
    BuildContext context,
    AppGlobalizations g11n,
    ProviderConfig provider,
    String model,
  ) {
    final theme = Theme.of(context);
    final bright = theme.brightness == Brightness.light;
    final selected = model == _selectedModel;
    // 元数据合并(对齐上游 ProviderModelRow 的 mergeModelMetadata):
    // 目录 + 自定义逐字段合并,自定义优先;目录匹配不到时回退推断默认值
    // (128k/64k/工具),保证每行都渲染能力标签。
    final catalog = ref.watch(modelCatalogProvider).valueOrNull ?? ModelCatalog.empty;
    final custom = ref.watch(customModelMetadataProvider).valueOrNull ?? _customMetadata;
    final metadata = resolveModelMetadata(
      catalog,
      custom,
      providerId: provider.id,
      model: model,
      type: provider.type,
    );
    final testing = _testing.contains(model);
    final result = _testResults[model];
    final batchSelected = _selectedModels.contains(model);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // 与玻璃面板同材质的浅色块:半透明白 + 高光描边,避免实心方块压住背景。
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: bright ? 0.65 : 0.16),
                  Colors.white.withValues(alpha: bright ? 0.28 : 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                width: 0.8,
                color: Colors.white.withValues(alpha: bright ? 0.80 : 0.22),
              ),
            ),
            child: ModelLogoIcon(modelName: model),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ModelMetadataTags(
                  metadata: metadata,
                  trailing: [
                    if (selected)
                      ModelTagPill(texts: [g11n.providerModelCurrent]),
                  ],
                ),
                if (result != null) ModelTestResultLine(model: model, result: result),
              ],
            ),
          ),
          _trailingAction(context, g11n, provider, model, testing, batchSelected),
        ],
      ),
    );

    if (_selectionMode) {
      // 选择模式:整行点击切换勾选,禁用左滑删除与长按拖拽(对齐上游)。
      return InkWell(
        onTap: () => _toggleModelSelection(model),
        child: content,
      );
    }
    return SwipeToDeleteRow(
      onDelete: () => _removeModel(provider, model),
      onTap: () => _editModel(provider, model),
      decorateChild: false,
      child: content,
    );
  }

  /// 行尾操作(对齐上游 ProviderModelRow 右侧 56dp 区域):
  /// 选择模式显示勾选框;测试中显示转圈;默认是固定宽度的「测试」按钮。
  Widget _trailingAction(
    BuildContext context,
    AppGlobalizations g11n,
    ProviderConfig provider,
    String model,
    bool testing,
    bool batchSelected,
  ) {
    final theme = Theme.of(context);
    if (_selectionMode) {
      return SizedBox(
        width: 56,
        height: 36,
        child: Center(
          child: Checkbox(
            value: batchSelected,
            onChanged: (_) => _toggleModelSelection(model),
          ),
        ),
      );
    }
    if (testing) {
      return const SizedBox(
        width: 56,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return SizedBox(
      width: 56,
      height: 32,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _testModel(provider, model),
        child: Text(g11n.providerTestModel, style: theme.textTheme.labelMedium),
      ),
    );
  }

  /// 拉取模型:新增的模型并入列表并立即保存(对齐上游 AddModelSheet / FetchModelsDialog 的写入时机);
  /// 拉取成功后按「自动清理过期模型」开关移除远端已不存在的本地模型。
  Future<void> _fetchModels(ProviderConfig provider) async {
    var removed = 0;
    await showFetchModelsSheet(
      context,
      provider: _draft(provider),
      onAddModels: (models) {
        setState(() {
          for (final model in models) {
            if (!_models.contains(model)) _models.add(model);
          }
          if (_selectedModel.isEmpty && _models.isNotEmpty) _selectedModel = _models.first;
        });
        _save(provider);
      },
      onFetched: (models) {
        if (!mounted) return;
        if (!ref.read(generalSettingsProvider).autoRemoveStaleModels) return;
        final remote = models.map((m) => m.trim()).where((m) => m.isNotEmpty).toSet();
        if (remote.isEmpty) return;
        final stale = _models.where((m) => !remote.contains(m)).toList();
        if (stale.isEmpty) return;
        setState(() {
          _models.removeWhere((m) => !remote.contains(m));
          if (!remote.contains(_selectedModel)) _selectedModel = _models.isEmpty ? '' : _models.first;
        });
        _save(provider);
        removed = stale.length;
      },
    );
    // 弹层还开着时提示会被它挡住,关闭后再报清理结果。
    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppGlobalizations.of(context).providerModelsAlignedRemoved(removed))),
      );
    }
  }

  /// 编辑模型元数据(对齐上游 AddModelSheet);改名时同时更新列表与选用项。
  /// 初始值用「目录 + 自定义」合并结果,与行内标签同源,思考档位预勾选目录识别值。
  Future<void> _editModel(ProviderConfig provider, String model) async {
    final g11n = AppGlobalizations.of(context);
    final catalog = ref.read(modelCatalogProvider).valueOrNull ?? ModelCatalog.empty;
    final metadata = resolveModelMetadata(
      catalog,
      _customMetadata,
      providerId: provider.id,
      model: model,
      type: provider.type,
    );
    final result = await showModelEditSheet(
      context,
      model: model,
      metadata: metadata,
      title: g11n.providerEditModel,
      existingModels: _models,
    );
    if (result == null || !mounted) return;
    if (result.id != model) {
      setState(() {
        final index = _models.indexOf(model);
        if (index >= 0) _models[index] = result.id;
        if (_selectedModel == model) _selectedModel = result.id;
      });
      await ref.read(modelMetadataStoreProvider).remove(provider.id, model);
    }
    await ref.read(modelMetadataStoreProvider).put(provider.id, result.id, result);
    _refreshMetadata();
    await _save(provider);
  }

  /// 单模型连通性测试:结果写入 [_testResults] 行内展示(对齐上游 testResults),
  /// 点击行内结果行才打开调试详情弹层。
  Future<void> _testModel(ProviderConfig provider, String model) async {
    if (_testing.contains(model)) return;
    final g11n = AppGlobalizations.of(context);
    setState(() => _testing.add(model));
    final draft = _draft(provider);
    final result = await ref.read(modelApiProvider).testModel(
          provider: draft,
          apiKey: draft.firstUsableApiKey,
          model: model,
          messageForKeyMissing: g11n.providerApiKeyRequired,
        );
    if (!mounted) return;
    setState(() {
      _testing.remove(model);
      _testResults[model] = result;
    });
  }

  /// 批量测试选中模型(对齐上游:逐个触发,结果行内回写)。
  void _testSelected(ProviderConfig provider) {
    for (final model in _selectedModels.toList()) {
      _testModel(provider, model);
    }
  }

  /// 批量删除选中模型:确认弹窗 → 移除模型与自定义元数据 → 退出选择模式并保存。
  Future<void> _batchDelete(ProviderConfig provider) async {
    final g11n = AppGlobalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.providerModelsBatchDeleteTitle),
        content: Text(g11n.providerModelsBatchDeleteConfirm(_selectedModels.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(g11n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              g11n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final toDelete = Set<String>.of(_selectedModels);
    setState(() {
      _models.removeWhere(toDelete.contains);
      if (toDelete.contains(_selectedModel)) _selectedModel = '';
      _testResults.removeWhere((key, _) => toDelete.contains(key));
      _testing.removeWhere(toDelete.contains);
      _selectedModels.clear();
      _selectionMode = false;
    });
    final store = ref.read(modelMetadataStoreProvider);
    for (final model in toDelete) {
      await store.remove(provider.id, model);
    }
    _refreshMetadata();
    await _save(provider);
  }

  /// 移除单个模型(左滑删除 / 批量删除共用):同步清掉自定义元数据与测试结果。
  Future<void> _removeModel(ProviderConfig provider, String model) async {
    final wasSelected = model == _selectedModel;
    setState(() {
      _models.remove(model);
      if (wasSelected) _selectedModel = '';
      _selectedModels.remove(model);
      _testResults.remove(model);
      _testing.remove(model);
    });
    await ref.read(modelMetadataStoreProvider).remove(provider.id, model);
    _refreshMetadata();
    await _save(provider);
  }

  bool get _isAllSelected => _models.isNotEmpty && _selectedModels.length == _models.length;

  void _toggleSelectAll() {
    setState(() {
      _selectedModels.clear();
      if (!_isAllSelected) _selectedModels.addAll(_models);
    });
  }

  void _toggleModelSelection(String model) {
    setState(() {
      if (!_selectedModels.remove(model)) _selectedModels.add(model);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedModels.clear();
    });
  }

  void _refreshMetadata() {
    ref.invalidate(customModelMetadataProvider);
    _customMetadata =
        ref.read(customModelMetadataProvider).valueOrNull ?? const {};
  }

  Widget _textFieldRow({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.semantic.subtleText),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  /// 上游格式选择(对齐上游 ProviderTypeSelectionSheet)。
  Future<void> _pickType() async {
    final g11n = AppGlobalizations.of(context);
    final selected = await showModalBottomSheet<ProviderType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  g11n.providerSectionType,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final type in ProviderType.values)
              ListTile(
                leading: ModelLogoIcon(
                  modelName: switch (type) {
                    ProviderType.openai => 'openai',
                    ProviderType.anthropic => 'anthropic',
                    ProviderType.gemini => 'google',
                  },
                  size: 24,
                ),
                title: Text(type.label),
                subtitle: Text(type.defaultBaseUrl),
                trailing: type == _type ? const Icon(Icons.check, size: 20) : null,
                onTap: () => Navigator.pop(sheetContext, type),
              ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _type = selected;
      if (_baseUrl.text.trim().isEmpty) _baseUrl.text = selected.defaultBaseUrl;
    });
  }

  /// 自定义请求头管理(对齐上游 ProviderHeadersSheet)。
  Future<void> _editHeaders(ProviderConfig provider) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _HeadersSheet(initial: _headers),
    );
    if (result == null || !mounted) return;
    setState(() => _headers = result);
  }

  /// 添加模型(对齐上游 AddModelSheet:含窗口、价格、能力与思考档位)。
  Future<void> _addModel(ProviderConfig provider) async {
    final g11n = AppGlobalizations.of(context);
    final result = await showModelEditSheet(
      context,
      model: '',
      title: g11n.providerAddModel,
      confirmLabel: g11n.commonAdd,
      existingModels: _models,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (!_models.contains(result.id)) _models.add(result.id);
      _selectedModel = result.id;
    });
    await ref.read(modelMetadataStoreProvider).put(provider.id, result.id, result);
    _refreshMetadata();
    await _save(provider);
  }

  Future<void> _saveAndClose(ProviderConfig provider) async {
    await _save(provider);
    if (mounted) Navigator.of(context).pop();
  }

  /// 多 Key 管理:子页返回后并入配置(API Key 输入框在多 Key 模式下隐藏)。
  Future<void> _editKeys(ProviderConfig provider) async {
    final updated = await Navigator.of(context).push<ProviderConfig>(
      MaterialPageRoute(
        builder: (routeContext) => ProviderKeysPage(
          initial: provider.copyWith(
            apiKeys: _apiKeys,
            keyRotationStrategy: _keyStrategy,
            keyCooldownMinutes: _keyCooldown,
            keySwitchStatusCodes: _keyCodes,
          ),
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _apiKeys = List.of(updated.apiKeys);
      _keyStrategy = updated.keyRotationStrategy;
      _keyCooldown = updated.keyCooldownMinutes;
      _keyCodes = List.of(updated.keySwitchStatusCodes);
    });
    await _save(provider);
  }

  /// 页面编辑态合并进配置:拉取 / 测试模型时直接使用草稿(未保存的 baseUrl / type /
  /// headers 等同样生效),无需先保存退出再进——否则拉取仍走已保存的旧配置。
  ProviderConfig _draft(ProviderConfig base) => base.copyWith(
        name: _name.text,
        type: _type,
        baseUrl: _baseUrl.text,
        apiKey: _apiKey.text,
        models: _models,
        selectedModel: _selectedModel,
        isEnabled: _isEnabled,
        useFullUrl: _useFullUrl,
        customHeaders: _headers,
        multiKeyEnabled: _multiKeyEnabled,
        apiKeys: _apiKeys,
        keyRotationStrategy: _keyStrategy,
        keyCooldownMinutes: _keyCooldown,
        keySwitchStatusCodes: _keyCodes,
      );

  /// 保存中同步多 Key 字段。
  Future<void> _save(ProviderConfig provider) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(providersProvider.notifier).save(_draft(provider));
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete(ProviderConfig provider) async {
    final g11n = AppGlobalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.deleteProviderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(g11n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(providersProvider.notifier).remove(provider.id);
    if (mounted) Navigator.of(context).pop();
  }
}

/// 自定义请求头编辑弹层(对齐上游 ProviderHeadersSheet):成对的名字 / 值 + 删除 + 追加。
class _HeadersSheet extends StatefulWidget {
  const _HeadersSheet({required this.initial});

  final Map<String, String> initial;

  @override
  State<_HeadersSheet> createState() => _HeadersSheetState();
}

class _HeadersSheetState extends State<_HeadersSheet> {
  late final List<(TextEditingController, TextEditingController)> _rows = [
    for (final entry in widget.initial.entries)
      (
        TextEditingController(text: entry.key),
        TextEditingController(text: entry.value),
      ),
  ];

  @override
  void dispose() {
    for (final row in _rows) {
      row.$1.dispose();
      row.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
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
            Text(
              g11n.providerHeadersTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              g11n.providerHeadersDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: context.semantic.subtleText),
            ),
            const SizedBox(height: Spacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var index = 0; index < _rows.length; index++) ...[
                      if (index > 0) const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rows[index].$1,
                              decoration: const InputDecoration(
                                hintText: 'Header',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _rows[index].$2,
                              decoration: const InputDecoration(
                                hintText: 'Value',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              final row = _rows.removeAt(index);
                              row.$1.dispose();
                              row.$2.dispose();
                            }),
                            icon: const Icon(Iconfont.x, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(
                    (TextEditingController(), TextEditingController()),
                  )),
              icon: const Icon(Icons.add, size: 18),
              label: Text(g11n.providerHeadersAdd),
            ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, {
                  for (final row in _rows)
                    if (row.$1.text.trim().isNotEmpty) row.$1.text.trim(): row.$2.text,
                }),
                child: Text(g11n.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}