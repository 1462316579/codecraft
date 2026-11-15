import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../l10n/app_localizations.dart';

/// 设置页(样式对齐新版设置页:大标题 + 副标题、内容卡片、圆角色块图标行、行尾箭头):
/// 首组为 AI 提供商 / Skill 管理 / 主题;「账户与数据」组为 关于。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 页面底部渐变背景（液态柔光玻璃基底）。
          Container(
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
          ),
          // 液态玻璃内容层，随页面滚动；SafeArea 保证不被状态栏遮挡。
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: Spacing.lg,
                left: Spacing.lg,
                right: Spacing.lg,
                bottom: 140,
              ),
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          icon: Iconfont.slidersHorizontal,
                          title: l10n.settingsGeneral,
                          onTap: () => context.push('/settings/general'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.server,
                          title: l10n.providers,
                          subtitle: l10n.providersSubtitle,
                          onTap: () => context.push('/settings/providers'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.puzzle,
                          title: l10n.skillsTitle,
                          subtitle: l10n.skillsSubtitle,
                          onTap: () => context.push('/settings/skills'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.messageSquare,
                          title: l10n.promptsTitle,
                          subtitle: l10n.promptsSubtitle,
                          onTap: () => context.push('/settings/prompts'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.plug,
                          title: l10n.mcpTitle,
                          subtitle: l10n.mcpSubtitle,
                          onTap: () => context.push('/settings/mcp'),
                        ),
                        SettingsRow(
                          icon: Iconfont.shield,
                          title: l10n.permissionsTitle,
                          subtitle: l10n.permissionsSubtitle,
                          onTap: () => context.push('/settings/permissions'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.smartphone,
                          title: l10n.softwarePermissionsTitle,
                          subtitle: l10n.softwarePermissionsSubtitle,
                          onTap: () => context.push('/permissions-system'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.palette,
                          title: l10n.themeTitle,
                          subtitle: l10n.themeSubtitle,
                          onTap: () => context.push('/settings/theme'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.box,
                          title: l10n.settingsContainer,
                          subtitle: l10n.settingsContainerSubtitle,
                          onTap: () => context.push('/settings/container'),
                        ),
                      ],
                    ),
                    SettingsGroupHeader(text: l10n.settingsCategoryData),
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          icon: Iconfont.barChart,
                          title: l10n.tokenStatsTitle,
                          onTap: () => context.push('/settings/token-stats'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.hardDrive,
                          title: '存储空间',
                          onTap: () => context.push('/settings/storage'),
                        ),
                        const SettingsDivider(indent: SettingsRow.textIndent),
                        SettingsRow(
                          icon: Iconfont.fileText,
                          title: l10n.settingsLog,
                          subtitle: l10n.settingsLogSubtitle,
                          onTap: () => context.push('/settings/logs'),
                        ),
                      ],
                    ),
                    SettingsGroupHeader(text: l10n.accountAndData),
                    SettingsGroup(
                      children: [
                        SettingsRow(
                          icon: Iconfont.info,
                          title: l10n.about,
                          subtitle: l10n.aboutSubtitle,
                          onTap: () => context.push('/settings/about'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}