import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../agent/models/project.dart';
import '../agent/models/skill.dart';
import '../features/browser/browser_page.dart';
import '../features/capture/capture_page.dart';
import '../features/codespaces/codespaces_page.dart';
import '../features/credentials/credential_page.dart';
import '../features/editor/editor_page.dart';
import '../features/editor/editor_settings_page.dart';
import '../features/git/git_page.dart';
import '../features/reverse/arsc_editor_page.dart';
import '../features/reverse/axml_editor_page.dart';
import '../features/reverse/dex_editor_page.dart';
import '../features/reverse/hex_editor_page.dart';
import '../features/settings/provider_edit_page.dart';
import '../features/settings/providers_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/container_page.dart';
import '../features/settings/general_page.dart';
import '../features/settings/log_page.dart';
import '../features/terminal/terminal_page.dart';
import '../features/settings/mcp_page.dart';
import '../features/settings/permissions_page.dart';
import '../features/settings/software_permissions_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/token_stats_page.dart';
import '../features/settings/theme_page.dart';
import '../features/settings/skill_edit_page.dart';
import '../features/settings/skills_page.dart';
import '../features/settings/prompt_detail_page.dart';
import '../features/settings/prompt_edit_page.dart';
import '../features/settings/prompts_page.dart';
import '../data/prompts.dart';
import '../features/settings/storage_page.dart';
import 'chat_route_page.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatRoutePage(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/permissions-system',
        builder: (context, state) => const SoftwarePermissionsPage(),
      ),
      GoRoute(
        path: '/credentials',
        builder: (context, state) => const CredentialPage(),
      ),
      GoRoute(
        path: '/codespaces',
        builder: (context, state) => const CodespacesPage(),
      ),
      GoRoute(
        path: '/editor/settings',
        builder: (context, state) => const EditorSettingsPage(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => EditorPage(
          path: state.uri.queryParameters['path'] ?? '',
          line: int.tryParse(state.uri.queryParameters['line'] ?? ''),
        ),
      ),
      // 逆向工具:按文件类型进对应的分析页(入口在文件树里,只对逆向项目开放)。
      GoRoute(
        path: '/reverse/dex',
        builder: (context, state) => DexEditorPage(
          path: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reverse/arsc',
        builder: (context, state) => ArscEditorPage(
          path: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reverse/hex',
        builder: (context, state) => HexEditorPage(
          path: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reverse/manifest',
        builder: (context, state) => AXmlEditorPage(
          path: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/terminal',
        builder: (context, state) => const TerminalPage(),
      ),
      GoRoute(
        path: '/browser',
        builder: (context, state) => const BrowserPage(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CapturePage(),
      ),
      GoRoute(
        path: '/git',
        builder: (context, state) => GitPage(
          onNavigateToCredentials: () => context.push('/credentials'),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'token-stats',
            builder: (context, state) => const TokenStatsPage(),
          ),
          GoRoute(
            path: 'storage',
            builder: (context, state) => const StoragePage(),
          ),
          GoRoute(
            path: 'logs',
            builder: (context, state) => LogPage(
              filterServerName: state.uri.queryParameters['server'],
            ),
          ),
          GoRoute(
            path: 'providers',
            builder: (context, state) => const ProvidersPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ProviderEditPage(
                  providerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'mcp',
            builder: (context, state) => const McpPage(),
          ),
          GoRoute(
            path: 'permissions',
            builder: (context, state) => const PermissionsPage(),
          ),
          GoRoute(
            path: 'general',
            builder: (context, state) => const GeneralPage(),
          ),
          GoRoute(
            path: 'container',
            builder: (context, state) => const ContainerPage(),
            routes: [
              GoRoute(
                path: 'download',
                builder: (context, state) => const ContainerDownloadPage(),
              ),
            ],
          ),
          GoRoute(
            path: 'theme',
            builder: (context, state) => const ThemePage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: 'prompts',
            builder: (context, state) => const PromptsPage(),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) => PromptDetailPage(
                  number: state.uri.queryParameters['number'] == null
                      ? null
                      : int.parse(state.uri.queryParameters['number']!),
                  kind: state.uri.queryParameters['kind'] == null
                      ? null
                      : ProjectKind.parse(state.uri.queryParameters['kind']),
                ),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final kindStr = state.uri.queryParameters['kind'];
                  final kind = kindStr == null
                      ? null
                      : ProjectKind.parse(kindStr);
                  return PromptEditPage(
                    number: state.uri.queryParameters['number'] == null
                        ? null
                        : int.parse(state.uri.queryParameters['number']!),
                    kind: kind,
                    initialTitle: state.uri.queryParameters['title'] == null
                        ? null
                        : state.uri.queryParameters['title']!,
                    initialDescription: state.uri.queryParameters['description'] == null
                        ? null
                        : state.uri.queryParameters['description']!,
                    initialContent: state.uri.queryParameters['content'] == null
                        ? null
                        : state.uri.queryParameters['content']!,
                    initialScope: state.uri.queryParameters['scope'] == 'global'
                        ? PromptFragmentSource.global
                        : PromptFragmentSource.project,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'skills',
            builder: (context, state) => const SkillsPage(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final raw = state.uri.queryParameters['name'];
                  return SkillEditPage(
                    skillName: raw,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
