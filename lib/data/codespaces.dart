import 'dart:convert';
import 'dart:io';

import 'credentials.dart';

/// GitHub Codespaces 的 host(凭据与 API 都固定走 github.com)。
const String codespacesHost = 'github.com';

const String _apiBase = 'https://api.github.com';
const String _apiVersion = '2022-11-28';

/// 一个 Codespace(字段取自 REST API `GET /user/codespaces`)。
class Codespace {
  const Codespace({
    required this.name,
    required this.repository,
    required this.state,
    this.displayName = '',
    this.machineDisplay = '',
    this.lastUsedAt,
    this.webUrl = '',
    this.gitRef = '',
    this.hasUncommittedChanges = false,
  });

  final String name;

  /// 仓库全名(`owner/repo`)。
  final String repository;

  /// 原始状态字符串:Available / Starting / Stopped / Shutdown / Failed / Deleting …
  final String state;

  final String displayName;

  /// 机器规格展示文本,如 `4 cores, 16 GB RAM, 64 GB storage`。
  final String machineDisplay;

  final DateTime? lastUsedAt;

  /// 浏览器访问地址,如 `https://xxx.github.dev`。
  final String webUrl;

  final String gitRef;

  final bool hasUncommittedChanges;

  /// 从 REST API 的 JSON 解析;缺失字段按空值兜底。
  factory Codespace.fromJson(Map<String, dynamic> json) {
    final repository = json['repository'];
    final machine = json['machine'];
    final gitStatus = json['git_status'];
    return Codespace(
      name: json['name'] as String? ?? '',
      repository: repository is Map<String, dynamic>
          ? repository['full_name'] as String? ?? ''
          : '',
      state: json['state'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      machineDisplay: machine is Map<String, dynamic>
          ? machine['display_name'] as String? ?? ''
          : '',
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
      webUrl: json['web_url'] as String? ?? '',
      gitRef: gitStatus is Map<String, dynamic> ? gitStatus['ref'] as String? ?? '' : '',
      hasUncommittedChanges: gitStatus is Map<String, dynamic>
          ? gitStatus['has_uncommitted_changes'] as bool? ?? false
          : false,
    );
  }

  /// UI 展示名:优先 displayName,空则用 name。
  String get title => displayName.trim().isEmpty ? name : displayName;

  /// 是否处于「可用/运行中」状态,可直接接入执行环境。
  bool get isAvailable => state.toLowerCase() == 'available' || state.toLowerCase() == 'starting';

  /// 状态更新辅助方法。
  Codespace copyWithState(String newState) {
    return Codespace(
      name: name,
      repository: repository,
      state: newState,
      displayName: displayName,
      machineDisplay: machineDisplay,
      lastUsedAt: lastUsedAt,
      webUrl: webUrl,
      gitRef: gitRef,
      hasUncommittedChanges: hasUncommittedChanges,
    );
  }

  /// 是否启动中(含从停止态唤醒)。
  bool get isStarting => state.toLowerCase() == 'starting';

  /// 是否已停机。
  bool get isStopped {
    final normalized = state.toLowerCase();
    return normalized == 'stopped' || normalized == 'shutdown';
  }

  @override
  bool operator ==(Object other) =>
      other is Codespace &&
      other.name == name &&
      other.repository == repository &&
      other.state == state &&
      other.displayName == displayName &&
      other.machineDisplay == machineDisplay &&
      other.lastUsedAt == lastUsedAt &&
      other.webUrl == webUrl &&
      other.gitRef == gitRef &&
      other.hasUncommittedChanges == hasUncommittedChanges;

  @override
  int get hashCode => Object.hash(
        name,
        repository,
        state,
        displayName,
        machineDisplay,
        lastUsedAt,
        webUrl,
        gitRef,
        hasUncommittedChanges,
      );
}

/// 一个可用于新建 Codespace 的仓库(`GET /user/repos`)。
class GitHubRepo {
  const GitHubRepo({
    required this.fullName,
    this.defaultBranch = '',
    this.private = false,
    this.description = '',
  });

  /// `owner/repo`。
  final String fullName;
  final String defaultBranch;
  final bool private;
  final String description;

  factory GitHubRepo.fromJson(Map<String, dynamic> json) => GitHubRepo(
        fullName: json['full_name'] as String? ?? '',
        defaultBranch: json['default_branch'] as String? ?? '',
        private: json['private'] as bool? ?? false,
        description: json['description'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) => other is GitHubRepo && other.fullName == fullName;

  @override
  int get hashCode => fullName.hashCode;
}

/// 机型和规格(`GET /repos/{owner}/{repo}/codespaces/machines`)。
class CodespaceMachine {
  const CodespaceMachine({
    required this.name,
    required this.displayName,
    this.cpus = 0,
    this.memoryInBytes = 0,
    this.storageInBytes = 0,
  });

