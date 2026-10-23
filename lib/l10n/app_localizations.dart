import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'no5ocial'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Social Publishing & Scheduling Workspace'**
  String get appTagline;

  /// No description provided for @proWorkspace.
  ///
  /// In en, this message translates to:
  /// **'PRO WORKSPACE'**
  String get proWorkspace;

  /// No description provided for @navQueue.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navQueue;

  /// No description provided for @navContent.
  ///
  /// In en, this message translates to:
  /// **'Content Library'**
  String get navContent;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navCalendar;

  /// No description provided for @navChannels.
  ///
  /// In en, this message translates to:
  /// **'Connected Channels'**
  String get navChannels;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Workspace Settings'**
  String get navSettings;

  /// No description provided for @btnNewPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get btnNewPost;

  /// No description provided for @btnCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get btnCreatePost;

  /// No description provided for @btnComposePost.
  ///
  /// In en, this message translates to:
  /// **'Compose Post'**
  String get btnComposePost;

  /// No description provided for @btnQueuePost.
  ///
  /// In en, this message translates to:
  /// **'Queue Post'**
  String get btnQueuePost;

  /// No description provided for @btnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get btnSchedule;

  /// No description provided for @btnShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share Now'**
  String get btnShareNow;

  /// No description provided for @btnSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get btnSaveDraft;

  /// No description provided for @btnConnectChannel.
  ///
  /// In en, this message translates to:
  /// **'Connect Channel'**
  String get btnConnectChannel;

  /// No description provided for @btnCreateChannelGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Channel Group'**
  String get btnCreateChannelGroup;

  /// No description provided for @btnRegisterCompany.
  ///
  /// In en, this message translates to:
  /// **'Register Company'**
  String get btnRegisterCompany;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnClose;

  /// No description provided for @btnDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get btnDisconnect;

  /// No description provided for @btnSchedulePost.
  ///
  /// In en, this message translates to:
  /// **'Schedule a Post'**
  String get btnSchedulePost;

  /// No description provided for @btnConfirmWipe.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Wipe Data'**
  String get btnConfirmWipe;

  /// No description provided for @btnClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data & Start Fresh'**
  String get btnClearAllData;

  /// No description provided for @btnLoadDemoData.
  ///
  /// In en, this message translates to:
  /// **'Load Sample Demo Data'**
  String get btnLoadDemoData;

  /// No description provided for @consoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Publishing Operations Console'**
  String get consoleTitle;

  /// No description provided for @growthWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Growth Workspace'**
  String get growthWorkspace;

  /// No description provided for @selectTimezoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Publishing Timezone'**
  String get selectTimezoneTitle;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to: {language}'**
  String languageSetTo(String language);

  /// No description provided for @channelsActive.
  ///
  /// In en, this message translates to:
  /// **'{count} Channels Active'**
  String channelsActive(int count);

  /// No description provided for @channelsConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} Channels Connected'**
  String channelsConnected(int count);

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow Your Reach Across Every Social Network'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan, collaborate, and schedule engaging posts across Instagram, X, LinkedIn, and YouTube from one unified queue.'**
  String get heroSubtitle;

  /// No description provided for @actionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Action Required ({count} Destination Issues)'**
  String actionRequiredTitle(int count);

  /// No description provided for @actionRequiredSub.
  ///
  /// In en, this message translates to:
  /// **'One or more publishing destinations encountered a timeout or require manual handoff. Review and resolve below:'**
  String get actionRequiredSub;

  /// No description provided for @metricDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get metricDrafts;

  /// No description provided for @metricDraftsSub.
  ///
  /// In en, this message translates to:
  /// **'Ideas & in-progress'**
  String get metricDraftsSub;

  /// No description provided for @metricScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get metricScheduled;

  /// No description provided for @metricScheduledSub.
  ///
  /// In en, this message translates to:
  /// **'Next in queue'**
  String get metricScheduledSub;

  /// No description provided for @metricPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get metricPublished;

  /// No description provided for @metricPublishedSub.
  ///
  /// In en, this message translates to:
  /// **'Live on channels'**
  String get metricPublishedSub;

  /// No description provided for @metricNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get metricNeedsReview;

  /// No description provided for @metricNeedsReviewSub.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get metricNeedsReviewSub;

  /// No description provided for @queueSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Publishing Queue'**
  String get queueSectionTitle;

  /// No description provided for @queueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your publishing queue is empty'**
  String get queueEmptyTitle;

  /// No description provided for @queueEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan and queue upcoming posts to maintain a consistent social media presence across all your networks.'**
  String get queueEmptySubtitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Publishing Activity'**
  String get recentActivityTitle;

  /// No description provided for @recentActivitySub.
  ///
  /// In en, this message translates to:
  /// **'Execution audit log & real-time delivery status'**
  String get recentActivitySub;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No completed jobs yet. Published and verified posts will appear here.'**
  String get noRecentActivity;

  /// No description provided for @contentLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-Platform Content Library'**
  String get contentLibraryTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts, captions, campaigns, or tags...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All Posts'**
  String get filterAll;

  /// No description provided for @filterDraft.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get filterDraft;

  /// No description provided for @filterScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get filterScheduled;

  /// No description provided for @filterPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get filterPublished;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed / Blocked'**
  String get filterFailed;

  /// No description provided for @noPostsMatch.
  ///
  /// In en, this message translates to:
  /// **'No posts match your filters.'**
  String get noPostsMatch;

  /// No description provided for @noPostsMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting the search query or brand filter.'**
  String get noPostsMatchSub;

  /// No description provided for @deleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post Draft?'**
  String get deleteDraftTitle;

  /// No description provided for @deleteDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This will cancel associated jobs.'**
  String deleteDraftConfirm(String title);

  /// No description provided for @draftDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Post draft deleted.'**
  String get draftDeletedSnack;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Editorial Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Editorial queue is empty'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptySub.
  ///
  /// In en, this message translates to:
  /// **'No upcoming posts scheduled in your timezone.'**
  String get calendarEmptySub;

  /// No description provided for @registryTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand & Channel Registry'**
  String get registryTitle;

  /// No description provided for @connectedWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected Social Workspace'**
  String get connectedWorkspaceTitle;

  /// No description provided for @connectedWorkspaceSub.
  ///
  /// In en, this message translates to:
  /// **'Manage all your multi-platform identities, bundle same-product profiles into Groups, and publish seamlessly to Instagram, X (Twitter), LinkedIn, and YouTube.'**
  String get connectedWorkspaceSub;

  /// No description provided for @tabSocialChannels.
  ///
  /// In en, this message translates to:
  /// **'Social Channels ({count})'**
  String tabSocialChannels(int count);

  /// No description provided for @tabChannelGroups.
  ///
  /// In en, this message translates to:
  /// **'Channel Groups ({count})'**
  String tabChannelGroups(int count);

  /// No description provided for @tabCompanyPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Company Portfolio ({count})'**
  String tabCompanyPortfolio(int count);

  /// No description provided for @noCompaniesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Companies Registered Yet'**
  String get noCompaniesTitle;

  /// No description provided for @noCompaniesSub.
  ///
  /// In en, this message translates to:
  /// **'Get started by registering your company to connect social channels.'**
  String get noCompaniesSub;

  /// No description provided for @noGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Channel Groups Created Yet'**
  String get noGroupsTitle;

  /// No description provided for @noGroupsSub.
  ///
  /// In en, this message translates to:
  /// **'Groups let you bundle multiple social profiles for the same product to publish to all of them with a single click!'**
  String get noGroupsSub;

  /// No description provided for @noChannelsForBrand.
  ///
  /// In en, this message translates to:
  /// **'No social accounts registered for this brand yet.'**
  String get noChannelsForBrand;

  /// No description provided for @btnConnectBrandChannel.
  ///
  /// In en, this message translates to:
  /// **'+ Connect Channel'**
  String get btnConnectBrandChannel;

  /// No description provided for @registerCompanyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Company / Brand'**
  String get registerCompanyDialogTitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company / Brand Name *'**
  String get companyNameLabel;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Corporation or Nova Media'**
  String get companyNameHint;

  /// No description provided for @brandSlugLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand Slug *'**
  String get brandSlugLabel;

  /// No description provided for @brandSlugHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. acme-corp'**
  String get brandSlugHint;

  /// No description provided for @brandDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get brandDescLabel;

  /// No description provided for @brandDescHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of this company or brand'**
  String get brandDescHint;

  /// No description provided for @websiteUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Website URL (Optional)'**
  String get websiteUrlLabel;

  /// No description provided for @connectChannelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Social Channel'**
  String get connectChannelDialogTitle;

  /// No description provided for @connectChannelDialogSub.
  ///
  /// In en, this message translates to:
  /// **'Link a social profile across platforms to schedule and publish posts.'**
  String get connectChannelDialogSub;

  /// No description provided for @selectCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Associated Company / Brand *'**
  String get selectCompanyLabel;

  /// No description provided for @selectPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Social Network Platform *'**
  String get selectPlatformLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name *'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Tech Global'**
  String get displayNameHint;

  /// No description provided for @handleLabel.
  ///
  /// In en, this message translates to:
  /// **'Handle / User ID *'**
  String get handleLabel;

  /// No description provided for @handleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. @acme_official'**
  String get handleHint;

  /// No description provided for @disconnectConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Channel'**
  String get disconnectConfirmTitle;

  /// No description provided for @disconnectConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect {handle}? Historical posts referencing this channel will remain saved.'**
  String disconnectConfirmMessage(String handle);

  /// No description provided for @createGroupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Channel Group'**
  String get createGroupDialogTitle;

  /// No description provided for @createGroupDialogSub.
  ///
  /// In en, this message translates to:
  /// **'Bundle multiple social network accounts for the same product (e.g. Acme Instagram + Acme X) so you can publish to all at once.'**
  String get createGroupDialogSub;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name *'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Global Bundle (IG + X)'**
  String get groupNameHint;

  /// No description provided for @groupDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Description (Optional)'**
  String get groupDescLabel;

  /// No description provided for @groupDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Global primary marketing identities'**
  String get groupDescHint;

  /// No description provided for @groupSelectChannels.
  ///
  /// In en, this message translates to:
  /// **'Select Channels to Bundle ({count} selected):'**
  String groupSelectChannels(int count);

  /// No description provided for @composerTitle.
  ///
  /// In en, this message translates to:
  /// **'Commercial Post Composer'**
  String get composerTitle;

  /// No description provided for @composerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get composerEditTitle;

  /// No description provided for @stepChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Select Channels & Groups'**
  String get stepChannelsTitle;

  /// No description provided for @stepChannelsEmptyBrands.
  ///
  /// In en, this message translates to:
  /// **'No companies registered yet. Register a company in Connected Channels to organize profiles.'**
  String get stepChannelsEmptyBrands;

  /// No description provided for @stepChannelsEmptyAccounts.
  ///
  /// In en, this message translates to:
  /// **'No social channels connected yet. Go to Connected Channels to link Instagram, X, LinkedIn, or YouTube accounts.'**
  String get stepChannelsEmptyAccounts;

  /// No description provided for @brandIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand / Company Identity'**
  String get brandIdentityLabel;

  /// No description provided for @quickSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Quick-Select by Channel Group:'**
  String get quickSelectGroup;

  /// No description provided for @destinationProfiles.
  ///
  /// In en, this message translates to:
  /// **'Destination Profiles:'**
  String get destinationProfiles;

  /// No description provided for @stepPostDetails.
  ///
  /// In en, this message translates to:
  /// **'2. Post Details'**
  String get stepPostDetails;

  /// No description provided for @postTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Post Title *'**
  String get postTitleLabel;

  /// No description provided for @postTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Internal reference name for this campaign...'**
  String get postTitleHint;

  /// No description provided for @campaignLabel.
  ///
  /// In en, this message translates to:
  /// **'Campaign Name (Optional)'**
  String get campaignLabel;

  /// No description provided for @campaignHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Launch 2026'**
  String get campaignHint;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags / Categorization'**
  String get tagsLabel;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'marketing, launch, update (comma separated)'**
  String get tagsHint;

  /// No description provided for @stepContentCopy.
  ///
  /// In en, this message translates to:
  /// **'3. Content & Captions'**
  String get stepContentCopy;

  /// No description provided for @sharedCaptionTab.
  ///
  /// In en, this message translates to:
  /// **'Shared (All Networks)'**
  String get sharedCaptionTab;

  /// No description provided for @captionLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Post Caption'**
  String get captionLabel;

  /// No description provided for @captionHint.
  ///
  /// In en, this message translates to:
  /// **'Write your core post message here...'**
  String get captionHint;

  /// No description provided for @sameCaptionToggle.
  ///
  /// In en, this message translates to:
  /// **'Use Same Caption Across All Networks'**
  String get sameCaptionToggle;

  /// No description provided for @stepMediaAssets.
  ///
  /// In en, this message translates to:
  /// **'4. Attached Media Assets'**
  String get stepMediaAssets;

  /// No description provided for @stepMediaAssetsSub.
  ///
  /// In en, this message translates to:
  /// **'Select existing assets from your library or click \"Add Media Asset\" to link new images/videos.'**
  String get stepMediaAssetsSub;

  /// No description provided for @addMediaAssetBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Media Asset'**
  String get addMediaAssetBtn;

  /// No description provided for @livePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Social Media Preview'**
  String get livePreviewTitle;

  /// No description provided for @simulatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get simulatedBadge;

  /// No description provided for @previewEmptyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select at least one destination channel to preview mockup.'**
  String get previewEmptyPlaceholder;

  /// No description provided for @preflightRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preflight Rules'**
  String get preflightRulesTitle;

  /// No description provided for @btnQueueForPublication.
  ///
  /// In en, this message translates to:
  /// **'Queue for Publication ({count})'**
  String btnQueueForPublication(int count);

  /// No description provided for @btnPublishNow.
  ///
  /// In en, this message translates to:
  /// **'Publish Now ({count} Targets)'**
  String btnPublishNow(int count);

  /// No description provided for @draftSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Draft saved to library.'**
  String get draftSavedSnack;

  /// No description provided for @confirmPublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Multi-Destination Publish'**
  String get confirmPublishTitle;

  /// No description provided for @confirmPublishMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to publish to {count} destination account(s)? Each account will be published independently.'**
  String confirmPublishMessage(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage workspace preferences, activity history, and workspace settings.'**
  String get settingsSubtitle;

  /// No description provided for @dbManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dbManagementTitle;

  /// No description provided for @dbManagementSub.
  ///
  /// In en, this message translates to:
  /// **'Manage local application data and reset workspace state.'**
  String get dbManagementSub;

  /// No description provided for @wipeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Workspace Data'**
  String get wipeConfirmTitle;

  /// No description provided for @wipeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all data? This will clear all registered brands, connected accounts, drafts, and scheduled posts on this device.'**
  String get wipeConfirmMessage;

  /// No description provided for @dbWipedSnack.
  ///
  /// In en, this message translates to:
  /// **'Workspace data reset successfully.'**
  String get dbWipedSnack;

  /// No description provided for @demoLoadedSnack.
  ///
  /// In en, this message translates to:
  /// **'Sample workspace data loaded.'**
  String get demoLoadedSnack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to no5ocial'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your all-in-one social publishing workspace'**
  String get loginSubtitle;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get loginDisclaimer;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @loginLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored locally on this device only.'**
  String get loginLocalNote;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'da',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'nl',
    'pl',
    'pt',
    'ru',
    'sv',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
