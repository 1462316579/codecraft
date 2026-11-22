import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/text_input_dialog.dart';
import '../../core/util/git_ignore_matcher.dart';
import '../../data/container/external_storage.dart';
import '../../data/workspace_files.dart';
import '../../agent/models/project.dart';
import '../../app/shell.dart';
import '../../core/util/window_size.dart';
import '../../data/apk_workspace.dart';
import '../../data/editor_target.dart';
import '../reverse/reverse_routes.dart';
import '../../data/workbench.dart';
import '../../data/workspaces.dart';
import '../../data/novel_project.dart';
import '../../g11n/app_globalizations.dart';
import 'file_type_icon.dart';

/// 文件树只有一个根:当前工作区(编程 = 项目目录,写作 = AI小说/<小说名>)。

/// 侧边栏「文件」Tab:
/// 只展示**当前工作区**一棵树(开发模式 → workspace,写作模式 → AI 写作目录),
/// 就地展开、按文件类型图标、`.gitignore` 忽略态、复制/剪切/粘贴、
/// 新建/重命名/删除、横向滚动与行内加载态。
class FileTreeTab extends ConsumerStatefulWidget {
  const FileTreeTab({super.key});

  @override
  ConsumerState<FileTreeTab> createState() => _FileTreeTabState();
}

/// 剪贴板:一次只持有一项,复制或剪切后待粘贴。
class _Clipboard {
  const _Clipboard({required this.sourcePath, required this.name, required this.isCut});

  final String sourcePath;
  final String name;
  final bool isCut;
}

