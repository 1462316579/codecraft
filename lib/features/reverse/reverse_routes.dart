/// 逆向项目的文件分流:按文件类型决定进哪个分析工具。
///
/// 只对逆向项目生效——写作/编程项目的二进制文件仍交给普通编辑器处理。
library;

/// `.dex` 进 Dex 编辑器,`.arsc` 进 ARSC 编辑器,`AndroidManifest.xml` 进 AXML 反编译页;
/// 其余返回 null(交给普通编辑器)。
String? reverseRouteForPath(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1).toLowerCase();
  if (name.endsWith('.dex')) return '/reverse/dex';
  if (name.endsWith('.arsc')) return '/reverse/arsc';
  if (name == 'androidmanifest.xml') return '/reverse/manifest';
  return null;
}

/// 十六进制视图的路由(带 path 查询参数)。
String hexRouteForPath(String path) =>
    '/reverse/hex?path=${Uri.encodeQueryComponent(path)}';

/// 给路由拼上文件路径。
String reverseRouteWithPath(String route, String path) =>
    '$route?path=${Uri.encodeQueryComponent(path)}';