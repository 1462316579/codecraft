// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'CodeCraft';

  @override
  String get tabSessions => 'セッション';

  @override
  String get tabSettings => '設定';

  @override
  String get newSession => '新規作成セッション';

  @override
  String get send => '发送';

  @override
  String get stop => '停止';

  @override
  String get reverseTabClasses => '类';

  @override
  String get reverseTabStrings => '字符串池';

  @override
  String get reverseTabResources => '资源';

  @override
  String get reverseTabHex => '十六进制';

  @override
  String get reverseSearchClassHint => '検索类名';

  @override
  String get reverseSearchStringHint => '検索字符串';

  @override
  String get reverseSearchResourceHint => '検索资源名、タイプ或 0x 番号';

  @override
  String get reverseNoMatch => '没有匹配件';

  @override
  String get reverseEmptyFile => 'ファイル为空';

  @override
  String get reverseLoadFailed => '開く失敗';

  @override
  String get reverseParseFailed => '解析失敗,这个ファイル可能被加固或已损坏';

  @override
  String get reverseEditString => '修改字符串';

  @override
  String get reverseEqualLengthHint =>
      '只能等长替换:新コンテンツ编码后的字节数必须与原字符串一致,否则ファイル内偏移会すべて错位';

  @override
  String get reverseEditByte => '修改字节';

  @override
  String get reverseEditByteHint => '输入两位十六进制,例如 0a、ff';

  @override
  String get reverseInvalidByte => '请输入 00-ff 之间的十六进制字节';

  @override
  String get reverseJumpToOffset => '跳转到偏移';

  @override
  String get reverseOffsetInvalid => '偏移なし效,请输入十六进制';

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
  String get reverseAbstractMethod => 'なし方法体';

  @override
  String get reverseSmaliHint => '以上为 smali 反汇编结果;offset 是该指令在方法体内的字节偏移';

  @override
  String get reverseOpenAsHex => '以十六进制開く';

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
  String get cancel => 'キャンセル';

  @override
  String get confirm => 'OK';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get rename => '重命名';

  @override
  String get copy => 'コピー';

  @override
  String get copied => '已コピー';

  @override
  String get retry => '再試行';

  @override
  String get pin => '置顶';

  @override
  String get unpin => 'キャンセル置顶';

  @override
  String get search => '検索';

  @override
  String get searchSessions => '検索セッション';

  @override
  String get noSessions => '暂なしセッション';

  @override
  String get noMessages => '開始新的对话吧';

  @override
  String get chatInputPlaceholder => '输入消息,与 AI 对话…';

  @override
  String get reasoningTitle => '思考过程';

  @override
  String get untitled => '未命名';

  @override
  String get pinned => '已置顶';

  @override
  String get settings => '設定';

  @override
  String get providers => 'AI プロバイダ';

  @override
  String get providersSubtitle => 'モデル、接口与密钥';

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
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get license => '开源プロトコル';

  @override
  String get licenseBody =>
      '本プロジェクト是 jieapi/Codecraft 的 Flutter 复刻,按 GPL-3.0 プロトコル开源。';

  @override
  String get addProvider => '添加供应商';

  @override
  String get providerName => '名前';

  @override
  String get providerType => 'プロトコル';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => '默认モデル';

  @override
  String get modelList => 'モデル列表';

  @override
  String get model => 'モデル';

  @override
  String get mode => '模式';

  @override
  String get reasoningEffort => '思考深度';

  @override
  String get reasoningEffortNone => '不思考';

  @override
  String get reasoningEffortMinimal => '非常に低い';

  @override
  String get reasoningEffortLow => '低';

  @override
  String get reasoningEffortMedium => '中';

  @override
  String get reasoningEffortHigh => '高';

  @override
  String get reasoningEffortXHigh => '非常に高い';

  @override
  String get reasoningEffortMax => '最高';

  @override
  String get deleteProviderConfirm => '削除してもよろしいですか？该供应商?';

  @override
  String get deleteSessionConfirm => '削除してもよろしいですか？该セッション?';

  @override
  String get emptyProviders => '还没有供应商,点右上角 + 添加';

  @override
  String get emptyModels => '还没有モデル';

  @override
  String get modelInputHint => '输入モデル ID 后回车添加';

  @override
  String get errorGeneric => '出错了';

  @override
  String get retrying => '正在再試行';

  @override
  String get emptyMessage => '消息コンテンツ为空';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String providerModelsCountTag(int count) {
    return '$count 个モデル';
  }

  @override
  String get inputTokens => '输入';

  @override
  String get outputTokens => '输出';

  @override
  String get emptyChatHint => '選択一个セッション開始对话';

  @override
  String get errorNoProvider => '未設定利用可能的供应商,请先在設定中添加';

  @override
  String get errorNoModel => '请为该供应商選択モデル';

  @override
  String get errorEmptyResponse => 'モデル返回了空白コンテンツ';

  @override
  String get thinking => '思考中…';

  @override
  String get modelListTitle => '選択モデル';

  @override
  String get providerListTitle => '選択供应商';

  @override
  String get customProvider => 'カスタム';

  @override
  String get addFromPreset => '从预设添加';

  @override
  String get useFullUrlHint => 'baseUrl 已是完整端点';

  @override
  String get aboutBody =>
      'Codecraft Flutter 是 jieapi/Codecraft 的 Flutter 复刻(Phase 1:核心对话闭环)。';

  @override
  String get chatPlaceholder => '有什么可以帮你的?';

  @override
  String get chatInputHint => '描述你的需求,我来帮你编写、修改或解释代码';

  @override
  String get openSidebar => '開く侧边栏';

  @override
  String get noModelSelected => '未選択モデル';

  @override
  String get sessionGroupPinned => '置顶';

  @override
  String get sessionGroupToday => '今日';

  @override
  String get sessionGroupYesterday => '昨日';

  @override
  String get sessionGroupLast7Days => '7日内';

  @override
  String get sessionGroupLast30Days => '30日内';

  @override
  String get sessionGroupMonthFormat => 'yyyy年M月';

  @override
  String chatThinkingRunningTime(String seconds) {
    return '正在思考(所要時間 $seconds 秒)';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return '思考完了(所要時間 $seconds 秒)';
  }

  @override
  String get chatThinkingDone => '思考完了';

  @override
  String get chatQueueHint => 'AI 正在処理中,点右侧方块可停止';

  @override
  String get chatStatusGenerating => '正在生成';

  @override
  String get chatStatusThinking => '正在思考';

  @override
  String get chatStatusCallingTool => '正在调用工具';

  @override
  String get chatStatusRunningCommand => '正在コマンドの実行';

  @override
  String get chatStatusEditingFile => '正在編集ファイル';

  @override
  String get chatStatusReadingFile => '正在读取ファイル';

  @override
  String get chatStatusViewingImage => '正在查看图片';

  @override
  String get chatStatusSearchingWeb => '正在联网検索';

  @override
  String get chatStatusBrowsingWeb => '正在操作浏览器';

  @override
  String get chatStatusAskingUser => '正在询问用户';

  @override
  String get chatStatusGeneratingImage => '正在生成图片';

  @override
  String get chatStatusUpdatingTodo => '正在整理待办';

  @override
  String get chatStatusStartingSubagent => '正在開始サブエージェント';

  @override
  String get chatCompressingContext => '正在压缩上下文';

  @override
  String get chatContextCompressed => '上下文已压缩';

  @override
  String get chatCompactionSummary => '接手概要';

  @override
  String get chatStatusReadingMemory => '正在读取记忆';

  @override
  String get chatToolRunning => '工具执行中';

  @override
  String get chatToolSucceeded => '工具执行成功';

  @override
  String get chatToolFailed => '工具执行失敗';

  @override
  String get chatEffortNone => '不思考';

  @override
  String get chatEffortMinimal => '非常に低い';

  @override
  String get chatEffortLow => '低';

  @override
  String get chatEffortMedium => '中';

  @override
  String get chatEffortHigh => '高';

  @override
  String get chatEffortXHigh => '非常に高い';

  @override
  String get chatEffortMax => '最高';

  @override
  String get searchModels => '検索モデル';

  @override
  String get chatAddAttachment => '添加附件';

  @override
  String get chatUploadFile => '上传ファイル';

  @override
  String get chatUploadImage => '上传图片';

  @override
  String get chatTakePhoto => '拍照';

  @override
  String get attachmentPrefix => '附件:';

  @override
  String attachmentMax(int count) {
    return '最多可同时发送 $count 个附件';
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
    return '正在上传 $count 个ファイル…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return '图片超过 $size,请压缩后再試行';
  }

  @override
  String get attachmentUnsupportedImageType =>
      'なし法识别图片タイプ,仅支持 jpg/png/gif/webp';

  @override
  String get attachmentReadFileFailed => 'なし法读取所选ファイル';

  @override
  String get attachmentUploadFailed => '上传失敗';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get imagePreview => '图片预览';

  @override
  String get imageLoadFailed => '图片読み込み失敗,ファイル可能已被移动或削除';

  @override
  String get close => '閉じる';

  @override
  String get fileFallback => 'ファイル';

  @override
  String get skillsTitle => 'Skill 管理';

  @override
  String get skillsSubtitle => '浏览、インポート与管理写作技能';

  @override
  String get skillsNew => '新規作成技能';

  @override
  String get skillsImport => 'インポート Markdown';

  @override
  String get skillsScopeTitle => '選択スコープ';

  @override
  String get skillsScopeGlobal => '';

  @override
  String get skillsScopeProject => 'プロジェクト技能';

  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills,跨プロジェクト共享';

  @override
  String get skillsScopeProjectHint =>
      '~/workspace/.codecraft/skills,随現在ワークスペース';

  @override
  String skillsProjectGroup(String name) {
    return '現在のプロジェクト($name)';
  }

  @override
  String get skillsNoProjectSkills => '現在のプロジェクト还没有技能';

  @override
  String get skillsNoGlobalSkills => '还没有グローバル技能';

  @override
  String get skillsEmpty => '还没有技能';

  @override
  String get skillsEmptyHint => '技能是写给 AI 的专件操作説明;インポート SKILL.md 或手动新規作成一个吧。';

  @override
  String get skillsName => '名前';

  @override
  String get skillsDescription => '描述';

  @override
  String get skillsDescriptionHint => '何时使用这个技能(会进系统ヒント)';

  @override
  String get skillsInstructions => '指令正文';

  @override
  String get skillsInstructionsHint => '技能要执行的步骤,Markdown 书写';

  @override
  String skillsImported(String name) {
    return '已インポート技能「$name」';
  }

  @override
  String get skillsDeleteTitle => '削除技能';

  @override
  String skillsDeleteConfirm(String name) {
    return '削除してもよろしいですか？技能「$name」(含其ディレクトリ与脚本)?';
  }

  @override
  String get skillsErrorInvalidName => '技能名なし效:不能为空、超长或含 / \\ : * ? \" < > |';

  @override
  String get skillsErrorEmptyInstructions => '指令正文不能为空';

  @override
  String skillsErrorNameConflict(String name) {
    return '同スコープ已有名为「$name」的技能';
  }

  @override
  String get skillsErrorNoSkill => 'ファイル里没有可识别的技能';

  @override
  String get skillsErrorIoFailed => '读写技能ファイル失敗';

  @override
  String get providerAdd => '添加供应商';

  @override
  String get providerEdit => '編集供应商';

  @override
  String get providerEditModel => '編集モデル';

  @override
  String get providerConfig => '設定';

  @override
  String get providerSectionBasic => '基本情報';

  @override
  String get providerSectionType => '上游格式';

  @override
  String get providerSectionOptions => 'オプション';

  @override
  String get providerFullUrl => '完整 URL';

  @override
  String get providerFullUrlDesc => 'Base URL 即完整リクエスト地址,不自动拼接默认パス';

  @override
  String get providerHeadersTitle => 'カスタムリクエストヘッダー';

  @override
  String get providerHeadersDesc => '完全覆盖该供应商リクエスト的同名默认头';

  @override
  String get providerHeadersAdd => '添加リクエストヘッダー';

  @override
  String get providerHeadersManage => '管理';

  @override
  String providerHeadersCount(int count) {
    return '設定済み $count 个リクエストヘッダー';
  }

  @override
  String get providerShowApiKey => '显示密钥';

  @override
  String get providerHideApiKey => '隐藏密钥';

  @override
  String get providerAddModel => '添加モデル';

  @override
  String get providerNoModels => '暂なしモデル';

  @override
  String get providerNoModelsHint => '点击右上方按钮添加モデル';

  @override
  String get providerModelCurrent => '現在';

  @override
  String providerModelsCount(String count) {
    return 'モデル($count)';
  }

  @override
  String get providerModelsSelect => '複数選択';

  @override
  String providerModelsSelectedCount(int count) {
    return '選択済み $count 件';
  }

  @override
  String get providerModelsSelectAll => 'すべて選択';

  @override
  String get providerModelsDeselectAll => '全選択を解除';

  @override
  String get providerModelsBatchTest => '测试';

  @override
  String get providerModelsBatchDelete => '削除';

  @override
  String get providerModelsBatchDeleteTitle => '削除モデル';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '選択した項目を削除してもよろしいですか？ $count 个モデル吗?';
  }

  @override
  String get providerFetchModels => '拉取モデル';

  @override
  String get providerAddAllModels => 'すべて添加';

  @override
  String get providerAddAllModelsTitle => '添加すべてモデル';

  @override
  String providerAddAllModelsConfirm(int count) {
    return 'OK将拉取到的 $count 个モデルすべて添加至現在プロバイダ?';
  }

  @override
  String get providerFilterModelsHint => '输入モデル名前筛选';

  @override
  String get providerNoMatchingModels => '没有匹配的モデル';

  @override
  String providerModelAdded(String name) {
    return '已添加モデル「$name」';
  }

  @override
  String get providerModelName => 'モデル名前';

  @override
  String get providerModelAlreadyAdded => '该モデル已添加';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · ${latency}ms';
  }

  @override
  String get providerFetchMissingFields => 'レスポンス缺少列表字段';

  @override
  String get providerFetchFailed => '拉取モデル失敗';

  @override
  String get providerApiKeyRequired => '请先填写 API Key';

  @override
  String get providerTestModel => '测试';

  @override
  String get providerModelContext => '上下文窗口 (tokens)';

  @override
  String get providerModelContextInput => '输入上限 (tokens)';

  @override
  String get providerModelContextOutput => '输出上限 (tokens)';

  @override
  String get providerModelWindowInvalid => '请输入有效的正整数,或留空使用自动识别值';

  @override
  String get providerModelSectionPrice => '价格';

  @override
  String get providerModelPriceInput => '输入价格 (USD/1M tokens)';

  @override
  String get providerModelPriceOutput => '输出价格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheRead => '缓存读价格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheWrite => '缓存写价格 (USD/1M tokens)';

  @override
  String get providerModelCapabilities => '能力';

  @override
  String get providerModelCapVision => '图片输入';

  @override
  String get providerModelCapImageOutput => '图片输出';

  @override
  String get providerModelCapTools => '工具调用';

  @override
  String get providerModelCapReasoning => '思考';

  @override
  String get providerModelSectionReasoning => '思考档位';

  @override
  String get providerModelReasoningHint => '只勾选该モデル真实支持的档位;すべて不勾则由組み込み能力表自动判断';

  @override
  String get providerModelReasoningCanDisable => '可以閉じる思考';

  @override
  String get providerTestRequestUrl => 'リクエスト地址';

  @override
  String get providerTestRequestHeaders => 'リクエストヘッダー';

  @override
  String get providerTestRequestBody => 'リクエストボディ';

  @override
  String get providerTestResponse => 'レスポンス';

  @override
  String get providerTestError => 'エラー詳細';

  @override
  String get providerMultiKeyTitle => '多 Key 模式';

  @override
  String get providerMultiKeySubtitle => '同一供应商下配多个 Key,密钥利用不可时自动切换并重发';

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
    return '密钥 #$index';
  }

  @override
  String get providerMultiKeyEmpty => '点此添加第一个 Key';

  @override
  String get providerMultiKeyAdd => '添加 Key';

  @override
  String get providerMultiKeyWeight => '调度权重';

  @override
  String get providerMultiKeyWeightHint => '默认 1 · ≤ 0 时不参与 · 最大 1,000,000';

  @override
  String get providerMultiKeyStrategy => '取用策略';

  @override
  String get providerMultiKeyStrategySequential => '顺序';

  @override
  String get providerMultiKeyStrategySequentialDesc => '始终用靠前的 Key,失敗达阈值才切下一个';

  @override
  String get providerMultiKeyStrategyRoundRobin => '轮询';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc =>
      '新セッション轮流起步以摊平额度;同一セッション内不换 Key,保持缓存命中';

  @override
  String get providerMultiKeyStatusCodes => '自动切换ステータスコード';

  @override
  String get providerMultiKeyStatusCodesHint => '逗号分隔,留空使用默认 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => '冷却时长';

  @override
  String get providerMultiKeyCooldownDesc => '被切走的 Key 隔多久重新纳入候选';

  @override
  String get workspaceOpen => 'ワークスペース';

  @override
  String get workspaceLocal => 'ローカルワークスペース';

  @override
  String get workspaceLocalSubtitle => '应用数据ディレクトリ';

  @override
  String get allow => '允许';

  @override
  String get deny => '拒绝';

  @override
  String get tabFiles => 'ファイル';

  @override
  String get newFile => '新規作成ファイル';

  @override
  String get newFolder => '新規作成フォルダ';

  @override
  String get create => '作成';

  @override
  String get deleteFileConfirm => '削除してもよろしいですか？该ファイル?';

  @override
  String get deleteFolderConfirm => '削除してもよろしいですか？该フォルダ(含コンテンツ)?';

  @override
  String get refresh => '更新';

  @override
  String get workspaceNew => '新規作成';

  @override
  String get workspaceEmptyHint => '还没有ワークスペース,点右上角「新規作成」';

  @override
  String get workspaceNameExists => '同名ワークスペース已存在';

  @override
  String get workspaceDelete => '削除ワークスペース';

  @override
  String workspaceDeleteConfirm(String name) {
    return '削除してもよろしいですか？ワークスペース「$name」(含其中すべてファイル)?';
  }

  @override
  String get todoDashboardTitle => '任务待办';

  @override
  String todoDashboardProgress(int completed, int total) {
    return '$completed/$total 完了';
  }

  @override
  String get todoDashboardAllDone => 'すべて完了';

  @override
  String get todoInProgress => '実行中';

  @override
  String get todoCompleted => '完了';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitRefresh => '更新';

  @override
  String get gitTabStatus => 'ステータス';

  @override
  String get browserTitle => '浏览器';

  @override
  String get browserAddressHint => '输入网址或検索';

  @override
  String get browserBack => '后退';

  @override
  String get browserForward => '前进';

  @override
  String get browserReload => '更新';

  @override
  String get browserNotReady => '浏览器準備未完了,请在地址栏输入网址開始浏览';

  @override
  String get browserNewTab => '新規作成タグ页';

  @override
  String get browserCloseTab => '閉じるタグ页';

  @override
  String get browserTabDefaultTitle => '新タグ页';

  @override
  String browserTabsCount(int count) {
    return 'タグ页 ($count)';
  }

  @override
  String get browserEmptyHint => '在上方地址栏输入网址開始浏览';

  @override
  String get browserTabsManage => 'タグ页管理';

  @override
  String get browserEmptyClickHint => '点击上方输入网址開始浏览';

  @override
  String get browserNightModeOn => '閉じる夜间模式';

  @override
  String get browserNightModeOff => '有効化夜间模式';

  @override
  String get browserDevtools => '开发者工具';

  @override
  String get browserDialogAlertTitle => '网页ヒント';

  @override
  String get browserDialogConfirmTitle => '网页确认';

  @override
  String get browserDialogPromptTitle => '网页输入';

  @override
  String get browserMenu => 'さらに表示設定';

  @override
  String get browserMenuTitle => '浏览器設定与工具';

  @override
  String get browserMenuGeneralSection => '页面与工具';

  @override
  String get browserNightModeTitle => '夜间模式';

  @override
  String get browserNightModeDesc => '降低页面亮度并有効化深色偏好';

  @override
  String get browserDevtoolsTitle => '开发者工具';

  @override
  String get browserDevtoolsDesc => '有効化移动端 Eruda デバッグ控制台';

  @override
  String get browserUaSection => '浏览器标识 (User-Agent)';

  @override
  String get browserUaDesc => '模拟不同设备与环境访问网页';

  @override
  String get browserUaDefault => '系统默认';

  @override
  String get browserUaDefaultDesc => '現在设备原生 WebView 标识';

  @override
  String get browserUaAndroidPhone => '安卓手机';

  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';

  @override
  String get browserUaAndroidTablet => '安卓平板';

  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';

  @override
  String get browserUaDesktopPc => '桌面电脑';

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
  String get browserUaCustom => 'カスタム';

  @override
  String get browserUaCustomDesc => '手动指定 User-Agent 字符串';

  @override
  String get browserUaCustomDialogTitle => 'カスタム User-Agent';

  @override
  String get browserUaCustomInputHint => '输入完整的 User-Agent 字符串';

  @override
  String get browserUaAppliedToast => '已切换浏览器标识并更新页面';

  @override
  String get gitTabBranches => 'ブランチ';

  @override
  String get gitTabCommits => '提交';

  @override
  String get gitStatusClean => 'ワークスペース干净,なし改动';

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
  String get gitUnstage => 'キャンセル暂存';

  @override
  String get gitStageAll => '暂存すべて';

  @override
  String get gitUnstageAll => 'すべてキャンセル暂存';

  @override
  String get gitUnstageAllConfirm => '将キャンセル所有ファイル的暂存,但不会削除ファイルコンテンツ。OK继续吗?';

  @override
  String get gitActionRevertAll => 'すべて回退';

  @override
  String gitRevertAllConfirm(int count) {
    return '丢弃すべて未暂存的改动($count 个ファイル),復元到上次暂存或提交的コンテンツ?已暂存的コンテンツ不受影响,但丢弃的改动なし法找回。';
  }

  @override
  String get gitActionRestoreFile => '恢复ファイル';

  @override
  String gitRevertConfirmWorktree(String name) {
    return '把 $name 復元成上次暂存或提交的コンテンツ?未暂存的改动会丢失,且なし法找回。';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return '把 $name 復元到上次提交的コンテンツ?该ファイル已暂存和未暂存的改动都会丢失,且なし法找回。';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return '恢复已削除的 $name?将从上次提交取回这个ファイル。';
  }

  @override
  String get gitActionDeleteFile => '削除ファイル';

  @override
  String get gitActionDeleteDir => '削除ディレクトリ';

  @override
  String get gitMergePendingTitle => '合并待提交';

  @override
  String get gitMergePendingHint => '現在没有未解决的冲突。请确认并暂存需要保留的改动,然后提交以完了合并。';

  @override
  String get gitActionAbortMerge => '中止合并';

  @override
  String get gitAbortMergeConfirm =>
      'OK中止現在合并吗?未解决的冲突改动将被放弃,ワークスペース将復元到合并前的ステータス。';

  @override
  String get gitCommitChanges => '提交更改';

  @override
  String get gitCommitNeedsIdentity => '尚未設定提交署名,请在「凭据与署名」页填写用户名和邮箱';

  @override
  String get gitCommitDialogTitle => '提交更改';

  @override
  String get gitCommitMessage => '提交情報';

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
  String get gitStashMessageHint => '储藏説明(オプション)';

  @override
  String get gitStashIncludeUntracked => '包含未跟踪ファイル(-u)';

  @override
  String get gitStashEmpty => '暂なし储藏記録';

  @override
  String get gitStashPop => '弹出 (Pop)';

  @override
  String get gitStashApply => '应用 (Apply)';

  @override
  String get gitStashDrop => '丢弃 (Drop)';

  @override
  String gitStashDropConfirm(String index) {
    return 'OK丢弃储藏 $index 吗?该操作不可撤销。';
  }

  @override
  String get gitStashClear => '清空すべて';

  @override
  String get gitStashClearConfirm => 'OK清空所有储藏記録吗?该操作不可撤销。';

  @override
  String gitStashCount(int count) {
    return '储藏 ($count)';
  }

  @override
  String get gitPull => '拉取';

  @override
  String get gitPush => '推送';

  @override
  String get gitPullDirtyConfirm =>
      '現在ワークスペース有未提交改动,拉取可能导致冲突。建议先提交或暂存。仍要继续拉取吗?';

  @override
  String get gitPullContinue => '继续拉取';

  @override
  String get gitNoUpstream => '未設定上游';

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
  String get gitDetachedHeadLabel => 'detached HEAD:現在不在任何ブランチ上';

  @override
  String get gitNoBranch => '(なしブランチ)';

  @override
  String get gitLoadingBranches => '正在読み込みブランチ列表…';

  @override
  String get gitNoCheckedOutBranch => '未检出ブランチ';

  @override
  String get gitClean => 'ワークスペース干净';

  @override
  String get gitHasChanges => 'ワークスペース有改动';

  @override
  String get gitNotARepo => '現在ワークスペース还不是 Git リポジトリ';

  @override
  String get gitCloningHint => '正在克隆リポジトリ,请稍候…';

  @override
  String get gitInitDescPrimary => '可在此初始化新リポジトリ,開始版本管理';

  @override
  String get gitInitDescSecondary => '若子ディレクトリ已有 Git リポジトリ,也可直接選択使用';

  @override
  String get gitInitRepo => '初始化新リポジトリ';

  @override
  String get gitCloneRepo => '克隆远程リポジトリ';

  @override
  String get gitCloneDialogTitle => '克隆 Git リポジトリ';

  @override
  String get gitCloneDesc =>
      '将远程リポジトリ克隆到現在ワークスペース根ディレクトリ(ワークスペース需为空)。若为私有リポジトリ,可先点右上角钥匙登录 GitHub 或填入访问令牌。';

  @override
  String get gitCloneUrlLabel => 'リポジトリ地址';

  @override
  String get gitCloning => '正在克隆リポジトリ,请稍候…';

  @override
  String get gitSwitchRepo => '切换リポジトリ';

  @override
  String get gitPickExistingRepo => '選択已有リポジトリ';

  @override
  String get gitRepoSelectorTitle => '選択リポジトリ';

  @override
  String get gitRepoNotRepo => '非リポジトリ';

  @override
  String get gitPickRepoEmpty => '現在ワークスペース没有オプション的ディレクトリ';

  @override
  String get gitNoBranches => '暂なしブランチ';

  @override
  String get gitNewBranch => '新規作成ブランチ';

  @override
  String get gitBranchName => 'ブランチ名';

  @override
  String get gitBaseBranch => '基准ブランチ';

  @override
  String get gitCreateAndSwitch => '作成并切换';

  @override
  String get gitDeleteBranch => '削除ブランチ';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '削除ローカルブランチ $name?';
  }

  @override
  String get gitDeleteRemoteBranch => '削除远程ブランチ';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return '削除远程ブランチ $name?该操作不可撤销。';
  }

  @override
  String get gitRenameBranch => '重命名ブランチ';

  @override
  String gitRenameTo(String name) {
    return '将 $name 重命名为:';
  }

  @override
  String get gitNewBranchName => '新ブランチ名';

  @override
  String get gitTags => 'タグ';

  @override
  String get gitTagName => 'タグ名';

  @override
  String get gitDeleteTag => '削除タグ';

  @override
  String gitDeleteTagConfirm(String name) {
    return '削除ローカルタグ $name?';
  }

  @override
  String gitCreateTagDesc(String hash) {
    return '从現在 HEAD($hash)作成軽量タグ';
  }

  @override
  String get gitCheckedOut => '現在检出';

  @override
  String get gitCurrentBranch => '現在ブランチ';

  @override
  String get gitRemote => '远程';

  @override
  String get commonLocal => 'ローカル';

  @override
  String get gitNew => '新增';

  @override
  String get gitNoCommits => '暂なし提交記録';

  @override
  String gitCommitCount(int count) {
    return '提交記録 ($count)';
  }

  @override
  String get gitSearchCommitsHint => '検索提交説明或作者…';

  @override
  String get gitLoadMoreCommits => '上拉読み込み更早提交';

  @override
  String get gitNoMoreCommits => '没有さらに表示了';

  @override
  String get gitLatestCommit => '最新提交';

  @override
  String gitFilesChanged(int count) {
    return '$count 个ファイル改动';
  }

  @override
  String get gitNoFilesChanged => '该提交なしファイル改动';

  @override
  String get gitMergeCommit => '合并提交';

  @override
  String get gitLoadingFiles => '正在読み込み改动ファイル…';

  @override
  String get gitCopyShortHash => 'コピー短哈希';

  @override
  String get gitCopyFullHash => 'コピー完整哈希';

  @override
  String get gitActionCreateBranch => '作成ブランチ';

  @override
  String get gitActionCreateTag => '作成タグ';

  @override
  String get gitCreateBranchFromCommit => '基于此提交作成ブランチ';

  @override
  String get gitCreateTagAtCommit => '在此提交作成タグ';

  @override
  String get gitResetToCommit => 'リセット到此提交 (Reset)';

  @override
  String get gitResetSoft => 'Soft(保留ワークスペース与暂存区)';

  @override
  String get gitResetMixed => 'Mixed(保留ワークスペース,清空暂存区)';

  @override
  String gitResetConfirm(String hash) {
    return 'OK将現在ブランチリセット到提交 $hash 吗?';
  }

  @override
  String get gitDiffBinary => '二进制ファイル,不显示差异';

  @override
  String get gitDiffTooLarge => 'ファイル过大,未计算差异';

  @override
  String get gitDiffEmpty => '没有可显示的差异';

  @override
  String get gitCopyPath => 'パスをコピー';

  @override
  String get gitViewDiff => '查看差异';

  @override
  String get gitRevert => '回退改动';

  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return '削除 $name?它从未被提交过,削除后なし法通过 Git 恢复。';
  }

  @override
  String get gitAddToGitignore => '添加到 .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return '忽略此ファイル ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return '忽略整个ディレクトリ ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return '忽略同タイプファイル (*.$ext)';
  }

  @override
  String get gitPathCopied => '已パスをコピー';

  @override
  String gitActionFailed(String action, String error) {
    return '$action失敗:$error';
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
  String get gitNoRemotePull => '未設定远程リポジトリ,なし法拉取';

  @override
  String get gitNoRemotePush => '未設定远程リポジトリ,なし法推送';

  @override
  String get gitPushMasterConfirmTitle => 'ブランチ命名建议';

  @override
  String get gitPushMasterConfirmDesc =>
      '現在ローカルブランチ为 master,GitHub 与 GitLab 推荐使用 main 作为默认主ブランチ。是否将ローカルブランチ重命名为 main 后再推送?';

  @override
  String get gitPushRenameToMain => '重命名为 main 并推送';

  @override
  String get gitPushKeepMaster => '保留 master 推送';

  @override
  String get gitTesting => '测试';

  @override
  String get credentialToken => '访问令牌(Token / PAT)';

  @override
  String get gitUserName => 'user.name';

  @override
  String get gitUserEmail => 'user.email';

  @override
  String get gitRepoUrl => 'リポジトリ地址';

  @override
  String get gitSelectBranch => '選択基准ブランチ';

  @override
  String get credentialTokenLogin => '令牌登录';

  @override
  String get credentialTokenLoginDesc => '只需貼り付け访问令牌(PAT),推送时自动匹配远端主机';

  @override
  String get credentialTokenSaved => '令牌已保存';

  @override
  String get commonShow => '显示';

  @override
  String get commonHide => '隐藏';

  @override
  String get credentialAdd => '添加凭据';

  @override
  String get settingsSubtitle => '管理 AI、外观、同步和应用数据';

  @override
  String get accountAndData => '账户与数据';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSubtitle => '外观、バックグラウンド与显示';

  @override
  String get aboutSubtitle => '版本、更新与反馈';

  @override
  String get aboutAutoCheck => '自动检查更新';

  @override
  String get aboutAutoCheckDesc => '開く App 时自动检测新版本';

  @override
  String get aboutUpdateChannel => '更新通道';

  @override
  String get aboutStableChannel => '稳定版';

  @override
  String get aboutDownloadMirror => '下载镜像源';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub リポジトリ';

  @override
  String get aboutUserAgreement => '用户プロトコル';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get mcpTitle => 'MCP サーバー';

  @override
  String get mcpSubtitle => '接入外部工具的 Model Context Protocol 服务';

  @override
  String get mcpAdd => '添加 MCP';

  @override
  String get mcpEdit => '編集 MCP';

  @override
  String get mcpEmpty => '还没有設定 MCP サーバー';

  @override
  String get mcpEmptyHint => '点击右上角 + 可以添加远程 HTTP 或ローカル stdio 服务器';

  @override
  String get mcpSearchPlaceholder => '検索 MCP サーバー…';

  @override
  String get mcpSearchEmpty => '未找到匹配的 MCP サーバー';

  @override
  String get mcpScopeLabel => 'スコープ';

  @override
  String get mcpScopeGlobal => 'グローバル';

  @override
  String get mcpScopeProject => 'プロジェクト';

  @override
  String get mcpTypeStdio => 'stdio';

  @override
  String get mcpStatusDisabled => '無効';

  @override
  String get mcpStatusNotConnected => '未连接';

  @override
  String get mcpStatusConnected => '已连接';

  @override
  String get mcpStatusConnecting => '连接中…';

  @override
  String get mcpStatusFailed => '接続に失敗しました';

  @override
  String get mcpStatusNeedsAuth => '需要登录';

  @override
  String mcpToolsCount(int count) {
    return '$count 个工具';
  }

  @override
  String get mcpDetails => '詳細';

  @override
  String get mcpBasicSettings => '基本設定';

  @override
  String get mcpEnabledLabel => '是否有効化';

  @override
  String get mcpNameLabel => '名前';

  @override
  String get mcpNameHint => '例如:fetch、github、gitlab';

  @override
  String get mcpNameInvalid => '名前只能包含字母、数字、下划线和连字符';

  @override
  String get mcpTransportType => '传输タイプ';

  @override
  String get mcpRemoteHttp => '远程 HTTP';

  @override
  String get mcpLocalStdio => 'ローカル stdio';

  @override
  String get mcpServerUrl => '服务器地址';

  @override
  String get mcpServerUrlHint => '例如:https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => 'カスタムリクエストヘッダー';

  @override
  String get mcpNoCustomHeaders => '暂なし設定的カスタム Header';

  @override
  String get mcpHeaderName => 'リクエストヘッダー名前';

  @override
  String get mcpHeaderNameHint => '如 Authorization';

  @override
  String get mcpHeaderValue => 'リクエストヘッダー值';

  @override
  String get mcpHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpAddHeader => '添加リクエストヘッダー';

  @override
  String get mcpCommand => '開始命令';

  @override
  String get mcpCommandHint => '例如:npx';

  @override
  String get mcpArgs => '命令参数';

  @override
  String get mcpNoArgs => 'なし额外命令行参数';

  @override
  String get mcpArgValue => '参数值';

  @override
  String get mcpArgHint => '如 -y 或 @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => '添加参数';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return '有効 $enabled / $total 个工具';
  }

  @override
  String get mcpToolsSearch => '検索工具名前或描述…';

  @override
  String get mcpToolsSearchEmpty => '未找到匹配的工具';

  @override
  String get mcpToolsEnableAll => 'すべて有効化';

  @override
  String get mcpToolsDisableAll => 'すべて無効化';

  @override
  String get mcpSaveFirstHint => '请先保存并连接服务器后查看工具列表';

  @override
  String get mcpNoToolsHint => '未检测到工具,点击右上角更新按钮再試行';

  @override
  String get mcpNoDescription => 'なし描述';

  @override
  String get mcpAddSheetTitle => '添加 MCP サーバー';

  @override
  String get mcpAddManual => '手动填写';

  @override
  String get mcpAddManualDesc => '逐个填写地址、リクエストヘッダー或開始命令';

  @override
  String get mcpAddFromJson => '从 JSON インポート';

  @override
  String get mcpAddFromJsonDesc => '貼り付け标准 mcpServers 設定批量インポート';

  @override
  String get mcpJsonImportTitle => '从 JSON インポート';

  @override
  String get mcpJsonImportHint =>
      '貼り付け标准 mcpServers 設定:键是服务器名,值里填 url(远程 HTTP)或 command(ローカル stdio)。';

  @override
  String get mcpJsonImportAction => 'インポート';

  @override
  String get mcpJsonImportEmpty => '未解析到任何 MCP サーバー';

  @override
  String get mcpSaved => '已保存';

  @override
  String get mcpRefreshTools => '更新工具';

  @override
  String get mcpRemoved => '已移除 MCP サーバー';

  @override
  String get permissionsTitle => '工具授权';

  @override
  String get permissionsSubtitle => '规则与记忆';

  @override
  String permCurrentProject(String name) {
    return '現在のプロジェクト:$name';
  }

  @override
  String get permCurrentProjectNone => '現在のプロジェクト(未選択)';

  @override
  String get permNoProjectRules => '本プロジェクト暂なし规则';

  @override
  String get permGlobal => 'グローバル';

  @override
  String get permNoGlobalRules => '暂なしグローバル规则';

  @override
  String get permEntireTool => '整个工具';

  @override
  String get permDeny => '禁止';

  @override
  String get permPromoteToGlobal => '提升为グローバル';

  @override
  String get permRulesShort => '对话中选「始终実行」会在現在のプロジェクト生成记忆规则';

  @override
  String get chatPermDeny => '拒绝';

  @override
  String get chatPermAlwaysAllow => '始终実行';

  @override
  String get chatPermAlwaysToolDesc => '「始终実行」将在本プロジェクト记住:该工具的すべて调用';

  @override
  String get chatPermAlwaysPrefix => '「始终実行」将在本プロジェクト记住:';

  @override
  String get chatPermSingleUseDesc => '该调用不可记忆,仅可单次放行';

  @override
  String get commonName => '名前';

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
  String get mcpViewLogs => '查看此 MCP ログ';

  @override
  String get mcpAuthEnable => 'OAuth 认证';

  @override
  String get mcpAuthDesc => '用于需要浏览器登录授权的远程 MCP 服务';

  @override
  String get mcpAuthClientId => 'client_id(オプション)';

  @override
  String get mcpAuthClientIdHint => '预注册的客户端 ID;留空则尝试动态注册';

  @override
  String get mcpAuthServer => '授权服务器(オプション)';

  @override
  String get mcpAuthServerHint => '覆盖自动发现的授权服务器地址';

  @override
  String get mcpAuthAdvanced => '詳細設定认证オプション';

  @override
  String get mcpAuthLogin => '登录 / 重新授权';

  @override
  String get mcpAuthReauthorize => '重新授权';

  @override
  String get mcpAuthLogout => '退出登录';

  @override
  String get mcpAuthCancel => 'キャンセル授权';

  @override
  String get mcpAuthInProgress => '待機浏览器授权…';

  @override
  String get mcpAuthInProgressHint => '已在系统浏览器開く登录页,授权完了后将自动返回并连接';

  @override
  String get mcpAuthSaveFirst => '保存服务器設定后,即可在此发起登录授权';

  @override
  String mcpAuthFailed(String message) {
    return '授权失敗:$message';
  }

  @override
  String get mcpAuthStatusLabel => '授权ステータス';

  @override
  String get mcpAuthStatusAuthorized => '已登录';

  @override
  String get mcpAuthStatusUnauthorized => '未登录';

  @override
  String get mcpAuthStatusAuthorizing => '授权中';

  @override
  String get mcpAuthSuccess => '授权成功,已连接';

  @override
  String get settingsReconnect => '重新连接';

  @override
  String get settingsAddMcpServer => '添加 MCP サーバー';

  @override
  String get settingsContainer => '容器与镜像';

  @override
  String get settingsContainerSubtitle => 'PRoot 容器、镜像与初始化';

  @override
  String get commonEdit => '編集';

  @override
  String get commonSwitch => '切换';

  @override
  String get chatOpenTerminal => '開くターミナル';

  @override
  String get terminalTitle => 'ターミナル';

  @override
  String terminalStartFailed(String message) {
    return 'なし法開始ターミナル:';
  }

  @override
  String get terminalRetry => '再試行';

  @override
  String get terminalNoOpenTabs => '没有開く的ターミナルタグ';

  @override
  String get terminalNewTab => '新規作成タグ';

  @override
  String get terminalCloseTab => '閉じるタグ';

  @override
  String get terminalSettingsTitle => 'ターミナル設定';

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
  String get terminalFontSizeTitle => '字体サイズ';

  @override
  String get terminalCursorStyleTitle => '光标样式';

  @override
  String get terminalCursorBlock => '方块';

  @override
  String get terminalCursorUnderline => '下划线';

  @override
  String get terminalCursorBar => '竖线';

  @override
  String get terminalFontTitle => 'ターミナル字体';

  @override
  String get terminalFontDefault => '系统等宽';

  @override
  String get terminalFontBuiltin => 'JetBrains Mono';

  @override
  String get settingsGeneral => '偏好設定';

  @override
  String get settingsGeneralModels => 'モデル';

  @override
  String get settingsAutoRemoveStaleModels => '拉取モデル后自动移除なし效モデル';

  @override
  String get settingsAutoRemoveStaleModelsDesc => '拉取成功后,移除远端已不存在的ローカルモデル件目';

  @override
  String get settingsGeneralSession => 'セッション';

  @override
  String get settingsStartupSession => '開始时セッション';

  @override
  String get settingsStartupSessionNew => '新开セッション';

  @override
  String get settingsStartupSessionNewDesc => '复用尚未发送过消息的空セッション,否则新規作成';

  @override
  String get settingsStartupSessionRecent => '開く最近セッション';

  @override
  String get settingsStartupSessionRecentDesc => '直接进入最近更新的セッション';

  @override
  String get settingsDeleteExternalWorkspaceSessions => '削除外部ワークスペースチャット履歴';

  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc =>
      '移除外部ローカルワークスペース时,一并削除该ワークスペース的チャット履歴';

  @override
  String get settingsGeneralInput => '输入';

  @override
  String get settingsEnterToSend => '回车键发送消息';

  @override
  String get settingsEnterToSendDesc => '閉じる后回车换行,需点发送按钮发送';

  @override
  String get settingsCompactionThreshold => '自动压缩阈值';

  @override
  String get settingsCompactionThresholdDesc => '上下文占用达到窗口的该比例时自动压缩';

  @override
  String get settingsCompactionThresholdInputHint => '填 1-100 的整数百分比';

  @override
  String settingsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsGeneralNetwork => '网络';

  @override
  String get settingsFirstByteTimeout => '首字节超时';

  @override
  String get settingsFirstByteTimeoutDesc => '待機首个レスポンス块的最长时间';

  @override
  String get settingsStreamIdleTimeout => '数据块间隔超时';

  @override
  String get settingsStreamIdleTimeoutDesc => '两个レスポンス块之间的最长待機';

  @override
  String get settingsTimeoutUnlimited => '不限制';

  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get settingsTimeoutInputHint => '单位秒,填 0 表示不限制';

  @override
  String get settingsMaxNetworkRetries => '再試行次数';

  @override
  String get settingsMaxNetworkRetriesDesc => '网络失敗后的指数退避再試行次数';

  @override
  String settingsRetriesCount(int count) {
    return '$count 次';
  }

  @override
  String get settingsRetriesInputHint => '填 0 表示不再試行';

  @override
  String get settingsGeneralTools => '工具';

  @override
  String get settingsSendfileMaxSize => 'sendFile 单ファイル上限';

  @override
  String get settingsGeneralGoal => '目標(goal)';

  @override
  String get settingsGoalMaxTurns => '最大续跑轮数';

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
  String get settingsGoalMaxTurnsInputHint => '填大于 0 的整数轮数';

  @override
  String get settingsGoalMaxTokensInputHint => '填不小于 1000 的整数';

  @override
  String get settingsSendfileMaxSizeDesc => '单个ファイルサイズ上限,超过则整批发送失敗';

  @override
  String get settingsSendfileMaxSizeInputHint => '单位 MB,填大于 0 的整数';

  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }

  @override
  String providerModelsAlignedRemoved(int count) {
    return '已移除 $count 个远端已不存在的モデル';
  }

  @override
  String get tokenStatsTitle => 'Token 统计';

  @override
  String get tokenStatsPeriodToday => '今日';

  @override
  String get tokenStatsPeriod7d => '近7日';

  @override
  String get tokenStatsPeriod30d => '近30日';

  @override
  String get tokenStatsPeriodAll => 'すべて';

  @override
  String get tokenStatsTotal => '总消耗';

  @override
  String get tokenStatsRequests => 'リクエスト次数';

  @override
  String get tokenStatsCost => '费用';

  @override
  String get tokenStatsCacheHitRate => '缓存命中率';

  @override
  String tokenStatsCacheReadWrite(String read, String write) {
    return '读取 $read / 写入 $write';
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
  String get tokenStatsModel => 'モデル统计';

  @override
  String tokenStatsSuccessRate(String rate) {
    return '成功率 $rate';
  }

  @override
  String get tokenStatsRecentCalls => '调用記録';

  @override
  String get tokenStatsUnknown => '不明';

  @override
  String get tokenStatsNoData => '暂なし数据';

  @override
  String get tokenStatsCallsSuffix => '次调用';

  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count 次调用';
  }

  @override
  String get tokenStatsColModel => 'モデル';

  @override
  String get tokenStatsColReasoningEffort => '思考深度';

  @override
  String get tokenStatsColProvider => '供应商';

  @override
  String get tokenStatsColInput => '输入';

  @override
  String get tokenStatsColOutput => '输出';

  @override
  String get tokenStatsColCachedRead => '缓存读取';

  @override
  String get tokenStatsColCachedWrite => '缓存写入';

  @override
  String get tokenStatsColCacheHitRate => '命中率';

  @override
  String get tokenStatsColTtfb => '首字节';

  @override
  String get tokenStatsColDuration => '所要時間';

  @override
  String get tokenStatsColTime => '时间';

  @override
  String get tokenStatsColStatus => 'ステータス';

  @override
  String get tokenStatsColCost => '费用';

  @override
  String tokenStatsPage(int page, int total) {
    return '第 $page / $total 页';
  }

  @override
  String tokenStatsRetries(int count) {
    return '再試行 $count 次';
  }

  @override
  String get tokenStatsReset => 'リセット';

  @override
  String get tokenStatsResetTitle => 'リセット Token 统计';

  @override
  String get tokenStatsResetConfirm => '将清空すべて调用記録,此操作不可恢复。OKリセット?';

  @override
  String get tokenStatsFilterAllProviders => 'すべて供应商';

  @override
  String get tokenStatsFilterAllModels => 'すべてモデル';

  @override
  String get tokenStatsFilterClear => '清除筛选';

  @override
  String tokenStatsFilterProvider(String name) {
    return '供应商:$name';
  }

  @override
  String tokenStatsFilterModel(String name) {
    return 'モデル:$name';
  }

  @override
  String tokenStatsProviderKeys(int count) {
    return '$count 个密钥';
  }

  @override
  String get tokenStatsRequestsUnit => '次リクエスト';

  @override
  String get tokenStatsHourSuffix => '时';

  @override
  String get tokenStatsPrevPage => '上一页';

  @override
  String get tokenStatsNextPage => '下一页';

  @override
  String get settingsCategoryData => '数据与诊断';

  @override
  String get gitActionClone => '克隆';

  @override
  String get gitActionInit => '初始化';

  @override
  String get gitActionMerge => '合并ブランチ';

  @override
  String get gitActionStageAll => 'すべて暂存';

  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';

  @override
  String get gitComputingDiff => '正在计算差异…';

  @override
  String get gitCreateTagTitle => '新規作成タグ';

  @override
  String gitCreateTrackingBranch(String branch) {
    return '从远程ブランチ $branch 作成ローカル跟踪ブランチ并切换?';
  }

  @override
  String get gitCredentialsAndIdentity => '凭据与署名';

  @override
  String gitDetachedHeadWarning(String ref) {
    return '切换到タグ $ref 将进入 detached HEAD ステータス——不处于任何ブランチ上,新提交不属于任何ブランチ。OK继续?';
  }

  @override
  String gitMergeConfirm(String branch, String current) {
    return 'OK将ブランチ $branch 合并到現在ブランチ($current)吗?';
  }

  @override
  String get gitMergeNoFf => '作成合并提交(--no-ff)';

  @override
  String get gitOpenInEditor => '在編集器中開く';

  @override
  String get gitSwitchBranch => '切换ブランチ';

  @override
  String gitSwitchConfirm(String ref) {
    return 'OK切换到 $ref?';
  }

  @override
  String gitToastLoadBranchesFailed(String error) {
    return '読み込みブランチ失敗:$error';
  }

  @override
  String gitToastRefreshFailed(String error) {
    return '更新失敗:$error';
  }

  @override
  String gitToastActionRefreshFailed(String message) {
    return '$message(更新失敗)';
  }

  @override
  String gitToastLoadMoreFailed(String error) {
    return '読み込みさらに表示失敗:$error';
  }

  @override
  String gitToastCheckoutFailed(String error) {
    return '切换失敗:$error';
  }

  @override
  String get gitToastNotRepo => '该ディレクトリ不是 Git リポジトリ';

  @override
  String gitToastSwitchRepoFailed(String error) {
    return '切换リポジトリ失敗:$error';
  }

  @override
  String get gitToastDiffFailed => '読み込み差异失敗';

  @override
  String get gitToastNoDiffForCommit => '暂存区与ワークスペース均なし差异,なし法生成提交情報';

  @override
  String get gitToastGenerateCommitFailed => 'AI 生成提交情報失敗,请检查モデル或网络';

  @override
  String get diffBinaryFile => '二进制ファイル,不支持文本差异对比';

  @override
  String get diffFileTooLarge => 'ファイル过大,已跳过差异计算';

  @override
  String get diffFileTooLargeDesc => '超过 2000 行或含超长行的ファイル不做行级 diff,以避免渲染与内存压力。';

  @override
  String get diffNoChanges => 'なし差异';

  @override
  String get back => '返回';

  @override
  String get chatOpenGit => '開く Git';

  @override
  String get switchLabel => '切换';

  @override
  String get credentialEdit => '編集凭据';

  @override
  String get credentialToastSaved => '凭据已保存';

  @override
  String credentialToastSaveFailed(String param1) {
    return '保存に失敗しました:%1\$s';
  }

  @override
  String get credentialToastDeleted => '凭据已削除';

  @override
  String get credentialToastIdentitySaved => '署名与リポジトリ地址已保存';

  @override
  String get credentialEmptyHint => '尚未添加凭据,点右上角 + 添加';

  @override
  String get credentialEmptyTitle => '暂なし Git 認証情報';

  @override
  String get credentialEmptyDesc => '設定凭据后,Codecraft 可在推送或拉取代码リポジトリ时自动完了身份认证';

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
    return '現在连接 GitHub Codespace $name';
  }

  @override
  String get gitRepoUrlTitle => 'リポジトリ地址';

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
    return '网络エラー:$error';
  }

  @override
  String get codespacesAccount => '账号';

  @override
  String codespacesCount(int count) {
    return 'Codespaces ($count)';
  }

  @override
  String get codespacesEmptyTitle => '还没有 Codespace';

  @override
  String get codespacesEmptyDesc => '在 GitHub 上作成 Codespace 后,这里即可列出并连接';

  @override
  String get codespacesCreateOnWeb => '在 github.com 新規作成';

  @override
  String get codespacesRefresh => '更新';

  @override
  String get codespacesOpenInBrowser => '在浏览器開く';

  @override
  String get codespacesStart => '開始';

  @override
  String get codespacesStop => '停止';

  @override
  String get codespacesDelete => '削除';

  @override
  String codespacesDeleteConfirm(String name) {
    return '削除してもよろしいですか？ $name?该操作不可撤销';
  }

  @override
  String get codespacesStateAvailable => '実行中';

  @override
  String get codespacesStateStarting => '開始中';

  @override
  String get codespacesStateStopped => '停止済み';

  @override
  String get codespacesStateUnknown => 'ステータス不明';

  @override
  String codespacesLastUsed(String time) {
    return '最近使用 $time';
  }

  @override
  String get codespacesNoRepo => '不明リポジトリ';

  @override
  String get codespacesUncommitted => '有未提交改动';

  @override
  String get codespacesMoreActions => 'さらに表示操作';

  @override
  String get editorLoadFailed => 'なし法读取该ファイル';

  @override
  String get editorSaveFailed => '保存に失敗しました';

  @override
  String get editorSaved => '已保存';

  @override
  String get editorCharacters => '角色';

  @override
  String get characterTitle => '角色管理';

  @override
  String get characterNew => '新規作成角色';

  @override
  String get characterEdit => '編集角色';

  @override
  String get characterEmpty => '暂なし角色';

  @override
  String get characterSearchHint => '検索角色名前、別名或タグ';

  @override
  String get characterSearchEmpty => '未找到匹配角色';

  @override
  String get characterFieldBasic => '基本情報';

  @override
  String get characterFieldName => '氏名';

  @override
  String get characterFieldNameHint => '角色的真实氏名';

  @override
  String get characterFieldAlias => '別名/称呼';

  @override
  String get characterFieldAliasHint => '故事中常用的称呼(如:老张、小李)';

  @override
  String get characterFieldGender => '性別';

  @override
  String get characterFieldGenderHint => '男/女/その他';

  @override
  String get characterFieldAge => '年齢';

  @override
  String get characterFieldAgeHint => '数字,如 25';

  @override
  String get characterFieldBirthday => '誕生日';

  @override
  String get characterFieldBirthdayHint => '格式:MM-DD,如 01-15';

  @override
  String get characterFieldAppearance => '外見描写';

  @override
  String get characterFieldAppearanceHint => '身高、体型、发色、瞳色、特征等';

  @override
  String get characterFieldPersonality => '性格';

  @override
  String get characterFieldPersonalityHint => '性格特点、動作模式、说话风格等';

  @override
  String get characterFieldBackground => 'バックグラウンド故事';

  @override
  String get characterFieldBackgroundHint => '成长经历、重要イベント、家庭バックグラウンド等';

  @override
  String get characterFieldGoals => '目標/願望';

  @override
  String get characterFieldGoalsHint => '角色想要达成的事、追求的东西';

  @override
  String get characterFieldFears => '恐怖/弱点';

  @override
  String get characterFieldFearsHint => '害怕的事、心理阴影、致命弱点等';

  @override
  String get characterFieldTags => 'タグ';

  @override
  String get characterFieldTagsHint => '用逗号分隔,如:主角、反派、魔法师';

  @override
  String get characterScope => 'スコープ';

  @override
  String get characterScopeProject => '現在のプロジェクト';

  @override
  String get characterScopeGlobal => 'グローバル';

  @override
  String characterSelectedCount(int count) {
    return '選択済み $count 件';
  }

  @override
  String get editorUndo => '撤销';

  @override
  String get editorRedo => '重做';

  @override
  String get editorSearch => '検索';

  @override
  String get editorSearchHint => '查找コンテンツ';

  @override
  String get editorSearchPrev => '上一个';

  @override
  String get editorSearchNext => '下一个';

  @override
  String get editorTypeset => '自动排版';

  @override
  String get editorTypesetDone => '已排版,可撤销';

  @override
  String get editorCopy => 'コピー';

  @override
  String get editorCopied => '已コピー到剪贴板';

  @override
  String get editorUnsavedState => '未保存';

  @override
  String editorWordCount(int count) {
    return '$count 字';
  }

  @override
  String get editorNoFile => '还没有開く的ファイル,从差异页点「在編集器中開く」即可';

  @override
  String get editorUnsavedTitle => '未保存的修改';

  @override
  String get editorUnsavedMessage => '現在ファイル有未保存的修改,是否保存?';

  @override
  String get editorSaveAndExit => '保存并退出';

  @override
  String get editorSaveAndSwitch => '保存并切换';

  @override
  String get editorDontSave => '不保存';

  @override
  String get editorMdPreview => '预览 Markdown';

  @override
  String get editorMdShowSource => '显示源码';

  @override
  String get editorIndent => '缩进';

  @override
  String get editorCursorLeft => '光标左移';

  @override
  String get editorCursorRight => '光标右移';

  @override
  String get editorSettings => '編集器設定';

  @override
  String get editorFontSize => '字体サイズ';

  @override
  String editorFontSizeValue(int size) {
    return '$size sp';
  }

  @override
  String get editorWordWrap => '自动换行';

  @override
  String get editorShowIndentGuide => '显示缩进参考线';

  @override
  String get editorShowWhitespace => '显示空白符号';

  @override
  String editorFileTooLarge(int mb) {
    return 'ファイル过大($mb MB),暂不支持開く';
  }

  @override
  String get editorBinaryUnsupported => '二进制ファイル,暂不支持開く';

  @override
  String get editorSaveConflictTitle => 'ファイル已被修改';

  @override
  String get editorSaveConflictMessage =>
      '该ファイル在你開く之后已被 AI 或その他程序修改。直接保存会覆盖对方的改动。';

  @override
  String editorSaveConflictDiff(String diff) {
    return '- 磁盘現在コンテンツ';
  }

  @override
  String get editorSaveConflictOverwrite => '覆盖磁盘';

  @override
  String get editorSaveConflictDiscard => '放弃我的修改';

  @override
  String get editorSaveConflictCancel => 'キャンセル';

  @override
  String get editorSaveConflictDiscarded => '已放弃修改并重新载入磁盘コンテンツ';

  @override
  String editorLineColumn(int line, int column) {
    return '$line:$column';
  }

  @override
  String get codespacesConnect => '连接';

  @override
  String get codespacesDisconnect => '断开';

  @override
  String get codespacesGhMissing =>
      '容器里还没有 gh(GitHub CLI)。请先在ターミナルコマンドの実行 codecraft,選択「GitHub Codespaces」场景安装依赖。';

  @override
  String get codespacesExecutionEnv => '执行环境';

  @override
  String get codespacesEnvLocal => 'ローカル容器';

  @override
  String get codespacesEnvCodespace => '远程 Codespace';

  @override
  String terminalRemoteEnv(String name) {
    return '远程环境:$name';
  }

  @override
  String get codespacesNew => '新規作成 Codespace';

  @override
  String get codespacesRepoTab => 'リポジトリ';

  @override
  String get codespacesRepoSearchHint => '検索リポジトリ';

  @override
  String get codespacesBranch => 'ブランチ(留空用默认ブランチ)';

  @override
  String get codespacesMachine => '机器规格';

  @override
  String get codespacesMachineDefault => '默认规格';

  @override
  String get codespacesCreate => '作成';

  @override
  String get codespacesRename => '重命名';

  @override
  String get codespacesRenameTitle => 'Codespace 显示名';

  @override
  String get codespacesChangeMachine => '更改マシンタイプ';

  @override
  String get codespacesNoMachines => '该リポジトリ没有オプションマシンタイプ';

  @override
  String get codespacesLoadFailed => '読み込み失敗';

  @override
  String get codespacesPorts => '端口';

  @override
  String get codespacesPortsEmpty => '该 Codespace 还没有转发的端口';

  @override
  String get codespacesPortVisibility => '可见性';

  @override
  String get codespacesPortPrivate => '仅自己';

  @override
  String get codespacesPortOrg => '组织内';

  @override
  String get codespacesPortPublic => '公开';

  @override
  String get codespacesPortOpen => '開く';

  @override
  String get codespacesRebuild => '重建容器';

  @override
  String get codespacesRebuildDesc =>
      '重建会按現在 devcontainer 重新作成容器:代码与未提交改动保留,容器内已安装的工具与実行ステータス会丢失。';

  @override
  String get codespacesRebuildFull => '完全重建(同时清除缓存的 Docker 镜像,更慢)';

  @override
  String get settingsLog => 'ログ';

  @override
  String get settingsLogSubtitle => '应用実行ログ与 AI リクエストログ';

  @override
  String get logFiles => 'ログファイル';

  @override
  String get logNoFiles => '还没有ログファイル';

  @override
  String logReadFailed(String error) {
    return '读取ログ失敗:$error';
  }

  @override
  String get logSearchHint => '検索ログ';

  @override
  String get logNoMatch => '現在筛选件件下没有ログ';

  @override
  String get logLevel => 'ログレベル';

  @override
  String get logLevelDesc => '記録低于该レベル的ログ将被忽略。开发期建议 VERBOSE(すべて記録);NONE 閉じるログ。';

  @override
  String get logCopied => '已コピー';

  @override
  String logMcpPrefix(String server) {
    return 'MCP ログ:$server';
  }

  @override
  String logSearchResults(int count) {
    return '匹配 $count 行';
  }

  @override
  String logShowLastLines(int shown, int total) {
    return '显示最后 $shown/$total 行';
  }

  @override
  String logShowLines(int count) {
    return '显示 $count 行';
  }

  @override
  String get logCopy => 'コピー';

  @override
  String get logClearFilter => '清除筛选';

  @override
  String get logCopyMenuTitle => 'コピーログ';

  @override
  String get logCopyLine => 'コピー本件ログ';

  @override
  String get logCopyWithStack => 'コピー本件及堆栈';

  @override
  String get logCopyMessage => 'コピー消息コンテンツ';

  @override
  String get logFollowLatest => '实时滚动';

  @override
  String get logFileLocation => 'ログファイル位于 Android/data/<包名>/files/logs/。';

  @override
  String get logLevelVerbose => '詳細';

  @override
  String get logLevelDebug => 'デバッグ';

  @override
  String get logLevelInfo => '情報';

  @override
  String get logLevelWarn => '警告';

  @override
  String get logLevelError => 'エラー';

  @override
  String get logLevelNone => '閉じる';

  @override
  String get credentialTokenHint =>
      '建议用带 codespace スコープ的 GitHub 令牌,填一次同时供 Git 推送与 Codespaces 登录使用';

  @override
  String get credentialHostOptional => '主机(オプション)';

  @override
  String get credentialHostAny => '留空 = 所有主机';

  @override
  String get credentialHostHint => '只在需要给特定主机单独配令牌时才填,例如 gitlab.com';

  @override
  String get codespacesNeedCredentialTitle => '尚未設定 GitHub 認証情報';

  @override
  String get codespacesNeedCredentialDesc =>
      'Codespaces 使用「Git 認証情報」里的令牌(需含 codespace スコープ),不再单独填写。';

  @override
  String get codespacesGoToCredentials => '去填写 Git 認証情報';

  @override
  String get credentialAllHosts => '所有主机';

  @override
  String get credentialUsernameAuto => '用户名自动推导';

  @override
  String get chatMentionSkill => '@ 技能';

  @override
  String get chatMentionSkillEmpty => '还没有利用可能的技能,先在設定里インポート或新規作成一个。';

  @override
  String get chatMentionSkillManage => '管理技能';

  @override
  String get chatPickFile => '# ファイル';

  @override
  String get chatPickFileParent => '上一级';

  @override
  String get chatPickFileEmpty => '这个ディレクトリ是空的';

  @override
  String get mentionHintSkill => '继续输入可筛选技能';

  @override
  String get mentionHintFile => '继续输入可筛选ファイル';

  @override
  String get fileBrowserError => '读取ディレクトリ失敗';

  @override
  String get fileBrowserRefresh => '更新';

  @override
  String get fileBrowserExpand => '展開';

  @override
  String get fileBrowserCollapse => '折りたたみ';

  @override
  String get fileBrowserNewFile => '新規作成ファイル';

  @override
  String get fileBrowserNewFolder => '新規作成フォルダ';

  @override
  String get fileBrowserNameLabel => '名前';

  @override
  String fileBrowserDeleteFileConfirm(String name) {
    return '削除してもよろしいですか？ファイル「$name」?';
  }

  @override
  String fileBrowserDeleteFolderConfirm(String name) {
    return '削除してもよろしいですか？フォルダ「$name」及其すべてコンテンツ?';
  }

  @override
  String get fileBrowserCreateFailed => '作成に失敗しました,可能已存在同名件或なし写入权限';

  @override
  String get fileBrowserRenameFailed => '名前の変更に失敗しました,可能已存在同名件';

  @override
  String get fileBrowserDeleteFailed => '削除に失敗しました';

  @override
  String get fileBrowserPasteHere => '貼り付け到此处';

  @override
  String get fileBrowserExtract => '解压';

  @override
  String get fileBrowserExtractFailed => '解压失敗';

  @override
  String get fileBrowserExtractConflictTitle => '目標フォルダ已存在';

  @override
  String fileBrowserExtractConflict(String name) {
    return '同ディレクトリ下已有「$name」,解压会先覆盖它的コンテンツ。';
  }

  @override
  String get fileBrowserExtractOverwrite => '覆盖并解压';

  @override
  String get fileBrowserPasteConflictTitle => '同名ファイル已存在';

  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '目標位置已存在同名プロジェクト「$name」,是否覆盖?';
  }

  @override
  String get fileBrowserClipboardCut => '已切り取り';

  @override
  String get fileBrowserClipboardCopy => '已コピー';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonCut => '切り取り';

  @override
  String get commonPaste => '貼り付け';

  @override
  String get workspacePickWritingFolder => '写作ディレクトリ';

  @override
  String get writingFolderNeedAccessTitle => '需要存储访问权限';

  @override
  String get writingFolderNeedAccessDesc =>
      '读取手机里的「AI写作」ディレクトリ需要「所有ファイル访问权限」。也可以跳过,直接在下一步選択ディレクトリ。';

  @override
  String get writingFolderGrant => '去授权';

  @override
  String writingFolderSet(String path) {
    return '写作ディレクトリ已设为 $path';
  }

  @override
  String get modelAuto => 'Auto Model';

  @override
  String get modelAutoDesc => '按任务自动選択最合适的モデル';

  @override
  String get sessionExport => 'エクスポートセッション';

  @override
  String sessionExportDone(String path) {
    return '已エクスポート到 $path';
  }

  @override
  String get sessionExportFailed => 'エクスポート失敗';

  @override
  String get sessionBatchSelect => '批量選択';

  @override
  String sessionSelectedCount(String count) {
    return '選択済み $count 件';
  }

  @override
  String get sessionSelectAll => 'すべて選択';

  @override
  String get sessionCancelSelect => 'キャンセル';

  @override
  String get sessionDeleteSelected => '削除所选';

  @override
  String get sessionDeleteConfirm => '削除该セッション及其すべて消息?';

  @override
  String get fileBrowserNeedPermission => 'なし法读取该フォルダ,可能需要存储访问权限';

  @override
  String get checkpointRewindTitle => '回退到此处';

  @override
  String checkpointTargetPrompt(String snippet) {
    return '目標:$snippet';
  }

  @override
  String get checkpointRestoreCodeAndConversation => '復元代码与セッション';

  @override
  String get checkpointRestoreCodeAndConversationDesc =>
      '回滚ワークスペースファイル,并削除这之后的所有消息,提问会回填到输入框';

  @override
  String get checkpointRestoreConversation => '只復元セッション';

  @override
  String get checkpointRestoreConversationDesc => '削除这之后的所有消息,ワークスペースファイル保持不变';

  @override
  String get checkpointRestoreCode => '只復元代码';

  @override
  String get checkpointRestoreCodeDesc => '回滚ワークスペースファイル,对话記録保持不变';

  @override
  String checkpointRewindSkipped(int count) {
    return '$count 个ファイル因存在その他改动已跳过';
  }

  @override
  String get chatMoreOptions => 'さらに表示オプション';

  @override
  String get chatActionEdit => '編集';

  @override
  String get chatActionDelete => '削除';

  @override
  String get chatEditMessageTitle => '編集消息';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonBatchDelete => '批量削除';

  @override
  String get tabProjects => 'プロジェクト';

  @override
  String get projectListEmpty => '还没有プロジェクト';

  @override
  String get workspaceCurrent => '現在';

  @override
  String get workspaceNameHint => 'プロジェクト名前';

  @override
  String get projectNew => '新規作成プロジェクト';

  @override
  String get projectUntitled => '未命名プロジェクト';

  @override
  String get projectKindCoding => '编程';

  @override
  String get projectKindCodingDesc => '在沙盒ワークスペース里写代码、跑命令、改ファイル';

  @override
  String get projectKindWriting => '写作';

  @override
  String get projectKindWritingDesc => '在「AI写作」ディレクトリ里撰写与修改文稿';

  @override
  String get projectKindReverse => '应用逆向';

  @override
  String get projectKindReverseDesc => '分析 APK、パケットキャプチャ接口、静态逆向与デバッグ辅助';

  @override
  String projectDeleteConfirm(String name) {
    return '削除してもよろしいですか？プロジェクト「$name」?其下所有セッション都会一并削除。';
  }

  @override
  String get installedAppsTitle => '選択应用';

  @override
  String get installedAppsSearch => '検索应用名或包名';

  @override
  String get installedAppsEmpty => '没有匹配的应用';

  @override
  String get storagePermissionGrant => '去授权';

  @override
  String get softwarePermissionsTitle => '软件权限';

  @override
  String get softwarePermissionsSubtitle => '点任一件由系统弹出授权,或跳到对应的系统設定页。';

  @override
  String get systemPermissionsGroup => '系统权限';

  @override
  String get permissionStorageTitle => '访问存储空间';

  @override
  String get permissionBatteryTitle => '忽略电池优化';

  @override
  String get permissionBatteryDesc => '允许后台持续実行,减少被杀';

  @override
  String get permissionAutoStartTitle => '自開始管理';

  @override
  String get permissionAutoStartDesc => '允许系统在后台自动拉起应用';

  @override
  String get permissionShizukuTitle => 'Shizuku';

  @override
  String get permissionShizukuDesc => '点击前往下载安装 Shizuku';

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
  String get permissionAppsDesc => '读取已安装应用的名前、包名与版本';

  @override
  String get apkPathUnavailable => '拿不到这个应用的安装包パス,换一个应用再试。';

  @override
  String get apkExtractHint => '这个プロジェクト显示所选 APK 里的ファイル。首次浏览需要先解压一次。';

  @override
  String get apkExtractAction => '解压 APK';

  @override
  String get apkExtracting => '正在解压…';

  @override
  String get apkExtractFailed => '解压失敗,可能没有读取该安装包的权限。';

  @override
  String get terminalAgentTab => 'AI 命令';

  @override
  String get runModeAuto => '自动模式';

  @override
  String get runModeBuild => '构建模式';

  @override
  String get runModePlan => '计划模式';

  @override
  String get runModePlanIntercept => '現在处于计划模式,禁止执行写操作';

  @override
  String get runModeBuildAuthorize => 'AI 尝试执行写操作,是否允许?';

  @override
  String get runModeBuildAllow => '允许';

  @override
  String get runModeBuildDeny => '拒绝';

  @override
  String runModeSwitchChanged(Object mode) {
    return '実行模式已切换至 $mode';
  }

  @override
  String get commonScrollToBottom => '回到底部';

  @override
  String get subagentTitle => 'サブエージェント';

  @override
  String get subagentSubtitle => 'モデル档位与カスタム定義';

  @override
  String get subagentTierSubtitle =>
      '为每个档位绑定プロバイダ与モデル。未設定的档位:サブエージェント定義写死モデル时用定義モデル,否则継承現在セッションモデル';

  @override
  String get subagentTierSection => 'モデル档位';

  @override
  String get subagentTierLight => '軽量';

  @override
  String get subagentTierStandard => 'バランス';

  @override
  String get subagentTierStrong => '強力';

  @override
  String get subagentTierLightDesc => '只读探索、批量定位、机械改名';

  @override
  String get subagentTierStandardDesc => '单ファイルの修正与標準修复';

  @override
  String get subagentTierStrongDesc => '跨模块重构、疑难排查与方案设计';

  @override
  String get subagentTierUnset => '未設定(継承現在セッションモデル)';

  @override
  String get subagentTierPick => '選択モデル';

  @override
  String get subagentTierClear => '清除';

  @override
  String get subagentTierCleared => '已清除';

  @override
  String get subagentTierSaved => '已保存';

  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier 档モデル';
  }

  @override
  String get subagentTierSheetHint => '選択该档位使用的プロバイダ与モデル';

  @override
  String get subagentTierSheetInherit => '継承現在セッションモデル';

  @override
  String get subagentNoticeTitle => 'サブエージェント';

  @override
  String get subagentStateRunning => '実行中';

  @override
  String get subagentStateCompleted => '完了';

  @override
  String get subagentStateFailed => '执行失敗';

  @override
  String get subagentStateMessage => '来消息';

  @override
  String get subagentViewOutput => '查看输出';

  @override
  String get subagentOpen => '開く';

  @override
  String get subagentOutputEmpty => '暂なし输出';

  @override
  String get subagentOutputTitle => 'サブエージェント输出';

  @override
  String get promptsTitle => 'ヒント词';

  @override
  String get promptsScenarioSection => '场景ヒント词';

  @override
  String get promptsSortLongPress => '长按可调整顺序';

  @override
  String get promptsEmpty => '暂なし利用可能片段';

  @override
  String get promptsSourceProject => 'プロジェクト';

  @override
  String get promptsSourceGlobal => 'グローバル';

  @override
  String get promptsSourceLocal => 'ローカル';

  @override
  String get promptsSourceBuiltin => '組み込み';

  @override
  String get promptsFieldBasic => '基本情報';

  @override
  String get promptsFieldNumber => '番号';

  @override
  String get promptsFieldNumberPlaceholder => '2桁の数字,如 35';

  @override
  String get promptsFieldTitle => '名前';

  @override
  String get promptsFieldTitlePlaceholder => '例: 自分用のセキュリティルール';

  @override
  String get promptsFieldSummary => '概要(オプション)';

  @override
  String get promptsFieldSummaryPlaceholder =>
      'スニペットコンテンツを簡潔に説明,プロンプトには注入されません';

  @override
  String get promptsFieldContent => 'スニペット内容';

  @override
  String get promptsFieldContentPlaceholder => '写モデル要遵守的コンテンツ';

  @override
  String get promptsEditorNew => '新規プロンプト';

  @override
  String get promptsEditorEdit => 'プロンプトを編集';

  @override
  String get promptsAddPrompt => 'スニペットを追加';

  @override
  String get promptsResetCustom => 'カスタムプロンプトをリセット';

  @override
  String get promptsResetConfirm =>
      '将削除現在のプロジェクト与グローバル层里的所有カスタムヒント词,各番号回落到組み込みヒント词。この操作は元に戻せません。';

  @override
  String get promptsResetAction => 'リセット';

  @override
  String get promptsHelp => 'ヘルプ';

  @override
  String get promptsDisableBuiltin => '組み込みプロンプトを完全に無効化';

  @override
  String get promptsDisableBuiltinHint =>
      '自分のスニペットのみを保持;すべてのルールを自分で補完する必要があります,注意して有効化してください';

  @override
  String get promptsBatchDeleteTitle => 'プロンプトを削除';

  @override
  String promptsBatchDeleteConfirm(int count) {
    return '選択した項目を削除してもよろしいですか？ $count 件のカスタムプロンプト吗?対応する番号は次のレイヤーのソースにフォールバックします。';
  }

  @override
  String get promptsScope => 'スコープ';

  @override
  String get promptsScopeProject => '現在のプロジェクト';

  @override
  String get promptsScopeGlobal => 'グローバル';

  @override
  String get promptsSelectMode => '複数選択';

  @override
  String promptsSelectedCount(int count) {
    return '選択済み $count 件';
  }

  @override
  String get promptsSelectAll => 'すべて選択';

  @override
  String get promptsDeselectAll => '全選択を解除';

  @override
  String get promptsSummary => '概要';

  @override
  String get promptsGotIt => 'わかりました';

  @override
  String get promptsSubtitle => 'カスタムプロンプトスニペット';

  @override
  String get novelNew => '新規小説';

  @override
  String get novelFieldName => 'タイトル';

  @override
  String get novelFieldNameHint => '例: 修仙界でスーパーを開く';

  @override
  String get novelFieldGender => '小説ジャンル';

  @override
  String get novelGenderMale => '男性向け';

  @override
  String get novelGenderFemale => '女性向け';

  @override
  String get novelFieldTags => '小説タグ';

  @override
  String get novelFieldTagsHint => '可複数選択,也可以カスタム';

  @override
  String get novelCustomTagHint => 'カスタムタグ';

  @override
  String get novelFieldWordsPerChapter => '1章あたりの文字数';

  @override
  String get novelFieldWordsHint => 'オプション档位,也可以カスタム';

  @override
  String get novelCreate => '作成';

  @override
  String get novelPickExisting => '既存の小説を選択';

  @override
  String get novelOpen => '開く';

  @override
  String get novelExistingEmpty => '「AI小説」ディレクトリ里还没有その他小说';

  @override
  String get novelExistingEmptyHint => '把小说フォルダ放进 AI小说 ディレクトリ后,再回到这里選択';

  @override
  String get novelExistingFailed => '小説リストの読み取りに失敗しました';

  @override
  String novelExistingBrief(String title) {
    return '執筆を続行已有小说《$title》,まず読む「小説資料」与已有章节,了解设定与进度后再动笔。';
  }

  @override
  String novelBriefTitle(String title) {
    return '新規小説《$title》';
  }

  @override
  String novelBriefTags(String tags) {
    return 'タグ:$tags';
  }

  @override
  String novelBriefWords(String words) {
    return '1章あたりの文字数:$words';
  }

  @override
  String get novelScaffoldFailedTitle => '小説ディレクトリの作成に失敗しました';

  @override
  String novelScaffoldFailed(String path) {
    return '$path に小説ディレクトリを作成できません,请检查存储权限后再試行。';
  }

  @override
  String get agentTitle => 'サブエージェント';

  @override
  String get agentSubtitle => 'カスタムサブエージェント定義';

  @override
  String get agentListEmpty => 'カスタムサブエージェントはありません';

  @override
  String get agentListEmptyHint => '右上の + から新規作成カスタムサブエージェント定義';

  @override
  String get agentScopeProject => '現在のプロジェクト';

  @override
  String get agentScopeGlobal => 'グローバル';

  @override
  String get agentScopeProjectHint => '現在のワークスペースにのみ適用';

  @override
  String get agentScopeGlobalHint => 'すべてのプロジェクトで共有';

  @override
  String get agentNew => '新規サブエージェント';

  @override
  String get agentEdit => 'サブエージェントを編集';

  @override
  String get agentSave => '保存';

  @override
  String get agentCancel => 'キャンセル';

  @override
  String get agentDelete => '削除';

  @override
  String get agentDeleteTitle => '削除サブエージェント';

  @override
  String agentDeleteConfirm(Object name) {
    return '削除 $name?此操作不可恢复。';
  }

  @override
  String get agentImport => 'インポート';

  @override
  String get agentName => '名前';

  @override
  String get agentDescription => '用途の説明';

  @override
  String get agentDescriptionHint => 'このサブエージェントを選択するタイミング';

  @override
  String get agentPrompt => 'プロンプト本文';

  @override
  String get agentPromptHint => '追加到基线系统ヒント词后的专属指令';

  @override
  String get agentProvider => 'プロバイダ';

  @override
  String get agentModel => 'モデル';

  @override
  String get agentReasoningEffort => '思考深度';

  @override
  String get agentMode => 'デフォルトモード';

  @override
  String get agentTools => 'ツールホワイトリスト';

  @override
  String get agentToolsHint => '空欄の場合はすべてのツールを開放';

  @override
  String get agentDisallowedTools => 'ツールブラックリスト';

  @override
  String get agentInject => 'ルールスニペットを注入';

  @override
  String get agentInjectHint =>
      'base/mainRules/skills/memory/projectRules または none';

  @override
  String get agentEnable => '有効化';

  @override
  String get agentDisable => '無効化';

  @override
  String get agentEnabled => '有効';

  @override
  String get agentDisabled => '無効';

  @override
  String get agentErrorInvalidName => '無効な名前です';

  @override
  String get agentErrorEmptyPrompt => 'プロンプト本文を入力してください';

  @override
  String get agentErrorNameConflict => 'このスコープには既に同じ名前のサブエージェントが存在します';

  @override
  String get agentErrorIoFailed => 'ファイルの書き込みに失敗しました';

  @override
  String get agentCapabilityRead => 'ファイルの読み取り';

  @override
  String get agentCapabilityWrite => 'ファイルの修正';

  @override
  String get agentCapabilityCommand => 'コマンドの実行';

  @override
  String get agentBuiltin => '組み込み';

  @override
  String get agentBuiltinHint => '初回起動時に展開,アップグレード時に完全に保持';

  @override
  String get agentSelectMode => '複数選択';

  @override
  String get agentBatchEnable => '有効化';

  @override
  String get agentBatchDisable => '無効化';

  @override
  String get agentBatchDelete => '削除';

  @override
  String get agentBatchAll => 'すべて選択';

  @override
  String get agentBatchCancel => 'キャンセル';

  @override
  String agentSelectedCount(Object count) {
    return '選択済み $count 件';
  }

  @override
  String agentBatchDeleteConfirm(Object count) {
    return '$count 個のサブエージェントを削除しますか？この操作は元に戻せません。';
  }

  @override
  String get agentBatchDeleting => '削除中…';

  @override
  String get agentInherit => 'セッションを継承';

  @override
  String get agentReasoningNone => 'なし';

  @override
  String get agentReasoningMinimal => '非常に低い';

  @override
  String get agentReasoningLow => '低';

  @override
  String get agentReasoningMedium => '中';

  @override
  String get agentReasoningHigh => '高';

  @override
  String get agentReasoningXhigh => '非常に高い';

  @override
  String get agentReasoningMax => '最大';

  @override
  String get agentModeBuild => 'Build';

  @override
  String get agentModePlan => 'Plan';

  @override
  String get agentModeAuto => 'Auto';

  @override
  String get agentDetail => 'サブエージェント詳細';

  @override
  String get agentDetailHint => '定義を編集;名前変更時に定義ファイルもリネームされます';

  @override
  String get promptsFieldType => 'タイプ';

  @override
  String get promptsSaveFailed => '保存に失敗しました';

  @override
  String get promptsNoOverrideToDelete => 'このプロンプトには削除可能なカスタムオーバーライドはありません';

  @override
  String get codespacesSearchHint => '名前で検索、リポジトリまたはブランチで検索';

  @override
  String get codespacesFilterAll => 'すべて';

  @override
  String get codespacesFilterRunning => '実行中';

  @override
  String get codespacesFilterStopped => '停止済み';

  @override
  String get codespacesNoMatch => '現在のフィルタに一致する Codespace はありません';

  @override
  String get codespacesStartAndConnect => '起動して接続';

  @override
  String get codespacesConnecting => '接続中…';

  @override
  String get codespacesWaitingForStart => '待機 Codespace 变为利用可能…';

  @override
  String codespacesConnectError(String error) {
    return '接続に失敗しました：$error';
  }

  @override
  String get codespacesDetails => '詳細';

  @override
  String get codespacesOverview => '概要';

  @override
  String get codespacesBranchLabel => 'ブランチ';

  @override
  String get codespacesMachineLabel => 'マシンタイプ';

  @override
  String get codespacesLocation => 'リージョン';

  @override
  String get codespacesIdleTimeout => 'アイドルタイムアウト（分）';

  @override
  String get codespacesRetentionPeriod => '保持期間（日）';

  @override
  String get codespacesDevcontainerPath => 'Dev container パス';

  @override
  String get codespacesCreatedAt => '作成日時';

  @override
  String get codespacesOwner => '所有者';

  @override
  String get codespacesBillableOwner => '課金所有者';

  @override
  String get codespacesCopySsh => 'SSH コマンドをコピー';

  @override
  String get codespacesSshCopied => 'SSH コマンドをコピーしました';

  @override
  String get codespacesOpenWeb => 'VS Code Web 版で開く';

  @override
  String get codespacesUnpushed => 'プッシュされていないコミットがあります';

  @override
  String get codespacesGitStatus => 'Git ステータス';

  @override
  String get codespacesActions => '操作';

  @override
  String get codespacesPendingOperation => '操作を実行中';

  @override
  String get codespacesStateQueued => 'キュー中';

  @override
  String get codespacesStateProvisioning => 'プロビジョニング中';

  @override
  String get codespacesStateShuttingDown => '停止中';

  @override
  String get codespacesStateFailed => '失敗';

  @override
  String get codespacesStateDeleting => '削除中';

  @override
  String get codespacesCurrentEnv => '現在の環境';

  @override
  String get codespacesSwitchToLocal => 'ローカルコンテナに切り替え';

  @override
  String get codespacesManage => 'Codespaces を管理';

  @override
  String get codespacesQuickActions => 'Codespaces';

  @override
  String get codespacesPortCopyUrl => 'リンクをコピー';

  @override
  String get codespacesPortUrlCopied => 'リンクをコピーしました';

  @override
  String codespacesErrorInline(String error) {
    return '$error';
  }

  @override
  String get codespacesRetry => '再試行';

  @override
  String get codespacesRegionDefault => 'デフォルトリージョン';

  @override
  String get codespacesAdvanced => '詳細設定';

  @override
  String get codespacesDevcontainerPathHint => 'devcontainer.json パス（オプション）';

  @override
  String get codespacesIdleTimeoutHint => '空闲后自动停止的分数（オプション）';

  @override
  String get codespacesRetentionHint => '停止後の保持日数（オプション）';

  @override
  String get codespacesReadinessTitle => '接続準備完了';

  @override
  String get codespacesReadinessCredOk => 'GitHub 認証情報：設定済み';

  @override
  String get codespacesReadinessCredMissing =>
      'GitHub 認証情報：未設定（需含 codespace 权限的令牌）';

  @override
  String get codespacesReadinessGhOk => 'gh CLI：準備完了';

  @override
  String get codespacesReadinessGhMissing =>
      'gh CLI：準備未完了（ターミナルで codecraft を実行し「GitHub Codespaces」シナリオをインストール）';

  @override
  String get codespacesOpenTerminal => 'ターミナルで開く';

  @override
  String get codespacesOpenGit => 'Git を開く（デプロイ/同期）';

  @override
  String get codespacesManageCredentials => '認証情報を管理';

  @override
  String get codespacesDeploySyncHint =>
      'Git のプッシュ/プル等の操作会作用于現在执行环境；连接 Codespace 后即在远端リポジトリ执行部署/同步。';

  @override
  String gitExecutionTargetCodespace(String name) {
    return '現在の操作は Codespace に適用：$name';
  }

  @override
  String get gitExecutionTargetLocal => '現在の操作はローカルコンテナに適用';

  @override
  String get gitDeploySyncSection => 'デプロイ / 同期';

  @override
  String get gitDeploySyncHintCodespace =>
      'プッシュ、プルおよびリモート操作接続済みの Codespace で実行。';

  @override
  String get gitDeploySyncHintLocal =>
      'プッシュ、プルおよびリモート操作ローカルコンテナで実行；Codespace に接続するとリモートでデプロイ/同期可能。';

  @override
  String get gitOpenCodespaces => 'Codespaces';

  @override
  String get gitOpenTerminal => 'ターミナル';

  @override
  String get terminalCodespaceManage => 'Codespaces 管理';

  @override
  String get terminalCodespaceCredentials => 'Git 認証情報';

  @override
  String get captureTitle => 'パケットキャプチャ';

  @override
  String get captureStart => 'プロキシを起動';

  @override
  String get captureStop => '停止';

  @override
  String get captureRunning => '実行中';

  @override
  String get captureStopped => '停止済み';

  @override
  String get capturePort => 'プロキシポート';

  @override
  String get captureClear => '記録をクリア';

  @override
  String get captureSearchHint => 'URL / メソッド / ステータスコードを検索';

  @override
  String get captureEmpty =>
      'パケットキャプチャ記録はありません。プロキシ起動後，対象トラフィックをプロキシ経由で 127.0.0.1:<ポート>。';

  @override
  String get captureLimitHint =>
      '仅抓取经代理的流量。HTTPS には CA をインストールし信頼する必要があります；Android 7+ のほとんどのアプリと証明書ピンニングアプリは MITM 不可能（デバッグ版/信頼済み証明書のシナリオで利用可能）。';

  @override
  String get captureCaTitle => 'CA 証明書';

  @override
  String get captureCaPath => '証明書パス';

  @override
  String get captureCaGuide =>
      '証明書をシステム/ユーザー証明書にインストールし信頼設定（ネットワーク/HTTPS キャプチャ用）。Android 設定パスは機種により異なります，通常は「セキュリティ/暗号化と認証情報/証明書のインストール」。インストール後は HTTP プロキシを 127.0.0.1:<ポート> に設定。';

  @override
  String get captureCopyPath => 'パスをコピー';

  @override
  String get captureDetail => 'リクエスト詳細';

  @override
  String get captureRequest => 'リクエスト';

  @override
  String get captureResponse => 'レスポンス';

  @override
  String get captureNotFound => '記録が存在しません';

  @override
  String get captureCopyUrl => 'URL をコピー';

  @override
  String get captureInstallCa => '証明書をインストール';

  @override
  String get captureOpenSecurity => 'セキュリティ設定';

  @override
  String get captureDownloadCa => '証明書を保存';

  @override
  String get captureCaInstallFail =>
      '直接インストール不可（パスをコピー済み），システムセキュリティ設定から手動で証明書をインストール。';

  @override
  String get captureVpnPermissionDenied =>
      'VPN 権限が拒否されました，パケットキャプチャを有効化できません。VPN 権限を許可してから再試行。';

  @override
  String get captureSequence => 'すべてのリクエスト';

  @override
  String get captureDomains => 'ドメインリスト';

  @override
  String captureDomainSubtitle(String time, int count) {
    return '最後のリクエスト: $time · $count 件';
  }

  @override
  String get captureClearConfirm => 'すべての抓包記録をクリアしてもよろしいですか？';

  @override
  String get capturePip => 'ピクチャーインピクチャー';

  @override
  String get capturePipUnsupported => 'このデバイスはピクチャーインピクチャーをサポートしていません';

  @override
  String get capturePipNoTraffic => 'トラフィックなし';

  @override
  String get captureNoDomains => 'ドメインなし';

  @override
  String get captureCopyHost => 'ドメインをコピー';

  @override
  String get captureDeleteConfirm => '削除该域名的すべて記録？';

  @override
  String get captureSort => '並び替え';

  @override
  String get captureOverview => '概要';

  @override
  String get captureCookies => 'Cookie';

  @override
  String get captureProtocol => 'プロトコル';

  @override
  String get captureDuration => '所要時間';

  @override
  String get captureSize => 'サイズ';

  @override
  String get captureRemoteAddress => 'リモートアドレス';

  @override
  String get captureRequestTime => 'リクエスト時間';

  @override
  String get capturePath => 'パス';

  @override
  String get captureStatusCode => 'ステータスコード';

  @override
  String get captureRequestHeaders => 'リクエストヘッダー';

  @override
  String get captureResponseHeaders => 'レスポンスヘッダー';

  @override
  String get captureRequestBody => 'リクエストボディ';

  @override
  String get captureResponseBody => 'レスポンスボディ';

  @override
  String get captureBodyTruncated => '（内容は省略されています）';

  @override
  String get captureFormatted => 'フォーマット';

  @override
  String get captureRaw => '生データ';

  @override
  String get captureNoCookies => 'Cookie なし';

  @override
  String get captureRequestCookies => 'リクエスト Cookie';

  @override
  String get captureResponseCookies => 'レスポンス Set-Cookie';

  @override
  String get backupAndRestore => 'バックアップと復元';

  @override
  String get selectExportData => 'エクスポートデータを選択';

  @override
  String get aiProvider => 'AI プロバイダ';

  @override
  String get connectSync => '接続と同期';

  @override
  String get chatRecords => 'チャット履歴';

  @override
  String get mcpServer => 'MCP サーバー';

  @override
  String get permissionRules => '認可ルール';

  @override
  String get appSettings => 'アプリ設定';

  @override
  String get workspaceFiles => 'ワークスペースファイル';

  @override
  String get workspaceFilesHint =>
      'ワークスペースファイルは Git コミットでのバックアップを推奨，エクスポートバックアップは予備用のみ';

  @override
  String get exportBackup => 'バックアップのエクスポート';

  @override
  String get exportBackupDesc => 'エクスポートするデータを選択，パスワードで暗号化可能';

  @override
  String get importBackup => 'バックアップのインポート';

  @override
  String get importBackupDesc => 'バックアップファイルからデータを復元';

  @override
  String get localBackup => 'ローカルバックアップ';

  @override
  String get cloudBackup => 'クラウドバックアップ';

  @override
  String get aboutUpdateAvailable => '新しいバージョンが利用可能';

  @override
  String get aboutUpdateDesc => '新しいバージョンが利用可能';

  @override
  String get aboutUpdateLater => '後で';

  @override
  String get aboutUpdateGo => 'ダウンロードへ';

  @override
  String get aboutCheckingUpdate => 'GitHub で最新バージョンを確認中…';

  @override
  String get aboutAlreadyLatest => '最新バージョンです';

  @override
  String get aboutCurrentVersion => '現在のバージョン';
}
