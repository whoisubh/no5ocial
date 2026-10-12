// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Social Publishing & Scheduling Workspace';

  @override
  String get proWorkspace => 'PRO WORKSPACE';

  @override
  String get navQueue => 'Overview';

  @override
  String get navContent => 'Content Library';

  @override
  String get navCalendar => 'Schedule';

  @override
  String get navChannels => 'Connected Channels';

  @override
  String get navSettings => 'Workspace Settings';

  @override
  String get btnNewPost => 'New Post';

  @override
  String get btnCreatePost => 'Create Post';

  @override
  String get btnComposePost => 'Compose Post';

  @override
  String get btnQueuePost => 'Queue Post';

  @override
  String get btnSchedule => 'Schedule';

  @override
  String get btnShareNow => 'Share Now';

  @override
  String get btnSaveDraft => 'Save as Draft';

  @override
  String get btnConnectChannel => 'Connect Channel';

  @override
  String get btnCreateChannelGroup => 'Create Channel Group';

  @override
  String get btnRegisterCompany => 'Register Company';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnSave => 'Save';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnClose => 'Close';

  @override
  String get btnDisconnect => 'Disconnect';

  @override
  String get btnSchedulePost => 'Schedule a Post';

  @override
  String get btnConfirmWipe => 'Confirm & Wipe Data';

  @override
  String get btnClearAllData => 'Clear All Data & Start Fresh';

  @override
  String get btnLoadDemoData => 'Load Sample Demo Data';

  @override
  String get consoleTitle => 'Publishing Operations Console';

  @override
  String get growthWorkspace => 'Growth Workspace';

  @override
  String get selectTimezoneTitle => 'Select Publishing Timezone';

  @override
  String languageSetTo(String language) {
    return 'Language set to: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Channels Active';
  }

  @override
  String channelsConnected(int count) {
    return '$count Channels Connected';
  }

  @override
  String get heroTitle => 'Grow Your Reach Across Every Social Network';

  @override
  String get heroSubtitle =>
      'Plan, collaborate, and schedule engaging posts across Instagram, X, LinkedIn, and YouTube from one unified queue.';

  @override
  String actionRequiredTitle(int count) {
    return 'Action Required ($count Destination Issues)';
  }

  @override
  String get actionRequiredSub =>
      'One or more publishing destinations encountered a timeout or require manual handoff. Review and resolve below:';

  @override
  String get metricDrafts => 'Drafts';

  @override
  String get metricDraftsSub => 'Ideas & in-progress';

  @override
  String get metricScheduled => 'Scheduled';

  @override
  String get metricScheduledSub => 'Next in queue';

  @override
  String get metricPublished => 'Published';

  @override
  String get metricPublishedSub => 'Live on channels';

  @override
  String get metricNeedsReview => 'Needs Review';

  @override
  String get metricNeedsReviewSub => 'Action required';

  @override
  String get queueSectionTitle => 'Upcoming Publishing Queue';

  @override
  String get queueEmptyTitle => 'Your publishing queue is empty';

  @override
  String get queueEmptySubtitle =>
      'Plan and queue upcoming posts to maintain a consistent social media presence across all your networks.';

  @override
  String get recentActivityTitle => 'Recent Publishing Activity';

  @override
  String get recentActivitySub =>
      'Execution audit log & real-time delivery status';

  @override
  String get noRecentActivity =>
      'No completed jobs yet. Published and verified posts will appear here.';

  @override
  String get contentLibraryTitle => 'Multi-Platform Content Library';

  @override
  String get searchHint => 'Search posts, captions, campaigns, or tags...';

  @override
  String get filterAll => 'All Posts';

  @override
  String get filterDraft => 'Drafts';

  @override
  String get filterScheduled => 'Scheduled';

  @override
  String get filterPublished => 'Published';

  @override
  String get filterFailed => 'Failed / Blocked';

  @override
  String get noPostsMatch => 'No posts match your filters.';

  @override
  String get noPostsMatchSub =>
      'Try adjusting the search query or brand filter.';

  @override
  String get deleteDraftTitle => 'Delete Post Draft?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This will cancel associated jobs.';
  }

  @override
  String get draftDeletedSnack => 'Post draft deleted.';

  @override
  String get calendarTitle => 'Scheduled Editorial Calendar';

  @override
  String get calendarEmptyTitle => 'Editorial queue is empty';

  @override
  String get calendarEmptySub =>
      'No upcoming posts scheduled in your timezone.';

  @override
  String get registryTitle => 'Brand & Channel Registry';

  @override
  String get connectedWorkspaceTitle => 'Connected Social Workspace';

  @override
  String get connectedWorkspaceSub =>
      'Manage all your multi-platform identities, bundle same-product profiles into Groups, and publish seamlessly to Instagram, X (Twitter), LinkedIn, and YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Social Channels ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Channel Groups ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Company Portfolio ($count)';
  }

  @override
  String get noCompaniesTitle => 'No Companies Registered Yet';

  @override
  String get noCompaniesSub =>
      'Get started by registering your company to connect social channels.';

  @override
  String get noGroupsTitle => 'No Channel Groups Created Yet';

  @override
  String get noGroupsSub =>
      'Groups let you bundle multiple social profiles for the same product to publish to all of them with a single click!';

  @override
  String get noChannelsForBrand =>
      'No social accounts registered for this brand yet.';

  @override
  String get btnConnectBrandChannel => '+ Connect Channel';

  @override
  String get registerCompanyDialogTitle => 'Register Company / Brand';

  @override
  String get companyNameLabel => 'Company / Brand Name *';

  @override
  String get companyNameHint => 'e.g. Acme Corporation or Nova Media';

  @override
  String get brandSlugLabel => 'Brand Slug *';

  @override
  String get brandSlugHint => 'e.g. acme-corp';

  @override
  String get brandDescLabel => 'Description';

  @override
  String get brandDescHint => 'Short summary of this company or brand';

  @override
  String get websiteUrlLabel => 'Website URL (Optional)';

  @override
  String get connectChannelDialogTitle => 'Connect Social Channel';

  @override
  String get connectChannelDialogSub =>
      'Link a social profile across platforms to schedule and publish posts.';

  @override
  String get selectCompanyLabel => 'Associated Company / Brand *';

  @override
  String get selectPlatformLabel => 'Social Network Platform *';

  @override
  String get displayNameLabel => 'Display Name *';

  @override
  String get displayNameHint => 'e.g. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / User ID *';

  @override
  String get handleHint => 'e.g. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Disconnect Channel';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Are you sure you want to disconnect $handle? Historical posts referencing this channel will remain saved.';
  }

  @override
  String get createGroupDialogTitle => 'Create Channel Group';

  @override
  String get createGroupDialogSub =>
      'Bundle multiple social network accounts for the same product (e.g. Acme Instagram + Acme X) so you can publish to all at once.';

  @override
  String get groupNameLabel => 'Group Name *';

  @override
  String get groupNameHint => 'e.g. Acme Global Bundle (IG + X)';

  @override
  String get groupDescLabel => 'Group Description (Optional)';

  @override
  String get groupDescHint => 'e.g. Global primary marketing identities';

  @override
  String groupSelectChannels(int count) {
    return 'Select Channels to Bundle ($count selected):';
  }

  @override
  String get composerTitle => 'Commercial Post Composer';

  @override
  String get composerEditTitle => 'Edit Post';

  @override
  String get stepChannelsTitle => '1. Select Channels & Groups';

  @override
  String get stepChannelsEmptyBrands =>
      'No companies registered yet. Register a company in Connected Channels to organize profiles.';

  @override
  String get stepChannelsEmptyAccounts =>
      'No social channels connected yet. Go to Connected Channels to link Instagram, X, LinkedIn, or YouTube accounts.';

  @override
  String get brandIdentityLabel => 'Brand / Company Identity';

  @override
  String get quickSelectGroup => 'Quick-Select by Channel Group:';

  @override
  String get destinationProfiles => 'Destination Profiles:';

  @override
  String get stepPostDetails => '2. Post Details';

  @override
  String get postTitleLabel => 'Post Title *';

  @override
  String get postTitleHint => 'Internal reference name for this campaign...';

  @override
  String get campaignLabel => 'Campaign Name (Optional)';

  @override
  String get campaignHint => 'e.g. Summer Launch 2026';

  @override
  String get tagsLabel => 'Tags / Categorization';

  @override
  String get tagsHint => 'marketing, launch, update (comma separated)';

  @override
  String get stepContentCopy => '3. Content & Captions';

  @override
  String get sharedCaptionTab => 'Shared (All Networks)';

  @override
  String get captionLabel => 'Main Post Caption';

  @override
  String get captionHint => 'Write your core post message here...';

  @override
  String get sameCaptionToggle => 'Use Same Caption Across All Networks';

  @override
  String get stepMediaAssets => '4. Attached Media Assets';

  @override
  String get stepMediaAssetsSub =>
      'Select existing assets from your library or click \"Add Media Asset\" to link new images/videos.';

  @override
  String get addMediaAssetBtn => 'Add Media Asset';

  @override
  String get livePreviewTitle => 'Live Social Media Preview';

  @override
  String get simulatedBadge => 'Simulated';

  @override
  String get previewEmptyPlaceholder =>
      'Select at least one destination channel to preview mockup.';

  @override
  String get preflightRulesTitle => 'Preflight Rules';

  @override
  String btnQueueForPublication(int count) {
    return 'Queue for Publication ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publish Now ($count Targets)';
  }

  @override
  String get draftSavedSnack => 'Draft saved to library.';

  @override
  String get confirmPublishTitle => 'Confirm Multi-Destination Publish';

  @override
  String confirmPublishMessage(int count) {
    return 'Are you ready to publish to $count destination account(s)? Each account will be published independently.';
  }

  @override
  String get settingsTitle => 'Workspace Settings';

  @override
  String get settingsSubtitle =>
      'Manage workspace preferences, inspect audit events, and configure workspace settings.';

  @override
  String get dbManagementTitle => 'Database & Workspace Management';

  @override
  String get dbManagementSub =>
      'Manage local SQLite database records, reset workspace state, or load demonstration data.';

  @override
  String get wipeConfirmTitle => 'Confirm Database Wipe';

  @override
  String get wipeConfirmMessage =>
      'Are you sure you want to delete ALL data? This will clear all registered brands, connected accounts, groups, drafts, and queue jobs from local SQLite.';

  @override
  String get dbWipedSnack =>
      'Workspace database reset to clean state (0 records).';

  @override
  String get demoLoadedSnack =>
      'Sample demo brands, accounts, and groups loaded into SQLite.';

  @override
  String get loginTitle => 'Welcome to no5ocial';

  @override
  String get loginSubtitle => 'Your all-in-one social publishing workspace';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginDisclaimer => 'By continuing, you agree to our';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get loginLocalNote =>
      'Your data is stored locally on this device only.';

  @override
  String get andText => 'and';
}
