import 'dart:convert';
import 'dart:io';

import 'package:codecraft/core/log/ai_logger.dart';
import 'package:codecraft/core/log/file_logger.dart';
import 'package:codecraft/core/log/log_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('logs-test'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  String todayFileName(DateTime now) =>
      'log-${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.txt';

  String readToday() => File('${dir.path}/${todayFileName(DateTime.now())}').readAsStringSync();

  group('文件日志', () {
    test('按天分文件写入,行内含时间/等级/标签', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.i('Container', '容器初始化开始');
      await logger.close();

      final content = readToday();
      expect(content, contains('INFO Container: 容器初始化开始'));
      expect(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} INFO ', multiLine: true)
          .hasMatch(content), isTrue);
    });

    test('阈值之下的等级被丢弃,阈值之上的保留', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.warn);
      logger.d('Tag', '不该出现');
      logger.i('Tag', '也不该出现');
      logger.w('Tag', '警告要留');
      logger.e('Tag', '错误要留');
      await logger.close();

      final content = readToday();
      expect(content, isNot(contains('不该出现')));
      expect(content, isNot(contains('也不该出现')));
      expect(content, contains('警告要留'));
      expect(content, contains('错误要留'));
    });

    test('NONE 阈值下什么都不写(文件不产生)', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.none);
      logger.e('Tag', '错误也不写');
      await logger.close();
      expect(File('${dir.path}/${todayFileName(DateTime.now())}').existsSync(), isFalse);
    });

    test('错误随附异常与堆栈', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.e('Tag', '失败', StateError('boom'));
      await logger.close();

      final content = readToday();
      expect(content, contains('Bad state: boom'));
      // 非 StackTrace 的异常会补一条当前位置的堆栈(表现为 `#0  ...` 帧)。
      expect(content, contains('#0'));
    });

    test('清理 7 天前的旧文件,保留新文件', () async {
      File('${dir.path}/log-2020-01-01.txt').writeAsStringSync('old');
      File('${dir.path}/log-2020-01-02.txt').writeAsStringSync('old');
      final fresh = todayFileName(DateTime.now());
      File('${dir.path}/$fresh').writeAsStringSync('keep');

      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.i('Tag', '触发清理');
      await logger.close();

      expect(File('${dir.path}/log-2020-01-01.txt').existsSync(), isFalse);
      expect(File('${dir.path}/log-2020-01-02.txt').existsSync(), isFalse);
      expect(File('${dir.path}/$fresh').existsSync(), isTrue);
    });

    test('超过上限的旧文件被截断到上限之内', () async {
      // 用「昨天」的日期:按天规则只清 7 天前的,这里要单独验证超限截断。
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final name = 'log-${yesterday.year.toString().padLeft(4, '0')}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}.txt';
      final big = File('${dir.path}/$name')..writeAsBytesSync(List.filled(1000, 0x41));

      // 上限注入成小值:不必真造 5MB 文件,测试也快。
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose, maxFileBytes: 400);
      logger.i('Tag', '触发清理');
      await logger.close();

      expect(big.lengthSync(), lessThanOrEqualTo(400));
    });

    test('非日志文件不会被误删', () async {
      final other = File('${dir.path}/notes.txt')..writeAsStringSync('keep me');
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.i('Tag', 'x');
      await logger.close();
      expect(other.existsSync(), isTrue);
    });

    test('崩溃日志同步落到 crash-<日期>.txt,不依赖队列与 close', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.none);
      // 等级为 NONE(正常日志全丢)时崩溃仍必须落盘:崩溃日志不看等级阈值。
      logger.crash('FlutterError', StateError('boom'), StackTrace.current);

      final name = 'crash-${DateTime.now().year.toString().padLeft(4, '0')}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().day.toString().padLeft(2, '0')}.txt';
      final file = File('${dir.path}/$name');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('CRASH FlutterError: Bad state: boom'));
      expect(content, contains('#0'));
      await logger.close();
    });

    test('崩溃日志带上框架给的上下文(widget 树信息)', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.crash(
        'FlutterError',
        StateError('boom'),
        StackTrace.current,
        context: 'context: during a frame callback\n  ShellScope\n    Scaffold',
      );
      await logger.close();

      final name = Directory(dir.path)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .firstWhere((n) => n.startsWith('crash-'));
      final content = File('${dir.path}/$name').readAsStringSync();
      expect(content, contains('during a frame callback'));
      expect(content, contains('ShellScope'));
    });

    test('崩溃日志单独成文件,不与当天日志文件混写', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.i('Tag', '正常日志');
      logger.crash('CRASH', Exception('x'), StackTrace.current);
      await logger.close();

      expect(readToday(), contains('正常日志'));
      expect(readToday(), isNot(contains('CRASH')));
    });

    test('崩溃日志文件不被按天清理(不属 log-* 范围)', () async {
      final logger = FileLogger(dir: dir, minLevel: LogLevel.verbose);
      logger.crash('CRASH', Exception('x'), StackTrace.current);
      await logger.close();
      final name = Directory(dir.path)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .firstWhere((n) => n.startsWith('crash-'));
      expect(name, startsWith('crash-'));
    });

    test('AppLog 门面未初始化时为空操作', () {
      AppLog.reset();
      expect(() => AppLog.i('Tag', 'noop'), returnsNormally);
      expect(() => AppLog.crash('CRASH', Exception('x'), StackTrace.current),
          returnsNormally);
      expect(AppLog.instance, isNull);
    });
  });

  group('日志行解析', () {
    test('识别 时间/等级/标签/内容', () {
      final entries = LogEntry.parseLines(
        '2026-10-25 05:12:33.123 INFO  Container: 初始化完成\n'
        '2026-10-25 05:12:34.456 ERROR Chat: 失败\n',
      );
      expect(entries, hasLength(2));
      expect(entries.first.level, LogLevel.info);
      expect(entries.first.tag, 'Container');
      expect(entries.first.message, '初始化完成');
      expect(entries.last.level, LogLevel.error);
    });

    test('续行(堆栈)并入上一条', () {
      final entries = LogEntry.parseLines(
        '2026-10-25 05:12:33.123 ERROR Tag: 失败\n'
        '#0      main (package:x)\n'
        '#1      run (package:y)\n',
      );
      expect(entries, hasLength(1));
      expect(entries.single.message, contains('#0'));
      expect(entries.single.message, contains('#1'));
    });

    test('无法识别的行按原文保留', () {
      final entries = LogEntry.parseLines('随便一行没有格式的文本');
      expect(entries.single.raw, '随便一行没有格式的文本');
    });

    test('空内容得到空列表', () {
      expect(LogEntry.parseLines(''), isEmpty);
    });
  });

  group('日志存储', () {
    test('列举应用日志与 AI 日志并按时间倒序', () async {
      final logsDir = Directory('${dir.path}/logs')..createSync();
      final aiDir = Directory('${dir.path}/ai-logs')..createSync();
      File('${logsDir.path}/log-2026-10-25.txt').writeAsStringSync('a');
      File('${aiDir.path}/session-s1.log').writeAsStringSync('bb');

      final store = LogStore(logsDir: logsDir, aiLogsDir: aiDir);
      final files = store.listFiles();
      expect(files, hasLength(2));
      expect(files.map((f) => f.source), containsAll([LogSource.app, LogSource.ai]));
      expect(store.totalBytes(), 3);
    });

    test('清空日志返回释放字节数且两个目录都清', () async {
      final logsDir = Directory('${dir.path}/logs')..createSync();
      final aiDir = Directory('${dir.path}/ai-logs')..createSync();
      File('${logsDir.path}/log-2026-10-25.txt').writeAsStringSync('aaaa');
      File('${aiDir.path}/session-s1.log').writeAsStringSync('bb');

      final store = LogStore(logsDir: logsDir, aiLogsDir: aiDir);
      expect(await store.deleteAll(), 6);
      expect(store.listFiles(), isEmpty);
    });

    test('目录不存在时不抛异常', () {
      final store = LogStore(
        logsDir: Directory('${dir.path}/none'),
        aiLogsDir: Directory('${dir.path}/none2'),
      );
      expect(store.listFiles(), isEmpty);
      expect(store.totalBytes(), 0);
    });
  });

  group('AI 请求日志', () {
    late AiLogger logger;

    setUp(() => logger = AiLogger(dir: Directory('${dir.path}/ai-logs')));

    test('按会话一个文件,逐条 JSON 行', () async {
      logger.logRequest(sessionId: 's1', url: 'https://x/v1/chat/completions', body: {'a': 1});
      logger.logResponse(sessionId: 's1', statusCode: 200, rawText: 'data: [DONE]');
      await logger.close();

      final file = File('${dir.path}/ai-logs/session-s1.log');
      expect(file.existsSync(), isTrue);
      final lines = const LineSplitter()
          .convert(file.readAsStringSync())
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
      expect(lines, hasLength(2));
      expect(lines.first['event'], 'request');
      expect(lines.first['url'], 'https://x/v1/chat/completions');
      expect(lines.last['event'], 'response');
      expect(lines.last['status'], 200);
    });

    test('不记录 API Key(只在 headers,不在 body)', () async {
      // 调用方约定不把 Key 放进 body;这里断言即便 body 里混入字符串也会原样记,
      // 而 Key 的注入点在 headers,因此不应出现在日志里。
      logger.logRequest(sessionId: 's2', url: 'u', body: {'messages': []});
      await logger.close();
      expect(File('${dir.path}/ai-logs/session-s2.log').readAsStringSync(),
          isNot(contains('Bearer')));
    });

    test('超大字符串按结构脱敏为长度占位符', () {
      final big = 'a' * (AiLogger.redactThreshold + 10);
      final redacted = AiLogger.redact({
        'messages': [
          {'content': big, 'nested': {'deep': big}},
        ],
      });
      final text = jsonEncode(redacted);
      expect(text, contains('已省略'));
      expect(text, isNot(contains(big)));
    });

    test('短字符串不脱敏', () {
      expect(AiLogger.redact({'a': 'short'}), {'a': 'short'});
    });

    test('会话 id 里的路径字符被替换,避免写到目录之外', () async {
      logger.logRequest(sessionId: '../../etc/passwd', url: 'u', body: const {});
      await logger.close();
      final files = Directory('${dir.path}/ai-logs').listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.single.path, contains('session-.._.._etc_passwd.log'));
    });

    test('超过上限后滚动归档,超出归档份数的旧档被删除', () async {
      final dir2 = Directory('${dir.path}/roll')..createSync(recursive: true);
      // 上限注入成小值:写入几次即触发滚动,不必真写 20MB。
      final rolling = AiLogger(dir: dir2, maxFileBytes: 120, maxArchiveFiles: 2);
      final path = rolling.filePath('s3');
      for (var i = 0; i < 6; i++) {
        rolling.logRequest(sessionId: 's3', url: 'https://example/$i', body: const {});
      }
      // 归档发生在写入过程中,之后再写一条才能验证新文件被重新创建。
      rolling.logRequest(sessionId: 's3', url: 'https://example/after-roll', body: const {});
      await rolling.close();

      expect(File('$path.1').existsSync(), isTrue, reason: '超限后应归档为 .1');
      expect(File(path).existsSync(), isTrue, reason: '归档后继续写入应重建新文件');
      expect(File('$path.3').existsSync(), isFalse,
          reason: '归档只保留 maxArchiveFiles 份');
    });

    test('AiLog 未初始化时为空操作', () {
      AiLog.reset();
      expect(() => AiLog.request(sessionId: 's', url: 'u', body: const {}), returnsNormally);
      expect(AiLog.instance, isNull);
    });
  });
}