/// 一个可见节点(已按展开状态扁平化,携带缩进层级)。
class _Node {
  const _Node({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.depth,
    this.isRoot = false,
    this.isExpanded = false,
    this.hasError = false,
    this.ignored = false,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int depth;

  /// 是否是树根(根节点不提供复制/剪切/重命名/删除)。
  final bool isRoot;
  final bool isExpanded;
  final bool hasError;
  final bool ignored;
}

class _FileTreeTabState extends ConsumerState<FileTreeTab> with WidgetsBindingObserver {
  final _expanded = <String>{};
  final _children = <String, List<DirEntry>>{};
  final _dirErrors = <String>{};
  final _busy = <String>{};
  _Clipboard? _clipboard;
  String? _expandingPath;
  String? _loadedRoot;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  /// 旧写作布局迁移只在每个工作区首次加载时尝试一次。
  bool _legacyMigrated = false;
  /// 外部工作区是否缺少「所有文件访问权限」(缺少时可能只看到目录、看不到文件)。
  bool _externalNoAccess = false;
  List<String> _ignorePatterns = const [];

  /// 树根的显示名(工作区名,如 `workspace` 或 `AI小说`)。
  String _workspaceLabel = 'workspace';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统「所有文件访问权限」设置页返回后自动重读,不必用户再手动刷新。
    final root = _loadedRoot;
    if (state == AppLifecycleState.resumed && root != null && _externalNoAccess) {
      _refresh(root);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    // 逆向项目的工作区就是目标 APK 解出来的目录(与 Agent 工具同一来源)。
    final project = ref.watch(currentProjectProvider);
    final reverse = project?.kind == ProjectKind.reverse;
    if (reverse) {
      final apkPath = project!.appApkPath;
      if (apkPath == null || apkPath.isEmpty) {
        return _hint(g11n.apkPathUnavailable);
      }
      final ready = ref.watch(apkWorkspaceReadyProvider(project.id)).valueOrNull;
      if (ready != true) {
        return _apkPrompt(g11n, project);
      }
      _workspaceLabel = 'APK';
    } else {
      _workspaceLabel = ref.watch(currentWorkspaceInfoProvider)?.name ?? 'workspace';
    }
    final root = ref.watch(currentWorkspaceProvider).rootPath;
    final rootChanged = _loadedRoot != root;
    if (rootChanged) {
      // 根目录换了,旧的展开状态与缓存都不再属于当前树,必须清空。
      _expanded.clear();
      _children.clear();
      _dirErrors.clear();
      _legacyMigrated = false;
      _loadedRoot = root;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh(root);
      });
    }

    final nodes = _buildTree(root);

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: Spacing.xs),
            // 外部工作区缺「所有文件访问权限」时可能只列出目录、看不到文件,
            // 这里给一条常驻提示(而不是等到读目录失败才出现)。
            if (_externalNoAccess && _error == null) _permissionBanner(g11n, root),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            if (_needsStoragePermission(root)) ...[
                              const SizedBox(height: Spacing.sm),
                              Text(
                                g11n.fileBrowserNeedPermission,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.semantic.subtleText,
                                    ),
                              ),
                              const SizedBox(height: Spacing.md),
                              FilledButton(
                                onPressed: () async {
                                  await ExternalStorage.requestAllFilesAccess();
                                  if (!mounted) return;
                                  await _refresh(root);
                                },
                                child: Text(g11n.storagePermissionGrant),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : _loading && nodes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildList(nodes, root),
            ),
          ],
        ),
        // 右上角操作排:剪贴板指示器 + 操作中转圈 + 刷新(对齐上游)。
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_clipboard != null)
                _ClipboardIndicator(
                  clipboardLabel: _clipboard!.isCut
                      ? g11n.fileBrowserClipboardCut
                      : g11n.fileBrowserClipboardCopy,
                  name: _clipboard!.name,
                  onClear: () => setState(() => _clipboard = null),
                ),
              if (_busy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.xs),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              IconButton(
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: context.semantic.subtleText,
                tooltip: g11n.fileBrowserRefresh,
                icon: const Icon(Iconfont.refreshCw),
                onPressed: () => _refresh(root),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 整棵树统一横向滚动:先估最宽行,再让每行取同一宽度。
  Widget _buildList(List<_Node> nodes, String root) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final estimated = nodes.isEmpty
        ? 0.0
        : nodes
            .map((n) => n.depth * Spacing.lg + _displayWidth(n.name) * 8 + 64)
            .reduce((a, b) => a > b ? a : b);
    // 横向滚动容器里的子树宽度无界,必须显式给宽度,否则 ListView 无法布局。
    final rowWidth = estimated > viewportWidth ? estimated : viewportWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: rowWidth,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            return _FileRow(
              node: node,
              style: style,
              expanding: node.isDirectory && node.path == _expandingPath,
              busy: _busy.contains(node.path),
              onTap: () => _onTap(node, root),
              onLongPress: () => _showActions(node),
            );
          },
        ),
      ),
    );
  }

  /// 粗估文本宽度(CJK 记 2 个字符宽):只用于给横向滚动留够空间。
  static int _displayWidth(String text) {
    var width = 0;
    for (final rune in text.runes) {
      width += rune > 0x2E80 ? 2 : 1;
    }
    return width;
  }

  /// 扁平化可见节点:工作区根一行,已展开的目录插入其子项。
  List<_Node> _buildTree(String root) {
    final nodes = <_Node>[];
    // 根节点始终展开,首次加载后子文件即时可见。
    const expanded = true;
    nodes.add(_Node(
      path: root,
      name: _workspaceLabel,
      isDirectory: true,
      depth: 0,
      isRoot: true,
      isExpanded: expanded,
    ));
    if (expanded) {
      _appendChildren(nodes, root, 1, const [], root);
    }
    return nodes;
  }

  /// 把 [dir] 的子项追加进 [nodes](递归处理已展开的子目录)。
  void _appendChildren(
    List<_Node> nodes,
    String dir,
    int depth,
    List<String> relParts,
    String workspaceRoot,
  ) {
    final children = _children[dir];
    if (children == null) return;
    for (final entry in children) {
      final path = dir == '/' ? '/${entry.name}' : p.join(dir, entry.name);
      final parts = [...relParts, entry.name];
      final ignored = _ignorePatterns.isNotEmpty &&
          GitIgnoreMatcher.isIgnored(_ignorePatterns, parts);
      final open = entry.isDirectory && _expanded.contains(path);
      nodes.add(_Node(
        path: path,
        name: entry.name,
        isDirectory: entry.isDirectory,
        depth: depth,
        isExpanded: open,
        hasError: open && _dirErrors.contains(path),
        ignored: ignored,
      ));
      if (open && !_dirErrors.contains(path)) {
        _appendChildren(nodes, path, depth + 1, parts, workspaceRoot);
      }
    }
  }

  Future<void> _refresh(String root) async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // 工作区目录可能尚未创建(历史项目或创建时 IO 失败):先补建再列举,
      // 否则 Directory.list 会直接抛 PathNotFoundException。
      await _ensureRoot(root);
      final external = _isExternalWorkspace(root);
      // 外部目录可能「列得出目录、读不到文件」,这里顺带把权限状态反馈给界面。
      final noAccess = external && !await ExternalStorage.hasAccess();
      if (!mounted) return;
      if (noAccess != _externalNoAccess) {
        setState(() => _externalNoAccess = noAccess);
        // 权限从无到有:让旧布局迁移再试一次(没有权限时迁移只能白跑)。
        if (!noAccess) _legacyMigrated = false;
      }
      // 旧写作布局(工作区根直接是「AI小说」)遗留的章节/资料搬进当前小说目录,
      // 否则文件树只看新目录,旧内容永远看不到。每个工作区只尝试一次。
      if (!_legacyMigrated && external && !noAccess) {
        _legacyMigrated = true;
        try {
          await NovelScaffold.migrateLegacyLayout(p.dirname(root), p.basename(root));
        } catch (_) {
          // 迁移是尽力而为:失败不影响后面的正常列目录。
        }
        if (!mounted) return;
      }
      _ignorePatterns = await _loadGitignore(root).timeout(
        const Duration(seconds: 8),
        onTimeout: () => const [],
      );
      await _loadDir(root).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          if (mounted) {
            setState(() => _error =
                '加载超时，请重试');
          }
        },
      );
      // 已展开的子树一并重读(远端没有文件变更通知,只能靠刷新)。
      for (final dir in _expanded.toList()) {
        if (dir == root) continue;
        await _loadDir(dir).timeout(
          const Duration(seconds: 20),
          onTimeout: () {},
        );
        if (!mounted) return;
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 确保工作区根目录存在(缺失时补建)。
  ///
  /// 权限不足、远端不可用等情况静默跳过,交给随后的读取报错与授权提示处理。
  Future<void> _ensureRoot(String root) async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      await files.createDir(root);
    } catch (_) {}
  }

  /// 读工作区根 `.gitignore`(只处理根级,不处理嵌套);读不到返回空。
  Future<List<String>> _loadGitignore(String root) async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      if (!await files.exists(p.join(root, '.gitignore'))) return const [];
      return GitIgnoreMatcher.parse(await files.readText(p.join(root, '.gitignore')));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadDir(String dir) async {
    try {
      final files = await ref.read(workspaceFilesProvider.future).timeout(
        const Duration(seconds: 45),
      );
      final entries = await files.listDir(dir).timeout(
        const Duration(seconds: 60),
      );
      // 文件系统的 readdir 可能重复返回同一条目,按名字去重(与上游一致)。
      final seen = <String>{};
      final unique = [
        for (final entry in entries)
          if (seen.add(entry.name)) entry,
      ]..sort((a, b) {
          if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      if (!mounted) return;
      setState(() {
        _children[dir] = unique;
        _dirErrors.remove(dir);
        // 首次成功读取根目录后自动展开根节点,否则用户只能看到根目录名而看不到子文件。
        if (dir == _loadedRoot) _expanded.add(dir);
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _dirErrors.add(dir));
      if (dir == _loadedRoot) setState(() => _error = '加载超时，请重试');
    } catch (error) {
      if (!mounted) return;
      setState(() => _dirErrors.add(dir));
      // 工作区根读失败整体报错;子目录失败只标红该行(对齐上游)。
      if (dir == _loadedRoot) {
        final detail = '$error'.trim();
        setState(() => _error = detail.isEmpty
            ? AppGlobalizations.of(context).fileBrowserError
            : '${AppGlobalizations.of(context).fileBrowserError}\n$detail');
      }
    }
  }

  bool _extracting = false;
  String? _apkError;

  /// 逆向项目的 APK 还没解压:给出说明与解压入口。
  Widget _apkPrompt(AppGlobalizations g11n, Project project) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconfont.package, size: 32, color: context.semantic.subtleText),
            const SizedBox(height: Spacing.md),
            Text(
              g11n.apkExtractHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semantic.subtleText,
                  ),
            ),
            const SizedBox(height: Spacing.md),
            if (_extracting) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: Spacing.sm),
              Text(g11n.apkExtracting, style: Theme.of(context).textTheme.bodySmall),
            ] else
              FilledButton(
                onPressed: () => _extractApk(project),
                child: Text(g11n.apkExtractAction),
              ),
            if (_apkError != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                g11n.apkExtractFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                _apkError!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: context.semantic.subtleText,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _extractApk(Project project) async {
    setState(() {
      _extracting = true;
      _apkError = null;
    });
    try {
      await ref.read(apkWorkspaceProvider).ensureExtracted(project);
      if (!mounted) return;
      setState(() => _extracting = false);
      ref.invalidate(apkWorkspaceReadyProvider(project.id));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _apkError = error.toString();
      });
    }
  }

  Widget _hint(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.semantic.subtleText,
                ),
          ),
        ),
      );

  /// 当前工作区是否是需要外部存储权限的外部目录。
  ///
  /// 用「路径不在应用私有目录下」判断,而不是查权限:用户也可能用 SAF 只授权了
  /// 某个子树,此时全文件访问权限仍是 false,但目录能正常读写。
  bool _needsStoragePermission(String root) {
    final workspace = ref.watch(currentWorkspaceInfoProvider);
    if (workspace == null || !workspace.isExternal) return false;
    return !root.startsWith('/data/');
  }

  /// 同上,但可在异步流程里调用(不能用 `ref.watch`)。
  bool _isExternalWorkspace(String root) {
    final workspace = ref.read(currentWorkspaceInfoProvider);
    if (workspace == null || !workspace.isExternal) return false;
    return !root.startsWith('/data/');
  }

  /// 外部工作区缺少「所有文件访问权限」时的顶部提示条。
  Widget _permissionBanner(AppGlobalizations g11n, String root) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      padding: const EdgeInsets.only(left: Spacing.sm, right: Spacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              g11n.fileBrowserNeedPermission,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.semantic.subtleText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ExternalStorage.requestAllFilesAccess();
              if (!mounted) return;
              await _refresh(root);
            },
            child: Text(g11n.storagePermissionGrant),
          ),
        ],
      ),
    );
  }

  Future<void> _onTap(_Node node, String root) async {
    if (node.isDirectory) {
      await _toggleExpand(node);
      return;
    }
    _openFile(node);
  }

  /// 展开/折叠;折叠时连同所有后代一起移出展开集(避免再展开时意外深开)。
  Future<void> _toggleExpand(_Node node) async {
    if (_expandingPath == node.path) return;
    if (_expanded.contains(node.path)) {
      setState(() {
        _expanded.removeWhere(
          (path) => path == node.path || path.startsWith('${node.path}/'),
        );
      });
      return;
    }
    setState(() {
      _expanded.add(node.path);
      _expandingPath = node.path;
    });
    await _loadDir(node.path);
    if (!mounted) return;
    setState(() => _expandingPath = null);
  }

  /// 点文件:打开编辑器(宽屏进工作台右栏,窄屏跳整屏路由)。
  ///
  /// 逆向项目里 `.dex`/`.arsc` 走专门的分析页:它们不是文本,
  /// 交给普通编辑器只能看到「二进制文件不支持」。
  void _openFile(_Node node) {
    if (ref.read(currentProjectProvider)?.kind == ProjectKind.reverse) {
      final route = reverseRouteForPath(node.path);
      if (route != null) {
        context.push(reverseRouteWithPath(route, node.path));
        return;
      }
    }
    ref.read(editorTargetProvider.notifier).open(node.path);
    openWorkbench(context, ref, WorkbenchPaneKind.editor, isWideLayout(context));
  }

  /// 长按菜单:顺序与上游一致——粘贴到此处(有剪贴板且是目录)→ 新建 → 复制/剪切/重命名/删除。
  Future<void> _showActions(_Node node) async {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // 菜单项较多(粘贴/新建×2/复制/剪切/重命名/删除):矮屏下必须可滚动,
      // 否则 Column 会溢出。
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
              child: Text(
                node.name,
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_clipboard != null && node.isDirectory)
              _actionRow(sheetContext, Iconfont.clipboard, g11n.fileBrowserPasteHere,
                  'paste', tint: theme.colorScheme.primary),
            if (node.isDirectory) ...[
              _actionRow(sheetContext, Iconfont.filePlus, g11n.fileBrowserNewFile, 'newFile'),
              _actionRow(
                  sheetContext, Iconfont.folderPlus, g11n.fileBrowserNewFolder, 'newFolder'),
            ],
            if (!node.isDirectory && supportsArchiveExtraction(node.path))
              _actionRow(sheetContext, Iconfont.packageOpen, g11n.fileBrowserExtract, 'extract'),
            if (!node.isRoot) ...[
              _actionRow(sheetContext, Iconfont.copy, g11n.commonCopy, 'copy'),
              _actionRow(sheetContext, Iconfont.scissors, g11n.commonCut, 'cut'),
              _actionRow(sheetContext, Iconfont.edit2, g11n.rename, 'rename'),
              _actionRow(sheetContext, Iconfont.trash2, g11n.delete, 'delete',
                  destructive: true),
            ],
          ],
        ),
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'paste':
        await _paste(node);
      case 'newFile':
        await _create(node, isFile: true);
      case 'newFolder':
        await _create(node, isFile: false);
      case 'copy':
        setState(() => _clipboard =
            _Clipboard(sourcePath: node.path, name: node.name, isCut: false));
      case 'cut':
        setState(() => _clipboard =
            _Clipboard(sourcePath: node.path, name: node.name, isCut: true));
      case 'extract':
        await _extractArchive(node);
      case 'rename':
        await _rename(node);
      case 'delete':
        await _delete(node);
    }
  }

  Widget _actionRow(
    BuildContext sheetContext,
    IconData icon,
    String label,
    String value, {
    bool destructive = false,
    Color? tint,
  }) {
    final theme = Theme.of(sheetContext);
    final color = destructive ? theme.colorScheme.error : (tint ?? theme.colorScheme.onSurface);
    return InkWell(
      onTap: () => Navigator.pop(sheetContext, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Spacing.lg),
            Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _create(_Node node, {required bool isFile}) async {
    final g11n = AppGlobalizations.of(context);
    if (!_expanded.contains(node.path)) {
      setState(() => _expanded.add(node.path));
    }
    final name = await _promptName(
      title: isFile ? g11n.fileBrowserNewFile : g11n.fileBrowserNewFolder,
      confirmLabel: g11n.create,
    );
    if (name == null) return;
    final target = node.path == '/' ? '/$name' : p.join(node.path, name);
    await _mutate({target}, () async {
      final files = await ref.read(workspaceFilesProvider.future);
      if (await files.exists(target)) return false;
      if (isFile) {
        await files.writeText(target, '');
      } else {
        await files.createDir(target);
      }
      return true;
    }, failMessage: g11n.fileBrowserCreateFailed, parent: node.path);
  }

  Future<void> _rename(_Node node) async {
    final g11n = AppGlobalizations.of(context);
    final name = await _promptName(
      title: g11n.rename,
      confirmLabel: g11n.rename,
      initial: node.name,
    );
    if (name == null || name == node.name) return;
    final parent = node.path == '/' ? '/' : p.dirname(node.path);
    final target = parent == '/' ? '/$name' : p.join(parent, name);
    await _mutate({node.path}, () async {
      final files = await ref.read(workspaceFilesProvider.future);
      if (await files.exists(target)) return false;
      await files.rename(node.path, target);
      return true;
    }, failMessage: g11n.fileBrowserRenameFailed, parent: parent);
  }

  /// 解压:解到同目录下的同名文件夹(去掉压缩后缀)。目标已存在时先确认覆盖。
  Future<void> _extractArchive(_Node node) async {
    final g11n = AppGlobalizations.of(context);
    final parent = node.path == '/' ? '/' : p.dirname(node.path);
    final name = archiveTargetName(node.name);
    final dest = parent == '/' ? '/$name' : p.join(parent, name);

    try {
      final files = await ref.read(workspaceFilesProvider.future);
      if (await files.exists(dest)) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(g11n.fileBrowserExtractConflictTitle),
            content: Text(g11n.fileBrowserExtractConflict(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(g11n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(g11n.fileBrowserExtractOverwrite),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await files.delete(dest, recursive: true);
      }
    } catch (_) {
      // 目标探测失败按「不存在」继续,让真正的解压流程报错。
    }

    setState(() => _busy.add(node.path));
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      await files.extractArchive(node.path, dest);
      if (!mounted) return;
      await _loadDir(parent);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${g11n.fileBrowserExtractFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(node.path));
    }
  }

  Future<void> _delete(_Node node) async {
    final g11n = AppGlobalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.delete),
        content: Text(
          node.isDirectory
              ? g11n.fileBrowserDeleteFolderConfirm(node.name)
              : g11n.fileBrowserDeleteFileConfirm(node.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              g11n.delete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final parent = node.path == '/' ? '/' : p.dirname(node.path);
    await _mutate({node.path}, () async {
      final files = await ref.read(workspaceFilesProvider.future);
      await files.delete(node.path, recursive: node.isDirectory);
      return true;
    }, failMessage: g11n.fileBrowserDeleteFailed, parent: parent);
  }

  /// 粘贴:目标已存在同名项时弹窗询问是否覆盖;禁止粘到自身或其子孙。
  Future<void> _paste(_Node node) async {
    final g11n = AppGlobalizations.of(context);
    final clip = _clipboard;
    if (clip == null || !node.isDirectory) return;
    final target = node.path == '/' ? '/${clip.name}' : p.join(node.path, clip.name);
    // 粘到自身或自己的子目录里会无限递归。
    if (target == clip.sourcePath || target.startsWith('${clip.sourcePath}/')) return;

    var overwrite = false;
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      if (await files.exists(target)) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(g11n.fileBrowserPasteConflictTitle),
            content: Text(g11n.fileBrowserPasteConflictMessage(clip.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(g11n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(g11n.delete),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        overwrite = true;
      }
    } catch (_) {
      // 探测失败就按「不存在」继续,让真正的操作报错。
    }

    final success = await _mutate({target}, () async {
      final files = await ref.read(workspaceFilesProvider.future);
      if (clip.isCut) {
        await files.move(clip.sourcePath, target, overwrite: overwrite);
      } else {
        await files.copy(clip.sourcePath, target, overwrite: overwrite);
      }
      return true;
    }, failMessage: g11n.errorGeneric, parent: node.path);
    // 粘贴成功即清空剪贴板(无论复制还是剪切,一次粘贴后失效);失败保留供重试。
    if (success && mounted) setState(() => _clipboard = null);
  }

  /// 写操作共用包装:标记 busy、成功后重读目录、失败给提示。
  Future<bool> _mutate(
    Set<String> busyPaths,
    Future<bool> Function() action, {
    required String failMessage,
    String? parent,
  }) async {
    setState(() => _busy.addAll(busyPaths));
    var success = false;
    try {
      success = await action();
    } catch (_) {
      success = false;
    } finally {
      if (mounted) setState(() => _busy.removeAll(busyPaths));
    }
    if (!mounted) return success;
    if (success) {
      if (parent != null) await _loadDir(parent);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failMessage)));
    }
    return success;
  }

  Future<String?> _promptName({
    required String title,
    required String confirmLabel,
    String initial = '',
  }) {
    return showTextInputDialog(
      context,
      title: title,
      confirmLabel: confirmLabel,
      initial: initial,
      labelText: AppGlobalizations.of(context).fileBrowserNameLabel,
      // 文件名不能带路径分隔符,否则会写到预期之外的目录。
      isAcceptable: (value) => !value.contains('/') && !value.contains('\\'),
    );
  }
}

/// 文件树一行(对齐上游 `FileTreeRow`):缩进 + 箭头/加载态 + 类型图标 + 文件名。
class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.node,
    required this.style,
    required this.expanding,
    required this.busy,
    required this.onTap,
    required this.onLongPress,
  });

  final _Node node;
  final TextStyle? style;
  final bool expanding;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final theme = Theme.of(context);
    final isDotfile = !node.isRoot && node.name.startsWith('.');
    final decorationColor = node.hasError
        ? theme.colorScheme.error
        : node.ignored
            ? const Color(0xFFD97706)
            : isDotfile
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55)
                : null;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.sm + Spacing.lg * node.depth,
          right: Spacing.md,
          top: Spacing.xs + 2,
          bottom: Spacing.xs + 2,
        ),
        child: Row(
          children: [
            if (node.isDirectory)
              expanding
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : AnimatedRotation(
                      turns: node.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      child: Icon(Icons.chevron_right, size: 16, color: semantic.subtleText),
                    )
            else
              const SizedBox(width: 16),
            const SizedBox(width: Spacing.xs),
            if (busy)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                node.isDirectory ? Iconfont.folder : fileTypeIconFor(node.name),
                size: 20,
                color: decorationColor ??
                    (node.isDirectory
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(width: Spacing.sm),
            Text(
              node.name,
              style: style?.copyWith(color: decorationColor ?? theme.colorScheme.onSurface),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// 剪贴板指示器:显示「已复制/已剪切 + 名称」,点击清除。
class _ClipboardIndicator extends StatelessWidget {
  const _ClipboardIndicator({
    required this.clipboardLabel,
    required this.name,
    required this.onClear,
  });

  final String clipboardLabel;
  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onClear,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconfont.clipboard, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$clipboardLabel $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}