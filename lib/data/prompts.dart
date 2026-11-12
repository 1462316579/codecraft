import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/models/project.dart';
import '../agent/tools/workspace.dart';
import '../data/workspaces.dart';

/// 片段来源,优先级从高到低:项目 > 全局 > 本地 > 内置。
enum PromptFragmentSource {
  project,
  global,
  local,
  builtin,
}

/// 一个编号最终生效的片段。
class PromptFragment {
  const PromptFragment({
    required this.number,
    required this.title,
    required this.source,
    required this.content,
    this.file,
    required this.description,
  });

  final int number;
  final String title;
  final PromptFragmentSource source;
  final String content;
  final File? file;
  final String description;

  /// 用于拖拽重排时的稳定键(标题 + 内容哈希)。
  String get stableReorderKey => '$title:${content.hashCode}';

  /// 正文:去掉开头的 `<!-- ... -->` 摘要注释。
  String get body => PromptFragment.stripLeadingComment(content);

  /// 生效层是否可写(项目/全局可写,本地/内置只读)。
  bool get editable =>
      source == PromptFragmentSource.project ||
      source == PromptFragmentSource.global;

  /// 合成存储内容:若有摘要则在正文前加 `<!-- summary -->`。
  static String composeContent(String description, String body) {
    if (description.trim().isEmpty) return body;
    final escaped = description.trim().replaceAll('-->', '-- >');
    return '<!-- $escaped -->\n$body';
  }

  /// 去掉正文开头的 `<!-- ... -->` 摘要注释(与 [body] 同规则,供外部组装基线用)。
  static String stripLeadingComment(String content) {
    final leadingComment = RegExp(r'^\s*<!--.*?-->\s*', dotAll: true);
    return content.replaceFirst(leadingComment, '');
  }

  /// 提取正文开头的 `<!-- ... -->` 摘要注释(无则空串)。
  static String extractDescription(String content) {
    final match = RegExp(r'^\s*<!--\s*(.*?)\s*-->', dotAll: true).firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }
}

/// 场景提示词:按项目类型(编程 / 写作 / 应用逆向)注入系统提示词的内置片段。
///
/// 与数字编号片段不同,场景片段按名称(kind)定位:项目层 > 全局层 > 内置 assets,
/// 自定义文件放在 `prompts.custom/scenarios/<kind>.md`。
class ScenarioPrompt {
  const ScenarioPrompt({required this.kind, required this.content, required this.source});

  final ProjectKind kind;

  /// 完整内容(含开头的 `<!-- 摘要 -->` 注释)。
  final String content;
  final PromptFragmentSource source;

  /// 摘要:正文开头的 `<!-- ... -->` 注释。
  String get description => PromptFragment.extractDescription(content);

  /// 正文:去掉开头的 `<!-- ... -->` 摘要注释。
  String get body => PromptFragment.stripLeadingComment(content).trim();
}

/// 三款内置场景提示词的完整正文(与 assets/prompts/scenarios/*.md 一致)。
/// 直接内嵌在代码中,避免每次通过 rootBundle 读取 assets 带来的 platform channel 开销,
/// 从而修复提示词页面首次加载缓慢的问题。
const String builtinCodingScenario = '''<!-- 编程项目场景:工作区是 ~/workspace 下的源码仓库,容器内可用完整工具集 -->
## 编程项目

当前是编程项目:工作区 `~/workspace` 下是源码仓库,AI 在本地容器(PRoot)中工作,文件读写、终端命令、构建测试与浏览器等工具集全部可用。

- 读写代码、跑构建与测试、用 Git 管理改动,都直接在工作区内进行。
- 涉及容器初始化、系统依赖或构建环境时,先确认容器内工具链可用再动手,不要臆测环境。
''';

const String builtinWritingScenario = '''<!-- 写作项目场景:工作区是外部「AI小说」目录下的书籍脚手架,不经容器、没有命令工具 -->
## 写作项目

当前是写作项目:工作区是手机外部存储「AI小说」目录下的书籍脚手架(角色关联 / 小说资料 / 小说章节),不是容器内的源码仓库。

- 读写一律用文件工具(`readFile` / `writeFile` / `editFile` / `list` / `search`);没有 Bash、终端与构建工具,也不要尝试启动容器。
- 按小说创作流程推进:先定大纲与人物库,再分卷分章写作;改稿保留用户原意与既有风格。
- 章节内容落成 `小说章节/` 下的 Markdown 文件,并在回复里说明写到了哪个路径。
''';

