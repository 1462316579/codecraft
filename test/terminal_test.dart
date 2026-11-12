import 'dart:async';

import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/terminal/terminal_manager.dart';
import 'package:codecraft/features/terminal/terminal_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:codecraft/data/terminal/terminal_settings.dart';
import 'package:codecraft/data/terminal/terminal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 假终端进程:记录写入字节,可由测试推入输出。
class _FakeProcess implements TerminalProcess {
  _FakeProcess();

  final _output = StreamController<List<int>>();
  final List<int> written = [];
  final List<({int cols, int rows})> resizes = [];
  bool killed = false;
  final _exit = Completer<int>();

  @override
  Stream<List<int>> get output => _output.stream;

  @override
  void write(List<int> bytes) => written.addAll(bytes);

  @override
  Future<int> get exitCode => _exit.future;

  @override
  void resize(int cols, int rows) {
    resizes.add((cols: cols, rows: rows));
  }

  @override
  void kill() {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(137);
    _output.close();
  }

  void emit(String text) => _output.add(text.codeUnits);
}

class _FakeEngine implements CommandEngine {
  _FakeEngine(this.process);

  final _FakeProcess process;
  final List<({int cols, int rows})> opened = [];

  @override
  Future<TerminalProcess> openTerminal({String? command, int cols = 80, int rows = 24, String? workdir}) async {
    opened.add((cols: cols, rows: rows));
    return process;
  }

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  @override
  Future<CommandResult> runCommandSync(String command,
          {String? workdir, Duration timeout = const Duration(seconds: 120)}) async =>
      const CommandResult(output: '', exitCode: 0);

  @override
  Stream<Object> runCommandStream(String command,
          {String? workdir, Duration timeout = const Duration(seconds: 120)}) =>
      const Stream.empty();
}

