import 'dart:io';

import 'package:codecraft/data/codespaces.dart';
import 'package:codecraft/data/credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('混淆编解码', () {
    test('往返一致', () {
      const plain = 'https://user:token@github.com\n';
      final encoded = obfuscate(plain);
      expect(encoded, isNot(plain));
      expect(deobfuscate(encoded), plain);
    });

    test('非本格式(旧版明文)返回 null,交给调用方按明文处理', () {
      expect(deobfuscate('https://user:token@github.com'), isNull);
      expect(deobfuscate('   '), isNull);
    });
  });

  group('令牌取自 Git 凭据', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('cs-cred'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('优先 github.com 条目', () async {
      final store = CredentialStore(File('${dir.path}/git-credentials'));
      await store.save(const GitCredential(host: 'github.com', username: '', token: 'ghp_gh'));
      await store.save(const GitCredential(host: '*', username: '', token: 'ghp_any'));
      expect(await codespacesTokenFrom(store), 'ghp_gh');
    });

    test('没有 github.com 条目时退回「所有主机」条目', () async {
      final store = CredentialStore(File('${dir.path}/git-credentials'));
      await store.save(const GitCredential(host: '*', username: '', token: 'ghp_any'));
      expect(await codespacesTokenFrom(store), 'ghp_any');
    });

    test('没有可用凭据时返回空串(视为未登录)', () async {
      final store = CredentialStore(File('${dir.path}/git-credentials'));
      await store.save(const GitCredential(host: 'gitlab.com', username: '', token: 'glpat'));
      expect(await codespacesTokenFrom(store), '');
    });
  });

  group('仓库与机型解析', () {
    test('GitHubRepo 取全名/默认分支/可见性', () {
      final repo = GitHubRepo.fromJson({
        'full_name': 'octocat/Hello-World',
        'default_branch': 'main',
        'private': true,
        'description': 'demo',
      });
      expect(repo.fullName, 'octocat/Hello-World');
      expect(repo.defaultBranch, 'main');
      expect(repo.private, isTrue);
      expect(repo.description, 'demo');
      expect(repo, const GitHubRepo(fullName: 'octocat/Hello-World'));
    });

    test('CodespaceMachine 取机型名/规格', () {
      final machine = CodespaceMachine.fromJson({
        'name': 'standardLinux',
        'display_name': '4 cores, 16 GB RAM, 64 GB storage',
        'cpus': 4,
        'memory_in_bytes': 17179869184,
        'storage_in_bytes': 68719476736,
      });
      expect(machine.name, 'standardLinux');
      expect(machine.displayName, '4 cores, 16 GB RAM, 64 GB storage');
      expect(machine.cpus, 4);
      expect(machine.memoryInBytes, 17179869184);
      expect(machine.storageInBytes, 68719476736);
    });

    test('机型缺字段不抛异常', () {
      final machine = CodespaceMachine.fromJson({});
      expect(machine.name, '');
      expect(machine.cpus, 0);
    });
  });

  group('新建请求体(字段名须与 GitHub API 对齐)', () {
    test('只带有值的字段,空串与 null 都省略', () {
      const spec = CodespaceCreateSpec(repository: 'octocat/Hello-World');
      expect(spec.toJson(), isEmpty);

      const blank = CodespaceCreateSpec(
        repository: 'octocat/Hello-World',
        ref: '   ',
        machine: '',
        displayName: '',
      );
      expect(blank.toJson(), isEmpty);
    });

    test('分支/机型/显示名按 API 字段名输出并去掉首尾空白', () {
      const spec = CodespaceCreateSpec(
        repository: 'octocat/Hello-World',
        ref: ' feature/x ',
        machine: 'standardLinux',
        displayName: ' 我的环境 ',
      );
      expect(spec.toJson(), {
        'ref': 'feature/x',
        'machine': 'standardLinux',
        'display_name': '我的环境',
      });
    });

    test('位置、devcontainer 与闲置超时按需带上', () {
      const spec = CodespaceCreateSpec(
        repository: 'octocat/Hello-World',
        location: 'WestUs2',
        devcontainerPath: '.devcontainer/devcontainer.json',
        idleTimeoutMinutes: 30,
      );
      expect(spec.toJson(), {
        'location': 'WestUs2',
        'devcontainer_path': '.devcontainer/devcontainer.json',
        'idle_timeout_minutes': 30,
      });
    });
  });

  group('更新请求体', () {
    test('重命名可传空串(用于清除显示名)', () {
      expect(const CodespaceUpdateSpec(displayName: '').toJson(), {'display_name': ''});
      expect(const CodespaceUpdateSpec(displayName: ' hi ').toJson(), {'display_name': 'hi'});
    });

    test('改机型输出 machine,空白值省略', () {
      expect(const CodespaceUpdateSpec(machine: 'premiumLinux').toJson(),
          {'machine': 'premiumLinux'});
      expect(const CodespaceUpdateSpec(machine: '  ').toJson(), isEmpty);
    });
  });

  group('Codespace 解析', () {
    test('完整字段', () {
      final codespace = Codespace.fromJson({
        'name': 'fluffy-parakeet-abc123',
        'display_name': '我的开发环境',
        'state': 'Available',
        'repository': {'full_name': 'octocat/Hello-World'},
        'machine': {'display_name': '4 cores, 16 GB RAM, 64 GB storage'},
        'last_used_at': '2021-10-14T00:53:30-06:00',
        'web_url': 'https://fluffy-parakeet-abc123.github.dev',
        'git_status': {'ref': 'main', 'has_uncommitted_changes': true},
      });
      expect(codespace.name, 'fluffy-parakeet-abc123');
      expect(codespace.title, '我的开发环境');
      expect(codespace.repository, 'octocat/Hello-World');
      expect(codespace.machineDisplay, '4 cores, 16 GB RAM, 64 GB storage');
      expect(codespace.webUrl, 'https://fluffy-parakeet-abc123.github.dev');
      expect(codespace.gitRef, 'main');
      expect(codespace.hasUncommittedChanges, isTrue);
      expect(codespace.lastUsedAt, isNotNull);
      expect(codespace.isAvailable, isTrue);
      expect(codespace.isStopped, isFalse);
    });

    test('缺字段不抛异常,展示名回退到 name', () {
      final codespace = Codespace.fromJson({'name': 'plain-name'});
      expect(codespace.title, 'plain-name');
      expect(codespace.repository, '');
      expect(codespace.machineDisplay, '');
      expect(codespace.webUrl, '');
      expect(codespace.lastUsedAt, isNull);
      expect(codespace.hasUncommittedChanges, isFalse);
      expect(codespace.isAvailable, isFalse);
      expect(codespace.isStopped, isFalse);
    });

    test('停机状态覆盖 Stopped 与 Shutdown 两种写法', () {
      expect(Codespace.fromJson({'state': 'Stopped'}).isStopped, isTrue);
      expect(Codespace.fromJson({'state': 'Shutdown'}).isStopped, isTrue);
      expect(Codespace.fromJson({'state': 'Starting'}).isStarting, isTrue);
      expect(Codespace.fromJson({'state': 'Failed'}).isStopped, isFalse);
    });

    test('时间字段非法时不报错,置空', () {
      expect(Codespace.fromJson({'last_used_at': 'not-a-date'}).lastUsedAt, isNull);
      expect(Codespace.fromJson({'last_used_at': ''}).lastUsedAt, isNull);
    });
  });
}