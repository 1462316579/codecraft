/// 浏览器领域的模型(对照上游 `feature/agent/domain/tool/browser/BrowserManager.kt`
/// 中的 `BrowserUserAgentPreset` / `BrowserTabState` / `BrowserState` / `BrowserDialog`)。
library;

/// 用户代理预设:UI 菜单里可切换,[userAgentString] 为 null 表示用系统默认或自定义值。
enum BrowserUserAgentPreset {
  defaultValue('default', 'browserUaDefault', 'browserUaDefaultDesc', null),
  androidPhone(
    'android_phone',
    'browserUaAndroidPhone',
    'browserUaAndroidPhoneDesc',
    'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
  ),
  androidTablet(
    'android_tablet',
    'browserUaAndroidTablet',
    'browserUaAndroidTabletDesc',
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  ),
  desktopPc(
    'desktop_pc',
    'browserUaDesktopPc',
    'browserUaDesktopPcDesc',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  ),
  iphone(
    'iphone',
    'browserUaIphone',
    'browserUaIphoneDesc',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
  ),
  ipad(
    'ipad',
    'browserUaIpad',
    'browserUaIpadDesc',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15',
  ),
  custom('custom', 'browserUaCustom', 'browserUaCustomDesc', null);

  const BrowserUserAgentPreset(this.id, this.titleKey, this.descKey, this.userAgentString);

  final String id;
  final String titleKey;
  final String descKey;
  final String? userAgentString;

  static BrowserUserAgentPreset fromId(String? id) =>
      values.firstWhere((preset) => preset.id == id, orElse: () => defaultValue);
}

/// 单个标签页的状态。
class BrowserTabState {
  const BrowserTabState({
    required this.id,
    this.url = '',
    this.title = '',
    this.loading = false,
    this.error,
    this.devToolsOpen = false,
  });

  final String id;
  final String url;
  final String title;
  final bool loading;
  final String? error;
  final bool devToolsOpen;

  BrowserTabState copyWith({
    String? url,
    String? title,
    bool? loading,
    String? Function()? error,
    bool? devToolsOpen,
  }) =>
      BrowserTabState(
        id: id,
        url: url ?? this.url,
        title: title ?? this.title,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        devToolsOpen: devToolsOpen ?? this.devToolsOpen,
      );
}

/// 浏览器整体状态(UI 与 AI 工具共用)。
class BrowserState {
  const BrowserState({
    this.tabs = const [],
    this.activeTabId = '',
    this.attached = false,
    this.nightMode = false,
    this.userAgentPreset = BrowserUserAgentPreset.defaultValue,
    this.customUserAgent = '',
    this.currentUserAgent = '',
    this.pendingDialog,
  });

  final List<BrowserTabState> tabs;
  final String activeTabId;

  /// 面板是否已挂载到可见界面(AI 工具据此决定能否截图)。
  final bool attached;
  final bool nightMode;
  final BrowserUserAgentPreset userAgentPreset;
  final String customUserAgent;
  final String currentUserAgent;

  /// 面板可见时等待用户处理的网页对话框(alert/confirm/prompt)。
  final BrowserDialog? pendingDialog;

  BrowserTabState? get activeTab {
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return tabs.isEmpty ? null : tabs.first;
  }

  String get url => activeTab?.url ?? '';
  String get title => activeTab?.title ?? '';
  bool get loading => activeTab?.loading ?? false;
  String? get error => activeTab?.error;
  bool get devToolsOpen => activeTab?.devToolsOpen ?? false;

  BrowserState copyWith({
    List<BrowserTabState>? tabs,
    String? activeTabId,
    bool? attached,
    bool? nightMode,
    BrowserUserAgentPreset? userAgentPreset,
    String? customUserAgent,
    String? currentUserAgent,
    BrowserDialog? Function()? pendingDialog,
  }) =>
      BrowserState(
        tabs: tabs ?? this.tabs,
        activeTabId: activeTabId ?? this.activeTabId,
        attached: attached ?? this.attached,
        nightMode: nightMode ?? this.nightMode,
        userAgentPreset: userAgentPreset ?? this.userAgentPreset,
        customUserAgent: customUserAgent ?? this.customUserAgent,
        currentUserAgent: currentUserAgent ?? this.currentUserAgent,
        pendingDialog: pendingDialog == null ? this.pendingDialog : pendingDialog(),
      );
}

/// 网页对话框(alert / confirm / prompt)。
class BrowserDialog {
  const BrowserDialog({required this.type, required this.message, this.defaultValue});

  /// `alert` / `confirm` / `prompt`。
  final String type;
  final String message;
  final String? defaultValue;
}

/// 控制台条目(开发者工具面板用)。
class BrowserConsoleEntry {
  const BrowserConsoleEntry({
    required this.level,
    required this.message,
    required this.line,
    required this.source,
  });

  final String level;
  final String message;
  final int line;
  final String source;
}