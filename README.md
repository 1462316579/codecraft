# CodeCraft

CodeCraft 是一款基于 Flutter 构建的移动端 AI 编程助手与集成开发工具，支持在 Android 设备上进行 AI 对话编程、项目管理、文件编辑、终端操作、Git 版本控制、抓包分析、应用逆向等开发工作。

## 主要功能

| 模块 | 说明 |
|------|------|
| **AI 聊天** | 支持 DeepSeek、Gemini、OpenAI 等多模型提供商，带技能系统、上下文管理、检查点、消息回退等 |
| **项目管理** | 支持编程、写作、应用逆向三种项目类型，自动创建工作区与首条会话 |
| **代码编辑器** | 内置代码编辑页面，支持语法高亮与文件操作 |
| **终端** | 内置 PTY 终端，支持命令行交互与容器内执行 |
| **Git 集成** | 支持 Git 状态、日志、分支、差异查看与提交 |
| **抓包分析** | 内置 HTTP/HTTPS 抓包，支持证书安装与请求响应查看 |
| **浏览器** | 内置 WebView 浏览器，可在应用内访问网页 |
| **Codespaces** | 支持 GitHub Codespaces 云开发环境 |
| **应用逆向** | APK 解包、arsc/axml/dex 资源编辑，支持已安装应用逆向分析 |
| **设置与更新** | 关于页显示版本号，支持自动检查更新，对接 GitHub Releases 最新版本 |

## 项目结构

```
codecraft/
├── android/                 # Android 原生工程
│   └── app/build.gradle     # APK 打包配置、签名方案、minSdk
├── lib/
│   ├── agent/               # AI 代理层：聊天控制器、会话、项目、工具、协议客户端
│   ├── app/                 # 应用外壳：主入口、路由、权限引导、底部导航
│   ├── core/                # 核心 UI、主题、终端、日志、工具类
│   ├── data/                # 数据层：数据库、存储、容器、抓包、Git、MCP、设置等
│   ├── features/            # 功能页面：首页、聊天、编辑器、Git、抓包、浏览器、逆向、设置
│   └── l10n/                # 多语言资源（中/英文）
├── assets/                  # 静态资源：字体、图标、技能、提示词、内置工具等
├── .github/workflows/ci.yml # CI：构建 APK 并发布到 GitHub Releases
├── pubspec.yaml             # Flutter 依赖配置
└── LICENSE                  # GPL-3.0 开源协议
```

## 构建与打包

### 环境要求

- Flutter SDK (稳定版)
- JDK 17
- Android SDK (compileSdk 36, buildTools 35.0.0)

### 获取依赖

```bash
flutter pub get
```

### 构建 APK

**只打包 arm64-v8a（默认）：**

```bash
flutter build apk --release
```

输出文件：`build/app/outputs/flutter-apk/codecraft-release.apk`

**打包 universal（所有 ABI：arm64-v8a、armv7、x86_64、x86）：**

```bash
flutter build apk --release --target-platform android-arm64,armv7,x86_64,x86
```

或通过 Gradle 属性：

```bash
flutter build apk --release -Puniversal=1
```

输出文件：`build/app/outputs/flutter-apk/codecraft-universal-release.apk`

**调试包：**

```bash
flutter build apk --debug
```

输出文件：`build/app/outputs/flutter-apk/codecraft-debug.apk`

### 签名配置

`android/app/build.gradle` 中的 `signingConfigs.upload` 已启用 v1 + v2 + v3 + v4 签名方案。构建前需在 `android/key.properties` 配置签名信息：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=你的别名
storeFile=upload-keystore.jks
```

并将签名密钥库文件放置于 `android/app/upload-keystore.jks`。

CI 构建时通过 GitHub Secrets 注入：
- `ANDROID_KEYSTORE_BASE64`：Base64 编码的密钥库文件
- `STORE_PASSWORD`、`KEY_PASSWORD`、`KEY_ALIAS`

### 最低支持版本

`minSdk = 14`（Android 4.0 Ice Cream Sandwich）。`targetSdk = 28` 以保持与 ZeroTermux/Termux 的兼容性。

## 版本更新机制

- **关于页**：点击版本行可检查更新，对接 GitHub API `repos/{owner}/{repo}/releases/latest`，优先使用 Release 的 `name` 字段作为展示版本，`tag_name` 用于版本比较。
- **首页**：应用启动时自动检查更新，若有新版本会弹窗提示是否更新，显示更新内容（Release body），点击「去更新」跳转 GitHub Releases 页面下载。
- 关于页支持开关「自动检查更新」，状态持久化至 `shared_preferences`。

## 开源协议

本项目采用 [GPL-3.0](LICENSE) 开源协议，协议全文见仓库根目录 `LICENSE` 文件。

## 关于页面

关于页采用液态柔光玻璃风格，包含以下行：
- 版本（点击检测更新）
- 自动检查更新（开关）
- 更新通道（稳定版）
- 下载镜像源
- GitHub 仓库（跳转 Releases）
- 开源许可证（GPL-3.0 全文）
- 用户协议
- 隐私政策
