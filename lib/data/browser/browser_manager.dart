import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import 'backbone_js.dart';
import 'browser_models.dart';
import '../workspaces.dart';

/// 浏览器管理器(对照上游 `feature/agent/domain/tool/browser/BrowserManager.kt`)。
///
/// UI 与 AI 工具**共用同一个实例**:UI 把每个标签的 `WebViewController` 交给管理器持有,
/// 因此 AI 的 navigate/click/getText 等操作直接作用于用户眼前那个页面。
class BrowserManager extends ChangeNotifier {
  BrowserManager();

  static const String searchEngineUrl = 'https://www.bing.com/search?q=';

  /// 每个标签一个 WebView 控制器(UI 用 WebViewWidget 渲染,AI 用同一控制器执行 JS)。
  final Map<String, WebViewController> _controllers = {};
  final Map<String, String> _pendingUrls = {};
  var _tabSeq = 1;

  BrowserState _state = const BrowserState();
  BrowserState get state => _state;

  /// 面板是否已挂载(AI 工具据此判断页面是否可见)。
  bool get attached => _state.attached;

  void _emit(BrowserState next) {
    _state = next;
    notifyListeners();
  }

  List<BrowserTabState> get _tabs => _state.tabs;

  void _updateTab(String id, BrowserTabState Function(BrowserTabState tab) update) {
    _emit(_state.copyWith(
      tabs: [
        for (final tab in _tabs)
          if (tab.id == id) update(tab) else tab,
      ],
    ));
  }

  /// UI 收到导航开始:更新 URL 与加载态。
  void onPageStarted(String tabId, String url) {
    _updateTab(
      tabId,
      (tab) => tab.copyWith(url: url, loading: true, error: () => null),
    );
    if (_state.nightMode) unawaited(_applyNightMode(tabId));
  }

  void onPageFinished(String tabId, String url) {
    _updateTab(tabId, (tab) => tab.copyWith(url: url, loading: false));
    final tab = _tabs.where((item) => item.id == tabId).firstOrNull;
    // 新页面加载完要重新应用夜间样式(样式随页面文档一起被替换掉了)。
    if (_state.nightMode) unawaited(_applyNightMode(tabId));
    if (tab != null && tab.devToolsOpen) {
      unawaited(_injectEruda(tabId, autoShow: false));
    }
  }

  void onPageError(String tabId, String description) {
    _updateTab(tabId, (tab) => tab.copyWith(loading: false, error: () => description));
  }

  /// 开发者工具(对齐上游 toggleDevTools):开启时注入 Eruda 并展示,关闭时销毁。
  Future<bool> toggleDevTools({String? tabId}) async {
    final tab = _resolveTab(tabId);
    if (tab == null) return false;
    final next = !tab.devToolsOpen;
    _updateTab(tab.id, (current) => current.copyWith(devToolsOpen: next));
    if (next) {
      await _injectEruda(tab.id, autoShow: true);
    } else {
      await _controllers[tab.id]?.runJavaScript('''
(function() {
    if (window.eruda) {
        try {
            window.eruda.destroy();
        } catch(e) {
            try { window.eruda.hide(); } catch(_){}
        }
    }
})()''');
    }
    return next;
  }

  String? _erudaScript;

  /// Eruda 调试器脚本随包提供(与上游同一份 `scripts/eruda.min.js`)。
  Future<String> _loadErudaScript() async {
    final cached = _erudaScript;
    if (cached != null) return cached;
    try {
      _erudaScript = await rootBundle.loadString('assets/codecraft/scripts/eruda.min.js');
    } catch (_) {
      _erudaScript = '';
    }
    return _erudaScript!;
  }

  Future<void> _injectEruda(String tabId, {required bool autoShow}) async {
    final script = await _loadErudaScript();
    if (script.isEmpty) return;
    final showCall = autoShow ? 'try { window.eruda.show(); } catch(e){}' : '';
    await _controllers[tabId]?.runJavaScript('''
(function() {
    if (window.eruda) {
        $showCall
        return;
    }
    try {
        $script
        window.eruda.init();
        $showCall
    } catch(e) {
        console.error('Failed to init Eruda', e);
    }
})()''');
  }

