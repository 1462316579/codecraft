import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/workspaces.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/floating_tab_bar.dart';
import '../../core/ui/settings_group.dart';
import '../../data/credentials.dart';
import '../../data/git/container_git.dart';
import '../../l10n/app_localizations.dart';

/// 凭据与署名页(对齐上游 `CredentialScreen`):底部悬浮 tab 切「署名」与「凭据」两个标签页。
/// 顶栏「+」新增凭据,编辑/新增用同一弹层。
class CredentialPage extends ConsumerStatefulWidget {
  const CredentialPage({super.key, this.onNavigateBack});

  final VoidCallback? onNavigateBack;

  @override
  ConsumerState<CredentialPage> createState() => _CredentialPageState();
}

class _CredentialPageState extends ConsumerState<CredentialPage> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // 每次进入重新读署名:用户可能在终端改过项目级/全局署名。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(gitIdentityProvider);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save(GitCredential credential) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(credentialStoreProvider).save(credential);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(credentialsProvider);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.credentialToastSaved)));
  }

  Future<void> _delete(GitCredential credential) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(credentialStoreProvider).delete(credential.id);
    if (!mounted) return;

    ref.invalidate(credentialsProvider);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.credentialToastDeleted)));
  }

  Future<void> _openEditorFromItem(GitCredential initial) => _openEditor(initial);

  Future<void> _openEditor(GitCredential? initial) async {
    final l10n = AppLocalizations.of(context);
    final hostController = TextEditingController(
      text: (initial == null || initial.host == defaultCredentialHost) ? '' : initial.host,
    );
    final usernameController = TextEditingController(text: initial?.username ?? '');
    final tokenController = TextEditingController(text: initial?.token ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CredentialEditorSheet(
        hostController: hostController,
        usernameController: usernameController,
        tokenController: tokenController,
        title: initial == null ? l10n.credentialAdd : l10n.credentialEdit,
      ),
    );
    final host = hostText(hostController.text);
    final username = usernameController.text.trim();
    final token = tokenController.text.trim();
    // Bottom sheet 退出动画可能仍在运行,延后一帧再释放,避免在 TextField 仍挂载时 dispose。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hostController.dispose();
      usernameController.dispose();
      tokenController.dispose();
    });
    if (saved ?? false) {
      await _save(GitCredential(
        host: host.isEmpty ? defaultCredentialHost : host,
        // 用户名不再询问:留空即由远端主机推导(GitHub 用 x-access-token,其余用 oauth2)。
        username: username,
        token: token,
      ));
    }
  }

  /// 规范化主机输入:去协议前缀、去路径、转小写;空串表示「所有主机」。
  String hostText(String raw) {
    var host = raw.trim().toLowerCase();
    host = host.replaceFirst(RegExp(r'^https?://'), '');
    final slash = host.indexOf('/');
    if (slash > 0) host = host.substring(0, slash);
    return host;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final credentialsAsync = ref.watch(credentialsProvider);
    final credentials = credentialsAsync.valueOrNull ?? const <GitCredential>[];

    return Scaffold(
      backgroundColor: context.semantic.pageBackground,
      appBar: AppBar(
        backgroundColor: context.semantic.pageBackground,
        title: Text(l10n.gitCredentialsAndIdentity),
        leading: IconButton(
          onPressed: widget.onNavigateBack ?? () => Navigator.of(context).maybePop(),
          tooltip: l10n.back,
          icon: const Icon(Iconfont.arrowLeft),
        ),
        actions: [
          IconButton(
            onPressed: () => _openEditor(null),
            tooltip: l10n.credentialAdd,
            icon: const Icon(Iconfont.plus),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _page = page),
            children: [
              _IdentityTab(),
              credentials.isEmpty
                  ? _EmptyCredentials(onManualAdd: () => _openEditor(null))
                  : _CredentialList(
                      credentials: credentials,
                      onEdit: _openEditorFromItem,
                      onDelete: _delete,
                    ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingTabBar(
              controller: _pageController,
              page: _page,
              items: [
                FloatingTabItem(icon: Iconfont.user, label: l10n.gitTabIdentity),
                FloatingTabItem(icon: Iconfont.key, label: l10n.gitTabCredentials),
              ],
              maskColor: context.semantic.pageBackground,
              onSelect: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 署名页:user.name / user.email / 仓库地址,保存到容器 git config。
class _IdentityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_IdentityTab> createState() => _IdentityTabState();
}

class _IdentityTabState extends ConsumerState<_IdentityTab> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _repoUrl = TextEditingController();
  String? _lastIdentityKey;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _repoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final git = ref.read(containerGitProvider);
    final workspace = ref.read(currentWorkspaceProvider).rootPath;
    await git.setUserIdentity(workspace, _name.text.trim(), _email.text.trim());
    if (_repoUrl.text.trim().isNotEmpty) {
      await git.setRepoUrl(workspace, _repoUrl.text.trim());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.credentialToastIdentitySaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final identityAsync = ref.watch(gitIdentityProvider);
    final identity = identityAsync.valueOrNull;

    if (identity != null) {
      final key = '${identity.name}\t${identity.email}\t${identity.repoUrl}';
      if (_lastIdentityKey != key) {
        _lastIdentityKey = key;
        _name.text = identity.name;
        _email.text = identity.email;
        _repoUrl.text = identity.repoUrl;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 70),
      children: [
        SettingsGroupHeader(text: l10n.gitIdentityTitle),
        if (identity?.globalName != null && identity!.globalName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xs),
            child: Text(
              identity.globalName!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.semantic.subtleText,
              ),
            ),
          ),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'user.name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'user.email', border: OutlineInputBorder()),
        ),
        const SizedBox(height: Spacing.xl),
        SettingsGroupHeader(text: l10n.gitRepoUrlTitle),
        TextField(
          controller: _repoUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.gitRemoteUrl, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: Spacing.xs),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.mdLarge),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconfont.check, size: 17),
                const SizedBox(width: Spacing.sm),
                Text(
                  l10n.save,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 凭据列表:左平台图标 + 主机/用户名 + 品牌徽章,右划删除,点击编辑。
class _CredentialList extends StatelessWidget {
  const _CredentialList({
    required this.credentials,
    required this.onEdit,
    required this.onDelete,
  });

  final List<GitCredential> credentials;
  final ValueChanged<GitCredential> onEdit;
  final ValueChanged<GitCredential> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 70),
      children: [
        const SizedBox(height: Spacing.sm),
        Text(
          l10n.gitCredentialsCount(credentials.length),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: context.semantic.subtleText,
              ),
        ),
        const SizedBox(height: Spacing.xs),
        SettingsGroup(
          children: [
            for (var index = 0; index < credentials.length; index++) ...[
              if (index > 0) const SettingsDivider(),
              _CredentialItem(
                credential: credentials[index],
                onEdit: () => onEdit(credentials[index]),
                onDelete: () => onDelete(credentials[index]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CredentialItem extends StatelessWidget {
  const _CredentialItem({required this.credential, required this.onEdit, required this.onDelete});

  final GitCredential credential;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    // 通用令牌(主机为 *)在列表里显示为「所有主机」,而不是一个星号。
    final universal = credential.host == defaultCredentialHost;
    return InkWell(
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      universal || credential.host.contains('github')
                          ? Iconfont.github
                          : Iconfont.key,
                      size: 22,
                      color: subtle,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                universal ? l10n.credentialAllHosts : credential.host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            if (!universal) ...[
                              const SizedBox(width: Spacing.xs),
                              _HostBadge(host: credential.host),
                            ],
                          ],
                        ),
                        Text(
                          credential.username.isEmpty
                              ? l10n.credentialUsernameAuto
                              : credential.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
                        ),
                      ],
                    ),
                  ),
                  Icon(Iconfont.chevronRight, size: 18, color: subtle),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: Theme.of(context).platform == TargetPlatform.iOS ? '删除' : '删除',
            icon: Icon(Iconfont.trash2, size: 18, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}

/// 远程主机品牌徽章:按 host 识别常见 Git 托管服务,未知取首段域名首字母大写。
class _HostBadge extends StatelessWidget {
  const _HostBadge({required this.host});

  final String host;

  static String label(String host) {
    final clean = host
        .replaceFirst(RegExp(r'^https://'), '')
        .replaceFirst(RegExp(r'^http://'), '')
        .split('/')
        .first
        .split(':')
        .first;
    return switch (clean) {
      _ when clean.contains('github') => 'GitHub',
      _ when clean.contains('gitlab') => 'GitLab',
      _ when clean.contains('gitee') => 'Gitee',
      _ when clean.contains('bitbucket') => 'Bitbucket',
      _ when clean.contains('codeberg') => 'Codeberg',
      _ when clean.contains('azure') || clean.contains('visualstudio') => 'Azure DevOps',
      _ => clean.split('.').first.isEmpty
          ? clean
          : clean.split('.').first[0].toUpperCase() + clean.split('.').first.substring(1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label(host),
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// 凭据列表空态:图标 + 标题/描述 + 快捷登录 / 手动添加两按钮。
class _EmptyCredentials extends StatelessWidget {
  const _EmptyCredentials({required this.onManualAdd});

  final VoidCallback onManualAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: context.semantic.cardSurface,
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.mdLarge),
                ),
                child: Icon(Iconfont.key, size: 26, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                l10n.credentialEmptyTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                l10n.credentialEmptyDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: onManualAdd,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.mdLarge),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconfont.pencil, size: 16),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        l10n.credentialAdd,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 手动添加/编辑凭据弹层:主机 + 用户名 + 令牌。
class _CredentialEditorSheet extends StatelessWidget {
  const _CredentialEditorSheet({
    required this.hostController,
    required this.usernameController,
    required this.tokenController,
    required this.title,
  });

  final TextEditingController hostController;
  final TextEditingController usernameController;
  final TextEditingController tokenController;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: hostController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.credentialHostOptional,
                hintText: l10n.credentialHostAny,
                helperText: l10n.credentialHostHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: usernameController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: tokenController,
              obscureText: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.credentialToken,
                helperText: l10n.credentialTokenHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () {
                  if (tokenController.text.trim().isEmpty) return;
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.mdLarge),
                  ),
                ),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 署名页读取:当前仓库 identity + 全局 user.name(供「终端可改」提示行)。
class GitIdentityView {
  const GitIdentityView({
    required this.name,
    required this.email,
    required this.repoUrl,
    this.globalName,
  });

  final String name;
  final String email;
  final String repoUrl;
  final String? globalName;
}

final gitIdentityProvider = FutureProvider<GitIdentityView>((ref) async {
  final git = ref.watch(containerGitProvider);
  final workspace = ref.watch(currentWorkspaceProvider).rootPath;
  try {
    final identity = await git.identity(workspace);
    final repoUrl = await git.getRepoUrl(workspace);
    return GitIdentityView(
      name: identity.name,
      email: identity.email,
      repoUrl: repoUrl,
      globalName: await git.getUserName(workspace),
    );
  } catch (_) {
    return const GitIdentityView(name: '', email: '', repoUrl: '');
  }
});