const String builtinReverseScenario = '''<!-- 应用逆向项目场景:工作区是目标 APK 的解包结果,AI 做只读静态分析 -->
## 应用逆向项目(工作区是 APK 解包结果)

当前项目是「应用逆向」:工作区里放的是某个已安装应用的安装包**解包后的文件**,不是源码仓库。
用户的目标是对它做静态分析——看清它由什么构成、权限与组件有哪些、关键逻辑在哪个库里。

### 工作区里通常有什么
- `AndroidManifest.xml`:**二进制 AXML**,直接读会看到乱码;用 `aapt2 dump badging` / `xmltree` 或 `strings` 提取。
- `classes.dex`、`classes2.dex`…:Dalvik 字节码,二进制。
- `lib/<abi>/*.so`:原生库(Flutter 应用的业务代码常在 `libapp.so`)。
- `res/`、`assets/`、`META-INF/`:资源与签名信息。

### 应用自带的逆向工具(用户可直接打开,你也可以引导他去用)
- **Dex 编辑器**:文件树点 `.dex` 就进。有「类」(类列表→类结构→方法 smali 反汇编)、「字符串池」(全局几十万条字符串,可搜)、「十六进制」三个页签。
- **ARSC 编辑器**:点 `resources.arsc` 就进。有「资源」(按类型/key/`0x` 编号搜,能看同一资源在全部语言与密度配置下的取值)、「字符串池」、「十六进制」。
- **十六进制**:任何二进制文件在编辑器里点「以十六进制打开」。

这三个工具只读分析就够用;写回只支持两种改法,且边界很窄:
- 字符串**等长替换**(新内容编码后的字节数必须与原串一致),dex 会顺带重算 checksum 与 sha1;
- 十六进制直接改字节。

所以不要在建议里承诺「随便改字符串」「改代码逻辑后重新打包」——dex 值变长会移动全部偏移,现有工具做不到。需要用户改大段逻辑时,说明只能改等长内容,或由用户自行用外部工具重打包。

### 做法
- 二进制文件用 `Bash` 里的 `strings`、`unzip -l`、`grep -a` 提取可读内容;`readFile` 读二进制会给出可打印字符串而不是报错。
- 先给整体结构:包名/版本/权限/组件/原生库清单,再按用户关心的点深入某个库或某段字符串。
- 引用证据时给出文件与字符串原文,不要凭经验猜实现。
- 分析默认是只读的:不修改解包出来的文件。用户明确要求改写并重新打包时,先说明这会改变应用行为与签名。

### 说明
静态分析、理解实现、排查安全问题、学习与研究都是正常工作内容,直接动手做,不需要先做免责声明或反问用途。
涉及绕过他人付费/授权/广告奖励等规避商业机制的目标,或制作恶意程序时,说明做不到并给出正当替代方案。
''';

/// 按项目类型取内置场景提示词正文;未知类型返回 null。
String? builtinScenarioContent(ProjectKind kind) => switch (kind) {
      ProjectKind.coding => builtinCodingScenario,
      ProjectKind.writing => builtinWritingScenario,
      ProjectKind.reverse => builtinReverseScenario,
    };

/// 提示词页 UI 状态。
class PromptsUiState {
  const PromptsUiState({
    this.fragments = const [],
    this.scenarios = const [],
    this.builtinDisabled = false,
    this.hasWorkspace = false,
    this.loading = true,
    this.guideText = '',
    this.guideOutdated = false,
  });

  final List<PromptFragment> fragments;

  /// 三款内置场景提示词(编程 / 写作 / 应用逆向)。
  final List<ScenarioPrompt> scenarios;
  final bool builtinDisabled;
  final bool hasWorkspace;
  final bool loading;

  /// 提示词使用说明公告正文(按界面语言取内置 assets),空串表示加载失败。
  final String guideText;

  /// 公告相对已读记录有更新(或从未读过):进入页面时自动弹一次。
  final bool guideOutdated;

  PromptsUiState copyWith({
    List<PromptFragment>? fragments,
    List<ScenarioPrompt>? scenarios,
    bool? builtinDisabled,
    bool? hasWorkspace,
    bool? loading,
    String? guideText,
    bool? guideOutdated,
  }) {
    return PromptsUiState(
      fragments: fragments ?? this.fragments,
      scenarios: scenarios ?? this.scenarios,
      builtinDisabled: builtinDisabled ?? this.builtinDisabled,
      hasWorkspace: hasWorkspace ?? this.hasWorkspace,
      loading: loading ?? this.loading,
      guideText: guideText ?? this.guideText,
      guideOutdated: guideOutdated ?? this.guideOutdated,
    );
  }
}