  /// 面板挂载/卸载(对齐上游 attach/detach)。
  void attach() => _emit(_state.copyWith(attached: true));
  void detach() => _emit(_state.copyWith(attached: false));

  /// UI 渲染某个标签时把控制器注册进来;控制器随标签销毁而移除。
  void bindController(String tabId, WebViewController controller) {
    _controllers[tabId] = controller;
    final pending = _pendingUrls.remove(tabId);
    if (pending != null) {
      controller.loadRequest(Uri.parse(pending));
    }
    // 夜间模式下新建/重挂的标签也要跟上:WebView 是原生控件,不继承 Flutter 主题,
    // 必须自己设底色并注入压暗样式。
    if (_state.nightMode) {
      unawaited(controller.setBackgroundColor(_nightBackground));
      unawaited(_applyNightMode(tabId));
    }
  }

  WebViewController? controllerFor(String tabId) => _controllers[tabId];

  /// 新建标签并设为活动标签,返回新标签 id。
  String newTab({String url = ''}) {
    final id = 'tab-${_tabSeq++}';
    _emit(BrowserState(
      tabs: [..._tabs, BrowserTabState(id: id, url: url, loading: url.isNotEmpty)],
      activeTabId: id,
      attached: _state.attached,
      nightMode: _state.nightMode,
      userAgentPreset: _state.userAgentPreset,
      customUserAgent: _state.customUserAgent,
      currentUserAgent: _state.currentUserAgent,
    ));
    if (url.isNotEmpty) {
      _pendingUrls[id] = url;
    }
    return id;
  }

  /// 关闭标签;最后一个标签关闭后自动补一个空白标签(浏览器不空窗)。
  bool closeTab(String tabId) {
    final tabs = _tabs.where((tab) => tab.id != tabId).toList();
    _controllers.remove(tabId);
    _pendingUrls.remove(tabId);
    if (tabs.isEmpty) {
      _emit(_state.copyWith(tabs: const [], activeTabId: ''));
      newTab();
      return true;
    }
    final activeId = _state.activeTabId == tabId ? tabs.first.id : _state.activeTabId;
    _emit(_state.copyWith(tabs: tabs, activeTabId: activeId));
    return true;
  }

  void switchTab(String tabId) {
    if (!_tabs.any((tab) => tab.id == tabId)) return;
    _emit(_state.copyWith(activeTabId: tabId));
  }

  /// 导航(对齐上游 navigate 的输入解析):完整 URL 直用;本地路径转 file://;
  /// 形如主机名则补 `https://`(失败退 http);其余交给搜索引擎。
  Future<String> navigate(String url, {String? tabId}) async {
    final target = url.trim();
    final tab = _resolveTab(tabId);
    if (tab == null) return '';
    if (target.startsWith('http://') || target.startsWith('https://')) {
      await _loadInto(tab, target);
      return target;
    }
    if (_isLocalPathInput(target)) {
      final fileUrl = _resolveLocalFileUrl(target);
      await _loadInto(tab, fileUrl);
      return fileUrl;
    }
    if (_looksLikeHost(target)) {
      try {
        await _loadInto(tab, 'https://$target');
        return 'https://$target';
      } catch (_) {
        await _loadInto(tab, 'http://$target');
        return 'http://$target';
      }
    }
    final searchUrl = searchEngineUrl + Uri.encodeComponent(target);
    await _loadInto(tab, searchUrl);
    return searchUrl;
  }

  Future<void> reload({String? tabId}) async {
    final tab = _resolveTab(tabId);
    if (tab == null) return;
    _updateTab(tab.id, (current) => current.copyWith(loading: true, error: () => null));
    await _controllers[tab.id]?.reload();
  }

