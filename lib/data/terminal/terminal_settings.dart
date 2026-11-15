import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 终端设置
class TerminalSettings {
  final double fontSize;
  final TerminalFontFamily fontFamily;
  final TerminalCursorStyle cursorStyle;
  final TerminalThemePreset theme;

  /// 用户导入的字体文件路径（无则为 null）。
  final String? importedFontPath;

  const TerminalSettings({
    this.fontSize = 14.0,
    this.fontFamily = const TerminalFontFamily('monospace', '系统等宽'),
    this.cursorStyle = TerminalCursorStyle.block,
    this.theme = TerminalThemePreset.followApp,
    this.importedFontPath,
  });

  TerminalSettings copyWith({
    double? fontSize,
    TerminalFontFamily? fontFamily,
    TerminalCursorStyle? cursorStyle,
    TerminalThemePreset? theme,
    String? Function()? importedFontPath,
  }) {
    return TerminalSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      theme: theme ?? this.theme,
      importedFontPath:
          importedFontPath == null ? this.importedFontPath : importedFontPath(),
    );
  }
}

/// 终端字体族
class TerminalFontFamily {
  final String family;
  final String displayName;

  const TerminalFontFamily(this.family, this.displayName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalFontFamily &&
          runtimeType == other.runtimeType &&
          family == other.family;

  @override
  int get hashCode => family.hashCode;
}

/// 终端光标样式
enum TerminalCursorStyle { block, underline, bar }

/// 终端配色主题。`background` 为空表示跟随应用主题。
class TerminalThemePreset {
  const TerminalThemePreset({
    required this.id,
    required this.name,
    this.background,
    this.foreground,
    this.cursor,
  });

  final String id;
  final String name;
  final Color? background;
  final Color? foreground;
  final Color? cursor;

  bool get isFollowApp => background == null;

  Color backgroundFor(BuildContext context) =>
      background ??
      (Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF));

  Color foregroundFor(BuildContext context) =>
      foreground ??
      (Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFD4D4D4)
          : const Color(0xFF24292F));

  Color cursorFor(BuildContext context) =>
      cursor ?? Theme.of(context).colorScheme.primary;

  /// 跟随应用（用应用主题色）。
  static const followApp = TerminalThemePreset(id: 'follow-app', name: '跟随应用');

  static const termiusDark = TerminalThemePreset(
    id: 'termius-dark',
    name: 'Termius Dark',
    background: Color(0xFF10131A),
    foreground: Color(0xFFD6DEEB),
    cursor: Color(0xFF7AA2F7),
  );

  static const githubLight = TerminalThemePreset(
    id: 'github-light',
    name: 'GitHub Light',
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF24292E),
    cursor: Color(0xFF0366D6),
  );

  static const dracula = TerminalThemePreset(
    id: 'dracula',
    name: 'Dracula',
    background: Color(0xFF282A36),
    foreground: Color(0xFFF8F8F2),
    cursor: Color(0xFFFF79C6),
  );

  static const oneDark = TerminalThemePreset(
    id: 'one-dark',
    name: 'One Dark',
    background: Color(0xFF282C34),
    foreground: Color(0xFFABB2BF),
    cursor: Color(0xFF528BFF),
  );

  static const monokai = TerminalThemePreset(
    id: 'monokai',
    name: 'Monokai',
    background: Color(0xFF272822),
    foreground: Color(0xFFF8F8F2),
    cursor: Color(0xFFF92672),
  );

  static const githubDark = TerminalThemePreset(
    id: 'github-dark',
    name: 'GitHub Dark',
    background: Color(0xFF0D1117),
    foreground: Color(0xFFC9D1D9),
    cursor: Color(0xFF58A6FF),
  );

  /// 内置配色列表（顺序即展示顺序）。
  static const List<TerminalThemePreset> all = [
    followApp,
    termiusDark,
    githubLight,
    dracula,
    oneDark,
    monokai,
    githubDark,
  ];

  static TerminalThemePreset byId(String? id) =>
      all.where((item) => item.id == id).firstOrNull ?? followApp;
}

/// 终端设置持久化。
class TerminalSettingsStore {
  static const _kFontSize = 'terminal.fontSize';
  static const _kFontFamily = 'terminal.fontFamily';
  static const _kCursorStyle = 'terminal.cursorStyle';
  static const _kThemeId = 'terminal.themeId';
  static const _kImportedFontPath = 'terminal.importedFontPath';

  static Future<TerminalSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final family = prefs.getString(_kFontFamily);
    final cursor = prefs.getString(_kCursorStyle);
    return TerminalSettings(
      fontSize: prefs.getDouble(_kFontSize) ?? 14.0,
      fontFamily: TerminalFontFamily(
        family ?? 'monospace',
        family == kImportedTerminalFontFamily
            ? '导入字体'
            : defaultFontName(family),
      ),
      cursorStyle: TerminalCursorStyle.values
              .where((item) => item.name == cursor)
              .firstOrNull ??
          TerminalCursorStyle.block,
      theme: TerminalThemePreset.byId(prefs.getString(_kThemeId)),
      importedFontPath: prefs.getString(_kImportedFontPath),
    );
  }

  static String defaultFontName(String? family) => switch (family) {
        'JetBrainsMono' => 'JetBrains Mono',
        'Iconfont' => 'Iconfont',
        _ => '系统等宽',
      };

  static Future<void> save(TerminalSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, settings.fontSize);
    await prefs.setString(_kFontFamily, settings.fontFamily.family);
    await prefs.setString(_kCursorStyle, settings.cursorStyle.name);
    await prefs.setString(_kThemeId, settings.theme.id);
    final path = settings.importedFontPath;
    if (path == null) {
      await prefs.remove(_kImportedFontPath);
    } else {
      await prefs.setString(_kImportedFontPath, path);
    }
  }
}

/// 导入字体的固定字体族名（运行时通过 FontLoader 注册）。
const String kImportedTerminalFontFamily = 'TerminalImported';

bool _importedFontLoaded = false;
String? _loadedFontPath;

/// 把用户选择的字体文件复制到应用目录，返回保存后的路径。
Future<String> saveImportedFontFile(List<int> bytes, String extension) async {
  final dir = await getApplicationSupportDirectory();
  final target = File(p.join(dir.path, 'terminal-font$extension'));
  await target.writeAsBytes(bytes, flush: true);
  return target.path;
}

/// 运行时注册导入的字体，供 TerminalView 使用。
Future<void> loadImportedTerminalFont(String path) async {
  if (_importedFontLoaded && _loadedFontPath == path) return;
  final file = File(path);
  if (!await file.exists()) return;
  final bytes = await file.readAsBytes();
  final loader = FontLoader(kImportedTerminalFontFamily)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
  _importedFontLoaded = true;
  _loadedFontPath = path;
}

/// 终端设置提供器（自动持久化）。
final terminalSettingsProvider =
    NotifierProvider<TerminalSettingsNotifier, TerminalSettings>(
  TerminalSettingsNotifier.new,
);

class TerminalSettingsNotifier extends Notifier<TerminalSettings> {
  @override
  TerminalSettings build() {
    Future<void>.microtask(_load);
    return const TerminalSettings();
  }

  Future<void> _load() async {
    final loaded = await TerminalSettingsStore.load();
    final path = loaded.importedFontPath;
    if (path != null) {
      await loadImportedTerminalFont(path);
      state = loaded;
      return;
    }
    state = loaded;
  }

  /// 更新并持久化设置。
  Future<void> update(TerminalSettings next) async {
    state = next;
    await TerminalSettingsStore.save(next);
  }
}
