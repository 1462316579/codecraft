import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/tools/workspace.dart';

/// 未指定主机的「通用令牌」占位主机名:推送/拉取时对任意远端生效(精确主机条目优先)。
const String defaultCredentialHost = '*';

/// 凭据里没记用户名时,按远端主机推导 userpass 的用户名部分:
/// GitHub 用 x-access-token,其余(GitLab / Gitee / 自建)用 oauth2。
String resolveGitUsername(String host, String stored) {
  if (stored.isNotEmpty) return stored;
  return host.toLowerCase() == 'github.com' ? 'x-access-token' : 'oauth2';
}

/// 一条 Git 远程仓库凭据(每主机一条,[id] 即 host 小写;对齐上游 GitCredential)。
class GitCredential {
  const GitCredential({
    required this.host,
    required this.username,
    required this.token,
  });

  final String host;
  final String username;
  final String token;

  String get id => host.toLowerCase();
}

/// 从仓库 URL / 远端地址里取出主机名(小写);解析不出返回空串。
/// 支持 `https://host/path`、`git@host:path` 与裸 `host/path` 写法。
String credentialHostOf(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  final scp = RegExp(r'^[^/@]+@([^:/]+):').firstMatch(trimmed);
  if (scp != null) return scp.group(1)!.toLowerCase();
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.host.isNotEmpty) return parsed.host.toLowerCase();
  final bare = trimmed.replaceFirst(RegExp(r'^[a-zA-Z]+://'), '');
  return bare.split(RegExp(r'[/:]')).first.toLowerCase();
}

/// base64 后整体反转(与上游一致:属混淆而非加密,避免文件被随手回显)。
String obfuscate(String plain) => base64Encode(utf8.encode(plain)).split('').reversed.join();

/// 解码 [obfuscate] 的产物;不是该格式(如旧版明文)时返回 null,由调用方按明文处理。
String? deobfuscate(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return null;
  try {
    final decoded = utf8.decode(base64Decode(raw.split('').reversed.join()));
    return obfuscate(decoded) == raw ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// 凭据文件存储(对齐上游 FileCredentialRepository):真源是
/// `<应用配置目录>/git-credentials`,内容为 git-credentials 格式的「base64 后整体反转」编码串。
///
/// 采用同一格式的好处:将来接入容器 git 时可直接用 `credential.helper=store` 复用这份文件。
class CredentialStore {
  CredentialStore(this._file);

  final File _file;

  Future<List<GitCredential>> all() async {
    try {
      if (!await _file.exists()) return const [];
      final raw = await _file.readAsString();
      final decoded = deobfuscate(raw) ?? raw;
      return _parse(decoded);
    } catch (_) {
      return const [];
    }
  }

  /// 精确匹配主机;没有时退回「通用令牌」([defaultCredentialHost])。
  Future<GitCredential?> findForHost(String host) async {
    final target = host.toLowerCase();
    GitCredential? fallback;
    for (final credential in await all()) {
      if (credential.id == target) return credential;
      if (credential.id == defaultCredentialHost) fallback = credential;
    }
    return fallback;
  }

  Future<void> save(GitCredential credential) async {
    final list = [...await all()];
    list.removeWhere((entry) => entry.id == credential.id);
    list.add(credential);
    await _write(list);
  }

  Future<void> delete(String id) async {
    final list = [...await all()]..removeWhere((entry) => entry.id == id.toLowerCase());
    await _write(list);
  }

  List<GitCredential> _parse(String content) {
    final credentials = <GitCredential>[];
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final at = line.lastIndexOf('@');
      if (at < 0) continue;
      final host = line.substring(at + 1).trim().toLowerCase();
      final rest = line.substring(0, at).replaceFirst(RegExp(r'^[a-zA-Z]+://'), '');
      final separator = rest.indexOf(':');
      if (separator < 0) continue;
      String decodeComponent(String s) {
        try {
          return Uri.decodeComponent(s);
        } catch (_) {
          return s;
        }
      }
      final username = decodeComponent(rest.substring(0, separator));
      final token = decodeComponent(rest.substring(separator + 1));
      if (host.isEmpty) continue;
      credentials.add(GitCredential(host: host, username: username, token: token));
    }
    return credentials;
  }

  /// 先写临时文件再改名,避免读到半截文件。
  Future<void> _write(List<GitCredential> credentials) async {
    await _file.parent.create(recursive: true);
    final sorted = [...credentials]..sort((a, b) => a.host.compareTo(b.host));
    final buffer = StringBuffer();
    for (final credential in sorted) {
      buffer
        ..write('https://')
        ..write(Uri.encodeComponent(credential.username))
        ..write(':')
        ..write(Uri.encodeComponent(credential.token))
        ..write('@')
        ..write(credential.host)
        ..write('\n');
    }
    final encoded = obfuscate(buffer.toString());
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(encoded);
    try {
      await tmp.rename(_file.path);
    } catch (_) {
      await _file.writeAsString(encoded);
      if (await tmp.exists()) await tmp.delete();
    }
  }

}

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => CredentialStore(File(p.join(ref.watch(configDirProvider), 'git-credentials'))),
);

/// 凭据列表(凭据页用);增删改后由调用方 invalidate。
final credentialsProvider = FutureProvider<List<GitCredential>>(
  (ref) => ref.watch(credentialStoreProvider).all(),
);