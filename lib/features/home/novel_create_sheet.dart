import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/novel_project.dart';
import '../../l10n/app_localizations.dart';

/// 新建小说向导:创建小说前提问(书名 / 小说标签 / 每章字数)。
///
/// 每个问题都支持「选择预设」与「输入自定义答案」两种方式:
/// - 书名:直接输入(自定义答案);
/// - 标签:预设标签多选 + 自定义标签添加;
/// - 每章字数:预设档位单选 + 自定义数字输入。
///
/// 创建完成后由调用方负责建目录与项目。
Future<NovelSpec?> showNovelCreateSheet(BuildContext context) {
  return showModalBottomSheet<NovelSpec>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const NovelCreateSheet(),
  );
}

class NovelCreateSheet extends StatefulWidget {
  const NovelCreateSheet({super.key});

  @override
  State<NovelCreateSheet> createState() => _NovelCreateSheetState();
}

class _NovelCreateSheetState extends State<NovelCreateSheet> {
  final _title = TextEditingController();
  final _customTag = TextEditingController();
  final _customWords = TextEditingController();

  final Set<String> _tags = {};
  int? _wordsPerChapter;
  String? _gender;

  /// 预设标签(数据而非常量文案,但体量小且固定,与上游预设同理)。
  static const List<String> _presetTags = [
    '玄幻', '仙侠', '都市', '言情', '科幻', '历史', '悬疑', '武侠', '游戏', '轻小说',
  ];

  /// 预设每章字数档位。
  static const List<int> _presetWords = [1500, 2000, 3000, 5000, 8000];

  bool get _canCreate => _title.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _customTag.dispose();
    _customWords.dispose();
    super.dispose();
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

  void _create() {
    if (!_canCreate) return;
    Navigator.pop(
      context,
      NovelSpec(
        title: _title.text.trim(),
        tags: _tags.toList(),
        wordsPerChapter: _wordsPerChapter,
        gender: _gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.novelNew,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: Spacing.lg),

            // 书名
            Text(l10n.novelFieldName, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.novelFieldNameHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // 小说类型:男频 / 女频单选
            Text(l10n.novelFieldGender, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: Spacing.xs),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                FilterChip(
                  label: Text(l10n.novelGenderMale),
                  selected: _gender == l10n.novelGenderMale,
                  onSelected: (v) => setState(() => _gender = v ? l10n.novelGenderMale : null),
                ),
                FilterChip(
                  label: Text(l10n.novelGenderFemale),
                  selected: _gender == l10n.novelGenderFemale,
                  onSelected: (v) => setState(() => _gender = v ? l10n.novelGenderFemale : null),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // 标签:预设多选 + 自定义
            Text(l10n.novelFieldTags, style: Theme.of(context).textTheme.labelLarge),
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
                      hintText: l10n.novelCustomTagHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCustomTag(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                FilledButton.tonal(
                  onPressed: _addCustomTag,
                  child: Text(l10n.commonAdd),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // 每章字数:预设单选 + 自定义
            Text(l10n.novelFieldWordsPerChapter, style: Theme.of(context).textTheme.labelLarge),
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
                      hintText: l10n.novelFieldWordsHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _setCustomWords(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                FilledButton.tonal(
                  onPressed: _setCustomWords,
                  child: Text(l10n.commonAdd),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),

            // 操作
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _canCreate ? _create : null,
                  child: Text(l10n.novelCreate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}