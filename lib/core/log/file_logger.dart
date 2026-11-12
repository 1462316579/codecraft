import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 日志等级,由低到高;[LogLevel.none] 用作阈值时关闭一切输出。
enum LogLevel {
  verbose('VERBOSE'),
  debug('DEBUG'),
  info('INFO'),
  warn('WARN'),
  error('ERROR'),
  none('NONE');

  const LogLevel(this.label);

  final String label;

  /// 从行首等级串解析(供日志查看与等级设置复用)。
  static LogLevel? parse(String raw) {
    final upper = raw.trim().toUpperCase();
    for (final level in LogLevel.values) {
      if (level.label == upper) return level;
    }
    return null;
  }

  static LogLevel fromName(String? name) {
    for (final level in LogLevel.values) {
      if (level.name == name) return level;
    }
    return LogLevel.info;
  }
}

/// 一条日志(查看页按行解析后的结构)。
///
/// [level] 为 null 表示非标准日志行(堆栈续行、文件超限重置标记等),
/// 与上游一致:续行不并入上一条,作为独立灰色行展示。
class LogEntry {
  const LogEntry({
    required this.level,
    required this.timestamp,
    required this.tag,
    required this.message,
    required this.raw,
  });

  final LogLevel? level;
  final String timestamp;
  final String? tag;
  final String message;

  /// 原始行(搜索、复制与无法解析时的兜底展示)。
  final String raw;

  /// 与 [FileLogger] 落盘格式匹配:`yyyy-MM-dd HH:mm:ss.SSS LEVEL [TAG] message`。
  static final RegExp _linePattern = RegExp(
      r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) (VERBOSE|DEBUG|INFO|WARN|ERROR)(?: \[([^\]]*)\])? (.*)$');

  static List<LogEntry> parseLines(String content) {
    return [
      for (final line in const LineSplitter().convert(content)) _parseLine(line),
    ];
  }

  static LogEntry _parseLine(String line) {
    final match = _linePattern.firstMatch(line);
    if (match == null) {
      return LogEntry(level: null, timestamp: '', tag: null, message: line, raw: line);
    }
    final tag = match.group(3);
    return LogEntry(
      level: LogLevel.parse(match.group(2) ?? ''),
      timestamp: match.group(1) ?? '',
      tag: (tag == null || tag.isEmpty) ? null : tag,
      message: match.group(4) ?? '',
      raw: line,
    );
  }
}

/// 把日志落盘到应用私有目录,方便在没有 adb 的情况下排查问题(对齐上游 `FileLogger`)。
///
/// - 目录:外部私有目录 `<externalFilesDir>/logs`(不可用时回退 `<filesDir>/logs`),
///   按天分文件 `log-yyyy-MM-dd.txt`;
/// - 等级阈值 [minLevel] 之下的日志(含 debugPrint 镜像与落盘)一律跳过;
/// - 写入串行化到单条后台队列,普通日志合并落盘(500ms),ERROR 立即落盘;
/// - 启动时清理 7 天前与超过 5MB 的旧文件。
class FileLogger {
  FileLogger({
    required this.dir,
    LogLevel? minLevel,
    this.maxAgeDays = defaultMaxAgeDays,
    this.maxFileBytes = defaultMaxFileBytes,
  }) : minLevel = minLevel ?? (kDebugMode ? LogLevel.verbose : LogLevel.info);

  /// 日志目录。
  final Directory dir;

  static const int defaultMaxAgeDays = 7;
  static const int defaultMaxFileBytes = 5 * 1024 * 1024;
  static const Duration flushDelay = Duration(milliseconds: 500);

  /// 旧文件保留天数与单文件上限(测试可注入小值)。
  final int maxAgeDays;
  final int maxFileBytes;

  LogLevel minLevel;

  IOSink? _sink;
  String? _sinkDate;
  Timer? _flushTimer;
  final _pending = StringBuffer();
  Future<void> _queue = Future<void>.value();

  bool _shouldLog(LogLevel level) => level.index >= minLevel.index;

  String _fileName(DateTime now) =>
      'log-${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.txt';

  static String _timestamp(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.'
      '${time.millisecond.toString().padLeft(3, '0')}';

  void v(String tag, String message) => _log(LogLevel.verbose, tag, message);
  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message, [Object? error]) => _log(LogLevel.warn, tag, message, error);
  void e(String tag, String message, [Object? error]) =>
      _log(LogLevel.error, tag, message, error);

  void _log(LogLevel level, String tag, String message, [Object? error]) {
    if (!_shouldLog(level)) return;
    final buffer = StringBuffer('${_timestamp(DateTime.now())} ${level.label} [$tag] $message');
    if (error != null) {
      buffer.write('\n$error');
      // 传进来的是异常本体时补一条当前位置的堆栈;传的已是 StackTrace 就不再叠加。
      if (error is! StackTrace) buffer.write('\n${StackTrace.current}');
    }
    final line = buffer.toString();
    // 镜像到 debugPrint,保持开发期观感一致(release 下 debugPrint 会丢弃)。
    debugPrint(line);
    _queue = _queue.then((_) => _write(line, level == LogLevel.error));
  }

