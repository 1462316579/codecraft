import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 容器初始化默认装的依赖集合回归:初始化菜单的「自动安装依赖」必须只装
/// 运行 Codespaces 所需(基础工具 + gh CLI),而不是把 Node/Python 也一并装上。
/// 这些是 shell 脚本,改错不会有编译期报错,因此用文本断言把契约钉住。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String read(String relative) => File(relative).readAsStringSync();

  test('场景文件与资产声明:codespaces 场景已打包', () async {
    final script = File('assets/codecraft/lib/scenarios/codespaces.sh');
    expect(script.existsSync(), isTrue);
    expect(read('assets/codecraft/lib/scenarios/codespaces.sh'), contains('install_light_runtimes "gh"'));

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(
      manifest.listAssets(),
      contains('assets/codecraft/lib/scenarios/codespaces.sh'),
      reason: 'pubspec 未声明该目录时 extractEnvTool 枚举不到,容器里就缺场景',
    );
  });

  test('gh 在各包管理器下都有包名映射', () {
    final common = read('assets/codecraft/lib/env-common.sh');
    expect(common, contains('apt:gh)      echo "gh"'));
    expect(common, contains('apk:gh)      echo "github-cli"'));
    expect(common, contains('pacman:gh)     echo "github-cli"'));
    expect(common, contains('dnf:gh|yum:gh)     echo "gh"'));
    // 清单里要能显示这一项,否则 show_plan 会漏掉 gh(装了却不说)。
    expect(common, contains('gh)     plan_line "GitHub CLI"'));
  });

  test('场景菜单把 codespaces 排在首位(即推荐默认)', () {
    final common = read('assets/codecraft/lib/env-common.sh');
    expect(
      common,
      contains('SCENARIO_IDS="codespaces common python node android flutter java go rust php base"'),
    );
  });

  test('初始化菜单的自动安装指向 codespaces 场景', () {
    final provision = read('assets/codecraft/provision.sh');
    expect(provision, contains('install_scenario codespaces'));
    expect(provision, isNot(contains('install_scenario common')),
        reason: '自动安装不应再回到通用开发场景(会多装 Node/Python)');
    expect(provision, contains('仅运行 Codespaces 所需'));
  });
}