import 'dart:ffi' as ffi;

import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/installed_apps.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/home/installed_apps_page.dart';
import 'package:codecraft/features/settings/software_permissions_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 「软件权限」页与首次启动引导。
///
/// 授权一律走系统:运行时权限用原生弹窗,特殊权限跳系统页面。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  const runtimeChannel = MethodChannel('com.codecraft.flutter/permissions');
  const storageChannel = MethodChannel('com.codecraft.flutter/external_storage');
  const softwareChannel = MethodChannel('com.codecraft.flutter/software_permissions');
  const appsChannel = MethodChannel('com.codecraft.flutter/installed_apps');

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetPermissionsGateGuardForTest();
    InstalledAppsService.resetCache();
    db = await AppDatabase.open(inMemory: true);
  });

  tearDown(() async {
    await db.close();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(runtimeChannel, null);
    messenger.setMockMethodCallHandler(storageChannel, null);
    messenger.setMockMethodCallHandler(softwareChannel, null);
    messenger.setMockMethodCallHandler(appsChannel, null);
  });

  /// 原生侧通道。`calls` 记录实际调用了哪些方法。
  void mockChannels({
    bool pendingRuntime = true,
    bool allFiles = false,
    bool battery = false,
    bool shizuku = false,
    bool appList = true,
    List<String>? calls,
  }) {
    var hasPending = pendingRuntime;
    var hasAllFiles = allFiles;
    var ignoringBattery = battery;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(runtimeChannel, (call) async {
      calls?.add(call.method);
      switch (call.method) {
        case 'hasPending':
          return hasPending;
        case 'requestStartup':
          hasPending = false;
          return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(storageChannel, (call) async {
      calls?.add(call.method);
      switch (call.method) {
        case 'hasAllFilesAccess':
          return hasAllFiles;
        case 'requestAllFilesAccess':
          hasAllFiles = true;
          return true;
        case 'primaryRoot':
          return '/storage/emulated/0';
      }
      return null;
    });
    messenger.setMockMethodCallHandler(appsChannel, (call) async {
      calls?.add('apps.${call.method}');
      if (call.method == 'listApps') {
        return appList
            ? [
                {
                  'packageName': 'com.hbsclj.uth',
                  'label': '栗子漫画',
                  'versionName': '1.1.7',
                  'versionCode': 19,
                  'isSystem': false,
                },
              ]
            : const <Object?>[];
      }
      return null;
    });
    messenger.setMockMethodCallHandler(softwareChannel, (call) async {
      calls?.add(call.method);
      switch (call.method) {
        case 'status':
          return {'battery': ignoringBattery, 'shizuku': shizuku};
        case 'requestIgnoreBattery':
          ignoringBattery = true;
          return true;
        case 'openAutoStart':
        case 'openShizuku':
          return true;
      }
      return null;
    });
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SoftwarePermissionsPage(),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  testWidgets('页面列出四项系统权限,未授权时显示未允许/未安装', (tester) async {
    mockChannels();
    await pumpPage(tester);

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(l10n.softwarePermissionsTitle), findsOneWidget);
    expect(find.text(l10n.systemPermissionsGroup), findsOneWidget);
    expect(find.text(l10n.permissionStorageTitle), findsOneWidget);
    expect(find.text(l10n.permissionAppsTitle), findsOneWidget);
    expect(find.text(l10n.permissionBatteryTitle), findsOneWidget);
    expect(find.text(l10n.permissionAutoStartTitle), findsOneWidget);
    expect(find.text(l10n.permissionShizukuTitle), findsOneWidget);

    expect(find.text(l10n.permissionNotAllowed), findsNWidgets(2), reason: '存储与电池各一处(应用列表已允许)');
    expect(find.text(l10n.permissionAllowed), findsOneWidget, reason: '应用列表已允许');
    expect(find.text(l10n.permissionNotInstalled), findsOneWidget, reason: 'Shizuku 未安装');
  });

  testWidgets('已授权项显示已允许', (tester) async {
    mockChannels(allFiles: true, battery: true, shizuku: true);
    await pumpPage(tester);

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(l10n.permissionAllowed), findsNWidgets(3),
        reason: '存储 / 应用列表 / 电池三项均已允许');
    expect(find.text(l10n.permissionInstalled), findsOneWidget);
  });

  testWidgets('点存储:先弹系统原生授权框,再跳全文件访问设置页', (tester) async {
    final calls = <String>[];
    mockChannels(calls: calls);
    await pumpPage(tester);

    await tester.tap(find.text(
      AppLocalizations.of(tester.element(find.byType(Scaffold))).permissionStorageTitle,
    ));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(calls, contains('requestStartup'), reason: '先弹系统授权框(原生弹窗)');
    expect(calls, contains('requestAllFilesAccess'), reason: '再跳系统设置页申请全文件访问');
  });

  testWidgets('点电池优化:走系统确认框;点 Shizuku / 自启动跳对应页面', (tester) async {
    final calls = <String>[];
    mockChannels(calls: calls);
    await pumpPage(tester);

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    await tester.tap(find.text(l10n.permissionBatteryTitle));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(calls, contains('requestIgnoreBattery'));

    await tester.tap(find.text(l10n.permissionAutoStartTitle));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(calls, contains('openAutoStart'));

    await tester.ensureVisible(find.text(l10n.permissionShizukuTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.permissionShizukuTitle), warnIfMissed: false);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(calls, contains('openShizuku'));
  });

  testWidgets('首次启动:只弹系统原生授权框,不跳转任何页面', (tester) async {
    final calls = <String>[];
    mockChannels(calls: calls);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-perm-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(calls, contains('requestStartup'), reason: '应由系统弹原生授权框');
    expect(calls, contains('apps.listApps'),
        reason: '应用列表授权也在启动时触发,别拖到点「应用逆向」时闪一下');
    expect(find.byType(SoftwarePermissionsPage), findsNothing,
        reason: '授权完就留在原处,不该自动进「软件权限」页');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PermissionsGate.onboardedKey), isTrue);
  });

  testWidgets('点「应用逆向」不弹授权,直接进选应用页', (tester) async {
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    final calls = <String>[];
    mockChannels(calls: calls);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-perm-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    calls.clear();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.projectKindReverse).first);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(calls.where((c) => c == 'requestStartup'), isEmpty,
        reason: '进选应用页不该弹系统授权框');
    expect(calls.where((c) => c == 'requestAllFilesAccess'), isEmpty);
    expect(find.byType(InstalledAppsPage), findsOneWidget, reason: '应直接进入选应用页');
  });

  testWidgets('已引导过:启动不再申请', (tester) async {
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    final calls = <String>[];
    mockChannels(calls: calls);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-perm-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(calls, isNot(contains('requestStartup')), reason: '只引导一次');
  });
}