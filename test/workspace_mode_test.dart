import 'dart:io';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/current_project.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/workspaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 工作区路径由项目类型决定,用户不能手动改:
/// - 编程:容器内的 `<沙盒>/<项目名>`
/// - 逆向:容器内的 `<沙盒>/apk-<项目 id>`
/// - 写作:`/storage/emulated/0/AI小说`
///
/// 当前工作区按模式**派生**,不存可变状态:早先存成状态后,冷启动或 provider
/// 重建会退回 `default`,写作项目的文件面板就显示成 `default`。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel('com.codecraft.flutter/external_storage');

  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('ws-sandbox');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      if (call.method == 'primaryRoot') return '/storage/emulated/0';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  Future<ProviderContainer> boot({AgentMode mode = AgentMode.build}) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        workspaceProvider.overrideWithValue(Workspace(sandbox.path)),
        currentAgentModeProvider.overrideWithValue(mode),
      ],
    );
    addTearDown(container.dispose);
    await container.read(workspacesProvider.future);
    return container;
  }

  test('编程项目用容器内目录', () async {
    final container = await boot();
    final current = container.read(currentWorkspaceInfoProvider)!;

    expect(current.isExternal, isFalse);
    expect(current.path, '${sandbox.path}/编程');
    expect(Directory(current.path).existsSync(), isTrue, reason: '容器内目录应已创建');
  });

  test('写作项目用 /storage/emulated/0/AI小说,不是 default', () async {
    final container = await boot(mode: AgentMode.write);
    final current = container.read(currentWorkspaceInfoProvider)!;

    expect(current.isExternal, isTrue);
    expect(current.path, '/storage/emulated/0/AI小说');
    expect(current.name, 'AI小说');
    expect(current.name, isNot('default'), reason: '写作项目落到沙盒就是这次要修的 bug');
  });

  test('写作目录不存在时仍然出现在列表里(不因读不到而消失)', () async {
    // 没权限时 Directory.exists() 对 /storage/emulated/0/... 也返回 false,
    // 若据此丢弃,外部工作区会整个消失、表现为「识别不到外部文件夹」。
    final container = await boot();
    final state = container.read(workspacesProvider).valueOrNull!;
    final external = state.workspaces.where((w) => w.isExternal).toList();
    expect(external, hasLength(1));
    expect(external.single.path, '/storage/emulated/0/AI小说');
  });

  test('provider 重建后仍按模式解析(不退回 default)', () async {
    final container = await boot(mode: AgentMode.write);
    expect(container.read(currentWorkspaceInfoProvider)!.name, 'AI小说');

    // 重建状态:早先这里会把「当前工作区」重置成 default。
    container.invalidate(workspacesProvider);
    await container.read(workspacesProvider.future);

    expect(
      container.read(currentWorkspaceInfoProvider)!.name,
      'AI小说',
      reason: '当前工作区应由模式派生,重建后不该退回 default',
    );
  });

  test('两种模式解析到不同目录', () async {
    final build = await boot();
    expect(build.read(currentWorkspaceInfoProvider)!.isExternal, isFalse);

    final write = await boot(mode: AgentMode.write);
    expect(write.read(currentWorkspaceInfoProvider)!.isExternal, isTrue);
  });
}