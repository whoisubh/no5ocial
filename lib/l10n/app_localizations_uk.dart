// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline =>
      'Робочий простір публікацій та планування у соціальних мережах';

  @override
  String get proWorkspace => 'ПРО РОБОЧИЙ ПРОСТІР';

  @override
  String get navQueue => 'Черга публікацій';

  @override
  String get navContent => 'Бібліотека вмісту';

  @override
  String get navCalendar => 'Календар публікацій';

  @override
  String get navChannels => 'Підключені канали';

  @override
  String get navSettings => 'Налаштування простору';

  @override
  String get btnNewPost => 'Новий допис';

  @override
  String get btnCreatePost => 'Створити допис';

  @override
  String get btnComposePost => 'Написати допис';

  @override
  String get btnQueuePost => 'Додати в чергу';

  @override
  String get btnSchedule => 'Запланувати';

  @override
  String get btnShareNow => 'Опублікувати зараз';

  @override
  String get btnSaveDraft => 'Зберегти чернетку';

  @override
  String get btnConnectChannel => 'Підключити канал';

  @override
  String get btnCreateChannelGroup => 'Створити групу каналів';

  @override
  String get btnRegisterCompany => 'Зареєструвати компанію';

  @override
  String get btnCancel => 'Скасувати';

  @override
  String get btnSave => 'Зберегти';

  @override
  String get btnConfirm => 'Підтвердити';

  @override
  String get btnDelete => 'Видалити';

  @override
  String get btnClose => 'Закрити';

  @override
  String get btnDisconnect => 'Відключити';

  @override
  String get btnSchedulePost => 'Запланувати допис';

  @override
  String get btnConfirmWipe => 'Підтвердити та очистити дані';

  @override
  String get btnClearAllData => 'Очистити всі дані та почати спочатку';

  @override
  String get btnLoadDemoData => 'Завантажити демо-дані';

  @override
  String get consoleTitle => 'Панель керування публікаціями';

  @override
  String get growthWorkspace => 'Простір зростання';

  @override
  String get selectTimezoneTitle => 'Виберіть часовий пояс публікацій';

  @override
  String languageSetTo(String language) {
    return 'Мову змінено на: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count активних каналів';
  }

  @override
  String channelsConnected(int count) {
    return '$count підключених каналів';
  }

  @override
  String get heroTitle => 'Збільшуйте охоплення в усіх соціальних мережах';

  @override
  String get heroSubtitle =>
      'Плануйте, співпрацюйте та публікуйте захопливі дописи в Instagram, X, LinkedIn та YouTube з єдиної черги.';

  @override
  String actionRequiredTitle(int count) {
    return 'Потрібна дія ($count проблем із призначеннями)';
  }

  @override
  String get actionRequiredSub =>
      'В одному або кількох призначеннях минув час очікування або потрібна дія вручну. Перегляньте нижче:';

  @override
  String get metricDrafts => 'Чернетки';

  @override
  String get metricDraftsSub => 'Ідеї та в процесі';

  @override
  String get metricScheduled => 'Заплановано';

  @override
  String get metricScheduledSub => 'Наступні в черзі';

  @override
  String get metricPublished => 'Опубліковано';

  @override
  String get metricPublishedSub => 'Активні на каналах';

  @override
  String get metricNeedsReview => 'Потребує перегляду';

  @override
  String get metricNeedsReviewSub => 'Потрібна дія';

  @override
  String get queueSectionTitle => 'Черга майбутніх публікацій';

  @override
  String get queueEmptyTitle => 'Ваша черга публікацій порожня';

  @override
  String get queueEmptySubtitle =>
      'Плануйте та додавайте дописи в чергу для підтримки постійної присутності в соцмережах.';

  @override
  String get recentActivityTitle => 'Остання активність публікацій';

  @override
  String get recentActivitySub =>
      'Журнал аудиту виконання та статус доставки в реальному часі';

  @override
  String get noRecentActivity =>
      'Завершених завдань поки немає. Опубліковані дописи з\'являться тут.';

  @override
  String get contentLibraryTitle => 'Мультиплатформна бібліотека вмісту';

  @override
  String get searchHint => 'Пошук дописів, текстів, кампаній чи тегів...';

  @override
  String get filterAll => 'Усі дописи';

  @override
  String get filterDraft => 'Чернетки';

  @override
  String get filterScheduled => 'Заплановано';

  @override
  String get filterPublished => 'Опубліковано';

  @override
  String get filterFailed => 'Не вдалося / Заблоковано';

  @override
  String get noPostsMatch => 'Немає дописів, що відповідають фільтрам.';

  @override
  String get noPostsMatchSub =>
      'Спробуйте змінити пошуковий запит або фільтр бренду.';

  @override
  String get deleteDraftTitle => 'Видалити чернетку допису?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Ви впевнені, що хочете видалити \"$title\"? Це скасує пов\'язані завдання.';
  }

  @override
  String get draftDeletedSnack => 'Чернетку видалено.';

  @override
  String get calendarTitle => 'Запланований редакційний календар';

  @override
  String get calendarEmptyTitle => 'Редакційна черга порожня';

  @override
  String get calendarEmptySub =>
      'Немає запланованих дописів у вашому часовому поясі.';

  @override
  String get registryTitle => 'Реєстр брендів і каналів';

  @override
  String get connectedWorkspaceTitle => 'Підключений соціальний простір';

  @override
  String get connectedWorkspaceSub =>
      'Керуйте своїми профілями на різних платформах, об\'єднуйте їх у групи та легко публікуйте в Instagram, X, LinkedIn та YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Соціальні канали ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Групи каналів ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Портфоліо компаній ($count)';
  }

  @override
  String get noCompaniesTitle => 'Ще немає зареєстрованих компаній';

  @override
  String get noCompaniesSub =>
      'Почніть із реєстрації компанії для підключення соціальних каналів.';

  @override
  String get noGroupsTitle => 'Ще немає створених груп каналів';

  @override
  String get noGroupsSub =>
      'Групи дозволяють об\'єднувати кілька профілів для публікації одним кліком!';

  @override
  String get noChannelsForBrand =>
      'Для цього бренду ще немає зареєстрованих акаунтів.';

  @override
  String get btnConnectBrandChannel => '+ Підключити канал';

  @override
  String get registerCompanyDialogTitle => 'Зареєструвати компанію / бренд';

  @override
  String get companyNameLabel => 'Назва компанії / бренду *';

  @override
  String get companyNameHint => 'наприклад, Acme Corporation або Nova Media';

  @override
  String get brandSlugLabel => 'Ідентифікатор бренду (slug) *';

  @override
  String get brandSlugHint => 'наприклад, acme-corp';

  @override
  String get brandDescLabel => 'Опис';

  @override
  String get brandDescHint => 'Короткий опис цієї компанії або бренду';

  @override
  String get websiteUrlLabel => 'URL веб-сайту (необов\'язково)';

  @override
  String get connectChannelDialogTitle => 'Підключити соціальний канал';

  @override
  String get connectChannelDialogSub =>
      'Прив\'яжіть профіль для планування та публікації дописів.';

  @override
  String get selectCompanyLabel => 'Пов\'язана компанія / бренд *';

  @override
  String get selectPlatformLabel => 'Соціальна мережа *';

  @override
  String get displayNameLabel => 'Відображуване ім\'я *';

  @override
  String get displayNameHint => 'наприклад, Acme Tech Global';

  @override
  String get handleLabel => 'Ім\'я користувача / ID *';

  @override
  String get handleHint => 'наприклад, @acme_official';

  @override
  String get disconnectConfirmTitle => 'Відключити канал';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Ви впевнені, що хочете відключити $handle? Історія попередніх дописів збережеться.';
  }

  @override
  String get createGroupDialogTitle => 'Створити групу каналів';

  @override
  String get createGroupDialogSub =>
      'Об\'єднайте кілька акаунтів для одного продукту (наприклад, Acme Instagram + Acme X) для спільної публікації.';

  @override
  String get groupNameLabel => 'Назва групи *';

  @override
  String get groupNameHint => 'наприклад, Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Опис групи (необов\'язково)';

  @override
  String get groupDescHint => 'наприклад, Основні маркетингові профілі';

  @override
  String groupSelectChannels(int count) {
    return 'Виберіть канали для об\'єднання ($count вибрано):';
  }

  @override
  String get composerTitle => 'Редактор публікацій';

  @override
  String get composerEditTitle => 'Редагувати допис';

  @override
  String get stepChannelsTitle => '1. Виберіть канали та групи';

  @override
  String get stepChannelsEmptyBrands =>
      'Ще немає зареєстрованих компаній. Зареєструйте компанію в Підключених каналах.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Ще немає підключених каналів. Перейдіть до Підключених каналів для прив\'язки акаунтів.';

  @override
  String get brandIdentityLabel => 'Ідентичність бренду / компанії';

  @override
  String get quickSelectGroup => 'Швидкий вибір за групою каналів:';

  @override
  String get destinationProfiles => 'Цільові профілі:';

  @override
  String get stepPostDetails => '2. Деталі допису';

  @override
  String get postTitleLabel => 'Заголовок допису *';

  @override
  String get postTitleHint => 'Внутрішня назва цієї кампанії...';

  @override
  String get campaignLabel => 'Назва кампанії (необов\'язково)';

  @override
  String get campaignHint => 'наприклад, Літній запуск 2026';

  @override
  String get tagsLabel => 'Теги / Категоризація';

  @override
  String get tagsHint => 'маркетинг, запуск, оновлення (через кому)';

  @override
  String get stepContentCopy => '3. Вміст та підписи';

  @override
  String get sharedCaptionTab => 'Спільний (усі мережі)';

  @override
  String get captionLabel => 'Основний текст допису';

  @override
  String get captionHint => 'Напишіть текст повідомлення тут...';

  @override
  String get sameCaptionToggle =>
      'Використовувати однаковий текст для всіх мереж';

  @override
  String get stepMediaAssets => '4. Долучені медіафайли';

  @override
  String get stepMediaAssetsSub =>
      'Виберіть файли з бібліотеки або натисніть \"Додати медіафайл\".';

  @override
  String get addMediaAssetBtn => 'Додати медіафайл';

  @override
  String get livePreviewTitle => 'Попередній перегляд у соцмережах';

  @override
  String get simulatedBadge => 'Симуляція';

  @override
  String get previewEmptyPlaceholder =>
      'Виберіть хоча б один канал для попереднього перегляду.';

  @override
  String get preflightRulesTitle => 'Правила попередньої перевірки';

  @override
  String btnQueueForPublication(int count) {
    return 'Додати в чергу ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Опублікувати зараз ($count призначень)';
  }

  @override
  String get draftSavedSnack => 'Чернетку збережено в бібліотеці.';

  @override
  String get confirmPublishTitle => 'Підтвердити публікацію на кількох каналах';

  @override
  String confirmPublishMessage(int count) {
    return 'Ви готові опублікувати на $count цільових акаунтах? Кожен акаунт публікуватиметься незалежно.';
  }

  @override
  String get settingsTitle => 'Налаштування простору';

  @override
  String get settingsSubtitle =>
      'Керуйте налаштуваннями, переглядайте події аудиту та конфігурацію.';

  @override
  String get dbManagementTitle => 'Керування базою даних та простором';

  @override
  String get dbManagementSub =>
      'Керуйте записами SQLite, скидайте стан простору або завантажуйте демо-дані.';

  @override
  String get wipeConfirmTitle => 'Підтвердити очищення бази даних';

  @override
  String get wipeConfirmMessage =>
      'Ви впевнені, що хочете видалити ВСІ дані? Це очистить зареєстровані бренди, акаунти, групи та чернетки з SQLite.';

  @override
  String get dbWipedSnack => 'Базу даних простору скинуто (0 записів).';

  @override
  String get demoLoadedSnack => 'Демо-дані завантажено в SQLite.';

  @override
  String get loginTitle => 'Ласкаво просимо до no5ocial';

  @override
  String get loginSubtitle =>
      'Ваш універсальний простір для публікацій у соцмережах';

  @override
  String get loginWithGoogle => 'Продовжити через Google';

  @override
  String get loginDisclaimer => 'Продовжуючи, ви погоджуєтеся з нашими';

  @override
  String get termsOfService => 'Умовами використання';

  @override
  String get privacyPolicy => 'Політикою конфіденційності';

  @override
  String get disclaimer => 'Відмовою від відповідальності';

  @override
  String get loginLocalNote =>
      'Ваші дані зберігаються виключно локально на цьому пристрої.';

  @override
  String get andText => 'та';
}
