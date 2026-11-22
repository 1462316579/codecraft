import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/browser/browser_manager.dart';
import '../../data/browser/browser_models.dart';
import '../../core/ui/text_input_dialog.dart';
import '../../g11n/app_globalizations.dart';

/// 浏览器页(对照上游 `feature/browser/presentation/BrowserScreen.kt`)。
///
/// [embedded] 为 true 时用关闭图标替代返回箭头(大屏工作台右栏形态)。
class BrowserPage extends ConsumerStatefulWidget {
  const BrowserPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends ConsumerState<BrowserPage> {
  bool _editingAddress = false;

  @override
  void initState() {
    super.initState();
    final manager = ref.read(browserManagerProvider);
    manager.attach();
    if (manager.state.tabs.isEmpty) {
      manager.newTab();
    }
  }

  @override
  void dispose() {
    ref.read(browserManagerProvider).detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final manager = ref.watch(browserManagerProvider);
    final state = manager.state;
    final tab = state.activeTab;

    // 夜间模式:整页套用深色主题,顶栏/底栏/空态/弹层一次性全变黑。
    // 逐个改颜色会漏(顶栏、底栏、各类 sheet 各有一套配色),换主题最彻底。
    if (!state.nightMode) {
      return _buildPage(context, g11n, manager, state, tab);
    }
    // Builder 取 Theme 内部的 context:弹层用 showModalBottomSheet 打开时
    // 取的是调用方 context 的主题,用外层 context 会拿到浅色主题。
    return Theme(
      data: buildAppTheme(Brightness.dark),
      child: Builder(
        builder: (themedContext) =>
            _buildPage(themedContext, g11n, manager, state, tab),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    AppGlobalizations g11n,
    BrowserManager manager,
    BrowserState state,
    BrowserTabState? tab,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _BrowserTopBar(
          title: tab?.title ?? '',
          url: tab?.url ?? '',
          loading: state.loading,
          editing: _editingAddress,
          embedded: widget.embedded,
          onEditingChange: (value) => setState(() => _editingAddress = value),
          onBack: () => Navigator.of(context).maybePop(),
          onReload: () => manager.reload(),
          onNavigate: (url) async {
            setState(() => _editingAddress = false);
            await manager.navigate(url);
          },
        ),
      ),
      bottomNavigationBar: _BrowserBottomBar(
        // 上游口径:加载中禁用前进/后退(不是 canGoBack/canGoForward)。
        canGoBack: !state.loading,
        canGoForward: !state.loading,
        tabsCount: state.tabs.length,
        hasActiveSettings: state.nightMode ||
            state.devToolsOpen ||
            state.userAgentPreset != BrowserUserAgentPreset.defaultValue,
        onGoBack: () => manager.goBack(),
        onGoForward: () => manager.goForward(),
        onNewTab: () => manager.newTab(),
        onOpenTabs: () => _openTabsSheet(context, g11n, manager),
        onOpenMenu: () => _openMenuSheet(context, g11n, manager),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: state.tabs.indexWhere((item) => item.id == state.activeTabId),
            children: [
              for (final item in state.tabs)
                BrowserTabView(
                  key: ValueKey(item.id),
                  tabId: item.id,
                ),
            ],
          ),
          if (tab != null && tab.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tab.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        IconButton(
                          onPressed: () => manager.reload(),
                          icon: Icon(
                            Iconfont.refreshCw,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (tab != null && tab.url.isEmpty && !tab.loading && tab.error == null)
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconfont.globe,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        g11n.browserEmptyClickHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 地址栏编辑时覆盖一层 8% 黑遮罩:拦手势且点空白处退出编辑态(上游 BrowserScreen 94-99 行)。
          if (_editingAddress)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _editingAddress = false),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          if (state.pendingDialog != null)
            _BrowserJsDialog(dialog: state.pendingDialog!, manager: manager),
        ],
      ),
    );
  }

  Future<void> _openTabsSheet(
    BuildContext context,
    AppGlobalizations g11n,
    BrowserManager manager,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.semantic.pageBackground,
      builder: (sheetContext) => Consumer(
        builder: (consumerContext, ref, _) {
          final current = ref.watch(browserManagerProvider).state;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          g11n.browserTabsCount(current.tabs.length),
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: () {
                            manager.newTab();
                            Navigator.of(sheetContext).pop();
                          },
                          icon: Icon(
                            Iconfont.plus,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          ),
                          tooltip: g11n.browserNewTab,
                        ),
                      ],
                    ),
                  ),
                  SettingsGroup(
                    children: [
                      for (var index = 0; index < current.tabs.length; index++) ...[
                        if (index > 0) const SettingsDivider(),
                        _tabRow(
                          sheetContext,
                          g11n,
                          manager,
                          current,
                          current.tabs[index],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 标签行(对齐上游 BrowserTabItemRow):左滑删除,行尾 X 关闭,选中项主题色。
  Widget _tabRow(
    BuildContext context,
    AppGlobalizations g11n,
    BrowserManager manager,
    BrowserState state,
    BrowserTabState tab,
  ) {
    final theme = Theme.of(context);
    final selected = tab.id == state.activeTabId;
    final title = tab.title.isNotEmpty
        ? tab.title
        : (tab.url.isNotEmpty
            ? tab.url.replaceFirst(RegExp(r'^https?://'), '')
            : g11n.browserTabDefaultTitle);
    return SwipeToDeleteRow(
      onDelete: () => manager.closeTab(tab.id),
      onTap: () {
        manager.switchTab(tab.id);
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 11),
        child: Row(
          children: [
            Icon(
              Iconfont.globe,
              size: 18,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (tab.url.isNotEmpty)
                    Text(
                      tab.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => manager.closeTab(tab.id),
              tooltip: g11n.browserCloseTab,
              icon: Icon(
                Iconfont.close,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenuSheet(
    BuildContext context,
    AppGlobalizations g11n,
    BrowserManager manager,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.semantic.pageBackground,
      builder: (sheetContext) => _BrowserMenuSheet(g11n: g11n, manager: manager),
    );
  }
}

/// 浏览器菜单弹层(对齐上游 BrowserMenuSheet):主菜单(夜间模式 / 开发者工具 / 浏览器标识)
/// 与「浏览器标识」子页两级。
class _BrowserMenuSheet extends StatefulWidget {
  const _BrowserMenuSheet({required this.g11n, required this.manager});

  final AppGlobalizations g11n;
  final BrowserManager manager;

  @override
  State<_BrowserMenuSheet> createState() => _BrowserMenuSheetState();
}

class _BrowserMenuSheetState extends State<_BrowserMenuSheet> {
  int _level = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g11n = widget.g11n;
    return Consumer(
      builder: (consumerContext, ref, _) {
        final state = ref.watch(browserManagerProvider).state;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Row(
                    children: [
                      if (_level == 1) ...[
                        IconButton(
                          onPressed: () => setState(() => _level = 0),
                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Iconfont.arrowLeft,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                      ],
                      Text(
                        _level == 1 ? g11n.browserUaSection : g11n.browserMenuTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (_level == 0) ...[
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: state.nightMode ? Iconfont.night : Iconfont.day,
                        title: g11n.browserNightModeTitle,
                        trailing: Switch(
                          value: state.nightMode,
                          onChanged: (value) => widget.manager.setNightMode(value),
                        ),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: Iconfont.code,
                        title: g11n.browserDevtoolsTitle,
                        trailing: Switch(
                          value: state.devToolsOpen,
                          onChanged: (value) => widget.manager.toggleDevTools(),
                        ),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: Iconfont.globe,
                        title: g11n.browserUaSection,
                        trailing: Text(
                          _uaTitle(g11n, state.userAgentPreset),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        onTap: () => setState(() => _level = 1),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs, left: Spacing.lg),
                    child: Text(
                      g11n.browserNightModeDesc,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ] else
                  SettingsGroup(
                    children: [
                      for (var index = 0; index < BrowserUserAgentPreset.values.length; index++) ...[
                        if (index > 0) const SettingsDivider(),
                        _uaRow(context, g11n, state, BrowserUserAgentPreset.values[index]),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _uaRow(
    BuildContext context,
    AppGlobalizations g11n,
    BrowserState state,
    BrowserUserAgentPreset preset,
  ) {
    final theme = Theme.of(context);
    final selected = state.userAgentPreset == preset;
    final icon = switch (preset) {
      BrowserUserAgentPreset.defaultValue => Iconfont.globe,
      BrowserUserAgentPreset.androidPhone => Iconfont.phone,
      BrowserUserAgentPreset.androidTablet => Iconfont.tablet,
      BrowserUserAgentPreset.desktopPc => Iconfont.desktop,
      BrowserUserAgentPreset.iphone => Iconfont.phone,
      BrowserUserAgentPreset.ipad => Iconfont.tablet,
      BrowserUserAgentPreset.custom => Iconfont.sliders,
    };
    final subtitle = preset == BrowserUserAgentPreset.custom && state.customUserAgent.isNotEmpty
        ? state.customUserAgent
        : _uaDesc(g11n, preset);
    return InkWell(
      onTap: () async {
        setState(() => _level = 0);
        if (preset == BrowserUserAgentPreset.custom) {
          final input = await _promptCustomUa(context, g11n, state.customUserAgent);
          if (input == null) return;
          await widget.manager.setUserAgent(preset, custom: input);
        } else {
          await widget.manager.setUserAgent(preset);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uaTitle(g11n, preset),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Iconfont.check, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _uaTitle(AppGlobalizations g11n, BrowserUserAgentPreset preset) => switch (preset) {
        BrowserUserAgentPreset.defaultValue => g11n.browserUaDefault,
        BrowserUserAgentPreset.androidPhone => g11n.browserUaAndroidPhone,
        BrowserUserAgentPreset.androidTablet => g11n.browserUaAndroidTablet,
        BrowserUserAgentPreset.desktopPc => g11n.browserUaDesktopPc,
        BrowserUserAgentPreset.iphone => g11n.browserUaIphone,
        BrowserUserAgentPreset.ipad => g11n.browserUaIpad,
        BrowserUserAgentPreset.custom => g11n.browserUaCustom,
      };

  String _uaDesc(AppGlobalizations g11n, BrowserUserAgentPreset preset) => switch (preset) {
        BrowserUserAgentPreset.defaultValue => g11n.browserUaDefaultDesc,
        BrowserUserAgentPreset.androidPhone => g11n.browserUaAndroidPhoneDesc,
        BrowserUserAgentPreset.androidTablet => g11n.browserUaAndroidTabletDesc,
        BrowserUserAgentPreset.desktopPc => g11n.browserUaDesktopPcDesc,
        BrowserUserAgentPreset.iphone => g11n.browserUaIphoneDesc,
        BrowserUserAgentPreset.ipad => g11n.browserUaIpadDesc,
        BrowserUserAgentPreset.custom => g11n.browserUaCustomDesc,
      };

  Future<String?> _promptCustomUa(
    BuildContext context,
    AppGlobalizations g11n,
    String initial,
  ) {
    return showTextInputDialog(
      context,
      title: g11n.browserUaCustomDialogTitle,
      confirmLabel: g11n.confirm,
      initial: initial,
      hintText: g11n.browserUaCustomInputHint,
    );
  }
}

/// 单标签的 WebView 视图:创建控制器并交给管理器持有(UI 与 AI 共用)。
class BrowserTabView extends ConsumerStatefulWidget {
  const BrowserTabView({super.key, required this.tabId});

  final String tabId;

  @override
  ConsumerState<BrowserTabView> createState() => _BrowserTabViewState();
}

class _BrowserTabViewState extends ConsumerState<BrowserTabView> {
  late final WebViewController _controller;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final manager = ref.read(browserManagerProvider);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => manager.onPageStarted(widget.tabId, url),
          onPageFinished: (url) => manager.onPageFinished(widget.tabId, url),
          onWebResourceError: (error) =>
              manager.onPageError(widget.tabId, error.description),
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      );
    _controller = controller;
    manager.bindController(widget.tabId, controller);
    manager.bindCapture(widget.tabId, _capturePixels);
    manager.bindViewOrigin(widget.tabId, () {
      final box = _boundaryKey.currentContext?.findRenderObject() as RenderBox?;
      return box == null ? Offset.zero : box.localToGlobal(Offset.zero);
    });
    manager.bindViewDensity(widget.tabId, () => MediaQuery.of(context).devicePixelRatio);
    controller.setOnConsoleMessage((message) {
      manager.addConsole(widget.tabId, message.level.name, message.message);
    });

    // 网页对话框(alert/confirm/prompt)用平台回调拦下来交弹层处理(与上游 WebChromeClient 同机制):
    // 未决期间页面的 JS 保持阻塞,所以 confirm/prompt 必须回填真实结果。
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnJavaScriptAlertDialog((request) async {
        final completer = Completer<Object?>();
        manager.registerDialog(
          BrowserDialog(type: 'alert', message: request.message),
          completer,
        );
        await completer.future;
      });
      platform.setOnJavaScriptConfirmDialog((request) async {
        final completer = Completer<Object?>();
        manager.registerDialog(
          BrowserDialog(type: 'confirm', message: request.message),
          completer,
        );
        final result = await completer.future;
        return result == true;
      });
      platform.setOnJavaScriptTextInputDialog((request) async {
        final completer = Completer<Object?>();
        manager.registerDialog(
          BrowserDialog(
            type: 'prompt',
            message: request.message,
            defaultValue: request.defaultText,
          ),
          completer,
        );
        final result = await completer.future;
        return result is String ? result : '';
      });
    }
  }

  /// 把 WebView 所在区域抓成 PNG(供 AI 的 screenshot 动作)。
  Future<Uint8List?> _capturePixels() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: _boundaryKey,
        child: WebViewWidget(controller: _controller),
      );
}

class _BrowserTopBar extends StatelessWidget {
  const _BrowserTopBar({
    required this.title,
    required this.url,
    required this.loading,
    required this.editing,
    required this.embedded,
    required this.onEditingChange,
    required this.onBack,
    required this.onReload,
    required this.onNavigate,
  });

  final String title;
  final String url;
  final bool loading;
  final bool editing;
  final bool embedded;
  final ValueChanged<bool> onEditingChange;
  final VoidCallback onBack;
  final VoidCallback onReload;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g11n = AppGlobalizations.of(context);
    final addressText = title.isNotEmpty ? title : (url.isNotEmpty ? url : g11n.browserTitle);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: editing ? () => onEditingChange(false) : onBack,
                      tooltip: editing
                          ? g11n.cancel
                          : MaterialLocalizations.of(context).backButtonTooltip,
                      icon: Icon(editing || embedded ? Iconfont.close : Iconfont.arrowLeft),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                          child: editing
                              ? Row(
                                  children: [
                                    Icon(Iconfont.globe,
                                        size: 15, color: theme.colorScheme.primary),
                                    const SizedBox(width: Spacing.xs),
                                    Expanded(
                                      child: TextField(
                                        autofocus: true,
                                        controller: TextEditingController(text: url)
                                          ..selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: url.length,
                                          ),
                                        textInputAction: TextInputAction.go,
                                        onSubmitted: (value) {
                                          if (value.trim().isEmpty) return;
                                          onNavigate(value);
                                        },
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        cursorColor: theme.colorScheme.primary,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: () => onEditingChange(true),
                                  child: Row(
                                    children: [
                                      Icon(Iconfont.globe,
                                          size: 15,
                                          color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: Spacing.xs),
                                      Expanded(
                                        child: Text(
                                          addressText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: title.isNotEmpty || url.isNotEmpty
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: loading ? null : onReload,
                        tooltip: g11n.browserReload,
                        icon: loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Icon(Iconfont.refreshCw, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserBottomBar extends StatelessWidget {
  const _BrowserBottomBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.tabsCount,
    required this.hasActiveSettings,
    required this.onGoBack,
    required this.onGoForward,
    required this.onNewTab,
    required this.onOpenTabs,
    required this.onOpenMenu,
  });

  final bool canGoBack;
  final bool canGoForward;
  final int tabsCount;
  final bool hasActiveSettings;
  final VoidCallback onGoBack;
  final VoidCallback onGoForward;
  final VoidCallback onNewTab;
  final VoidCallback onOpenTabs;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g11n = AppGlobalizations.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                IconButton(
                  onPressed: canGoBack ? onGoBack : null,
                  tooltip: g11n.browserBack,
                  icon: const Icon(Iconfont.arrowLeft, size: 24),
                ),
                IconButton(
                  onPressed: canGoForward ? onGoForward : null,
                  tooltip: g11n.browserForward,
                  icon: const Icon(Iconfont.chevronRight, size: 24),
                ),
                IconButton(
                  onPressed: onNewTab,
                  tooltip: g11n.browserNewTab,
                  icon: Icon(Iconfont.plus, size: 24, color: theme.colorScheme.primary),
                ),
                  InkWell(
                    onTap: onOpenTabs,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          width: 1.8,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$tabsCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onOpenMenu,
                  tooltip: g11n.browserMenu,
                  icon: Icon(
                    Iconfont.menu,
                    size: 23,
                    color: hasActiveSettings
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
      ),
    );
  }
}

/// 网页对话框(alert / confirm / prompt)弹层,对照上游 BrowserJsDialog。
class _BrowserJsDialog extends StatefulWidget {
  const _BrowserJsDialog({required this.dialog, required this.manager});

  final BrowserDialog dialog;
  final BrowserManager manager;

  @override
  State<_BrowserJsDialog> createState() => _BrowserJsDialogState();
}

class _BrowserJsDialogState extends State<_BrowserJsDialog> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input.text = widget.dialog.defaultValue ?? '';
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final isPrompt = widget.dialog.type == 'prompt';
    final isConfirm = widget.dialog.type == 'confirm';
    return AlertDialog(
      // 上游 onDismissRequest = {}(点外部不能关);本实现在页面 Stack 里内联渲染,同样无法点外部关闭。
      title: Text(
        isPrompt
            ? g11n.browserDialogPromptTitle
            : isConfirm
                ? g11n.browserDialogConfirmTitle
                : g11n.browserDialogAlertTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.dialog.message),
          if (isPrompt)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: TextField(
                controller: _input,
                maxLines: null,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
      actions: [
        if (isConfirm || isPrompt)
          TextButton(
            onPressed: () => widget.manager.resolveDialog(accept: false),
            child: Text(g11n.cancel),
          ),
        TextButton(
          onPressed: () =>
              widget.manager.resolveDialog(accept: true, text: _input.text),
          child: Text(g11n.confirm),
        ),
      ],
    );
  }
}