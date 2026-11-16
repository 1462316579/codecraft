import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../l10n/app_localizations.dart';

const String _githubRepo = '1462316579/codecraft';
const String _githubApi = 'https://api.github.com';
const String _autoCheckKey = 'about_auto_check_updates';

/// 关于页(版本、更新与反馈)，液态柔光玻璃风格，与设置页保持一致。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';
  String _latestVersion = '';
  bool _updateAvailable = false;
  bool _checking = false;
  bool _autoCheck = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _autoCheck = prefs.getBool(_autoCheckKey) ?? true);
    if (_autoCheck) await _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(
          '$_githubApi/repos/$_githubRepo/releases/latest'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        // 对接 GitHub Releases 最新 Release：优先用 Release 的 name（标题）作为展示版本，
        // tag_name 仅用于版本号比较；若 name 为空则回退到 tag_name。
        final tag = data['tag_name'] as String? ?? '';
        final version = tag.startsWith('v') ? tag.substring(1) : tag;
        final releaseName = data['name'] as String? ?? '';
        final displayVersion = releaseName.isNotEmpty ? releaseName : 'v$version';
        if (!mounted) return;
        setState(() {
          _latestVersion = displayVersion;
          _updateAvailable = _isNewer(version, _version);
        });
      } else if (!mounted) {
        return;
      } else {
        setState(() => _updateAvailable = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _updateAvailable = false);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool _isNewer(String newVer, String curVer) {
    final n = _parseVersion(newVer);
    final c = _parseVersion(curVer);
    for (var i = 0; i < n.length; i++) {
      final a = i < c.length ? c[i] : 0;
      if (n[i] > a) return true;
      if (n[i] < a) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) =>
      v.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'\D'), '')) ?? 0)
          .toList();

  Future<void> _toggleAutoCheck(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckKey, value);
    if (!mounted) return;
    setState(() => _autoCheck = value);
    if (value) await _checkUpdate();
  }

  Future<void> _openReleasePage() async {
    final url = 'https://github.com/$_githubRepo/releases/latest';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _getVersionText() {
    if (_updateAvailable && _latestVersion.isNotEmpty) return _latestVersion;
    if (_buildNumber.isNotEmpty) return 'v$_version ($_buildNumber)';
    return 'v$_version';
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.xxl),
        children: [
          SettingsPageHeader(title: l10n.about, subtitle: l10n.aboutSubtitle),
          const SizedBox(height: Spacing.md),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Iconfont.info,
                title: l10n.version,
                subtitle: _checking ? '检查中…' : _getVersionText(),
                onTap: _checking ? null : _checkUpdate,
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.refreshCw,
                title: l10n.aboutAutoCheck,
                subtitle: l10n.aboutAutoCheckDesc,
                trailing: Switch(
                  value: _autoCheck,
                  onChanged: _toggleAutoCheck,
                  activeColor: Brand.violet,
                ),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.gitBranch,
                title: l10n.aboutUpdateChannel,
                subtitle: l10n.aboutStableChannel,
                onTap: () {},
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.download,
                title: l10n.aboutDownloadMirror,
                subtitle: l10n.aboutMirrorUrl,
                onTap: () {},
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.github,
                title: l10n.githubRepo,
                onTap: _openReleasePage,
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.fileText,
                title: l10n.license,
                onTap: () => _showLicense(context, l10n),
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.fileText,
                title: l10n.aboutUserAgreement,
                onTap: () {},
              ),
              const SettingsDivider(indent: SettingsRow.textIndent),
              SettingsRow(
                icon: Iconfont.shield,
                title: l10n.aboutPrivacyPolicy,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 开源协议弹窗:展示随包分发的 GPL-3.0 全文。
  Future<void> _showLicense(BuildContext context, AppLocalizations l10n) =>
      showDialog<void>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text(l10n.license),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: FutureBuilder<String>(
                future: rootBundle.loadString('LICENSE'),
                builder: (context, snapshot) {
                  final text = snapshot.data;
                  if (text == null) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Scrollbar(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
      );
}
