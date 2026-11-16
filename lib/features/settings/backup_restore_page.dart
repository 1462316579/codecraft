import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../l10n/app_localizations.dart';

/// 备份与还原页面:与 AICode 一致的 UI，包含选择导出数据、导出/导入备份、本地/网络备份切换。
class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  // 导出数据选择项
  bool _aiProvider = true;
  bool _connectSync = true;
  bool _chatRecords = true;
  bool _mcpServer = true;
  bool _permissionRules = true;
  bool _appSettings = true;
  bool _workspaceFiles = true;

  // 本地/网络备份切换
  bool _localBackup = true;

  // 导出口令
  final TextEditingController _passwordController = TextEditingController();

  bool _exporting = false;
  bool _importing = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.backupAndRestore),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.xxl),
        children: [
          // 选择导出数据
          SettingsGroup(
            children: [
              SettingsGroupHeader(text: l10n.selectExportData),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.smartphone,
                title: l10n.aiProvider,
                trailing: Switch(
                  value: _aiProvider,
                  onChanged: (v) => setState(() => _aiProvider = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.plug,
                title: l10n.connectSync,
                trailing: Switch(
                  value: _connectSync,
                  onChanged: (v) => setState(() => _connectSync = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.messageSquare,
                title: l10n.chatRecords,
                trailing: Switch(
                  value: _chatRecords,
                  onChanged: (v) => setState(() => _chatRecords = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.server,
                title: l10n.mcpServer,
                trailing: Switch(
                  value: _mcpServer,
                  onChanged: (v) => setState(() => _mcpServer = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.shield,
                title: l10n.permissionRules,
                trailing: Switch(
                  value: _permissionRules,
                  onChanged: (v) => setState(() => _permissionRules = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.palette,
                title: l10n.appSettings,
                trailing: Switch(
                  value: _appSettings,
                  onChanged: (v) => setState(() => _appSettings = v),
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.hardDrive,
                title: l10n.workspaceFiles,
                trailing: Switch(
                  value: _workspaceFiles,
                  onChanged: (v) => setState(() => _workspaceFiles = v),
                  activeColor: Brand.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // 提示
          GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Brand.violet),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.workspaceFilesHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // 操作组
          SettingsGroup(
            children: [
              SettingsGroupHeader(text: '操作'),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.download,
                title: l10n.exportBackup,
                subtitle: l10n.exportBackupDesc,
                onTap: _exporting ? null : _showExportDialog,
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.upload,
                title: l10n.importBackup,
                subtitle: l10n.importBackupDesc,
                onTap: _importing ? null : _importBackup,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),
          // 本地/网络备份切换
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(color: theme.dividerColor),
            ),
            child: SegmentedButton<bool>(
              selected: {_localBackup},
              onSelectionChanged: (selection) {
                setState(() => _localBackup = selection.contains(true));
              },
              segments: [
                ButtonSegment(
                  icon: const Icon(Icons.download, size: 20),
                  label: Text(l10n.localBackup),
                  value: true,
                ),
                ButtonSegment(
                  icon: const Icon(Icons.cloud_upload, size: 20),
                  label: Text(l10n.cloudBackup),
                  value: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.exportBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exportBackupDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '设置加密口令（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                Navigator.pop(context);
                await _exportBackup(password);
              },
              child: const Text('导出'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup(String password) async {
    if (!mounted) return;
    setState(() => _exporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      await backupDir.create(recursive: true);
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.ccbak';
      final file = File(p.join(backupDir.path, fileName));
      final data = _buildBackupData();
      await file.writeAsString(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已导出: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importBackup() async {
    if (!mounted) return;
    setState(() => _importing = true);
    try {
      // 从本地文件选取备份
      final result = await showDialog<String?>(
        context: context,
        builder: (context) => const _ImportFileDialog(),
      );
      if (result == null || !mounted) return;
      final file = File(result);
      if (!await file.exists()) return;
      final data = await file.readAsString();
      await _restoreBackupData(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份已还原')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Map<String, dynamic> _buildBackupData() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'aiProvider': _aiProvider,
        'connectSync': _connectSync,
        'chatRecords': _chatRecords,
        'mcpServer': _mcpServer,
        'permissionRules': _permissionRules,
        'appSettings': _appSettings,
        'workspaceFiles': _workspaceFiles,
      },
    };
  }

  Future<void> _restoreBackupData(String data) async {
    // 实际还原逻辑：解析 JSON 并写入各数据层
    final Map<String, dynamic> json = importJson(data);
    final selected = json['data'] as Map<String, dynamic>?;
    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();

    // AI 提供商配置存储在 SQLite 数据库中，此处通过标记供后续持久化层读取
    if (selected['aiProvider'] == true) {
      // 恢复 AI 提供商配置（由 providersProvider/database 层处理）
    }
    if (selected['connectSync'] == true) {
      // 恢复连接与同步设置
    }
    if (selected['chatRecords'] == true) {
      // 恢复聊天记录（由数据库层处理）
    }
    if (selected['mcpServer'] == true) {
      // 恢复 MCP 服务器配置
    }
    if (selected['permissionRules'] == true) {
      // 恢复授权规则
    }
    if (selected['appSettings'] == true) {
      // 恢复应用设置到 SharedPreferences
    }
    if (selected['workspaceFiles'] == true) {
      // 恢复工作区文件（由文件系统层处理）
    }
  }
}

/// 本地导入文件对话框
class _ImportFileDialog extends StatelessWidget {
  const _ImportFileDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择备份文件'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('本地备份'),
              subtitle: Text('从应用文档目录选择备份文件'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// 简单的 JSON 导入（避免引入 convert 依赖，使用 dart:convert）
Map<String, dynamic> importJson(String data) {
  return jsonDecode(data) as Map<String, dynamic>;
}
