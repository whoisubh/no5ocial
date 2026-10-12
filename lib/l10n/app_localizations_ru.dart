// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline =>
      'Рабочее пространство для публикации в социальных сетях';

  @override
  String get proWorkspace => 'ПРО ПЛАН';

  @override
  String get navQueue => 'Очередь публикаций';

  @override
  String get navContent => 'Библиотека контента';

  @override
  String get navCalendar => 'Редакционный календарь';

  @override
  String get navChannels => 'Подключённые каналы';

  @override
  String get navSettings => 'Настройки';

  @override
  String get btnNewPost => 'Новая публикация';

  @override
  String get btnCreatePost => 'Создать публикацию';

  @override
  String get btnComposePost => 'Написать публикацию';

  @override
  String get btnQueuePost => 'В очередь';

  @override
  String get btnSchedule => 'Запланировать';

  @override
  String get btnShareNow => 'Поделиться сейчас';

  @override
  String get btnSaveDraft => 'Сохранить черновик';

  @override
  String get btnConnectChannel => 'Подключить канал';

  @override
  String get btnCreateChannelGroup => 'Создать группу каналов';

  @override
  String get btnRegisterCompany => 'Зарегистрировать компанию';

  @override
  String get btnCancel => 'Отмена';

  @override
  String get btnSave => 'Сохранить';

  @override
  String get btnConfirm => 'Подтвердить';

  @override
  String get btnDelete => 'Удалить';

  @override
  String get btnClose => 'Закрыть';

  @override
  String get btnDisconnect => 'Отключить';

  @override
  String get btnSchedulePost => 'Запланировать публикацию';

  @override
  String get btnConfirmWipe => 'Подтвердить и удалить данные';

  @override
  String get btnClearAllData => 'Очистить все данные';

  @override
  String get btnLoadDemoData => 'Загрузить демо-данные';

  @override
  String get consoleTitle => 'Консоль операций публикации';

  @override
  String get growthWorkspace => 'Рабочее пространство роста';

  @override
  String get selectTimezoneTitle => 'Выбрать часовой пояс';

  @override
  String languageSetTo(String language) {
    return 'Язык установлен на: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count каналов активно';
  }

  @override
  String channelsConnected(int count) {
    return '$count каналов подключено';
  }

  @override
  String get heroTitle => 'Расширьте охват во всех социальных сетях';

  @override
  String get heroSubtitle =>
      'Планируйте и публикуйте в Instagram, X, LinkedIn и YouTube из единой очереди.';

  @override
  String actionRequiredTitle(int count) {
    return 'Требуется действие ($count проблем)';
  }

  @override
  String get actionRequiredSub =>
      'Одно или несколько направлений требуют ручного вмешательства.';

  @override
  String get metricDrafts => 'Черновики';

  @override
  String get metricDraftsSub => 'Идеи в работе';

  @override
  String get metricScheduled => 'Запланировано';

  @override
  String get metricScheduledSub => 'Следующее в очереди';

  @override
  String get metricPublished => 'Опубликовано';

  @override
  String get metricPublishedSub => 'Живое на каналах';

  @override
  String get metricNeedsReview => 'Требует проверки';

  @override
  String get metricNeedsReviewSub => 'Требуется действие';

  @override
  String get queueSectionTitle => 'Предстоящая очередь публикаций';

  @override
  String get queueEmptyTitle => 'Очередь публикаций пуста';

  @override
  String get queueEmptySubtitle =>
      'Запланируйте публикации для постоянного присутствия в соцсетях.';

  @override
  String get recentActivityTitle => 'Последняя активность';

  @override
  String get recentActivitySub => 'Журнал аудита и статус доставки';

  @override
  String get noRecentActivity => 'Завершённых заданий пока нет.';

  @override
  String get contentLibraryTitle => 'Мультиплатформенная библиотека контента';

  @override
  String get searchHint => 'Поиск публикаций, кампаний или тегов...';

  @override
  String get filterAll => 'Все';

  @override
  String get filterDraft => 'Черновики';

  @override
  String get filterScheduled => 'Запланированные';

  @override
  String get filterPublished => 'Опубликованные';

  @override
  String get filterFailed => 'Неудачные / Заблокированные';

  @override
  String get noPostsMatch => 'Нет публикаций, соответствующих фильтрам.';

  @override
  String get noPostsMatchSub => 'Попробуйте изменить критерии поиска.';

  @override
  String get deleteDraftTitle => 'Удалить черновик?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Удалить \"$title\"?';
  }

  @override
  String get draftDeletedSnack => 'Черновик удалён.';

  @override
  String get calendarTitle => 'Запланированный редакционный календарь';

  @override
  String get calendarEmptyTitle => 'Редакционная очередь пуста';

  @override
  String get calendarEmptySub => 'Нет запланированных публикаций.';

  @override
  String get registryTitle => 'Реестр брендов и каналов';

  @override
  String get connectedWorkspaceTitle =>
      'Подключённое социальное рабочее пространство';

  @override
  String get connectedWorkspaceSub =>
      'Управляйте мультиплатформенными идентичностями и публикуйте в Instagram, X, LinkedIn и YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Социальные каналы ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Группы каналов ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Портфель компаний ($count)';
  }

  @override
  String get noCompaniesTitle => 'Нет зарегистрированных компаний';

  @override
  String get noCompaniesSub => 'Начните с регистрации вашей компании.';

  @override
  String get noGroupsTitle => 'Нет групп каналов';

  @override
  String get noGroupsSub =>
      'Группы позволяют объединить несколько профилей для одновременной публикации!';

  @override
  String get noChannelsForBrand => 'Нет социальных аккаунтов для этого бренда.';

  @override
  String get btnConnectBrandChannel => '+ Подключить канал';

  @override
  String get registerCompanyDialogTitle => 'Зарегистрировать компанию / бренд';

  @override
  String get companyNameLabel => 'Название компании / бренда *';

  @override
  String get companyNameHint => 'напр. Acme Corporation';

  @override
  String get brandSlugLabel => 'Идентификатор бренда *';

  @override
  String get brandSlugHint => 'напр. acme-corp';

  @override
  String get brandDescLabel => 'Описание';

  @override
  String get brandDescHint => 'Краткое описание компании или бренда';

  @override
  String get websiteUrlLabel => 'URL сайта (необязательно)';

  @override
  String get connectChannelDialogTitle => 'Подключить социальный канал';

  @override
  String get connectChannelDialogSub =>
      'Свяжите социальный профиль для планирования публикаций.';

  @override
  String get selectCompanyLabel => 'Связанная компания / бренд *';

  @override
  String get selectPlatformLabel => 'Платформа социальной сети *';

  @override
  String get displayNameLabel => 'Отображаемое имя *';

  @override
  String get displayNameHint => 'напр. Acme Tech Global';

  @override
  String get handleLabel => 'Хэндл / ID пользователя *';

  @override
  String get handleHint => 'напр. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Отключить канал';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Отключить $handle? История останется сохранённой.';
  }

  @override
  String get createGroupDialogTitle => 'Создать группу каналов';

  @override
  String get createGroupDialogSub =>
      'Объедините аккаунты одного продукта для одновременной публикации.';

  @override
  String get groupNameLabel => 'Название группы *';

  @override
  String get groupNameHint => 'напр. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Описание группы (необязательно)';

  @override
  String get groupDescHint =>
      'напр. Основные глобальные маркетинговые идентичности';

  @override
  String groupSelectChannels(int count) {
    return 'Выберите каналы для объединения ($count выбрано):';
  }

  @override
  String get composerTitle => 'Составитель публикаций';

  @override
  String get composerEditTitle => 'Редактировать публикацию';

  @override
  String get stepChannelsTitle => '1. Выберите каналы и группы';

  @override
  String get stepChannelsEmptyBrands => 'Нет зарегистрированных компаний.';

  @override
  String get stepChannelsEmptyAccounts => 'Нет подключённых каналов.';

  @override
  String get brandIdentityLabel => 'Идентичность бренда';

  @override
  String get quickSelectGroup => 'Быстрый выбор по группе:';

  @override
  String get destinationProfiles => 'Профили назначения:';

  @override
  String get stepPostDetails => '2. Детали публикации';

  @override
  String get postTitleLabel => 'Заголовок публикации *';

  @override
  String get postTitleHint => 'Внутреннее название...';

  @override
  String get campaignLabel => 'Название кампании (необязательно)';

  @override
  String get campaignHint => 'напр. Летний запуск 2026';

  @override
  String get tagsLabel => 'Теги / Категоризация';

  @override
  String get tagsHint => 'маркетинг, запуск (через запятую)';

  @override
  String get stepContentCopy => '3. Контент и подписи';

  @override
  String get sharedCaptionTab => 'Общий (все сети)';

  @override
  String get captionLabel => 'Основная подпись';

  @override
  String get captionHint => 'Напишите здесь ваше основное сообщение...';

  @override
  String get sameCaptionToggle =>
      'Использовать одинаковую подпись для всех сетей';

  @override
  String get stepMediaAssets => '4. Прикреплённые медиа';

  @override
  String get stepMediaAssetsSub =>
      'Выберите существующие медиа или добавьте новые.';

  @override
  String get addMediaAssetBtn => 'Добавить медиа';

  @override
  String get livePreviewTitle => 'Живой предпросмотр';

  @override
  String get simulatedBadge => 'Симулировано';

  @override
  String get previewEmptyPlaceholder =>
      'Выберите хотя бы один канал для предпросмотра.';

  @override
  String get preflightRulesTitle => 'Правила предполётной проверки';

  @override
  String btnQueueForPublication(int count) {
    return 'В очередь на публикацию ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Опубликовать сейчас ($count цели)';
  }

  @override
  String get draftSavedSnack => 'Черновик сохранён.';

  @override
  String get confirmPublishTitle => 'Подтвердить множественную публикацию';

  @override
  String confirmPublishMessage(int count) {
    return 'Готовы опубликовать в $count аккаунт(ах)?';
  }

  @override
  String get settingsTitle => 'Настройки рабочего пространства';

  @override
  String get settingsSubtitle =>
      'Управляйте настройками и проверяйте события аудита.';

  @override
  String get dbManagementTitle => 'Управление базой данных';

  @override
  String get dbManagementSub =>
      'Управляйте локальными записями SQLite или загружайте демо-данные.';

  @override
  String get wipeConfirmTitle => 'Подтвердить очистку';

  @override
  String get wipeConfirmMessage => 'Удалить ВСЕ данные?';

  @override
  String get dbWipedSnack => 'База данных сброшена.';

  @override
  String get demoLoadedSnack => 'Демо-данные загружены.';

  @override
  String get loginTitle => 'Добро пожаловать в no5ocial';

  @override
  String get loginSubtitle =>
      'Ваше универсальное рабочее пространство для публикации в соцсетях';

  @override
  String get loginWithGoogle => 'Продолжить с Google';

  @override
  String get loginDisclaimer => 'Продолжая, вы соглашаетесь с нашими';

  @override
  String get termsOfService => 'Условиями использования';

  @override
  String get privacyPolicy => 'Политикой конфиденциальности';

  @override
  String get disclaimer => 'Отказом от ответственности';

  @override
  String get loginLocalNote =>
      'Ваши данные хранятся только локально на этом устройстве.';

  @override
  String get andText => 'и';
}
