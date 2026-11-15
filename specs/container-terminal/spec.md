# 规格：移除 Termux 终端，改用 PRoot 容器（对齐 AIcode）

状态：待批准
日期：2026-11-15
范围：Android（Flutter + Kotlin）本地终端与命令执行

## 1. 目标

1. 删除现有「Termux bootstrap + 直接 exec bash」的终端启动链（反复失败：bash 秒退、空白屏）。
2. 终端改为在 **PRoot 容器**内运行，交互体验与 AIcode 一致：进入即得到一个可用的 shell，容器内可 `apk`/`apt` 装包。
3. 设置页新增「容器与镜像」页面：查看 PRoot 运行环境状态、下载容器镜像、安装/删除容器、设默认容器。
4. AI 的命令执行与终端共用同一容器运行参数，保证「终端里能跑的，AI 也能跑」。

保留（已验证可用、不改动行为）：终端渲染/解析引擎 `lib/core/terminal/*`（含 `tests/terminal_render_test.dart` 覆盖的渲染、resize、scrollback）。

## 2. 已确认的技术事实（本次调研结论）

- Termux 包 `proot_5.1.107.102_aarch64.deb` 提供：
  - `bin/proot`（259832 字节），NEEDED = `libtalloc.so.2`、`libandroid-shmem.so`、`libc.so`
  - RUNPATH = `/data/data/com.termux/files/usr/lib`（需改写为 `$ORIGIN/../lib`）
  - `libexec/proot/loader`、`libexec/proot/loader32`
- **loader 路径是编译期硬编码**的绝对路径 `/data/data/com.termux/files/usr/libexec/proot/loader`（46 字节，短于我们真实路径，无法等长改写）→ 必须通过环境变量 `PROOT_LOADER` / `PROOT_LOADER_32` 覆盖。
- `libtalloc` 来自 `libtalloc_2.5.0_aarch64.deb`（SONAME `libtalloc.so.2`，33592 字节）。
- `libandroid-shmem` 来自 `libandroid-shmem_0.7_aarch64.deb`（14432 字节，无 SONAME，按原名 `libandroid-shmem.so` 使用）。
- 本工程 `targetSdk = 28`（`android/app/build.gradle`），允许从应用私有目录 exec，也允许 ptrace 自身子进程，满足 PRoot 运行条件。
- 现有 `BootstrapInstaller.ElfRunpath` 已实现「等长/变短改写 ELF RUNPATH」并保留其余段结构，可直接复用。
- `archive 3.6.1` 提供 `GZipDecoder` + `TarDecoder`；`TarFile` 有 `mode`、`typeFlag`、`nameOfLinkedFile`，可据此还原权限与符号链接。
- 可用镜像源（已 HTTP 200 验证）：
  - Alpine 3.21.3 arm64 minirootfs（约 3.85 MB）
  - Alpine 3.20.3 arm64 minirootfs（约 3.95 MB）
  - Ubuntu Base 24.04.5 arm64（约 30 MB，chunked 无 content-length）

## 3. 架构决策

### 3.1 运行环境（最小化，不再内置 97MB Termux）

- 新增资产目录 `android/app/src/main/assets/proot/`：
  - `bin/proot`
  - `libexec/proot/loader`、`libexec/proot/loader32`
  - `lib/libtalloc.so.2`、`lib/libandroid-shmem.so`
- 首次进入容器页/终端时，`ProotInstaller` 把上述资产拷贝到 `filesDir/proot`，改写 RUNPATH（`bin/proot`→`$ORIGIN/../lib`，`lib/*.so`→`$ORIGIN`），对 `bin/proot`、`libexec/proot/*` 设置可执行位，写版本标记 `.installed`。
- 删除 `android/app/src/main/assets/usr/**`（3484 个文件，97MB）与 `assets/bootstrap_symlinks.txt`，删除 `BootstrapInstaller.kt`。

### 3.2 容器数据布局

```
filesDir/proot/            PRoot 运行环境（由 APK 资产安装）
filesDir/containers/<id>/  rootfs（解压后的容器根目录）
filesDir/containers/.downloads/<image>.tar.gz  下载缓存（安装后删除）
```

容器元数据（列表 / 默认容器）用 `shared_preferences` 的 JSON 保存，键 `codecraft.containers.v1`。

### 3.3 启动参数（终端与 AI 命令共用）

```
<filesDir>/proot/bin/proot
  --kill-on-exit --link2symlink -0
  -r <rootfs>
  -b /dev -b /proc -b /sys
  -b <docsDir>:<docsDir>      # 工作区（应用文档目录）以相同绝对路径映射进容器
  -w <docsDir>                # 终端与命令默认 cwd
  /bin/sh -l
```

