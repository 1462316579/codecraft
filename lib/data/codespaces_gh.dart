import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'container/container_engine_provider.dart';
import 'container/command_engine.dart';
import 'git/git_runner.dart';

/// 一个转发端口(`gh codespace ports --json` 的字段)。
class CodespacePort {
  const CodespacePort({
    required this.sourcePort,
    this.label = '',
    this.visibility = '',
    this.browseUrl = '',
  });

  /// 容器内被转发的端口号。
  final int sourcePort;

  /// 端口标签(进程/服务名,gh 提供)。
  final String label;

  /// `private` / `org` / `public`。
  final String visibility;

  /// 浏览器访问地址(`https://<codespace>-<port>.app.github.dev`)。
  final String browseUrl;

  factory CodespacePort.fromJson(Map<String, dynamic> json) => CodespacePort(
        sourcePort: (json['sourcePort'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        visibility: json['visibility'] as String? ?? '',
        browseUrl: json['browseUrl'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is CodespacePort &&
      other.sourcePort == sourcePort &&
      other.label == label &&
      other.visibility == visibility &&
      other.browseUrl == browseUrl;

  @override
  int get hashCode => Object.hash(sourcePort, label, visibility, browseUrl);
}

/// 端口可见性(gh 接受的取值)。
enum PortVisibility { private, org, public }

/// 走 GitHub CLI 的 Codespaces 操作。
///
/// 端口转发与重建容器**都没有 REST 端点**,只能通过 gh;gh 跑在本地容器里
/// (不是 codespace 内部,否则会递归),命令经 [ghHelper] 包装,
/// 由它在容器内解码令牌并注入 GH_TOKEN(令牌不进 argv)。
class CodespacesGhService {
  CodespacesGhService({required this.engine, this.ghHelper = defaultGhHelper});

  /// 本地容器引擎(gh 装在容器里)。
  final CommandEngine engine;

  /// 容器内包装 gh 的脚本路径。
  final String ghHelper;

  static const String defaultGhHelper = '/root/.codecraft/gh-codecraft.sh';

  /// `gh codespace ports --json` 的字段名(与手册的 JSON Fields 一致)。
  static const String jsonFields = 'sourcePort,label,visibility,browseUrl';

  static String _helperPrefix(String helper) => GitRunner.quote(helper);

  /// 端口列表命令(不含 shell 展开,便于单测断言)。
  static String listPortsCommand(String codespace, {String helper = defaultGhHelper}) =>
      '${_helperPrefix(helper)} codespace ports -c ${GitRunner.quote(codespace)} '
      '--json $jsonFields';

  /// 改端口可见性命令:`<port>:<visibility>`。
  static String portVisibilityCommand(
    String codespace,
    int port,
    PortVisibility visibility, {
    String helper = defaultGhHelper,
  }) =>
      '${_helperPrefix(helper)} codespace ports visibility '
      '${GitRunner.quote('$port:${visibility.name}')} -c ${GitRunner.quote(codespace)}';

  /// 重建命令。[full] 额外清除缓存的 Docker 镜像。
  static String rebuildCommand(
    String codespace, {
    bool full = false,
    String helper = defaultGhHelper,
  }) =>
      '${_helperPrefix(helper)} codespace rebuild -c ${GitRunner.quote(codespace)}'
      '${full ? ' --full' : ''}';

  Future<CommandResult> _run(String command, {Duration? timeout}) => engine.runCommandSync(
        command,
        timeout: timeout ?? const Duration(seconds: 60),
      );

  Future<List<CodespacePort>> listPorts(String codespace) async {
    final result = await _run(listPortsCommand(codespace, helper: ghHelper));
    if (result.exitCode != 0) {
      throw CodespacesGhException(_failureMessage(result.output));
    }
    final decoded = jsonDecode(result.output);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) CodespacePort.fromJson(item),
    ];
  }

  Future<void> setPortVisibility(String codespace, int port, PortVisibility visibility) async {
    final result = await _run(portVisibilityCommand(codespace, port, visibility, helper: ghHelper));
    if (result.exitCode != 0) {
      throw CodespacesGhException(_failureMessage(result.output));
    }
  }

  /// 重建容器:重建后代码与未提交改动保留;[full] 会额外清掉镜像缓存因而更慢。
  /// 重建耗时较长,给足超时并在失败时把 gh 的输出原样带出。
  Future<void> rebuild(String codespace, {bool full = false}) async {
    final result = await _run(
      rebuildCommand(codespace, full: full, helper: ghHelper),
      timeout: const Duration(minutes: 10),
    );
    if (result.exitCode != 0) {
      throw CodespacesGhException(_failureMessage(result.output));
    }
  }

  /// 失败信息:脚本用 stderr 输出可读文案,这里取最后一行非空内容。
  static String _failureMessage(String output) {
    final lines = output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.isEmpty ? 'gh 调用失败' : lines.last;
  }
}

class CodespacesGhException implements Exception {
  const CodespacesGhException(this.message);

  final String message;

  @override
  String toString() => message;
}

final codespacesGhServiceProvider = FutureProvider<CodespacesGhService>((ref) async {
  return CodespacesGhService(engine: await ref.read(containerEngineProvider.future));
});