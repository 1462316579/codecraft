import 'package:flutter/widgets.dart';

/// 是否为大屏展开宽度(对照上游 `WindowSize.isExpandedWidth`:Material3 的 EXPANDED 档,≥840dp)。
/// 大屏下终端/浏览器/编辑器走工作台右栏,窄屏走整屏路由。
bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= 840;