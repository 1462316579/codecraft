import 'dart:io';

import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/data/credentials.dart';
import 'package:codecraft/features/codespaces/codespaces_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 内存凭据存储:令牌来自 Git 凭据,这里直接给一份,避免部件测试的 FakeAsync 下真实文件 IO 挂起。
class _MemoryCredentialStore extends CredentialStore {
  _MemoryCredentialStore(this._credentials) : super(File('/dev/null'));

  final List<GitCredential> _credentials;

  @override
  Future<List<GitCredential>> all() async => _credentials;
}

void main() {
  Future<void> pump(WidgetTester tester, {String token = ''}) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          credentialStoreProvider.overrideWithValue(
            _MemoryCredentialStore([
              if (token.isNotEmpty)
                GitCredential(host: 'github.com', username: '', token: token),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CodespacesPage(),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('没有 Git 凭据时展示引导卡片,不再就地输入令牌', (tester) async {
    await pump(tester);

    expect(find.text('GitHub Codespaces'), findsOneWidget);
    expect(find.text('尚未配置 GitHub 凭据'), findsOneWidget);
    expect(find.text('去填写 Git 凭据'), findsOneWidget);
    // 令牌只在 Git 凭据里填:这里没有输入框,也没有新建入口。
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('新建 Codespace'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已登录时可打开新建弹层,未选仓库时创建按钮不可用', (tester) async {
    await pump(tester, token: 'ghp_example');

    await tester.tap(find.byTooltip('新建 Codespace'));
    await tester.pumpAndSettle();

    expect(find.text('新建 Codespace'), findsWidgets);
    expect(find.text('仓库'), findsWidgets);
    expect(find.text('机器规格'), findsOneWidget);
    expect(find.text('分支(留空用默认分支)'), findsOneWidget);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '创建'),
    );
    expect(createButton.onPressed, isNull, reason: '没选仓库就不能创建');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Git 凭据里有令牌时展示账号区与操作入口', (tester) async {
    await pump(tester, token: 'ghp_example');

    // 令牌已存在但列表需要网络:此轮只断言账号区与操作入口出现、且不再显示引导卡片。
    expect(find.text('账号'), findsOneWidget);
    expect(find.text('github.com'), findsOneWidget);
    expect(find.text('尚未配置 GitHub 凭据'), findsNothing);
    expect(find.byTooltip('刷新'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}