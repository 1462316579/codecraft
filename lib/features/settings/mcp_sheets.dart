import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/segmented_tabs.dart';
import '../../core/ui/settings_group.dart';
import '../../data/mcp/mcp_auth_ui_state.dart';
import '../../data/mcp/mcp_client.dart';
import '../../data/mcp/mcp_config.dart';
import '../../data/mcp/mcp_manager.dart';
import '../../l10n/app_localizations.dart';

/// 「添加 MCP 服务器」弹层:手动填写、粘贴 JSON 批量导入(统一使用全局作用域)。
Future<void> showMcpAddSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  const scope = McpScope.global;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
            child: Text(
              l10n.mcpAddSheetTitle,
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SettingsGroup(
              children: [
                SettingsRow(
                  icon: Iconfont.pencil,
                  title: l10n.mcpAddManual,
                  subtitle: l10n.mcpAddManualDesc,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showMcpEditorSheet(context, ref, scope: scope);
                  },
                ),
                const SettingsDivider(indent: SettingsRow.textIndent),
                SettingsRow(
                  icon: Iconfont.fileText,
                  title: l10n.mcpAddFromJson,
                  subtitle: l10n.mcpAddFromJsonDesc,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showMcpJsonImportSheet(context, ref, scope);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    ),
  );
}

/// 「从 JSON 导入」弹层:粘贴标准 mcpServers 配置批量写入所选作用域。
Future<void> showMcpJsonImportSheet(
  BuildContext context,
  WidgetRef ref,
  McpScope scope,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _McpJsonImportSheet(scope: scope),
  );
}

/// JSON 导入弹层。
///
/// 输入框的控制器由本 State 持有:早先在函数里建、在 `showModalBottomSheet`
/// 返回后立刻释放,此时弹层还在退场、输入框仍在拆除,会触发
/// 「A TextEditingController was used after being disposed」并连带把
/// `_dependents.isEmpty` 断言带崩。
class _McpJsonImportSheet extends ConsumerStatefulWidget {
  const _McpJsonImportSheet({required this.scope});

  final McpScope scope;

  @override
  ConsumerState<_McpJsonImportSheet> createState() => _McpJsonImportSheetState();
}

class _McpJsonImportSheetState extends ConsumerState<_McpJsonImportSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final parsed = McpConfigRepository.parse(_controller.text);
    if (parsed.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.mcpJsonImportEmpty)));
      return;
    }
    await ref.read(mcpConfigRepositoryProvider).importServers(parsed, widget.scope);
    ref.invalidate(mcpEntriesProvider);
    ref.read(mcpManagerProvider.notifier).reconnectUnconnectedAsync();
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.mcpSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              l10n.mcpJsonImportTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.mcpJsonImportHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.semantic.subtleText),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: Spacing.md),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: value.text.trim().isEmpty ? null : _import,
                  child: Text(l10n.mcpJsonImportAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单条 server 的编辑弹层(对齐上游 McpEditorDialog):
/// 顶栏(标题 + 查看日志 + 刷新工具)、「基础设置 / 工具」两个分段页,
/// 基础设置含作用域、启用、名称、传输类型与(HTTP 的)OAuth 认证区块;工具页逐工具开关。
Future<void> showMcpEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  McpServerEntry? entry,
  McpScope scope = McpScope.global,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetContext) => _McpEditorSheet(entry: entry, scope: entry?.scope ?? scope),
  );
}

