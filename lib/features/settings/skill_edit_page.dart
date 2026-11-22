import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/models/skill.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/skills.dart';
import '../../g11n/app_globalizations.dart';
import 'skills_page.dart';

/// 技能详情 / 编辑页(对齐上游 SkillDetailSection + SkillEditorScreen):
/// 名称、描述、指令正文三个字段;保存后回到列表,已有技能可在此删除。
/// 所有技能统一写入全局层,不再区分项目/全局作用域。
class SkillEditPage extends ConsumerStatefulWidget {
  const SkillEditPage({super.key, this.skillName});

  /// 为 null 表示新建。
  final String? skillName;

  @override
  ConsumerState<SkillEditPage> createState() => _SkillEditPageState();
}

class _SkillEditPageState extends ConsumerState<SkillEditPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _instructions = TextEditingController();
  List<String> _requiredTools = const [];
  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.skillName == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final entries = await ref.read(skillsStoreProvider).listAll();
    final target = widget.skillName!.toLowerCase();
    Skill? found;
    for (final entry in entries) {
      if (entry.skill.name.toLowerCase() == target) {
        found = entry.skill;
        break;
      }
    }
    if (found != null) {
      _name.text = found.name;
      _description.text = found.description;
      _instructions.text = found.instructions;
      _requiredTools = found.requiredTools;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isNew ? g11n.skillsNew : g11n.skillsTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: g11n.delete,
              icon: const Icon(Iconfont.trash2),
              onPressed: _saving ? null : () => _delete(g11n),
            ),
          TextButton(
            onPressed: _saving || !_loaded ? null : () => _save(g11n),
            child: Text(g11n.save),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 100, Spacing.lg, 140),
              children: [
                _field(label: g11n.skillsName, controller: _name, hint: 'skill-name'),
                const SizedBox(height: Spacing.md),
                _field(label: g11n.skillsDescription, controller: _description, hint: g11n.skillsDescriptionHint),
                const SizedBox(height: Spacing.md),
                _field(
                  label: g11n.skillsInstructions,
                  controller: _instructions,
                  hint: g11n.skillsInstructionsHint,
                  maxLines: 14,
                ),
              ],
            ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        TextField(
          controller: controller,
          minLines: maxLines == 1 ? 1 : 8,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppGlobalizations g11n) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(skillsStoreProvider).save(
          SkillForm(
            name: _name.text,
            description: _description.text,
            instructions: _instructions.text,
            requiredTools: _requiredTools,
          ),
          SkillScope.global,
          originalName: widget.skillName,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(_saveErrorText(g11n, error))));
      return;
    }
    refreshSkills(ref);
    context.pop();
  }

  String _saveErrorText(AppGlobalizations g11n, SkillSaveError error) => switch (error) {
        SkillSaveError.invalidName => g11n.skillsErrorInvalidName,
        SkillSaveError.emptyInstructions => g11n.skillsErrorEmptyInstructions,
        SkillSaveError.nameConflict => g11n.skillsErrorNameConflict(_name.text.trim()),
        SkillSaveError.ioFailed => g11n.skillsErrorIoFailed,
      };

  Future<void> _delete(AppGlobalizations g11n) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.skillsDeleteTitle),
        content: Text(g11n.skillsDeleteConfirm(widget.skillName!)),
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
    final deleted =
        await ref.read(skillsStoreProvider).delete(widget.skillName!, SkillScope.global);
    if (!mounted) return;
    if (!deleted) {
      messenger.showSnackBar(SnackBar(content: Text(g11n.skillsErrorIoFailed)));
      return;
    }
    refreshSkills(ref);
    context.pop();
  }
}