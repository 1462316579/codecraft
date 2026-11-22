// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_globalizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppGlobalizationsJa extends AppGlobalizations {
  AppGlobalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'CodeCraft';

  @override
  String get tabSessions => 'セッション';

  @override
  String get tabSettings => '設定';

  @override
  String get newSession => '新規作成セッション';

  @override
  String get send => '送信';

  @override
  String get stop => '停止';

  @override
  String get reverseTabClasses => 'クラス';

  @override
  String get reverseTabStrings => '文字列プール';

  @override
  String get reverseTabResources => 'リソース';

  @override
  String get reverseTabHex => '16進数';

  @override
  String get reverseSearchClassHint => '検索クラス名';

  @override
  String get reverseSearchStringHint => '検索文字列';

  @override
  String get reverseSearchResourceHint => '検索リソース名、タイプまたは 0x 番号';

  @override
  String get reverseNoMatch => 'なし一致件';

  @override
  String get reverseEmptyFile => 'ファイルのため空';

  @override
  String get reverseLoadFailed => '開く失敗';

  @override
  String get reverseParseFailed => '解析失敗,このファイル可能能被加固または済み损坏';

  @override
  String get reverseEditString => '編集文字列';

  @override
  String get reverseEqualLengthHint =>
      '只能等长置換:新コンテンツ编码後バイト数必须と原文字列一致,そうでなければファイル内オフセット会すべて错位';

  @override
  String get reverseEditByte => '修正バイト';

  @override
  String get reverseEditByteHint => '入力两位16進数,例えば 0a、ff';

  @override
  String get reverseInvalidByte => 'お願いします入力 00-ff 之间16進数バイト';

  @override
  String get reverseJumpToOffset => '跳转にオフセット';

  @override
  String get reverseOffsetInvalid => 'オフセットなし効,お願いします入力16進数';

  @override
  String get reverseSuperclass => '父クラス';

  @override
  String get reverseInterfaces => 'インターフェース';

  @override
  String get reverseAccessFlags => '修飾';

  @override
  String get reverseFields => 'フィールド';

  @override
  String get reverseMethods => 'メソッド';

  @override
  String get reverseAbstractMethod => 'なしメソッド体';

  @override
  String get reverseSmaliHint =>
      '以上のため smali 反汇编結果;offset はいこの指令でメソッド体内バイトオフセット';

  @override
  String get reverseOpenAsHex => '以16進数開く';

  @override
  String reverseMethodCount(int count) {
    return '$count 個メソッド';
  }

  @override
  String reverseFieldCount(int count) {
    return '$count 個フィールド';
  }

  @override
  String reverseHexByteCount(int count) {
    return '合計 $count バイト';
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
  String get rename => '名前変更';

  @override
  String get copy => 'コピー';

  @override
  String get copied => '済みコピー';

  @override
  String get retry => '再試行';

  @override
  String get pin => 'ピン留め';

  @override
  String get unpin => 'キャンセルピン留め';

  @override
  String get search => '検索';

  @override
  String get searchSessions => '検索セッション';

  @override
  String get noSessions => '一時なしセッション';

  @override
  String get noMessages => '開始新チャット吧';

  @override
  String get chatInputPlaceholder => '入力メッセージ,と AI チャット…';

  @override
  String get reasoningTitle => '思考プロセス';

  @override
  String get untitled => '無題';

  @override
  String get pinned => '済みピン留め';

  @override
  String get settings => '設定';

  @override
  String get providers => 'AI プロバイダ';

  @override
  String get providersSubtitle => 'モデル、インターフェースとAPIキー';

  @override
  String get appearance => '外観';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get themeModeSystem => 'システムに従うう';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムに従うう';

  @override
  String get about => 'について';

  @override
  String get version => 'バージョン';

  @override
  String get license => 'オープンソースプロトコル';

  @override
  String get licenseBody =>
      '本プロジェクトはい jieapi/Codecraft  Flutter フォーク,按 GPL-3.0 プロトコルオープンソース。';

  @override
  String get addProvider => '追加プロバイダ';

  @override
  String get providerName => '名前';

  @override
  String get providerType => 'プロトコル';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => 'デフォルトモデル';

  @override
  String get modelList => 'モデルリスト';

  @override
  String get model => 'モデル';

  @override
  String get mode => 'モード';

  @override
  String get reasoningEffort => '思考の深さ';

  @override
  String get reasoningEffortNone => '思考なし';

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
  String get deleteProviderConfirm => '削除してもよろしいですか？このプロバイダ?';

  @override
  String get deleteSessionConfirm => '削除してもよろしいですか？このセッション?';

  @override
  String get emptyProviders => '还なしプロバイダ,クリック右上隅 + 追加';

  @override
  String get emptyModels => '还なしモデル';

  @override
  String get modelInputHint => '入力モデル ID 後回车追加';

  @override
  String get errorGeneric => 'エラー';

  @override
  String get retrying => '再試行中';

  @override
  String get emptyMessage => 'メッセージコンテンツのため空';

  @override
  String get enabled => 'あり効';

  @override
  String get disabled => '無効';

  @override
  String providerModelsCountTag(int count) {
    return '$count 個モデル';
  }

  @override
  String get inputTokens => '入力';

  @override
  String get outputTokens => '出力';

  @override
  String get emptyChatHint => '選択一個セッション開始チャット';

  @override
  String get errorNoProvider => '未設定利使用可能能プロバイダ,お願いします先で設定中追加';

  @override
  String get errorNoModel => 'お願いしますのためこのプロバイダ選択モデル';

  @override
  String get errorEmptyResponse => 'モデル返回空白コンテンツ';

  @override
  String get thinking => '思考中…';

  @override
  String get modelListTitle => '選択モデル';

  @override
  String get providerListTitle => '選択プロバイダ';

  @override
  String get customProvider => 'カスタム';

  @override
  String get addFromPreset => 'から预設追加';

  @override
  String get useFullUrlHint => 'baseUrl 済みはい完全端クリック';

  @override
  String get aboutBody =>
      'Codecraft Flutter はい jieapi/Codecraft  Flutter フォーク(Phase 1:核心チャット闭环)。';

  @override
  String get chatPlaceholder => 'あり什么可能以帮你?';

  @override
  String get chatInputHint => '説明你要件,我来帮你執筆、修正または説明コード';

  @override
  String get openSidebar => '開くサイドバー';

  @override
  String get noModelSelected => '未選択モデル';

  @override
  String get sessionGroupPinned => 'ピン留め';

  @override
  String get sessionGroupToday => '今日';

  @override
  String get sessionGroupYesterday => '昨日';

  @override
  String get sessionGroupLast7Days => '7日以内';

  @override
  String get sessionGroupLast30Days => '30日以内';

  @override
  String get sessionGroupMonthFormat => 'yyyy年M月';

  @override
  String chatThinkingRunningTime(String seconds) {
    return '思考中(所要時間 $seconds 秒)';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return '思考完(所要時間 $seconds 秒)';
  }

  @override
  String get chatThinkingDone => '思考完';

  @override
  String get chatQueueHint => 'AI 中処理中,クリック右方块可能停止';

  @override
  String get chatStatusGenerating => '生成中';

  @override
  String get chatStatusThinking => '思考中';

  @override
  String get chatStatusCallingTool => '中呼び出しび出し工具';

  @override
  String get chatStatusRunningCommand => '中コマンドの実行';

  @override
  String get chatStatusEditingFile => '中編集ファイル';

  @override
  String get chatStatusReadingFile => '読み取得り中ファイル';

  @override
  String get chatStatusViewingImage => '画像表示中';

  @override
  String get chatStatusSearchingWeb => '中ウェブ検索';

  @override
  String get chatStatusBrowsingWeb => '操作中ブラウザ';

  @override
  String get chatStatusAskingUser => 'ユーザー確認中ユーザー';

  @override
  String get chatStatusGeneratingImage => '画像生成中';

  @override
  String get chatStatusUpdatingTodo => 'タスク整理中';

  @override
  String get chatStatusStartingSubagent => '開始中サブエージェント';

  @override
  String get chatCompressingContext => '圧縮中コンテキスト';

  @override
  String get chatContextCompressed => '上下文済み压缩';

  @override
  String get chatCompactionSummary => '引き継ぎ概要';

  @override
  String get chatStatusReadingMemory => 'メモリ読み取得り中';

  @override
  String get chatToolRunning => '工具実行中';

  @override
  String get chatToolSucceeded => '工具実行成功';

  @override
  String get chatToolFailed => '工具実行失敗';

  @override
  String get chatEffortNone => '思考なし';

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
  String get chatAddAttachment => 'ファイルを追加';

  @override
  String get chatUploadFile => '上传ファイル';

  @override
  String get chatUploadImage => '画像をアップロード';

  @override
  String get chatTakePhoto => '写真を撮る';

  @override
  String get attachmentPrefix => '添付:';

  @override
  String attachmentMax(int count) {
    return '最大 $count 個のファイルを同時に送信';
  }

  @override
  String attachmentUploaded(int count) {
    return '済み上传 $count 個附件';
  }

  @override
  String attachmentUploadedPartial(int count) {
    return '済み上传 $count 個附件,部分附件未加入';
  }

  @override
  String attachmentUploading(int count) {
    return 'アップロード中 $count 個ファイル…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return '画像超過 $size,お願いします压缩後再試行';
  }

  @override
  String get attachmentUnsupportedImageType =>
      'なし法识别画像タイプ,仅支持 jpg/png/gif/webp';

  @override
  String get attachmentReadFileFailed => 'なし法読み取り得所选ファイル';

  @override
  String get attachmentUploadFailed => 'アップロード失敗';

  @override
  String get removeAttachment => '添付ファイルを削除';

  @override
  String get imagePreview => '画像プレビュー';

  @override
  String get imageLoadFailed => '画像読み込み失敗,ファイル可能能済み被移動または削除';

  @override
  String get close => '閉じる';

  @override
  String get fileFallback => 'ファイル';

  @override
  String get skillsTitle => 'スキル管理';

  @override
  String get skillsSubtitle => '浏览、インポートと管理執筆技能';

  @override
  String get skillsNew => '新規スキル作成';

  @override
  String get skillsImport => 'インポート Markdown';

  @override
  String get skillsScopeTitle => '選択スコープ';

  @override
  String get skillsScopeGlobal => '';

  @override
  String get skillsScopeProject => 'プロジェクト技能';

  @override
  String get skillsScopeGlobalHint => '~/.codecraft/skills,跨プロジェクト合計享';

  @override
  String get skillsScopeProjectHint =>
      '~/workspace/.codecraft/skills,随現でワークスペース';

  @override
  String skillsProjectGroup(String name) {
    return '現でのプロジェクト($name)';
  }

  @override
  String get skillsNoProjectSkills => '現でのプロジェクト还なし技能';

  @override
  String get skillsNoGlobalSkills => '还なしグローバル技能';

  @override
  String get skillsEmpty => '还なし技能';

  @override
  String get skillsEmptyHint =>
      '技能はい書くに AI 专件操作説明;インポート SKILL.md または手動新規作成一個吧。';

  @override
  String get skillsName => '名前';

  @override
  String get skillsDescription => '説明';

  @override
  String get skillsDescriptionHint => '何時使使用この技能(会進システムヒント)';

  @override
  String get skillsInstructions => '指示本文';

  @override
  String get skillsInstructionsHint => '技能要実行ステップ,Markdown 书書く';

  @override
  String skillsImported(String name) {
    return '済みインポート技能「$name」';
  }

  @override
  String get skillsDeleteTitle => 'スキル削除';

  @override
  String skillsDeleteConfirm(String name) {
    return '削除してもよろしいですか？技能「$name」(含むその他ディレクトリと脚本)?';
  }

  @override
  String get skillsErrorInvalidName =>
      '技能名なし効:なし能のため空、超长または含む / \\ : * ? \" < > |';

  @override
  String get skillsErrorEmptyInstructions => '指令本文なし能のため空';

  @override
  String skillsErrorNameConflict(String name) {
    return '同スコープ済みあり名のため「$name」技能';
  }

  @override
  String get skillsErrorNoSkill => 'ファイル内なし可能识别技能';

  @override
  String get skillsErrorIoFailed => '読書く技能ファイル失敗';

  @override
  String get providerAdd => '追加プロバイダ';

  @override
  String get providerEdit => '編集プロバイダ';

  @override
  String get providerEditModel => '編集モデル';

  @override
  String get providerConfig => '設定';

  @override
  String get providerSectionBasic => '基本情報';

  @override
  String get providerSectionType => '上流形式';

  @override
  String get providerSectionOptions => 'オプション';

  @override
  String get providerFullUrl => '完全な URL';

  @override
  String get providerFullUrlDesc => 'Base URL 即完全リクエストアドレス,なし自動拼接デフォルトパス';

  @override
  String get providerHeadersTitle => 'カスタムリクエストヘッダー';

  @override
  String get providerHeadersDesc => '完全覆盖このプロバイダリクエスト同名デフォルト头';

  @override
  String get providerHeadersAdd => '追加リクエストヘッダー';

  @override
  String get providerHeadersManage => '管理';

  @override
  String providerHeadersCount(int count) {
    return '設定済みみ $count 個リクエストヘッダー';
  }

  @override
  String get providerShowApiKey => '表示APIキー';

  @override
  String get providerHideApiKey => '非表示APIキー';

  @override
  String get providerAddModel => '追加モデル';

  @override
  String get providerNoModels => '一時なしモデル';

  @override
  String get providerNoModelsHint => 'クリック击右上方按钮追加モデル';

  @override
  String get providerModelCurrent => '現で';

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
  String get providerModelsDeselectAll => 'すべて選択を解除';

  @override
  String get providerModelsBatchTest => 'テスト';

  @override
  String get providerModelsBatchDelete => '削除';

  @override
  String get providerModelsBatchDeleteTitle => '削除モデル';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return '選択した項目を削除してもよろしいですか？ $count 個モデルですか?';
  }

  @override
  String get providerFetchModels => '取得得モデル';

  @override
  String get providerAddAllModels => 'すべて追加';

  @override
  String get providerAddAllModelsTitle => '追加すべてモデル';

  @override
  String providerAddAllModelsConfirm(int count) {
    return 'OKを取得得に $count 個モデルすべて追加至現でプロバイダ?';
  }

  @override
  String get providerFilterModelsHint => '入力モデル名前フィルタ';

  @override
  String get providerNoMatchingModels => 'なし一致モデル';

  @override
  String providerModelAdded(String name) {
    return '追加済みみモデル「$name」';
  }

  @override
  String get providerModelName => 'モデル名前';

  @override
  String get providerModelAlreadyAdded => 'このモデル追加済みみ';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · ${latency}ms';
  }

  @override
  String get providerFetchMissingFields => 'レスポンス缺少リストフィールド';

  @override
  String get providerFetchFailed => '取得得モデル失敗';

  @override
  String get providerApiKeyRequired => 'お願いします先入力 API Key';

  @override
  String get providerTestModel => 'テスト';

  @override
  String get providerModelContext => '上下文ウィンドウ (tokens)';

  @override
  String get providerModelContextInput => '入力上限 (tokens)';

  @override
  String get providerModelContextOutput => '出力上限 (tokens)';

  @override
  String get providerModelWindowInvalid => 'お願いします入力あり効正整数,または空欄使使用自動识别値';

  @override
  String get providerModelSectionPrice => '価格';

  @override
  String get providerModelPriceInput => '入力価格 (USD/1M tokens)';

  @override
  String get providerModelPriceOutput => '出力価格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheRead => 'キャッシュ読价格 (USD/1M tokens)';

  @override
  String get providerModelPriceCacheWrite => 'キャッシュ書く价格 (USD/1M tokens)';

  @override
  String get providerModelCapabilities => '能力';

  @override
  String get providerModelCapVision => '画像入力';

  @override
  String get providerModelCapImageOutput => '画像出力';

  @override
  String get providerModelCapTools => '工具呼び出しび出し';

  @override
  String get providerModelCapReasoning => '思考';

  @override
  String get providerModelSectionReasoning => '思考クラス';

  @override
  String get providerModelReasoningHint =>
      '只勾选このモデル真实支持クラス;すべてなし勾ならにより組み込み能力表自動判断';

  @override
  String get providerModelReasoningCanDisable => '可能以閉じる思考';

  @override
  String get providerTestRequestUrl => 'リクエストアドレス';

  @override
  String get providerTestRequestHeaders => 'リクエストヘッダー';

  @override
  String get providerTestRequestBody => 'リクエストボディ';

  @override
  String get providerTestResponse => 'レスポンス';

  @override
  String get providerTestError => 'エラー詳細';

  @override
  String get providerMultiKeyTitle => '多 Key モード';

  @override
  String get providerMultiKeySubtitle => '同一プロバイダ下配多個 Key,APIキー利使用なし可能時自動切换并重发';

  @override
  String get providerMultiKeyManage => '多 Key 管理';

  @override
  String providerMultiKeySummary(int count, String strategy) {
    return '$count 個 · $strategy';
  }

  @override
  String get providerMultiKeyList => 'Key リスト';

  @override
  String providerMultiKeyItem(int index) {
    return 'APIキー #$index';
  }

  @override
  String get providerMultiKeyEmpty => 'クリック此追加第一個 Key';

  @override
  String get providerMultiKeyAdd => '追加 Key';

  @override
  String get providerMultiKeyWeight => 'スケジュール重み';

  @override
  String get providerMultiKeyWeightHint => 'デフォルト 1 · ≤ 0 時なし参と · 最大 1,000,000';

  @override
  String get providerMultiKeyStrategy => '取得使用ポリシー';

  @override
  String get providerMultiKeyStrategySequential => '順序';

  @override
  String get providerMultiKeyStrategySequentialDesc =>
      '常に先頭の Key を使用し、失敗し読み取り値に達したら次の Key に切り替え';

  @override
  String get providerMultiKeyStrategyRoundRobin => 'ラウンドロビン';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc =>
      '新セッション回流起步以摊平额度;同一セッション内なし换 Key,保持キャッシュ命中';

  @override
  String get providerMultiKeyStatusCodes => '自動切换ステータスコード';

  @override
  String get providerMultiKeyStatusCodesHint =>
      '逗号分隔,空欄使使用デフォルト 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => '冷却時間';

  @override
  String get providerMultiKeyCooldownDesc => '切り替えられた Key がどれくらいの間候補に再追加されるか';

  @override
  String get workspaceOpen => 'ワークスペース';

  @override
  String get workspaceLocal => 'ローカルワークスペース';

  @override
  String get workspaceLocalSubtitle => 'アプリデータディレクトリ';

  @override
  String get allow => '許可';

  @override
  String get deny => '拒いいえいいえ';

  @override
  String get tabFiles => 'ファイル';

  @override
  String get newFile => '新規作成ファイル';

  @override
  String get newFolder => '新規作成フォルダ';

  @override
  String get create => '作成';

  @override
  String get deleteFileConfirm => '削除してもよろしいですか？このファイル?';

  @override
  String get deleteFolderConfirm => '削除してもよろしいですか？このフォルダ(含むコンテンツ)?';

  @override
  String get refresh => '更新';

  @override
  String get workspaceNew => '新規作成';

  @override
  String get workspaceEmptyHint => '还なしワークスペース,クリック右上隅「新規作成」';

  @override
  String get workspaceNameExists => '同名ワークスペース済み存で';

  @override
  String get workspaceDelete => '削除ワークスペース';

  @override
  String workspaceDeleteConfirm(String name) {
    return '削除してもよろしいですか？ワークスペース「$name」(含むその他中すべてファイル)?';
  }

  @override
  String get todoDashboardTitle => 'タスク管理';

  @override
  String todoDashboardProgress(int completed, int total) {
    return '$completed/$total 完';
  }

  @override
  String get todoDashboardAllDone => 'すべて完';

  @override
  String get todoInProgress => '実行中';

  @override
  String get todoCompleted => '完';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitRefresh => '更新';

  @override
  String get gitTabStatus => 'ステータス';

  @override
  String get browserTitle => 'ブラウザ';

  @override
  String get browserAddressHint => '入力ネットワーク址または検索';

  @override
  String get browserBack => '戻る';

  @override
  String get browserForward => '進む';

  @override
  String get browserReload => '更新';

  @override
  String get browserNotReady => 'ブラウザ準備未完,お願いしますでアドレス栏入力ネットワーク址開始浏览';

  @override
  String get browserNewTab => '新規作成タグページ';

  @override
  String get browserCloseTab => '閉じるタグページ';

  @override
  String get browserTabDefaultTitle => '新タグページ';

  @override
  String browserTabsCount(int count) {
    return 'タグページ ($count)';
  }

  @override
  String get browserEmptyHint => 'で上方アドレス栏入力ネットワーク址開始浏览';

  @override
  String get browserTabsManage => 'タグページ管理';

  @override
  String get browserEmptyClickHint => 'クリック击上方入力ネットワーク址開始浏览';

  @override
  String get browserNightModeOn => '閉じる夜間モード';

  @override
  String get browserNightModeOff => 'あり効化夜間モード';

  @override
  String get browserDevtools => '開発者ツール';

  @override
  String get browserDialogAlertTitle => 'ネットワークページヒント';

  @override
  String get browserDialogConfirmTitle => 'ネットワークページ確認';

  @override
  String get browserDialogPromptTitle => 'ネットワークページ入力';

  @override
  String get browserMenu => 'さらに表示設定';

  @override
  String get browserMenuTitle => 'ブラウザ設定と工具';

  @override
  String get browserMenuGeneralSection => 'ページと工具';

  @override
  String get browserNightModeTitle => '夜間モード';

  @override
  String get browserNightModeDesc => '降低ページ亮度并あり効化ダーク偏好';

  @override
  String get browserDevtoolsTitle => '開発者ツール';

  @override
  String get browserDevtoolsDesc => 'あり効化移動端 Eruda デバッグ控制台';

  @override
  String get browserUaSection => 'ブラウザ識別 (User-Agent)';

  @override
  String get browserUaDesc => '模拟なし同デバイスと环境アクセスネットワークページ';

  @override
  String get browserUaDefault => 'システムデフォルト';

  @override
  String get browserUaDefaultDesc => '現でデバイス原生 WebView 識別';

  @override
  String get browserUaAndroidPhone => 'Android スマートフォン';

  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';

  @override
  String get browserUaAndroidTablet => 'Android タブレット';

  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';

  @override
  String get browserUaDesktopPc => 'デスクトップ PC';

  @override
  String get browserUaDesktopPcDesc => 'Chrome Desktop (Windows PC)';

  @override
  String get browserUaIphone => 'アップル iPhone';

  @override
  String get browserUaIphoneDesc => 'Mobile Safari (iOS)';

  @override
  String get browserUaIpad => 'アップル iPad';

  @override
  String get browserUaIpadDesc => 'Tablet Safari (iPadOS)';

  @override
  String get browserUaCustom => 'カスタム';

  @override
  String get browserUaCustomDesc => '手動指定 User-Agent 文字列';

  @override
  String get browserUaCustomDialogTitle => 'カスタム User-Agent';

  @override
  String get browserUaCustomInputHint => '完全な User-Agent 文字列を入力';

  @override
  String get browserUaAppliedToast => '済み切换ブラウザ識別并更新ページ';

  @override
  String get gitTabBranches => 'ブランチ';

  @override
  String get gitTabCommits => 'コミット';

  @override
  String get gitStatusClean => 'ワークスペースクリーン,なし変更';

  @override
  String gitConflictedCount(int count) {
    return '存で衝突 ($count)';
  }

  @override
  String gitStagedCount(int count) {
    return '済み一時存 ($count)';
  }

  @override
  String gitModifiedCount(int count) {
    return '済み修正 ($count)';
  }

  @override
  String gitUntrackedCount(int count) {
    return '未トレース ($count)';
  }

  @override
  String get gitConflictedLabel => '存で衝突';

  @override
  String get gitStagedLabel => '済み一時存';

  @override
  String get gitModifiedLabel => '済み修正';

  @override
  String get gitUntrackedLabel => '未トレース';

  @override
  String get gitStage => 'ステージ';

  @override
  String get gitUnstage => 'キャンセル一時存';

  @override
  String get gitStageAll => '一時存すべて';

  @override
  String get gitUnstageAll => 'すべてキャンセル一時存';

  @override
  String get gitUnstageAllConfirm =>
      'をキャンセルすべてファイル一時存,但なし会削除ファイルコンテンツ。OK继续ですか?';

  @override
  String get gitActionRevertAll => 'すべて戻す';

  @override
  String gitRevertAllConfirm(int count) {
    return '破棄すべて未一時存変更($count 個ファイル),復元に上回一時存またはコミットコンテンツ?済み一時存コンテンツなし受影响,但破棄変更なし見つからない。';
  }

  @override
  String get gitActionRestoreFile => '復元ファイル';

  @override
  String gitRevertConfirmWorktree(String name) {
    return 'を $name 復元成上回一時存またはコミットコンテンツ?未一時存変更会紛失,かつなし見つからない。';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return 'を $name 復元に前回コミットコンテンツ?このファイル済み一時存と未一時存変更都会紛失,かつなし見つからない。';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return '復元済み削除 $name?をから前回コミット取得回このファイル。';
  }

  @override
  String get gitActionDeleteFile => '削除ファイル';

  @override
  String get gitActionDeleteDir => '削除ディレクトリ';

  @override
  String get gitMergePendingTitle => 'マージ待コミット';

  @override
  String get gitMergePendingHint => '現でなし未解决衝突。お願いします確認并一時存必要保留変更,回にコミット以完マージ。';

  @override
  String get gitActionAbortMerge => '中止マージ';

  @override
  String get gitAbortMergeConfirm =>
      'OK中止現でマージですか?未解决衝突変更を被放弃,ワークスペースを復元にマージ前ステータス。';

  @override
  String get gitCommitChanges => '変更をコミット';

  @override
  String get gitCommitNeedsIdentity =>
      '未設定コミット署名,お願いしますで「認証情報と署名」ページ入力ユーザー名とメールアドレス';

  @override
  String get gitCommitDialogTitle => '変更をコミット';

  @override
  String get gitCommitMessage => 'コミット情報';

  @override
  String get gitCommitAmend => '追加に前回コミット (--amend)';

  @override
  String get gitCommitAiGenerate => 'AI 生成';

  @override
  String get gitCommitGenerating => '生成中…';

  @override
  String get gitActionCommit => 'コミット';

  @override
  String get gitTabStash => 'スタッシュ';

  @override
  String get gitStashTitle => 'スタッシュ箱';

  @override
  String get gitActionStash => 'スタッシュ変更';

  @override
  String get gitStashMessageHint => 'スタッシュ説明(オプション)';

  @override
  String get gitStashIncludeUntracked => '包含む未トレースファイル(-u)';

  @override
  String get gitStashEmpty => '一時なしスタッシュ記録';

  @override
  String get gitStashPop => 'ポップ (Pop)';

  @override
  String get gitStashApply => 'アプリ (Apply)';

  @override
  String get gitStashDrop => '破棄 (Drop)';

  @override
  String gitStashDropConfirm(String index) {
    return 'OK破棄スタッシュ $index ですか?この操作元に戻せません。';
  }

  @override
  String get gitStashClear => 'クリアすべて';

  @override
  String get gitStashClearConfirm => 'OKクリアすべてスタッシュ記録ですか?この操作元に戻せません。';

  @override
  String gitStashCount(int count) {
    return 'スタッシュ ($count)';
  }

  @override
  String get gitPull => '取得';

  @override
  String get gitPush => 'プッシュ';

  @override
  String get gitPullDirtyConfirm =>
      '現でワークスペースあり未コミットの変更,取得得可能能导致衝突。建议先コミットまたは一時存。仍要继续取得得ですか?';

  @override
  String get gitPullContinue => '続けて取得';

  @override
  String get gitNoUpstream => 'アップストリーム未設定';

  @override
  String gitTrackingBranch(String name) {
    return 'トレース $name';
  }

  @override
  String gitAheadCount(int count) {
    return '待プッシュ $count';
  }

  @override
  String gitBehindCount(int count) {
    return '取得待ち $count';
  }

  @override
  String get gitBranchSynced => '済み同期';

  @override
  String get gitDetachedHeadLabel => 'detached HEAD:現でなしで任意ブランチ上';

  @override
  String get gitNoBranch => '(なしブランチ)';

  @override
  String get gitLoadingBranches => '読み取得り中み込みブランチリスト…';

  @override
  String get gitNoCheckedOutBranch => '未检出ブランチ';

  @override
  String get gitClean => 'ワークスペースクリーン';

  @override
  String get gitHasChanges => 'ワークスペースあり変更';

  @override
  String get gitNotARepo => '現でワークスペース还なしはい Git リポジトリ';

  @override
  String get gitCloningHint => 'クローン中リポジトリ,お願いしますしばらくお待ちください…';

  @override
  String get gitInitDescPrimary => '可能で此初期化新リポジトリ,開始バージョン管理';

  @override
  String get gitInitDescSecondary => '若子ディレクトリ済みあり Git リポジトリ,也可能直接選択使使用';

  @override
  String get gitInitRepo => '初期化新リポジトリ';

  @override
  String get gitCloneRepo => 'クローンリモートリポジトリ';

  @override
  String get gitCloneDialogTitle => 'クローン Git リポジトリ';

  @override
  String get gitCloneDesc =>
      'をリモートリポジトリクローンに現でワークスペース根ディレクトリ(ワークスペース必要のため空)。若のためプライベートリポジトリ,可能先クリック右上隅钥匙ログイン GitHub または入力入アクセストークン。';

  @override
  String get gitCloneUrlLabel => 'リポジトリアドレス';

  @override
  String get gitCloning => 'クローン中リポジトリ,お願いしますしばらくお待ちください…';

  @override
  String get gitSwitchRepo => '切换リポジトリ';

  @override
  String get gitPickExistingRepo => '選択済みありリポジトリ';

  @override
  String get gitRepoSelectorTitle => '選択リポジトリ';

  @override
  String get gitRepoNotRepo => '非リポジトリ';

  @override
  String get gitPickRepoEmpty => '現でワークスペースなしオプションディレクトリ';

  @override
  String get gitNoBranches => '一時なしブランチ';

  @override
  String get gitNewBranch => '新規作成ブランチ';

  @override
  String get gitBranchName => 'ブランチ名';

  @override
  String get gitBaseBranch => '基准ブランチ';

  @override
  String get gitCreateAndSwitch => '作成して切り替え';

  @override
  String get gitDeleteBranch => '削除ブランチ';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return '削除ローカルブランチ $name?';
  }

  @override
  String get gitDeleteRemoteBranch => 'リモート削除ブランチ';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return 'リモート削除ブランチ $name?この操作元に戻せません。';
  }

  @override
  String get gitRenameBranch => '名前変更ブランチ';

  @override
  String gitRenameTo(String name) {
    return 'を $name 名前変更のため:';
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
    return 'から現で HEAD($hash)作成軽量タグ';
  }

  @override
  String get gitCheckedOut => '現で检出';

  @override
  String get gitCurrentBranch => '現でブランチ';

  @override
  String get gitRemote => 'リモート';

  @override
  String get commonLocal => 'ローカル';

  @override
  String get gitNew => '新規';

  @override
  String get gitNoCommits => '一時なしコミット記録';

  @override
  String gitCommitCount(int count) {
    return 'コミット記録 ($count)';
  }

  @override
  String get gitSearchCommitsHint => '検索コミット説明または作者…';

  @override
  String get gitLoadMoreCommits => '上拉読み込みより早いコミット';

  @override
  String get gitNoMoreCommits => 'なしさらに表示';

  @override
  String get gitLatestCommit => '最新コミット';

  @override
  String gitFilesChanged(int count) {
    return '$count 個ファイル変更';
  }

  @override
  String get gitNoFilesChanged => 'このコミットなしファイル変更';

  @override
  String get gitMergeCommit => 'マージコミット';

  @override
  String get gitLoadingFiles => '読み取得り中み込み変更ファイル…';

  @override
  String get gitCopyShortHash => 'コピー短ハッシュ';

  @override
  String get gitCopyFullHash => 'コピー完全ハッシュ';

  @override
  String get gitActionCreateBranch => '作成ブランチ';

  @override
  String get gitActionCreateTag => '作成タグ';

  @override
  String get gitCreateBranchFromCommit => '基にこのコミットを作成ブランチ';

  @override
  String get gitCreateTagAtCommit => 'でこのコミットを作成タグ';

  @override
  String get gitResetToCommit => 'リセットに此コミット (Reset)';

  @override
  String get gitResetSoft => 'Soft(保留ワークスペースとステージング)';

  @override
  String get gitResetMixed => 'Mixed(保留ワークスペース,クリアステージング)';

  @override
  String gitResetConfirm(String hash) {
    return 'OKを現でブランチリセットにコミット $hash ですか?';
  }

  @override
  String get gitDiffBinary => '2進数ファイル,なし表示差异';

  @override
  String get gitDiffTooLarge => 'ファイル過大,未计算差异';

  @override
  String get gitDiffEmpty => 'なし可能表示差异';

  @override
  String get gitCopyPath => 'パスをコピー';

  @override
  String get gitViewDiff => '差分を表示';

  @override
  String get gitRevert => '戻す変更';

  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return '削除 $name?它から未被コミット过,削除後なし法通过 Git 復元。';
  }

  @override
  String get gitAddToGitignore => '追加に .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return '忽略此ファイル ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return '忽略整個ディレクトリ ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return '忽略同タイプファイル (*.$ext)';
  }

  @override
  String get gitPathCopied => '済みパスをコピー';

  @override
  String gitActionFailed(String action, String error) {
    return '$action失敗: $error';
  }

  @override
  String gitActionDone(String action) {
    return '$action成功';
  }

  @override
  String gitCheckoutSuccess(String name) {
    return '済み切换に $name';
  }

  @override
  String get gitNoRemotePull => 'リモート未設定リポジトリ,なし法取得得';

  @override
  String get gitNoRemotePush => 'リモート未設定リポジトリ,なし法プッシュ';

  @override
  String get gitPushMasterConfirmTitle => 'ブランチ命名建议';

  @override
  String get gitPushMasterConfirmDesc =>
      '現でローカルブランチのため master,GitHub と GitLab 推荐使使用 main 作のためデフォルト主ブランチ。よろしいですかをローカルブランチ名前変更のため main 後再プッシュ?';

  @override
  String get gitPushRenameToMain => '名前変更のため main 并プッシュ';

  @override
  String get gitPushKeepMaster => '保留 master プッシュ';

  @override
  String get gitTesting => 'テスト';

  @override
  String get credentialToken => 'アクセストークン(Token / PAT)';

  @override
  String get gitUserName => 'user.name';

  @override
  String get gitUserEmail => 'user.email';

  @override
  String get gitRepoUrl => 'リポジトリアドレス';

  @override
  String get gitSelectBranch => '選択基准ブランチ';

  @override
  String get credentialTokenLogin => 'トークンログイン';

  @override
  String get credentialTokenLoginDesc =>
      '只必要貼り支払いけアクセストークン(PAT),プッシュ時自動一致远端ホスト';

  @override
  String get credentialTokenSaved => 'トークン保存済みみ';

  @override
  String get commonShow => '表示';

  @override
  String get commonHide => '非表示';

  @override
  String get credentialAdd => '追加認証情報';

  @override
  String get settingsSubtitle => '管理 AI、外观、同期とアプリデータ';

  @override
  String get accountAndData => '账户とデータ';

  @override
  String get themeTitle => 'テーマ';

  @override
  String get themeSubtitle => '外観、バックグラウンドと表示';

  @override
  String get aboutSubtitle => 'バージョン、更新と反馈';

  @override
  String get aboutAutoCheck => '自動チェック更新';

  @override
  String get aboutAutoCheckDesc => '開く App 時自動检测新バージョン';

  @override
  String get aboutUpdateChannel => '更新チャンネル';

  @override
  String get aboutStableChannel => '安定版';

  @override
  String get aboutDownloadMirror => '下载イメージ源';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub リポジトリ';

  @override
  String get aboutUserAgreement => 'ユーザープロトコル';

  @override
  String get aboutPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get mcpTitle => 'MCP サーバー';

  @override
  String get mcpSubtitle => '接入外部工具 Model Context Protocol サービス';

  @override
  String get mcpAdd => '追加 MCP';

  @override
  String get mcpEdit => '編集 MCP';

  @override
  String get mcpEmpty => '还なし設定 MCP サーバー';

  @override
  String get mcpEmptyHint => 'クリック击右上隅 + 可能以追加リモート HTTP またはローカル stdio サーバー';

  @override
  String get mcpSearchPlaceholder => '検索 MCP サーバー…';

  @override
  String get mcpSearchEmpty => '見つかりません一致 MCP サーバー';

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
  String get mcpStatusNotConnected => '未接続';

  @override
  String get mcpStatusConnected => '接続済みみ';

  @override
  String get mcpStatusConnecting => '接続中…';

  @override
  String get mcpStatusFailed => '接続に失敗しました';

  @override
  String get mcpStatusNeedsAuth => '必要ログイン';

  @override
  String mcpToolsCount(int count) {
    return '$count 個のツール';
  }

  @override
  String get mcpDetails => '詳細';

  @override
  String get mcpBasicSettings => '基本設定';

  @override
  String get mcpEnabledLabel => 'よろしいですかあり効化';

  @override
  String get mcpNameLabel => '名前';

  @override
  String get mcpNameHint => '例えば:fetch、github、gitlab';

  @override
  String get mcpNameInvalid => '名前只能包含む字母、数値、下線と连字符';

  @override
  String get mcpTransportType => '传输タイプ';

  @override
  String get mcpRemoteHttp => 'リモート HTTP';

  @override
  String get mcpLocalStdio => 'ローカル stdio';

  @override
  String get mcpServerUrl => 'サーバーアドレス';

  @override
  String get mcpServerUrlHint => '例えば:https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => 'カスタムリクエストヘッダー';

  @override
  String get mcpNoCustomHeaders => '一時なし設定カスタム Header';

  @override
  String get mcpHeaderName => 'リクエストヘッダー名前';

  @override
  String get mcpHeaderNameHint => '例: Authorization';

  @override
  String get mcpHeaderValue => 'リクエストヘッダー値';

  @override
  String get mcpHeaderValueHint => '例: Bearer xxxxxx';

  @override
  String get mcpAddHeader => '追加リクエストヘッダー';

  @override
  String get mcpCommand => '開始コマンド';

  @override
  String get mcpCommandHint => '例えば:npx';

  @override
  String get mcpArgs => 'コマンドパラメータ';

  @override
  String get mcpNoArgs => 'なし额外コマンド行パラメータ';

  @override
  String get mcpArgValue => 'パラメータ値';

  @override
  String get mcpArgHint => '如 -y または @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => '追加パラメータ';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return 'あり効 $enabled / $total 個のツール';
  }

  @override
  String get mcpToolsSearch => '検索工具名前または説明…';

  @override
  String get mcpToolsSearchEmpty => '見つかりません一致工具';

  @override
  String get mcpToolsEnableAll => 'すべてあり効化';

  @override
  String get mcpToolsDisableAll => 'すべて無効化';

  @override
  String get mcpSaveFirstHint => 'お願いします先保存并接続サーバー後表示工具リスト';

  @override
  String get mcpNoToolsHint => '未检测に工具,クリック击右上隅更新按钮再試行';

  @override
  String get mcpNoDescription => 'なし説明';

  @override
  String get mcpAddSheetTitle => '追加 MCP サーバー';

  @override
  String get mcpAddManual => '手動入力';

  @override
  String get mcpAddManualDesc => '逐個入力アドレス、リクエストヘッダーまたは開始コマンド';

  @override
  String get mcpAddFromJson => 'から JSON インポート';

  @override
  String get mcpAddFromJsonDesc => '貼り支払いけ標準 mcpServers 設定一括インポート';

  @override
  String get mcpJsonImportTitle => 'から JSON インポート';

  @override
  String get mcpJsonImportHint =>
      '貼り支払いけ標準 mcpServers 設定:键はいサーバー名,値内入力 url(リモート HTTP)または command(ローカル stdio)。';

  @override
  String get mcpJsonImportAction => 'インポート';

  @override
  String get mcpJsonImportEmpty => '未解析に任意 MCP サーバー';

  @override
  String get mcpSaved => '保存済みみ';

  @override
  String get mcpRefreshTools => '更新工具';

  @override
  String get mcpRemoved => '済み削除 MCP サーバー';

  @override
  String get permissionsTitle => '工具認証';

  @override
  String get permissionsSubtitle => 'ルールと记忆';

  @override
  String permCurrentProject(String name) {
    return '現でのプロジェクト:$name';
  }

  @override
  String get permCurrentProjectNone => '現でのプロジェクト(未選択)';

  @override
  String get permNoProjectRules => '本プロジェクト一時なしルール';

  @override
  String get permGlobal => 'グローバル';

  @override
  String get permNoGlobalRules => '一時なしグローバルルール';

  @override
  String get permEntireTool => '整個のツール';

  @override
  String get permDeny => '禁止';

  @override
  String get permPromoteToGlobal => '提升のためグローバル';

  @override
  String get permRulesShort => 'チャット中选「始终実行」会で現でのプロジェクト生成记忆ルール';

  @override
  String get chatPermDeny => '拒いいえいいえ';

  @override
  String get chatPermAlwaysAllow => '常に実行';

  @override
  String get chatPermAlwaysToolDesc => '「始终実行」をで本プロジェクト記憶:この工具すべて呼び出しび出し';

  @override
  String get chatPermAlwaysPrefix => '「始终実行」をで本プロジェクト記憶:';

  @override
  String get chatPermSingleUseDesc => 'この呼び出しび出しなし可能记忆,仅可能単一回放行';

  @override
  String get commonName => '名前';

  @override
  String get commonTool => '工具';

  @override
  String get commonAdd => '追加';

  @override
  String commonLabelWithApi(String label, String api) {
    return '$label($api)';
  }

  @override
  String get commonExpand => '展開';

  @override
  String get commonCollapse => '折りたたむ';

  @override
  String get mcpViewLogs => '表示此 MCP ログ';

  @override
  String get mcpAuthEnable => 'OAuth 認証';

  @override
  String get mcpAuthDesc => '使用に必要ブラウザログイン認証リモート MCP サービス';

  @override
  String get mcpAuthClientId => 'client_id(オプション)';

  @override
  String get mcpAuthClientIdHint => '预注册クライアント ID;空欄なら尝试動态注册';

  @override
  String get mcpAuthServer => '認証サーバー(オプション)';

  @override
  String get mcpAuthServerHint => '覆盖自動发现認証サーバーアドレス';

  @override
  String get mcpAuthAdvanced => '詳細設定认证オプション';

  @override
  String get mcpAuthLogin => 'ログイン / 再認証';

  @override
  String get mcpAuthReauthorize => '再認証';

  @override
  String get mcpAuthLogout => 'ログアウト';

  @override
  String get mcpAuthCancel => 'キャンセル認証';

  @override
  String get mcpAuthInProgress => '待機ブラウザ認証…';

  @override
  String get mcpAuthInProgressHint => '済みでシステムブラウザ開くログインページ,認証完後を自動返回并接続';

  @override
  String get mcpAuthSaveFirst => '保存サーバー設定後,それで十分で此发起ログイン認証';

  @override
  String mcpAuthFailed(String message) {
    return '認証失敗:$message';
  }

  @override
  String get mcpAuthStatusLabel => '認証ステータス';

  @override
  String get mcpAuthStatusAuthorized => '済みログイン';

  @override
  String get mcpAuthStatusUnauthorized => '未ログイン';

  @override
  String get mcpAuthStatusAuthorizing => '認証中';

  @override
  String get mcpAuthSuccess => '認証成功,接続済みみ';

  @override
  String get settingsReconnect => '再接続';

  @override
  String get settingsAddMcpServer => '追加 MCP サーバー';

  @override
  String get settingsContainer => 'コンテナとイメージ';

  @override
  String get settingsContainerSubtitle => 'PRoot コンテナ、イメージと初期化';

  @override
  String get commonEdit => '編集';

  @override
  String get commonSwitch => '切り替え';

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
  String get terminalNoOpenTabs => 'なし開くターミナルタグ';

  @override
  String get terminalNewTab => '新規作成タグ';

  @override
  String get terminalCloseTab => '閉じるタグ';

  @override
  String get terminalSettingsTitle => 'ターミナル設定';

  @override
  String get terminalThemeTitle => '配色テーマ';

  @override
  String get terminalThemeFollowApp => '跟随アプリ';

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
  String get terminalFontSizeTitle => 'フォントサイズ';

  @override
  String get terminalCursorStyleTitle => 'カーソルスタイル';

  @override
  String get terminalCursorBlock => 'ブロック';

  @override
  String get terminalCursorUnderline => '下線';

  @override
  String get terminalCursorBar => '縦線';

  @override
  String get terminalFontTitle => 'ターミナルフォント';

  @override
  String get terminalFontDefault => 'システム等宽';

  @override
  String get terminalFontBuiltin => 'JetBrains Mono';

  @override
  String get settingsGeneral => '一般設定';

  @override
  String get settingsGeneralModels => 'モデル';

  @override
  String get settingsAutoRemoveStaleModels => '取得得モデル後自動削除なし効モデル';

  @override
  String get settingsAutoRemoveStaleModelsDesc => '取得得成功後,削除远端済みなしでローカルモデル件目';

  @override
  String get settingsGeneralSession => 'セッション';

  @override
  String get settingsStartupSession => '開始時セッション';

  @override
  String get settingsStartupSessionNew => '新开セッション';

  @override
  String get settingsStartupSessionNewDesc => '复使用尚未送信过メッセージ空セッション,そうでなければ新規作成';

  @override
  String get settingsStartupSessionRecent => '開く最近セッション';

  @override
  String get settingsStartupSessionRecentDesc => '直接進入最近更新セッション';

  @override
  String get settingsDeleteExternalWorkspaceSessions => '削除外部ワークスペースチャット履歴';

  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc =>
      '削除外部ローカルワークスペース時,一そして削除このワークスペースチャット履歴';

  @override
  String get settingsGeneralInput => '入力';

  @override
  String get settingsEnterToSend => '回车键送信メッセージ';

  @override
  String get settingsEnterToSendDesc => '閉じる後回车改行,必要クリック送信按钮送信';

  @override
  String get settingsCompactionThreshold => '自動圧縮閾値';

  @override
  String get settingsCompactionThresholdDesc => '上下文占使用达にウィンドウこの比率時自動压缩';

  @override
  String get settingsCompactionThresholdInputHint => '入力 1-100 整数パーセント';

  @override
  String settingsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsGeneralNetwork => 'ネットワーク';

  @override
  String get settingsFirstByteTimeout => 'TTFBタイムアウト';

  @override
  String get settingsFirstByteTimeoutDesc => '待機首個レスポンス块最长時間';

  @override
  String get settingsStreamIdleTimeout => 'データ块間隔タイムアウト';

  @override
  String get settingsStreamIdleTimeoutDesc => '两個レスポンス块之间最长待機';

  @override
  String get settingsTimeoutUnlimited => 'なし限制';

  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get settingsTimeoutInputHint => '単一位秒,入力 0 表示なし限制';

  @override
  String get settingsMaxNetworkRetries => '再試行回数';

  @override
  String get settingsMaxNetworkRetriesDesc => 'ネットワーク失敗後指数退避再試行回数';

  @override
  String settingsRetriesCount(int count) {
    return '$count 回';
  }

  @override
  String get settingsRetriesInputHint => '入力 0 表示なし再試行';

  @override
  String get settingsGeneralTools => '工具';

  @override
  String get settingsSendfileMaxSize => 'sendFile 単一ファイル上限';

  @override
  String get settingsGeneralGoal => '目標(goal)';

  @override
  String get settingsGoalMaxTurns => '最大実行回数';

  @override
  String get settingsGoalMaxTurnsDesc => '自律ループ最大续跑多少回,达に即停止';

  @override
  String get settingsGoalMaxTokens => 'token 予算';

  @override
  String get settingsGoalMaxTokensDesc => '自律ループ累计消耗入力+出力 token 上限';

  @override
  String settingsTurnsValue(int count) {
    return '$count 回';
  }

  @override
  String settingsTokensValue(int count) {
    return '$count';
  }

  @override
  String get settingsGoalMaxTurnsInputHint => '拡大入力に 0 整数回数';

  @override
  String get settingsGoalMaxTokensInputHint => '入力なし小に 1000 整数';

  @override
  String get settingsSendfileMaxSizeDesc => '単一個ファイルサイズ上限,超過なら整批送信失敗';

  @override
  String get settingsSendfileMaxSizeInputHint => '単一位 MB,拡大入力に 0 整数';

  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }

  @override
  String providerModelsAlignedRemoved(int count) {
    return '済み削除 $count 個远端済みなしでモデル';
  }

  @override
  String get tokenStatsTitle => 'Token 統計';

  @override
  String get tokenStatsPeriodToday => '今日';

  @override
  String get tokenStatsPeriod7d => '直近 7 日';

  @override
  String get tokenStatsPeriod30d => '直近 30 日';

  @override
  String get tokenStatsPeriodAll => 'すべて';

  @override
  String get tokenStatsTotal => '総消費';

  @override
  String get tokenStatsRequests => 'リクエスト回数';

  @override
  String get tokenStatsCost => '費用';

  @override
  String get tokenStatsCacheHitRate => 'キャッシュ命中率';

  @override
  String tokenStatsCacheReadWrite(String read, String write) {
    return '読み取り得 $read / 書き込み $write';
  }

  @override
  String get tokenStatsTrend => '消耗トレンド';

  @override
  String get tokenStatsLegendInput => '入力';

  @override
  String get tokenStatsLegendOutput => '出力';

  @override
  String get tokenStatsLegendCached => 'キャッシュ';

  @override
  String get tokenStatsProvider => 'プロバイダ統計';

  @override
  String get tokenStatsModel => 'モデル統計';

  @override
  String tokenStatsSuccessRate(String rate) {
    return '成功率 $rate';
  }

  @override
  String get tokenStatsRecentCalls => '呼び出しび出し記録';

  @override
  String get tokenStatsUnknown => 'なし明';

  @override
  String get tokenStatsNoData => '一時なしデータ';

  @override
  String get tokenStatsCallsSuffix => '回の呼び出しび出しび出し';

  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count 回の呼び出しび出しび出し';
  }

  @override
  String get tokenStatsColModel => 'モデル';

  @override
  String get tokenStatsColReasoningEffort => '思考の深さ';

  @override
  String get tokenStatsColProvider => 'プロバイダ';

  @override
  String get tokenStatsColInput => '入力';

  @override
  String get tokenStatsColOutput => '出力';

  @override
  String get tokenStatsColCachedRead => 'キャッシュ読み取り得';

  @override
  String get tokenStatsColCachedWrite => 'キャッシュ書き込み';

  @override
  String get tokenStatsColCacheHitRate => '命中率';

  @override
  String get tokenStatsColTtfb => 'TTFB';

  @override
  String get tokenStatsColDuration => '所要時間';

  @override
  String get tokenStatsColTime => '時間';

  @override
  String get tokenStatsColStatus => 'ステータス';

  @override
  String get tokenStatsColCost => '費用';

  @override
  String tokenStatsPage(int page, int total) {
    return '第 $page / $total ページ';
  }

  @override
  String tokenStatsRetries(int count) {
    return '再試行 $count 回';
  }

  @override
  String get tokenStatsReset => 'リセット';

  @override
  String get tokenStatsResetTitle => 'リセット Token 統計';

  @override
  String get tokenStatsResetConfirm => 'をクリアすべて呼び出しび出し記録,この操作は元に戻せません。OKリセット?';

  @override
  String get tokenStatsFilterAllProviders => 'すべてプロバイダ';

  @override
  String get tokenStatsFilterAllModels => 'すべてモデル';

  @override
  String get tokenStatsFilterClear => 'クリアフィルタ';

  @override
  String tokenStatsFilterProvider(String name) {
    return 'プロバイダ:$name';
  }

  @override
  String tokenStatsFilterModel(String name) {
    return 'モデル:$name';
  }

  @override
  String tokenStatsProviderKeys(int count) {
    return '$count 個APIキー';
  }

  @override
  String get tokenStatsRequestsUnit => '回リクエスト';

  @override
  String get tokenStatsHourSuffix => '時';

  @override
  String get tokenStatsPrevPage => '前ページ';

  @override
  String get tokenStatsNextPage => '回ページ';

  @override
  String get settingsCategoryData => 'データと诊断';

  @override
  String get gitActionClone => 'クローン';

  @override
  String get gitActionInit => '初期化';

  @override
  String get gitActionMerge => 'マージブランチ';

  @override
  String get gitActionStageAll => 'すべて一時存';

  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';

  @override
  String get gitComputingDiff => '差分計算中…';

  @override
  String get gitCreateTagTitle => '新規作成タグ';

  @override
  String gitCreateTrackingBranch(String branch) {
    return 'からリモートブランチ $branch 作成ローカルトレースブランチ并切换?';
  }

  @override
  String get gitCredentialsAndIdentity => '認証情報と署名';

  @override
  String gitDetachedHeadWarning(String ref) {
    return '切换にタグ $ref を進入 detached HEAD ステータス——なし处に任意ブランチ上,新コミットなし属に任意ブランチ。OK继续?';
  }

  @override
  String gitMergeConfirm(String branch, String current) {
    return 'OKをブランチ $branch マージに現でブランチ($current)ですか?';
  }

  @override
  String get gitMergeNoFf => '作成マージコミット(--no-ff)';

  @override
  String get gitOpenInEditor => 'でエディタで開くく';

  @override
  String get gitSwitchBranch => '切换ブランチ';

  @override
  String gitSwitchConfirm(String ref) {
    return 'OK切换に $ref?';
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
    return '切り替え失敗: $error';
  }

  @override
  String get gitToastNotRepo => 'このディレクトリなしはい Git リポジトリ';

  @override
  String gitToastSwitchRepoFailed(String error) {
    return '切换リポジトリ失敗:$error';
  }

  @override
  String get gitToastDiffFailed => '読み込み差异失敗';

  @override
  String get gitToastNoDiffForCommit => 'ステージングとワークスペース均なし差异,なし法生成コミット情報';

  @override
  String get gitToastGenerateCommitFailed =>
      'AI 生成コミット情報失敗,お願いしますチェックモデルまたはネットワーク';

  @override
  String get diffBinaryFile => '2進数ファイル,なし支持テキスト差异に比';

  @override
  String get diffFileTooLarge => 'ファイル過大,済みスキップ差异计算';

  @override
  String get diffFileTooLargeDesc =>
      '超過 2000 行または含む超长行ファイルなし做行レベル diff,以避免渲染と内存压力。';

  @override
  String get diffNoChanges => 'なし差异';

  @override
  String get back => '戻る';

  @override
  String get chatOpenGit => '開く Git';

  @override
  String get switchLabel => '切り替え';

  @override
  String get credentialEdit => '編集認証情報';

  @override
  String get credentialToastSaved => '認証情報保存済みみ';

  @override
  String credentialToastSaveFailed(String param1) {
    return '保存に失敗しました:%1\$s';
  }

  @override
  String get credentialToastDeleted => '認証情報済み削除';

  @override
  String get credentialToastIdentitySaved => '署名とリポジトリアドレス保存済みみ';

  @override
  String get credentialEmptyHint => '尚未追加認証情報,クリック右上隅 + 追加';

  @override
  String get credentialEmptyTitle => '一時なし Git 認証情報';

  @override
  String get credentialEmptyDesc =>
      '設定認証情報後,Codecraft 可能でプッシュまたは取得得コードリポジトリ時自動完身份认证';

  @override
  String get credentialAddManual => '手動追加';

  @override
  String get gitTabIdentity => '署名';

  @override
  String get gitTabCredentials => '認証情報';

  @override
  String get gitIdentityTitle => 'コミット署名';

  @override
  String gitIdentityCodespace(String name) {
    return '現で接続 GitHub Codespace $name';
  }

  @override
  String get gitRepoUrlTitle => 'リポジトリアドレス';

  @override
  String get gitRemoteUrl => 'remote.origin.url';

  @override
  String gitCredentialsCount(int param1) {
    return '認証情報 ($param1)';
  }

  @override
  String get codespacesTitle => 'GitHub Codespaces';

  @override
  String codespacesNetworkError(String error) {
    return 'ネットワークエラー:$error';
  }

  @override
  String get codespacesAccount => 'アカウント';

  @override
  String codespacesCount(int count) {
    return 'Codespaces ($count)';
  }

  @override
  String get codespacesEmptyTitle => '还なし Codespace';

  @override
  String get codespacesEmptyDesc => 'で GitHub 上作成 Codespace 後,ここそれで十分列出并接続';

  @override
  String get codespacesCreateOnWeb => 'で github.com 新規作成';

  @override
  String get codespacesRefresh => '更新';

  @override
  String get codespacesOpenInBrowser => 'でブラウザ開く';

  @override
  String get codespacesStart => '開始';

  @override
  String get codespacesStop => '停止';

  @override
  String get codespacesDelete => '削除';

  @override
  String codespacesDeleteConfirm(String name) {
    return '削除してもよろしいですか？ $name?この操作元に戻せません';
  }

  @override
  String get codespacesStateAvailable => '実行中';

  @override
  String get codespacesStateStarting => '開始中';

  @override
  String get codespacesStateStopped => '停止済みみ';

  @override
  String get codespacesStateUnknown => 'ステータスなし明';

  @override
  String codespacesLastUsed(String time) {
    return '最近使用: $time';
  }

  @override
  String get codespacesNoRepo => 'なし明リポジトリ';

  @override
  String get codespacesUncommitted => 'あり未コミットの変更';

  @override
  String get codespacesMoreActions => 'さらに表示操作';

  @override
  String get editorLoadFailed => 'なし読み取得れませんファイル';

  @override
  String get editorSaveFailed => '保存に失敗しました';

  @override
  String get editorSaved => '保存済みみ';

  @override
  String get editorCharacters => 'ロール';

  @override
  String get characterTitle => 'ロール管理';

  @override
  String get characterNew => '新規作成ロール';

  @override
  String get characterEdit => '編集ロール';

  @override
  String get characterEmpty => '一時なしロール';

  @override
  String get characterSearchHint => '検索ロール名前、別名またはタグ';

  @override
  String get characterSearchEmpty => '見つかりません一致ロール';

  @override
  String get characterFieldBasic => '基本情報';

  @override
  String get characterFieldName => '氏名';

  @override
  String get characterFieldNameHint => 'ロール真实氏名';

  @override
  String get characterFieldAlias => '別名/称呼び出し';

  @override
  String get characterFieldAliasHint => '故事中常使用称呼び出し(如:老张、小李)';

  @override
  String get characterFieldGender => '性別';

  @override
  String get characterFieldGenderHint => '男/女/その他';

  @override
  String get characterFieldAge => '年齢';

  @override
  String get characterFieldAgeHint => '数値,例: 25';

  @override
  String get characterFieldBirthday => '誕生日';

  @override
  String get characterFieldBirthdayHint => '形式:MM-DD,例: 01-15';

  @override
  String get characterFieldAppearance => '外見描書く';

  @override
  String get characterFieldAppearanceHint => '身長、体型、髪の色、瞳の色、特徴など';

  @override
  String get characterFieldPersonality => '性格';

  @override
  String get characterFieldPersonalityHint => '性格特クリック、動作モード、说话风格等';

  @override
  String get characterFieldBackground => 'バックグラウンド故事';

  @override
  String get characterFieldBackgroundHint => '成长经历、重要イベント、家庭バックグラウンド等';

  @override
  String get characterFieldGoals => '目標/願望';

  @override
  String get characterFieldGoalsHint => 'ロール想要达成事、追求东西';

  @override
  String get characterFieldFears => '恐怖/弱クリック';

  @override
  String get characterFieldFearsHint => '害怕事、心理阴影、致命弱クリック等';

  @override
  String get characterFieldTags => 'タグ';

  @override
  String get characterFieldTagsHint => 'カンマ区切り,如:主角、反派、魔法师';

  @override
  String get characterScope => 'スコープ';

  @override
  String get characterScopeProject => '現でのプロジェクト';

  @override
  String get characterScopeGlobal => 'グローバル';

  @override
  String characterSelectedCount(int count) {
    return '選択済み $count 件';
  }

  @override
  String get editorUndo => '元に戻す';

  @override
  String get editorRedo => 'やり直し';

  @override
  String get editorSearch => '検索';

  @override
  String get editorSearchHint => '検索コンテンツ';

  @override
  String get editorSearchPrev => '前へ';

  @override
  String get editorSearchNext => '次へ';

  @override
  String get editorTypeset => '自動組版';

  @override
  String get editorTypesetDone => '済み排版,可能元に戻す';

  @override
  String get editorCopy => 'コピー';

  @override
  String get editorCopied => '済みコピーに剪贴板';

  @override
  String get editorUnsavedState => '未保存';

  @override
  String editorWordCount(int count) {
    return '$count 字';
  }

  @override
  String get editorNoFile => '还なし開くファイル,から差异ページクリック「でエディタで開くく」それで十分';

  @override
  String get editorUnsavedTitle => '未保存の修正';

  @override
  String get editorUnsavedMessage => '現でファイルあり未保存の修正,よろしいですか保存?';

  @override
  String get editorSaveAndExit => '保存して終';

  @override
  String get editorSaveAndSwitch => '保存して切り替え';

  @override
  String get editorDontSave => 'なし保存';

  @override
  String get editorMdPreview => 'プレビュー Markdown';

  @override
  String get editorMdShowSource => 'ソースコードを表示';

  @override
  String get editorIndent => 'インデント';

  @override
  String get editorCursorLeft => 'カーソルを左に移動';

  @override
  String get editorCursorRight => 'カーソルを右に移動';

  @override
  String get editorSettings => 'エディタ設定';

  @override
  String get editorFontSize => 'フォントサイズ';

  @override
  String editorFontSizeValue(int size) {
    return '$size sp';
  }

  @override
  String get editorWordWrap => '自動改行';

  @override
  String get editorShowIndentGuide => 'インデント参考線を表示';

  @override
  String get editorShowWhitespace => '空白文字を表示';

  @override
  String editorFileTooLarge(int mb) {
    return 'ファイル過大($mb MB),一時に開けませんく';
  }

  @override
  String get editorBinaryUnsupported => '2進数ファイル,一時に開けませんく';

  @override
  String get editorSaveConflictTitle => 'ファイル済み被修正';

  @override
  String get editorSaveConflictMessage =>
      'このファイルで你開く後済み被 AI またはその他程序修正。直接保存会覆盖に方変更。';

  @override
  String editorSaveConflictDiff(String diff) {
    return '- 磁盘現でコンテンツ';
  }

  @override
  String get editorSaveConflictOverwrite => 'ディスクを上書き';

  @override
  String get editorSaveConflictDiscard => '自分の変更を破棄';

  @override
  String get editorSaveConflictCancel => 'キャンセル';

  @override
  String get editorSaveConflictDiscarded => '済み放弃修正并重新载入磁盘コンテンツ';

  @override
  String editorLineColumn(int line, int column) {
    return '$line:$column';
  }

  @override
  String get codespacesConnect => '接続';

  @override
  String get codespacesDisconnect => '切断';

  @override
  String get codespacesGhMissing =>
      'コンテナ内还なし gh(GitHub CLI)。お願いします先でターミナルコマンドの実行 codecraft,選択「GitHub Codespaces」シーンインストール依赖。';

  @override
  String get codespacesExecutionEnv => '実行環境';

  @override
  String get codespacesEnvLocal => 'ローカルコンテナ';

  @override
  String get codespacesEnvCodespace => 'リモート Codespace';

  @override
  String terminalRemoteEnv(String name) {
    return 'リモート环境:$name';
  }

  @override
  String get codespacesNew => 'Codespace を新規作成';

  @override
  String get codespacesRepoTab => 'リポジトリ';

  @override
  String get codespacesRepoSearchHint => '検索リポジトリ';

  @override
  String get codespacesBranch => 'ブランチ(空欄使用デフォルトブランチ)';

  @override
  String get codespacesMachine => 'マシン仕様';

  @override
  String get codespacesMachineDefault => 'デフォルト规格';

  @override
  String get codespacesCreate => '作成';

  @override
  String get codespacesRename => '名前変更';

  @override
  String get codespacesRenameTitle => 'Codespace 表示名';

  @override
  String get codespacesChangeMachine => '更改マシンタイプ';

  @override
  String get codespacesNoMachines => 'このリポジトリなしオプションマシンタイプ';

  @override
  String get codespacesLoadFailed => '読み込み失敗';

  @override
  String get codespacesPorts => 'ポート';

  @override
  String get codespacesPortsEmpty => 'この Codespace 还なし転送端口';

  @override
  String get codespacesPortVisibility => '可視性';

  @override
  String get codespacesPortPrivate => '自分だけ';

  @override
  String get codespacesPortOrg => 'グループ织内';

  @override
  String get codespacesPortPublic => '公開';

  @override
  String get codespacesPortOpen => '開く';

  @override
  String get codespacesRebuild => '重建コンテナ';

  @override
  String get codespacesRebuildDesc =>
      '重建会按現で devcontainer 重新作成コンテナ:コードと未コミットの変更保留,コンテナ内済みインストール工具と実行ステータス会紛失。';

  @override
  String get codespacesRebuildFull => '完全重建(同時クリアキャッシュ Docker イメージ,更慢)';

  @override
  String get settingsLog => 'ログ';

  @override
  String get settingsLogSubtitle => 'アプリ実行ログと AI リクエストログ';

  @override
  String get logFiles => 'ログファイル';

  @override
  String get logNoFiles => '还なしログファイル';

  @override
  String logReadFailed(String error) {
    return '読み取り得ログ失敗:$error';
  }

  @override
  String get logSearchHint => '検索ログ';

  @override
  String get logNoMatch => '現でフィルタ件件下なしログ';

  @override
  String get logLevel => 'ログレベル';

  @override
  String get logLevelDesc => '記録低にこのレベルログを被忽略。开发期建议 VERBOSE(すべて記録);NONE 閉じるログ。';

  @override
  String get logCopied => '済みコピー';

  @override
  String logMcpPrefix(String server) {
    return 'MCP ログ:$server';
  }

  @override
  String logSearchResults(int count) {
    return '一致 $count 行';
  }

  @override
  String logShowLastLines(int shown, int total) {
    return '表示最後 $shown/$total 行';
  }

  @override
  String logShowLines(int count) {
    return '表示 $count 行';
  }

  @override
  String get logCopy => 'コピー';

  @override
  String get logClearFilter => 'クリアフィルタ';

  @override
  String get logCopyMenuTitle => 'コピーログ';

  @override
  String get logCopyLine => 'コピーこの件ログ';

  @override
  String get logCopyWithStack => 'コピーこの件およびヒープスタック';

  @override
  String get logCopyMessage => 'コピーメッセージコンテンツ';

  @override
  String get logFollowLatest => 'リアルタイム滚動';

  @override
  String get logFileLocation => 'ログファイル位に Android/data/<パッケージ名>/files/logs/。';

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
      '建议使用带 codespace スコープ GitHub トークン,入力一度同時供 Git プッシュと Codespaces ログイン使使用';

  @override
  String get credentialHostOptional => 'ホスト(オプション)';

  @override
  String get credentialHostAny => '空欄 = すべてホスト';

  @override
  String get credentialHostHint => '只で必要に特定ホスト単一独配トークン時才入力,例えば gitlab.com';

  @override
  String get codespacesNeedCredentialTitle => '未設定 GitHub 認証情報';

  @override
  String get codespacesNeedCredentialDesc =>
      'Codespaces 使使用「Git 認証情報」内トークン(含むめる必要があります codespace スコープ),なし再単一独入力。';

  @override
  String get codespacesGoToCredentials => '入力してください Git 認証情報';

  @override
  String get credentialAllHosts => 'すべてホスト';

  @override
  String get credentialUsernameAuto => 'ユーザー名自動推导';

  @override
  String get chatMentionSkill => '@ スキル';

  @override
  String get chatMentionSkillEmpty => '还なし利使用可能能技能,先で設定内インポートまたは新規作成一個。';

  @override
  String get chatMentionSkillManage => 'スキル管理';

  @override
  String get chatPickFile => '# ファイル';

  @override
  String get chatPickFileParent => '上一レベル';

  @override
  String get chatPickFileEmpty => 'このディレクトリはい空';

  @override
  String get mentionHintSkill => '入力を続行可能能フィルタ技能';

  @override
  String get mentionHintFile => '入力を続行可能能フィルタファイル';

  @override
  String get fileBrowserError => '読み取り得ディレクトリ失敗';

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
    return '削除してもよろしいですか？フォルダ「$name」およびその他すべてコンテンツ?';
  }

  @override
  String get fileBrowserCreateFailed => '作成に失敗しました,可能能済み存で同名項目またはなし書き込み権限';

  @override
  String get fileBrowserRenameFailed => '名前の変更に失敗しました,可能能済み存で同名項目';

  @override
  String get fileBrowserDeleteFailed => '削除に失敗しました';

  @override
  String get fileBrowserPasteHere => '貼り支払いけにここ';

  @override
  String get fileBrowserExtract => '解凍';

  @override
  String get fileBrowserExtractFailed => '解凍失敗';

  @override
  String get fileBrowserExtractConflictTitle => '目標フォルダ済み存で';

  @override
  String fileBrowserExtractConflict(String name) {
    return '同ディレクトリ下済みあり「$name」,解凍会先覆盖它コンテンツ。';
  }

  @override
  String get fileBrowserExtractOverwrite => '上書きして解凍';

  @override
  String get fileBrowserPasteConflictTitle => '同名ファイル済み存で';

  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '目標位置済み存で同名プロジェクト「$name」,よろしいですか覆盖?';
  }

  @override
  String get fileBrowserClipboardCut => '済み切り取得り';

  @override
  String get fileBrowserClipboardCopy => '済みコピー';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonCut => '切り取得り';

  @override
  String get commonPaste => '貼り支払いけ';

  @override
  String get workspacePickWritingFolder => '執筆ディレクトリ';

  @override
  String get writingFolderNeedAccessTitle => '必要ストレージアクセス権限';

  @override
  String get writingFolderNeedAccessDesc =>
      '読み取り得手机内「AI執筆」ディレクトリ必要「すべてファイルアクセス権限」。またはスキップ,直接で下一步選択ディレクトリ。';

  @override
  String get writingFolderGrant => '認証へ';

  @override
  String writingFolderSet(String path) {
    return '執筆ディレクトリ済み設のため $path';
  }

  @override
  String get modelAuto => 'Auto Model';

  @override
  String get modelAutoDesc => '按任务自動選択最合适モデル';

  @override
  String get sessionExport => 'エクスポートセッション';

  @override
  String sessionExportDone(String path) {
    return '済みエクスポートに $path';
  }

  @override
  String get sessionExportFailed => 'エクスポート失敗';

  @override
  String get sessionBatchSelect => '一括選択';

  @override
  String sessionSelectedCount(String count) {
    return '選択済み $count 件';
  }

  @override
  String get sessionSelectAll => 'すべて選択';

  @override
  String get sessionCancelSelect => 'キャンセル';

  @override
  String get sessionDeleteSelected => '選択項目を削除';

  @override
  String get sessionDeleteConfirm => '削除このセッションおよびその他すべてメッセージ?';

  @override
  String get fileBrowserNeedPermission =>
      'なし読み取得れませんフォルダ,必要な場合がありますストレージアクセス権限';

  @override
  String get checkpointRewindTitle => '戻すにここ';

  @override
  String checkpointTargetPrompt(String snippet) {
    return '目標:$snippet';
  }

  @override
  String get checkpointRestoreCodeAndConversation => '復元コードとセッション';

  @override
  String get checkpointRestoreCodeAndConversationDesc =>
      'ロールバックワークスペースファイル,そして削除この後すべてメッセージ,提问会回入力に入力框';

  @override
  String get checkpointRestoreConversation => '復元のみセッション';

  @override
  String get checkpointRestoreConversationDesc =>
      '削除この後すべてメッセージ,ワークスペースファイル保持なし变';

  @override
  String get checkpointRestoreCode => '復元のみコード';

  @override
  String get checkpointRestoreCodeDesc => 'ロールバックワークスペースファイル,チャット記録保持なし变';

  @override
  String checkpointRewindSkipped(int count) {
    return '$count 個ファイル因存でその他変更済みスキップ';
  }

  @override
  String get chatMoreOptions => 'さらに表示オプション';

  @override
  String get chatActionEdit => '編集';

  @override
  String get chatActionDelete => '削除';

  @override
  String get chatEditMessageTitle => '編集メッセージ';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonBatchDelete => '一括削除';

  @override
  String get tabProjects => 'プロジェクト';

  @override
  String get projectListEmpty => '还なしプロジェクト';

  @override
  String get workspaceCurrent => '現で';

  @override
  String get workspaceNameHint => 'プロジェクト名前';

  @override
  String get projectNew => '新規作成プロジェクト';

  @override
  String get projectUntitled => '無題プロジェクト';

  @override
  String get projectKindCoding => 'プログラミング';

  @override
  String get projectKindCodingDesc => 'で沙盒ワークスペース内書くコード、跑コマンド、改ファイル';

  @override
  String get projectKindWriting => '執筆';

  @override
  String get projectKindWritingDesc => 'で「AI執筆」ディレクトリ内撰書くと修本文稿';

  @override
  String get projectKindReverse => 'アプリ逆向';

  @override
  String get projectKindReverseDesc => '分析 APK、パケットキャプチャインターフェース、静态逆向とデバッグ辅助';

  @override
  String projectDeleteConfirm(String name) {
    return '削除してもよろしいですか？プロジェクト「$name」?その他下すべてセッション都会一そして削除。';
  }

  @override
  String get installedAppsTitle => '選択アプリ';

  @override
  String get installedAppsSearch => '検索アプリ名またはパッケージ名';

  @override
  String get installedAppsEmpty => 'なし一致アプリ';

  @override
  String get storagePermissionGrant => '認証へ';

  @override
  String get softwarePermissionsTitle => 'ソフトウェア権限';

  @override
  String get softwarePermissionsSubtitle =>
      'クリック任一件によりシステム弹出認証,または跳にに应システム設定ページ。';

  @override
  String get systemPermissionsGroup => 'システム権限';

  @override
  String get permissionStorageTitle => 'アクセスストレージ空间';

  @override
  String get permissionBatteryTitle => 'バッテリ最適化を無視';

  @override
  String get permissionBatteryDesc => 'バックグラウンドでの実行を許可し、終を減らす';

  @override
  String get permissionAutoStartTitle => '自動起動管理';

  @override
  String get permissionAutoStartDesc => '許可能システムで後台自動拉起アプリ';

  @override
  String get permissionShizukuTitle => 'Shizuku';

  @override
  String get permissionShizukuDesc => 'クリック击前往下载インストール Shizuku';

  @override
  String get permissionAllowed => '済み許可能';

  @override
  String get permissionNotAllowed => '未許可';

  @override
  String get permissionInstalled => '済みインストール';

  @override
  String get permissionNotInstalled => '未インストール';

  @override
  String get permissionAppsTitle => 'アプリリスト';

  @override
  String get permissionAppsDesc => '読み取り得済みインストールアプリ名前、パッケージ名とバージョン';

  @override
  String get apkPathUnavailable => '拿なしにこのアプリインストール包パス,换一個アプリ再试。';

  @override
  String get apkExtractHint => 'このプロジェクト表示所选 APK 内ファイル。首回浏览必要先解凍一度。';

  @override
  String get apkExtractAction => '解凍 APK';

  @override
  String get apkExtracting => '解凍中…';

  @override
  String get apkExtractFailed => '解凍失敗,可能能なし読み取り得このインストール包権限。';

  @override
  String get terminalAgentTab => 'AI コマンド';

  @override
  String get runModeAuto => '自動モード';

  @override
  String get runModeBuild => '构建モード';

  @override
  String get runModePlan => '計画モード';

  @override
  String get runModePlanIntercept => '現で处に計画モード,禁止実行書く操作';

  @override
  String get runModeBuildAuthorize => 'AI 尝试実行書く操作,よろしいですか許可能?';

  @override
  String get runModeBuildAllow => '許可';

  @override
  String get runModeBuildDeny => '拒いいえいいえ';

  @override
  String runModeSwitchChanged(Object mode) {
    return '実行モード済み切换至 $mode';
  }

  @override
  String get commonScrollToBottom => '回にボトム';

  @override
  String get subagentTitle => 'サブエージェント';

  @override
  String get subagentSubtitle => 'モデルクラスとカスタム定義';

  @override
  String get subagentTierSubtitle =>
      'のため每個クラス绑定プロバイダとモデル。未設定クラス:サブエージェント定義書く死モデル時使用定義モデル,そうでなければ継承でセッションモデル';

  @override
  String get subagentTierSection => 'モデルクラス';

  @override
  String get subagentTierLight => '軽量';

  @override
  String get subagentTierStandard => 'バランス';

  @override
  String get subagentTierStrong => '強力';

  @override
  String get subagentTierLightDesc => '読み取り専用探索、一括位置特定、機械な名前変更';

  @override
  String get subagentTierStandardDesc => '単一ファイルの修正と標準修复';

  @override
  String get subagentTierStrongDesc => '跨模块重构、疑难排查と方案設计';

  @override
  String get subagentTierUnset => '未設定(継承でセッションモデル)';

  @override
  String get subagentTierPick => '選択モデル';

  @override
  String get subagentTierClear => 'クリア';

  @override
  String get subagentTierCleared => '済みクリア';

  @override
  String get subagentTierSaved => '保存済みみ';

  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier 档モデル';
  }

  @override
  String get subagentTierSheetHint => '選択このクラス使使用プロバイダとモデル';

  @override
  String get subagentTierSheetInherit => '継承でセッションモデル';

  @override
  String get subagentNoticeTitle => 'サブエージェント';

  @override
  String get subagentStateRunning => '実行中';

  @override
  String get subagentStateCompleted => '完';

  @override
  String get subagentStateFailed => '実行失敗';

  @override
  String get subagentStateMessage => '来メッセージ';

  @override
  String get subagentViewOutput => '表示出力';

  @override
  String get subagentOpen => '開く';

  @override
  String get subagentOutputEmpty => '一時なし出力';

  @override
  String get subagentOutputTitle => 'サブエージェント出力';

  @override
  String get promptsTitle => 'ヒント単語';

  @override
  String get promptsScenarioSection => 'シーンヒント単語';

  @override
  String get promptsSortLongPress => '長押しで順序を調整';

  @override
  String get promptsEmpty => '一時なし利使用可能能片段';

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
  String get promptsFieldNumberPlaceholder => '2桁の数値,如 35';

  @override
  String get promptsFieldTitle => '名前';

  @override
  String get promptsFieldTitlePlaceholder => '例: 自分使用のセキュリティルール';

  @override
  String get promptsFieldSummary => '概要(オプション)';

  @override
  String get promptsFieldSummaryPlaceholder =>
      'スニペットコンテンツを簡潔に説明,プロンプトには注入されません';

  @override
  String get promptsFieldContent => 'スニペットコンテンツ';

  @override
  String get promptsFieldContentPlaceholder => '書くモデル要遵守コンテンツ';

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
      'を削除現でのプロジェクトとグローバル层内すべてカスタムヒント単語,各番号回落に組み込みヒント単語。この操作は元に戻せません。';

  @override
  String get promptsResetAction => 'リセット';

  @override
  String get promptsHelp => 'ヘルプ';

  @override
  String get promptsDisableBuiltin => '組み込みプロンプトを完全に無効化';

  @override
  String get promptsDisableBuiltinHint =>
      '自分のスニペットのみを保持;すべてのルールを自分で補完する必要があります,注意してあり効化してください';

  @override
  String get promptsBatchDeleteTitle => 'プロンプトを削除';

  @override
  String promptsBatchDeleteConfirm(int count) {
    return '選択した項目を削除してもよろしいですか？ $count 件のカスタムプロンプトですか?対応する番号は回のレイヤーのソースにフォールバックします。';
  }

  @override
  String get promptsScope => 'スコープ';

  @override
  String get promptsScopeProject => '現でのプロジェクト';

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
  String get promptsDeselectAll => 'すべて選択を解除';

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
  String get novelFieldTagsHint => '可能複数選択,またはカスタム';

  @override
  String get novelCustomTagHint => 'カスタムタグ';

  @override
  String get novelFieldWordsPerChapter => '1章あたりの文字数';

  @override
  String get novelFieldWordsHint => 'オプションクラス,またはカスタム';

  @override
  String get novelCreate => '作成';

  @override
  String get novelPickExisting => '既存の小説を選択';

  @override
  String get novelOpen => '開く';

  @override
  String get novelExistingEmpty => '「AI小説」ディレクトリ内还なしその他小説';

  @override
  String get novelExistingEmptyHint => 'を小説フォルダ放進 AI小説 ディレクトリ後,再回にここ選択';

  @override
  String get novelExistingFailed => '小説リストの読み取得りに失敗しました';

  @override
  String novelExistingBrief(String title) {
    return '執筆を続行済みあり小説《$title》,まず読む「小説資料」と済みあり章,解設定と進捗後再執筆。';
  }

  @override
  String novelBriefTitle(String title) {
    return '新規小説『$title』';
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
    return '$path に小説ディレクトリを作成できません,お願いしますチェックストレージ権限後再試行。';
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
  String get agentScopeProject => '現でのプロジェクト';

  @override
  String get agentScopeGlobal => 'グローバル';

  @override
  String get agentScopeProjectHint => '現でのワークスペースにのみ適使用';

  @override
  String get agentScopeGlobalHint => 'すべてのプロジェクトで合計あり';

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
    return '削除 $name?この操作は元に戻せません。';
  }

  @override
  String get agentImport => 'インポート';

  @override
  String get agentName => '名前';

  @override
  String get agentDescription => '使用途の説明';

  @override
  String get agentDescriptionHint => 'このサブエージェントを選択するタイミング';

  @override
  String get agentPrompt => 'プロンプト本文';

  @override
  String get agentPromptHint => '追加に基线システムヒント単語後专属指令';

  @override
  String get agentProvider => 'プロバイダ';

  @override
  String get agentModel => 'モデル';

  @override
  String get agentReasoningEffort => '思考の深さ';

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
  String get agentEnable => 'あり効化';

  @override
  String get agentDisable => '無効化';

  @override
  String get agentEnabled => 'あり効';

  @override
  String get agentDisabled => '無効';

  @override
  String get agentErrorInvalidName => '無効な名前です';

  @override
  String get agentErrorEmptyPrompt => 'プロンプト本文を入力してください';

  @override
  String get agentErrorNameConflict => 'このスコープには既に同じ名前のサブエージェントが存でします';

  @override
  String get agentErrorIoFailed => 'ファイルの書き込みに失敗しました';

  @override
  String get agentCapabilityRead => 'ファイルの読み取得り';

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
  String get agentBatchEnable => 'あり効化';

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
  String get promptsNoOverrideToDelete => 'このプロンプトには削除可能能なカスタムオーバーライドはありません';

  @override
  String get codespacesSearchHint => '名前で検索、リポジトリまたはブランチで検索';

  @override
  String get codespacesFilterAll => 'すべて';

  @override
  String get codespacesFilterRunning => '実行中';

  @override
  String get codespacesFilterStopped => '停止済みみ';

  @override
  String get codespacesNoMatch => '現でのフィルタに一致する Codespace はありません';

  @override
  String get codespacesStartAndConnect => '起動して接続';

  @override
  String get codespacesConnecting => '接続中…';

  @override
  String get codespacesWaitingForStart => '待機 Codespace 变のため利使用可能能…';

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
  String get codespacesRetentionPeriod => '保持期間 (日)';

  @override
  String get codespacesDevcontainerPath => 'Dev container パス';

  @override
  String get codespacesCreatedAt => '作成日時';

  @override
  String get codespacesOwner => 'すべて者';

  @override
  String get codespacesBillableOwner => '課金すべて者';

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
  String get codespacesCurrentEnv => '現での環境';

  @override
  String get codespacesSwitchToLocal => 'ローカルコンテナに切り置換え';

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
  String get codespacesIdleTimeoutHint => '空闲後自動停止分数（オプション）';

  @override
  String get codespacesRetentionHint => '停止後の保持日数（オプション）';

  @override
  String get codespacesReadinessTitle => '接続準備完';

  @override
  String get codespacesReadinessCredOk => 'GitHub 認証情報：設定済みみ';

  @override
  String get codespacesReadinessCredMissing =>
      'GitHub 認証情報：未設定（含むめる必要があります codespace 権限トークン）';

  @override
  String get codespacesReadinessGhOk => 'gh CLI：準備完';

  @override
  String get codespacesReadinessGhMissing =>
      'gh CLI：準備未完（ターミナルで codecraft を実行し「GitHub Codespaces」シナリオをインストール）';

  @override
  String get codespacesOpenTerminal => 'ターミナルで開く';

  @override
  String get codespacesOpenGit => 'Git を開く（デプロイ/同期）';

  @override
  String get codespacesManageCredentials => '認証情報を管理';

  @override
  String get codespacesDeploySyncHint =>
      'Git のプッシュ/プル等の操作会作使用に現で実行環境；接続 Codespace 後即で远端リポジトリ実行部署/同期。';

  @override
  String gitExecutionTargetCodespace(String name) {
    return '現での操作は Codespace に適使用：$name';
  }

  @override
  String get gitExecutionTargetLocal => '現での操作はローカルコンテナに適使用';

  @override
  String get gitDeploySyncSection => 'デプロイ / 同期';

  @override
  String get gitDeploySyncHintCodespace =>
      'プッシュ、プルおよびリモート操作接続済みみの Codespace で実行。';

  @override
  String get gitDeploySyncHintLocal =>
      'プッシュ、プルおよびリモート操作ローカルコンテナで実行；Codespace に接続するとリモートでデプロイ/同期可能能。';

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
  String get captureStopped => '停止済みみ';

  @override
  String get capturePort => 'プロキシポート';

  @override
  String get captureClear => '記録をクリア';

  @override
  String get captureSearchHint => 'URL / メソッド / ステータスコードを検索';

  @override
  String get captureEmpty =>
      'パケットキャプチャ記録はありません。プロキシ起動後，対象トラフィックをプロキシ経によりで 127.0.0.1:<ポート>。';

  @override
  String get captureLimitHint =>
      '仅抓取得经代理流量。HTTPS には CA をインストールし信頼する必要があります；Android 7+ のほとんどのアプリと証明書ピンニングアプリは MITM なし可能能（デバッグ版/信頼済み証明書のシナリオで利使用可能能）。';

  @override
  String get captureCaTitle => 'CA 証明書';

  @override
  String get captureCaPath => '証明書パス';

  @override
  String get captureCaGuide =>
      '証明書をシステム/ユーザー証明書にインストールし信頼設定（ネットワーク/HTTPS キャプチャ使用）。Android 設定パスは機種により異なります，通常は「セキュリティ/暗号化と認証情報/証明書のインストール」。インストール後は HTTP プロキシを 127.0.0.1:<ポート> に設定。';

  @override
  String get captureCopyPath => 'パスをコピー';

  @override
  String get captureDetail => 'リクエスト詳細';

  @override
  String get captureRequest => 'リクエスト';

  @override
  String get captureResponse => 'レスポンス';

  @override
  String get captureNotFound => '記録が存でしません';

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
      '直接インストールなし可能（パスをコピー済み），システムセキュリティ設定から手動で証明書をインストール。';

  @override
  String get captureVpnPermissionDenied =>
      'VPN 権限が拒いいえいいえされました，パケットキャプチャをあり効化できません。VPN 権限を許可能してから再試行。';

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
  String get captureDeleteConfirm => '削除この域名すべて記録？';

  @override
  String get captureSort => '並び置換え';

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
  String get captureBodyTruncated => '（コンテンツは省略されています）';

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
  String get permissionRules => '認可能ルール';

  @override
  String get appSettings => 'アプリ設定';

  @override
  String get workspaceFiles => 'ワークスペースファイル';

  @override
  String get workspaceFilesHint =>
      'ワークスペースファイルは Git コミットでのバックアップを推奨，エクスポートバックアップは予備使用のみ';

  @override
  String get exportBackup => 'バックアップのエクスポート';

  @override
  String get exportBackupDesc => 'エクスポートするデータを選択，パスワードで暗号化可能能';

  @override
  String get importBackup => 'バックアップのインポート';

  @override
  String get importBackupDesc => 'バックアップファイルからデータを復元';

  @override
  String get localBackup => 'ローカルバックアップ';

  @override
  String get cloudBackup => 'クラウドバックアップ';

  @override
  String get aboutUpdateAvailable => '新しいバージョンが利使用可能能';

  @override
  String get aboutUpdateDesc => '新しいバージョンが利使用可能能';

  @override
  String get aboutUpdateLater => '後で';

  @override
  String get aboutUpdateGo => 'ダウンロードへ';

  @override
  String get aboutCheckingUpdate => 'GitHub で最新バージョンを確認中…';

  @override
  String get aboutAlreadyLatest => '最新バージョンです';

  @override
  String get aboutCurrentVersion => '現でのバージョン';

  @override
  String get aboutNewVersionFound => '新しいバージョンが見つかりました';

  @override
  String get aboutUpdateFailed => 'アップデートの確認に失敗しました';

  @override
  String get storageTitle => 'ストレージ';

  @override
  String get storageRefresh => '更新';

  @override
  String get storageCategoryDetail => '使用状況';

  @override
  String get storageFootnote =>
      '矢印付きのカテゴリーをタップすると詳細が展開されます。チャットを削除するとチャット記録が減少します。';

  @override
  String storageFreedBytes(Object size) {
    return '解放 $size';
  }

  @override
  String get storageAppUsage => 'アプリ使用量';

  @override
  String get storageComputing => '計算中…';

  @override
  String storageDeviceSpace(Object available, Object total) {
    return '利用可能 $available / 合計 $total';
  }

  @override
  String storageCleanSelect(Object size) {
    return '選択項目をクリーンアップ · $size';
  }

  @override
  String get storageConfirmClean => 'クリーンアップを確認';

  @override
  String storageConfirmContent(Object size) {
    return '以下の選択項目をクリーンアップします。合計約 $size。この操作は元に戻せません。';
  }

  @override
  String get storageConfirmDetail =>
      'ローカルアプリキャッシュ、ログ、グローバルディレクトリ内の選択データのみをクリーンアップします。ワークスペース間の過去出力の読み取りや画像ベースの追跡問い合わせに影響する場合があります。チャット記録、ワークスペースファイル、AI 設定、リモートサーバーデータは削除されません。';

  @override
  String get storageCancel => 'キャンセル';

  @override
  String get storageClean => 'クリーンアップ';

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
  String get containerPageTitle => 'コンテナとイメージ';

  @override
  String get containerDownloadTooltip => 'コンテナをダウンロード';

  @override
  String get containerRefreshTooltip => '更新';

  @override
  String get containerInstalledSection => 'インストール済みコンテナ';

  @override
  String get containerDefaultLabel => 'デフォルトコンテナ';

  @override
  String get containerSetDefault => 'デフォルトに設定';

  @override
  String get containerDeleteTitle => 'コンテナを削除';

  @override
  String containerDeleteContent(String name) {
    return '「$name」を削除してもよろしいですか？コンテナ内にインストールされたソフトウェアも削除されます。';
  }

  @override
  String get containerDownloadPageTitle => 'コンテナのダウンロード';

  @override
  String get containerDownloadHint =>
      'ダウンロードするイメージを選択してください。イメージは公式の aarch64 rootfs で、解凍後 PRoot により隔離されたファイルシステムが提供されます。';

  @override
  String get containerInstallingStage => 'インストール中…';

  @override
  String get containerAvailableImages => '利用可能なイメージ';

  @override
  String get containerDownloadAfter => 'ダウンロード完了後、コンテナは「コンテナとイメージ」ページに表示されます。';

  @override
  String containerInstalledCount(int count) {
    return '$count 個インストール済み';
  }

  @override
  String get containerDownloadButton => 'ダウンロード';

  @override
  String get containerNoContainers => 'ダウンロード済みのコンテナはありません';

  @override
  String get containerNoContainersDesc => '右上のダウンロードボタンをクリックしてイメージを選択してください';

  @override
  String containerDefaultSubtitle(String size) {
    return 'デフォルトコンテナ · $size';
  }

  @override
  String get containerDeleteFootnote =>
      'コンテナを削除すると、コンテナ内にインストールされたソフトウェアパッケージも同時に削除されます。ワークスペースファイルは影響を受けません。';

  @override
  String get exportSetPassword => '暗号化パスワードの設定（オプション）';

  @override
  String get exportBackupAction => 'エクスポート';

  @override
  String get importSelectBackupFile => 'バックアップファイルを選択';

  @override
  String get importLocalBackup => 'ローカルバックアップ';

  @override
  String get importLocalBackupDesc => 'アプリのドキュメントディレクトリからバックアップファイルを選択します';

  @override
  String exportSuccess(String fileName) {
    return 'バックアップをエクスポートしました: $fileName';
  }

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get importSuccess => 'バックアップを復元しました';

  @override
  String importFailed(String error) {
    return 'インポートに失敗しました: $error';
  }
}
