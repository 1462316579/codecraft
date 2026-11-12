import 'package:codecraft/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 浏览器夜间模式要覆盖**整个页面**(顶栏/底栏/空态),而不只是 WebView 里的网页。
/// 实现方式:nightMode 开启时整页套用深色主题,因此深色主题必须是真正的深色。
void main() {
  test('深色主题的表面色足够暗(顶栏/底栏/空态都取它)', () {
    final dark = buildAppTheme(Brightness.dark).colorScheme;
    final luminance = dark.surface.computeLuminance();
    expect(luminance, lessThan(0.1),
        reason: '深色 surface 应接近黑,实际亮度 $luminance');
    // 文字必须反过来是浅色,否则黑底黑字。
    expect(dark.onSurface.computeLuminance(), greaterThan(0.5),
        reason: '深色主题的 onSurface 应是浅色');
  });

  test('浅色与深色主题的 surface 必须不同(否则换主题看不出效果)', () {
    final light = buildAppTheme(Brightness.light).colorScheme.surface;
    final dark = buildAppTheme(Brightness.dark).colorScheme.surface;
    expect(light, isNot(equals(dark)));
  });
}
