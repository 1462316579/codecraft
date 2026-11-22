import 'package:flutter/material.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ids.dart';
import '../../data/novel_project.dart';
import '../../g11n/app_globalizations.dart';

/// 写作项目入口:新建小说(向导收集设定)或选择写作根下已有的小说。
Future<NovelSelection?> showNovelCreateSheet(
  BuildContext context, {
  required String writingRoot,
}) {
  return showModalBottomSheet<NovelSelection>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => NovelCreateSheet(writingRoot: writingRoot),
  );
}

/// 新建/选择小说的面板。
///
/// - 新建小说:书名 / 类型 / 标签 / 每章字数,均支持预设与自定义;
/// - 选择已有小说:列出 `AI小说` 目录下的书籍文件夹,选中后直接打开。
///
/// 目录与项目的创建由调用方负责。
class NovelCreateSheet extends StatefulWidget {
  const NovelCreateSheet({super.key, required this.writingRoot});

  /// 写作根目录(`<外部存储>/AI小说`),用于列出已有小说。
  final String writingRoot;

  @override
  State<NovelCreateSheet> createState() => _NovelCreateSheetState();
}

enum _NovelSheetMode { create, existing }

class _NovelCreateSheetState extends State<NovelCreateSheet> {
  final _title = TextEditingController();
  final _customTag = TextEditingController();
  final _customWords = TextEditingController();

  final Set<String> _tags = {};
  int? _wordsPerChapter;
  String? _gender;

  _NovelSheetMode _mode = _NovelSheetMode.create;

  List<NovelInfo>? _novels;
  Object? _novelsError;
  String? _selectedNovel;
  bool _loadingNovels = false;

  /// 预设标签(数据而非常量文案,但体量小且固定,与上游预设同理)。
  static const List<String> _presetTags = [
    '玄幻', '仙侠', '都市', '言情', '科幻', '历史', '悬疑', '武侠', '游戏', '轻小说',
  ];

  /// 预设每章字数档位。
  static const List<int> _presetWords = [1500, 2000, 3000, 5000, 8000];

  bool get _canCreate => _title.text.trim().isNotEmpty;
  bool get _canConfirm =>
      _mode == _NovelSheetMode.create ? _canCreate : _selectedNovel != null;

  @override
  void initState() {
    super.initState();
    _loadNovels();
  }

  @override
  void dispose() {
    _title.dispose();
    _customTag.dispose();
    _customWords.dispose();
    super.dispose();
  }