  Future<void> goBack({String? tabId}) async {
    final controller = _controllers[_resolveTab(tabId)?.id];
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  Future<void> goForward({String? tabId}) async {
    final controller = _controllers[_resolveTab(tabId)?.id];
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  /// 在页面里执行 JS 并返回结果字符串(AI 工具的基础能力)。
  Future<String> evaluateJavaScript(String script, {String? tabId}) async {
    final controller = _controllers[_resolveTab(tabId)?.id];
    if (controller == null) return '';
    final result = await controller.runJavaScriptReturningResult(script);
    return result.toString();
  }

  /// 截图质量(上游 SCREENSHOT_QUALITY=80)。
  static const int screenshotQuality = 80;

  /// 工作区根目录(截图默认存到 `<root>/.codecraft/browser-screenshots/`)。
  String workspaceRoot = '';

  /// 页面侧注册的抓图回调(把平台视图渲染成 PNG 字节)。
  final Map<String, Future<Uint8List?> Function()> _captureCallbacks = {};

  /// 页面侧注册的 WebView 全局区域回调用(供真实触摸换算坐标)。
  final Map<String, Offset Function()> _originResolvers = {};

  void bindCapture(String tabId, Future<Uint8List?> Function() capture) =>
      _captureCallbacks[tabId] = capture;

  void bindViewOrigin(String tabId, Offset Function() origin) =>
      _originResolvers[tabId] = origin;

  /// 截图(对齐上游 screenshotIfVisible):面板不可见或拿不到像素时返回 null。
  Future<String?> screenshot({String? tabId, String? path}) async {
    if (!attached) return null;
    final tab = _resolveTab(tabId);
    if (tab == null) return null;
    final capture = _captureCallbacks[tab.id];
    if (capture == null) return null;
    final bytes = await capture();
    if (bytes == null) return null;
    final directory = Directory(
      path != null && path.trim().isNotEmpty
          ? p.dirname(path)
          : p.join(workspaceRoot, '.codecraft', 'browser-screenshots'),
    );
    if (!directory.existsSync()) directory.createSync(recursive: true);
    final file = File(
      path != null && path.trim().isNotEmpty
          ? path
          : p.join(
              directory.path,
              'browser-${DateTime.now().millisecondsSinceEpoch}.png',
            ),
    );
    file.writeAsBytesSync(bytes);
    return file.path;
  }

  /// 点击(对齐上游 clickElement 的两步做法):先 JS 取元素中心坐标与尺寸,有可见尺寸时
  /// 派发**真实指针事件**(isTrusted: true,部分站点只认真实触摸),否则退回 JS `el.click()`。
  Future<String> clickElement(String selector, {String? tabId}) async {
    final tab = _resolveTab(tabId);
    if (tab == null) return 'not-found';
    final prepRaw = await evaluateJavaScript('''
$_selectorHelper
(function(sel){
    var el = __resolveSelector(sel);
    if(!el) return JSON.stringify({matched:false});
    el.scrollIntoView({block: 'center'});
    var r = el.getBoundingClientRect();
    return JSON.stringify({
        matched: true,
        x: r.left + r.width / 2,
        y: r.top + r.height / 2,
        w: r.width,
        h: r.height,
        beforeUrl: location.href
    });
})(${_jsLiteral(selector)})''', tabId: tab.id);
    final prep = _decodeJsonObject(prepRaw);
    if (prep == null || prep['matched'] != true) return 'not-found';
    final width = (prep['w'] as num?)?.toDouble() ?? 0;
    final height = (prep['h'] as num?)?.toDouble() ?? 0;
    final x = (prep['x'] as num?)?.toDouble() ?? 0;
    final y = (prep['y'] as num?)?.toDouble() ?? 0;
    final origin = _originResolvers[tab.id];
    if (width > 0 && height > 0 && origin != null) {
      final density = _viewDensityResolvers[tab.id]?.call() ?? 1.0;
      final base = origin();
      final position = Offset(base.dx + x * density, base.dy + y * density);
      GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: position));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: position));
      return 'clicked';
    }
    final fallback = await evaluateJavaScript('''
$_selectorHelper
(function(sel){
    var el = __resolveSelector(sel);
    if (!el) return 'not-found';
    el.click();
    return 'clicked';
})(${_jsLiteral(selector)})''', tabId: tab.id);
    return fallback;
  }

  /// 设备像素比回调(CSS px → 设备 px)。
  final Map<String, double Function()> _viewDensityResolvers = {};

  void bindViewDensity(String tabId, double Function() density) =>
      _viewDensityResolvers[tabId] = density;

  static Map<String, dynamic>? _decodeJsonObject(String raw) {
    try {
      final decoded = jsonDecode(_unquoteJsString(raw));
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  /// 选择器辅助函数(逐字取自上游 `selectorHelper`):prepend 到所有需要选择器的 JS 里,
  /// 支持 `ref=` / `text=` / `text*=` / `role=` / `xpath=` / CSS。
  static const String _selectorHelper = r'''
function __resolveSelector(selector){
    if(selector.startsWith('ref=')){
        var id=selector.substring(4);
        var reg=window.__bicodeRefs||{};
        var el=reg[id];
        return (el && el.isConnected) ? el : null;
    }
    if(selector.startsWith('text=')){
        var t=selector.substring(5);
        var els=document.querySelectorAll('*');
        for(var i=els.length-1;i>=0;i--){
            var own=els[i].childNodes;
            for(var j=0;j<own.length;j++){
                if(own[j].nodeType===3&&own[j].textContent.trim()===t)return els[i];
            }
        }
        for(var i=0;i<els.length;i++){
            if(els[i].textContent.trim()===t)return els[i];
        }
        return null;
    }
    if(selector.startsWith('text*=')){
        var t=selector.substring(6);
        var els=document.querySelectorAll('*');
        var best=null,bestLen=Infinity;
        for(var i=0;i<els.length;i++){
            var tag=els[i].tagName;
            if(tag==='HTML'||tag==='BODY'||tag==='HEAD'||tag==='SCRIPT'||tag==='STYLE')continue;
            var text=els[i].textContent||'';
            if(text.includes(t)&&text.length<bestLen){
                best=els[i];bestLen=text.length;
            }
        }
        return best;
    }
    if(selector.startsWith('role=')){
        var m=selector.match(/^role=(\w+)(?:\[name="(.+)"\])?$/);
        if(!m)return null;
        var role=m[1],name=m[2];
        var els=document.querySelectorAll('[role="'+role+'"]');
        if(name){
            for(var i=0;i<els.length;i++){
                if(els[i].textContent.includes(name))return els[i];
            }
            return null;
        }
        return els[0]||null;
    }
    if(selector.startsWith('xpath=')){
        var x=selector.substring(6);
        return document.evaluate(x,document,null,XPathResult.FIRST_ORDERED_NODE_TYPE,null).singleNodeValue;
    }
    return document.querySelector(selector);
}
''';

  // ── 交互类动作(JS 逐字取自上游)──

  Future<String> fillField(String selector, String value, {String? tabId}) async {
    final result = await evaluateJavaScript('''
$_selectorHelper
(function() {
    var el = __resolveSelector(${_jsLiteral(selector)});
    if (!el) return 'not-found';
    el.focus();
    var proto = el.tagName === 'TEXTAREA' ? window.HTMLTextAreaElement.prototype : window.HTMLInputElement.prototype;
    var setter = Object.getOwnPropertyDescriptor(proto, 'value');
    if (setter && setter.set) { setter.set.call(el, ${_jsLiteral(value)}); } else { el.value = ${_jsLiteral(value)}; }
    el.dispatchEvent(new Event('input', {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
    return 'filled';
})()''', tabId: tabId);
    return result;
  }

  Future<String> pressKey(String key, {String? tabId}) async {
    final result = await evaluateJavaScript('''
(function() {
    var el = document.activeElement || document.body;
    var opts = {key: ${_jsLiteral(key)}, bubbles: true, cancelable: true};
    el.dispatchEvent(new KeyboardEvent('keydown', opts));
    el.dispatchEvent(new KeyboardEvent('keyup', opts));
    return 'pressed';
})()''', tabId: tabId);
    return result;
  }

  Future<String> getText({String? selector, String? tabId}) async {
    final target = selector == null || selector.isEmpty
        ? 'document.body ? document.body.innerText : \'\''
        : '(function(){ var el = __resolveSelector(${_jsLiteral(selector)}); return el ? el.innerText : \'\'; })()';
    final result = await evaluateJavaScript(
      '$_selectorHelper\n(function(){ return $target; })()',
      tabId: tabId,
    );
    return _unquoteJsString(result);
  }

  Future<String> getHtml({String? selector, String? tabId}) async {
    final target = selector == null || selector.isEmpty
        ? 'document.documentElement ? document.documentElement.outerHTML : \'\''
        : '(function(){ var el = __resolveSelector(${_jsLiteral(selector)}); return el ? el.outerHTML : \'\'; })()';
    final result = await evaluateJavaScript(
      '$_selectorHelper\n(function(){ return $target; })()',
      tabId: tabId,
    );
    return _unquoteJsString(result);
  }

  Future<String> scroll({String? selector, int? x, int? y, String? tabId}) async {
    final script = selector != null && selector.isNotEmpty
        ? '$_selectorHelper\n(function(){ var el = __resolveSelector(${_jsLiteral(selector)}); if (!el) return \'not-found\'; el.scrollIntoView({block: \'center\'}); return \'scrolled\'; })()'
        : '(function(){ window.scrollBy(${x ?? 0}, ${y ?? 0}); return \'scrolled\'; })()';
    return evaluateJavaScript(script, tabId: tabId);
  }

  /// 等待条件:`text=` / `text*=` 或选择器存在(与工具参数的 condition 语法一致)。
  Future<bool> wait(
    String condition, {
    int timeoutMs = 10000,
    String? tabId,
  }) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      if (await _conditionMet(condition, tabId)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<bool> _conditionMet(String condition, String? tabId) async {
    if (condition.startsWith('text*=')) {
      final needle = _jsLiteral(condition.substring('text*='.length));
      final result = await evaluateJavaScript(
        '(function(){ return (document.body ? document.body.innerText : \'\').indexOf($needle) >= 0; })()',
        tabId: tabId,
      );
      return result == 'true';
    }
    final selector = condition.startsWith('selector=')
        ? condition.substring('selector='.length)
        : condition;
    final result = await evaluateJavaScript(
      '$_selectorHelper\n(function(){ return __resolveSelector(${_jsLiteral(selector)}) !== null; })()',
      tabId: tabId,
    );
    return result == 'true';
  }

  /// 无障碍树(`getBackbone`):返回 role/name/ref 的 JSON;同时把可交互元素登记进
  /// `window.__bicodeRefs`,后续可用 `ref=e3` 作为选择器。节点预算与上游一致(600)。
  Future<String> getBackbone({int maxDepth = 15, String? tabId}) async {
    final raw = await evaluateJavaScript(
      '$backboneFunction($maxDepth, 600)',
      tabId: tabId,
    );
    return _unquoteJsString(raw);
  }

  // ── 交互类动作(JS 逐字取自上游)──

  /// hover:派发 mouseenter/mouseover/mousemove(上游 hoverElement)。
  Future<String> hoverElement(String selector, {String? tabId}) async {
    final result = await evaluateJavaScript('''
$_selectorHelper
(function(sel){
    var el = __resolveSelector(sel);
    if(!el) return JSON.stringify({matched:false});
    var events = ['mouseenter','mouseover','mousemove'];
    for(var i=0;i<events.length;i++){
        el.dispatchEvent(new MouseEvent(events[i],{
            view: window, bubbles: true, cancelable: true
        }));
    }
    return JSON.stringify({
        matched: true,
        tag: el.tagName ? el.tagName.toLowerCase() : null,
        text: (el.textContent || '').trim().substring(0, 100)
    });
})(${_jsLiteral(selector)})''', tabId: tabId);
    return _unquoteJsString(result);
  }

  /// select:按 option 的 value 或可见文本选中(上游 selectOption)。
  Future<String> selectOption(String selector, String value, {String? tabId}) async {
    final result = await evaluateJavaScript('''
$_selectorHelper
(function(sel, val){
    var el = __resolveSelector(sel);
    if(!el) return JSON.stringify({matched:false, reason:'not-found'});
    if(el.tagName !== 'SELECT') return JSON.stringify({matched:false, reason:'not-select'});
    var opt = null;
    for(var i=0;i<el.options.length;i++){
        var o = el.options[i];
        if(o.value === val || (o.textContent||'').trim() === val){ opt = o; break; }
    }
    if(!opt) return JSON.stringify({matched:false, reason:'option-not-found'});
    el.value = opt.value;
    el.dispatchEvent(new Event('input', {bubbles:true}));
    el.dispatchEvent(new Event('change', {bubbles:true}));
    return JSON.stringify({
        matched: true,
        value: opt.value,
        text: (opt.textContent || '').trim()
    });
})(${_jsLiteral(selector)}, ${_jsLiteral(value)})''', tabId: tabId);
    return _unquoteJsString(result);
  }

  /// 控制台日志缓冲区(由平台 onConsoleMessage 回调写入)。
  final Map<String, List<BrowserConsoleEntry>> _consoleLogs = {};

  void addConsole(String tabId, String level, String message) {
    _consoleLogs.putIfAbsent(tabId, () => []).add(
          BrowserConsoleEntry(level: level, message: message, line: 0, source: ''),
        );
  }

  /// console:按级别过滤后返回 `{count, logs:[...]}`,`clear` 为 true 时取完清空(上游 getConsoleLogs)。
  String getConsoleLogs({String? level, bool clear = false, String? tabId}) {
    final id = _resolveTab(tabId)?.id ?? '';
    final all = _consoleLogs[id] ?? const <BrowserConsoleEntry>[];
    final filtered = (level == null || level.trim().isEmpty)
        ? all.toList()
        : all.where((entry) => entry.level.toLowerCase() == level.toLowerCase()).toList();
    final logs = filtered
        .map((entry) =>
            '{"level":"${entry.level}","message":${_jsonString(entry.message)},'
            '"line":${entry.line},"source":"${entry.source}"}')
        .join(',');
    if (clear) _consoleLogs[id] = [];
    return '{"count":${filtered.length},"logs":[$logs]}';
  }

  static String _jsonString(String value) => '"${value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t')}"';

  /// 逐标签信息(listTabs 动作)。
  List<Map<String, String>> listTabs() => [
        for (final tab in _tabs)
          {
            'id': tab.id,
            'url': tab.url,
            'title': tab.title,
            'active': tab.id == _state.activeTabId ? 'true' : 'false',
          },
      ];

  /// 把 `runJavaScriptReturningResult` 返回的 JSON 字串还原成原文。
  static String _unquoteJsString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
      try {
        final decoded = trimmed
            .substring(1, trimmed.length - 1)
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
        return decoded;
      } catch (_) {
        return trimmed;
      }
    }
    return raw;
  }

  static String _jsLiteral(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n')}'";

  /// 网页对话框由 UI 弹层解决后回填结果(对齐上游 resolveDialogFromUi):
  /// 页面的 JS 在对话框未决期间保持阻塞,与上游 WebChromeClient 行为一致。
  void resolveDialog({required bool accept, String? text}) {
    final dialog = _state.pendingDialog;
    final completer = _dialogCompleter;
    if (dialog == null || completer == null) return;
    _dialogCompleter = null;
    _emit(_state.copyWith(pendingDialog: () => null));
    switch (dialog.type) {
      case 'confirm':
        completer.complete(accept);
      case 'prompt':
        completer.complete(accept ? (text ?? '') : null);
      default:
        completer.complete(null);
    }
  }

  Completer<Object?>? _dialogCompleter;

  /// UI 收到网页对话框回调时登记,交给弹层展示并等待用户结果。
  void registerDialog(BrowserDialog dialog, Completer<Object?> completer) {
    _dialogCompleter = completer;
    _emit(_state.copyWith(pendingDialog: () => dialog));
  }

  /// 切换用户代理:预设自带 UA 字符串,custom 用传入值,default 交回系统默认。
  Future<void> setUserAgent(
    BrowserUserAgentPreset preset, {
    String? custom,
  }) async {
    final ua = preset == BrowserUserAgentPreset.custom
        ? (custom ?? _state.customUserAgent)
        : preset.userAgentString;
    _emit(_state.copyWith(
      userAgentPreset: preset,
      customUserAgent: custom ?? _state.customUserAgent,
      currentUserAgent: ua ?? '',
    ));
    for (final controller in _controllers.values) {
      if (ua == null || ua.isEmpty) {
        await controller.setUserAgent(null);
      } else {
        await controller.setUserAgent(ua);
      }
      await controller.reload();
    }
  }

  /// 夜间模式:注入一段压暗样式(对齐上游 applyNightModeTo)。
  ///
  /// 之前只改了 WebView 背景色——页面自身的白色背景会把它盖住,所以看起来「点了没反应」。
  /// 现在按上游做法:给 `html::after` 盖一层半透明黑蒙版(保留原色、只降亮度,不影响 fixed 布局),
  /// 并设置 `color-scheme: dark` 让原生控件也跟着变暗;页面本身已是深色时跳过,避免重复压暗。
  Future<void> setNightMode(bool enabled) async {
    _emit(_state.copyWith(nightMode: enabled));
    for (final entry in _controllers.entries) {
      await entry.value.setBackgroundColor(
        enabled ? _nightBackground : const Color(0xFFFFFFFF),
      );
      await _applyNightMode(entry.key);
    }
  }

  static const Color _nightBackground = Color(0xFF121212);

  /// 夜间压暗样式:半透明黑蒙版 + 深色 color-scheme。
  static const String _nightStyleId = '__bicode_night_css__';
  /// 整页反色成暗色:invert 让白底黑字变黑底白字,hue-rotate 把反色带来的
  /// 色相偏差转回来;图片和视频再反转一次以保持原色。
  /// 比 rgba 蒙版有效得多——蒙版只是盖一层灰,白底依然是白底。
  static const String _nightCss =
      'html{filter:invert(0.92) hue-rotate(180deg) contrast(0.95)!important;'
      'background:#121212!important}'
      'img,video,picture,canvas,svg,iframe{filter:invert(1) hue-rotate(180deg)!important}';

  /// 对某个标签应用/移除夜间样式。
  Future<void> _applyNightMode(String tabId) async {
    final controller = _controllers[tabId];
    if (controller == null) return;
    final script = _state.nightMode ? _nightOnScript : _nightOffScript;
    try {
      await controller.runJavaScript(script);
    } catch (_) {
      // 页面尚未就绪(about:blank / 已销毁)时注入失败无妨,onPageFinished 会再试一次。
    }
  }

  /// 开启:设 color-scheme,页面本身已是深色则不压暗(避免二次变黑)。
  static const String _nightOnScript = '''
(function(){
    try {
        var meta = document.querySelector('meta[name="color-scheme"]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'color-scheme';
            meta.content = 'dark';
            (document.head || document.documentElement).appendChild(meta);
        } else {
            meta.content = 'dark';
        }
        if (document.documentElement) document.documentElement.style.colorScheme = 'dark';
    } catch(e){}

    var bg = '';
    try {
        var el = document.body || document.documentElement;
        if (el) bg = window.getComputedStyle(el).backgroundColor;
    } catch(e){}

    function isDark(c) {
        if (!c || c === 'transparent' || c === 'rgba(0, 0, 0, 0)') return false;
        var m = c.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
        if (!m) return false;
        var r = parseInt(m[1]), g = parseInt(m[2]), b = parseInt(m[3]);
        return (0.299 * r + 0.587 * g + 0.114 * b) < 128;
    }

    var id = '$_nightStyleId';
    var styleEl = document.getElementById(id);
    if (isDark(bg)) {
        if (styleEl && styleEl.parentNode) styleEl.parentNode.removeChild(styleEl);
        return;
    }
    if (!styleEl) {
        styleEl = document.createElement('style');
        styleEl.id = id;
        styleEl.textContent = "$_nightCss";
        (document.head || document.documentElement).appendChild(styleEl);
    }
    console.log('[night] mask applied, bg=' + bg);
})()''';

  /// 关闭:移除蒙版并恢复 color-scheme。
  static const String _nightOffScript = '''
(function(){
    var id = '$_nightStyleId';
    var el = document.getElementById(id);
    if (el && el.parentNode) el.parentNode.removeChild(el);
    try {
        var meta = document.querySelector('meta[name="color-scheme"]');
        if (meta && meta.content === 'dark') meta.content = 'light';
        if (document.documentElement) document.documentElement.style.colorScheme = '';
    } catch(e){}
})()''';

  Future<void> _loadInto(BrowserTabState tab, String url) async {
    _updateTab(tab.id, (current) => current.copyWith(url: url, loading: true, error: () => null));
    final controller = _controllers[tab.id];
    if (controller == null) {
      _pendingUrls[tab.id] = url;
      return;
    }
    await controller.loadRequest(Uri.parse(url));
  }

  BrowserTabState? _resolveTab(String? tabId) {
    if (tabId != null) {
      for (final tab in _tabs) {
        if (tab.id == tabId) return tab;
      }
      return null;
    }
    return _state.activeTab;
  }

  static bool _looksLikeHost(String target) {
    if (target.contains(RegExp(r'\s'))) return false;
    if (target.startsWith('[')) return true;
    final slash = target.indexOf('/');
    final hostPort = slash < 0 ? target : target.substring(0, slash);
    if (':'.allMatches(hostPort).length >= 2) return true;
    var host = hostPort.split('?').first.split('#').first;
    final colon = host.indexOf(':');
    if (colon >= 0) host = host.substring(0, colon);
    return host == 'localhost' || host.contains('.');
  }

  static bool _isLocalPathInput(String input) =>
      input.startsWith('file://') ||
      input.startsWith('/') ||
      input.startsWith('~') ||
      input.startsWith('./') ||
      input.startsWith('../');

  /// 解码 file:// 后的路径段:非法百分号编码(如未转义的空格)会抛 FormatException,
  /// 这里吞掉异常原样返回,避免把一个路径输入搞崩整个浏览器。
  static String _safeDecodeComponent(String input) {
    try {
      return Uri.decodeComponent(input);
    } catch (_) {
      return input;
    }
  }

  /// 本地路径转 file URL:直接路径存在则用它,否则按工作区相对路径解析。
  static String _resolveLocalFileUrl(String input) {
    final raw = input.startsWith('file://')
        ? _safeDecodeComponent(input.substring('file://'.length))
        : input;
    if (raw.trim().isEmpty) return input;
    final expanded = raw.startsWith('~')
        ? raw.replaceFirst('~', '/root')
        : (raw.startsWith('/') ? raw : '/root/workspace/${raw.replaceFirst(RegExp(r'^\./'), '')}');
    return Uri.file(expanded).toString();
  }

  @override
  void dispose() {
    _controllers.clear();
    super.dispose();
  }
}

/// 全局单例:UI 与 AI 工具共用(对齐上游 BrowserManager 的注入范围)。
final browserManagerProvider = ChangeNotifierProvider<BrowserManager>((ref) {
  final manager = BrowserManager();
  // 截图默认落到当前工作区的 .codecraft/browser-screenshots/。
  manager.workspaceRoot = ref.read(currentWorkspaceProvider).rootPath;
  ref.onDispose(manager.dispose);
  return manager;
});