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
  String get send => '전송';

  @override
  String get stop => '중지';

  @override
  String get reverseTabClasses => '클래스';

  @override
  String get reverseTabStrings => '문자열 풀';

  @override
  String get reverseTabResources => '자원';

  @override
  String get reverseTabHex => '16진수';

  @override
  String get reverseSearchClassHint => '클래스명 검색';

  @override
  String get reverseSearchStringHint => '문자열 검색';

  @override
  String get reverseSearchResourceHint => '검색자원이름、유형또는 0x 번호';

  @override
  String get reverseNoMatch => '일치하는 항목 없음';

  @override
  String get reverseEmptyFile => '파일 비어 있음';

  @override
  String get reverseLoadFailed => '열기실패';

  @override
  String get reverseParseFailed => '해석실패,이파일난독화되거나됨손상';

  @override
  String get reverseEditString => '문자열 수정';

  @override
  String get reverseEqualLengthHint =>
      '같은 길이만 가능바꾸기:새내용인코딩후바이트 수는 원래 문자열과 일치해야 함,그렇지 않으면파일내 오프셋은전체오프셋';

  @override
  String get reverseEditByte => '바이트 수정';

  @override
  String get reverseEditByteHint => '입력두 자리16진수,예 0a、ff';

  @override
  String get reverseInvalidByte => '부탁입력 00-ff 사이16진수바이트';

  @override
  String get reverseJumpToOffset => '오프셋으로 이동';

  @override
  String get reverseOffsetInvalid => '오프셋없음효과,부탁입력16진수';

  @override
  String get reverseSuperclass => '부모 클래스';

  @override
  String get reverseInterfaces => '인터페이스';

  @override
  String get reverseAccessFlags => '수정자';

  @override
  String get reverseFields => '필드';

  @override
  String get reverseMethods => '메서드';

  @override
  String get reverseAbstractMethod => '없음메서드본체';

  @override
  String get reverseSmaliHint =>
      '을상를 위해 smali 역어셈블리결과;offset 예해당 명령에메서드메서드 내 바이트 오프셋';

  @override
  String get reverseOpenAsHex => '을16진수열기';

  @override
  String reverseMethodCount(int count) {
    return '$count 개메서드';
  }

  @override
  String reverseFieldCount(int count) {
    return '$count 개필드';
  }

  @override
  String reverseHexByteCount(int count) {
    return '함께 $count 바이트';
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
  String get rename => '이름 변경';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사됨';

  @override
  String get retry => '재시도';

  @override
  String get pin => '고정';

  @override
  String get unpin => '고정 해제';

  @override
  String get search => '검색';

  @override
  String get searchSessions => '검색세션';

  @override
  String get noSessions => '세션 없음';

  @override
  String get noMessages => '시작새대화~';

  @override
  String get chatInputPlaceholder => '입력메시지,및 AI 대화…';

  @override
  String get reasoningTitle => '사고 과정';

  @override
  String get untitled => '제목 없음';

  @override
  String get pinned => '고정됨';

  @override
  String get settings => '설정';

  @override
  String get providers => 'AI 제공자';

  @override
  String get providersSubtitle => '모델、인터페이스및비밀번호';

  @override
  String get appearance => '외관';

  @override
  String get themeMode => '테마 모드';

  @override
  String get themeModeSystem => '시스템에 따름';

  @override
  String get themeModeLight => '라이트';

  @override
  String get themeModeDark => '다크';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템에 따름';

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get license => '오픈 소스프로토콜';

  @override
  String get licenseBody =>
      '본프로젝트예 jieapi/Codecraft  Flutter 분기본,누름 GPL-3.0 프로토콜오픈 소스。';

  @override
  String get addProvider => '제공자 추가';

  @override
  String get providerName => '이름';

  @override
  String get providerType => '프로토콜';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => '기본값모델';

  @override
  String get modelList => '모델목록';

  @override
  String get model => '모델';

  @override
  String get mode => '모드';

  @override
  String get reasoningEffort => '사고 강도';

  @override
  String get reasoningEffortNone => '사고 안 함';

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
  String get reasoningEffortMax => '최고';

  @override
  String get deleteProviderConfirm => '삭제하시겠습니까?해당제공자?';

  @override
  String get deleteSessionConfirm => '삭제하시겠습니까?해당세션?';

  @override
  String get emptyProviders => '아직없음제공자,클릭오른쪽 상단 + 추가';

  @override
  String get emptyModels => '모델 없음';

  @override
  String get modelInputHint => '입력모델 ID 후엔터추가';

  @override
  String get errorGeneric => '오류 발생';

  @override
  String get retrying => '재시도 중';

  @override
  String get emptyMessage => '메시지내용를 위해빈';

  @override
  String get enabled => '활성화됨';

  @override
  String get disabled => '비활성화됨';

  @override
  String providerModelsCountTag(int count) {
    return '$count 개모델';
  }

  @override
  String get inputTokens => '입력';

  @override
  String get outputTokens => '출력';

  @override
  String get emptyChatHint => '선택하나개세션시작대화';

  @override
  String get errorNoProvider => '미설정사용 가능제공자,부탁먼저에설정중간추가';

  @override
  String get errorNoModel => '부탁를 위해해당제공자선택모델';

  @override
  String get errorEmptyResponse => '모델뒤로 가기빈빈내용';

  @override
  String get thinking => '사고중간…';

  @override
  String get modelListTitle => '선택모델';

  @override
  String get providerListTitle => '제공자 선택';

  @override
  String get customProvider => '사용자 정의';

  @override
  String get addFromPreset => '로부터프리셋추가';

  @override
  String get useFullUrlHint => 'baseUrl 됨예완전한 엔드포인트클릭';

  @override
  String get aboutBody =>
      'Codecraft Flutter 예 jieapi/Codecraft  Flutter 분기본(Phase 1:핵심대화루프)。';

  @override
  String get chatPlaceholder => '있음무엇을 도와드릴까요?';

  @override
  String get chatInputHint => '설명요구사항,제가 작성해 드립니다、수정 또는 설명코드';

  @override
  String get openSidebar => '사이드바 열기';

  @override
  String get noModelSelected => '미선택모델';

  @override
  String get sessionGroupPinned => '고정';

  @override
  String get sessionGroupToday => '오늘';

  @override
  String get sessionGroupYesterday => '어제';

  @override
  String get sessionGroupLast7Days => '7일 이내';

  @override
  String get sessionGroupLast30Days => '30일 이내';

  @override
  String get sessionGroupMonthFormat => 'yyyy년M월';

  @override
  String chatThinkingRunningTime(String seconds) {
    return '사고 중(소요 시간 $seconds 초)';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return '사고 완료(소요 시간 $seconds 초)';
  }

  @override
  String get chatThinkingDone => '사고 완료';

  @override
  String get chatQueueHint => 'AI 중처리 중,클릭오른쪽측블록가능중지';

  @override
  String get chatStatusGenerating => '생성 중';

  @override
  String get chatStatusThinking => '사고 중';

  @override
  String get chatStatusCallingTool => '중호출도구';

  @override
  String get chatStatusRunningCommand => '중명령 실행';

  @override
  String get chatStatusEditingFile => '중편집파일';

  @override
  String get chatStatusReadingFile => '중읽기파일';

  @override
  String get chatStatusViewingImage => '중보기이미지';

  @override
  String get chatStatusSearchingWeb => '중네트워크검색';

  @override
  String get chatStatusBrowsingWeb => '중작업브라우저';

  @override
  String get chatStatusAskingUser => '중사용자 질문';

  @override
  String get chatStatusGeneratingImage => '생성 중이미지';

  @override
  String get chatStatusUpdatingTodo => '중할 일 정리';

  @override
  String get chatStatusStartingSubagent => '중시작서브 에이전트';

  @override
  String get chatCompressingContext => '중압축상하파일';

  @override
  String get chatContextCompressed => '상하파일됨압축';

  @override
  String get chatCompactionSummary => '인수 요약';

  @override
  String get chatStatusReadingMemory => '중기억 읽기';

  @override
  String get chatToolRunning => '도구실행중간';

  @override
  String get chatToolSucceeded => '도구실행성공';

  @override
  String get chatToolFailed => '도구실행실패';

  @override
  String get chatEffortNone => '사고 안 함';

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
  String get chatEffortMax => '최고';

  @override
  String get searchModels => '검색모델';

  @override
  String get chatAddAttachment => '첨부 파일 추가';

  @override
  String get chatUploadFile => '상전송파일';

  @override
  String get chatUploadImage => '이미지 업로드';

  @override
  String get chatTakePhoto => '사진 찍기';

  @override
  String get attachmentPrefix => '첨부 파일:';

  @override
  String attachmentMax(int count) {
    return '최대 동시에시전송 $count 개첨부 파일';
  }

  @override
  String attachmentUploaded(int count) {
    return '됨상전송 $count 개첨부 파일';
  }

  @override
  String attachmentUploadedPartial(int count) {
    return '됨상전송 $count 개첨부 파일,부분첨부 파일미참여';
  }

  @override
  String attachmentUploading(int count) {
    return '중상전송 $count 개파일…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return '이미지 초과 $size,부탁압축후재시도';
  }

  @override
  String get attachmentUnsupportedImageType =>
      '없음이미지 인식 불가유형,지원만 jpg/png/gif/webp';

  @override
  String get attachmentReadFileFailed => '없음선택 항목 읽기 불가파일';

  @override
  String get attachmentUploadFailed => '업로드 실패';

  @override
  String get removeAttachment => '첨부 파일 제거';

  @override
  String get imagePreview => '이미지 미리보기';

  @override
  String get imageLoadFailed => '이미지불러오기실패,파일가능됨이동되거나삭제';

  @override
  String get close => '닫기';

  @override
  String get fileFallback => '파일';

  @override
  String get skillsTitle => 'Skill 관리';

  @override
  String get skillsSubtitle => '탐색、가져오기및관리글쓰기기술';

  @override
  String get skillsNew => '새로 만들기기술';

  @override
  String get skillsImport => '가져오기 Markdown';

  @override
  String get skillsScopeTitle => '선택범위';

  @override
  String get skillsScopeGlobal => '';

  @override
  String get skillsScopeProject => '프로젝트기술';

  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills,간프로젝트공유';

  @override
  String get skillsScopeProjectHint =>
      '~/workspace/.codecraft/skills,따름현재작업 영역';

  @override
  String skillsProjectGroup(String name) {
    return '현재 프로젝트($name)';
  }

  @override
  String get skillsNoProjectSkills => '현재 프로젝트아직없음기술';

  @override
  String get skillsNoGlobalSkills => '아직없음전역기술';

  @override
  String get skillsEmpty => '아직없음기술';

  @override
  String get skillsEmptyHint =>
      '기술예쓰기에게 AI 전문개작업설명;가져오기 SKILL.md 또는수동새로 만들기하나개~。';

  @override
  String get skillsName => '이름';

  @override
  String get skillsDescription => '설명';

  @override
  String get skillsDescriptionHint => '어떤시사용이기술(진입시스템팁)';

  @override
  String get skillsInstructions => '명령 본문';

  @override
  String get skillsInstructionsHint => '기술이 실행할 단계,Markdown 글쓰기';

  @override
  String skillsImported(String name) {
    return '됨가져오기기술「$name」';
  }

  @override
  String get skillsDeleteTitle => '스킬 삭제';

  @override
  String skillsDeleteConfirm(String name) {
    return '삭제하시겠습니까?기술「$name」(포함디렉토리스크립트와)?';
  }

  @override
  String get skillsErrorInvalidName =>
      '기술 이름없음효과:불가를 위해빈、초과 길이 또는 포함 / \\ : * ? \" < > |';

  @override
  String get skillsErrorEmptyInstructions => '명령 본문불가를 위해빈';

  @override
  String skillsErrorNameConflict(String name) {
    return '동일범위됨있음이름를 위해「$name」기술';
  }

  @override
  String get skillsErrorNoSkill => '파일안에없음인식 가능한 기술';

  @override
  String get skillsErrorIoFailed => '읽기/쓰기 기술파일실패';

  @override
  String get providerAdd => '제공자 추가';

  @override
  String get providerEdit => '제공자 수정';

  @override
  String get providerEditModel => '편집모델';

  @override
  String get providerConfig => '구성';

  @override
  String get providerSectionBasic => '기본 정보';

  @override
  String get providerSectionType => '상류 형식';

  @override
  String get providerSectionOptions => '옵션';

  @override
  String get providerFullUrl => '완전한 URL';

  @override
  String get providerFullUrlDesc => 'Base URL 즉 완전한요청주소,안자동연결기본값경로';

  @override
  String get providerHeadersTitle => '사용자 정의요청 헤더';

  @override
  String get providerHeadersDesc => '해당 항목 완전히 덮어쓰기제공자요청동일 이름기본값머리';

  @override
  String get providerHeadersAdd => '추가요청 헤더';

  @override
  String get providerHeadersManage => '관리';

  @override
  String providerHeadersCount(int count) {
    return '설정됨 $count 개요청 헤더';
  }

  @override
  String get providerShowApiKey => '비밀번호 표시';

  @override
  String get providerHideApiKey => '숨기기비밀번호';

  @override
  String get providerAddModel => '모델 추가';

  @override
  String get providerNoModels => '임시없음모델';

  @override
  String get providerNoModelsHint => '클릭클릭오른쪽상정사각형 버튼모델 추가';

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
  String get providerModelsBatchTest => '테스트';

  @override
  String get providerModelsBatchDelete => '삭제';

  @override
  String get providerModelsBatchDeleteTitle => '삭제모델';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '선택한 항목을 삭제하시겠습니까? $count 개모델~?';
  }

  @override
  String get providerFetchModels => '모델 가져오기';

  @override
  String get providerAddAllModels => '전체추가';

  @override
  String get providerAddAllModelsTitle => '추가전체모델';

  @override
  String providerAddAllModelsConfirm(int count) {
    return '확인을풀에 $count 개모델전체추가까지현재제공자?';
  }

  @override
  String get providerFilterModelsHint => '입력모델이름필터';

  @override
  String get providerNoMatchingModels => '없음매칭모델';

  @override
  String providerModelAdded(String name) {
    return '됨모델 추가「$name」';
  }

  @override
  String get providerModelName => '모델이름';

  @override
  String get providerModelAlreadyAdded => '해당모델됨추가';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · ${latency}ms';
  }

  @override
  String get providerFetchMissingFields => '응답목록 누락필드';

  @override
  String get providerFetchFailed => '모델 가져오기실패';

  @override
  String get providerApiKeyRequired => '부탁먼저 입력 API Key';

  @override
  String get providerTestModel => '테스트';

  @override
  String get providerModelContext => '상하파일 창 (tokens)';

  @override
  String get providerModelContextInput => '입력상제한 (tokens)';

  @override
  String get providerModelContextOutput => '출력상제한 (tokens)';

  @override
  String get providerModelWindowInvalid => '부탁입력유효양의 정수,또는 비움빈사용자동인식 값';

  @override
  String get providerModelSectionPrice => '가격';

  @override
  String get providerModelPriceInput => '입력가격 (USD/1M tokens)';

  @override
  String get providerModelPriceOutput => '출력가격 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheRead => '캐시읽기가격 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheWrite => '캐시쓰기가격 (USD/1M tokens)';

  @override
  String get providerModelCapabilities => '능력';

  @override
  String get providerModelCapVision => '이미지 입력';

  @override
  String get providerModelCapImageOutput => '이미지 출력';

  @override
  String get providerModelCapTools => '도구호출';

  @override
  String get providerModelCapReasoning => '사고';

  @override
  String get providerModelSectionReasoning => '사고 단계';

  @override
  String get providerModelReasoningHint =>
      '해당 항목만 선택모델실제 지원 단계;전체선택 안 함그렇다면에 의해기본 제공능력 목록자동판단';

  @override
  String get providerModelReasoningCanDisable => '가능닫기사고';

  @override
  String get providerTestRequestUrl => '요청주소';

  @override
  String get providerTestRequestHeaders => '요청 헤더';

  @override
  String get providerTestRequestBody => '요청 본문';

  @override
  String get providerTestResponse => '응답';

  @override
  String get providerTestError => '오류상세';

  @override
  String get providerMultiKeyTitle => '여러 Key 모드';

  @override
  String get providerMultiKeySubtitle =>
      '동일제공자하여러 개 구성개 Key,비밀번호사용 불가시자동전환및 재전송';

  @override
  String get providerMultiKeyManage => '여러 Key 관리';

  @override
  String providerMultiKeySummary(int count, String strategy) {
    return '$count 개 · $strategy';
  }

  @override
  String get providerMultiKeyList => 'Key 목록';

  @override
  String providerMultiKeyItem(int index) {
    return '비밀번호 #$index';
  }

  @override
  String get providerMultiKeyEmpty => '클릭이추가첫 번째개 Key';

  @override
  String get providerMultiKeyAdd => '추가 Key';

  @override
  String get providerMultiKeyWeight => '스케줄 가중치';

  @override
  String get providerMultiKeyWeightHint => '기본값 1 · ≤ 0 시참여 안 함 · 최대 1,000,000';

  @override
  String get providerMultiKeyStrategy => '사용 전략';

  @override
  String get providerMultiKeyStrategySequential => '순서';

  @override
  String get providerMultiKeyStrategySequentialDesc =>
      '항상 먼저 사용전 Key,실패임계치 도달 시 전환다음';

  @override
  String get providerMultiKeyStrategyRoundRobin => '라운드 로빈';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc =>
      '새세션바퀴쿼터 균등 분배를 위해 순환 시작;동일세션내부 변경 안 함 Key,유지캐시명령중간';

  @override
  String get providerMultiKeyStatusCodes => '자동전환상태 코드';

  @override
  String get providerMultiKeyStatusCodesHint =>
      '콤마 구분,비움빈사용기본값 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => '냉각시길고';

  @override
  String get providerMultiKeyCooldownDesc => '전환됨 Key 얼마 후 다시 후보에 포함';

  @override
  String get workspaceOpen => '작업 영역';

  @override
  String get workspaceLocal => '로컬작업 영역';

  @override
  String get workspaceLocalSubtitle => '앱데이터디렉토리';

  @override
  String get allow => '허용';

  @override
  String get deny => '거부';

  @override
  String get tabFiles => '파일';

  @override
  String get newFile => '새로 만들기파일';

  @override
  String get newFolder => '새로 만들기폴더';

  @override
  String get create => '만들기';

  @override
  String get deleteFileConfirm => '삭제하시겠습니까?해당파일?';

  @override
  String get deleteFolderConfirm => '삭제하시겠습니까?해당폴더(포함내용)?';

  @override
  String get refresh => '새로고침';

  @override
  String get workspaceNew => '새로 만들기';

  @override
  String get workspaceEmptyHint => '아직없음작업 영역,클릭오른쪽 상단「새로 만들기」';

  @override
  String get workspaceNameExists => '동일 이름작업 영역됨저장에';

  @override
  String get workspaceDelete => '삭제작업 영역';

  @override
  String workspaceDeleteConfirm(String name) {
    return '삭제하시겠습니까?작업 영역「$name」(포함중간전체파일)?';
  }

  @override
  String get todoDashboardTitle => '할 일 관리';

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
  String get browserTitle => '브라우저';

  @override
  String get browserAddressHint => '입력URL 또는검색';

  @override
  String get browserBack => '뒤로';

  @override
  String get browserForward => '앞으로';

  @override
  String get browserReload => '새로고침';

  @override
  String get browserNotReady => '브라우저준비 안 됨,부탁에주소열입력URL시작탐색';

  @override
  String get browserNewTab => '새로 만들기태그페이지';

  @override
  String get browserCloseTab => '태그 페이지 닫기';

  @override
  String get browserTabDefaultTitle => '새태그페이지';

  @override
  String browserTabsCount(int count) {
    return '태그페이지 ($count)';
  }

  @override
  String get browserEmptyHint => '에상방주소열입력URL시작탐색';

  @override
  String get browserTabsManage => '태그 페이지 관리';

  @override
  String get browserEmptyClickHint => '클릭클릭상방입력URL시작탐색';

  @override
  String get browserNightModeOn => '닫기야간모드';

  @override
  String get browserNightModeOff => '활성화야간모드';

  @override
  String get browserDevtools => '개발자 도구';

  @override
  String get browserDialogAlertTitle => '웹 팁';

  @override
  String get browserDialogConfirmTitle => '네트워크페이지확인';

  @override
  String get browserDialogPromptTitle => '네트워크페이지입력';

  @override
  String get browserMenu => '더보기설정';

  @override
  String get browserMenuTitle => '브라우저설정및도구';

  @override
  String get browserMenuGeneralSection => '페이지 및 도구';

  @override
  String get browserNightModeTitle => '야간모드';

  @override
  String get browserNightModeDesc => '낮춤낮음페이지화면 밝기 및활성화다크선호도';

  @override
  String get browserDevtoolsTitle => '개발자 도구';

  @override
  String get browserDevtoolsDesc => '활성화모바일 Eruda 디버그콘솔';

  @override
  String get browserUaSection => '브라우저식별자 (User-Agent)';

  @override
  String get browserUaDesc => '다양한 시뮬레이션장치환경에서 네트워크 접속페이지';

  @override
  String get browserUaDefault => '시스템기본값';

  @override
  String get browserUaDefaultDesc => '현재장치원래 WebView 식별자';

  @override
  String get browserUaAndroidPhone => '안드로이드 스마트폰';

  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';

  @override
  String get browserUaAndroidTablet => '안드로이드 태블릿';

  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';

  @override
  String get browserUaDesktopPc => '데스크톱 PC';

  @override
  String get browserUaDesktopPcDesc => 'Chrome Desktop (Windows PC)';

  @override
  String get browserUaIphone => '애플 iPhone';

  @override
  String get browserUaIphoneDesc => 'Mobile Safari (iOS)';

  @override
  String get browserUaIpad => '애플 iPad';

  @override
  String get browserUaIpadDesc => 'Tablet Safari (iPadOS)';

  @override
  String get browserUaCustom => '사용자 정의';

  @override
  String get browserUaCustomDesc => '수동지정 User-Agent 문자열';

  @override
  String get browserUaCustomDialogTitle => '사용자 정의 User-Agent';

  @override
  String get browserUaCustomInputHint => '입력완전한 User-Agent 문자열';

  @override
  String get browserUaAppliedToast => '됨전환브라우저표시 및새로고침페이지면';

  @override
  String get gitTabBranches => '브랜치';

  @override
  String get gitTabCommits => '커밋';

  @override
  String get gitStatusClean => '작업 영역깨끗함,없음변경';

  @override
  String gitConflictedCount(int count) {
    return '저장에충돌 ($count)';
  }

  @override
  String gitStagedCount(int count) {
    return '스테이징됨 ($count)';
  }

  @override
  String gitModifiedCount(int count) {
    return '수정됨 ($count)';
  }

  @override
  String gitUntrackedCount(int count) {
    return '추적 안 됨 ($count)';
  }

  @override
  String get gitConflictedLabel => '저장에충돌';

  @override
  String get gitStagedLabel => '스테이징됨';

  @override
  String get gitModifiedLabel => '수정됨';

  @override
  String get gitUntrackedLabel => '추적 안 됨';

  @override
  String get gitStage => '스테이징';

  @override
  String get gitUnstage => '취소스테이징';

  @override
  String get gitStageAll => '스테이징전체';

  @override
  String get gitUnstageAll => '전체취소스테이징';

  @override
  String get gitUnstageAllConfirm => '을취소장소있음파일스테이징,하지만 안 함삭제파일내용。확인계속할까요?';

  @override
  String get gitActionRevertAll => '전체롤백';

  @override
  String gitRevertAllConfirm(int count) {
    return '폐기전체미스테이징변경($count 개파일),복원에상회스테이징또는커밋내용?스테이징됨내용영향 없음,하지만 변경 사항 폐기없음복구 불가。';
  }

  @override
  String get gitActionRestoreFile => '복원파일';

  @override
  String gitRevertConfirmWorktree(String name) {
    return '를 $name 복원만들기상회스테이징또는커밋내용?미스테이징변경손실됨,및없음복구 불가。';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return '를 $name 복원에상회커밋내용?해당파일스테이징됨및 미스테이징변경모두손실됨,및없음복구 불가。';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return '복원됨삭제 $name?을로부터상회커밋복구이파일。';
  }

  @override
  String get gitActionDeleteFile => '삭제파일';

  @override
  String get gitActionDeleteDir => '삭제디렉토리';

  @override
  String get gitMergePendingTitle => '병합 대기 중';

  @override
  String get gitMergePendingHint => '현재없음미해결 충돌。부탁확인및스테이징보존할 변경 사항,그다음커밋을완료병합。';

  @override
  String get gitActionAbortMerge => '중단병합';

  @override
  String get gitAbortMergeConfirm =>
      '확인중단현재병합할까요?미해결 충돌 변경 사항을폐기됨,작업 영역을복원에병합전상태。';

  @override
  String get gitCommitChanges => '커밋변경';

  @override
  String get gitCommitNeedsIdentity => '아직미설정커밋서명,부탁에「자격 증명및서명」페이지입력사용자명및이메일';

  @override
  String get gitCommitDialogTitle => '커밋변경';

  @override
  String get gitCommitMessage => '커밋정보';

  @override
  String get gitCommitAmend => '추가에상회커밋 (--amend)';

  @override
  String get gitCommitAiGenerate => 'AI 생성';

  @override
  String get gitCommitGenerating => '생성 중…';

  @override
  String get gitActionCommit => '커밋';

  @override
  String get gitTabStash => '스태시';

  @override
  String get gitStashTitle => '스태시 상자';

  @override
  String get gitActionStash => '스태시변경';

  @override
  String get gitStashMessageHint => '스태시설명(선택 사항)';

  @override
  String get gitStashIncludeUntracked => '포함추적 안 됨파일(-u)';

  @override
  String get gitStashEmpty => '임시없음스태시기록';

  @override
  String get gitStashPop => '팝업 (Pop)';

  @override
  String get gitStashApply => '앱 (Apply)';

  @override
  String get gitStashDrop => '폐기 (Drop)';

  @override
  String gitStashDropConfirm(String index) {
    return '확인폐기스태시 $index ~?해당작업되돌릴 수 없음。';
  }

  @override
  String get gitStashClear => '청소빈전체';

  @override
  String get gitStashClearConfirm => '확인청소빈장소있음스태시기록~?해당작업되돌릴 수 없음。';

  @override
  String gitStashCount(int count) {
    return '스태시 ($count)';
  }

  @override
  String get gitPull => '풀';

  @override
  String get gitPush => '푸시';

  @override
  String get gitPullDirtyConfirm =>
      '현재작업 영역있음미커밋변경,풀충돌 유발 가능。먼저 권장커밋또는스테이징。계속 진행풀~?';

  @override
  String get gitPullContinue => '계속풀';

  @override
  String get gitNoUpstream => '상류 미설정';

  @override
  String gitTrackingBranch(String name) {
    return '추적 $name';
  }

  @override
  String gitAheadCount(int count) {
    return '대기푸시 $count';
  }

  @override
  String gitBehindCount(int count) {
    return '대기풀 $count';
  }

  @override
  String get gitBranchSynced => '동기화됨';

  @override
  String get gitDetachedHeadLabel => 'detached HEAD:현재안에어떤브랜치상';

  @override
  String get gitNoBranch => '(없음브랜치)';

  @override
  String get gitLoadingBranches => '중불러오기브랜치목록…';

  @override
  String get gitNoCheckedOutBranch => '체크아웃 안 됨브랜치';

  @override
  String get gitClean => '작업 영역깨끗함';

  @override
  String get gitHasChanges => '작업 영역있음변경';

  @override
  String get gitNotARepo => '현재작업 영역아직예 Git 저장소';

  @override
  String get gitCloningHint => '중클론저장소,부탁잠시 기다려 주세요…';

  @override
  String get gitInitDescPrimary => '가능에새 초기화저장소,시작버전관리';

  @override
  String get gitInitDescSecondary => '만약디렉토리됨있음 Git 저장소,또는 직접선택사용';

  @override
  String get gitInitRepo => '새 초기화저장소';

  @override
  String get gitCloneRepo => '클론원격저장소';

  @override
  String get gitCloneDialogTitle => '클론 Git 저장소';

  @override
  String get gitCloneDesc =>
      '을원격저장소클론에현재작업 영역근원디렉토리(작업 영역필요를 위해빈)。만약를 위해개인있음저장소,먼저 가능클릭오른쪽 상단키로그인 GitHub 또는 접근 토큰 입력。';

  @override
  String get gitCloneUrlLabel => '저장소주소';

  @override
  String get gitCloning => '중클론저장소,부탁잠시 기다려 주세요…';

  @override
  String get gitSwitchRepo => '저장소 전환';

  @override
  String get gitPickExistingRepo => '선택됨있음저장소';

  @override
  String get gitRepoSelectorTitle => '선택저장소';

  @override
  String get gitRepoNotRepo => '아니저장소';

  @override
  String get gitPickRepoEmpty => '현재작업 영역없음선택 사항디렉토리';

  @override
  String get gitNoBranches => '임시없음브랜치';

  @override
  String get gitNewBranch => '새로 만들기브랜치';

  @override
  String get gitBranchName => '브랜치이름';

  @override
  String get gitBaseBranch => '기준브랜치';

  @override
  String get gitCreateAndSwitch => '만들기및전환';

  @override
  String get gitDeleteBranch => '삭제브랜치';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '삭제로컬브랜치 $name?';
  }

  @override
  String get gitDeleteRemoteBranch => '삭제원격브랜치';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return '삭제원격브랜치 $name?해당작업되돌릴 수 없음。';
  }

  @override
  String get gitRenameBranch => '이름 변경브랜치';

  @override
  String gitRenameTo(String name) {
    return '을 $name 이름 변경를 위해:';
  }

  @override
  String get gitNewBranchName => '새브랜치이름';

  @override
  String get gitTags => '태그';

  @override
  String get gitTagName => '태그이름';

  @override
  String get gitDeleteTag => '삭제태그';

  @override
  String gitDeleteTagConfirm(String name) {
    return '삭제로컬태그 $name?';
  }

  @override
  String gitCreateTagDesc(String hash) {
    return '로부터현재 HEAD($hash)만들기가벼움태그';
  }

  @override
  String get gitCheckedOut => '현재체크아웃';

  @override
  String get gitCurrentBranch => '현재브랜치';

  @override
  String get gitRemote => '원격';

  @override
  String get commonLocal => '로컬';

  @override
  String get gitNew => '추가';

  @override
  String get gitNoCommits => '임시없음커밋기록';

  @override
  String gitCommitCount(int count) {
    return '커밋기록 ($count)';
  }

  @override
  String get gitSearchCommitsHint => '검색커밋설명또는 작성자…';

  @override
  String get gitLoadMoreCommits => '상끌기불러오기더 이른커밋';

  @override
  String get gitNoMoreCommits => '없음더보기';

  @override
  String get gitLatestCommit => '최신커밋';

  @override
  String gitFilesChanged(int count) {
    return '$count 개파일변경';
  }

  @override
  String get gitNoFilesChanged => '해당커밋없음파일변경';

  @override
  String get gitMergeCommit => '병합커밋';

  @override
  String get gitLoadingFiles => '중불러오기변경파일…';

  @override
  String get gitCopyShortHash => '복사단축 해시';

  @override
  String get gitCopyFullHash => '복사완전한 해시';

  @override
  String get gitActionCreateBranch => '만들기브랜치';

  @override
  String get gitActionCreateTag => '만들기태그';

  @override
  String get gitCreateBranchFromCommit => '기본에이커밋만들기브랜치';

  @override
  String get gitCreateTagAtCommit => '에이커밋만들기태그';

  @override
  String get gitResetToCommit => '재설정에이커밋 (Reset)';

  @override
  String get gitResetSoft => 'Soft(보존작업 영역및스테이징구역)';

  @override
  String get gitResetMixed => 'Mixed(보존작업 영역,청소빈스테이징구역)';

  @override
  String gitResetConfirm(String hash) {
    return '확인을현재브랜치재설정에커밋 $hash ~?';
  }

  @override
  String get gitDiffBinary => '2진수파일,안표시차이';

  @override
  String get gitDiffTooLarge => '파일과다,차이 계산 안 됨';

  @override
  String get gitDiffEmpty => '없음가능표시차이';

  @override
  String get gitCopyPath => '경로 복사';

  @override
  String get gitViewDiff => '보기차이';

  @override
  String get gitRevert => '변경 사항 롤백';

  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return '삭제 $name?그것로부터아직커밋지남,삭제후없음통과 불가 Git 복원。';
  }

  @override
  String get gitAddToGitignore => '추가에 .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return '이 항목 무시파일 ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return '전체 무시개디렉토리 ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return '동일 무시유형파일 (*.$ext)';
  }

  @override
  String get gitPathCopied => '됨경로 복사';

  @override
  String gitActionFailed(String action, String error) {
    return '$action실패:$error';
  }

  @override
  String gitActionDone(String action) {
    return '$action성공';
  }

  @override
  String gitCheckoutSuccess(String name) {
    return '됨전환에 $name';
  }

  @override
  String get gitNoRemotePull => '미설정원격저장소,없음방법풀';

  @override
  String get gitNoRemotePush => '미설정원격저장소,없음방법푸시';

  @override
  String get gitPushMasterConfirmTitle => '브랜치이름 지정 제안';

  @override
  String get gitPushMasterConfirmDesc =>
      '현재로컬브랜치를 위해 master,GitHub 및 GitLab 사용 권장 main 작업를 위해기본값주요브랜치。확인을로컬브랜치이름 변경를 위해 main 후다시푸시?';

  @override
  String get gitPushRenameToMain => '이름 변경를 위해 main 및푸시';

  @override
  String get gitPushKeepMaster => '보존 master 푸시';

  @override
  String get gitTesting => '테스트';

  @override
  String get credentialToken => '접근 토큰(Token / PAT)';

  @override
  String get gitUserName => 'user.name';

  @override
  String get gitUserEmail => 'user.email';

  @override
  String get gitRepoUrl => '저장소주소';

  @override
  String get gitSelectBranch => '선택기준브랜치';

  @override
  String get credentialTokenLogin => '토큰로그인';

  @override
  String get credentialTokenLoginDesc => '단지붙여넣기접근 토큰(PAT),푸시시자동원격 호스트 매칭';

  @override
  String get credentialTokenSaved => '토큰저장됨';

  @override
  String get commonShow => '표시';

  @override
  String get commonHide => '숨기기';

  @override
  String get credentialAdd => '추가자격 증명';

  @override
  String get settingsSubtitle => '관리 AI、모양、동기화및앱데이터';

  @override
  String get accountAndData => '계정 및데이터';

  @override
  String get themeTitle => '테마';

  @override
  String get themeSubtitle => '외관、배경과 표시';

  @override
  String get aboutSubtitle => '버전、업데이트및 피드백';

  @override
  String get aboutAutoCheck => '자동확인업데이트';

  @override
  String get aboutAutoCheckDesc => '열기 App 시자동새 항목 감지버전';

  @override
  String get aboutUpdateChannel => '업데이트채널';

  @override
  String get aboutStableChannel => '안정 버전';

  @override
  String get aboutDownloadMirror => '하이미지 소스 로드';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub 저장소';

  @override
  String get aboutUserAgreement => '사용자프로토콜';

  @override
  String get aboutPrivacyPolicy => '개인정보 보호정책';

  @override
  String get mcpTitle => 'MCP 서버';

  @override
  String get mcpSubtitle => '외부 접근도구 Model Context Protocol 서비스';

  @override
  String get mcpAdd => '추가 MCP';

  @override
  String get mcpEdit => '편집 MCP';

  @override
  String get mcpEmpty => '아직없음구성 MCP 서버';

  @override
  String get mcpEmptyHint => '클릭클릭오른쪽 상단 + 가능추가원격 HTTP 또는로컬 stdio 서버';

  @override
  String get mcpSearchPlaceholder => '검색 MCP 서버…';

  @override
  String get mcpSearchEmpty => '찾을 수 없음에매칭 MCP 서버';

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
  String get mcpStatusNotConnected => '연결 안 됨';

  @override
  String get mcpStatusConnected => '연결됨';

  @override
  String get mcpStatusConnecting => '연결중간…';

  @override
  String get mcpStatusFailed => '연결 실패';

  @override
  String get mcpStatusNeedsAuth => '필요로그인';

  @override
  String mcpToolsCount(int count) {
    return '$count 개도구';
  }

  @override
  String get mcpDetails => '상세';

  @override
  String get mcpBasicSettings => '기본설정';

  @override
  String get mcpEnabledLabel => '확인활성화';

  @override
  String get mcpNameLabel => '이름';

  @override
  String get mcpNameHint => '예:fetch、github、gitlab';

  @override
  String get mcpNameInvalid => '이름문자만 포함 가능、숫자、밑줄및 하이픈';

  @override
  String get mcpTransportType => '전송유형';

  @override
  String get mcpRemoteHttp => '원격 HTTP';

  @override
  String get mcpLocalStdio => '로컬 stdio';

  @override
  String get mcpServerUrl => '서버주소';

  @override
  String get mcpServerUrlHint => '예:https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => '사용자 정의요청 헤더';

  @override
  String get mcpNoCustomHeaders => '임시없음구성사용자 정의 Header';

  @override
  String get mcpHeaderName => '요청 헤더이름';

  @override
  String get mcpHeaderNameHint => '예 Authorization';

  @override
  String get mcpHeaderValue => '요청 헤더값';

  @override
  String get mcpHeaderValueHint => '예 Bearer xxxxxx';

  @override
  String get mcpAddHeader => '추가요청 헤더';

  @override
  String get mcpCommand => '시작명령';

  @override
  String get mcpCommandHint => '예:npx';

  @override
  String get mcpArgs => '명령 매개변수';

  @override
  String get mcpNoArgs => '없음추가 명령줄 매개변수';

  @override
  String get mcpArgValue => '매개변수 값';

  @override
  String get mcpArgHint => '예 -y 또는 @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => '추가매개변수';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return '활성화됨 $enabled / $total 개도구';
  }

  @override
  String get mcpToolsSearch => '검색도구이름또는설명…';

  @override
  String get mcpToolsSearchEmpty => '찾을 수 없음에매칭도구';

  @override
  String get mcpToolsEnableAll => '전체활성화';

  @override
  String get mcpToolsDisableAll => '전체비활성화';

  @override
  String get mcpSaveFirstHint => '부탁먼저저장및연결서버후보기도구목록';

  @override
  String get mcpNoToolsHint => '감지 안 됨에도구,클릭클릭오른쪽 상단새로고침버튼재시도';

  @override
  String get mcpNoDescription => '없음설명';

  @override
  String get mcpAddSheetTitle => '추가 MCP 서버';

  @override
  String get mcpAddManual => '수동입력';

  @override
  String get mcpAddManualDesc => '점진적개입력주소、요청 헤더또는시작명령';

  @override
  String get mcpAddFromJson => '로부터 JSON 가져오기';

  @override
  String get mcpAddFromJsonDesc => '붙여넣기표준 mcpServers 구성일괄가져오기';

  @override
  String get mcpJsonImportTitle => '로부터 JSON 가져오기';

  @override
  String get mcpJsonImportHint =>
      '붙여넣기표준 mcpServers 구성:키예서버 이름,값 안에 입력 url(원격 HTTP)또는 command(로컬 stdio)。';

  @override
  String get mcpJsonImportAction => '가져오기';

  @override
  String get mcpJsonImportEmpty => '미해석에어떤 MCP 서버';

  @override
  String get mcpSaved => '저장됨';

  @override
  String get mcpRefreshTools => '새로고침도구';

  @override
  String get mcpRemoved => '됨제거 MCP 서버';

  @override
  String get permissionsTitle => '도구인증';

  @override
  String get permissionsSubtitle => '규칙그렇다면및 기억';

  @override
  String permCurrentProject(String name) {
    return '현재 프로젝트:$name';
  }

  @override
  String get permCurrentProjectNone => '현재 프로젝트(미선택)';

  @override
  String get permNoProjectRules => '본프로젝트임시없음규칙그렇다면';

  @override
  String get permGlobal => '전역';

  @override
  String get permNoGlobalRules => '임시없음전역규칙그렇다면';

  @override
  String get permEntireTool => '정리개도구';

  @override
  String get permDeny => '금지';

  @override
  String get permPromoteToGlobal => '향상를 위해전역';

  @override
  String get permRulesShort => '대화중간선택「항상실행」모임에현재 프로젝트기억 규칙 생성그렇다면';

  @override
  String get chatPermDeny => '거부';

  @override
  String get chatPermAlwaysAllow => '항상실행';

  @override
  String get chatPermAlwaysToolDesc => '「항상실행」을에본프로젝트기억:해당도구전체호출';

  @override
  String get chatPermAlwaysPrefix => '「항상실행」을에본프로젝트기억:';

  @override
  String get chatPermSingleUseDesc => '해당호출기억 불가,한 번만 허용';

  @override
  String get commonName => '이름';

  @override
  String get commonTool => '도구';

  @override
  String get commonAdd => '추가';

  @override
  String commonLabelWithApi(String label, String api) {
    return '$label($api)';
  }

  @override
  String get commonExpand => '펼치기';

  @override
  String get commonCollapse => '접기';

  @override
  String get mcpViewLogs => '보기이 MCP 로그';

  @override
  String get mcpAuthEnable => 'OAuth 인증';

  @override
  String get mcpAuthDesc => '사용에필요브라우저로그인인증원격 MCP 서비스';

  @override
  String get mcpAuthClientId => 'client_id(선택 사항)';

  @override
  String get mcpAuthClientIdHint => '사전 등록된 클라이언트 ID;비움빈그렇다면동적 등록 시도';

  @override
  String get mcpAuthServer => '인증서버(선택 사항)';

  @override
  String get mcpAuthServerHint => '덮어쓰기자동발견인증서버주소';

  @override
  String get mcpAuthAdvanced => '고급인증옵션';

  @override
  String get mcpAuthLogin => '로그인 / 다시인증';

  @override
  String get mcpAuthReauthorize => '다시인증';

  @override
  String get mcpAuthLogout => '로그아웃로그인';

  @override
  String get mcpAuthCancel => '취소인증';

  @override
  String get mcpAuthInProgress => '대기브라우저인증…';

  @override
  String get mcpAuthInProgressHint => '됨에시스템브라우저열기로그인페이지,인증완료후을자동뒤로 가기및연결';

  @override
  String get mcpAuthSaveFirst => '저장서버구성후,그로 충분에여기서 시작로그인인증';

  @override
  String mcpAuthFailed(String message) {
    return '인증실패:$message';
  }

  @override
  String get mcpAuthStatusLabel => '인증상태';

  @override
  String get mcpAuthStatusAuthorized => '로그인됨';

  @override
  String get mcpAuthStatusUnauthorized => '로그인 안 됨';

  @override
  String get mcpAuthStatusAuthorizing => '인증중간';

  @override
  String get mcpAuthSuccess => '인증성공,연결됨';

  @override
  String get settingsReconnect => '다시연결';

  @override
  String get settingsAddMcpServer => '추가 MCP 서버';

  @override
  String get settingsContainer => '컨테이너 및 이미지';

  @override
  String get settingsContainerSubtitle => 'PRoot 컨테이너、이미지 및 초기화';

  @override
  String get commonEdit => '수정';

  @override
  String get commonSwitch => '전환';

  @override
  String get chatOpenTerminal => '열기터미널';

  @override
  String get terminalTitle => '터미널';

  @override
  String terminalStartFailed(String message) {
    return '없음방법시작터미널:';
  }

  @override
  String get terminalRetry => '재시도';

  @override
  String get terminalNoOpenTabs => '없음열기터미널태그';

  @override
  String get terminalNewTab => '새로 만들기태그';

  @override
  String get terminalCloseTab => '닫기태그';

  @override
  String get terminalSettingsTitle => '터미널설정';

  @override
  String get terminalThemeTitle => '색상 구성테마';

  @override
  String get terminalThemeFollowApp => '따르기앱';

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
  String get terminalFontSizeTitle => '글꼴크기';

  @override
  String get terminalCursorStyleTitle => '커서 스타일';

  @override
  String get terminalCursorBlock => '블록';

  @override
  String get terminalCursorUnderline => '밑줄';

  @override
  String get terminalCursorBar => '세로선';

  @override
  String get terminalFontTitle => '터미널글꼴';

  @override
  String get terminalFontDefault => '시스템고정 폭';

  @override
  String get terminalFontBuiltin => 'JetBrains Mono';

  @override
  String get settingsGeneral => '선호도설정';

  @override
  String get settingsGeneralModels => '모델';

  @override
  String get settingsAutoRemoveStaleModels => '모델 가져오기후자동제거없음효과모델';

  @override
  String get settingsAutoRemoveStaleModelsDesc => '풀성공후,원격 제거됨없음에로컬모델개목표';

  @override
  String get settingsGeneralSession => '세션';

  @override
  String get settingsStartupSession => '시작시세션';

  @override
  String get settingsStartupSessionNew => '새로 열기세션';

  @override
  String get settingsStartupSessionNewDesc => '아직 재사용전송지남메시지빈세션,그렇지 않으면새로 만들기';

  @override
  String get settingsStartupSessionRecent => '열기최근세션';

  @override
  String get settingsStartupSessionRecentDesc => '최근 항목으로 바로 이동업데이트세션';

  @override
  String get settingsDeleteExternalWorkspaceSessions => '삭제외부작업 영역채팅 기록';

  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc =>
      '외부 제거로컬작업 영역시,함께삭제해당작업 영역채팅 기록';

  @override
  String get settingsGeneralInput => '입력';

  @override
  String get settingsEnterToSend => '엔터 키전송메시지';

  @override
  String get settingsEnterToSendDesc => '닫기후엔터 줄바꿈,필요클릭전송버튼전송';

  @override
  String get settingsCompactionThreshold => '자동압축 임계값';

  @override
  String get settingsCompactionThresholdDesc => '상하파일 점유율 도달에창 비율시자동압축';

  @override
  String get settingsCompactionThresholdInputHint => '입력 1-100 정수 백분율';

  @override
  String settingsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsGeneralNetwork => '네트워크';

  @override
  String get settingsFirstByteTimeout => '첫 바이트시간 초과';

  @override
  String get settingsFirstByteTimeoutDesc => '대기첫개응답블록 최대시간';

  @override
  String get settingsStreamIdleTimeout => '데이터블록 간격시간 초과';

  @override
  String get settingsStreamIdleTimeoutDesc => '두개응답블록 간 최대대기';

  @override
  String get settingsTimeoutUnlimited => '제한 없음';

  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds 초';
  }

  @override
  String get settingsTimeoutInputHint => '단위초,입력 0 표시제한 없음';

  @override
  String get settingsMaxNetworkRetries => '재시도횟수';

  @override
  String get settingsMaxNetworkRetriesDesc => '네트워크실패후지수 백오프재시도횟수';

  @override
  String settingsRetriesCount(int count) {
    return '$count 회';
  }

  @override
  String get settingsRetriesInputHint => '입력 0 표시 안 함재시도';

  @override
  String get settingsGeneralTools => '도구';

  @override
  String get settingsSendfileMaxSize => 'sendFile 단일파일상제한';

  @override
  String get settingsGeneralGoal => '목표(goal)';

  @override
  String get settingsGoalMaxTurns => '최대연속 실행바퀴수';

  @override
  String get settingsGoalMaxTurnsDesc => '자율 루프 최대 몇 바퀴 실행바퀴,도달에즉시중지';

  @override
  String get settingsGoalMaxTokens => 'token 예산';

  @override
  String get settingsGoalMaxTokensDesc => '자율 루프 누적 입력 소비입력+출력 token 상제한';

  @override
  String settingsTurnsValue(int count) {
    return '$count 바퀴';
  }

  @override
  String settingsTokensValue(int count) {
    return '$count';
  }

  @override
  String get settingsGoalMaxTurnsInputHint => '확장 입력에 0 정수바퀴수';

  @override
  String get settingsGoalMaxTokensInputHint => '작게 입력에 1000 정수';

  @override
  String get settingsSendfileMaxSizeDesc => '단일개파일크기상제한,초과그렇다면일괄전송실패';

  @override
  String get settingsSendfileMaxSizeInputHint => '단위 MB,확장 입력에 0 정수';

  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }

  @override
  String providerModelsAlignedRemoved(int count) {
    return '됨제거 $count 개원격됨없음에모델';
  }

  @override
  String get tokenStatsTitle => 'Token 통계';

  @override
  String get tokenStatsPeriodToday => '오늘';

  @override
  String get tokenStatsPeriod7d => '최근 7일';

  @override
  String get tokenStatsPeriod30d => '가까운30일';

  @override
  String get tokenStatsPeriodAll => '전체';

  @override
  String get tokenStatsTotal => '총 소비';

  @override
  String get tokenStatsRequests => '요청횟수';

  @override
  String get tokenStatsCost => '비용';

  @override
  String get tokenStatsCacheHitRate => '캐시명령중간비율';

  @override
  String tokenStatsCacheReadWrite(String read, String write) {
    return '읽기 $read / 쓰기 $write';
  }

  @override
  String get tokenStatsTrend => '소비추세';

  @override
  String get tokenStatsLegendInput => '입력';

  @override
  String get tokenStatsLegendOutput => '출력';

  @override
  String get tokenStatsLegendCached => '캐시';

  @override
  String get tokenStatsProvider => '제공자통계';

  @override
  String get tokenStatsModel => '모델통계';

  @override
  String tokenStatsSuccessRate(String rate) {
    return '성공률 $rate';
  }

  @override
  String get tokenStatsRecentCalls => '호출기록';

  @override
  String get tokenStatsUnknown => '알 수 없음';

  @override
  String get tokenStatsNoData => '임시없음데이터';

  @override
  String get tokenStatsCallsSuffix => '호출 횟수';

  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count 회호출';
  }

  @override
  String get tokenStatsColModel => '모델';

  @override
  String get tokenStatsColReasoningEffort => '사고 강도';

  @override
  String get tokenStatsColProvider => '제공자';

  @override
  String get tokenStatsColInput => '입력';

  @override
  String get tokenStatsColOutput => '출력';

  @override
  String get tokenStatsColCachedRead => '캐시읽기';

  @override
  String get tokenStatsColCachedWrite => '캐시쓰기';

  @override
  String get tokenStatsColCacheHitRate => '명령중간비율';

  @override
  String get tokenStatsColTtfb => '첫 바이트';

  @override
  String get tokenStatsColDuration => '소요 시간';

  @override
  String get tokenStatsColTime => '시간';

  @override
  String get tokenStatsColStatus => '상태';

  @override
  String get tokenStatsColCost => '비용';

  @override
  String tokenStatsPage(int page, int total) {
    return '제 $page / $total 페이지';
  }

  @override
  String tokenStatsRetries(int count) {
    return '재시도 $count 회';
  }

  @override
  String get tokenStatsReset => '재설정';

  @override
  String get tokenStatsResetTitle => '재설정 Token 통계';

  @override
  String get tokenStatsResetConfirm => '을청소빈전체호출기록,이작업불가복원。확인재설정?';

  @override
  String get tokenStatsFilterAllProviders => '전체제공자';

  @override
  String get tokenStatsFilterAllModels => '전체모델';

  @override
  String get tokenStatsFilterClear => '지우기필터';

  @override
  String tokenStatsFilterProvider(String name) {
    return '제공자:$name';
  }

  @override
  String tokenStatsFilterModel(String name) {
    return '모델:$name';
  }

  @override
  String tokenStatsProviderKeys(int count) {
    return '$count 개비밀번호';
  }

  @override
  String get tokenStatsRequestsUnit => '요청 횟수';

  @override
  String get tokenStatsHourSuffix => '시';

  @override
  String get tokenStatsPrevPage => '이전 페이지';

  @override
  String get tokenStatsNextPage => '다음 페이지';

  @override
  String get settingsCategoryData => '데이터및 진단';

  @override
  String get gitActionClone => '클론';

  @override
  String get gitActionInit => '초기화';

  @override
  String get gitActionMerge => '병합브랜치';

  @override
  String get gitActionStageAll => '전체스테이징';

  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';

  @override
  String get gitComputingDiff => '중차이 계산…';

  @override
  String get gitCreateTagTitle => '새로 만들기태그';

  @override
  String gitCreateTrackingBranch(String branch) {
    return '로부터원격브랜치 $branch 만들기로컬추적브랜치및전환?';
  }

  @override
  String get gitCredentialsAndIdentity => '자격 증명및서명';

  @override
  String gitDetachedHeadWarning(String ref) {
    return '전환에태그 $ref 을진입 detached HEAD 상태——처리 안 함에어떤브랜치상,새커밋속하지 않음에어떤브랜치。확인계속?';
  }

  @override
  String gitMergeConfirm(String branch, String current) {
    return '확인을브랜치 $branch 병합에현재브랜치($current)~?';
  }

  @override
  String get gitMergeNoFf => '만들기병합커밋(--no-ff)';

  @override
  String get gitOpenInEditor => '에편집기기중간열기';

  @override
  String get gitSwitchBranch => '전환브랜치';

  @override
  String gitSwitchConfirm(String ref) {
    return '확인전환에 $ref?';
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
    return '전환실패:$error';
  }

  @override
  String get gitToastNotRepo => '해당디렉토리안예 Git 저장소';

  @override
  String gitToastSwitchRepoFailed(String error) {
    return '전환저장소실패:$error';
  }

  @override
  String get gitToastDiffFailed => '불러오기차이실패';

  @override
  String get gitToastNoDiffForCommit => '스테이징구역 및작업 영역균등없음차이,없음생성 불가커밋정보';

  @override
  String get gitToastGenerateCommitFailed => 'AI 생성커밋정보실패,부탁확인모델또는네트워크';

  @override
  String get diffBinaryFile => '2진수파일,지원 안 함파일본차이에비교';

  @override
  String get diffFileTooLarge => '파일과다,됨건너뛰기차이 계산';

  @override
  String get diffFileTooLargeDesc =>
      '초과 2000 줄 또는 초과 길이 줄파일행 단위 수행 안 함 diff,렌더링 및 메모리 압력 방지를 위해。';

  @override
  String get diffNoChanges => '없음차이';

  @override
  String get back => '뒤로 가기';

  @override
  String get chatOpenGit => '열기 Git';

  @override
  String get switchLabel => '전환';

  @override
  String get credentialEdit => '편집자격 증명';

  @override
  String get credentialToastSaved => '자격 증명저장됨';

  @override
  String credentialToastSaveFailed(String param1) {
    return '저장 실패:%1\$s';
  }

  @override
  String get credentialToastDeleted => '자격 증명됨삭제';

  @override
  String get credentialToastIdentitySaved => '서명및저장소주소저장됨';

  @override
  String get credentialEmptyHint => '아직추가자격 증명,클릭오른쪽 상단 + 추가';

  @override
  String get credentialEmptyTitle => '임시없음 Git 자격 증명';

  @override
  String get credentialEmptyDesc =>
      '구성자격 증명후,Codecraft 가능에푸시또는풀코드저장소시자동완료신원 인증';

  @override
  String get credentialAddManual => '수동추가';

  @override
  String get gitTabIdentity => '서명';

  @override
  String get gitTabCredentials => '자격 증명';

  @override
  String get gitIdentityTitle => '커밋서명';

  @override
  String gitIdentityCodespace(String name) {
    return '현재연결 GitHub Codespace $name';
  }

  @override
  String get gitRepoUrlTitle => '저장소주소';

  @override
  String get gitRemoteUrl => 'remote.origin.url';

  @override
  String gitCredentialsCount(int param1) {
    return '자격 증명 ($param1)';
  }

  @override
  String get codespacesTitle => 'GitHub Codespaces';

  @override
  String codespacesNetworkError(String error) {
    return '네트워크오류:$error';
  }

  @override
  String get codespacesAccount => '계정';

  @override
  String codespacesCount(int count) {
    return 'Codespaces ($count)';
  }

  @override
  String get codespacesEmptyTitle => '아직없음 Codespace';

  @override
  String get codespacesEmptyDesc => '에 GitHub 상만들기 Codespace 후,여기목록 및 연결 가능연결';

  @override
  String get codespacesCreateOnWeb => '에 github.com 새로 만들기';

  @override
  String get codespacesRefresh => '새로고침';

  @override
  String get codespacesOpenInBrowser => '에브라우저열기';

  @override
  String get codespacesStart => '시작';

  @override
  String get codespacesStop => '중지';

  @override
  String get codespacesDelete => '삭제';

  @override
  String codespacesDeleteConfirm(String name) {
    return '삭제하시겠습니까? $name?해당작업되돌릴 수 없음';
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
    return '최근 사용 $time';
  }

  @override
  String get codespacesNoRepo => '알 수 없음저장소';

  @override
  String get codespacesUncommitted => '있음미커밋변경';

  @override
  String get codespacesMoreActions => '더보기작업';

  @override
  String get editorLoadFailed => '없음방법해당 읽기파일';

  @override
  String get editorSaveFailed => '저장 실패';

  @override
  String get editorSaved => '저장됨';

  @override
  String get editorCharacters => '역할';

  @override
  String get characterTitle => '역할관리';

  @override
  String get characterNew => '새로 만들기역할';

  @override
  String get characterEdit => '편집역할';

  @override
  String get characterEmpty => '임시없음역할';

  @override
  String get characterSearchHint => '검색역할이름、별칭또는태그';

  @override
  String get characterSearchEmpty => '찾을 수 없음에매칭역할';

  @override
  String get characterFieldBasic => '기본 정보';

  @override
  String get characterFieldName => '이름';

  @override
  String get characterFieldNameHint => '역할실제이름';

  @override
  String get characterFieldAlias => '별칭/호칭';

  @override
  String get characterFieldAliasHint => '이야기중간자주 사용하는 호칭(예:장 씨、리 씨)';

  @override
  String get characterFieldGender => '성별';

  @override
  String get characterFieldGenderHint => '남/여/기타';

  @override
  String get characterFieldAge => '나이';

  @override
  String get characterFieldAgeHint => '숫자,예 25';

  @override
  String get characterFieldBirthday => '생일';

  @override
  String get characterFieldBirthdayHint => '형식:MM-DD,예 01-15';

  @override
  String get characterFieldAppearance => '외모묘사';

  @override
  String get characterFieldAppearanceHint => '몸높음、체형、머리 색상、눈동자 색상、특성 등';

  @override
  String get characterFieldPersonality => '성격';

  @override
  String get characterFieldPersonalityHint => '성격 특성클릭、동작모드、말하기 스타일 등';

  @override
  String get characterFieldBackground => '배경이야기';

  @override
  String get characterFieldBackgroundHint => '성장 경험、중요이벤트、가족배경등';

  @override
  String get characterFieldGoals => '목표/소망';

  @override
  String get characterFieldGoalsHint => '역할달성하고자 하는 일、추구하는 것';

  @override
  String get characterFieldFears => '두려움/약점';

  @override
  String get characterFieldFearsHint => '두려운 일、심리적 트라우마、치명적약점등';

  @override
  String get characterFieldTags => '태그';

  @override
  String get characterFieldTagsHint => '콤마로 구분,예:주인공、악역、마법사';

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
  String get editorUndo => '실행 취소';

  @override
  String get editorRedo => '다시 실행';

  @override
  String get editorSearch => '검색';

  @override
  String get editorSearchHint => '찾기내용';

  @override
  String get editorSearchPrev => '이전';

  @override
  String get editorSearchNext => '다음';

  @override
  String get editorTypeset => '자동조판';

  @override
  String get editorTypesetDone => '됨조판,가능실행 취소';

  @override
  String get editorCopy => '복사';

  @override
  String get editorCopied => '됨복사에클리프보드';

  @override
  String get editorUnsavedState => '저장 안 됨';

  @override
  String editorWordCount(int count) {
    return '$count 문자';
  }

  @override
  String get editorNoFile => '아직없음열기파일,로부터차이페이지클릭「에편집기기중간열기」그로 충분';

  @override
  String get editorUnsavedTitle => '미저장수정';

  @override
  String get editorUnsavedMessage => '현재파일있음미저장수정,확인저장?';

  @override
  String get editorSaveAndExit => '저장및로그아웃';

  @override
  String get editorSaveAndSwitch => '저장및전환';

  @override
  String get editorDontSave => '저장 안 함';

  @override
  String get editorMdPreview => '미리보기 Markdown';

  @override
  String get editorMdShowSource => '표시소스 코드';

  @override
  String get editorIndent => '들여쓰기';

  @override
  String get editorCursorLeft => '커서왼쪽이동';

  @override
  String get editorCursorRight => '커서오른쪽이동';

  @override
  String get editorSettings => '편집기기설정';

  @override
  String get editorFontSize => '글꼴크기';

  @override
  String editorFontSizeValue(int size) {
    return '$size sp';
  }

  @override
  String get editorWordWrap => '자동줄바꿈';

  @override
  String get editorShowIndentGuide => '표시들여쓰기참고선';

  @override
  String get editorShowWhitespace => '표시빈빈 기호';

  @override
  String editorFileTooLarge(int mb) {
    return '파일과다($mb MB),임시지원 안 함열기';
  }

  @override
  String get editorBinaryUnsupported => '2진수파일,임시지원 안 함열기';

  @override
  String get editorSaveConflictTitle => '파일됨수정됨';

  @override
  String get editorSaveConflictMessage =>
      '해당파일에당신열기의후됨피함 AI 또는기타프로그램 수정。직접저장덮어씀에다른 변경 사항。';

  @override
  String editorSaveConflictDiff(String diff) {
    return '- 디스크현재내용';
  }

  @override
  String get editorSaveConflictOverwrite => '디스크 덮어쓰기';

  @override
  String get editorSaveConflictDiscard => '내 수정 사항 폐기';

  @override
  String get editorSaveConflictCancel => '취소';

  @override
  String get editorSaveConflictDiscarded => '됨수정 사항 폐기 후 디스크에서 다시 로드내용';

  @override
  String editorLineColumn(int line, int column) {
    return '$line:$column';
  }

  @override
  String get codespacesConnect => '연결';

  @override
  String get codespacesDisconnect => '연결 해제';

  @override
  String get codespacesGhMissing =>
      '컨테이너 내에없음 gh(GitHub CLI)。부탁먼저에터미널명령 실행 codecraft,선택「GitHub Codespaces」시나리오설치의존성。';

  @override
  String get codespacesExecutionEnv => '실행 환경';

  @override
  String get codespacesEnvLocal => '로컬컨테이너';

  @override
  String get codespacesEnvCodespace => '원격 Codespace';

  @override
  String terminalRemoteEnv(String name) {
    return '원격환경:$name';
  }

  @override
  String get codespacesNew => '새로 만들기 Codespace';

  @override
  String get codespacesRepoTab => '저장소';

  @override
  String get codespacesRepoSearchHint => '검색저장소';

  @override
  String get codespacesBranch => '브랜치(비움빈사용기본값브랜치)';

  @override
  String get codespacesMachine => '머신 사양';

  @override
  String get codespacesMachineDefault => '기본값사양';

  @override
  String get codespacesCreate => '만들기';

  @override
  String get codespacesRename => '이름 변경';

  @override
  String get codespacesRenameTitle => 'Codespace 표시이름';

  @override
  String get codespacesChangeMachine => '변경머신 유형';

  @override
  String get codespacesNoMachines => '해당저장소없음선택 사항머신 유형';

  @override
  String get codespacesLoadFailed => '불러오기실패';

  @override
  String get codespacesPorts => '포트';

  @override
  String get codespacesPortsEmpty => '해당 Codespace 아직없음전달포트';

  @override
  String get codespacesPortVisibility => '가시성';

  @override
  String get codespacesPortPrivate => '나만';

  @override
  String get codespacesPortOrg => '조직 내부';

  @override
  String get codespacesPortPublic => '공개';

  @override
  String get codespacesPortOpen => '열기';

  @override
  String get codespacesRebuild => '컨테이너 재건축';

  @override
  String get codespacesRebuildDesc =>
      '재건축 시현재 devcontainer 다시만들기컨테이너:코드및 미커밋변경 사항 유지,컨테이너 내부설치됨도구및실행상태손실됨。';

  @override
  String get codespacesRebuildFull => '완전 재건축(동일시지우기캐시 Docker 이미지,더 느림)';

  @override
  String get settingsLog => '로그';

  @override
  String get settingsLogSubtitle => '앱실행로그및 AI 요청로그';

  @override
  String get logFiles => '로그파일';

  @override
  String get logNoFiles => '아직없음로그파일';

  @override
  String logReadFailed(String error) {
    return '읽기로그실패:$error';
  }

  @override
  String get logSearchHint => '검색로그';

  @override
  String get logNoMatch => '현재필터개항목하없음로그';

  @override
  String get logLevel => '로그수준';

  @override
  String get logLevelDesc =>
      '기록낮음에해당수준로그을무시됨。개발 중 권장 사항 VERBOSE(전체기록);NONE 닫기로그。';

  @override
  String get logCopied => '복사됨';

  @override
  String logMcpPrefix(String server) {
    return 'MCP 로그:$server';
  }

  @override
  String logSearchResults(int count) {
    return '매칭 $count 행';
  }

  @override
  String logShowLastLines(int shown, int total) {
    return '표시최대후 $shown/$total 행';
  }

  @override
  String logShowLines(int count) {
    return '표시 $count 행';
  }

  @override
  String get logCopy => '복사';

  @override
  String get logClearFilter => '지우기필터';

  @override
  String get logCopyMenuTitle => '복사로그';

  @override
  String get logCopyLine => '복사본개로그';

  @override
  String get logCopyWithStack => '복사본개및 스택 추적';

  @override
  String get logCopyMessage => '복사메시지내용';

  @override
  String get logFollowLatest => '실제시스크롤';

  @override
  String get logFileLocation => '로그파일위치에 Android/data/<패키지명>/files/logs/。';

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
      '권장하는 대로 codespace 범위 GitHub 토큰,한 번 입력시제공 Git 푸시및 Codespaces 로그인사용';

  @override
  String get credentialHostOptional => '호스트(선택 사항)';

  @override
  String get credentialHostAny => '비움빈 = 장소있음호스트';

  @override
  String get credentialHostHint => '단지에필요에게특정 호스트에만 개별 토큰 구성시입력,예 gitlab.com';

  @override
  String get codespacesNeedCredentialTitle => '아직미설정 GitHub 자격 증명';

  @override
  String get codespacesNeedCredentialDesc =>
      'Codespaces 사용「Git 자격 증명」안의 토큰(포함 필요 codespace 범위),더 이상 개별 입력。';

  @override
  String get codespacesGoToCredentials => '채우기 위해 가다 Git 자격 증명';

  @override
  String get credentialAllHosts => '장소있음호스트';

  @override
  String get credentialUsernameAuto => '사용자명자동추론';

  @override
  String get chatMentionSkill => '@ 기술';

  @override
  String get chatMentionSkillEmpty => '아직없음사용 가능기술,먼저에설정안에가져오기또는새로 만들기하나개。';

  @override
  String get chatMentionSkillManage => '관리기술';

  @override
  String get chatPickFile => '# 파일';

  @override
  String get chatPickFileParent => '상위';

  @override
  String get chatPickFileEmpty => '이디렉토리예빈';

  @override
  String get mentionHintSkill => '계속입력가능필터기술';

  @override
  String get mentionHintFile => '계속입력가능필터파일';

  @override
  String get fileBrowserError => '읽기디렉토리실패';

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
    return '삭제하시겠습니까?폴더「$name」및전체내용?';
  }

  @override
  String get fileBrowserCreateFailed => '생성에 실패했습니다,가능됨저장에동일 이름개또는없음쓰기권한';

  @override
  String get fileBrowserRenameFailed => '이름 변경에 실패했습니다,가능됨저장에동일 이름개';

  @override
  String get fileBrowserDeleteFailed => '삭제에 실패했습니다';

  @override
  String get fileBrowserPasteHere => '붙여넣기에여기';

  @override
  String get fileBrowserExtract => '압축 해제';

  @override
  String get fileBrowserExtractFailed => '압축 해제실패';

  @override
  String get fileBrowserExtractConflictTitle => '목표폴더됨저장에';

  @override
  String fileBrowserExtractConflict(String name) {
    return '동일디렉토리하됨있음「$name」,압축 해제먼저 덮어씀내용。';
  }

  @override
  String get fileBrowserExtractOverwrite => '덮어쓰고압축 해제';

  @override
  String get fileBrowserPasteConflictTitle => '동일 이름파일됨저장에';

  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '목표위치됨저장에동일 이름프로젝트「$name」,확인덮어쓰기?';
  }

  @override
  String get fileBrowserClipboardCut => '됨잘라내기';

  @override
  String get fileBrowserClipboardCopy => '복사됨';

  @override
  String get commonCopy => '복사';

  @override
  String get commonCut => '잘라내기';

  @override
  String get commonPaste => '붙여넣기';

  @override
  String get workspacePickWritingFolder => '글쓰기디렉토리';

  @override
  String get writingFolderNeedAccessTitle => '필요저장소접근권한';

  @override
  String get writingFolderNeedAccessDesc =>
      '휴대폰에서 읽기「AI글쓰기」디렉토리필요「장소있음파일접근권한」。또한 가능건너뛰기,직접에하단계선택디렉토리。';

  @override
  String get writingFolderGrant => '권한 해제';

  @override
  String writingFolderSet(String path) {
    return '글쓰기디렉토리됨설정를 위해 $path';
  }

  @override
  String get modelAuto => 'Auto Model';

  @override
  String get modelAutoDesc => '작업별자동선택가장 적합모델';

  @override
  String get sessionExport => '내보내기세션';

  @override
  String sessionExportDone(String path) {
    return '됨내보내기에 $path';
  }

  @override
  String get sessionExportFailed => '내보내기실패';

  @override
  String get sessionBatchSelect => '일괄선택';

  @override
  String sessionSelectedCount(String count) {
    return '선택됨 $count 개';
  }

  @override
  String get sessionSelectAll => '모두 선택';

  @override
  String get sessionCancelSelect => '취소';

  @override
  String get sessionDeleteSelected => '삭제선택';

  @override
  String get sessionDeleteConfirm => '삭제해당세션및전체메시지?';

  @override
  String get fileBrowserNeedPermission => '없음방법해당 읽기폴더,필요할 수 있음저장소접근권한';

  @override
  String get checkpointRewindTitle => '롤백에여기';

  @override
  String checkpointTargetPrompt(String snippet) {
    return '목표:$snippet';
  }

  @override
  String get checkpointRestoreCodeAndConversation => '복원코드및세션';

  @override
  String get checkpointRestoreCodeAndConversationDesc =>
      '롤백작업 영역 파일,및삭제이의후장소있음메시지,질문 내용이 채워짐에입력상자';

  @override
  String get checkpointRestoreConversation => '단지복원세션';

  @override
  String get checkpointRestoreConversationDesc =>
      '삭제이의후장소있음메시지,작업 영역 파일변경 없음 유지';

  @override
  String get checkpointRestoreCode => '단지복원코드';

  @override
  String get checkpointRestoreCodeDesc => '롤백작업 영역 파일,대화기록변경 없음 유지';

  @override
  String checkpointRewindSkipped(int count) {
    return '$count 개파일저장됨에기타변경됨건너뛰기';
  }

  @override
  String get chatMoreOptions => '더보기옵션';

  @override
  String get chatActionEdit => '수정';

  @override
  String get chatActionDelete => '삭제';

  @override
  String get chatEditMessageTitle => '편집메시지';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonClose => '닫기';

  @override
  String get commonBatchDelete => '일괄삭제';

  @override
  String get tabProjects => '프로젝트';

  @override
  String get projectListEmpty => '아직없음프로젝트';

  @override
  String get workspaceCurrent => '현재';

  @override
  String get workspaceNameHint => '프로젝트이름';

  @override
  String get projectNew => '새로 만들기프로젝트';

  @override
  String get projectUntitled => '제목 없음프로젝트';

  @override
  String get projectKindCoding => '프로그래밍';

  @override
  String get projectKindCodingDesc => '에샌드박스작업 영역안에 쓰기코드、명령 실행、변경파일';

  @override
  String get projectKindWriting => '글쓰기';

  @override
  String get projectKindWritingDesc => '에「AI글쓰기」디렉토리여기서 문서 작성 및 수정';

  @override
  String get projectKindReverse => '앱역방향';

  @override
  String get projectKindReverseDesc => '분석 APK、패킷 캡처인터페이스、정적 역분석 및디버그도움';

  @override
  String projectDeleteConfirm(String name) {
    return '삭제하시겠습니까?프로젝트「$name」?기타하장소있음세션모두 함께삭제。';
  }

  @override
  String get installedAppsTitle => '선택앱';

  @override
  String get installedAppsSearch => '검색앱이름 또는 패키지명';

  @override
  String get installedAppsEmpty => '없음매칭앱';

  @override
  String get storagePermissionGrant => '권한 해제';

  @override
  String get softwarePermissionsTitle => '소프트웨어권한';

  @override
  String get softwarePermissionsSubtitle =>
      '클릭어떤개에 의해시스템팝업인증,또는 건너뜀에에응용시스템설정페이지。';

  @override
  String get systemPermissionsGroup => '시스템권한';

  @override
  String get permissionStorageTitle => '접근저장소빈간격';

  @override
  String get permissionBatteryTitle => '배터리 최적화 무시';

  @override
  String get permissionBatteryDesc => '허용후지속실행,종료 감소';

  @override
  String get permissionAutoStartTitle => '스스로시작관리';

  @override
  String get permissionAutoStartDesc => '허용시스템에후대자동시작앱';

  @override
  String get permissionShizukuTitle => 'Shizuku';

  @override
  String get permissionShizukuDesc => '클릭클릭전향해하로드설치 Shizuku';

  @override
  String get permissionAllowed => '허용됨';

  @override
  String get permissionNotAllowed => '허용 안 됨';

  @override
  String get permissionInstalled => '설치됨';

  @override
  String get permissionNotInstalled => '설치 안 됨';

  @override
  String get permissionAppsTitle => '앱목록';

  @override
  String get permissionAppsDesc => '읽기설치됨앱이름、패키지명 및버전';

  @override
  String get apkPathUnavailable => '가져올 수 없음에이앱설치패키지경로,바꾸기개앱다시 시도。';

  @override
  String get apkExtractHint => '이프로젝트표시선택 APK 안에파일。최초 탐색 시 먼저압축 해제한 번。';

  @override
  String get apkExtractAction => '압축 해제 APK';

  @override
  String get apkExtracting => '중압축 해제…';

  @override
  String get apkExtractFailed => '압축 해제실패,가능없음해당 읽기설치패키지권한。';

  @override
  String get terminalAgentTab => 'AI 명령';

  @override
  String get runModeAuto => '자동모드';

  @override
  String get runModeBuild => '구축모드';

  @override
  String get runModePlan => '계획모드';

  @override
  String get runModePlanIntercept => '현재장소에계획모드,금지쓰기 실행작업';

  @override
  String get runModeBuildAuthorize => 'AI 시도쓰기 실행작업,확인허용?';

  @override
  String get runModeBuildAllow => '허용';

  @override
  String get runModeBuildDeny => '거부';

  @override
  String runModeSwitchChanged(Object mode) {
    return '실행모드됨전환까지 $mode';
  }

  @override
  String get commonScrollToBottom => '회에하단';

  @override
  String get subagentTitle => '서브 에이전트';

  @override
  String get subagentSubtitle => '모델단계 및사용자 정의정의';

  @override
  String get subagentTierSubtitle =>
      '를 위해매개단계 바인딩제공자및모델。미설정단계:서브 에이전트정의하드코딩모델시사용정의모델,그렇지 않으면상속현재세션모델';

  @override
  String get subagentTierSection => '모델단계';

  @override
  String get subagentTierLight => '가벼움';

  @override
  String get subagentTierStandard => '균형';

  @override
  String get subagentTierStrong => '강력';

  @override
  String get subagentTierLightDesc => '읽기 전용 탐색、일괄위치 지정、기계적 이름 변경';

  @override
  String get subagentTierStandardDesc => '단일파일 수정및표준수정';

  @override
  String get subagentTierStrongDesc => '모듈 간 리팩토링、문제 해결 및 솔루션 설계';

  @override
  String get subagentTierUnset => '미설정(상속현재세션모델)';

  @override
  String get subagentTierPick => '선택모델';

  @override
  String get subagentTierClear => '지우기';

  @override
  String get subagentTierCleared => '지움';

  @override
  String get subagentTierSaved => '저장됨';

  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier 파일모델';
  }

  @override
  String get subagentTierSheetHint => '선택해당 단계 사용제공자및모델';

  @override
  String get subagentTierSheetInherit => '상속현재세션모델';

  @override
  String get subagentNoticeTitle => '서브 에이전트';

  @override
  String get subagentStateRunning => '실행 중';

  @override
  String get subagentStateCompleted => '완료';

  @override
  String get subagentStateFailed => '실행실패';

  @override
  String get subagentStateMessage => '새 메시지';

  @override
  String get subagentViewOutput => '보기출력';

  @override
  String get subagentOpen => '열기';

  @override
  String get subagentOutputEmpty => '임시없음출력';

  @override
  String get subagentOutputTitle => '서브 에이전트출력';

  @override
  String get promptsTitle => '팁단어';

  @override
  String get promptsScenarioSection => '시나리오팁단어';

  @override
  String get promptsSortLongPress => '길게 눌러 조정 가능순서';

  @override
  String get promptsEmpty => '임시없음사용 가능조각';

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
  String get promptsFieldNumberPlaceholder => '두 자리 숫자,예 35';

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
  String get promptsFieldContentPlaceholder => '쓰기모델준수해야 함내용';

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
      '을삭제현재 프로젝트및전역내부의 모든있음사용자 정의팁단어,각번호폴백에기본 제공팁단어。이 작업은 되돌릴 수 없습니다。';

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
    return '선택한 항목을 삭제하시겠습니까? $count 개의 사용자 정의 프롬프트~?해당 번호는 다음 계층의 소스로 대체됩니다。';
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
  String get novelFieldTagsHint => '가능다중 선택,또한 가능사용자 정의';

  @override
  String get novelCustomTagHint => '사용자 정의태그';

  @override
  String get novelFieldWordsPerChapter => '장당 글자 수';

  @override
  String get novelFieldWordsHint => '선택 사항단계,또한 가능사용자 정의';

  @override
  String get novelCreate => '만들기';

  @override
  String get novelPickExisting => '기존 소설 선택';

  @override
  String get novelOpen => '열기';

  @override
  String get novelExistingEmpty => '「AI소설」디렉토리안에 있음없음기타소설';

  @override
  String get novelExistingEmptyHint => '소설을 넣다폴더넣기 AI소설 디렉토리후,다시 돌아감에여기선택';

  @override
  String get novelExistingFailed => '소설 목록 읽기 실패';

  @override
  String novelExistingBrief(String title) {
    return '집필 계속됨있음소설《$title》,먼저 읽기「소설 자료」및됨있음장,설정 및 진행 상황후다시 쓰기 시작。';
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
    return '$path 에서 소설 디렉토리를 생성할 수 없음,부탁확인저장소권한후재시도。';
  }

  @override
  String get agentTitle => '서브 에이전트';

  @override
  String get agentSubtitle => '사용자 정의 서브 에이전트 정의';

  @override
  String get agentListEmpty => '사용자 정의 서브 에이전트 없음';

  @override
  String get agentListEmptyHint => '클릭오른쪽 상단 + 새로 만들기사용자 정의 서브 에이전트 정의';

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
    return '삭제 $name?이작업불가복원。';
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
  String get agentDetailHint => '편집정의;이름 변경 시 정의 파일도 함께 이름 변경';

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
  String get codespacesRetentionHint => '중지후보존일수（선택 사항）';

  @override
  String get codespacesReadinessTitle => '연결 준비 완료';

  @override
  String get codespacesReadinessCredOk => 'GitHub 자격 증명：설정됨';

  @override
  String get codespacesReadinessCredMissing =>
      'GitHub 자격 증명：미설정（포함 필요 codespace 권한토큰）';

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
      'Git 푸시/풀 등 작업작용함에현재실행 환경；연결 Codespace 후즉시에원격저장소배포 실행/동기화。';

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
      '프록시를 통한 트래픽만 수집。HTTPS는 CA 설치 및 신뢰 필요；Android 7+ 대부분의 앱 및 인증서 고정 앱은 MITM 불가능（디버그 버전/신뢰된 인증서 시나리오에서 사용 가능）。';

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
  String get captureDeleteConfirm => '삭제해당 도메인전체기록？';

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

  @override
  String get storageTitle => '저장 공간';

  @override
  String get storageRefresh => '다시 통계';

  @override
  String get storageCategoryDetail => '사용 내역';

  @override
  String get storageFootnote =>
      '화살표가 있는 카테고리를 탭하면 세부 정보를 확장할 수 있습니다. 대화를 삭제하면 대화 기록이 줄어듭니다.';

  @override
  String storageFreedBytes(Object size) {
    return '해제된 크기 $size';
  }

  @override
  String get storageAppUsage => '앱 사용량';

  @override
  String get storageComputing => '통계 중…';

  @override
  String storageDeviceSpace(Object available, Object total) {
    return '사용 가능 $available / 총 $total';
  }

  @override
  String storageCleanSelect(Object size) {
    return '선택 항목 정리 · $size';
  }

  @override
  String get storageConfirmClean => '정리 확인';

  @override
  String storageConfirmContent(Object size) {
    return '다음 선택 항목을 정리합니다. 총 약 $size입니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get storageConfirmDetail =>
      '로컬 앱 캐시, 로그, 전역 디렉토리의 선택된 데이터만 정리합니다. 여러 작업 공간의 과거 출력 읽기 또는 이미지 기반 추적 문의에 영향을 줄 수 있습니다. 대화 기록, 작업 공간 파일, AI 구성, 원격 서버 데이터는 삭제되지 않습니다.';

  @override
  String get storageCancel => '취소';

  @override
  String get storageClean => '정리';

  @override
  String get storageUsageUnavailable => '—';

  @override
  String get storageCategoryContainer => '容器';

  @override
  String get storageCategoryContainerImage => '容器镜像';

  @override
  String get storageCategoryChat => '聊天';

  @override
  String get storageCategoryWorkspaces => '工作区';

  @override
  String get storageCategoryAiConfig => 'AI 配置';

  @override
  String get storageCategoryCheckpoints => '检查点';

  @override
  String get storageCategoryLogs => '日志';

  @override
  String get storageCategoryCaches => '缓存';

  @override
  String get storageCategoryOther => '其他数据';

  @override
  String get storageCategoryApk => '应用安装包';

  @override
  String get cleanupCaches => '缓存文件';

  @override
  String get cleanupCachesDesc => '临时文件,删除后会自动重建';

  @override
  String get cleanupLogs => '运行日志';

  @override
  String get cleanupLogsDesc => '应用日志与 AI 请求日志,删除不影响功能';

  @override
  String get cleanupToolOutput => '工具输出存档';

  @override
  String get cleanupToolOutputDesc => 'AI 超长工具输出保存到磁盘的副本,删除后旧消息里的输出路径不再可读';

  @override
  String get cleanupVisionSessions => '识图会话缓存';

  @override
  String get cleanupVisionSessionsDesc => '识图追问的历史,删除后无法继续追问旧图片';

  @override
  String get containerPageTitle => '컨테이너 및 이미지';

  @override
  String get containerDownloadTooltip => '컨테이너 다운로드';

  @override
  String get containerRefreshTooltip => '새로고침';

  @override
  String get containerInstalledSection => '설치된 컨테이너';

  @override
  String get containerDefaultLabel => '기본 컨테이너';

  @override
  String get containerSetDefault => '기본으로 설정';

  @override
  String get containerDeleteTitle => '컨테이너 삭제';

  @override
  String containerDeleteContent(String name) {
    return '「$name」을(를) 삭제하시겠습니까? 컨테이너 내에 설치된 소프트웨어도 함께 삭제됩니다.';
  }

  @override
  String get containerDownloadPageTitle => '컨테이너 다운로드';

  @override
  String get containerDownloadHint =>
      '다운로드할 이미지를 선택하세요. 이미지는 공식 aarch64 rootfs이며, 압축 해제 후 PRoot가 격리된 파일 시스템을 제공합니다.';

  @override
  String get containerInstallingStage => '설치 중…';

  @override
  String get containerAvailableImages => '사용 가능한 이미지';

  @override
  String get containerDownloadAfter =>
      '다운로드 완료 후, 컨테이너는「컨테이너 및 이미지」페이지에 표시됩니다.';

  @override
  String containerInstalledCount(int count) {
    return '$count 개 설치됨';
  }

  @override
  String get containerDownloadButton => '다운로드';

  @override
  String get containerNoContainers => '다운로드된 컨테이너가 없습니다';

  @override
  String get containerNoContainersDesc => '오른쪽 상단 다운로드 버튼을 클릭하여 이미지를 선택하세요';

  @override
  String containerDefaultSubtitle(String size) {
    return '기본 컨테이너 · $size';
  }

  @override
  String get containerDeleteFootnote =>
      '컨테이너를 삭제하면 컨테이너 내에 설치된 소프트웨어 패키지도 함께 삭제됩니다. 작업 공간 파일은 영향을 받지 않습니다.';

  @override
  String get exportSetPassword => '암호화 비밀번호 설정 (선택 사항)';

  @override
  String get exportBackupAction => '내보내기';

  @override
  String get importSelectBackupFile => '백업 파일 선택';

  @override
  String get importLocalBackup => '로컬 백업';

  @override
  String get importLocalBackupDesc => '앱 문서 디렉토리에서 백업 파일을 선택하세요';

  @override
  String exportSuccess(String fileName) {
    return '백업이 내보내졌습니다: $fileName';
  }

  @override
  String exportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get importSuccess => '백업이 복원되었습니다';

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }
}
