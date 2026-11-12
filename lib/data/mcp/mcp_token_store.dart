import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../agent/tools/workspace.dart';
import 'mcp_auth_models.dart';

/// OAuth 客户端身份与令牌的持久化(对齐上游 McpTokenStore),按授权服务器 issuer 为键。
///
/// 文件内容做 base64 + 整体反转处理,与 `git-credentials` 一致:**属混淆、非加密**,
/// 只为避免明文直读,不构成安全承诺。
class McpTokenStore {
  McpTokenStore(this._file);

  final File _file;
  Map<String, dynamic>? _cache;

  Future<OAuthClientRegistration?> getClient(String issuer) async {
    final stored = _clients[issuer];
    if (stored is! Map) return null;
    final map = stored.cast<String, dynamic>();
    final clientId = map['clientId'];
    final redirectUri = map['redirectUri'];
    if (clientId is! String || redirectUri is! String) return null;
    return OAuthClientRegistration(
      issuer: issuer,
      clientId: clientId,
      clientSecret: map['clientSecret'] is String ? map['clientSecret'] as String : null,
      redirectUri: redirectUri,
    );
  }

  Future<void> putClient(OAuthClientRegistration registration) => _update((root) {
        final clients = Map<String, dynamic>.from(root['clients'] as Map? ?? const {});
        clients[registration.issuer] = {
          'clientId': registration.clientId,
          if (registration.clientSecret != null) 'clientSecret': registration.clientSecret,
          'redirectUri': registration.redirectUri,
        };
        return {...root, 'clients': clients};
      });

  Future<void> clearClient(String issuer) => _update((root) {
        final clients = Map<String, dynamic>.from(root['clients'] as Map? ?? const {});
        clients.remove(issuer);
        return {...root, 'clients': clients};
      });

  Future<OAuthTokens?> getTokens(String issuer) async {
    final stored = _tokens[issuer];
    if (stored is! Map) return null;
    final map = stored.cast<String, dynamic>();
    final accessToken = map['accessToken'];
    if (accessToken is! String) return null;
    return OAuthTokens(
      accessToken: accessToken,
      refreshToken: map['refreshToken'] is String ? map['refreshToken'] as String : null,
      expiresAtEpochSeconds: switch (map['expiresAt']) {
        final num value => value.toInt(),
        _ => null,
      },
      scope: map['scope'] is String ? map['scope'] as String : null,
    );
  }

  Future<void> putTokens(String issuer, OAuthTokens tokens) => _update((root) {
        final entries = Map<String, dynamic>.from(root['tokens'] as Map? ?? const {});
        entries[issuer] = {
          'accessToken': tokens.accessToken,
          if (tokens.refreshToken != null) 'refreshToken': tokens.refreshToken,
          if (tokens.expiresAtEpochSeconds != null) 'expiresAt': tokens.expiresAtEpochSeconds,
          if (tokens.scope != null) 'scope': tokens.scope,
        };
        return {...root, 'tokens': entries};
      });

  /// 清除某个 issuer 的客户端注册与令牌,以及指向它的 server 映射。
  Future<void> clear(String issuer) => _update((root) {
        final clients = Map<String, dynamic>.from(root['clients'] as Map? ?? const {});
        final tokens = Map<String, dynamic>.from(root['tokens'] as Map? ?? const {});
        final servers = Map<String, dynamic>.from(root['serverIssuers'] as Map? ?? const {});
        clients.remove(issuer);
        tokens.remove(issuer);
        servers.removeWhere((_, value) => value == issuer);
        return {...root, 'clients': clients, 'tokens': tokens, 'serverIssuers': servers};
      });

  /// server 名 → issuer 的映射(重启后按 server 恢复会话与刷新)。
  Future<String?> getIssuerForServer(String serverName) async {
    final value = _serverIssuers[serverName];
    return value is String ? value : null;
  }

  Future<void> putServerIssuer(String serverName, String issuer) => _update((root) {
        final servers = Map<String, dynamic>.from(root['serverIssuers'] as Map? ?? const {});
        servers[serverName] = issuer;
        return {...root, 'serverIssuers': servers};
      });

  Future<void> clearServerIssuer(String serverName) => _update((root) {
        final servers = Map<String, dynamic>.from(root['serverIssuers'] as Map? ?? const {});
        servers.remove(serverName);
        return {...root, 'serverIssuers': servers};
      });

  Map<String, dynamic> get _root => _cache ?? const {};

  Map<Object?, Object?> get _clients => _root['clients'] as Map? ?? const {};

  Map<Object?, Object?> get _tokens => _root['tokens'] as Map? ?? const {};

  Map<Object?, Object?> get _serverIssuers => _root['serverIssuers'] as Map? ?? const {};

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    try {
      if (!await _file.exists()) {
        _cache = <String, dynamic>{};
        return _cache!;
      }
      final raw = await _file.readAsString();
      final decoded = _tryDecode(raw) ?? raw;
      final parsed = jsonDecode(decoded);
      _cache = parsed is Map ? parsed.cast<String, dynamic>() : <String, dynamic>{};
    } catch (_) {
      _cache = <String, dynamic>{};
    }
    return _cache!;
  }

  Future<void> _update(Map<String, dynamic> Function(Map<String, dynamic> root) transform) async {
    final next = transform(await _load());
    _cache = next;
    try {
      await _file.parent.create(recursive: true);
      final temp = File('${_file.path}.tmp');
      await temp.writeAsString(_encode(jsonEncode(next)), flush: true);
      await temp.rename(_file.path);
    } catch (_) {}
  }

  /// 编码:base64 后整体反转(属混淆,非加密)。
  static String _encode(String plain) =>
      base64.encode(utf8.encode(plain)).split('').reversed.join();

  /// 解码编码串;不是本格式时返回 null(用往返校验判定格式)。
  static String? _tryDecode(String text) {
    try {
      final raw = text.trim();
      if (raw.isEmpty) return null;
      final decoded = utf8.decode(base64.decode(raw.split('').reversed.join()));
      if (_encode(decoded) != raw) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }
}

/// 令牌存储(`<配置目录>/mcp-oauth.json`,与 mcp.json 同级)。
final mcpTokenStoreProvider = Provider<McpTokenStore>(
  (ref) => McpTokenStore(File(p.join(ref.watch(configDirProvider), 'mcp-oauth.json'))),
);