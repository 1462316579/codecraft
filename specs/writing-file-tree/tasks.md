# 任务清单：写作项目文件树「目录为空」修复

1. [x] `lib/data/novel_project.dart`：新增 `NovelScaffold.migrateLegacyLayout(writingRoot, title)`
   （搬运旧根级三个固定目录内容、跳过非空同名项、可替换 0 字节脚手架文件、搬空后删旧目录、失败只跳过并返回搬运条数）。
2. [x] `lib/features/sessions/file_tree_tab.dart`：
   - root 变化时清空 `_expanded/_children/_dirErrors`；
   - `_refresh` 中对 external 工作区首次调用 `migrateLegacyLayout` 并在 root 变化时重置标记；
   - 新增 `_externalNoAccess`（`ExternalStorage.hasAccess()` 检测）与顶部授权提示条（含授权按钮）。
3. [x] 新增 `test/novel_scaffold_migration_test.dart`：迁移、跳过、覆盖空文件、幂等四个用例。
4. [x] 校验：`flutter analyze`（改动文件无 error）、`flutter test` 全部通过。
5. [x] 提交并推送，`gh run watch <id> --exit-status` 等待 CI 通过。
