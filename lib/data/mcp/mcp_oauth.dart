import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mcp_auth_models.dart';
import 'mcp_config.dart';
import 'mcp_token_store.dart';

/// 元数据发现(对齐上游 McpOAuthDiscovery):从 401 指向的受保护资源元数据(RFC 9728)取出授权服务器,
/// 再按 RFC 8414 或 OIDC Discovery 拉取授权服务器元数据。
class McpOAuthDiscovery {
  McpOAuthDiscovery(this._dio);

  final Dio _dio;

  static const Duration _timeout = Duration(seconds: 20);

  /// 候选的 well-known 地址:RFC 8414 把 `.well-known/oauth-authorization-server` 插在 host 与路径之间,
  /// OIDC Discovery 则插在 host 后(带路径)或追加在 issuer 之后。三种都给出,逐一尝试。
  static List<String> wellKnownUrls(String issuer) {
    final uri = Uri.tryParse(issuer);
    if (uri == null || uri.host.isEmpty) {
      return ['${issuer.replaceAll(RegExp(r'/+$'), '')}/.well-known/oauth-authorization-server'];
    }
    final authority = _authorityOf(uri);
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return <String>{
      '$authority/.well-known/oauth-authorization-server$path',
      '$authority/.well-known/openid-configuration$path',
      '${issuer.replaceAll(RegExp(r'/+$'), '')}/.well-known/openid-configuration',
    }.toList();
  }

  /// RFC 9728 标准位置:把 `.well-known/oauth-protected-resource` 插在 host 与 resource 路径之间。
  static List<String> wellKnownResourceMetadataUrls(String resource) {
    final uri = Uri.tryParse(resource);
    if (uri == null || uri.host.isEmpty) return const [];
    final authority = _authorityOf(uri);
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return <String>{'$authority/.well-known/oauth-protected-resource$path'}.toList();
  }

  /// issuer 比对:scheme 与 host 大小写不敏感(RFC 3986 §6.2.1),其余保持原样。
  static bool issuerMatches(String expected, String actual) =>
      expected == actual || _normalizeIssuer(expected) == _normalizeIssuer(actual);

  static String _authorityOf(Uri uri) {
    final buffer = StringBuffer('${uri.scheme}://${uri.host}');
    if (uri.hasPort) buffer.write(':${uri.port}');
    return buffer.toString();
  }

  static String _normalizeIssuer(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return value;
    final buffer = StringBuffer('${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}');
    if (uri.hasPort) buffer.write(':${uri.port}');
    buffer.write(uri.path);
    if (uri.query.isNotEmpty) buffer.write('?${uri.query}');
    return buffer.toString();
  }

  Future<ProtectedResourceMetadata> fetchProtectedResourceMetadata(String url) async =>
      ProtectedResourceMetadata.fromJson(await _getJson(url));

  /// 从 resource 本身按 RFC 9728 标准位置取受保护资源元数据(server 匿名可用但支持登录时走这条)。
  Future<ProtectedResourceMetadata> fetchProtectedResourceMetadataForResource(String resource) async {
    Object? lastError;
    for (final candidate in wellKnownResourceMetadataUrls(resource)) {
      try {
        return ProtectedResourceMetadata.fromJson(await _getJson(candidate));
      } catch (error) {
        lastError = error;
      }
    }
    throw McpOAuthException('无法获取受保护资源元数据($resource):${lastError ?? '无可用端点'}');
  }

  Future<AuthorizationServerMetadata> fetchAuthorizationServerMetadata(String issuer) async {
    Object? lastError;
    for (final candidate in wellKnownUrls(issuer)) {
      try {
        final metadata = AuthorizationServerMetadata.fromJson(await _getJson(candidate));
        if (metadata.issuer.isEmpty || !issuerMatches(issuer, metadata.issuer)) continue;
        return metadata;
      } catch (error) {
        lastError = error;
      }
    }
    throw McpOAuthException(
      '无法获取授权服务器元数据($issuer):${lastError ?? '所有 well-known 端点均不可用'}',
    );
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await _dio
        .get<Object?>(
          url,
          options: Options(
            headers: const {'Accept': 'application/json'},
            responseType: ResponseType.plain,
          ),
        )
        .timeout(_timeout, onTimeout: () => throw McpOAuthException('请求 $url 超时'));
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw McpOAuthException('HTTP $status 请求 $url 失败');
    }
    final map = oauthMapOf(response.data);
    if (map == null) throw McpOAuthException('$url 响应不是合法 JSON');
    return map;
  }
}

