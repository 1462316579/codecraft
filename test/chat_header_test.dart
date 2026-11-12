import 'dart:ffi' as ffi;

import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 聊天详情页的顶栏左侧按钮。
///
/// 它必须是「打开侧边栏」,而不是「返回」——返回由系统返回手势/返回键负责,
/// 顶栏左侧留给侧栏入口(与首页一致)。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;

  setUp(() async {
    // 跳过首次权限引导:本文件不验证它,弹窗会遮挡其它点击。
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    db = await AppDatabase.open(inMemory: true);
  });

  tearDown(() async => db.close());

  testWidgets('聊天页左上角是侧边栏按钮,不是返回按钮', (tester) async {
    await db.projectDao.upsert(
      const Project(id: 'p-chat-1', name: '聊天页测试', createdAt: 1, updatedAt: 1),
    );
    await db.sessionDao.upsert(
      const ChatSession(
        id: 'chat-s1',
        title: '聊天页测试',
        createdAt: 1,
        updatedAt: 1,
        projectId: 'p-chat-1',
      ),
    );
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-chat-route')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    // 启动停在项目列表,点进项目才到聊天页。
    await tester.tap(find.text('聊天页测试').first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 顶栏左侧的侧边栏按钮(窄屏下侧栏本身在抽屉里,未展开时不在树中)。
    final sidebarButton = find.byIcon(Icons.menu);
    expect(sidebarButton, findsWidgets, reason: '聊天页顶栏左侧应是侧边栏入口');
    final l10n = AppLocalizations.of(tester.element(sidebarButton.first));

    // 左上角是「打开侧边栏」。
    expect(
      find.byTooltip(l10n.openSidebar),
      findsWidgets,
      reason: '聊天页顶栏左侧应是侧边栏入口',
    );
    // 且不应出现返回箭头(返回交给系统手势/返回键)。
    expect(
      find.byIcon(Icons.arrow_back),
      findsNothing,
      reason: '顶栏左侧不应是返回按钮',
    );
  });
}
