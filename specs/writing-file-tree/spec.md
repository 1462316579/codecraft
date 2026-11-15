# 写作项目文件树「目录为空」修复

## 现象

写作项目「穿越女频只为救女」的文件面板中，树根显示 `.codecraft`、`小说章节`、`小说资料`、`角色关联`，
三个目录的 chevron 朝下（已展开）但没有任何子项；用户确认磁盘上实际有内容。

## 已排查结论（静态证据）

- `LocalWorkspaceFiles.listDir` 无任何过滤（不过滤空文件、隐藏文件、`.md`），实现正确。
- 子目录行图标为紫色、文字为正常色 → 未命中 `hasError`（`_dirErrors` 为空），说明 `listDir` 成功返回了**空列表**，
  不是异常、不是超时。
- 渲染层 `_appendChildren`/`_FileRow` 不丢弃任何条目（ignored 只改橙色，不隐藏）。
- 写作项目的文件工具确实走宿主实现：`workspaceFilesProvider` 在 `project.kind != coding` 时直接
  `LocalWorkspaceFiles(root: currentWorkspaceProvider.rootPath)`，与文件树同源，不存在容器/远端路径错位。
- 因此「目录为空」= 这三个目录在**文件树读取的路径**上确实没有条目；内容在别处。

## 根因判断

1. **主因（旧布局遗留）**：提交 `3348921` 之前，写作工作区根就是 `AI小说` 本身，AI 把章节与资料写在
   `AI小说/小说章节`、`AI小说/小说资料` 等**根级**目录。`3348921` 把工作区改为 `AI小说/<书名>` 后，
   文件树只读新目录，旧内容不再可见；新目录里只剩脚手架（三个空目录 + 5 个 0 字节 md）。
   `.codecraft` 出现在新目录，说明 `currentWorkspaceProvider` 已正确指向 `AI小说/<书名>`，即树根无误。
2. **次要问题（缓存残留）**：`build()` 中只有 `executionTarget` 变化才清空 `_expanded/_children/_dirErrors`，
   root 变化只触发 `_refresh`。切换工作区时可能残留旧根缓存，掩盖真实结果。
3. **弱假设（权限不可见）**：外部目录能列目录但读不到文件时（scoped storage 下的非媒体文件），
   当前只有 `_error != null` 才展示「所有文件访问权限」入口，用户没有任何可操作提示。

## 方案

### 1. 旧布局一次性迁移（主修复）

`lib/data/novel_project.dart` 新增 `NovelScaffold.migrateLegacyLayout(String writingRoot, String title)`：

- 若 `writingRoot/<dirName(title)>` 不存在 → 直接返回 0（不新建任何东西）。
- 依次处理 `角色关联`、`小说资料`、`小说章节` 三个固定目录：
  - 旧目录 `writingRoot/<目录名>` 不存在 → 跳过；
  - 目标目录 `writingRoot/<书名>/<目录名>` 不存在 → 创建；
  - 逐条搬运旧目录内容：
    - 目标同名项不存在 → `rename` 搬过去；
    - 目标同名项是 **0 字节文件** 且旧条目是非空文件 → 覆盖（搬家式替换空脚手架占位）；
    - 其余同名项 → 跳过，绝不覆盖用户数据；
  - 旧目录搬空后 `delete()`（非递归、失败忽略）；仍有内容则保留。
- 单条搬运失败（权限/跨设备）只跳过该条，不抛异常；返回成功搬运的条目数。

### 2. 文件树接入迁移 + 修复缓存残留

`lib/features/sessions/file_tree_tab.dart`：

- `build()`：`rootChanged` 时同样清空 `_expanded/_children/_dirErrors`（与 `targetChanged` 合并判断）。
- 新增 `bool _legacyMigrated = false;`，root 变化时重置为 false。
- `_refresh(root)` 开头（`_ensureRoot` 之后）：若当前工作区为 external 且 `!_legacyMigrated`，
  置位并 `await NovelScaffold.migrateLegacyLayout(p.dirname(root), p.basename(root))`；
  异常静默（迁移是尽力而为，失败不影响正常列目录）。

### 3. 外部工作区授权提示

`lib/features/sessions/file_tree_tab.dart`：

- 新增 `bool _externalNoAccess = false;`；`_refresh` 中对 `_needsStoragePermission(root)` 的工作区查
  `await ExternalStorage.hasAccess()`，结果写入该字段。
- 列表区域：当 `_externalNoAccess == true` 时，在树列表上方显示一条紧凑提示
  （`l10n.fileBrowserNeedPermission` + 「授予权限」按钮 → `requestAllFilesAccess()` 后 `_refresh(root)`），
  不再只在 `_error != null` 时出现。

### 4. 测试

新增 `test/novel_scaffold_migration_test.dart`（纯 `dart:io`，临时目录）：

- 旧根级 `小说章节/第1章.md` 迁移进 `AI小说/<书名>/小说章节`，旧目录被删除，返回 1；
- 目标已有非空同名文件 → 跳过、原文件内容不变；
- 目标只有 0 字节脚手架 md、旧文件非空 → 覆盖为旧内容；
- 再次调用返回 0（幂等），不产生重复文件。

## 影响面

- 仅影响写作项目的目录初始化与文件树读取；编程/逆向工作区逻辑不变（`currentWorkspaceProvider` 未改）。
- 迁移只搬运 `AI小说` 根级的三个固定目录内的条目，跳过同名非空项，可重复执行。

## 验证

1. `flutter analyze lib/data/novel_project.dart lib/features/sessions/file_tree_tab.dart test/novel_scaffold_migration_test.dart` 无 error。
2. `flutter test` 全部通过（含新增迁移测试）。
3. 真机：打开旧写作项目 → 文件树中三个目录出现原有章节/资料（旧内容搬入 `AI小说/<书名>/` 下）；
   新建小说后目录正常、刷新不重复搬运。

## 审批

请确认后开始实施（含提交与推送）。
