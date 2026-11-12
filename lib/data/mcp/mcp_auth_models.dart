import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// MCP OAuth 异常(统一类型,带可读消息)。
class McpOAuthException implements Exception {
  const McpOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 用户取消授权(主动关闭回调服务器)。
class McpOAuthCancelledException extends McpOAuthException {
  const McpOAuthCancelledException() : super('已取消授权');
}

/// RFC 9728 受保护资源元数据(MCP server 在 401 里指向的文档)。
class ProtectedResourceMetadata {
  const ProtectedResourceMetadata({
    this.resource,
    this.authorizationServers = const [],
    this.scopesSupported = const [],
    this.bearerMethodsSupported = const [],
  });

  final String? resource;
  final List<String> authorizationServers;
  final List<String> scopesSupported;
  final List<String> bearerMethodsSupported;

  static ProtectedResourceMetadata fromJson(Map<String, dynamic> json) =>
      ProtectedResourceMetadata(
        resource: json['resource'] is String ? json['resource'] as String : null,
        authorizationServers: _stringList(json['authorization_servers']),
        scopesSupported: _stringList(json['scopes_supported']),
        bearerMethodsSupported: _stringList(json['bearer_methods_supported']),
      );
}

/// RFC 8414 / OIDC Discovery 授权服务器元数据(只取实现需要的子集)。
class AuthorizationServerMetadata {
  const AuthorizationServerMetadata({
    required this.issuer,
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.registrationEndpoint,
    this.scopesSupported = const [],
    this.codeChallengeMethodsSupported = const [],
    this.tokenEndpointAuthMethodsSupported = const [],
    this.authorizationResponseIssParameterSupported = false,
  });

  final String issuer;
  final String? authorizationEndpoint;
  final String? tokenEndpoint;
  final String? registrationEndpoint;
  final List<String> scopesSupported;
  final List<String> codeChallengeMethodsSupported;
  final List<String> tokenEndpointAuthMethodsSupported;
  final bool authorizationResponseIssParameterSupported;

  static AuthorizationServerMetadata fromJson(Map<String, dynamic> json) =>
      AuthorizationServerMetadata(
        issuer: '${json['issuer'] ?? ''}',
        authorizationEndpoint: _stringOf(json['authorization_endpoint']),
        tokenEndpoint: _stringOf(json['token_endpoint']),
        registrationEndpoint: _stringOf(json['registration_endpoint']),
        scopesSupported: _stringList(json['scopes_supported']),
        codeChallengeMethodsSupported: _stringList(json['code_challenge_methods_supported']),
        tokenEndpointAuthMethodsSupported:
            _stringList(json['token_endpoint_auth_methods_supported']),
        authorizationResponseIssParameterSupported:
            json['authorization_response_iss_parameter_supported'] == true,
      );
}

/// 一次 401/403 响应里 `WWW-Authenticate: Bearer` 挑战携带的信息。
class BearerChallenge {
  const BearerChallenge({
    this.resourceMetadataUrl,
    this.scope,
    this.error,
    this.errorDescription,
  });

  final String? resourceMetadataUrl;
  final String? scope;
  final String? error;
  final String? errorDescription;
}

/// 已获得的 OAuth 客户端身份(绑定到具体授权服务器 issuer)。
class OAuthClientRegistration {
  const OAuthClientRegistration({
    required this.issuer,
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
  });

  final String issuer;
  final String clientId;
  final String? clientSecret;
  final String redirectUri;
}

/// 一次授权换取的令牌。
class OAuthTokens {
  const OAuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAtEpochSeconds,
    this.scope,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresAtEpochSeconds;
  final String? scope;

  /// 是否已过期(提前 [skewSeconds] 视为过期,避免边界重试)。
  bool isExpired(int nowEpochSeconds, {int skewSeconds = 30}) =>
      expiresAtEpochSeconds != null && nowEpochSeconds >= expiresAtEpochSeconds! - skewSeconds;
}

/// loopback 回调的解析结果。
class LoopbackCallback {
  const LoopbackCallback({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
    this.iss,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;
  final String? iss;
}

/// PKCE(RFC 7636)与 state 生成。
class McpPkce {
  const McpPkce._();

  static final Random _random = Random.secure();

  static String _randomBase64Url(int bytes) {
    final data = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64UrlEncodeNoPadding(data);
  }

  /// code_verifier:32 字节随机数的 base64url(无 padding)→ 43 个字符。
  static String generateCodeVerifier() => _randomBase64Url(32);

  /// code_challenge = BASE64URL(SHA256(verifier)),无 padding(S256)。
  static String codeChallengeS256(String verifier) =>
      base64UrlEncodeNoPadding(sha256.convert(ascii.encode(verifier)).bytes);

  /// state:防 CSRF,32 字节随机。
  static String generateState() => _randomBase64Url(32);

  static String base64UrlEncodeNoPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}

/// 解析 `WWW-Authenticate: Bearer ...` 挑战头。
/// 形如:`Bearer resource_metadata="https://...", scope="a b", error="insufficient_scope"`;
/// 值可带引号(可含逗号与空格),未带引号时读到下一个逗号为止。只处理 Bearer 方案。
class WwwAuthenticateParser {
  const WwwAuthenticateParser._();

  static BearerChallenge parse(String? header) {
    if (header == null || header.trim().isEmpty) return const BearerChallenge();
    final trimmed = header.trim();
    final schemeEnd = trimmed.indexOf(' ');
    final scheme = schemeEnd < 0 ? trimmed : trimmed.substring(0, schemeEnd);
    if (scheme.toLowerCase() != 'bearer') return const BearerChallenge();
    final params = schemeEnd < 0 ? '' : trimmed.substring(schemeEnd + 1);
    final map = _parseParams(params);
    return BearerChallenge(
      resourceMetadataUrl: map['resource_metadata'],
      scope: map['scope'],
      error: map['error'],
      errorDescription: map['error_description'],
    );
  }

  static Map<String, String> _parseParams(String input) {
    final result = <String, String>{};
    var i = 0;
    while (i < input.length) {
      while (i < input.length && (_isWhitespace(input[i]) || input[i] == ',')) {
        i++;
      }
      final keyStart = i;
      while (i < input.length && input[i] != '=' && input[i] != ',') {
        i++;
      }
      if (i >= input.length) break;
      if (input[i] == ',') continue;
      final key = input.substring(keyStart, i).trim();
      i++; // 跳过 '='
      String value;
      if (i < input.length && input[i] == '"') {
        i++;
        final buffer = StringBuffer();
        while (i < input.length && input[i] != '"') {
          if (input[i] == r'\' && i + 1 < input.length) {
            i++;
            buffer.write(input[i]);
          } else {
            buffer.write(input[i]);
          }
          i++;
        }
        i++; // 跳过收尾引号
        value = buffer.toString();
      } else {
        final valueStart = i;
        while (i < input.length && input[i] != ',') {
          i++;
        }
        value = input.substring(valueStart, i).trim();
      }
      if (key.isNotEmpty) result[key] = value;
    }
    return result;
  }

  static bool _isWhitespace(String char) => char.trim().isEmpty;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final entry in value) if (entry is String) entry];
}

String? _stringOf(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}