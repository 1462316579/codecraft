import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'agent/tools/workspace.dart';
import 'core/log/ai_logger.dart';
import 'core/log/file_logger.dart';
import 'core/log/log_store.dart';
import 'data/db/app_database.dart';
import 'data/settings/app_settings.dart';

/// 把 [FlutterErrorDetails] 里「哪个 widget / 哪个元素出的问题」整理成可落盘文本。
///
/// 框架默认只在控制台 dump 这些信息(真机上取不到),而这类断言的堆栈全是框架内部帧,
/// 没有上下文就无法定位,所以这里主动收集一份写进崩溃日志。
String _describeError(FlutterErrorDetails details) {
  final buffer = StringBuffer();
  final context = details.context;
  if (context != null) buffer.writeln('context: $context');
  final library = details.library;
  if (library != null) buffer.writeln('library: $library');
  final collector = details.informationCollector;
  if (collector != null) {
    for (final node in collector()) {
      buffer.writeln(node.toStringDeep());
    }
  }
  return buffer.toString().trimRight();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局设置状态栏样式:背景设为透明,确保沉浸式效果
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final preferences = await SharedPreferences.getInstance();
  late final AppDatabase database;
  try {
    database = await AppDatabase.open();
  } catch (e) {
    print("DB open failed: $e, falling back to in-memory database");
    database = await AppDatabase.open(inMemory: true);
  }
  final workspace = await openWorkspace();
  final configDir = (await getApplicationDocumentsDirectory()).path;

  // 首次启动：把内置三款技能（写作 / 编程 / 应用逆向）写入全局技能目录，供 AI 按需 loadSkill。
  await _seedBuiltinSkills(configDir);

  // 日志:解析目录后装配,失败不阻塞启动(日志只是辅助手段)。
  try {
    final base = await resolveLogBaseDir();
    final logsDir = Directory(p.join(base.path, LogSource.app.dirName));
    AppLog.init(FileLogger(
      dir: logsDir,
      minLevel: LogLevel.fromName(preferences.getString(logLevelPrefKey)),
    ));
    AiLog.init(AiLogger(dir: Directory(p.join(base.path, LogSource.ai.dirName))));
    AppLog.i('App', '启动完成,日志目录: ${logsDir.path}');

    // 崩溃落盘:真机上没有 adb,框架错误默认只打到 logcat,出问题无从查起。
    // 保持原有处理链不变(仍然打印/红屏),只是多写一份文件。
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLog.crash(
        'FlutterError',
        details.exception,
        details.stack,
        context: _describeError(details),
      );
      previousOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.crash('UncaughtError', error, stack);
      return false;
    };
  } catch (error) {
    // ignore: avoid_print
    print('日志初始化失败:$error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        databaseProvider.overrideWithValue(database),
        workspaceProvider.overrideWithValue(workspace),
        configDirProvider.overrideWithValue(configDir),
      ],
      child: const CodecraftApp(),
    ),
  );
}

/// 首次启动时把内置技能（assets/skills/<name>/SKILL.md）写入全局技能目录，已存在则跳过。
Future<void> _seedBuiltinSkills(String configDir) async {
  const skills = ['writing', 'coding', 'reverse'];
  for (final name in skills) {
    final dir = Directory(p.join(configDir, 'skills', name));
    final file = File(p.join(dir.path, 'SKILL.md'));
    if (await file.exists()) continue;
    try {
      await dir.create(recursive: true);
      final content = await rootBundle.loadString('assets/skills/$name/SKILL.md');
      await file.writeAsString(content);
    } catch (_) {
      // 资产读取或写盘失败不阻塞启动。
    }
  }
}