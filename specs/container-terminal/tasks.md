# 任务清单：PRoot 容器终端

前置：`proot` 运行时资产已放入 `android/app/src/main/assets/proot/`（已完成）。

## [x] T1 运行环境安装器（Kotlin）
- 新建 `ProotInstaller.kt`：拷贝 `assets/proot` → `filesDir/proot`（staging + rename），复用 `ElfRunpath` 改写 RUNPATH，设置可执行位，写 `.installed` 版本标记。
- 提供 `prootStatus`（installed/installing/stage/error）、`ensureProot`（异步回调）。
- 提供 `chmodExecutable(paths: List<String>)` 供 rootfs 解压后置执行位。
- 验证：`grep` 确认方法签名，编译由 CI 校验。

## [x] T2 清理旧 Termux 终端
- `git rm -r android/app/src/main/assets/usr` 与 `assets/bootstrap_symlinks.txt`。
- 删除 `BootstrapInstaller.kt`，`MainActivity.kt` 移除对应通道分支。

## [x] T3 容器管理模块（Dart）
- `lib/data/container/container_manager.dart`：
  - 内置镜像表（Alpine 3.21.3 / Alpine 3.20.3 / Ubuntu Base 24.04.5，aarch64）。
  - `ContainerState`/`ContainerNotifier`：`refresh()`、`ensureRuntime()`、`install(image)`、`remove(id)`、`setDefault(id)`。
  - dio 下载带进度；`archive` 解压（文件/目录/软链/硬链 + mode → 执行位清单）。
  - 写 `etc/resolv.conf`；校验 `bin/sh`；staging → 正式目录。
  - 元数据持久化到 `shared_preferences` 键 `codecraft.containers.v1`。
- 验证：`flutter analyze` 无 error。

## [x] T4 统一启动参数
- `lib/data/container/container_launcher.dart`：`ContainerLaunchSpec` + `buildContainerSpec()`，含 `PROOT_LOADER`/`PROOT_LOADER_32`/`PROOT_TMP_DIR`，绑定 `-b /dev -b /proc -b /sys`、工作区同路径绑定、`-w`、`--kill-on-exit --link2symlink -0`。
- 未安装容器抛 `ContainerMissingException`。

## [x] T5 设置页「容器与镜像」
- 新建 `lib/features/settings/container_page.dart`（沿用 `SettingsGroup`/`SettingsGroupHeader` 风格）：运行环境状态、镜像下载/安装、已安装容器（设默认/删除）、进度与错误。
- `settings_page.dart` 加入口（`Iconfont.box` + 已存在的 `l10n.settingsContainer` / `settingsContainerSubtitle`）。
- `router.dart` 增加 `/settings/container`。

## [x] T6 终端切到 PRoot
- 重写 `lib/data/terminal/terminal_manager.dart` 启动段：`newTab()` → `buildContainerSpec` → `Pty.start`；删除 Termux 预检/降级链。
- `terminal_page.dart`：错误视图加「打开容器设置」次按钮；`kTerminalEngineTag` 升为 v4。
- 验证：`flutter test test/terminal_render_test.dart` 通过。

## [x] T7 AI 命令走容器
- `pty_command_engine.dart` 使用 `buildContainerSpec`；`isReady()/notReadyHint()` 反映容器状态。

## [x] T8 提交与验证
- `flutter analyze`；`flutter test test/terminal_render_test.dart`；提交并推送，等待 GitHub Actions；产物 `app-release-apk`。
- 交付真机验证步骤：设置 → 容器与镜像 → 下载 Alpine → 终端执行 `uname -a` / `apk add curl`。
