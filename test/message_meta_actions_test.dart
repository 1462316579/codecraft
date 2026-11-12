import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/features/chat/widgets/message_bubble.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 气泡下方「复制 / 回退 / 更多」三个按钮的排布。
///
/// IconButton 即使只给 constraints 下限,默认 tapTargetSize 仍会把盒子撑到 48dp,
/// 三个按钮之间就会凭空多出二十多 dp 的空隙——那正是用户反馈的「间距过大」。
/// 这里按真实渲染尺寸断言,防止以后改样式时又把盒子撑开。
void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  List<Rect> iconRects(WidgetTester tester) {
    final finder = find.byType(Icon);
    return [
      for (var i = 0; i < finder.evaluate().length; i++) tester.getRect(finder.at(i)),
    ];
  }

  testWidgets('用户消息:复制/回退/更多三个按钮等距且紧凑', (tester) async {
    await tester.pumpWidget(wrap(MessageBubble(
      role: MessageRole.user,
      content: 'hello',
      timestamp: 1700000000000,
      showActions: true,
      onRewind: () {},
      onMore: () {},
    )));
    await tester.pump();

    final rects = iconRects(tester);
    expect(rects, hasLength(3));
    final gaps = [
      for (var i = 1; i < rects.length; i++) rects[i].left - rects[i - 1].right,
    ];
    // 三个图标两两之间的视觉间隙必须一致(不对称会显得杂乱)。
    expect(gaps[0], closeTo(gaps[1], 0.5));
    // 且足够紧凑:超过一格的间距就说明按钮盒子被撑大了。
    expect(gaps[0], lessThan(12));
  });

  testWidgets('助手消息:复制/更多两个按钮紧凑', (tester) async {
    await tester.pumpWidget(wrap(MessageBubble(
      role: MessageRole.assistant,
      content: 'answer',
      timestamp: 1700000000000,
      showActions: true,
      onMore: () {},
    )));
    await tester.pump();

    final rects = iconRects(tester);
    expect(rects, hasLength(2));
    expect(rects[1].left - rects[0].right, lessThan(12));
  });

  testWidgets('复制按钮的可点区域没有被压到图标大小', (tester) async {
    await tester.pumpWidget(wrap(MessageBubble(
      role: MessageRole.user,
      content: 'hello',
      timestamp: 1700000000000,
      showActions: true,
      onMore: () {},
    )));
    await tester.pump();

    // 紧凑归紧凑,点击区仍要不小于 20dp,否则难以点中。
    final button = tester.getSize(find.byType(IconButton).first);
    expect(button.width, greaterThanOrEqualTo(20));
    expect(button.height, greaterThanOrEqualTo(20));
  });
}