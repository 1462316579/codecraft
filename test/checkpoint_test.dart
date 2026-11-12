import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/checkpoint_manager.dart';
import 'package:codecraft/agent/file_version_registry.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/checkpoint_dao.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// 检查点与回滚。
///
/// 最关键的一条:**本会话自己改过的文件必须能回滚**。判据若错用「快照时的指纹」,
/// 本会话的正常改动会被误判成外部改动,回滚永远拒绝执行——功能等于废掉。
void main() {
  late AppDatabase db;
  late Directory root;
  late Directory workspace;
  late CheckpointManager manager;

  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    db = await AppDatabase.open(inMemory: true);
    root = Directory.systemTemp.createTempSync('cp-root');
    workspace = Directory.systemTemp.createTempSync('cp-ws');
    manager = CheckpointManager(
      database: db,
      checkpointRoot: root,
      files: () async => LocalWorkspaceFiles(root: workspace.path),
      workspaceRoot: () async => workspace.path,
    );
  });

  tearDown(() async {
    await db.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  String filePath(String name) => p.join(workspace.path, name);
  File file(String name) => File(filePath(name));

  /// 该会话最新的检查点 id。
  Future<String> latest() async {
    final all = await db.checkpointDao.listForSession('s1');
    return all.last.id;
  }

  Future<void> startCheckpoint(String prompt) async {
    await manager.createCheckpoint(
      sessionId: 's1',
      userMessageId: 'm-${DateTime.now().microsecondsSinceEpoch}',
      prompt: prompt,
    );
  }

  /// 模拟工具写文件:先拍快照,再写入,并记下本会话的版本。
  Future<void> writeAsAgent(String name, String content) async {
    final path = filePath(name);
    await manager.beforeFileModified('s1', path);
    file(name).writeAsStringSync(content);
    manager.versions.record('s1', p.basename(path), FileVersionRegistry.fingerprintOf(content)!);
  }

  test('MODIFY:回滚把文件恢复成快照内容', () async {
    file('a.txt').writeAsStringSync('原始内容');
    await startCheckpoint('改一下 a.txt');

    await writeAsAgent('a.txt', '被改过的内容');
    expect(file('a.txt').readAsStringSync(), '被改过的内容');

    final result = await manager.restoreCodeToCheckpoint('s1', (await latest()));
    expect(result.restored, 1);
    expect(result.skipped, isEmpty);
    expect(file('a.txt').readAsStringSync(), '原始内容');
  });

  test('本会话自己改过的文件必须能回滚(不能用快照指纹当判据)', () async {
    file('a.txt').writeAsStringSync('v1');
    await startCheckpoint('改两次');

    await writeAsAgent('a.txt', 'v2');
    await writeAsAgent('a.txt', 'v3');

    final result = await manager.restoreCodeToCheckpoint('s1', (await latest()));
    expect(result.skipped, isEmpty, reason: '本会话的改动是用户要撤销的东西,不该跳过');
    expect(result.restored, 1);
    expect(file('a.txt').readAsStringSync(), 'v1');
  });

  test('外部改动:跳过并记入 skipped', () async {
    file('a.txt').writeAsStringSync('v1');
    await startCheckpoint('先改');
    await writeAsAgent('a.txt', 'v2');

    // 模拟别的会话/用户直接写了磁盘:本会话没有记录这个版本。
    file('a.txt').writeAsStringSync('别人写的');

    final result = await manager.restoreCodeToCheckpoint('s1', (await latest()));
    expect(result.restored, 0);
    expect(result.skipped, hasLength(1));
    expect(file('a.txt').readAsStringSync(), '别人写的', reason: '外部改动必须保留');
  });

  test('CREATE:回滚把本会话新建的文件删掉', () async {
    await startCheckpoint('新建一个文件');
    await writeAsAgent('new.txt', '新建内容');
    expect(file('new.txt').existsSync(), isTrue);

    final result = await manager.restoreCodeToCheckpoint('s1', (await latest()));
    expect(result.restored, 1);
    expect(file('new.txt').existsSync(), isFalse);
  });

  test('同一检查点内同一文件只拍一次快照', () async {
    file('a.txt').writeAsStringSync('原始');
    await startCheckpoint('多次改同一个文件');
    final checkpointId = (await latest());

    await manager.beforeFileModified('s1', filePath('a.txt'));
    file('a.txt').writeAsStringSync('第二次');
    await manager.beforeFileModified('s1', filePath('a.txt'));

    final snapshots = await db.checkpointDao.snapshotsFor(checkpointId);
    expect(snapshots, hasLength(1), reason: '应保留最原始的那次快照');

    // 回滚后拿到的是最早的「原始」,不是「第二次」。
    await manager.restoreCodeToCheckpoint('s1', checkpointId);
    expect(file('a.txt').readAsStringSync(), '原始');
  });

  test('回滚目标之后的所有检查点一并倒序还原', () async {
    file('a.txt').writeAsStringSync('v1');
    await startCheckpoint('第一轮');
    final first = await latest();
    await writeAsAgent('a.txt', 'v2');

    await startCheckpoint('第二轮');
    await writeAsAgent('a.txt', 'v3');

    // 回滚到第一轮 → 应回到 v1(跨两个检查点倒序还原)。
    final result = await manager.restoreCodeToCheckpoint('s1', first);
    expect(result.restored, greaterThanOrEqualTo(1));
    expect(file('a.txt').readAsStringSync(), 'v1');
  });

  test('删除会话会清掉检查点记录与快照目录', () async {
    file('a.txt').writeAsStringSync('v1');
    await startCheckpoint('随便');
    await writeAsAgent('a.txt', 'v2');

    final sessionDir = Directory(p.join(root.path, 's1'));
    expect(sessionDir.existsSync(), isTrue);

    await manager.clearSessionCheckpoints('s1');
    expect(await db.checkpointDao.listForSession('s1'), isEmpty);
    expect(sessionDir.existsSync(), isFalse);
  });

  test('没有活动检查点时拍快照是空操作', () async {
    file('a.txt').writeAsStringSync('v1');
    await manager.beforeFileModified('s1', filePath('a.txt'));
    expect(await db.checkpointDao.listForSession('s1'), isEmpty);
  });

  test('会话之间互不干扰:活动检查点按会话隔离', () async {
    await manager.createCheckpoint(sessionId: 's1', userMessageId: 'm1', prompt: 'a');
    await manager.createCheckpoint(sessionId: 's2', userMessageId: 'm2', prompt: 'b');

    file('a.txt').writeAsStringSync('x');
    await manager.beforeFileModified('s2', filePath('a.txt'));

    final s1 = await db.checkpointDao.listForSession('s1');
    final s2 = await db.checkpointDao.listForSession('s2');
    expect(await db.checkpointDao.snapshotsFor(s1.single.id), isEmpty);
    expect(await db.checkpointDao.snapshotsFor(s2.single.id), hasLength(1));
  });
}


