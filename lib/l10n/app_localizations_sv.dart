// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline =>
      'Arbetsyta för publicering och schemaläggning i sociala medier';

  @override
  String get proWorkspace => 'PRO-ARBETSYTA';

  @override
  String get navQueue => 'Publiceringskö';

  @override
  String get navContent => 'Innehållsbibliotek';

  @override
  String get navCalendar => 'Publiceringskalender';

  @override
  String get navChannels => 'Anslutna kanaler';

  @override
  String get navSettings => 'Inställningar';

  @override
  String get btnNewPost => 'Nytt inlägg';

  @override
  String get btnCreatePost => 'Skapa inlägg';

  @override
  String get btnComposePost => 'Skriv inlägg';

  @override
  String get btnQueuePost => 'Lägg i kö';

  @override
  String get btnSchedule => 'Schemalägg';

  @override
  String get btnShareNow => 'Dela nu';

  @override
  String get btnSaveDraft => 'Spara som utkast';

  @override
  String get btnConnectChannel => 'Anslut kanal';

  @override
  String get btnCreateChannelGroup => 'Skapa kanalgrupp';

  @override
  String get btnRegisterCompany => 'Registrera företag';

  @override
  String get btnCancel => 'Avbryt';

  @override
  String get btnSave => 'Spara';

  @override
  String get btnConfirm => 'Bekräfta';

  @override
  String get btnDelete => 'Ta bort';

  @override
  String get btnClose => 'Stäng';

  @override
  String get btnDisconnect => 'Koppla från';

  @override
  String get btnSchedulePost => 'Schemalägg ett inlägg';

  @override
  String get btnConfirmWipe => 'Bekräfta och rensa data';

  @override
  String get btnClearAllData => 'Rensa alla data och börja om';

  @override
  String get btnLoadDemoData => 'Läs in demodata';

  @override
  String get consoleTitle => 'Konsol för publiceringsåtgärder';

  @override
  String get growthWorkspace => 'Tillväxtarbetsyta';

  @override
  String get selectTimezoneTitle => 'Välj tidszon för publicering';

  @override
  String languageSetTo(String language) {
    return 'Språk inställt på: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count aktiva kanaler';
  }

  @override
  String channelsConnected(int count) {
    return '$count anslutna kanaler';
  }

  @override
  String get heroTitle => 'Öka din räckvidd över alla sociala nätverk';

  @override
  String get heroSubtitle =>
      'Planera, samarbeta och schemalägg inlägg på Instagram, X, LinkedIn och YouTube från en enhetlig kö.';

  @override
  String actionRequiredTitle(int count) {
    return 'Åtgärd krävs ($count problem med destinationer)';
  }

  @override
  String get actionRequiredSub =>
      'En eller flera destinationer stötte på en timeout eller kräver manuell hantering. Granska och åtgärda nedan:';

  @override
  String get metricDrafts => 'Utkast';

  @override
  String get metricDraftsSub => 'Idéer och pågående';

  @override
  String get metricScheduled => 'Schemalagt';

  @override
  String get metricScheduledSub => 'Nästa i kön';

  @override
  String get metricPublished => 'Publicerat';

  @override
  String get metricPublishedSub => 'Live på kanaler';

  @override
  String get metricNeedsReview => 'Kräver granskning';

  @override
  String get metricNeedsReviewSub => 'Åtgärd krävs';

  @override
  String get queueSectionTitle => 'Kommande publiceringskö';

  @override
  String get queueEmptyTitle => 'Din publiceringskö är tom';

  @override
  String get queueEmptySubtitle =>
      'Planera och köa inlägg för att upprätthålla en konsekvent närvaro i sociala medier.';

  @override
  String get recentActivityTitle => 'Senaste publiceringsaktivitet';

  @override
  String get recentActivitySub =>
      'Granskningslogg och leveransstatus i realtid';

  @override
  String get noRecentActivity =>
      'Inga slutförda jobb ännu. Publicerade inlägg visas här.';

  @override
  String get contentLibraryTitle => 'Innehållsbibliotek för flera plattformar';

  @override
  String get searchHint => 'Sök inlägg, bildtexter, kampanjer eller taggar...';

  @override
  String get filterAll => 'Alla inlägg';

  @override
  String get filterDraft => 'Utkast';

  @override
  String get filterScheduled => 'Schemalagt';

  @override
  String get filterPublished => 'Publicerat';

  @override
  String get filterFailed => 'Misslyckades / Blockerad';

  @override
  String get noPostsMatch => 'Inga inlägg matchar dina filter.';

  @override
  String get noPostsMatchSub =>
      'Prova att justera sökfrågan eller varumärkesfiltret.';

  @override
  String get deleteDraftTitle => 'Ta bort inläggsutkast?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Är du säker på att du vill ta bort \"$title\"? Detta avbryter associerade jobb.';
  }

  @override
  String get draftDeletedSnack => 'Inläggsutkast borttaget.';

  @override
  String get calendarTitle => 'Schemalagd redaktionell kalender';

  @override
  String get calendarEmptyTitle => 'Redaktionskön är tom';

  @override
  String get calendarEmptySub =>
      'Inga kommande inlägg schemalagda i din tidszon.';

  @override
  String get registryTitle => 'Varumärkes- och kanalregister';

  @override
  String get connectedWorkspaceTitle => 'Ansluten arbetsyta';

  @override
  String get connectedWorkspaceSub =>
      'Hantera alla dina identiteter, bunta ihop profiler i Grupper och publicera till Instagram, X, LinkedIn och YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Sociala kanaler ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kanalgrupper ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Företagsportfölj ($count)';
  }

  @override
  String get noCompaniesTitle => 'Inga företag registrerade ännu';

  @override
  String get noCompaniesSub =>
      'Kom igång genom att registrera ditt företag för att ansluta sociala kanaler.';

  @override
  String get noGroupsTitle => 'Inga kanalgrupper skapade ännu';

  @override
  String get noGroupsSub =>
      'Grupper låter dig bunta ihop profiler för samma produkt för att publicera till alla med ett klick!';

  @override
  String get noChannelsForBrand =>
      'Inga sociala konton registrerade för detta varumärke ännu.';

  @override
  String get btnConnectBrandChannel => '+ Anslut kanal';

  @override
  String get registerCompanyDialogTitle => 'Registrera företag / varumärke';

  @override
  String get companyNameLabel => 'Företags- / varumärkesnamn *';

  @override
  String get companyNameHint => 't.ex. Acme Corporation eller Nova Media';

  @override
  String get brandSlugLabel => 'Varumärkesslug *';

  @override
  String get brandSlugHint => 't.ex. acme-corp';

  @override
  String get brandDescLabel => 'Beskrivning';

  @override
  String get brandDescHint =>
      'Kort sammanfattning av företaget eller varumärket';

  @override
  String get websiteUrlLabel => 'Webbplats-URL (valfritt)';

  @override
  String get connectChannelDialogTitle => 'Anslut social kanal';

  @override
  String get connectChannelDialogSub =>
      'Koppla en profil för att schemalägga och publicera inlägg.';

  @override
  String get selectCompanyLabel => 'Associerat företag / varumärke *';

  @override
  String get selectPlatformLabel => 'Social plattform *';

  @override
  String get displayNameLabel => 'Visningsnamn *';

  @override
  String get displayNameHint => 't.ex. Acme Tech Global';

  @override
  String get handleLabel => 'Användarnamn / ID *';

  @override
  String get handleHint => 't.ex. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Koppla från kanal';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Är du säker på att du vill koppla från $handle? Tidigare inlägg sparas fortfarande.';
  }

  @override
  String get createGroupDialogTitle => 'Skapa kanalgrupp';

  @override
  String get createGroupDialogSub =>
      'Bunta ihop flera konton för samma produkt (t.ex. Acme Instagram + Acme X) för att publicera till alla samtidigt.';

  @override
  String get groupNameLabel => 'Gruppnamn *';

  @override
  String get groupNameHint => 't.ex. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Gruppbeskrivning (valfritt)';

  @override
  String get groupDescHint =>
      't.ex. Globala primära marknadsföringsidentiteter';

  @override
  String groupSelectChannels(int count) {
    return 'Välj kanaler att bunta ihop ($count valda):';
  }

  @override
  String get composerTitle => 'Inläggsskapare';

  @override
  String get composerEditTitle => 'Redigera inlägg';

  @override
  String get stepChannelsTitle => '1. Välj kanaler och grupper';

  @override
  String get stepChannelsEmptyBrands =>
      'Inga företag registrerade ännu. Registrera ett företag i Anslutna kanaler för att organisera profiler.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Inga kanaler anslutna ännu. Gå till Anslutna kanaler för att ansluta konton.';

  @override
  String get brandIdentityLabel => 'Varumärkesidentitet';

  @override
  String get quickSelectGroup => 'Snabbval efter kanalgrupp:';

  @override
  String get destinationProfiles => 'Målprofiler:';

  @override
  String get stepPostDetails => '2. Inläggsdetaljer';

  @override
  String get postTitleLabel => 'Inläggstitel *';

  @override
  String get postTitleHint => 'Internt referensnamn för denna kampanj...';

  @override
  String get campaignLabel => 'Kampanjnamn (valfritt)';

  @override
  String get campaignHint => 't.ex. Sommarkampanj 2026';

  @override
  String get tagsLabel => 'Taggar / Kategorisering';

  @override
  String get tagsHint => 'marknadsföring, lansering (kommaseparerat)';

  @override
  String get stepContentCopy => '3. Innehåll och bildtexter';

  @override
  String get sharedCaptionTab => 'Delad (alla nätverk)';

  @override
  String get captionLabel => 'Huvudinläggstext';

  @override
  String get captionHint => 'Skriv ditt huvudinlägg här...';

  @override
  String get sameCaptionToggle => 'Använd samma text i alla nätverk';

  @override
  String get stepMediaAssets => '4. Bifogade mediefiler';

  @override
  String get stepMediaAssetsSub =>
      'Välj befintliga filer från biblioteket eller klicka på \"Lägg till mediefil\".';

  @override
  String get addMediaAssetBtn => 'Lägg till mediefil';

  @override
  String get livePreviewTitle => 'Live-förhandsgranskning';

  @override
  String get simulatedBadge => 'Simulerad';

  @override
  String get previewEmptyPlaceholder =>
      'Välj minst en målkanal för att förhandsgranska.';

  @override
  String get preflightRulesTitle => 'Regler före publicering';

  @override
  String btnQueueForPublication(int count) {
    return 'Lägg i kö för publicering ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publicera nu ($count mål)';
  }

  @override
  String get draftSavedSnack => 'Utkast sparat i biblioteket.';

  @override
  String get confirmPublishTitle =>
      'Bekräfta publicering till flera destinationer';

  @override
  String confirmPublishMessage(int count) {
    return 'Är du redo att publicera till $count målkonton? Varje konto publiceras oberoende.';
  }

  @override
  String get settingsTitle => 'Arbetsyteinställningar';

  @override
  String get settingsSubtitle =>
      'Hantera inställningar, granska händelser och konfigurera arbetsytan.';

  @override
  String get dbManagementTitle => 'Databas- och arbetsytehantering';

  @override
  String get dbManagementSub =>
      'Hantera lokala SQLite-poster, återställ arbetsytan eller läs in demodata.';

  @override
  String get wipeConfirmTitle => 'Bekräfta rensning av databas';

  @override
  String get wipeConfirmMessage =>
      'Är du säker på att du vill ta bort ALLA data? Detta rensar alla varumärken, konton, grupper och utkast från lokal SQLite.';

  @override
  String get dbWipedSnack => 'Arbetsytans databas återställd (0 poster).';

  @override
  String get demoLoadedSnack => 'Demodata har lästs in i SQLite.';

  @override
  String get loginTitle => 'Välkommen till no5ocial';

  @override
  String get loginSubtitle => 'Din allt-i-ett-arbetsyta för social publicering';

  @override
  String get loginWithGoogle => 'Fortsätt med Google';

  @override
  String get loginDisclaimer => 'Genom att fortsätta godkänner du våra';

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get disclaimer => 'Ansvarsfriskrivning';

  @override
  String get loginLocalNote =>
      'Dina data sparas endast lokalt på den här enheten.';

  @override
  String get andText => 'och';
}