/// 获取 OAuth 客户端身份(对齐上游 McpClientRegistrar):预注册 → 动态客户端注册(DCR)。
class McpClientRegistrar {
  McpClientRegistrar(this._dio, this._tokenStore);

  final Dio _dio;
  final McpTokenStore _tokenStore;

  static const Duration _timeout = Duration(seconds: 20);

  Future<OAuthClientRegistration?> resolveClient({
    required String issuer,
    required AuthorizationServerMetadata metadata,
    required String redirectUri,
    String? preRegisteredClientId,
  }) async {
    final cached = await _tokenStore.getClient(issuer);
    final trimmed = preRegisteredClientId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      if (cached != null && cached.clientId == trimmed) return cached;
      final registration = OAuthClientRegistration(
        issuer: issuer,
        clientId: trimmed,
        redirectUri: redirectUri,
      );
      await _tokenStore.putClient(registration);
      return registration;
    }
    if (cached != null) return cached;

    final endpoint = metadata.registrationEndpoint;
    if (endpoint == null || endpoint.trim().isEmpty) return null;
    final registration = await _registerDynamically(
      endpoint: endpoint,
      issuer: issuer,
      redirectUri: redirectUri,
      scopesSupported: metadata.scopesSupported,
    );
    await _tokenStore.putClient(registration);
    return registration;
  }

  Future<OAuthClientRegistration> _registerDynamically({
    required String endpoint,
    required String issuer,
    required String redirectUri,
    required List<String> scopesSupported,
  }) async {
    final response = await _dio
        .post<Object?>(
          endpoint,
          data: jsonEncode({
            'client_name': 'Codecraft',
            'redirect_uris': [redirectUri],
            'grant_types': ['authorization_code', 'refresh_token'],
            'response_types': ['code'],
            'token_endpoint_auth_method': 'none',
            if (scopesSupported.isNotEmpty) 'scope': scopesSupported.join(' '),
          }),
          options: Options(
            contentType: Headers.jsonContentType,
            headers: const {'Accept': 'application/json'},
            responseType: ResponseType.plain,
          ),
        )
        .timeout(_timeout, onTimeout: () => throw const McpOAuthException('动态客户端注册超时'));
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw McpOAuthException('动态客户端注册失败:HTTP $status');
    }
    final map = oauthMapOf(response.data);
    if (map == null) throw const McpOAuthException('动态客户端注册响应解析失败');
    final clientId = map['client_id'];
    if (clientId is! String || clientId.isEmpty) {
      throw const McpOAuthException('动态客户端注册响应缺少 client_id');
    }
    return OAuthClientRegistration(
      issuer: issuer,
      clientId: clientId,
      clientSecret: map['client_secret'] is String ? map['client_secret'] as String : null,
      redirectUri: redirectUri,
    );
  }
}

/// 监听 127.0.0.1 的 OAuth 回调服务器(对齐上游 McpLoopbackServer):
/// 授权完成后浏览器重定向到 `http://127.0.0.1:<port>/callback?code=...&state=...`,
/// 这里接收一次请求、解析查询串并回一个提示页。
class McpLoopbackServer {
  McpLoopbackServer(this._port, {this.path = '/callback'});

  final int _port;
  final String path;

  HttpServer? _server;

  int get boundPort => _server?.port ?? _port;

