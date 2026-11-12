import 'package:codecraft/core/ui/provider_logo.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/data/providers/provider_presets.dart';
import 'package:codecraft/data/providers/provider_store.dart';
import 'package:codecraft/features/settings/providers_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  group('品牌识别', () {
    test('名称优先、协议兜底', () {
      expect(
        providerBrandKey(const ProviderConfig(id: '1', name: 'DeepSeek', type: ProviderType.openai)),
        'deepseek',
      );
      expect(
        providerBrandKey(const ProviderConfig(id: '2', name: '随便什么', type: ProviderType.gemini)),
        'google',
      );
      expect(
        providerBrandKey(const ProviderConfig(id: '3', name: '随便什么', type: ProviderType.anthropic)),
        'anthropic',
      );
    });

    test('匹配顺序:minimax 先于 grok,ollama 先于 meta', () {
      expect(modelBrandKey('MiniMaxAI-abab'), 'minimax');
      expect(modelBrandKey('grok-3'), 'grok');
      expect(modelBrandKey('ollama3:8b'), 'ollama');
      expect(modelBrandKey('meta-llama-3'), 'meta');
      expect(modelBrandKey('glm-4.6'), 'zhipu');
      expect(modelBrandKey('claude-sonnet-4'), 'anthropic');
      expect(modelBrandKey('未知模型'), 'other');
    });

    test('自定义请求头占位符替换', () {
      const provider = ProviderConfig(
        id: '1',
        name: 'x',
        type: ProviderType.openai,
        apiKey: 'sk-test',
        customHeaders: {'X-Key': '{{API_KEY}}', 'X-Session': '{{SESSION_ID}}', 'X-Static': 'v'},
      );
      expect(provider.resolvedHeaders(sessionId: 's-1'), {
        'X-Key': 'sk-test',
        'X-Session': 's-1',
        'X-Static': 'v',
      });
    });
  });

  group('供应商列表与排序', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = await AppDatabase.open(inMemory: true);
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('拖拽排序后按新顺序读回', () async {
      final notifier = container.read(providersProvider.notifier);
      for (final name in ['A', 'B', 'C']) {
        await notifier.save(ProviderConfig(id: name, name: name, type: ProviderType.openai));
      }
      expect((await container.read(providersProvider.future)).map((p) => p.name), ['A', 'B', 'C']);

      await notifier.reorder(2, 0);
      expect((await container.read(providersProvider.future)).map((p) => p.name), ['C', 'A', 'B']);
    });
  });

  testWidgets('列表行展示品牌 logo 与状态胶囊', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = await AppDatabase.open(inMemory: true);
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(id: 'p1', name: 'DeepSeek', type: ProviderType.openai),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProvidersPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('0 个模型'), findsOneWidget);
    expect(find.text('已启用'), findsOneWidget);
  });

  test('预设表覆盖上游全部条目且带注册标签', () {
    expect(providerPresets.map((preset) => preset.id), [
      'openai',
      'anthropic',
      'deepseek',
      'google',
      'xai',
      'alibaba',
      'zai',
      'moonshotai',
      'minimax',
      'xiaomi',
      'codecraft',
      'siliconflow',
      'qiniu',
    ]);
    expect(providerPresets.firstWhere((preset) => preset.id == 'codecraft').isRecommended, isTrue);
    expect(providerPresets.firstWhere((preset) => preset.id == 'qiniu').tags, isNotEmpty);
  });
}