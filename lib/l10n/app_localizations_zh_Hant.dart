// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizations {
  AppLocalizationsZhHant([String locale = 'zh_Hant']) : super(locale);

  @override
  String get appName => 'CodeCraft';

  @override
  String get tabSessions => '會話';

  @override
  String get tabSettings => '設定';

  @override
  String get newSession => '新增會話';

  @override
  String get send => '傳送';

  @override
  String get stop => '停止';

  @override
  String get reverseTabClasses => '類別';

  @override
  String get reverseTabStrings => '字串池';

  @override
  String get reverseTabResources => '資源';

  @override
  String get reverseTabHex => '十六進位';

  @override
  String get reverseSearchClassHint => '搜尋類別名稱';

  @override
  String get reverseSearchStringHint => '搜尋字串';

  @override
  String get reverseSearchResourceHint => '搜尋資源名稱、類型或 0x 編號';

  @override
  String get reverseNoMatch => '沒有符合項目';

  @override
  String get reverseEmptyFile => '檔案為空';

  @override
  String get reverseLoadFailed => '開啟失敗';

  @override
  String get reverseParseFailed => '解析失敗，這個檔案可能被加固或已損壞';

  @override
  String get reverseEditString => '修改字串';

  @override
  String get reverseEqualLengthHint => '只能等長替換：新內容編碼後的位元組數必須與原字串一致，否則檔案內偏移會全部錯位';

  @override
  String get reverseEditByte => '修改位元組';

  @override
  String get reverseEditByteHint => '輸入兩位十六進位，例如 0a、ff';

  @override
  String get reverseInvalidByte => '請輸入 00-ff 之間的十六進位位元組';

  @override
  String get reverseJumpToOffset => '跳轉到偏移';

  @override
  String get reverseOffsetInvalid => '偏移無效，請輸入十六進位';

  @override
  String get reverseSuperclass => '父類別';

  @override
  String get reverseInterfaces => '介面';

  @override
  String get reverseAccessFlags => '修飾符';

  @override
  String get reverseFields => '欄位';

  @override
  String get reverseMethods => '方法';

  @override
  String get reverseAbstractMethod => '無方法體';

  @override
  String get reverseSmaliHint => '以上為 smali 反組譯結果；offset 是該指令在方法體內的位元組偏移';

  @override
  String get reverseOpenAsHex => '以十六進位開啟';

  @override
  String reverseMethodCount(int count) {
    return '$count 個方法';
  }

  @override
  String reverseFieldCount(int count) {
    return '$count 個欄位';
  }

  @override
  String reverseHexByteCount(int count) {
    return '共 $count 位元組';
  }

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get rename => '重新命名';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get retry => '重試';

  @override
  String get pin => '置頂';

  @override
  String get unpin => '取消置頂';

  @override
  String get search => '搜尋';

  @override
  String get searchSessions => '搜尋會話';

  @override
  String get noSessions => '暫無會話';

  @override
  String get noMessages => '開始新的對話吧';

  @override
  String get chatInputPlaceholder => '輸入訊息，與 AI 對話…';

  @override
  String get reasoningTitle => '思考過程';

  @override
  String get untitled => '未命名';

  @override
  String get pinned => '已置頂';

  @override
  String get settings => '設定';

  @override
  String get providers => 'AI 供應商';

  @override
  String get providersSubtitle => '模型、介面與金鑰';

  @override
  String get appearance => '外觀';

  @override
  String get themeMode => '主題模式';

  @override
  String get themeModeSystem => '跟隨系統';

  @override
  String get themeModeLight => '淺色';

  @override
  String get themeModeDark => '深色';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get license => '開源授權條款';

  @override
  String get licenseBody => '本專案是 jieapi/Codecraft 的 Flutter 復刻，依 GPL-3.0 授權條款開源。';

  @override
  String get addProvider => '新增供應商';

  @override
  String get providerName => '名稱';

  @override
  String get providerType => '協定';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => '預設模型';

  @override
  String get modelList => '模型列表';

  @override
  String get model => '模型';

  @override
  String get mode => '模式';

  @override
  String get reasoningEffort => '思考強度';

  @override
  String get reasoningEffortNone => '不思考';

  @override
  String get reasoningEffortMinimal => '極低';

  @override
  String get reasoningEffortLow => '低';

  @override
  String get reasoningEffortMedium => '中';

  @override
  String get reasoningEffortHigh => '高';

  @override
  String get reasoningEffortXHigh => '極高';

  @override
  String get reasoningEffortMax => '最高';

  @override
  String get deleteProviderConfirm => '確定刪除該供應商？';

  @override
  String get deleteSessionConfirm => '確定刪除該會話？';

  @override
  String get emptyProviders => '還沒有供應商，點右上角 + 新增';

  @override
  String get emptyModels => '還沒有模型';

  @override
  String get modelInputHint => '輸入模型 ID 後按 Enter 新增';

  @override
  String get errorGeneric => '發生錯誤';

  @override
  String get retrying => '正在重試';

  @override
  String get emptyMessage => '訊息內容為空';

  @override
  String get enabled => '已啟用';

  @override
  String get disabled => '已停用';

  @override
  String providerModelsCountTag(int count) {
    return '$count 個模型';
  }

  @override
  String get inputTokens => '輸入';

  @override
  String get outputTokens => '輸出';

  @override
  String get emptyChatHint => '選擇一個會話開始對話';

  @override
  String get errorNoProvider => '未設定可用的供應商，請先在設定中新增';

  @override
  String get errorNoModel => '請為該供應商選擇模型';

  @override
  String get errorEmptyResponse => '模型傳回了空白內容';

  @override
  String get thinking => '思考中…';

  @override
  String get modelListTitle => '選擇模型';

  @override
  String get providerListTitle => '選擇供應商';

  @override
  String get customProvider => '自訂';

  @override
  String get addFromPreset => '從預設新增';

  @override
  String get useFullUrlHint => 'baseUrl 已是完整端點';

  @override
  String get aboutBody => 'Codecraft Flutter 是 jieapi/Codecraft 的 Flutter 復刻（Phase 1：核心對話閉環）。';

  @override
  String get chatPlaceholder => '有什麼可以幫你的？';

  @override
  String get chatInputHint => '描述你的需求，我來幫你撰寫、修改或解釋程式碼';

  @override
  String get openSidebar => '開啟側邊欄';

  @override
  String get noModelSelected => '未選擇模型';

  @override
  String get sessionGroupPinned => '置頂';

  @override
  String get sessionGroupToday => '今天';

  @override
  String get sessionGroupYesterday => '昨天';

  @override
  String get sessionGroupLast7Days => '7 天內';

  @override
  String get sessionGroupLast30Days => '30 天內';

  @override
  String get sessionGroupMonthFormat => 'yyyy年M月';

  @override
  String chatThinkingRunningTime(String seconds) {
    return '正在思考（耗時 $seconds 秒）';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return '思考完成（耗時 $seconds 秒）';
  }

  @override
  String get chatThinkingDone => '思考完成';

  @override
  String get chatQueueHint => 'AI 正在處理中，點右側方塊可停止';

  @override
  String get chatStatusGenerating => '正在生成';

  @override
  String get chatStatusThinking => '正在思考';

  @override
  String get chatStatusCallingTool => '正在呼叫工具';

  @override
  String get chatStatusRunningCommand => '正在執行命令';

  @override
  String get chatStatusEditingFile => '正在編輯檔案';

  @override
  String get chatStatusReadingFile => '正在讀取檔案';

  @override
  String get chatStatusViewingImage => '正在查看圖片';

  @override
  String get chatStatusSearchingWeb => '正在聯網搜尋';

  @override
  String get chatStatusBrowsingWeb => '正在操作瀏覽器';

  @override
  String get chatStatusAskingUser => '正在詢問使用者';

  @override
  String get chatStatusGeneratingImage => '正在生成圖片';

  @override
  String get chatStatusUpdatingTodo => '正在整理待辦';

  @override
  String get chatStatusStartingSubagent => '正在啟動子代理';

  @override
  String get chatCompressingContext => '正在壓縮上下文';

  @override
  String get chatContextCompressed => '上下文已壓縮';

  @override
  String get chatCompactionSummary => '接手摘要';

  @override
  String get chatStatusReadingMemory => '正在讀取記憶';

  @override
  String get chatToolRunning => '工具執行中';

  @override
  String get chatToolSucceeded => '工具執行成功';

  @override
  String get chatToolFailed => '工具執行失敗';

  @override
  String get chatEffortNone => '不思考';

  @override
  String get chatEffortMinimal => '極低';

  @override
  String get chatEffortLow => '低';

  @override
  String get chatEffortMedium => '中';

  @override
  String get chatEffortHigh => '高';

  @override
  String get chatEffortXHigh => '極高';

  @override
  String get chatEffortMax => '最高';

  @override
  String get searchModels => '搜尋模型';

  @override
  String get chatAddAttachment => '新增附件';

  @override
  String get chatUploadFile => '上傳檔案';

  @override
  String get chatUploadImage => '上傳圖片';

  @override
  String get chatTakePhoto => '拍照';

  @override
  String get attachmentPrefix => '附件：';

  @override
  String attachmentMax(int count) {
    return '最多可同時傳送 $count 個附件';
  }

  @override
  String attachmentUploaded(int count) {
    return '已上傳 $count 個附件';
  }

  @override
  String attachmentUploadedPartial(int count) {
    return '已上傳 $count 個附件，部分附件未加入';
  }

  @override
  String attachmentUploading(int count) {
    return '正在上傳 $count 個檔案…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return '圖片超過 $size，請壓縮後重試';
  }

  @override
  String get attachmentUnsupportedImageType => '無法辨識圖片類型，僅支援 jpg/png/gif/webp';

  @override
  String get attachmentReadFileFailed => '無法讀取所選檔案';

  @override
  String get attachmentUploadFailed => '上傳失敗';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get imagePreview => '圖片預覽';

  @override
  String get imageLoadFailed => '圖片載入失敗，檔案可能已被移動或刪除';

  @override
  String get close => '關閉';

  @override
  String get fileFallback => '檔案';

  @override
  String get skillsTitle => 'Skill 管理';

  @override
  String get skillsSubtitle => '瀏覽、匯入與管理寫作技能';

  @override
  String get skillsNew => '新建技能';

  @override
  String get skillsImport => '匯入 Markdown';

  @override
  String get skillsScopeTitle => '選擇作用域';

  @override
  String get skillsScopeGlobal => '';

  @override
  String get skillsScopeProject => '專案技能';

  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills，跨專案共享';

  @override
  String get skillsScopeProjectHint => '~/workspace/.codecraft/skills，隨目前工作區';

  @override
  String skillsProjectGroup(String name) {
    return '目前專案（$name）';
  }

  @override
  String get skillsNoProjectSkills => '目前專案還沒有技能';

  @override
  String get skillsNoGlobalSkills => '還沒有全域技能';

  @override
  String get skillsEmpty => '還沒有技能';

  @override
  String get skillsEmptyHint => '技能是寫給 AI 的專項操作說明；匯入 SKILL.md 或手動新建一個吧。';

  @override
  String get skillsName => '名稱';

  @override
  String get skillsDescription => '描述';

  @override
  String get skillsDescriptionHint => '何時使用這個技能（會進系統提示）';

  @override
  String get skillsInstructions => '指令正文';

  @override
  String get skillsInstructionsHint => '技能要執行的步驟，以 Markdown 撰寫';

  @override
  String skillsImported(String name) {
    return '已匯入技能「$name」';
  }

  @override
  String get skillsDeleteTitle => '刪除技能';

  @override
  String skillsDeleteConfirm(String name) {
    return '確定刪除技能「$name」（含其目錄與腳本）？';
  }

  @override
  String get skillsErrorInvalidName => '技能名稱無效：不能為空、過長或含 / \\ : * ? " < > |';

  @override
  String get skillsErrorEmptyInstructions => '指令正文不能為空';

  @override
  String skillsErrorNameConflict(String name) {
    return '同作用域已有名為「$name」的技能';
  }

  @override
  String get skillsErrorNoSkill => '檔案裡沒有可辨識的技能';

  @override
  String get skillsErrorIoFailed => '讀寫技能檔案失敗';

  @override
  String get providerAdd => '新增供應商';

  @override
  String get providerEdit => '編輯供應商';

  @override
  String get providerEditModel => '編輯模型';

  @override
  String get providerConfig => '設定';

  @override
  String get providerSectionBasic => '基本資訊';

  @override
  String get providerSectionType => '上游格式';

  @override
  String get providerSectionOptions => '選項';

  @override
  String get providerFullUrl => '完整 URL';

  @override
  String get providerFullUrlDesc => 'Base URL 即完整請求位址，不自動拼接預設路徑';

  @override
  String get providerHeadersTitle => '自訂請求標頭';

  @override
  String get providerHeadersDesc => '完全覆蓋該供應商請求的同名預設標頭';

  @override
  String get providerHeadersAdd => '新增請求標頭';

  @override
  String get providerHeadersManage => '管理';

  @override
  String providerHeadersCount(int count) {
    return '已設定 $count 個請求標頭';
  }

  @override
  String get providerShowApiKey => '顯示金鑰';

  @override
  String get providerHideApiKey => '隱藏金鑰';

  @override
  String get providerAddModel => '新增模型';

  @override
  String get providerNoModels => '暫無模型';

  @override
  String get providerNoModelsHint => '點擊右上方按鈕新增模型';

  @override
  String get providerModelCurrent => '目前';

  @override
  String providerModelsCount(String count) {
    return '模型（$count）';
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
  String get providerModelsBatchTest => '測試';

  @override
  String get providerModelsBatchDelete => '刪除';

  @override
  String get providerModelsBatchDeleteTitle => '刪除模型';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '確定刪除選取的 $count 個模型嗎？';
  }

  @override
  String get providerAddAllModels => '全部新增';

  @override
  String get providerAddAllModelsTitle => '新增全部模型';

  @override
  String providerAddAllModelsConfirm(int count) {
    return '確定將拉取到的 $count 個模型全部新增至目前供應商？';
  }

  @override
  String get providerFilterModelsHint => '輸入模型名稱篩選';

  @override
  String get providerNoMatchingModels => '沒有符合的模型';

  @override
  String providerModelAdded(String name) {
    return '已新增模型「$name」';
  }

  @override
  String get providerModelName => '模型名稱';

  @override
  String get providerModelAlreadyAdded => '該模型已新增';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · {latency}ms';
  }

  @override
  String get providerFetchMissingFields => '回應缺少列表欄位';

  @override
  String get providerFetchFailed => '拉取模型失敗';

  @override
  String get providerApiKeyRequired => '請先填寫 API Key';

  @override
  String get providerTestModel => '測試';

  @override
  String get providerModelContext => '上下文視窗 (tokens)';

  @override
  String get providerModelContextInput => '輸入上限 (tokens)';

  @override
  String get providerModelContextOutput => '輸出上限 (tokens)';

  @override
  String get providerModelWindowInvalid => '請輸入有效的正整數，或留空使用自動辨識值';

  @override
  String get providerModelSectionPrice => '價格';

  @override
  String get providerModelPriceInput => '輸入價格 (USD/1M tokens)';

  @override
  String get providerModelPriceOutput => '輸出價格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheRead => '快取讀取價格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheWrite => '快取寫入價格 (USD/1M tokens)';

  @override
  String get providerModelCapabilities => '能力';

  @override
  String get providerModelCapVision => '圖片輸入';

  @override
  String get providerModelCapImageOutput => '圖片輸出';

  @override
  String get providerModelCapTools => '工具呼叫';

  @override
  String get providerModelCapReasoning => '思考';

  @override
  String get providerModelSectionReasoning => '思考檔位';

  @override
  String get providerModelReasoningHint => '只勾選該模型實際支援的檔位；全部不勾則由內建能力表自動判斷';

  @override
  String get providerModelReasoningCanDisable => '可以關閉思考';

  @override
  String get providerTestRequestUrl => '請求位址';

  @override
  String get providerTestRequestHeaders => '請求標頭';

  @override
  String get providerTestRequestBody => '請求主體';

  @override
  String get providerTestResponse => '回應';

  @override
  String get providerTestError => '錯誤詳情';

  @override
  String get providerMultiKeyTitle => '多 Key 模式';

  @override
  String get providerMultiKeySubtitle => '同一供應商下設定多個 Key，金鑰不可用時自動切換並重送';

  @override
  String get providerMultiKeyManage => '多 Key 管理';

  @override
  String providerMultiKeySummary(int count, String strategy) {
    return '$count 個 · $strategy';
  }

  @override
  String get providerMultiKeyList => 'Key 列表';

  @override
  String providerMultiKeyItem(int index) {
    return '金鑰 #$index';
  }

  @override
  String get providerMultiKeyEmpty => '點此新增第一個 Key';

  @override
  String get providerMultiKeyAdd => '新增 Key';

  @override
  String get providerMultiKeyWeight => '調度權重';

  @override
  String get providerMultiKeyWeightHint => '預設 1 · ≤ 0 時不參與 · 最大 1,000,000';

  @override
  String get providerMultiKeyStrategy => '取用策略';

  @override
  String get providerMultiKeyStrategySequential => '順序';

  @override
  String get providerMultiKeyStrategySequentialDesc => '始終使用靠前的 Key，失敗達閾值才切換下一個';

  @override
  String get providerMultiKeyStrategyRoundRobin => '輪詢';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc => '新會話輪流起步以攤平額度；同一會話內不換 Key，保持快取命中';

  @override
  String get providerMultiKeyStatusCodes => '自動切換狀態碼';

  @override
  String get providerMultiKeyStatusCodesHint => '逗號分隔，留空使用預設 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => '冷卻時長';

  @override
  String get providerMultiKeyCooldownDesc => '被切走的 Key 隔多久重新納入候選';

  @override
  String get workspaceOpen => '工作區';

  @override
  String get workspaceLocal => '本地工作區';

  @override
  String get workspaceLocalSubtitle => '應用程式資料目錄';

  @override
  String get allow => '允許';

  @override
  String get deny => '拒絕';

  @override
  String get tabFiles => '檔案';

  @override
  String get newFile => '新建檔案';

  @override
  String get newFolder => '新建資料夾';

  @override
  String get create => '建立';

  @override
  String get deleteFileConfirm => '確定刪除該檔案？';

  @override
  String get deleteFolderConfirm => '確定刪除該資料夾（含內容）？';

  @override
  String get refresh => '重新整理';

  @override
  String get workspaceNew => '新建';

  @override
  String get workspaceEmptyHint => '還沒有工作區，點右上角「新建」';

  @override
  String get workspaceNameExists => '同名工作區已存在';

  @override
  String get workspaceDelete => '刪除工作區';

  @override
  String workspaceDeleteConfirm(String name) {
    return '確定刪除工作區「$name」（含其中全部檔案）？';
  }

  @override
  String get todoDashboardTitle => '任務待辦';

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
  String get gitRefresh => '重新整理';

  @override
  String get gitTabStatus => '狀態';

  @override
  String get browserTitle => '瀏覽器';

  @override
  String get browserAddressHint => '輸入網址或搜尋';

  @override
  String get browserBack => '後退';

  @override
  String get browserForward => '前進';

  @override
  String get browserReload => '重新整理';

  @override
  String get browserNotReady => '瀏覽器未就緒，請在位址欄輸入網址開始瀏覽';

  @override
  String get browserNewTab => '新建分頁';

  @override
  String get browserCloseTab => '關閉分頁';

  @override
  String get browserTabDefaultTitle => '新分頁';

  @override
  String browserTabsCount(int count) {
    return '分頁 ($count)';
  }

  @override
  String get browserEmptyHint => '在上方位址欄輸入網址開始瀏覽';

  @override
  String get browserTabsManage => '分頁管理';

  @override
  String get browserEmptyClickHint => '點擊上方輸入網址開始瀏覽';

  @override
  String get browserNightModeOn => '關閉夜間模式';

  @override
  String get browserNightModeOff => '開啟夜間模式';

  @override
  String get browserDevtools => '開發者工具';

  @override
  String get browserDialogAlertTitle => '網頁提示';

  @override
  String get browserDialogConfirmTitle => '網頁確認';

  @override
  String get browserDialogPromptTitle => '網頁輸入';

  @override
  String get browserMenu => '更多設定';

  @override
  String get browserMenuTitle => '瀏覽器設定與工具';

  @override
  String get browserMenuGeneralSection => '頁面與工具';

  @override
  String get browserNightModeTitle => '夜間模式';

  @override
  String get browserNightModeDesc => '降低頁面亮度並啟用深色偏好';

  @override
  String get browserDevtoolsTitle => '開發者工具';

  @override
  String get browserDevtoolsDesc => '開啟行動端 Eruda 偵錯主控台';

  @override
  String get browserUaSection => '瀏覽器識別 (User-Agent)';

  @override
  String get browserUaDesc => '模擬不同裝置與環境存取網頁';

  @override
  String get browserUaDefault => '系統預設';

  @override
  String get browserUaDefaultDesc => '目前裝置原生 WebView 識別';

  @override
  String get browserUaAndroidPhone => '安卓手機';

  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';

  @override
  String get browserUaAndroidTablet => '安卓平板';

  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';

  @override
  String get browserUaDesktopPc => '桌面電腦';

  @override
  String get browserUaDesktopPcDesc => 'Chrome Desktop (Windows PC)';

  @override
  String get browserUaIphone => '蘋果 iPhone';

  @override
  String get browserUaIphoneDesc => 'Mobile Safari (iOS)';

  @override
  String get browserUaIpad => '蘋果 iPad';

  @override
  String get browserUaIpadDesc => 'Tablet Safari (iPadOS)';

  @override
  String get browserUaCustom => '自訂';

  @override
  String get browserUaCustomDesc => '手動指定 User-Agent 字串';

  @override
  String get browserUaCustomDialogTitle => '自訂 User-Agent';

  @override
  String get browserUaCustomInputHint => '輸入完整的 User-Agent 字串';

  @override
  String get browserUaAppliedToast => '已切換瀏覽器識別並重新整理頁面';

  @override
  String get gitTabBranches => '分支';

  @override
  String get gitTabCommits => '提交';

  @override
  String get gitStatusClean => '工作區乾淨，無改動';

  @override
  String gitConflictedCount(int count) {
    return '存在衝突 ($count)';
  }

  @override
  String gitStagedCount(int count) {
    return '已暫存 ($count)';
  }

  @override
  String gitModifiedCount(int count) {
    return '已修改 ($count)';
  }

  @override
  String gitUntrackedCount(int count) {
    return '未跟蹤 ($count)';
  }

  @override
  String get gitConflictedLabel => '存在衝突';

  @override
  String get gitStagedLabel => '已暫存';

  @override
  String get gitModifiedLabel => '已修改';

  @override
  String get gitUntrackedLabel => '未跟蹤';

  @override
  String get gitStage => '暫存';

  @override
  String get gitUnstage => '取消暫存';

  @override
  String get gitStageAll => '暫存全部';

  @override
  String get gitUnstageAll => '全部取消暫存';

  @override
  String get gitUnstageAllConfirm => '將取消所有檔案的暫存，但不會刪除檔案內容。確定繼續嗎？';

  @override
  String get gitActionRevertAll => '全部回退';

  @override
  String gitRevertAllConfirm(int count) {
    return '丟棄全部未暫存的改動（$count 個檔案），還原到上次暫存或提交的內容？已暫存的內容不受影響，但丟棄的改動無法找回。';
  }

  @override
  String get gitActionRestoreFile => '恢復檔案';

  @override
  String gitRevertConfirmWorktree(String name) {
    return '把 $name 還原成上次暫存或提交的內容？未暫存的改動會遺失，且無法找回。';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return '把 $name 還原到上次提交的內容？該檔案已暫存和未暫存的改動都會遺失，且無法找回。';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return '恢復已刪除的 $name？將從上次提交取回這個檔案。';
  }

  @override
  String get gitActionDeleteFile => '刪除檔案';

  @override
  String get gitActionDeleteDir => '刪除目錄';

  @override
  String get gitMergePendingTitle => '合併待提交';

  @override
  String get gitMergePendingHint => '目前沒有未解決的衝突。請確認並暫存需要保留的改動，然後提交以完成合併。';

  @override
  String get gitActionAbortMerge => '中止合併';

  @override
  String get gitAbortMergeConfirm => '確定中止目前合併嗎？未解決的衝突改動將被放棄，工作區將還原到合併前的狀態。';

  @override
  String get gitCommitChanges => '提交變更';

  @override
  String get gitCommitNeedsIdentity => '尚未設定提交署名，請在「憑證與署名」頁填寫使用者名稱和電子郵件';

  @override
  String get gitCommitDialogTitle => '提交變更';

  @override
  String get gitCommitMessage => '提交訊息';

  @override
  String get gitCommitAmend => '追加到上次提交 (--amend)';

  @override
  String get gitCommitAiGenerate => 'AI 生成';

  @override
  String get gitCommitGenerating => '正在生成…';

  @override
  String get gitActionCommit => '提交';

  @override
  String get gitTabStash => '儲藏';

  @override
  String get gitStashTitle => '儲藏箱';

  @override
  String get gitActionStash => '儲藏改動';

  @override
  String get gitStashMessageHint => '儲藏說明（可選）';

  @override
  String get gitStashIncludeUntracked => '包含未跟蹤檔案 (-u)';

  @override
  String get gitStashEmpty => '暫無儲藏記錄';

  @override
  String get gitStashPop => '彈出 (Pop)';

  @override
  String get gitStashApply => '套用 (Apply)';

  @override
  String get gitStashDrop => '丟棄 (Drop)';

  @override
  String gitStashDropConfirm(String index) {
    return '確定丟棄儲藏 $index 嗎？該操作不可撤銷。';
  }

  @override
  String get gitStashClear => '清空全部';

  @override
  String get gitStashClearConfirm => '確定清空所有儲藏記錄嗎？該操作不可撤銷。';

  @override
  String gitStashCount(int count) {
    return '儲藏 ($count)';
  }

  @override
  String get gitPull => '拉取';

  @override
  String get gitPush => '推送';

  @override
  String get gitPullDirtyConfirm => '目前工作區有未提交改動，拉取可能導致衝突。建議先提交或暫存。仍要繼續拉取嗎？';

  @override
  String get gitPullContinue => '繼續拉取';

  @override
  String get gitNoUpstream => '未設定上游';

  @override
  String gitTrackingBranch(String name) {
    return '跟蹤 $name';
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
  String get gitDetachedHeadLabel => 'detached HEAD：目前不在任何分支上';

  @override
  String get gitNoBranch => '(無分支)';

  @override
  String get gitLoadingBranches => '正在載入分支列表…';

  @override
  String get gitNoCheckedOutBranch => '未檢出分支';

  @override
  String get gitClean => '工作區乾淨';

  @override
  String get gitHasChanges => '工作區有改動';

  @override
  String get gitNotARepo => '目前工作區還不是 Git 倉庫';

  @override
  String get gitCloningHint => '正在克隆倉庫，請稍候…';

  @override
  String get gitInitDescPrimary => '可在此初始化新倉庫，開始版本管理';

  @override
  String get gitInitDescSecondary => '若子目錄已有 Git 倉庫，也可直接選擇使用';

  @override
  String get gitInitRepo => '初始化新倉庫';

  @override
  String get gitCloneRepo => '克隆遠端倉庫';

  @override
  String get gitCloneDialogTitle => '克隆 Git 倉庫';

  @override
  String get gitCloneDesc => '將遠端倉庫克隆到目前工作區根目錄（工作區需為空）。若為私有倉庫，可先點右上角鑰匙登入 GitHub 或填入存取權杖。';

  @override
  String get gitCloneUrlLabel => '倉庫位址';

  @override
  String get gitCloning => '正在克隆倉庫，請稍候…';

  @override
  String get gitSwitchRepo => '切換倉庫';

  @override
  String get gitPickExistingRepo => '選擇既有倉庫';

  @override
  String get gitRepoSelectorTitle => '選擇倉庫';

  @override
  String get gitRepoNotRepo => '非倉庫';

  @override
  String get gitPickRepoEmpty => '目前工作區沒有可選的目錄';

  @override
  String get gitNoBranches => '暫無分支';

  @override
  String get gitNewBranch => '新建分支';

  @override
  String get gitBranchName => '分支名稱';

  @override
  String get gitBaseBranch => '基準分支';

  @override
  String get gitCreateAndSwitch => '建立並切換';

  @override
  String get gitDeleteBranch => '刪除分支';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '刪除本地分支 $name？';
  }

  @override
  String get gitDeleteRemoteBranch => '刪除遠端分支';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return '刪除遠端分支 $name？該操作不可撤銷。';
  }

  @override
  String get gitRenameBranch => '重新命名分支';

  @override
  String gitRenameTo(String name) {
    return '將 $name 重新命名為：';
  }

  @override
  String get gitNewBranchName => '新分支名稱';

  @override
  String get gitTags => '標籤';

  @override
  String get gitTagName => '標籤名稱';

  @override
  String get gitDeleteTag => '刪除標籤';

  @override
  String gitDeleteTagConfirm(String name) {
    return '刪除本地標籤 $name？';
  }

  @override
  String gitCreateTagDesc(String hash) {
    return '從目前 HEAD（$hash）建立輕量標籤';
  }

  @override
  String get gitCheckedOut => '目前檢出';

  @override
  String get gitCurrentBranch => '目前分支';

  @override
  String get gitRemote => '遠端';

  @override
  String get commonLocal => '本地';

  @override
  String get gitNew => '新增';

  @override
  String get gitNoCommits => '暫無提交記錄';

  @override
  String gitCommitCount(int count) {
    return '提交記錄 ($count)';
  }

  @override
  String get gitSearchCommitsHint => '搜尋提交說明或作者…';

  @override
  String get gitLoadMoreCommits => '上拉載入更早提交';

  @override
  String get gitNoMoreCommits => '沒有更多了';

  @override
  String get gitLatestCommit => '最新提交';

  @override
  String gitFilesChanged(int count) {
    return '$count 個檔案改動';
  }

  @override
  String get gitNoFilesChanged => '該提交無檔案改動';

  @override
  String get gitMergeCommit => '合併提交';

  @override
  String get gitLoadingFiles => '正在載入改動檔案…';

  @override
  String get gitCopyShortHash => '複製短雜湊';

  @override
  String get gitCopyFullHash => '複製完整雜湊';

  @override
  String get gitActionCreateBranch => '建立分支';

  @override
  String get gitActionCreateTag => '建立標籤';

  @override
  String get gitCreateBranchFromCommit => '基於此提交建立分支';

  @override
  String get gitCreateTagAtCommit => '在此提交建立標籤';

  @override
  String get gitResetToCommit => '重置到此提交 (Reset)';

  @override
  String get gitResetSoft => 'Soft（保留工作區與暫存區）';

  @override
  String get gitResetMixed => 'Mixed（保留工作區，清空暫存區）';

  @override
  String gitResetConfirm(String hash) {
    return '確定將目前分支重置到提交 $hash 嗎？';
  }

  @override
  String get gitDiffBinary => '二進位檔案，不顯示差異';

  @override
  String get gitDiffTooLarge => '檔案過大，未計算差異';

  @override
  String get gitDiffEmpty => '沒有可顯示的差異';

  @override
  String get gitCopyPath => '複製路徑';

  @override
  String get gitViewDiff => '查看差異';

  @override
  String get gitRevert => '回退改動';

  @override
  String get gitDeleteUntrackedConfirm => '刪除 {name}？它從未被提交過，刪除後無法透過 Git 恢復。';

  @override
  String get gitAddToGitignore => '新增到 .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return '忽略此檔案 ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return '忽略整個目錄 ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return '忽略同類型檔案 (*.$ext)';
  }

  @override
  String get gitPathCopied => '已複製路徑';

  @override
  String gitActionFailed(String action, String error) {
    return '{action}失敗：$error';
  }

  @override
  String gitActionDone(String action) {
    return '{action}成功';
  }

  @override
  String gitCheckoutSuccess(String name) {
    return '已切換到 $name';
  }

  @override
  String get gitNoRemotePull => '未設定遠端倉庫，無法拉取';

  @override
  String get gitNoRemotePush => '未設定遠端倉庫，無法推送';

  @override
  String get gitPushMasterConfirmTitle => '分支命名建議';

  @override
  String get gitPushMasterConfirmDesc => '目前本地分支為 master，GitHub 與 GitLab 推薦使用 main 作為預設主分支。是否將本地分支重新命名為 main 後再推送？';

  @override
  String get gitPushRenameToMain => '重新命名為 main 並推送';

  @override
  String get gitPushKeepMaster => '保留 master 推送';

  @override
  String get gitTesting => '測試';

  @override
  String get credentialToken => '存取權杖(Token / PAT)';

  @override
  String get gitUserName => 'user.name';

  @override
  String get gitUserEmail => 'user.email';

  @override
  String get gitRepoUrl => '倉庫位址';

  @override
  String get gitSelectBranch => '選擇基準分支';

  @override
  String get credentialTokenLogin => '權杖登入';

  @override
  String get credentialTokenLoginDesc => '只需貼上存取權杖(PAT)，推送時自動比對遠端主機';

  @override
  String get credentialTokenSaved => '權杖已儲存';

  @override
  String get commonShow => '顯示';

  @override
  String get commonHide => '隱藏';

  @override
  String get credentialAdd => '新增憑證';

  @override
  String get settingsSubtitle => '管理 AI、外觀、同步與應用程式資料';

  @override
  String get accountAndData => '帳戶與資料';

  @override
  String get themeTitle => '主題';

  @override
  String get themeSubtitle => '外觀、背景與顯示';

  @override
  String get aboutSubtitle => '版本、更新與回饋';

  @override
  String get aboutAutoCheck => '自動檢查更新';

  @override
  String get aboutAutoCheckDesc => '開啟 App 時自動偵測新版本';

  @override
  String get aboutUpdateChannel => '更新通道';

  @override
  String get aboutStableChannel => '穩定版';

  @override
  String get aboutDownloadMirror => '下載鏡像來源';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub 倉庫';

  @override
  String get aboutUserAgreement => '使用者協議';

  @override
  String get aboutPrivacyPolicy => '隱私權政策';

  @override
  String get mcpTitle => 'MCP 伺服器';

  @override
  String get mcpSubtitle => '接入外部工具的 Model Context Protocol 服務';

  @override
  String get mcpAdd => '新增 MCP';

  @override
  String get mcpEdit => '編輯 MCP';

  @override
  String get mcpEmpty => '還沒有設定 MCP 伺服器';

  @override
  String get mcpEmptyHint => '點擊右上角 + 可以新增遠端 HTTP 或本地 stdio 伺服器';

  @override
  String get mcpSearchPlaceholder => '搜尋 MCP 伺服器…';

  @override
  String get mcpSearchEmpty => '未找到符合的 MCP 伺服器';

  @override
  String get mcpScopeLabel => '作用域';

  @override
  String get mcpScopeGlobal => '全域';

  @override
  String get mcpScopeProject => '專案';

  @override
  String get mcpTypeStdio => 'stdio';

  @override
  String get mcpStatusDisabled => '已停用';

  @override
  String get mcpStatusNotConnected => '未連線';

  @override
  String get mcpStatusConnected => '已連線';

  @override
  String get mcpStatusConnecting => '連線中…';

  @override
  String get mcpStatusFailed => '連線失敗';

  @override
  String get mcpStatusNeedsAuth => '需要登入';

  @override
  String mcpToolsCount(int count) {
    return '$count 個工具';
  }

  @override
  String get mcpDetails => '詳情';

  @override
  String get mcpBasicSettings => '基礎設定';

  @override
  String get mcpEnabledLabel => '是否啟用';

  @override
  String get mcpNameLabel => '名稱';

  @override
  String get mcpNameHint => '例如：fetch、github、gitlab';

  @override
  String get mcpNameInvalid => '名稱只能包含字母、數字、底線和連字號';

  @override
  String get mcpTransportType => '傳輸類型';

  @override
  String get mcpRemoteHttp => '遠端 HTTP';

  @override
  String get mcpLocalStdio => '本地 stdio';

  @override
  String get mcpServerUrl => '伺服器位址';

  @override
  String get mcpServerUrlHint => '例如：https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => '自訂請求標頭';

  @override
  String get mcpNoCustomHeaders => '暫無設定的自訂 Header';

  @override
  String get mcpHeaderName => '請求標頭名稱';

  @override
  String get mcpHeaderNameHint => '如 Authorization';

  @override
  String get mcpHeaderValue => '請求標頭值';

  @override
  String get mcpHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpAddHeader => '新增請求標頭';

  @override
  String get mcpCommand => '啟動命令';

  @override
  String get mcpCommandHint => '例如：npx';

  @override
  String get mcpArgs => '命令參數';

  @override
  String get mcpNoArgs => '無額外命令列參數';

  @override
  String get mcpArgValue => '參數值';

  @override
  String get mcpArgHint => '如 -y 或 @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => '新增參數';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return '已啟用 $enabled / $total 個工具';
  }

  @override
  String get mcpToolsSearch => '搜尋工具名稱或描述…';

  @override
  String get mcpToolsSearchEmpty => '未找到符合的工具';

  @override
  String get mcpToolsEnableAll => '全部啟用';

  @override
  String get mcpToolsDisableAll => '全部停用';

  @override
  String get mcpSaveFirstHint => '請先儲存並連線伺服器後查看工具列表';

  @override
  String get mcpNoToolsHint => '未偵測到工具，點擊右上角重新整理按鈕重試';

  @override
  String get mcpNoDescription => '無描述';

  @override
  String get mcpAddSheetTitle => '新增 MCP 伺服器';

  @override
  String get mcpAddManual => '手動填寫';

  @override
  String get mcpAddManualDesc => '逐一填寫位址、請求標頭或啟動命令';

  @override
  String get mcpAddFromJson => '從 JSON 匯入';

  @override
  String get mcpAddFromJsonDesc => '貼上標準 mcpServers 設定批次匯入';

  @override
  String get mcpJsonImportTitle => '從 JSON 匯入';

  @override
  String get mcpJsonImportHint => '貼上標準 mcpServers 設定：鍵是伺服器名稱，值裡填 url（遠端 HTTP）或 command（本地 stdio）。';

  @override
  String get mcpJsonImportAction => '匯入';

  @override
  String get mcpJsonImportEmpty => '未解析到任何 MCP 伺服器';

  @override
  String get mcpSaved => '已儲存';

  @override
  String get mcpRefreshTools => '重新整理工具';

  @override
  String get mcpRemoved => '已移除 MCP 伺服器';

  @override
  String get permissionsTitle => '工具授權';

  @override
  String get permissionsSubtitle => '規則與記憶';

  @override
  String permCurrentProject(String name) {
    return '目前專案：$name';
  }

}