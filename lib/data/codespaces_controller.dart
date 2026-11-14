import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'codespaces.dart';
import 'codespaces_readiness.dart';
import 'credentials.dart';
import 'settings/app_settings.dart' show appLocalizationsProvider;

/// Codespaces 页状态。
class CodespacesUiState {
  const CodespacesUiState({
    this.initialized = false,
    this.loading = false,
    this.token = '',
    this.login = '',
    this.codespaces = const [],
    this.error,
    this.busyNames = const {},
    this.repos = const [],
    this.creating = false,
  });

  /// 是否已完成首次读取(决定显示登录页还是列表页)。
  final bool initialized;

  final bool loading;

  /// 已保存的令牌;非空即视为已登录。
  final String token;

  final String login;

  final List<Codespace> codespaces;

  /// 最近一次失败的诊断文本(沿用 git 错误提示的中文直出约定)。
  final String? error;

  bool get errorSuggestsCredentials => codespacesErrorSuggestsCredentials(error);

  bool get errorSuggestsGhOrConnection => codespacesErrorSuggestsGhOrConnection(error);

  /// 正在启动/停止/删除/改名/换机型中的 Codespace 名,用于按钮禁用与转圈。
  final Set<String> busyNames;

  /// 新建流程用的仓库列表(`GET /user/repos` 的结果,拉一次后复用)。
  final List<GitHubRepo> repos;

  /// 是否正在新建 Codespace(异步的,创建后状态仍会是 Queued/Starting)。
  final bool creating;

  CodespacesUiState copyWith({
    bool? initialized,
    bool? loading,
    String? token,
    String? login,
    List<Codespace>? codespaces,
    String? error,
    bool clearError = false,
    Set<String>? busyNames,
    List<GitHubRepo>? repos,
    bool? creating,
  }) =>
      CodespacesUiState(
        initialized: initialized ?? this.initialized,
        loading: loading ?? this.loading,
        token: token ?? this.token,
        login: login ?? this.login,
        codespaces: codespaces ?? this.codespaces,
        error: clearError ? null : (error ?? this.error),
        busyNames: busyNames ?? this.busyNames,
        repos: repos ?? this.repos,
        creating: creating ?? this.creating,
      );
}

final codespacesProvider =
    StateNotifierProvider<CodespacesController, CodespacesUiState>(
  (ref) => CodespacesController(ref),
);

/// Codespaces 编排:令牌读写、列表拉取、启动/停止/删除。
class CodespacesController extends StateNotifier<CodespacesUiState> {
  CodespacesController(this._ref) : super(const CodespacesUiState()) {
    load();
  }

  final Ref _ref;

  /// 令牌取自 Git 凭据(同一条带 codespace 作用域的令牌,两处共用)。
  Future<String> _readToken() =>
      codespacesTokenFrom(_ref.read(credentialStoreProvider));

  AppLocalizations get _l10n => _ref.read(appLocalizationsProvider);

  /// 读 Git 凭据里的令牌;每次调用都重新读,用户刚在「Git 凭据」里填完就能立即生效。
  /// 令牌为空则进入未登录态;有令牌就先拉一次列表(顺便验证作用域是否够)。
  Future<void> load() async {
    final token = await _readToken();
    if (!mounted) return;
    if (token.isEmpty) {
      state = state.copyWith(
        initialized: true,
        token: '',
        login: '',
        codespaces: const [],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(initialized: true, token: token, loading: true, clearError: true);
    try {
      final login = await CodespacesClient(token: token).fetchLogin();
      if (!mounted) return;
      state = state.copyWith(login: login);
    } catch (_) {
      // 登录名读取失败不影响主流程，保留为空
    }
    await _fetch();
  }

  Future<void> refresh() async => load();

  Future<void> _fetch() async {
    try {
      final codespaces = await CodespacesClient(token: state.token).listCodespaces();
      if (!mounted) return;
      state = state.copyWith(loading: false, codespaces: codespaces, clearError: true);
    } on CodespacesException catch (error) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: _l10n.codespacesNetworkError('$error'));
    }
  }