class _HeaderPair {
  _HeaderPair(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _McpEditorSheet extends ConsumerStatefulWidget {
  const _McpEditorSheet({required this.entry, required this.scope});

  final McpServerEntry? entry;
  final McpScope scope;

  @override
  ConsumerState<_McpEditorSheet> createState() => _McpEditorSheetState();
}

class _McpEditorSheetState extends ConsumerState<_McpEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _command;
  late final TextEditingController _clientId;
  late final TextEditingController _authServer;
  late final List<_HeaderPair> _headers;
  late final List<_HeaderPair> _env;
  late final List<TextEditingController> _args;
  late final Set<String> _disabledTools;
  late McpScope _scope;
  late bool _enabled;
  late bool _isStdio;
  late bool _authEnabled;
  late bool _advancedExpanded;
  int _tab = 0;
  String? _error;
  String _toolsQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final server = widget.entry?.server;
    _scope = widget.scope;
    _name = TextEditingController(text: server?.name ?? '');
    _url = TextEditingController(text: server?.url ?? '');
    _command = TextEditingController(text: server?.command ?? '');
    _clientId = TextEditingController(text: server?.auth?.clientId ?? '');
    _authServer = TextEditingController(text: server?.auth?.authServer ?? '');
    _headers = [
      for (final header in (server?.headers ?? const <String, String>{}).entries)
        _HeaderPair(header.key, header.value),
    ];
    _env = [
      for (final entry in (server?.env ?? const <String, String>{}).entries)
        _HeaderPair(entry.key, entry.value),
    ];
    _args = [for (final arg in server?.args ?? const <String>[]) TextEditingController(text: arg)];
    _disabledTools = {...?server?.disabledTools};
    _enabled = server?.enabled ?? true;
    _isStdio = server?.isStdio ?? false;
    _authEnabled = server?.auth != null;
    _advancedExpanded = _clientId.text.trim().isNotEmpty || _authServer.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _command.dispose();
    _clientId.dispose();
    _authServer.dispose();
    for (final header in _headers) {
      header.dispose();
    }
    for (final entry in _env) {
      entry.dispose();
    }
    for (final arg in _args) {
      arg.dispose();
    }
    super.dispose();
  }

