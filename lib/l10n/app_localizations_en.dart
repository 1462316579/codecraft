// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CodeCraft';

  @override
  String get tabSessions => 'Chats';

  @override
  String get tabSettings => 'Settings';

  @override
  String get newSession => 'New chat';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get reverseTabClasses => 'Classes';

  @override
  String get reverseTabStrings => 'Strings';

  @override
  String get reverseTabResources => 'Resources';

  @override
  String get reverseTabHex => 'Hex';

  @override
  String get reverseSearchClassHint => 'Search classes';

  @override
  String get reverseSearchStringHint => 'Search strings';

  @override
  String get reverseSearchResourceHint => 'Search name, type or 0x id';

  @override
  String get reverseNoMatch => 'No match';

  @override
  String get reverseEmptyFile => 'Empty file';

  @override
  String get reverseLoadFailed => 'Failed to open';

  @override
  String get reverseParseFailed =>
      'Failed to parse; the file may be packed or corrupted';

  @override
  String get reverseEditString => 'Edit string';

  @override
  String get reverseEqualLengthHint =>
      'Equal-length replacement only: the encoded byte length must match the original, otherwise every offset in the file shifts';

  @override
  String get reverseEditByte => 'Edit byte';

  @override
  String get reverseEditByteHint => 'Two hex digits, e.g. 0a or ff';

  @override
  String get reverseInvalidByte => 'Enter a hex byte between 00 and ff';

  @override
  String get reverseJumpToOffset => 'Jump to offset';

  @override
  String get reverseOffsetInvalid => 'Invalid offset, enter hex';

  @override
  String get reverseSuperclass => 'Superclass';

  @override
  String get reverseInterfaces => 'Interfaces';

  @override
  String get reverseAccessFlags => 'Modifiers';

  @override
  String get reverseFields => 'Fields';

  @override
  String get reverseMethods => 'Methods';

  @override
  String get reverseAbstractMethod => 'No body';

  @override
  String get reverseSmaliHint =>
      'Smali disassembly; offset is the byte offset inside the method body';

  @override
  String get reverseOpenAsHex => 'Open as hex';

  @override
  String reverseMethodCount(int count) {
    return '$count methods';
  }

  @override
  String reverseFieldCount(int count) {
    return '$count fields';
  }

  @override
  String reverseHexByteCount(int count) {
    return '$count bytes';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get retry => 'Retry';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get search => 'Search';

  @override
  String get searchSessions => 'Search chats';

  @override
  String get noSessions => 'No chats yet';

  @override
  String get noMessages => 'Start a new conversation';

  @override
  String get chatInputPlaceholder => 'Type a message to chat with AI…';

  @override
  String get reasoningTitle => 'Thoughts';

  @override
  String get untitled => 'Untitled';

  @override
  String get pinned => 'Pinned';

  @override
  String get settings => 'Settings';

  @override
  String get providers => 'AI Providers';

  @override
  String get providersSubtitle => 'Models, API and keys';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get license => 'License';

  @override
  String get licenseBody =>
      'This project is a Flutter port of jieapi/Codecraft, licensed under GPL-3.0.';

  @override
  String get addProvider => 'Add provider';

  @override
  String get providerName => 'Name';

  @override
  String get providerType => 'Protocol';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get defaultModel => 'Default model';

  @override
  String get modelList => 'Models';

  @override
  String get model => 'Model';

  @override
  String get mode => 'Mode';

  @override
  String get reasoningEffort => 'Reasoning effort';

  @override
  String get reasoningEffortNone => 'None';

  @override
  String get reasoningEffortMinimal => 'Minimal';

  @override
  String get reasoningEffortLow => 'Low';

  @override
  String get reasoningEffortMedium => 'Medium';

  @override
  String get reasoningEffortHigh => 'High';

  @override
  String get reasoningEffortXHigh => 'Extra high';

  @override
  String get reasoningEffortMax => 'Max';

  @override
  String get deleteProviderConfirm => 'Delete this provider?';

  @override
  String get deleteSessionConfirm => 'Delete this chat?';

  @override
  String get emptyProviders => 'No providers yet, tap + to add';

  @override
  String get emptyModels => 'No models yet';

  @override
  String get modelInputHint => 'Type a model ID and press Enter';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get retrying => 'Retrying';

  @override
  String get emptyMessage => 'Message is empty';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String providerModelsCountTag(int count) {
    return '$count models';
  }

  @override
  String get inputTokens => 'Input';

  @override
  String get outputTokens => 'Output';

  @override
  String get emptyChatHint => 'Pick a conversation to start';

  @override
  String get errorNoProvider =>
      'No usable provider configured. Add one in Settings first.';

  @override
  String get errorNoModel => 'Pick a model for this provider';

  @override
  String get errorEmptyResponse => 'The model returned empty content';

  @override
  String get thinking => 'Thinking…';

  @override
  String get modelListTitle => 'Pick a model';

  @override
  String get providerListTitle => 'Pick a provider';

  @override
  String get customProvider => 'Custom';

  @override
  String get addFromPreset => 'Add from preset';

  @override
  String get useFullUrlHint => 'baseUrl is a full endpoint URL';

  @override
  String get aboutBody =>
      'Codecraft Flutter is a Flutter port of jieapi/Codecraft (Phase 1: core chat loop).';

  @override
  String get chatPlaceholder => 'How can I help you?';

  @override
  String get chatInputHint =>
      'Describe what you need and I\'ll write, modify or explain code';

  @override
  String get openSidebar => 'Open sidebar';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get sessionGroupPinned => 'Pinned';

  @override
  String get sessionGroupToday => 'Today';

  @override
  String get sessionGroupYesterday => 'Yesterday';

  @override
  String get sessionGroupLast7Days => 'Last 7 days';

  @override
  String get sessionGroupLast30Days => 'Last 30 days';

  @override
  String get sessionGroupMonthFormat => 'MMM yyyy';

  @override
  String chatThinkingRunningTime(String seconds) {
    return 'Thinking (${seconds}s)';
  }

  @override
  String chatThinkingDoneTime(String seconds) {
    return 'Thought for ${seconds}s';
  }

  @override
  String get chatThinkingDone => 'Thought';

  @override
  String get chatQueueHint => 'AI is working — tap the square to stop';

  @override
  String get chatStatusGenerating => 'Generating';

  @override
  String get chatStatusThinking => 'Thinking';

  @override
  String get chatStatusCallingTool => 'Calling tool';

  @override
  String get chatStatusRunningCommand => 'Running command';

  @override
  String get chatStatusEditingFile => 'Editing file';

  @override
  String get chatStatusReadingFile => 'Reading file';

  @override
  String get chatStatusViewingImage => 'Viewing image';

  @override
  String get chatStatusSearchingWeb => 'Searching the web';

  @override
  String get chatStatusBrowsingWeb => 'Controlling browser';

  @override
  String get chatStatusAskingUser => 'Asking user';

  @override
  String get chatStatusGeneratingImage => 'Generating image';

  @override
  String get chatStatusUpdatingTodo => 'Updating to-dos';

  @override
  String get chatStatusStartingSubagent => 'Starting sub-agent';

  @override
  String get chatCompressingContext => 'Compacting context…';

  @override
  String get chatContextCompressed => 'Context compacted';

  @override
  String get chatCompactionSummary => 'Handoff summary';

  @override
  String get chatStatusReadingMemory => 'Reading memory';

  @override
  String get chatToolRunning => 'Tool running';

  @override
  String get chatToolSucceeded => 'Tool succeeded';

  @override
  String get chatToolFailed => 'Tool failed';

  @override
  String get chatEffortNone => 'Off';

  @override
  String get chatEffortMinimal => 'Minimal';

  @override
  String get chatEffortLow => 'Low';

  @override
  String get chatEffortMedium => 'Medium';

  @override
  String get chatEffortHigh => 'High';

  @override
  String get chatEffortXHigh => 'Very high';

  @override
  String get chatEffortMax => 'Max';

  @override
  String get searchModels => 'Search models';

  @override
  String get chatAddAttachment => 'Add attachment';

  @override
  String get chatUploadFile => 'Upload file';

  @override
  String get chatUploadImage => 'Upload image';

  @override
  String get chatTakePhoto => 'Take photo';

  @override
  String get attachmentPrefix => 'Attachments:';

  @override
  String attachmentMax(int count) {
    return 'Up to $count attachments at a time';
  }

  @override
  String attachmentUploaded(int count) {
    return 'Uploaded $count attachment(s)';
  }

  @override
  String attachmentUploadedPartial(int count) {
    return 'Uploaded $count attachment(s); some were skipped';
  }

  @override
  String attachmentUploading(int count) {
    return 'Uploading $count file(s)…';
  }

  @override
  String attachmentImageTooLarge(String size) {
    return 'Image exceeds $size, please compress it and retry';
  }

  @override
  String get attachmentUnsupportedImageType =>
      'Unrecognized image type; only jpg/png/gif/webp are supported';

  @override
  String get attachmentReadFileFailed => 'Cannot read the selected file';

  @override
  String get attachmentUploadFailed => 'Upload failed';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get imagePreview => 'Image preview';

  @override
  String get imageLoadFailed =>
      'Failed to load the image; the file may have been moved or deleted';

  @override
  String get close => 'Close';

  @override
  String get fileFallback => 'File';

  @override
  String get skillsTitle => 'Skills';

  @override
  String get skillsSubtitle => 'Browse, import and manage skills';

  @override
  String get skillsNew => 'New skill';

  @override
  String get skillsImport => 'Import Markdown';

  @override
  String get skillsScopeTitle => 'Choose scope';

  @override
  String get skillsScopeGlobal => 'Global skills';

  @override
  String get skillsScopeProject => 'Project skills';

  @override
  String get skillsScopeGlobalHint =>
      '~/.codecraft/skills, shared across projects';

  @override
  String get skillsScopeProjectHint =>
      '~/workspace/.codecraft/skills, tied to the current workspace';

  @override
  String skillsProjectGroup(String name) {
    return 'Current project ($name)';
  }

  @override
  String get skillsNoProjectSkills => 'No skills in this project yet';

  @override
  String get skillsNoGlobalSkills => 'No global skills yet';

  @override
  String get skillsEmpty => 'No skills yet';

  @override
  String get skillsEmptyHint =>
      'Skills are focused instructions for the AI; import a SKILL.md or create one.';

  @override
  String get skillsName => 'Name';

  @override
  String get skillsDescription => 'Description';

  @override
  String get skillsDescriptionHint =>
      'When to use this skill (goes into the system prompt)';

  @override
  String get skillsInstructions => 'Instructions';

  @override
  String get skillsInstructionsHint =>
      'Steps the skill should follow, written in Markdown';

  @override
  String skillsImported(String name) {
    return 'Imported skill \"$name\"';
  }

  @override
  String get skillsDeleteTitle => 'Delete skill';

  @override
  String skillsDeleteConfirm(String name) {
    return 'Delete skill \"$name\" including its directory and scripts?';
  }

  @override
  String get skillsErrorInvalidName =>
      'Invalid skill name: cannot be empty, too long, or contain / \\ : * ? \" < > |';

  @override
  String get skillsErrorEmptyInstructions => 'Instructions cannot be empty';

  @override
  String skillsErrorNameConflict(String name) {
    return 'A skill named \"$name\" already exists in this scope';
  }

  @override
  String get skillsErrorNoSkill => 'No recognizable skill found in the file';

  @override
  String get skillsErrorIoFailed => 'Failed to read or write the skill file';

  @override
  String get providerAdd => 'Add provider';

  @override
  String get providerEdit => 'Edit provider';

  @override
  String get providerEditModel => 'Edit Model';

  @override
  String get providerConfig => 'Config';

  @override
  String get providerSectionBasic => 'Basics';

  @override
  String get providerSectionType => 'Upstream format';

  @override
  String get providerSectionOptions => 'Options';

  @override
  String get providerFullUrl => 'Full URL';

  @override
  String get providerFullUrlDesc =>
      'Base URL is the full request address; no default path is appended';

  @override
  String get providerHeadersTitle => 'Custom headers';

  @override
  String get providerHeadersDesc =>
      'Fully override default headers of the same name for this provider';

  @override
  String get providerHeadersAdd => 'Add header';

  @override
  String get providerHeadersManage => 'Manage';

  @override
  String providerHeadersCount(int count) {
    return '$count header(s) configured';
  }

  @override
  String get providerShowApiKey => 'Show key';

  @override
  String get providerHideApiKey => 'Hide key';

  @override
  String get providerAddModel => 'Add model';

  @override
  String get providerNoModels => 'No models';

  @override
  String get providerNoModelsHint =>
      'Tap the button in the top-right to add a model';

  @override
  String get providerModelCurrent => 'Current';

  @override
  String providerModelsCount(String count) {
    return 'Models ($count)';
  }

  @override
  String get providerModelsSelect => 'Select';

  @override
  String providerModelsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get providerModelsSelectAll => 'Select all';

  @override
  String get providerModelsDeselectAll => 'Deselect all';

  @override
  String get providerModelsBatchTest => 'Test';

  @override
  String get providerModelsBatchDelete => 'Delete';

  @override
  String get providerModelsBatchDeleteTitle => 'Delete models';

  @override
  String providerModelsBatchDeleteConfirm(int count) {
    return 'Delete $count selected models?';
  }

  @override
  String get providerFetchModels => 'Fetch models';

  @override
  String get providerAddAllModels => 'Add all';

  @override
  String get providerAddAllModelsTitle => 'Add all models';

  @override
  String providerAddAllModelsConfirm(int count) {
    return 'Add all $count fetched models to this provider?';
  }

  @override
  String get providerFilterModelsHint => 'Filter models by name';

  @override
  String get providerNoMatchingModels => 'No matching models';

  @override
  String providerModelAdded(String name) {
    return 'Added model \"$name\"';
  }

  @override
  String get providerModelName => 'Model Name';

  @override
  String get providerModelAlreadyAdded => 'This model has already been added';

  @override
  String providerFetchHttpError(int code, int latency) {
    return 'HTTP $code · ${latency}ms';
  }

  @override
  String get providerFetchMissingFields => 'Response has no model list field';

  @override
  String get providerFetchFailed => 'Failed to fetch models';

  @override
  String get providerApiKeyRequired => 'Fill in the API key first';

  @override
  String get providerTestModel => 'Test';

  @override
  String get providerModelContext => 'Context window (tokens)';

  @override
  String get providerModelContextInput => 'Input limit (tokens)';

  @override
  String get providerModelContextOutput => 'Output limit (tokens)';

  @override
  String get providerModelWindowInvalid =>
      'Enter a valid positive integer, or leave blank to use the automatically detected value';

  @override
  String get providerModelSectionPrice => 'Price';

  @override
  String get providerModelPriceInput => 'Input price (USD/1M tokens)';

  @override
  String get providerModelPriceOutput => 'Output price (USD/1M tokens)';

  @override
  String get providerModelPriceCacheRead => 'Cache read price (USD/1M tokens)';

  @override
  String get providerModelPriceCacheWrite =>
      'Cache write price (USD/1M tokens)';

  @override
  String get providerModelCapabilities => 'Capabilities';

  @override
  String get providerModelCapVision => 'Image input';

  @override
  String get providerModelCapImageOutput => 'Image output';

  @override
  String get providerModelCapTools => 'Tool calls';

  @override
  String get providerModelCapReasoning => 'Reasoning';

  @override
  String get providerModelSectionReasoning => 'Reasoning levels';

  @override
  String get providerModelReasoningHint =>
      'Tick only the levels this model really accepts; leave all unticked to use the built-in capability table';

  @override
  String get providerModelReasoningCanDisable => 'Thinking can be turned off';

  @override
  String get providerTestRequestUrl => 'Request URL';

  @override
  String get providerTestRequestHeaders => 'Request headers';

  @override
  String get providerTestRequestBody => 'Request body';

  @override
  String get providerTestResponse => 'Response';

  @override
  String get providerTestError => 'Error detail';

  @override
  String get providerMultiKeyTitle => 'Multi-key mode';

  @override
  String get providerMultiKeySubtitle =>
      'Keep several keys for one provider; switch and resend automatically when a key fails';

  @override
  String get providerMultiKeyManage => 'Multi-key management';

  @override
  String providerMultiKeySummary(int count, String strategy) {
    return '$count · $strategy';
  }

  @override
  String get providerMultiKeyList => 'Key list';

  @override
  String providerMultiKeyItem(int index) {
    return 'Key #$index';
  }

  @override
  String get providerMultiKeyEmpty => 'Tap to add the first key';

  @override
  String get providerMultiKeyAdd => 'Add key';

  @override
  String get providerMultiKeyWeight => 'Scheduling weight';

  @override
  String get providerMultiKeyWeightHint =>
      'Default 1 · ≤ 0 skips it · max 1,000,000';

  @override
  String get providerMultiKeyStrategy => 'Pick strategy';

  @override
  String get providerMultiKeyStrategySequential => 'Sequential';

  @override
  String get providerMultiKeyStrategySequentialDesc =>
      'Always use the leading key; move on only after repeated failures';

  @override
  String get providerMultiKeyStrategyRoundRobin => 'Round robin';

  @override
  String get providerMultiKeyStrategyRoundRobinDesc =>
      'New sessions start on the next key to spread quota; keep the same key within a session to stay cache-friendly';

  @override
  String get providerMultiKeyStatusCodes => 'Auto-switch status codes';

  @override
  String get providerMultiKeyStatusCodesHint =>
      'Comma separated; leave empty for default 401,402,403,429';

  @override
  String get providerMultiKeyCooldown => 'Cooldown';

  @override
  String get providerMultiKeyCooldownDesc =>
      'How long a switched-away key stays out of the pool';

  @override
  String get workspaceOpen => 'Workspace';

  @override
  String get workspaceLocal => 'Local workspace';

  @override
  String get workspaceLocalSubtitle => 'App data directory';

  @override
  String get allow => 'Allow';

  @override
  String get deny => 'Deny';

  @override
  String get tabFiles => 'Files';

  @override
  String get newFile => 'New file';

  @override
  String get newFolder => 'New folder';

  @override
  String get create => 'Create';

  @override
  String get deleteFileConfirm => 'Delete this file?';

  @override
  String get deleteFolderConfirm => 'Delete this folder and its contents?';

  @override
  String get refresh => 'Refresh';

  @override
  String get workspaceNew => 'New';

  @override
  String get workspaceEmptyHint =>
      'No workspaces yet, tap New in the top-right';

  @override
  String get workspaceNameExists => 'A workspace with this name already exists';

  @override
  String get workspaceDelete => 'Delete workspace';

  @override
  String workspaceDeleteConfirm(String name) {
    return 'Delete workspace \"$name\" and all its files?';
  }

  @override
  String get todoDashboardTitle => 'Tasks';

  @override
  String todoDashboardProgress(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String get todoDashboardAllDone => 'All done';

  @override
  String get todoInProgress => 'In progress';

  @override
  String get todoCompleted => 'Completed';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitRefresh => 'Refresh';

  @override
  String get gitTabStatus => 'Status';

  @override
  String get browserTitle => 'Browser';

  @override
  String get browserAddressHint => 'Enter URL or search';

  @override
  String get browserBack => 'Back';

  @override
  String get browserForward => 'Forward';

  @override
  String get browserReload => 'Reload';

  @override
  String get browserNotReady =>
      'Browser not ready. Enter a URL in the address bar to start browsing.';

  @override
  String get browserNewTab => 'New tab';

  @override
  String get browserCloseTab => 'Close tab';

  @override
  String get browserTabDefaultTitle => 'New Tab';

  @override
  String browserTabsCount(int count) {
    return 'Tabs ($count)';
  }

  @override
  String get browserEmptyHint =>
      'Enter a URL in the address bar above to start browsing';

  @override
  String get browserTabsManage => 'Manage Tabs';

  @override
  String get browserEmptyClickHint =>
      'Tap above to enter a URL and start browsing';

  @override
  String get browserNightModeOn => 'Turn off night mode';

  @override
  String get browserNightModeOff => 'Turn on night mode';

  @override
  String get browserDevtools => 'Developer tools';

  @override
  String get browserDialogAlertTitle => 'Page Alert';

  @override
  String get browserDialogConfirmTitle => 'Page Confirmation';

  @override
  String get browserDialogPromptTitle => 'Page Input';

  @override
  String get browserMenu => 'More options';

  @override
  String get browserMenuTitle => 'Browser Options';

  @override
  String get browserMenuGeneralSection => 'Display &amp; Tools';

  @override
  String get browserNightModeTitle => 'Night mode';

  @override
  String get browserNightModeDesc =>
      'Dim page brightness and enable dark mode preference';

  @override
  String get browserDevtoolsTitle => 'Developer tools';

  @override
  String get browserDevtoolsDesc => 'Enable mobile Eruda debug console';

  @override
  String get browserUaSection => 'User-Agent';

  @override
  String get browserUaDesc => 'Emulate different device environments';

  @override
  String get browserUaDefault => 'System default';

  @override
  String get browserUaDefaultDesc => 'Native WebView User-Agent';

  @override
  String get browserUaAndroidPhone => 'Android Phone';

  @override
  String get browserUaAndroidPhoneDesc => 'Chrome Mobile (Android)';

  @override
  String get browserUaAndroidTablet => 'Android Tablet';

  @override
  String get browserUaAndroidTabletDesc => 'Chrome Tablet (Android)';

  @override
  String get browserUaDesktopPc => 'Desktop PC';

  @override
  String get browserUaDesktopPcDesc => 'Chrome Desktop (Windows PC)';

  @override
  String get browserUaIphone => 'iPhone';

  @override
  String get browserUaIphoneDesc => 'Mobile Safari (iOS)';

  @override
  String get browserUaIpad => 'iPad';

  @override
  String get browserUaIpadDesc => 'Tablet Safari (iPadOS)';

  @override
  String get browserUaCustom => 'Custom';

  @override
  String get browserUaCustomDesc => 'Specify custom User-Agent string';

  @override
  String get browserUaCustomDialogTitle => 'Custom User-Agent';

  @override
  String get browserUaCustomInputHint => 'Enter full User-Agent string';

  @override
  String get browserUaAppliedToast => 'User-Agent updated, page reloaded';

  @override
  String get gitTabBranches => 'Branches';

  @override
  String get gitTabCommits => 'Commits';

  @override
  String get gitStatusClean => 'Working tree clean, no changes';

  @override
  String gitConflictedCount(int count) {
    return 'Conflicts ($count)';
  }

  @override
  String gitStagedCount(int count) {
    return 'Staged ($count)';
  }

  @override
  String gitModifiedCount(int count) {
    return 'Modified ($count)';
  }

  @override
  String gitUntrackedCount(int count) {
    return 'Untracked ($count)';
  }

  @override
  String get gitConflictedLabel => 'Conflicts';

  @override
  String get gitStagedLabel => 'Staged';

  @override
  String get gitModifiedLabel => 'Modified';

  @override
  String get gitUntrackedLabel => 'Untracked';

  @override
  String get gitStage => 'Stage';

  @override
  String get gitUnstage => 'Unstage';

  @override
  String get gitStageAll => 'Stage All';

  @override
  String get gitUnstageAll => 'Unstage all';

  @override
  String get gitUnstageAllConfirm =>
      'All files will be unstaged, but their contents will not be deleted. Continue?';

  @override
  String get gitActionRevertAll => 'Revert all';

  @override
  String gitRevertAllConfirm(int count) {
    return 'Discard all unstaged changes ($count files) and restore them to the last staged or committed content? Staged content is unaffected, but discarded changes cannot be recovered.';
  }

  @override
  String get gitActionRestoreFile => 'Restore file';

  @override
  String gitRevertConfirmWorktree(String name) {
    return 'Restore $name to its last staged or committed content? Unstaged changes will be lost and cannot be recovered.';
  }

  @override
  String gitRevertConfirmHead(String name) {
    return 'Restore $name to its last committed content? Both staged and unstaged changes to this file will be lost and cannot be recovered.';
  }

  @override
  String gitRestoreFileConfirm(String name) {
    return 'Restore the deleted $name? The file will be brought back from the last commit.';
  }

  @override
  String get gitActionDeleteFile => 'Delete file';

  @override
  String get gitActionDeleteDir => 'Delete folder';

  @override
  String get gitMergePendingTitle => 'Merge Awaiting Commit';

  @override
  String get gitMergePendingHint =>
      'There are no unresolved conflicts. Review and stage the changes you want to keep, then commit to complete the merge.';

  @override
  String get gitActionAbortMerge => 'Abort Merge';

  @override
  String get gitAbortMergeConfirm =>
      'Abort the current merge? Unresolved changes will be discarded and the working tree will be restored.';

  @override
  String get gitCommitChanges => 'Commit Changes';

  @override
  String get gitCommitNeedsIdentity =>
      'No commit identity configured. Set your name and email in “Credentials & Identity”.';

  @override
  String get gitCommitDialogTitle => 'Commit Changes';

  @override
  String get gitCommitMessage => 'Commit message';

  @override
  String get gitCommitAmend => 'Amend last commit (--amend)';

  @override
  String get gitCommitAiGenerate => 'AI Generate';

  @override
  String get gitCommitGenerating => 'Generating…';

  @override
  String get gitActionCommit => 'Commit';

  @override
  String get gitTabStash => 'Stash';

  @override
  String get gitStashTitle => 'Stashes';

  @override
  String get gitActionStash => 'Stash Changes';

  @override
  String get gitStashMessageHint => 'Stash message (optional)';

  @override
  String get gitStashIncludeUntracked => 'Include untracked files (-u)';

  @override
  String get gitStashEmpty => 'No stashes found';

  @override
  String get gitStashPop => 'Pop';

  @override
  String get gitStashApply => 'Apply';

  @override
  String get gitStashDrop => 'Drop';

  @override
  String gitStashDropConfirm(String index) {
    return 'Drop stash $index? This action cannot be undone.';
  }

  @override
  String get gitStashClear => 'Clear All';

  @override
  String get gitStashClearConfirm =>
      'Clear all stashes? This action cannot be undone.';

  @override
  String gitStashCount(int count) {
    return 'Stashes ($count)';
  }

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPush => 'Push';

  @override
  String get gitPullDirtyConfirm =>
      'The working tree has uncommitted changes. Pulling may cause conflicts. Commit or stage them first if possible. Continue pulling?';

  @override
  String get gitPullContinue => 'Continue Pull';

  @override
  String get gitNoUpstream => 'No upstream set';

  @override
  String gitTrackingBranch(String name) {
    return 'Tracking $name';
  }

  @override
  String gitAheadCount(int count) {
    return '$count to push';
  }

  @override
  String gitBehindCount(int count) {
    return '$count to pull';
  }

  @override
  String get gitBranchSynced => 'Up to date';

  @override
  String get gitDetachedHeadLabel => 'detached HEAD: not on any branch';

  @override
  String get gitNoBranch => '(no branch)';

  @override
  String get gitLoadingBranches => 'Loading branch list…';

  @override
  String get gitNoCheckedOutBranch => 'No branch checked out';

  @override
  String get gitClean => 'Working tree clean';

  @override
  String get gitHasChanges => 'Working tree has changes';

  @override
  String get gitNotARepo => 'This workspace is not a Git repository yet';

  @override
  String get gitCloningHint => 'Cloning repository, please wait…';

  @override
  String get gitInitDescPrimary =>
      'Initialize a new repository to start versioning';

  @override
  String get gitInitDescSecondary =>
      'Or pick an existing repository from a subdirectory';

  @override
  String get gitInitRepo => 'Initialize repository';

  @override
  String get gitCloneRepo => 'Clone remote repository';

  @override
  String get gitCloneDialogTitle => 'Clone Git repository';

  @override
  String get gitCloneDesc =>
      'Clone into the workspace root (must be empty). For private repositories, tap the key icon to sign in with GitHub or paste an access token first.';

  @override
  String get gitCloneUrlLabel => 'Repository URL';

  @override
  String get gitCloning => 'Cloning repository, please wait…';

  @override
  String get gitSwitchRepo => 'Switch repository';

  @override
  String get gitPickExistingRepo => 'Pick existing repository';

  @override
  String get gitRepoSelectorTitle => 'Select repository';

  @override
  String get gitRepoNotRepo => 'Not a repository';

  @override
  String get gitPickRepoEmpty => 'No directories available in this workspace';

  @override
  String get gitNoBranches => 'No branches yet';

  @override
  String get gitNewBranch => 'New branch';

  @override
  String get gitBranchName => 'Branch name';

  @override
  String get gitBaseBranch => 'Base branch';

  @override
  String get gitCreateAndSwitch => 'Create and switch';

  @override
  String get gitDeleteBranch => 'Delete branch';

  @override
  String gitDeleteLocalBranchConfirm(String name) {
    return 'Delete local branch $name?';
  }

  @override
  String get gitDeleteRemoteBranch => 'Delete remote branch';

  @override
  String gitDeleteRemoteBranchConfirm(String name) {
    return 'Delete remote branch $name? This cannot be undone.';
  }

  @override
  String get gitRenameBranch => 'Rename branch';

  @override
  String gitRenameTo(String name) {
    return 'Rename $name to:';
  }

  @override
  String get gitNewBranchName => 'New branch name';

  @override
  String get gitTags => 'Tags';

  @override
  String get gitTagName => 'Tag name';

  @override
  String get gitDeleteTag => 'Delete tag';

  @override
  String gitDeleteTagConfirm(String name) {
    return 'Delete local tag $name?';
  }

  @override
  String gitCreateTagDesc(String hash) {
    return 'Create a lightweight tag at HEAD ($hash)';
  }

  @override
  String get gitCheckedOut => 'Checked out';

  @override
  String get gitCurrentBranch => 'Current branch';

  @override
  String get gitRemote => 'Remote';

  @override
  String get commonLocal => 'Local';

  @override
  String get gitNew => 'New';

  @override
  String get gitNoCommits => 'No commits yet';

  @override
  String gitCommitCount(int count) {
    return 'Commits ($count)';
  }

  @override
  String get gitSearchCommitsHint => 'Search commit message or author…';

  @override
  String get gitLoadMoreCommits => 'Pull up to load earlier commits';

  @override
  String get gitNoMoreCommits => 'No more commits';

  @override
  String get gitLatestCommit => 'Latest commit';

  @override
  String gitFilesChanged(int count) {
    return '$count file(s) changed';
  }

  @override
  String get gitNoFilesChanged => 'No file changes in this commit';

  @override
  String get gitMergeCommit => 'Merge commit';

  @override
  String get gitLoadingFiles => 'Loading changed files...';

  @override
  String get gitCopyShortHash => 'Copy short hash';

  @override
  String get gitCopyFullHash => 'Copy full hash';

  @override
  String get gitActionCreateBranch => 'Create branch';

  @override
  String get gitActionCreateTag => 'Create tag';

  @override
  String get gitCreateBranchFromCommit => 'Create Branch from Commit';

  @override
  String get gitCreateTagAtCommit => 'Create Tag at Commit';

  @override
  String get gitResetToCommit => 'Reset to this Commit';

  @override
  String get gitResetSoft => 'Soft (Keep working tree and staged)';

  @override
  String get gitResetMixed => 'Mixed (Keep working tree, unstage)';

  @override
  String gitResetConfirm(String hash) {
    return 'Reset current branch to commit $hash?';
  }

  @override
  String get gitDiffBinary => 'Binary file; diff not shown';

  @override
  String get gitDiffTooLarge => 'File too large; diff not computed';

  @override
  String get gitDiffEmpty => 'Nothing to show';

  @override
  String get gitCopyPath => 'Copy path';

  @override
  String get gitViewDiff => 'View diff';

  @override
  String get gitRevert => 'Revert changes';

  @override
  String gitDeleteUntrackedConfirm(Object name) {
    return 'Delete $name? It has never been committed, so Git cannot recover it after deletion.';
  }

  @override
  String get gitAddToGitignore => 'Add to .gitignore';

  @override
  String gitIgnoreFile(String name) {
    return 'Ignore this file ($name)';
  }

  @override
  String gitIgnoreDir(String name) {
    return 'Ignore directory ($name/)';
  }

  @override
  String gitIgnoreExtension(String ext) {
    return 'Ignore same extension (*.$ext)';
  }

  @override
  String get gitPathCopied => 'Path copied';

  @override
  String gitActionFailed(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String gitActionDone(String action) {
    return '$action successful';
  }

  @override
  String gitCheckoutSuccess(String name) {
    return 'Switched to $name';
  }

  @override
  String get gitNoRemotePull => 'No remote configured; cannot pull';

  @override
  String get gitNoRemotePush => 'No remote configured; cannot push';

  @override
  String get gitPushMasterConfirmTitle => 'Branch naming';

  @override
  String get gitPushMasterConfirmDesc =>
      'The local branch is master; GitHub and GitLab recommend main. Rename it to main before pushing?';

  @override
  String get gitPushRenameToMain => 'Rename to main and push';

  @override
  String get gitPushKeepMaster => 'Push as master';

  @override
  String get gitTesting => 'Test';

  @override
  String get credentialToken => 'Access token (PAT)';

  @override
  String get gitUserName => 'user.name';

  @override
  String get gitUserEmail => 'user.email';

  @override
  String get gitRepoUrl => 'Repository URL';

  @override
  String get gitSelectBranch => 'Select base branch';

  @override
  String get credentialTokenLogin => 'Token login';

  @override
  String get credentialTokenLoginDesc =>
      'Just paste a personal access token; the remote host is matched automatically on push';

  @override
  String get credentialTokenSaved => 'Token saved';

  @override
  String get commonShow => 'Show';

  @override
  String get commonHide => 'Hide';

  @override
  String get credentialAdd => 'Add credential';

  @override
  String get settingsSubtitle => 'Manage AI, appearance, sync and app data';

  @override
  String get accountAndData => 'Account & data';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSubtitle => 'Appearance, background and display';

  @override
  String get aboutSubtitle => 'Version, updates and feedback';

  @override
  String get aboutAutoCheck => 'Auto-check updates';

  @override
  String get aboutAutoCheckDesc => 'Check for new versions on app launch';

  @override
  String get aboutUpdateChannel => 'Update channel';

  @override
  String get aboutStableChannel => 'Stable';

  @override
  String get aboutDownloadMirror => 'Download mirror';

  @override
  String get aboutMirrorUrl => 'https://cdn.gh-proxy.co...';

  @override
  String get githubRepo => 'GitHub repository';

  @override
  String get aboutUserAgreement => 'User agreement';

  @override
  String get aboutPrivacyPolicy => 'Privacy policy';

  @override
  String get mcpTitle => 'MCP servers';

  @override
  String get mcpSubtitle =>
      'Model Context Protocol services for external tools';

  @override
  String get mcpAdd => 'Add MCP';

  @override
  String get mcpEdit => 'Edit MCP';

  @override
  String get mcpEmpty => 'No MCP servers configured yet';

  @override
  String get mcpEmptyHint =>
      'Tap + in the top right to add a remote HTTP or local stdio server';

  @override
  String get mcpSearchPlaceholder => 'Search MCP servers…';

  @override
  String get mcpSearchEmpty => 'No matching MCP server';

  @override
  String get mcpScopeLabel => 'Scope';

  @override
  String get mcpScopeGlobal => 'Global';

  @override
  String get mcpScopeProject => 'Project';

  @override
  String get mcpTypeStdio => 'stdio';

  @override
  String get mcpStatusDisabled => 'Disabled';

  @override
  String get mcpStatusNotConnected => 'Not connected';

  @override
  String get mcpStatusConnected => 'Connected';

  @override
  String get mcpStatusConnecting => 'Connecting…';

  @override
  String get mcpStatusFailed => 'Connection failed';

  @override
  String get mcpStatusNeedsAuth => 'Sign-in required';

  @override
  String mcpToolsCount(int count) {
    return '$count tools';
  }

  @override
  String get mcpDetails => 'Details';

  @override
  String get mcpBasicSettings => 'Basics';

  @override
  String get mcpEnabledLabel => 'Enabled';

  @override
  String get mcpNameLabel => 'Name';

  @override
  String get mcpNameHint => 'e.g. fetch, github, gitlab';

  @override
  String get mcpNameInvalid =>
      'Name may only contain letters, digits, underscores and hyphens';

  @override
  String get mcpTransportType => 'Transport';

  @override
  String get mcpRemoteHttp => 'Remote HTTP';

  @override
  String get mcpLocalStdio => 'Local stdio';

  @override
  String get mcpServerUrl => 'Server URL';

  @override
  String get mcpServerUrlHint => 'e.g. https://api.example.com/mcp';

  @override
  String get mcpCustomHeaders => 'Custom headers';

  @override
  String get mcpNoCustomHeaders => 'No custom header configured';

  @override
  String get mcpHeaderName => 'Header name';

  @override
  String get mcpHeaderNameHint => 'e.g. Authorization';

  @override
  String get mcpHeaderValue => 'Header value';

  @override
  String get mcpHeaderValueHint => 'e.g. Bearer xxxxxx';

  @override
  String get mcpAddHeader => 'Add header';

  @override
  String get mcpCommand => 'Command';

  @override
  String get mcpCommandHint => 'e.g. npx';

  @override
  String get mcpArgs => 'Arguments';

  @override
  String get mcpNoArgs => 'No extra arguments';

  @override
  String get mcpArgValue => 'Argument value';

  @override
  String get mcpArgHint => 'e.g. -y or @modelcontextprotocol/server-xxx';

  @override
  String get mcpAddArg => 'Add argument';

  @override
  String mcpToolsSummary(int enabled, int total) {
    return '$enabled of $total tools enabled';
  }

  @override
  String get mcpToolsSearch => 'Search tools by name or description…';

  @override
  String get mcpToolsSearchEmpty => 'No matching tool';

  @override
  String get mcpToolsEnableAll => 'Enable all';

  @override
  String get mcpToolsDisableAll => 'Disable all';

  @override
  String get mcpSaveFirstHint =>
      'Save and connect the server first to see its tools';

  @override
  String get mcpNoToolsHint =>
      'No tools detected — tap refresh in the top right to retry';

  @override
  String get mcpNoDescription => 'No description';

  @override
  String get mcpAddSheetTitle => 'Add MCP server';

  @override
  String get mcpAddManual => 'Fill in manually';

  @override
  String get mcpAddManualDesc => 'Enter URL, headers or a start command';

  @override
  String get mcpAddFromJson => 'Import from JSON';

  @override
  String get mcpAddFromJsonDesc =>
      'Paste a standard mcpServers config to import in bulk';

  @override
  String get mcpJsonImportTitle => 'Import from JSON';

  @override
  String get mcpJsonImportHint =>
      'Paste a standard mcpServers config: the key is the server name, and the value holds a url (remote HTTP) or command (local stdio).';

  @override
  String get mcpJsonImportAction => 'Import';

  @override
  String get mcpJsonImportEmpty => 'No MCP server parsed';

  @override
  String get mcpSaved => 'Saved';

  @override
  String get mcpRefreshTools => 'Refresh tools';

  @override
  String get mcpRemoved => 'MCP server removed';

  @override
  String get permissionsTitle => 'Tool permissions';

  @override
  String get permissionsSubtitle => 'Rules and memory';

  @override
  String permCurrentProject(String name) {
    return 'Current project: $name';
  }

  @override
  String get permCurrentProjectNone => 'Current project (none selected)';

  @override
  String get permNoProjectRules => 'No rules for this project';

  @override
  String get permGlobal => 'Global';

  @override
  String get permNoGlobalRules => 'No global rules';

  @override
  String get permEntireTool => 'Entire tool';

  @override
  String get permDeny => 'Deny';

  @override
  String get permPromoteToGlobal => 'Promote to global';

  @override
  String get permRulesShort =>
      'Choosing “Always run” in a chat creates a rule for the current project';

  @override
  String get chatPermDeny => 'Deny';

  @override
  String get chatPermAlwaysAllow => 'Always run';

  @override
  String get chatPermAlwaysToolDesc =>
      '“Always run” will remember every call of this tool in this project';

  @override
  String get chatPermAlwaysPrefix =>
      '“Always run” will remember in this project: ';

  @override
  String get chatPermSingleUseDesc =>
      'This call cannot be remembered; single use only';

  @override
  String get commonName => 'Name';

  @override
  String get commonTool => 'Tools';

  @override
  String get commonAdd => 'Add';

  @override
  String commonLabelWithApi(String label, String api) {
    return '$label ($api)';
  }

  @override
  String get commonExpand => 'Expand';

  @override
  String get commonCollapse => 'Collapse';

  @override
  String get mcpViewLogs => 'View logs for this MCP';

  @override
  String get mcpAuthEnable => 'OAuth authentication';

  @override
  String get mcpAuthDesc =>
      'For remote MCP services that require browser sign-in';

  @override
  String get mcpAuthClientId => 'client_id (optional)';

  @override
  String get mcpAuthClientIdHint =>
      'Pre-registered client ID; leave empty to try dynamic registration';

  @override
  String get mcpAuthServer => 'Authorization server (optional)';

  @override
  String get mcpAuthServerHint =>
      'Override the discovered authorization server';

  @override
  String get mcpAuthAdvanced => 'Advanced authentication options';

  @override
  String get mcpAuthLogin => 'Sign in / Re-authorize';

  @override
  String get mcpAuthReauthorize => 'Re-authorize';

  @override
  String get mcpAuthLogout => 'Sign out';

  @override
  String get mcpAuthCancel => 'Cancel authorization';

  @override
  String get mcpAuthInProgress => 'Waiting for browser authorization…';

  @override
  String get mcpAuthInProgressHint =>
      'The sign-in page was opened in your browser; it will return and connect automatically';

  @override
  String get mcpAuthSaveFirst =>
      'Save the server first, then you can authorize here';

  @override
  String mcpAuthFailed(String message) {
    return 'Authorization failed: $message';
  }

  @override
  String get mcpAuthStatusLabel => 'Authorization status';

  @override
  String get mcpAuthStatusAuthorized => 'Signed in';

  @override
  String get mcpAuthStatusUnauthorized => 'Not signed in';

  @override
  String get mcpAuthStatusAuthorizing => 'Authorizing';

  @override
  String get mcpAuthSuccess => 'Authorized and connected';

  @override
  String get settingsReconnect => 'Reconnect';

  @override
  String get settingsAddMcpServer => 'Add MCP server';

  @override
  String get settingsContainer => 'Container & Images';

  @override
  String get settingsContainerSubtitle =>
      'PRoot container, images and initialization';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSwitch => 'Switch';

  @override
  String get chatOpenTerminal => 'Open terminal';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String terminalStartFailed(String message) {
    return 'Failed to start terminal:\n$message';
  }

  @override
  String get terminalRetry => 'Retry';

  @override
  String get terminalNoOpenTabs => 'No open terminal tabs';

  @override
  String get terminalNewTab => 'New tab';

  @override
  String get terminalCloseTab => 'Close tab';

  @override
  String get terminalSettingsTitle => 'Terminal settings';

  @override
  String get terminalThemeTitle => 'Color theme';

  @override
  String get terminalThemeFollowApp => 'Follow app';

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
  String get terminalFontSizeTitle => 'Font size';

  @override
  String get terminalCursorStyleTitle => 'Cursor style';

  @override
  String get terminalCursorBlock => 'Block';

  @override
  String get terminalCursorUnderline => 'Underline';

  @override
  String get terminalCursorBar => 'Bar';

  @override
  String get terminalFontTitle => 'Terminal font';

  @override
  String get terminalFontDefault => 'System monospace';

  @override
  String get terminalFontBuiltin => 'JetBrains Mono';

  @override
  String get settingsGeneral => 'Preferences';

  @override
  String get settingsGeneralModels => 'Models';

  @override
  String get settingsAutoRemoveStaleModels =>
      'Remove stale models after fetching';

  @override
  String get settingsAutoRemoveStaleModelsDesc =>
      'On a successful fetch, drop local models the vendor no longer offers';

  @override
  String get settingsGeneralSession => 'Session';

  @override
  String get settingsStartupSession => 'Session on launch';

  @override
  String get settingsStartupSessionNew => 'New session';

  @override
  String get settingsStartupSessionNewDesc =>
      'Reuse an empty session, otherwise start a new one';

  @override
  String get settingsStartupSessionRecent => 'Recent session';

  @override
  String get settingsStartupSessionRecentDesc =>
      'Open the most recently updated session';

  @override
  String get settingsDeleteExternalWorkspaceSessions =>
      'Delete external workspace chats';

  @override
  String get settingsDeleteExternalWorkspaceSessionsDesc =>
      'Also delete a workspace\'s chats when an external local workspace is removed';

  @override
  String get settingsGeneralInput => 'Input';

  @override
  String get settingsEnterToSend => 'Enter key sends message';

  @override
  String get settingsEnterToSendDesc =>
      'When off, Enter inserts a newline and you send with the button';

  @override
  String get settingsCompactionThreshold => 'Auto-compaction threshold';

  @override
  String get settingsCompactionThresholdDesc =>
      'Compact context once it reaches this share of the window';

  @override
  String get settingsCompactionThresholdInputHint =>
      'Integer percentage between 1 and 100';

  @override
  String settingsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsGeneralNetwork => 'Network';

  @override
  String get settingsFirstByteTimeout => 'First byte timeout';

  @override
  String get settingsFirstByteTimeoutDesc =>
      'Max wait for the first response chunk';

  @override
  String get settingsStreamIdleTimeout => 'Chunk idle timeout';

  @override
  String get settingsStreamIdleTimeoutDesc =>
      'Max wait between response chunks';

  @override
  String get settingsTimeoutUnlimited => 'Unlimited';

  @override
  String settingsTimeoutSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get settingsTimeoutInputHint => 'Seconds; 0 means unlimited';

  @override
  String get settingsMaxNetworkRetries => 'Retry attempts';

  @override
  String get settingsMaxNetworkRetriesDesc =>
      'Exponential-backoff retries after a network failure';

  @override
  String settingsRetriesCount(int count) {
    return '$count';
  }

  @override
  String get settingsRetriesInputHint => '0 disables retries';

  @override
  String get settingsGeneralTools => 'Tools';

  @override
  String get settingsSendfileMaxSize => 'sendFile max file size';

  @override
  String get settingsGeneralGoal => 'Goal';

  @override
  String get settingsGoalMaxTurns => 'Max continuation turns';

  @override
  String get settingsGoalMaxTurnsDesc =>
      'Stop the autonomous loop after this many turns';

  @override
  String get settingsGoalMaxTokens => 'Token budget';

  @override
  String get settingsGoalMaxTokensDesc =>
      'Cap on input+output tokens consumed by the autonomous loop';

  @override
  String settingsTurnsValue(int count) {
    return '$count turns';
  }

  @override
  String settingsTokensValue(int count) {
    return '$count';
  }

  @override
  String get settingsGoalMaxTurnsInputHint =>
      'Integer number of turns greater than 0';

  @override
  String get settingsGoalMaxTokensInputHint => 'Integer not less than 1000';

  @override
  String get settingsSendfileMaxSizeDesc =>
      'Per-file size cap; exceeding it fails the whole batch';

  @override
  String get settingsSendfileMaxSizeInputHint =>
      'MB, an integer greater than 0';

  @override
  String settingsMbValue(int mb) {
    return '$mb MB';
  }

  @override
  String providerModelsAlignedRemoved(int count) {
    return 'Removed $count model(s) no longer offered by the vendor';
  }

  @override
  String get tokenStatsTitle => 'Token Stats';

  @override
  String get tokenStatsPeriodToday => 'Today';

  @override
  String get tokenStatsPeriod7d => '7 days';

  @override
  String get tokenStatsPeriod30d => '30 days';

  @override
  String get tokenStatsPeriodAll => 'All';

  @override
  String get tokenStatsTotal => 'Total';

  @override
  String get tokenStatsRequests => 'Requests';

  @override
  String get tokenStatsCost => 'Cost';

  @override
  String get tokenStatsCacheHitRate => 'Cache hit rate';

  @override
  String tokenStatsCacheReadWrite(String read, String write) {
    return 'Read $read / Write $write';
  }

  @override
  String get tokenStatsTrend => 'Usage trend';

  @override
  String get tokenStatsLegendInput => 'Input';

  @override
  String get tokenStatsLegendOutput => 'Output';

  @override
  String get tokenStatsLegendCached => 'Cached';

  @override
  String get tokenStatsProvider => 'By vendor';

  @override
  String get tokenStatsModel => 'By model';

  @override
  String tokenStatsSuccessRate(String rate) {
    return 'Success rate $rate';
  }

  @override
  String get tokenStatsRecentCalls => 'Call records';

  @override
  String get tokenStatsUnknown => 'Unknown';

  @override
  String get tokenStatsNoData => 'No data';

  @override
  String get tokenStatsCallsSuffix => 'calls';

  @override
  String tokenStatsCallsSuffix2(int count) {
    return '$count calls';
  }

  @override
  String get tokenStatsColModel => 'Model';

  @override
  String get tokenStatsColReasoningEffort => 'Effort';

  @override
  String get tokenStatsColProvider => 'Vendor';

  @override
  String get tokenStatsColInput => 'Input';

  @override
  String get tokenStatsColOutput => 'Output';

  @override
  String get tokenStatsColCachedRead => 'Cache read';

  @override
  String get tokenStatsColCachedWrite => 'Cache write';

  @override
  String get tokenStatsColCacheHitRate => 'Hit rate';

  @override
  String get tokenStatsColTtfb => 'TTFB';

  @override
  String get tokenStatsColDuration => 'Duration';

  @override
  String get tokenStatsColTime => 'Time';

  @override
  String get tokenStatsColStatus => 'Status';

  @override
  String get tokenStatsColCost => 'Cost';

  @override
  String tokenStatsPage(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String tokenStatsRetries(int count) {
    return '$count retries';
  }

  @override
  String get tokenStatsReset => 'Reset';

  @override
  String get tokenStatsResetTitle => 'Reset token stats';

  @override
  String get tokenStatsResetConfirm =>
      'All call records will be permanently deleted. Reset?';

  @override
  String get tokenStatsFilterAllProviders => 'All Vendors';

  @override
  String get tokenStatsFilterAllModels => 'All Models';

  @override
  String get tokenStatsFilterClear => 'Clear filters';

  @override
  String tokenStatsFilterProvider(String name) {
    return 'Vendor: $name';
  }

  @override
  String tokenStatsFilterModel(String name) {
    return 'Model: $name';
  }

  @override
  String tokenStatsProviderKeys(int count) {
    return '$count keys';
  }

  @override
  String get tokenStatsRequestsUnit => 'requests';

  @override
  String get tokenStatsHourSuffix => 'h';

  @override
  String get tokenStatsPrevPage => 'Previous';

  @override
  String get tokenStatsNextPage => 'Next';

  @override
  String get settingsCategoryData => 'Data & Diagnostics';

  @override
  String get gitActionClone => 'Clone';

  @override
  String get gitActionInit => 'Initialize';

  @override
  String get gitActionMerge => 'Merge Branch';

  @override
  String get gitActionStageAll => 'Stage all';

  @override
  String get gitCloneUrlHint => 'https://github.com/user/repo.git';

  @override
  String get gitComputingDiff => 'Computing diff...';

  @override
  String get gitCreateTagTitle => 'New Tag';

  @override
  String gitCreateTrackingBranch(String branch) {
    return 'Create a local tracking branch from remote branch $branch and switch?';
  }

  @override
  String get gitCredentialsAndIdentity => 'Credentials & Identity';

  @override
  String gitDetachedHeadWarning(String ref) {
    return 'Switching to tag $ref will enter detached HEAD state — not on any branch, new commits will not belong to any branch. Continue?';
  }

  @override
  String gitMergeConfirm(String branch, String current) {
    return 'Merge branch $branch into current branch ($current)?';
  }

  @override
  String get gitMergeNoFf => 'Create a merge commit (--no-ff)';

  @override
  String get gitOpenInEditor => 'Open in Editor';

  @override
  String get gitSwitchBranch => 'Switch Branch';

  @override
  String gitSwitchConfirm(String ref) {
    return 'Switch to $ref?';
  }

  @override
  String gitToastLoadBranchesFailed(String error) {
    return 'Failed to load branches: $error';
  }

  @override
  String gitToastRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String gitToastActionRefreshFailed(String message) {
    return '$message (refresh failed)';
  }

  @override
  String gitToastLoadMoreFailed(String error) {
    return 'Failed to load more: $error';
  }

  @override
  String gitToastCheckoutFailed(String error) {
    return 'Switch failed: $error';
  }

  @override
  String get gitToastNotRepo => 'This directory is not a Git repository';

  @override
  String gitToastSwitchRepoFailed(String error) {
    return 'Switch repository failed: $error';
  }

  @override
  String get gitToastDiffFailed => 'Failed to load diff';

  @override
  String get gitToastNoDiffForCommit =>
      'No changes found to generate commit message';

  @override
  String get gitToastGenerateCommitFailed =>
      'Failed to generate commit message, please check model or network';

  @override
  String get diffBinaryFile => 'Binary file, text diff not supported';

  @override
  String get diffFileTooLarge => 'File too large, diff calculation skipped';

  @override
  String get diffFileTooLargeDesc =>
      'Files over 2000 lines or with extremely long lines are not diffed line-by-line, to avoid rendering and memory pressure.';

  @override
  String get diffNoChanges => 'No differences';

  @override
  String get back => 'Back';

  @override
  String get chatOpenGit => 'Open Git';

  @override
  String get switchLabel => 'Switch';

  @override
  String get credentialEdit => 'Edit Credential';

  @override
  String get credentialToastSaved => 'Credential saved';

  @override
  String credentialToastSaveFailed(String param1) {
    return 'Save failed: %1\$s';
  }

  @override
  String get credentialToastDeleted => 'Credential deleted';

  @override
  String get credentialToastIdentitySaved =>
      'Identity and repository URL saved';

  @override
  String get credentialEmptyHint => 'No credentials yet, tap + to add';

  @override
  String get credentialEmptyTitle => 'No Git Credentials';

  @override
  String get credentialEmptyDesc =>
      'Configure credentials so Codecraft can authenticate when pushing or pulling repositories';

  @override
  String get credentialAddManual => 'Add manually';

  @override
  String get gitTabIdentity => 'Identity';

  @override
  String get gitTabCredentials => 'Credentials';

  @override
  String get gitIdentityTitle => 'Commit Identity';

  @override
  String gitIdentityCodespace(String name) {
    return 'Connected to GitHub Codespace $name';
  }

  @override
  String get gitRepoUrlTitle => 'Repository URL';

  @override
  String get gitRemoteUrl => 'remote.origin.url';

  @override
  String gitCredentialsCount(int param1) {
    return 'Credentials ($param1)';
  }

  @override
  String get codespacesTitle => 'GitHub Codespaces';

  @override
  String codespacesNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String get codespacesAccount => 'Account';

  @override
  String codespacesCount(int count) {
    return 'Codespaces ($count)';
  }

  @override
  String get codespacesEmptyTitle => 'No Codespaces yet';

  @override
  String get codespacesEmptyDesc =>
      'Create a Codespace on GitHub and it will show up here';

  @override
  String get codespacesCreateOnWeb => 'Create on github.com';

  @override
  String get codespacesRefresh => 'Refresh';

  @override
  String get codespacesOpenInBrowser => 'Open in browser';

  @override
  String get codespacesStart => 'Start';

  @override
  String get codespacesStop => 'Stop';

  @override
  String get codespacesDelete => 'Delete';

  @override
  String codespacesDeleteConfirm(String name) {
    return 'Delete $name? This cannot be undone';
  }

  @override
  String get codespacesStateAvailable => 'Running';

  @override
  String get codespacesStateStarting => 'Starting';

  @override
  String get codespacesStateStopped => 'Stopped';

  @override
  String get codespacesStateUnknown => 'Unknown state';

  @override
  String codespacesLastUsed(String time) {
    return 'Last used $time';
  }

  @override
  String get codespacesNoRepo => 'Unknown repository';

  @override
  String get codespacesUncommitted => 'Uncommitted changes';

  @override
  String get codespacesMoreActions => 'More actions';

  @override
  String get editorLoadFailed => 'Could not read this file';

  @override
  String get editorSaveFailed => 'Save failed';

  @override
  String get editorSaved => 'Saved';

  @override
  String get editorCharacters => 'Characters';

  @override
  String get characterTitle => 'Characters';

  @override
  String get characterNew => 'New Character';

  @override
  String get characterEdit => 'Edit Character';

  @override
  String get characterEmpty => 'No characters yet';

  @override
  String get characterSearchHint => 'Search by name, alias or tags';

  @override
  String get characterSearchEmpty => 'No matching characters';

  @override
  String get characterFieldBasic => 'Basic Info';

  @override
  String get characterFieldName => 'Name';

  @override
  String get characterFieldNameHint => 'Character\'s real name';

  @override
  String get characterFieldAlias => 'Alias/Nickname';

  @override
  String get characterFieldAliasHint => 'Common nickname in the story';

  @override
  String get characterFieldGender => 'Gender';

  @override
  String get characterFieldGenderHint => 'Male/Female/Other';

  @override
  String get characterFieldAge => 'Age';

  @override
  String get characterFieldAgeHint => 'Number, e.g. 25';

  @override
  String get characterFieldBirthday => 'Birthday';

  @override
  String get characterFieldBirthdayHint => 'Format: MM-DD, e.g. 01-15';

  @override
  String get characterFieldAppearance => 'Appearance';

  @override
  String get characterFieldAppearanceHint =>
      'Height, build, hair/eye color, features';

  @override
  String get characterFieldPersonality => 'Personality';

  @override
  String get characterFieldPersonalityHint =>
      'Traits, behavior patterns, speech style';

  @override
  String get characterFieldBackground => 'Background';

  @override
  String get characterFieldBackgroundHint =>
      'Upbringing, key events, family history';

  @override
  String get characterFieldGoals => 'Goals';

  @override
  String get characterFieldGoalsHint => 'What the character wants to achieve';

  @override
  String get characterFieldFears => 'Fears';

  @override
  String get characterFieldFearsHint => 'Phobias, trauma, fatal weaknesses';

  @override
  String get characterFieldTags => 'Tags';

  @override
  String get characterFieldTagsHint =>
      'Comma-separated, e.g. protagonist, mage';

  @override
  String get characterScope => 'Scope';

  @override
  String get characterScopeProject => 'This project';

  @override
  String get characterScopeGlobal => 'Global';

  @override
  String characterSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get editorUndo => 'Undo';

  @override
  String get editorRedo => 'Redo';

  @override
  String get editorSearch => 'Search';

  @override
  String get editorSearchHint => 'Find';

  @override
  String get editorSearchPrev => 'Previous';

  @override
  String get editorSearchNext => 'Next';

  @override
  String get editorTypeset => 'Auto format';

  @override
  String get editorTypesetDone => 'Formatted, undoable';

  @override
  String get editorCopy => 'Copy';

  @override
  String get editorCopied => 'Copied to clipboard';

  @override
  String get editorUnsavedState => 'Unsaved';

  @override
  String editorWordCount(int count) {
    return '$count chars';
  }

  @override
  String get editorNoFile =>
      'No file open yet. Use \"Open in editor\" from a diff';

  @override
  String get editorUnsavedTitle => 'Unsaved changes';

  @override
  String get editorUnsavedMessage =>
      'This file has unsaved changes. Save them?';

  @override
  String get editorSaveAndExit => 'Save and exit';

  @override
  String get editorSaveAndSwitch => 'Save and switch';

  @override
  String get editorDontSave => 'Don\'t save';

  @override
  String get editorMdPreview => 'Preview Markdown';

  @override
  String get editorMdShowSource => 'Show source';

  @override
  String get editorIndent => 'Indent';

  @override
  String get editorCursorLeft => 'Move cursor left';

  @override
  String get editorCursorRight => 'Move cursor right';

  @override
  String get editorSettings => 'Editor settings';

  @override
  String get editorFontSize => 'Font size';

  @override
  String editorFontSizeValue(int size) {
    return '$size sp';
  }

  @override
  String get editorWordWrap => 'Word wrap';

  @override
  String get editorShowIndentGuide => 'Show indent guides';

  @override
  String get editorShowWhitespace => 'Show whitespace';

  @override
  String editorFileTooLarge(int mb) {
    return 'File too large ($mb MB) to open';
  }

  @override
  String get editorBinaryUnsupported => 'Binary file, cannot open';

  @override
  String get editorSaveConflictTitle => 'File was modified';

  @override
  String get editorSaveConflictMessage =>
      'This file was changed by AI or another program after you opened it. Saving will overwrite those changes.';

  @override
  String editorSaveConflictDiff(String diff) {
    return '- content on disk\n+ your edits\n\n$diff';
  }

  @override
  String get editorSaveConflictOverwrite => 'Overwrite disk';

  @override
  String get editorSaveConflictDiscard => 'Discard my edits';

  @override
  String get editorSaveConflictCancel => 'Cancel';

  @override
  String get editorSaveConflictDiscarded =>
      'Edits discarded, reloaded from disk';

  @override
  String editorLineColumn(int line, int column) {
    return '$line:$column';
  }

  @override
  String get codespacesConnect => 'Connect';

  @override
  String get codespacesDisconnect => 'Disconnect';

  @override
  String get codespacesGhMissing =>
      'gh (GitHub CLI) is missing in the container. Run `codecraft` in the terminal and install the \"GitHub Codespaces\" scenario.';

  @override
  String get codespacesExecutionEnv => 'Execution environment';

  @override
  String get codespacesEnvLocal => 'Local container';

  @override
  String get codespacesEnvCodespace => 'Remote Codespace';

  @override
  String terminalRemoteEnv(String name) {
    return 'Remote: $name';
  }

  @override
  String get codespacesNew => 'New Codespace';

  @override
  String get codespacesRepoTab => 'Repository';

  @override
  String get codespacesRepoSearchHint => 'Search repositories';

  @override
  String get codespacesBranch => 'Branch (leave empty for default)';

  @override
  String get codespacesMachine => 'Machine type';

  @override
  String get codespacesMachineDefault => 'Default';

  @override
  String get codespacesCreate => 'Create';

  @override
  String get codespacesRename => 'Rename';

  @override
  String get codespacesRenameTitle => 'Codespace display name';

  @override
  String get codespacesChangeMachine => 'Change machine type';

  @override
  String get codespacesNoMachines =>
      'No machine types available for this repository';

  @override
  String get codespacesLoadFailed => 'Load failed';

  @override
  String get codespacesPorts => 'Ports';

  @override
  String get codespacesPortsEmpty => 'No forwarded ports yet';

  @override
  String get codespacesPortVisibility => 'Visibility';

  @override
  String get codespacesPortPrivate => 'Private';

  @override
  String get codespacesPortOrg => 'Organization';

  @override
  String get codespacesPortPublic => 'Public';

  @override
  String get codespacesPortOpen => 'Open';

  @override
  String get codespacesRebuild => 'Rebuild container';

  @override
  String get codespacesRebuildDesc =>
      'Rebuild recreates the container from your current devcontainer. Your code and uncommitted changes are preserved, but installed tools and running processes inside the container are lost.';

  @override
  String get codespacesRebuildFull =>
      'Full rebuild (also clears cached Docker images; slower)';

  @override
  String get settingsLog => 'Logs';

  @override
  String get settingsLogSubtitle => 'App logs and AI request logs';

  @override
  String get logFiles => 'Log files';

  @override
  String get logNoFiles => 'No log files yet';

  @override
  String logReadFailed(String error) {
    return 'Could not read the log: $error';
  }

  @override
  String get logSearchHint => 'Search logs';

  @override
  String get logNoMatch => 'No logs match the current filter';

  @override
  String get logLevel => 'Log level';

  @override
  String get logLevelDesc =>
      'Logs below this level are dropped. VERBOSE records everything during development; NONE disables logging.';

  @override
  String get logCopied => 'Copied';

  @override
  String logMcpPrefix(String server) {
    return 'MCP logs: $server';
  }

  @override
  String logSearchResults(int count) {
    return '$count matching lines';
  }

  @override
  String logShowLastLines(int shown, int total) {
    return 'Showing last $shown/$total lines';
  }

  @override
  String logShowLines(int count) {
    return 'Showing $count lines';
  }

  @override
  String get logCopy => 'Copy';

  @override
  String get logClearFilter => 'Clear filter';

  @override
  String get logCopyMenuTitle => 'Copy log';

  @override
  String get logCopyLine => 'Copy this line';

  @override
  String get logCopyWithStack => 'Copy with stack trace';

  @override
  String get logCopyMessage => 'Copy message only';

  @override
  String get logFollowLatest => 'Follow latest';

  @override
  String get logFileLocation =>
      'Log files are located in Android/data/<package>/files/logs/.';

  @override
  String get logLevelVerbose => 'VERBOSE';

  @override
  String get logLevelDebug => 'DEBUG';

  @override
  String get logLevelInfo => 'INFO';

  @override
  String get logLevelWarn => 'WARN';

  @override
  String get logLevelError => 'ERROR';

  @override
  String get logLevelNone => 'NONE';

  @override
  String get credentialTokenHint =>
      'Use a GitHub token with the codespace scope; one token covers both git push and Codespaces sign-in';

  @override
  String get credentialHostOptional => 'Host (optional)';

  @override
  String get credentialHostAny => 'Leave empty for all hosts';

  @override
  String get credentialHostHint =>
      'Fill only to give one host its own token, e.g. gitlab.com';

  @override
  String get codespacesNeedCredentialTitle => 'No GitHub credential yet';

  @override
  String get codespacesNeedCredentialDesc =>
      'Codespaces uses the token from your Git credentials (must include the codespace scope); nothing to fill in here.';

  @override
  String get codespacesGoToCredentials => 'Open Git credentials';

  @override
  String get credentialAllHosts => 'All hosts';

  @override
  String get credentialUsernameAuto => 'Username derived automatically';

  @override
  String get chatMentionSkill => 'Mention a skill';

  @override
  String get chatMentionSkillEmpty =>
      'No skills yet — import or create one in settings first.';

  @override
  String get chatMentionSkillManage => 'Manage skills';

  @override
  String get chatPickFile => '# File';

  @override
  String get chatPickFileParent => 'Parent folder';

  @override
  String get chatPickFileEmpty => 'This folder is empty';

  @override
  String get mentionHintSkill => 'Keep typing to filter skills';

  @override
  String get mentionHintFile => 'Keep typing to filter files';

  @override
  String get fileBrowserError => 'Failed to read directory';

  @override
  String get fileBrowserRefresh => 'Refresh';

  @override
  String get fileBrowserExpand => 'Expand';

  @override
  String get fileBrowserCollapse => 'Collapse';

  @override
  String get fileBrowserNewFile => 'New file';

  @override
  String get fileBrowserNewFolder => 'New folder';

  @override
  String get fileBrowserNameLabel => 'Name';

  @override
  String fileBrowserDeleteFileConfirm(String name) {
    return 'Delete file \"$name\"?';
  }

  @override
  String fileBrowserDeleteFolderConfirm(String name) {
    return 'Delete folder \"$name\" and everything inside?';
  }

  @override
  String get fileBrowserCreateFailed =>
      'Could not create — a name clash or no write permission';

  @override
  String get fileBrowserRenameFailed =>
      'Could not rename — a name clash may exist';

  @override
  String get fileBrowserDeleteFailed => 'Could not delete';

  @override
  String get fileBrowserPasteHere => 'Paste here';

  @override
  String get fileBrowserExtract => 'Extract';

  @override
  String get fileBrowserExtractFailed => 'Extraction failed';

  @override
  String get fileBrowserExtractConflictTitle => 'Target folder already exists';

  @override
  String fileBrowserExtractConflict(String name) {
    return 'A folder named \"$name\" already exists here. Extracting will overwrite its contents.';
  }

  @override
  String get fileBrowserExtractOverwrite => 'Overwrite and extract';

  @override
  String get fileBrowserPasteConflictTitle => 'An item with that name exists';

  @override
  String fileBrowserPasteConflictMessage(String name) {
    return '\"$name\" already exists here. Overwrite it?';
  }

  @override
  String get fileBrowserClipboardCut => 'Cut';

  @override
  String get fileBrowserClipboardCopy => 'Copied';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCut => 'Cut';

  @override
  String get commonPaste => 'Paste';

  @override
  String get workspacePickWritingFolder => 'Writing folder';

  @override
  String get writingFolderNeedAccessTitle => 'Storage access needed';

  @override
  String get writingFolderNeedAccessDesc =>
      'Reading the AI-writing folder on your device needs all-files access. You can skip and pick a folder directly instead.';

  @override
  String get writingFolderGrant => 'Grant';

  @override
  String writingFolderSet(String path) {
    return 'Writing folder set to $path';
  }

  @override
  String get modelAuto => 'Auto Model';

  @override
  String get modelAutoDesc => 'Picks the best model for each task';

  @override
  String get sessionExport => 'Export chat';

  @override
  String sessionExportDone(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionExportFailed => 'Export failed';

  @override
  String get sessionBatchSelect => 'Batch select';

  @override
  String sessionSelectedCount(String count) {
    return '$count selected';
  }

  @override
  String get sessionSelectAll => 'Select all';

  @override
  String get sessionCancelSelect => 'Cancel';

  @override
  String get sessionDeleteSelected => 'Delete selected';

  @override
  String get sessionDeleteConfirm => 'Delete this chat and all its messages?';

  @override
  String get fileBrowserNeedPermission =>
      'Cannot read this folder — storage access may be required';

  @override
  String get checkpointRewindTitle => 'Rewind to here';

  @override
  String checkpointTargetPrompt(String snippet) {
    return 'Target: $snippet';
  }

  @override
  String get checkpointRestoreCodeAndConversation =>
      'Restore code and conversation';

  @override
  String get checkpointRestoreCodeAndConversationDesc =>
      'Roll back workspace files and delete all later messages; the prompt returns to the input box';

  @override
  String get checkpointRestoreConversation => 'Restore conversation only';

  @override
  String get checkpointRestoreConversationDesc =>
      'Delete all later messages; workspace files stay unchanged';

  @override
  String get checkpointRestoreCode => 'Restore code only';

  @override
  String get checkpointRestoreCodeDesc =>
      'Roll back workspace files; the conversation stays unchanged';

  @override
  String checkpointRewindSkipped(int count) {
    return '$count file(s) skipped because of other changes';
  }

  @override
  String get chatMoreOptions => 'More options';

  @override
  String get chatActionEdit => 'Edit';

  @override
  String get chatActionDelete => 'Delete';

  @override
  String get chatEditMessageTitle => 'Edit message';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBatchDelete => 'Batch delete';

  @override
  String get tabProjects => 'Projects';

  @override
  String get projectListEmpty => 'No projects yet';

  @override
  String get workspaceCurrent => 'Current';

  @override
  String get workspaceNameHint => 'Project name';

  @override
  String get projectNew => 'New project';

  @override
  String get projectUntitled => 'Untitled project';

  @override
  String get projectKindCoding => 'Coding';

  @override
  String get projectKindCodingDesc =>
      'Write code, run commands and edit files in a sandbox workspace';

  @override
  String get projectKindWriting => 'Writing';

  @override
  String get projectKindWritingDesc =>
      'Draft and revise documents in the AI Writing folder';

  @override
  String get projectKindReverse => 'App reverse engineering';

  @override
  String get projectKindReverseDesc =>
      'APK analysis, traffic capture, static reversing & debugging aids';

  @override
  String projectDeleteConfirm(String name) {
    return 'Delete project \"$name\"? All its sessions will be removed too.';
  }

  @override
  String get installedAppsTitle => 'Choose an app';

  @override
  String get installedAppsSearch => 'Search by name or package';

  @override
  String get installedAppsEmpty => 'No matching apps';

  @override
  String get storagePermissionGrant => 'Grant';

  @override
  String get softwarePermissionsTitle => 'App permissions';

  @override
  String get softwarePermissionsSubtitle =>
      'Tap an item to let the system ask for permission, or open the matching system settings page.';

  @override
  String get systemPermissionsGroup => 'System permissions';

  @override
  String get permissionStorageTitle => 'Storage access';

  @override
  String get permissionBatteryTitle => 'Ignore battery optimization';

  @override
  String get permissionBatteryDesc =>
      'Keep running in the background instead of being killed';

  @override
  String get permissionAutoStartTitle => 'Auto-start';

  @override
  String get permissionAutoStartDesc =>
      'Let the system launch the app in the background';

  @override
  String get permissionShizukuTitle => 'Shizuku';

  @override
  String get permissionShizukuDesc => 'Tap to download and install Shizuku';

  @override
  String get permissionAllowed => 'Allowed';

  @override
  String get permissionNotAllowed => 'Not allowed';

  @override
  String get permissionInstalled => 'Installed';

  @override
  String get permissionNotInstalled => 'Not installed';

  @override
  String get permissionAppsTitle => 'App list';

  @override
  String get permissionAppsDesc =>
      'Read installed apps\' name, package and version';

  @override
  String get apkPathUnavailable =>
      'Can\'t locate this app\'s APK. Try another app.';

  @override
  String get apkExtractHint =>
      'This project shows the files inside the selected APK. Extract it once to browse.';

  @override
  String get apkExtractAction => 'Extract APK';

  @override
  String get apkExtracting => 'Extracting…';

  @override
  String get apkExtractFailed =>
      'Extraction failed — the APK may not be readable.';

  @override
  String get terminalAgentTab => 'AI commands';

  @override
  String get runModeAuto => 'Auto mode';

  @override
  String get runModeBuild => 'Build mode';

  @override
  String get runModePlan => 'Plan mode';

  @override
  String get runModePlanIntercept =>
      'Write operations are blocked in plan mode';

  @override
  String get runModeBuildAuthorize =>
      'AI wants to perform a write operation. Allow?';

  @override
  String get runModeBuildAllow => 'Allow';

  @override
  String get runModeBuildDeny => 'Deny';

  @override
  String runModeSwitchChanged(Object mode) {
    return 'Switched run mode to $mode';
  }

  @override
  String get commonScrollToBottom => 'Scroll to bottom';

  @override
  String get subagentTitle => 'Sub-agents';

  @override
  String get subagentSubtitle => 'Model tiers & custom definitions';

  @override
  String get subagentTierSubtitle =>
      'Bind a provider and model to each tier. Unconfigured tiers use the definition\'s pinned model, or inherit the current session\'s model';

  @override
  String get subagentTierSection => 'Model tiers';

  @override
  String get subagentTierLight => 'Light';

  @override
  String get subagentTierStandard => 'Standard';

  @override
  String get subagentTierStrong => 'Strong';

  @override
  String get subagentTierLightDesc =>
      'Read-only exploration, batch locating, mechanical renames';

  @override
  String get subagentTierStandardDesc => 'Single-file edits and routine fixes';

  @override
  String get subagentTierStrongDesc =>
      'Cross-module refactors, tricky debugging, and solution design';

  @override
  String get subagentTierUnset => 'Not set (inherit session model)';

  @override
  String get subagentTierPick => 'Pick model';

  @override
  String get subagentTierClear => 'Clear';

  @override
  String get subagentTierCleared => 'Cleared';

  @override
  String get subagentTierSaved => 'Saved';

  @override
  String subagentTierSheetTitle(String tier) {
    return '$tier tier model';
  }

  @override
  String get subagentTierSheetHint =>
      'Pick the provider and model for this tier';

  @override
  String get subagentTierSheetInherit => 'Inherit session model';

  @override
  String get subagentNoticeTitle => 'Sub-agent';

  @override
  String get subagentStateRunning => 'Running';

  @override
  String get subagentStateCompleted => 'Completed';

  @override
  String get subagentStateFailed => 'Failed';

  @override
  String get subagentStateMessage => 'New message';

  @override
  String get subagentViewOutput => 'View output';

  @override
  String get subagentOpen => 'Open';

  @override
  String get subagentOutputEmpty => 'No output yet';

  @override
  String get subagentOutputTitle => 'Sub-agent output';

  @override
  String get promptsTitle => 'Prompts';

  @override
  String get promptsScenarioSection => 'Scenario prompts';

  @override
  String get promptsSortLongPress => 'Long-press to reorder';

  @override
  String get promptsEmpty => 'No fragments available';

  @override
  String get promptsSourceProject => 'Project';

  @override
  String get promptsSourceGlobal => 'Global';

  @override
  String get promptsSourceLocal => 'Local';

  @override
  String get promptsSourceBuiltin => 'Built-in';

  @override
  String get promptsFieldBasic => 'Basic';

  @override
  String get promptsFieldNumber => 'Number';

  @override
  String get promptsFieldNumberPlaceholder => 'Two digits, e.g. 35';

  @override
  String get promptsFieldTitle => 'Name';

  @override
  String get promptsFieldTitlePlaceholder => 'e.g. My safety rules';

  @override
  String get promptsFieldSummary => 'Summary (optional)';

  @override
  String get promptsFieldSummaryPlaceholder =>
      'Brief description; not included in the prompt';

  @override
  String get promptsFieldContent => 'Fragment content';

  @override
  String get promptsFieldContentPlaceholder => 'What the model should follow';

  @override
  String get promptsEditorNew => 'New prompt';

  @override
  String get promptsEditorEdit => 'Edit prompt';

  @override
  String get promptsAddPrompt => 'Add fragment';

  @override
  String get promptsResetCustom => 'Reset custom prompts';

  @override
  String get promptsResetConfirm =>
      'Deletes every custom prompt fragment in this project and the global layer; each number falls back to the built-in prompt. This cannot be undone.';

  @override
  String get promptsResetAction => 'Reset';

  @override
  String get promptsHelp => 'Help';

  @override
  String get promptsDisableBuiltin => 'Disable all built-in prompts';

  @override
  String get promptsDisableBuiltinHint =>
      'Keep only your fragments; you must supply every rule yourself';

  @override
  String get promptsBatchDeleteTitle => 'Delete Prompts';

  @override
  String promptsBatchDeleteConfirm(int count) {
    return 'Delete the selected $count custom prompt fragments? Their numbers will fall back to the next source.';
  }

  @override
  String get promptsScope => 'Scope';

  @override
  String get promptsScopeProject => 'This project';

  @override
  String get promptsScopeGlobal => 'Global';

  @override
  String get promptsSelectMode => 'Select';

  @override
  String promptsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get promptsSelectAll => 'Select All';

  @override
  String get promptsDeselectAll => 'Deselect All';

  @override
  String get promptsSummary => 'Summary';

  @override
  String get promptsGotIt => 'Got it';

  @override
  String get promptsSubtitle => 'Custom prompt fragments';

  @override
  String get novelNew => 'New Novel';

  @override
  String get novelFieldName => 'Title';

  @override
  String get novelFieldNameHint => 'e.g. I Run a Shop in the Cultivation World';

  @override
  String get novelFieldGender => 'Genre';

  @override
  String get novelGenderMale => 'Male-oriented';

  @override
  String get novelGenderFemale => 'Female-oriented';

  @override
  String get novelFieldTags => 'Tags';

  @override
  String get novelFieldTagsHint => 'Pick presets or enter your own';

  @override
  String get novelCustomTagHint => 'Custom tag';

  @override
  String get novelFieldWordsPerChapter => 'Words per chapter';

  @override
  String get novelFieldWordsHint => 'Pick a preset or enter a custom count';

  @override
  String get novelCreate => 'Create';

  @override
  String get novelPickExisting => 'Existing Novel';

  @override
  String get novelOpen => 'Open';

  @override
  String get novelExistingEmpty => 'No other novels in the AI Novel folder';

  @override
  String get novelExistingEmptyHint =>
      'Put novel folders into the AI Novel folder, then come back to select one';

  @override
  String get novelExistingFailed => 'Failed to load novels';

  @override
  String novelExistingBrief(String title) {
    return 'Continue the existing novel “$title”. Read the story materials and existing chapters first, then continue writing.';
  }

  @override
  String novelBriefTitle(String title) {
    return 'New novel “$title”';
  }

  @override
  String novelBriefTags(String tags) {
    return 'Tags: $tags';
  }

  @override
  String novelBriefWords(String words) {
    return 'Words per chapter: $words';
  }

  @override
  String get novelScaffoldFailedTitle => 'Failed to create novel directory';

  @override
  String novelScaffoldFailed(String path) {
    return 'Could not create the novel directory under $path. Check storage permission and try again.';
  }

  @override
  String get agentTitle => 'Sub-agents';

  @override
  String get agentSubtitle => 'Custom agent definitions';

  @override
  String get agentListEmpty => 'No custom sub-agents yet';

  @override
  String get agentListEmptyHint =>
      'Tap + to create a custom sub-agent definition';

  @override
  String get agentScopeProject => 'Current project';

  @override
  String get agentScopeGlobal => 'Global';

  @override
  String get agentScopeProjectHint => 'Only effective in this workspace';

  @override
  String get agentScopeGlobalHint => 'Shared across all projects';

  @override
  String get agentNew => 'New sub-agent';

  @override
  String get agentEdit => 'Edit sub-agent';

  @override
  String get agentSave => 'Save';

  @override
  String get agentCancel => 'Cancel';

  @override
  String get agentDelete => 'Delete';

  @override
  String get agentDeleteTitle => 'Delete sub-agent';

  @override
  String agentDeleteConfirm(Object name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String get agentImport => 'Import';

  @override
  String get agentName => 'Name';

  @override
  String get agentDescription => 'Description';

  @override
  String get agentDescriptionHint => 'When to use this sub-agent';

  @override
  String get agentPrompt => 'Prompt body';

  @override
  String get agentPromptHint =>
      'Instructions appended to the base system prompt';

  @override
  String get agentProvider => 'Provider';

  @override
  String get agentModel => 'Model';

  @override
  String get agentReasoningEffort => 'Reasoning effort';

  @override
  String get agentMode => 'Default mode';

  @override
  String get agentTools => 'Tool allow-list';

  @override
  String get agentToolsHint => 'Empty means inherit all tools';

  @override
  String get agentDisallowedTools => 'Tool deny-list';

  @override
  String get agentInject => 'Injected rules';

  @override
  String get agentInjectHint =>
      'base/mainRules/skills/memory/projectRules or none';

  @override
  String get agentEnable => 'Enable';

  @override
  String get agentDisable => 'Disable';

  @override
  String get agentEnabled => 'Enabled';

  @override
  String get agentDisabled => 'Disabled';

  @override
  String get agentErrorInvalidName => 'Invalid name';

  @override
  String get agentErrorEmptyPrompt => 'Prompt body is required';

  @override
  String get agentErrorNameConflict =>
      'A sub-agent with this name already exists in this scope';

  @override
  String get agentErrorIoFailed => 'Failed to write file';

  @override
  String get agentCapabilityRead => 'File read';

  @override
  String get agentCapabilityWrite => 'File modify';

  @override
  String get agentCapabilityCommand => 'Run commands';

  @override
  String get agentBuiltin => 'Built-in';

  @override
  String get agentBuiltinHint =>
      'Released on first launch, preserved across upgrades';

  @override
  String get agentSelectMode => 'Select';

  @override
  String get agentBatchEnable => 'Enable';

  @override
  String get agentBatchDisable => 'Disable';

  @override
  String get agentBatchDelete => 'Delete';

  @override
  String get agentBatchAll => 'Select all';

  @override
  String get agentBatchCancel => 'Cancel';

  @override
  String agentSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String agentBatchDeleteConfirm(Object count) {
    return 'Delete $count sub-agent(s)? This cannot be undone.';
  }

  @override
  String get agentBatchDeleting => 'Deleting...';

  @override
  String get agentInherit => 'Inherit session';

  @override
  String get agentReasoningNone => 'None';

  @override
  String get agentReasoningMinimal => 'Minimal';

  @override
  String get agentReasoningLow => 'Low';

  @override
  String get agentReasoningMedium => 'Medium';

  @override
  String get agentReasoningHigh => 'High';

  @override
  String get agentReasoningXhigh => 'X-High';

  @override
  String get agentReasoningMax => 'Max';

  @override
  String get agentModeBuild => 'Build';

  @override
  String get agentModePlan => 'Plan';

  @override
  String get agentModeAuto => 'Auto';

  @override
  String get agentDetail => 'Sub-agent detail';

  @override
  String get agentDetailHint => 'Edit the definition; rename renames the file';

  @override
  String get promptsFieldType => 'Type';

  @override
  String get promptsSaveFailed => 'Save failed';

  @override
  String get promptsNoOverrideToDelete =>
      'No custom override to delete for this prompt';

  @override
  String get codespacesSearchHint => 'Search by name, repository, or branch';

  @override
  String get codespacesFilterAll => 'All';

  @override
  String get codespacesFilterRunning => 'Running';

  @override
  String get codespacesFilterStopped => 'Stopped';

  @override
  String get codespacesNoMatch => 'No codespaces match the current filter';

  @override
  String get codespacesStartAndConnect => 'Start & Connect';

  @override
  String get codespacesConnecting => 'Connecting…';

  @override
  String get codespacesWaitingForStart =>
      'Waiting for Codespace to become available…';

  @override
  String codespacesConnectError(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get codespacesDetails => 'Details';

  @override
  String get codespacesOverview => 'Overview';

  @override
  String get codespacesBranchLabel => 'Branch';

  @override
  String get codespacesMachineLabel => 'Machine';

  @override
  String get codespacesLocation => 'Region';

  @override
  String get codespacesIdleTimeout => 'Idle timeout (min)';

  @override
  String get codespacesRetentionPeriod => 'Retention (days)';

  @override
  String get codespacesDevcontainerPath => 'Dev container path';

  @override
  String get codespacesCreatedAt => 'Created';

  @override
  String get codespacesOwner => 'Owner';

  @override
  String get codespacesBillableOwner => 'Billable owner';

  @override
  String get codespacesCopySsh => 'Copy SSH command';

  @override
  String get codespacesSshCopied => 'SSH command copied';

  @override
  String get codespacesOpenWeb => 'Open in VS Code for the Web';

  @override
  String get codespacesUnpushed => 'Unpushed changes';

  @override
  String get codespacesGitStatus => 'Git status';

  @override
  String get codespacesActions => 'Actions';

  @override
  String get codespacesPendingOperation => 'Operation in progress';

  @override
  String get codespacesStateQueued => 'Queued';

  @override
  String get codespacesStateProvisioning => 'Provisioning';

  @override
  String get codespacesStateShuttingDown => 'Shutting down';

  @override
  String get codespacesStateFailed => 'Failed';

  @override
  String get codespacesStateDeleting => 'Deleting';

  @override
  String get codespacesCurrentEnv => 'Current environment';

  @override
  String get codespacesSwitchToLocal => 'Switch to local container';

  @override
  String get codespacesManage => 'Manage Codespaces';

  @override
  String get codespacesQuickActions => 'Codespaces';

  @override
  String get codespacesPortCopyUrl => 'Copy URL';

  @override
  String get codespacesPortUrlCopied => 'URL copied';

  @override
  String codespacesErrorInline(String error) {
    return '$error';
  }

  @override
  String get codespacesRetry => 'Retry';

  @override
  String get codespacesRegionDefault => 'Default region';

  @override
  String get codespacesAdvanced => 'Advanced options';

  @override
  String get codespacesDevcontainerPathHint =>
      'Path to devcontainer.json (optional)';

  @override
  String get codespacesIdleTimeoutHint => 'Minutes before idle stop (optional)';

  @override
  String get codespacesRetentionHint =>
      'Days to retain stopped codespace (optional)';

  @override
  String get codespacesReadinessTitle => 'Connection readiness';

  @override
  String get codespacesReadinessCredOk => 'GitHub credentials: configured';

  @override
  String get codespacesReadinessCredMissing =>
      'GitHub credentials: missing (token needs codespace scope)';

  @override
  String get codespacesReadinessGhOk => 'gh CLI: ready';

  @override
  String get codespacesReadinessGhMissing =>
      'gh CLI: not ready (run `codecraft` in terminal and install the Codespaces scenario)';

  @override
  String get codespacesOpenTerminal => 'Open terminal';

  @override
  String get codespacesOpenGit => 'Open Git (deploy/sync)';

  @override
  String get codespacesManageCredentials => 'Manage credentials';

  @override
  String get codespacesDeploySyncHint =>
      'Git push/pull and other operations run in the current execution environment. After connecting a Codespace, deploy/sync runs on the remote repo.';

  @override
  String gitExecutionTargetCodespace(String name) {
    return 'Operations target Codespace: $name';
  }

  @override
  String get gitExecutionTargetLocal => 'Operations target local container';

  @override
  String get gitDeploySyncSection => 'Deploy / Sync';

  @override
  String get gitDeploySyncHintCodespace =>
      'Push, pull, and remote operations run inside the connected Codespace.';

  @override
  String get gitDeploySyncHintLocal =>
      'Push, pull, and remote operations run in the local container; connect a Codespace to deploy/sync remotely.';

  @override
  String get gitOpenCodespaces => 'Codespaces';

  @override
  String get gitOpenTerminal => 'Terminal';

  @override
  String get terminalCodespaceManage => 'Codespaces';

  @override
  String get terminalCodespaceCredentials => 'Git credentials';

  @override
  String get captureTitle => 'Capture';

  @override
  String get captureStart => 'Start proxy';

  @override
  String get captureStop => 'Stop';

  @override
  String get captureRunning => 'Running';

  @override
  String get captureStopped => 'Stopped';

  @override
  String get capturePort => 'Proxy port';

  @override
  String get captureClear => 'Clear';

  @override
  String get captureSearchHint => 'Search URL / method / status';

  @override
  String get captureEmpty =>
      'No captured flows. Start proxy and route target traffic to 127.0.0.1:<port>.';

  @override
  String get captureLimitHint =>
      'Only proxied traffic is captured. HTTPS requires installing/trusting the CA. Android 7+ apps and pinned apps may not be MITM-decryptable.';

  @override
  String get captureCaTitle => 'CA certificate';

  @override
  String get captureCaPath => 'Certificate path';

  @override
  String get captureCaGuide =>
      'Install and trust this CA for network/HTTPS capture. Android path varies by device (Security/Encryption & credentials/Install a certificate). Then set HTTP proxy to 127.0.0.1:<port>.';

  @override
  String get captureCopyPath => 'Copy path';

  @override
  String get captureDetail => 'Flow detail';

  @override
  String get captureRequest => 'Request';

  @override
  String get captureResponse => 'Response';

  @override
  String get captureNotFound => 'Flow not found';

  @override
  String get captureCopyUrl => 'Copy URL';

  @override
  String get captureInstallCa => 'Install cert';

  @override
  String get captureOpenSecurity => 'Security settings';

  @override
  String get captureDownloadCa => 'Save certificate';

  @override
  String get captureCaInstallFail =>
      'Direct install unavailable (path copied). Install the certificate from system security settings.';

  @override
  String get captureVpnPermissionDenied =>
      'VPN permission denied. Please grant VPN permission to enable capture.';

  @override
  String get captureSequence => 'All requests';

  @override
  String get captureDomains => 'Domains';

  @override
  String captureDomainSubtitle(String time, int count) {
    return 'Last request: $time · $count requests';
  }

  @override
  String get captureClearConfirm => 'Clear all captured flows?';

  @override
  String get capturePip => 'Window mode';

  @override
  String get capturePipUnsupported =>
      'Picture-in-picture is not supported on this device';

  @override
  String get capturePipNoTraffic => 'No traffic yet';

  @override
  String get captureNoDomains => 'No domains yet';

  @override
  String get captureCopyHost => 'Copy host';

  @override
  String get captureDeleteConfirm => 'Delete all records of this domain?';

  @override
  String get captureSort => 'Sort';

  @override
  String get captureOverview => 'Overview';

  @override
  String get captureCookies => 'Cookies';

  @override
  String get captureProtocol => 'Protocol';

  @override
  String get captureDuration => 'Duration';

  @override
  String get captureSize => 'Size';

  @override
  String get captureRemoteAddress => 'Remote address';

  @override
  String get captureRequestTime => 'Request time';

  @override
  String get capturePath => 'Path';

  @override
  String get captureStatusCode => 'Status code';

  @override
  String get captureRequestHeaders => 'Request headers';

  @override
  String get captureResponseHeaders => 'Response headers';

  @override
  String get captureRequestBody => 'Request body';

  @override
  String get captureResponseBody => 'Response body';

  @override
  String get captureBodyTruncated => '(body truncated)';

  @override
  String get captureFormatted => 'Formatted';

  @override
  String get captureRaw => 'Raw';

  @override
  String get captureNoCookies => 'No cookies';

  @override
  String get captureRequestCookies => 'Request cookies';

  @override
  String get captureResponseCookies => 'Response Set-Cookie';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get selectExportData => 'Select Export Data';

  @override
  String get aiProvider => 'AI Providers';

  @override
  String get connectSync => 'Connection & Sync';

  @override
  String get chatRecords => 'Chat Records';

  @override
  String get mcpServer => 'MCP Servers';

  @override
  String get permissionRules => 'Permission Rules';

  @override
  String get appSettings => 'App Settings';

  @override
  String get workspaceFiles => 'Workspace Files';

  @override
  String get workspaceFilesHint =>
      'Workspace files should be backed up via Git commit; export backup is for reference only';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupDesc =>
      'Choose data to export, password encryption available';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupDesc => 'Restore data from backup file';

  @override
  String get localBackup => 'Local Backup';

  @override
  String get cloudBackup => 'Cloud Backup';

  @override
  String get aboutUpdateAvailable => 'New version available';

  @override
  String get aboutUpdateDesc => 'New version available';

  @override
  String get aboutUpdateLater => 'Later';

  @override
  String get aboutUpdateGo => 'Go to download';

  @override
  String get aboutCheckingUpdate => 'Checking for latest version on GitHub…';

  @override
  String get aboutAlreadyLatest => 'Already up to date';

  @override
  String get aboutCurrentVersion => 'Current version';

  @override
  String get aboutNewVersionFound => 'New version found';
}
