// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'सोशल पब्लिशिंग और शेड्यूलिंग वर्कस्पेस';

  @override
  String get proWorkspace => 'प्रो प्लान';

  @override
  String get navQueue => 'प्रकाशन कतार';

  @override
  String get navContent => 'सामग्री पुस्तकालय';

  @override
  String get navCalendar => 'संपादकीय कैलेंडर';

  @override
  String get navChannels => 'जुड़े हुए चैनल';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get btnNewPost => 'नई पोस्ट';

  @override
  String get btnCreatePost => 'पोस्ट बनाएं';

  @override
  String get btnComposePost => 'पोस्ट लिखें';

  @override
  String get btnQueuePost => 'कतार में जोड़ें';

  @override
  String get btnSchedule => 'शेड्यूल करें';

  @override
  String get btnShareNow => 'अभी शेयर करें';

  @override
  String get btnSaveDraft => 'ड्राफ्ट सेव करें';

  @override
  String get btnConnectChannel => 'चैनल जोड़ें';

  @override
  String get btnCreateChannelGroup => 'चैनल समूह बनाएं';

  @override
  String get btnRegisterCompany => 'कंपनी पंजीकृत करें';

  @override
  String get btnCancel => 'रद्द करें';

  @override
  String get btnSave => 'सेव करें';

  @override
  String get btnConfirm => 'पुष्टि करें';

  @override
  String get btnDelete => 'हटाएं';

  @override
  String get btnClose => 'बंद करें';

  @override
  String get btnDisconnect => 'डिस्कनेक्ट करें';

  @override
  String get btnSchedulePost => 'पोस्ट शेड्यूल करें';

  @override
  String get btnConfirmWipe => 'पुष्टि करें और डेटा मिटाएं';

  @override
  String get btnClearAllData => 'सभी डेटा हटाएं';

  @override
  String get btnLoadDemoData => 'डेमो डेटा लोड करें';

  @override
  String get consoleTitle => 'प्रकाशन संचालन कंसोल';

  @override
  String get growthWorkspace => 'ग्रोथ वर्कस्पेस';

  @override
  String get selectTimezoneTitle => 'टाइमज़ोन चुनें';

  @override
  String languageSetTo(String language) {
    return 'भाषा $language पर सेट की गई';
  }

  @override
  String channelsActive(int count) {
    return '$count चैनल सक्रिय';
  }

  @override
  String channelsConnected(int count) {
    return '$count चैनल जुड़े हुए';
  }

  @override
  String get heroTitle => 'सभी सोशल नेटवर्क पर अपनी पहुंच बढ़ाएं';

  @override
  String get heroSubtitle =>
      'एक एकीकृत कतार से Instagram, X, LinkedIn और YouTube पर पोस्ट करें।';

  @override
  String actionRequiredTitle(int count) {
    return 'कार्रवाई आवश्यक ($count समस्याएं)';
  }

  @override
  String get actionRequiredSub =>
      'एक या अधिक गंतव्यों को मैन्युअल हस्तक्षेप की आवश्यकता है।';

  @override
  String get metricDrafts => 'ड्राफ्ट';

  @override
  String get metricDraftsSub => 'प्रगति में विचार';

  @override
  String get metricScheduled => 'शेड्यूल्ड';

  @override
  String get metricScheduledSub => 'अगला कतार में';

  @override
  String get metricPublished => 'प्रकाशित';

  @override
  String get metricPublishedSub => 'चैनलों पर लाइव';

  @override
  String get metricNeedsReview => 'समीक्षा आवश्यक';

  @override
  String get metricNeedsReviewSub => 'कार्रवाई आवश्यक';

  @override
  String get queueSectionTitle => 'आगामी प्रकाशन कतार';

  @override
  String get queueEmptyTitle => 'आपकी प्रकाशन कतार खाली है';

  @override
  String get queueEmptySubtitle =>
      'निरंतर सोशल मीडिया उपस्थिति के लिए पोस्ट कतार में जोड़ें।';

  @override
  String get recentActivityTitle => 'हालिया गतिविधि';

  @override
  String get recentActivitySub => 'ऑडिट लॉग और रीयल-टाइम डिलीवरी स्थिति';

  @override
  String get noRecentActivity => 'अभी तक कोई पूर्ण कार्य नहीं।';

  @override
  String get contentLibraryTitle => 'मल्टी-प्लेटफ़ॉर्म कंटेंट लाइब्रेरी';

  @override
  String get searchHint => 'पोस्ट, अभियान या टैग खोजें...';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterDraft => 'ड्राफ्ट';

  @override
  String get filterScheduled => 'शेड्यूल्ड';

  @override
  String get filterPublished => 'प्रकाशित';

  @override
  String get filterFailed => 'विफल / अवरुद्ध';

  @override
  String get noPostsMatch => 'फ़िल्टर से मेल खाने वाली कोई पोस्ट नहीं।';

  @override
  String get noPostsMatchSub => 'खोज मानदंड समायोजित करें।';

  @override
  String get deleteDraftTitle => 'ड्राफ्ट हटाएं?';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\" हटाएं?';
  }

  @override
  String get draftDeletedSnack => 'ड्राफ्ट हटाया गया।';

  @override
  String get calendarTitle => 'शेड्यूल्ड संपादकीय कैलेंडर';

  @override
  String get calendarEmptyTitle => 'संपादकीय कतार खाली है';

  @override
  String get calendarEmptySub => 'कोई शेड्यूल्ड पोस्ट नहीं।';

  @override
  String get registryTitle => 'ब्रांड और चैनल रजिस्ट्री';

  @override
  String get connectedWorkspaceTitle => 'जुड़ा हुआ सोशल वर्कस्पेस';

  @override
  String get connectedWorkspaceSub =>
      'अपनी मल्टी-प्लेटफ़ॉर्म पहचान प्रबंधित करें और बेरोकटोक प्रकाशित करें।';

  @override
  String tabSocialChannels(int count) {
    return 'सोशल चैनल ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'चैनल समूह ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'कंपनी पोर्टफोलियो ($count)';
  }

  @override
  String get noCompaniesTitle => 'कोई कंपनी पंजीकृत नहीं';

  @override
  String get noCompaniesSub =>
      'चैनल जोड़ने के लिए पहले अपनी कंपनी पंजीकृत करें।';

  @override
  String get noGroupsTitle => 'कोई चैनल समूह नहीं';

  @override
  String get noGroupsSub =>
      'समूह आपको एक बार में कई प्रोफ़ाइल पर पोस्ट करने देते हैं!';

  @override
  String get noChannelsForBrand => 'इस ब्रांड के लिए कोई सोशल अकाउंट नहीं।';

  @override
  String get btnConnectBrandChannel => '+ चैनल जोड़ें';

  @override
  String get registerCompanyDialogTitle => 'कंपनी / ब्रांड पंजीकृत करें';

  @override
  String get companyNameLabel => 'कंपनी / ब्रांड का नाम *';

  @override
  String get companyNameHint => 'उदा. Acme कॉर्पोरेशन';

  @override
  String get brandSlugLabel => 'ब्रांड स्लग *';

  @override
  String get brandSlugHint => 'उदा. acme-corp';

  @override
  String get brandDescLabel => 'विवरण';

  @override
  String get brandDescHint => 'कंपनी या ब्रांड का संक्षिप्त सारांश';

  @override
  String get websiteUrlLabel => 'वेबसाइट URL (वैकल्पिक)';

  @override
  String get connectChannelDialogTitle => 'सोशल चैनल जोड़ें';

  @override
  String get connectChannelDialogSub =>
      'पोस्ट शेड्यूल करने के लिए सोशल प्रोफ़ाइल लिंक करें।';

  @override
  String get selectCompanyLabel => 'संबद्ध कंपनी / ब्रांड *';

  @override
  String get selectPlatformLabel => 'सोशल नेटवर्क प्लेटफ़ॉर्म *';

  @override
  String get displayNameLabel => 'प्रदर्शन नाम *';

  @override
  String get displayNameHint => 'उदा. Acme Tech Global';

  @override
  String get handleLabel => 'हैंडल / यूज़र आईडी *';

  @override
  String get handleHint => 'उदा. @acme_official';

  @override
  String get disconnectConfirmTitle => 'चैनल डिस्कनेक्ट करें';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handle डिस्कनेक्ट करें? इतिहास सुरक्षित रहेगा।';
  }

  @override
  String get createGroupDialogTitle => 'चैनल समूह बनाएं';

  @override
  String get createGroupDialogSub =>
      'एक साथ प्रकाशित करने के लिए एक ही उत्पाद के कई अकाउंट जोड़ें।';

  @override
  String get groupNameLabel => 'समूह का नाम *';

  @override
  String get groupNameHint => 'उदा. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'समूह विवरण (वैकल्पिक)';

  @override
  String get groupDescHint => 'उदा. वैश्विक प्राथमिक मार्केटिंग पहचान';

  @override
  String groupSelectChannels(int count) {
    return 'बंडल करने के लिए चैनल चुनें ($count चुने):';
  }

  @override
  String get composerTitle => 'पोस्ट कंपोज़र';

  @override
  String get composerEditTitle => 'पोस्ट संपादित करें';

  @override
  String get stepChannelsTitle => '1. चैनल और समूह चुनें';

  @override
  String get stepChannelsEmptyBrands => 'कोई कंपनी पंजीकृत नहीं।';

  @override
  String get stepChannelsEmptyAccounts => 'कोई चैनल जुड़ा नहीं।';

  @override
  String get brandIdentityLabel => 'ब्रांड / कंपनी पहचान';

  @override
  String get quickSelectGroup => 'चैनल समूह द्वारा त्वरित चयन:';

  @override
  String get destinationProfiles => 'गंतव्य प्रोफ़ाइल:';

  @override
  String get stepPostDetails => '2. पोस्ट विवरण';

  @override
  String get postTitleLabel => 'पोस्ट शीर्षक *';

  @override
  String get postTitleHint => 'आंतरिक संदर्भ नाम...';

  @override
  String get campaignLabel => 'अभियान नाम (वैकल्पिक)';

  @override
  String get campaignHint => 'उदा. समर लॉन्च 2026';

  @override
  String get tagsLabel => 'टैग / वर्गीकरण';

  @override
  String get tagsHint => 'मार्केटिंग, लॉन्च (अल्पविराम से अलग)';

  @override
  String get stepContentCopy => '3. सामग्री और कैप्शन';

  @override
  String get sharedCaptionTab => 'साझा (सभी नेटवर्क)';

  @override
  String get captionLabel => 'मुख्य कैप्शन';

  @override
  String get captionHint => 'अपना मुख्य संदेश यहाँ लिखें...';

  @override
  String get sameCaptionToggle => 'सभी नेटवर्क पर एक ही कैप्शन उपयोग करें';

  @override
  String get stepMediaAssets => '4. संलग्न मीडिया';

  @override
  String get stepMediaAssetsSub => 'मौजूदा मीडिया चुनें या नया जोड़ें।';

  @override
  String get addMediaAssetBtn => 'मीडिया जोड़ें';

  @override
  String get livePreviewTitle => 'लाइव प्रीव्यू';

  @override
  String get simulatedBadge => 'सिमुलेटेड';

  @override
  String get previewEmptyPlaceholder =>
      'प्रीव्यू के लिए कम से कम एक चैनल चुनें।';

  @override
  String get preflightRulesTitle => 'प्रीफ्लाइट नियम';

  @override
  String btnQueueForPublication(int count) {
    return 'प्रकाशन कतार में जोड़ें ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'अभी प्रकाशित करें ($count लक्ष्य)';
  }

  @override
  String get draftSavedSnack => 'ड्राफ्ट सेव हो गया।';

  @override
  String get confirmPublishTitle => 'मल्टी-डेस्टिनेशन प्रकाशन की पुष्टि करें';

  @override
  String confirmPublishMessage(int count) {
    return '$count अकाउंट पर प्रकाशित करने के लिए तैयार?';
  }

  @override
  String get settingsTitle => 'वर्कस्पेस सेटिंग्स';

  @override
  String get settingsSubtitle =>
      'प्राथमिकताएं प्रबंधित करें और ऑडिट इवेंट देखें।';

  @override
  String get dbManagementTitle => 'डेटाबेस प्रबंधन';

  @override
  String get dbManagementSub =>
      'स्थानीय SQLite रिकॉर्ड प्रबंधित करें या डेमो डेटा लोड करें।';

  @override
  String get wipeConfirmTitle => 'मिटाने की पुष्टि करें';

  @override
  String get wipeConfirmMessage => 'सभी डेटा हटाएं?';

  @override
  String get dbWipedSnack => 'डेटाबेस रीसेट हो गया।';

  @override
  String get demoLoadedSnack => 'डेमो डेटा लोड हो गया।';

  @override
  String get loginTitle => 'no5ocial में आपका स्वागत है';

  @override
  String get loginSubtitle => 'आपका ऑल-इन-वन सोशल पब्लिशिंग वर्कस्पेस';

  @override
  String get loginWithGoogle => 'Google से जारी रखें';

  @override
  String get loginDisclaimer => 'जारी रखकर, आप हमारी सहमति देते हैं';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get disclaimer => 'अस्वीकरण';

  @override
  String get loginLocalNote =>
      'आपका डेटा केवल इस डिवाइस पर स्थानीय रूप से संग्रहीत है।';

  @override
  String get andText => 'और';
}
