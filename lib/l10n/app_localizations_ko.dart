// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'CodeCraft';

  @override
  String get tabSessions => '세션';

  @override
  String get tabSettings => '설정';

  @override
  String get newSession => '새로 만들기세션';

  @override
  String get send => '发送';

  @override
  String get stop => '중지';

  @override
  String get reverseTabClasses => '类';

  @override
  String get reverseTabStrings => '字符串池';

  @override
  String get reverseTabResources => '资源';

  @override
  String get reverseTabHex => '十六进制';

  @override
  String get reverseSearchClassHint => '검색类名';

  @override
  String get reverseSearchStringHint => '검색字符串';

  @override
  String get reverseSearchResourceHint => '검색资源名、유형或 0x 번호';

  @override
  String get reverseNoMatch => '没有匹配개';

  @override
  String get reverseEmptyFile => '파일为空';

  @override
  String get reverseLoadFailed => '열기실패';

  @override
  String get reverseParseFailed => '解析실패,这个파일可能被加固或已损坏';

  @override
  String get reverseEditString => '修改字符串';

  @override
  String get reverseEqualLengthHint =>
      '只能等长替换:新내용编码后的字节数必须与原字符串一致,否则파일内偏移会전체错位';

  @override
  String get reverseEditByte => '修改字节';

  @override
  String get reverseEditByteHint => '输入两位十六进制,例如 0a、ff';

  @override
  String get reverseInvalidByte => '请输入 00-ff 之间的十六进制字节';

  @override
  String get reverseJumpToOffset => '跳转到偏移';

  @override
  String get reverseOffsetInvalid => '偏移없음效,请输入十六进制';

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
  String get reverseAbstractMethod => '없음方法体';

  @override
  String get reverseSmaliHint => '以上为 smali 反汇编结果;offset 是该指令在方法体内的字节偏移';

  @override
  String get reverseOpenAsHex => '以十六进制열기';

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
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get rename => '重命名';

  @override
  String get copy => '복사';

  @override
  String get copied => '已복사';

  @override
  String get retry => '재시도';

  @override
  String get pin => '置顶';

  @override
  String get unpin => '취소置顶';

  @override
  String get search => '검색';

  @override
  String get searchSessions => '검색세션';

  @override
  String get noSessions => '暂없음세션';

  @override
  String get noMessages => '시작新的对话吧';

  @override
  String get chatInputPlaceholder => '输入消息,与 AI 对话…';

  @override
  String get reasoningTitle => '思考过程';

  @override
  String get untitled => '未命名';

  @override
  String get pinned => '已置顶';

  @override
  String get settings => '설정';

  @override
  String get providers => 'AI 제공자';

  @override
  String get providersSubtitle => '모델、接口与密钥';

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
  String get license => '开源프로토콜';

  @override
  String get licenseBody =>
      '本프로젝트是 jieapi/Codecraft 的 Flutter 复刻,按 GPL-3.0 프로토콜开源。';

  @override
  String get addProvider => '添加供应商';

  @override
  String get providerName => '이름';

  @override
  String get providerType => '프로토콜';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => '默认모델';

  @override
  String get modelList => '모델列表';

  @override
  String get model => '모델';

  @override
  String get mode => '模式';

  @override
  String get reasoningEffort => '사고 강도';

  @override
  String get reasoningEffortNone => '不思考';

  @override
  String get reasoningEffortMinimal => '매우 낮음';

  @override
  String get reasoningEffortLow => '낮음';

  @override
  String get reasoningEffortMedium => '중간';

  @override
  String get reasoningEffortHigh => '높음';

  @override
  String get reasoningEffortXHigh => '매우 높음';

  @override
  String get reasoningEffortMax => '最높음';

  @override
  String get deleteProviderConfirm => '삭제하시겠습니까?该供应商?';

  @override
  String get deleteSessionConfirm => '삭제하시겠습니까?该세션?';

  @override
  String get emptyProviders => '还没有供应商,点右上角 + 添加';

  @override
  String get emptyModels => '还没有모델';

  @override
  String get modelInputHint => '输入모델 ID 后回车添加';

  @override
  String get errorGeneric => '出错了';

  @override
  String get retrying => '正在재시도';

  @override
  String get emptyMessage => '消息내용为空';

  @override
  String get enabled => '활성화됨';

  @override
  String get disabled => '비활성화됨';

  @override
  String providerModelsCountTag(int count) {
    return '$count 个모델';
  }

  @override
  String get inputTokens => '输入';

  @override
  String get outputTokens => '输出';

  @override
  String get emptyChatHint => '선택一个세션시작对话';

  @override
  String get errorNoProvider => '미설정사용 가능的供应商,请先在설정중간添加';

  @override
  String get errorNoModel => '请为该供应商선택모델';

  @override
  String get errorEmptyResponse => '모델返回了空白내용';

  @override
  String get thinking => '思考중간…';

  @override
  String get modelListTitle => '선택모델';

  @override
  String get providerListTitle => '선택供应商';

  @override
  String get customProvider => '사용자 정의';

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
  String get openSidebar => '열기侧边栏';

  @override
  String get noModelSelected => '未선택모델';

  @override
  String get sessionGroupPinned => '置顶';

  @override
  String get sessionGroupToday => '今일';

  @override
  String get sessionGroupYesterday => '昨일';

  @override
  String get sessionGroupLast7Days => '7일内';

  @override
  String get sessionGroupLast30Days => '30일内';

  @override
  String get sessionGroupMonthFormat => 'yyyy年M月';

  @override
  String chatThinkingRunningTime(String seconds) {
    return '正在思考(소요 시간 $seconds 秒)';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return '思考완료(소요 시간 $seconds 秒)';
  }

  @override
  String get chatThinkingDone => '思考완료';

  @override
  String get chatQueueHint => 'AI 正在처리 중,点右侧方块可중지';

  @override
  String get chatStatusGenerating => '正在生成';

  @override
  String get chatStatusThinking => '正在思考';

  @override
  String get chatStatusCallingTool => '正在调用工具';

  @override
  String get chatStatusRunningCommand => '正在명령 실행';

  @override
  String get chatStatusEditingFile => '正在编辑파일';

  @override
  String get chatStatusReadingFile => '正在读取파일';

  @override
  String get chatStatusViewingImage => '正在查看图片';

  @override
  String get chatStatusSearchingWeb => '正在联网검색';

  @override
  String get chatStatusBrowsingWeb => '正在작업浏览器';

  @override
  String get chatStatusAskingUser => '正在询问用户';

  @override
  String get chatStatusGeneratingImage => '正在生成图片';

  @override
  String get chatStatusUpdatingTodo => '正在整理待办';

  @override
  String get chatStatusStartingSubagent => '正在시작서브 에이전트';

  @override
  String get chatCompressingContext => '正在压缩上下文';

  @override
  String get chatContextCompressed => '上下文已压缩';

  @override
  String get chatCompactionSummary => '接手요약';

  @override
  String get chatStatusReadingMemory => '正在读取记忆';

  @override
  String get chatToolRunning => '工具执行중간';

  @override
  String get chatToolSucceeded => '工具执行成功';

  @override
  String get chatToolFailed => '工具执行실패';

  @override
  String get chatEffortNone => '不思考';

  @override
  String get chatEffortMinimal => '매우 낮음';

  @override
  String get chatEffortLow => '낮음';

  @override
  String get chatEffortMedium => '중간';

  @override
  String get chatEffortHigh => '높음';

  @override
  String get chatEffortXHigh => '매우 높음';

  @override
  String get chatEffortMax => '最높음';

  @override
  String get searchModels => '검색모델';

  @override
  String get chatAddAttachment => '添加附件';

  @override
  String get chatUploadFile => '上传파일';

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
    return '正在上传 $count 个파일…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return '图片超过 $size,请压缩后재시도';
  }

  @override
  String get attachmentUnsupportedImageType => '없음法识别图片유형,仅支持 jpg/png/gif/webp';

  @override
  String get attachmentReadFileFailed => '없음法读取所选파일';

  @override
  String get attachmentUploadFailed => '上传실패';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get imagePreview => '图片预览';

  @override
  String get imageLoadFailed => '图片불러오기실패,파일可能已被移动或삭제';

  @override
  String get close => '닫기';

  @override
  String get fileFallback => '파일';

  @override
  String get skillsTitle => 'Skill 管理';

  @override
  String get skillsSubtitle => '浏览、가져오기与管理写作技能';

  @override
  String get skillsNew => '새로 만들기技能';

  @override
  String get skillsImport => '가져오기 Markdown';

  @override
  String get skillsScopeTitle => '선택범위';

  @override
  String get skillsScopeGlobal => '';

  @override
  String get skillsScopeProject => '프로젝트技能';

  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills,跨프로젝트共享';

  @override
  String get skillsScopeProjectHint => '~/workspace/.codecraft/skills,随현재작업 영역';

  @override
  String skillsProjectGroup(String name) {
    return '현재 프로젝트($name)';
  }

  @override
  String get skillsNoProjectSkills => '현재 프로젝트还没有技能';

  @override
  String get skillsNoGlobalSkills => '还没有전역技能';

  @override
  String get skillsEmpty => '还没有技能';

  @override
  String get skillsEmptyHint => '技能是写给 AI 的专개작업설명;가져오기 SKILL.md 或手动새로 만들기一个吧。';

  @override
  String get skillsName => '이름';

  @override
  String get skillsDescription => '描述';

  @override
  String get skillsDescriptionHint => '何时使用这个技能(会进系统팁)';

  @override
  String get skillsInstructions => '指令正文';

  @override
  String get skillsInstructionsHint => '技能要执行的步骤,Markdown 书写';

  @override
  String skillsImported(String name) {
    return '已가져오기技能「$name」';
  }

  @override
  String get skillsDeleteTitle => '삭제技能';

  @override
  String skillsDeleteConfirm(String name) {
    return '삭제하시겠습니까?技能「$name」(含其디렉토리与脚本)?';
  }

  @override
  String get skillsErrorInvalidName => '技能名없음效:不能为空、超长或含 / \\ : * ? \" < > |';

  @override
  String get skillsErrorEmptyInstructions => '指令正文不能为空';

  @override
  String skillsErrorNameConflict(String name) {
    return '同범위已有名为「$name」的技能';
  }

  @override
  String get skillsErrorNoSkill => '파일里没有可识别的技能';

  @override
  String get skillsErrorIoFailed => '读写技能파일실패';

  @override
  String get providerAdd => '添加供应商';

  @override
  String get providerEdit => '编辑供应商';

  @override
  String get providerEditModel => '编辑모델';

  @override
  String get providerConfig => '구성';

  @override
  String get providerSectionBasic => '기본 정보';

  @override
  String get providerSectionType => '上游格式';

  @override
  String get providerSectionOptions => '옵션';

  @override
  String get providerFullUrl => '完整 URL';

  @override
  String get providerFullUrlDesc => 'Base URL 即完整요청地址,不自动拼接默认경로';

  @override
  String get providerHeadersTitle => '사용자 정의요청 헤더';

  @override
  String get providerHeadersDesc => '完全覆盖该供应商요청的同名默认头';

  @override
  String get providerHeadersAdd => '添加요청 헤더';

  @override
  String get providerHeadersManage => '管理';

  @override
  String providerHeadersCount(int count) {
    return '설정됨 $count 个요청 헤더';
  }

  @override
  String get providerShowApiKey => '显示密钥';

  @override
  String get providerHideApiKey => '隐藏密钥';

  @override
  String get providerAddModel => '添加모델';

  @override
  String get providerNoModels => '暂없음모델';

  @override
  String get providerNoModelsHint => '点击右上方按钮添加모델';

  @override
  String get providerModelCurrent => '현재';

  @override
  String providerModelsCount(String count) {
    return '모델($count)';
  }

  @override
  String get providerModelsSelect => '다중 선택';

  @override
  String providerModelsSelectedCount(int count) {
    return '선택됨 $count 개';
  }

  @override
  String get providerModelsSelectAll => '모두 선택';

  @override
  String get providerModelsDeselectAll => '전체 선택 취소';

  @override
  String get providerModelsBatchTest => '测试';

  @override
  String get providerModelsBatchDelete => '삭제';

  @override
  String get providerModelsBatchDeleteTitle => '삭제모델';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '선택한 항목을 삭제하시겠습니까? $count 个모델吗?';
  }

  @override
  String get providerFetchModels => '拉取모델';

  @override
  String get providerAddAllModels => '전체添加';

  @override
  String get providerAddAllModelsTitle => '添加전체모델';

  @override
  String providerAddAllModelsConfirm(int count) {
    return '확인将拉取到的 $count 个모델전체添加至현재제공자?';
  }

  @override
  String get providerFilterModelsHint => '输入모델이름筛选';

  @override
  String get providerNoMatchingModels => '没有匹配的모델';

  @override
  String providerModelAdded(String name) {
    return '已添加모델「$name」';
  }

  @override
  String get providerModelName => '모델이름';

  @override
  String get providerModelAlreadyAdded => '该모델已添加';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · ${latency}ms';
  }

  @override
  String get providerFetchMissingFields => '응답缺少列表字段';

  @override
  String get providerFetchFailed => '拉取모델실패';

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
  String get providerModelReasoningHint => '只勾选该모델真实支持的档位;전체不勾则由기본 제공能力表自动判断';

  @override
  String get providerModelReasoningCanDisable => '可以닫기思考';

  @override
  String get providerTestRequestUrl => '요청地址';

  @override
  String get providerTestRequestHeaders => '요청 헤더';

  @override
  String get providerTestRequestBody => '요청 본문';

  @override
  String get providerTestResponse => '응답';

  @override
  String get providerTestError => '오류상세';

  @override
  String get providerMultiKeyTitle => '多 Key 模式';

  @override
  String get providerMultiKeySubtitle => '同一供应商下配多个 Key,密钥사용 불가时自动切换并重发';

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
  String get providerMultiKeyWeightHint => '默认 1 · ≤ 0 时不参与 · 최대 1,000,000';

  @override
  String get providerMultiKeyStrategy => '取用策略';

  @override
  String get providerMultiKeyStrategySequential => '顺序';

  @override
  String get providerMultiKeyStrategySequentialDesc => '始终用靠前的 Key,실패达阈值才切下一个';

  @override
  String get providerMultiKeyStrategyRoundRobin => '轮询';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc =>
      '新세션轮流起步以摊平额度;同一세션内不换 Key,保持缓存命중간';

  @override
  String get providerMultiKeyStatusCodes => '自动切换상태 코드';

  @override
  String get providerMultiKeyStatusCodesHint => '逗号分隔,留空使用默认 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => '冷却时长';

  @override
  String get providerMultiKeyCooldownDesc => '被切走的 Key 隔多久重新纳入候选';

  @override
  String get workspaceOpen => '작업 영역';

  @override
  String get workspaceLocal => '로컬작업 영역';

  @override
  String get workspaceLocalSubtitle => '应用数据디렉토리';

  @override
  String get allow => '允许';

  @override
  String get deny => '拒绝';

  @override
  String get tabFiles => '파일';

  @override
  String get newFile => '새로 만들기파일';

  @override
  String get newFolder => '새로 만들기폴더';

  @override
  String get create => '만들기';

  @override
  String get deleteFileConfirm => '삭제하시겠습니까?该파일?';

  @override
  String get deleteFolderConfirm => '삭제하시겠습니까?该폴더(含내용)?';

  @override
  String get refresh => '새로고침';

  @override
  String get workspaceNew => '새로 만들기';

  @override
  String get workspaceEmptyHint => '还没有작업 영역,点右上角「새로 만들기」';

  @override
  String get workspaceNameExists => '同名작업 영역已存在';

  @override
  String get workspaceDelete => '삭제작업 영역';

  @override
  String workspaceDeleteConfirm(String name) {
    return '삭제하시겠습니까?작업 영역「$name」(含其중간전체파일)?';
  }

  @override
  String get todoDashboardTitle => '任务待办';

  @override
  String todoDashboardProgress(int completed, int total) {
    return '$completed/$total 완료';
  }

  @override
  String get todoDashboardAllDone => '전체완료';

  @override
  String get todoInProgress => '진행 중';

  @override
  String get todoCompleted => '완료';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitRefresh => '새로고침';

  @override
  String get gitTabStatus => '상태';

  @override
  String get browserTitle => '浏览器';

  @override
  String get browserAddressHint => '输入网址或검색';

  @override
  String get browserBack => '后退';

  @override
  String get browserForward => '前进';

  @override
  String get browserReload => '새로고침';

  @override
  String get browserNotReady => '浏览器준비 안 됨,请在地址栏输入网址시작浏览';

  @override
  String get browserNewTab => '새로 만들기태그页';

  @override
  String get browserCloseTab => '닫기태그页';

  @override
  String get browserTabDefaultTitle => '新태그页';

  @override
  String browserTabsCount(int count) {
    return '태그页 ($count)';
  }

  @override
  String get browserEmptyHint => '在上方地址栏输入网址시작浏览';

  @override
  String get browserTabsManage => '태그页管理';

  @override
  String get browserEmptyClickHint => '点击上方输入网址시작浏览';

  @override
  String get browserNightModeOn => '닫기夜间模式';

  @override
  String get browserNightModeOff => '활성화夜间模式';

  @override
  String get browserDevtools => '开发者工具';

  @override
  String get browserDialogAlertTitle => '网页팁';

  @override
  String get browserDialogConfirmTitle => '网页确认';

  @override
  String get browserDialogPromptTitle => '网页输入';

  @override
  String get browserMenu => '더보기설정';

  @override
  String get browserMenuTitle => '浏览器설정与工具';

  @override
  String get browserMenuGeneralSection => '页面与工具';

  @override
  String get browserNightModeTitle => '夜间模式';

  @override
  String get browserNightModeDesc => '降낮음页面亮度并활성화深色偏好';

  @override
  String get browserDevtoolsTitle => '开发者工具';

  @override
  String get browserDevtoolsDesc => '활성화移动端 Eruda 디버그控制台';

  @override
  String get browserUaSection => '浏览器标识 (User-Agent)';

  @override
  String get browserUaDesc => '模拟不同设备与环境访问网页';

  @override
  String get browserUaDefault => '系统默认';

  @override
  String get browserUaDefaultDesc => '현재设备原生 WebView 标识';

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
  String get browserUaCustom => '사용자 정의';

  @override
  String get browserUaCustomDesc => '手动指定 User-Agent 字符串';

  @override
  String get browserUaCustomDialogTitle => '사용자 정의 User-Agent';

  @override
  String get browserUaCustomInputHint => '输入完整的 User-Agent 字符串';

  @override
  String get browserUaAppliedToast => '已切换浏览器标识并새로고침页面';

  @override
  String get gitTabBranches => '브랜치';

  @override
  String get gitTabCommits => '提交';

  @override
  String get gitStatusClean => '작업 영역干净,없음改动';

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
  String get gitUnstage => '취소暂存';

  @override
  String get gitStageAll => '暂存전체';

  @override
  String get gitUnstageAll => '전체취소暂存';

  @override
  String get gitUnstageAllConfirm => '将취소所有파일的暂存,但不会삭제파일내용。확인继续吗?';

  @override
  String get gitActionRevertAll => '전체回退';

  @override
  String gitRevertAllConfirm(int count) {
    return '丢弃전체未暂存的改动($count 个파일),복원到上次暂存或提交的내용?已暂存的내용不受影响,但丢弃的改动없음法找回。';
  }

  @override
  String get gitActionRestoreFile => '恢复파일';

  @override
  String gitRevertConfirmWorktree(String name) {
    return '把 $name 복원成上次暂存或提交的내용?未暂存的改动会丢失,且없음法找回。';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return '把 $name 복원到上次提交的내용?该파일已暂存和未暂存的改动都会丢失,且없음法找回。';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return '恢复已삭제的 $name?将从上次提交取回这个파일。';
  }

  @override
  String get gitActionDeleteFile => '삭제파일';

  @override
  String get gitActionDeleteDir => '삭제디렉토리';

  @override
  String get gitMergePendingTitle => '合并待提交';

  @override
  String get gitMergePendingHint => '현재没有未解决的冲突。请确认并暂存需要保留的改动,然后提交以완료合并。';

  @override
  String get gitActionAbortMerge => '중단合并';

  @override
  String get gitAbortMergeConfirm => '확인중단현재合并吗?未解决的冲突改动将被放弃,작업 영역将복원到合并前的상태。';

  @override
  String get gitCommitChanges => '提交更改';

  @override
  String get gitCommitNeedsIdentity => '尚미설정提交署名,请在「凭据与署名」页填写用户名和邮箱';

  @override
  String get gitCommitDialogTitle => '提交更改';

  @override
  String get gitCommitMessage => '提交정보';

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
  String get gitStashMessageHint => '储藏설명(선택 사항)';

  @override
  String get gitStashIncludeUntracked => '包含未跟踪파일(-u)';

  @override
  String get gitStashEmpty => '暂없음储藏기록';

  @override
  String get gitStashPop => '弹出 (Pop)';

  @override
  String get gitStashApply => '应用 (Apply)';

  @override
  String get gitStashDrop => '丢弃 (Drop)';

  @override
  String gitStashDropConfirm(String index) {
    return '확인丢弃储藏 $index 吗?该작업不可撤销。';
  }

  @override
  String get gitStashClear => '清空전체';

  @override
  String get gitStashClearConfirm => '확인清空所有储藏기록吗?该작업不可撤销。';

  @override
  String gitStashCount(int count) {
    return '储藏 ($count)';
  }

  @override
  String get gitPull => '拉取';

  @override
  String get gitPush => '推送';

  @override
  String get gitPullDirtyConfirm => '현재작업 영역有未提交改动,拉取可能导致冲突。建议先提交或暂存。仍要继续拉取吗?';

  @override
  String get gitPullContinue => '继续拉取';

  @override
  String get gitNoUpstream => '미설정上游';

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
  String get gitDetachedHeadLabel => 'detached HEAD:현재不在任何브랜치上';

  @override
  String get gitNoBranch => '(없음브랜치)';

  @override
  String get gitLoadingBranches => '正在불러오기브랜치列表…';

  @override
  String get gitNoCheckedOutBranch => '未检出브랜치';

  @override
  String get gitClean => '작업 영역干净';

  @override
  String get gitHasChanges => '작업 영역有改动';

  @override
  String get gitNotARepo => '현재작업 영역还不是 Git 저장소';

  @override
  String get gitCloningHint => '正在克隆저장소,请稍候…';

  @override
  String get gitInitDescPrimary => '可在此初始化新저장소,시작版本管理';

  @override
  String get gitInitDescSecondary => '若子디렉토리已有 Git 저장소,也可直接선택使用';

  @override
  String get gitInitRepo => '初始化新저장소';

  @override
  String get gitCloneRepo => '克隆远程저장소';

  @override
  String get gitCloneDialogTitle => '克隆 Git 저장소';

  @override
  String get gitCloneDesc =>
      '将远程저장소克隆到현재작업 영역根디렉토리(작업 영역需为空)。若为私有저장소,可先点右上角钥匙登录 GitHub 或填入访问令牌。';

  @override
  String get gitCloneUrlLabel => '저장소地址';

  @override
  String get gitCloning => '正在克隆저장소,请稍候…';

  @override
  String get gitSwitchRepo => '切换저장소';

  @override
  String get gitPickExistingRepo => '선택已有저장소';

  @override
  String get gitRepoSelectorTitle => '선택저장소';

  @override
  String get gitRepoNotRepo => '非저장소';

  @override
  String get gitPickRepoEmpty => '현재작업 영역没有선택 사항的디렉토리';

  @override
  String get gitNoBranches => '暂없음브랜치';

  @override
  String get gitNewBranch => '새로 만들기브랜치';

  @override
  String get gitBranchName => '브랜치名';

  @override
  String get gitBaseBranch => '基准브랜치';

  @override
  String get gitCreateAndSwitch => '만들기并切换';

  @override
  String get gitDeleteBranch => '삭제브랜치';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '삭제로컬브랜치 $name?';
  }

  @override
  String get gitDeleteRemoteBranch => '삭제远程브랜치';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return '삭제远程브랜치 $name?该작업不可撤销。';
  }

  @override
  String get gitRenameBranch => '重命名브랜치';

  @override
  String gitRenameTo(String name) {
    return '将 $name 重命名为:';
  }

  @override
  String get gitNewBranchName => '新브랜치名';

  @override
  String get gitTags => '태그';

  @override
  String get gitTagName => '태그名';

  @override
  String get gitDeleteTag => '삭제태그';

  @override
  String gitDeleteTagConfirm(String name) {
    return '삭제로컬태그 $name?';
  }

  @override
  String gitCreateTagDesc(String hash) {
    return '从현재 HEAD($hash)만들기가벼움태그';
  }

  @override
  String get gitCheckedOut => '현재检出';

  @override
  String get gitCurrentBranch => '현재브랜치';

  @override
  String get gitRemote => '远程';

  @override
  String get commonLocal => '로컬';

  @override
  String get gitNew => '新增';

  @override
  String get gitNoCommits => '暂없음提交기록';

  @override
  String gitCommitCount(int count) {
    return '提交기록 ($count)';
  }

  @override
  String get gitSearchCommitsHint => '검색提交설명或作者…';

  @override
  String get gitLoadMoreCommits => '上拉불러오기更早提交';

  @override
  String get gitNoMoreCommits => '没有더보기了';

  @override
  String get gitLatestCommit => '最新提交';

  @override
  String gitFilesChanged(int count) {
    return '$count 个파일改动';
  }

  @override
  String get gitNoFilesChanged => '该提交없음파일改动';

  @override
  String get gitMergeCommit => '合并提交';

  @override
  String get gitLoadingFiles => '正在불러오기改动파일…';

  @override
  String get gitCopyShortHash => '복사短哈希';

  @override
  String get gitCopyFullHash => '복사完整哈希';

  @override
  String get gitActionCreateBranch => '만들기브랜치';

  @override
  String get gitActionCreateTag => '만들기태그';

  @override
  String get gitCreateBranchFromCommit => '基于此提交만들기브랜치';

  @override
  String get gitCreateTagAtCommit => '在此提交만들기태그';

  @override
  String get gitResetToCommit => '재설정到此提交 (Reset)';

  @override
  String get gitResetSoft => 'Soft(保留작업 영역与暂存区)';

  @override
  String get gitResetMixed => 'Mixed(保留작업 영역,清空暂存区)';

  @override
  String gitResetConfirm(String hash) {
    return '확인将현재브랜치재설정到提交 $hash 吗?';
  }

  @override
  String get gitDiffBinary => '二进制파일,不显示差异';

  @override
  String get gitDiffTooLarge => '파일过大,未计算差异';

  @override
  String get gitDiffEmpty => '没有可显示的差异';

  @override
  String get gitCopyPath => '경로 복사';

  @override
  String get gitViewDiff => '查看差异';

  @override
  String get gitRevert => '回退改动';

  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return '삭제 $name?它从未被提交过,삭제后없음法通过 Git 恢复。';
  }

  @override
  String get gitAddToGitignore => '添加到 .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return '忽略此파일 ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return '忽略整个디렉토리 ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return '忽略同유형파일 (*.$ext)';
  }

  @override
  String get gitPathCopied => '已경로 복사';

  @override
  String gitActionFailed(String action, String error) {
    return '$action실패:$error';
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
  String get gitNoRemotePull => '미설정远程저장소,없음法拉取';

  @override
  String get gitNoRemotePush => '미설정远程저장소,없음法推送';

  @override
  String get gitPushMasterConfirmTitle => '브랜치命名建议';

  @override
  String get gitPushMasterConfirmDesc =>
      '현재로컬브랜치为 master,GitHub 与 GitLab 推荐使用 main 作为默认主브랜치。是否将로컬브랜치重命名为 main 后再推送?';

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
  String get gitRepoUrl => '저장소地址';

  @override
  String get gitSelectBranch => '선택基准브랜치';

  @override
  String get credentialTokenLogin => '令牌登录';

  @override
  String get credentialTokenLoginDesc => '只需붙여넣기访问令牌(PAT),推送时自动匹配远端主机';

  @override
  String get credentialTokenSaved => '令牌已저장';

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
  String get themeSubtitle => '外观、배경与显示';

  @override
  String get aboutSubtitle => '版本、更新与反馈';

  @override
  String get aboutAutoCheck => '自动检查更新';

  @override
  String get aboutAutoCheckDesc => '열기 App 时自动检测新版本';

  @override
  String get aboutUpdateChannel => '更新通道';

  @override
  String get aboutStableChannel => '稳定版';

  @override
  String get aboutDownloadMirror => '下载镜像源';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub 저장소';

  @override
  String get aboutUserAgreement => '用户프로토콜';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get mcpTitle => 'MCP 서버';

  @override
  String get mcpSubtitle => '接入外部工具的 Model Context Protocol 服务';

  @override
  String get mcpAdd => '添加 MCP';

  @override
  String get mcpEdit => '编辑 MCP';

  @override
  String get mcpEmpty => '还没有구성 MCP 서버';

  @override
  String get mcpEmptyHint => '点击右上角 + 可以添加远程 HTTP 或로컬 stdio 服务器';

  @override
  String get mcpSearchPlaceholder => '검색 MCP 서버…';

  @override
  String get mcpSearchEmpty => '未找到匹配的 MCP 서버';

  @override
  String get mcpScopeLabel => '범위';

  @override
  String get mcpScopeGlobal => '전역';

  @override
  String get mcpScopeProject => '프로젝트';

  @override
  String get mcpTypeStdio => 'stdio';

  @override
  String get mcpStatusDisabled => '비활성화됨';

  @override
  String get mcpStatusNotConnected => '未连接';

  @override
  String get mcpStatusConnected => '已连接';

  @override
  String get mcpStatusConnecting => '连接중간…';

  @override
  String get mcpStatusFailed => '연결 실패';

  @override
  String get mcpStatusNeedsAuth => '需要登录';

  @override
  String mcpToolsCount(int count) {
    return '$count 个工具';
  }

  @override
  String get mcpDetails => '상세';

  @override
  String get mcpBasicSettings => '기본설정';

  @override
  String get mcpEnabledLabel => '是否활성화';

  @override
  String get mcpNameLabel => '이름';

  @override
  String get mcpNameHint => '例如:fetch、github、gitlab';

  @override
  String get mcpNameInvalid => '이름只能包含字母、数字、下划线和连字符';

  @override
  String get mcpTransportType => '传输유형';

  @override
  String get mcpRemoteHttp => '远程 HTTP';

  @override
  String get mcpLocalStdio => '로컬 stdio';

  @override
  String get mcpServerUrl => '服务器地址';

  @override
  String get mcpServerUrlHint => '例如:https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => '사용자 정의요청 헤더';

  @override
  String get mcpNoCustomHeaders => '暂없음구성的사용자 정의 Header';

  @override
  String get mcpHeaderName => '요청 헤더이름';

  @override
  String get mcpHeaderNameHint => '如 Authorization';

  @override
  String get mcpHeaderValue => '요청 헤더值';

  @override
  String get mcpHeaderValueHint => '如 Bearer xxxxxx';

  @override
  String get mcpAddHeader => '添加요청 헤더';

  @override
  String get mcpCommand => '시작命令';

  @override
  String get mcpCommandHint => '例如:npx';

  @override
  String get mcpArgs => '命令参数';

  @override
  String get mcpNoArgs => '없음额外命令行参数';

  @override
  String get mcpArgValue => '参数值';

  @override
  String get mcpArgHint => '如 -y 或 @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => '添加参数';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return '활성화됨 $enabled / $total 个工具';
  }

  @override
  String get mcpToolsSearch => '검색工具이름或描述…';

  @override
  String get mcpToolsSearchEmpty => '未找到匹配的工具';

  @override
  String get mcpToolsEnableAll => '전체활성화';

  @override
  String get mcpToolsDisableAll => '전체비활성화';

  @override
  String get mcpSaveFirstHint => '请先저장并连接服务器后查看工具列表';

  @override
  String get mcpNoToolsHint => '未检测到工具,点击右上角새로고침按钮재시도';

  @override
  String get mcpNoDescription => '없음描述';

  @override
  String get mcpAddSheetTitle => '添加 MCP 서버';

  @override
  String get mcpAddManual => '手动填写';

  @override
  String get mcpAddManualDesc => '逐个填写地址、요청 헤더或시작命令';

  @override
  String get mcpAddFromJson => '从 JSON 가져오기';

  @override
  String get mcpAddFromJsonDesc => '붙여넣기标准 mcpServers 구성批量가져오기';

  @override
  String get mcpJsonImportTitle => '从 JSON 가져오기';

  @override
  String get mcpJsonImportHint =>
      '붙여넣기标准 mcpServers 구성:键是服务器名,值里填 url(远程 HTTP)或 command(로컬 stdio)。';

  @override
  String get mcpJsonImportAction => '가져오기';

  @override
  String get mcpJsonImportEmpty => '未解析到任何 MCP 서버';

  @override
  String get mcpSaved => '已저장';

  @override
  String get mcpRefreshTools => '새로고침工具';

  @override
  String get mcpRemoved => '已移除 MCP 서버';

  @override
  String get permissionsTitle => '工具授权';

  @override
  String get permissionsSubtitle => '规则与记忆';

  @override
  String permCurrentProject(String name) {
    return '현재 프로젝트:$name';
  }

  @override
  String get permCurrentProjectNone => '현재 프로젝트(未선택)';

  @override
  String get permNoProjectRules => '本프로젝트暂없음规则';

  @override
  String get permGlobal => '전역';

  @override
  String get permNoGlobalRules => '暂없음전역规则';

  @override
  String get permEntireTool => '整个工具';

  @override
  String get permDeny => '禁止';

  @override
  String get permPromoteToGlobal => '提升为전역';

  @override
  String get permRulesShort => '对话중간选「始终실행」会在현재 프로젝트生成记忆规则';

  @override
  String get chatPermDeny => '拒绝';

  @override
  String get chatPermAlwaysAllow => '始终실행';

  @override
  String get chatPermAlwaysToolDesc => '「始终실행」将在本프로젝트记住:该工具的전체调用';

  @override
  String get chatPermAlwaysPrefix => '「始终실행」将在本프로젝트记住:';

  @override
  String get chatPermSingleUseDesc => '该调用不可记忆,仅可单次放行';

  @override
  String get commonName => '이름';

  @override
  String get commonTool => '工具';

  @override
  String get commonAdd => '添加';

  @override
  String commonLabelWithApi(String label, String api) {
    return '$label($api)';
  }

  @override
  String get commonExpand => '펼치기';

  @override
  String get commonCollapse => '收起';

  @override
  String get mcpViewLogs => '查看此 MCP 로그';

  @override
  String get mcpAuthEnable => 'OAuth 认证';

  @override
  String get mcpAuthDesc => '用于需要浏览器登录授权的远程 MCP 服务';

  @override
  String get mcpAuthClientId => 'client_id(선택 사항)';

  @override
  String get mcpAuthClientIdHint => '预注册的客户端 ID;留空则尝试动态注册';

  @override
  String get mcpAuthServer => '授权服务器(선택 사항)';

  @override
  String get mcpAuthServerHint => '覆盖自动发现的授权服务器地址';

  @override
  String get mcpAuthAdvanced => '고급认证옵션';

  @override
  String get mcpAuthLogin => '登录 / 重新授权';

  @override
  String get mcpAuthReauthorize => '重新授权';

  @override
  String get mcpAuthLogout => '退出登录';

  @override
  String get mcpAuthCancel => '취소授权';

  @override
  String get mcpAuthInProgress => '대기浏览器授权…';

  @override
  String get mcpAuthInProgressHint => '已在系统浏览器열기登录页,授权완료后将自动返回并连接';

  @override
  String get mcpAuthSaveFirst => '저장服务器구성后,即可在此发起登录授权';

  @override
  String mcpAuthFailed(String message) {
    return '授权실패:$message';
  }

  @override
  String get mcpAuthStatusLabel => '授权상태';

  @override
  String get mcpAuthStatusAuthorized => '已登录';

  @override
  String get mcpAuthStatusUnauthorized => '未登录';

  @override
  String get mcpAuthStatusAuthorizing => '授权중간';

  @override
  String get mcpAuthSuccess => '授权成功,已连接';

  @override
  String get settingsReconnect => '重新连接';

  @override
  String get settingsAddMcpServer => '添加 MCP 서버';

  @override
  String get settingsContainer => '容器与镜像';

  @override
  String get settingsContainerSubtitle => 'PRoot 容器、镜像与初始化';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonSwitch => '切换';

  @override
  String get chatOpenTerminal => '열기터미널';

  @override
  String get terminalTitle => '터미널';

  @override
  String terminalStartFailed(String message) {
    return '없음法시작터미널:';
  }

  @override
  String get terminalRetry => '재시도';

  @override
  String get terminalNoOpenTabs => '没有열기的터미널태그';

  @override
  String get terminalNewTab => '새로 만들기태그';

  @override
  String get terminalCloseTab => '닫기태그';

  @override
  String get terminalSettingsTitle => '터미널설정';

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
  String get terminalFontSizeTitle => '字体크기';

  @override
  String get terminalCursorStyleTitle => '光标样式';

  @override
  String get terminalCursorBlock => '方块';

  @override
  String get terminalCursorUnderline => '下划线';

  @override
  String get terminalCursorBar => '竖线';

  @override
  String get terminalFontTitle => '터미널字体';

  @override
  String get terminalFontDefault => '系统等宽';

  @override
  String get terminalFontBuiltin => 'JetBrains Mono';

  @override
  String get settingsGeneral => '偏好설정';

  @override
  String get settingsGeneralModels => '모델';

  @override
  String get settingsAutoRemoveStaleModels => '拉取모델后自动移除없음效모델';

  @override
  String get settingsAutoRemoveStaleModelsDesc => '拉取成功后,移除远端已不存在的로컬모델개目';

  @override
  String get settingsGeneralSession => '세션';

  @override
  String get settingsStartupSession => '시작时세션';

  @override
  String get settingsStartupSessionNew => '新开세션';

  @override
  String get settingsStartupSessionNewDesc => '复用尚未发送过消息的空세션,否则새로 만들기';

  @override
  String get settingsStartupSessionRecent => '열기最近세션';

  @override
  String get settingsStartupSessionRecentDesc => '直接进入最近更新的세션';

  @override
  String get settingsDeleteExternalWorkspaceSessions => '삭제外部작업 영역채팅 기록';

  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc =>
      '移除外部로컬작업 영역时,一并삭제该작업 영역的채팅 기록';

  @override
  String get settingsGeneralInput => '输入';

  @override
  String get settingsEnterToSend => '回车键发送消息';

  @override
  String get settingsEnterToSendDesc => '닫기后回车换行,需点发送按钮发送';

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
  String get settingsFirstByteTimeoutDesc => '대기首个응답块的最长时间';

  @override
  String get settingsStreamIdleTimeout => '数据块间隔超时';

  @override
  String get settingsStreamIdleTimeoutDesc => '两个응답块之间的最长대기';

  @override
  String get settingsTimeoutUnlimited => '不限制';

  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get settingsTimeoutInputHint => '单位秒,填 0 表示不限制';

  @override
  String get settingsMaxNetworkRetries => '재시도次数';

  @override
  String get settingsMaxNetworkRetriesDesc => '网络실패后的指数退避재시도次数';

  @override
  String settingsRetriesCount(int count) {
    return '$count 次';
  }

  @override
  String get settingsRetriesInputHint => '填 0 表示不재시도';

  @override
  String get settingsGeneralTools => '工具';

  @override
  String get settingsSendfileMaxSize => 'sendFile 单파일上限';

  @override
  String get settingsGeneralGoal => '목표(goal)';

  @override
  String get settingsGoalMaxTurns => '최대续跑轮数';

  @override
  String get settingsGoalMaxTurnsDesc => '自主循环最多续跑多少轮,达到即중지';

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
  String get settingsSendfileMaxSizeDesc => '单个파일크기上限,超过则整批发送실패';

  @override
  String get settingsSendfileMaxSizeInputHint => '单位 MB,填大于 0 的整数';

  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }

  @override
  String providerModelsAlignedRemoved(int count) {
    return '已移除 $count 个远端已不存在的모델';
  }

  @override
  String get tokenStatsTitle => 'Token 统计';

  @override
  String get tokenStatsPeriodToday => '今일';

  @override
  String get tokenStatsPeriod7d => '近7일';

  @override
  String get tokenStatsPeriod30d => '近30일';

  @override
  String get tokenStatsPeriodAll => '전체';

  @override
  String get tokenStatsTotal => '总消耗';

  @override
  String get tokenStatsRequests => '요청次数';

  @override
  String get tokenStatsCost => '费用';

  @override
  String get tokenStatsCacheHitRate => '缓存命중간率';

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
  String get tokenStatsModel => '모델统计';

  @override
  String tokenStatsSuccessRate(String rate) {
    return '成功率 $rate';
  }

  @override
  String get tokenStatsRecentCalls => '调用기록';

  @override
  String get tokenStatsUnknown => '알 수 없음';

  @override
  String get tokenStatsNoData => '暂없음数据';

  @override
  String get tokenStatsCallsSuffix => '次调用';

  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count 次调用';
  }

  @override
  String get tokenStatsColModel => '모델';

  @override
  String get tokenStatsColReasoningEffort => '사고 강도';

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
  String get tokenStatsColCacheHitRate => '命중간率';

  @override
  String get tokenStatsColTtfb => '首字节';

  @override
  String get tokenStatsColDuration => '소요 시간';

  @override
  String get tokenStatsColTime => '时间';

  @override
  String get tokenStatsColStatus => '상태';

  @override
  String get tokenStatsColCost => '费用';

  @override
  String tokenStatsPage(int page, int total) {
    return '第 $page / $total 页';
  }

  @override
  String tokenStatsRetries(int count) {
    return '재시도 $count 次';
  }

  @override
  String get tokenStatsReset => '재설정';

  @override
  String get tokenStatsResetTitle => '재설정 Token 统计';

  @override
  String get tokenStatsResetConfirm => '将清空전체调用기록,此작업不可恢复。확인재설정?';

  @override
  String get tokenStatsFilterAllProviders => '전체供应商';

  @override
  String get tokenStatsFilterAllModels => '전체모델';

  @override
  String get tokenStatsFilterClear => '清除筛选';

  @override
  String tokenStatsFilterProvider(String name) {
    return '供应商:$name';
  }

  @override
  String tokenStatsFilterModel(String name) {
    return '모델:$name';
  }

  @override
  String tokenStatsProviderKeys(int count) {
    return '$count 个密钥';
  }

  @override
  String get tokenStatsRequestsUnit => '次요청';

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
  String get gitActionMerge => '合并브랜치';

  @override
  String get gitActionStageAll => '전체暂存';

  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';

  @override
  String get gitComputingDiff => '正在计算差异…';

  @override
  String get gitCreateTagTitle => '새로 만들기태그';

  @override
  String gitCreateTrackingBranch(String branch) {
    return '从远程브랜치 $branch 만들기로컬跟踪브랜치并切换?';
  }

  @override
  String get gitCredentialsAndIdentity => '凭据与署名';

  @override
  String gitDetachedHeadWarning(String ref) {
    return '切换到태그 $ref 将进入 detached HEAD 상태——不处于任何브랜치上,新提交不属于任何브랜치。확인继续?';
  }

  @override
  String gitMergeConfirm(String branch, String current) {
    return '확인将브랜치 $branch 合并到현재브랜치($current)吗?';
  }

  @override
  String get gitMergeNoFf => '만들기合并提交(--no-ff)';

  @override
  String get gitOpenInEditor => '在编辑器중간열기';

  @override
  String get gitSwitchBranch => '切换브랜치';

  @override
  String gitSwitchConfirm(String ref) {
    return '확인切换到 $ref?';
  }

  @override
  String gitToastLoadBranchesFailed(String error) {
    return '불러오기브랜치실패:$error';
  }

  @override
  String gitToastRefreshFailed(String error) {
    return '새로고침실패:$error';
  }

  @override
  String gitToastActionRefreshFailed(String message) {
    return '$message(새로고침실패)';
  }

  @override
  String gitToastLoadMoreFailed(String error) {
    return '불러오기더보기실패:$error';
  }

  @override
  String gitToastCheckoutFailed(String error) {
    return '切换실패:$error';
  }

  @override
  String get gitToastNotRepo => '该디렉토리不是 Git 저장소';

  @override
  String gitToastSwitchRepoFailed(String error) {
    return '切换저장소실패:$error';
  }

  @override
  String get gitToastDiffFailed => '불러오기差异실패';

  @override
  String get gitToastNoDiffForCommit => '暂存区与작업 영역均없음差异,없음法生成提交정보';

  @override
  String get gitToastGenerateCommitFailed => 'AI 生成提交정보실패,请检查모델或网络';

  @override
  String get diffBinaryFile => '二进制파일,不支持文本差异对比';

  @override
  String get diffFileTooLarge => '파일过大,已跳过差异计算';

  @override
  String get diffFileTooLargeDesc => '超过 2000 行或含超长行的파일不做行级 diff,以避免渲染与内存压力。';

  @override
  String get diffNoChanges => '없음差异';

  @override
  String get back => '返回';

  @override
  String get chatOpenGit => '열기 Git';

  @override
  String get switchLabel => '切换';

  @override
  String get credentialEdit => '编辑凭据';

  @override
  String get credentialToastSaved => '凭据已저장';

  @override
  String credentialToastSaveFailed(String param1) {
    return '저장 실패:%1\$s';
  }

  @override
  String get credentialToastDeleted => '凭据已삭제';

  @override
  String get credentialToastIdentitySaved => '署名与저장소地址已저장';

  @override
  String get credentialEmptyHint => '尚未添加凭据,点右上角 + 添加';

  @override
  String get credentialEmptyTitle => '暂없음 Git 자격 증명';

  @override
  String get credentialEmptyDesc => '구성凭据后,Codecraft 可在推送或拉取代码저장소时自动완료身份认证';

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
    return '현재连接 GitHub Codespace $name';
  }

  @override
  String get gitRepoUrlTitle => '저장소地址';

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
    return '网络오류:$error';
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
  String get codespacesEmptyDesc => '在 GitHub 上만들기 Codespace 后,这里即可列出并连接';

  @override
  String get codespacesCreateOnWeb => '在 github.com 새로 만들기';

  @override
  String get codespacesRefresh => '새로고침';

  @override
  String get codespacesOpenInBrowser => '在浏览器열기';

  @override
  String get codespacesStart => '시작';

  @override
  String get codespacesStop => '중지';

  @override
  String get codespacesDelete => '삭제';

  @override
  String codespacesDeleteConfirm(String name) {
    return '삭제하시겠습니까? $name?该작업不可撤销';
  }

  @override
  String get codespacesStateAvailable => '실행 중';

  @override
  String get codespacesStateStarting => '시작중간';

  @override
  String get codespacesStateStopped => '중지됨';

  @override
  String get codespacesStateUnknown => '상태알 수 없음';

  @override
  String codespacesLastUsed(String time) {
    return '最近使用 $time';
  }

  @override
  String get codespacesNoRepo => '알 수 없음저장소';

  @override
  String get codespacesUncommitted => '有未提交改动';

  @override
  String get codespacesMoreActions => '더보기작업';

  @override
  String get editorLoadFailed => '없음法读取该파일';

  @override
  String get editorSaveFailed => '저장 실패';

  @override
  String get editorSaved => '已저장';

  @override
  String get editorCharacters => '角色';

  @override
  String get characterTitle => '角色管理';

  @override
  String get characterNew => '새로 만들기角色';

  @override
  String get characterEdit => '编辑角色';

  @override
  String get characterEmpty => '暂없음角色';

  @override
  String get characterSearchHint => '검색角色이름、별칭或태그';

  @override
  String get characterSearchEmpty => '未找到匹配角色';

  @override
  String get characterFieldBasic => '기본 정보';

  @override
  String get characterFieldName => '이름';

  @override
  String get characterFieldNameHint => '角色的真实이름';

  @override
  String get characterFieldAlias => '별칭/称呼';

  @override
  String get characterFieldAliasHint => '故事중간常用的称呼(如:老张、小李)';

  @override
  String get characterFieldGender => '性别';

  @override
  String get characterFieldGenderHint => '男/女/기타';

  @override
  String get characterFieldAge => '나이';

  @override
  String get characterFieldAgeHint => '数字,如 25';

  @override
  String get characterFieldBirthday => '생일';

  @override
  String get characterFieldBirthdayHint => '格式:MM-DD,如 01-15';

  @override
  String get characterFieldAppearance => '외모描写';

  @override
  String get characterFieldAppearanceHint => '身높음、体型、发色、瞳色、特征等';

  @override
  String get characterFieldPersonality => '性格';

  @override
  String get characterFieldPersonalityHint => '性格特点、동작模式、说话风格等';

  @override
  String get characterFieldBackground => '배경故事';

  @override
  String get characterFieldBackgroundHint => '成长经历、重要이벤트、家庭배경等';

  @override
  String get characterFieldGoals => '목표/소망';

  @override
  String get characterFieldGoalsHint => '角色想要达成的事、追求的东西';

  @override
  String get characterFieldFears => '두려움/약점';

  @override
  String get characterFieldFearsHint => '害怕的事、心理阴影、致命약점等';

  @override
  String get characterFieldTags => '태그';

  @override
  String get characterFieldTagsHint => '用逗号分隔,如:主角、反派、魔法师';

  @override
  String get characterScope => '범위';

  @override
  String get characterScopeProject => '현재 프로젝트';

  @override
  String get characterScopeGlobal => '전역';

  @override
  String characterSelectedCount(int count) {
    return '선택됨 $count 개';
  }

  @override
  String get editorUndo => '撤销';

  @override
  String get editorRedo => '重做';

  @override
  String get editorSearch => '검색';

  @override
  String get editorSearchHint => '查找내용';

  @override
  String get editorSearchPrev => '上一个';

  @override
  String get editorSearchNext => '下一个';

  @override
  String get editorTypeset => '自动排版';

  @override
  String get editorTypesetDone => '已排版,可撤销';

  @override
  String get editorCopy => '복사';

  @override
  String get editorCopied => '已복사到剪贴板';

  @override
  String get editorUnsavedState => '未저장';

  @override
  String editorWordCount(int count) {
    return '$count 字';
  }

  @override
  String get editorNoFile => '还没有열기的파일,从差异页点「在编辑器중간열기」即可';

  @override
  String get editorUnsavedTitle => '未저장的修改';

  @override
  String get editorUnsavedMessage => '현재파일有未저장的修改,是否저장?';

  @override
  String get editorSaveAndExit => '저장并退出';

  @override
  String get editorSaveAndSwitch => '저장并切换';

  @override
  String get editorDontSave => '不저장';

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
  String get editorSettings => '编辑器설정';

  @override
  String get editorFontSize => '字体크기';

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
    return '파일过大($mb MB),暂不支持열기';
  }

  @override
  String get editorBinaryUnsupported => '二进制파일,暂不支持열기';

  @override
  String get editorSaveConflictTitle => '파일已被修改';

  @override
  String get editorSaveConflictMessage =>
      '该파일在你열기之后已被 AI 或기타程序修改。直接저장会覆盖对方的改动。';

  @override
  String editorSaveConflictDiff(String diff) {
    return '- 磁盘현재내용';
  }

  @override
  String get editorSaveConflictOverwrite => '覆盖磁盘';

  @override
  String get editorSaveConflictDiscard => '放弃我的修改';

  @override
  String get editorSaveConflictCancel => '취소';

  @override
  String get editorSaveConflictDiscarded => '已放弃修改并重新载入磁盘내용';

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
      '容器里还没有 gh(GitHub CLI)。请先在터미널명령 실행 codecraft,선택「GitHub Codespaces」场景安装依赖。';

  @override
  String get codespacesExecutionEnv => '执行环境';

  @override
  String get codespacesEnvLocal => '로컬容器';

  @override
  String get codespacesEnvCodespace => '远程 Codespace';

  @override
  String terminalRemoteEnv(String name) {
    return '远程环境:$name';
  }

  @override
  String get codespacesNew => '새로 만들기 Codespace';

  @override
  String get codespacesRepoTab => '저장소';

  @override
  String get codespacesRepoSearchHint => '검색저장소';

  @override
  String get codespacesBranch => '브랜치(留空用默认브랜치)';

  @override
  String get codespacesMachine => '机器规格';

  @override
  String get codespacesMachineDefault => '默认规格';

  @override
  String get codespacesCreate => '만들기';

  @override
  String get codespacesRename => '重命名';

  @override
  String get codespacesRenameTitle => 'Codespace 显示名';

  @override
  String get codespacesChangeMachine => '更改머신 유형';

  @override
  String get codespacesNoMachines => '该저장소没有선택 사항머신 유형';

  @override
  String get codespacesLoadFailed => '불러오기실패';

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
  String get codespacesPortOpen => '열기';

  @override
  String get codespacesRebuild => '重建容器';

  @override
  String get codespacesRebuildDesc =>
      '重建会按현재 devcontainer 重新만들기容器:代码与未提交改动保留,容器内已安装的工具与실행상태会丢失。';

  @override
  String get codespacesRebuildFull => '完全重建(同时清除缓存的 Docker 镜像,更慢)';

  @override
  String get settingsLog => '로그';

  @override
  String get settingsLogSubtitle => '应用실행로그与 AI 요청로그';

  @override
  String get logFiles => '로그파일';

  @override
  String get logNoFiles => '还没有로그파일';

  @override
  String logReadFailed(String error) {
    return '读取로그실패:$error';
  }

  @override
  String get logSearchHint => '검색로그';

  @override
  String get logNoMatch => '현재筛选개件下没有로그';

  @override
  String get logLevel => '로그수준';

  @override
  String get logLevelDesc => '기록낮음于该수준的로그将被忽略。开发期建议 VERBOSE(전체기록);NONE 닫기로그。';

  @override
  String get logCopied => '已복사';

  @override
  String logMcpPrefix(String server) {
    return 'MCP 로그:$server';
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
  String get logCopy => '복사';

  @override
  String get logClearFilter => '清除筛选';

  @override
  String get logCopyMenuTitle => '복사로그';

  @override
  String get logCopyLine => '복사本개로그';

  @override
  String get logCopyWithStack => '복사本개及堆栈';

  @override
  String get logCopyMessage => '복사消息내용';

  @override
  String get logFollowLatest => '实时滚动';

  @override
  String get logFileLocation => '로그파일位于 Android/data/<包名>/files/logs/。';

  @override
  String get logLevelVerbose => '자세히';

  @override
  String get logLevelDebug => '디버그';

  @override
  String get logLevelInfo => '정보';

  @override
  String get logLevelWarn => '경고';

  @override
  String get logLevelError => '오류';

  @override
  String get logLevelNone => '닫기';

  @override
  String get credentialTokenHint =>
      '建议用带 codespace 범위的 GitHub 令牌,填一次同时供 Git 推送与 Codespaces 登录使用';

  @override
  String get credentialHostOptional => '主机(선택 사항)';

  @override
  String get credentialHostAny => '留空 = 所有主机';

  @override
  String get credentialHostHint => '只在需要给特定主机单独配令牌时才填,例如 gitlab.com';

  @override
  String get codespacesNeedCredentialTitle => '尚미설정 GitHub 자격 증명';

  @override
  String get codespacesNeedCredentialDesc =>
      'Codespaces 使用「Git 자격 증명」里的令牌(需含 codespace 범위),不再单独填写。';

  @override
  String get codespacesGoToCredentials => '去填写 Git 자격 증명';

  @override
  String get credentialAllHosts => '所有主机';

  @override
  String get credentialUsernameAuto => '用户名自动推导';

  @override
  String get chatMentionSkill => '@ 技能';

  @override
  String get chatMentionSkillEmpty => '还没有사용 가능的技能,先在설정里가져오기或새로 만들기一个。';

  @override
  String get chatMentionSkillManage => '管理技能';

  @override
  String get chatPickFile => '# 파일';

  @override
  String get chatPickFileParent => '上一级';

  @override
  String get chatPickFileEmpty => '这个디렉토리是空的';

  @override
  String get mentionHintSkill => '继续输入可筛选技能';

  @override
  String get mentionHintFile => '继续输入可筛选파일';

  @override
  String get fileBrowserError => '读取디렉토리실패';

  @override
  String get fileBrowserRefresh => '새로고침';

  @override
  String get fileBrowserExpand => '펼치기';

  @override
  String get fileBrowserCollapse => '접기';

  @override
  String get fileBrowserNewFile => '새로 만들기파일';

  @override
  String get fileBrowserNewFolder => '새로 만들기폴더';

  @override
  String get fileBrowserNameLabel => '이름';

  @override
  String fileBrowserDeleteFileConfirm(String name) {
    return '삭제하시겠습니까?파일「$name」?';
  }

  @override
  String fileBrowserDeleteFolderConfirm(String name) {
    return '삭제하시겠습니까?폴더「$name」及其전체내용?';
  }

  @override
  String get fileBrowserCreateFailed => '생성에 실패했습니다,可能已存在同名개或없음写入权限';

  @override
  String get fileBrowserRenameFailed => '이름 변경에 실패했습니다,可能已存在同名개';

  @override
  String get fileBrowserDeleteFailed => '삭제에 실패했습니다';

  @override
  String get fileBrowserPasteHere => '붙여넣기到此处';

  @override
  String get fileBrowserExtract => '解压';

  @override
  String get fileBrowserExtractFailed => '解压실패';

  @override
  String get fileBrowserExtractConflictTitle => '목표폴더已存在';

  @override
  String fileBrowserExtractConflict(String name) {
    return '同디렉토리下已有「$name」,解压会先覆盖它的내용。';
  }

  @override
  String get fileBrowserExtractOverwrite => '覆盖并解压';

  @override
  String get fileBrowserPasteConflictTitle => '同名파일已存在';

  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '목표位置已存在同名프로젝트「$name」,是否覆盖?';
  }

  @override
  String get fileBrowserClipboardCut => '已잘라내기';

  @override
  String get fileBrowserClipboardCopy => '已복사';

  @override
  String get commonCopy => '복사';

  @override
  String get commonCut => '잘라내기';

  @override
  String get commonPaste => '붙여넣기';

  @override
  String get workspacePickWritingFolder => '写作디렉토리';

  @override
  String get writingFolderNeedAccessTitle => '需要存储访问权限';

  @override
  String get writingFolderNeedAccessDesc =>
      '读取手机里的「AI写作」디렉토리需要「所有파일访问权限」。也可以跳过,直接在下一步선택디렉토리。';

  @override
  String get writingFolderGrant => '去授权';

  @override
  String writingFolderSet(String path) {
    return '写作디렉토리已设为 $path';
  }

  @override
  String get modelAuto => 'Auto Model';

  @override
  String get modelAutoDesc => '按任务自动선택最合适的모델';

  @override
  String get sessionExport => '내보내기세션';

  @override
  String sessionExportDone(String path) {
    return '已내보내기到 $path';
  }

  @override
  String get sessionExportFailed => '내보내기실패';

  @override
  String get sessionBatchSelect => '批量선택';

  @override
  String sessionSelectedCount(String count) {
    return '선택됨 $count 개';
  }

  @override
  String get sessionSelectAll => '모두 선택';

  @override
  String get sessionCancelSelect => '취소';

  @override
  String get sessionDeleteSelected => '삭제所选';

  @override
  String get sessionDeleteConfirm => '삭제该세션及其전체消息?';

  @override
  String get fileBrowserNeedPermission => '없음法读取该폴더,可能需要存储访问权限';

  @override
  String get checkpointRewindTitle => '回退到此处';

  @override
  String checkpointTargetPrompt(String snippet) {
    return '목표:$snippet';
  }

  @override
  String get checkpointRestoreCodeAndConversation => '복원代码与세션';

  @override
  String get checkpointRestoreCodeAndConversationDesc =>
      '回滚작업 영역 파일,并삭제这之后的所有消息,提问会回填到输入框';

  @override
  String get checkpointRestoreConversation => '只복원세션';

  @override
  String get checkpointRestoreConversationDesc => '삭제这之后的所有消息,작업 영역 파일保持不变';

  @override
  String get checkpointRestoreCode => '只복원代码';

  @override
  String get checkpointRestoreCodeDesc => '回滚작업 영역 파일,对话기록保持不变';

  @override
  String checkpointRewindSkipped(int count) {
    return '$count 个파일因存在기타改动已跳过';
  }

  @override
  String get chatMoreOptions => '더보기옵션';

  @override
  String get chatActionEdit => '编辑';

  @override
  String get chatActionDelete => '삭제';

  @override
  String get chatEditMessageTitle => '编辑消息';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonClose => '닫기';

  @override
  String get commonBatchDelete => '批量삭제';

  @override
  String get tabProjects => '프로젝트';

  @override
  String get projectListEmpty => '还没有프로젝트';

  @override
  String get workspaceCurrent => '현재';

  @override
  String get workspaceNameHint => '프로젝트이름';

  @override
  String get projectNew => '새로 만들기프로젝트';

  @override
  String get projectUntitled => '未命名프로젝트';

  @override
  String get projectKindCoding => '编程';

  @override
  String get projectKindCodingDesc => '在沙盒작업 영역里写代码、跑命令、改파일';

  @override
  String get projectKindWriting => '写作';

  @override
  String get projectKindWritingDesc => '在「AI写作」디렉토리里撰写与修改文稿';

  @override
  String get projectKindReverse => '应用逆向';

  @override
  String get projectKindReverseDesc => '分析 APK、패킷 캡처接口、静态逆向与디버그辅助';

  @override
  String projectDeleteConfirm(String name) {
    return '삭제하시겠습니까?프로젝트「$name」?其下所有세션都会一并삭제。';
  }

  @override
  String get installedAppsTitle => '선택应用';

  @override
  String get installedAppsSearch => '검색应用名或包名';

  @override
  String get installedAppsEmpty => '没有匹配的应用';

  @override
  String get storagePermissionGrant => '去授权';

  @override
  String get softwarePermissionsTitle => '软件权限';

  @override
  String get softwarePermissionsSubtitle => '点任一개由系统弹出授权,或跳到对应的系统설정页。';

  @override
  String get systemPermissionsGroup => '系统权限';

  @override
  String get permissionStorageTitle => '访问存储空间';

  @override
  String get permissionBatteryTitle => '忽略电池优化';

  @override
  String get permissionBatteryDesc => '允许后台持续실행,减少被杀';

  @override
  String get permissionAutoStartTitle => '自시작管理';

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
  String get permissionAppsDesc => '读取已安装应用的이름、包名与版本';

  @override
  String get apkPathUnavailable => '拿不到这个应用的安装包경로,换一个应用再试。';

  @override
  String get apkExtractHint => '这个프로젝트显示所选 APK 里的파일。首次浏览需要先解压一次。';

  @override
  String get apkExtractAction => '解压 APK';

  @override
  String get apkExtracting => '正在解压…';

  @override
  String get apkExtractFailed => '解压실패,可能没有读取该安装包的权限。';

  @override
  String get terminalAgentTab => 'AI 命令';

  @override
  String get runModeAuto => '自动模式';

  @override
  String get runModeBuild => '构建模式';

  @override
  String get runModePlan => '计划模式';

  @override
  String get runModePlanIntercept => '현재处于计划模式,禁止执行写작업';

  @override
  String get runModeBuildAuthorize => 'AI 尝试执行写작업,是否允许?';

  @override
  String get runModeBuildAllow => '允许';

  @override
  String get runModeBuildDeny => '拒绝';

  @override
  String runModeSwitchChanged(Object mode) {
    return '실행模式已切换至 $mode';
  }

  @override
  String get commonScrollToBottom => '回到底部';

  @override
  String get subagentTitle => '서브 에이전트';

  @override
  String get subagentSubtitle => '모델档位与사용자 정의정의';

  @override
  String get subagentTierSubtitle =>
      '为每个档位绑定제공자与모델。미설정的档位:서브 에이전트정의写死모델时用정의모델,否则상속현재세션모델';

  @override
  String get subagentTierSection => '모델档位';

  @override
  String get subagentTierLight => '가벼움';

  @override
  String get subagentTierStandard => '균형';

  @override
  String get subagentTierStrong => '강력';

  @override
  String get subagentTierLightDesc => '只读探索、批量定位、机械改名';

  @override
  String get subagentTierStandardDesc => '单파일 수정与표준修复';

  @override
  String get subagentTierStrongDesc => '跨模块重构、疑难排查与方案设计';

  @override
  String get subagentTierUnset => '미설정(상속현재세션모델)';

  @override
  String get subagentTierPick => '선택모델';

  @override
  String get subagentTierClear => '清除';

  @override
  String get subagentTierCleared => '已清除';

  @override
  String get subagentTierSaved => '已저장';

  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier 档모델';
  }

  @override
  String get subagentTierSheetHint => '선택该档位使用的제공자与모델';

  @override
  String get subagentTierSheetInherit => '상속현재세션모델';

  @override
  String get subagentNoticeTitle => '서브 에이전트';

  @override
  String get subagentStateRunning => '실행 중';

  @override
  String get subagentStateCompleted => '완료';

  @override
  String get subagentStateFailed => '执行실패';

  @override
  String get subagentStateMessage => '来消息';

  @override
  String get subagentViewOutput => '查看输出';

  @override
  String get subagentOpen => '열기';

  @override
  String get subagentOutputEmpty => '暂없음输出';

  @override
  String get subagentOutputTitle => '서브 에이전트输出';

  @override
  String get promptsTitle => '팁词';

  @override
  String get promptsScenarioSection => '场景팁词';

  @override
  String get promptsSortLongPress => '长按可调整顺序';

  @override
  String get promptsEmpty => '暂없음사용 가능片段';

  @override
  String get promptsSourceProject => '프로젝트';

  @override
  String get promptsSourceGlobal => '전역';

  @override
  String get promptsSourceLocal => '로컬';

  @override
  String get promptsSourceBuiltin => '기본 제공';

  @override
  String get promptsFieldBasic => '기본 정보';

  @override
  String get promptsFieldNumber => '번호';

  @override
  String get promptsFieldNumberPlaceholder => '두 자리 숫자,如 35';

  @override
  String get promptsFieldTitle => '이름';

  @override
  String get promptsFieldTitlePlaceholder => '예: 내 보안 규칙';

  @override
  String get promptsFieldSummary => '요약(선택 사항)';

  @override
  String get promptsFieldSummaryPlaceholder => '조각 내용을 간략히 설명,프롬프트에 주입되지 않음';

  @override
  String get promptsFieldContent => '조각 내용';

  @override
  String get promptsFieldContentPlaceholder => '写모델要遵守的내용';

  @override
  String get promptsEditorNew => '새 프롬프트';

  @override
  String get promptsEditorEdit => '프롬프트 편집';

  @override
  String get promptsAddPrompt => '조각 추가';

  @override
  String get promptsResetCustom => '사용자 정의 프롬프트 재설정';

  @override
  String get promptsResetConfirm =>
      '将삭제현재 프로젝트与전역层里的所有사용자 정의팁词,各번호回落到기본 제공팁词。이 작업은 되돌릴 수 없습니다。';

  @override
  String get promptsResetAction => '재설정';

  @override
  String get promptsHelp => '도움말';

  @override
  String get promptsDisableBuiltin => '기본 제공 프롬프트 완전히 비활성화';

  @override
  String get promptsDisableBuiltinHint => '내 조각만 유지;모든 규칙을 직접 보완해야 함,주의해서 활성화';

  @override
  String get promptsBatchDeleteTitle => '프롬프트 삭제';

  @override
  String promptsBatchDeleteConfirm(int count) {
    return '선택한 항목을 삭제하시겠습니까? $count 개의 사용자 정의 프롬프트吗?해당 번호는 다음 계층의 소스로 대체됩니다。';
  }

  @override
  String get promptsScope => '범위';

  @override
  String get promptsScopeProject => '현재 프로젝트';

  @override
  String get promptsScopeGlobal => '전역';

  @override
  String get promptsSelectMode => '다중 선택';

  @override
  String promptsSelectedCount(int count) {
    return '선택됨 $count 개';
  }

  @override
  String get promptsSelectAll => '모두 선택';

  @override
  String get promptsDeselectAll => '전체 선택 취소';

  @override
  String get promptsSummary => '요약';

  @override
  String get promptsGotIt => '알겠습니다';

  @override
  String get promptsSubtitle => '사용자 정의 프롬프트 조각';

  @override
  String get novelNew => '새 소설';

  @override
  String get novelFieldName => '제목';

  @override
  String get novelFieldNameHint => '예: 수선계에서 슈퍼마켓 개점';

  @override
  String get novelFieldGender => '소설 장르';

  @override
  String get novelGenderMale => '남성향';

  @override
  String get novelGenderFemale => '여성향';

  @override
  String get novelFieldTags => '소설 태그';

  @override
  String get novelFieldTagsHint => '可다중 선택,也可以사용자 정의';

  @override
  String get novelCustomTagHint => '사용자 정의태그';

  @override
  String get novelFieldWordsPerChapter => '장당 글자 수';

  @override
  String get novelFieldWordsHint => '선택 사항档位,也可以사용자 정의';

  @override
  String get novelCreate => '만들기';

  @override
  String get novelPickExisting => '기존 소설 선택';

  @override
  String get novelOpen => '열기';

  @override
  String get novelExistingEmpty => '「AI소설」디렉토리里还没有기타小说';

  @override
  String get novelExistingEmptyHint => '把小说폴더放进 AI小说 디렉토리后,再回到这里선택';

  @override
  String get novelExistingFailed => '소설 목록 읽기 실패';

  @override
  String novelExistingBrief(String title) {
    return '집필 계속已有小说《$title》,먼저 읽기「소설 자료」与已有章节,了解设定与进度后再动笔。';
  }

  @override
  String novelBriefTitle(String title) {
    return '새 소설《$title》';
  }

  @override
  String novelBriefTags(String tags) {
    return '태그:$tags';
  }

  @override
  String novelBriefWords(String words) {
    return '장당 글자 수:$words';
  }

  @override
  String get novelScaffoldFailedTitle => '소설 디렉토리 생성 실패';

  @override
  String novelScaffoldFailed(String path) {
    return '$path 에서 소설 디렉토리를 생성할 수 없음,请检查存储权限后재시도。';
  }

  @override
  String get agentTitle => '서브 에이전트';

  @override
  String get agentSubtitle => '사용자 정의 서브 에이전트 정의';

  @override
  String get agentListEmpty => '사용자 정의 서브 에이전트 없음';

  @override
  String get agentListEmptyHint => '点右上角 + 새로 만들기사용자 정의 서브 에이전트 정의';

  @override
  String get agentScopeProject => '현재 프로젝트';

  @override
  String get agentScopeGlobal => '전역';

  @override
  String get agentScopeProjectHint => '현재 작업 영역에만 적용';

  @override
  String get agentScopeGlobalHint => '모든 프로젝트 공유';

  @override
  String get agentNew => '새 서브 에이전트';

  @override
  String get agentEdit => '서브 에이전트 편집';

  @override
  String get agentSave => '저장';

  @override
  String get agentCancel => '취소';

  @override
  String get agentDelete => '삭제';

  @override
  String get agentDeleteTitle => '삭제서브 에이전트';

  @override
  String agentDeleteConfirm(Object name) {
    return '삭제 $name?此작업不可恢复。';
  }

  @override
  String get agentImport => '가져오기';

  @override
  String get agentName => '이름';

  @override
  String get agentDescription => '용도 설명';

  @override
  String get agentDescriptionHint => '이 서브 에이전트를 선택할 시점';

  @override
  String get agentPrompt => '프롬프트 본문';

  @override
  String get agentPromptHint => '기본 시스템 프롬프트 이후에 추가할 전용 명령어';

  @override
  String get agentProvider => '제공자';

  @override
  String get agentModel => '모델';

  @override
  String get agentReasoningEffort => '사고 강도';

  @override
  String get agentMode => '기본 모드';

  @override
  String get agentTools => '도구 화이트리스트';

  @override
  String get agentToolsHint => '비워두면 모든 도구 개방';

  @override
  String get agentDisallowedTools => '도구 블랙리스트';

  @override
  String get agentInject => '규칙 조각 주입';

  @override
  String get agentInjectHint =>
      'base/mainRules/skills/memory/projectRules 또는 none';

  @override
  String get agentEnable => '활성화';

  @override
  String get agentDisable => '비활성화';

  @override
  String get agentEnabled => '활성화됨';

  @override
  String get agentDisabled => '비활성화됨';

  @override
  String get agentErrorInvalidName => '잘못된 이름입니다';

  @override
  String get agentErrorEmptyPrompt => '프롬프트 본문을 입력하세요';

  @override
  String get agentErrorNameConflict => '이 범위에 이미 동일한 이름의 서브 에이전트가 있음';

  @override
  String get agentErrorIoFailed => '파일 쓰기 실패';

  @override
  String get agentCapabilityRead => '파일 읽기';

  @override
  String get agentCapabilityWrite => '파일 수정';

  @override
  String get agentCapabilityCommand => '명령 실행';

  @override
  String get agentBuiltin => '기본 제공';

  @override
  String get agentBuiltinHint => '첫 시작 시 배포,업그레이드 시 완전히 유지';

  @override
  String get agentSelectMode => '다중 선택';

  @override
  String get agentBatchEnable => '활성화';

  @override
  String get agentBatchDisable => '비활성화';

  @override
  String get agentBatchDelete => '삭제';

  @override
  String get agentBatchAll => '모두 선택';

  @override
  String get agentBatchCancel => '취소';

  @override
  String agentSelectedCount(Object count) {
    return '선택됨 $count 개';
  }

  @override
  String agentBatchDeleteConfirm(Object count) {
    return '$count 개의 서브 에이전트를 삭제하시겠습니까? 이 작업은 복구할 수 없습니다。';
  }

  @override
  String get agentBatchDeleting => '삭제 중…';

  @override
  String get agentInherit => '세션 상속';

  @override
  String get agentReasoningNone => '없음';

  @override
  String get agentReasoningMinimal => '매우 낮음';

  @override
  String get agentReasoningLow => '낮음';

  @override
  String get agentReasoningMedium => '중간';

  @override
  String get agentReasoningHigh => '높음';

  @override
  String get agentReasoningXhigh => '매우 높음';

  @override
  String get agentReasoningMax => '최대';

  @override
  String get agentModeBuild => 'Build';

  @override
  String get agentModePlan => 'Plan';

  @override
  String get agentModeAuto => 'Auto';

  @override
  String get agentDetail => '서브 에이전트 상세';

  @override
  String get agentDetailHint => '编辑정의;이름 변경 시 정의 파일도 함께 이름 변경';

  @override
  String get promptsFieldType => '유형';

  @override
  String get promptsSaveFailed => '저장 실패';

  @override
  String get promptsNoOverrideToDelete => '이 프롬프트에 삭제 가능한 사용자 정의 덮어쓰기 없음';

  @override
  String get codespacesSearchHint => '이름으로 검색、저장소또는 분기로 검색';

  @override
  String get codespacesFilterAll => '전체';

  @override
  String get codespacesFilterRunning => '실행 중';

  @override
  String get codespacesFilterStopped => '중지됨';

  @override
  String get codespacesNoMatch => '현재 필터와 일치하는 Codespace 없음';

  @override
  String get codespacesStartAndConnect => '시작 및 연결';

  @override
  String get codespacesConnecting => '연결 중…';

  @override
  String get codespacesWaitingForStart => 'Codespace 사용 가능 대기 중…';

  @override
  String codespacesConnectError(String error) {
    return '연결 실패：$error';
  }

  @override
  String get codespacesDetails => '상세';

  @override
  String get codespacesOverview => '개요';

  @override
  String get codespacesBranchLabel => '브랜치';

  @override
  String get codespacesMachineLabel => '머신 유형';

  @override
  String get codespacesLocation => '리전';

  @override
  String get codespacesIdleTimeout => '휴식 시간 초과（분）';

  @override
  String get codespacesRetentionPeriod => '보존 기간（일）';

  @override
  String get codespacesDevcontainerPath => 'Dev container 경로';

  @override
  String get codespacesCreatedAt => '생성 시간';

  @override
  String get codespacesOwner => '소유자';

  @override
  String get codespacesBillableOwner => '결제 소유자';

  @override
  String get codespacesCopySsh => 'SSH 명령 복사';

  @override
  String get codespacesSshCopied => 'SSH 명령 복사됨';

  @override
  String get codespacesOpenWeb => 'VS Code 웹 버전에서 열기';

  @override
  String get codespacesUnpushed => '푸시되지 않은 커밋 있음';

  @override
  String get codespacesGitStatus => 'Git 상태';

  @override
  String get codespacesActions => '작업';

  @override
  String get codespacesPendingOperation => '작업 실행 중';

  @override
  String get codespacesStateQueued => '대기 중';

  @override
  String get codespacesStateProvisioning => '프로비저닝 중';

  @override
  String get codespacesStateShuttingDown => '중지 중';

  @override
  String get codespacesStateFailed => '실패';

  @override
  String get codespacesStateDeleting => '삭제 중';

  @override
  String get codespacesCurrentEnv => '현재 환경';

  @override
  String get codespacesSwitchToLocal => '로컬 컨테이너로 전환';

  @override
  String get codespacesManage => 'Codespaces 관리';

  @override
  String get codespacesQuickActions => 'Codespaces';

  @override
  String get codespacesPortCopyUrl => '링크 복사';

  @override
  String get codespacesPortUrlCopied => '링크 복사됨';

  @override
  String codespacesErrorInline(String error) {
    return '$error';
  }

  @override
  String get codespacesRetry => '재시도';

  @override
  String get codespacesRegionDefault => '기본 리전';

  @override
  String get codespacesAdvanced => '고급 옵션';

  @override
  String get codespacesDevcontainerPathHint => 'devcontainer.json 경로（선택 사항）';

  @override
  String get codespacesIdleTimeoutHint => '휴식 후 자동 중지까지의 분 수（선택 사항）';

  @override
  String get codespacesRetentionHint => '중지后保留일数（선택 사항）';

  @override
  String get codespacesReadinessTitle => '연결 준비 완료';

  @override
  String get codespacesReadinessCredOk => 'GitHub 자격 증명：설정됨';

  @override
  String get codespacesReadinessCredMissing =>
      'GitHub 자격 증명：미설정（需含 codespace 权限的令牌）';

  @override
  String get codespacesReadinessGhOk => 'gh CLI：준비 완료';

  @override
  String get codespacesReadinessGhMissing =>
      'gh CLI：준비 안 됨（터미널에서 codecraft 실행하여 「GitHub Codespaces」시나리오 설치）';

  @override
  String get codespacesOpenTerminal => '터미널에서 열기';

  @override
  String get codespacesOpenGit => 'Git 열기 (배포/동기화)';

  @override
  String get codespacesManageCredentials => '자격 증명 관리';

  @override
  String get codespacesDeploySyncHint =>
      'Git 푸시/풀 등 작업会作用于현재执行环境；连接 Codespace 后即在远端저장소执行部署/同步。';

  @override
  String gitExecutionTargetCodespace(String name) {
    return '현재 작업은 Codespace에 적용：$name';
  }

  @override
  String get gitExecutionTargetLocal => '현재 작업은 로컬 컨테이너에 적용';

  @override
  String get gitDeploySyncSection => '배포 / 동기화';

  @override
  String get gitDeploySyncHintCodespace => '푸시, 풀 및 원격 작업연결된 Codespace에서 실행。';

  @override
  String get gitDeploySyncHintLocal =>
      '푸시, 풀 및 원격 작업로컬 컨테이너에서 실행；Codespace 연결 시 원격에서 배포/동기화 가능。';

  @override
  String get gitOpenCodespaces => 'Codespaces';

  @override
  String get gitOpenTerminal => '터미널';

  @override
  String get terminalCodespaceManage => 'Codespaces 관리';

  @override
  String get terminalCodespaceCredentials => 'Git 자격 증명';

  @override
  String get captureTitle => '패킷 캡처';

  @override
  String get captureStart => '프록시 시작';

  @override
  String get captureStop => '중지';

  @override
  String get captureRunning => '실행 중';

  @override
  String get captureStopped => '중지됨';

  @override
  String get capturePort => '프록시 포트';

  @override
  String get captureClear => '기록 비우기';

  @override
  String get captureSearchHint => 'URL / 메서드 / 상태 코드 검색';

  @override
  String get captureEmpty =>
      '패킷 캡처 기록 없음。프록시 시작 후，대상 트래픽을 프록시로 127.0.0.1:<포트>。';

  @override
  String get captureLimitHint =>
      '仅抓取经代理的流量。HTTPS는 CA 설치 및 신뢰 필요；Android 7+ 대부분의 앱 및 인증서 고정 앱은 MITM 불가능（디버그 버전/신뢰된 인증서 시나리오에서 사용 가능）。';

  @override
  String get captureCaTitle => 'CA 인증서';

  @override
  String get captureCaPath => '인증서 경로';

  @override
  String get captureCaGuide =>
      '시스템/사용자 인증서에 설치하고 신뢰 설정（네트워크/HTTPS 캡처용）。Android 설정 경로는 기종에 따라 다름，일반적으로 「보안/암호화 및 자격 증명/인증서 설치」。설치 후 HTTP 프록시를 127.0.0.1:<포트>로 설정。';

  @override
  String get captureCopyPath => '경로 복사';

  @override
  String get captureDetail => '요청 상세';

  @override
  String get captureRequest => '요청';

  @override
  String get captureResponse => '응답';

  @override
  String get captureNotFound => '기록 없음';

  @override
  String get captureCopyUrl => 'URL 복사';

  @override
  String get captureInstallCa => '인증서 설치';

  @override
  String get captureOpenSecurity => '보안 설정';

  @override
  String get captureDownloadCa => '인증서 저장';

  @override
  String get captureCaInstallFail =>
      '직접 설치 불가 (경로 복사됨)，시스템 보안 설정에서 수동으로 인증서 설치。';

  @override
  String get captureVpnPermissionDenied =>
      'VPN 권한 거부됨，패킷 캡처를 사용할 수 없음。VPN 권한 허용 후 다시 시도。';

  @override
  String get captureSequence => '모든 요청';

  @override
  String get captureDomains => '도메인 목록';

  @override
  String captureDomainSubtitle(String time, int count) {
    return '마지막 요청: $time · $count 개';
  }

  @override
  String get captureClearConfirm => '모든 패킷 캡처 기록을 삭제하시겠습니까?';

  @override
  String get capturePip => 'PIP 모드';

  @override
  String get capturePipUnsupported => '이 기기에서 PIP 모드를 지원하지 않음';

  @override
  String get capturePipNoTraffic => '트래픽 없음';

  @override
  String get captureNoDomains => '도메인 없음';

  @override
  String get captureCopyHost => '도메인 복사';

  @override
  String get captureDeleteConfirm => '삭제该域名的전체기록？';

  @override
  String get captureSort => '정렬';

  @override
  String get captureOverview => '개요';

  @override
  String get captureCookies => '쿠키';

  @override
  String get captureProtocol => '프로토콜';

  @override
  String get captureDuration => '소요 시간';

  @override
  String get captureSize => '크기';

  @override
  String get captureRemoteAddress => '원격 주소';

  @override
  String get captureRequestTime => '요청 시간';

  @override
  String get capturePath => '경로';

  @override
  String get captureStatusCode => '상태 코드';

  @override
  String get captureRequestHeaders => '요청 헤더';

  @override
  String get captureResponseHeaders => '응답 헤더';

  @override
  String get captureRequestBody => '요청 본문';

  @override
  String get captureResponseBody => '응답 본문';

  @override
  String get captureBodyTruncated => ' (내용이 잘림)';

  @override
  String get captureFormatted => '서식 지정';

  @override
  String get captureRaw => '원문';

  @override
  String get captureNoCookies => '쿠키 없음';

  @override
  String get captureRequestCookies => '요청 쿠키';

  @override
  String get captureResponseCookies => '응답 Set-Cookie';

  @override
  String get backupAndRestore => '백업 및 복원';

  @override
  String get selectExportData => '내보낼 데이터 선택';

  @override
  String get aiProvider => 'AI 공급자';

  @override
  String get connectSync => '연결 및 동기화';

  @override
  String get chatRecords => '채팅 기록';

  @override
  String get mcpServer => 'MCP 서버';

  @override
  String get permissionRules => '권한 규칙';

  @override
  String get appSettings => '앱 설정';

  @override
  String get workspaceFiles => '작업 영역 파일';

  @override
  String get workspaceFilesHint =>
      '작업 영역 파일은 Git 커밋으로 백업하는 것이 좋습니다，내보낸 백업은 예비용으로만 사용';

  @override
  String get exportBackup => '백업 내보내기';

  @override
  String get exportBackupDesc => '내보낼 데이터 선택，비밀번호로 암호화 가능';

  @override
  String get importBackup => '백업 가져오기';

  @override
  String get importBackupDesc => '백업 파일에서 데이터 복원';

  @override
  String get localBackup => '로컬 백업';

  @override
  String get cloudBackup => '클라우드 백업';

  @override
  String get aboutUpdateAvailable => '새 버전 사용 가능';

  @override
  String get aboutUpdateDesc => '새 버전 사용 가능';

  @override
  String get aboutUpdateLater => '나중에';

  @override
  String get aboutUpdateGo => '다운로드 페이지로';

  @override
  String get aboutCheckingUpdate => 'GitHub에서 최신 버전 확인 중…';

  @override
  String get aboutAlreadyLatest => '최신 버전입니다';

  @override
  String get aboutCurrentVersion => '현재 버전';

  @override
  String get aboutNewVersionFound => '새 버전이 발견되었습니다';

  @override
  String get aboutUpdateFailed => '업데이트 확인에 실패했습니다';
}