环境变量：
```
PROOT_LOADER   = <filesDir>/proot/libexec/proot/loader
PROOT_LOADER_32= <filesDir>/proot/libexec/proot/loader32
PROOT_TMP_DIR  = <filesDir>/proot/tmp
HOME=/root  TERM=xterm-256color  LANG=C.UTF-8
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

`<docsDir>` 取自现有 `workspaceProvider`（`getApplicationDocumentsDirectory()`），使 AI 工具使用的宿主绝对路径在容器内同样有效。

### 3.4 安装镜像时的文件处理

解压 `tar.gz` 到 `containers/.staging-<id>`：
- 普通文件：写入字节；按 `TarFile.mode & 0o111 != 0` 记录待加执行位。
- 目录：创建。
- 符号链接（`typeFlag == '2'`）：`Link(...).create(target)`。
- 硬链接（`typeFlag == '1'`）：`Link(...).create(指向已解压文件)`（Android 上等价可用）。
- 完成解压后写入 `etc/resolv.conf`（`nameserver 8.8.8.8` / `1.1.1.1`）。
- 通过新增通道方法 `chmodExecutable` 批量给记录的文件加执行位（一次调用传路径数组）。
- 校验 `rootfs/bin/sh` 存在后，`rename` 到 `containers/<id>`；失败则删除 staging 并报错。

## 4. 文件级改动清单

### 新增

| 文件 | 内容 |
| --- | --- |
| `android/app/src/main/assets/proot/**` | 已放入 proot 运行时（见 3.1） |
| `android/app/src/main/kotlin/ids/codecraft/app/ProotInstaller.kt` | 资产拷贝、RUNPATH 改写（复用 `ElfRunpath`）、设可执行位、`isInstalled/installing/stage/lastError`、`chmodExecutable(List<String>)` |
| `lib/data/container/container_manager.dart` | `ContainerImage`（内置镜像表）、`ContainerInfo`、`ContainerState`、`ContainerNotifier`（Riverpod `NotifierProvider`）、下载（dio，进度回调）、解压安装、删除、设默认、`ensureRuntime()` |
| `lib/data/container/container_launcher.dart` | 单一入口 `Future<LaunchSpec> buildContainerSpec({String? workdir})`：确保运行环境 + 默认容器，返回 `{path, arguments, environment, workdir}`；未安装容器时抛 `ContainerMissingException` |
| `lib/features/settings/container_page.dart` | 「容器与镜像」页：运行环境状态卡、可下载镜像列表、已安装容器列表（设默认/删除）、进度与错误展示 |

### 修改

| 文件 | 改动 |
| --- | --- |
| `android/app/src/main/kotlin/ids/codecraft/app/MainActivity.kt` | 通道方法：删除 `bootstrapStatus`/`ensureBootstrap`/`terminalPreflight`；新增 `prootStatus`、`ensureProot`、`chmodExecutable` |
| `lib/features/settings/settings_page.dart` | 「主题」之后新增 `SettingsRow(icon: Iconfont.box, title: l10n.settingsContainer, subtitle: l10n.settingsContainerSubtitle, onTap: → '/settings/container')` |
| `lib/app/router.dart` | 新增子路由 `container` → `ContainerPage` |
| `lib/data/terminal/terminal_manager.dart` | 删除 `TermuxBootstrap`/`TerminalPreflightResult`/`_LaunchSpec`/`_launchSpecs`；`newTab()` 改走 `buildContainerSpec`；未安装容器时抛出可识别错误；横幅改为 `CodeCraft Terminal · <容器名>`；保留标签管理、镜像标签、resize/write 等逻辑 |
| `lib/features/terminal/terminal_page.dart` | `_ErrorView` 增加可选次按钮「打开容器设置」（`context.push('/settings/container')`）；版本标识改为 v4 |
| `lib/core/terminal/terminal.dart` | `kTerminalEngineTag = 'v4 · 2026-11-15'` |
| `lib/data/container/pty_command_engine.dart` | 启动改为 `buildContainerSpec` 的结果（无容器时抛 `notReadyHint`），保留 `_PtyTerminalProcess` 与超时逻辑 |
| `android/app/build.gradle` | 无需改（`targetSdk 28` 保持） |

### 删除

- `android/app/src/main/assets/usr/**`（97MB）
- `android/app/src/main/assets/bootstrap_symlinks.txt`
- `android/app/src/main/kotlin/ids/codecraft/app/BootstrapInstaller.kt`

## 5. 行为细节

1. **首次进入终端**：若 PRoot 运行环境或默认容器缺失 → 终端页显示「尚未安装容器」+「打开容器设置」按钮，不显示空白终端。
2. **容器页安装**：点击镜像「下载并安装」→ 显示百分比进度 → 解压阶段显示「正在解压」→ 成功后自动设为默认（若无默认）。
3. **删除默认容器**：自动回退到剩余容器中第一个，无剩余则清空默认。
4. **终端横幅**：`CodeCraft Terminal · <容器名> (PRoot)`；容器 shell 退出后打印退出码，不再自动降级到系统 sh。
5. **AI 命令**：`PtyCommandEngine` 在容器内执行；容器未安装时 `isReady()` 返回 false，`notReadyHint()` 返回「请到 设置 → 容器与镜像 安装容器」。

## 6. 验证

1. `cd android && ./gradlew :app:assembleDebug`（本地若环境不可用则以 CI 为准）。
2. `flutter analyze` 无 error/warning（允许既有 info）。
3. `flutter test test/terminal_render_test.dart` 全绿。
4. 本地 Python 复刻验证：对 `assets/proot/bin/proot` 执行 RUNPATH 改写后 `readelf -d` 仍解析正常（结构不变、INTERP 保留）。
5. CI：推送后 GitHub Actions run 成功，产物 `app-release-apk` 生成。
6. 真机：安装 → 设置 → 容器与镜像 → 下载 Alpine → 返回终端 → 输入 `uname -a`、`apk add curl`、`ls` 正常；AI 对话中执行 `pwd` 落在工作区目录。

## 7. 风险与回退

- 风险：proot 在本机 SELinux/ptrace 限制下不可用。缓解：保留「容器未就绪」明确报错文案；不改动已验证的渲染引擎，便于后续替换执行后端。
- 风险：Ubuntu Base 解压耗时与磁盘占用较大。缓解：默认推荐 Alpine，且安装前显示体积。
- 回退：`container_launcher.dart` 是唯一启动入口，回退只需改此文件与 `pty_command_engine.dart`。
