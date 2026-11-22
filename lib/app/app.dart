import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/settings/app_settings.dart';
import '../g11n/app_globalizations.dart';
import 'router.dart';
import 'permissions_gate.dart';

class CodecraftApp extends ConsumerWidget {
  const CodecraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppGlobalizations.of(context).appName,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: settings.themeMode.material,
      locale: settings.locale,
      localizationsDelegates: AppGlobalizations.localizationsDelegates,
      supportedLocales: AppGlobalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      // 权限引导挂在 MaterialApp 内部,保证首帧渲染完再弹系统授权框。
      builder: (context, child) => PermissionsGate(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}