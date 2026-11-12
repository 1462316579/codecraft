import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../agent/models/project.dart';
import '../../agent/tools/workspace.dart';
import '../../data/prompts.dart' show builtinScenarioContent, PromptFragment, PromptFragmentSource, PromptFragmentResolver, PromptFragmentCatalog, ScenarioPrompt, PromptsUiState, promptCatalogProvider;
import '../../data/workspaces.dart';

class PromptsViewModel extends ChangeNotifier {
  PromptsViewModel({
    required this.catalog,
    required this.workspaceProvider,
  });

  final PromptFragmentCatalog catalog;
  final Workspace workspaceProvider;

  PromptsUiState _state = const PromptsUiState(loading: true);
  PromptsUiState get state => _state;

  /// 完整刷新:重新扫描磁盘层并合并内置片段、场景提示词。
  Future<void> refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _loadOnce();
      } while (_refreshAgain);
    } finally {
      _refreshing = false;
    }
  }

  bool _refreshing = false;
  bool _refreshAgain = false;

  Future<void> _loadOnce() async {
    _state = _state.copyWith(loading: true);
    notifyListeners();

    final fragmentsFuture = _mergeLayers(catalog);
    final scenariosFuture = _loadScenarios(catalog);
    final fragments = await fragmentsFuture;
    final scenarios = await scenariosFuture;
    final builtinDisabled = catalog.isBuiltinDisabled();
    final hasWorkspace = workspaceProvider.rootPath.isNotEmpty;

    _state = PromptsUiState(
      fragments: fragments,
      scenarios: scenarios,
      builtinDisabled: builtinDisabled,
      hasWorkspace: hasWorkspace,
      guideText: '',
      guideOutdated: false,
      loading: false,
    );
    notifyListeners();
  }

  /// 保存某编号的覆盖(新建与编辑同一入口):写到所选作用域层;编辑改编号时清掉旧编号。
  /// 返回写入是否成功;失败时不刷新,由调用方决定是否提示并留在页面。
  Future<bool> saveFragment({
    required int number,
    required String title,
    required PromptFragmentSource scope,
    required String content,
    int? previousNumber,
  }) async {
    final ok = catalog.saveOverride(
      number: number,
      title: title,
      content: content,
      target: scope,
      previousNumber: previousNumber,
    );
    if (ok) await refresh();
    return ok;
  }

  /// 保存某项目类型的场景提示词自定义覆盖(编程 / 写作 / 应用逆向)。
  /// 保存后会清空场景缓存并刷新,使自定义内容立即生效。
  /// 返回写入是否成功。
  Future<bool> saveScenario({
    required ProjectKind kind,
    required String content,
    required PromptFragmentSource scope,
  }) async {
    final ok = catalog.saveScenario(kind, content, scope);
    if (ok) {
      _builtinScenarioCache = null;
      await refresh();
    }
    return ok;
  }

  /// 删除某编号的覆盖,自动回退到下一层。
  Future<bool> deleteFragment(int number) async {
    final ok = catalog.deleteOverride(number);
    if (ok) await refresh();
    return ok;
  }

  /// 批量删除(列表多选批量操作):一次 IO 里删完再刷新一次列表。
  Future<void> deleteFragments(List<int> numbers) async {
    if (numbers.isEmpty) return;
    for (final n in numbers) {
      catalog.deleteOverride(n);
    }
    await refresh();
  }

  /// 重置:清空项目层与全局层的所有自定义片段,各编号回落到内置提示词。
  Future<void> resetCustomFragments() async {
    catalog.deleteAllCustom();
    await refresh();
  }

  /// 拖拽重排:按新顺序重新编号并落盘,改变注入顺序。乐观更新本地状态,避免重读导致列表跳动。
  Future<void> reorderFragments(List<PromptFragment> reordered) async {
    final numbers = reordered.map((f) => f.number).toList()..sort();
    final renumbered = <PromptFragment>[];
    for (var i = 0; i < reordered.length; i++) {
      final f = reordered[i];
      renumbered.add(PromptFragment(
        number: numbers[i],
        title: f.title,
        source: f.source,
        content: f.content,
        file: f.file,
        description: f.description,
      ));
    }

    _state = _state.copyWith(fragments: renumbered);
    notifyListeners();

    final ok = catalog.reorder(renumbered);
    if (ok) {
      await refresh();
    } else {
      // 回滚到服务端顺序
      await refresh();
    }
  }

  /// 切换「完全禁用内置提示词」标记(全局层)。
  Future<void> setBuiltinDisabled(bool disabled) async {
    final ok = catalog.setBuiltinDisabled(disabled);
    if (ok) await refresh();
  }



  /// 三款内置场景提示词(编程 / 写作 / 应用逆向)进程级缓存。
  static List<ScenarioPrompt>? _builtinScenarioCache;

  /// 加载三款场景提示词:项目层 > 全局层 > 内置常量;进程级缓存避免重复解析。
  Future<List<ScenarioPrompt>> _loadScenarios(PromptFragmentCatalog catalog) async {
    final cached = _builtinScenarioCache;
    if (cached != null) return cached;

    final list = <ScenarioPrompt>[];
    for (final kind in ProjectKind.values) {
      // 项目层自定义文件优先
      final projectFile = catalog.scenarioProjectFile(kind);
      // 全局层自定义文件次之
      final globalFile = catalog.scenarioGlobalFile(kind);
      String content;
      PromptFragmentSource source;
      if (projectFile != null) {
        try {
          content = projectFile.readAsStringSync();
          source = PromptFragmentSource.project;
        } catch (_) {
          content = builtinScenarioContent(kind) ?? '';
          source = PromptFragmentSource.builtin;
        }
      } else if (globalFile != null) {
        try {
          content = globalFile.readAsStringSync();
          source = PromptFragmentSource.global;
        } catch (_) {
          content = builtinScenarioContent(kind) ?? '';
          source = PromptFragmentSource.builtin;
        }
      } else {
        content = builtinScenarioContent(kind) ?? '';
        source = PromptFragmentSource.builtin;
      }
      list.add(ScenarioPrompt(kind: kind, content: content, source: source));
    }
    _builtinScenarioCache = list;
    return list;
  }

  /// 内置数字片段(编号 → 片段),进程级缓存:assets 不可变,刷新时不必重读。
  static Map<int, PromptFragment>? _builtinFragmentCache;

  Future<List<PromptFragment>> _mergeLayers(PromptFragmentCatalog catalog) async {
    // 本地三层(项目/全局/本地)的片段在 listLocalLayers 里已读过正文,直接复用,不再重读。
    final local = <int, PromptFragment>{};
    for (final f in catalog.listLocalLayers()) {
      local[f.number] = f;
    }
    final builtin = await _loadBuiltinFragments();
    final numbers = <int>{...local.keys, ...builtin.keys}.toList()..sort();
    final merged = [
      for (final number in numbers) local[number] ?? builtin[number]!,
    ];
    if (catalog.isBuiltinDisabled()) {
      return merged.where((f) => f.editable).toList();
    }
    return merged;
  }

  /// 一次性并行读取全部内置数字片段(对齐上游 assets.list 目录扫描,避免逐文件顺序等待)。
  /// 解析结果进程级缓存:每次保存/删除后的刷新不必重读 assets。
  Future<Map<int, PromptFragment>> _loadBuiltinFragments() async {
    final cached = _builtinFragmentCache;
    if (cached != null) return cached;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final names = manifest.listAssets()
          .where((k) => k.startsWith('assets/prompts/') && k.endsWith('.md') && !k.contains('/agent/'))
          .map((k) => p.basename(k))
          .toList()
        ..sort();
      final entries = await Future.wait(names.map((name) async {
        final number = PromptFragmentResolver.parseNumber(name);
        if (number == null) return null;
        try {
          final content = await rootBundle.loadString('assets/prompts/$name');
          return MapEntry(
            number,
            PromptFragment(
              number: number,
              title: _titleOf(name),
              source: PromptFragmentSource.builtin,
              content: content,
              file: null,
              description: PromptFragment.extractDescription(content),
            ),
          );
        } catch (_) {
          return null;
        }
      }));
      final byNumber = <int, PromptFragment>{};
      for (final entry in entries) {
        if (entry != null && !byNumber.containsKey(entry.key)) {
          byNumber[entry.key] = entry.value;
        }
      }
      _builtinFragmentCache = byNumber;
      return byNumber;
    } catch (_) {
      return {};
    }
  }

  static String _titleOf(String fileName) {
    final base = fileName.replaceFirst('.md', '');
    final idx = base.indexOf('-');
    return idx >= 0 ? base.substring(idx + 1) : base;
  }
}

/// ViewModel provider:自动在首次访问时刷新。
final promptsViewModelProvider = ChangeNotifierProvider<PromptsViewModel>((ref) {
  final catalog = ref.watch(promptCatalogProvider);
  final workspace = ref.watch(currentWorkspaceProvider);
  final vm = PromptsViewModel(
    catalog: catalog,
    workspaceProvider: workspace,
  );
  Future.microtask(() => vm.refresh());
  return vm;
});