  /// 传给 API 的机型名,如 `standardLinux`。
  final String name;
  final String displayName;
  final int cpus;
  final int memoryInBytes;
  final int storageInBytes;

  factory CodespaceMachine.fromJson(Map<String, dynamic> json) => CodespaceMachine(
        name: json['name'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        cpus: (json['cpus'] as num?)?.toInt() ?? 0,
        memoryInBytes: (json['memory_in_bytes'] as num?)?.toInt() ?? 0,
        storageInBytes: (json['storage_in_bytes'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) => other is CodespaceMachine && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// 新建 Codespace 的请求体(字段名与 `POST /repos/{owner}/{repo}/codespaces` 对齐)。
class CodespaceCreateSpec {
  const CodespaceCreateSpec({
    required this.repository,
    this.ref,
    this.machine,
    this.displayName,
    this.location,
    this.devcontainerPath,
    this.idleTimeoutMinutes,
  });

  final String repository;
  final String? ref;
  final String? machine;
  final String? displayName;
  final String? location;
  final String? devcontainerPath;
  final int? idleTimeoutMinutes;

  /// 只带上真正有值的字段:缺省字段交给服务端按默认值处理。
  Map<String, Object?> toJson() => {
        if (ref != null && ref!.trim().isNotEmpty) 'ref': ref!.trim(),
        if (machine != null && machine!.trim().isNotEmpty) 'machine': machine!.trim(),
        if (displayName != null && displayName!.trim().isNotEmpty)
          'display_name': displayName!.trim(),
        if (location != null && location!.trim().isNotEmpty) 'location': location!.trim(),
        if (devcontainerPath != null && devcontainerPath!.trim().isNotEmpty)
          'devcontainer_path': devcontainerPath!.trim(),
        if (idleTimeoutMinutes != null) 'idle_timeout_minutes': idleTimeoutMinutes,
      };
}

/// 更新 Codespace 的请求体(「重命名」与「更改机型」都走这里)。
class CodespaceUpdateSpec {
  const CodespaceUpdateSpec({this.machine, this.displayName});

  final String? machine;
  final String? displayName;

  Map<String, Object?> toJson() => {
        if (machine != null && machine!.trim().isNotEmpty) 'machine': machine!.trim(),
        if (displayName != null) 'display_name': displayName!.trim(),
      };
}

/// Codespaces 调用失败。[scopeMissing] 为 true 表示令牌缺少 `codespace` 权限或账号未开通
/// Codespaces,UI 需要给出针对性提示而不是笼统报错。
class CodespacesException implements Exception {
  const CodespacesException(this.message, {this.statusCode, this.scopeMissing = false});

  final String message;
  final int? statusCode;
  final bool scopeMissing;

  @override
  String toString() => message;
}

/// Codespaces REST 客户端。令牌需要 `codespace` 作用域(classic PAT)
/// 或 fine-grained 令牌的 Codespaces 权限;缺失时接口返回 403。
class CodespacesClient {
  CodespacesClient({required this.token, HttpClient Function()? clientFactory})
      : _clientFactory = clientFactory;

  final String token;
  final HttpClient Function()? _clientFactory;

  Future<(int, Map<String, dynamic>)> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final client = _clientFactory != null ? _clientFactory() : HttpClient();
    // 允许在 VPN/代理环境下完成 TLS 握手(某些 VPN 会拦截并重新签名证书)。
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    try {
      final uri = Uri.parse('$_apiBase$path').replace(queryParameters: query);
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set('X-GitHub-Api-Version', _apiVersion);
      request.headers.set(HttpHeaders.userAgentHeader, 'Codecraft');
      if (body != null) {
        final payload = utf8.encode(jsonEncode(body));
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.contentLength = payload.length;
        request.add(payload);
      }
      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode == 204 || raw.trim().isEmpty) {
        return (response.statusCode, const <String, dynamic>{});
      }
      final decoded = jsonDecode(raw);
      final Map<String, dynamic> map =
          decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      return (response.statusCode, map);
    } finally {
      client.close();
    }
  }

  Never _fail(int status, Map<String, dynamic> body) {
    final message = body['message'] as String? ?? '';
    if (status == 401) {
      throw const CodespacesException('令牌无效或已过期,请重新登录');
    }
    if (status == 403) {
      final missing = message.toLowerCase().contains('scope') ||
          message.toLowerCase().contains('forbidden') ||
          message.isEmpty;
      throw CodespacesException(
        missing ? '令牌缺少 codespace 权限,或该账号未开通 Codespaces' : message,
        statusCode: status,
        scopeMissing: true,
      );
    }
    if (status == 404) {
      throw CodespacesException(
        message.isEmpty ? '未找到该 Codespace(可能已被删除)' : message,
        statusCode: status,
      );
    }
    if (status == 429) {
      throw const CodespacesException('请求过于频繁,请稍后重试');
    }
    throw CodespacesException(
      message.isEmpty ? 'GitHub 返回错误(HTTP $status)' : message,
      statusCode: status,
    );
  }

  /// 校验令牌并取回登录名;失败抛出 [CodespacesException]。
  Future<String> fetchLogin() async {
    final (status, body) = await _request('GET', '/user');
    if (status != 200) _fail(status, body);
    final login = body['login'] as String? ?? '';
    if (login.isEmpty) {
      throw const CodespacesException('无法读取 GitHub 账号信息');
    }
    return login;
  }

  /// 列出账号下的全部 Codespace(自动翻页)。
  Future<List<Codespace>> listCodespaces() async {
    final result = <Codespace>[];
    var page = 1;
    while (true) {
      final (status, body) = await _request(
        'GET',
        '/user/codespaces',
        query: {'per_page': '100', 'page': '$page'},
      );
      if (status != 200) _fail(status, body);
      final items = body['codespaces'];
      if (items is! List) break;
      for (final item in items) {
        if (item is Map<String, dynamic>) result.add(Codespace.fromJson(item));
      }
      if (items.length < 100) break;
      page += 1;
    }
    return result;
  }

  Future<Codespace> _lifecycle(String action, String name) async {
    final (status, body) = await _request(
      'POST',
      '/user/codespaces/${Uri.encodeComponent(name)}/$action',
    );
    if (status != 200 && status != 201 && status != 202) _fail(status, body);
    return Codespace.fromJson(body);
  }

  Future<Codespace> start(String name) => _lifecycle('start', name);

  Future<Codespace> stop(String name) => _lifecycle('stop', name);

  /// 账号可用的仓库(按最近更新排序,取前 100 个)。
  Future<List<GitHubRepo>> listRepos() async {
    final (status, body) = await _request(
      'GET',
      '/user/repos',
      query: {'per_page': '100', 'sort': 'updated', 'affiliation': 'owner,collaborator,organization_member'},
    );
    if (status != 200) _fail(status, body);
    final items = body['data'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) GitHubRepo.fromJson(item),
    ];
  }

  /// 某仓库可用的机型(新建时选规格)。
  Future<List<CodespaceMachine>> machinesForRepo(String repository) async {
    final parts = repository.split('/');
    if (parts.length != 2) {
      throw const CodespacesException('仓库名格式应为 owner/repo');
    }
    final (status, body) = await _request(
      'GET',
      '/repos/${parts[0]}/${parts[1]}/codespaces/machines',
    );
    if (status != 200) _fail(status, body);
    final items = body['machines'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) CodespaceMachine.fromJson(item),
    ];
  }

