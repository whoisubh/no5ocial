// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Social Publishing & Planungs-Workspace';

  @override
  String get proWorkspace => 'PRO-PLAN';

  @override
  String get navQueue => 'Veröffentlichungswarteschlange';

  @override
  String get navContent => 'Inhaltsbibliothek';

  @override
  String get navCalendar => 'Redaktionskalender';

  @override
  String get navChannels => 'Verbundene Kanäle';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get btnNewPost => 'Neuer Beitrag';

  @override
  String get btnCreatePost => 'Beitrag erstellen';

  @override
  String get btnComposePost => 'Beitrag verfassen';

  @override
  String get btnQueuePost => 'In Warteschlange';

  @override
  String get btnSchedule => 'Planen';

  @override
  String get btnShareNow => 'Jetzt teilen';

  @override
  String get btnSaveDraft => 'Als Entwurf speichern';

  @override
  String get btnConnectChannel => 'Kanal verbinden';

  @override
  String get btnCreateChannelGroup => 'Kanalgruppe erstellen';

  @override
  String get btnRegisterCompany => 'Unternehmen registrieren';

  @override
  String get btnCancel => 'Abbrechen';

  @override
  String get btnSave => 'Speichern';

  @override
  String get btnConfirm => 'Bestätigen';

  @override
  String get btnDelete => 'Löschen';

  @override
  String get btnClose => 'Schließen';

  @override
  String get btnDisconnect => 'Trennen';

  @override
  String get btnSchedulePost => 'Beitrag planen';

  @override
  String get btnConfirmWipe => 'Bestätigen & Daten löschen';

  @override
  String get btnClearAllData => 'Alle Daten löschen';

  @override
  String get btnLoadDemoData => 'Demodaten laden';

  @override
  String get consoleTitle => 'Veröffentlichungskonsole';

  @override
  String get growthWorkspace => 'Wachstums-Workspace';

  @override
  String get selectTimezoneTitle => 'Zeitzone auswählen';

  @override
  String languageSetTo(String language) {
    return 'Sprache auf $language gesetzt';
  }

  @override
  String channelsActive(int count) {
    return '$count aktive Kanäle';
  }

  @override
  String channelsConnected(int count) {
    return '$count verbundene Kanäle';
  }

  @override
  String get heroTitle =>
      'Erweitern Sie Ihre Reichweite in allen sozialen Netzwerken';

  @override
  String get heroSubtitle =>
      'Planen und veröffentlichen Sie Beiträge auf Instagram, X, LinkedIn und YouTube.';

  @override
  String actionRequiredTitle(int count) {
    return 'Aktion erforderlich ($count Probleme)';
  }

  @override
  String get actionRequiredSub =>
      'Ein oder mehrere Ziele erfordern manuelle Überprüfung.';

  @override
  String get metricDrafts => 'Entwürfe';

  @override
  String get metricDraftsSub => 'Ideen in Arbeit';

  @override
  String get metricScheduled => 'Geplant';

  @override
  String get metricScheduledSub => 'Nächste in der Warteschlange';

  @override
  String get metricPublished => 'Veröffentlicht';

  @override
  String get metricPublishedSub => 'Live auf Kanälen';

  @override
  String get metricNeedsReview => 'Überprüfung erforderlich';

  @override
  String get metricNeedsReviewSub => 'Aktion erforderlich';

  @override
  String get queueSectionTitle => 'Bevorstehende Warteschlange';

  @override
  String get queueEmptyTitle => 'Ihre Warteschlange ist leer';

  @override
  String get queueEmptySubtitle =>
      'Planen Sie Beiträge für eine konstante Präsenz.';

  @override
  String get recentActivityTitle => 'Letzte Aktivität';

  @override
  String get recentActivitySub => 'Auditprotokoll und Lieferstatus';

  @override
  String get noRecentActivity => 'Noch keine abgeschlossenen Jobs.';

  @override
  String get contentLibraryTitle => 'Multi-Plattform-Inhaltsbibliothek';

  @override
  String get searchHint => 'Beiträge, Kampagnen oder Tags suchen...';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterDraft => 'Entwürfe';

  @override
  String get filterScheduled => 'Geplant';

  @override
  String get filterPublished => 'Veröffentlicht';

  @override
  String get filterFailed => 'Fehlgeschlagen / Blockiert';

  @override
  String get noPostsMatch => 'Keine Beiträge entsprechen den Filtern.';

  @override
  String get noPostsMatchSub => 'Suchanfrage anpassen.';

  @override
  String get deleteDraftTitle => 'Entwurf löschen?';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\" löschen?';
  }

  @override
  String get draftDeletedSnack => 'Entwurf gelöscht.';

  @override
  String get calendarTitle => 'Geplanter Redaktionskalender';

  @override
  String get calendarEmptyTitle => 'Redaktionswarteschlange ist leer';

  @override
  String get calendarEmptySub => 'Keine geplanten Beiträge.';

  @override
  String get registryTitle => 'Marken- und Kanalregister';

  @override
  String get connectedWorkspaceTitle => 'Verbundener sozialer Workspace';

  @override
  String get connectedWorkspaceSub =>
      'Verwalten Sie Ihre Multi-Plattform-Identitäten.';

  @override
  String tabSocialChannels(int count) {
    return 'Soziale Kanäle ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kanalgruppen ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Unternehmensportfolio ($count)';
  }

  @override
  String get noCompaniesTitle => 'Keine Unternehmen registriert';

  @override
  String get noCompaniesSub =>
      'Registrieren Sie Ihr Unternehmen, um Kanäle zu verbinden.';

  @override
  String get noGroupsTitle => 'Keine Kanalgruppen';

  @override
  String get noGroupsSub =>
      'Gruppen erlauben das Bündeln mehrerer Profile für eine Veröffentlichung!';

  @override
  String get noChannelsForBrand => 'Keine sozialen Konten für diese Marke.';

  @override
  String get btnConnectBrandChannel => '+ Kanal verbinden';

  @override
  String get registerCompanyDialogTitle => 'Unternehmen / Marke registrieren';

  @override
  String get companyNameLabel => 'Unternehmens- / Markenname *';

  @override
  String get companyNameHint => 'z.B. Acme GmbH';

  @override
  String get brandSlugLabel => 'Marken-Slug *';

  @override
  String get brandSlugHint => 'z.B. acme-gmbh';

  @override
  String get brandDescLabel => 'Beschreibung';

  @override
  String get brandDescHint => 'Kurze Zusammenfassung';

  @override
  String get websiteUrlLabel => 'Website-URL (optional)';

  @override
  String get connectChannelDialogTitle => 'Sozialen Kanal verbinden';

  @override
  String get connectChannelDialogSub =>
      'Verknüpfen Sie ein soziales Profil für Veröffentlichungen.';

  @override
  String get selectCompanyLabel => 'Zugehöriges Unternehmen *';

  @override
  String get selectPlatformLabel => 'Soziale Netzwerkplattform *';

  @override
  String get displayNameLabel => 'Anzeigename *';

  @override
  String get displayNameHint => 'z.B. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / Benutzer-ID *';

  @override
  String get handleHint => 'z.B. @acme_offiziell';

  @override
  String get disconnectConfirmTitle => 'Kanal trennen';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handle trennen? Der Verlauf bleibt erhalten.';
  }

  @override
  String get createGroupDialogTitle => 'Kanalgruppe erstellen';

  @override
  String get createGroupDialogSub =>
      'Bündeln Sie Konten desselben Produkts für gleichzeitige Veröffentlichung.';

  @override
  String get groupNameLabel => 'Gruppenname *';

  @override
  String get groupNameHint => 'z.B. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Gruppenbeschreibung (optional)';

  @override
  String get groupDescHint => 'z.B. Globale Marketing-Identitäten';

  @override
  String groupSelectChannels(int count) {
    return 'Kanäle auswählen ($count ausgewählt):';
  }

  @override
  String get composerTitle => 'Beitrags-Composer';

  @override
  String get composerEditTitle => 'Beitrag bearbeiten';

  @override
  String get stepChannelsTitle => '1. Kanäle und Gruppen auswählen';

  @override
  String get stepChannelsEmptyBrands => 'Keine Unternehmen registriert.';

  @override
  String get stepChannelsEmptyAccounts => 'Keine Kanäle verbunden.';

  @override
  String get brandIdentityLabel => 'Marken-Identität';

  @override
  String get quickSelectGroup => 'Schnellauswahl nach Gruppe:';

  @override
  String get destinationProfiles => 'Zielprofile:';

  @override
  String get stepPostDetails => '2. Beitragsdetails';

  @override
  String get postTitleLabel => 'Beitragstitel *';

  @override
  String get postTitleHint => 'Interner Referenzname...';

  @override
  String get campaignLabel => 'Kampagnenname (optional)';

  @override
  String get campaignHint => 'z.B. Sommer-Launch 2026';

  @override
  String get tagsLabel => 'Tags / Kategorisierung';

  @override
  String get tagsHint => 'marketing, launch (kommagetrennt)';

  @override
  String get stepContentCopy => '3. Inhalt und Bildunterschriften';

  @override
  String get sharedCaptionTab => 'Geteilt (alle Netzwerke)';

  @override
  String get captionLabel => 'Haupt-Bildunterschrift';

  @override
  String get captionHint => 'Schreiben Sie hier Ihre Hauptbotschaft...';

  @override
  String get sameCaptionToggle => 'Gleiche Bildunterschrift für alle Netzwerke';

  @override
  String get stepMediaAssets => '4. Angehängte Medien';

  @override
  String get stepMediaAssetsSub =>
      'Vorhandene Medien auswählen oder neue hinzufügen.';

  @override
  String get addMediaAssetBtn => 'Medium hinzufügen';

  @override
  String get livePreviewTitle => 'Live-Vorschau';

  @override
  String get simulatedBadge => 'Simuliert';

  @override
  String get previewEmptyPlaceholder =>
      'Mindestens einen Kanal auswählen für Vorschau.';

  @override
  String get preflightRulesTitle => 'Vorab-Prüfregeln';

  @override
  String btnQueueForPublication(int count) {
    return 'In Warteschlange ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Jetzt veröffentlichen ($count Ziele)';
  }

  @override
  String get draftSavedSnack => 'Entwurf gespeichert.';

  @override
  String get confirmPublishTitle => 'Multi-Veröffentlichung bestätigen';

  @override
  String confirmPublishMessage(int count) {
    return 'Bereit für $count Konto/Konten zu veröffentlichen?';
  }

  @override
  String get settingsTitle => 'Workspace-Einstellungen';

  @override
  String get settingsSubtitle =>
      'Einstellungen und Audit-Ereignisse verwalten.';

  @override
  String get dbManagementTitle => 'Datenbankverwaltung';

  @override
  String get dbManagementSub => 'Lokale SQLite-Einträge verwalten.';

  @override
  String get wipeConfirmTitle => 'Löschen bestätigen';

  @override
  String get wipeConfirmMessage => 'ALLE Daten löschen?';

  @override
  String get dbWipedSnack => 'Datenbank zurückgesetzt.';

  @override
  String get demoLoadedSnack => 'Demodaten geladen.';

  @override
  String get loginTitle => 'Willkommen bei no5ocial';

  @override
  String get loginSubtitle => 'Ihr All-in-One Social Publishing Workspace';

  @override
  String get loginWithGoogle => 'Mit Google fortfahren';

  @override
  String get loginDisclaimer => 'Mit dem Fortfahren stimmen Sie unseren';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get disclaimer => 'Haftungsausschluss';

  @override
  String get loginLocalNote =>
      'Ihre Daten werden lokal auf diesem Gerät gespeichert.';

  @override
  String get andText => 'und';
}
