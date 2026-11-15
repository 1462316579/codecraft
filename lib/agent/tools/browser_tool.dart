import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../data/browser/browser_manager.dart';
import 'tool.dart';

/// 内置浏览器工具(对照上游 `feature/agent/domain/tool/browser/BrowserTool.kt`):
/// 与浏览器页面共用同一个 [BrowserManager],所以 AI 操作的就是用户眼前那个标签。
class BrowserTool extends AgentTool {
  BrowserTool(this._ref);

  final Ref _ref;

  static const List<String> actions = [
    'navigate',
    'evaluate',
    'click',
    'fill',
    'select',
    'hover',
    'press',
    'getText',
    'getHtml',
    'getBackbone',
    'screenshot',
    'console',
    'wait',
    'scroll',
    'dialog',
    'back',
    'forward',
    'reload',
    'newTab',
    'closeTab',
    'selectTab',
    'listTabs',
  ];

  static const Set<String> readOnlyActions = {
    'getText',
    'getHtml',
    'getBackbone',
    'screenshot',
    'console',
    'wait',
    'listTabs',
  };

  @override
  String get name => 'browser';

  @override
  String get description =>
      '控制应用内置浏览器执行自动化操作,与浏览器页面共用同一组标签(WebView)。'
      '浏览器页未打开时会自动打开并等待 WebView 挂载,之后可后台执行;无标签时会自动新建。'
      'selector 支持 ref= / text= / text*= / role=button[name=xxx] / xpath= / CSS;'
      'getBackbone 返回无障碍树(role/name/ref),ref 可直接用作 selector。'
      '需查看页面视觉内容时显式调用 action="screenshot"。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.networkRead};

  @override
  PermissionRequestText permissionRequest(
      Map<String, dynamic> args, String argsPreview) {
    final action = (args['action'] as String?)?.trim() ?? '';
    final url = args['url'] as String?;
    final target = (url != null && url.isNotEmpty) ? ' $url' : '';
    return PermissionRequestText(
      title: '内置浏览器',
      summary: 'AI 请求执行 browser.$action$target',
      details: argsPreview,
    );
  }

  @override
  Map<String, ToolParameter> get parameters => {
        'action': ToolParameter(
          name: 'action',
          type: ParameterType.string,
          description: '操作类型。navigate=导航URL(支持 http(s)/file:// 与容器路径,非网址输入按搜索关键词处理); '
              'evaluate=执行JS(支持 Promise); click/fill/hover/press=交互(兼容 React); select=下拉选择; '
              'getText/getHtml=提取内容; getBackbone=无障碍树(role/name/ref); screenshot=截图; '
              'console=控制台日志; wait=等待条件; scroll=滚动; dialog=处理confirm/prompt(浏览器面板可见时由用户在界面上处理); '
              'back/forward/reload=导航控制; newTab/closeTab/selectTab/listTabs=标签页管理',
          enumValues: actions,
        ),
        'selector': ToolParameter(
          name: 'selector',
          type: ParameterType.string,
          description: 'click/fill/select/hover/getText/getHtml/scroll: 目标元素。支持 ref= / text= / text*= / '
              'role=button[name=xxx] / xpath= / CSS',
          required: false,
        ),
        'value': ToolParameter(
          name: 'value',
          type: ParameterType.string,
          description: 'fill/select: 要填入的值或要选中的 option(value 或可见文本)',
          required: false,
        ),
        'script': ToolParameter(
          name: 'script',
          type: ParameterType.string,
          description: 'evaluate: JS 代码(支持 Promise/async)',
          required: false,
        ),
        'url': ToolParameter(
          name: 'url',
          type: ParameterType.string,
          description: 'navigate/newTab: URL。支持 http(s);本地文件支持 file:// 或容器路径(~/workspace/…、/etc/…);'
              '无协议头时优先 https,失败回退 http;不像网址的输入则用内置搜索引擎(Bing)搜索',
          required: false,
        ),
        'path': ToolParameter(
          name: 'path',
          type: ParameterType.string,
          description: 'screenshot: 截图保存路径(可选,缺省默认保存在 <工作区>/.codecraft/browser-screenshots/)',
          required: false,
        ),
        'key': ToolParameter(
          name: 'key',
          type: ParameterType.string,
          description: 'press: 键名(Enter/Escape/Tab/ArrowUp/…)',
          required: false,
        ),
        'condition': ToolParameter(
          name: 'condition',
          type: ParameterType.string,
          description: 'wait: 等待条件。text=登录(精确匹配) / text*=登录(包含匹配) / selector=#result(CSS存在) / domStable(DOM稳定)',
          required: false,
        ),
        'timeout': ToolParameter(
          name: 'timeout',
          type: ParameterType.integer,
          description: 'wait: 超时毫秒,默认 10000',
          required: false,
        ),
        'maxDepth': ToolParameter(
          name: 'maxDepth',
          type: ParameterType.integer,
          description: 'getBackbone: 无障碍树最大深度,默认 15',
          required: false,
        ),
        'level': ToolParameter(
          name: 'level',
          type: ParameterType.string,
          description: 'console: 日志级别过滤(log/warning/error/debug)',
          required: false,
        ),
        'clear': ToolParameter(
          name: 'clear',
          type: ParameterType.boolean,
          description: 'console: 取完后是否清空日志,默认 false',
          required: false,
        ),
        'accept': ToolParameter(
          name: 'accept',
          type: ParameterType.boolean,
          description: 'dialog: 是否接受对话框(true=确定,false=取消),默认 true',
          required: false,
        ),
        'text': ToolParameter(
          name: 'text',
          type: ParameterType.string,
          description: 'dialog: prompt 输入内容(accept=true 时生效)',
          required: false,
        ),
        'tabId': ToolParameter(
          name: 'tabId',
          type: ParameterType.string,
          description: '目标标签 id(缺省作用于当前激活标签)',
          required: false,
        ),
      };