/// 提示词片段解析规则(纯文件系统逻辑,便于单测)。
class PromptFragmentResolver {
  /// 存在该文件即完全禁用内置提示词(仅主代理生效)。
  static const String disableBuiltinFile = '.no-builtin';

  static final _numbered = RegExp(r'^(\d{2})-(.+)\.md$');

  /// 顶层数字片段的数字值;非两位数字前缀返回 null。
  static int? parseNumber(String fileName) {
    final match = _numbered.firstMatch(fileName);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// 目录顶层 `<两位数字>-<名称>.md` 文件,按数字升序。
  /// 同一数字有多个文件时只保留字典序首个,避免排序不稳定。
  static List<MapEntry<int, File>> numberedFragments(Directory dir) {
    final files = dir.listSync().whereType<File>().toList();
    final byNumber = <int, File>{};
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final number = parseNumber(p.basename(file.path));
      if (number != null && !byNumber.containsKey(number)) {
        byNumber[number] = file;
      }
    }
    final entries = byNumber.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  /// `.no-builtin` 是否存在。
  static bool isBuiltinDisabled(Directory dir) {
    return File(p.join(dir.path, disableBuiltinFile)).existsSync();
  }
}

/// 提示词片段的四级来源解析:同一编号只生效优先级最高的一层。
///
/// - 项目:工作区 `.codecraft/prompts.custom/`
/// - 全局:`<configDir>/prompts.custom/`
/// - 本地:`<configDir>/prompts/`(上游由启动时释放的内置副本占据;本移植内置层直接读 assets,该层恒为空)
/// - 内置:`assets/prompts/`
///
/// 编号即身份(文件名前两位数字),决定片段在系统提示词里的顺序。
class PromptFragmentCatalog {
  PromptFragmentCatalog({
    required String configDir,
    required String workspaceRoot,
  }) : _configDir = configDir,
       _workspaceRoot = workspaceRoot;

  final String _configDir;
  final String _workspaceRoot;

  Directory get _globalDir => Directory(p.join(_configDir, 'prompts.custom'));
  Directory get _localDir => Directory(p.join(_configDir, 'prompts'));

  Directory? get _projectDir {
    final codecraftDir = Directory(p.join(_workspaceRoot, '.codecraft'));
    if (!codecraftDir.existsSync()) return null;
    return Directory(p.join(codecraftDir.path, 'prompts.custom'));
  }

  /// 编辑/新增的写入层:有工作区写项目层,否则写全局层。
  Directory get writableDir => _projectDir ?? _globalDir;

  /// 按编号升序列出所有生效片段(不含内置层,内置由 ViewModel 通过 rootBundle 合并)。
  List<PromptFragment> listLocalLayers() {
    final project = _numberedFragments(_projectDir);
    final global = _numberedFragments(_globalDir);
    final local = _numberedFragments(_localDir);

    final numbers = <int>{}
      ..addAll(project.keys)
      ..addAll(global.keys)
      ..addAll(local.keys);

    final all = numbers.toList()..sort();
    final fragments = <PromptFragment>[];

    for (final number in all) {
      final frag = _resolveLocal(number, project, global, local);
      if (frag != null) fragments.add(frag);
    }
    return fragments;
  }

  /// 渲染静态基线:合并内置索引与本地层,按编号拼接正文(去摘要)。
  ///
  /// [builtinIndex] 为内置 assets 编号片段正文(编号 → 内容),由调用方通过 rootBundle 获取。
  String renderStatic(Map<int, String> builtinIndex) {
    final project = _numberedFragments(_projectDir);
    final global = _numberedFragments(_globalDir);
    final local = _numberedFragments(_localDir);

    final numbers = <int>{}
      ..addAll(builtinIndex.keys)
      ..addAll(project.keys)
      ..addAll(global.keys)
      ..addAll(local.keys);

    final all = numbers.toList()..sort();
    final fragments = <PromptFragment>[];

    for (final number in all) {
      final frag = _resolveFull(number, builtinIndex, project, global, local);
      if (frag != null) fragments.add(frag);
    }

    // 「完全禁用内置提示词」时只保留自定义来源(项目/全局)。
    final effectiveFragments = isBuiltinDisabled()
        ? fragments.where((f) => f.editable).toList()
        : fragments;

    return effectiveFragments
        .map((f) => f.body.trim())
        .where((s) => s.isNotEmpty)
        .join('\n\n');
  }

  /// 是否存在「完全禁用内置提示词」标记(全局层)。
  bool isBuiltinDisabled() => PromptFragmentResolver.isBuiltinDisabled(_globalDir);

