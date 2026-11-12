import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:codecraft/data/credentials.dart';
import 'package:codecraft/features/credentials/credential_login.dart';
import 'package:codecraft/l10n/app_localizations.dart';

/// testWidgets 跑在 FakeAsync 里,真实文件 IO 的 Future 不会完成,
/// 部件测试因此用内存版本(真实落盘仍由 credentials_test.dart 覆盖)。
class _MemoryCredentialStore extends CredentialStore {
  _MemoryCredentialStore() : super(File('/dev/null'));

  final List<GitCredential> _items = [];

  @override
  Future<List<GitCredential>> all() async => List.of(_items);

  @override
  Future<void> save(GitCredential credential) async {
    _items.removeWhere((entry) => entry.id == credential.id);
    _items.add(credential);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((entry) => entry.id == id.toLowerCase());
  }

  @override
  Future<GitCredential?> findForHost(String host) async {
    final target = host.toLowerCase();
    GitCredential? fallback;
    for (final entry in _items) {
      if (entry.id == target) return entry;
      if (entry.id == defaultCredentialHost) fallback = entry;
    }
    return fallback;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryCredentialStore store;

  setUp(() {
    store = _MemoryCredentialStore();
  });

  Widget harness() => ProviderScope(
        overrides: [credentialStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showTokenLoginSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('令牌登录:只有一个输入框,保存后写入通用令牌', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 只要求令牌,不要主机与用户名
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('远程主机'), findsNothing);
    expect(find.text('username'), findsNothing);

    final saveButton = find.widgetWithText(FilledButton, '保存');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull, reason: '未填令牌时不可保存');

    await tester.enterText(find.byType(TextField), 'ghp_abc123');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final saved = await store.all();
    expect(saved.single.token, 'ghp_abc123');
    expect(saved.single.host, defaultCredentialHost);
    expect(find.text('令牌已保存'), findsOneWidget);
  });

  testWidgets('令牌登录:可切换明文显示', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.eyeOff));
    await tester.pump();
    expect(find.byIcon(LucideIcons.eye), findsOneWidget);
  });

  test('通用令牌对所有主机生效,精确主机条目优先(真实落盘)', () async {
    final dir = await Directory.systemTemp.createTemp('codecraft_cred_');
    addTearDown(() => dir.delete(recursive: true));
    final real = CredentialStore(File('${dir.path}/git-credentials'));

    await real.save(const GitCredential(host: defaultCredentialHost, username: '', token: 'any'));
    expect((await real.findForHost('gitee.com'))!.token, 'any');
    expect((await real.findForHost('github.com'))!.token, 'any');

    await real.save(const GitCredential(host: 'github.com', username: 'octocat', token: 'gh'));
    expect((await real.findForHost('github.com'))!.token, 'gh');
    expect((await real.findForHost('gitlab.com'))!.token, 'any');
  });

  test('没记用户名时按主机推导:GitHub 用 x-access-token,其余用 oauth2', () {
    expect(resolveGitUsername('github.com', ''), 'x-access-token');
    expect(resolveGitUsername('GitHub.com', ''), 'x-access-token');
    expect(resolveGitUsername('gitee.com', ''), 'oauth2');
    expect(resolveGitUsername('gitee.com', 'someone'), 'someone');
  });
}