  Future<McpLoopbackServer> bind() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port, shared: false);
    return this;
  }

  Future<LoopbackCallback> awaitCallback(Duration timeout) async {
    final server = _server;
    if (server == null) throw const McpOAuthException('回调服务器未启动');
    try {
      final request = await server.first.timeout(
        timeout,
        onTimeout: () => throw const McpOAuthException('等待授权回调超时'),
      );
      final query = request.uri.path.startsWith(path)
          ? request.uri.queryParameters
          : const <String, String>{};
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(_resultHtml(query['error']));
      await request.response.close();
      return LoopbackCallback(
        code: query['code'],
        state: query['state'],
        error: query['error'],
        errorDescription: query['error_description'],
        iss: query['iss'],
      );
    } on TimeoutException {
      throw const McpOAuthException('等待授权回调超时');
    } on HttpException {
      // 上层主动 close 会打断监听 → 视作用户取消。
      throw const McpOAuthCancelledException();
    } on StateError {
      throw const McpOAuthCancelledException();
    } finally {
      await close();
    }
  }

  Future<void> close() async {
    final server = _server;
    _server = null;
    try {
      await server?.close(force: true);
    } catch (_) {}
  }

  static String _resultHtml(String? error) {
    final message = (error == null || error.trim().isEmpty)
        ? '授权完成,可以返回 Codecraft。<br>Authorization complete. You can return to Codecraft.'
        : '授权失败:$error<br>Authorization failed. Return to Codecraft and retry.';
    return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Codecraft</title></head>'
        '<body style="font-family:sans-serif;padding:24px;line-height:1.6"><h3>$message</h3></body></html>';
  }
}

/// 通用 MCP OAuth 客户端(对齐上游 McpOAuthManager):
/// 为任意远程 MCP server 完成「发现 → 注册 → PKCE 授权 → 换令牌 → 刷新」。
/// 令牌按授权服务器 issuer 持久化,内存另存 server 名 → 会话的映射,供请求头同步取用。
class McpOAuthManager {
  McpOAuthManager({
    required McpOAuthDiscovery discovery,
    required McpClientRegistrar registrar,
    required McpTokenStore tokenStore,
    Dio? dio,
    Future<void> Function(String url)? browserLauncher,
    int callbackPort = 8765,
    Duration callbackTimeout = const Duration(minutes: 5),
  })  : _discovery = discovery,
        _registrar = registrar,
        _tokenStore = tokenStore,
        _dio = dio ?? Dio(BaseOptions(validateStatus: (_) => true)),
        _launch = browserLauncher ?? _defaultBrowserLauncher,
        _callbackPort = callbackPort,
        _callbackTimeout = callbackTimeout;

  static const String callbackPath = '/callback';
  static const Duration _requestTimeout = Duration(seconds: 30);

  final McpOAuthDiscovery _discovery;
  final McpClientRegistrar _registrar;
  final McpTokenStore _tokenStore;
  final Dio _dio;
  final Future<void> Function(String url) _launch;
  final int _callbackPort;
  final Duration _callbackTimeout;

  final Map<String, _AuthSession> _sessions = {};
  final Map<String, McpLoopbackServer> _activeServers = {};