  /// 保存某编号的覆盖。
  ///
  /// - [target] 指定写入层(项目/全局);null 表示写到该编号当前生效的层(只读层则回落可写层)。
  /// - [previousNumber] 编辑时若改了编号,传原编号,用于清掉旧编号的覆盖。
  /// - 同一编号只保留一份:写入前清掉各可写层里的同编号旧文件。
  bool saveOverride({
    required int number,
    required String title,
    required String content,
    PromptFragmentSource? target,
    int? previousNumber,
  }) {
    final project = _projectDir;
    final dir = switch (target) {
      PromptFragmentSource.project => project ?? _globalDir,
      PromptFragmentSource.global => _globalDir,
      _ => writableDir,
    };

    try {
      if (previousNumber != null && previousNumber != number) {
        _deleteOverridesFor(previousNumber, project);
        _deleteOverridesFor(previousNumber, _globalDir);
      }
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _deleteOverridesFor(number, dir);
      if (project != null && project != dir) _deleteOverridesFor(number, project);
      if (_globalDir != dir) _deleteOverridesFor(number, _globalDir);

      final file = File(p.join(dir.path, '${number.toString().padLeft(2, '0')}-${_sanitizeTitle(title)}.md'));
      file.writeAsStringSync(content);
      return true;
    } catch (e) {
      debugPrint('saveOverride failed: $e');
      return false;
    }
  }

