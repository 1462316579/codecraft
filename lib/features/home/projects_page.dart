import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../agent/chat_controller.dart';
import '../../agent/models/chat_session.dart';
import '../../agent/models/project.dart';
import '../../agent/projects_controller.dart';
import '../../agent/sessions_controller.dart';
import '../../agent/tools/workspace.dart';
import '../../app/shell.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ids.dart';
import '../../data/container/external_storage.dart';
import '../../data/installed_apps.dart';
import '../../data/novel_project.dart';
import '../../data/workspaces.dart';
import 'installed_apps_page.dart';
import 'novel_create_sheet.dart';
import '../../l10n/app_localizations.dart';

/// 「项目」页签:项目列表。默认为空,右上角加号新建。
///
/// 列表行布局对齐上游 AppItem:48dp 圆角图标 + 加粗标题 + 两行次要信息 + 右侧标签。
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key, required this.onOpenProject});

  /// 打开项目:进入该项目的会话(由外壳切换到聊天)。
  final void Function(Project project) onOpenProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.tabProjects),
        actions: [
          IconButton(
            tooltip: l10n.projectNew,
            icon: const Icon(Iconfont.plus, size: 20),
            onPressed: () => _pickKind(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.light
                    ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                    : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
              ),
            ),
          ),
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
            data: (projects) {
              if (projects.isEmpty) {
                return _EmptyState(onCreate: () => _pickKind(context, ref));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(projectsProvider);
                  await ref.read(projectsProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    Spacing.md,
                    MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.sm,
                    Spacing.md,
                    Spacing.sm,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _GlassProjectRow(
                      project: project,
                      onTap: () => onOpenProject(project),
                      onLongPress: () => _showActions(context, ref, project),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  Future<void> _pickKind(BuildContext context, WidgetRef ref) async {
    final kind = await showModalBottomSheet<ProjectKind>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.semantic.cardSurface,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _KindItem(
                icon: Iconfont.code,
                title: l10n.projectKindCoding,
                description: l10n.projectKindCodingDesc,
                onTap: () => Navigator.pop(sheetContext, ProjectKind.coding),
              ),
              _KindItem(
                icon: Iconfont.pencil,
                title: l10n.projectKindWriting,
                description: l10n.projectKindWritingDesc,
                onTap: () => Navigator.pop(sheetContext, ProjectKind.writing),
              ),
              _KindItem(
                icon: Iconfont.binary,
                title: l10n.projectKindReverse,
                description: l10n.projectKindReverseDesc,
                onTap: () => Navigator.pop(sheetContext, ProjectKind.reverse),
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        );
      },
    );
    if (kind == null || !context.mounted) return;
    if (kind == ProjectKind.reverse) {
      await _createReverseProject(context, ref);
      return;
    }
    if (kind == ProjectKind.writing) {
      await _createWritingProject(context, ref);
      return;
    }
    await _createProject(context, ref, kind);
  }

  /// 新建「应用逆向」项目:先从已安装应用里选目标。
  ///
  /// 项目名直接用应用名;图标/包名/版本存进项目,列表行按应用信息展示。
  Future<void> _createReverseProject(BuildContext context, WidgetRef ref) async {
    final app = await Navigator.of(context).push<InstalledApp>(
      MaterialPageRoute(builder: (_) => const InstalledAppsPage()),
    );
    if (app == null || !context.mounted) return;
    // 图标直接在选应用时取一次存进项目(48dp PNG 只有几 KB),
    // 不落盘:省掉文件生命周期,也不用依赖文档目录。
    final icon = await InstalledAppsService.appIcon(app.packageName);
    if (!context.mounted) return;
    await _createProjectWithApp(context, ref, ProjectKind.reverse, app, icon, app.label);
  }

  /// 新建项目:建项目 → 建它的第一条会话 → 进入聊天。
  ///
  /// 项目与会话是两层:这里建一个项目,并给它开一条初始会话;
  /// 之后在聊天页点加号只会在本项目内新增会话,不会再产生项目。
  /// 编程/写作项目不打断用户输入名称,按类型自动命名;要改可长按重命名。
  Future<void> _createProject(BuildContext context, WidgetRef ref, ProjectKind kind) async {
    final l10n = AppLocalizations.of(context);
    final projects = await ref.read(projectsProvider.future);
    if (!context.mounted) return;
    await _createProjectWithApp(
      context,
      ref,
      kind,
      null,
      null,
      _autoProjectName(projects, kind, l10n),
    );
  }

  /// 新建写作项目:新建小说(向导收集书名/类型/标签/每章字数)或选择已有小说,
  /// 再建项目并开首条会话。
  Future<void> _createWritingProject(BuildContext context, WidgetRef ref) async {
    final writingRoot = p.join(await ExternalStorage.primaryRoot(), writingWorkspaceName);
    if (!context.mounted) return;
    final selection = await showNovelCreateSheet(context, writingRoot: writingRoot);
    if (selection == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final mode = AgentMode.write;
    final title = selection.title;
    // 先确保小说目录脚手架存在(角色关联/小说资料/小说章节),再建项目。
    // 选择已有小说时是幂等补全:只补缺失结构,不覆盖已有内容。
    try {
      await NovelScaffold.create(writingRoot, title);
    } catch (_) {
      // 目录创建失败不阻断项目创建;用户可在文件页或设置中授权后重试。
    }

    // 同名写作项目已存在时直接打开,避免同一本小说出现多个项目。
    final projects = await ref.read(projectsProvider.future);
    if (!context.mounted) return;
    final existing = projects
        .where((project) => project.kind == ProjectKind.writing && project.name == title)
        .firstOrNull;
    if (existing != null) {
      onOpenProject(existing);
      return;
    }

    final project = await ref.read(projectsProvider.notifier).create(
          name: title,
          mode: mode,
          kind: ProjectKind.writing,
        );
    final session = await ref.read(sessionsProvider.notifier).create(
          mode: mode,
          projectId: project.id,
        );
    if (!context.mounted) return;
    // 把新建小说时收集的设定作为首条消息发送给 AI;已有小说则提示先读资料再续写。
    final spec = selection.spec;
    final brief = spec == null
        ? l10n.novelExistingBrief(title)
        : <String>[
            l10n.novelBriefTitle(spec.title),
            if (spec.gender != null && spec.gender!.isNotEmpty) spec.gender!,
            if (spec.tags.isNotEmpty) l10n.novelBriefTags(spec.tags.join('、')),
            if (spec.wordsPerChapter != null)
              l10n.novelBriefWords('${spec.wordsPerChapter}'),
          ].join('\n');
    // 异步发送,不阻塞打开聊天页;失败时用户仍可在输入框看到文本(由 controller 兜底)。
    unawaited(ref.read(chatControllerProvider(session.id).notifier).send(brief));
    onOpenProject(project.copyWith());
    ref.read(selectedSessionProvider.notifier).state = session.id;
  }

  /// 自动项目名:「编程 1」「写作 2」——按类型取第一个没被占用的序号。
  String _autoProjectName(List<Project> projects, ProjectKind kind, AppLocalizations l10n) {
    final base = kind == ProjectKind.writing ? l10n.projectKindWriting : l10n.projectKindCoding;
    final used = {for (final project in projects) project.name.trim()};
    var index = 1;
    while (used.contains('$base $index')) {
      index++;
    }
    return '$base $index';
  }

  /// 实际落盘:建项目(逆向项目带应用元数据)→ 首条会话 → 进入聊天。
  Future<void> _createProjectWithApp(
    BuildContext context,
    WidgetRef ref,
    ProjectKind kind,
    InstalledApp? app,
    Uint8List? appIcon,
    String fallbackName,
  ) async {
    final writing = kind == ProjectKind.writing;
    final mode = writing ? AgentMode.write : AgentMode.build;
    final project = await ref.read(projectsProvider.notifier).create(
          name: app?.label ?? fallbackName,
          mode: mode,
          kind: kind,
          appPackage: app?.packageName,
          appName: app?.label,
          appVersionName: app?.versionName,
          appVersionCode: app?.versionCode,
          appIcon: appIcon,
          appApkPath: app?.apkPath,
          appApkPaths: app?.apkPaths ?? const [],
        );
    final session = await ref.read(sessionsProvider.notifier).create(
          mode: mode,
          projectId: project.id,
        );
    // 编程项目按项目名隔离工作区:先建好目录,否则文件页一打开就报目录不存在。
    if (kind == ProjectKind.coding) {
      try {
        final root = ref.read(workspaceProvider).rootPath;
        await Directory(p.join(root, project.name)).create(recursive: true);
      } catch (_) {
        // 建目录失败不阻断项目创建;文件页读取时会再补建一次。
      }
    }
    if (!context.mounted) return;
    onOpenProject(project.copyWith());
    // 新项目的首条会话直接进入,避免用户再点一次。
    ref.read(selectedSessionProvider.notifier).state = session.id;
  }

  /// 项目重命名后同步移动工作区目录,避免项目仍指向旧目录导致文件「消失」。
  Future<void> _syncWorkspaceDir(
    WidgetRef ref,
    Project project,
    String oldName,
    String newName,
  ) async {
    // 逆向项目的工作区按项目 id 命名,与项目名无关。
    if (project.kind == ProjectKind.reverse) return;
    try {
      final String base;
      if (project.kind == ProjectKind.writing) {
        final workspaces = await ref.read(workspacesProvider.future);
        final external = workspaces.workspaces.where((w) => w.isExternal).firstOrNull;
        if (external == null) return;
        base = external.path;
      } else {
        base = ref.read(workspaceProvider).rootPath;
      }
      final from = project.kind == ProjectKind.writing
          ? writingProjectDir(base, oldName)
          : p.join(base, oldName);
      final to = project.kind == ProjectKind.writing
          ? writingProjectDir(base, newName)
          : p.join(base, newName);
      if (from == to) return;
      final source = Directory(from);
      if (!await source.exists()) return;
      // 目标已存在(同名项目)时不覆盖,保留原目录。
      if (await Directory(to).exists()) return;
      await source.rename(to);
    } catch (_) {
      // 移动失败不影响重命名本身;文件页会按新名称补建目录。
    }
  }

  /// 长按项目:重命名 / 删除。
  Future<void> _showActions(BuildContext context, WidgetRef ref, Project project) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.semantic.cardSurface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconfont.pencil, size: 20),
              title: Text(l10n.rename),
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            ListTile(
              leading: Icon(Iconfont.trash2, size: 20, color: Theme.of(context).colorScheme.error),
              title: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'rename') {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _ProjectNameDialog(
          title: l10n.rename,
          hint: l10n.workspaceNameHint,
          initial: project.name,
          confirm: l10n.confirm,
          cancel: l10n.cancel,
        ),
      );
      if (name == null || name.trim().isEmpty) return;
      final oldName = project.name;
      final newName = name.trim();
      await ref.read(projectsProvider.notifier).rename(project.id, newName);
      await _syncWorkspaceDir(ref, project, oldName, newName);
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.delete),
          content: Text(l10n.projectDeleteConfirm(project.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(projectsProvider.notifier).remove(project.id);
      if (ref.read(selectedProjectProvider) == project.id) {
        ref.read(selectedProjectProvider.notifier).state = null;
        ref.read(selectedSessionProvider.notifier).state = null;
      }
    }
  }
}

