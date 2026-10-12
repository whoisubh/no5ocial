// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Social Publishing & Plannings-Werkruimte';

  @override
  String get proWorkspace => 'PRO PLAN';

  @override
  String get navQueue => 'Publicatiewachtrij';

  @override
  String get navContent => 'Inhoudsbibliotheek';

  @override
  String get navCalendar => 'Redactionele kalender';

  @override
  String get navChannels => 'Verbonden kanalen';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get btnNewPost => 'Nieuwe post';

  @override
  String get btnCreatePost => 'Post aanmaken';

  @override
  String get btnComposePost => 'Post schrijven';

  @override
  String get btnQueuePost => 'Toevoegen aan wachtrij';

  @override
  String get btnSchedule => 'Plannen';

  @override
  String get btnShareNow => 'Nu delen';

  @override
  String get btnSaveDraft => 'Opslaan als concept';

  @override
  String get btnConnectChannel => 'Kanaal verbinden';

  @override
  String get btnCreateChannelGroup => 'Kanalengroep aanmaken';

  @override
  String get btnRegisterCompany => 'Bedrijf registreren';

  @override
  String get btnCancel => 'Annuleren';

  @override
  String get btnSave => 'Opslaan';

  @override
  String get btnConfirm => 'Bevestigen';

  @override
  String get btnDelete => 'Verwijderen';

  @override
  String get btnClose => 'Sluiten';

  @override
  String get btnDisconnect => 'Verbreken';

  @override
  String get btnSchedulePost => 'Post plannen';

  @override
  String get btnConfirmWipe => 'Bevestigen en gegevens wissen';

  @override
  String get btnClearAllData => 'Alle gegevens wissen';

  @override
  String get btnLoadDemoData => 'Demogegevens laden';

  @override
  String get consoleTitle => 'Publicatiebeheersconsole';

  @override
  String get growthWorkspace => 'Groeiwerkruimte';

  @override
  String get selectTimezoneTitle => 'Selecteer tijdzone';

  @override
  String languageSetTo(String language) {
    return 'Taal ingesteld op: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count kanalen actief';
  }

  @override
  String channelsConnected(int count) {
    return '$count kanalen verbonden';
  }

  @override
  String get heroTitle => 'Vergroot uw bereik op alle sociale netwerken';

  @override
  String get heroSubtitle =>
      'Plan en publiceer op Instagram, X, LinkedIn en YouTube vanuit één wachtrij.';

  @override
  String actionRequiredTitle(int count) {
    return 'Actie vereist ($count problemen)';
  }

  @override
  String get actionRequiredSub =>
      'Een of meer bestemmingen vereisen handmatige actie.';

  @override
  String get metricDrafts => 'Concepten';

  @override
  String get metricDraftsSub => 'Ideeën in uitvoering';

  @override
  String get metricScheduled => 'Gepland';

  @override
  String get metricScheduledSub => 'Volgende in wachtrij';

  @override
  String get metricPublished => 'Gepubliceerd';

  @override
  String get metricPublishedSub => 'Live op kanalen';

  @override
  String get metricNeedsReview => 'Vereist controle';

  @override
  String get metricNeedsReviewSub => 'Actie vereist';

  @override
  String get queueSectionTitle => 'Aankomende publicatiewachtrij';

  @override
  String get queueEmptyTitle => 'Uw publicatiewachtrij is leeg';

  @override
  String get queueEmptySubtitle =>
      'Plan posts voor een consistente aanwezigheid op sociale media.';

  @override
  String get recentActivityTitle => 'Recente activiteit';

  @override
  String get recentActivitySub => 'Auditlogboek en leveringsstatus';

  @override
  String get noRecentActivity => 'Nog geen voltooide taken.';

  @override
  String get contentLibraryTitle => 'Multiplatform inhoudsbibliotheek';

  @override
  String get searchHint => 'Zoek posts, campagnes of tags...';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterDraft => 'Concepten';

  @override
  String get filterScheduled => 'Gepland';

  @override
  String get filterPublished => 'Gepubliceerd';

  @override
  String get filterFailed => 'Mislukt / Geblokkeerd';

  @override
  String get noPostsMatch => 'Geen posts komen overeen met de filters.';

  @override
  String get noPostsMatchSub => 'Pas de zoekcriteria aan.';

  @override
  String get deleteDraftTitle => 'Concept verwijderen?';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\" verwijderen?';
  }

  @override
  String get draftDeletedSnack => 'Concept verwijderd.';

  @override
  String get calendarTitle => 'Geplande redactionele kalender';

  @override
  String get calendarEmptyTitle => 'Redactionele wachtrij is leeg';

  @override
  String get calendarEmptySub => 'Geen geplande posts.';

  @override
  String get registryTitle => 'Merk- en kanaalregister';

  @override
  String get connectedWorkspaceTitle => 'Verbonden sociale werkruimte';

  @override
  String get connectedWorkspaceSub =>
      'Beheer uw multiplatform-identiteiten en publiceer op Instagram, X, LinkedIn en YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Sociale kanalen ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kanalengroepen ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Bedrijfsportfolio ($count)';
  }

  @override
  String get noCompaniesTitle => 'Geen bedrijven geregistreerd';

  @override
  String get noCompaniesSub => 'Registreer uw bedrijf om kanalen te verbinden.';

  @override
  String get noGroupsTitle => 'Geen kanalengroepen';

  @override
  String get noGroupsSub =>
      'Met groepen kunt u meerdere profielen bundelen voor publicatie!';

  @override
  String get noChannelsForBrand => 'Geen sociale accounts voor dit merk.';

  @override
  String get btnConnectBrandChannel => '+ Kanaal verbinden';

  @override
  String get registerCompanyDialogTitle => 'Bedrijf / merk registreren';

  @override
  String get companyNameLabel => 'Bedrijfs- / merknaam *';

  @override
  String get companyNameHint => 'bijv. Acme Corporation';

  @override
  String get brandSlugLabel => 'Merk-slug *';

  @override
  String get brandSlugHint => 'bijv. acme-corp';

  @override
  String get brandDescLabel => 'Beschrijving';

  @override
  String get brandDescHint => 'Korte samenvatting van dit bedrijf of merk';

  @override
  String get websiteUrlLabel => 'Website-URL (optioneel)';

  @override
  String get connectChannelDialogTitle => 'Sociaal kanaal verbinden';

  @override
  String get connectChannelDialogSub =>
      'Koppel een sociaal profiel voor publicaties.';

  @override
  String get selectCompanyLabel => 'Gekoppeld bedrijf / merk *';

  @override
  String get selectPlatformLabel => 'Sociaal netwerkplatform *';

  @override
  String get displayNameLabel => 'Weergavenaam *';

  @override
  String get displayNameHint => 'bijv. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / Gebruikers-ID *';

  @override
  String get handleHint => 'bijv. @acme_officieel';

  @override
  String get disconnectConfirmTitle => 'Kanaal verbreken';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handle verbreken? Geschiedenis blijft bewaard.';
  }

  @override
  String get createGroupDialogTitle => 'Kanalengroep aanmaken';

  @override
  String get createGroupDialogSub =>
      'Bundel accounts van hetzelfde product voor gelijktijdige publicatie.';

  @override
  String get groupNameLabel => 'Groepsnaam *';

  @override
  String get groupNameHint => 'bijv. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Groepsbeschrijving (optioneel)';

  @override
  String get groupDescHint => 'bijv. Globale primaire marketingidentiteiten';

  @override
  String groupSelectChannels(int count) {
    return 'Selecteer kanalen ($count geselecteerd):';
  }

  @override
  String get composerTitle => 'Post-composer';

  @override
  String get composerEditTitle => 'Post bewerken';

  @override
  String get stepChannelsTitle => '1. Selecteer kanalen en groepen';

  @override
  String get stepChannelsEmptyBrands => 'Geen bedrijven geregistreerd.';

  @override
  String get stepChannelsEmptyAccounts => 'Geen kanalen verbonden.';

  @override
  String get brandIdentityLabel => 'Merkidentiteit';

  @override
  String get quickSelectGroup => 'Snelle selectie per groep:';

  @override
  String get destinationProfiles => 'Doelprofielen:';

  @override
  String get stepPostDetails => '2. Postdetails';

  @override
  String get postTitleLabel => 'Posttitel *';

  @override
  String get postTitleHint => 'Interne referentienaam...';

  @override
  String get campaignLabel => 'Campagnenaam (optioneel)';

  @override
  String get campaignHint => 'bijv. Zomerlancering 2026';

  @override
  String get tagsLabel => 'Tags / Categorisering';

  @override
  String get tagsHint => 'marketing, lancering (kommagescheiden)';

  @override
  String get stepContentCopy => '3. Inhoud en bijschriften';

  @override
  String get sharedCaptionTab => 'Gedeeld (alle netwerken)';

  @override
  String get captionLabel => 'Hoofdbijschrift';

  @override
  String get captionHint => 'Schrijf uw hoofdboodschap hier...';

  @override
  String get sameCaptionToggle =>
      'Gebruik hetzelfde bijschrift voor alle netwerken';

  @override
  String get stepMediaAssets => '4. Bijgevoegde media';

  @override
  String get stepMediaAssetsSub =>
      'Selecteer bestaande media of voeg nieuwe toe.';

  @override
  String get addMediaAssetBtn => 'Media toevoegen';

  @override
  String get livePreviewTitle => 'Live voorbeeld';

  @override
  String get simulatedBadge => 'Gesimuleerd';

  @override
  String get previewEmptyPlaceholder =>
      'Selecteer minimaal één kanaal voor een voorbeeld.';

  @override
  String get preflightRulesTitle => 'Pre-vluchtregels';

  @override
  String btnQueueForPublication(int count) {
    return 'Toevoegen aan wachtrij ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Nu publiceren ($count doelen)';
  }

  @override
  String get draftSavedSnack => 'Concept opgeslagen.';

  @override
  String get confirmPublishTitle => 'Meervoudige publicatie bevestigen';

  @override
  String confirmPublishMessage(int count) {
    return 'Klaar om te publiceren naar $count account(s)?';
  }

  @override
  String get settingsTitle => 'Werkruimte-instellingen';

  @override
  String get settingsSubtitle =>
      'Beheer voorkeuren en controleer auditgebeurtenissen.';

  @override
  String get dbManagementTitle => 'Databasebeheer';

  @override
  String get dbManagementSub =>
      'Beheer lokale SQLite-records of laad demogegevens.';

  @override
  String get wipeConfirmTitle => 'Wissen bevestigen';

  @override
  String get wipeConfirmMessage => 'ALLE gegevens verwijderen?';

  @override
  String get dbWipedSnack => 'Database gereset.';

  @override
  String get demoLoadedSnack => 'Demogegevens geladen.';

  @override
  String get loginTitle => 'Welkom bij no5ocial';

  @override
  String get loginSubtitle => 'Uw alles-in-één sociale publicatiewerkruimte';

  @override
  String get loginWithGoogle => 'Doorgaan met Google';

  @override
  String get loginDisclaimer => 'Door door te gaan, stemt u in met onze';

  @override
  String get termsOfService => 'Gebruiksvoorwaarden';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get loginLocalNote =>
      'Uw gegevens worden alleen lokaal op dit apparaat opgeslagen.';

  @override
  String get andText => 'en';
}