void main() {
  group('终端配色主题', () {
    test('7 套预设,跟随应用按当前主题合成且保留 ANSI 调色板', () {
      expect(TerminalThemePreset.all.length, 7);
      expect(TerminalThemePreset.all.first.id, TerminalThemePreset.followAppId);

      final resolved = TerminalThemePreset.resolve(
        TerminalThemePreset.followApp,
        background: const Color(0xFF123456),
        foreground: const Color(0xFFABCDEF),
        cursor: const Color(0xFF654321),
      );
      expect(resolved.background, const Color(0xFF123456));
      expect(resolved.foreground, const Color(0xFFABCDEF));
      expect(resolved.ansi, TerminalThemePreset.followApp.ansi);

      final dracula = TerminalThemePreset.resolve(
        TerminalThemePreset.dracula,
        background: const Color(0xFF000000),
        foreground: const Color(0xFFFFFFFF),
        cursor: const Color(0xFF000000),
      );
      expect(dracula.background, TerminalThemePreset.dracula.background, reason: '预设不跟随应用');
    });

    test('未知 id 回落跟随应用;ANSI 映射到 xterm 主题', () {
      expect(TerminalThemePreset.byId('nope').id, TerminalThemePreset.followAppId);
      final xterm = TerminalThemePreset.githubDark.toXtermTheme();
      expect(xterm.background, TerminalThemePreset.githubDark.background);
      expect(xterm.red, TerminalThemePreset.githubDark.ansi[1]);
      expect(xterm.brightWhite, TerminalThemePreset.githubDark.ansi[15]);
    });
  });

  group('终端设置', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('默认值:跟随应用 / 14sp / 方块 / 系统等宽', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = TerminalSettingsNotifier(prefs);
      expect(notifier.state.themeId, 'follow_app');
      expect(notifier.state.fontSize, 14);
      expect(notifier.state.cursorStyle, TerminalCursorStyle.block);
      expect(notifier.state.fontFamily, TerminalFontFamily.system);
      notifier.dispose();
    });

    test('改动落盘并可回读;字号夹在 8~28', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = TerminalSettingsNotifier(prefs);
      await notifier.setTheme('dracula');
      await notifier.setCursorStyle(TerminalCursorStyle.bar);
      await notifier.setFontFamily(TerminalFontFamily.jetBrainsMono);
      await notifier.setFontSize(40);
      expect(notifier.state.fontSize, TerminalSettingsNotifier.maxFontSize);

      final reloaded = TerminalSettingsNotifier(prefs);
      expect(reloaded.state.themeId, 'dracula');
      expect(reloaded.state.cursorStyle, TerminalCursorStyle.bar);
      expect(reloaded.state.fontFamily, TerminalFontFamily.jetBrainsMono);
      notifier.dispose();
      reloaded.dispose();
    });
  });

  group('终端会话与标签', () {
    test('CTRL/ALT 修饰映射为控制字节', () {
      expect(applyTerminalModifiers('c', ctrl: true, alt: false), [0x03]);
      expect(applyTerminalModifiers('C', ctrl: true, alt: false), [0x03]);
      expect(applyTerminalModifiers('[', ctrl: true, alt: false), [0x1b]);
      expect(applyTerminalModifiers('x', ctrl: false, alt: true), [0x1b, 0x78]);
      expect(applyTerminalModifiers('x', ctrl: true, alt: true), [0x1b, 0x18]);
      expect(applyTerminalModifiers('ls', ctrl: false, alt: false), [0x6c, 0x73]);
    });

    test('新建标签建立会话、输出进终端、关闭标签回收进程', () async {
      final process = _FakeProcess();
      final engine = _FakeEngine(process);
      final container = ProviderContainer(overrides: [
        terminalCommandEngineProvider.overrideWith((ref) async => engine),
        workspaceProvider.overrideWithValue(Workspace('/tmp/term-ws')),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(terminalTabsProvider.notifier);

      await notifier.newTab();
      var state = container.read(terminalTabsProvider);
      expect(state.tabs, hasLength(1));
      expect(state.activeTabId, state.tabs.single.id);
      expect(state.tabs.single.running, isTrue);
      expect(state.tabs.single.terminal.viewWidth, engine.opened.single.cols);

      // 终端输出写进 xterm 缓冲;输入经修饰键映射后送到进程。
      process.emit('hello');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      notifier.write('ls');
      expect(process.written, 'ls'.codeUnits);

      notifier.toggleCtrl();
      notifier.writeBytes([0x03]);
      expect(process.written.sublist(2), [0x03]);
      expect(container.read(terminalTabsProvider).ctrl, isFalse, reason: '修饰键用完即复位');

      notifier.closeTab(state.tabs.single.id);
      state = container.read(terminalTabsProvider);
      expect(state.tabs, isEmpty);
      expect(process.killed, isTrue);
    });
  });

  group('终端页布局', () {
    // 顶部三条(标题栏/标签栏/终端内容)的间距与尺寸:用 golden 截图人工核对,
    // 不复用 pumpAndSettle(聚焦的终端视图会一直等待输入,settle 会挂住)。
    testWidgets('顶部栏目尺寸与间距', (tester) async {
      tester.view.physicalSize = const Size(1080, 2000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final process = _FakeProcess();
      final container = ProviderContainer(overrides: [
        terminalCommandEngineProvider.overrideWith((ref) async => _FakeEngine(process)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        workspaceProvider.overrideWithValue(Workspace('/tmp/term-ws')),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            home: const TerminalPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // 标题栏 64dp、标签卡 36dp、间距 4dp(对齐上游 TopAppBar/TabBar 规格)。
      final appBar = tester.getRect(find.byType(AppBar));
      expect(appBar.height - MediaQuery.of(tester.element(find.byType(AppBar))).padding.top, 64);
      final tabBar = tester.getRect(find.byType(ListView).first);
      expect(tabBar.height, 44, reason: '标签栏 = 垂直内边距 4 + 标签卡 36 + 4');
      expect(tabBar.left, 0, reason: '内容靠左起排(与上游 horizontalScroll 一致)');
      final keysRow = tester.getRect(find.byType(ListView).last);
      expect(keysRow.height, 46, reason: '按键行 = 按键 34 + 上下内边距 6/6');

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/terminal_page_expanded.png'),
      );
    });
  });

  group('AI 命令镜像到终端', () {
    ProviderContainer boot() {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [workspaceProvider.overrideWithValue(Workspace('/tmp/term-ws'))],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('执行命令时创建镜像标签并写入命令与输出', () {
      final container = boot();
      final notifier = container.read(terminalTabsProvider.notifier);

      notifier.mirrorCommand('AI 命令', 'ls -la');
      notifier.mirrorOutput('total 0\n');

      final state = container.read(terminalTabsProvider);
      final tab = state.tabs.single;
      expect(tab.mirror, isTrue, reason: '镜像标签不该被当成可输入的 shell');
      expect(tab.title, 'AI 命令');
      expect(tab.process, isNull, reason: '镜像标签不连 PTY');
      final text = tab.terminal.buffer.getText();
      expect(text, contains('ls -la'), reason: '终端里应能看到 AI 跑了什么');
      expect(text, contains('total 0'));
    });

    test('非零退出码补一行提示', () {
      final container = boot();
      final notifier = container.read(terminalTabsProvider.notifier);
      notifier.mirrorCommand('AI 命令', 'false');
      notifier.mirrorOutput('', exitCode: 1);

      final tab = container.read(terminalTabsProvider).tabs.single;
      expect(tab.terminal.buffer.getText(), contains('[exit 1]'));
    });

    test('多次执行复用同一个镜像标签', () {
      final container = boot();
      final notifier = container.read(terminalTabsProvider.notifier);
      notifier.mirrorCommand('AI 命令', 'echo 1');
      notifier.mirrorCommand('AI 命令', 'echo 2');

      final tabs = container.read(terminalTabsProvider).tabs;
      expect(tabs, hasLength(1));
      final text = tabs.single.terminal.buffer.getText();
      expect(text, contains('echo 1'));
      expect(text, contains('echo 2'));
    });

    test('只有镜像标签时仍会开一个真 shell', () async {
      final process = _FakeProcess();
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          terminalCommandEngineProvider.overrideWith((ref) async => _FakeEngine(process)),
          workspaceProvider.overrideWithValue(Workspace('/tmp/term-ws')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(terminalTabsProvider.notifier);
      notifier.mirrorCommand('AI 命令', 'echo hi');
      await notifier.prepare();

      final tabs = container.read(terminalTabsProvider).tabs;
      expect(tabs.where((tab) => !tab.mirror), hasLength(1),
          reason: '进终端页必须有一个可输入的 shell,不能只剩镜像标签');
    });
  });
}