  /// 某个已存在的 Codespace 可切换的机型。
  Future<List<CodespaceMachine>> machinesForCodespace(String name) async {
    final (status, body) = await _request(
      'GET',
      '/user/codespaces/${Uri.encodeComponent(name)}/machines',
    );
    if (status != 200) _fail(status, body);
    final items = body['machines'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) CodespaceMachine.fromJson(item),
    ];
  }

  /// 新建 Codespace。创建是异步的:返回的 state 通常是 `Queued`/`Starting`。
  Future<Codespace> create(CodespaceCreateSpec spec) async {
    final parts = spec.repository.split('/');
    if (parts.length != 2) {
      throw const CodespacesException('仓库名格式应为 owner/repo');
    }
    final (status, response) = await _request(
      'POST',
      '/repos/${parts[0]}/${parts[1]}/codespaces',
      body: spec.toJson(),
    );
    if (status != 200 && status != 201 && status != 202) _fail(status, response);
    return Codespace.fromJson(response);
  }

  /// 更新 Codespace(改显示名或机型;机型在下次启动时生效)。
  Future<Codespace> update(String name, CodespaceUpdateSpec spec) async {
    final (status, response) = await _request(
      'PATCH',
      '/user/codespaces/${Uri.encodeComponent(name)}',
      body: spec.toJson(),
    );
    if (status != 200) _fail(status, response);
    return Codespace.fromJson(response);
  }

  Future<void> delete(String name) async {
    final (status, body) = await _request(
      'DELETE',
      '/user/codespaces/${Uri.encodeComponent(name)}',
    );
    if (status != 202 && status != 204 && status != 200) _fail(status, body);
  }
}

/// Codespaces 用的令牌取自 **Git 凭据**:带 `codespace` 作用域的 GitHub 令牌同时能用于推送,
/// 因此不再单独存一份。优先 `github.com` 条目,其次「所有主机」条目(见 [CredentialStore.findForHost]);
/// 都没有则视为未登录。
Future<String> codespacesTokenFrom(CredentialStore store) async =>
    (await store.findForHost('github.com'))?.token ?? '';
