// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => '소셜 퍼블리싱 및 스케줄링 워크스페이스';

  @override
  String get proWorkspace => '프로 플랜';

  @override
  String get navQueue => '게시 대기열';

  @override
  String get navContent => '콘텐츠 라이브러리';

  @override
  String get navCalendar => '편집 캘린더';

  @override
  String get navChannels => '연결된 채널';

  @override
  String get navSettings => '설정';

  @override
  String get btnNewPost => '새 게시물';

  @override
  String get btnCreatePost => '게시물 만들기';

  @override
  String get btnComposePost => '게시물 작성';

  @override
  String get btnQueuePost => '대기열에 추가';

  @override
  String get btnSchedule => '예약';

  @override
  String get btnShareNow => '지금 공유';

  @override
  String get btnSaveDraft => '초안으로 저장';

  @override
  String get btnConnectChannel => '채널 연결';

  @override
  String get btnCreateChannelGroup => '채널 그룹 만들기';

  @override
  String get btnRegisterCompany => '회사 등록';

  @override
  String get btnCancel => '취소';

  @override
  String get btnSave => '저장';

  @override
  String get btnConfirm => '확인';

  @override
  String get btnDelete => '삭제';

  @override
  String get btnClose => '닫기';

  @override
  String get btnDisconnect => '연결 해제';

  @override
  String get btnSchedulePost => '게시물 예약';

  @override
  String get btnConfirmWipe => '확인 및 데이터 삭제';

  @override
  String get btnClearAllData => '모든 데이터 삭제';

  @override
  String get btnLoadDemoData => '데모 데이터 로드';

  @override
  String get consoleTitle => '게시 운영 콘솔';

  @override
  String get growthWorkspace => '성장 워크스페이스';

  @override
  String get selectTimezoneTitle => '시간대 선택';

  @override
  String languageSetTo(String language) {
    return '언어가 $language로 설정되었습니다';
  }

  @override
  String channelsActive(int count) {
    return '$count개 채널 활성';
  }

  @override
  String channelsConnected(int count) {
    return '$count개 채널 연결됨';
  }

  @override
  String get heroTitle => '모든 소셜 네트워크에서 도달 범위 확대';

  @override
  String get heroSubtitle =>
      '하나의 통합 대기열에서 Instagram, X, LinkedIn, YouTube에 게시물을 계획하고 예약하세요.';

  @override
  String actionRequiredTitle(int count) {
    return '조치 필요 ($count건 문제)';
  }

  @override
  String get actionRequiredSub => '하나 이상의 게시 대상이 수동 처리를 필요로 합니다.';

  @override
  String get metricDrafts => '초안';

  @override
  String get metricDraftsSub => '작업 중인 아이디어';

  @override
  String get metricScheduled => '예약됨';

  @override
  String get metricScheduledSub => '대기열 다음';

  @override
  String get metricPublished => '게시됨';

  @override
  String get metricPublishedSub => '채널에서 라이브';

  @override
  String get metricNeedsReview => '검토 필요';

  @override
  String get metricNeedsReviewSub => '조치 필요';

  @override
  String get queueSectionTitle => '예정된 게시 대기열';

  @override
  String get queueEmptyTitle => '게시 대기열이 비어 있습니다';

  @override
  String get queueEmptySubtitle => '일관된 소셜 미디어 존재감을 위해 게시물을 대기열에 추가하세요.';

  @override
  String get recentActivityTitle => '최근 활동';

  @override
  String get recentActivitySub => '감사 로그 및 실시간 배달 상태';

  @override
  String get noRecentActivity => '완료된 작업이 없습니다.';

  @override
  String get contentLibraryTitle => '멀티 플랫폼 콘텐츠 라이브러리';

  @override
  String get searchHint => '게시물, 캠페인 또는 태그 검색...';

  @override
  String get filterAll => '전체';

  @override
  String get filterDraft => '초안';

  @override
  String get filterScheduled => '예약됨';

  @override
  String get filterPublished => '게시됨';

  @override
  String get filterFailed => '실패 / 차단됨';

  @override
  String get noPostsMatch => '필터와 일치하는 게시물이 없습니다.';

  @override
  String get noPostsMatchSub => '검색 조건을 조정해 보세요.';

  @override
  String get deleteDraftTitle => '초안을 삭제하시겠습니까?';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get draftDeletedSnack => '초안이 삭제되었습니다.';

  @override
  String get calendarTitle => '예약된 편집 캘린더';

  @override
  String get calendarEmptyTitle => '편집 대기열이 비어 있습니다';

  @override
  String get calendarEmptySub => '예약된 게시물이 없습니다.';

  @override
  String get registryTitle => '브랜드 및 채널 레지스트리';

  @override
  String get connectedWorkspaceTitle => '연결된 소셜 워크스페이스';

  @override
  String get connectedWorkspaceSub => '멀티 플랫폼 ID를 관리하고 원활하게 게시하세요.';

  @override
  String tabSocialChannels(int count) {
    return '소셜 채널 ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return '채널 그룹 ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return '회사 포트폴리오 ($count)';
  }

  @override
  String get noCompaniesTitle => '등록된 회사 없음';

  @override
  String get noCompaniesSub => '채널을 연결하려면 먼저 회사를 등록하세요.';

  @override
  String get noGroupsTitle => '채널 그룹 없음';

  @override
  String get noGroupsSub => '그룹을 사용하면 여러 프로필을 묶어 한 번에 게시할 수 있습니다!';

  @override
  String get noChannelsForBrand => '이 브랜드에 등록된 소셜 계정이 없습니다.';

  @override
  String get btnConnectBrandChannel => '+ 채널 연결';

  @override
  String get registerCompanyDialogTitle => '회사 / 브랜드 등록';

  @override
  String get companyNameLabel => '회사 / 브랜드 이름 *';

  @override
  String get companyNameHint => '예: Acme 주식회사';

  @override
  String get brandSlugLabel => '브랜드 슬러그 *';

  @override
  String get brandSlugHint => '예: acme-kr';

  @override
  String get brandDescLabel => '설명';

  @override
  String get brandDescHint => '회사 또는 브랜드에 대한 간단한 요약';

  @override
  String get websiteUrlLabel => '웹사이트 URL (선택사항)';

  @override
  String get connectChannelDialogTitle => '소셜 채널 연결';

  @override
  String get connectChannelDialogSub => '게시물을 예약하고 게시하기 위해 소셜 프로필을 연결하세요.';

  @override
  String get selectCompanyLabel => '관련 회사 / 브랜드 *';

  @override
  String get selectPlatformLabel => '소셜 네트워크 플랫폼 *';

  @override
  String get displayNameLabel => '표시 이름 *';

  @override
  String get displayNameHint => '예: Acme Tech Global';

  @override
  String get handleLabel => '핸들 / 사용자 ID *';

  @override
  String get handleHint => '예: @acme_official';

  @override
  String get disconnectConfirmTitle => '채널 연결 해제';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handle의 연결을 해제하시겠습니까? 기록은 유지됩니다.';
  }

  @override
  String get createGroupDialogTitle => '채널 그룹 만들기';

  @override
  String get createGroupDialogSub => '동일한 제품의 여러 계정을 묶어 한 번에 게시하세요.';

  @override
  String get groupNameLabel => '그룹 이름 *';

  @override
  String get groupNameHint => '예: Acme 글로벌 (IG + X)';

  @override
  String get groupDescLabel => '그룹 설명 (선택사항)';

  @override
  String get groupDescHint => '예: 글로벌 주요 마케팅 ID';

  @override
  String groupSelectChannels(int count) {
    return '묶을 채널 선택 ($count개 선택됨):';
  }

  @override
  String get composerTitle => '게시물 작성기';

  @override
  String get composerEditTitle => '게시물 편집';

  @override
  String get stepChannelsTitle => '1. 채널 및 그룹 선택';

  @override
  String get stepChannelsEmptyBrands => '등록된 회사가 없습니다.';

  @override
  String get stepChannelsEmptyAccounts => '연결된 채널이 없습니다.';

  @override
  String get brandIdentityLabel => '브랜드 / 회사 ID';

  @override
  String get quickSelectGroup => '채널 그룹으로 빠른 선택:';

  @override
  String get destinationProfiles => '대상 프로필:';

  @override
  String get stepPostDetails => '2. 게시물 세부 정보';

  @override
  String get postTitleLabel => '게시물 제목 *';

  @override
  String get postTitleHint => '내부 참조 이름...';

  @override
  String get campaignLabel => '캠페인 이름 (선택사항)';

  @override
  String get campaignHint => '예: 여름 출시 2026';

  @override
  String get tagsLabel => '태그 / 분류';

  @override
  String get tagsHint => '마케팅, 출시 (쉼표로 구분)';

  @override
  String get stepContentCopy => '3. 콘텐츠 및 캡션';

  @override
  String get sharedCaptionTab => '공유 (모든 네트워크)';

  @override
  String get captionLabel => '메인 캡션';

  @override
  String get captionHint => '핵심 메시지를 여기에 작성하세요...';

  @override
  String get sameCaptionToggle => '모든 네트워크에 동일한 캡션 사용';

  @override
  String get stepMediaAssets => '4. 첨부 미디어';

  @override
  String get stepMediaAssetsSub => '기존 미디어를 선택하거나 새 미디어를 추가하세요.';

  @override
  String get addMediaAssetBtn => '미디어 추가';

  @override
  String get livePreviewTitle => '라이브 미리보기';

  @override
  String get simulatedBadge => '시뮬레이션';

  @override
  String get previewEmptyPlaceholder => '미리보기를 위해 하나 이상의 채널을 선택하세요.';

  @override
  String get preflightRulesTitle => '사전 확인 규칙';

  @override
  String btnQueueForPublication(int count) {
    return '게시 대기열에 추가 ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return '지금 게시 ($count개 대상)';
  }

  @override
  String get draftSavedSnack => '초안이 저장되었습니다.';

  @override
  String get confirmPublishTitle => '다중 게시 확인';

  @override
  String confirmPublishMessage(int count) {
    return '$count개 계정에 게시할 준비가 되었습니까?';
  }

  @override
  String get settingsTitle => '워크스페이스 설정';

  @override
  String get settingsSubtitle => '기본 설정을 관리하고 감사 이벤트를 검사합니다.';

  @override
  String get dbManagementTitle => '데이터베이스 관리';

  @override
  String get dbManagementSub => '로컬 SQLite 레코드를 관리하거나 데모 데이터를 로드합니다.';

  @override
  String get wipeConfirmTitle => '삭제 확인';

  @override
  String get wipeConfirmMessage => '모든 데이터를 삭제하시겠습니까?';

  @override
  String get dbWipedSnack => '데이터베이스가 초기화되었습니다.';

  @override
  String get demoLoadedSnack => '데모 데이터가 로드되었습니다.';

  @override
  String get loginTitle => 'no5ocial에 오신 것을 환영합니다';

  @override
  String get loginSubtitle => '올인원 소셜 퍼블리싱 워크스페이스';

  @override
  String get loginWithGoogle => 'Google로 계속';

  @override
  String get loginDisclaimer => '계속하면 다음에 동의하는 것입니다';

  @override
  String get termsOfService => '서비스 약관';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get disclaimer => '면책 조항';

  @override
  String get loginLocalNote => '데이터는 이 기기에만 로컬로 저장됩니다.';

  @override
  String get andText => '및';
}
