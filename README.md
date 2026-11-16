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

## 开源协议

本项目采用 [GPL-3.0](LICENSE) 开源协议，协议全文见仓库根目录 `LICENSE` 文件。