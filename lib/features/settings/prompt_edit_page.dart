import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/prompts.dart';
import '../../g11n/app_globalizations.dart';
import 'prompts_viewmodel.dart';

import '../../agent/models/project.dart';

/// 提示词片段新建/编辑页:自带顶栏(返回 + 右上角保存)。
/// 支持编辑数字编号片段([number] 非空)或场景提示词([kind] 非空,编程/写作/应用逆向)。
class PromptEditPage extends ConsumerStatefulWidget {
  const PromptEditPage({
    super.key,
    this.number,
    this.kind,
    this.initialTitle,
    this.initialDescription,
    this.initialContent,
    this.initialScope,
  });

  /// 为 null 表示新建。
  final int? number;
  final ProjectKind? kind;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialContent;
  final PromptFragmentSource? initialScope;

  bool get isNew => number == null && kind == null;

  /// 是否为场景提示词(编程 / 写作 / 应用逆向)的编辑。
  bool get isScenario => kind != null;

  @override
  ConsumerState<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends ConsumerState<PromptEditPage> {
  final _numberController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  bool get _isNew => widget.isNew;

  @override
  void initState() {
    super.initState();
    if (widget.isScenario) {
      final vm = ref.read(promptsViewModelProvider);
      final scenario = vm.state.scenarios.firstWhere(
        (s) => s.kind == widget.kind,
        orElse: () => ScenarioPrompt(kind: widget.kind!, content: '', source: PromptFragmentSource.builtin),
      );
      _contentController.text = scenario.body;
      _titleController.text = widget.initialTitle ?? widget.kind!.name;
      _descriptionController.text = widget.initialDescription ?? scenario.description;
    } else if (_isNew) {
      // 无需手动设置编号,新建时由页面保持空,保存时由用户输入
    } else {
      _numberController.text = widget.number!.toString().padLeft(2, '0');
      _titleController.text = widget.initialTitle ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _contentController.text = widget.initialContent ?? '';
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final title = _titleController.text.trim();
    if (title.isEmpty) return false;
    if (widget.isScenario) {
      return _contentController.text.trim().isNotEmpty;
    }
    final number = _numberController.text.trim();
    if (number.isEmpty) return false;
    final num = int.tryParse(number);
    return num != null && num >= 0 && num <= 99;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final g11n = AppGlobalizations.of(context);
    final vm = ref.read(promptsViewModelProvider);
    bool ok;
    try {
      ok = widget.isScenario
          ? await vm.saveScenario(
              kind: widget.kind!,
              content: _contentController.text,
              scope: PromptFragmentSource.global,
            )
          : await vm.saveFragment(
              number: int.parse(_numberController.text.trim()),
              title: _titleController.text.trim(),
              scope: PromptFragmentSource.global,
              content: PromptFragment.composeContent(
                _descriptionController.text,
                _contentController.text,
              ),
              previousNumber: widget.number,
            );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${g11n.promptsSaveFailed}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(g11n.promptsSaveFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isNew ? g11n.promptsEditorNew : g11n.promptsEditorEdit),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Iconfont.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(g11n.commonSave),
          ),
        ],
      ),
      body: Container(
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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg,
            MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.md,
            Spacing.lg,
            140,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SettingsGroupHeader(text: g11n.promptsFieldBasic),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isScenario)
                      _buildTextField(
                        controller: _numberController,
                        label: g11n.promptsFieldNumber,
                        placeholder: g11n.promptsFieldNumberPlaceholder,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                      ),
                    if (!widget.isScenario) const SizedBox(height: Spacing.md),
                    if (widget.isScenario) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Row(
                          children: [
                            Icon(Iconfont.folder, size: 20, color: context.semantic.subtleText),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                '${g11n.promptsFieldType}: ${widget.kind!.name}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.semantic.subtleText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                    _buildTextField(
                      controller: _titleController,
                      label: g11n.promptsFieldTitle,
                      placeholder: g11n.promptsFieldTitlePlaceholder,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.md),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g11n.promptsFieldSummary, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: Spacing.xs),
                    TextField(
                      controller: _descriptionController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: g11n.promptsFieldSummaryPlaceholder,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.md),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g11n.promptsFieldContent, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: Spacing.xs),
                    TextField(
                      controller: _contentController,
                      minLines: 8,
                      maxLines: 12,
                      decoration: InputDecoration(
                        hintText: g11n.promptsFieldContentPlaceholder,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int minLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: placeholder,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
