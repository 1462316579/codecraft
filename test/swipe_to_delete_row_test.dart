import 'package:codecraft/core/ui/swipe_to_delete_row.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 左滑删除行:滑动只露出删除按钮(不直接删),点按钮才回调 onDelete(对齐上游 SwipeToDeleteRow)。
void main() {
  /// 分多步移动:拖拽识别器把「触发识别的那次移动」吃掉,后续移动才产生 update。
  Future<void> swipeLeft(WidgetTester tester, Finder target, {double distance = 150}) async {
    final gesture = await tester.startGesture(tester.getCenter(target));
    for (var i = 0; i < 3; i++) {
      await gesture.moveBy(Offset(-distance / 3, 0));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> pumpRow(
    WidgetTester tester, {
    required VoidCallback onDelete,
    VoidCallback? onTap,
    bool deleteEnabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SwipeToDeleteRow(
            onDelete: onDelete,
            onTap: onTap,
            deleteEnabled: deleteEnabled,
            child: const SizedBox(height: 60, child: Center(child: Text('行内容'))),
          ),
        ),
      ),
    );
  }

  testWidgets('左滑露出删除按钮但不删除,点按钮才回调', (tester) async {
    var deleted = 0;
    var tapped = 0;
    await pumpRow(tester, onDelete: () => deleted++, onTap: () => tapped++);

    expect(find.text('删除'), findsNothing, reason: '未滑动时不显示删除按钮');

    await swipeLeft(tester, find.text('行内容'));
    expect(find.text('删除'), findsOneWidget);
    expect(deleted, 0, reason: '滑动本身不触发删除');
    expect(tapped, 0, reason: '滑开时点击是收回,不触发行点击');

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(find.text('删除'), findsNothing, reason: '点完收回');
  });

  testWidgets('未滑开时点行触发 onClick', (tester) async {
    var tapped = 0;
    await pumpRow(tester, onDelete: () {}, onTap: () => tapped++);
    await tester.tap(find.text('行内容'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('deleteEnabled=false:按钮可露出但点它无效', (tester) async {
    var deleted = 0;
    await pumpRow(tester, onDelete: () => deleted++, deleteEnabled: false);
    await swipeLeft(tester, find.text('行内容'));
    expect(find.text('删除'), findsOneWidget);
    await tester.tap(find.text('删除'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(deleted, 0);
  });

  testWidgets('滑不到一半就松手会收回', (tester) async {
    await pumpRow(tester, onDelete: () {});
    await swipeLeft(tester, find.text('行内容'), distance: 30);
    expect(find.text('删除'), findsNothing, reason: '少量滑动应回弹收起');
  });
}
