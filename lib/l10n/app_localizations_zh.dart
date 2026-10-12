// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => '社交媒体发布和排期工作区';

  @override
  String get proWorkspace => '专业版';

  @override
  String get navQueue => '发布队列';

  @override
  String get navContent => '内容库';

  @override
  String get navCalendar => '编辑日历';

  @override
  String get navChannels => '已连接频道';

  @override
  String get navSettings => '设置';

  @override
  String get btnNewPost => '新建帖子';

  @override
  String get btnCreatePost => '创建帖子';

  @override
  String get btnComposePost => '撰写帖子';

  @override
  String get btnQueuePost => '加入队列';

  @override
  String get btnSchedule => '排期';

  @override
  String get btnShareNow => '立即分享';

  @override
  String get btnSaveDraft => '保存草稿';

  @override
  String get btnConnectChannel => '连接频道';

  @override
  String get btnCreateChannelGroup => '创建频道组';

  @override
  String get btnRegisterCompany => '注册公司';

  @override
  String get btnCancel => '取消';

  @override
  String get btnSave => '保存';

  @override
  String get btnConfirm => '确认';

  @override
  String get btnDelete => '删除';

  @override
  String get btnClose => '关闭';

  @override
  String get btnDisconnect => '断开连接';

  @override
  String get btnSchedulePost => '排期帖子';

  @override
  String get btnConfirmWipe => '确认并清除数据';

  @override
  String get btnClearAllData => '清除所有数据';

  @override
  String get btnLoadDemoData => '加载演示数据';

  @override
  String get consoleTitle => '发布运营控制台';

  @override
  String get growthWorkspace => '增长工作区';

  @override
  String get selectTimezoneTitle => '选择时区';

  @override
  String languageSetTo(String language) {
    return '语言已设置为：$language';
  }

  @override
  String channelsActive(int count) {
    return '$count个频道活跃';
  }

  @override
  String channelsConnected(int count) {
    return '$count个频道已连接';
  }

  @override
  String get heroTitle => '扩展您在所有社交网络上的影响力';

  @override
  String get heroSubtitle => '从统一队列规划和发布Instagram、X、LinkedIn和YouTube内容。';

  @override
  String actionRequiredTitle(int count) {
    return '需要操作（$count个问题）';
  }

  @override
  String get actionRequiredSub => '一个或多个发布目标需要手动处理。';

  @override
  String get metricDrafts => '草稿';

  @override
  String get metricDraftsSub => '进行中的想法';

  @override
  String get metricScheduled => '已排期';

  @override
  String get metricScheduledSub => '队列中的下一个';

  @override
  String get metricPublished => '已发布';

  @override
  String get metricPublishedSub => '频道直播';

  @override
  String get metricNeedsReview => '需要审核';

  @override
  String get metricNeedsReviewSub => '需要操作';

  @override
  String get queueSectionTitle => '即将发布的队列';

  @override
  String get queueEmptyTitle => '您的发布队列为空';

  @override
  String get queueEmptySubtitle => '规划并排期帖子以保持持续的社交媒体存在。';

  @override
  String get recentActivityTitle => '最近活动';

  @override
  String get recentActivitySub => '审计日志和实时发送状态';

  @override
  String get noRecentActivity => '暂无已完成的任务。';

  @override
  String get contentLibraryTitle => '多平台内容库';

  @override
  String get searchHint => '搜索帖子、活动或标签...';

  @override
  String get filterAll => '全部';

  @override
  String get filterDraft => '草稿';

  @override
  String get filterScheduled => '已排期';

  @override
  String get filterPublished => '已发布';

  @override
  String get filterFailed => '失败 / 被阻止';

  @override
  String get noPostsMatch => '没有匹配筛选条件的帖子。';

  @override
  String get noPostsMatchSub => '尝试调整搜索条件。';

  @override
  String get deleteDraftTitle => '删除草稿？';

  @override
  String deleteDraftConfirm(String title) {
    return '删除\"$title\"？';
  }

  @override
  String get draftDeletedSnack => '草稿已删除。';

  @override
  String get calendarTitle => '已排期编辑日历';

  @override
  String get calendarEmptyTitle => '编辑队列为空';

  @override
  String get calendarEmptySub => '没有已排期的帖子。';

  @override
  String get registryTitle => '品牌和频道注册';

  @override
  String get connectedWorkspaceTitle => '已连接社交工作区';

  @override
  String get connectedWorkspaceSub => '管理多平台身份并无缝发布。';

  @override
  String tabSocialChannels(int count) {
    return '社交频道 ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return '频道组 ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return '公司组合 ($count)';
  }

  @override
  String get noCompaniesTitle => '尚未注册公司';

  @override
  String get noCompaniesSub => '开始注册您的公司以连接社交频道。';

  @override
  String get noGroupsTitle => '尚无频道组';

  @override
  String get noGroupsSub => '组允许您捆绑多个配置文件以一键发布到所有配置文件！';

  @override
  String get noChannelsForBrand => '此品牌尚无社交账户。';

  @override
  String get btnConnectBrandChannel => '+ 连接频道';

  @override
  String get registerCompanyDialogTitle => '注册公司 / 品牌';

  @override
  String get companyNameLabel => '公司 / 品牌名称 *';

  @override
  String get companyNameHint => '例如：Acme公司';

  @override
  String get brandSlugLabel => '品牌标识符 *';

  @override
  String get brandSlugHint => '例如：acme-corp';

  @override
  String get brandDescLabel => '描述';

  @override
  String get brandDescHint => '公司或品牌的简短描述';

  @override
  String get websiteUrlLabel => '网站URL（可选）';

  @override
  String get connectChannelDialogTitle => '连接社交频道';

  @override
  String get connectChannelDialogSub => '链接社交资料以排期和发布帖子。';

  @override
  String get selectCompanyLabel => '关联公司 / 品牌 *';

  @override
  String get selectPlatformLabel => '社交网络平台 *';

  @override
  String get displayNameLabel => '显示名称 *';

  @override
  String get displayNameHint => '例如：Acme科技全球';

  @override
  String get handleLabel => '句柄 / 用户ID *';

  @override
  String get handleHint => '例如：@acme_official';

  @override
  String get disconnectConfirmTitle => '断开频道连接';

  @override
  String disconnectConfirmMessage(String handle) {
    return '断开$handle？历史记录将保留。';
  }

  @override
  String get createGroupDialogTitle => '创建频道组';

  @override
  String get createGroupDialogSub => '捆绑同一产品的多个账户以一次性发布。';

  @override
  String get groupNameLabel => '组名称 *';

  @override
  String get groupNameHint => '例如：Acme全球 (IG + X)';

  @override
  String get groupDescLabel => '组描述（可选）';

  @override
  String get groupDescHint => '例如：全球主要营销身份';

  @override
  String groupSelectChannels(int count) {
    return '选择要捆绑的频道（已选$count）:';
  }

  @override
  String get composerTitle => '帖子编辑器';

  @override
  String get composerEditTitle => '编辑帖子';

  @override
  String get stepChannelsTitle => '1. 选择频道和组';

  @override
  String get stepChannelsEmptyBrands => '尚未注册公司。';

  @override
  String get stepChannelsEmptyAccounts => '尚未连接频道。';

  @override
  String get brandIdentityLabel => '品牌 / 公司身份';

  @override
  String get quickSelectGroup => '按频道组快速选择：';

  @override
  String get destinationProfiles => '目标配置文件：';

  @override
  String get stepPostDetails => '2. 帖子详情';

  @override
  String get postTitleLabel => '帖子标题 *';

  @override
  String get postTitleHint => '内部参考名称...';

  @override
  String get campaignLabel => '活动名称（可选）';

  @override
  String get campaignHint => '例如：夏季发布2026';

  @override
  String get tagsLabel => '标签 / 分类';

  @override
  String get tagsHint => '营销，发布（逗号分隔）';

  @override
  String get stepContentCopy => '3. 内容和说明';

  @override
  String get sharedCaptionTab => '共享（所有网络）';

  @override
  String get captionLabel => '主要说明';

  @override
  String get captionHint => '在此处写下您的核心信息...';

  @override
  String get sameCaptionToggle => '在所有网络使用相同说明';

  @override
  String get stepMediaAssets => '4. 附加媒体';

  @override
  String get stepMediaAssetsSub => '选择现有媒体或添加新媒体。';

  @override
  String get addMediaAssetBtn => '添加媒体';

  @override
  String get livePreviewTitle => '实时预览';

  @override
  String get simulatedBadge => '模拟';

  @override
  String get previewEmptyPlaceholder => '请至少选择一个目标频道以预览。';

  @override
  String get preflightRulesTitle => '预检规则';

  @override
  String btnQueueForPublication(int count) {
    return '加入发布队列 ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return '立即发布 ($count个目标)';
  }

  @override
  String get draftSavedSnack => '草稿已保存。';

  @override
  String get confirmPublishTitle => '确认多目标发布';

  @override
  String confirmPublishMessage(int count) {
    return '准备好向$count个账户发布了吗？';
  }

  @override
  String get settingsTitle => '工作区设置';

  @override
  String get settingsSubtitle => '管理偏好设置和检查审计事件。';

  @override
  String get dbManagementTitle => '数据库管理';

  @override
  String get dbManagementSub => '管理本地SQLite记录或加载演示数据。';

  @override
  String get wipeConfirmTitle => '确认清除';

  @override
  String get wipeConfirmMessage => '删除所有数据？';

  @override
  String get dbWipedSnack => '数据库已重置。';

  @override
  String get demoLoadedSnack => '演示数据已加载。';

  @override
  String get loginTitle => '欢迎使用no5ocial';

  @override
  String get loginSubtitle => '您的一体化社交发布工作区';

  @override
  String get loginWithGoogle => '使用Google继续';

  @override
  String get loginDisclaimer => '继续即表示您同意我们的';

  @override
  String get termsOfService => '服务条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get disclaimer => '免责声明';

  @override
  String get loginLocalNote => '您的数据仅存储在此设备上。';

  @override
  String get andText => '和';
}
