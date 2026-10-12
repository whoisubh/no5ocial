// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline =>
      'Obszar publikacji i planowania w mediach społecznościowych';

  @override
  String get proWorkspace => 'OBSZAR ROBOCZY PRO';

  @override
  String get navQueue => 'Kolejka publikacji';

  @override
  String get navContent => 'Biblioteka treści';

  @override
  String get navCalendar => 'Kalendarz publikacji';

  @override
  String get navChannels => 'Połączone kanały';

  @override
  String get navSettings => 'Ustawienia obszaru';

  @override
  String get btnNewPost => 'Nowy post';

  @override
  String get btnCreatePost => 'Utwórz post';

  @override
  String get btnComposePost => 'Napisz post';

  @override
  String get btnQueuePost => 'Dodaj do kolejki';

  @override
  String get btnSchedule => 'Zaplanuj';

  @override
  String get btnShareNow => 'Opublikuj teraz';

  @override
  String get btnSaveDraft => 'Zapisz jako wersję roboczą';

  @override
  String get btnConnectChannel => 'Połącz kanał';

  @override
  String get btnCreateChannelGroup => 'Utwórz grupę kanałów';

  @override
  String get btnRegisterCompany => 'Zarejestruj firmę';

  @override
  String get btnCancel => 'Anuluj';

  @override
  String get btnSave => 'Zapisz';

  @override
  String get btnConfirm => 'Potwierdź';

  @override
  String get btnDelete => 'Usuń';

  @override
  String get btnClose => 'Zamknij';

  @override
  String get btnDisconnect => 'Odłącz';

  @override
  String get btnSchedulePost => 'Zaplanuj post';

  @override
  String get btnConfirmWipe => 'Potwierdź i wyczyść dane';

  @override
  String get btnClearAllData => 'Wyczyść wszystkie dane';

  @override
  String get btnLoadDemoData => 'Załaduj dane demonstracyjne';

  @override
  String get consoleTitle => 'Konsola operacji publikacji';

  @override
  String get growthWorkspace => 'Obszar rozwoju';

  @override
  String get selectTimezoneTitle => 'Wybierz strefę czasową publikacji';

  @override
  String languageSetTo(String language) {
    return 'Język ustawiony na: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count aktywnych kanałów';
  }

  @override
  String channelsConnected(int count) {
    return '$count połączonych kanałów';
  }

  @override
  String get heroTitle =>
      'Zwiększ zasięg we wszystkich sieciach społecznościowych';

  @override
  String get heroSubtitle =>
      'Planuj, współpracuj i publikuj angażujące posty na Instagramie, X, LinkedIn i YouTube z jednej spójnej kolejki.';

  @override
  String actionRequiredTitle(int count) {
    return 'Wymagane działanie ($count problemów)';
  }

  @override
  String get actionRequiredSub =>
      'W przypadku co najmniej jednego miejsca docelowego wystąpił limit czasu lub wymagane jest działanie ręczne. Przejrzyj i rozwiąż poniżej:';

  @override
  String get metricDrafts => 'Wersje robocze';

  @override
  String get metricDraftsSub => 'Pomysły i w toku';

  @override
  String get metricScheduled => 'Zaplanowane';

  @override
  String get metricScheduledSub => 'Następne w kolejce';

  @override
  String get metricPublished => 'Opublikowane';

  @override
  String get metricPublishedSub => 'Aktywne na kanałach';

  @override
  String get metricNeedsReview => 'Wymaga przeglądu';

  @override
  String get metricNeedsReviewSub => 'Wymagane działanie';

  @override
  String get queueSectionTitle => 'Nadchodząca kolejka publikacji';

  @override
  String get queueEmptyTitle => 'Kolejka publikacji jest pusta';

  @override
  String get queueEmptySubtitle =>
      'Planuj i dodawaj nadchodzące posty do kolejki, aby utrzymać stałą obecność w mediach społecznościowych.';

  @override
  String get recentActivityTitle => 'Ostatnia aktywność publikacji';

  @override
  String get recentActivitySub =>
      'Dziennik audytu wykonania i status dostawy w czasie rzeczywistym';

  @override
  String get noRecentActivity =>
      'Brak zakończonych zadań. Opublikowane posty pojawią się tutaj.';

  @override
  String get contentLibraryTitle => 'Wieloplatformowa biblioteka treści';

  @override
  String get searchHint => 'Szukaj postów, opisów, kampanii lub tagów...';

  @override
  String get filterAll => 'Wszystkie posty';

  @override
  String get filterDraft => 'Wersje robocze';

  @override
  String get filterScheduled => 'Zaplanowane';

  @override
  String get filterPublished => 'Opublikowane';

  @override
  String get filterFailed => 'Nieudane / Zablokowane';

  @override
  String get noPostsMatch => 'Brak postów spełniających kryteria.';

  @override
  String get noPostsMatchSub => 'Spróbuj dostosować zapytanie lub filtr marki.';

  @override
  String get deleteDraftTitle => 'Usunąć wersję roboczą?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Czy na pewno chcesz usunąć „$title”? Spowoduje to anulowanie powiązanych zadań.';
  }

  @override
  String get draftDeletedSnack => 'Wersja robocza posta usunięta.';

  @override
  String get calendarTitle => 'Kalendarz redakcyjny';

  @override
  String get calendarEmptyTitle => 'Kalendarz jest pusty';

  @override
  String get calendarEmptySub =>
      'Brak nadchodzących postów zaplanowanych w Twojej strefie czasowej.';

  @override
  String get registryTitle => 'Rejestr marek i kanałów';

  @override
  String get connectedWorkspaceTitle => 'Połączony obszar społecznościowy';

  @override
  String get connectedWorkspaceSub =>
      'Zarządzaj tożsamościami na wielu platformach, łącz profile w Grupy i publikuj na Instagramie, X (Twitterze), LinkedIn i YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Kanały społecznościowe ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Grupy kanałów ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portfolio firm ($count)';
  }

  @override
  String get noCompaniesTitle => 'Brak zarejestrowanych firm';

  @override
  String get noCompaniesSub =>
      'Rozpocznij od zarejestrowania firmy, aby podłączyć kanały społecznościowe.';

  @override
  String get noGroupsTitle => 'Brak utworzonych grup kanałów';

  @override
  String get noGroupsSub =>
      'Grupy umożliwiają łączenie wielu profili dla tego samego produktu, aby publikować do wszystkich jednym kliknięciem!';

  @override
  String get noChannelsForBrand =>
      'Brak zarejestrowanych kont społecznościowych dla tej marki.';

  @override
  String get btnConnectBrandChannel => '+ Połącz kanał';

  @override
  String get registerCompanyDialogTitle => 'Zarejestruj firmę / markę';

  @override
  String get companyNameLabel => 'Nazwa firmy / marki *';

  @override
  String get companyNameHint => 'np. Acme Corporation lub Nova Media';

  @override
  String get brandSlugLabel => 'Identyfikator marki (slug) *';

  @override
  String get brandSlugHint => 'np. acme-corp';

  @override
  String get brandDescLabel => 'Opis';

  @override
  String get brandDescHint => 'Krótki opis tej firmy lub marki';

  @override
  String get websiteUrlLabel => 'Adres URL witryny (opcjonalnie)';

  @override
  String get connectChannelDialogTitle => 'Połącz kanał społecznościowy';

  @override
  String get connectChannelDialogSub =>
      'Połącz profil społecznościowy, aby planować i publikować posty.';

  @override
  String get selectCompanyLabel => 'Powiązana firma / marka *';

  @override
  String get selectPlatformLabel => 'Platforma społecznościowa *';

  @override
  String get displayNameLabel => 'Wyświetlana nazwa *';

  @override
  String get displayNameHint => 'np. Acme Tech Global';

  @override
  String get handleLabel => 'Nazwa użytkownika / ID *';

  @override
  String get handleHint => 'np. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Odłącz kanał';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Czy na pewno chcesz odłączyć $handle? Historia publikacji powiązanych z tym kanałem pozostanie zachowana.';
  }

  @override
  String get createGroupDialogTitle => 'Utwórz grupę kanałów';

  @override
  String get createGroupDialogSub =>
      'Połącz wiele kont dla tego samego produktu (np. Acme Instagram + Acme X), aby publikować do wszystkich naraz.';

  @override
  String get groupNameLabel => 'Nazwa grupy *';

  @override
  String get groupNameHint => 'np. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Opis grupy (opcjonalnie)';

  @override
  String get groupDescHint => 'np. Główne tożsamości marketingowe';

  @override
  String groupSelectChannels(int count) {
    return 'Wybierz kanały do połączenia (wybrano: $count):';
  }

  @override
  String get composerTitle => 'Kreator postów';

  @override
  String get composerEditTitle => 'Edytuj post';

  @override
  String get stepChannelsTitle => '1. Wybierz kanały i grupy';

  @override
  String get stepChannelsEmptyBrands =>
      'Brak zarejestrowanych firm. Zarejestruj firmę w Połączonych kanałach, aby zarządzać profilami.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Brak połączonych kanałów. Przejdź do Połączonych kanałów, aby połączyć konta.';

  @override
  String get brandIdentityLabel => 'Tożsamość marki / firmy';

  @override
  String get quickSelectGroup => 'Szybki wybór grupy kanałów:';

  @override
  String get destinationProfiles => 'Profile docelowe:';

  @override
  String get stepPostDetails => '2. Szczegóły posta';

  @override
  String get postTitleLabel => 'Tytuł posta *';

  @override
  String get postTitleHint => 'Wewnętrzna nazwa referencyjna kampanii...';

  @override
  String get campaignLabel => 'Nazwa kampanii (opcjonalnie)';

  @override
  String get campaignHint => 'np. Premiera Lato 2026';

  @override
  String get tagsLabel => 'Tagi / Kategorie';

  @override
  String get tagsHint =>
      'marketing, premiera, aktualizacja (oddzielone przecinkami)';

  @override
  String get stepContentCopy => '3. Treść i podpisy';

  @override
  String get sharedCaptionTab => 'Wspólne (wszystkie sieci)';

  @override
  String get captionLabel => 'Główna treść posta';

  @override
  String get captionHint => 'Wpisz główną treść wiadomości tutaj...';

  @override
  String get sameCaptionToggle =>
      'Użyj tego samego tekstu we wszystkich sieciach';

  @override
  String get stepMediaAssets => '4. Załączone multimedia';

  @override
  String get stepMediaAssetsSub =>
      'Wybierz istniejące zasoby lub kliknij „Dodaj multimedia”, aby dodać nowe obrazy lub filmy.';

  @override
  String get addMediaAssetBtn => 'Dodaj multimedia';

  @override
  String get livePreviewTitle => 'Podgląd w mediach społecznościowych';

  @override
  String get simulatedBadge => 'Symulacja';

  @override
  String get previewEmptyPlaceholder =>
      'Wybierz co najmniej jeden kanał docelowy, aby wyświetlić podgląd.';

  @override
  String get preflightRulesTitle => 'Zasady wstępnej weryfikacji';

  @override
  String btnQueueForPublication(int count) {
    return 'Dodaj do kolejki ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Opublikuj teraz ($count miejsc docelowych)';
  }

  @override
  String get draftSavedSnack => 'Wersja robocza zapisana w bibliotece.';

  @override
  String get confirmPublishTitle => 'Potwierdź publikację na wielu profilach';

  @override
  String confirmPublishMessage(int count) {
    return 'Czy jesteś gotowy opublikować na $count kontach docelowych? Każde konto zostanie opublikowane niezależnie.';
  }

  @override
  String get settingsTitle => 'Ustawienia obszaru';

  @override
  String get settingsSubtitle =>
      'Zarządzaj preferencjami obszaru, przeglądaj zdarzenia audytu i konfiguruj ustawienia.';

  @override
  String get dbManagementTitle => 'Zarządzanie bazą danych i obszarem';

  @override
  String get dbManagementSub =>
      'Zarządzaj lokalnymi rekordami bazy danych SQLite, zresetuj stan obszaru lub załaduj dane demonstracyjne.';

  @override
  String get wipeConfirmTitle => 'Potwierdź wyczyszczenie bazy danych';

  @override
  String get wipeConfirmMessage =>
      'Czy na pewno chcesz usunąć WSZYSTKIE dane? Spowoduje to wyczyszczenie marek, kont, grup i zadań z lokalnego SQLite.';

  @override
  String get dbWipedSnack => 'Baza danych obszaru zresetowana (0 rekordów).';

  @override
  String get demoLoadedSnack => 'Przykładowe dane załadowane do SQLite.';

  @override
  String get loginTitle => 'Witamy w no5ocial';

  @override
  String get loginSubtitle =>
      'Kompleksowy obszar publikacji w mediach społecznościowych';

  @override
  String get loginWithGoogle => 'Kontynuuj z Google';

  @override
  String get loginDisclaimer => 'Kontynuując, akceptujesz nasze';

  @override
  String get termsOfService => 'Warunki korzystania';

  @override
  String get privacyPolicy => 'Politykę prywatności';

  @override
  String get disclaimer => 'Zastrzeżenia';

  @override
  String get loginLocalNote =>
      'Twoje dane są przechowywane wyłącznie lokalnie na tym urządzeniu.';

  @override
  String get andText => 'oraz';
}