  /// 按拖拽后的顺序重新编号并落盘:编号集合保持不变,只把各片段内容依次映射到这些编号,
  /// 从而改变注入顺序(数字越小越靠前)。写入可写层。
  bool reorder(List<PromptFragment> reordered) {
    if (reordered.isEmpty) return false;
    final project = _projectDir;
    final dir = writableDir;
    final numbers = reordered.map((f) => f.number).toList()..sort();

    try {
      if (!dir.existsSync()) dir.createSync(recursive: true);
      for (final number in numbers) {
        _deleteOverridesFor(number, dir);
        if (project != null && project != dir) _deleteOverridesFor(number, project);
        if (_globalDir != dir) _deleteOverridesFor(number, _globalDir);
      }
      for (var i = 0; i < reordered.length; i++) {
        final file = File(
          p.join(dir.path, '${numbers[i].toString().padLeft(2, '0')}-${_sanitizeTitle(reordered[i].title)}.md'),
        );
        file.writeAsStringSync(reordered[i].content);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除某编号的覆盖(仅当生效层可写),删后自动回退到下一层。
  bool deleteOverride(int number) {
    // 只能删除本地层(项目/全局)的文件
    final localLayers = listLocalLayers();
    for (final f in localLayers) {
      if (f.number == number && f.editable && f.file != null) {
        final file = f.file!;
        if (file.existsSync()) {
          file.deleteSync();
          return !file.existsSync();
        }
      }
    }
    return false;
  }

  /// 清空所有自定义提示词:删掉项目层与全局层里的全部 `<两位数字>-*.md`,
  /// 各编号随即回落到内置 / 本地层,等于把提示词「重置」回默认。
  ///
  /// 只删带编号的片段文件,全局层里的「完全禁用内置提示词」标记等其它文件原样保留。
  /// @return 实际删除的文件数。
  int deleteAllCustom() {
    final dirs = <Directory>[];
    if (_projectDir != null) dirs.add(_projectDir!);
    dirs.add(_globalDir);

    var deleted = 0;
    for (final dir in dirs) {
      final files = dir.listSync().whereType<File>().toList();
      for (final file in files) {
        if (PromptFragmentResolver.parseNumber(p.basename(file.path)) != null) {
          if (file.existsSync()) {
            file.deleteSync();
            if (!file.existsSync()) deleted++;
          }
        }
      }
    }
    return deleted;
  }

  /// 切换「完全禁用内置提示词」标记(全局层)。
  bool setBuiltinDisabled(bool disabled) {
    try {
      final marker = File(p.join(_globalDir.path, PromptFragmentResolver.disableBuiltinFile));
      if (disabled) {
        if (!_globalDir.existsSync()) _globalDir.createSync(recursive: true);
        marker.writeAsStringSync('');
      } else if (marker.existsSync()) {
        marker.deleteSync();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  PromptFragment? _resolveLocal(
    int number,
    Map<int, File> project,
    Map<int, File> global,
    Map<int, File> local,
  ) {
    if (project.containsKey(number)) {
      return _readFragment(project[number]!, number, PromptFragmentSource.project);
    }
    if (global.containsKey(number)) {
      return _readFragment(global[number]!, number, PromptFragmentSource.global);
    }
    if (local.containsKey(number)) {
      return _readFragment(local[number]!, number, PromptFragmentSource.local);
    }
    return null;
  }

  PromptFragment? _resolveFull(
    int number,
    Map<int, String> builtinIndex,
    Map<int, File> project,
    Map<int, File> global,
    Map<int, File> local,
  ) {
    if (project.containsKey(number)) {
      return _readFragment(project[number]!, number, PromptFragmentSource.project);
    }
    if (global.containsKey(number)) {
      return _readFragment(global[number]!, number, PromptFragmentSource.global);
    }
    if (local.containsKey(number)) {
      return _readFragment(local[number]!, number, PromptFragmentSource.local);
    }
    if (builtinIndex.containsKey(number)) {
      final content = builtinIndex[number]!;
      return PromptFragment(
        number: number,
        // 基线渲染只拼接正文,标题不参与;内置层没有文件名可推标题。
        title: 'builtin',
        source: PromptFragmentSource.builtin,
        content: content,
        file: null,
        description: PromptFragment.extractDescription(content),
      );
    }
    return null;
  }

  PromptFragment? _readFragment(File file, int number, PromptFragmentSource source) {
    try {
      final content = file.readAsStringSync();
      return PromptFragment(
        number: number,
        title: _titleOf(p.basename(file.path)),
        source: source,
        content: content,
        file: file,
        description: _extractDescription(content),
      );
    } catch (_) {
      return null;
    }
  }

  Map<int, File> _numberedFragments(Directory? dir) {
    if (dir == null || !dir.existsSync()) return {};
    final entries = PromptFragmentResolver.numberedFragments(dir);
    return {for (final e in entries) e.key: e.value};
  }

  bool _deleteOverridesFor(int number, Directory? dir) {
    if (dir == null || !dir.existsSync()) return false;
    final files = dir.listSync().whereType<File>().where((f) => PromptFragmentResolver.parseNumber(p.basename(f.path)) == number).toList();
    var deleted = false;
    for (final f in files) {
      if (f.existsSync()) {
        f.deleteSync();
        if (!f.existsSync()) deleted = true;
      }
    }
    return deleted;
  }

  String _titleOf(String fileName) {
    final base = fileName.replaceFirst('.md', '');
    final idx = base.indexOf('-');
    return idx >= 0 ? base.substring(idx + 1) : base;
  }

  String _extractDescription(String content) {
    final match = RegExp(r'^\s*<!--\s*(.*?)\s*-->', dotAll: true).firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }

  String _sanitizeTitle(String title) {
    final trimmed = title.trim();
    final sanitized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._\u4e00-\u9fa5-]'), '-');
    if (sanitized.isEmpty) return 'fragment';
    return sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
  }

  /// 场景提示词自定义目录名(`prompts.custom/scenarios/`)。
  static const String scenarioDirName = 'scenarios';

  /// 某项目类型的场景提示词自定义文件(项目层);无覆盖返回 null。
  File? scenarioProjectFile(ProjectKind kind) => _scenarioFile(_projectDir, kind);

  /// 某项目类型的场景提示词自定义文件(全局层);无覆盖返回 null。
  File? scenarioGlobalFile(ProjectKind kind) => _scenarioFile(_globalDir, kind);

  /// 保存某项目类型的场景提示词自定义覆盖(项目层或全局层)。
  /// 返回是否写入成功。写入后调用方应重新加载场景提示词。
  bool saveScenario(ProjectKind kind, String content, PromptFragmentSource scope) {
    final dir = switch (scope) {
      PromptFragmentSource.project => _projectDir,
      PromptFragmentSource.global => _globalDir,
      _ => writableDir,
    };
    final target = dir ?? _globalDir;
    if (target == null) return false;
    try {
      final scenariosDir = Directory(p.join(target.path, scenarioDirName));
      if (!scenariosDir.existsSync()) scenariosDir.createSync(recursive: true);
      final file = File(p.join(scenariosDir.path, '${kind.name}.md'));
      file.writeAsStringSync(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  File? _scenarioFile(Directory? dir, ProjectKind kind) {
    if (dir == null) return null;
    final file = File(p.join(dir.path, scenarioDirName, '${kind.name}.md'));
    return file.existsSync() ? file : null;
  }
}

/// 以当前工作区与配置目录为依据的目录实例。
final promptCatalogProvider = Provider<PromptFragmentCatalog>((ref) {
  final configDir = ref.watch(configDirProvider);
  final workspace = ref.watch(currentWorkspaceProvider);
  return PromptFragmentCatalog(configDir: configDir, workspaceRoot: workspace.rootPath);
});
