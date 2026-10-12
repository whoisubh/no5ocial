// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Espace de travail de publication sociale';

  @override
  String get proWorkspace => 'PLAN PRO';

  @override
  String get navQueue => 'File de publication';

  @override
  String get navContent => 'Bibliothèque de contenu';

  @override
  String get navCalendar => 'Calendrier éditorial';

  @override
  String get navChannels => 'Canaux connectés';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get btnNewPost => 'Nouvelle publication';

  @override
  String get btnCreatePost => 'Créer une publication';

  @override
  String get btnComposePost => 'Rédiger une publication';

  @override
  String get btnQueuePost => 'Mettre en file';

  @override
  String get btnSchedule => 'Planifier';

  @override
  String get btnShareNow => 'Partager maintenant';

  @override
  String get btnSaveDraft => 'Enregistrer comme brouillon';

  @override
  String get btnConnectChannel => 'Connecter un canal';

  @override
  String get btnCreateChannelGroup => 'Créer un groupe de canaux';

  @override
  String get btnRegisterCompany => 'Enregistrer une entreprise';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get btnConfirm => 'Confirmer';

  @override
  String get btnDelete => 'Supprimer';

  @override
  String get btnClose => 'Fermer';

  @override
  String get btnDisconnect => 'Déconnecter';

  @override
  String get btnSchedulePost => 'Planifier une publication';

  @override
  String get btnConfirmWipe => 'Confirmer et effacer';

  @override
  String get btnClearAllData => 'Effacer toutes les données';

  @override
  String get btnLoadDemoData => 'Charger les données de démonstration';

  @override
  String get consoleTitle => 'Console des opérations de publication';

  @override
  String get growthWorkspace => 'Espace de croissance';

  @override
  String get selectTimezoneTitle => 'Sélectionner le fuseau horaire';

  @override
  String languageSetTo(String language) {
    return 'Langue définie sur : $language';
  }

  @override
  String channelsActive(int count) {
    return '$count canaux actifs';
  }

  @override
  String channelsConnected(int count) {
    return '$count canaux connectés';
  }

  @override
  String get heroTitle =>
      'Élargissez votre portée sur tous les réseaux sociaux';

  @override
  String get heroSubtitle =>
      'Planifiez et programmez vos publications sur Instagram, X, LinkedIn et YouTube depuis une file unifiée.';

  @override
  String actionRequiredTitle(int count) {
    return 'Action requise ($count problèmes)';
  }

  @override
  String get actionRequiredSub =>
      'Un ou plusieurs destinations nécessitent une intervention manuelle.';

  @override
  String get metricDrafts => 'Brouillons';

  @override
  String get metricDraftsSub => 'Idées en cours';

  @override
  String get metricScheduled => 'Planifiées';

  @override
  String get metricScheduledSub => 'Prochaines en file';

  @override
  String get metricPublished => 'Publiées';

  @override
  String get metricPublishedSub => 'En direct';

  @override
  String get metricNeedsReview => 'À réviser';

  @override
  String get metricNeedsReviewSub => 'Action requise';

  @override
  String get queueSectionTitle => 'File de publication à venir';

  @override
  String get queueEmptyTitle => 'Votre file de publication est vide';

  @override
  String get queueEmptySubtitle =>
      'Planifiez des publications pour maintenir une présence constante.';

  @override
  String get recentActivityTitle => 'Activité récente';

  @override
  String get recentActivitySub => 'Journal d\'audit et état de livraison';

  @override
  String get noRecentActivity => 'Aucun travail terminé pour l\'instant.';

  @override
  String get contentLibraryTitle => 'Bibliothèque de contenu multiplateforme';

  @override
  String get searchHint => 'Rechercher des publications, campagnes ou tags...';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterDraft => 'Brouillons';

  @override
  String get filterScheduled => 'Planifiées';

  @override
  String get filterPublished => 'Publiées';

  @override
  String get filterFailed => 'Échouées / Bloquées';

  @override
  String get noPostsMatch => 'Aucune publication ne correspond aux filtres.';

  @override
  String get noPostsMatchSub => 'Essayez d\'ajuster les critères de recherche.';

  @override
  String get deleteDraftTitle => 'Supprimer le brouillon ?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Supprimer \"$title\" ?';
  }

  @override
  String get draftDeletedSnack => 'Brouillon supprimé.';

  @override
  String get calendarTitle => 'Calendrier éditorial planifié';

  @override
  String get calendarEmptyTitle => 'La file éditoriale est vide';

  @override
  String get calendarEmptySub => 'Aucune publication planifiée.';

  @override
  String get registryTitle => 'Registre des marques et canaux';

  @override
  String get connectedWorkspaceTitle => 'Espace de travail social connecté';

  @override
  String get connectedWorkspaceSub =>
      'Gérez vos identités multiplateformes et publiez sur Instagram, X, LinkedIn et YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Canaux sociaux ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Groupes de canaux ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portefeuille d\'entreprises ($count)';
  }

  @override
  String get noCompaniesTitle => 'Aucune entreprise enregistrée';

  @override
  String get noCompaniesSub => 'Commencez par enregistrer votre entreprise.';

  @override
  String get noGroupsTitle => 'Aucun groupe de canaux';

  @override
  String get noGroupsSub =>
      'Les groupes vous permettent de regrouper plusieurs profils pour publier en une fois !';

  @override
  String get noChannelsForBrand => 'Aucun compte social pour cette marque.';

  @override
  String get btnConnectBrandChannel => '+ Connecter un canal';

  @override
  String get registerCompanyDialogTitle =>
      'Enregistrer une entreprise / marque';

  @override
  String get companyNameLabel => 'Nom de l\'entreprise / marque *';

  @override
  String get companyNameHint => 'ex. Acme Corporation';

  @override
  String get brandSlugLabel => 'Identifiant de marque *';

  @override
  String get brandSlugHint => 'ex. acme-corp';

  @override
  String get brandDescLabel => 'Description';

  @override
  String get brandDescHint => 'Résumé de cette entreprise ou marque';

  @override
  String get websiteUrlLabel => 'URL du site web (facultatif)';

  @override
  String get connectChannelDialogTitle => 'Connecter un canal social';

  @override
  String get connectChannelDialogSub =>
      'Liez un profil social pour planifier des publications.';

  @override
  String get selectCompanyLabel => 'Entreprise / Marque associée *';

  @override
  String get selectPlatformLabel => 'Plateforme de réseau social *';

  @override
  String get displayNameLabel => 'Nom d\'affichage *';

  @override
  String get displayNameHint => 'ex. Acme Tech Global';

  @override
  String get handleLabel => 'Identifiant / Nom d\'utilisateur *';

  @override
  String get handleHint => 'ex. @acme_officiel';

  @override
  String get disconnectConfirmTitle => 'Déconnecter le canal';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Déconnecter $handle ? L\'historique sera conservé.';
  }

  @override
  String get createGroupDialogTitle => 'Créer un groupe de canaux';

  @override
  String get createGroupDialogSub =>
      'Regroupez des comptes du même produit pour publier en une fois.';

  @override
  String get groupNameLabel => 'Nom du groupe *';

  @override
  String get groupNameHint => 'ex. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Description du groupe (facultatif)';

  @override
  String get groupDescHint => 'ex. Identités marketing principales';

  @override
  String groupSelectChannels(int count) {
    return 'Sélectionner les canaux ($count sélectionnés) :';
  }

  @override
  String get composerTitle => 'Compositeur de publications';

  @override
  String get composerEditTitle => 'Modifier la publication';

  @override
  String get stepChannelsTitle => '1. Sélectionner les canaux et groupes';

  @override
  String get stepChannelsEmptyBrands => 'Aucune entreprise enregistrée.';

  @override
  String get stepChannelsEmptyAccounts => 'Aucun canal connecté.';

  @override
  String get brandIdentityLabel => 'Identité de marque';

  @override
  String get quickSelectGroup => 'Sélection rapide par groupe :';

  @override
  String get destinationProfiles => 'Profils de destination :';

  @override
  String get stepPostDetails => '2. Détails de la publication';

  @override
  String get postTitleLabel => 'Titre de la publication *';

  @override
  String get postTitleHint => 'Nom de référence interne...';

  @override
  String get campaignLabel => 'Nom de la campagne (facultatif)';

  @override
  String get campaignHint => 'ex. Lancement Été 2026';

  @override
  String get tagsLabel => 'Tags / Catégorisation';

  @override
  String get tagsHint => 'marketing, lancement (séparés par des virgules)';

  @override
  String get stepContentCopy => '3. Contenu et légendes';

  @override
  String get sharedCaptionTab => 'Partagé (tous les réseaux)';

  @override
  String get captionLabel => 'Légende principale';

  @override
  String get captionHint => 'Écrivez votre message principal ici...';

  @override
  String get sameCaptionToggle =>
      'Utiliser la même légende sur tous les réseaux';

  @override
  String get stepMediaAssets => '4. Médias attachés';

  @override
  String get stepMediaAssetsSub =>
      'Sélectionnez des médias existants ou ajoutez-en de nouveaux.';

  @override
  String get addMediaAssetBtn => 'Ajouter un média';

  @override
  String get livePreviewTitle => 'Aperçu en direct';

  @override
  String get simulatedBadge => 'Simulé';

  @override
  String get previewEmptyPlaceholder =>
      'Sélectionnez au moins un canal pour afficher l\'aperçu.';

  @override
  String get preflightRulesTitle => 'Règles de vérification préalable';

  @override
  String btnQueueForPublication(int count) {
    return 'Mettre en file ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publier maintenant ($count cibles)';
  }

  @override
  String get draftSavedSnack => 'Brouillon enregistré.';

  @override
  String get confirmPublishTitle => 'Confirmer la publication multiple';

  @override
  String confirmPublishMessage(int count) {
    return 'Prêt à publier sur $count compte(s) ?';
  }

  @override
  String get settingsTitle => 'Paramètres de l\'espace de travail';

  @override
  String get settingsSubtitle =>
      'Gérez les préférences et inspectez les événements d\'audit.';

  @override
  String get dbManagementTitle => 'Gestion de la base de données';

  @override
  String get dbManagementSub =>
      'Gérez les enregistrements SQLite locaux ou chargez des données de démonstration.';

  @override
  String get wipeConfirmTitle => 'Confirmer la suppression';

  @override
  String get wipeConfirmMessage => 'Supprimer TOUTES les données ?';

  @override
  String get dbWipedSnack => 'Base de données réinitialisée.';

  @override
  String get demoLoadedSnack => 'Données de démonstration chargées.';

  @override
  String get loginTitle => 'Bienvenue sur no5ocial';

  @override
  String get loginSubtitle =>
      'Votre espace de travail de publication sociale tout-en-un';

  @override
  String get loginWithGoogle => 'Continuer avec Google';

  @override
  String get loginDisclaimer => 'En continuant, vous acceptez nos';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get disclaimer => 'Avertissement';

  @override
  String get loginLocalNote =>
      'Vos données sont stockées localement sur cet appareil.';

  @override
  String get andText => 'et';
}
