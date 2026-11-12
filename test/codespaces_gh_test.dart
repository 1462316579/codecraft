import 'dart:convert';
import 'dart:io';

import 'package:codecraft/data/codespaces_gh.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/credentials.dart';
import 'package:codecraft/data/git/git_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录命令并回放预设输出的假引擎(gh 跑在本地容器里,这一层就是容器)。
class _RecordingEngine extends CommandEngine {
  _RecordingEngine({this.output = '[]', this.exitCode = 0});

  String output;
  int exitCode;
  final List<String> commands = [];

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    commands.add(command);
    return CommandResult(output: output, exitCode: exitCode);
  }

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  @override
  Future<TerminalProcess> openTerminal({String? command, int cols = 80, int rows = 24, String? workdir}) =>
      throw UnimplementedError();

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      const Stream.empty();
}

void main() {
  group('端口解析', () {
    test('取 gh 的 camelCase 字段', () {
      final port = CodespacePort.fromJson({
        'sourcePort': 3000,
        'label': 'web',
        'visibility': 'public',
        'browseUrl': 'https://cs-abc-3000.app.github.dev',
      });
      expect(port.sourcePort, 3000);
      expect(port.label, 'web');
      expect(port.visibility, 'public');
      expect(port.browseUrl, 'https://cs-abc-3000.app.github.dev');
    });

    test('缺字段不抛异常', () {
      final port = CodespacePort.fromJson({});
      expect(port.sourcePort, 0);
      expect(port.label, '');
      expect(port.visibility, '');
      expect(port.browseUrl, '');
    });
  });

  group('命令构造', () {
    test('列表命令带 --json 且对 codespace 名做 shell 转义', () {
      expect(
        CodespacesGhService.listPortsCommand('cs-1'),
        "'/root/.codecraft/gh-codespaces.sh' codespace ports -c 'cs-1' "
        '--json sourcePort,label,visibility,browseUrl',
      );
    });

    test('名称含单引号时不会破坏 shell 命令', () {
      final command = CodespacesGhService.listPortsCommand("a'b");
      expect(command, contains(r"'a'\''b'"));
      // 整条命令交给真实 sh 解析后应无语法错误(用 echo 验证引号闭合)。
      expect(Process.runSync('sh', ['-n', '-c', command]).exitCode, 0);
    });

    test('可见性命令用 <port>:<visibility> 形式', () {
      expect(
        CodespacesGhService.portVisibilityCommand('cs-1', 3000, PortVisibility.public),
        "'/root/.codecraft/gh-codespaces.sh' codespace ports visibility '3000:public' -c 'cs-1'",
      );
      expect(
        CodespacesGhService.portVisibilityCommand('cs-1', 22, PortVisibility.private),
        contains("'22:private'"),
      );
    });
  });

  group('gh 服务', () {
    test('解析 gh 的 JSON 数组', () async {
      final engine = _RecordingEngine(
        output: jsonEncode([
          {'sourcePort': 3000, 'label': 'web', 'visibility': 'private', 'browseUrl': 'u1'},
          {'sourcePort': 8080, 'label': '', 'visibility': 'org', 'browseUrl': 'u2'},
        ]),
      );
      final ports = await CodespacesGhService(engine: engine).listPorts('cs-1');
      expect(ports.map((p) => p.sourcePort), [3000, 8080]);
      expect(ports.last.visibility, 'org');
    });

    test('非零退出码抛出可读错误(取最后一行)', () async {
      final engine = _RecordingEngine(output: '一些噪声\ngh: Not Found (HTTP 404)', exitCode: 1);
      await expectLater(
        CodespacesGhService(engine: engine).listPorts('cs-1'),
        throwsA(isA<CodespacesGhException>().having(
          (e) => e.message,
          'message',
          contains('Not Found'),
        )),
      );
    });

    test('改可见性发送对应命令并在失败时报错', () async {
      final engine = _RecordingEngine(output: '', exitCode: 0);
      final service = CodespacesGhService(engine: engine);
      await service.setPortVisibility('cs-1', 3000, PortVisibility.public);
      expect(engine.commands.single, contains("'3000:public'"));

      final failing = _RecordingEngine(output: 'boom', exitCode: 1);
      await expectLater(
        CodespacesGhService(engine: failing)
            .setPortVisibility('cs-1', 3000, PortVisibility.org),
        throwsA(isA<CodespacesGhException>()),
      );
    });
  });

  group('重建容器命令', () {
    test('普通重建不带 --full', () {
      expect(
        CodespacesGhService.rebuildCommand('cs-1'),
        "'/root/.codecraft/gh-codespaces.sh' codespace rebuild -c 'cs-1'",
      );
    });

    test('完全重建带 --full', () {
      expect(
        CodespacesGhService.rebuildCommand('cs-1', full: true),
        "'/root/.codecraft/gh-codespaces.sh' codespace rebuild -c 'cs-1' --full",
      );
    });

    test('重建命令经真实 sh 解析无语法错误', () {
      final command = CodespacesGhService.rebuildCommand("a'b", full: true);
      expect(Process.runSync('sh', ['-n', '-c', command]).exitCode, 0);
    });

    test('重建失败时把 gh 的输出末行作为错误抛回', () async {
      final engine = _RecordingEngine(output: 'noise\ncannot rebuild: codespace is not running', exitCode: 1);
      await expectLater(
        CodespacesGhService(engine: engine).rebuild('cs-1'),
        throwsA(isA<CodespacesGhException>().having(
          (e) => e.message,
          'message',
          contains('not running'),
        )),
      );
    });

    test('重建成功不抛异常,且用的是超过默认 60 秒的超时', () async {
      final engine = _RecordingEngine(output: '', exitCode: 0);
      await CodespacesGhService(engine: engine).rebuild('cs-1', full: true);
      expect(engine.commands.single, contains('--full'));
    });
  });

  group('容器内 gh 包装脚本(真实执行)', () {
    late Directory root;
    late Directory bin;

    setUp(() {
      root = Directory.systemTemp.createTempSync('ghcs-root');
      bin = Directory.systemTemp.createTempSync('ghcs-bin');
    });

    tearDown(() {
      root.deleteSync(recursive: true);
      bin.deleteSync(recursive: true);
    });

    /// 假 gh:把收到的 GH_TOKEN 与本行参数打印出来,便于断言。
    File writeFakeGh() {
      final gh = File('${bin.path}/gh')
        ..writeAsStringSync(r'''#!/bin/sh
echo "TOKEN=${GH_TOKEN:-<unset>}"
echo "ARGS=$@"
''');
      Process.runSync('chmod', ['755', gh.path]);
      return gh;
    }

    /// 写一份混淆编码的 git 凭据文件(格式与 App 侧 CredentialStore 一致)。
    void writeCredentials(String lines) => File('${root.path}/git-credentials')
        .writeAsStringSync(obfuscate('$lines\n'));

    ProcessResult runHelper(List<String> args) => Process.runSync(
          'sh',
          ['assets/codecraft/gh-codespaces.sh', ...args],
          environment: {
            'CODECRAFT_DIR': root.path,
            'PATH': '${bin.path}:${Platform.environment['PATH'] ?? ''}',
          },
        );

    test('从 git 凭据解码令牌后经 GH_TOKEN 交给 gh,参数原样透传', () {
      writeFakeGh();
      writeCredentials('https://x-access-token:ghp_secret_token@*');

      final result = runHelper(['codespace', 'ports', '-c', 'cs-1']);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final out = result.stdout.toString();
      expect(out, contains('TOKEN=ghp_secret_token'));
      expect(out, contains('ARGS=codespace ports -c cs-1'));
      // 令牌不落进 argv。
      expect('${result.stdout}${result.stderr}', isNot(contains('gh-codespaces.sh ghp')));
    });

    test('github.com 条目优先于「所有主机」条目', () {
      writeFakeGh();
      writeCredentials(
        'https://x-access-token:ghp_any@*\nhttps://u:ghp_exact@github.com',
      );
      expect(runHelper(['codespace', 'list']).stdout, contains('TOKEN=ghp_exact'));
    });

    test('旧版明文凭据文件也能用(回退解析)', () {
      writeFakeGh();
      File('${root.path}/git-credentials')
          .writeAsStringSync('https://x-access-token:ghp_legacy@github.com');
      expect(runHelper(['codespace', 'list']).stdout, contains('TOKEN=ghp_legacy'));
    });

    test('凭据里只有非 GitHub 主机时明确报错,不静默空跑', () {
      writeFakeGh();
      writeCredentials('https://oauth2:glpat@gitlab.com');
      final result = runHelper(['codespace', 'list']);
      expect(result.exitCode, 3);
      expect(result.stderr.toString(), contains('Git 凭据'));
    });

    test('缺少凭据文件时明确报错,不静默空跑', () {
      writeFakeGh();
      final result = runHelper(['codespace', 'list']);
      expect(result.exitCode, 3);
      expect(result.stderr.toString(), contains('未配置'));
    });

    test('容器里没有 gh 时给出安装引导', () {
      // 确定性构造「有 coreutils 但没有 gh」的 PATH:把脚本需要的可执行文件软链到临时目录。
      for (final tool in ['sh', 'cat', 'awk', 'sed', 'base64', 'tr']) {
        final found = Process.runSync('sh', ['-c', 'command -v $tool']).stdout.toString().trim();
        expect(found, isNotEmpty, reason: '$tool 应当可用');
        Link('${bin.path}/$tool').createSync(found);
      }
      writeCredentials('https://x-access-token:t@github.com');

      final result = Process.runSync(
        'sh',
        ['assets/codecraft/gh-codespaces.sh', 'codespace', 'list'],
        environment: {'CODECRAFT_DIR': root.path, 'PATH': bin.path},
      );
      expect(result.exitCode, 4, reason: result.stderr.toString());
      expect(result.stderr.toString(), contains('codecraft'));
    });

    test('脚本语法合法(sh -n)', () {
      expect(Process.runSync('sh', ['-n', 'assets/codecraft/gh-codespaces.sh']).exitCode, 0);
    });

    test('令牌文件与 GitRunner.quote 的转义约定一致(防范脚本内引号问题)', () {
      expect(GitRunner.quote('/root/.codecraft/gh-codespaces.sh'),
          "'/root/.codecraft/gh-codespaces.sh'");
    });
  });
}