// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Spazio di lavoro per la pubblicazione social';

  @override
  String get proWorkspace => 'PIANO PRO';

  @override
  String get navQueue => 'Coda di pubblicazione';

  @override
  String get navContent => 'Libreria contenuti';

  @override
  String get navCalendar => 'Calendario editoriale';

  @override
  String get navChannels => 'Canali connessi';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get btnNewPost => 'Nuovo post';

  @override
  String get btnCreatePost => 'Crea post';

  @override
  String get btnComposePost => 'Componi post';

  @override
  String get btnQueuePost => 'Aggiungi alla coda';

  @override
  String get btnSchedule => 'Pianifica';

  @override
  String get btnShareNow => 'Condividi ora';

  @override
  String get btnSaveDraft => 'Salva bozza';

  @override
  String get btnConnectChannel => 'Connetti canale';

  @override
  String get btnCreateChannelGroup => 'Crea gruppo canali';

  @override
  String get btnRegisterCompany => 'Registra azienda';

  @override
  String get btnCancel => 'Annulla';

  @override
  String get btnSave => 'Salva';

  @override
  String get btnConfirm => 'Conferma';

  @override
  String get btnDelete => 'Elimina';

  @override
  String get btnClose => 'Chiudi';

  @override
  String get btnDisconnect => 'Disconnetti';

  @override
  String get btnSchedulePost => 'Pianifica un post';

  @override
  String get btnConfirmWipe => 'Conferma ed elimina dati';

  @override
  String get btnClearAllData => 'Cancella tutti i dati';

  @override
  String get btnLoadDemoData => 'Carica dati demo';

  @override
  String get consoleTitle => 'Console operazioni di pubblicazione';

  @override
  String get growthWorkspace => 'Spazio di crescita';

  @override
  String get selectTimezoneTitle => 'Seleziona fuso orario';

  @override
  String languageSetTo(String language) {
    return 'Lingua impostata su: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count canali attivi';
  }

  @override
  String channelsConnected(int count) {
    return '$count canali connessi';
  }

  @override
  String get heroTitle => 'Espandi la tua portata su tutti i social network';

  @override
  String get heroSubtitle =>
      'Pianifica e pubblica su Instagram, X, LinkedIn e YouTube da un\'unica coda.';

  @override
  String actionRequiredTitle(int count) {
    return 'Azione richiesta ($count problemi)';
  }

  @override
  String get actionRequiredSub =>
      'Una o più destinazioni richiedono intervento manuale.';

  @override
  String get metricDrafts => 'Bozze';

  @override
  String get metricDraftsSub => 'Idee in corso';

  @override
  String get metricScheduled => 'Pianificate';

  @override
  String get metricScheduledSub => 'Prossime in coda';

  @override
  String get metricPublished => 'Pubblicate';

  @override
  String get metricPublishedSub => 'Live sui canali';

  @override
  String get metricNeedsReview => 'Revisione necessaria';

  @override
  String get metricNeedsReviewSub => 'Azione richiesta';

  @override
  String get queueSectionTitle => 'Prossime in coda';

  @override
  String get queueEmptyTitle => 'La coda di pubblicazione è vuota';

  @override
  String get queueEmptySubtitle =>
      'Pianifica post per mantenere una presenza costante.';

  @override
  String get recentActivityTitle => 'Attività recente';

  @override
  String get recentActivitySub => 'Log di audit e stato di consegna';

  @override
  String get noRecentActivity => 'Nessun lavoro completato ancora.';

  @override
  String get contentLibraryTitle => 'Libreria contenuti multipiattaforma';

  @override
  String get searchHint => 'Cerca post, campagne o tag...';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterDraft => 'Bozze';

  @override
  String get filterScheduled => 'Pianificate';

  @override
  String get filterPublished => 'Pubblicate';

  @override
  String get filterFailed => 'Falliti / Bloccati';

  @override
  String get noPostsMatch => 'Nessun post corrisponde ai filtri.';

  @override
  String get noPostsMatchSub => 'Prova ad aggiustare i criteri di ricerca.';

  @override
  String get deleteDraftTitle => 'Eliminare la bozza?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Eliminare \"$title\"?';
  }

  @override
  String get draftDeletedSnack => 'Bozza eliminata.';

  @override
  String get calendarTitle => 'Calendario editoriale pianificato';

  @override
  String get calendarEmptyTitle => 'La coda editoriale è vuota';

  @override
  String get calendarEmptySub => 'Nessun post pianificato.';

  @override
  String get registryTitle => 'Registro marchi e canali';

  @override
  String get connectedWorkspaceTitle => 'Spazio di lavoro social connesso';

  @override
  String get connectedWorkspaceSub =>
      'Gestisci le identità multipiattaforma e pubblica su Instagram, X, LinkedIn e YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Canali social ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Gruppi canali ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portfolio aziende ($count)';
  }

  @override
  String get noCompaniesTitle => 'Nessuna azienda registrata';

  @override
  String get noCompaniesSub => 'Inizia registrando la tua azienda.';

  @override
  String get noGroupsTitle => 'Nessun gruppo di canali';

  @override
  String get noGroupsSub =>
      'I gruppi permettono di raggruppare più profili per pubblicare tutti insieme!';

  @override
  String get noChannelsForBrand => 'Nessun account social per questo marchio.';

  @override
  String get btnConnectBrandChannel => '+ Connetti canale';

  @override
  String get registerCompanyDialogTitle => 'Registra azienda / marchio';

  @override
  String get companyNameLabel => 'Nome azienda / marchio *';

  @override
  String get companyNameHint => 'es. Acme Corporation';

  @override
  String get brandSlugLabel => 'Identificatore marchio *';

  @override
  String get brandSlugHint => 'es. acme-corp';

  @override
  String get brandDescLabel => 'Descrizione';

  @override
  String get brandDescHint => 'Breve descrizione dell\'azienda o marchio';

  @override
  String get websiteUrlLabel => 'URL sito web (opzionale)';

  @override
  String get connectChannelDialogTitle => 'Connetti canale social';

  @override
  String get connectChannelDialogSub =>
      'Collega un profilo social per pianificare pubblicazioni.';

  @override
  String get selectCompanyLabel => 'Azienda / marchio associato *';

  @override
  String get selectPlatformLabel => 'Piattaforma social *';

  @override
  String get displayNameLabel => 'Nome visualizzato *';

  @override
  String get displayNameHint => 'es. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / ID utente *';

  @override
  String get handleHint => 'es. @acme_ufficiale';

  @override
  String get disconnectConfirmTitle => 'Disconnetti canale';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Disconnettere $handle? La cronologia rimarrà salvata.';
  }

  @override
  String get createGroupDialogTitle => 'Crea gruppo canali';

  @override
  String get createGroupDialogSub =>
      'Raggruppa account dello stesso prodotto per pubblicare tutti insieme.';

  @override
  String get groupNameLabel => 'Nome gruppo *';

  @override
  String get groupNameHint => 'es. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Descrizione gruppo (opzionale)';

  @override
  String get groupDescHint => 'es. Identità marketing globali principali';

  @override
  String groupSelectChannels(int count) {
    return 'Seleziona canali da raggruppare ($count selezionati):';
  }

  @override
  String get composerTitle => 'Compositore di post';

  @override
  String get composerEditTitle => 'Modifica post';

  @override
  String get stepChannelsTitle => '1. Seleziona canali e gruppi';

  @override
  String get stepChannelsEmptyBrands => 'Nessuna azienda registrata.';

  @override
  String get stepChannelsEmptyAccounts => 'Nessun canale connesso.';

  @override
  String get brandIdentityLabel => 'Identità marchio';

  @override
  String get quickSelectGroup => 'Selezione rapida per gruppo:';

  @override
  String get destinationProfiles => 'Profili destinazione:';

  @override
  String get stepPostDetails => '2. Dettagli del post';

  @override
  String get postTitleLabel => 'Titolo del post *';

  @override
  String get postTitleHint => 'Nome riferimento interno...';

  @override
  String get campaignLabel => 'Nome campagna (opzionale)';

  @override
  String get campaignHint => 'es. Lancio estate 2026';

  @override
  String get tagsLabel => 'Tag / Categorizzazione';

  @override
  String get tagsHint => 'marketing, lancio (separati da virgola)';

  @override
  String get stepContentCopy => '3. Contenuto e didascalie';

  @override
  String get sharedCaptionTab => 'Condiviso (tutte le reti)';

  @override
  String get captionLabel => 'Didascalia principale';

  @override
  String get captionHint => 'Scrivi qui il tuo messaggio principale...';

  @override
  String get sameCaptionToggle => 'Usa la stessa didascalia su tutte le reti';

  @override
  String get stepMediaAssets => '4. Media allegati';

  @override
  String get stepMediaAssetsSub =>
      'Seleziona media esistenti o aggiungine di nuovi.';

  @override
  String get addMediaAssetBtn => 'Aggiungi media';

  @override
  String get livePreviewTitle => 'Anteprima live';

  @override
  String get simulatedBadge => 'Simulato';

  @override
  String get previewEmptyPlaceholder =>
      'Seleziona almeno un canale per l\'anteprima.';

  @override
  String get preflightRulesTitle => 'Regole pre-volo';

  @override
  String btnQueueForPublication(int count) {
    return 'Aggiungi alla coda ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Pubblica ora ($count obiettivi)';
  }

  @override
  String get draftSavedSnack => 'Bozza salvata.';

  @override
  String get confirmPublishTitle => 'Conferma pubblicazione multipla';

  @override
  String confirmPublishMessage(int count) {
    return 'Pronti a pubblicare su $count account?';
  }

  @override
  String get settingsTitle => 'Impostazioni area di lavoro';

  @override
  String get settingsSubtitle =>
      'Gestisci preferenze ed esamina eventi di audit.';

  @override
  String get dbManagementTitle => 'Gestione database';

  @override
  String get dbManagementSub =>
      'Gestisci record SQLite locali o carica dati demo.';

  @override
  String get wipeConfirmTitle => 'Conferma eliminazione';

  @override
  String get wipeConfirmMessage => 'Eliminare TUTTI i dati?';

  @override
  String get dbWipedSnack => 'Database ripristinato.';

  @override
  String get demoLoadedSnack => 'Dati demo caricati.';

  @override
  String get loginTitle => 'Benvenuto su no5ocial';

  @override
  String get loginSubtitle =>
      'Il tuo spazio di lavoro per la pubblicazione social tutto in uno';

  @override
  String get loginWithGoogle => 'Continua con Google';

  @override
  String get loginDisclaimer => 'Continuando, accetti i nostri';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get disclaimer => 'Avvertenza';

  @override
  String get loginLocalNote =>
      'I tuoi dati sono archiviati localmente su questo dispositivo.';

  @override
  String get andText => 'e';
}
