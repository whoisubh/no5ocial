// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline =>
      'Arbejdsområde til udgivelse og planlægning på sociale medier';

  @override
  String get proWorkspace => 'PRO-ARBEJDSOMRÅDE';

  @override
  String get navQueue => 'Udgivelseskø';

  @override
  String get navContent => 'Indholdsbibliotek';

  @override
  String get navCalendar => 'Udgivelseskalender';

  @override
  String get navChannels => 'Forbundne kanaler';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get btnNewPost => 'Nyt opslag';

  @override
  String get btnCreatePost => 'Opret opslag';

  @override
  String get btnComposePost => 'Skriv opslag';

  @override
  String get btnQueuePost => 'Føj til kø';

  @override
  String get btnSchedule => 'Planlæg';

  @override
  String get btnShareNow => 'Del nu';

  @override
  String get btnSaveDraft => 'Gem som kladde';

  @override
  String get btnConnectChannel => 'Forbind kanal';

  @override
  String get btnCreateChannelGroup => 'Opret kanalgruppe';

  @override
  String get btnRegisterCompany => 'Registrer virksomhed';

  @override
  String get btnCancel => 'Annuller';

  @override
  String get btnSave => 'Gem';

  @override
  String get btnConfirm => 'Bekræft';

  @override
  String get btnDelete => 'Slet';

  @override
  String get btnClose => 'Luk';

  @override
  String get btnDisconnect => 'Afbryd';

  @override
  String get btnSchedulePost => 'Planlæg et opslag';

  @override
  String get btnConfirmWipe => 'Bekræft og ryd data';

  @override
  String get btnClearAllData => 'Ryd alle data og start forfra';

  @override
  String get btnLoadDemoData => 'Indlæs demodata';

  @override
  String get consoleTitle => 'Konsol for udgivelseshandlinger';

  @override
  String get growthWorkspace => 'Vækstarbejdsområde';

  @override
  String get selectTimezoneTitle => 'Vælg tidszone for udgivelse';

  @override
  String languageSetTo(String language) {
    return 'Sprog indstillet til: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count aktive kanaler';
  }

  @override
  String channelsConnected(int count) {
    return '$count forbundne kanaler';
  }

  @override
  String get heroTitle => 'Øg din rækkevidde på tværs af alle sociale netværk';

  @override
  String get heroSubtitle =>
      'Planlæg, samarbejd og udgiv fængslende opslag på Instagram, X, LinkedIn og YouTube fra én samlet kø.';

  @override
  String actionRequiredTitle(int count) {
    return 'Handling påkrævet ($count problemer)';
  }

  @override
  String get actionRequiredSub =>
      'En eller flere destinationer oplevede timeout eller kræver manuel handling. Gennemse og løs nedenfor:';

  @override
  String get metricDrafts => 'Kladder';

  @override
  String get metricDraftsSub => 'Idéer og i gang';

  @override
  String get metricScheduled => 'Planlagt';

  @override
  String get metricScheduledSub => 'Næste i køen';

  @override
  String get metricPublished => 'Udgivet';

  @override
  String get metricPublishedSub => 'Live på kanaler';

  @override
  String get metricNeedsReview => 'Kræver gennemgang';

  @override
  String get metricNeedsReviewSub => 'Handling påkrævet';

  @override
  String get queueSectionTitle => 'Kommende udgivelseskø';

  @override
  String get queueEmptyTitle => 'Din udgivelseskø er tom';

  @override
  String get queueEmptySubtitle =>
      'Planlæg og sæt kommende opslag i kø for at opretholde en konsekvent tilstedeværelse.';

  @override
  String get recentActivityTitle => 'Seneste udgivelsesaktivitet';

  @override
  String get recentActivitySub => 'Handlingslog og leveringsstatus i realtid';

  @override
  String get noRecentActivity =>
      'Ingen afsluttede opgaver endnu. Udgivne opslag vises her.';

  @override
  String get contentLibraryTitle => 'Indholdsbibliotek til flere platforme';

  @override
  String get searchHint =>
      'Søg i opslag, billedtekster, kampagner eller tags...';

  @override
  String get filterAll => 'Alle opslag';

  @override
  String get filterDraft => 'Kladder';

  @override
  String get filterScheduled => 'Planlagt';

  @override
  String get filterPublished => 'Udgivet';

  @override
  String get filterFailed => 'Mislykkedes / Blokeret';

  @override
  String get noPostsMatch => 'Ingen opslag matcher dine filtre.';

  @override
  String get noPostsMatchSub =>
      'Prøv at justere søgningen eller brandfilteret.';

  @override
  String get deleteDraftTitle => 'Slet kladde?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Er du sikker på, at du vil slette \"$title\"? Dette vil annullere tilknyttede opgaver.';
  }

  @override
  String get draftDeletedSnack => 'Kladde slettet.';

  @override
  String get calendarTitle => 'Planlagt redaktionel kalender';

  @override
  String get calendarEmptyTitle => 'Kalenderen er tom';

  @override
  String get calendarEmptySub =>
      'Ingen kommende opslag planlagt i din tidszone.';

  @override
  String get registryTitle => 'Brand- og kanalregister';

  @override
  String get connectedWorkspaceTitle => 'Forbundet arbejdsområde';

  @override
  String get connectedWorkspaceSub =>
      'Administrer alle dine identiteter, saml profiler i Grupper og udgiv problemfrit til Instagram, X, LinkedIn og YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Sociale kanaler ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kanalgrupper ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Virksomhedsportefølje ($count)';
  }

  @override
  String get noCompaniesTitle => 'Ingen virksomheder registreret endnu';

  @override
  String get noCompaniesSub =>
      'Kom i gang ved at registrere din virksomhed for at forbinde sociale kanaler.';

  @override
  String get noGroupsTitle => 'Ingen kanalgrupper oprettet endnu';

  @override
  String get noGroupsSub =>
      'Grupper lader dig samle profiler for samme produkt, så du kan udgive til alle med ét klik!';

  @override
  String get noChannelsForBrand =>
      'Ingen konti registreret for dette brand endnu.';

  @override
  String get btnConnectBrandChannel => '+ Forbind kanal';

  @override
  String get registerCompanyDialogTitle => 'Registrer virksomhed / brand';

  @override
  String get companyNameLabel => 'Virksomheds- / brandnavn *';

  @override
  String get companyNameHint => 'f.eks. Acme Corporation eller Nova Media';

  @override
  String get brandSlugLabel => 'Brand-slug *';

  @override
  String get brandSlugHint => 'f.eks. acme-corp';

  @override
  String get brandDescLabel => 'Beskrivelse';

  @override
  String get brandDescHint =>
      'Kort beskrivelse af denne virksomhed eller brand';

  @override
  String get websiteUrlLabel => 'Website-URL (valgfrit)';

  @override
  String get connectChannelDialogTitle => 'Forbind social kanal';

  @override
  String get connectChannelDialogSub =>
      'Tilknyt en profil for at planlægge og udgive opslag.';

  @override
  String get selectCompanyLabel => 'Tilknyttet virksomhed / brand *';

  @override
  String get selectPlatformLabel => 'Social platform *';

  @override
  String get displayNameLabel => 'Visningsnavn *';

  @override
  String get displayNameHint => 'f.eks. Acme Tech Global';

  @override
  String get handleLabel => 'Brugernavn / ID *';

  @override
  String get handleHint => 'f.eks. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Afbryd kanal';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Er du sikker på, at du vil afbryde $handle? Tidligere opslag forbliver gemt.';
  }

  @override
  String get createGroupDialogTitle => 'Opret kanalgruppe';

  @override
  String get createGroupDialogSub =>
      'Saml flere konti for samme produkt (f.eks. Acme Instagram + Acme X) for at udgive til alle på én gang.';

  @override
  String get groupNameLabel => 'Gruppenavn *';

  @override
  String get groupNameHint => 'f.eks. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Gruppebeskrivelse (valgfrit)';

  @override
  String get groupDescHint =>
      'f.eks. Globale primære markedsføringsidentiteter';

  @override
  String groupSelectChannels(int count) {
    return 'Vælg kanaler, der skal samles ($count valgt):';
  }

  @override
  String get composerTitle => 'Opslagseditor';

  @override
  String get composerEditTitle => 'Rediger opslag';

  @override
  String get stepChannelsTitle => '1. Vælg kanaler og grupper';

  @override
  String get stepChannelsEmptyBrands =>
      'Ingen virksomheder registreret endnu. Registrer en virksomhed under Forbundne kanaler for at organisere profiler.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Ingen sociale kanaler forbundet endnu. Gå til Forbundne kanaler for at forbinde konti.';

  @override
  String get brandIdentityLabel => 'Brand- / virksomhedsidentitet';

  @override
  String get quickSelectGroup => 'Hurtigvalg efter kanalgruppe:';

  @override
  String get destinationProfiles => 'Målprofiler:';

  @override
  String get stepPostDetails => '2. Opslagsdetaljer';

  @override
  String get postTitleLabel => 'Opslagstitel *';

  @override
  String get postTitleHint => 'Internt referencenavn for denne kampagne...';

  @override
  String get campaignLabel => 'Kampagnenavn (valgfrit)';

  @override
  String get campaignHint => 'f.eks. Sommerlancering 2026';

  @override
  String get tagsLabel => 'Tags / Kategorisering';

  @override
  String get tagsHint => 'markedsføring, lancering (kommasepareret)';

  @override
  String get stepContentCopy => '3. Indhold og billedtekster';

  @override
  String get sharedCaptionTab => 'Delt (alle netværk)';

  @override
  String get captionLabel => 'Hovedopslagstekst';

  @override
  String get captionHint => 'Skriv dit hovedbudskab her...';

  @override
  String get sameCaptionToggle => 'Brug samme tekst på tværs af alle netværk';

  @override
  String get stepMediaAssets => '4. Vedhæftede mediefiler';

  @override
  String get stepMediaAssetsSub =>
      'Vælg eksisterende filer fra biblioteket eller klik på \"Tilføj mediefil\".';

  @override
  String get addMediaAssetBtn => 'Tilføj mediefil';

  @override
  String get livePreviewTitle => 'Live forhåndsvisning';

  @override
  String get simulatedBadge => 'Simuleret';

  @override
  String get previewEmptyPlaceholder =>
      'Vælg mindst én målkanal for at se forhåndsvisning.';

  @override
  String get preflightRulesTitle => 'Regler før udgivelse';

  @override
  String btnQueueForPublication(int count) {
    return 'Føj til udgivelseskø ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Udgiv nu ($count mål)';
  }

  @override
  String get draftSavedSnack => 'Kladde gemt i biblioteket.';

  @override
  String get confirmPublishTitle => 'Bekræft udgivelse til flere destinationer';

  @override
  String confirmPublishMessage(int count) {
    return 'Er du klar til at udgive til $count målkonti? Hver konto udgives uafhængigt.';
  }

  @override
  String get settingsTitle => 'Arbejdsområdeindstillinger';

  @override
  String get settingsSubtitle =>
      'Administrer præferencer, inspicer hændelser og konfigurer indstillinger.';

  @override
  String get dbManagementTitle => 'Database- og arbejdsområdestyring';

  @override
  String get dbManagementSub =>
      'Administrer lokale SQLite-poster, nulstil arbejdsområdet eller indlæs demodata.';

  @override
  String get wipeConfirmTitle => 'Bekræft rydning af database';

  @override
  String get wipeConfirmMessage =>
      'Er du sikker på, at du vil slette ALLE data? Dette fjerner registrerede brands, konti, grupper og kladder fra SQLite.';

  @override
  String get dbWipedSnack =>
      'Arbejdsområdets database er nulstillet (0 poster).';

  @override
  String get demoLoadedSnack => 'Demodata er indlæst i SQLite.';

  @override
  String get loginTitle => 'Velkommen til no5ocial';

  @override
  String get loginSubtitle => 'Dit alt-i-ét arbejdsområde til social udgivelse';

  @override
  String get loginWithGoogle => 'Fortsæt med Google';

  @override
  String get loginDisclaimer => 'Ved at fortsætte accepterer du vores';

  @override
  String get termsOfService => 'Vilkår for brug';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get disclaimer => 'Ansvarsfraskrivelse';

  @override
  String get loginLocalNote => 'Dine data gemmes kun lokalt på denne enhed.';

  @override
  String get andText => 'og';
}
