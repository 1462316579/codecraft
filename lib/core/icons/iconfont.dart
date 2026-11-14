import 'package:flutter/material.dart';

/// 基于阿里巴巴图标库 (iconfont.cn) 下载的字体文件图标定义。
///
/// 使用方式：
/// 1. 在 iconfont.cn 上创建项目并下载代码，将 iconfont.ttf 放入
///    assets/fonts/iconfont.ttf（pubspec.yaml 已配置）。
/// 2. 将下载的 symbol_unique_name.json 中的每个图标名称与码点填写到
///    下方的静态常量中（码点为 0x 开头的十六进制）。
/// 3. 在页面中使用 `Iconfont.名称`，例如 `Iconfont.home`。
class Iconfont {
  Iconfont._();

  /// 常用图标占位（码点需与你的阿里巴巴 iconfont 项目一致，否则显示方框）。
  static const IconData home = IconData(0xe600, fontFamily: 'Iconfont');
  static const IconData menu = IconData(0xe601, fontFamily: 'Iconfont');
  static const IconData plus = IconData(0xe602, fontFamily: 'Iconfont');
  static const IconData settings = IconData(0xe603, fontFamily: 'Iconfont');
  static const IconData terminal = IconData(0xe604, fontFamily: 'Iconfont');
  static const IconData close = IconData(0xe605, fontFamily: 'Iconfont');
  static const IconData alertCircle = IconData(0xe606, fontFamily: 'Iconfont');
  static const IconData arrowLeft = IconData(0xe607, fontFamily: 'Iconfont');
  static const IconData arrowUp = IconData(0xe608, fontFamily: 'Iconfont');
  static const IconData arrowDown = IconData(0xe609, fontFamily: 'Iconfont');
  static const IconData arrowRight = IconData(0xe60a, fontFamily: 'Iconfont');
  static const IconData file = IconData(0xe60b, fontFamily: 'Iconfont');
  static const IconData folder = IconData(0xe60c, fontFamily: 'Iconfont');
  static const IconData code = IconData(0xe60d, fontFamily: 'Iconfont');
  static const IconData browser = IconData(0xe60e, fontFamily: 'Iconfont');
  static const IconData refreshCw = IconData(0xe60f, fontFamily: 'Iconfont');
  static const IconData download = IconData(0xe610, fontFamily: 'Iconfont');
  static const IconData upload = IconData(0xe611, fontFamily: 'Iconfont');
  static const IconData checkCircle = IconData(0xe612, fontFamily: 'Iconfont');
  static const IconData copy = IconData(0xe613, fontFamily: 'Iconfont');
  static const IconData edit = IconData(0xe614, fontFamily: 'Iconfont');
  static const IconData trash = IconData(0xe615, fontFamily: 'Iconfont');
  static const IconData lock = IconData(0xe616, fontFamily: 'Iconfont');
  static const IconData play = IconData(0xe617, fontFamily: 'Iconfont');
  static const IconData stop = IconData(0xe618, fontFamily: 'Iconfont');
  static const IconData search = IconData(0xe619, fontFamily: 'Iconfont');
  static const IconData filter = IconData(0xe61a, fontFamily: 'Iconfont');
  static const IconData moreVertical = IconData(0xe61b, fontFamily: 'Iconfont');
  static const IconData pictureInPicture = IconData(0xe61c, fontFamily: 'Iconfont');
  static const IconData circleDot = IconData(0xe61d, fontFamily: 'Iconfont');
  static const IconData square = IconData(0xe61e, fontFamily: 'Iconfont');
  static const IconData pause = IconData(0xe61f, fontFamily: 'Iconfont');
  static const IconData checkCircle2 = IconData(0xe620, fontFamily: 'Iconfont');
  static const IconData arrowRightCircle = IconData(0xe621, fontFamily: 'Iconfont');
  static const IconData chevronRight = IconData(0xe622, fontFamily: 'Iconfont');
  static const IconData night = IconData(0xe623, fontFamily: 'Iconfont');
  static const IconData day = IconData(0xe624, fontFamily: 'Iconfont');
  static const IconData phone = IconData(0xe625, fontFamily: 'Iconfont');
  static const IconData tablet = IconData(0xe626, fontFamily: 'Iconfont');
  static const IconData desktop = IconData(0xe627, fontFamily: 'Iconfont');
  static const IconData sliders = IconData(0xe628, fontFamily: 'Iconfont');
  static const IconData check = IconData(0xe629, fontFamily: 'Iconfont');
  static const IconData sparkles = IconData(0xe62a, fontFamily: 'Iconfont');
  static const IconData flaskConical = IconData(0xe62b, fontFamily: 'Iconfont');
  static const IconData atSign = IconData(0xe62c, fontFamily: 'Iconfont');
  static const IconData filePlus = IconData(0xe62d, fontFamily: 'Iconfont');
  static const IconData fileText = IconData(0xe62e, fontFamily: 'Iconfont');
  static const IconData image = IconData(0xe62f, fontFamily: 'Iconfont');
  static const IconData camera = IconData(0xe630, fontFamily: 'Iconfont');
  static const IconData x = IconData(0xe631, fontFamily: 'Iconfont');
  static const IconData gitBranch = IconData(0xe632, fontFamily: 'Iconfont');
  static const IconData zap = IconData(0xe633, fontFamily: 'Iconfont');
  static const IconData info = IconData(0xe634, fontFamily: 'Iconfont');
  static const IconData hash = IconData(0xe635, fontFamily: 'Iconfont');
  static const IconData edit3 = IconData(0xe637, fontFamily: 'Iconfont');
  static const IconData globe = IconData(0xe639, fontFamily: 'Iconfont');
  static const IconData helpCircle = IconData(0xe63a, fontFamily: 'Iconfont');
  static const IconData cpu = IconData(0xe63b, fontFamily: 'Iconfont');
  static const IconData database = IconData(0xe63c, fontFamily: 'Iconfont');
  static const IconData wrench = IconData(0xe63d, fontFamily: 'Iconfont');
  static const IconData rotateCcw = IconData(0xe63e, fontFamily: 'Iconfont');
  static const IconData clock = IconData(0xe63f, fontFamily: 'Iconfont');
  static const IconData moreHorizontal = IconData(0xe640, fontFamily: 'Iconfont');
  static const IconData atom = IconData(0xe642, fontFamily: 'Iconfont');
  static const IconData shield = IconData(0xe643, fontFamily: 'Iconfont');
  static const IconData messageSquare = IconData(0xe644, fontFamily: 'Iconfont');
  static const IconData checkSquare = IconData(0xe645, fontFamily: 'Iconfont');
  static const IconData pencil = IconData(0xe646, fontFamily: 'Iconfont');
  static const IconData trash2 = IconData(0xe647, fontFamily: 'Iconfont');
  static const IconData activity = IconData(0xe648, fontFamily: 'Iconfont');
  static const IconData alertTriangle = IconData(0xe649, fontFamily: 'Iconfont');
  static const IconData appWindow = IconData(0xe64a, fontFamily: 'Iconfont');
  static const IconData archive = IconData(0xe64b, fontFamily: 'Iconfont');
  static const IconData barChart = IconData(0xe64c, fontFamily: 'Iconfont');
  static const IconData binary = IconData(0xe64d, fontFamily: 'Iconfont');
  static const IconData book = IconData(0xe64e, fontFamily: 'Iconfont');
  static const IconData box = IconData(0xe64f, fontFamily: 'Iconfont');
  static const IconData chevronDown = IconData(0xe650, fontFamily: 'Iconfont');
  static const IconData chevronUp = IconData(0xe651, fontFamily: 'Iconfont');
  static const IconData clipboard = IconData(0xe652, fontFamily: 'Iconfont');
  static const IconData cloud = IconData(0xe653, fontFamily: 'Iconfont');
  static const IconData crosshair = IconData(0xe654, fontFamily: 'Iconfont');
  static const IconData downloadCloud = IconData(0xe655, fontFamily: 'Iconfont');
  static const IconData edit2 = IconData(0xe656, fontFamily: 'Iconfont');
  static const IconData externalLink = IconData(0xe657, fontFamily: 'Iconfont');
  static const IconData eye = IconData(0xe658, fontFamily: 'Iconfont');
  static const IconData eyeOff = IconData(0xe659, fontFamily: 'Iconfont');
  static const IconData fileCode = IconData(0xe65a, fontFamily: 'Iconfont');
  static const IconData fileUp = IconData(0xe65b, fontFamily: 'Iconfont');
  static const IconData folderOpen = IconData(0xe65c, fontFamily: 'Iconfont');
  static const IconData folderPlus = IconData(0xe65d, fontFamily: 'Iconfont');
  static const IconData gitCommit = IconData(0xe65e, fontFamily: 'Iconfont');
  static const IconData gitMerge = IconData(0xe65f, fontFamily: 'Iconfont');
  static const IconData github = IconData(0xe660, fontFamily: 'Iconfont');
  static const IconData hardDrive = IconData(0xe661, fontFamily: 'Iconfont');
  static const IconData key = IconData(0xe662, fontFamily: 'Iconfont');
  static const IconData languages = IconData(0xe663, fontFamily: 'Iconfont');
  static const IconData minus = IconData(0xe664, fontFamily: 'Iconfont');
  static const IconData music = IconData(0xe665, fontFamily: 'Iconfont');
  static const IconData network = IconData(0xe666, fontFamily: 'Iconfont');
  static const IconData package = IconData(0xe667, fontFamily: 'Iconfont');
  static const IconData packageOpen = IconData(0xe668, fontFamily: 'Iconfont');
  static const IconData palette = IconData(0xe669, fontFamily: 'Iconfont');
  static const IconData pin = IconData(0xe66a, fontFamily: 'Iconfont');
  static const IconData pinOff = IconData(0xe66b, fontFamily: 'Iconfont');
  static const IconData plug = IconData(0xe66c, fontFamily: 'Iconfont');
  static const IconData power = IconData(0xe66d, fontFamily: 'Iconfont');
  static const IconData puzzle = IconData(0xe66e, fontFamily: 'Iconfont');
  static const IconData radio = IconData(0xe66f, fontFamily: 'Iconfont');
  static const IconData redo2 = IconData(0xe670, fontFamily: 'Iconfont');
  static const IconData save = IconData(0xe671, fontFamily: 'Iconfont');
  static const IconData scissors = IconData(0xe672, fontFamily: 'Iconfont');
  static const IconData server = IconData(0xe673, fontFamily: 'Iconfont');
  static const IconData slidersHorizontal = IconData(0xe674, fontFamily: 'Iconfont');
  static const IconData smartphone = IconData(0xe675, fontFamily: 'Iconfont');
  static const IconData sunMoon = IconData(0xe676, fontFamily: 'Iconfont');
  static const IconData tag = IconData(0xe677, fontFamily: 'Iconfont');
  static const IconData type = IconData(0xe678, fontFamily: 'Iconfont');
  static const IconData undo2 = IconData(0xe679, fontFamily: 'Iconfont');
  static const IconData uploadCloud = IconData(0xe67a, fontFamily: 'Iconfont');
  static const IconData user = IconData(0xe67b, fontFamily: 'Iconfont');
  static const IconData video = IconData(0xe67c, fontFamily: 'Iconfont');
  static const IconData xCircle = IconData(0xe67d, fontFamily: 'Iconfont');
}