  Future<void> _lifecycle(
    String name,
    Future<Codespace> Function(CodespacesClient) action, {
    Codespace Function(Codespace)? transformUpdated,
  }) async {
    if (state.token.isEmpty) return;
    state = state.copyWith(busyNames: {...state.busyNames, name}, clearError: true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    try {
      final updated = await action(CodespacesClient(token: state.token));
      if (!mounted) return;
      final finalUpdated = transformUpdated != null ? transformUpdated(updated) : updated;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        codespaces: [
          for (final item in state.codespaces)
            if (item.name == finalUpdated.name) finalUpdated else item,
        ],
        clearError: true,
      );
    } on CodespacesException catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        error: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        error: _l10n.codespacesNetworkError('$error'),
      );
    }
  }

  Future<void> start(String name) => _lifecycle(
        name,
        (client) => client.start(name),
        transformUpdated: (updated) {
          // 只要启动接口返回成功，我们就将其状态标记为 Starting。
          // 即使 API 还没同步成 Available，我们也允许用户尝试连接。
          return updated.copyWithState('Starting');
        },
      );

  Future<void> stop(String name) => _lifecycle(name, (client) => client.stop(name));

  Future<void> delete(String name) async {
    if (state.token.isEmpty) return;
    state = state.copyWith(busyNames: {...state.busyNames, name}, clearError: true);
    try {
      await CodespacesClient(token: state.token).delete(name);
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        codespaces: state.codespaces.where((item) => item.name != name).toList(),
        clearError: true,
      );
    } on CodespacesException catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        error: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        error: _l10n.codespacesNetworkError('$error'),
      );
    }
  }

  Future<List<GitHubRepo>> loadRepos() async {
    if (state.token.isEmpty) return const [];
    try {
      final repos = await CodespacesClient(token: state.token).listRepos();
      if (mounted) state = state.copyWith(repos: repos, clearError: true);
      return repos;
    } on CodespacesException catch (error) {
      if (mounted) state = state.copyWith(error: error.message);
      return const [];
    } catch (error) {
      if (mounted) state = state.copyWith(error: _l10n.codespacesNetworkError('$error'));
      return const [];
    }
  }

  Future<List<CodespaceMachine>> loadMachinesForRepo(String repository) async {
    if (state.token.isEmpty) return const [];
    try {
      return await CodespacesClient(token: state.token).machinesForRepo(repository);
    } on CodespacesException catch (error) {
      if (mounted) state = state.copyWith(error: error.message);
      return const [];
    } catch (error) {
      if (mounted) state = state.copyWith(error: _l10n.codespacesNetworkError('$error'));
      return const [];
    }
  }

  Future<List<CodespaceMachine>> loadMachinesForCodespace(String name) async {
    if (state.token.isEmpty) return const [];
    try {
      return await CodespacesClient(token: state.token).machinesForCodespace(name);
    } on CodespacesException catch (error) {
      if (mounted) state = state.copyWith(error: error.message);
      return const [];
    } catch (error) {
      if (mounted) state = state.copyWith(error: _l10n.codespacesNetworkError('$error'));
      return const [];
    }
  }

  Future<Codespace?> create(CodespaceCreateSpec spec) async {
    if (state.token.isEmpty) return null;
    state = state.copyWith(creating: true, clearError: true);
    try {
      final created = await CodespacesClient(token: state.token).create(spec);
      if (!mounted) return created;
      state = state.copyWith(
        creating: false,
        codespaces: [created, ...state.codespaces],
        clearError: true,
      );
      return created;
    } on CodespacesException catch (error) {
      if (mounted) {
        state = state.copyWith(creating: false, error: error.message);
      }
      return null;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(creating: false, error: _l10n.codespacesNetworkError('$error'));
      }
      return null;
    }
  }

  Future<void> rename(String name, String displayName) =>
      _update(name, CodespaceUpdateSpec(displayName: displayName));

  Future<void> changeMachine(String name, String machine) =>
      _update(name, CodespaceUpdateSpec(machine: machine));

  Future<void> _update(String name, CodespaceUpdateSpec spec) async {
    if (state.token.isEmpty) return;
    state = state.copyWith(busyNames: {...state.busyNames, name}, clearError: true);
    try {
      final updated = await CodespacesClient(token: state.token).update(name, spec);
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        codespaces: [
          for (final item in state.codespaces)
            if (item.name == updated.name) updated else item,
        ],
        clearError: true,
      );
    } on CodespacesException catch (error) {
      if (!mounted) return;
      state = state.copyWith(busyNames: {...state.busyNames}..remove(name), error: error.message);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busyNames: {...state.busyNames}..remove(name),
        error: _l10n.codespacesNetworkError('$error'),
      );
    }
  }


}