import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/data/permissions.dart';
import 'package:codecraft/data/workspaces.dart';
import 'package:codecraft/features/settings/permissions_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 固定规则集(避免部件测试里做真实文件 IO)。
class _FakeRules extends PermissionRulesNotifier {
  _FakeRules(this.fixed);

  final PermissionRulesState fixed;

  @override
  Future<PermissionRulesState> build() async => fixed;
}

/// 固定工作区(同上:不创建目录、不读偏好)。
class _FakeWorkspaces extends WorkspacesNotifier {
  _FakeWorkspaces(this.fixed);

  final WorkspacesState fixed;

  @override
  Future<WorkspacesState> build() async => fixed;
}

Widget _harness({
  required PermissionRulesState rules,
  required SharedPreferences preferences,
  String currentName = 'demo',
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      permissionRulesProvider.overrideWith(() => _FakeRules(rules)),
      workspacesProvider.overrideWith(
        () => _FakeWorkspaces(
          WorkspacesState(
            workspaces: [WorkspaceInfo(name: currentName, path: '/tmp/$currentName')],
          ),
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PermissionsPage(),
    ),
  );
}

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('两组规则:项目组带提升按钮,全局组没有', (tester) async {
    await tester.pumpWidget(_harness(
      rules: const PermissionRulesState(
        project: [PermissionRule(toolName: 'writeFile')],
        global: [
          PermissionRule(toolName: 'manageMcp', decision: PermissionDecision.deny),
        ],
      ),
      preferences: preferences,
    ));
    await tester.pumpAndSettle();

    expect(find.text('工具授权'), findsOneWidget);
    expect(find.text('当前项目:demo'), findsOneWidget);
    expect(find.text('全局'), findsOneWidget);

    // 项目规则:整个工具 · 允许,且可提升为全局
    expect(find.text('writeFile'), findsOneWidget);
    expect(find.text('整个工具 · 允许'), findsOneWidget);
    expect(find.byTooltip('提升为全局'), findsOneWidget);

    // 全局规则:禁止,没有提升按钮
    expect(find.text('manageMcp'), findsOneWidget);
    expect(find.text('整个工具 · 禁止'), findsOneWidget);
    expect(find.byTooltip('提升为全局'), findsOneWidget,
        reason: '只有一条项目规则时,提升按钮也只有一个');

    expect(find.text('对话中选「始终允许」会在当前项目生成记忆规则'), findsOneWidget);
  });

  testWidgets('无规则时显示空态文案;点标题可折叠', (tester) async {
    await tester.pumpWidget(_harness(
      rules: const PermissionRulesState(project: [], global: []),
      preferences: preferences,
    ));
    await tester.pumpAndSettle();

    expect(find.text('本项目暂无规则'), findsOneWidget);
    expect(find.text('暂无全局规则'), findsOneWidget);

    await tester.tap(find.text('全局'));
    await tester.pumpAndSettle();
    expect(find.text('暂无全局规则'), findsNothing, reason: '折叠后应隐藏该组内容');
    expect(find.text('本项目暂无规则'), findsOneWidget);
  });
}