import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/installed_apps.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/home/installed_apps_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 「应用逆向」流程:选应用 → 项目里显示应用的图标/名称/包名/版本。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  const appsChannel = MethodChannel('com.codecraft.flutter/installed_apps');

  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    // 跳过首次权限引导:本文件不验证它,弹窗会遮挡其它点击。
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    db = await AppDatabase.open(inMemory: true);
    tempDir = await Directory.systemTemp.createTemp('codecraft-apps');
  });

  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appsChannel, null);
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// 宿主侧「已安装应用」通道:两条应用。
  void mockAppsChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appsChannel, (call) async {
      switch (call.method) {
        case 'listApps':
          return [
            {
              'packageName': 'com.hbsclj.uth',
              'label': '栗子漫画',
              'versionName': '1.1.7',
              'versionCode': 19,
              'isSystem': false,
              'apkPath': '/data/app/~~hash/com.hbsclj.uth-1/base.apk',
            },
            {
              'packageName': 'com.tudou.tool',
              'label': '囧次元',
              'versionName': '1.5.8.0',
              'versionCode': 84,
              'isSystem': false,
            },
          ];
        case 'appIcon':
          // 1x1 透明 PNG:只要能被解码即可。
          return Uint8List.fromList(const [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
            0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
            0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
            0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
            0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
            0x42, 0x60, 0x82,
          ]);
      }
      return null;
    });
  }

  testWidgets('应用列表按名称/包名/版本展示,点选返回该应用', (tester) async {
    mockAppsChannel();
    InstalledApp? picked;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await Navigator.of(context).push<InstalledApp>(
                      MaterialPageRoute(builder: (_) => const InstalledAppsPage()),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 三行信息:名称 / 包名 / 版本 (code)。
    expect(find.text('栗子漫画'), findsOneWidget);
    expect(find.text('com.hbsclj.uth'), findsOneWidget);
    expect(find.text('1.1.7 (19)'), findsOneWidget);
    expect(find.text('囧次元'), findsOneWidget);
    expect(find.text('1.5.8.0 (84)'), findsOneWidget);

    await tester.tap(find.text('囧次元'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(picked?.packageName, 'com.tudou.tool');
    expect(picked?.label, '囧次元');
  });

  testWidgets('逆向项目行显示应用名/包名/版本', (tester) async {
    await db.projectDao.upsert(
      const Project(
        id: 'p-rev',
        name: '栗子漫画',
        createdAt: 1,
        updatedAt: 2,
        kind: ProjectKind.reverse,
        appPackage: 'com.hbsclj.uth',
        appName: '栗子漫画',
        appVersionName: '1.1.7',
        appVersionCode: 19,
      ),
    );
    await db.sessionDao.upsert(
      const ChatSession(
        id: 's-rev',
        title: '',
        createdAt: 1,
        updatedAt: 2,
        projectId: 'p-rev',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-apps-test')),
          installedAppsProvider.overrideWith((ref) async => const <InstalledApp>[]),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(find.text('栗子漫画'), findsOneWidget);
    expect(find.text('com.hbsclj.uth'), findsOneWidget);
    expect(find.text('1.1.7 (19)'), findsOneWidget);
  });

  testWidgets('选「应用逆向」后进入应用列表,选中即建带应用信息的项目', (tester) async {
    mockAppsChannel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-apps-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.projectKindReverse).first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 已进入应用列表。
    expect(find.byType(InstalledAppsPage), findsOneWidget);
    await tester.tap(find.text('栗子漫画'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    final projects = await db.projectDao.list();
    expect(projects, hasLength(1), reason: '应建出一个逆向项目');
    final project = projects.first;
    expect(project.kind, ProjectKind.reverse);
    expect(project.name, '栗子漫画', reason: '项目名取应用名');
    expect(project.appPackage, 'com.hbsclj.uth');
    expect(project.appVersionName, '1.1.7');
    expect(project.appVersionCode, 19);
    expect(project.appApkPath, '/data/app/~~hash/com.hbsclj.uth-1/base.apk',
        reason: '文件面板要按这个路径读 APK 内的文件');
    expect(project.appIcon, isNotNull, reason: '图标应随项目存下');
    expect(project.appIcon!.isNotEmpty, isTrue);

    // 项目下有一条初始会话。
    final sessions = await db.sessionDao.list();
    expect(sessions, hasLength(1));
    expect(sessions.first.projectId, project.id);
  });
}