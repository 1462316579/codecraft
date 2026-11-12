import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/data/mcp/mcp_client.dart';
import 'package:codecraft/data/mcp/mcp_config.dart';
import 'package:codecraft/data/mcp/mcp_manager.dart';
import 'package:codecraft/features/settings/mcp_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 部件测试不能做真实连接:用固定状态的假管理器(build 里不发起网络)。
class _FakeMcpManager extends McpManager {
  _FakeMcpManager(this.initialState);

  final McpUiState initialState;

  @override
  McpUiState build() => initialState;
}

Widget _harness({
  required List<McpServerEntry> entries,
  McpUiState? state,
}) {
  return ProviderScope(
    overrides: [
      // 编辑器会用配置目录(经 workspaceProvider/configDirProvider)拼路径,测试里给固定值。
      workspaceProvider.overrideWithValue(Workspace('/tmp/mcp-page-test')),
      configDirProvider.overrideWithValue('/tmp/mcp-page-test-config'),
      mcpEntriesProvider.overrideWith((ref) => Future.value(entries)),
      mcpManagerProvider.overrideWith(() => _FakeMcpManager(state ?? const McpUiState())),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const McpPage(),
    ),
  );
}

void main() {
  testWidgets('空态:提示还没有配置 MCP 服务器', (tester) async {
    await tester.pumpWidget(_harness(entries: const []));
    await tester.pumpAndSettle();

    expect(find.text('MCP 服务器'), findsOneWidget); // 标题在上游同款的顶栏
    expect(find.text('还没有配置 MCP 服务器'), findsOneWidget);
    expect(find.text('点击右上角 + 可以添加远程 HTTP 或本地 stdio 服务器'), findsOneWidget);
  });

  testWidgets('列表:作用域/类型/状态 pills 与工具数', (tester) async {
    const entries = [
      McpServerEntry(
        McpServerConfig(name: 'remote', url: 'https://x/mcp'),
        McpScope.global,
      ),
      McpServerEntry(
        McpServerConfig(name: 'local', command: 'npx', args: ['-y', 'x']),
        McpScope.project,
      ),
    ];
    await tester.pumpWidget(_harness(
      entries: entries,
      state: const McpUiState(
        statuses: [
          McpServerStatus(name: 'remote', state: McpServerState.connected, toolCount: 3),
          McpServerStatus(name: 'local', state: McpServerState.failed),
        ],
        toolsByServer: {
          'remote': [McpToolDescriptor(name: 'search', description: '搜一搜')],
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('MCP 服务器'), findsOneWidget);
    expect(find.text('remote'), findsOneWidget);
    expect(find.text('local'), findsOneWidget);
    // 作用域 pills
    expect(find.text('全局'), findsOneWidget);
    expect(find.text('项目'), findsOneWidget);
    // 类型 pills
    expect(find.text('HTTP'), findsOneWidget);
    expect(find.text('stdio'), findsOneWidget);
    // 状态 pills 与工具数
    expect(find.text('已连接'), findsOneWidget);
    expect(find.text('3 个工具'), findsOneWidget);
    expect(find.text('需容器'), findsOneWidget);
    // 两台服务器时不出搜索框
    expect(find.text('搜索 MCP 服务器…'), findsNothing);
  });

  testWidgets('三台以上显示搜索框,可按名称过滤', (tester) async {
    const entries = [
      McpServerEntry(McpServerConfig(name: 'alpha', url: 'https://a/mcp'), McpScope.global),
      McpServerEntry(McpServerConfig(name: 'beta', url: 'https://b/mcp'), McpScope.global),
      McpServerEntry(McpServerConfig(name: 'gamma', url: 'https://c/mcp'), McpScope.global),
    ];
    await tester.pumpWidget(_harness(entries: entries));
    await tester.pumpAndSettle();

    expect(find.text('搜索 MCP 服务器…'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'be');
    await tester.pump();
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('alpha'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('未找到匹配的 MCP 服务器'), findsOneWidget);
  });

  testWidgets('编辑弹层:顶栏 + 基础设置/工具分段 + OAuth 认证区块', (tester) async {
    const entries = [
      McpServerEntry(
        McpServerConfig(name: 'remote', url: 'https://x/mcp', auth: McpAuthConfig()),
        McpScope.global,
      ),
    ];
    await tester.pumpWidget(_harness(entries: entries));
    await tester.pumpAndSettle();

    await tester.tap(find.text('remote'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('编辑 MCP'), findsOneWidget);
    expect(find.byTooltip('查看此 MCP 日志'), findsOneWidget);
    expect(find.byTooltip('刷新工具'), findsOneWidget);
    expect(find.text('基础设置'), findsOneWidget);
    expect(find.text('工具'), findsOneWidget);
    // 作用域 / 启用 / 名称 / 传输类型
    expect(find.text('作用域'), findsOneWidget);
    expect(find.text('是否启用'), findsOneWidget);
    expect(find.text('传输类型'), findsOneWidget);
    // OAuth 区块(该 server 已开启认证)
    expect(find.text('OAuth 认证'), findsOneWidget);
    expect(find.text('授权状态'), findsOneWidget);
    expect(find.text('未登录'), findsOneWidget);
    expect(find.text('登录 / 重新授权'), findsOneWidget);

    // 切到工具页:编辑已有 server 且无工具时给「点击刷新重试」提示(新建时才是「先保存」提示)
    await tester.tap(find.text('工具'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('未检测到工具,点击右上角刷新按钮重试'), findsOneWidget);
  });

  testWidgets('未连接状态显示为「未连接」', (tester) async {
    const entries = [
      McpServerEntry(McpServerConfig(name: 'idle', url: 'https://x/mcp'), McpScope.global),
    ];
    await tester.pumpWidget(_harness(entries: entries));
    await tester.pumpAndSettle();
    expect(find.text('未连接'), findsOneWidget);
  });
}