  Future<void> _write(String line, bool immediate) async {
    try {
      final now = DateTime.now();
      final name = _fileName(now);
      if (_sink == null || _sinkDate != name) {
        await _sink?.flush();
        await _sink?.close();
        await dir.create(recursive: true);
        _sink = File('${dir.path}/$name').openWrite(mode: FileMode.append);
        _sinkDate = name;
        _pruneOldFiles(now);
      }
      _pending.write(line);
      _pending.write('\n');
      if (immediate) {
        await _flushNow();
      } else {
        _scheduleFlush();
      }
    } catch (_) {
      // 落盘失败不影响业务:日志只是辅助手段。
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, () {
      _queue = _queue.then((_) => _flushNow());
    });
  }

  Future<void> _flushNow() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pending.isEmpty) return;
    final text = _pending.toString();
    _pending.clear();
    try {
      _sink?.write(text);
      await _sink?.flush();
    } catch (_) {}
  }

  /// 清理过期与超限文件:按天文件保留 [maxAgeDays],超 [maxFileBytes] 的截断到上限之内。
  void _pruneOldFiles(DateTime now) {
    try {
      if (!dir.existsSync()) return;
      final cutoff = now.subtract(Duration(days: maxAgeDays));
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith('log-') || !name.endsWith('.txt')) continue;
        final dateText = name.substring(4, name.length - 4);
        final date = DateTime.tryParse(dateText);
        if (date == null) continue;
        if (date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) {
          entity.deleteSync();
          continue;
        }
        if (entity.lengthSync() > maxFileBytes) {
          // 超限文件保留尾部(新日志更有用),再继续追加。
          final bytes = entity.readAsBytesSync();
          entity.writeAsBytesSync(bytes.sublist(bytes.length - maxFileBytes ~/ 2));
        }
      }
    } catch (_) {}
  }

  /// 崩溃日志:同步追加到 `crash-yyyy-MM-dd.txt`。
  ///
  /// 崩溃时常规的异步队列来不及落盘(进程随时可能被杀),也[不能]与队列共用同一句柄
  /// (同步追加会与缓冲中的写入交错、把行截断),所以单独开一个文件、同步写。
  /// 该文件不在按天清理的 `log-*` 范围内,会一直留到用户手动清空日志。
  void crash(String tag, Object error, StackTrace? stack, {String? context}) {
    final now = DateTime.now();
    final line = '${_timestamp(now)} CRASH $tag: $error\n'
        '${stack ?? StackTrace.current}\n'
        '${context == null ? '' : '$context\n'}';
    debugPrint(line);
    try {
      dir.createSync(recursive: true);
      final name = _fileName(now).replaceFirst('log-', 'crash-');
      File('${dir.path}/$name').writeAsStringSync(line, mode: FileMode.append);
    } catch (_) {
      // 崩溃日志也写不进去时只能放弃:绝不能因为记录失败再抛异常。
    }
  }

  /// 关闭当前文件句柄(应用退出或测试收尾用)。
  ///
  /// 必须先 await 排队中的写入:日志是「先入队再写」,直接 flush 会漏掉还没执行的那些。
  Future<void> close() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _queue;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flushNow();
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}

/// 全局文件日志入口;未初始化时为空操作(不改变原有行为)。
///
/// 用静态门面而不是 provider:日志调用点遍布各层(引擎、API、安装器),
/// 逐个透传 provider 不现实;上游同样是全局 object。
class AppLog {
  AppLog._();

  static FileLogger? _logger;

  static void init(FileLogger logger) => _logger = logger;

  static FileLogger? get instance => _logger;

  static void v(String tag, String message) => _logger?.v(tag, message);
  static void d(String tag, String message) => _logger?.d(tag, message);
  static void i(String tag, String message) => _logger?.i(tag, message);
  static void w(String tag, String message, [Object? error]) =>
      _logger?.w(tag, message, error);
  static void e(String tag, String message, [Object? error]) =>
      _logger?.e(tag, message, error);

  /// 记录崩溃(同步落盘,不经异步队列)。未初始化时退化为 debugPrint。
  ///
  /// [context] 放框架给的信息收集结果(widget 树/元素位置):
  /// 这类断言的堆栈全是框架内部帧,只有上下文能定位到是哪个 widget 出的问题。
  static void crash(String tag, Object error, StackTrace? stack, {String? context}) {
    final logger = _logger;
    if (logger != null) {
      logger.crash(tag, error, stack, context: context);
      return;
    }
    debugPrint('CRASH $tag: $error\n${stack ?? StackTrace.current}'
        '${context == null ? '' : '\n$context'}');
  }

  /// 用户改等级后即时生效(持久化由设置层负责)。
  static void setMinLevel(LogLevel level) {
    final logger = _logger;
    if (logger != null) logger.minLevel = level;
  }

  static LogLevel get minLevel => _logger?.minLevel ?? LogLevel.info;

  @visibleForTesting
  static void reset() => _logger = null;
}
