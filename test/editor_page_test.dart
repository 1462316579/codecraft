import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/settings/editor_settings.dart';
import 'package:codecraft/features/editor/editor_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 编辑器页的判定逻辑与设置持久化(平台视图本身需真机验证)。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('文件能否以文本打开', () {
    test('普通文本可编辑', () {
      expect(
        classifyFile(sizeBytes: 1024, binary: false),
        EditorLoadKind.editable,
      );
    });

    test('二进制内容不可编辑', () {
      expect(
        classifyFile(sizeBytes: 1024, binary: true),
        EditorLoadKind.binary,
      );
    });

    test('超过 2MB 视为过大', () {
      expect(
        classifyFile(sizeBytes: maxEditableBytes + 1, binary: false),
        EditorLoadKind.tooLarge,
      );
      expect(
        classifyFile(sizeBytes: maxEditableBytes, binary: false),
        EditorLoadKind.editable,
        reason: '正好等于上限时仍可打开',
      );
    });

    test('体积优先于二进制判定', () {
      // 几十 MB 的 .so 两个条件都满足,报「过大」比报「二进制」更贴近用户能采取的动作。
      expect(
        classifyFile(sizeBytes: 64 * 1024 * 1024, binary: true),
        EditorLoadKind.tooLarge,
      );
    });
  });

  group('保存冲突判定', () {
    test('磁盘内容没变时不冲突', () {
      expect(
        saveConflicts(loadedFingerprint: 'abc', diskFingerprint: 'abc'),
        isFalse,
      );
    });

    test('磁盘内容变了要提示', () {
      expect(
        saveConflicts(loadedFingerprint: 'abc', diskFingerprint: 'def'),
        isTrue,
        reason: 'AI 会话可能刚改过同一文件,不能静默覆盖',
      );
    });

    test('任一侧指纹缺失时按没变处理', () {
      expect(saveConflicts(loadedFingerprint: null, diskFingerprint: 'def'), isFalse);
      expect(saveConflicts(loadedFingerprint: 'abc', diskFingerprint: null), isFalse);
    });
  });

  group('编辑器设置持久化', () {
    Future<ProviderContainer> boot([Map<String, Object> initial = const {}]) async {
      SharedPreferences.setMockInitialValues(initial);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('默认值与上游一致', () async {
      final container = await boot();
      final settings = container.read(editorSettingsProvider);

      expect(settings.fontSizeSp, 14);
      expect(settings.wordWrap, isFalse);
      expect(settings.showIndentGuide, isTrue);
      expect(settings.showWhitespace, isFalse);
    });

    test('改动写入后重新读取仍然生效', () async {
      final container = await boot();
      final notifier = container.read(editorSettingsProvider.notifier);
      await notifier.setFontSize(20);
      await notifier.setWordWrap(true);
      await notifier.setShowWhitespace(true);

      // 新容器读同一份 prefs,模拟重开 App。
      final reopened = await boot({
        'editor.fontSizeSp': 20,
        'editor.wordWrap': true,
        'editor.showWhitespace': true,
      });
      final settings = reopened.read(editorSettingsProvider);
      expect(settings.fontSizeSp, 20);
      expect(settings.wordWrap, isTrue);
      expect(settings.showWhitespace, isTrue);
    });

    test('字号被收敛到 10–28', () async {
      final container = await boot();
      final notifier = container.read(editorSettingsProvider.notifier);

      await notifier.setFontSize(4);
      expect(container.read(editorSettingsProvider).fontSizeSp, 10);
      await notifier.setFontSize(99);
      expect(container.read(editorSettingsProvider).fontSizeSp, 28);
    });

    test('存盘里的越界字号读出来也被收敛', () async {
      final container = await boot({'editor.fontSizeSp': 200});
      expect(container.read(editorSettingsProvider).fontSizeSp, 28);
    });
  });
}