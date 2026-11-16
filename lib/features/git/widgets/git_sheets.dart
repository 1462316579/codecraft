import 'package:flutter/material.dart';
import '../../../core/icons/iconfont.dart';
import 'package:flutter/services.dart';

import '../../credentials/credential_login.dart';

import '../../../agent/models/git_models.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/text_input_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'git_common.dart';

/// 长按文件行弹出的菜单项。
class FileMenuItem {
  const FileMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// 文件操作菜单:标题路径 + 可执行的操作项。
Future<void> showFileActionSheet(
  BuildContext context, {
  required String path,
  required List<FileMenuItem> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
            child: Text(
              path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final action in actions)
            InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                action.onSelected();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Row(
                  children: [
                    Icon(
                      action.icon,
                      size: 20,
                      color: action.destructive
                          ? Theme.of(sheetContext).colorScheme.error
                          : Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                    const SizedBox(width: Spacing.lg),
                    Text(
                      action.label,
                      style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                            color: action.destructive
                                ? Theme.of(sheetContext).colorScheme.error
                                : Theme.of(sheetContext).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    ),
  );
}

/// 分支/标签行弹出的操作菜单项。
class RefMenuItem {
  const RefMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// 分支操作菜单:标题引用名 + 操作项。
Future<void> showRefActionSheet(
  BuildContext context, {
  required String refName,
  required List<RefMenuItem> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
            child: Text(
              refName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final action in actions)
            InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                action.onSelected();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Row(
                  children: [
                    Icon(
                      action.icon,
                      size: 20,
                      color: action.destructive
                          ? Theme.of(sheetContext).colorScheme.error
                          : Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                    const SizedBox(width: Spacing.lg),
                    Text(
                      action.label,
                      style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                            color: action.destructive
                                ? Theme.of(sheetContext).colorScheme.error
                                : Theme.of(sheetContext).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    ),
  );
}

/// 提交对话框:快捷前缀胶囊 + AI 生成 + 多行输入 + amend 开关。
class CommitDialog extends StatefulWidget {
  const CommitDialog({
    super.key,
    required this.isGenerating,
    required this.onGenerateAiMessage,
  });

  final bool isGenerating;

  /// 请求 AI 生成;结果通过回调回填到输入框。
  final void Function(void Function(String message) onResult) onGenerateAiMessage;

  @override
  State<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends State<CommitDialog> {
  static const List<String> _types = [
    'feat',
    'fix',
    'refactor',
    'chore',
    'docs',
    'style',
    'perf',
    'test',
  ];

  final _controller = TextEditingController();
  bool _amend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPrefix(String type) {
    final text = _controller.text;
    final prefix = '$type: ';
    final next = text.contains(': ') ? prefix + text.substring(text.indexOf(': ') + 2) : prefix + text;
    _controller.text = next;
    _controller.selection = TextSelection.collapsed(offset: next.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canCommit = _controller.text.trim().isNotEmpty && !widget.isGenerating;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.gitCommitDialogTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: widget.isGenerating
                ? null
                : () => widget.onGenerateAiMessage((message) {
                      _controller.text = message;
                      _controller.selection = TextSelection.collapsed(offset: message.length);
                      setState(() {});
                    }),
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 5),
              decoration: BoxDecoration(
                color: widget.isGenerating
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isGenerating)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    )
                  else
                    Icon(Iconfont.zap, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    widget.isGenerating ? l10n.gitCommitGenerating : l10n.gitCommitAiGenerate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final type in _types)
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.xs),
                        child: _PrefixChip(
                          label: type,
                          selected: _controller.text.startsWith('$type:') ||
                              _controller.text.startsWith('$type('),
                          onTap: () => _applyPrefix(type),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.gitCommitMessage,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.md),
              InkWell(
                onTap: () => setState(() => _amend = !_amend),
                borderRadius: BorderRadius.circular(Radii.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: context.semantic.mutedSurface,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.gitCommitAmend,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _amend,
                        onChanged: (value) => setState(() => _amend = value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: canCommit
              ? () => Navigator.of(context).pop((_controller.text.trim(), _amend))
              : null,
          child: Text(l10n.gitActionCommit),
        ),
      ],
    );
  }
}

/// 提交前缀胶囊:选中态主色底,未选中为浅底 + 细描边。
class _PrefixChip extends StatelessWidget {
  const _PrefixChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 储藏箱弹层:新建储藏 + 列表(弹出 / 应用 / 丢弃)+ 清空。
class StashSheet extends StatefulWidget {
  const StashSheet({
    super.key,
    required this.stashes,
    required this.loading,
    required this.hasChanges,
    required this.busy,
    required this.onSave,
    required this.onPop,
    required this.onApply,
    required this.onDrop,
    required this.onClear,
  });

  final List<GitStash> stashes;
  final bool loading;
  final bool hasChanges;
  final bool busy;
  final void Function(String? message, bool includeUntracked) onSave;
  final void Function(String index) onPop;
  final void Function(String index) onApply;
  final void Function(String index) onDrop;
  final VoidCallback onClear;

  @override
  State<StashSheet> createState() => _StashSheetState();
}

class _StashSheetState extends State<StashSheet> {
  final _message = TextEditingController();
  bool _includeUntracked = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.gitStashTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (widget.stashes.isNotEmpty)
                  TextButton(
                    onPressed: widget.busy ? null : widget.onClear,
                    child: Text(
                      l10n.gitStashClear,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: context.semantic.mutedSurface,
                borderRadius: BorderRadius.circular(Radii.mdLarge),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _message,
                    decoration: InputDecoration(
                      labelText: l10n.gitStashMessageHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.gitStashIncludeUntracked,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Switch(
                        value: _includeUntracked,
                        onChanged: (value) => setState(() => _includeUntracked = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton.tonal(
                      onPressed: widget.busy || !widget.hasChanges
                          ? null
                          : () {
                              final message = _message.text.trim();
                              _message.clear();
                              widget.onSave(message.isEmpty ? null : message, _includeUntracked);
                            },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconfont.archive, size: 16),
                          const SizedBox(width: Spacing.xs),
                          Text(l10n.gitActionStash),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              l10n.gitStashCount(widget.stashes.length),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: context.semantic.subtleText,
              ),
            ),
            if (widget.stashes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                child: Center(
                  child: Text(
                    l10n.gitStashEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.stashes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
                  itemBuilder: (context, index) {
                    final stash = widget.stashes[index];
                    return _StashItemRow(
                      stash: stash,
                      busy: widget.busy,
                      onPop: () => widget.onPop(stash.index),
                      onApply: () => widget.onApply(stash.index),
                      onDrop: () => widget.onDrop(stash.index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StashItemRow extends StatelessWidget {
  const _StashItemRow({
    required this.stash,
    required this.busy,
    required this.onPop,
    required this.onApply,
    required this.onDrop,
  });

  final GitStash stash;
  final bool busy;
  final VoidCallback onPop;
  final VoidCallback onApply;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stash.message.trim().isEmpty ? stash.index : stash.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                stash.date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  stash.index,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: busy ? null : onPop,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.gitStashPop, style: theme.textTheme.labelSmall),
              ),
              TextButton(
                onPressed: busy ? null : onApply,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.gitStashApply, style: theme.textTheme.labelSmall),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: busy ? null : onDrop,
                  tooltip: l10n.gitStashDrop,
                  icon: Icon(Iconfont.trash2, size: 15, color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 仓库选择弹层:列出工作区根与其一层直接子目录,Git 仓库可点选,非 Git 目录灰显标注。
class RepoPickerSheet extends StatelessWidget {
  const RepoPickerSheet({
    super.key,
    required this.workspaceRoot,
    required this.subdirs,
    required this.repos,
    required this.currentRepo,
    required this.onSelect,
  });

  final String workspaceRoot;
  final List<String> subdirs;
  final List<String> repos;
  final String? currentRepo;
  final ValueChanged<String> onSelect;

  /// 显示名:工作区名/子目录名(如 default/git1);工作区根本身只显示工作区名。
  static String displayPath(String path, String workspaceRoot) {
    final root = workspaceRoot.endsWith('/')
        ? workspaceRoot.substring(0, workspaceRoot.length - 1)
        : workspaceRoot;
    final rootName = root.contains('/') ? root.substring(root.lastIndexOf('/') + 1) : root;
    var relative = path;
    if (relative.startsWith(root)) relative = relative.substring(root.length);
    if (relative.startsWith('/')) relative = relative.substring(1);
    return relative.isEmpty ? rootName : '$rootName/$relative';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = [
      if (workspaceRoot.isNotEmpty) workspaceRoot,
      ...subdirs,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                l10n.gitRepoSelectorTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text(
                  l10n.gitPickRepoEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final path = entries[index];
                    final isRepo = repos.contains(path);
                    final isSelected = path == currentRepo;
                    return InkWell(
                      onTap: isRepo ? () => onSelect(path) : null,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconfont.folder,
                              size: 20,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Text(
                                displayPath(path, workspaceRoot),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : isRepo
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (!isRepo)
                              Text(
                                l10n.gitRepoNotRepo,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 克隆仓库对话框:只填地址,非空才可确认。
class CloneRepoDialog extends StatefulWidget {
  const CloneRepoDialog({super.key});

  @override
  State<CloneRepoDialog> createState() => _CloneRepoDialogState();
}

class _CloneRepoDialogState extends State<CloneRepoDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        l10n.gitCloneDialogTitle,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.gitCloneDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _url,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.gitCloneUrlLabel,
              hintText: l10n.gitCloneUrlHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _url.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_url.text.trim()),
          child: Text(l10n.gitActionClone),
        ),
      ],
    );
  }
}

/// 提交详情弹层:完整信息 + 复制哈希 + 建分支/打标签/重置 + 改动文件清单。
class CommitDetailSheet extends StatefulWidget {
  const CommitDetailSheet({
    super.key,
    required this.commit,
    required this.files,
    required this.loading,
    required this.onFileDiff,
    required this.onCreateBranch,
    required this.onCreateTag,
    required this.onReset,
    required this.onDismiss,
  });

  final GitCommit commit;
  final List<GitFileChange>? files;
  final bool loading;
  final void Function(String hash, String path) onFileDiff;
  final ValueChanged<String> onCreateBranch;
  final ValueChanged<String> onCreateTag;
  final ValueChanged<String> onReset;
  final VoidCallback onDismiss;

  @override
  State<CommitDetailSheet> createState() => _CommitDetailSheetState();
}

class _CommitDetailSheetState extends State<CommitDetailSheet> {
  String _resetMode = 'mixed';

  Future<void> _copy(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _promptBranch() async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.gitCreateBranchFromCommit,
      label: l10n.gitBranchName,
    );
    if (name != null) {
      widget.onCreateBranch(name);
      widget.onDismiss();
    }
  }

  Future<void> _promptTag() async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.gitCreateTagAtCommit,
      label: l10n.gitTagName,
    );
    if (name != null) widget.onCreateTag(name);
  }

  Future<String?> _promptName({required String title, required String label}) {
    return showTextInputDialog(
      context,
      title: title,
      confirmLabel: AppLocalizations.of(context).create,
      labelText: label,
    );
  }

  Future<void> _promptReset() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.gitResetToCommit),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gitResetConfirm(widget.commit.shortHash)),
              for (final mode in ['soft', 'mixed'])
                RadioListTile<String>(
                  value: mode,
                  groupValue: _resetMode,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    mode == 'soft' ? l10n.gitResetSoft : l10n.gitResetMixed,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onChanged: (value) {
                    setDialogState(() => _resetMode = value ?? 'mixed');
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.gitResetToCommit,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      widget.onReset(_resetMode);
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final commit = widget.commit;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commit.message,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (commit.body.trim().isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                commit.body.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Spacing.sm),
            Text(
              '${commit.author} · ${commit.date}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    commit.hash,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _copy(context, commit.shortHash, l10n.gitPathCopied),
                  child: Text(l10n.gitCopyShortHash, style: theme.textTheme.labelMedium),
                ),
                TextButton(
                  onPressed: () => _copy(context, commit.hash, l10n.gitPathCopied),
                  child: Text(l10n.gitCopyFullHash, style: theme.textTheme.labelMedium),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: _DetailAction(
                    icon: Iconfont.gitBranch,
                    label: l10n.gitTabBranches,
                    onPressed: _promptBranch,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: _DetailAction(
                    icon: Iconfont.tag,
                    label: l10n.gitTags,
                    onPressed: _promptTag,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: _DetailAction(
                    icon: Iconfont.rotateCcw,
                    label: 'Reset',
                    onPressed: _promptReset,
                  ),
                ),
              ],
            ),
            if (commit.isMerge) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.gitMergeCommit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
            const SizedBox(height: Spacing.sm),
            if (widget.loading)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    l10n.gitLoadingFiles,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else if (widget.files != null) ...[
              if (widget.files!.isEmpty)
                Text(
                  l10n.gitNoFilesChanged,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                Text(
                  l10n.gitFilesChanged(widget.files!.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final file in widget.files!)
                  InkWell(
                    onTap: () => widget.onFileDiff(commit.hash, file.path),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                      child: Row(
                        children: [
                          StatusChip(code: file.statusCode),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              file.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 详情弹层底部的深度操作按钮(36dp 高、小圆角)。
class _DetailAction extends StatelessWidget {
  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}