/// 项目命名弹窗(新建与重命名共用)。
class _ProjectNameDialog extends StatefulWidget {
  const _ProjectNameDialog({
    required this.title,
    required this.hint,
    required this.confirm,
    required this.cancel,
    this.initial,
  });

  final String title;
  final String hint;
  final String confirm;
  final String cancel;
  final String? initial;

  @override
  State<_ProjectNameDialog> createState() => _ProjectNameDialogState();
}

class _ProjectNameDialogState extends State<_ProjectNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}

/// 新建类型选项行(图标 + 标题 + 描述)。
class _KindItem extends StatelessWidget {
  const _KindItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: context.semantic.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 项目行(液态柔光玻璃卡片)。
class _GlassProjectRow extends StatelessWidget {
  const _GlassProjectRow({
    required this.project,
    required this.onTap,
    required this.onLongPress,
  });

  final Project project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final bright = theme.brightness == Brightness.light;
    final isReverse = project.kind == ProjectKind.reverse;
    final writing = project.mode == AgentMode.write;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: bright ? 0.5 : 0.14),
                Colors.white.withValues(alpha: bright ? 0.2 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(
              width: 1,
              color: Colors.white.withValues(alpha: bright ? 0.55 : 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.violet.withValues(alpha: bright ? 0.06 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            leading: isReverse
                ? _ProjectAppIcon(bytes: project.appIcon, label: project.appName ?? project.name)
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.22),
                          theme.colorScheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 0.5,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      writing ? Iconfont.pencil : Iconfont.code,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
            title: Text(
              project.name.trim().isEmpty ? l10n.projectUntitled : project.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: isReverse
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.appPackage ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        project.appVersionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        writing ? l10n.projectKindWriting : l10n.projectKindCoding,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatDate(project.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }
}

/// 空态(液态柔光玻璃卡片)。
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bright = theme.brightness == Brightness.light;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: bright ? 0.45 : 0.12),
                  Colors.white.withValues(alpha: bright ? 0.16 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(
                width: 1,
                color: Colors.white.withValues(alpha: bright ? 0.5 : 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Brand.violet.withValues(alpha: bright ? 0.06 : 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconfont.folderOpen, size: 48, color: context.semantic.subtleText),
                  const SizedBox(height: 10),
                  Text(
                    l10n.projectListEmpty,
                    style: TextStyle(fontSize: 14, color: context.semantic.subtleText),
                  ),
                  const SizedBox(height: Spacing.md),
                  FilledButton.tonal(onPressed: onCreate, child: Text(l10n.projectNew)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 逆向项目的应用图标(建项目时存入);缺失时用首字母占位。
class _ProjectAppIcon extends StatelessWidget {
  const _ProjectAppIcon({required this.bytes, required this.label});

  final Uint8List? bytes;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: bytes == null
          ? _fallback(theme)
          : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }

  Widget _fallback(ThemeData theme) => Center(
        child: Text(
          label.isEmpty ? '?' : label.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
}
