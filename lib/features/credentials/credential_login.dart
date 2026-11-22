import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/credentials.dart';
import '../../g11n/app_globalizations.dart';

/// 令牌登录弹层:只填访问令牌(PAT),主机与用户名由推送/拉取时按远端自动决定。
Future<void> showTokenLoginSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const _TokenLoginSheet(),
  );
}

class _TokenLoginSheet extends ConsumerStatefulWidget {
  const _TokenLoginSheet();

  @override
  ConsumerState<_TokenLoginSheet> createState() => _TokenLoginSheetState();
}

class _TokenLoginSheetState extends ConsumerState<_TokenLoginSheet> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = _controller.text.trim();
    if (token.isEmpty || _saving) return;
    final g11n = AppGlobalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await ref.read(credentialStoreProvider).save(
          GitCredential(host: defaultCredentialHost, username: '', token: token),
        );
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(g11n.credentialTokenSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g11n.credentialTokenLogin,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              g11n.credentialTokenLoginDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: context.semantic.subtleText),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: g11n.credentialToken,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Iconfont.eyeOff : Iconfont.eye),
                  tooltip: _obscure ? g11n.commonShow : g11n.commonHide,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Spacing.md),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: value.text.trim().isEmpty || _saving ? null : _save,
                  child: Text(g11n.save),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(g11n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}