  bool get _nameInvalid => !McpServerConfig.isValidName(_name.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mcpState = ref.watch(mcpManagerProvider);
    final server = widget.entry?.server;
    final status = server == null
        ? null
        : mcpState.statuses.where((item) => item.name == server.name).firstOrNull;
    final tools = server == null
        ? const <McpToolDescriptor>[]
        : (mcpState.toolsByServer[server.name] ?? const <McpToolDescriptor>[]);
    final connected = status?.state == McpServerState.connected;
    final authState = ref.watch(mcpAuthUiStateProvider);
    final auth = authState.serverName == server?.name ? authState : const McpAuthUiState();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 顶栏:标题居中,右侧浮动按钮(日志 / 刷新工具)──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  server == null ? l10n.mcpAdd : l10n.mcpEdit,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (server != null)
                        IconButton(
                          icon: const Icon(Iconfont.fileText, size: 20),
                          tooltip: l10n.mcpViewLogs,
                          onPressed: () => context.push(
                            '/settings/logs?server=${Uri.encodeComponent(server.name)}',
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Iconfont.refreshCw, size: 20),
                        tooltip: l10n.mcpRefreshTools,
                        onPressed: server == null
                            ? null
                            : () => ref
                                .read(mcpManagerProvider.notifier)
                                .refreshServerTools(server.name),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── 分段页:基础设置 / 工具 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedTabs(
              selected: _tab,
              labels: [l10n.mcpBasicSettings, l10n.commonTool],
              onSelect: (index) => setState(() => _tab = index),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _tab == 0
                ? _basicTab(context, l10n, server: server, connected: connected, auth: auth)
                : _toolsTab(context, l10n, tools: tools, server: server),
          ),
          // ── 底部保存 ──
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: (_saving || _nameInvalid) ? null : _save,
                    icon: const Icon(Iconfont.check, size: 18),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicTab(
    BuildContext context,
    AppLocalizations l10n, {
    required McpServerConfig? server,
    required bool connected,
    required McpAuthUiState auth,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 是否启用
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(Radii.mdLarge),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.mcpEnabledLabel,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 名称
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.commonName,
              hintText: l10n.mcpNameHint,
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _nameInvalid ? l10n.mcpNameInvalid : null,
            ),
          ),
          const SizedBox(height: 12),
          // 传输类型
          Text(
            l10n.mcpTransportType,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w500, color: semantic.subtleText),
          ),
          const SizedBox(height: 6),
          SegmentedTabs(
            selected: _isStdio ? 1 : 0,
            labels: [l10n.mcpRemoteHttp, l10n.mcpLocalStdio],
            onSelect: (index) => setState(() => _isStdio = index == 1),
          ),
          const SizedBox(height: 12),
          if (_isStdio) ...[
            _fieldRow(label: l10n.mcpCommand, controller: _command, hint: l10n.mcpCommandHint),
            _pairList(
              title: l10n.mcpArgs,
              addLabel: l10n.mcpAddArg,
              pairs: [
                for (final arg in _args)
                  _PairText(value: arg, label: l10n.mcpArgValue, hint: l10n.mcpArgHint),
              ],
              onAdd: () => setState(() => _args.add(TextEditingController())),
              onRemove: (index) => setState(() => _args.removeAt(index).dispose()),
              emptyHint: l10n.mcpNoArgs,
            ),
            _pairList(
              title: '环境变量',
              addLabel: '添加变量',
              pairs: [
                for (final entry in _env)
                  _PairRow(
                    keyController: entry.keyController,
                    valueController: entry.valueController,
                    keyLabel: '变量名',
                    valueLabel: '变量值',
                  ),
              ],
              onAdd: () => setState(() => _env.add(_HeaderPair('', ''))),
              onRemove: (index) => setState(() => _env.removeAt(index).dispose()),
              emptyHint: '无自定义环境变量',
            ),
            const SizedBox(height: 8),
            Text(
              '本地 stdio 服务器当前不可用；配置已保存。',
              style: theme.textTheme.bodySmall?.copyWith(color: semantic.warning),
            ),
          ] else ...[
            _fieldRow(label: l10n.mcpServerUrl, controller: _url, hint: l10n.mcpServerUrlHint),
            _pairList(
              title: l10n.mcpCustomHeaders,
              addLabel: l10n.mcpAddHeader,
              pairs: [
                for (final header in _headers)
                  _PairRow(
                    keyController: header.keyController,
                    valueController: header.valueController,
                    keyLabel: l10n.mcpHeaderName,
                    valueLabel: l10n.mcpHeaderValue,
                  ),
              ],
              onAdd: () => setState(() => _headers.add(_HeaderPair('', ''))),
              onRemove: (index) => setState(() => _headers.removeAt(index).dispose()),
              emptyHint: l10n.mcpNoCustomHeaders,
            ),
            _authSection(context, l10n, server: server, connected: connected, auth: auth),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _authSection(
    BuildContext context,
    AppLocalizations l10n, {
    required McpServerConfig? server,
    required bool connected,
    required McpAuthUiState auth,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── OAuth 开关卡片 ──
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(Radii.mdLarge),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _authEnabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Iconfont.shield,
                  size: 18,
                  color: _authEnabled ? theme.colorScheme.primary : semantic.subtleText,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mcpAuthEnable,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      l10n.mcpAuthDesc,
                      style: theme.textTheme.bodySmall?.copyWith(color: semantic.subtleText),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _authEnabled,
                onChanged: (value) => setState(() => _authEnabled = value),
              ),
            ],
          ),
        ),
        if (_authEnabled) ...[
          const SizedBox(height: Spacing.md),
          if (server == null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.mdLarge),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 12),
              child: Row(
                children: [
                  Icon(Iconfont.info, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.mcpAuthSaveFirst, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            )
          else
            _authStatusCard(context, l10n, server: server, connected: connected, auth: auth),
          const SizedBox(height: Spacing.md),
          // ── 高级认证选项(可折叠)──
          InkWell(
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Iconfont.slidersHorizontal, size: 16, color: semantic.subtleText),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.mcpAuthAdvanced,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(
                    _advancedExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: semantic.subtleText,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded) ...[
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _clientId,
              decoration: InputDecoration(
                labelText: l10n.mcpAuthClientId,
                hintText: l10n.mcpAuthClientIdHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _authServer,
              decoration: InputDecoration(
                labelText: l10n.mcpAuthServer,
                hintText: l10n.mcpAuthServerHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _authStatusCard(
    BuildContext context,
    AppLocalizations l10n, {
    required McpServerConfig server,
    required bool connected,
    required McpAuthUiState auth,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isAuthorized = auth.success || connected || ref
        .read(mcpManagerProvider.notifier)
        .isAuthorized(server.name);
    final statusLabel = auth.inProgress
        ? l10n.mcpAuthStatusAuthorizing
        : auth.success
            ? l10n.mcpAuthSuccess
            : isAuthorized
                ? l10n.mcpAuthStatusAuthorized
                : l10n.mcpAuthStatusUnauthorized;
    final statusColor = auth.inProgress
        ? theme.colorScheme.primary
        : isAuthorized
            ? semantic.success
            : semantic.subtleText;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mcpAuthStatusLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (auth.inProgress)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.8, color: statusColor),
                      )
                    else if (isAuthorized)
                      Icon(Iconfont.check, size: 12, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (auth.error != null) ...[
            const SizedBox(height: Spacing.md),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconfont.alertCircle, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.mcpAuthFailed(auth.error!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          if (auth.inProgress)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.mcpAuthInProgress,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            l10n.mcpAuthInProgressHint,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: semantic.subtleText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelAuthorize(server.name),
                    child: Text(l10n.mcpAuthCancel),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _authorize(server.name),
                    child: Text(
                      isAuthorized ? l10n.mcpAuthReauthorize : l10n.mcpAuthLogin,
                    ),
                  ),
                ),
                if (isAuthorized) ...[
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _logout(server.name),
                      child: Text(l10n.mcpAuthLogout),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _toolsTab(
    BuildContext context,
    AppLocalizations l10n, {
    required List<McpToolDescriptor> tools,
    required McpServerConfig? server,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    if (tools.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconfont.wrench, size: 32, color: semantic.subtleText.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                server == null ? l10n.mcpSaveFirstHint : l10n.mcpNoToolsHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: semantic.subtleText),
              ),
            ],
          ),
        ),
      );
    }
    final filtered = _toolsQuery.trim().isEmpty
        ? tools
        : [
            for (final tool in tools)
              if (tool.name.toLowerCase().contains(_toolsQuery.toLowerCase()) ||
                  tool.description.toLowerCase().contains(_toolsQuery.toLowerCase()))
                tool,
          ];
    final enabledCount = tools.where((tool) => !_disabledTools.contains(tool.name)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tools.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                onChanged: (value) => setState(() => _toolsQuery = value),
                decoration: InputDecoration(
                  hintText: l10n.mcpToolsSearch,
                  prefixIcon: const Icon(Iconfont.search, size: 18),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mcpToolsSummary(enabledCount, tools.length),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500, color: semantic.subtleText),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _disabledTools.clear()),
                child: Text(l10n.mcpToolsEnableAll),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _disabledTools
                    ..clear()
                    ..addAll([for (final tool in tools) tool.name]);
                }),
                child: Text(l10n.mcpToolsDisableAll),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Iconfont.search, size: 24, color: semantic.subtleText.withValues(alpha: 0.5)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.mcpToolsSearchEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(color: semantic.subtleText),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final tool in filtered)
              _toolCard(context, l10n, tool: tool),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _toolCard(BuildContext context, AppLocalizations l10n, {required McpToolDescriptor tool}) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final enabled = !_disabledTools.contains(tool.name);
    final paramKeys = switch (tool.inputSchema?['properties']) {
      final Map<Object?, Object?> map => [for (final key in map.keys) '$key'],
      _ => const <String>[],
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Radii.mdLarge),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tool.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : semantic.subtleText.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (value) => setState(() {
                  if (value) {
                    _disabledTools.remove(tool.name);
                  } else {
                    _disabledTools.add(tool.name);
                  }
                }),
              ),
            ],
          ),
          _ToolDescription(
            text: tool.description.trim().isEmpty ? l10n.mcpNoDescription : tool.description,
            expandLabel: l10n.commonExpand,
            collapseLabel: l10n.commonCollapse,
          ),
          if (paramKeys.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in paramKeys)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      key,
                      style: theme.textTheme.labelSmall?.copyWith(color: semantic.subtleText),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _pairList({
    required String title,
    required String addLabel,
    required List<Widget> pairs,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
    required String emptyHint,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: semantic.subtleText),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconfont.plus, size: 16),
              label: Text(addLabel),
            ),
          ],
        ),
        if (pairs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              emptyHint,
              style: theme.textTheme.bodySmall?.copyWith(color: semantic.subtleText),
            ),
          )
        else
          for (var index = 0; index < pairs.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: pairs[index]),
                  IconButton(
                    icon: Icon(Iconfont.trash2, size: 18, color: theme.colorScheme.error),
                    onPressed: () => onRemove(index),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _authorize(String serverName) async {
    final notifier = ref.read(mcpAuthUiStateProvider.notifier);
    notifier.start(serverName);
    try {
      await ref.read(mcpManagerProvider.notifier).authorize(serverName);
      notifier.succeed(serverName);
    } catch (error) {
      notifier.fail(serverName, '$error');
    }
  }

  Future<void> _cancelAuthorize(String serverName) async {
    await ref.read(mcpManagerProvider.notifier).cancelAuthorize(serverName);
    ref.read(mcpAuthUiStateProvider.notifier).fail(serverName, '已取消授权');
  }

  Future<void> _logout(String serverName) async {
    await ref.read(mcpManagerProvider.notifier).logout(serverName);
    ref.read(mcpAuthUiStateProvider.notifier).clear();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    if (!McpServerConfig.isValidName(name)) {
      setState(() => _error = l10n.mcpNameInvalid);
      return;
    }
    final url = _url.text.trim();
    final command = _command.text.trim();
    if (_isStdio && command.isEmpty) {
      setState(() => _error = '${l10n.mcpCommand}不能为空');
      return;
    }
    if (!_isStdio && url.isEmpty) {
      setState(() => _error = '${l10n.mcpServerUrl}不能为空');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = ref.read(mcpConfigRepositoryProvider);
    final originalName = widget.entry?.server.name;
    final originalScope = widget.entry?.scope;
    final authConfig = _authEnabled
        ? McpAuthConfig(
            clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
            authServer: _authServer.text.trim().isEmpty ? null : _authServer.text.trim(),
          )
        : null;
    final config = McpServerConfig(
      name: name,
      url: _isStdio ? '' : url,
      headers: _isStdio
          ? const {}
          : {
              for (final header in _headers)
                if (header.keyController.text.trim().isNotEmpty)
                  header.keyController.text.trim(): header.valueController.text.trim(),
            },
      command: _isStdio ? command : '',
      args: _isStdio
          ? [for (final arg in _args) if (arg.text.trim().isNotEmpty) arg.text.trim()]
          : const [],
      env: _isStdio
          ? {
              for (final entry in _env)
                if (entry.keyController.text.trim().isNotEmpty)
                  entry.keyController.text.trim(): entry.valueController.text.trim(),
            }
          : const {},
      enabled: _enabled,
      disabledTools: {..._disabledTools},
      auth: authConfig,
    );
    await repository.saveServer(config, _scope);
    if (originalName != null && (originalName != name || originalScope != _scope)) {
      await repository.removeServer(originalName, originalScope ?? McpScope.global);
    }
    ref.invalidate(mcpEntriesProvider);
    await ref.read(mcpManagerProvider.notifier).reloadServer(name);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.mcpSaved)));
  }
}

/// 工具描述:默认两行,超长可展开(对齐上游)。
class _ToolDescription extends StatefulWidget {
  const _ToolDescription({
    required this.text,
    required this.expandLabel,
    required this.collapseLabel,
  });

  final String text;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<_ToolDescription> createState() => _ToolDescriptionState();
}

class _ToolDescriptionState extends State<_ToolDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: context.semantic.subtleText),
        ),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _expanded ? widget.collapseLabel : widget.expandLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// 单值输入(参数列表用)。
class _PairText extends StatelessWidget {
  const _PairText({required this.value, required this.label, required this.hint});

  final TextEditingController value;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

/// 键值输入(请求头 / 环境变量用)。
class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.keyController,
    required this.valueController,
    required this.keyLabel,
    required this.valueLabel,
  });

  final TextEditingController keyController;
  final TextEditingController valueController;
  final String keyLabel;
  final String valueLabel;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: keyLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            flex: 3,
            child: TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: valueLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      );
}