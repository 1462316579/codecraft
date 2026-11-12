import 'dart:convert';
import 'dart:io';

import 'package:codecraft/data/credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('主机名解析', () {
    test('https / scp / 裸写法都能取出 host', () {
      expect(credentialHostOf('https://github.com/user/repo.git'), 'github.com');
      expect(credentialHostOf('https://gitee.com/a/b'), 'gitee.com');
      expect(credentialHostOf('git@github.com:user/repo.git'), 'github.com');
      expect(credentialHostOf('GitLab.com/group/repo'), 'gitlab.com');
      expect(credentialHostOf('http://127.0.0.1:8080/x.git'), '127.0.0.1');
      expect(credentialHostOf(''), '');
    });
  });

  group('凭据存储', () {
    late Directory dir;
    late CredentialStore store;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cred_store');
      file = File(p.join(dir.path, 'git-credentials'));
      store = CredentialStore(file);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('保存后可读回,且文件不是明文(base64 反转)', () async {
      await store.save(const GitCredential(host: 'github.com', username: 'octocat', token: 'ghp_x'));

      final all = await store.all();
      expect(all.single.host, 'github.com');
      expect(all.single.username, 'octocat');
      expect(all.single.token, 'ghp_x');
      expect(all.single.id, 'github.com');

      final raw = await file.readAsString();
      expect(raw.contains('ghp_x'), isFalse, reason: '落盘内容不应是明文');
      final decoded = utf8.decode(base64Decode(raw.trim().split('').reversed.join()));
      expect(decoded.trim(), 'https://octocat:ghp_x@github.com');
    });

    test('同主机覆盖、按 id 删除、findForHost 命中', () async {
      await store.save(const GitCredential(host: 'github.com', username: 'a', token: 't1'));
      await store.save(const GitCredential(host: 'github.com', username: 'b', token: 't2'));
      await store.save(const GitCredential(host: 'gitlab.com', username: 'c', token: 't3'));

      final all = await store.all();
      expect(all.length, 2);
      expect((await store.findForHost('GitHub.com'))!.username, 'b');

      await store.delete('github.com');
      expect((await store.all()).map((entry) => entry.host), ['gitlab.com']);
    });

    test('旧版明文文件仍可解析', () async {
      await file.writeAsString('https://user:token@example.com\n');
      final all = await store.all();
      expect(all.single.host, 'example.com');
      expect(all.single.token, 'token');
    });

    test('URL 编码与冒号:token 含特殊字符也能往返', () async {
      await store.save(const GitCredential(
        host: 'example.com',
        username: 'user name',
        token: 'a:b/c?d=e',
      ));
      final credential = (await store.all()).single;
      expect(credential.username, 'user name');
      expect(credential.token, 'a:b/c?d=e');
    });
  });
}