  Future<void> _loadNovels() async {
    setState(() {
      _loadingNovels = true;
      _novelsError = null;
    });
    try {
      final novels = await NovelScaffold.list(widget.writingRoot);
      if (!mounted) return;
      setState(() {
        _novels = novels;
        _loadingNovels = false;
        // 已选的小说被外部删除/改名时清空选择。
        if (_selectedNovel != null &&
            !novels.any((novel) => novel.name == _selectedNovel)) {
          _selectedNovel = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _novelsError = error;
        _loadingNovels = false;
      });
    }
  }

  void _addCustomTag() {
    final tag = _customTag.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      _tags.add(tag);
      _customTag.clear();
    });
  }

  void _setCustomWords() {
    final words = int.tryParse(_customWords.text.trim());
    if (words == null || words <= 0) return;
    setState(() {
      _wordsPerChapter = words;
      _customWords.clear();
    });
  }

  void _confirm() {
    if (!_canConfirm) return;
    if (_mode == _NovelSheetMode.existing) {
      Navigator.pop(context, NovelSelection.existing(_selectedNovel!));
      return;
    }
    Navigator.pop(
      context,
      NovelSelection.create(NovelSpec(
        title: _title.text.trim(),
        tags: _tags.toList(),
        wordsPerChapter: _wordsPerChapter,
        gender: _gender,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g11n.projectKindWriting,
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: Spacing.md),
            SegmentedButton<_NovelSheetMode>(
              segments: [
                ButtonSegment(
                  value: _NovelSheetMode.create,
                  label: Text(g11n.novelNew),
                ),
                ButtonSegment(
                  value: _NovelSheetMode.existing,
                  label: Text(g11n.novelPickExisting),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            const SizedBox(height: Spacing.lg),
            if (_mode == _NovelSheetMode.create)
              ..._buildCreateForm(context)
            else
              ..._buildNovelList(context),
            const SizedBox(height: Spacing.xl),

            // 操作
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(g11n.commonCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _canConfirm ? _confirm : null,
                  child: Text(
                    _mode == _NovelSheetMode.create
                        ? g11n.novelCreate
                        : g11n.novelOpen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCreateForm(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    return [
      // 书名
      Text(g11n.novelFieldName, style: theme.textTheme.labelLarge),
      const SizedBox(height: Spacing.xs),
      TextField(
        controller: _title,
        autofocus: true,
        maxLength: 40,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: g11n.novelFieldNameHint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: Spacing.lg),

      // 小说类型:男频 / 女频单选
      Text(g11n.novelFieldGender, style: theme.textTheme.labelLarge),
      const SizedBox(height: Spacing.xs),
      Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: [
          FilterChip(
            label: Text(g11n.novelGenderMale),
            selected: _gender == g11n.novelGenderMale,
            onSelected: (v) => setState(() => _gender = v ? g11n.novelGenderMale : null),
          ),
          FilterChip(
            label: Text(g11n.novelGenderFemale),
            selected: _gender == g11n.novelGenderFemale,
            onSelected: (v) => setState(() => _gender = v ? g11n.novelGenderFemale : null),
          ),
        ],
      ),
      const SizedBox(height: Spacing.lg),

      // 标签:预设多选 + 自定义
      Text(g11n.novelFieldTags, style: theme.textTheme.labelLarge),
      const SizedBox(height: Spacing.xs),
      Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: [
          for (final tag in _presetTags)
            FilterChip(
              label: Text(tag),
              selected: _tags.contains(tag),
              onSelected: (v) => setState(() {
                if (v) {
                  _tags.add(tag);
                } else {
                  _tags.remove(tag);
                }
              }),
            ),
          for (final tag in _tags.where((t) => !_presetTags.contains(t)))
            InputChip(
              label: Text(tag),
              onDeleted: () => setState(() => _tags.remove(tag)),
            ),
        ],
      ),
      const SizedBox(height: Spacing.xs),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customTag,
              decoration: InputDecoration(
                hintText: g11n.novelCustomTagHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _addCustomTag(),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.tonal(
            onPressed: _addCustomTag,
            child: Text(g11n.commonAdd),
          ),
        ],
      ),
      const SizedBox(height: Spacing.lg),

      // 每章字数:预设单选 + 自定义
      Text(g11n.novelFieldWordsPerChapter, style: theme.textTheme.labelLarge),
      const SizedBox(height: Spacing.xs),
      Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: [
          for (final words in _presetWords)
            FilterChip(
              label: Text('$words'),
              selected: _wordsPerChapter == words,
              onSelected: (v) => setState(() {
                _wordsPerChapter = v ? words : null;
                _customWords.clear();
              }),
            ),
        ],
      ),
      const SizedBox(height: Spacing.xs),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customWords,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: g11n.novelFieldWordsHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _setCustomWords(),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.tonal(
            onPressed: _setCustomWords,
            child: Text(g11n.commonAdd),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildNovelList(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    if (_loadingNovels) {
      return [
        const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_novelsError != null) {
      return [
        Text(
          '${g11n.novelExistingFailed}: $_novelsError',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        FilledButton.tonal(
          onPressed: _loadNovels,
          child: Text(g11n.fileBrowserRefresh),
        ),
      ];
    }
    final novels = _novels ?? const <NovelInfo>[];
    if (novels.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
          child: Column(
            children: [
              Icon(Icons.menu_book_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: Spacing.sm),
              Text(
                g11n.novelExistingEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                g11n.novelExistingEmptyHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.semantic.subtleText,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      Text(
        widget.writingRoot,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.semantic.subtleText,
        ),
      ),
      const SizedBox(height: Spacing.xs),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            final selected = novel.name == _selectedNovel;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.menu_book_outlined,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                novel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(formatDate(novel.modified.millisecondsSinceEpoch)),
              trailing: selected
                  ? Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary)
                  : null,
              selected: selected,
              onTap: () => setState(() => _selectedNovel = novel.name),
            );
          },
        ),
      ),
    ];
  }
}
