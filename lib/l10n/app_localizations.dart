import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'CodeCraft'**
  String get appName;

  /// No description provided for @tabSessions.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get tabSessions;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @newSession.
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get newSession;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @reverseTabClasses.
  ///
  /// In zh, this message translates to:
  /// **'类'**
  String get reverseTabClasses;

  /// No description provided for @reverseTabStrings.
  ///
  /// In zh, this message translates to:
  /// **'字符串池'**
  String get reverseTabStrings;

  /// No description provided for @reverseTabResources.
  ///
  /// In zh, this message translates to:
  /// **'资源'**
  String get reverseTabResources;

  /// No description provided for @reverseTabHex.
  ///
  /// In zh, this message translates to:
  /// **'十六进制'**
  String get reverseTabHex;

  /// No description provided for @reverseSearchClassHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索类名'**
  String get reverseSearchClassHint;

  /// No description provided for @reverseSearchStringHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索字符串'**
  String get reverseSearchStringHint;

  /// No description provided for @reverseSearchResourceHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索资源名、类型或 0x 编号'**
  String get reverseSearchResourceHint;

  /// No description provided for @reverseNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配项'**
  String get reverseNoMatch;

  /// No description provided for @reverseEmptyFile.
  ///
  /// In zh, this message translates to:
  /// **'文件为空'**
  String get reverseEmptyFile;

  /// No description provided for @reverseLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开失败'**
  String get reverseLoadFailed;

  /// No description provided for @reverseParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'解析失败,这个文件可能被加固或已损坏'**
  String get reverseParseFailed;

  /// No description provided for @reverseEditString.
  ///
  /// In zh, this message translates to:
  /// **'修改字符串'**
  String get reverseEditString;

  /// No description provided for @reverseEqualLengthHint.
  ///
  /// In zh, this message translates to:
  /// **'只能等长替换:新内容编码后的字节数必须与原字符串一致,否则文件内偏移会全部错位'**
  String get reverseEqualLengthHint;

  /// No description provided for @reverseEditByte.
  ///
  /// In zh, this message translates to:
  /// **'修改字节'**
  String get reverseEditByte;

  /// No description provided for @reverseEditByteHint.
  ///
  /// In zh, this message translates to:
  /// **'输入两位十六进制,例如 0a、ff'**
  String get reverseEditByteHint;

  /// No description provided for @reverseInvalidByte.
  ///
  /// In zh, this message translates to:
  /// **'请输入 00-ff 之间的十六进制字节'**
  String get reverseInvalidByte;

  /// No description provided for @reverseJumpToOffset.
  ///
  /// In zh, this message translates to:
  /// **'跳转到偏移'**
  String get reverseJumpToOffset;

  /// No description provided for @reverseOffsetInvalid.
  ///
  /// In zh, this message translates to:
  /// **'偏移无效,请输入十六进制'**
  String get reverseOffsetInvalid;

  /// No description provided for @reverseSuperclass.
  ///
  /// In zh, this message translates to:
  /// **'父类'**
  String get reverseSuperclass;

  /// No description provided for @reverseInterfaces.
  ///
  /// In zh, this message translates to:
  /// **'接口'**
  String get reverseInterfaces;

  /// No description provided for @reverseAccessFlags.
  ///
  /// In zh, this message translates to:
  /// **'修饰符'**
  String get reverseAccessFlags;

  /// No description provided for @reverseFields.
  ///
  /// In zh, this message translates to:
  /// **'字段'**
  String get reverseFields;

  /// No description provided for @reverseMethods.
  ///
  /// In zh, this message translates to:
  /// **'方法'**
  String get reverseMethods;

  /// No description provided for @reverseAbstractMethod.
  ///
  /// In zh, this message translates to:
  /// **'无方法体'**
  String get reverseAbstractMethod;

  /// No description provided for @reverseSmaliHint.
  ///
  /// In zh, this message translates to:
  /// **'以上为 smali 反汇编结果;offset 是该指令在方法体内的字节偏移'**
  String get reverseSmaliHint;

  /// No description provided for @reverseOpenAsHex.
  ///
  /// In zh, this message translates to:
  /// **'以十六进制打开'**
  String get reverseOpenAsHex;

  /// No description provided for @reverseMethodCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个方法'**
  String reverseMethodCount(int count);

  /// No description provided for @reverseFieldCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个字段'**
  String reverseFieldCount(int count);

  /// No description provided for @reverseHexByteCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 字节'**
  String reverseHexByteCount(int count);

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @pin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get unpin;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchSessions.
  ///
  /// In zh, this message translates to:
  /// **'搜索会话'**
  String get searchSessions;

  /// No description provided for @noSessions.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话'**
  String get noSessions;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'开始新的对话吧'**
  String get noMessages;

  /// No description provided for @chatInputPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入消息,与 AI 对话…'**
  String get chatInputPlaceholder;

  /// No description provided for @reasoningTitle.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get reasoningTitle;

  /// No description provided for @untitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名'**
  String get untitled;

  /// No description provided for @pinned.
  ///
  /// In zh, this message translates to:
  /// **'已置顶'**
  String get pinned;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @providers.
  ///
  /// In zh, this message translates to:
  /// **'AI 提供商'**
  String get providers;

  /// No description provided for @providersSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'模型、接口与密钥'**
  String get providersSubtitle;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeModeDark;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @license.
  ///
  /// In zh, this message translates to:
  /// **'开源协议'**
  String get license;

  /// No description provided for @licenseBody.
  ///
  /// In zh, this message translates to:
  /// **'本项目是 jieapi/Codecraft 的 Flutter 复刻,按 GPL-3.0 协议开源。'**
  String get licenseBody;

  /// No description provided for @addProvider.
  ///
  /// In zh, this message translates to:
  /// **'添加供应商'**
  String get addProvider;

  /// No description provided for @providerName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get providerName;

  /// No description provided for @providerType.
  ///
  /// In zh, this message translates to:
  /// **'协议'**
  String get providerType;

  /// No description provided for @baseUrl.
  ///
  /// In zh, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @apiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @defaultModel.
  ///
  /// In zh, this message translates to:
  /// **'默认模型'**
  String get defaultModel;

  /// No description provided for @modelList.
  ///
  /// In zh, this message translates to:
  /// **'模型列表'**
  String get modelList;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @mode.
  ///
  /// In zh, this message translates to:
  /// **'模式'**
  String get mode;

  /// No description provided for @reasoningEffort.
  ///
  /// In zh, this message translates to:
  /// **'思考强度'**
  String get reasoningEffort;

  /// No description provided for @reasoningEffortNone.
  ///
  /// In zh, this message translates to:
  /// **'不思考'**
  String get reasoningEffortNone;

  /// No description provided for @reasoningEffortMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极低'**
  String get reasoningEffortMinimal;

  /// No description provided for @reasoningEffortLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get reasoningEffortLow;

  /// No description provided for @reasoningEffortMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get reasoningEffortMedium;

  /// No description provided for @reasoningEffortHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get reasoningEffortHigh;

  /// No description provided for @reasoningEffortXHigh.
  ///
  /// In zh, this message translates to:
  /// **'极高'**
  String get reasoningEffortXHigh;

  /// No description provided for @reasoningEffortMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get reasoningEffortMax;

  /// No description provided for @deleteProviderConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该供应商?'**
  String get deleteProviderConfirm;

  /// No description provided for @deleteSessionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该会话?'**
  String get deleteSessionConfirm;

  /// No description provided for @emptyProviders.
  ///
  /// In zh, this message translates to:
  /// **'还没有供应商,点右上角 + 添加'**
  String get emptyProviders;

  /// No description provided for @emptyModels.
  ///
  /// In zh, this message translates to:
  /// **'还没有模型'**
  String get emptyModels;

  /// No description provided for @modelInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入模型 ID 后回车添加'**
  String get modelInputHint;

  /// No description provided for @errorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'出错了'**
  String get errorGeneric;

  /// No description provided for @retrying.
  ///
  /// In zh, this message translates to:
  /// **'正在重试'**
  String get retrying;

  /// No description provided for @emptyMessage.
  ///
  /// In zh, this message translates to:
  /// **'消息内容为空'**
  String get emptyMessage;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabled;

  /// No description provided for @providerModelsCountTag.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个模型'**
  String providerModelsCountTag(int count);

  /// No description provided for @inputTokens.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get inputTokens;

  /// No description provided for @outputTokens.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get outputTokens;

  /// No description provided for @emptyChatHint.
  ///
  /// In zh, this message translates to:
  /// **'选择一个会话开始对话'**
  String get emptyChatHint;

  /// No description provided for @errorNoProvider.
  ///
  /// In zh, this message translates to:
  /// **'未配置可用的供应商,请先在设置中添加'**
  String get errorNoProvider;

  /// No description provided for @errorNoModel.
  ///
  /// In zh, this message translates to:
  /// **'请为该供应商选择模型'**
  String get errorNoModel;

  /// No description provided for @errorEmptyResponse.
  ///
  /// In zh, this message translates to:
  /// **'模型返回了空白内容'**
  String get errorEmptyResponse;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中…'**
  String get thinking;

  /// No description provided for @modelListTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get modelListTitle;

  /// No description provided for @providerListTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择供应商'**
  String get providerListTitle;

  /// No description provided for @customProvider.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get customProvider;

  /// No description provided for @addFromPreset.
  ///
  /// In zh, this message translates to:
  /// **'从预设添加'**
  String get addFromPreset;

  /// No description provided for @useFullUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'baseUrl 已是完整端点'**
  String get useFullUrlHint;

  /// No description provided for @aboutBody.
  ///
  /// In zh, this message translates to:
  /// **'Codecraft Flutter 是 jieapi/Codecraft 的 Flutter 复刻(Phase 1:核心对话闭环)。'**
  String get aboutBody;

  /// No description provided for @chatPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'有什么可以帮你的?'**
  String get chatPlaceholder;

  /// No description provided for @chatInputHint.
  ///
  /// In zh, this message translates to:
  /// **'描述你的需求,我来帮你编写、修改或解释代码'**
  String get chatInputHint;

  /// No description provided for @openSidebar.
  ///
  /// In zh, this message translates to:
  /// **'打开侧边栏'**
  String get openSidebar;

  /// No description provided for @noModelSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择模型'**
  String get noModelSelected;

  /// No description provided for @sessionGroupPinned.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get sessionGroupPinned;

  /// No description provided for @sessionGroupToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get sessionGroupToday;

  /// No description provided for @sessionGroupYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get sessionGroupYesterday;

  /// No description provided for @sessionGroupLast7Days.
  ///
  /// In zh, this message translates to:
  /// **'7天内'**
  String get sessionGroupLast7Days;

  /// No description provided for @sessionGroupLast30Days.
  ///
  /// In zh, this message translates to:
  /// **'30天内'**
  String get sessionGroupLast30Days;

  /// No description provided for @sessionGroupMonthFormat.
  ///
  /// In zh, this message translates to:
  /// **'yyyy年M月'**
  String get sessionGroupMonthFormat;

  /// No description provided for @chatThinkingRunningTime.
  ///
  /// In zh, this message translates to:
  /// **'正在思考(耗时 {seconds} 秒)'**
  String chatThinkingRunningTime(String seconds);

  /// No description provided for @chatThinkingDoneTime.
  ///
  /// In zh, this message translates to:
  /// **'思考完成(耗时 {seconds} 秒)'**
  String chatThinkingDoneTime(String seconds);

  /// No description provided for @chatThinkingDone.
  ///
  /// In zh, this message translates to:
  /// **'思考完成'**
  String get chatThinkingDone;

  /// No description provided for @chatQueueHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 正在处理中,点右侧方块可停止'**
  String get chatQueueHint;

  /// No description provided for @chatStatusGenerating.
  ///
  /// In zh, this message translates to:
  /// **'正在生成'**
  String get chatStatusGenerating;

  /// No description provided for @chatStatusThinking.
  ///
  /// In zh, this message translates to:
  /// **'正在思考'**
  String get chatStatusThinking;

  /// No description provided for @chatStatusCallingTool.
  ///
  /// In zh, this message translates to:
  /// **'正在调用工具'**
  String get chatStatusCallingTool;

  /// No description provided for @chatStatusRunningCommand.
  ///
  /// In zh, this message translates to:
  /// **'正在执行命令'**
  String get chatStatusRunningCommand;

  /// No description provided for @chatStatusEditingFile.
  ///
  /// In zh, this message translates to:
  /// **'正在编辑文件'**
  String get chatStatusEditingFile;

  /// No description provided for @chatStatusReadingFile.
  ///
  /// In zh, this message translates to:
  /// **'正在读取文件'**
  String get chatStatusReadingFile;

  /// No description provided for @chatStatusViewingImage.
  ///
  /// In zh, this message translates to:
  /// **'正在查看图片'**
  String get chatStatusViewingImage;

  /// No description provided for @chatStatusSearchingWeb.
  ///
  /// In zh, this message translates to:
  /// **'正在联网搜索'**
  String get chatStatusSearchingWeb;

  /// No description provided for @chatStatusBrowsingWeb.
  ///
  /// In zh, this message translates to:
  /// **'正在操作浏览器'**
  String get chatStatusBrowsingWeb;

  /// No description provided for @chatStatusAskingUser.
  ///
  /// In zh, this message translates to:
  /// **'正在询问用户'**
  String get chatStatusAskingUser;

  /// No description provided for @chatStatusGeneratingImage.
  ///
  /// In zh, this message translates to:
  /// **'正在生成图片'**
  String get chatStatusGeneratingImage;

  /// No description provided for @chatStatusUpdatingTodo.
  ///
  /// In zh, this message translates to:
  /// **'正在整理待办'**
  String get chatStatusUpdatingTodo;

  /// No description provided for @chatStatusStartingSubagent.
  ///
  /// In zh, this message translates to:
  /// **'正在启动子代理'**
  String get chatStatusStartingSubagent;

  /// No description provided for @chatCompressingContext.
  ///
  /// In zh, this message translates to:
  /// **'正在压缩上下文'**
  String get chatCompressingContext;

  /// No description provided for @chatContextCompressed.
  ///
  /// In zh, this message translates to:
  /// **'上下文已压缩'**
  String get chatContextCompressed;

  /// No description provided for @chatCompactionSummary.
  ///
  /// In zh, this message translates to:
  /// **'接手摘要'**
  String get chatCompactionSummary;

  /// No description provided for @chatStatusReadingMemory.
  ///
  /// In zh, this message translates to:
  /// **'正在读取记忆'**
  String get chatStatusReadingMemory;

  /// No description provided for @chatToolRunning.
  ///
  /// In zh, this message translates to:
  /// **'工具执行中'**
  String get chatToolRunning;

  /// No description provided for @chatToolSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'工具执行成功'**
  String get chatToolSucceeded;

  /// No description provided for @chatToolFailed.
  ///
  /// In zh, this message translates to:
  /// **'工具执行失败'**
  String get chatToolFailed;

  /// No description provided for @chatEffortNone.
  ///
  /// In zh, this message translates to:
  /// **'不思考'**
  String get chatEffortNone;

  /// No description provided for @chatEffortMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极低'**
  String get chatEffortMinimal;

  /// No description provided for @chatEffortLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get chatEffortLow;

  /// No description provided for @chatEffortMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get chatEffortMedium;

  /// No description provided for @chatEffortHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get chatEffortHigh;

  /// No description provided for @chatEffortXHigh.
  ///
  /// In zh, this message translates to:
  /// **'极高'**
  String get chatEffortXHigh;

  /// No description provided for @chatEffortMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get chatEffortMax;

  /// No description provided for @searchModels.
  ///
  /// In zh, this message translates to:
  /// **'搜索模型'**
  String get searchModels;

  /// No description provided for @chatAddAttachment.
  ///
  /// In zh, this message translates to:
  /// **'添加附件'**
  String get chatAddAttachment;

  /// No description provided for @chatUploadFile.
  ///
  /// In zh, this message translates to:
  /// **'上传文件'**
  String get chatUploadFile;

  /// No description provided for @chatUploadImage.
  ///
  /// In zh, this message translates to:
  /// **'上传图片'**
  String get chatUploadImage;

  /// No description provided for @chatTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get chatTakePhoto;

  /// No description provided for @attachmentPrefix.
  ///
  /// In zh, this message translates to:
  /// **'附件:'**
  String get attachmentPrefix;

  /// No description provided for @attachmentMax.
  ///
  /// In zh, this message translates to:
  /// **'最多可同时发送 {count} 个附件'**
  String attachmentMax(int count);

  /// No description provided for @attachmentUploaded.
  ///
  /// In zh, this message translates to:
  /// **'已上传 {count} 个附件'**
  String attachmentUploaded(int count);

  /// No description provided for @attachmentUploadedPartial.
  ///
  /// In zh, this message translates to:
  /// **'已上传 {count} 个附件,部分附件未加入'**
  String attachmentUploadedPartial(int count);

  /// No description provided for @attachmentUploading.
  ///
  /// In zh, this message translates to:
  /// **'正在上传 {count} 个文件…'**
  String attachmentUploading(int count);

  /// No description provided for @attachmentImageTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片超过 {size},请压缩后重试'**
  String attachmentImageTooLarge(String size);

  /// No description provided for @attachmentUnsupportedImageType.
  ///
  /// In zh, this message translates to:
  /// **'无法识别图片类型,仅支持 jpg/png/gif/webp'**
  String get attachmentUnsupportedImageType;

  /// No description provided for @attachmentReadFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取所选文件'**
  String get attachmentReadFileFailed;

  /// No description provided for @attachmentUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败'**
  String get attachmentUploadFailed;

  /// No description provided for @removeAttachment.
  ///
  /// In zh, this message translates to:
  /// **'移除附件'**
  String get removeAttachment;

  /// No description provided for @imagePreview.
  ///
  /// In zh, this message translates to:
  /// **'图片预览'**
  String get imagePreview;

  /// No description provided for @imageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败,文件可能已被移动或删除'**
  String get imageLoadFailed;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @fileFallback.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get fileFallback;

  /// No description provided for @skillsTitle.
  ///
  /// In zh, this message translates to:
  /// **'Skill 管理'**
  String get skillsTitle;

  /// No description provided for @skillsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'浏览、导入与管理写作技能'**
  String get skillsSubtitle;

  /// No description provided for @skillsNew.
  ///
  /// In zh, this message translates to:
  /// **'新建技能'**
  String get skillsNew;

  /// No description provided for @skillsImport.
  ///
  /// In zh, this message translates to:
  /// **'导入 Markdown'**
  String get skillsImport;

  /// No description provided for @skillsScopeTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择作用域'**
  String get skillsScopeTitle;

  /// No description provided for @skillsScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **''**
  String get skillsScopeGlobal;

  /// No description provided for @skillsScopeProject.
  ///
  /// In zh, this message translates to:
  /// **'项目技能'**
  String get skillsScopeProject;

  /// No description provided for @skillsScopeGlobalHint.
  ///
  /// In zh, this message translates to:
  /// **'~/.codecraft/skills,跨项目共享'**
  String get skillsScopeGlobalHint;

  /// No description provided for @skillsScopeProjectHint.
  ///
  /// In zh, this message translates to:
  /// **'~/workspace/.codecraft/skills,随当前工作区'**
  String get skillsScopeProjectHint;

  /// No description provided for @skillsProjectGroup.
  ///
  /// In zh, this message translates to:
  /// **'当前项目({name})'**
  String skillsProjectGroup(String name);

  /// No description provided for @skillsNoProjectSkills.
  ///
  /// In zh, this message translates to:
  /// **'当前项目还没有技能'**
  String get skillsNoProjectSkills;

  /// No description provided for @skillsNoGlobalSkills.
  ///
  /// In zh, this message translates to:
  /// **'还没有全局技能'**
  String get skillsNoGlobalSkills;

  /// No description provided for @skillsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有技能'**
  String get skillsEmpty;

  /// No description provided for @skillsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'技能是写给 AI 的专项操作说明;导入 SKILL.md 或手动新建一个吧。'**
  String get skillsEmptyHint;

  /// No description provided for @skillsName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get skillsName;

  /// No description provided for @skillsDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get skillsDescription;

  /// No description provided for @skillsDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'何时使用这个技能(会进系统提示)'**
  String get skillsDescriptionHint;

  /// No description provided for @skillsInstructions.
  ///
  /// In zh, this message translates to:
  /// **'指令正文'**
  String get skillsInstructions;

  /// No description provided for @skillsInstructionsHint.
  ///
  /// In zh, this message translates to:
  /// **'技能要执行的步骤,Markdown 书写'**
  String get skillsInstructionsHint;

  /// No description provided for @skillsImported.
  ///
  /// In zh, this message translates to:
  /// **'已导入技能「{name}」'**
  String skillsImported(String name);

  /// No description provided for @skillsDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除技能'**
  String get skillsDeleteTitle;

  /// No description provided for @skillsDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除技能「{name}」(含其目录与脚本)?'**
  String skillsDeleteConfirm(String name);

  /// No description provided for @skillsErrorInvalidName.
  ///
  /// In zh, this message translates to:
  /// **'技能名无效:不能为空、超长或含 / \\ : * ? \" < > |'**
  String get skillsErrorInvalidName;

  /// No description provided for @skillsErrorEmptyInstructions.
  ///
  /// In zh, this message translates to:
  /// **'指令正文不能为空'**
  String get skillsErrorEmptyInstructions;

  /// No description provided for @skillsErrorNameConflict.
  ///
  /// In zh, this message translates to:
  /// **'同作用域已有名为「{name}」的技能'**
  String skillsErrorNameConflict(String name);

  /// No description provided for @skillsErrorNoSkill.
  ///
  /// In zh, this message translates to:
  /// **'文件里没有可识别的技能'**
  String get skillsErrorNoSkill;

  /// No description provided for @skillsErrorIoFailed.
  ///
  /// In zh, this message translates to:
  /// **'读写技能文件失败'**
  String get skillsErrorIoFailed;

  /// No description provided for @providerAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加供应商'**
  String get providerAdd;

  /// No description provided for @providerEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑供应商'**
  String get providerEdit;

  /// No description provided for @providerEditModel.
  ///
  /// In zh, this message translates to:
  /// **'编辑模型'**
  String get providerEditModel;

  /// No description provided for @providerConfig.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get providerConfig;

  /// No description provided for @providerSectionBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get providerSectionBasic;

  /// No description provided for @providerSectionType.
  ///
  /// In zh, this message translates to:
  /// **'上游格式'**
  String get providerSectionType;

  /// No description provided for @providerSectionOptions.
  ///
  /// In zh, this message translates to:
  /// **'选项'**
  String get providerSectionOptions;

  /// No description provided for @providerFullUrl.
  ///
  /// In zh, this message translates to:
  /// **'完整 URL'**
  String get providerFullUrl;

  /// No description provided for @providerFullUrlDesc.
  ///
  /// In zh, this message translates to:
  /// **'Base URL 即完整请求地址,不自动拼接默认路径'**
  String get providerFullUrlDesc;

  /// No description provided for @providerHeadersTitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头'**
  String get providerHeadersTitle;

  /// No description provided for @providerHeadersDesc.
  ///
  /// In zh, this message translates to:
  /// **'完全覆盖该供应商请求的同名默认头'**
  String get providerHeadersDesc;

  /// No description provided for @providerHeadersAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加请求头'**
  String get providerHeadersAdd;

  /// No description provided for @providerHeadersManage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get providerHeadersManage;

  /// No description provided for @providerHeadersCount.
  ///
  /// In zh, this message translates to:
  /// **'已配置 {count} 个请求头'**
  String providerHeadersCount(int count);

  /// No description provided for @providerShowApiKey.
  ///
  /// In zh, this message translates to:
  /// **'显示密钥'**
  String get providerShowApiKey;

  /// No description provided for @providerHideApiKey.
  ///
  /// In zh, this message translates to:
  /// **'隐藏密钥'**
  String get providerHideApiKey;

  /// No description provided for @providerAddModel.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get providerAddModel;

  /// No description provided for @providerNoModels.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型'**
  String get providerNoModels;

  /// No description provided for @providerNoModelsHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上方按钮添加模型'**
  String get providerNoModelsHint;

  /// No description provided for @providerModelCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get providerModelCurrent;

  /// No description provided for @providerModelsCount.
  ///
  /// In zh, this message translates to:
  /// **'模型({count})'**
  String providerModelsCount(String count);

  /// No description provided for @providerModelsSelect.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get providerModelsSelect;

  /// No description provided for @providerModelsSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String providerModelsSelectedCount(int count);

  /// No description provided for @providerModelsSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get providerModelsSelectAll;

  /// No description provided for @providerModelsDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get providerModelsDeselectAll;

  /// No description provided for @providerModelsBatchTest.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get providerModelsBatchTest;

  /// No description provided for @providerModelsBatchDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get providerModelsBatchDelete;

  /// No description provided for @providerModelsBatchDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除模型'**
  String get providerModelsBatchDeleteTitle;

  /// No description provided for @providerModelsBatchDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除选中的 {count} 个模型吗?'**
  String providerModelsBatchDeleteConfirm(int count);

  /// No description provided for @providerFetchModels.
  ///
  /// In zh, this message translates to:
  /// **'拉取模型'**
  String get providerFetchModels;

  /// No description provided for @providerAddAllModels.
  ///
  /// In zh, this message translates to:
  /// **'全部添加'**
  String get providerAddAllModels;

  /// No description provided for @providerAddAllModelsTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加全部模型'**
  String get providerAddAllModelsTitle;

  /// No description provided for @providerAddAllModelsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将拉取到的 {count} 个模型全部添加至当前提供商?'**
  String providerAddAllModelsConfirm(int count);

  /// No description provided for @providerFilterModelsHint.
  ///
  /// In zh, this message translates to:
  /// **'输入模型名称筛选'**
  String get providerFilterModelsHint;

  /// No description provided for @providerNoMatchingModels.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的模型'**
  String get providerNoMatchingModels;

  /// No description provided for @providerModelAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加模型「{name}」'**
  String providerModelAdded(String name);

  /// No description provided for @providerModelName.
  ///
  /// In zh, this message translates to:
  /// **'模型名称'**
  String get providerModelName;

  /// No description provided for @providerModelAlreadyAdded.
  ///
  /// In zh, this message translates to:
  /// **'该模型已添加'**
  String get providerModelAlreadyAdded;

  /// No description provided for @providerFetchHttpError.
  ///
  /// In zh, this message translates to:
  /// **'HTTP {code} · {latency}ms'**
  String providerFetchHttpError(int code, int latency);

  /// No description provided for @providerFetchMissingFields.
  ///
  /// In zh, this message translates to:
  /// **'响应缺少列表字段'**
  String get providerFetchMissingFields;

  /// No description provided for @providerFetchFailed.
  ///
  /// In zh, this message translates to:
  /// **'拉取模型失败'**
  String get providerFetchFailed;

  /// No description provided for @providerApiKeyRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写 API Key'**
  String get providerApiKeyRequired;

  /// No description provided for @providerTestModel.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get providerTestModel;

  /// No description provided for @providerModelContext.
  ///
  /// In zh, this message translates to:
  /// **'上下文窗口 (tokens)'**
  String get providerModelContext;

  /// No description provided for @providerModelContextInput.
  ///
  /// In zh, this message translates to:
  /// **'输入上限 (tokens)'**
  String get providerModelContextInput;

  /// No description provided for @providerModelContextOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出上限 (tokens)'**
  String get providerModelContextOutput;

  /// No description provided for @providerModelWindowInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的正整数,或留空使用自动识别值'**
  String get providerModelWindowInvalid;

  /// No description provided for @providerModelSectionPrice.
  ///
  /// In zh, this message translates to:
  /// **'价格'**
  String get providerModelSectionPrice;

  /// No description provided for @providerModelPriceInput.
  ///
  /// In zh, this message translates to:
  /// **'输入价格 (USD/1M tokens)'**
  String get providerModelPriceInput;

  /// No description provided for @providerModelPriceOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出价格 (USD/1M tokens)'**
  String get providerModelPriceOutput;

  /// No description provided for @providerModelPriceCacheRead.
  ///
  /// In zh, this message translates to:
  /// **'缓存读价格 (USD/1M tokens)'**
  String get providerModelPriceCacheRead;

  /// No description provided for @providerModelPriceCacheWrite.
  ///
  /// In zh, this message translates to:
  /// **'缓存写价格 (USD/1M tokens)'**
  String get providerModelPriceCacheWrite;

  /// No description provided for @providerModelCapabilities.
  ///
  /// In zh, this message translates to:
  /// **'能力'**
  String get providerModelCapabilities;

  /// No description provided for @providerModelCapVision.
  ///
  /// In zh, this message translates to:
  /// **'图片输入'**
  String get providerModelCapVision;

  /// No description provided for @providerModelCapImageOutput.
  ///
  /// In zh, this message translates to:
  /// **'图片输出'**
  String get providerModelCapImageOutput;

  /// No description provided for @providerModelCapTools.
  ///
  /// In zh, this message translates to:
  /// **'工具调用'**
  String get providerModelCapTools;

  /// No description provided for @providerModelCapReasoning.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get providerModelCapReasoning;

  /// No description provided for @providerModelSectionReasoning.
  ///
  /// In zh, this message translates to:
  /// **'思考档位'**
  String get providerModelSectionReasoning;

  /// No description provided for @providerModelReasoningHint.
  ///
  /// In zh, this message translates to:
  /// **'只勾选该模型真实支持的档位;全部不勾则由内置能力表自动判断'**
  String get providerModelReasoningHint;

  /// No description provided for @providerModelReasoningCanDisable.
  ///
  /// In zh, this message translates to:
  /// **'可以关闭思考'**
  String get providerModelReasoningCanDisable;

  /// No description provided for @providerTestRequestUrl.
  ///
  /// In zh, this message translates to:
  /// **'请求地址'**
  String get providerTestRequestUrl;

  /// No description provided for @providerTestRequestHeaders.
  ///
  /// In zh, this message translates to:
  /// **'请求头'**
  String get providerTestRequestHeaders;

  /// No description provided for @providerTestRequestBody.
  ///
  /// In zh, this message translates to:
  /// **'请求体'**
  String get providerTestRequestBody;

  /// No description provided for @providerTestResponse.
  ///
  /// In zh, this message translates to:
  /// **'响应'**
  String get providerTestResponse;

  /// No description provided for @providerTestError.
  ///
  /// In zh, this message translates to:
  /// **'错误详情'**
  String get providerTestError;

  /// No description provided for @providerMultiKeyTitle.
  ///
  /// In zh, this message translates to:
  /// **'多 Key 模式'**
  String get providerMultiKeyTitle;

  /// No description provided for @providerMultiKeySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'同一供应商下配多个 Key,密钥不可用时自动切换并重发'**
  String get providerMultiKeySubtitle;

  /// No description provided for @providerMultiKeyManage.
  ///
  /// In zh, this message translates to:
  /// **'多 Key 管理'**
  String get providerMultiKeyManage;

  /// No description provided for @providerMultiKeySummary.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个 · {strategy}'**
  String providerMultiKeySummary(int count, String strategy);

  /// No description provided for @providerMultiKeyList.
  ///
  /// In zh, this message translates to:
  /// **'Key 列表'**
  String get providerMultiKeyList;

  /// No description provided for @providerMultiKeyItem.
  ///
  /// In zh, this message translates to:
  /// **'密钥 #{index}'**
  String providerMultiKeyItem(int index);

  /// No description provided for @providerMultiKeyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'点此添加第一个 Key'**
  String get providerMultiKeyEmpty;

  /// No description provided for @providerMultiKeyAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加 Key'**
  String get providerMultiKeyAdd;

  /// No description provided for @providerMultiKeyWeight.
  ///
  /// In zh, this message translates to:
  /// **'调度权重'**
  String get providerMultiKeyWeight;

  /// No description provided for @providerMultiKeyWeightHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 1 · ≤ 0 时不参与 · 最大 1,000,000'**
  String get providerMultiKeyWeightHint;

  /// No description provided for @providerMultiKeyStrategy.
  ///
  /// In zh, this message translates to:
  /// **'取用策略'**
  String get providerMultiKeyStrategy;

  /// No description provided for @providerMultiKeyStrategySequential.
  ///
  /// In zh, this message translates to:
  /// **'顺序'**
  String get providerMultiKeyStrategySequential;

  /// No description provided for @providerMultiKeyStrategySequentialDesc.
  ///
  /// In zh, this message translates to:
  /// **'始终用靠前的 Key,失败达阈值才切下一个'**
  String get providerMultiKeyStrategySequentialDesc;

  /// No description provided for @providerMultiKeyStrategyRoundRobin.
  ///
  /// In zh, this message translates to:
  /// **'轮询'**
  String get providerMultiKeyStrategyRoundRobin;

  /// No description provided for @providerMultiKeyStrategyRoundRobinDesc.
  ///
  /// In zh, this message translates to:
  /// **'新会话轮流起步以摊平额度;同一会话内不换 Key,保持缓存命中'**
  String get providerMultiKeyStrategyRoundRobinDesc;

  /// No description provided for @providerMultiKeyStatusCodes.
  ///
  /// In zh, this message translates to:
  /// **'自动切换状态码'**
  String get providerMultiKeyStatusCodes;

  /// No description provided for @providerMultiKeyStatusCodesHint.
  ///
  /// In zh, this message translates to:
  /// **'逗号分隔,留空使用默认 401,402,403,429'**
  String get providerMultiKeyStatusCodesHint;

  /// No description provided for @providerMultiKeyCooldown.
  ///
  /// In zh, this message translates to:
  /// **'冷却时长'**
  String get providerMultiKeyCooldown;

  /// No description provided for @providerMultiKeyCooldownDesc.
  ///
  /// In zh, this message translates to:
  /// **'被切走的 Key 隔多久重新纳入候选'**
  String get providerMultiKeyCooldownDesc;

  /// No description provided for @workspaceOpen.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get workspaceOpen;

  /// No description provided for @workspaceLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地工作区'**
  String get workspaceLocal;

  /// No description provided for @workspaceLocalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'应用数据目录'**
  String get workspaceLocalSubtitle;

  /// No description provided for @allow.
  ///
  /// In zh, this message translates to:
  /// **'允许'**
  String get allow;

  /// No description provided for @deny.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get deny;

  /// No description provided for @tabFiles.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get tabFiles;

  /// No description provided for @newFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get newFile;

  /// No description provided for @newFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get newFolder;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @deleteFileConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该文件?'**
  String get deleteFileConfirm;

  /// No description provided for @deleteFolderConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该文件夹(含内容)?'**
  String get deleteFolderConfirm;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @workspaceNew.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get workspaceNew;

  /// No description provided for @workspaceEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有工作区,点右上角「新建」'**
  String get workspaceEmptyHint;

  /// No description provided for @workspaceNameExists.
  ///
  /// In zh, this message translates to:
  /// **'同名工作区已存在'**
  String get workspaceNameExists;

  /// No description provided for @workspaceDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除工作区'**
  String get workspaceDelete;

  /// No description provided for @workspaceDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除工作区「{name}」(含其中全部文件)?'**
  String workspaceDeleteConfirm(String name);

  /// No description provided for @todoDashboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务待办'**
  String get todoDashboardTitle;

  /// No description provided for @todoDashboardProgress.
  ///
  /// In zh, this message translates to:
  /// **'{completed}/{total} 完成'**
  String todoDashboardProgress(int completed, int total);

  /// No description provided for @todoDashboardAllDone.
  ///
  /// In zh, this message translates to:
  /// **'全部完成'**
  String get todoDashboardAllDone;

  /// No description provided for @todoInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get todoInProgress;

  /// No description provided for @todoCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get todoCompleted;

  /// No description provided for @gitTitle.
  ///
  /// In zh, this message translates to:
  /// **'Git'**
  String get gitTitle;

  /// No description provided for @gitRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get gitRefresh;

  /// No description provided for @gitTabStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get gitTabStatus;

  /// No description provided for @browserTitle.
  ///
  /// In zh, this message translates to:
  /// **'浏览器'**
  String get browserTitle;

  /// No description provided for @browserAddressHint.
  ///
  /// In zh, this message translates to:
  /// **'输入网址或搜索'**
  String get browserAddressHint;

  /// No description provided for @browserBack.
  ///
  /// In zh, this message translates to:
  /// **'后退'**
  String get browserBack;

  /// No description provided for @browserForward.
  ///
  /// In zh, this message translates to:
  /// **'前进'**
  String get browserForward;

  /// No description provided for @browserReload.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get browserReload;

  /// No description provided for @browserNotReady.
  ///
  /// In zh, this message translates to:
  /// **'浏览器未就绪,请在地址栏输入网址开始浏览'**
  String get browserNotReady;

  /// No description provided for @browserNewTab.
  ///
  /// In zh, this message translates to:
  /// **'新建标签页'**
  String get browserNewTab;

  /// No description provided for @browserCloseTab.
  ///
  /// In zh, this message translates to:
  /// **'关闭标签页'**
  String get browserCloseTab;

  /// No description provided for @browserTabDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'新标签页'**
  String get browserTabDefaultTitle;

  /// No description provided for @browserTabsCount.
  ///
  /// In zh, this message translates to:
  /// **'标签页 ({count})'**
  String browserTabsCount(int count);

  /// No description provided for @browserEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'在上方地址栏输入网址开始浏览'**
  String get browserEmptyHint;

  /// No description provided for @browserTabsManage.
  ///
  /// In zh, this message translates to:
  /// **'标签页管理'**
  String get browserTabsManage;

  /// No description provided for @browserEmptyClickHint.
  ///
  /// In zh, this message translates to:
  /// **'点击上方输入网址开始浏览'**
  String get browserEmptyClickHint;

  /// No description provided for @browserNightModeOn.
  ///
  /// In zh, this message translates to:
  /// **'关闭夜间模式'**
  String get browserNightModeOn;

  /// No description provided for @browserNightModeOff.
  ///
  /// In zh, this message translates to:
  /// **'开启夜间模式'**
  String get browserNightModeOff;

  /// No description provided for @browserDevtools.
  ///
  /// In zh, this message translates to:
  /// **'开发者工具'**
  String get browserDevtools;

  /// No description provided for @browserDialogAlertTitle.
  ///
  /// In zh, this message translates to:
  /// **'网页提示'**
  String get browserDialogAlertTitle;

  /// No description provided for @browserDialogConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'网页确认'**
  String get browserDialogConfirmTitle;

  /// No description provided for @browserDialogPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'网页输入'**
  String get browserDialogPromptTitle;

  /// No description provided for @browserMenu.
  ///
  /// In zh, this message translates to:
  /// **'更多设置'**
  String get browserMenu;

  /// No description provided for @browserMenuTitle.
  ///
  /// In zh, this message translates to:
  /// **'浏览器设置与工具'**
  String get browserMenuTitle;

  /// No description provided for @browserMenuGeneralSection.
  ///
  /// In zh, this message translates to:
  /// **'页面与工具'**
  String get browserMenuGeneralSection;

  /// No description provided for @browserNightModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'夜间模式'**
  String get browserNightModeTitle;

  /// No description provided for @browserNightModeDesc.
  ///
  /// In zh, this message translates to:
  /// **'降低页面亮度并启用深色偏好'**
  String get browserNightModeDesc;

  /// No description provided for @browserDevtoolsTitle.
  ///
  /// In zh, this message translates to:
  /// **'开发者工具'**
  String get browserDevtoolsTitle;

  /// No description provided for @browserDevtoolsDesc.
  ///
  /// In zh, this message translates to:
  /// **'开启移动端 Eruda 调试控制台'**
  String get browserDevtoolsDesc;

  /// No description provided for @browserUaSection.
  ///
  /// In zh, this message translates to:
  /// **'浏览器标识 (User-Agent)'**
  String get browserUaSection;

  /// No description provided for @browserUaDesc.
  ///
  /// In zh, this message translates to:
  /// **'模拟不同设备与环境访问网页'**
  String get browserUaDesc;

  /// No description provided for @browserUaDefault.
  ///
  /// In zh, this message translates to:
  /// **'系统默认'**
  String get browserUaDefault;

  /// No description provided for @browserUaDefaultDesc.
  ///
  /// In zh, this message translates to:
  /// **'当前设备原生 WebView 标识'**
  String get browserUaDefaultDesc;

  /// No description provided for @browserUaAndroidPhone.
  ///
  /// In zh, this message translates to:
  /// **'安卓手机'**
  String get browserUaAndroidPhone;

  /// No description provided for @browserUaAndroidPhoneDesc.
  ///
  /// In zh, this message translates to:
  /// **'Chrome Mobile (Android)'**
  String get browserUaAndroidPhoneDesc;

  /// No description provided for @browserUaAndroidTablet.
  ///
  /// In zh, this message translates to:
  /// **'安卓平板'**
  String get browserUaAndroidTablet;

  /// No description provided for @browserUaAndroidTabletDesc.
  ///
  /// In zh, this message translates to:
  /// **'Chrome Tablet (Android)'**
  String get browserUaAndroidTabletDesc;

  /// No description provided for @browserUaDesktopPc.
  ///
  /// In zh, this message translates to:
  /// **'桌面电脑'**
  String get browserUaDesktopPc;

  /// No description provided for @browserUaDesktopPcDesc.
  ///
  /// In zh, this message translates to:
  /// **'Chrome Desktop (Windows PC)'**
  String get browserUaDesktopPcDesc;

  /// No description provided for @browserUaIphone.
  ///
  /// In zh, this message translates to:
  /// **'苹果 iPhone'**
  String get browserUaIphone;

  /// No description provided for @browserUaIphoneDesc.
  ///
  /// In zh, this message translates to:
  /// **'Mobile Safari (iOS)'**
  String get browserUaIphoneDesc;

  /// No description provided for @browserUaIpad.
  ///
  /// In zh, this message translates to:
  /// **'苹果 iPad'**
  String get browserUaIpad;

  /// No description provided for @browserUaIpadDesc.
  ///
  /// In zh, this message translates to:
  /// **'Tablet Safari (iPadOS)'**
  String get browserUaIpadDesc;

  /// No description provided for @browserUaCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get browserUaCustom;

  /// No description provided for @browserUaCustomDesc.
  ///
  /// In zh, this message translates to:
  /// **'手动指定 User-Agent 字符串'**
  String get browserUaCustomDesc;

  /// No description provided for @browserUaCustomDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义 User-Agent'**
  String get browserUaCustomDialogTitle;

  /// No description provided for @browserUaCustomInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入完整的 User-Agent 字符串'**
  String get browserUaCustomInputHint;

  /// No description provided for @browserUaAppliedToast.
  ///
  /// In zh, this message translates to:
  /// **'已切换浏览器标识并刷新页面'**
  String get browserUaAppliedToast;

  /// No description provided for @gitTabBranches.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get gitTabBranches;

  /// No description provided for @gitTabCommits.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get gitTabCommits;

  /// No description provided for @gitStatusClean.
  ///
  /// In zh, this message translates to:
  /// **'工作区干净,无改动'**
  String get gitStatusClean;

  /// No description provided for @gitConflictedCount.
  ///
  /// In zh, this message translates to:
  /// **'存在冲突 ({count})'**
  String gitConflictedCount(int count);

  /// No description provided for @gitStagedCount.
  ///
  /// In zh, this message translates to:
  /// **'已暂存 ({count})'**
  String gitStagedCount(int count);

  /// No description provided for @gitModifiedCount.
  ///
  /// In zh, this message translates to:
  /// **'已修改 ({count})'**
  String gitModifiedCount(int count);

  /// No description provided for @gitUntrackedCount.
  ///
  /// In zh, this message translates to:
  /// **'未跟踪 ({count})'**
  String gitUntrackedCount(int count);

  /// No description provided for @gitConflictedLabel.
  ///
  /// In zh, this message translates to:
  /// **'存在冲突'**
  String get gitConflictedLabel;

  /// No description provided for @gitStagedLabel.
  ///
  /// In zh, this message translates to:
  /// **'已暂存'**
  String get gitStagedLabel;

  /// No description provided for @gitModifiedLabel.
  ///
  /// In zh, this message translates to:
  /// **'已修改'**
  String get gitModifiedLabel;

  /// No description provided for @gitUntrackedLabel.
  ///
  /// In zh, this message translates to:
  /// **'未跟踪'**
  String get gitUntrackedLabel;

  /// No description provided for @gitStage.
  ///
  /// In zh, this message translates to:
  /// **'暂存'**
  String get gitStage;

  /// No description provided for @gitUnstage.
  ///
  /// In zh, this message translates to:
  /// **'取消暂存'**
  String get gitUnstage;

  /// No description provided for @gitStageAll.
  ///
  /// In zh, this message translates to:
  /// **'暂存全部'**
  String get gitStageAll;

  /// No description provided for @gitUnstageAll.
  ///
  /// In zh, this message translates to:
  /// **'全部取消暂存'**
  String get gitUnstageAll;

  /// No description provided for @gitUnstageAllConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将取消所有文件的暂存,但不会删除文件内容。确定继续吗?'**
  String get gitUnstageAllConfirm;

  /// No description provided for @gitActionRevertAll.
  ///
  /// In zh, this message translates to:
  /// **'全部回退'**
  String get gitActionRevertAll;

  /// No description provided for @gitRevertAllConfirm.
  ///
  /// In zh, this message translates to:
  /// **'丢弃全部未暂存的改动({count} 个文件),还原到上次暂存或提交的内容?已暂存的内容不受影响,但丢弃的改动无法找回。'**
  String gitRevertAllConfirm(int count);

  /// No description provided for @gitActionRestoreFile.
  ///
  /// In zh, this message translates to:
  /// **'恢复文件'**
  String get gitActionRestoreFile;

  /// No description provided for @gitRevertConfirmWorktree.
  ///
  /// In zh, this message translates to:
  /// **'把 {name} 还原成上次暂存或提交的内容?未暂存的改动会丢失,且无法找回。'**
  String gitRevertConfirmWorktree(String name);

  /// No description provided for @gitRevertConfirmHead.
  ///
  /// In zh, this message translates to:
  /// **'把 {name} 还原到上次提交的内容?该文件已暂存和未暂存的改动都会丢失,且无法找回。'**
  String gitRevertConfirmHead(String name);

  /// No description provided for @gitRestoreFileConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复已删除的 {name}?将从上次提交取回这个文件。'**
  String gitRestoreFileConfirm(String name);

  /// No description provided for @gitActionDeleteFile.
  ///
  /// In zh, this message translates to:
  /// **'删除文件'**
  String get gitActionDeleteFile;

  /// No description provided for @gitActionDeleteDir.
  ///
  /// In zh, this message translates to:
  /// **'删除目录'**
  String get gitActionDeleteDir;

  /// No description provided for @gitMergePendingTitle.
  ///
  /// In zh, this message translates to:
  /// **'合并待提交'**
  String get gitMergePendingTitle;

  /// No description provided for @gitMergePendingHint.
  ///
  /// In zh, this message translates to:
  /// **'当前没有未解决的冲突。请确认并暂存需要保留的改动,然后提交以完成合并。'**
  String get gitMergePendingHint;

  /// No description provided for @gitActionAbortMerge.
  ///
  /// In zh, this message translates to:
  /// **'中止合并'**
  String get gitActionAbortMerge;

  /// No description provided for @gitAbortMergeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定中止当前合并吗?未解决的冲突改动将被放弃,工作区将还原到合并前的状态。'**
  String get gitAbortMergeConfirm;

  /// No description provided for @gitCommitChanges.
  ///
  /// In zh, this message translates to:
  /// **'提交更改'**
  String get gitCommitChanges;

  /// No description provided for @gitCommitNeedsIdentity.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置提交署名,请在「凭据与署名」页填写用户名和邮箱'**
  String get gitCommitNeedsIdentity;

  /// No description provided for @gitCommitDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'提交更改'**
  String get gitCommitDialogTitle;

  /// No description provided for @gitCommitMessage.
  ///
  /// In zh, this message translates to:
  /// **'提交信息'**
  String get gitCommitMessage;

  /// No description provided for @gitCommitAmend.
  ///
  /// In zh, this message translates to:
  /// **'追加到上次提交 (--amend)'**
  String get gitCommitAmend;

  /// No description provided for @gitCommitAiGenerate.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成'**
  String get gitCommitAiGenerate;

  /// No description provided for @gitCommitGenerating.
  ///
  /// In zh, this message translates to:
  /// **'正在生成…'**
  String get gitCommitGenerating;

  /// No description provided for @gitActionCommit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get gitActionCommit;

  /// No description provided for @gitTabStash.
  ///
  /// In zh, this message translates to:
  /// **'储藏'**
  String get gitTabStash;

  /// No description provided for @gitStashTitle.
  ///
  /// In zh, this message translates to:
  /// **'储藏箱'**
  String get gitStashTitle;

  /// No description provided for @gitActionStash.
  ///
  /// In zh, this message translates to:
  /// **'储藏改动'**
  String get gitActionStash;

  /// No description provided for @gitStashMessageHint.
  ///
  /// In zh, this message translates to:
  /// **'储藏说明(可选)'**
  String get gitStashMessageHint;

  /// No description provided for @gitStashIncludeUntracked.
  ///
  /// In zh, this message translates to:
  /// **'包含未跟踪文件(-u)'**
  String get gitStashIncludeUntracked;

  /// No description provided for @gitStashEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无储藏记录'**
  String get gitStashEmpty;

  /// No description provided for @gitStashPop.
  ///
  /// In zh, this message translates to:
  /// **'弹出 (Pop)'**
  String get gitStashPop;

  /// No description provided for @gitStashApply.
  ///
  /// In zh, this message translates to:
  /// **'应用 (Apply)'**
  String get gitStashApply;

  /// No description provided for @gitStashDrop.
  ///
  /// In zh, this message translates to:
  /// **'丢弃 (Drop)'**
  String get gitStashDrop;

  /// No description provided for @gitStashDropConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定丢弃储藏 {index} 吗?该操作不可撤销。'**
  String gitStashDropConfirm(String index);

  /// No description provided for @gitStashClear.
  ///
  /// In zh, this message translates to:
  /// **'清空全部'**
  String get gitStashClear;

  /// No description provided for @gitStashClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定清空所有储藏记录吗?该操作不可撤销。'**
  String get gitStashClearConfirm;

  /// No description provided for @gitStashCount.
  ///
  /// In zh, this message translates to:
  /// **'储藏 ({count})'**
  String gitStashCount(int count);

  /// No description provided for @gitPull.
  ///
  /// In zh, this message translates to:
  /// **'拉取'**
  String get gitPull;

  /// No description provided for @gitPush.
  ///
  /// In zh, this message translates to:
  /// **'推送'**
  String get gitPush;

  /// No description provided for @gitPullDirtyConfirm.
  ///
  /// In zh, this message translates to:
  /// **'当前工作区有未提交改动,拉取可能导致冲突。建议先提交或暂存。仍要继续拉取吗?'**
  String get gitPullDirtyConfirm;

  /// No description provided for @gitPullContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续拉取'**
  String get gitPullContinue;

  /// No description provided for @gitNoUpstream.
  ///
  /// In zh, this message translates to:
  /// **'未设置上游'**
  String get gitNoUpstream;

  /// No description provided for @gitTrackingBranch.
  ///
  /// In zh, this message translates to:
  /// **'跟踪 {name}'**
  String gitTrackingBranch(String name);

  /// No description provided for @gitAheadCount.
  ///
  /// In zh, this message translates to:
  /// **'待推送 {count}'**
  String gitAheadCount(int count);

  /// No description provided for @gitBehindCount.
  ///
  /// In zh, this message translates to:
  /// **'待拉取 {count}'**
  String gitBehindCount(int count);

  /// No description provided for @gitBranchSynced.
  ///
  /// In zh, this message translates to:
  /// **'已同步'**
  String get gitBranchSynced;

  /// No description provided for @gitDetachedHeadLabel.
  ///
  /// In zh, this message translates to:
  /// **'detached HEAD:当前不在任何分支上'**
  String get gitDetachedHeadLabel;

  /// No description provided for @gitNoBranch.
  ///
  /// In zh, this message translates to:
  /// **'(无分支)'**
  String get gitNoBranch;

  /// No description provided for @gitLoadingBranches.
  ///
  /// In zh, this message translates to:
  /// **'正在加载分支列表…'**
  String get gitLoadingBranches;

  /// No description provided for @gitNoCheckedOutBranch.
  ///
  /// In zh, this message translates to:
  /// **'未检出分支'**
  String get gitNoCheckedOutBranch;

  /// No description provided for @gitClean.
  ///
  /// In zh, this message translates to:
  /// **'工作区干净'**
  String get gitClean;

  /// No description provided for @gitHasChanges.
  ///
  /// In zh, this message translates to:
  /// **'工作区有改动'**
  String get gitHasChanges;

  /// No description provided for @gitNotARepo.
  ///
  /// In zh, this message translates to:
  /// **'当前工作区还不是 Git 仓库'**
  String get gitNotARepo;

  /// No description provided for @gitCloningHint.
  ///
  /// In zh, this message translates to:
  /// **'正在克隆仓库,请稍候…'**
  String get gitCloningHint;

  /// No description provided for @gitInitDescPrimary.
  ///
  /// In zh, this message translates to:
  /// **'可在此初始化新仓库,开始版本管理'**
  String get gitInitDescPrimary;

  /// No description provided for @gitInitDescSecondary.
  ///
  /// In zh, this message translates to:
  /// **'若子目录已有 Git 仓库,也可直接选择使用'**
  String get gitInitDescSecondary;

  /// No description provided for @gitInitRepo.
  ///
  /// In zh, this message translates to:
  /// **'初始化新仓库'**
  String get gitInitRepo;

  /// No description provided for @gitCloneRepo.
  ///
  /// In zh, this message translates to:
  /// **'克隆远程仓库'**
  String get gitCloneRepo;

  /// No description provided for @gitCloneDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'克隆 Git 仓库'**
  String get gitCloneDialogTitle;

  /// No description provided for @gitCloneDesc.
  ///
  /// In zh, this message translates to:
  /// **'将远程仓库克隆到当前工作区根目录(工作区需为空)。若为私有仓库,可先点右上角钥匙登录 GitHub 或填入访问令牌。'**
  String get gitCloneDesc;

  /// No description provided for @gitCloneUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'仓库地址'**
  String get gitCloneUrlLabel;

  /// No description provided for @gitCloning.
  ///
  /// In zh, this message translates to:
  /// **'正在克隆仓库,请稍候…'**
  String get gitCloning;

  /// No description provided for @gitSwitchRepo.
  ///
  /// In zh, this message translates to:
  /// **'切换仓库'**
  String get gitSwitchRepo;

  /// No description provided for @gitPickExistingRepo.
  ///
  /// In zh, this message translates to:
  /// **'选择已有仓库'**
  String get gitPickExistingRepo;

  /// No description provided for @gitRepoSelectorTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择仓库'**
  String get gitRepoSelectorTitle;

  /// No description provided for @gitRepoNotRepo.
  ///
  /// In zh, this message translates to:
  /// **'非仓库'**
  String get gitRepoNotRepo;

  /// No description provided for @gitPickRepoEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前工作区没有可选的目录'**
  String get gitPickRepoEmpty;

  /// No description provided for @gitNoBranches.
  ///
  /// In zh, this message translates to:
  /// **'暂无分支'**
  String get gitNoBranches;

  /// No description provided for @gitNewBranch.
  ///
  /// In zh, this message translates to:
  /// **'新建分支'**
  String get gitNewBranch;

  /// No description provided for @gitBranchName.
  ///
  /// In zh, this message translates to:
  /// **'分支名'**
  String get gitBranchName;

  /// No description provided for @gitBaseBranch.
  ///
  /// In zh, this message translates to:
  /// **'基准分支'**
  String get gitBaseBranch;

  /// No description provided for @gitCreateAndSwitch.
  ///
  /// In zh, this message translates to:
  /// **'创建并切换'**
  String get gitCreateAndSwitch;

  /// No description provided for @gitDeleteBranch.
  ///
  /// In zh, this message translates to:
  /// **'删除分支'**
  String get gitDeleteBranch;

  /// No description provided for @gitDeleteLocalBranchConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除本地分支 {name}?'**
  String gitDeleteLocalBranchConfirm(String name);

  /// No description provided for @gitDeleteRemoteBranch.
  ///
  /// In zh, this message translates to:
  /// **'删除远程分支'**
  String get gitDeleteRemoteBranch;

  /// No description provided for @gitDeleteRemoteBranchConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除远程分支 {name}?该操作不可撤销。'**
  String gitDeleteRemoteBranchConfirm(String name);

  /// No description provided for @gitRenameBranch.
  ///
  /// In zh, this message translates to:
  /// **'重命名分支'**
  String get gitRenameBranch;

  /// No description provided for @gitRenameTo.
  ///
  /// In zh, this message translates to:
  /// **'将 {name} 重命名为:'**
  String gitRenameTo(String name);

  /// No description provided for @gitNewBranchName.
  ///
  /// In zh, this message translates to:
  /// **'新分支名'**
  String get gitNewBranchName;

  /// No description provided for @gitTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get gitTags;

  /// No description provided for @gitTagName.
  ///
  /// In zh, this message translates to:
  /// **'标签名'**
  String get gitTagName;

  /// No description provided for @gitDeleteTag.
  ///
  /// In zh, this message translates to:
  /// **'删除标签'**
  String get gitDeleteTag;

  /// No description provided for @gitDeleteTagConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除本地标签 {name}?'**
  String gitDeleteTagConfirm(String name);

  /// No description provided for @gitCreateTagDesc.
  ///
  /// In zh, this message translates to:
  /// **'从当前 HEAD({hash})创建轻量标签'**
  String gitCreateTagDesc(String hash);

  /// No description provided for @gitCheckedOut.
  ///
  /// In zh, this message translates to:
  /// **'当前检出'**
  String get gitCheckedOut;

  /// No description provided for @gitCurrentBranch.
  ///
  /// In zh, this message translates to:
  /// **'当前分支'**
  String get gitCurrentBranch;

  /// No description provided for @gitRemote.
  ///
  /// In zh, this message translates to:
  /// **'远程'**
  String get gitRemote;

  /// No description provided for @commonLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get commonLocal;

  /// No description provided for @gitNew.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get gitNew;

  /// No description provided for @gitNoCommits.
  ///
  /// In zh, this message translates to:
  /// **'暂无提交记录'**
  String get gitNoCommits;

  /// No description provided for @gitCommitCount.
  ///
  /// In zh, this message translates to:
  /// **'提交记录 ({count})'**
  String gitCommitCount(int count);

  /// No description provided for @gitSearchCommitsHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索提交说明或作者…'**
  String get gitSearchCommitsHint;

  /// No description provided for @gitLoadMoreCommits.
  ///
  /// In zh, this message translates to:
  /// **'上拉加载更早提交'**
  String get gitLoadMoreCommits;

  /// No description provided for @gitNoMoreCommits.
  ///
  /// In zh, this message translates to:
  /// **'没有更多了'**
  String get gitNoMoreCommits;

  /// No description provided for @gitLatestCommit.
  ///
  /// In zh, this message translates to:
  /// **'最新提交'**
  String get gitLatestCommit;

  /// No description provided for @gitFilesChanged.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件改动'**
  String gitFilesChanged(int count);

  /// No description provided for @gitNoFilesChanged.
  ///
  /// In zh, this message translates to:
  /// **'该提交无文件改动'**
  String get gitNoFilesChanged;

  /// No description provided for @gitMergeCommit.
  ///
  /// In zh, this message translates to:
  /// **'合并提交'**
  String get gitMergeCommit;

  /// No description provided for @gitLoadingFiles.
  ///
  /// In zh, this message translates to:
  /// **'正在加载改动文件…'**
  String get gitLoadingFiles;

  /// No description provided for @gitCopyShortHash.
  ///
  /// In zh, this message translates to:
  /// **'复制短哈希'**
  String get gitCopyShortHash;

  /// No description provided for @gitCopyFullHash.
  ///
  /// In zh, this message translates to:
  /// **'复制完整哈希'**
  String get gitCopyFullHash;

  /// No description provided for @gitActionCreateBranch.
  ///
  /// In zh, this message translates to:
  /// **'创建分支'**
  String get gitActionCreateBranch;

  /// No description provided for @gitActionCreateTag.
  ///
  /// In zh, this message translates to:
  /// **'创建标签'**
  String get gitActionCreateTag;

  /// No description provided for @gitCreateBranchFromCommit.
  ///
  /// In zh, this message translates to:
  /// **'基于此提交创建分支'**
  String get gitCreateBranchFromCommit;

  /// No description provided for @gitCreateTagAtCommit.
  ///
  /// In zh, this message translates to:
  /// **'在此提交创建标签'**
  String get gitCreateTagAtCommit;

  /// No description provided for @gitResetToCommit.
  ///
  /// In zh, this message translates to:
  /// **'重置到此提交 (Reset)'**
  String get gitResetToCommit;

  /// No description provided for @gitResetSoft.
  ///
  /// In zh, this message translates to:
  /// **'Soft(保留工作区与暂存区)'**
  String get gitResetSoft;

  /// No description provided for @gitResetMixed.
  ///
  /// In zh, this message translates to:
  /// **'Mixed(保留工作区,清空暂存区)'**
  String get gitResetMixed;

  /// No description provided for @gitResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将当前分支重置到提交 {hash} 吗?'**
  String gitResetConfirm(String hash);

  /// No description provided for @gitDiffBinary.
  ///
  /// In zh, this message translates to:
  /// **'二进制文件,不显示差异'**
  String get gitDiffBinary;

  /// No description provided for @gitDiffTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'文件过大,未计算差异'**
  String get gitDiffTooLarge;

  /// No description provided for @gitDiffEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有可显示的差异'**
  String get gitDiffEmpty;

  /// No description provided for @gitCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get gitCopyPath;

  /// No description provided for @gitViewDiff.
  ///
  /// In zh, this message translates to:
  /// **'查看差异'**
  String get gitViewDiff;

  /// No description provided for @gitRevert.
  ///
  /// In zh, this message translates to:
  /// **'回退改动'**
  String get gitRevert;

  /// No description provided for @gitDeleteUntrackedConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除 {name}?它从未被提交过,删除后无法通过 Git 恢复。'**
  String gitDeleteUntrackedConfirm(Object name);

  /// No description provided for @gitAddToGitignore.
  ///
  /// In zh, this message translates to:
  /// **'添加到 .gitignore'**
  String get gitAddToGitignore;

  /// No description provided for @gitIgnoreFile.
  ///
  /// In zh, this message translates to:
  /// **'忽略此文件 ({name})'**
  String gitIgnoreFile(String name);

  /// No description provided for @gitIgnoreDir.
  ///
  /// In zh, this message translates to:
  /// **'忽略整个目录 ({name}/)'**
  String gitIgnoreDir(String name);

  /// No description provided for @gitIgnoreExtension.
  ///
  /// In zh, this message translates to:
  /// **'忽略同类型文件 (*.{ext})'**
  String gitIgnoreExtension(String ext);

  /// No description provided for @gitPathCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制路径'**
  String get gitPathCopied;

  /// No description provided for @gitActionFailed.
  ///
  /// In zh, this message translates to:
  /// **'{action}失败:{error}'**
  String gitActionFailed(String action, String error);

  /// No description provided for @gitActionDone.
  ///
  /// In zh, this message translates to:
  /// **'{action}成功'**
  String gitActionDone(String action);

  /// No description provided for @gitCheckoutSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已切换到 {name}'**
  String gitCheckoutSuccess(String name);

  /// No description provided for @gitNoRemotePull.
  ///
  /// In zh, this message translates to:
  /// **'未配置远程仓库,无法拉取'**
  String get gitNoRemotePull;

  /// No description provided for @gitNoRemotePush.
  ///
  /// In zh, this message translates to:
  /// **'未配置远程仓库,无法推送'**
  String get gitNoRemotePush;

  /// No description provided for @gitPushMasterConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'分支命名建议'**
  String get gitPushMasterConfirmTitle;

  /// No description provided for @gitPushMasterConfirmDesc.
  ///
  /// In zh, this message translates to:
  /// **'当前本地分支为 master,GitHub 与 GitLab 推荐使用 main 作为默认主分支。是否将本地分支重命名为 main 后再推送?'**
  String get gitPushMasterConfirmDesc;

  /// No description provided for @gitPushRenameToMain.
  ///
  /// In zh, this message translates to:
  /// **'重命名为 main 并推送'**
  String get gitPushRenameToMain;

  /// No description provided for @gitPushKeepMaster.
  ///
  /// In zh, this message translates to:
  /// **'保留 master 推送'**
  String get gitPushKeepMaster;

  /// No description provided for @gitTesting.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get gitTesting;

  /// No description provided for @credentialToken.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌(Token / PAT)'**
  String get credentialToken;

  /// No description provided for @gitUserName.
  ///
  /// In zh, this message translates to:
  /// **'user.name'**
  String get gitUserName;

  /// No description provided for @gitUserEmail.
  ///
  /// In zh, this message translates to:
  /// **'user.email'**
  String get gitUserEmail;

  /// No description provided for @gitRepoUrl.
  ///
  /// In zh, this message translates to:
  /// **'仓库地址'**
  String get gitRepoUrl;

  /// No description provided for @gitSelectBranch.
  ///
  /// In zh, this message translates to:
  /// **'选择基准分支'**
  String get gitSelectBranch;

  /// No description provided for @credentialTokenLogin.
  ///
  /// In zh, this message translates to:
  /// **'令牌登录'**
  String get credentialTokenLogin;

  /// No description provided for @credentialTokenLoginDesc.
  ///
  /// In zh, this message translates to:
  /// **'只需粘贴访问令牌(PAT),推送时自动匹配远端主机'**
  String get credentialTokenLoginDesc;

  /// No description provided for @credentialTokenSaved.
  ///
  /// In zh, this message translates to:
  /// **'令牌已保存'**
  String get credentialTokenSaved;

  /// No description provided for @commonShow.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get commonShow;

  /// No description provided for @commonHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get commonHide;

  /// No description provided for @credentialAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加凭据'**
  String get credentialAdd;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理 AI、外观、同步和应用数据'**
  String get settingsSubtitle;

  /// No description provided for @accountAndData.
  ///
  /// In zh, this message translates to:
  /// **'账户与数据'**
  String get accountAndData;

  /// No description provided for @themeTitle.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'外观、背景与显示'**
  String get themeSubtitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'版本、更新与反馈'**
  String get aboutSubtitle;

  /// No description provided for @aboutAutoCheck.
  ///
  /// In zh, this message translates to:
  /// **'自动检查更新'**
  String get aboutAutoCheck;

  /// No description provided for @aboutAutoCheckDesc.
  ///
  /// In zh, this message translates to:
  /// **'打开 App 时自动检测新版本'**
  String get aboutAutoCheckDesc;

  /// No description provided for @aboutUpdateChannel.
  ///
  /// In zh, this message translates to:
  /// **'更新通道'**
  String get aboutUpdateChannel;

  /// No description provided for @aboutStableChannel.
  ///
  /// In zh, this message translates to:
  /// **'稳定版'**
  String get aboutStableChannel;

  /// No description provided for @aboutDownloadMirror.
  ///
  /// In zh, this message translates to:
  /// **'下载镜像源'**
  String get aboutDownloadMirror;

  /// No description provided for @aboutMirrorUrl.
  ///
  /// In zh, this message translates to:
  /// **'https://cdn.gh-proxy.co...'**
  String get aboutMirrorUrl;

  /// No description provided for @githubRepo.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库'**
  String get githubRepo;

  /// No description provided for @aboutUserAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get aboutUserAgreement;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get aboutPrivacyPolicy;

  /// No description provided for @mcpTitle.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器'**
  String get mcpTitle;

  /// No description provided for @mcpSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'接入外部工具的 Model Context Protocol 服务'**
  String get mcpSubtitle;

  /// No description provided for @mcpAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加 MCP'**
  String get mcpAdd;

  /// No description provided for @mcpEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑 MCP'**
  String get mcpEdit;

  /// No description provided for @mcpEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有配置 MCP 服务器'**
  String get mcpEmpty;

  /// No description provided for @mcpEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 可以添加远程 HTTP 或本地 stdio 服务器'**
  String get mcpEmptyHint;

  /// No description provided for @mcpSearchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索 MCP 服务器…'**
  String get mcpSearchPlaceholder;

  /// No description provided for @mcpSearchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的 MCP 服务器'**
  String get mcpSearchEmpty;

  /// No description provided for @mcpScopeLabel.
  ///
  /// In zh, this message translates to:
  /// **'作用域'**
  String get mcpScopeLabel;

  /// No description provided for @mcpScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get mcpScopeGlobal;

  /// No description provided for @mcpScopeProject.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get mcpScopeProject;

  /// No description provided for @mcpTypeStdio.
  ///
  /// In zh, this message translates to:
  /// **'stdio'**
  String get mcpTypeStdio;

  /// No description provided for @mcpStatusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get mcpStatusDisabled;

  /// No description provided for @mcpStatusNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get mcpStatusNotConnected;

  /// No description provided for @mcpStatusConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get mcpStatusConnected;

  /// No description provided for @mcpStatusConnecting.
  ///
  /// In zh, this message translates to:
  /// **'连接中…'**
  String get mcpStatusConnecting;

  /// No description provided for @mcpStatusFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get mcpStatusFailed;

  /// No description provided for @mcpStatusNeedsAuth.
  ///
  /// In zh, this message translates to:
  /// **'需要登录'**
  String get mcpStatusNeedsAuth;

  /// No description provided for @mcpToolsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个工具'**
  String mcpToolsCount(int count);

  /// No description provided for @mcpDetails.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get mcpDetails;

  /// No description provided for @mcpBasicSettings.
  ///
  /// In zh, this message translates to:
  /// **'基础设置'**
  String get mcpBasicSettings;

  /// No description provided for @mcpEnabledLabel.
  ///
  /// In zh, this message translates to:
  /// **'是否启用'**
  String get mcpEnabledLabel;

  /// No description provided for @mcpNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get mcpNameLabel;

  /// No description provided for @mcpNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如:fetch、github、gitlab'**
  String get mcpNameHint;

  /// No description provided for @mcpNameInvalid.
  ///
  /// In zh, this message translates to:
  /// **'名称只能包含字母、数字、下划线和连字符'**
  String get mcpNameInvalid;

  /// No description provided for @mcpTransportType.
  ///
  /// In zh, this message translates to:
  /// **'传输类型'**
  String get mcpTransportType;

  /// No description provided for @mcpRemoteHttp.
  ///
  /// In zh, this message translates to:
  /// **'远程 HTTP'**
  String get mcpRemoteHttp;

  /// No description provided for @mcpLocalStdio.
  ///
  /// In zh, this message translates to:
  /// **'本地 stdio'**
  String get mcpLocalStdio;

  /// No description provided for @mcpServerUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get mcpServerUrl;

  /// No description provided for @mcpServerUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'例如:https://api.example.com/mcp'**
  String get mcpServerUrlHint;

  /// No description provided for @mcpCustomHeaders.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头'**
  String get mcpCustomHeaders;

  /// No description provided for @mcpNoCustomHeaders.
  ///
  /// In zh, this message translates to:
  /// **'暂无配置的自定义 Header'**
  String get mcpNoCustomHeaders;

  /// No description provided for @mcpHeaderName.
  ///
  /// In zh, this message translates to:
  /// **'请求头名称'**
  String get mcpHeaderName;

  /// No description provided for @mcpHeaderNameHint.
  ///
  /// In zh, this message translates to:
  /// **'如 Authorization'**
  String get mcpHeaderNameHint;

  /// No description provided for @mcpHeaderValue.
  ///
  /// In zh, this message translates to:
  /// **'请求头值'**
  String get mcpHeaderValue;

  /// No description provided for @mcpHeaderValueHint.
  ///
  /// In zh, this message translates to:
  /// **'如 Bearer xxxxxx'**
  String get mcpHeaderValueHint;

  /// No description provided for @mcpAddHeader.
  ///
  /// In zh, this message translates to:
  /// **'添加请求头'**
  String get mcpAddHeader;

  /// No description provided for @mcpCommand.
  ///
  /// In zh, this message translates to:
  /// **'启动命令'**
  String get mcpCommand;

  /// No description provided for @mcpCommandHint.
  ///
  /// In zh, this message translates to:
  /// **'例如:npx'**
  String get mcpCommandHint;

  /// No description provided for @mcpArgs.
  ///
  /// In zh, this message translates to:
  /// **'命令参数'**
  String get mcpArgs;

  /// No description provided for @mcpNoArgs.
  ///
  /// In zh, this message translates to:
  /// **'无额外命令行参数'**
  String get mcpNoArgs;

  /// No description provided for @mcpArgValue.
  ///
  /// In zh, this message translates to:
  /// **'参数值'**
  String get mcpArgValue;

  /// No description provided for @mcpArgHint.
  ///
  /// In zh, this message translates to:
  /// **'如 -y 或 @modelcontextprotocol/server-xxx'**
  String get mcpArgHint;

  /// No description provided for @mcpAddArg.
  ///
  /// In zh, this message translates to:
  /// **'添加参数'**
  String get mcpAddArg;

  /// No description provided for @mcpToolsSummary.
  ///
  /// In zh, this message translates to:
  /// **'已启用 {enabled} / {total} 个工具'**
  String mcpToolsSummary(int enabled, int total);

  /// No description provided for @mcpToolsSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索工具名称或描述…'**
  String get mcpToolsSearch;

  /// No description provided for @mcpToolsSearchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的工具'**
  String get mcpToolsSearchEmpty;

  /// No description provided for @mcpToolsEnableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部启用'**
  String get mcpToolsEnableAll;

  /// No description provided for @mcpToolsDisableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部禁用'**
  String get mcpToolsDisableAll;

  /// No description provided for @mcpSaveFirstHint.
  ///
  /// In zh, this message translates to:
  /// **'请先保存并连接服务器后查看工具列表'**
  String get mcpSaveFirstHint;

  /// No description provided for @mcpNoToolsHint.
  ///
  /// In zh, this message translates to:
  /// **'未检测到工具,点击右上角刷新按钮重试'**
  String get mcpNoToolsHint;

  /// No description provided for @mcpNoDescription.
  ///
  /// In zh, this message translates to:
  /// **'无描述'**
  String get mcpNoDescription;

  /// No description provided for @mcpAddSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加 MCP 服务器'**
  String get mcpAddSheetTitle;

  /// No description provided for @mcpAddManual.
  ///
  /// In zh, this message translates to:
  /// **'手动填写'**
  String get mcpAddManual;

  /// No description provided for @mcpAddManualDesc.
  ///
  /// In zh, this message translates to:
  /// **'逐个填写地址、请求头或启动命令'**
  String get mcpAddManualDesc;

  /// No description provided for @mcpAddFromJson.
  ///
  /// In zh, this message translates to:
  /// **'从 JSON 导入'**
  String get mcpAddFromJson;

  /// No description provided for @mcpAddFromJsonDesc.
  ///
  /// In zh, this message translates to:
  /// **'粘贴标准 mcpServers 配置批量导入'**
  String get mcpAddFromJsonDesc;

  /// No description provided for @mcpJsonImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'从 JSON 导入'**
  String get mcpJsonImportTitle;

  /// No description provided for @mcpJsonImportHint.
  ///
  /// In zh, this message translates to:
  /// **'粘贴标准 mcpServers 配置:键是服务器名,值里填 url(远程 HTTP)或 command(本地 stdio)。'**
  String get mcpJsonImportHint;

  /// No description provided for @mcpJsonImportAction.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get mcpJsonImportAction;

  /// No description provided for @mcpJsonImportEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未解析到任何 MCP 服务器'**
  String get mcpJsonImportEmpty;

  /// No description provided for @mcpSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get mcpSaved;

  /// No description provided for @mcpRefreshTools.
  ///
  /// In zh, this message translates to:
  /// **'刷新工具'**
  String get mcpRefreshTools;

  /// No description provided for @mcpRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移除 MCP 服务器'**
  String get mcpRemoved;

  /// No description provided for @permissionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'工具授权'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'规则与记忆'**
  String get permissionsSubtitle;

  /// No description provided for @permCurrentProject.
  ///
  /// In zh, this message translates to:
  /// **'当前项目:{name}'**
  String permCurrentProject(String name);

  /// No description provided for @permCurrentProjectNone.
  ///
  /// In zh, this message translates to:
  /// **'当前项目(未选择)'**
  String get permCurrentProjectNone;

  /// No description provided for @permNoProjectRules.
  ///
  /// In zh, this message translates to:
  /// **'本项目暂无规则'**
  String get permNoProjectRules;

  /// No description provided for @permGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get permGlobal;

  /// No description provided for @permNoGlobalRules.
  ///
  /// In zh, this message translates to:
  /// **'暂无全局规则'**
  String get permNoGlobalRules;

  /// No description provided for @permEntireTool.
  ///
  /// In zh, this message translates to:
  /// **'整个工具'**
  String get permEntireTool;

  /// No description provided for @permDeny.
  ///
  /// In zh, this message translates to:
  /// **'禁止'**
  String get permDeny;

  /// No description provided for @permPromoteToGlobal.
  ///
  /// In zh, this message translates to:
  /// **'提升为全局'**
  String get permPromoteToGlobal;

  /// No description provided for @permRulesShort.
  ///
  /// In zh, this message translates to:
  /// **'对话中选「始终运行」会在当前项目生成记忆规则'**
  String get permRulesShort;

  /// No description provided for @chatPermDeny.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get chatPermDeny;

  /// No description provided for @chatPermAlwaysAllow.
  ///
  /// In zh, this message translates to:
  /// **'始终运行'**
  String get chatPermAlwaysAllow;

  /// No description provided for @chatPermAlwaysToolDesc.
  ///
  /// In zh, this message translates to:
  /// **'「始终运行」将在本项目记住:该工具的全部调用'**
  String get chatPermAlwaysToolDesc;

  /// No description provided for @chatPermAlwaysPrefix.
  ///
  /// In zh, this message translates to:
  /// **'「始终运行」将在本项目记住:'**
  String get chatPermAlwaysPrefix;

  /// No description provided for @chatPermSingleUseDesc.
  ///
  /// In zh, this message translates to:
  /// **'该调用不可记忆,仅可单次放行'**
  String get chatPermSingleUseDesc;

  /// No description provided for @commonName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get commonName;

  /// No description provided for @commonTool.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get commonTool;

  /// No description provided for @commonAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// No description provided for @commonLabelWithApi.
  ///
  /// In zh, this message translates to:
  /// **'{label}({api})'**
  String commonLabelWithApi(String label, String api);

  /// No description provided for @commonExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get commonExpand;

  /// No description provided for @commonCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get commonCollapse;

  /// No description provided for @mcpViewLogs.
  ///
  /// In zh, this message translates to:
  /// **'查看此 MCP 日志'**
  String get mcpViewLogs;

  /// No description provided for @mcpAuthEnable.
  ///
  /// In zh, this message translates to:
  /// **'OAuth 认证'**
  String get mcpAuthEnable;

  /// No description provided for @mcpAuthDesc.
  ///
  /// In zh, this message translates to:
  /// **'用于需要浏览器登录授权的远程 MCP 服务'**
  String get mcpAuthDesc;

  /// No description provided for @mcpAuthClientId.
  ///
  /// In zh, this message translates to:
  /// **'client_id(可选)'**
  String get mcpAuthClientId;

  /// No description provided for @mcpAuthClientIdHint.
  ///
  /// In zh, this message translates to:
  /// **'预注册的客户端 ID;留空则尝试动态注册'**
  String get mcpAuthClientIdHint;

  /// No description provided for @mcpAuthServer.
  ///
  /// In zh, this message translates to:
  /// **'授权服务器(可选)'**
  String get mcpAuthServer;

  /// No description provided for @mcpAuthServerHint.
  ///
  /// In zh, this message translates to:
  /// **'覆盖自动发现的授权服务器地址'**
  String get mcpAuthServerHint;

  /// No description provided for @mcpAuthAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级认证选项'**
  String get mcpAuthAdvanced;

  /// No description provided for @mcpAuthLogin.
  ///
  /// In zh, this message translates to:
  /// **'登录 / 重新授权'**
  String get mcpAuthLogin;

  /// No description provided for @mcpAuthReauthorize.
  ///
  /// In zh, this message translates to:
  /// **'重新授权'**
  String get mcpAuthReauthorize;

  /// No description provided for @mcpAuthLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get mcpAuthLogout;

  /// No description provided for @mcpAuthCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消授权'**
  String get mcpAuthCancel;

  /// No description provided for @mcpAuthInProgress.
  ///
  /// In zh, this message translates to:
  /// **'等待浏览器授权…'**
  String get mcpAuthInProgress;

  /// No description provided for @mcpAuthInProgressHint.
  ///
  /// In zh, this message translates to:
  /// **'已在系统浏览器打开登录页,授权完成后将自动返回并连接'**
  String get mcpAuthInProgressHint;

  /// No description provided for @mcpAuthSaveFirst.
  ///
  /// In zh, this message translates to:
  /// **'保存服务器配置后,即可在此发起登录授权'**
  String get mcpAuthSaveFirst;

  /// No description provided for @mcpAuthFailed.
  ///
  /// In zh, this message translates to:
  /// **'授权失败:{message}'**
  String mcpAuthFailed(String message);

  /// No description provided for @mcpAuthStatusLabel.
  ///
  /// In zh, this message translates to:
  /// **'授权状态'**
  String get mcpAuthStatusLabel;

  /// No description provided for @mcpAuthStatusAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'已登录'**
  String get mcpAuthStatusAuthorized;

  /// No description provided for @mcpAuthStatusUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get mcpAuthStatusUnauthorized;

  /// No description provided for @mcpAuthStatusAuthorizing.
  ///
  /// In zh, this message translates to:
  /// **'授权中'**
  String get mcpAuthStatusAuthorizing;

  /// No description provided for @mcpAuthSuccess.
  ///
  /// In zh, this message translates to:
  /// **'授权成功,已连接'**
  String get mcpAuthSuccess;

  /// No description provided for @settingsReconnect.
  ///
  /// In zh, this message translates to:
  /// **'重新连接'**
  String get settingsReconnect;

  /// No description provided for @settingsAddMcpServer.
  ///
  /// In zh, this message translates to:
  /// **'添加 MCP 服务器'**
  String get settingsAddMcpServer;

  /// No description provided for @settingsContainer.
  ///
  /// In zh, this message translates to:
  /// **'容器与镜像'**
  String get settingsContainer;

  /// No description provided for @settingsContainerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'PRoot 容器、镜像与初始化'**
  String get settingsContainerSubtitle;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonSwitch.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get commonSwitch;

  /// No description provided for @chatOpenTerminal.
  ///
  /// In zh, this message translates to:
  /// **'打开终端'**
  String get chatOpenTerminal;

  /// No description provided for @terminalTitle.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get terminalTitle;

  /// No description provided for @terminalStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法启动终端:\n{message}'**
  String terminalStartFailed(String message);

  /// No description provided for @terminalRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get terminalRetry;

  /// No description provided for @terminalNoOpenTabs.
  ///
  /// In zh, this message translates to:
  /// **'没有打开的终端标签'**
  String get terminalNoOpenTabs;

  /// No description provided for @terminalNewTab.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get terminalNewTab;

  /// No description provided for @terminalCloseTab.
  ///
  /// In zh, this message translates to:
  /// **'关闭标签'**
  String get terminalCloseTab;

  /// No description provided for @terminalSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'终端设置'**
  String get terminalSettingsTitle;

  /// No description provided for @terminalThemeTitle.
  ///
  /// In zh, this message translates to:
  /// **'配色主题'**
  String get terminalThemeTitle;

  /// No description provided for @terminalThemeFollowApp.
  ///
  /// In zh, this message translates to:
  /// **'跟随应用'**
  String get terminalThemeFollowApp;

  /// No description provided for @terminalThemeTermiusDark.
  ///
  /// In zh, this message translates to:
  /// **'Termius Dark'**
  String get terminalThemeTermiusDark;

  /// No description provided for @terminalThemeGithubLight.
  ///
  /// In zh, this message translates to:
  /// **'GitHub Light'**
  String get terminalThemeGithubLight;

  /// No description provided for @terminalThemeDracula.
  ///
  /// In zh, this message translates to:
  /// **'Dracula'**
  String get terminalThemeDracula;

  /// No description provided for @terminalThemeOneDark.
  ///
  /// In zh, this message translates to:
  /// **'One Dark'**
  String get terminalThemeOneDark;

  /// No description provided for @terminalThemeMonokai.
  ///
  /// In zh, this message translates to:
  /// **'Monokai'**
  String get terminalThemeMonokai;

  /// No description provided for @terminalThemeGithubDark.
  ///
  /// In zh, this message translates to:
  /// **'GitHub Dark'**
  String get terminalThemeGithubDark;

  /// No description provided for @terminalFontSizeTitle.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get terminalFontSizeTitle;

  /// No description provided for @terminalCursorStyleTitle.
  ///
  /// In zh, this message translates to:
  /// **'光标样式'**
  String get terminalCursorStyleTitle;

  /// No description provided for @terminalCursorBlock.
  ///
  /// In zh, this message translates to:
  /// **'方块'**
  String get terminalCursorBlock;

  /// No description provided for @terminalCursorUnderline.
  ///
  /// In zh, this message translates to:
  /// **'下划线'**
  String get terminalCursorUnderline;

  /// No description provided for @terminalCursorBar.
  ///
  /// In zh, this message translates to:
  /// **'竖线'**
  String get terminalCursorBar;

  /// No description provided for @terminalFontTitle.
  ///
  /// In zh, this message translates to:
  /// **'终端字体'**
  String get terminalFontTitle;

  /// No description provided for @terminalFontDefault.
  ///
  /// In zh, this message translates to:
  /// **'系统等宽'**
  String get terminalFontDefault;

  /// No description provided for @terminalFontBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'JetBrains Mono'**
  String get terminalFontBuiltin;

  /// No description provided for @settingsGeneral.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get settingsGeneral;

  /// No description provided for @settingsGeneralModels.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get settingsGeneralModels;

  /// No description provided for @settingsAutoRemoveStaleModels.
  ///
  /// In zh, this message translates to:
  /// **'拉取模型后自动移除无效模型'**
  String get settingsAutoRemoveStaleModels;

  /// No description provided for @settingsAutoRemoveStaleModelsDesc.
  ///
  /// In zh, this message translates to:
  /// **'拉取成功后,移除远端已不存在的本地模型条目'**
  String get settingsAutoRemoveStaleModelsDesc;

  /// No description provided for @settingsGeneralSession.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get settingsGeneralSession;

  /// No description provided for @settingsStartupSession.
  ///
  /// In zh, this message translates to:
  /// **'启动时会话'**
  String get settingsStartupSession;

  /// No description provided for @settingsStartupSessionNew.
  ///
  /// In zh, this message translates to:
  /// **'新开会话'**
  String get settingsStartupSessionNew;

  /// No description provided for @settingsStartupSessionNewDesc.
  ///
  /// In zh, this message translates to:
  /// **'复用尚未发送过消息的空会话,否则新建'**
  String get settingsStartupSessionNewDesc;

  /// No description provided for @settingsStartupSessionRecent.
  ///
  /// In zh, this message translates to:
  /// **'打开最近会话'**
  String get settingsStartupSessionRecent;

  /// No description provided for @settingsStartupSessionRecentDesc.
  ///
  /// In zh, this message translates to:
  /// **'直接进入最近更新的会话'**
  String get settingsStartupSessionRecentDesc;

  /// No description provided for @settingsDeleteExternalWorkspaceSessions.
  ///
  /// In zh, this message translates to:
  /// **'删除外部工作区聊天记录'**
  String get settingsDeleteExternalWorkspaceSessions;

  /// No description provided for @settingsDeleteExternalWorkspaceSessionsDesc.
  ///
  /// In zh, this message translates to:
  /// **'移除外部本地工作区时,一并删除该工作区的聊天记录'**
  String get settingsDeleteExternalWorkspaceSessionsDesc;

  /// No description provided for @settingsGeneralInput.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get settingsGeneralInput;

  /// No description provided for @settingsEnterToSend.
  ///
  /// In zh, this message translates to:
  /// **'回车键发送消息'**
  String get settingsEnterToSend;

  /// No description provided for @settingsEnterToSendDesc.
  ///
  /// In zh, this message translates to:
  /// **'关闭后回车换行,需点发送按钮发送'**
  String get settingsEnterToSendDesc;

  /// No description provided for @settingsCompactionThreshold.
  ///
  /// In zh, this message translates to:
  /// **'自动压缩阈值'**
  String get settingsCompactionThreshold;

  /// No description provided for @settingsCompactionThresholdDesc.
  ///
  /// In zh, this message translates to:
  /// **'上下文占用达到窗口的该比例时自动压缩'**
  String get settingsCompactionThresholdDesc;

  /// No description provided for @settingsCompactionThresholdInputHint.
  ///
  /// In zh, this message translates to:
  /// **'填 1-100 的整数百分比'**
  String get settingsCompactionThresholdInputHint;

  /// No description provided for @settingsPercentValue.
  ///
  /// In zh, this message translates to:
  /// **'{percent}%'**
  String settingsPercentValue(int percent);

  /// No description provided for @settingsGeneralNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get settingsGeneralNetwork;

  /// No description provided for @settingsFirstByteTimeout.
  ///
  /// In zh, this message translates to:
  /// **'首字节超时'**
  String get settingsFirstByteTimeout;

  /// No description provided for @settingsFirstByteTimeoutDesc.
  ///
  /// In zh, this message translates to:
  /// **'等待首个响应块的最长时间'**
  String get settingsFirstByteTimeoutDesc;

  /// No description provided for @settingsStreamIdleTimeout.
  ///
  /// In zh, this message translates to:
  /// **'数据块间隔超时'**
  String get settingsStreamIdleTimeout;

  /// No description provided for @settingsStreamIdleTimeoutDesc.
  ///
  /// In zh, this message translates to:
  /// **'两个响应块之间的最长等待'**
  String get settingsStreamIdleTimeoutDesc;

  /// No description provided for @settingsTimeoutUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'不限制'**
  String get settingsTimeoutUnlimited;

  /// No description provided for @settingsTimeoutSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String settingsTimeoutSeconds(int seconds);

  /// No description provided for @settingsTimeoutInputHint.
  ///
  /// In zh, this message translates to:
  /// **'单位秒,填 0 表示不限制'**
  String get settingsTimeoutInputHint;

  /// No description provided for @settingsMaxNetworkRetries.
  ///
  /// In zh, this message translates to:
  /// **'重试次数'**
  String get settingsMaxNetworkRetries;

  /// No description provided for @settingsMaxNetworkRetriesDesc.
  ///
  /// In zh, this message translates to:
  /// **'网络失败后的指数退避重试次数'**
  String get settingsMaxNetworkRetriesDesc;

  /// No description provided for @settingsRetriesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次'**
  String settingsRetriesCount(int count);

  /// No description provided for @settingsRetriesInputHint.
  ///
  /// In zh, this message translates to:
  /// **'填 0 表示不重试'**
  String get settingsRetriesInputHint;

  /// No description provided for @settingsGeneralTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get settingsGeneralTools;

  /// No description provided for @settingsSendfileMaxSize.
  ///
  /// In zh, this message translates to:
  /// **'sendFile 单文件上限'**
  String get settingsSendfileMaxSize;

  /// No description provided for @settingsGeneralGoal.
  ///
  /// In zh, this message translates to:
  /// **'目标(goal)'**
  String get settingsGeneralGoal;

  /// No description provided for @settingsGoalMaxTurns.
  ///
  /// In zh, this message translates to:
  /// **'最大续跑轮数'**
  String get settingsGoalMaxTurns;

  /// No description provided for @settingsGoalMaxTurnsDesc.
  ///
  /// In zh, this message translates to:
  /// **'自主循环最多续跑多少轮,达到即停止'**
  String get settingsGoalMaxTurnsDesc;

  /// No description provided for @settingsGoalMaxTokens.
  ///
  /// In zh, this message translates to:
  /// **'token 预算'**
  String get settingsGoalMaxTokens;

  /// No description provided for @settingsGoalMaxTokensDesc.
  ///
  /// In zh, this message translates to:
  /// **'自主循环累计消耗的输入+输出 token 上限'**
  String get settingsGoalMaxTokensDesc;

  /// No description provided for @settingsTurnsValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 轮'**
  String settingsTurnsValue(int count);

  /// No description provided for @settingsTokensValue.
  ///
  /// In zh, this message translates to:
  /// **'{count}'**
  String settingsTokensValue(int count);

  /// No description provided for @settingsGoalMaxTurnsInputHint.
  ///
  /// In zh, this message translates to:
  /// **'填大于 0 的整数轮数'**
  String get settingsGoalMaxTurnsInputHint;

  /// No description provided for @settingsGoalMaxTokensInputHint.
  ///
  /// In zh, this message translates to:
  /// **'填不小于 1000 的整数'**
  String get settingsGoalMaxTokensInputHint;

  /// No description provided for @settingsSendfileMaxSizeDesc.
  ///
  /// In zh, this message translates to:
  /// **'单个文件大小上限,超过则整批发送失败'**
  String get settingsSendfileMaxSizeDesc;

  /// No description provided for @settingsSendfileMaxSizeInputHint.
  ///
  /// In zh, this message translates to:
  /// **'单位 MB,填大于 0 的整数'**
  String get settingsSendfileMaxSizeInputHint;

  /// No description provided for @settingsMbValue.
  ///
  /// In zh, this message translates to:
  /// **'{mb} MB'**
  String settingsMbValue(int mb);

  /// No description provided for @providerModelsAlignedRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移除 {count} 个远端已不存在的模型'**
  String providerModelsAlignedRemoved(int count);

  /// No description provided for @tokenStatsTitle.
  ///
  /// In zh, this message translates to:
  /// **'Token 统计'**
  String get tokenStatsTitle;

  /// No description provided for @tokenStatsPeriodToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get tokenStatsPeriodToday;

  /// No description provided for @tokenStatsPeriod7d.
  ///
  /// In zh, this message translates to:
  /// **'近7天'**
  String get tokenStatsPeriod7d;

  /// No description provided for @tokenStatsPeriod30d.
  ///
  /// In zh, this message translates to:
  /// **'近30天'**
  String get tokenStatsPeriod30d;

  /// No description provided for @tokenStatsPeriodAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get tokenStatsPeriodAll;

  /// No description provided for @tokenStatsTotal.
  ///
  /// In zh, this message translates to:
  /// **'总消耗'**
  String get tokenStatsTotal;

  /// No description provided for @tokenStatsRequests.
  ///
  /// In zh, this message translates to:
  /// **'请求次数'**
  String get tokenStatsRequests;

  /// No description provided for @tokenStatsCost.
  ///
  /// In zh, this message translates to:
  /// **'费用'**
  String get tokenStatsCost;

  /// No description provided for @tokenStatsCacheHitRate.
  ///
  /// In zh, this message translates to:
  /// **'缓存命中率'**
  String get tokenStatsCacheHitRate;

  /// No description provided for @tokenStatsCacheReadWrite.
  ///
  /// In zh, this message translates to:
  /// **'读取 {read} / 写入 {write}'**
  String tokenStatsCacheReadWrite(String read, String write);

  /// No description provided for @tokenStatsTrend.
  ///
  /// In zh, this message translates to:
  /// **'消耗趋势'**
  String get tokenStatsTrend;

  /// No description provided for @tokenStatsLegendInput.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get tokenStatsLegendInput;

  /// No description provided for @tokenStatsLegendOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get tokenStatsLegendOutput;

  /// No description provided for @tokenStatsLegendCached.
  ///
  /// In zh, this message translates to:
  /// **'缓存'**
  String get tokenStatsLegendCached;

  /// No description provided for @tokenStatsProvider.
  ///
  /// In zh, this message translates to:
  /// **'供应商统计'**
  String get tokenStatsProvider;

  /// No description provided for @tokenStatsModel.
  ///
  /// In zh, this message translates to:
  /// **'模型统计'**
  String get tokenStatsModel;

  /// No description provided for @tokenStatsSuccessRate.
  ///
  /// In zh, this message translates to:
  /// **'成功率 {rate}'**
  String tokenStatsSuccessRate(String rate);

  /// No description provided for @tokenStatsRecentCalls.
  ///
  /// In zh, this message translates to:
  /// **'调用记录'**
  String get tokenStatsRecentCalls;

  /// No description provided for @tokenStatsUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get tokenStatsUnknown;

  /// No description provided for @tokenStatsNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get tokenStatsNoData;

  /// No description provided for @tokenStatsCallsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'次调用'**
  String get tokenStatsCallsSuffix;

  /// No description provided for @tokenStatsCallsSuffix2.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次调用'**
  String tokenStatsCallsSuffix2(int count);

  /// No description provided for @tokenStatsColModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get tokenStatsColModel;

  /// No description provided for @tokenStatsColReasoningEffort.
  ///
  /// In zh, this message translates to:
  /// **'思考强度'**
  String get tokenStatsColReasoningEffort;

  /// No description provided for @tokenStatsColProvider.
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get tokenStatsColProvider;

  /// No description provided for @tokenStatsColInput.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get tokenStatsColInput;

  /// No description provided for @tokenStatsColOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get tokenStatsColOutput;

  /// No description provided for @tokenStatsColCachedRead.
  ///
  /// In zh, this message translates to:
  /// **'缓存读取'**
  String get tokenStatsColCachedRead;

  /// No description provided for @tokenStatsColCachedWrite.
  ///
  /// In zh, this message translates to:
  /// **'缓存写入'**
  String get tokenStatsColCachedWrite;

  /// No description provided for @tokenStatsColCacheHitRate.
  ///
  /// In zh, this message translates to:
  /// **'命中率'**
  String get tokenStatsColCacheHitRate;

  /// No description provided for @tokenStatsColTtfb.
  ///
  /// In zh, this message translates to:
  /// **'首字节'**
  String get tokenStatsColTtfb;

  /// No description provided for @tokenStatsColDuration.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get tokenStatsColDuration;

  /// No description provided for @tokenStatsColTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get tokenStatsColTime;

  /// No description provided for @tokenStatsColStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get tokenStatsColStatus;

  /// No description provided for @tokenStatsColCost.
  ///
  /// In zh, this message translates to:
  /// **'费用'**
  String get tokenStatsColCost;

  /// No description provided for @tokenStatsPage.
  ///
  /// In zh, this message translates to:
  /// **'第 {page} / {total} 页'**
  String tokenStatsPage(int page, int total);

  /// No description provided for @tokenStatsRetries.
  ///
  /// In zh, this message translates to:
  /// **'重试 {count} 次'**
  String tokenStatsRetries(int count);

  /// No description provided for @tokenStatsReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get tokenStatsReset;

  /// No description provided for @tokenStatsResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置 Token 统计'**
  String get tokenStatsResetTitle;

  /// No description provided for @tokenStatsResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将清空全部调用记录,此操作不可恢复。确定重置?'**
  String get tokenStatsResetConfirm;

  /// No description provided for @tokenStatsFilterAllProviders.
  ///
  /// In zh, this message translates to:
  /// **'全部供应商'**
  String get tokenStatsFilterAllProviders;

  /// No description provided for @tokenStatsFilterAllModels.
  ///
  /// In zh, this message translates to:
  /// **'全部模型'**
  String get tokenStatsFilterAllModels;

  /// No description provided for @tokenStatsFilterClear.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get tokenStatsFilterClear;

  /// No description provided for @tokenStatsFilterProvider.
  ///
  /// In zh, this message translates to:
  /// **'供应商:{name}'**
  String tokenStatsFilterProvider(String name);

  /// No description provided for @tokenStatsFilterModel.
  ///
  /// In zh, this message translates to:
  /// **'模型:{name}'**
  String tokenStatsFilterModel(String name);

  /// No description provided for @tokenStatsProviderKeys.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个密钥'**
  String tokenStatsProviderKeys(int count);

  /// No description provided for @tokenStatsRequestsUnit.
  ///
  /// In zh, this message translates to:
  /// **'次请求'**
  String get tokenStatsRequestsUnit;

  /// No description provided for @tokenStatsHourSuffix.
  ///
  /// In zh, this message translates to:
  /// **'时'**
  String get tokenStatsHourSuffix;

  /// No description provided for @tokenStatsPrevPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get tokenStatsPrevPage;

  /// No description provided for @tokenStatsNextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get tokenStatsNextPage;

  /// No description provided for @settingsCategoryData.
  ///
  /// In zh, this message translates to:
  /// **'数据与诊断'**
  String get settingsCategoryData;

  /// No description provided for @gitActionClone.
  ///
  /// In zh, this message translates to:
  /// **'克隆'**
  String get gitActionClone;

  /// No description provided for @gitActionInit.
  ///
  /// In zh, this message translates to:
  /// **'初始化'**
  String get gitActionInit;

  /// No description provided for @gitActionMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并分支'**
  String get gitActionMerge;

  /// No description provided for @gitActionStageAll.
  ///
  /// In zh, this message translates to:
  /// **'全部暂存'**
  String get gitActionStageAll;

  /// No description provided for @gitCloneUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'https://github.com/user/repo.git'**
  String get gitCloneUrlHint;

  /// No description provided for @gitComputingDiff.
  ///
  /// In zh, this message translates to:
  /// **'正在计算差异…'**
  String get gitComputingDiff;

  /// No description provided for @gitCreateTagTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get gitCreateTagTitle;

  /// No description provided for @gitCreateTrackingBranch.
  ///
  /// In zh, this message translates to:
  /// **'从远程分支 {branch} 创建本地跟踪分支并切换?'**
  String gitCreateTrackingBranch(String branch);

  /// No description provided for @gitCredentialsAndIdentity.
  ///
  /// In zh, this message translates to:
  /// **'凭据与署名'**
  String get gitCredentialsAndIdentity;

  /// No description provided for @gitDetachedHeadWarning.
  ///
  /// In zh, this message translates to:
  /// **'切换到标签 {ref} 将进入 detached HEAD 状态——不处于任何分支上,新提交不属于任何分支。确定继续?'**
  String gitDetachedHeadWarning(String ref);

  /// No description provided for @gitMergeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将分支 {branch} 合并到当前分支({current})吗?'**
  String gitMergeConfirm(String branch, String current);

  /// No description provided for @gitMergeNoFf.
  ///
  /// In zh, this message translates to:
  /// **'创建合并提交(--no-ff)'**
  String get gitMergeNoFf;

  /// No description provided for @gitOpenInEditor.
  ///
  /// In zh, this message translates to:
  /// **'在编辑器中打开'**
  String get gitOpenInEditor;

  /// No description provided for @gitSwitchBranch.
  ///
  /// In zh, this message translates to:
  /// **'切换分支'**
  String get gitSwitchBranch;

  /// No description provided for @gitSwitchConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定切换到 {ref}?'**
  String gitSwitchConfirm(String ref);

  /// No description provided for @gitToastLoadBranchesFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载分支失败:{error}'**
  String gitToastLoadBranchesFailed(String error);

  /// No description provided for @gitToastRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'刷新失败:{error}'**
  String gitToastRefreshFailed(String error);

  /// No description provided for @gitToastActionRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'{message}(刷新失败)'**
  String gitToastActionRefreshFailed(String message);

  /// No description provided for @gitToastLoadMoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载更多失败:{error}'**
  String gitToastLoadMoreFailed(String error);

  /// No description provided for @gitToastCheckoutFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换失败:{error}'**
  String gitToastCheckoutFailed(String error);

  /// No description provided for @gitToastNotRepo.
  ///
  /// In zh, this message translates to:
  /// **'该目录不是 Git 仓库'**
  String get gitToastNotRepo;

  /// No description provided for @gitToastSwitchRepoFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换仓库失败:{error}'**
  String gitToastSwitchRepoFailed(String error);

  /// No description provided for @gitToastDiffFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载差异失败'**
  String get gitToastDiffFailed;

  /// No description provided for @gitToastNoDiffForCommit.
  ///
  /// In zh, this message translates to:
  /// **'暂存区与工作区均无差异,无法生成提交信息'**
  String get gitToastNoDiffForCommit;

  /// No description provided for @gitToastGenerateCommitFailed.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成提交信息失败,请检查模型或网络'**
  String get gitToastGenerateCommitFailed;

  /// No description provided for @diffBinaryFile.
  ///
  /// In zh, this message translates to:
  /// **'二进制文件,不支持文本差异对比'**
  String get diffBinaryFile;

  /// No description provided for @diffFileTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'文件过大,已跳过差异计算'**
  String get diffFileTooLarge;

  /// No description provided for @diffFileTooLargeDesc.
  ///
  /// In zh, this message translates to:
  /// **'超过 2000 行或含超长行的文件不做行级 diff,以避免渲染与内存压力。'**
  String get diffFileTooLargeDesc;

  /// No description provided for @diffNoChanges.
  ///
  /// In zh, this message translates to:
  /// **'无差异'**
  String get diffNoChanges;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @chatOpenGit.
  ///
  /// In zh, this message translates to:
  /// **'打开 Git'**
  String get chatOpenGit;

  /// No description provided for @switchLabel.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get switchLabel;

  /// No description provided for @credentialEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑凭据'**
  String get credentialEdit;

  /// No description provided for @credentialToastSaved.
  ///
  /// In zh, this message translates to:
  /// **'凭据已保存'**
  String get credentialToastSaved;

  /// No description provided for @credentialToastSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败:%1\$s'**
  String credentialToastSaveFailed(String param1);

  /// No description provided for @credentialToastDeleted.
  ///
  /// In zh, this message translates to:
  /// **'凭据已删除'**
  String get credentialToastDeleted;

  /// No description provided for @credentialToastIdentitySaved.
  ///
  /// In zh, this message translates to:
  /// **'署名与仓库地址已保存'**
  String get credentialToastIdentitySaved;

  /// No description provided for @credentialEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'尚未添加凭据,点右上角 + 添加'**
  String get credentialEmptyHint;

  /// No description provided for @credentialEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无 Git 凭据'**
  String get credentialEmptyTitle;

  /// No description provided for @credentialEmptyDesc.
  ///
  /// In zh, this message translates to:
  /// **'配置凭据后,Codecraft 可在推送或拉取代码仓库时自动完成身份认证'**
  String get credentialEmptyDesc;

  /// No description provided for @credentialAddManual.
  ///
  /// In zh, this message translates to:
  /// **'手动添加'**
  String get credentialAddManual;

  /// No description provided for @gitTabIdentity.
  ///
  /// In zh, this message translates to:
  /// **'署名'**
  String get gitTabIdentity;

  /// No description provided for @gitTabCredentials.
  ///
  /// In zh, this message translates to:
  /// **'凭据'**
  String get gitTabCredentials;

  /// No description provided for @gitIdentityTitle.
  ///
  /// In zh, this message translates to:
  /// **'提交署名'**
  String get gitIdentityTitle;

  /// No description provided for @gitIdentityCodespace.
  ///
  /// In zh, this message translates to:
  /// **'当前连接 GitHub Codespace {name}'**
  String gitIdentityCodespace(String name);

  /// No description provided for @gitRepoUrlTitle.
  ///
  /// In zh, this message translates to:
  /// **'仓库地址'**
  String get gitRepoUrlTitle;

  /// No description provided for @gitRemoteUrl.
  ///
  /// In zh, this message translates to:
  /// **'remote.origin.url'**
  String get gitRemoteUrl;

  /// No description provided for @gitCredentialsCount.
  ///
  /// In zh, this message translates to:
  /// **'凭据 ({param1})'**
  String gitCredentialsCount(int param1);

  /// No description provided for @codespacesTitle.
  ///
  /// In zh, this message translates to:
  /// **'GitHub Codespaces'**
  String get codespacesTitle;

  /// No description provided for @codespacesNetworkError.
  ///
  /// In zh, this message translates to:
  /// **'网络错误:{error}'**
  String codespacesNetworkError(String error);

  /// No description provided for @codespacesAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get codespacesAccount;

  /// No description provided for @codespacesCount.
  ///
  /// In zh, this message translates to:
  /// **'Codespaces ({count})'**
  String codespacesCount(int count);

  /// No description provided for @codespacesEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有 Codespace'**
  String get codespacesEmptyTitle;

  /// No description provided for @codespacesEmptyDesc.
  ///
  /// In zh, this message translates to:
  /// **'在 GitHub 上创建 Codespace 后,这里即可列出并连接'**
  String get codespacesEmptyDesc;

  /// No description provided for @codespacesCreateOnWeb.
  ///
  /// In zh, this message translates to:
  /// **'在 github.com 新建'**
  String get codespacesCreateOnWeb;

  /// No description provided for @codespacesRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get codespacesRefresh;

  /// No description provided for @codespacesOpenInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器打开'**
  String get codespacesOpenInBrowser;

  /// No description provided for @codespacesStart.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get codespacesStart;

  /// No description provided for @codespacesStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get codespacesStop;

  /// No description provided for @codespacesDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get codespacesDelete;

  /// No description provided for @codespacesDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除 {name}?该操作不可撤销'**
  String codespacesDeleteConfirm(String name);

  /// No description provided for @codespacesStateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get codespacesStateAvailable;

  /// No description provided for @codespacesStateStarting.
  ///
  /// In zh, this message translates to:
  /// **'启动中'**
  String get codespacesStateStarting;

  /// No description provided for @codespacesStateStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get codespacesStateStopped;

  /// No description provided for @codespacesStateUnknown.
  ///
  /// In zh, this message translates to:
  /// **'状态未知'**
  String get codespacesStateUnknown;

  /// No description provided for @codespacesLastUsed.
  ///
  /// In zh, this message translates to:
  /// **'最近使用 {time}'**
  String codespacesLastUsed(String time);

  /// No description provided for @codespacesNoRepo.
  ///
  /// In zh, this message translates to:
  /// **'未知仓库'**
  String get codespacesNoRepo;

  /// No description provided for @codespacesUncommitted.
  ///
  /// In zh, this message translates to:
  /// **'有未提交改动'**
  String get codespacesUncommitted;

  /// No description provided for @codespacesMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get codespacesMoreActions;

  /// No description provided for @editorLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取该文件'**
  String get editorLoadFailed;

  /// No description provided for @editorSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get editorSaveFailed;

  /// No description provided for @editorSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get editorSaved;

  /// No description provided for @editorCharacters.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get editorCharacters;

  /// No description provided for @characterTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色管理'**
  String get characterTitle;

  /// No description provided for @characterNew.
  ///
  /// In zh, this message translates to:
  /// **'新建角色'**
  String get characterNew;

  /// No description provided for @characterEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑角色'**
  String get characterEdit;

  /// No description provided for @characterEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色'**
  String get characterEmpty;

  /// No description provided for @characterSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索角色名称、别名或标签'**
  String get characterSearchHint;

  /// No description provided for @characterSearchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配角色'**
  String get characterSearchEmpty;

  /// No description provided for @characterFieldBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get characterFieldBasic;

  /// No description provided for @characterFieldName.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get characterFieldName;

  /// No description provided for @characterFieldNameHint.
  ///
  /// In zh, this message translates to:
  /// **'角色的真实姓名'**
  String get characterFieldNameHint;

  /// No description provided for @characterFieldAlias.
  ///
  /// In zh, this message translates to:
  /// **'别名/称呼'**
  String get characterFieldAlias;

  /// No description provided for @characterFieldAliasHint.
  ///
  /// In zh, this message translates to:
  /// **'故事中常用的称呼(如:老张、小李)'**
  String get characterFieldAliasHint;

  /// No description provided for @characterFieldGender.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get characterFieldGender;

  /// No description provided for @characterFieldGenderHint.
  ///
  /// In zh, this message translates to:
  /// **'男/女/其他'**
  String get characterFieldGenderHint;

  /// No description provided for @characterFieldAge.
  ///
  /// In zh, this message translates to:
  /// **'年龄'**
  String get characterFieldAge;

  /// No description provided for @characterFieldAgeHint.
  ///
  /// In zh, this message translates to:
  /// **'数字,如 25'**
  String get characterFieldAgeHint;

  /// No description provided for @characterFieldBirthday.
  ///
  /// In zh, this message translates to:
  /// **'生日'**
  String get characterFieldBirthday;

  /// No description provided for @characterFieldBirthdayHint.
  ///
  /// In zh, this message translates to:
  /// **'格式:MM-DD,如 01-15'**
  String get characterFieldBirthdayHint;

  /// No description provided for @characterFieldAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外貌描写'**
  String get characterFieldAppearance;

  /// No description provided for @characterFieldAppearanceHint.
  ///
  /// In zh, this message translates to:
  /// **'身高、体型、发色、瞳色、特征等'**
  String get characterFieldAppearanceHint;

  /// No description provided for @characterFieldPersonality.
  ///
  /// In zh, this message translates to:
  /// **'性格'**
  String get characterFieldPersonality;

  /// No description provided for @characterFieldPersonalityHint.
  ///
  /// In zh, this message translates to:
  /// **'性格特点、行为模式、说话风格等'**
  String get characterFieldPersonalityHint;

  /// No description provided for @characterFieldBackground.
  ///
  /// In zh, this message translates to:
  /// **'背景故事'**
  String get characterFieldBackground;

  /// No description provided for @characterFieldBackgroundHint.
  ///
  /// In zh, this message translates to:
  /// **'成长经历、重要事件、家庭背景等'**
  String get characterFieldBackgroundHint;

  /// No description provided for @characterFieldGoals.
  ///
  /// In zh, this message translates to:
  /// **'目标/愿望'**
  String get characterFieldGoals;

  /// No description provided for @characterFieldGoalsHint.
  ///
  /// In zh, this message translates to:
  /// **'角色想要达成的事、追求的东西'**
  String get characterFieldGoalsHint;

  /// No description provided for @characterFieldFears.
  ///
  /// In zh, this message translates to:
  /// **'恐惧/弱点'**
  String get characterFieldFears;

  /// No description provided for @characterFieldFearsHint.
  ///
  /// In zh, this message translates to:
  /// **'害怕的事、心理阴影、致命弱点等'**
  String get characterFieldFearsHint;

  /// No description provided for @characterFieldTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get characterFieldTags;

  /// No description provided for @characterFieldTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'用逗号分隔,如:主角、反派、魔法师'**
  String get characterFieldTagsHint;

  /// No description provided for @characterScope.
  ///
  /// In zh, this message translates to:
  /// **'作用域'**
  String get characterScope;

  /// No description provided for @characterScopeProject.
  ///
  /// In zh, this message translates to:
  /// **'当前项目'**
  String get characterScopeProject;

  /// No description provided for @characterScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get characterScopeGlobal;

  /// No description provided for @characterSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String characterSelectedCount(int count);

  /// No description provided for @editorUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get editorUndo;

  /// No description provided for @editorRedo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get editorRedo;

  /// No description provided for @editorSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get editorSearch;

  /// No description provided for @editorSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'查找内容'**
  String get editorSearchHint;

  /// No description provided for @editorSearchPrev.
  ///
  /// In zh, this message translates to:
  /// **'上一个'**
  String get editorSearchPrev;

  /// No description provided for @editorSearchNext.
  ///
  /// In zh, this message translates to:
  /// **'下一个'**
  String get editorSearchNext;

  /// No description provided for @editorTypeset.
  ///
  /// In zh, this message translates to:
  /// **'自动排版'**
  String get editorTypeset;

  /// No description provided for @editorTypesetDone.
  ///
  /// In zh, this message translates to:
  /// **'已排版,可撤销'**
  String get editorTypesetDone;

  /// No description provided for @editorCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get editorCopy;

  /// No description provided for @editorCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get editorCopied;

  /// No description provided for @editorUnsavedState.
  ///
  /// In zh, this message translates to:
  /// **'未保存'**
  String get editorUnsavedState;

  /// No description provided for @editorWordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 字'**
  String editorWordCount(int count);

  /// No description provided for @editorNoFile.
  ///
  /// In zh, this message translates to:
  /// **'还没有打开的文件,从差异页点「在编辑器中打开」即可'**
  String get editorNoFile;

  /// No description provided for @editorUnsavedTitle.
  ///
  /// In zh, this message translates to:
  /// **'未保存的修改'**
  String get editorUnsavedTitle;

  /// No description provided for @editorUnsavedMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前文件有未保存的修改,是否保存?'**
  String get editorUnsavedMessage;

  /// No description provided for @editorSaveAndExit.
  ///
  /// In zh, this message translates to:
  /// **'保存并退出'**
  String get editorSaveAndExit;

  /// No description provided for @editorSaveAndSwitch.
  ///
  /// In zh, this message translates to:
  /// **'保存并切换'**
  String get editorSaveAndSwitch;

  /// No description provided for @editorDontSave.
  ///
  /// In zh, this message translates to:
  /// **'不保存'**
  String get editorDontSave;

  /// No description provided for @editorMdPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览 Markdown'**
  String get editorMdPreview;

  /// No description provided for @editorMdShowSource.
  ///
  /// In zh, this message translates to:
  /// **'显示源码'**
  String get editorMdShowSource;

  /// No description provided for @editorIndent.
  ///
  /// In zh, this message translates to:
  /// **'缩进'**
  String get editorIndent;

  /// No description provided for @editorCursorLeft.
  ///
  /// In zh, this message translates to:
  /// **'光标左移'**
  String get editorCursorLeft;

  /// No description provided for @editorCursorRight.
  ///
  /// In zh, this message translates to:
  /// **'光标右移'**
  String get editorCursorRight;

  /// No description provided for @editorSettings.
  ///
  /// In zh, this message translates to:
  /// **'编辑器设置'**
  String get editorSettings;

  /// No description provided for @editorFontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get editorFontSize;

  /// No description provided for @editorFontSizeValue.
  ///
  /// In zh, this message translates to:
  /// **'{size} sp'**
  String editorFontSizeValue(int size);

  /// No description provided for @editorWordWrap.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get editorWordWrap;

  /// No description provided for @editorShowIndentGuide.
  ///
  /// In zh, this message translates to:
  /// **'显示缩进参考线'**
  String get editorShowIndentGuide;

  /// No description provided for @editorShowWhitespace.
  ///
  /// In zh, this message translates to:
  /// **'显示空白符号'**
  String get editorShowWhitespace;

  /// No description provided for @editorFileTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'文件过大({mb} MB),暂不支持打开'**
  String editorFileTooLarge(int mb);

  /// No description provided for @editorBinaryUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'二进制文件,暂不支持打开'**
  String get editorBinaryUnsupported;

  /// No description provided for @editorSaveConflictTitle.
  ///
  /// In zh, this message translates to:
  /// **'文件已被修改'**
  String get editorSaveConflictTitle;

  /// No description provided for @editorSaveConflictMessage.
  ///
  /// In zh, this message translates to:
  /// **'该文件在你打开之后已被 AI 或其他程序修改。直接保存会覆盖对方的改动。'**
  String get editorSaveConflictMessage;

  /// No description provided for @editorSaveConflictDiff.
  ///
  /// In zh, this message translates to:
  /// **'- 磁盘当前内容\n+ 你的编辑\n\n{diff}'**
  String editorSaveConflictDiff(String diff);

  /// No description provided for @editorSaveConflictOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖磁盘'**
  String get editorSaveConflictOverwrite;

  /// No description provided for @editorSaveConflictDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃我的修改'**
  String get editorSaveConflictDiscard;

  /// No description provided for @editorSaveConflictCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get editorSaveConflictCancel;

  /// No description provided for @editorSaveConflictDiscarded.
  ///
  /// In zh, this message translates to:
  /// **'已放弃修改并重新载入磁盘内容'**
  String get editorSaveConflictDiscarded;

  /// No description provided for @editorLineColumn.
  ///
  /// In zh, this message translates to:
  /// **'{line}:{column}'**
  String editorLineColumn(int line, int column);

  /// No description provided for @codespacesConnect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get codespacesConnect;

  /// No description provided for @codespacesDisconnect.
  ///
  /// In zh, this message translates to:
  /// **'断开'**
  String get codespacesDisconnect;

  /// No description provided for @codespacesGhMissing.
  ///
  /// In zh, this message translates to:
  /// **'容器里还没有 gh(GitHub CLI)。请先在终端执行命令 codecraft,选择「GitHub Codespaces」场景安装依赖。'**
  String get codespacesGhMissing;

  /// No description provided for @codespacesExecutionEnv.
  ///
  /// In zh, this message translates to:
  /// **'执行环境'**
  String get codespacesExecutionEnv;

  /// No description provided for @codespacesEnvLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地容器'**
  String get codespacesEnvLocal;

  /// No description provided for @codespacesEnvCodespace.
  ///
  /// In zh, this message translates to:
  /// **'远程 Codespace'**
  String get codespacesEnvCodespace;

  /// No description provided for @terminalRemoteEnv.
  ///
  /// In zh, this message translates to:
  /// **'远程环境:{name}'**
  String terminalRemoteEnv(String name);

  /// No description provided for @codespacesNew.
  ///
  /// In zh, this message translates to:
  /// **'新建 Codespace'**
  String get codespacesNew;

  /// No description provided for @codespacesRepoTab.
  ///
  /// In zh, this message translates to:
  /// **'仓库'**
  String get codespacesRepoTab;

  /// No description provided for @codespacesRepoSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索仓库'**
  String get codespacesRepoSearchHint;

  /// No description provided for @codespacesBranch.
  ///
  /// In zh, this message translates to:
  /// **'分支(留空用默认分支)'**
  String get codespacesBranch;

  /// No description provided for @codespacesMachine.
  ///
  /// In zh, this message translates to:
  /// **'机器规格'**
  String get codespacesMachine;

  /// No description provided for @codespacesMachineDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认规格'**
  String get codespacesMachineDefault;

  /// No description provided for @codespacesCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get codespacesCreate;

  /// No description provided for @codespacesRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get codespacesRename;

  /// No description provided for @codespacesRenameTitle.
  ///
  /// In zh, this message translates to:
  /// **'Codespace 显示名'**
  String get codespacesRenameTitle;

  /// No description provided for @codespacesChangeMachine.
  ///
  /// In zh, this message translates to:
  /// **'更改机型'**
  String get codespacesChangeMachine;

  /// No description provided for @codespacesNoMachines.
  ///
  /// In zh, this message translates to:
  /// **'该仓库没有可选机型'**
  String get codespacesNoMachines;

  /// No description provided for @codespacesLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get codespacesLoadFailed;

  /// No description provided for @codespacesPorts.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get codespacesPorts;

  /// No description provided for @codespacesPortsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'该 Codespace 还没有转发的端口'**
  String get codespacesPortsEmpty;

  /// No description provided for @codespacesPortVisibility.
  ///
  /// In zh, this message translates to:
  /// **'可见性'**
  String get codespacesPortVisibility;

  /// No description provided for @codespacesPortPrivate.
  ///
  /// In zh, this message translates to:
  /// **'仅自己'**
  String get codespacesPortPrivate;

  /// No description provided for @codespacesPortOrg.
  ///
  /// In zh, this message translates to:
  /// **'组织内'**
  String get codespacesPortOrg;

  /// No description provided for @codespacesPortPublic.
  ///
  /// In zh, this message translates to:
  /// **'公开'**
  String get codespacesPortPublic;

  /// No description provided for @codespacesPortOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get codespacesPortOpen;

  /// No description provided for @codespacesRebuild.
  ///
  /// In zh, this message translates to:
  /// **'重建容器'**
  String get codespacesRebuild;

  /// No description provided for @codespacesRebuildDesc.
  ///
  /// In zh, this message translates to:
  /// **'重建会按当前 devcontainer 重新创建容器:代码与未提交改动保留,容器内已安装的工具与运行状态会丢失。'**
  String get codespacesRebuildDesc;

  /// No description provided for @codespacesRebuildFull.
  ///
  /// In zh, this message translates to:
  /// **'完全重建(同时清除缓存的 Docker 镜像,更慢)'**
  String get codespacesRebuildFull;

  /// No description provided for @settingsLog.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get settingsLog;

  /// No description provided for @settingsLogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'应用运行日志与 AI 请求日志'**
  String get settingsLogSubtitle;

  /// No description provided for @logFiles.
  ///
  /// In zh, this message translates to:
  /// **'日志文件'**
  String get logFiles;

  /// No description provided for @logNoFiles.
  ///
  /// In zh, this message translates to:
  /// **'还没有日志文件'**
  String get logNoFiles;

  /// No description provided for @logReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取日志失败:{error}'**
  String logReadFailed(String error);

  /// No description provided for @logSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索日志'**
  String get logSearchHint;

  /// No description provided for @logNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件下没有日志'**
  String get logNoMatch;

  /// No description provided for @logLevel.
  ///
  /// In zh, this message translates to:
  /// **'日志等级'**
  String get logLevel;

  /// No description provided for @logLevelDesc.
  ///
  /// In zh, this message translates to:
  /// **'记录低于该等级的日志将被忽略。开发期建议 VERBOSE(全部记录);NONE 关闭日志。'**
  String get logLevelDesc;

  /// No description provided for @logCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get logCopied;

  /// No description provided for @logMcpPrefix.
  ///
  /// In zh, this message translates to:
  /// **'MCP 日志:{server}'**
  String logMcpPrefix(String server);

  /// No description provided for @logSearchResults.
  ///
  /// In zh, this message translates to:
  /// **'匹配 {count} 行'**
  String logSearchResults(int count);

  /// No description provided for @logShowLastLines.
  ///
  /// In zh, this message translates to:
  /// **'显示最后 {shown}/{total} 行'**
  String logShowLastLines(int shown, int total);

  /// No description provided for @logShowLines.
  ///
  /// In zh, this message translates to:
  /// **'显示 {count} 行'**
  String logShowLines(int count);

  /// No description provided for @logCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get logCopy;

  /// No description provided for @logClearFilter.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get logClearFilter;

  /// No description provided for @logCopyMenuTitle.
  ///
  /// In zh, this message translates to:
  /// **'复制日志'**
  String get logCopyMenuTitle;

  /// No description provided for @logCopyLine.
  ///
  /// In zh, this message translates to:
  /// **'复制本条日志'**
  String get logCopyLine;

  /// No description provided for @logCopyWithStack.
  ///
  /// In zh, this message translates to:
  /// **'复制本条及堆栈'**
  String get logCopyWithStack;

  /// No description provided for @logCopyMessage.
  ///
  /// In zh, this message translates to:
  /// **'复制消息内容'**
  String get logCopyMessage;

  /// No description provided for @logFollowLatest.
  ///
  /// In zh, this message translates to:
  /// **'实时滚动'**
  String get logFollowLatest;

  /// No description provided for @logFileLocation.
  ///
  /// In zh, this message translates to:
  /// **'日志文件位于 Android/data/<包名>/files/logs/。'**
  String get logFileLocation;

  /// No description provided for @logLevelVerbose.
  ///
  /// In zh, this message translates to:
  /// **'详细'**
  String get logLevelVerbose;

  /// No description provided for @logLevelDebug.
  ///
  /// In zh, this message translates to:
  /// **'调试'**
  String get logLevelDebug;

  /// No description provided for @logLevelInfo.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get logLevelInfo;

  /// No description provided for @logLevelWarn.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get logLevelWarn;

  /// No description provided for @logLevelError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get logLevelError;

  /// No description provided for @logLevelNone.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get logLevelNone;

  /// No description provided for @credentialTokenHint.
  ///
  /// In zh, this message translates to:
  /// **'建议用带 codespace 作用域的 GitHub 令牌,填一次同时供 Git 推送与 Codespaces 登录使用'**
  String get credentialTokenHint;

  /// No description provided for @credentialHostOptional.
  ///
  /// In zh, this message translates to:
  /// **'主机(可选)'**
  String get credentialHostOptional;

  /// No description provided for @credentialHostAny.
  ///
  /// In zh, this message translates to:
  /// **'留空 = 所有主机'**
  String get credentialHostAny;

  /// No description provided for @credentialHostHint.
  ///
  /// In zh, this message translates to:
  /// **'只在需要给特定主机单独配令牌时才填,例如 gitlab.com'**
  String get credentialHostHint;

  /// No description provided for @codespacesNeedCredentialTitle.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置 GitHub 凭据'**
  String get codespacesNeedCredentialTitle;

  /// No description provided for @codespacesNeedCredentialDesc.
  ///
  /// In zh, this message translates to:
  /// **'Codespaces 使用「Git 凭据」里的令牌(需含 codespace 作用域),不再单独填写。'**
  String get codespacesNeedCredentialDesc;

  /// No description provided for @codespacesGoToCredentials.
  ///
  /// In zh, this message translates to:
  /// **'去填写 Git 凭据'**
  String get codespacesGoToCredentials;

  /// No description provided for @credentialAllHosts.
  ///
  /// In zh, this message translates to:
  /// **'所有主机'**
  String get credentialAllHosts;

  /// No description provided for @credentialUsernameAuto.
  ///
  /// In zh, this message translates to:
  /// **'用户名自动推导'**
  String get credentialUsernameAuto;

  /// No description provided for @chatMentionSkill.
  ///
  /// In zh, this message translates to:
  /// **'@ 技能'**
  String get chatMentionSkill;

  /// No description provided for @chatMentionSkillEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有可用的技能,先在设置里导入或新建一个。'**
  String get chatMentionSkillEmpty;

  /// No description provided for @chatMentionSkillManage.
  ///
  /// In zh, this message translates to:
  /// **'管理技能'**
  String get chatMentionSkillManage;

  /// No description provided for @chatPickFile.
  ///
  /// In zh, this message translates to:
  /// **'# 文件'**
  String get chatPickFile;

  /// No description provided for @chatPickFileParent.
  ///
  /// In zh, this message translates to:
  /// **'上一级'**
  String get chatPickFileParent;

  /// No description provided for @chatPickFileEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这个目录是空的'**
  String get chatPickFileEmpty;

  /// No description provided for @mentionHintSkill.
  ///
  /// In zh, this message translates to:
  /// **'继续输入可筛选技能'**
  String get mentionHintSkill;

  /// No description provided for @mentionHintFile.
  ///
  /// In zh, this message translates to:
  /// **'继续输入可筛选文件'**
  String get mentionHintFile;

  /// No description provided for @fileBrowserError.
  ///
  /// In zh, this message translates to:
  /// **'读取目录失败'**
  String get fileBrowserError;

  /// No description provided for @fileBrowserRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get fileBrowserRefresh;

  /// No description provided for @fileBrowserExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get fileBrowserExpand;

  /// No description provided for @fileBrowserCollapse.
  ///
  /// In zh, this message translates to:
  /// **'折叠'**
  String get fileBrowserCollapse;

  /// No description provided for @fileBrowserNewFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get fileBrowserNewFile;

  /// No description provided for @fileBrowserNewFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get fileBrowserNewFolder;

  /// No description provided for @fileBrowserNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get fileBrowserNameLabel;

  /// No description provided for @fileBrowserDeleteFileConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除文件「{name}」?'**
  String fileBrowserDeleteFileConfirm(String name);

  /// No description provided for @fileBrowserDeleteFolderConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除文件夹「{name}」及其全部内容?'**
  String fileBrowserDeleteFolderConfirm(String name);

  /// No description provided for @fileBrowserCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败,可能已存在同名项或无写入权限'**
  String get fileBrowserCreateFailed;

  /// No description provided for @fileBrowserRenameFailed.
  ///
  /// In zh, this message translates to:
  /// **'重命名失败,可能已存在同名项'**
  String get fileBrowserRenameFailed;

  /// No description provided for @fileBrowserDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败'**
  String get fileBrowserDeleteFailed;

  /// No description provided for @fileBrowserPasteHere.
  ///
  /// In zh, this message translates to:
  /// **'粘贴到此处'**
  String get fileBrowserPasteHere;

  /// No description provided for @fileBrowserExtract.
  ///
  /// In zh, this message translates to:
  /// **'解压'**
  String get fileBrowserExtract;

  /// No description provided for @fileBrowserExtractFailed.
  ///
  /// In zh, this message translates to:
  /// **'解压失败'**
  String get fileBrowserExtractFailed;

  /// No description provided for @fileBrowserExtractConflictTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标文件夹已存在'**
  String get fileBrowserExtractConflictTitle;

  /// No description provided for @fileBrowserExtractConflict.
  ///
  /// In zh, this message translates to:
  /// **'同目录下已有「{name}」,解压会先覆盖它的内容。'**
  String fileBrowserExtractConflict(String name);

  /// No description provided for @fileBrowserExtractOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖并解压'**
  String get fileBrowserExtractOverwrite;

  /// No description provided for @fileBrowserPasteConflictTitle.
  ///
  /// In zh, this message translates to:
  /// **'同名文件已存在'**
  String get fileBrowserPasteConflictTitle;

  /// No description provided for @fileBrowserPasteConflictMessage.
  ///
  /// In zh, this message translates to:
  /// **'目标位置已存在同名项目「{name}」,是否覆盖?'**
  String fileBrowserPasteConflictMessage(String name);

  /// No description provided for @fileBrowserClipboardCut.
  ///
  /// In zh, this message translates to:
  /// **'已剪切'**
  String get fileBrowserClipboardCut;

  /// No description provided for @fileBrowserClipboardCopy.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get fileBrowserClipboardCopy;

  /// No description provided for @commonCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commonCopy;

  /// No description provided for @commonCut.
  ///
  /// In zh, this message translates to:
  /// **'剪切'**
  String get commonCut;

  /// No description provided for @commonPaste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴'**
  String get commonPaste;

  /// No description provided for @workspacePickWritingFolder.
  ///
  /// In zh, this message translates to:
  /// **'写作目录'**
  String get workspacePickWritingFolder;

  /// No description provided for @writingFolderNeedAccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要存储访问权限'**
  String get writingFolderNeedAccessTitle;

  /// No description provided for @writingFolderNeedAccessDesc.
  ///
  /// In zh, this message translates to:
  /// **'读取手机里的「AI写作」目录需要「所有文件访问权限」。也可以跳过,直接在下一步选择目录。'**
  String get writingFolderNeedAccessDesc;

  /// No description provided for @writingFolderGrant.
  ///
  /// In zh, this message translates to:
  /// **'去授权'**
  String get writingFolderGrant;

  /// No description provided for @writingFolderSet.
  ///
  /// In zh, this message translates to:
  /// **'写作目录已设为 {path}'**
  String writingFolderSet(String path);

  /// No description provided for @modelAuto.
  ///
  /// In zh, this message translates to:
  /// **'Auto Model'**
  String get modelAuto;

  /// No description provided for @modelAutoDesc.
  ///
  /// In zh, this message translates to:
  /// **'按任务自动选择最合适的模型'**
  String get modelAutoDesc;

  /// No description provided for @sessionExport.
  ///
  /// In zh, this message translates to:
  /// **'导出会话'**
  String get sessionExport;

  /// No description provided for @sessionExportDone.
  ///
  /// In zh, this message translates to:
  /// **'已导出到 {path}'**
  String sessionExportDone(String path);

  /// No description provided for @sessionExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败'**
  String get sessionExportFailed;

  /// No description provided for @sessionBatchSelect.
  ///
  /// In zh, this message translates to:
  /// **'批量选择'**
  String get sessionBatchSelect;

  /// No description provided for @sessionSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String sessionSelectedCount(String count);

  /// No description provided for @sessionSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get sessionSelectAll;

  /// No description provided for @sessionCancelSelect.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get sessionCancelSelect;

  /// No description provided for @sessionDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选'**
  String get sessionDeleteSelected;

  /// No description provided for @sessionDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除该会话及其全部消息?'**
  String get sessionDeleteConfirm;

  /// No description provided for @fileBrowserNeedPermission.
  ///
  /// In zh, this message translates to:
  /// **'无法读取该文件夹,可能需要存储访问权限'**
  String get fileBrowserNeedPermission;

  /// No description provided for @checkpointRewindTitle.
  ///
  /// In zh, this message translates to:
  /// **'回退到此处'**
  String get checkpointRewindTitle;

  /// No description provided for @checkpointTargetPrompt.
  ///
  /// In zh, this message translates to:
  /// **'目标:{snippet}'**
  String checkpointTargetPrompt(String snippet);

  /// No description provided for @checkpointRestoreCodeAndConversation.
  ///
  /// In zh, this message translates to:
  /// **'还原代码与会话'**
  String get checkpointRestoreCodeAndConversation;

  /// No description provided for @checkpointRestoreCodeAndConversationDesc.
  ///
  /// In zh, this message translates to:
  /// **'回滚工作区文件,并删除这之后的所有消息,提问会回填到输入框'**
  String get checkpointRestoreCodeAndConversationDesc;

  /// No description provided for @checkpointRestoreConversation.
  ///
  /// In zh, this message translates to:
  /// **'只还原会话'**
  String get checkpointRestoreConversation;

  /// No description provided for @checkpointRestoreConversationDesc.
  ///
  /// In zh, this message translates to:
  /// **'删除这之后的所有消息,工作区文件保持不变'**
  String get checkpointRestoreConversationDesc;

  /// No description provided for @checkpointRestoreCode.
  ///
  /// In zh, this message translates to:
  /// **'只还原代码'**
  String get checkpointRestoreCode;

  /// No description provided for @checkpointRestoreCodeDesc.
  ///
  /// In zh, this message translates to:
  /// **'回滚工作区文件,对话记录保持不变'**
  String get checkpointRestoreCodeDesc;

  /// No description provided for @checkpointRewindSkipped.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件因存在其他改动已跳过'**
  String checkpointRewindSkipped(int count);

  /// No description provided for @chatMoreOptions.
  ///
  /// In zh, this message translates to:
  /// **'更多选项'**
  String get chatMoreOptions;

  /// No description provided for @chatActionEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get chatActionEdit;

  /// No description provided for @chatActionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get chatActionDelete;

  /// No description provided for @chatEditMessageTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑消息'**
  String get chatEditMessageTitle;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonBatchDelete.
  ///
  /// In zh, this message translates to:
  /// **'批量删除'**
  String get commonBatchDelete;

  /// No description provided for @tabProjects.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get tabProjects;

  /// No description provided for @projectListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有项目'**
  String get projectListEmpty;

  /// No description provided for @workspaceCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get workspaceCurrent;

  /// No description provided for @workspaceNameHint.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get workspaceNameHint;

  /// No description provided for @projectNew.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get projectNew;

  /// No description provided for @projectUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名项目'**
  String get projectUntitled;

  /// No description provided for @projectKindCoding.
  ///
  /// In zh, this message translates to:
  /// **'编程'**
  String get projectKindCoding;

  /// No description provided for @projectKindCodingDesc.
  ///
  /// In zh, this message translates to:
  /// **'在沙盒工作区里写代码、跑命令、改文件'**
  String get projectKindCodingDesc;

  /// No description provided for @projectKindWriting.
  ///
  /// In zh, this message translates to:
  /// **'写作'**
  String get projectKindWriting;

  /// No description provided for @projectKindWritingDesc.
  ///
  /// In zh, this message translates to:
  /// **'在「AI写作」目录里撰写与修改文稿'**
  String get projectKindWritingDesc;

  /// No description provided for @projectKindReverse.
  ///
  /// In zh, this message translates to:
  /// **'应用逆向'**
  String get projectKindReverse;

  /// No description provided for @projectKindReverseDesc.
  ///
  /// In zh, this message translates to:
  /// **'分析 APK、抓包接口、静态逆向与调试辅助'**
  String get projectKindReverseDesc;

  /// No description provided for @projectDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除项目「{name}」?其下所有会话都会一并删除。'**
  String projectDeleteConfirm(String name);

  /// No description provided for @installedAppsTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择应用'**
  String get installedAppsTitle;

  /// No description provided for @installedAppsSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索应用名或包名'**
  String get installedAppsSearch;

  /// No description provided for @installedAppsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的应用'**
  String get installedAppsEmpty;

  /// No description provided for @storagePermissionGrant.
  ///
  /// In zh, this message translates to:
  /// **'去授权'**
  String get storagePermissionGrant;

  /// No description provided for @softwarePermissionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'软件权限'**
  String get softwarePermissionsTitle;

  /// No description provided for @softwarePermissionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点任一项由系统弹出授权,或跳到对应的系统设置页。'**
  String get softwarePermissionsSubtitle;

  /// No description provided for @systemPermissionsGroup.
  ///
  /// In zh, this message translates to:
  /// **'系统权限'**
  String get systemPermissionsGroup;

  /// No description provided for @permissionStorageTitle.
  ///
  /// In zh, this message translates to:
  /// **'访问存储空间'**
  String get permissionStorageTitle;

  /// No description provided for @permissionBatteryTitle.
  ///
  /// In zh, this message translates to:
  /// **'忽略电池优化'**
  String get permissionBatteryTitle;

  /// No description provided for @permissionBatteryDesc.
  ///
  /// In zh, this message translates to:
  /// **'允许后台持续运行,减少被杀'**
  String get permissionBatteryDesc;

  /// No description provided for @permissionAutoStartTitle.
  ///
  /// In zh, this message translates to:
  /// **'自启动管理'**
  String get permissionAutoStartTitle;

  /// No description provided for @permissionAutoStartDesc.
  ///
  /// In zh, this message translates to:
  /// **'允许系统在后台自动拉起应用'**
  String get permissionAutoStartDesc;

  /// No description provided for @permissionShizukuTitle.
  ///
  /// In zh, this message translates to:
  /// **'Shizuku'**
  String get permissionShizukuTitle;

  /// No description provided for @permissionShizukuDesc.
  ///
  /// In zh, this message translates to:
  /// **'点击前往下载安装 Shizuku'**
  String get permissionShizukuDesc;

  /// No description provided for @permissionAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get permissionAllowed;

  /// No description provided for @permissionNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'未允许'**
  String get permissionNotAllowed;

  /// No description provided for @permissionInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get permissionInstalled;

  /// No description provided for @permissionNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get permissionNotInstalled;

  /// No description provided for @permissionAppsTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用列表'**
  String get permissionAppsTitle;

  /// No description provided for @permissionAppsDesc.
  ///
  /// In zh, this message translates to:
  /// **'读取已安装应用的名称、包名与版本'**
  String get permissionAppsDesc;

  /// No description provided for @apkPathUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'拿不到这个应用的安装包路径,换一个应用再试。'**
  String get apkPathUnavailable;

  /// No description provided for @apkExtractHint.
  ///
  /// In zh, this message translates to:
  /// **'这个项目显示所选 APK 里的文件。首次浏览需要先解压一次。'**
  String get apkExtractHint;

  /// No description provided for @apkExtractAction.
  ///
  /// In zh, this message translates to:
  /// **'解压 APK'**
  String get apkExtractAction;

  /// No description provided for @apkExtracting.
  ///
  /// In zh, this message translates to:
  /// **'正在解压…'**
  String get apkExtracting;

  /// No description provided for @apkExtractFailed.
  ///
  /// In zh, this message translates to:
  /// **'解压失败,可能没有读取该安装包的权限。'**
  String get apkExtractFailed;

  /// No description provided for @terminalAgentTab.
  ///
  /// In zh, this message translates to:
  /// **'AI 命令'**
  String get terminalAgentTab;

  /// No description provided for @runModeAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动模式'**
  String get runModeAuto;

  /// No description provided for @runModeBuild.
  ///
  /// In zh, this message translates to:
  /// **'构建模式'**
  String get runModeBuild;

  /// No description provided for @runModePlan.
  ///
  /// In zh, this message translates to:
  /// **'计划模式'**
  String get runModePlan;

  /// No description provided for @runModePlanIntercept.
  ///
  /// In zh, this message translates to:
  /// **'当前处于计划模式,禁止执行写操作'**
  String get runModePlanIntercept;

  /// No description provided for @runModeBuildAuthorize.
  ///
  /// In zh, this message translates to:
  /// **'AI 尝试执行写操作,是否允许?'**
  String get runModeBuildAuthorize;

  /// No description provided for @runModeBuildAllow.
  ///
  /// In zh, this message translates to:
  /// **'允许'**
  String get runModeBuildAllow;

  /// No description provided for @runModeBuildDeny.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get runModeBuildDeny;

  /// No description provided for @runModeSwitchChanged.
  ///
  /// In zh, this message translates to:
  /// **'运行模式已切换至 {mode}'**
  String runModeSwitchChanged(Object mode);

  /// No description provided for @commonScrollToBottom.
  ///
  /// In zh, this message translates to:
  /// **'回到底部'**
  String get commonScrollToBottom;

  /// No description provided for @subagentTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get subagentTitle;

  /// No description provided for @subagentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'模型档位与自定义定义'**
  String get subagentSubtitle;

  /// No description provided for @subagentTierSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'为每个档位绑定提供商与模型。未配置的档位:子代理定义写死模型时用定义模型,否则继承当前会话模型'**
  String get subagentTierSubtitle;

  /// No description provided for @subagentTierSection.
  ///
  /// In zh, this message translates to:
  /// **'模型档位'**
  String get subagentTierSection;

  /// No description provided for @subagentTierLight.
  ///
  /// In zh, this message translates to:
  /// **'轻量'**
  String get subagentTierLight;

  /// No description provided for @subagentTierStandard.
  ///
  /// In zh, this message translates to:
  /// **'均衡'**
  String get subagentTierStandard;

  /// No description provided for @subagentTierStrong.
  ///
  /// In zh, this message translates to:
  /// **'强力'**
  String get subagentTierStrong;

  /// No description provided for @subagentTierLightDesc.
  ///
  /// In zh, this message translates to:
  /// **'只读探索、批量定位、机械改名'**
  String get subagentTierLightDesc;

  /// No description provided for @subagentTierStandardDesc.
  ///
  /// In zh, this message translates to:
  /// **'单文件修改与常规修复'**
  String get subagentTierStandardDesc;

  /// No description provided for @subagentTierStrongDesc.
  ///
  /// In zh, this message translates to:
  /// **'跨模块重构、疑难排查与方案设计'**
  String get subagentTierStrongDesc;

  /// No description provided for @subagentTierUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置(继承当前会话模型)'**
  String get subagentTierUnset;

  /// No description provided for @subagentTierPick.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get subagentTierPick;

  /// No description provided for @subagentTierClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get subagentTierClear;

  /// No description provided for @subagentTierCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清除'**
  String get subagentTierCleared;

  /// No description provided for @subagentTierSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get subagentTierSaved;

  /// No description provided for @subagentTierSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'{tier} 档模型'**
  String subagentTierSheetTitle(String tier);

  /// No description provided for @subagentTierSheetHint.
  ///
  /// In zh, this message translates to:
  /// **'选择该档位使用的提供商与模型'**
  String get subagentTierSheetHint;

  /// No description provided for @subagentTierSheetInherit.
  ///
  /// In zh, this message translates to:
  /// **'继承当前会话模型'**
  String get subagentTierSheetInherit;

  /// No description provided for @subagentNoticeTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get subagentNoticeTitle;

  /// No description provided for @subagentStateRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get subagentStateRunning;

  /// No description provided for @subagentStateCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get subagentStateCompleted;

  /// No description provided for @subagentStateFailed.
  ///
  /// In zh, this message translates to:
  /// **'执行失败'**
  String get subagentStateFailed;

  /// No description provided for @subagentStateMessage.
  ///
  /// In zh, this message translates to:
  /// **'来消息'**
  String get subagentStateMessage;

  /// No description provided for @subagentViewOutput.
  ///
  /// In zh, this message translates to:
  /// **'查看输出'**
  String get subagentViewOutput;

  /// No description provided for @subagentOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get subagentOpen;

  /// No description provided for @subagentOutputEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无输出'**
  String get subagentOutputEmpty;

  /// No description provided for @subagentOutputTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理输出'**
  String get subagentOutputTitle;

  /// No description provided for @promptsTitle.
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get promptsTitle;

  /// No description provided for @promptsScenarioSection.
  ///
  /// In zh, this message translates to:
  /// **'场景提示词'**
  String get promptsScenarioSection;

  /// No description provided for @promptsSortLongPress.
  ///
  /// In zh, this message translates to:
  /// **'长按可调整顺序'**
  String get promptsSortLongPress;

  /// No description provided for @promptsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用片段'**
  String get promptsEmpty;

  /// No description provided for @promptsSourceProject.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get promptsSourceProject;

  /// No description provided for @promptsSourceGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get promptsSourceGlobal;

  /// No description provided for @promptsSourceLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get promptsSourceLocal;

  /// No description provided for @promptsSourceBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get promptsSourceBuiltin;

  /// No description provided for @promptsFieldBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get promptsFieldBasic;

  /// No description provided for @promptsFieldNumber.
  ///
  /// In zh, this message translates to:
  /// **'编号'**
  String get promptsFieldNumber;

  /// No description provided for @promptsFieldNumberPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'两位数字,如 35'**
  String get promptsFieldNumberPlaceholder;

  /// No description provided for @promptsFieldTitle.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get promptsFieldTitle;

  /// No description provided for @promptsFieldTitlePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'如:我的安全规则'**
  String get promptsFieldTitlePlaceholder;

  /// No description provided for @promptsFieldSummary.
  ///
  /// In zh, this message translates to:
  /// **'摘要(可选)'**
  String get promptsFieldSummary;

  /// No description provided for @promptsFieldSummaryPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'简述片段内容,不会注入提示词'**
  String get promptsFieldSummaryPlaceholder;

  /// No description provided for @promptsFieldContent.
  ///
  /// In zh, this message translates to:
  /// **'片段内容'**
  String get promptsFieldContent;

  /// No description provided for @promptsFieldContentPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'写模型要遵守的内容'**
  String get promptsFieldContentPlaceholder;

  /// No description provided for @promptsEditorNew.
  ///
  /// In zh, this message translates to:
  /// **'新建提示词'**
  String get promptsEditorNew;

  /// No description provided for @promptsEditorEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑提示词'**
  String get promptsEditorEdit;

  /// No description provided for @promptsAddPrompt.
  ///
  /// In zh, this message translates to:
  /// **'添加片段'**
  String get promptsAddPrompt;

  /// No description provided for @promptsResetCustom.
  ///
  /// In zh, this message translates to:
  /// **'重置自定义提示词'**
  String get promptsResetCustom;

  /// No description provided for @promptsResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将删除当前项目与全局层里的所有自定义提示词,各编号回落到内置提示词。此操作不可撤销。'**
  String get promptsResetConfirm;

  /// No description provided for @promptsResetAction.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get promptsResetAction;

  /// No description provided for @promptsHelp.
  ///
  /// In zh, this message translates to:
  /// **'帮助'**
  String get promptsHelp;

  /// No description provided for @promptsDisableBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'完全禁用内置提示词'**
  String get promptsDisableBuiltin;

  /// No description provided for @promptsDisableBuiltinHint.
  ///
  /// In zh, this message translates to:
  /// **'只保留你的片段;需要自己补全全部规则,谨慎开启'**
  String get promptsDisableBuiltinHint;

  /// No description provided for @promptsBatchDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除提示词'**
  String get promptsBatchDeleteTitle;

  /// No description provided for @promptsBatchDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除选中的 {count} 条自定义提示词吗?对应编号将回落到下一层来源。'**
  String promptsBatchDeleteConfirm(int count);

  /// No description provided for @promptsScope.
  ///
  /// In zh, this message translates to:
  /// **'作用域'**
  String get promptsScope;

  /// No description provided for @promptsScopeProject.
  ///
  /// In zh, this message translates to:
  /// **'当前项目'**
  String get promptsScopeProject;

  /// No description provided for @promptsScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get promptsScopeGlobal;

  /// No description provided for @promptsSelectMode.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get promptsSelectMode;

  /// No description provided for @promptsSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String promptsSelectedCount(int count);

  /// No description provided for @promptsSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get promptsSelectAll;

  /// No description provided for @promptsDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get promptsDeselectAll;

  /// No description provided for @promptsSummary.
  ///
  /// In zh, this message translates to:
  /// **'摘要'**
  String get promptsSummary;

  /// No description provided for @promptsGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get promptsGotIt;

  /// No description provided for @promptsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义提示词片段'**
  String get promptsSubtitle;

  /// No description provided for @novelNew.
  ///
  /// In zh, this message translates to:
  /// **'新建小说'**
  String get novelNew;

  /// No description provided for @novelFieldName.
  ///
  /// In zh, this message translates to:
  /// **'书名'**
  String get novelFieldName;

  /// No description provided for @novelFieldNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如:我在修仙界开超市'**
  String get novelFieldNameHint;

  /// No description provided for @novelFieldGender.
  ///
  /// In zh, this message translates to:
  /// **'小说类型'**
  String get novelFieldGender;

  /// No description provided for @novelGenderMale.
  ///
  /// In zh, this message translates to:
  /// **'男频'**
  String get novelGenderMale;

  /// No description provided for @novelGenderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女频'**
  String get novelGenderFemale;

  /// No description provided for @novelFieldTags.
  ///
  /// In zh, this message translates to:
  /// **'小说标签'**
  String get novelFieldTags;

  /// No description provided for @novelFieldTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'可多选,也可以自定义'**
  String get novelFieldTagsHint;

  /// No description provided for @novelCustomTagHint.
  ///
  /// In zh, this message translates to:
  /// **'自定义标签'**
  String get novelCustomTagHint;

  /// No description provided for @novelFieldWordsPerChapter.
  ///
  /// In zh, this message translates to:
  /// **'每章字数'**
  String get novelFieldWordsPerChapter;

  /// No description provided for @novelFieldWordsHint.
  ///
  /// In zh, this message translates to:
  /// **'可选档位,也可以自定义'**
  String get novelFieldWordsHint;

  /// No description provided for @novelCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get novelCreate;

  /// No description provided for @novelPickExisting.
  ///
  /// In zh, this message translates to:
  /// **'选择已有小说'**
  String get novelPickExisting;

  /// No description provided for @novelOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get novelOpen;

  /// No description provided for @novelExistingEmpty.
  ///
  /// In zh, this message translates to:
  /// **'「AI小说」目录里还没有其他小说'**
  String get novelExistingEmpty;

  /// No description provided for @novelExistingEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'把小说文件夹放进 AI小说 目录后,再回到这里选择'**
  String get novelExistingEmptyHint;

  /// No description provided for @novelExistingFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取小说列表失败'**
  String get novelExistingFailed;

  /// No description provided for @novelExistingBrief.
  ///
  /// In zh, this message translates to:
  /// **'继续创作已有小说《{title}》,先阅读「小说资料」与已有章节,了解设定与进度后再动笔。'**
  String novelExistingBrief(String title);

  /// No description provided for @novelBriefTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建小说《{title}》'**
  String novelBriefTitle(String title);

  /// No description provided for @novelBriefTags.
  ///
  /// In zh, this message translates to:
  /// **'标签:{tags}'**
  String novelBriefTags(String tags);

  /// No description provided for @novelBriefWords.
  ///
  /// In zh, this message translates to:
  /// **'每章字数:{words}'**
  String novelBriefWords(String words);

  /// No description provided for @novelScaffoldFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'小说目录创建失败'**
  String get novelScaffoldFailedTitle;

  /// No description provided for @novelScaffoldFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法在 {path} 下创建小说目录,请检查存储权限后重试。'**
  String novelScaffoldFailed(String path);

  /// No description provided for @agentTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get agentTitle;

  /// No description provided for @agentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义子代理定义'**
  String get agentSubtitle;

  /// No description provided for @agentListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无自定义子代理'**
  String get agentListEmpty;

  /// No description provided for @agentListEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点右上角 + 新建自定义子代理定义'**
  String get agentListEmptyHint;

  /// No description provided for @agentScopeProject.
  ///
  /// In zh, this message translates to:
  /// **'当前项目'**
  String get agentScopeProject;

  /// No description provided for @agentScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get agentScopeGlobal;

  /// No description provided for @agentScopeProjectHint.
  ///
  /// In zh, this message translates to:
  /// **'仅对当前工作区生效'**
  String get agentScopeProjectHint;

  /// No description provided for @agentScopeGlobalHint.
  ///
  /// In zh, this message translates to:
  /// **'所有项目共享'**
  String get agentScopeGlobalHint;

  /// No description provided for @agentNew.
  ///
  /// In zh, this message translates to:
  /// **'新建子代理'**
  String get agentNew;

  /// No description provided for @agentEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑子代理'**
  String get agentEdit;

  /// No description provided for @agentSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get agentSave;

  /// No description provided for @agentCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get agentCancel;

  /// No description provided for @agentDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get agentDelete;

  /// No description provided for @agentDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除子代理'**
  String get agentDeleteTitle;

  /// No description provided for @agentDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除 {name}?此操作不可恢复。'**
  String agentDeleteConfirm(Object name);

  /// No description provided for @agentImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get agentImport;

  /// No description provided for @agentName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get agentName;

  /// No description provided for @agentDescription.
  ///
  /// In zh, this message translates to:
  /// **'用途描述'**
  String get agentDescription;

  /// No description provided for @agentDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'何时选用该子代理'**
  String get agentDescriptionHint;

  /// No description provided for @agentPrompt.
  ///
  /// In zh, this message translates to:
  /// **'提示词正文'**
  String get agentPrompt;

  /// No description provided for @agentPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'追加到基线系统提示词后的专属指令'**
  String get agentPromptHint;

  /// No description provided for @agentProvider.
  ///
  /// In zh, this message translates to:
  /// **'提供商'**
  String get agentProvider;

  /// No description provided for @agentModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get agentModel;

  /// No description provided for @agentReasoningEffort.
  ///
  /// In zh, this message translates to:
  /// **'思考强度'**
  String get agentReasoningEffort;

  /// No description provided for @agentMode.
  ///
  /// In zh, this message translates to:
  /// **'默认模式'**
  String get agentMode;

  /// No description provided for @agentTools.
  ///
  /// In zh, this message translates to:
  /// **'工具白名单'**
  String get agentTools;

  /// No description provided for @agentToolsHint.
  ///
  /// In zh, this message translates to:
  /// **'留空表示开放全部工具'**
  String get agentToolsHint;

  /// No description provided for @agentDisallowedTools.
  ///
  /// In zh, this message translates to:
  /// **'工具黑名单'**
  String get agentDisallowedTools;

  /// No description provided for @agentInject.
  ///
  /// In zh, this message translates to:
  /// **'注入规则片段'**
  String get agentInject;

  /// No description provided for @agentInjectHint.
  ///
  /// In zh, this message translates to:
  /// **'base/mainRules/skills/memory/projectRules 或 none'**
  String get agentInjectHint;

  /// No description provided for @agentEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get agentEnable;

  /// No description provided for @agentDisable.
  ///
  /// In zh, this message translates to:
  /// **'禁用'**
  String get agentDisable;

  /// No description provided for @agentEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get agentEnabled;

  /// No description provided for @agentDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get agentDisabled;

  /// No description provided for @agentErrorInvalidName.
  ///
  /// In zh, this message translates to:
  /// **'名称非法'**
  String get agentErrorInvalidName;

  /// No description provided for @agentErrorEmptyPrompt.
  ///
  /// In zh, this message translates to:
  /// **'提示词正文不能为空'**
  String get agentErrorEmptyPrompt;

  /// No description provided for @agentErrorNameConflict.
  ///
  /// In zh, this message translates to:
  /// **'该作用域下已存在同名子代理'**
  String get agentErrorNameConflict;

  /// No description provided for @agentErrorIoFailed.
  ///
  /// In zh, this message translates to:
  /// **'写入文件失败'**
  String get agentErrorIoFailed;

  /// No description provided for @agentCapabilityRead.
  ///
  /// In zh, this message translates to:
  /// **'文件读取'**
  String get agentCapabilityRead;

  /// No description provided for @agentCapabilityWrite.
  ///
  /// In zh, this message translates to:
  /// **'文件修改'**
  String get agentCapabilityWrite;

  /// No description provided for @agentCapabilityCommand.
  ///
  /// In zh, this message translates to:
  /// **'执行命令'**
  String get agentCapabilityCommand;

  /// No description provided for @agentBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get agentBuiltin;

  /// No description provided for @agentBuiltinHint.
  ///
  /// In zh, this message translates to:
  /// **'首次启动释放,升级时完整保留'**
  String get agentBuiltinHint;

  /// No description provided for @agentSelectMode.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get agentSelectMode;

  /// No description provided for @agentBatchEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get agentBatchEnable;

  /// No description provided for @agentBatchDisable.
  ///
  /// In zh, this message translates to:
  /// **'禁用'**
  String get agentBatchDisable;

  /// No description provided for @agentBatchDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get agentBatchDelete;

  /// No description provided for @agentBatchAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get agentBatchAll;

  /// No description provided for @agentBatchCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get agentBatchCancel;

  /// No description provided for @agentSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String agentSelectedCount(Object count);

  /// No description provided for @agentBatchDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除 {count} 个子代理?此操作不可恢复。'**
  String agentBatchDeleteConfirm(Object count);

  /// No description provided for @agentBatchDeleting.
  ///
  /// In zh, this message translates to:
  /// **'正在删除…'**
  String get agentBatchDeleting;

  /// No description provided for @agentInherit.
  ///
  /// In zh, this message translates to:
  /// **'继承会话'**
  String get agentInherit;

  /// No description provided for @agentReasoningNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get agentReasoningNone;

  /// No description provided for @agentReasoningMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极低'**
  String get agentReasoningMinimal;

  /// No description provided for @agentReasoningLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get agentReasoningLow;

  /// No description provided for @agentReasoningMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get agentReasoningMedium;

  /// No description provided for @agentReasoningHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get agentReasoningHigh;

  /// No description provided for @agentReasoningXhigh.
  ///
  /// In zh, this message translates to:
  /// **'极高'**
  String get agentReasoningXhigh;

  /// No description provided for @agentReasoningMax.
  ///
  /// In zh, this message translates to:
  /// **'最大'**
  String get agentReasoningMax;

  /// No description provided for @agentModeBuild.
  ///
  /// In zh, this message translates to:
  /// **'Build'**
  String get agentModeBuild;

  /// No description provided for @agentModePlan.
  ///
  /// In zh, this message translates to:
  /// **'Plan'**
  String get agentModePlan;

  /// No description provided for @agentModeAuto.
  ///
  /// In zh, this message translates to:
  /// **'Auto'**
  String get agentModeAuto;

  /// No description provided for @agentDetail.
  ///
  /// In zh, this message translates to:
  /// **'子代理详情'**
  String get agentDetail;

  /// No description provided for @agentDetailHint.
  ///
  /// In zh, this message translates to:
  /// **'编辑定义;改名会连带重命名定义文件'**
  String get agentDetailHint;

  /// No description provided for @promptsFieldType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get promptsFieldType;

  /// No description provided for @promptsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get promptsSaveFailed;

  /// No description provided for @promptsNoOverrideToDelete.
  ///
  /// In zh, this message translates to:
  /// **'该提示词暂无可删除的自定义覆盖'**
  String get promptsNoOverrideToDelete;

  /// No description provided for @codespacesSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'按名称、仓库或分支搜索'**
  String get codespacesSearchHint;

  /// No description provided for @codespacesFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get codespacesFilterAll;

  /// No description provided for @codespacesFilterRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get codespacesFilterRunning;

  /// No description provided for @codespacesFilterStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get codespacesFilterStopped;

  /// No description provided for @codespacesNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配当前筛选的 Codespace'**
  String get codespacesNoMatch;

  /// No description provided for @codespacesStartAndConnect.
  ///
  /// In zh, this message translates to:
  /// **'启动并连接'**
  String get codespacesStartAndConnect;

  /// No description provided for @codespacesConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接…'**
  String get codespacesConnecting;

  /// No description provided for @codespacesWaitingForStart.
  ///
  /// In zh, this message translates to:
  /// **'等待 Codespace 变为可用…'**
  String get codespacesWaitingForStart;

  /// No description provided for @codespacesConnectError.
  ///
  /// In zh, this message translates to:
  /// **'连接失败：{error}'**
  String codespacesConnectError(String error);

  /// No description provided for @codespacesDetails.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get codespacesDetails;

  /// No description provided for @codespacesOverview.
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get codespacesOverview;

  /// No description provided for @codespacesBranchLabel.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get codespacesBranchLabel;

  /// No description provided for @codespacesMachineLabel.
  ///
  /// In zh, this message translates to:
  /// **'机型'**
  String get codespacesMachineLabel;

  /// No description provided for @codespacesLocation.
  ///
  /// In zh, this message translates to:
  /// **'区域'**
  String get codespacesLocation;

  /// No description provided for @codespacesIdleTimeout.
  ///
  /// In zh, this message translates to:
  /// **'空闲超时（分钟）'**
  String get codespacesIdleTimeout;

  /// No description provided for @codespacesRetentionPeriod.
  ///
  /// In zh, this message translates to:
  /// **'保留期（天）'**
  String get codespacesRetentionPeriod;

  /// No description provided for @codespacesDevcontainerPath.
  ///
  /// In zh, this message translates to:
  /// **'Dev container 路径'**
  String get codespacesDevcontainerPath;

  /// No description provided for @codespacesCreatedAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get codespacesCreatedAt;

  /// No description provided for @codespacesOwner.
  ///
  /// In zh, this message translates to:
  /// **'所有者'**
  String get codespacesOwner;

  /// No description provided for @codespacesBillableOwner.
  ///
  /// In zh, this message translates to:
  /// **'计费所有者'**
  String get codespacesBillableOwner;

  /// No description provided for @codespacesCopySsh.
  ///
  /// In zh, this message translates to:
  /// **'复制 SSH 命令'**
  String get codespacesCopySsh;

  /// No description provided for @codespacesSshCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制 SSH 命令'**
  String get codespacesSshCopied;

  /// No description provided for @codespacesOpenWeb.
  ///
  /// In zh, this message translates to:
  /// **'在 VS Code 网页版中打开'**
  String get codespacesOpenWeb;

  /// No description provided for @codespacesUnpushed.
  ///
  /// In zh, this message translates to:
  /// **'有未推送提交'**
  String get codespacesUnpushed;

  /// No description provided for @codespacesGitStatus.
  ///
  /// In zh, this message translates to:
  /// **'Git 状态'**
  String get codespacesGitStatus;

  /// No description provided for @codespacesActions.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get codespacesActions;

  /// No description provided for @codespacesPendingOperation.
  ///
  /// In zh, this message translates to:
  /// **'正在执行操作'**
  String get codespacesPendingOperation;

  /// No description provided for @codespacesStateQueued.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get codespacesStateQueued;

  /// No description provided for @codespacesStateProvisioning.
  ///
  /// In zh, this message translates to:
  /// **'正在预配'**
  String get codespacesStateProvisioning;

  /// No description provided for @codespacesStateShuttingDown.
  ///
  /// In zh, this message translates to:
  /// **'正在停止'**
  String get codespacesStateShuttingDown;

  /// No description provided for @codespacesStateFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get codespacesStateFailed;

  /// No description provided for @codespacesStateDeleting.
  ///
  /// In zh, this message translates to:
  /// **'正在删除'**
  String get codespacesStateDeleting;

  /// No description provided for @codespacesCurrentEnv.
  ///
  /// In zh, this message translates to:
  /// **'当前环境'**
  String get codespacesCurrentEnv;

  /// No description provided for @codespacesSwitchToLocal.
  ///
  /// In zh, this message translates to:
  /// **'切换到本地容器'**
  String get codespacesSwitchToLocal;

  /// No description provided for @codespacesManage.
  ///
  /// In zh, this message translates to:
  /// **'管理 Codespaces'**
  String get codespacesManage;

  /// No description provided for @codespacesQuickActions.
  ///
  /// In zh, this message translates to:
  /// **'Codespaces'**
  String get codespacesQuickActions;

  /// No description provided for @codespacesPortCopyUrl.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get codespacesPortCopyUrl;

  /// No description provided for @codespacesPortUrlCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制链接'**
  String get codespacesPortUrlCopied;

  /// No description provided for @codespacesErrorInline.
  ///
  /// In zh, this message translates to:
  /// **'{error}'**
  String codespacesErrorInline(String error);

  /// No description provided for @codespacesRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get codespacesRetry;

  /// No description provided for @codespacesRegionDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认区域'**
  String get codespacesRegionDefault;

  /// No description provided for @codespacesAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级选项'**
  String get codespacesAdvanced;

  /// No description provided for @codespacesDevcontainerPathHint.
  ///
  /// In zh, this message translates to:
  /// **'devcontainer.json 路径（可选）'**
  String get codespacesDevcontainerPathHint;

  /// No description provided for @codespacesIdleTimeoutHint.
  ///
  /// In zh, this message translates to:
  /// **'空闲后自动停止的分钟数（可选）'**
  String get codespacesIdleTimeoutHint;

  /// No description provided for @codespacesRetentionHint.
  ///
  /// In zh, this message translates to:
  /// **'停止后保留天数（可选）'**
  String get codespacesRetentionHint;

  /// No description provided for @codespacesReadinessTitle.
  ///
  /// In zh, this message translates to:
  /// **'连接就绪'**
  String get codespacesReadinessTitle;

  /// No description provided for @codespacesReadinessCredOk.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 凭据：已配置'**
  String get codespacesReadinessCredOk;

  /// No description provided for @codespacesReadinessCredMissing.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 凭据：未配置（需含 codespace 权限的令牌）'**
  String get codespacesReadinessCredMissing;

  /// No description provided for @codespacesReadinessGhOk.
  ///
  /// In zh, this message translates to:
  /// **'gh CLI：已就绪'**
  String get codespacesReadinessGhOk;

  /// No description provided for @codespacesReadinessGhMissing.
  ///
  /// In zh, this message translates to:
  /// **'gh CLI：未就绪（终端执行 codecraft 安装「GitHub Codespaces」场景）'**
  String get codespacesReadinessGhMissing;

  /// No description provided for @codespacesOpenTerminal.
  ///
  /// In zh, this message translates to:
  /// **'在终端打开'**
  String get codespacesOpenTerminal;

  /// No description provided for @codespacesOpenGit.
  ///
  /// In zh, this message translates to:
  /// **'打开 Git（部署/同步）'**
  String get codespacesOpenGit;

  /// No description provided for @codespacesManageCredentials.
  ///
  /// In zh, this message translates to:
  /// **'管理凭证'**
  String get codespacesManageCredentials;

  /// No description provided for @codespacesDeploySyncHint.
  ///
  /// In zh, this message translates to:
  /// **'Git 的推送/拉取等操作会作用于当前执行环境；连接 Codespace 后即在远端仓库执行部署/同步。'**
  String get codespacesDeploySyncHint;

  /// No description provided for @gitExecutionTargetCodespace.
  ///
  /// In zh, this message translates to:
  /// **'当前操作作用于 Codespace：{name}'**
  String gitExecutionTargetCodespace(String name);

  /// No description provided for @gitExecutionTargetLocal.
  ///
  /// In zh, this message translates to:
  /// **'当前操作作用于本地容器'**
  String get gitExecutionTargetLocal;

  /// No description provided for @gitDeploySyncSection.
  ///
  /// In zh, this message translates to:
  /// **'部署 / 同步'**
  String get gitDeploySyncSection;

  /// No description provided for @gitDeploySyncHintCodespace.
  ///
  /// In zh, this message translates to:
  /// **'推送、拉取与远程操作在已连接的 Codespace 中执行。'**
  String get gitDeploySyncHintCodespace;

  /// No description provided for @gitDeploySyncHintLocal.
  ///
  /// In zh, this message translates to:
  /// **'推送、拉取与远程操作在本地容器中执行；连接 Codespace 可在远端部署/同步。'**
  String get gitDeploySyncHintLocal;

  /// No description provided for @gitOpenCodespaces.
  ///
  /// In zh, this message translates to:
  /// **'Codespaces'**
  String get gitOpenCodespaces;

  /// No description provided for @gitOpenTerminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get gitOpenTerminal;

  /// No description provided for @terminalCodespaceManage.
  ///
  /// In zh, this message translates to:
  /// **'Codespaces 管理'**
  String get terminalCodespaceManage;

  /// No description provided for @terminalCodespaceCredentials.
  ///
  /// In zh, this message translates to:
  /// **'Git 凭据'**
  String get terminalCodespaceCredentials;

  /// No description provided for @captureTitle.
  ///
  /// In zh, this message translates to:
  /// **'抓包'**
  String get captureTitle;

  /// No description provided for @captureStart.
  ///
  /// In zh, this message translates to:
  /// **'启动代理'**
  String get captureStart;

  /// No description provided for @captureStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get captureStop;

  /// No description provided for @captureRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get captureRunning;

  /// No description provided for @captureStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get captureStopped;

  /// No description provided for @capturePort.
  ///
  /// In zh, this message translates to:
  /// **'代理端口'**
  String get capturePort;

  /// No description provided for @captureClear.
  ///
  /// In zh, this message translates to:
  /// **'清空记录'**
  String get captureClear;

  /// No description provided for @captureSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索 URL / method / 状态码'**
  String get captureSearchHint;

  /// No description provided for @captureEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无抓包记录。启动代理后，将目标流量代理到 127.0.0.1:<端口>。'**
  String get captureEmpty;

  /// No description provided for @captureLimitHint.
  ///
  /// In zh, this message translates to:
  /// **'仅抓取经代理的流量。HTTPS 需安装并信任 CA；Android 7+ 多数应用与证书锁定应用无法 MITM（可用调试版/受信任证书场景）。'**
  String get captureLimitHint;

  /// No description provided for @captureCaTitle.
  ///
  /// In zh, this message translates to:
  /// **'CA 证书'**
  String get captureCaTitle;

  /// No description provided for @captureCaPath.
  ///
  /// In zh, this message translates to:
  /// **'证书路径'**
  String get captureCaPath;

  /// No description provided for @captureCaGuide.
  ///
  /// In zh, this message translates to:
  /// **'将证书安装到系统/用户证书并设为信任（用于网络/HTTPS 抓包）。Android 设置路径因机型不同，通常在「安全/加密与凭据/安装证书」。安装后需将 HTTP 代理设为 127.0.0.1:<端口>。'**
  String get captureCaGuide;

  /// No description provided for @captureCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get captureCopyPath;

  /// No description provided for @captureDetail.
  ///
  /// In zh, this message translates to:
  /// **'请求详情'**
  String get captureDetail;

  /// No description provided for @captureRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求'**
  String get captureRequest;

  /// No description provided for @captureResponse.
  ///
  /// In zh, this message translates to:
  /// **'响应'**
  String get captureResponse;

  /// No description provided for @captureNotFound.
  ///
  /// In zh, this message translates to:
  /// **'记录不存在'**
  String get captureNotFound;

  /// No description provided for @captureCopyUrl.
  ///
  /// In zh, this message translates to:
  /// **'复制 URL'**
  String get captureCopyUrl;

  /// No description provided for @captureInstallCa.
  ///
  /// In zh, this message translates to:
  /// **'安装证书'**
  String get captureInstallCa;

  /// No description provided for @captureOpenSecurity.
  ///
  /// In zh, this message translates to:
  /// **'安全设置'**
  String get captureOpenSecurity;

  /// No description provided for @captureDownloadCa.
  ///
  /// In zh, this message translates to:
  /// **'保存证书'**
  String get captureDownloadCa;

  /// No description provided for @captureCaInstallFail.
  ///
  /// In zh, this message translates to:
  /// **'无法直接安装（已复制路径），请到系统安全设置手动安装证书。'**
  String get captureCaInstallFail;

  /// No description provided for @captureVpnPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'VPN 权限被拒绝，无法启用抓包。请允许 VPN 权限后重试。'**
  String get captureVpnPermissionDenied;

  /// No description provided for @captureSequence.
  ///
  /// In zh, this message translates to:
  /// **'全部请求'**
  String get captureSequence;

  /// No description provided for @captureDomains.
  ///
  /// In zh, this message translates to:
  /// **'域名列表'**
  String get captureDomains;

  /// No description provided for @captureDomainSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'最后请求: {time} · {count} 条'**
  String captureDomainSubtitle(String time, int count);

  /// No description provided for @captureClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定清空全部抓包记录？'**
  String get captureClearConfirm;

  /// No description provided for @capturePip.
  ///
  /// In zh, this message translates to:
  /// **'小窗模式'**
  String get capturePip;

  /// No description provided for @capturePipUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前设备不支持小窗模式'**
  String get capturePipUnsupported;

  /// No description provided for @capturePipNoTraffic.
  ///
  /// In zh, this message translates to:
  /// **'暂无流量'**
  String get capturePipNoTraffic;

  /// No description provided for @captureNoDomains.
  ///
  /// In zh, this message translates to:
  /// **'暂无域名'**
  String get captureNoDomains;

  /// No description provided for @captureCopyHost.
  ///
  /// In zh, this message translates to:
  /// **'复制域名'**
  String get captureCopyHost;

  /// No description provided for @captureDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除该域名的全部记录？'**
  String get captureDeleteConfirm;

  /// No description provided for @captureSort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get captureSort;

  /// No description provided for @captureOverview.
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get captureOverview;

  /// No description provided for @captureCookies.
  ///
  /// In zh, this message translates to:
  /// **'Cookie'**
  String get captureCookies;

  /// No description provided for @captureProtocol.
  ///
  /// In zh, this message translates to:
  /// **'协议'**
  String get captureProtocol;

  /// No description provided for @captureDuration.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get captureDuration;

  /// No description provided for @captureSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get captureSize;

  /// No description provided for @captureRemoteAddress.
  ///
  /// In zh, this message translates to:
  /// **'远程地址'**
  String get captureRemoteAddress;

  /// No description provided for @captureRequestTime.
  ///
  /// In zh, this message translates to:
  /// **'请求时间'**
  String get captureRequestTime;

  /// No description provided for @capturePath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get capturePath;

  /// No description provided for @captureStatusCode.
  ///
  /// In zh, this message translates to:
  /// **'状态码'**
  String get captureStatusCode;

  /// No description provided for @captureRequestHeaders.
  ///
  /// In zh, this message translates to:
  /// **'请求头'**
  String get captureRequestHeaders;

  /// No description provided for @captureResponseHeaders.
  ///
  /// In zh, this message translates to:
  /// **'响应头'**
  String get captureResponseHeaders;

  /// No description provided for @captureRequestBody.
  ///
  /// In zh, this message translates to:
  /// **'请求体'**
  String get captureRequestBody;

  /// No description provided for @captureResponseBody.
  ///
  /// In zh, this message translates to:
  /// **'响应体'**
  String get captureResponseBody;

  /// No description provided for @captureBodyTruncated.
  ///
  /// In zh, this message translates to:
  /// **'（内容已截断）'**
  String get captureBodyTruncated;

  /// No description provided for @captureFormatted.
  ///
  /// In zh, this message translates to:
  /// **'格式化'**
  String get captureFormatted;

  /// No description provided for @captureRaw.
  ///
  /// In zh, this message translates to:
  /// **'原文'**
  String get captureRaw;

  /// No description provided for @captureNoCookies.
  ///
  /// In zh, this message translates to:
  /// **'没有 Cookie'**
  String get captureNoCookies;

  /// No description provided for @captureRequestCookies.
  ///
  /// In zh, this message translates to:
  /// **'请求 Cookie'**
  String get captureRequestCookies;

  /// No description provided for @captureResponseCookies.
  ///
  /// In zh, this message translates to:
  /// **'响应 Set-Cookie'**
  String get captureResponseCookies;

  /// No description provided for @backupAndRestore.
  ///
  /// In zh, this message translates to:
  /// **'备份与还原'**
  String get backupAndRestore;

  /// No description provided for @selectExportData.
  ///
  /// In zh, this message translates to:
  /// **'选择导出数据'**
  String get selectExportData;

  /// No description provided for @aiProvider.
  ///
  /// In zh, this message translates to:
  /// **'AI 供应商'**
  String get aiProvider;

  /// No description provided for @connectSync.
  ///
  /// In zh, this message translates to:
  /// **'连接与同步'**
  String get connectSync;

  /// No description provided for @chatRecords.
  ///
  /// In zh, this message translates to:
  /// **'聊天记录'**
  String get chatRecords;

  /// No description provided for @mcpServer.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器'**
  String get mcpServer;

  /// No description provided for @permissionRules.
  ///
  /// In zh, this message translates to:
  /// **'授权规则'**
  String get permissionRules;

  /// No description provided for @appSettings.
  ///
  /// In zh, this message translates to:
  /// **'应用设置'**
  String get appSettings;

  /// No description provided for @workspaceFiles.
  ///
  /// In zh, this message translates to:
  /// **'工作区文件'**
  String get workspaceFiles;

  /// No description provided for @workspaceFilesHint.
  ///
  /// In zh, this message translates to:
  /// **'工作区文件建议通过 Git 提交备份，导出备份仅作备用'**
  String get workspaceFilesHint;

  /// No description provided for @exportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份'**
  String get exportBackup;

  /// No description provided for @exportBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'选择要导出的数据，可设置口令加密'**
  String get exportBackupDesc;

  /// No description provided for @importBackup.
  ///
  /// In zh, this message translates to:
  /// **'导入备份'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'从备份文件还原数据'**
  String get importBackupDesc;

  /// No description provided for @localBackup.
  ///
  /// In zh, this message translates to:
  /// **'本地备份'**
  String get localBackup;

  /// No description provided for @cloudBackup.
  ///
  /// In zh, this message translates to:
  /// **'网络备份'**
  String get cloudBackup;

  /// No description provided for @aboutUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get aboutUpdateAvailable;

  /// No description provided for @aboutUpdateDesc.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get aboutUpdateDesc;

  /// No description provided for @aboutUpdateLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get aboutUpdateLater;

  /// No description provided for @aboutUpdateGo.
  ///
  /// In zh, this message translates to:
  /// **'前往下载'**
  String get aboutUpdateGo;

  /// No description provided for @aboutCheckingUpdate.
  ///
  /// In zh, this message translates to:
  /// **'正在向 GitHub 查询最新版本…'**
  String get aboutCheckingUpdate;

  /// No description provided for @aboutAlreadyLatest.
  ///
  /// In zh, this message translates to:
  /// **'已经是最新版本'**
  String get aboutAlreadyLatest;

  /// No description provided for @aboutCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本'**
  String get aboutCurrentVersion;

  /// No description provided for @aboutNewVersionFound.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get aboutNewVersionFound;

  /// No description provided for @aboutUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get aboutUpdateFailed;

  /// No description provided for @storageTitle.
  ///
  /// In zh, this message translates to:
  /// **'存储空间'**
  String get storageTitle;

  /// No description provided for @storageRefresh.
  ///
  /// In zh, this message translates to:
  /// **'重新统计'**
  String get storageRefresh;

  /// No description provided for @storageCategoryDetail.
  ///
  /// In zh, this message translates to:
  /// **'占用明细'**
  String get storageCategoryDetail;

  /// No description provided for @storageFootnote.
  ///
  /// In zh, this message translates to:
  /// **'点击带箭头的分类可展开明细。删会话可减小聊天记录。'**
  String get storageFootnote;

  /// No description provided for @storageFreedBytes.
  ///
  /// In zh, this message translates to:
  /// **'已释放 {size}'**
  String storageFreedBytes(Object size);

  /// No description provided for @storageAppUsage.
  ///
  /// In zh, this message translates to:
  /// **'应用占用'**
  String get storageAppUsage;

  /// No description provided for @storageComputing.
  ///
  /// In zh, this message translates to:
  /// **'统计中…'**
  String get storageComputing;

  /// No description provided for @storageDeviceSpace.
  ///
  /// In zh, this message translates to:
  /// **'设备可用 {available} / 共 {total}'**
  String storageDeviceSpace(Object available, Object total);

  /// No description provided for @storageCleanSelect.
  ///
  /// In zh, this message translates to:
  /// **'清理选中项 · {size}'**
  String storageCleanSelect(Object size);

  /// No description provided for @storageConfirmClean.
  ///
  /// In zh, this message translates to:
  /// **'确认清理'**
  String get storageConfirmClean;

  /// No description provided for @storageConfirmContent.
  ///
  /// In zh, this message translates to:
  /// **'将清理以下选中项,共约 {size}。此操作不可恢复。'**
  String storageConfirmContent(Object size);

  /// No description provided for @storageConfirmDetail.
  ///
  /// In zh, this message translates to:
  /// **'仅清理本机应用缓存、日志及全局目录中的所选数据,可能影响多个工作区的历史输出读取或识图追问;不会删除聊天记录、工作区文件、AI 配置或远程服务器数据。'**
  String get storageConfirmDetail;

  /// No description provided for @storageCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get storageCancel;

  /// No description provided for @storageClean.
  ///
  /// In zh, this message translates to:
  /// **'清理'**
  String get storageClean;

  /// No description provided for @storageUsageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'—'**
  String get storageUsageUnavailable;

  /// No description provided for @storageCategoryContainer.
  ///
  /// In zh, this message translates to:
  /// **'容器'**
  String get storageCategoryContainer;

  /// No description provided for @storageCategoryContainerImage.
  ///
  /// In zh, this message translates to:
  /// **'容器镜像'**
  String get storageCategoryContainerImage;

  /// No description provided for @storageCategoryChat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get storageCategoryChat;

  /// No description provided for @storageCategoryWorkspaces.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get storageCategoryWorkspaces;

  /// No description provided for @storageCategoryAiConfig.
  ///
  /// In zh, this message translates to:
  /// **'AI 配置'**
  String get storageCategoryAiConfig;

  /// No description provided for @storageCategoryCheckpoints.
  ///
  /// In zh, this message translates to:
  /// **'检查点'**
  String get storageCategoryCheckpoints;

  /// No description provided for @storageCategoryLogs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get storageCategoryLogs;

  /// No description provided for @storageCategoryCaches.
  ///
  /// In zh, this message translates to:
  /// **'缓存'**
  String get storageCategoryCaches;

  /// No description provided for @storageCategoryOther.
  ///
  /// In zh, this message translates to:
  /// **'其他数据'**
  String get storageCategoryOther;

  /// No description provided for @storageCategoryApk.
  ///
  /// In zh, this message translates to:
  /// **'应用安装包'**
  String get storageCategoryApk;

  /// No description provided for @cleanupCaches.
  ///
  /// In zh, this message translates to:
  /// **'缓存文件'**
  String get cleanupCaches;

  /// No description provided for @cleanupCachesDesc.
  ///
  /// In zh, this message translates to:
  /// **'临时文件,删除后会自动重建'**
  String get cleanupCachesDesc;

  /// No description provided for @cleanupLogs.
  ///
  /// In zh, this message translates to:
  /// **'运行日志'**
  String get cleanupLogs;

  /// No description provided for @cleanupLogsDesc.
  ///
  /// In zh, this message translates to:
  /// **'应用日志与 AI 请求日志,删除不影响功能'**
  String get cleanupLogsDesc;

  /// No description provided for @cleanupToolOutput.
  ///
  /// In zh, this message translates to:
  /// **'工具输出存档'**
  String get cleanupToolOutput;

  /// No description provided for @cleanupToolOutputDesc.
  ///
  /// In zh, this message translates to:
  /// **'AI 超长工具输出保存到磁盘的副本,删除后旧消息里的输出路径不再可读'**
  String get cleanupToolOutputDesc;

  /// No description provided for @cleanupVisionSessions.
  ///
  /// In zh, this message translates to:
  /// **'识图会话缓存'**
  String get cleanupVisionSessions;

  /// No description provided for @cleanupVisionSessionsDesc.
  ///
  /// In zh, this message translates to:
  /// **'识图追问的历史,删除后无法继续追问旧图片'**
  String get cleanupVisionSessionsDesc;

  /// No description provided for @containerPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'容器与镜像'**
  String get containerPageTitle;

  /// No description provided for @containerDownloadTooltip.
  ///
  /// In zh, this message translates to:
  /// **'下载容器'**
  String get containerDownloadTooltip;

  /// No description provided for @containerRefreshTooltip.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get containerRefreshTooltip;

  /// No description provided for @containerInstalledSection.
  ///
  /// In zh, this message translates to:
  /// **'已安装容器'**
  String get containerInstalledSection;

  /// No description provided for @containerDefaultLabel.
  ///
  /// In zh, this message translates to:
  /// **'默认容器'**
  String get containerDefaultLabel;

  /// No description provided for @containerSetDefault.
  ///
  /// In zh, this message translates to:
  /// **'设为默认'**
  String get containerSetDefault;

  /// No description provided for @containerDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除容器'**
  String get containerDeleteTitle;

  /// No description provided for @containerDeleteContent.
  ///
  /// In zh, this message translates to:
  /// **'确定删除「{name}」吗？容器内安装的软件会一并删除。'**
  String containerDeleteContent(String name);

  /// No description provided for @containerDownloadPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'容器下载'**
  String get containerDownloadPageTitle;

  /// No description provided for @containerDownloadHint.
  ///
  /// In zh, this message translates to:
  /// **'选择需要的镜像下载。镜像为官方 aarch64 rootfs，解压后由 PRoot 提供隔离的文件系统。'**
  String get containerDownloadHint;

  /// No description provided for @containerInstallingStage.
  ///
  /// In zh, this message translates to:
  /// **'正在安装…'**
  String get containerInstallingStage;

  /// No description provided for @containerAvailableImages.
  ///
  /// In zh, this message translates to:
  /// **'可用镜像'**
  String get containerAvailableImages;

  /// No description provided for @containerDownloadAfter.
  ///
  /// In zh, this message translates to:
  /// **'下载完成后，容器会显示在「容器与镜像」页面。'**
  String get containerDownloadAfter;

  /// No description provided for @containerInstalledCount.
  ///
  /// In zh, this message translates to:
  /// **'已安装 {count} 个'**
  String containerInstalledCount(int count);

  /// No description provided for @containerDownloadButton.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get containerDownloadButton;

  /// No description provided for @containerNoContainers.
  ///
  /// In zh, this message translates to:
  /// **'暂无已下载容器'**
  String get containerNoContainers;

  /// No description provided for @containerNoContainersDesc.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角下载按钮选择镜像'**
  String get containerNoContainersDesc;

  /// No description provided for @containerDefaultSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'默认容器 · {size}'**
  String containerDefaultSubtitle(String size);

  /// No description provided for @containerDeleteFootnote.
  ///
  /// In zh, this message translates to:
  /// **'删除容器会同时删除容器内安装的软件包；工作区文件不受影响。'**
  String get containerDeleteFootnote;

  /// No description provided for @exportSetPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置加密口令（可选）'**
  String get exportSetPassword;

  /// No description provided for @exportBackupAction.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get exportBackupAction;

  /// No description provided for @importSelectBackupFile.
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件'**
  String get importSelectBackupFile;

  /// No description provided for @importLocalBackup.
  ///
  /// In zh, this message translates to:
  /// **'本地备份'**
  String get importLocalBackup;

  /// No description provided for @importLocalBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'从应用文档目录选择备份文件'**
  String get importLocalBackupDesc;

  /// No description provided for @exportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份已导出: {fileName}'**
  String exportSuccess(String fileName);

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String exportFailed(String error);

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份已还原'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
