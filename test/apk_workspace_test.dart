import 'dart:io';

import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/current_project.dart';
import 'package:codecraft/data/apk_workspace.dart';
import 'package:codecraft/data/workspaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 逆向项目的工作区必须是目标 APK 解出来的目录,
/// 否则读文件 / 列目录 / 搜索这些工具还在看空的项目目录。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const apkChannel = MethodChannel('com.codecraft.flutter/apk_files');
  const storageChannel = MethodChannel('com.codecraft.flutter/external_storage');

  late Directory sandbox;
  late int extractCalls;
  late List<String> lastApkPaths;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('apk-ws');
    extractCalls = 0;
    lastApkPaths = const [];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(storageChannel, (call) async {
      if (call.method == 'primaryRoot') return '/storage/emulated/0';
      return null;
    });
    messenger.setMockMethodCallHandler(apkChannel, (call) async {
      if (call.method != 'extract') return null;
      extractCalls++;
      lastApkPaths = [
        for (final path in (call.arguments['apkPaths'] as List<Object?>))
          if (path is String) path,
      ];
      final dir = Directory(call.arguments['destDir'] as String)..createSync(recursive: true);
      Directory(p.join(dir.path, 'res')).createSync();
      File(p.join(dir.path, 'AndroidManifest.xml')).writeAsStringSync('<manifest/>');
      return 1;
    });
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(apkChannel, null);
    messenger.setMockMethodCallHandler(storageChannel, null);
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  Project reverseProject({String id = 'p1', String? apkPath = '/data/app/x/base.apk'}) => Project(
        id: id,
        name: '栗子漫画',
        createdAt: 0,
        updatedAt: 0,
        kind: ProjectKind.reverse,
        appApkPath: apkPath,
      );

  /// 非逆向项目的工作区来自异步的 workspacesProvider,要先等它就绪。
  Future<ProviderContainer> boot(Project? project) async {
    final container = ProviderContainer(
      overrides: [
        workspaceProvider.overrideWithValue(Workspace(sandbox.path)),
        currentProjectProvider.overrideWithValue(project),
      ],
    );
    addTearDown(container.dispose);
    await container.read(workspacesProvider.future);
    return container;
  }

  test('逆向项目:工作区指向 APK 解压目录,不是默认项目目录', () async {
    final container = await boot(reverseProject());
    final root = container.read(currentWorkspaceProvider).rootPath;

    expect(root, p.join(sandbox.path, 'apk-p1'));
    expect(root, isNot(p.join(sandbox.path, 'apk-default')),
        reason: '逆向项目工作区按项目 id 隔离,不退回默认目录');
  });

  test('编程项目:工作区仍是默认项目目录', () async {
    final container = await boot(
      const Project(id: 'p2', name: '编程', createdAt: 0, updatedAt: 0),
    );
    final root = container.read(currentWorkspaceProvider).rootPath;
    expect(root, p.join(sandbox.path, '编程'));
  });

  test('没有当前项目:退回默认项目目录', () async {
    final container = await boot(null);
    final root = container.read(currentWorkspaceProvider).rootPath;
    expect(root, sandbox.path);
  });

  test('解压后目录里是 APK 的内容;再次调用不重复解包', () async {
    final container = await boot(reverseProject());
    final workspace = container.read(apkWorkspaceProvider);
    final project = reverseProject();

    final dir = await workspace.ensureExtracted(project);
    expect(File(p.join(dir, 'AndroidManifest.xml')).existsSync(), isTrue);
    expect(Directory(p.join(dir, 'res')).existsSync(), isTrue);
    expect(extractCalls, 1);

    await workspace.ensureExtracted(project);
    expect(extractCalls, 1, reason: '已解压过就复用,不重复解包');
  });

  test('拿不到安装包路径时报错', () async {
    final container = await boot(reverseProject(apkPath: null));
    final workspace = container.read(apkWorkspaceProvider);
    await expectLater(
      workspace.ensureExtracted(reverseProject(apkPath: null)),
      throwsA(isA<ApkWorkspaceException>()),
    );
  });

  test('分卷 APK 会一起解包(原生库常只在分卷里)', () async {
    const splits = [
      '/data/app/x/base.apk',
      '/data/app/x/split_config.arm64_v8a.apk',
      '/data/app/x/split_config.zh.apk',
    ];
    final project = Project(
      id: 'p3',
      name: '分卷应用',
      createdAt: 0,
      updatedAt: 0,
      kind: ProjectKind.reverse,
      appApkPath: splits.first,
      appApkPaths: splits,
    );
    final container = await boot(project);
    await container.read(apkWorkspaceProvider).ensureExtracted(project);

    expect(lastApkPaths, splits, reason: 'base 与所有分卷都要解,否则看不到 libapp.so');
  });

  test('只有 base 路径时退回单包解压(老项目兼容)', () async {
    final project = reverseProject(id: 'p4');
    final container = await boot(project);
    await container.read(apkWorkspaceProvider).ensureExtracted(project);

    expect(lastApkPaths, ['/data/app/x/base.apk']);
  });

  test('并发调用只解包一次', () async {
    final project = reverseProject(id: 'p5');
    final container = await boot(project);
    final workspace = container.read(apkWorkspaceProvider);

    await Future.wait([
      workspace.ensureExtracted(project),
      workspace.ensureExtracted(project),
      workspace.ensureExtracted(project),
    ]);

    expect(extractCalls, 1, reason: '自动解包与手动点按钮撞在一起时不能重复写同一目录');
  });
}
