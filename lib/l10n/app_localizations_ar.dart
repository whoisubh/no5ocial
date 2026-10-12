// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'مساحة عمل النشر الاجتماعي والجدولة';

  @override
  String get proWorkspace => 'الخطة الاحترافية';

  @override
  String get navQueue => 'قائمة النشر';

  @override
  String get navContent => 'مكتبة المحتوى';

  @override
  String get navCalendar => 'التقويم التحريري';

  @override
  String get navChannels => 'القنوات المتصلة';

  @override
  String get navSettings => 'إعدادات مساحة العمل';

  @override
  String get btnNewPost => 'منشور جديد';

  @override
  String get btnCreatePost => 'إنشاء منشور';

  @override
  String get btnComposePost => 'تأليف منشور';

  @override
  String get btnQueuePost => 'إضافة للقائمة';

  @override
  String get btnSchedule => 'جدولة';

  @override
  String get btnShareNow => 'مشاركة الآن';

  @override
  String get btnSaveDraft => 'حفظ كمسودة';

  @override
  String get btnConnectChannel => 'ربط قناة';

  @override
  String get btnCreateChannelGroup => 'إنشاء مجموعة قنوات';

  @override
  String get btnRegisterCompany => 'تسجيل شركة';

  @override
  String get btnCancel => 'إلغاء';

  @override
  String get btnSave => 'حفظ';

  @override
  String get btnConfirm => 'تأكيد';

  @override
  String get btnDelete => 'حذف';

  @override
  String get btnClose => 'إغلاق';

  @override
  String get btnDisconnect => 'قطع الاتصال';

  @override
  String get btnSchedulePost => 'جدولة منشور';

  @override
  String get btnConfirmWipe => 'تأكيد ومسح البيانات';

  @override
  String get btnClearAllData => 'مسح جميع البيانات والبدء من جديد';

  @override
  String get btnLoadDemoData => 'تحميل بيانات تجريبية';

  @override
  String get consoleTitle => 'لوحة عمليات النشر';

  @override
  String get growthWorkspace => 'مساحة النمو';

  @override
  String get selectTimezoneTitle => 'اختر المنطقة الزمنية';

  @override
  String languageSetTo(String language) {
    return 'تم ضبط اللغة إلى: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count قناة نشطة';
  }

  @override
  String channelsConnected(int count) {
    return '$count قناة متصلة';
  }

  @override
  String get heroTitle => 'وسّع نطاق وصولك عبر جميع الشبكات الاجتماعية';

  @override
  String get heroSubtitle =>
      'خطط وتعاون وجدول منشوراتك على إنستغرام وX ولينكدإن ويوتيوب من قائمة موحدة.';

  @override
  String actionRequiredTitle(int count) {
    return 'إجراء مطلوب ($count مشكلة)';
  }

  @override
  String get actionRequiredSub => 'وجهة واحدة أو أكثر تتطلب مراجعة يدوية.';

  @override
  String get metricDrafts => 'المسودات';

  @override
  String get metricDraftsSub => 'أفكار قيد التطوير';

  @override
  String get metricScheduled => 'المجدولة';

  @override
  String get metricScheduledSub => 'التالي في القائمة';

  @override
  String get metricPublished => 'المنشورة';

  @override
  String get metricPublishedSub => 'مباشر على القنوات';

  @override
  String get metricNeedsReview => 'يحتاج مراجعة';

  @override
  String get metricNeedsReviewSub => 'إجراء مطلوب';

  @override
  String get queueSectionTitle => 'قائمة النشر القادمة';

  @override
  String get queueEmptyTitle => 'قائمة النشر فارغة';

  @override
  String get queueEmptySubtitle => 'خطط وأضف المنشورات للحفاظ على حضور ثابت.';

  @override
  String get recentActivityTitle => 'النشاط الأخير';

  @override
  String get recentActivitySub => 'سجل المراجعة وحالة التسليم';

  @override
  String get noRecentActivity => 'لا توجد وظائف مكتملة بعد.';

  @override
  String get contentLibraryTitle => 'مكتبة المحتوى متعددة المنصات';

  @override
  String get searchHint => 'ابحث عن منشورات أو حملات أو وسوم...';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterDraft => 'المسودات';

  @override
  String get filterScheduled => 'المجدولة';

  @override
  String get filterPublished => 'المنشورة';

  @override
  String get filterFailed => 'فشلت / محظورة';

  @override
  String get noPostsMatch => 'لا توجد منشورات تطابق الفلاتر.';

  @override
  String get noPostsMatchSub => 'جرب تعديل معايير البحث.';

  @override
  String get deleteDraftTitle => 'حذف المسودة؟';

  @override
  String deleteDraftConfirm(String title) {
    return 'هل أنت متأكد من حذف \"$title\"؟';
  }

  @override
  String get draftDeletedSnack => 'تم حذف المسودة.';

  @override
  String get calendarTitle => 'التقويم التحريري المجدول';

  @override
  String get calendarEmptyTitle => 'القائمة التحريرية فارغة';

  @override
  String get calendarEmptySub => 'لا توجد منشورات مجدولة.';

  @override
  String get registryTitle => 'سجل العلامات التجارية والقنوات';

  @override
  String get connectedWorkspaceTitle => 'مساحة العمل الاجتماعية المتصلة';

  @override
  String get connectedWorkspaceSub => 'أدر هوياتك متعددة المنصات وانشر بسلاسة.';

  @override
  String tabSocialChannels(int count) {
    return 'القنوات الاجتماعية ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'مجموعات القنوات ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'محفظة الشركات ($count)';
  }

  @override
  String get noCompaniesTitle => 'لا توجد شركات مسجلة';

  @override
  String get noCompaniesSub => 'ابدأ بتسجيل شركتك لربط القنوات الاجتماعية.';

  @override
  String get noGroupsTitle => 'لا توجد مجموعات قنوات';

  @override
  String get noGroupsSub =>
      'تتيح لك المجموعات تجميع ملفات تعريف متعددة للنشر دفعة واحدة!';

  @override
  String get noChannelsForBrand =>
      'لا توجد حسابات اجتماعية لهذه العلامة التجارية.';

  @override
  String get btnConnectBrandChannel => '+ ربط قناة';

  @override
  String get registerCompanyDialogTitle => 'تسجيل شركة / علامة تجارية';

  @override
  String get companyNameLabel => 'اسم الشركة / العلامة التجارية *';

  @override
  String get companyNameHint => 'مثال: شركة أكمي';

  @override
  String get brandSlugLabel => 'المعرف المختصر *';

  @override
  String get brandSlugHint => 'مثال: acme-corp';

  @override
  String get brandDescLabel => 'الوصف';

  @override
  String get brandDescHint => 'ملخص قصير لهذه الشركة';

  @override
  String get websiteUrlLabel => 'رابط الموقع (اختياري)';

  @override
  String get connectChannelDialogTitle => 'ربط قناة اجتماعية';

  @override
  String get connectChannelDialogSub =>
      'اربط ملف تعريف اجتماعي لجدولة المنشورات.';

  @override
  String get selectCompanyLabel => 'الشركة / العلامة المرتبطة *';

  @override
  String get selectPlatformLabel => 'منصة الشبكة الاجتماعية *';

  @override
  String get displayNameLabel => 'الاسم المعروض *';

  @override
  String get displayNameHint => 'مثال: أكمي تك العالمية';

  @override
  String get handleLabel => 'المعرف / رقم المستخدم *';

  @override
  String get handleHint => 'مثال: @acme_official';

  @override
  String get disconnectConfirmTitle => 'قطع اتصال القناة';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'هل تريد قطع اتصال $handle؟ سيبقى السجل التاريخي.';
  }

  @override
  String get createGroupDialogTitle => 'إنشاء مجموعة قنوات';

  @override
  String get createGroupDialogSub => 'اجمع حسابات نفس المنتج للنشر دفعة واحدة.';

  @override
  String get groupNameLabel => 'اسم المجموعة *';

  @override
  String get groupNameHint => 'مثال: أكمي العالمية (IG + X)';

  @override
  String get groupDescLabel => 'وصف المجموعة (اختياري)';

  @override
  String get groupDescHint => 'مثال: هويات التسويق الرئيسية';

  @override
  String groupSelectChannels(int count) {
    return 'اختر القنوات للتجميع ($count محددة):';
  }

  @override
  String get composerTitle => 'محرر المنشورات';

  @override
  String get composerEditTitle => 'تعديل المنشور';

  @override
  String get stepChannelsTitle => '1. اختر القنوات والمجموعات';

  @override
  String get stepChannelsEmptyBrands => 'لا توجد شركات مسجلة.';

  @override
  String get stepChannelsEmptyAccounts => 'لا توجد قنوات متصلة.';

  @override
  String get brandIdentityLabel => 'هوية العلامة التجارية';

  @override
  String get quickSelectGroup => 'اختيار سريع حسب المجموعة:';

  @override
  String get destinationProfiles => 'الملفات الوجهة:';

  @override
  String get stepPostDetails => '2. تفاصيل المنشور';

  @override
  String get postTitleLabel => 'عنوان المنشور *';

  @override
  String get postTitleHint => 'اسم مرجعي داخلي...';

  @override
  String get campaignLabel => 'اسم الحملة (اختياري)';

  @override
  String get campaignHint => 'مثال: إطلاق الصيف 2026';

  @override
  String get tagsLabel => 'الوسوم / التصنيف';

  @override
  String get tagsHint => 'تسويق، إطلاق (مفصولة بفواصل)';

  @override
  String get stepContentCopy => '3. المحتوى والتسميات';

  @override
  String get sharedCaptionTab => 'مشترك (جميع الشبكات)';

  @override
  String get captionLabel => 'التسمية الرئيسية للمنشور';

  @override
  String get captionHint => 'اكتب رسالتك الأساسية هنا...';

  @override
  String get sameCaptionToggle => 'استخدام نفس التسمية في جميع الشبكات';

  @override
  String get stepMediaAssets => '4. الوسائط المرفقة';

  @override
  String get stepMediaAssetsSub => 'اختر الوسائط الموجودة أو أضف جديدة.';

  @override
  String get addMediaAssetBtn => 'إضافة وسائط';

  @override
  String get livePreviewTitle => 'معاينة مباشرة';

  @override
  String get simulatedBadge => 'محاكاة';

  @override
  String get previewEmptyPlaceholder =>
      'حدد قناة واحدة على الأقل لمعاينة المنشور.';

  @override
  String get preflightRulesTitle => 'قواعد الفحص المسبق';

  @override
  String btnQueueForPublication(int count) {
    return 'إضافة للنشر ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'نشر الآن ($count وجهات)';
  }

  @override
  String get draftSavedSnack => 'تم حفظ المسودة.';

  @override
  String get confirmPublishTitle => 'تأكيد النشر المتعدد';

  @override
  String confirmPublishMessage(int count) {
    return 'هل أنت مستعد للنشر في $count حساب(ات)؟';
  }

  @override
  String get settingsTitle => 'إعدادات مساحة العمل';

  @override
  String get settingsSubtitle => 'أدر التفضيلات وافحص أحداث المراجعة.';

  @override
  String get dbManagementTitle => 'إدارة قاعدة البيانات';

  @override
  String get dbManagementSub =>
      'أدر سجلات SQLite المحلية أو حمّل بيانات تجريبية.';

  @override
  String get wipeConfirmTitle => 'تأكيد المسح';

  @override
  String get wipeConfirmMessage => 'هل أنت متأكد من حذف جميع البيانات؟';

  @override
  String get dbWipedSnack => 'تم إعادة ضبط قاعدة البيانات.';

  @override
  String get demoLoadedSnack => 'تم تحميل بيانات العرض التوضيحي.';

  @override
  String get loginTitle => 'مرحباً بك في no5ocial';

  @override
  String get loginSubtitle => 'مساحة عمل النشر الاجتماعي الشاملة';

  @override
  String get loginWithGoogle => 'المتابعة عبر Google';

  @override
  String get loginDisclaimer => 'بالمتابعة، فإنك توافق على';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get disclaimer => 'إخلاء المسؤولية';

  @override
  String get loginLocalNote => 'تُخزَّن بياناتك محلياً على هذا الجهاز فقط.';

  @override
  String get andText => 'و';
}