  /// 确保目标标签的 WebView 控制器已就绪;浏览器页未打开时自动打开并等待挂载。
  Future<bool> _ensureAttached(BrowserManager manager, String? tabId) async {
    bool ready() =>
        manager.controllerFor(tabId ?? manager.state.activeTabId) != null;
    if (ready()) return true;
    final target = tabId ?? manager.state.activeTabId;
    if (target.isEmpty) return false;
    if (!manager.state.tabs.any((tab) => tab.id == target)) return false;

    final router = _ref.read(routerProvider);
    if (router.routerDelegate.currentConfiguration.uri.path != '/browser') {
      // push 的 Future 在页面关闭时才完成,这里不等待。
      unawaited(router.push('/browser'));
    }
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (ready()) return true;
    }
    return false;
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final manager = _ref.read(browserManagerProvider);
    final action = (args['action'] as String?)?.trim() ?? '';
    final tabId = args['tabId'] as String?;
    // 无标签时自动新建一个,避免 AI 操作因「无活动标签」而静默失败。
    if (action != 'listTabs' && action != 'newTab' && action != 'closeTab' &&
        action != 'selectTab' && manager.state.tabs.isEmpty) {
      manager.newTab();
    }
    ToolError notAttached() => const ToolError(
          '浏览器 WebView 启动失败。请确认应用内可以正常打开浏览器页后重试。',
          code: 'BROWSER_NOT_ATTACHED',
        );
    const jsActions = {
      'navigate', 'evaluate', 'click', 'fill', 'press', 'getText', 'getHtml',
      'scroll', 'wait', 'back', 'forward', 'reload', 'hover', 'select', 'getBackbone',
    };
    // 浏览器页没打开时 WebView 尚未创建,JS 无法执行。这里自动打开浏览器页
    // 并等待控制器挂载,让 AI 不必先让用户手动点开浏览器。
    if (jsActions.contains(action) && !await _ensureAttached(manager, tabId)) {
      return notAttached();
    }
    if (action == 'screenshot') {
      await _ensureAttached(manager, tabId);
      // 等首帧渲染完成,否则抓到的可能是空白页面。
      if (manager.state.attached) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    switch (action) {
      case 'navigate':
        final url = args['url'] as String? ?? '';
        if (url.isEmpty) return const ToolError('navigate 需要 url 参数');
        final resolved = await manager.navigate(url, tabId: tabId);
        return ToolSuccess('已导航到 $resolved');
      case 'evaluate':
        final script = args['script'] as String? ?? '';
        if (script.isEmpty) return const ToolError('evaluate 需要 script 参数');
        final output = await manager.evaluateJavaScript(script, tabId: tabId);
        return ToolSuccess(output.isEmpty ? '(空结果)' : output);
      case 'click':
        final selector = args['selector'] as String? ?? '';
        if (selector.isEmpty) return const ToolError('click 需要 selector 参数');
        final result = await manager.clickElement(selector, tabId: tabId);
        return result == 'not-found'
            ? ToolError('未找到元素: $selector')
            : ToolSuccess('已点击 $selector');
      case 'fill':
        final selector = args['selector'] as String? ?? '';
        final value = args['value'] as String? ?? '';
        if (selector.isEmpty) return const ToolError('fill 需要 selector 参数');
        final result = await manager.fillField(selector, value, tabId: tabId);
        return result == 'not-found'
            ? ToolError('未找到元素: $selector')
            : ToolSuccess('已填入 $value');
      case 'press':
        final key = args['key'] as String? ?? '';
        if (key.isEmpty) return const ToolError('press 需要 key 参数');
        await manager.pressKey(key, tabId: tabId);
        return ToolSuccess('已按键 $key');
      case 'getText':
        final text = await manager.getText(selector: args['selector'] as String?, tabId: tabId);
        return ToolSuccess(text.isEmpty ? '(无文本)' : text);
      case 'getHtml':
        final html = await manager.getHtml(selector: args['selector'] as String?, tabId: tabId);
        return ToolSuccess(html.isEmpty ? '(无内容)' : html);
      case 'scroll':
        final result = await manager.scroll(
          selector: args['selector'] as String?,
          x: args['x'] as int?,
          y: args['y'] as int?,
          tabId: tabId,
        );
        return result == 'not-found'
            ? ToolError('未找到元素: ${args['selector']}')
            : ToolSuccess('已滚动');
      case 'wait':
        final condition = args['condition'] as String? ?? '';
        if (condition.isEmpty) return const ToolError('wait 需要 condition 参数');
        final timeout = (args['timeout'] as int?) ?? 10000;
        final met = await manager.wait(condition, timeoutMs: timeout, tabId: tabId);
        return met
            ? ToolSuccess('条件已满足: $condition')
            : ToolError('等待超时(${timeout}ms): $condition');
      case 'dialog':
        if (manager.state.pendingDialog == null) {
          return const ToolError('当前没有待处理的对话框');
        }
        final accept = (args['accept'] as bool?) ?? true;
        manager.resolveDialog(accept: accept, text: args['text'] as String?);
        return ToolSuccess(accept ? '已确认对话框' : '已取消对话框');
      case 'back':
        await manager.goBack(tabId: tabId);
        return ToolSuccess('已后退');
      case 'forward':
        await manager.goForward(tabId: tabId);
        return ToolSuccess('已前进');
      case 'reload':
        await manager.reload(tabId: tabId);
        return ToolSuccess('已刷新');
      case 'newTab':
        final id = manager.newTab();
        final url = args['url'] as String?;
        if (url != null && url.isNotEmpty) await manager.navigate(url, tabId: id);
        return ToolSuccess('已新建标签 $id');
      case 'closeTab':
        final target = tabId ?? manager.state.activeTabId;
        manager.closeTab(target);
        return ToolSuccess('已关闭标签 $target');
      case 'selectTab':
        final target = tabId ?? '';
        if (target.isEmpty) return const ToolError('selectTab 需要 tabId 参数');
        manager.switchTab(target);
        return ToolSuccess('已切换到标签 $target');
      case 'listTabs':
        final tabs = manager.listTabs();
        final lines = tabs
            .map((tab) => '- ${tab['id']}${tab['active'] == 'true' ? ' (当前)' : ''} '
                '${tab['title']?.isEmpty == true ? '(无标题)' : tab['title']} ${tab['url']}')
            .join('\n');
        return ToolSuccess(lines.isEmpty ? '(无标签)' : lines);
      case 'getBackbone':
        final backbone = await manager.getBackbone(
          maxDepth: (args['maxDepth'] as int?) ?? 15,
          tabId: tabId,
        );
        return ToolSuccess(backbone.isEmpty ? '(空无障碍树)' : backbone);
      case 'hover':
        final selector = args['selector'] as String? ?? '';
        if (selector.isEmpty) return const ToolError('hover 需要 selector 参数');
        final result = await manager.hoverElement(selector, tabId: tabId);
        return ToolSuccess(result);
      case 'select':
        final selector = args['selector'] as String? ?? '';
        final value = args['value'] as String? ?? '';
        if (selector.isEmpty) return const ToolError('select 需要 selector 参数');
        final result = await manager.selectOption(selector, value, tabId: tabId);
        return ToolSuccess(result);
      case 'console':
        final logs = manager.getConsoleLogs(
          level: args['level'] as String?,
          clear: (args['clear'] as bool?) ?? false,
          tabId: tabId,
        );
        return ToolSuccess(logs);
      case 'screenshot':
        final path = await manager.screenshot(
          tabId: tabId,
          path: args['path'] as String?,
        );
        return path == null
            ? const ToolError('截图失败(浏览器面板不可见或拿不到像素)')
            : ToolSuccess('截图已保存: $path');
      default:
        return ToolError('未知 action: $action');
    }
  }
}

/// 工具在会话里的注册入口。
final browserToolProvider = Provider<BrowserTool>((ref) => BrowserTool(ref));