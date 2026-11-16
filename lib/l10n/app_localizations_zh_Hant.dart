// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (Traditional) (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizations {
  AppLocalizationsZhHant([String locale = 'zh_Hant']) : super(locale);

  @override
  String get appName => 'CodeCraft';
  @override
  String get tabSessions => '會話';
  @override
  String get tabSettings => '设置';
  @override
  String get newSession => '新建會話';
  @override
  String get send => '髮送';
  @override
  String get stop => '停止';
  @override
  String get reverseTabClasses => '类';
  @override
  String get reverseTabStrings => '字符串池';
  @override
  String get reverseTabResources => '资源';
  @override
  String get reverseTabHex => '十六進制';
  @override
  String get reverseSearchClassHint => '搜索类名';
  @override
  String get reverseSearchStringHint => '搜索字符串';
  @override
  String get reverseSearchResourceHint => '搜索资源名、类型或 0x 编號';
  @override
  String get reverseNoMatch => '没有匹配項';
  @override
  String get reverseEmptyFile => '文件为空';
  @override
  String get reverseLoadFailed => '打開失败';
  @override
  String get reverseParseFailed => '解析失败,这个文件可能被加固或已损坏';
  @override
  String get reverseEditString => '修改字符串';
  @override
  String get reverseEqualLengthHint => '只能等長替换:新內容编碼後的字节數必须與原字符串一致,否则文件內偏移會全部錯位';
  @override
  String get reverseEditByte => '修改字节';
  @override
  String get reverseEditByteHint => '输入两位十六進制,例如 0a、ff';
  @override
  String get reverseInvalidByte => '请输入 00-ff 之間的十六進制字节';
  @override
  String get reverseJumpToOffset => '跳转到偏移';
  @override
  String get reverseOffsetInvalid => '偏移無效,请输入十六進制';
  @override
  String get reverseSuperclass => '父类';
  @override
  String get reverseInterfaces => '接口';
  @override
  String get reverseAccessFlags => '修饰符';
  @override
  String get reverseFields => '字段';
  @override
  String get reverseMethods => '方法';
  @override
  String get reverseAbstractMethod => '無方法體';
  @override
  String get reverseSmaliHint => '以上为 smali 反汇编结果;offset 是该指令在方法體內的字节偏移';
  @override
  String get reverseOpenAsHex => '以十六進制打開';
  @override
  String reverseMethodCount(int count) {
    return '$count 个方法';
  }
  @override
  String reverseFieldCount(int count) {
    return '$count 个字段';
  }
  @override
  String reverseHexByteCount(int count) {
    return '共 $count 字节';
  }
  @override
  String get cancel => '取消';
  @override
  String get confirm => '确定';
  @override
  String get save => '保存';
  @override
  String get delete => '刪除';
  @override
  String get rename => '重命名';
  @override
  String get copy => '复制';
  @override
  String get copied => '已复制';
  @override
  String get retry => '重試';
  @override
  String get pin => '置頂';
  @override
  String get unpin => '取消置頂';
  @override
  String get search => '搜索';
  @override
  String get searchSessions => '搜索會話';
  @override
  String get noSessions => '暂無會話';
  @override
  String get noMessages => '開始新的对話吧';
  @override
  String get chatInputPlaceholder => '输入消息,與 AI 对話…';
  @override
  String get reasoningTitle => '思考過程';
  @override
  String get untitled => '未命名';
  @override
  String get pinned => '已置頂';
  @override
  String get settings => '设置';
  @override
  String get providers => 'AI 提供商';
  @override
  String get providersSubtitle => '模型、接口與密鑰';
  @override
  String get appearance => '外观';
  @override
  String get themeMode => '主题模式';
  @override
  String get themeModeSystem => '跟随系统';
  @override
  String get themeModeLight => '浅色';
  @override
  String get themeModeDark => '深色';
  @override
  String get language => '語言';
  @override
  String get languageSystem => '跟随系统';
  @override
  String get about => '關于';
  @override
  String get version => '版本';
  @override
  String get license => '開源协議';
  @override
  String get licenseBody => '本項目是 jieapi/Codecraft 的 Flutter 复刻,按 GPL-3.0 协議開源。';
  @override
  String get addProvider => '添加供应商';
  @override
  String get providerName => '名稱';
  @override
  String get providerType => '协議';
  @override
  String get baseUrl => 'Base URL';
  @override
  String get apiKey => 'API Key';
  @override
  String get defaultModel => '默認模型';
  @override
  String get modelList => '模型列表';
  @override
  String get model => '模型';
  @override
  String get mode => '模式';
  @override
  String get reasoningEffort => '思考强度';
  @override
  String get reasoningEffortNone => '不思考';
  @override
  String get reasoningEffortMinimal => '极低';
  @override
  String get reasoningEffortLow => '低';
  @override
  String get reasoningEffortMedium => '中';
  @override
  String get reasoningEffortHigh => '高';
  @override
  String get reasoningEffortXHigh => '极高';
  @override
  String get reasoningEffortMax => '最高';
  @override
  String get deleteProviderConfirm => '确定刪除该供应商?';
  @override
  String get deleteSessionConfirm => '确定刪除该會話?';
  @override
  String get emptyProviders => '还没有供应商,點右上角 + 添加';
  @override
  String get emptyModels => '还没有模型';
  @override
  String get modelInputHint => '输入模型 ID 後回车添加';
  @override
  String get errorGeneric => '出錯了';
  @override
  String get retrying => '正在重試';
  @override
  String get emptyMessage => '消息內容为空';
  @override
  String get enabled => '已啟用';
  @override
  String get disabled => '已禁用';
  @override
  String providerModelsCountTag(int count) {
    return '$count 个模型';
  }
  @override
  String get inputTokens => '输入';
  @override
  String get outputTokens => '输出';
  @override
  String get emptyChatHint => '選择一个會話開始对話';
  @override
  String get errorNoProvider => '未配置可用的供应商,请先在设置中添加';
  @override
  String get errorNoModel => '请为该供应商選择模型';
  @override
  String get errorEmptyResponse => '模型返回了空白內容';
  @override
  String get thinking => '思考中…';
  @override
  String get modelListTitle => '選择模型';
  @override
  String get providerListTitle => '選择供应商';
  @override
  String get customProvider => '自定義';
  @override
  String get addFromPreset => '從预设添加';
  @override
  String get useFullUrlHint => 'baseUrl 已是完整端點';
  @override
  String get aboutBody => 'Codecraft Flutter 是 jieapi/Codecraft 的 Flutter 复刻(Phase 1:核心对話閉环)。';
  @override
  String get chatPlaceholder => '有什么可以帮你的?';
  @override
  String get chatInputHint => '描述你的需求,我来帮你编寫、修改或解释代碼';
  @override
  String get openSidebar => '打開侧边栏';
  @override
  String get noModelSelected => '未選择模型';
  @override
  String get sessionGroupPinned => '置頂';
  @override
  String get sessionGroupToday => '今天';
  @override
  String get sessionGroupYesterday => '昨天';
  @override
  String get sessionGroupLast7Days => '7天內';
  @override
  String get sessionGroupLast30Days => '30天內';
  @override
  String get sessionGroupMonthFormat => 'yyyy年M月';
  @override
  String chatThinkingRunningTime(String seconds) {
    return '正在思考(耗时 $seconds 秒)';
  }
  @override
  String chatThinkingDoneTime(String seconds) {
    return '思考完成(耗时 $seconds 秒)';
  }
  @override
  String get chatThinkingDone => '思考完成';
  @override
  String get chatQueueHint => 'AI 正在处理中,點右侧方块可停止';
  @override
  String get chatStatusGenerating => '正在生成';
  @override
  String get chatStatusThinking => '正在思考';
  @override
  String get chatStatusCallingTool => '正在調用工具';
  @override
  String get chatStatusRunningCommand => '正在执行命令';
  @override
  String get chatStatusEditingFile => '正在编辑文件';
  @override
  String get chatStatusReadingFile => '正在讀取文件';
  @override
  String get chatStatusViewingImage => '正在查看图片';
  @override
  String get chatStatusSearchingWeb => '正在联網搜索';
  @override
  String get chatStatusBrowsingWeb => '正在操作浏览器';
  @override
  String get chatStatusAskingUser => '正在询问用户';
  @override
  String get chatStatusGeneratingImage => '正在生成图片';
  @override
  String get chatStatusUpdatingTodo => '正在整理待办';
  @override
  String get chatStatusStartingSubagent => '正在啟动子代理';
  @override
  String get chatCompressingContext => '正在压缩上下文';
  @override
  String get chatContextCompressed => '上下文已压缩';
  @override
  String get chatCompactionSummary => '接手摘要';
  @override
  String get chatStatusReadingMemory => '正在讀取记忆';
  @override
  String get chatToolRunning => '工具执行中';
  @override
  String get chatToolSucceeded => '工具执行成功';
  @override
  String get chatToolFailed => '工具执行失败';
  @override
  String get chatEffortNone => '不思考';
  @override
  String get chatEffortMinimal => '极低';
  @override
  String get chatEffortLow => '低';
  @override
  String get chatEffortMedium => '中';
  @override
  String get chatEffortHigh => '高';
  @override
  String get chatEffortXHigh => '极高';
  @override
  String get chatEffortMax => '最高';
  @override
  String get searchModels => '搜索模型';
  @override
  String get chatAddAttachment => '添加附件';
  @override
  String get chatUploadFile => '上传文件';
  @override
  String get chatUploadImage => '上传图片';
  @override
  String get chatTakePhoto => '拍照';
  @override
  String get attachmentPrefix => '附件:';
  @override
  String attachmentMax(int count) {
    return '最多可同时髮送 $count 个附件';
  }
  @override
  String attachmentUploaded(int count) {
    return '已上传 $count 个附件';
  }
  @override
  String attachmentUploadedPartial(int count) {
    return '已上传 $count 个附件,部分附件未加入';
  }
  @override
  String attachmentUploading(int count) {
    return '正在上传 $count 个文件…';
  }
  @override
  String attachmentImageTooLarge(String size) {
    return '图片超過 $size,请压缩後重試';
  }
  @override
  String get attachmentUnsupportedImageType => '無法识別图片类型,仅支持 jpg/png/gif/webp';
  @override
  String get attachmentReadFileFailed => '無法讀取所選文件';
  @override
  String get attachmentUploadFailed => '上传失败';
  @override
  String get removeAttachment => '移除附件';
  @override
  String get imagePreview => '图片预览';
  @override
  String get imageLoadFailed => '图片加载失败,文件可能已被移动或刪除';
  @override
  String get close => '關閉';
  @override
  String get fileFallback => '文件';
  @override
  String get skillsTitle => 'Skill 管理';
  @override
  String get skillsSubtitle => '浏览、导入與管理寫作技能';
  @override
  String get skillsNew => '新建技能';
  @override
  String get skillsImport => '导入 Markdown';
  @override
  String get skillsScopeTitle => '選择作用域';
  @override
  String get skillsScopeGlobal => '';
  @override
  String get skillsScopeProject => '項目技能';
  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills,跨項目共享';
  @override
  String get skillsScopeProjectHint => '~/workspace/.codecraft/skills,随当前工作區';
  @override
  String skillsProjectGroup(String name) {
    return '当前項目($name)';
  }
  @override
  String get skillsNoProjectSkills => '当前項目还没有技能';
  @override
  String get skillsNoGlobalSkills => '还没有全局技能';
  @override
  String get skillsEmpty => '还没有技能';
  @override
  String get skillsEmptyHint => '技能是寫给 AI 的专項操作說明;导入 SKILL.md 或手动新建一个吧。';
  @override
  String get skillsName => '名稱';
  @override
  String get skillsDescription => '描述';
  @override
  String get skillsDescriptionHint => '何时使用这个技能(會進系统提示)';
  @override
  String get skillsInstructions => '指令正文';
  @override
  String get skillsInstructionsHint => '技能要执行的步骤,Markdown 書寫';
  @override
  String skillsImported(String name) {
    return '已导入技能「$name」';
  }
  @override
  String get skillsDeleteTitle => '刪除技能';
  @override
  String skillsDeleteConfirm(String name) {
    return '确定刪除技能「$name」(含其目錄與脚本)?';
  }
  @override
  String get skillsErrorInvalidName => '技能名無效:不能为空、超長或含 / \\ : * ? " < > |';
  @override
  String get skillsErrorEmptyInstructions => '指令正文不能为空';
  @override
  String skillsErrorNameConflict(String name) {
    return '同作用域已有名为「$name」的技能';
  }
  @override
  String get skillsErrorNoSkill => '文件裡没有可识別的技能';
  @override
  String get skillsErrorIoFailed => '讀寫技能文件失败';
  @override
  String get providerAdd => '添加供应商';
  @override
  String get providerEdit => '编辑供应商';
  @override
  String get providerEditModel => '编辑模型';
  @override
  String get providerConfig => '配置';
  @override
  String get providerSectionBasic => '基本信息';
  @override
  String get providerSectionType => '上游格式';
  @override
  String get providerSectionOptions => '選項';
  @override
  String get providerFullUrl => '完整 URL';
  @override
  String get providerFullUrlDesc => 'Base URL 即完整请求地址,不自动拼接默認路徑';
  @override
  String get providerHeadersTitle => '自定義请求头';
  @override
  String get providerHeadersDesc => '完全覆盖该供应商请求的同名默認头';
  @override
  String get providerHeadersAdd => '添加请求头';
  @override
  String get providerHeadersManage => '管理';
  @override
  String providerHeadersCount(int count) {
    return '已配置 $count 个请求头';
  }
  @override
  String get providerShowApiKey => '显示密鑰';
  @override
  String get providerHideApiKey => '隐藏密鑰';
  @override
  String get providerAddModel => '添加模型';
  @override
  String get providerNoModels => '暂無模型';
  @override
  String get providerNoModelsHint => '點击右上方按钮添加模型';
  @override
  String get providerModelCurrent => '当前';
  @override
  String providerModelsCount(String count) {
    return '模型($count)';
  }
  @override
  String get providerModelsSelect => '多選';
  @override
  String providerModelsSelectedCount(int count) {
    return '已選 $count 項';
  }
  @override
  String get providerModelsSelectAll => '全選';
  @override
  String get providerModelsDeselectAll => '取消全選';
  @override
  String get providerModelsBatchTest => '测試';
  @override
  String get providerModelsBatchDelete => '刪除';
  @override
  String get providerModelsBatchDeleteTitle => '刪除模型';
  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '确定刪除選中的 $count 个模型吗?';
  }
  @override
  String get providerFetchModels => '拉取模型';
  @override
  String get providerAddAllModels => '全部添加';
  @override
  String get providerAddAllModelsTitle => '添加全部模型';
  @override
  String providerAddAllModelsConfirm(int count) {
    return '确定将拉取到的 $count 个模型全部添加至当前提供商?';
  }
  @override
  String get providerFilterModelsHint => '输入模型名稱篩選';
  @override
  String get providerNoMatchingModels => '没有匹配的模型';
  @override
  String providerModelAdded(String name) {
    return '已添加模型「$name」';
  }
  @override
  String get providerModelName => '模型名稱';
  @override
  String get providerModelAlreadyAdded => '该模型已添加';
  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · $latencyms';
  }
  @override
  String get providerFetchMissingFields => '响应缺少列表字段';
  @override
  String get providerFetchFailed => '拉取模型失败';
  @override
  String get providerApiKeyRequired => '请先填寫 API Key';
  @override
  String get providerTestModel => '测試';
  @override
  String get providerModelContext => '上下文窗口 (tokens)';
  @override
  String get providerModelContextInput => '输入上限 (tokens)';
  @override
  String get providerModelContextOutput => '输出上限 (tokens)';
  @override
  String get providerModelWindowInvalid => '请输入有效的正整數,或留空使用自动识別值';
  @override
  String get providerModelSectionPrice => '价格';
  @override
  String get providerModelPriceInput => '输入价格 (USD/1M tokens)';
  @override
  String get providerModelPriceOutput => '输出价格 (USD/1M tokens)';
  @override
  String get providerModelPriceCacheRead => '缓存讀价格 (USD/1M tokens)';
  @override
  String get providerModelPriceCacheWrite => '缓存寫价格 (USD/1M tokens)';
  @override
  String get providerModelCapabilities => '能力';
  @override
  String get providerModelCapVision => '图片输入';
  @override
  String get providerModelCapImageOutput => '图片输出';
  @override
  String get providerModelCapTools => '工具調用';
  @override
  String get providerModelCapReasoning => '思考';
  @override
  String get providerModelSectionReasoning => '思考档位';
  @override
  String get providerModelReasoningHint => '只勾選该模型真實支持的档位;全部不勾则由內置能力表自动判断';
  @override
  String get providerModelReasoningCanDisable => '可以關閉思考';
  @override
  String get providerTestRequestUrl => '请求地址';
  @override
  String get providerTestRequestHeaders => '请求头';
  @override
  String get providerTestRequestBody => '请求體';
  @override
  String get providerTestResponse => '响应';
  @override
  String get providerTestError => '錯誤详情';
  @override
  String get providerMultiKeyTitle => '多 Key 模式';
  @override
  String get providerMultiKeySubtitle => '同一供应商下配多个 Key,密鑰不可用时自动切换并重髮';
  @override
  String get providerMultiKeyManage => '多 Key 管理';
  @override
  String providerMultiKeySummary(int count, String strategy) {
    return '$count 个 · $strategy';
  }
  @override
  String get providerMultiKeyList => 'Key 列表';
  @override
  String providerMultiKeyItem(int index) {
    return '密鑰 #$index';
  }
  @override
  String get providerMultiKeyEmpty => '點此添加第一个 Key';
  @override
  String get providerMultiKeyAdd => '添加 Key';
  @override
  String get providerMultiKeyWeight => '調度权重';
  @override
  String get providerMultiKeyWeightHint => '默認 1 · ≤ 0 时不参與 · 最大 1,000,000';
  @override
  String get providerMultiKeyStrategy => '取用策略';
  @override
  String get providerMultiKeyStrategySequential => '顺序';
  @override
  String get providerMultiKeyStrategySequentialDesc => '始终用靠前的 Key,失败达阈值才切下一个';
  @override
  String get providerMultiKeyStrategyRoundRobin => '轮询';
  @override
  String get providerMultiKeyStrategyRoundRobinDesc => '新會話轮流起步以摊平额度;同一會話內不换 Key,保持缓存命中';
  @override
  String get providerMultiKeyStatusCodes => '自动切换状态碼';
  @override
  String get providerMultiKeyStatusCodesHint => '逗號分隔,留空使用默認 401,402,403,429';
  @override
  String get providerMultiKeyCooldown => '冷却时長';
  @override
  String get providerMultiKeyCooldownDesc => '被切走的 Key 隔多久重新纳入候選';
  @override
  String get workspaceOpen => '工作區';
  @override
  String get workspaceLocal => '本地工作區';
  @override
  String get workspaceLocalSubtitle => '应用數据目錄';
  @override
  String get allow => '允许';
  @override
  String get deny => '拒绝';
  @override
  String get tabFiles => '文件';
  @override
  String get newFile => '新建文件';
  @override
  String get newFolder => '新建文件夾';
  @override
  String get create => '创建';
  @override
  String get deleteFileConfirm => '确定刪除该文件?';
  @override
  String get deleteFolderConfirm => '确定刪除该文件夾(含內容)?';
  @override
  String get refresh => '刷新';
  @override
  String get workspaceNew => '新建';
  @override
  String get workspaceEmptyHint => '还没有工作區,點右上角「新建」';
  @override
  String get workspaceNameExists => '同名工作區已存在';
  @override
  String get workspaceDelete => '刪除工作區';
  @override
  String workspaceDeleteConfirm(String name) {
    return '确定刪除工作區「$name」(含其中全部文件)?';
  }
  @override
  String get todoDashboardTitle => '任務待办';
  @override
  String todoDashboardProgress(int completed, int total) {
    return '$completed/$total 完成';
  }
  @override
  String get todoDashboardAllDone => '全部完成';
  @override
  String get todoInProgress => '進行中';
  @override
  String get todoCompleted => '已完成';
  @override
  String get gitTitle => 'Git';
  @override
  String get gitRefresh => '刷新';
  @override
  String get gitTabStatus => '状态';
  @override
  String get browserTitle => '浏览器';
  @override
  String get browserAddressHint => '输入網址或搜索';
  @override
  String get browserBack => '後退';
  @override
  String get browserForward => '前進';
  @override
  String get browserReload => '刷新';
  @override
  String get browserNotReady => '浏览器未就绪,请在地址栏输入網址開始浏览';
  @override
  String get browserNewTab => '新建標籤頁';
  @override
  String get browserCloseTab => '關閉標籤頁';
  @override
  String get browserTabDefaultTitle => '新標籤頁';
  @override
  String browserTabsCount(int count) {
    return '標籤頁 ($count)';
  }
  @override
  String get browserEmptyHint => '在上方地址栏输入網址開始浏览';
  @override
  String get browserTabsManage => '標籤頁管理';
  @override
  String get browserEmptyClickHint => '點击上方输入網址開始浏览';
  @override
  String get browserNightModeOn => '關閉夜間模式';
  @override
  String get browserNightModeOff => '開啟夜間模式';
  @override
  String get browserDevtools => '開髮者工具';
  @override
  String get browserDialogAlertTitle => '網頁提示';
  @override
  String get browserDialogConfirmTitle => '網頁确認';
  @override
  String get browserDialogPromptTitle => '網頁输入';
  @override
  String get browserMenu => '更多设置';
  @override
  String get browserMenuTitle => '浏览器设置與工具';
  @override
  String get browserMenuGeneralSection => '頁面與工具';
  @override
  String get browserNightModeTitle => '夜間模式';
  @override
  String get browserNightModeDesc => '降低頁面亮度并啟用深色偏好';
  @override
  String get browserDevtoolsTitle => '開髮者工具';
  @override
  String get browserDevtoolsDesc => '開啟移动端 Eruda 調試控制臺';
  @override
  String get browserUaSection => '浏览器標识 (User-Agent)';
  @override
  String get browserUaDesc => '模拟不同设备與环境访问網頁';
  @override
  String get browserUaDefault => '系统默認';
  @override
  String get browserUaDefaultDesc => '当前设备原生 WebView 標识';
  @override
  String get browserUaAndroidPhone => '安卓手機';
  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';
  @override
  String get browserUaAndroidTablet => '安卓平板';
  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';
  @override
  String get browserUaDesktopPc => '桌面電脑';
  @override
  String get browserUaDesktopPcDesc => 'Chrome Desktop (Windows PC)';
  @override
  String get browserUaIphone => '苹果 iPhone';
  @override
  String get browserUaIphoneDesc => 'Mobile Safari (iOS)';
  @override
  String get browserUaIpad => '苹果 iPad';
  @override
  String get browserUaIpadDesc => 'Tablet Safari (iPadOS)';
  @override
  String get browserUaCustom => '自定義';
  @override
  String get browserUaCustomDesc => '手动指定 User-Agent 字符串';
  @override
  String get browserUaCustomDialogTitle => '自定義 User-Agent';
  @override
  String get browserUaCustomInputHint => '输入完整的 User-Agent 字符串';
  @override
  String get browserUaAppliedToast => '已切换浏览器標识并刷新頁面';
  @override
  String get gitTabBranches => '分支';
  @override
  String get gitTabCommits => '提交';
  @override
  String get gitStatusClean => '工作區干净,無改动';
  @override
  String gitConflictedCount(int count) {
    return '存在冲突 ($count)';
  }
  @override
  String gitStagedCount(int count) {
    return '已暂存 ($count)';
  }
  @override
  String gitModifiedCount(int count) {
    return '已修改 ($count)';
  }
  @override
  String gitUntrackedCount(int count) {
    return '未跟踪 ($count)';
  }
  @override
  String get gitConflictedLabel => '存在冲突';
  @override
  String get gitStagedLabel => '已暂存';
  @override
  String get gitModifiedLabel => '已修改';
  @override
  String get gitUntrackedLabel => '未跟踪';
  @override
  String get gitStage => '暂存';
  @override
  String get gitUnstage => '取消暂存';
  @override
  String get gitStageAll => '暂存全部';
  @override
  String get gitUnstageAll => '全部取消暂存';
  @override
  String get gitUnstageAllConfirm => '将取消所有文件的暂存,但不會刪除文件內容。确定继续吗?';
  @override
  String get gitActionRevertAll => '全部回退';
  @override
  String gitRevertAllConfirm(int count) {
    return '丢弃全部未暂存的改动($count 个文件),还原到上次暂存或提交的內容?已暂存的內容不受影响,但丢弃的改动無法找回。';
  }
  @override
  String get gitActionRestoreFile => '恢复文件';
  @override
  String gitRevertConfirmWorktree(String name) {
    return '把 $name 还原成上次暂存或提交的內容?未暂存的改动會丢失,且無法找回。';
  }
  @override
  String gitRevertConfirmHead(String name) {
    return '把 $name 还原到上次提交的內容?该文件已暂存和未暂存的改动都會丢失,且無法找回。';
  }
  @override
  String gitRestoreFileConfirm(String name) {
    return '恢复已刪除的 $name?将從上次提交取回这个文件。';
  }
  @override
  String get gitActionDeleteFile => '刪除文件';
  @override
  String get gitActionDeleteDir => '刪除目錄';
  @override
  String get gitMergePendingTitle => '合并待提交';
  @override
  String get gitMergePendingHint => '当前没有未解决的冲突。请确認并暂存需要保留的改动,然後提交以完成合并。';
  @override
  String get gitActionAbortMerge => '中止合并';
  @override
  String get gitAbortMergeConfirm => '确定中止当前合并吗?未解决的冲突改动将被放弃,工作區将还原到合并前的状态。';
  @override
  String get gitCommitChanges => '提交更改';
  @override
  String get gitCommitNeedsIdentity => '尚未配置提交署名,请在「凭据與署名」頁填寫用户名和邮箱';
  @override
  String get gitCommitDialogTitle => '提交更改';
  @override
  String get gitCommitMessage => '提交信息';
  @override
  String get gitCommitAmend => '追加到上次提交 (--amend)';
  @override
  String get gitCommitAiGenerate => 'AI 生成';
  @override
  String get gitCommitGenerating => '正在生成…';
  @override
  String get gitActionCommit => '提交';
  @override
  String get gitTabStash => '储藏';
  @override
  String get gitStashTitle => '储藏箱';
  @override
  String get gitActionStash => '储藏改动';
  @override
  String get gitStashMessageHint => '储藏說明(可選)';
  @override
  String get gitStashIncludeUntracked => '包含未跟踪文件(-u)';
  @override
  String get gitStashEmpty => '暂無储藏记錄';
  @override
  String get gitStashPop => '弹出 (Pop)';
  @override
  String get gitStashApply => '应用 (Apply)';
  @override
  String get gitStashDrop => '丢弃 (Drop)';
  @override
  String gitStashDropConfirm(String index) {
    return '确定丢弃储藏 $index 吗?该操作不可撤销。';
  }
  @override
  String get gitStashClear => '清空全部';
  @override
  String get gitStashClearConfirm => '确定清空所有储藏记錄吗?该操作不可撤销。';
  @override
  String gitStashCount(int count) {
    return '储藏 ($count)';
  }
  @override
  String get gitPull => '拉取';
  @override
  String get gitPush => '推送';
  @override
  String get gitPullDirtyConfirm => '当前工作區有未提交改动,拉取可能导致冲突。建議先提交或暂存。仍要继续拉取吗?';
  @override
  String get gitPullContinue => '继续拉取';
  @override
  String get gitNoUpstream => '未设置上游';
  @override
  String gitTrackingBranch(String name) {
    return '跟踪 $name';
  }
  @override
  String gitAheadCount(int count) {
    return '待推送 $count';
  }
  @override
  String gitBehindCount(int count) {
    return '待拉取 $count';
  }
  @override
  String get gitBranchSynced => '已同步';
  @override
  String get gitDetachedHeadLabel => 'detached HEAD:当前不在任何分支上';
  @override
  String get gitNoBranch => '(無分支)';
  @override
  String get gitLoadingBranches => '正在加载分支列表…';
  @override
  String get gitNoCheckedOutBranch => '未检出分支';
  @override
  String get gitClean => '工作區干净';
  @override
  String get gitHasChanges => '工作區有改动';
  @override
  String get gitNotARepo => '当前工作區还不是 Git 仓库';
  @override
  String get gitCloningHint => '正在克隆仓库,请稍候…';
  @override
  String get gitInitDescPrimary => '可在此初始化新仓库,開始版本管理';
  @override
  String get gitInitDescSecondary => '若子目錄已有 Git 仓库,也可直接選择使用';
  @override
  String get gitInitRepo => '初始化新仓库';
  @override
  String get gitCloneRepo => '克隆远程仓库';
  @override
  String get gitCloneDialogTitle => '克隆 Git 仓库';
  @override
  String get gitCloneDesc => '将远程仓库克隆到当前工作區根目錄(工作區需为空)。若为私有仓库,可先點右上角鑰匙登錄 GitHub 或填入访问令牌。';
  @override
  String get gitCloneUrlLabel => '仓库地址';
  @override
  String get gitCloning => '正在克隆仓库,请稍候…';
  @override
  String get gitSwitchRepo => '切换仓库';
  @override
  String get gitPickExistingRepo => '選择已有仓库';
  @override
  String get gitRepoSelectorTitle => '選择仓库';
  @override
  String get gitRepoNotRepo => '非仓库';
  @override
  String get gitPickRepoEmpty => '当前工作區没有可選的目錄';
  @override
  String get gitNoBranches => '暂無分支';
  @override
  String get gitNewBranch => '新建分支';
  @override
  String get gitBranchName => '分支名';
  @override
  String get gitBaseBranch => '基准分支';
  @override
  String get gitCreateAndSwitch => '创建并切换';
  @override
  String get gitDeleteBranch => '刪除分支';
  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '刪除本地分支 $name?';
  }
  @override
  String get gitDeleteRemoteBranch => '刪除远程分支';
  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return '刪除远程分支 $name?该操作不可撤销。';
  }
  @override
  String get gitRenameBranch => '重命名分支';
  @override
  String gitRenameTo(String name) {
    return '将 $name 重命名为:';
  }
  @override
  String get gitNewBranchName => '新分支名';
  @override
  String get gitTags => '標籤';
  @override
  String get gitTagName => '標籤名';
  @override
  String get gitDeleteTag => '刪除標籤';
  @override
  String gitDeleteTagConfirm(String name) {
    return '刪除本地標籤 $name?';
  }
  @override
  String gitCreateTagDesc(String hash) {
    return '從当前 HEAD($hash)创建轻量標籤';
  }
  @override
  String get gitCheckedOut => '当前检出';
  @override
  String get gitCurrentBranch => '当前分支';
  @override
  String get gitRemote => '远程';
  @override
  String get commonLocal => '本地';
  @override
  String get gitNew => '新增';
  @override
  String get gitNoCommits => '暂無提交记錄';
  @override
  String gitCommitCount(int count) {
    return '提交记錄 ($count)';
  }
  @override
  String get gitSearchCommitsHint => '搜索提交說明或作者…';
  @override
  String get gitLoadMoreCommits => '上拉加载更早提交';
  @override
  String get gitNoMoreCommits => '没有更多了';
  @override
  String get gitLatestCommit => '最新提交';
  @override
  String gitFilesChanged(int count) {
    return '$count 个文件改动';
  }
  @override
  String get gitNoFilesChanged => '该提交無文件改动';
  @override
  String get gitMergeCommit => '合并提交';
  @override
  String get gitLoadingFiles => '正在加载改动文件…';
  @override
  String get gitCopyShortHash => '复制短哈希';
  @override
  String get gitCopyFullHash => '复制完整哈希';
  @override
  String get gitActionCreateBranch => '创建分支';
  @override
  String get gitActionCreateTag => '创建標籤';
  @override
  String get gitCreateBranchFromCommit => '基于此提交创建分支';
  @override
  String get gitCreateTagAtCommit => '在此提交创建標籤';
  @override
  String get gitResetToCommit => '重置到此提交 (Reset)';
  @override
  String get gitResetSoft => 'Soft(保留工作區與暂存區)';
  @override
  String get gitResetMixed => 'Mixed(保留工作區,清空暂存區)';
  @override
  String gitResetConfirm(String hash) {
    return '确定将当前分支重置到提交 $hash 吗?';
  }
  @override
  String get gitDiffBinary => '二進制文件,不显示差异';
  @override
  String get gitDiffTooLarge => '文件過大,未计算差异';
  @override
  String get gitDiffEmpty => '没有可显示的差异';
  @override
  String get gitCopyPath => '复制路徑';
  @override
  String get gitViewDiff => '查看差异';
  @override
  String get gitRevert => '回退改动';
  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return '刪除 $name?它從未被提交過,刪除後無法通過 Git 恢复。';
  }
  @override
  String get gitAddToGitignore => '添加到 .gitignore';
  @override
  String gitIgnoreFile(String name) {
    return '忽略此文件 ($name)';
  }
  @override
  String gitIgnoreDir(String name) {
    return '忽略整个目錄 ($name/)';
  }
  @override
  String gitIgnoreExtension(String ext) {
    return '忽略同类型文件 (*.$ext)';
  }
  @override
  String get gitPathCopied => '已复制路徑';
  @override
  String gitActionFailed(String action, String error) {
    return '$action失败:$error';
  }
  @override
  String gitActionDone(String action) {
    return '$action成功';
  }
  @override
  String gitCheckoutSuccess(String name) {
    return '已切换到 $name';
  }
  @override
  String get gitNoRemotePull => '未配置远程仓库,無法拉取';
  @override
  String get gitNoRemotePush => '未配置远程仓库,無法推送';
  @override
  String get gitPushMasterConfirmTitle => '分支命名建議';
  @override
  String get gitPushMasterConfirmDesc => '当前本地分支为 master,GitHub 與 GitLab 推荐使用 main 作为默認主分支。是否将本地分支重命名为 main 後再推送?';
  @override
  String get gitPushRenameToMain => '重命名为 main 并推送';
  @override
  String get gitPushKeepMaster => '保留 master 推送';
  @override
  String get gitTesting => '测試';
  @override
  String get credentialToken => '访问令牌(Token / PAT)';
  @override
  String get gitUserName => 'user.name';
  @override
  String get gitUserEmail => 'user.email';
  @override
  String get gitRepoUrl => '仓库地址';
  @override
  String get gitSelectBranch => '選择基准分支';
  @override
  String get credentialTokenLogin => '令牌登錄';
  @override
  String get credentialTokenLoginDesc => '只需粘贴访问令牌(PAT),推送时自动匹配远端主機';
  @override
  String get credentialTokenSaved => '令牌已保存';
  @override
  String get commonShow => '显示';
  @override
  String get commonHide => '隐藏';
  @override
  String get credentialAdd => '添加凭据';
  @override
  String get settingsSubtitle => '管理 AI、外观、同步和应用數据';
  @override
  String get accountAndData => '账户與數据';
  @override
  String get themeTitle => '主题';
  @override
  String get themeSubtitle => '外观、背景與显示';
  @override
  String get aboutSubtitle => '版本、更新與反馈';
  @override
  String get aboutAutoCheck => '自动检查更新';
  @override
  String get aboutAutoCheckDesc => '打開 App 时自动检测新版本';
  @override
  String get aboutUpdateChannel => '更新通道';
  @override
  String get aboutStableChannel => '稳定版';
  @override
  String get aboutDownloadMirror => '下载镜像源';
  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';
  @override
  String get githubRepo => 'GitHub 仓库';
  @override
  String get aboutUserAgreement => '用户协議';
  @override
  String get aboutPrivacyPolicy => '隐私政策';
  @override
  String get mcpTitle => 'MCP 服務器';
  @override
  String get mcpSubtitle => '接入外部工具的 Model Context Protocol 服務';
  @override
  String get mcpAdd => '添加 MCP';
  @override
  String get mcpEdit => '编辑 MCP';
  @override
  String get mcpEmpty => '还没有配置 MCP 服務器';
  @override
  String get mcpEmptyHint => '點击右上角 + 可以添加远程 HTTP 或本地 stdio 服務器';
  @override
  String get mcpSearchPlaceholder => '搜索 MCP 服務器…';
  @override
  String get mcpSearchEmpty => '未找到匹配的 MCP 服務器';
  @override
  String get mcpScopeLabel => '作用域';
  @override
  String get mcpScopeGlobal => '全局';
  @override
  String get mcpScopeProject => '項目';
  @override
  String get mcpTypeStdio => 'stdio';
  @override
  String get mcpStatusDisabled => '已禁用';
  @override
  String get mcpStatusNotConnected => '未连接';
  @override
  String get mcpStatusConnected => '已连接';
  @override
  String get mcpStatusConnecting => '连接中…';
  @override
  String get mcpStatusFailed => '连接失败';
  @override
  String get mcpStatusNeedsAuth => '需要登錄';
  @override
  String mcpToolsCount(int count) {
    return '$count 个工具';
  }
  @override
  String get mcpDetails => '详情';
  @override
  String get mcpBasicSettings => '基础设置';
  @override
  String get mcpEnabledLabel => '是否啟用';
  @override
  String get mcpNameLabel => '名稱';
  @override
  String get mcpNameHint => '例如:fetch、github、gitlab';
  @override
  String get mcpNameInvalid => '名稱只能包含字母、數字、下划線和连字符';
  @override
  String get mcpTransportType => '传输类型';
  @override
  String get mcpRemoteHttp => '远程 HTTP';
  @override
  String get mcpLocalStdio => '本地 stdio';
  @override
  String get mcpServerUrl => '服務器地址';
  @override
  String get mcpServerUrlHint => '例如:https://api.example.com/mcp';
  @override
  String get mcpCustomHeaders => '自定義请求头';
  @override
  String get mcpNoCustomHeaders => '暂無配置的自定義 Header';
  @override
  String get mcpHeaderName => '请求头名稱';
  @override
  String get mcpHeaderNameHint => '如 Authorization';
  @override
  String get mcpHeaderValue => '请求头值';
  @override
  String get mcpHeaderValueHint => '如 Bearer xxxxxx';
  @override
  String get mcpAddHeader => '添加请求头';
  @override
  String get mcpCommand => '啟动命令';
  @override
  String get mcpCommandHint => '例如:npx';
  @override
  String get mcpArgs => '命令参數';
  @override
  String get mcpNoArgs => '無额外命令行参數';
  @override
  String get mcpArgValue => '参數值';
  @override
  String get mcpArgHint => '如 -y 或 @modelcontextprotocol/server-xxx';
  @override
  String get mcpAddArg => '添加参數';
  @override
  String mcpToolsSummary(int enabled, int total) {
    return '已啟用 $enabled / $total 个工具';
  }
  @override
  String get mcpToolsSearch => '搜索工具名稱或描述…';
  @override
  String get mcpToolsSearchEmpty => '未找到匹配的工具';
  @override
  String get mcpToolsEnableAll => '全部啟用';
  @override
  String get mcpToolsDisableAll => '全部禁用';
  @override
  String get mcpSaveFirstHint => '请先保存并连接服務器後查看工具列表';
  @override
  String get mcpNoToolsHint => '未检测到工具,點击右上角刷新按钮重試';
  @override
  String get mcpNoDescription => '無描述';
  @override
  String get mcpAddSheetTitle => '添加 MCP 服務器';
  @override
  String get mcpAddManual => '手动填寫';
  @override
  String get mcpAddManualDesc => '逐个填寫地址、请求头或啟动命令';
  @override
  String get mcpAddFromJson => '從 JSON 导入';
  @override
  String get mcpAddFromJsonDesc => '粘贴標准 mcpServers 配置批量导入';
  @override
  String get mcpJsonImportTitle => '從 JSON 导入';
  @override
  String get mcpJsonImportHint => '粘贴標准 mcpServers 配置:键是服務器名,值裡填 url(远程 HTTP)或 command(本地 stdio)。';
  @override
  String get mcpJsonImportAction => '导入';
  @override
  String get mcpJsonImportEmpty => '未解析到任何 MCP 服務器';
  @override
  String get mcpSaved => '已保存';
  @override
  String get mcpRefreshTools => '刷新工具';
  @override
  String get mcpRemoved => '已移除 MCP 服務器';
  @override
  String get permissionsTitle => '工具授权';
  @override
  String get permissionsSubtitle => '规则與记忆';
  @override
  String permCurrentProject(String name) {
    return '当前項目:$name';
  }
  @override
  String get permCurrentProjectNone => '当前項目(未選择)';
  @override
  String get permNoProjectRules => '本項目暂無规则';
  @override
  String get permGlobal => '全局';
  @override
  String get permNoGlobalRules => '暂無全局规则';
  @override
  String get permEntireTool => '整个工具';
  @override
  String get permDeny => '禁止';
  @override
  String get permPromoteToGlobal => '提升为全局';
  @override
  String get permRulesShort => '对話中選「始终运行」會在当前項目生成记忆规则';
  @override
  String get chatPermDeny => '拒绝';
  @override
  String get chatPermAlwaysAllow => '始终运行';
  @override
  String get chatPermAlwaysToolDesc => '「始终运行」将在本項目记住:该工具的全部調用';
  @override
  String get chatPermAlwaysPrefix => '「始终运行」将在本項目记住:';
  @override
  String get chatPermSingleUseDesc => '该調用不可记忆,仅可单次放行';
  @override
  String get commonName => '名稱';
  @override
  String get commonTool => '工具';
  @override
  String get commonAdd => '添加';
  @override
  String commonLabelWithApi(String label, String api) {
    return '$label($api)';
  }
  @override
  String get commonExpand => '展開';
  @override
  String get commonCollapse => '收起';
  @override
  String get mcpViewLogs => '查看此 MCP 日誌';
  @override
  String get mcpAuthEnable => 'OAuth 認證';
  @override
  String get mcpAuthDesc => '用于需要浏览器登錄授权的远程 MCP 服務';
  @override
  String get mcpAuthClientId => 'client_id(可選)';
  @override
  String get mcpAuthClientIdHint => '预注册的客户端 ID;留空则尝試动态注册';
  @override
  String get mcpAuthServer => '授权服務器(可選)';
  @override
  String get mcpAuthServerHint => '覆盖自动髮现的授权服務器地址';
  @override
  String get mcpAuthAdvanced => '高級認證選項';
  @override
  String get mcpAuthLogin => '登錄 / 重新授权';
  @override
  String get mcpAuthReauthorize => '重新授权';
  @override
  String get mcpAuthLogout => '退出登錄';
  @override
  String get mcpAuthCancel => '取消授权';
  @override
  String get mcpAuthInProgress => '等待浏览器授权…';
  @override
  String get mcpAuthInProgressHint => '已在系统浏览器打開登錄頁,授权完成後将自动返回并连接';
  @override
  String get mcpAuthSaveFirst => '保存服務器配置後,即可在此髮起登錄授权';
  @override
  String mcpAuthFailed(String message) {
    return '授权失败:$message';
  }
  @override
  String get mcpAuthStatusLabel => '授权状态';
  @override
  String get mcpAuthStatusAuthorized => '已登錄';
  @override
  String get mcpAuthStatusUnauthorized => '未登錄';
  @override
  String get mcpAuthStatusAuthorizing => '授权中';
  @override
  String get mcpAuthSuccess => '授权成功,已连接';
  @override
  String get settingsReconnect => '重新连接';
  @override
  String get settingsAddMcpServer => '添加 MCP 服務器';
  @override
  String get settingsContainer => '容器與镜像';
  @override
  String get settingsContainerSubtitle => 'PRoot 容器、镜像與初始化';
  @override
  String get commonEdit => '编辑';
  @override
  String get commonSwitch => '切换';
  @override
  String get chatOpenTerminal => '打開终端';
  @override
  String get terminalTitle => '终端';
  @override
  String terminalStartFailed(String message) {
    return '無法啟动终端:';
  }
  @override
  String get terminalRetry => '重試';
  @override
  String get terminalNoOpenTabs => '没有打開的终端標籤';
  @override
  String get terminalNewTab => '新建標籤';
  @override
  String get terminalCloseTab => '關閉標籤';
  @override
  String get terminalSettingsTitle => '终端设置';
  @override
  String get terminalThemeTitle => '配色主题';
  @override
  String get terminalThemeFollowApp => '跟随应用';
  @override
  String get terminalThemeTermiusDark => 'Termius Dark';
  @override
  String get terminalThemeGithubLight => 'GitHub Light';
  @override
  String get terminalThemeDracula => 'Dracula';
  @override
  String get terminalThemeOneDark => 'One Dark';
  @override
  String get terminalThemeMonokai => 'Monokai';
  @override
  String get terminalThemeGithubDark => 'GitHub Dark';
  @override
  String get terminalFontSizeTitle => '字體大小';
  @override
  String get terminalCursorStyleTitle => '光標样式';
  @override
  String get terminalCursorBlock => '方块';
  @override
  String get terminalCursorUnderline => '下划線';
  @override
  String get terminalCursorBar => '竖線';
  @override
  String get terminalFontTitle => '终端字體';
  @override
  String get terminalFontDefault => '系统等宽';
  @override
  String get terminalFontBuiltin => 'JetBrains Mono';
  @override
  String get settingsGeneral => '偏好设置';
  @override
  String get settingsGeneralModels => '模型';
  @override
  String get settingsAutoRemoveStaleModels => '拉取模型後自动移除無效模型';
  @override
  String get settingsAutoRemoveStaleModelsDesc => '拉取成功後,移除远端已不存在的本地模型條目';
  @override
  String get settingsGeneralSession => '會話';
  @override
  String get settingsStartupSession => '啟动时會話';
  @override
  String get settingsStartupSessionNew => '新開會話';
  @override
  String get settingsStartupSessionNewDesc => '复用尚未髮送過消息的空會話,否则新建';
  @override
  String get settingsStartupSessionRecent => '打開最近會話';
  @override
  String get settingsStartupSessionRecentDesc => '直接進入最近更新的會話';
  @override
  String get settingsDeleteExternalWorkspaceSessions => '刪除外部工作區聊天记錄';
  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc => '移除外部本地工作區时,一并刪除该工作區的聊天记錄';
  @override
  String get settingsGeneralInput => '输入';
  @override
  String get settingsEnterToSend => '回车键髮送消息';
  @override
  String get settingsEnterToSendDesc => '關閉後回车换行,需點髮送按钮髮送';
  @override
  String get settingsCompactionThreshold => '自动压缩阈值';
  @override
  String get settingsCompactionThresholdDesc => '上下文占用达到窗口的该比例时自动压缩';
  @override
  String get settingsCompactionThresholdInputHint => '填 1-100 的整數百分比';
  @override
  String settingsPercentValue(int percent) {
    return '$percent%';
  }
  @override
  String get settingsGeneralNetwork => '網絡';
  @override
  String get settingsFirstByteTimeout => '首字节超时';
  @override
  String get settingsFirstByteTimeoutDesc => '等待首个响应块的最長时間';
  @override
  String get settingsStreamIdleTimeout => '數据块間隔超时';
  @override
  String get settingsStreamIdleTimeoutDesc => '两个响应块之間的最長等待';
  @override
  String get settingsTimeoutUnlimited => '不限制';
  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds 秒';
  }
  @override
  String get settingsTimeoutInputHint => '单位秒,填 0 表示不限制';
  @override
  String get settingsMaxNetworkRetries => '重試次數';
  @override
  String get settingsMaxNetworkRetriesDesc => '網絡失败後的指數退避重試次數';
  @override
  String settingsRetriesCount(int count) {
    return '$count 次';
  }
  @override
  String get settingsRetriesInputHint => '填 0 表示不重試';
  @override
  String get settingsGeneralTools => '工具';
  @override
  String get settingsSendfileMaxSize => 'sendFile 单文件上限';
  @override
  String get settingsGeneralGoal => '目標(goal)';
  @override
  String get settingsGoalMaxTurns => '最大续跑轮數';
  @override
  String get settingsGoalMaxTurnsDesc => '自主循环最多续跑多少轮,达到即停止';
  @override
  String get settingsGoalMaxTokens => 'token 预算';
  @override
  String get settingsGoalMaxTokensDesc => '自主循环累计消耗的输入+输出 token 上限';
  @override
  String settingsTurnsValue(int count) {
    return '$count 轮';
  }
  @override
  String settingsTokensValue(int count) {
    return '$count';
  }
  @override
  String get settingsGoalMaxTurnsInputHint => '填大于 0 的整數轮數';
  @override
  String get settingsGoalMaxTokensInputHint => '填不小于 1000 的整數';
  @override
  String get settingsSendfileMaxSizeDesc => '单个文件大小上限,超過则整批髮送失败';
  @override
  String get settingsSendfileMaxSizeInputHint => '单位 MB,填大于 0 的整數';
  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }
  @override
  String providerModelsAlignedRemoved(int count) {
    return '已移除 $count 个远端已不存在的模型';
  }
  @override
  String get tokenStatsTitle => 'Token 统计';
  @override
  String get tokenStatsPeriodToday => '今天';
  @override
  String get tokenStatsPeriod7d => '近7天';
  @override
  String get tokenStatsPeriod30d => '近30天';
  @override
  String get tokenStatsPeriodAll => '全部';
  @override
  String get tokenStatsTotal => '總消耗';
  @override
  String get tokenStatsRequests => '请求次數';
  @override
  String get tokenStatsCost => '费用';
  @override
  String get tokenStatsCacheHitRate => '缓存命中率';
  @override
  String tokenStatsCacheReadWrite(String read, String write) {
    return '讀取 $read / 寫入 $write';
  }
  @override
  String get tokenStatsTrend => '消耗趋势';
  @override
  String get tokenStatsLegendInput => '输入';
  @override
  String get tokenStatsLegendOutput => '输出';
  @override
  String get tokenStatsLegendCached => '缓存';
  @override
  String get tokenStatsProvider => '供应商统计';
  @override
  String get tokenStatsModel => '模型统计';
  @override
  String tokenStatsSuccessRate(String rate) {
    return '成功率 $rate';
  }
  @override
  String get tokenStatsRecentCalls => '調用记錄';
  @override
  String get tokenStatsUnknown => '未知';
  @override
  String get tokenStatsNoData => '暂無數据';
  @override
  String get tokenStatsCallsSuffix => '次調用';
  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count 次調用';
  }
  @override
  String get tokenStatsColModel => '模型';
  @override
  String get tokenStatsColReasoningEffort => '思考强度';
  @override
  String get tokenStatsColProvider => '供应商';
  @override
  String get tokenStatsColInput => '输入';
  @override
  String get tokenStatsColOutput => '输出';
  @override
  String get tokenStatsColCachedRead => '缓存讀取';
  @override
  String get tokenStatsColCachedWrite => '缓存寫入';
  @override
  String get tokenStatsColCacheHitRate => '命中率';
  @override
  String get tokenStatsColTtfb => '首字节';
  @override
  String get tokenStatsColDuration => '耗时';
  @override
  String get tokenStatsColTime => '时間';
  @override
  String get tokenStatsColStatus => '状态';
  @override
  String get tokenStatsColCost => '费用';
  @override
  String tokenStatsPage(int page, int total) {
    return '第 $page / $total 頁';
  }
  @override
  String tokenStatsRetries(int count) {
    return '重試 $count 次';
  }
  @override
  String get tokenStatsReset => '重置';
  @override
  String get tokenStatsResetTitle => '重置 Token 统计';
  @override
  String get tokenStatsResetConfirm => '将清空全部調用记錄,此操作不可恢复。确定重置?';
  @override
  String get tokenStatsFilterAllProviders => '全部供应商';
  @override
  String get tokenStatsFilterAllModels => '全部模型';
  @override
  String get tokenStatsFilterClear => '清除篩選';
  @override
  String tokenStatsFilterProvider(String name) {
    return '供应商:$name';
  }
  @override
  String tokenStatsFilterModel(String name) {
    return '模型:$name';
  }
  @override
  String tokenStatsProviderKeys(int count) {
    return '$count 个密鑰';
  }
  @override
  String get tokenStatsRequestsUnit => '次请求';
  @override
  String get tokenStatsHourSuffix => '时';
  @override
  String get tokenStatsPrevPage => '上一頁';
  @override
  String get tokenStatsNextPage => '下一頁';
  @override
  String get settingsCategoryData => '數据與诊断';
  @override
  String get gitActionClone => '克隆';
  @override
  String get gitActionInit => '初始化';
  @override
  String get gitActionMerge => '合并分支';
  @override
  String get gitActionStageAll => '全部暂存';
  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';
  @override
  String get gitComputingDiff => '正在计算差异…';
  @override
  String get gitCreateTagTitle => '新建標籤';
  @override
  String gitCreateTrackingBranch(String branch) {
    return '從远程分支 $branch 创建本地跟踪分支并切换?';
  }
  @override
  String get gitCredentialsAndIdentity => '凭据與署名';
  @override
  String gitDetachedHeadWarning(String ref) {
    return '切换到標籤 $ref 将進入 detached HEAD 状态——不处于任何分支上,新提交不属于任何分支。确定继续?';
  }
  @override
  String gitMergeConfirm(String branch, String current) {
    return '确定将分支 $branch 合并到当前分支($current)吗?';
  }
  @override
  String get gitMergeNoFf => '创建合并提交(--no-ff)';
  @override
  String get gitOpenInEditor => '在编辑器中打開';
  @override
  String get gitSwitchBranch => '切换分支';
  @override
  String gitSwitchConfirm(String ref) {
    return '确定切换到 $ref?';
  }
  @override
  String gitToastLoadBranchesFailed(String error) {
    return '加载分支失败:$error';
  }
  @override
  String gitToastRefreshFailed(String error) {
    return '刷新失败:$error';
  }
  @override
  String gitToastActionRefreshFailed(String message) {
    return '$message(刷新失败)';
  }
  @override
  String gitToastLoadMoreFailed(String error) {
    return '加载更多失败:$error';
  }
  @override
  String gitToastCheckoutFailed(String error) {
    return '切换失败:$error';
  }
  @override
  String get gitToastNotRepo => '该目錄不是 Git 仓库';
  @override
  String gitToastSwitchRepoFailed(String error) {
    return '切换仓库失败:$error';
  }
  @override
  String get gitToastDiffFailed => '加载差异失败';
  @override
  String get gitToastNoDiffForCommit => '暂存區與工作區均無差异,無法生成提交信息';
  @override
  String get gitToastGenerateCommitFailed => 'AI 生成提交信息失败,请检查模型或網絡';
  @override
  String get diffBinaryFile => '二進制文件,不支持文本差异对比';
  @override
  String get diffFileTooLarge => '文件過大,已跳過差异计算';
  @override
  String get diffFileTooLargeDesc => '超過 2000 行或含超長行的文件不做行級 diff,以避免渲染與內存压力。';
  @override
  String get diffNoChanges => '無差异';
  @override
  String get back => '返回';
  @override
  String get chatOpenGit => '打開 Git';
  @override
  String get switchLabel => '切换';
  @override
  String get credentialEdit => '编辑凭据';
  @override
  String get credentialToastSaved => '凭据已保存';
  @override
  String credentialToastSaveFailed(String param1) {
    return '保存失败:%1$s';
  }
  @override
  String get credentialToastDeleted => '凭据已刪除';
  @override
  String get credentialToastIdentitySaved => '署名與仓库地址已保存';
  @override
  String get credentialEmptyHint => '尚未添加凭据,點右上角 + 添加';
  @override
  String get credentialEmptyTitle => '暂無 Git 凭据';
  @override
  String get credentialEmptyDesc => '配置凭据後,Codecraft 可在推送或拉取代碼仓库时自动完成身份認證';
  @override
  String get credentialAddManual => '手动添加';
  @override
  String get gitTabIdentity => '署名';
  @override
  String get gitTabCredentials => '凭据';
  @override
  String get gitIdentityTitle => '提交署名';
  @override
  String gitIdentityCodespace(String name) {
    return '当前连接 GitHub Codespace $name';
  }
  @override
  String get gitRepoUrlTitle => '仓库地址';
  @override
  String get gitRemoteUrl => 'remote.origin.url';
  @override
  String gitCredentialsCount(int param1) {
    return '凭据 ($param1)';
  }
  @override
  String get codespacesTitle => 'GitHub Codespaces';
  @override
  String codespacesNetworkError(String error) {
    return '網絡錯誤:$error';
  }
  @override
  String get codespacesAccount => '账號';
  @override
  String codespacesCount(int count) {
    return 'Codespaces ($count)';
  }
  @override
  String get codespacesEmptyTitle => '还没有 Codespace';
  @override
  String get codespacesEmptyDesc => '在 GitHub 上创建 Codespace 後,这裡即可列出并连接';
  @override
  String get codespacesCreateOnWeb => '在 github.com 新建';
  @override
  String get codespacesRefresh => '刷新';
  @override
  String get codespacesOpenInBrowser => '在浏览器打開';
  @override
  String get codespacesStart => '啟动';
  @override
  String get codespacesStop => '停止';
  @override
  String get codespacesDelete => '刪除';
  @override
  String codespacesDeleteConfirm(String name) {
    return '确定刪除 $name?该操作不可撤销';
  }
  @override
  String get codespacesStateAvailable => '运行中';
  @override
  String get codespacesStateStarting => '啟动中';
  @override
  String get codespacesStateStopped => '已停止';
  @override
  String get codespacesStateUnknown => '状态未知';
  @override
  String codespacesLastUsed(String time) {
    return '最近使用 $time';
  }
  @override
  String get codespacesNoRepo => '未知仓库';
  @override
  String get codespacesUncommitted => '有未提交改动';
  @override
  String get codespacesMoreActions => '更多操作';
  @override
  String get editorLoadFailed => '無法讀取该文件';
  @override
  String get editorSaveFailed => '保存失败';
  @override
  String get editorSaved => '已保存';
  @override
  String get editorCharacters => '角色';
  @override
  String get characterTitle => '角色管理';
  @override
  String get characterNew => '新建角色';
  @override
  String get characterEdit => '编辑角色';
  @override
  String get characterEmpty => '暂無角色';
  @override
  String get characterSearchHint => '搜索角色名稱、別名或標籤';
  @override
  String get characterSearchEmpty => '未找到匹配角色';
  @override
  String get characterFieldBasic => '基本信息';
  @override
  String get characterFieldName => '姓名';
  @override
  String get characterFieldNameHint => '角色的真實姓名';
  @override
  String get characterFieldAlias => '別名/稱呼';
  @override
  String get characterFieldAliasHint => '故事中常用的稱呼(如:老張、小李)';
  @override
  String get characterFieldGender => '性別';
  @override
  String get characterFieldGenderHint => '男/女/其他';
  @override
  String get characterFieldAge => '年齡';
  @override
  String get characterFieldAgeHint => '數字,如 25';
  @override
  String get characterFieldBirthday => '生日';
  @override
  String get characterFieldBirthdayHint => '格式:MM-DD,如 01-15';
  @override
  String get characterFieldAppearance => '外貌描寫';
  @override
  String get characterFieldAppearanceHint => '身高、體型、髮色、瞳色、特征等';
  @override
  String get characterFieldPersonality => '性格';
  @override
  String get characterFieldPersonalityHint => '性格特點、行为模式、說話風格等';
  @override
  String get characterFieldBackground => '背景故事';
  @override
  String get characterFieldBackgroundHint => '成長經歷、重要事件、家庭背景等';
  @override
  String get characterFieldGoals => '目標/願望';
  @override
  String get characterFieldGoalsHint => '角色想要达成的事、追求的東西';
  @override
  String get characterFieldFears => '恐懼/弱點';
  @override
  String get characterFieldFearsHint => '害怕的事、心理陰影、致命弱點等';
  @override
  String get characterFieldTags => '標籤';
  @override
  String get characterFieldTagsHint => '用逗號分隔,如:主角、反派、魔法師';
  @override
  String get characterScope => '作用域';
  @override
  String get characterScopeProject => '当前項目';
  @override
  String get characterScopeGlobal => '全局';
  @override
  String characterSelectedCount(int count) {
    return '已選 $count 項';
  }
  @override
  String get editorUndo => '撤销';
  @override
  String get editorRedo => '重做';
  @override
  String get editorSearch => '搜索';
  @override
  String get editorSearchHint => '查找內容';
  @override
  String get editorSearchPrev => '上一个';
  @override
  String get editorSearchNext => '下一个';
  @override
  String get editorTypeset => '自动排版';
  @override
  String get editorTypesetDone => '已排版,可撤销';
  @override
  String get editorCopy => '复制';
  @override
  String get editorCopied => '已复制到剪贴板';
  @override
  String get editorUnsavedState => '未保存';
  @override
  String editorWordCount(int count) {
    return '$count 字';
  }
  @override
  String get editorNoFile => '还没有打開的文件,從差异頁點「在编辑器中打開」即可';
  @override
  String get editorUnsavedTitle => '未保存的修改';
  @override
  String get editorUnsavedMessage => '当前文件有未保存的修改,是否保存?';
  @override
  String get editorSaveAndExit => '保存并退出';
  @override
  String get editorSaveAndSwitch => '保存并切换';
  @override
  String get editorDontSave => '不保存';
  @override
  String get editorMdPreview => '预览 Markdown';
  @override
  String get editorMdShowSource => '显示源碼';
  @override
  String get editorIndent => '缩進';
  @override
  String get editorCursorLeft => '光標左移';
  @override
  String get editorCursorRight => '光標右移';
  @override
  String get editorSettings => '编辑器设置';
  @override
  String get editorFontSize => '字體大小';
  @override
  String editorFontSizeValue(int size) {
    return '$size sp';
  }
  @override
  String get editorWordWrap => '自动换行';
  @override
  String get editorShowIndentGuide => '显示缩進参考線';
  @override
  String get editorShowWhitespace => '显示空白符號';
  @override
  String editorFileTooLarge(int mb) {
    return '文件過大($mb MB),暂不支持打開';
  }
  @override
  String get editorBinaryUnsupported => '二進制文件,暂不支持打開';
  @override
  String get editorSaveConflictTitle => '文件已被修改';
  @override
  String get editorSaveConflictMessage => '该文件在你打開之後已被 AI 或其他程序修改。直接保存會覆盖对方的改动。';
  @override
  String editorSaveConflictDiff(String diff) {
    return '- 磁盘当前內容';
  }
  @override
  String get editorSaveConflictOverwrite => '覆盖磁盘';
  @override
  String get editorSaveConflictDiscard => '放弃我的修改';
  @override
  String get editorSaveConflictCancel => '取消';
  @override
  String get editorSaveConflictDiscarded => '已放弃修改并重新载入磁盘內容';
  @override
  String editorLineColumn(int line, int column) {
    return '$line:$column';
  }
  @override
  String get codespacesConnect => '连接';
  @override
  String get codespacesDisconnect => '断開';
  @override
  String get codespacesGhMissing => '容器裡还没有 gh(GitHub CLI)。请先在终端执行命令 codecraft,選择「GitHub Codespaces」场景安装依赖。';
  @override
  String get codespacesExecutionEnv => '执行环境';
  @override
  String get codespacesEnvLocal => '本地容器';
  @override
  String get codespacesEnvCodespace => '远程 Codespace';
  @override
  String terminalRemoteEnv(String name) {
    return '远程环境:$name';
  }
  @override
  String get codespacesNew => '新建 Codespace';
  @override
  String get codespacesRepoTab => '仓库';
  @override
  String get codespacesRepoSearchHint => '搜索仓库';
  @override
  String get codespacesBranch => '分支(留空用默認分支)';
  @override
  String get codespacesMachine => '機器规格';
  @override
  String get codespacesMachineDefault => '默認规格';
  @override
  String get codespacesCreate => '创建';
  @override
  String get codespacesRename => '重命名';
  @override
  String get codespacesRenameTitle => 'Codespace 显示名';
  @override
  String get codespacesChangeMachine => '更改機型';
  @override
  String get codespacesNoMachines => '该仓库没有可選機型';
  @override
  String get codespacesLoadFailed => '加载失败';
  @override
  String get codespacesPorts => '端口';
  @override
  String get codespacesPortsEmpty => '该 Codespace 还没有转髮的端口';
  @override
  String get codespacesPortVisibility => '可见性';
  @override
  String get codespacesPortPrivate => '仅自己';
  @override
  String get codespacesPortOrg => '组织內';
  @override
  String get codespacesPortPublic => '公開';
  @override
  String get codespacesPortOpen => '打開';
  @override
  String get codespacesRebuild => '重建容器';
  @override
  String get codespacesRebuildDesc => '重建會按当前 devcontainer 重新创建容器:代碼與未提交改动保留,容器內已安装的工具與运行状态會丢失。';
  @override
  String get codespacesRebuildFull => '完全重建(同时清除缓存的 Docker 镜像,更慢)';
  @override
  String get settingsLog => '日誌';
  @override
  String get settingsLogSubtitle => '应用运行日誌與 AI 请求日誌';
  @override
  String get logFiles => '日誌文件';
  @override
  String get logNoFiles => '还没有日誌文件';
  @override
  String logReadFailed(String error) {
    return '讀取日誌失败:$error';
  }
  @override
  String get logSearchHint => '搜索日誌';
  @override
  String get logNoMatch => '当前篩選條件下没有日誌';
  @override
  String get logLevel => '日誌等級';
  @override
  String get logLevelDesc => '记錄低于该等級的日誌将被忽略。開髮期建議 VERBOSE(全部记錄);NONE 關閉日誌。';
  @override
  String get logCopied => '已复制';
  @override
  String logMcpPrefix(String server) {
    return 'MCP 日誌:$server';
  }
  @override
  String logSearchResults(int count) {
    return '匹配 $count 行';
  }
  @override
  String logShowLastLines(int shown, int total) {
    return '显示最後 $shown/$total 行';
  }
  @override
  String logShowLines(int count) {
    return '显示 $count 行';
  }
  @override
  String get logCopy => '复制';
  @override
  String get logClearFilter => '清除篩選';
  @override
  String get logCopyMenuTitle => '复制日誌';
  @override
  String get logCopyLine => '复制本條日誌';
  @override
  String get logCopyWithStack => '复制本條及堆栈';
  @override
  String get logCopyMessage => '复制消息內容';
  @override
  String get logFollowLatest => '實时滚动';
  @override
  String get logFileLocation => '日誌文件位于 Android/data/<包名>/files/logs/。';
  @override
  String get logLevelVerbose => '详細';
  @override
  String get logLevelDebug => '調試';
  @override
  String get logLevelInfo => '信息';
  @override
  String get logLevelWarn => '警告';
  @override
  String get logLevelError => '錯誤';
  @override
  String get logLevelNone => '關閉';
  @override
  String get credentialTokenHint => '建議用带 codespace 作用域的 GitHub 令牌,填一次同时供 Git 推送與 Codespaces 登錄使用';
  @override
  String get credentialHostOptional => '主機(可選)';
  @override
  String get credentialHostAny => '留空 = 所有主機';
  @override
  String get credentialHostHint => '只在需要给特定主機单独配令牌时才填,例如 gitlab.com';
  @override
  String get codespacesNeedCredentialTitle => '尚未配置 GitHub 凭据';
  @override
  String get codespacesNeedCredentialDesc => 'Codespaces 使用「Git 凭据」裡的令牌(需含 codespace 作用域),不再单独填寫。';
  @override
  String get codespacesGoToCredentials => '去填寫 Git 凭据';
  @override
  String get credentialAllHosts => '所有主機';
  @override
  String get credentialUsernameAuto => '用户名自动推导';
  @override
  String get chatMentionSkill => '@ 技能';
  @override
  String get chatMentionSkillEmpty => '还没有可用的技能,先在设置裡导入或新建一个。';
  @override
  String get chatMentionSkillManage => '管理技能';
  @override
  String get chatPickFile => '# 文件';
  @override
  String get chatPickFileParent => '上一級';
  @override
  String get chatPickFileEmpty => '这个目錄是空的';
  @override
  String get mentionHintSkill => '继续输入可篩選技能';
  @override
  String get mentionHintFile => '继续输入可篩選文件';
  @override
  String get fileBrowserError => '讀取目錄失败';
  @override
  String get fileBrowserRefresh => '刷新';
  @override
  String get fileBrowserExpand => '展開';
  @override
  String get fileBrowserCollapse => '折叠';
  @override
  String get fileBrowserNewFile => '新建文件';
  @override
  String get fileBrowserNewFolder => '新建文件夾';
  @override
  String get fileBrowserNameLabel => '名稱';
  @override
  String fileBrowserDeleteFileConfirm(String name) {
    return '确定刪除文件「$name」?';
  }
  @override
  String fileBrowserDeleteFolderConfirm(String name) {
    return '确定刪除文件夾「$name」及其全部內容?';
  }
  @override
  String get fileBrowserCreateFailed => '创建失败,可能已存在同名項或無寫入权限';
  @override
  String get fileBrowserRenameFailed => '重命名失败,可能已存在同名項';
  @override
  String get fileBrowserDeleteFailed => '刪除失败';
  @override
  String get fileBrowserPasteHere => '粘贴到此处';
  @override
  String get fileBrowserExtract => '解压';
  @override
  String get fileBrowserExtractFailed => '解压失败';
  @override
  String get fileBrowserExtractConflictTitle => '目標文件夾已存在';
  @override
  String fileBrowserExtractConflict(String name) {
    return '同目錄下已有「$name」,解压會先覆盖它的內容。';
  }
  @override
  String get fileBrowserExtractOverwrite => '覆盖并解压';
  @override
  String get fileBrowserPasteConflictTitle => '同名文件已存在';
  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '目標位置已存在同名項目「$name」,是否覆盖?';
  }
  @override
  String get fileBrowserClipboardCut => '已剪切';
  @override
  String get fileBrowserClipboardCopy => '已复制';
  @override
  String get commonCopy => '复制';
  @override
  String get commonCut => '剪切';
  @override
  String get commonPaste => '粘贴';
  @override
  String get workspacePickWritingFolder => '寫作目錄';
  @override
  String get writingFolderNeedAccessTitle => '需要存储访问权限';
  @override
  String get writingFolderNeedAccessDesc => '讀取手機裡的「AI寫作」目錄需要「所有文件访问权限」。也可以跳過,直接在下一步選择目錄。';
  @override
  String get writingFolderGrant => '去授权';
  @override
  String writingFolderSet(String path) {
    return '寫作目錄已设为 $path';
  }
  @override
  String get modelAuto => 'Auto Model';
  @override
  String get modelAutoDesc => '按任務自动選择最合适的模型';
  @override
  String get sessionExport => '导出會話';
  @override
  String sessionExportDone(String path) {
    return '已导出到 $path';
  }
  @override
  String get sessionExportFailed => '导出失败';
  @override
  String get sessionBatchSelect => '批量選择';
  @override
  String sessionSelectedCount(String count) {
    return '已選 $count 項';
  }
  @override
  String get sessionSelectAll => '全選';
  @override
  String get sessionCancelSelect => '取消';
  @override
  String get sessionDeleteSelected => '刪除所選';
  @override
  String get sessionDeleteConfirm => '刪除该會話及其全部消息?';
  @override
  String get fileBrowserNeedPermission => '無法讀取该文件夾,可能需要存储访问权限';
  @override
  String get checkpointRewindTitle => '回退到此处';
  @override
  String checkpointTargetPrompt(String snippet) {
    return '目標:$snippet';
  }
  @override
  String get checkpointRestoreCodeAndConversation => '还原代碼與會話';
  @override
  String get checkpointRestoreCodeAndConversationDesc => '回滚工作區文件,并刪除这之後的所有消息,提问會回填到输入框';
  @override
  String get checkpointRestoreConversation => '只还原會話';
  @override
  String get checkpointRestoreConversationDesc => '刪除这之後的所有消息,工作區文件保持不变';
  @override
  String get checkpointRestoreCode => '只还原代碼';
  @override
  String get checkpointRestoreCodeDesc => '回滚工作區文件,对話记錄保持不变';
  @override
  String checkpointRewindSkipped(int count) {
    return '$count 个文件因存在其他改动已跳過';
  }
  @override
  String get chatMoreOptions => '更多選項';
  @override
  String get chatActionEdit => '编辑';
  @override
  String get chatActionDelete => '刪除';
  @override
  String get chatEditMessageTitle => '编辑消息';
  @override
  String get commonConfirm => '确定';
  @override
  String get commonCancel => '取消';
  @override
  String get commonSave => '保存';
  @override
  String get commonClose => '關閉';
  @override
  String get commonBatchDelete => '批量刪除';
  @override
  String get tabProjects => '項目';
  @override
  String get projectListEmpty => '还没有項目';
  @override
  String get workspaceCurrent => '当前';
  @override
  String get workspaceNameHint => '項目名稱';
  @override
  String get projectNew => '新建項目';
  @override
  String get projectUntitled => '未命名項目';
  @override
  String get projectKindCoding => '编程';
  @override
  String get projectKindCodingDesc => '在沙盒工作區裡寫代碼、跑命令、改文件';
  @override
  String get projectKindWriting => '寫作';
  @override
  String get projectKindWritingDesc => '在「AI寫作」目錄裡撰寫與修改文稿';
  @override
  String get projectKindReverse => '应用逆向';
  @override
  String get projectKindReverseDesc => '分析 APK、抓包接口、静态逆向與調試辅助';
  @override
  String projectDeleteConfirm(String name) {
    return '确定刪除項目「$name」?其下所有會話都會一并刪除。';
  }
  @override
  String get installedAppsTitle => '選择应用';
  @override
  String get installedAppsSearch => '搜索应用名或包名';
  @override
  String get installedAppsEmpty => '没有匹配的应用';
  @override
  String get storagePermissionGrant => '去授权';
  @override
  String get softwarePermissionsTitle => '軟件权限';
  @override
  String get softwarePermissionsSubtitle => '點任一項由系统弹出授权,或跳到对应的系统设置頁。';
  @override
  String get systemPermissionsGroup => '系统权限';
  @override
  String get permissionStorageTitle => '访问存储空間';
  @override
  String get permissionBatteryTitle => '忽略電池优化';
  @override
  String get permissionBatteryDesc => '允许後臺持续运行,减少被杀';
  @override
  String get permissionAutoStartTitle => '自啟动管理';
  @override
  String get permissionAutoStartDesc => '允许系统在後臺自动拉起应用';
  @override
  String get permissionShizukuTitle => 'Shizuku';
  @override
  String get permissionShizukuDesc => '點击前往下载安装 Shizuku';
  @override
  String get permissionAllowed => '已允许';
  @override
  String get permissionNotAllowed => '未允许';
  @override
  String get permissionInstalled => '已安装';
  @override
  String get permissionNotInstalled => '未安装';
  @override
  String get permissionAppsTitle => '应用列表';
  @override
  String get permissionAppsDesc => '讀取已安装应用的名稱、包名與版本';
  @override
  String get apkPathUnavailable => '拿不到这个应用的安装包路徑,换一个应用再試。';
  @override
  String get apkExtractHint => '这个項目显示所選 APK 裡的文件。首次浏览需要先解压一次。';
  @override
  String get apkExtractAction => '解压 APK';
  @override
  String get apkExtracting => '正在解压…';
  @override
  String get apkExtractFailed => '解压失败,可能没有讀取该安装包的权限。';
  @override
  String get terminalAgentTab => 'AI 命令';
  @override
  String get runModeAuto => '自动模式';
  @override
  String get runModeBuild => '构建模式';
  @override
  String get runModePlan => '计划模式';
  @override
  String get runModePlanIntercept => '当前处于计划模式,禁止执行寫操作';
  @override
  String get runModeBuildAuthorize => 'AI 尝試执行寫操作,是否允许?';
  @override
  String get runModeBuildAllow => '允许';
  @override
  String get runModeBuildDeny => '拒绝';
  @override
  String runModeSwitchChanged(Object mode) {
    return '运行模式已切换至 $mode';
  }
  @override
  String get commonScrollToBottom => '回到底部';
  @override
  String get subagentTitle => '子代理';
  @override
  String get subagentSubtitle => '模型档位與自定義定義';
  @override
  String get subagentTierSubtitle => '为每个档位绑定提供商與模型。未配置的档位:子代理定義寫死模型时用定義模型,否则继承当前會話模型';
  @override
  String get subagentTierSection => '模型档位';
  @override
  String get subagentTierLight => '轻量';
  @override
  String get subagentTierStandard => '均衡';
  @override
  String get subagentTierStrong => '强力';
  @override
  String get subagentTierLightDesc => '只讀探索、批量定位、機械改名';
  @override
  String get subagentTierStandardDesc => '单文件修改與常规修复';
  @override
  String get subagentTierStrongDesc => '跨模块重构、疑难排查與方案设计';
  @override
  String get subagentTierUnset => '未设置(继承当前會話模型)';
  @override
  String get subagentTierPick => '選择模型';
  @override
  String get subagentTierClear => '清除';
  @override
  String get subagentTierCleared => '已清除';
  @override
  String get subagentTierSaved => '已保存';
  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier 档模型';
  }
  @override
  String get subagentTierSheetHint => '選择该档位使用的提供商與模型';
  @override
  String get subagentTierSheetInherit => '继承当前會話模型';
  @override
  String get subagentNoticeTitle => '子代理';
  @override
  String get subagentStateRunning => '运行中';
  @override
  String get subagentStateCompleted => '已完成';
  @override
  String get subagentStateFailed => '执行失败';
  @override
  String get subagentStateMessage => '来消息';
  @override
  String get subagentViewOutput => '查看输出';
  @override
  String get subagentOpen => '打開';
  @override
  String get subagentOutputEmpty => '暂無输出';
  @override
  String get subagentOutputTitle => '子代理输出';
  @override
  String get promptsTitle => '提示词';
  @override
  String get promptsScenarioSection => '场景提示词';
  @override
  String get promptsSortLongPress => '長按可調整顺序';
  @override
  String get promptsEmpty => '暂無可用片段';
  @override
  String get promptsSourceProject => '項目';
  @override
  String get promptsSourceGlobal => '全局';
  @override
  String get promptsSourceLocal => '本地';
  @override
  String get promptsSourceBuiltin => '內置';
  @override
  String get promptsFieldBasic => '基本信息';
  @override
  String get promptsFieldNumber => '编號';
  @override
  String get promptsFieldNumberPlaceholder => '两位數字,如 35';
  @override
  String get promptsFieldTitle => '名稱';
  @override
  String get promptsFieldTitlePlaceholder => '如:我的安全规则';
  @override
  String get promptsFieldSummary => '摘要(可選)';
  @override
  String get promptsFieldSummaryPlaceholder => '简述片段內容,不會注入提示词';
  @override
  String get promptsFieldContent => '片段內容';
  @override
  String get promptsFieldContentPlaceholder => '寫模型要遵守的內容';
  @override
  String get promptsEditorNew => '新建提示词';
  @override
  String get promptsEditorEdit => '编辑提示词';
  @override
  String get promptsAddPrompt => '添加片段';
  @override
  String get promptsResetCustom => '重置自定義提示词';
  @override
  String get promptsResetConfirm => '将刪除当前項目與全局层裡的所有自定義提示词,各编號回落到內置提示词。此操作不可撤销。';
  @override
  String get promptsResetAction => '重置';
  @override
  String get promptsHelp => '帮助';
  @override
  String get promptsDisableBuiltin => '完全禁用內置提示词';
  @override
  String get promptsDisableBuiltinHint => '只保留你的片段;需要自己补全全部规则,谨慎開啟';
  @override
  String get promptsBatchDeleteTitle => '刪除提示词';
  @override
  String promptsBatchDeleteConfirm(int count) {
    return '确定刪除選中的 $count 條自定義提示词吗?对应编號将回落到下一层来源。';
  }
  @override
  String get promptsScope => '作用域';
  @override
  String get promptsScopeProject => '当前項目';
  @override
  String get promptsScopeGlobal => '全局';
  @override
  String get promptsSelectMode => '多選';
  @override
  String promptsSelectedCount(int count) {
    return '已選 $count 項';
  }
  @override
  String get promptsSelectAll => '全選';
  @override
  String get promptsDeselectAll => '取消全選';
  @override
  String get promptsSummary => '摘要';
  @override
  String get promptsGotIt => '知道了';
  @override
  String get promptsSubtitle => '自定義提示词片段';
  @override
  String get novelNew => '新建小說';
  @override
  String get novelFieldName => '書名';
  @override
  String get novelFieldNameHint => '例如:我在修仙界開超市';
  @override
  String get novelFieldGender => '小說类型';
  @override
  String get novelGenderMale => '男频';
  @override
  String get novelGenderFemale => '女频';
  @override
  String get novelFieldTags => '小說標籤';
  @override
  String get novelFieldTagsHint => '可多選,也可以自定義';
  @override
  String get novelCustomTagHint => '自定義標籤';
  @override
  String get novelFieldWordsPerChapter => '每章字數';
  @override
  String get novelFieldWordsHint => '可選档位,也可以自定義';
  @override
  String get novelCreate => '创建';
  @override
  String get novelPickExisting => '選择已有小說';
  @override
  String get novelOpen => '打開';
  @override
  String get novelExistingEmpty => '「AI小說」目錄裡还没有其他小說';
  @override
  String get novelExistingEmptyHint => '把小說文件夾放進 AI小說 目錄後,再回到这裡選择';
  @override
  String get novelExistingFailed => '讀取小說列表失败';
  @override
  String novelExistingBrief(String title) {
    return '继续创作已有小說《$title》,先閱讀「小說资料」與已有章节,了解设定與進度後再动笔。';
  }
  @override
  String novelBriefTitle(String title) {
    return '新建小說《$title》';
  }
  @override
  String novelBriefTags(String tags) {
    return '標籤:$tags';
  }
  @override
  String novelBriefWords(String words) {
    return '每章字數:$words';
  }
  @override
  String get novelScaffoldFailedTitle => '小說目錄创建失败';
  @override
  String novelScaffoldFailed(String path) {
    return '無法在 $path 下创建小說目錄,请检查存储权限後重試。';
  }
  @override
  String get agentTitle => '子代理';
  @override
  String get agentSubtitle => '自定義子代理定義';
  @override
  String get agentListEmpty => '暂無自定義子代理';
  @override
  String get agentListEmptyHint => '點右上角 + 新建自定義子代理定義';
  @override
  String get agentScopeProject => '当前項目';
  @override
  String get agentScopeGlobal => '全局';
  @override
  String get agentScopeProjectHint => '仅对当前工作區生效';
  @override
  String get agentScopeGlobalHint => '所有項目共享';
  @override
  String get agentNew => '新建子代理';
  @override
  String get agentEdit => '编辑子代理';
  @override
  String get agentSave => '保存';
  @override
  String get agentCancel => '取消';
  @override
  String get agentDelete => '刪除';
  @override
  String get agentDeleteTitle => '刪除子代理';
  @override
  String agentDeleteConfirm(Object name) {
    return '刪除 $name?此操作不可恢复。';
  }
  @override
  String get agentImport => '导入';
  @override
  String get agentName => '名稱';
  @override
  String get agentDescription => '用途描述';
  @override
  String get agentDescriptionHint => '何时選用该子代理';
  @override
  String get agentPrompt => '提示词正文';
  @override
  String get agentPromptHint => '追加到基線系统提示词後的专属指令';
  @override
  String get agentProvider => '提供商';
  @override
  String get agentModel => '模型';
  @override
  String get agentReasoningEffort => '思考强度';
  @override
  String get agentMode => '默認模式';
  @override
  String get agentTools => '工具白名单';
  @override
  String get agentToolsHint => '留空表示開放全部工具';
  @override
  String get agentDisallowedTools => '工具黑名单';
  @override
  String get agentInject => '注入规则片段';
  @override
  String get agentInjectHint => 'base/mainRules/skills/memory/projectRules 或 none';
  @override
  String get agentEnable => '啟用';
  @override
  String get agentDisable => '禁用';
  @override
  String get agentEnabled => '已啟用';
  @override
  String get agentDisabled => '已禁用';
  @override
  String get agentErrorInvalidName => '名稱非法';
  @override
  String get agentErrorEmptyPrompt => '提示词正文不能为空';
  @override
  String get agentErrorNameConflict => '该作用域下已存在同名子代理';
  @override
  String get agentErrorIoFailed => '寫入文件失败';
  @override
  String get agentCapabilityRead => '文件讀取';
  @override
  String get agentCapabilityWrite => '文件修改';
  @override
  String get agentCapabilityCommand => '执行命令';
  @override
  String get agentBuiltin => '內置';
  @override
  String get agentBuiltinHint => '首次啟动释放,升級时完整保留';
  @override
  String get agentSelectMode => '多選';
  @override
  String get agentBatchEnable => '啟用';
  @override
  String get agentBatchDisable => '禁用';
  @override
  String get agentBatchDelete => '刪除';
  @override
  String get agentBatchAll => '全選';
  @override
  String get agentBatchCancel => '取消';
  @override
  String agentSelectedCount(Object count) {
    return '已選 $count 項';
  }
  @override
  String agentBatchDeleteConfirm(Object count) {
    return '刪除 $count 个子代理?此操作不可恢复。';
  }
  @override
  String get agentBatchDeleting => '正在刪除…';
  @override
  String get agentInherit => '继承會話';
  @override
  String get agentReasoningNone => '無';
  @override
  String get agentReasoningMinimal => '极低';
  @override
  String get agentReasoningLow => '低';
  @override
  String get agentReasoningMedium => '中';
  @override
  String get agentReasoningHigh => '高';
  @override
  String get agentReasoningXhigh => '极高';
  @override
  String get agentReasoningMax => '最大';
  @override
  String get agentModeBuild => 'Build';
  @override
  String get agentModePlan => 'Plan';
  @override
  String get agentModeAuto => 'Auto';
  @override
  String get agentDetail => '子代理详情';
  @override
  String get agentDetailHint => '编辑定義;改名會连带重命名定義文件';
  @override
  String get promptsFieldType => '类型';
  @override
  String get promptsSaveFailed => '保存失败';
  @override
  String get promptsNoOverrideToDelete => '该提示词暂無可刪除的自定義覆盖';
  @override
  String get codespacesSearchHint => '按名稱、仓库或分支搜索';
  @override
  String get codespacesFilterAll => '全部';
  @override
  String get codespacesFilterRunning => '运行中';
  @override
  String get codespacesFilterStopped => '已停止';
  @override
  String get codespacesNoMatch => '没有匹配当前篩選的 Codespace';
  @override
  String get codespacesStartAndConnect => '啟动并连接';
  @override
  String get codespacesConnecting => '正在连接…';
  @override
  String get codespacesWaitingForStart => '等待 Codespace 变为可用…';
  @override
  String codespacesConnectError(String error) {
    return '连接失败：$error';
  }
  @override
  String get codespacesDetails => '详情';
  @override
  String get codespacesOverview => '概览';
  @override
  String get codespacesBranchLabel => '分支';
  @override
  String get codespacesMachineLabel => '機型';
  @override
  String get codespacesLocation => '區域';
  @override
  String get codespacesIdleTimeout => '空闲超时（分钟）';
  @override
  String get codespacesRetentionPeriod => '保留期（天）';
  @override
  String get codespacesDevcontainerPath => 'Dev container 路徑';
  @override
  String get codespacesCreatedAt => '创建时間';
  @override
  String get codespacesOwner => '所有者';
  @override
  String get codespacesBillableOwner => '计费所有者';
  @override
  String get codespacesCopySsh => '复制 SSH 命令';
  @override
  String get codespacesSshCopied => '已复制 SSH 命令';
  @override
  String get codespacesOpenWeb => '在 VS Code 網頁版中打開';
  @override
  String get codespacesUnpushed => '有未推送提交';
  @override
  String get codespacesGitStatus => 'Git 状态';
  @override
  String get codespacesActions => '操作';
  @override
  String get codespacesPendingOperation => '正在执行操作';
  @override
  String get codespacesStateQueued => '排队中';
  @override
  String get codespacesStateProvisioning => '正在预配';
  @override
  String get codespacesStateShuttingDown => '正在停止';
  @override
  String get codespacesStateFailed => '失败';
  @override
  String get codespacesStateDeleting => '正在刪除';
  @override
  String get codespacesCurrentEnv => '当前环境';
  @override
  String get codespacesSwitchToLocal => '切换到本地容器';
  @override
  String get codespacesManage => '管理 Codespaces';
  @override
  String get codespacesQuickActions => 'Codespaces';
  @override
  String get codespacesPortCopyUrl => '复制链接';
  @override
  String get codespacesPortUrlCopied => '已复制链接';
  @override
  String codespacesErrorInline(String error) {
    return '$error';
  }
  @override
  String get codespacesRetry => '重試';
  @override
  String get codespacesRegionDefault => '默認區域';
  @override
  String get codespacesAdvanced => '高級選項';
  @override
  String get codespacesDevcontainerPathHint => 'devcontainer.json 路徑（可選）';
  @override
  String get codespacesIdleTimeoutHint => '空闲後自动停止的分钟數（可選）';
  @override
  String get codespacesRetentionHint => '停止後保留天數（可選）';
  @override
  String get codespacesReadinessTitle => '连接就绪';
  @override
  String get codespacesReadinessCredOk => 'GitHub 凭据：已配置';
  @override
  String get codespacesReadinessCredMissing => 'GitHub 凭据：未配置（需含 codespace 权限的令牌）';
  @override
  String get codespacesReadinessGhOk => 'gh CLI：已就绪';
  @override
  String get codespacesReadinessGhMissing => 'gh CLI：未就绪（终端执行 codecraft 安装「GitHub Codespaces」场景）';
  @override
  String get codespacesOpenTerminal => '在终端打開';
  @override
  String get codespacesOpenGit => '打開 Git（部署/同步）';
  @override
  String get codespacesManageCredentials => '管理凭證';
  @override
  String get codespacesDeploySyncHint => 'Git 的推送/拉取等操作會作用于当前执行环境；连接 Codespace 後即在远端仓库执行部署/同步。';
  @override
  String gitExecutionTargetCodespace(String name) {
    return '当前操作作用于 Codespace：$name';
  }
  @override
  String get gitExecutionTargetLocal => '当前操作作用于本地容器';
  @override
  String get gitDeploySyncSection => '部署 / 同步';
  @override
  String get gitDeploySyncHintCodespace => '推送、拉取與远程操作在已连接的 Codespace 中执行。';
  @override
  String get gitDeploySyncHintLocal => '推送、拉取與远程操作在本地容器中执行；连接 Codespace 可在远端部署/同步。';
  @override
  String get gitOpenCodespaces => 'Codespaces';
  @override
  String get gitOpenTerminal => '终端';
  @override
  String get terminalCodespaceManage => 'Codespaces 管理';
  @override
  String get terminalCodespaceCredentials => 'Git 凭据';
  @override
  String get captureTitle => '抓包';
  @override
  String get captureStart => '啟动代理';
  @override
  String get captureStop => '停止';
  @override
  String get captureRunning => '运行中';
  @override
  String get captureStopped => '已停止';
  @override
  String get capturePort => '代理端口';
  @override
  String get captureClear => '清空记錄';
  @override
  String get captureSearchHint => '搜索 URL / method / 状态碼';
  @override
  String get captureEmpty => '暂無抓包记錄。啟动代理後，将目標流量代理到 127.0.0.1:<端口>。';
  @override
  String get captureLimitHint => '仅抓取經代理的流量。HTTPS 需安装并信任 CA；Android 7+ 多數应用與證書锁定应用無法 MITM（可用調試版/受信任證書场景）。';
  @override
  String get captureCaTitle => 'CA 證書';
  @override
  String get captureCaPath => '證書路徑';
  @override
  String get captureCaGuide => '将證書安装到系统/用户證書并设为信任（用于網絡/HTTPS 抓包）。Android 设置路徑因機型不同，通常在「安全/加密與凭据/安装證書」。安装後需将 HTTP 代理设为 127.0.0.1:<端口>。';
  @override
  String get captureCopyPath => '复制路徑';
  @override
  String get captureDetail => '请求详情';
  @override
  String get captureRequest => '请求';
  @override
  String get captureResponse => '响应';
  @override
  String get captureNotFound => '记錄不存在';
  @override
  String get captureCopyUrl => '复制 URL';
  @override
  String get captureInstallCa => '安装證書';
  @override
  String get captureOpenSecurity => '安全设置';
  @override
  String get captureDownloadCa => '保存證書';
  @override
  String get captureCaInstallFail => '無法直接安装（已复制路徑），请到系统安全设置手动安装證書。';
  @override
  String get captureVpnPermissionDenied => 'VPN 权限被拒绝，無法啟用抓包。请允许 VPN 权限後重試。';
  @override
  String get captureSequence => '全部请求';
  @override
  String get captureDomains => '域名列表';
  @override
  String captureDomainSubtitle(String time, int count) {
    return '最後请求: $time · $count 條';
  }
  @override
  String get captureClearConfirm => '确定清空全部抓包记錄？';
  @override
  String get capturePip => '小窗模式';
  @override
  String get capturePipUnsupported => '当前设备不支持小窗模式';
  @override
  String get capturePipNoTraffic => '暂無流量';
  @override
  String get captureNoDomains => '暂無域名';
  @override
  String get captureCopyHost => '复制域名';
  @override
  String get captureDeleteConfirm => '刪除该域名的全部记錄？';
  @override
  String get captureSort => '排序';
  @override
  String get captureOverview => '概览';
  @override
  String get captureCookies => 'Cookie';
  @override
  String get captureProtocol => '协議';
  @override
  String get captureDuration => '耗时';
  @override
  String get captureSize => '大小';
  @override
  String get captureRemoteAddress => '远程地址';
  @override
  String get captureRequestTime => '请求时間';
  @override
  String get capturePath => '路徑';
  @override
  String get captureStatusCode => '状态碼';
  @override
  String get captureRequestHeaders => '请求头';
  @override
  String get captureResponseHeaders => '响应头';
  @override
  String get captureRequestBody => '请求體';
  @override
  String get captureResponseBody => '响应體';
  @override
  String get captureBodyTruncated => '（內容已截断）';
  @override
  String get captureFormatted => '格式化';
  @override
  String get captureRaw => '原文';
  @override
  String get captureNoCookies => '没有 Cookie';
  @override
  String get captureRequestCookies => '请求 Cookie';
  @override
  String get captureResponseCookies => '响应 Set-Cookie';
  @override
  String get backupAndRestore => '备份與还原';
  @override
  String get selectExportData => '選择导出數据';
  @override
  String get aiProvider => 'AI 供应商';
  @override
  String get connectSync => '连接與同步';
  @override
  String get chatRecords => '聊天记錄';
  @override
  String get mcpServer => 'MCP 服務器';
  @override
  String get permissionRules => '授权规则';
  @override
  String get appSettings => '应用设置';
  @override
  String get workspaceFiles => '工作區文件';
  @override
  String get workspaceFilesHint => '工作區文件建議通過 Git 提交备份，导出备份仅作备用';
  @override
  String get exportBackup => '导出备份';
  @override
  String get exportBackupDesc => '選择要导出的數据，可设置口令加密';
  @override
  String get importBackup => '导入备份';
  @override
  String get importBackupDesc => '從备份文件还原數据';
  @override
  String get localBackup => '本地备份';
  @override
  String get cloudBackup => '網絡备份';
}