  static Future<void> _defaultBrowserLauncher(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// 供传输层同步取用的当前 access token;无有效会话时返回 null。
  String? cachedToken(String serverName) => _sessions[serverName]?.tokens.accessToken;

  bool isAuthorized(String serverName) => _sessions.containsKey(serverName);

  /// 取消正在进行的授权:关闭回调服务器,等待回调的协程抛 [McpOAuthCancelledException]。
  Future<void> cancel(String serverName) async {
    final server = _activeServers.remove(serverName);
    await server?.close();
  }

  /// 连接前准备:恢复已有会话并在令牌过期时刷新。失败不抛——拿不到令牌就让连接按 401 处理。
  Future<void> prepare(McpServerConfig cfg) async {
    if (cfg.auth == null) return;
    final existing = _sessions[cfg.name];
    if (existing != null) {
      await _refreshIfNeeded(cfg, existing);
      return;
    }
    final issuer = await _tokenStore.getIssuerForServer(cfg.name);
    if (issuer == null) return;
    final registration = await _tokenStore.getClient(issuer);
    final tokens = await _tokenStore.getTokens(issuer);
    if (registration == null || tokens == null) return;
    final session = _AuthSession(issuer: issuer, registration: registration, tokens: tokens);
    _sessions[cfg.name] = session;
    await _refreshIfNeeded(cfg, session);
  }

  /// 完整授权流程(成功写入存储与内存会话)。
  Future<OAuthTokens> authorize(McpServerConfig cfg) async {
    final rawUrl = cfg.url.trim();
    if (rawUrl.isEmpty) throw const McpOAuthException('server 未配置 url');
    final challenge = await _probeChallenge(rawUrl);
    final metadataUrl = challenge?.resourceMetadataUrl;
    final prm = (metadataUrl != null && metadataUrl.trim().isNotEmpty)
        ? await _discovery.fetchProtectedResourceMetadata(metadataUrl)
        : await _discovery.fetchProtectedResourceMetadataForResource(rawUrl);

    final configuredIssuer = cfg.auth?.authServer?.trim();
    final issuer = (configuredIssuer != null && configuredIssuer.isNotEmpty)
        ? configuredIssuer
        : (prm.authorizationServers.isNotEmpty ? prm.authorizationServers.first : null);
    if (issuer == null || issuer.isEmpty) {
      throw const McpOAuthException('受保护资源元数据未声明 authorization_servers');
    }
    final metadata = await _discovery.fetchAuthorizationServerMetadata(issuer);

    final existingClient = await _tokenStore.getClient(issuer);
    final preferredPort = (existingClient == null)
        ? _callbackPort
        : (_portFromRedirectUri(existingClient.redirectUri) ?? _callbackPort);
    final server = await _bindLoopbackServer(preferredPort, issuer, metadata);
    _activeServers[cfg.name] = server;
    try {
      final requestedRedirectUri = 'http://127.0.0.1:${server.boundPort}$callbackPath';
      final registration = await _registrar.resolveClient(
        issuer: issuer,
        metadata: metadata,
        redirectUri: requestedRedirectUri,
        preRegisteredClientId: cfg.auth?.clientId,
      );
      if (registration == null) {
        throw const McpOAuthException('授权服务器不支持动态注册,请在配置里填写 client_id');
      }
      final redirectUri = registration.redirectUri;

      final resource = (prm.resource != null && prm.resource!.isNotEmpty)
          ? prm.resource!
          : rawUrl.replaceAll(RegExp(r'/+$'), '');
      final challengeScope = challenge?.scope;
      final configuredScopes = cfg.auth?.scopes;
      final scope = (challengeScope != null && challengeScope.isNotEmpty)
          ? challengeScope
          : (configuredScopes != null && configuredScopes.isNotEmpty)
              ? configuredScopes.join(' ')
              : (prm.scopesSupported.isNotEmpty ? prm.scopesSupported.join(' ') : null);

      final verifier = McpPkce.generateCodeVerifier();
      final state = McpPkce.generateState();
      final authUrl = _buildAuthorizationUrl(
        metadata: metadata,
        registration: registration,
        redirectUri: redirectUri,
        resource: resource,
        scope: scope,
        verifier: verifier,
        state: state,
      );

      final callbackFuture = server.awaitCallback(_callbackTimeout);
      await _launch(authUrl);
      final callback = await callbackFuture;

      final error = callback.error;
      if (error != null && error.isNotEmpty) {
        throw McpOAuthException('授权被拒绝:$error ${callback.errorDescription ?? ''}'.trim());
      }
      if (callback.state != state) {
        throw const McpOAuthException('state 校验失败,可能遭遇 CSRF,已中止');
      }
      // RFC 9207:授权服务器声明支持 iss 时必须比对记录的 issuer。
      final callbackIss = callback.iss;
      if (metadata.authorizationResponseIssParameterSupported &&
          callbackIss != null &&
          !McpOAuthDiscovery.issuerMatches(issuer, callbackIss)) {
        throw McpOAuthException('iss 校验失败:期望 $issuer,实际 $callbackIss');
      }
      final code = callback.code;
      if (code == null || code.isEmpty) throw const McpOAuthException('授权回调缺少 code');

      final tokens = await _exchangeCode(
        metadata: metadata,
        registration: registration,
        code: code,
        redirectUri: redirectUri,
        verifier: verifier,
        resource: resource,
      );
      await _tokenStore.putTokens(issuer, tokens);
      await _tokenStore.putServerIssuer(cfg.name, issuer);
      _sessions[cfg.name] =
          _AuthSession(issuer: issuer, registration: registration, tokens: tokens);
      return tokens;
    } finally {
      _activeServers.remove(cfg.name);
      await server.close();
    }
  }

  Future<void> logout(McpServerConfig cfg) async {
    final issuer = _sessions[cfg.name]?.issuer ?? await _tokenStore.getIssuerForServer(cfg.name);
    if (issuer != null) await _tokenStore.clear(issuer);
    await _tokenStore.clearServerIssuer(cfg.name);
    _sessions.remove(cfg.name);
  }

  Future<void> _refreshIfNeeded(McpServerConfig cfg, _AuthSession session) async {
    if (!session.tokens.isExpired(_nowSeconds())) return;
    final refreshToken = session.tokens.refreshToken;
    if (refreshToken == null) return;
    try {
      final metadata = await _discovery.fetchAuthorizationServerMetadata(session.issuer);
      final refreshed = await _exchangeRefreshToken(
        metadata: metadata,
        registration: session.registration,
        refreshToken: refreshToken,
      );
      await _tokenStore.putTokens(session.issuer, refreshed);
      _sessions[cfg.name] = _AuthSession(
        issuer: session.issuer,
        registration: session.registration,
        tokens: refreshed,
      );
    } catch (_) {
      // 刷新失败不阻塞:连接会按 401 处理,由 UI 引导重新授权。
    }
  }

  /// 无令牌发一次 initialize 探测授权挑战;返回 null 表示 server 匿名可用。
  Future<BearerChallenge?> _probeChallenge(String url) async {
    final response = await _dio
        .post<Object?>(
          url,
          data: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'initialize',
            'params': {
              'protocolVersion': '2025-06-18',
              'capabilities': <String, dynamic>{},
              'clientInfo': {'name': 'ai-code-editor', 'version': '1.0.0'},
            },
          }),
          options: Options(
            contentType: Headers.jsonContentType,
            headers: const {'Accept': 'application/json, text/event-stream'},
            responseType: ResponseType.plain,
          ),
        )
        .timeout(_requestTimeout, onTimeout: () => throw const McpOAuthException('探测授权挑战超时'));
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      return WwwAuthenticateParser.parse(response.headers.value('www-authenticate'));
    }
    if (status >= 200 && status < 300) return null;
    throw McpOAuthException('server 返回 HTTP $status,无法开始授权');
  }

  Future<OAuthTokens> _exchangeCode({
    required AuthorizationServerMetadata metadata,
    required OAuthClientRegistration registration,
    required String code,
    required String redirectUri,
    required String verifier,
    required String resource,
  }) {
    final endpoint = metadata.tokenEndpoint;
    if (endpoint == null || endpoint.isEmpty) {
      throw const McpOAuthException('授权服务器缺少 token_endpoint');
    }
    return _postToken(endpoint, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': registration.clientId,
      'code_verifier': verifier,
      'resource': resource,
      if (registration.clientSecret != null) 'client_secret': registration.clientSecret!,
    });
  }

  Future<OAuthTokens> _exchangeRefreshToken({
    required AuthorizationServerMetadata metadata,
    required OAuthClientRegistration registration,
    required String refreshToken,
  }) {
    final endpoint = metadata.tokenEndpoint;
    if (endpoint == null || endpoint.isEmpty) {
      throw const McpOAuthException('授权服务器缺少 token_endpoint');
    }
    return _postToken(endpoint, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': registration.clientId,
      if (registration.clientSecret != null) 'client_secret': registration.clientSecret!,
    });
  }

  Future<OAuthTokens> _postToken(String endpoint, Map<String, String> form) async {
    final body = form.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    final response = await _dio
        .post<Object?>(
          endpoint,
          data: body,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: const {'Accept': 'application/json'},
            responseType: ResponseType.plain,
          ),
        )
        .timeout(_requestTimeout, onTimeout: () => throw const McpOAuthException('换取令牌超时'));
    final status = response.statusCode ?? 0;
    final text = '${response.data ?? ''}';
    if (status < 200 || status >= 300) {
      throw McpOAuthException('换取令牌失败:HTTP $status $text');
    }
    final map = oauthMapOf(response.data);
    if (map == null) throw const McpOAuthException('令牌响应解析失败');
    final accessToken = map['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const McpOAuthException('令牌响应缺少 access_token');
    }
    final expiresIn = switch (map['expires_in']) {
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
    return OAuthTokens(
      accessToken: accessToken,
      refreshToken: map['refresh_token'] is String ? map['refresh_token'] as String : null,
      expiresAtEpochSeconds: expiresIn == null ? null : _nowSeconds() + expiresIn,
      scope: map['scope'] is String ? map['scope'] as String : null,
    );
  }

  String _buildAuthorizationUrl({
    required AuthorizationServerMetadata metadata,
    required OAuthClientRegistration registration,
    required String redirectUri,
    required String resource,
    required String? scope,
    required String verifier,
    required String state,
  }) {
    final base = metadata.authorizationEndpoint;
    if (base == null || base.isEmpty) {
      throw const McpOAuthException('授权服务器缺少 authorization_endpoint');
    }
    final params = <String, String>{
      'response_type': 'code',
      'client_id': registration.clientId,
      'redirect_uri': redirectUri,
      'code_challenge': McpPkce.codeChallengeS256(verifier),
      'code_challenge_method': 'S256',
      'state': state,
      'resource': resource,
      if (scope != null && scope.isNotEmpty) 'scope': scope,
    };
    final separator = base.contains('?') ? '&' : '?';
    final query = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return '$base$separator$query';
  }

  /// 绑定回环端口:已有注册时优先复用其登记端口;端口被占用且支持动态注册时清掉旧注册改随机端口。
  Future<McpLoopbackServer> _bindLoopbackServer(
    int preferredPort,
    String issuer,
    AuthorizationServerMetadata metadata,
  ) async {
    try {
      return await McpLoopbackServer(preferredPort, path: callbackPath).bind();
    } on SocketException {
      if (metadata.registrationEndpoint == null || metadata.registrationEndpoint!.isEmpty) {
        throw McpOAuthException('回调端口 $preferredPort 被占用且客户端不支持重新注册,请释放端口后重试');
      }
      await _tokenStore.clearClient(issuer);
      return McpLoopbackServer(0, path: callbackPath).bind();
    }
  }

  static int? _portFromRedirectUri(String uri) {
    final port = Uri.tryParse(uri)?.port;
    return (port != null && port > 0) ? port : null;
  }

  static int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

class _AuthSession {
  const _AuthSession({
    required this.issuer,
    required this.registration,
    required this.tokens,
  });

  final String issuer;
  final OAuthClientRegistration registration;
  final OAuthTokens tokens;
}

final mcpOAuthManagerProvider = Provider<McpOAuthManager>((ref) {
  final tokenStore = ref.watch(mcpTokenStoreProvider);
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  return McpOAuthManager(
    discovery: McpOAuthDiscovery(dio),
    registrar: McpClientRegistrar(dio, tokenStore),
    tokenStore: tokenStore,
    dio: dio,
  );
});

/// 响应体 → Map(dio 可能已按 JSON 解析成 Map,也可能因 responseType 保持原始字符串)。
Map<String, dynamic>? oauthMapOf(Object? data) {
  if (data is Map) return data.cast<String, dynamic>();
  if (data is String && data.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  return null;
}
