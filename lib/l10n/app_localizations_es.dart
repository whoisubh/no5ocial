// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Espacio de Trabajo de Publicación Social';

  @override
  String get proWorkspace => 'PLAN PRO';

  @override
  String get navQueue => 'Cola de Publicación';

  @override
  String get navContent => 'Biblioteca de Contenido';

  @override
  String get navCalendar => 'Calendario Editorial';

  @override
  String get navChannels => 'Canales Conectados';

  @override
  String get navSettings => 'Configuración';

  @override
  String get btnNewPost => 'Nueva Publicación';

  @override
  String get btnCreatePost => 'Crear Publicación';

  @override
  String get btnComposePost => 'Redactar Publicación';

  @override
  String get btnQueuePost => 'Encolar Publicación';

  @override
  String get btnSchedule => 'Programar';

  @override
  String get btnShareNow => 'Compartir Ahora';

  @override
  String get btnSaveDraft => 'Guardar Borrador';

  @override
  String get btnConnectChannel => 'Conectar Canal';

  @override
  String get btnCreateChannelGroup => 'Crear Grupo de Canales';

  @override
  String get btnRegisterCompany => 'Registrar Empresa';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get btnSave => 'Guardar';

  @override
  String get btnConfirm => 'Confirmar';

  @override
  String get btnDelete => 'Eliminar';

  @override
  String get btnClose => 'Cerrar';

  @override
  String get btnDisconnect => 'Desconectar';

  @override
  String get btnSchedulePost => 'Programar Publicación';

  @override
  String get btnConfirmWipe => 'Confirmar y Borrar Datos';

  @override
  String get btnClearAllData => 'Borrar Todo y Empezar de Cero';

  @override
  String get btnLoadDemoData => 'Cargar Datos de Demostración';

  @override
  String get consoleTitle => 'Consola de Operaciones de Publicación';

  @override
  String get growthWorkspace => 'Espacio de Crecimiento';

  @override
  String get selectTimezoneTitle => 'Seleccionar Zona Horaria';

  @override
  String languageSetTo(String language) {
    return 'Idioma establecido en: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Canales Activos';
  }

  @override
  String channelsConnected(int count) {
    return '$count Canales Conectados';
  }

  @override
  String get heroTitle => 'Amplía tu Alcance en Todas las Redes Sociales';

  @override
  String get heroSubtitle =>
      'Planifica, colabora y programa publicaciones en Instagram, X, LinkedIn y YouTube desde una cola unificada.';

  @override
  String actionRequiredTitle(int count) {
    return 'Acción Requerida ($count Problemas)';
  }

  @override
  String get actionRequiredSub =>
      'Uno o más destinos requieren revisión manual.';

  @override
  String get metricDrafts => 'Borradores';

  @override
  String get metricDraftsSub => 'Ideas en progreso';

  @override
  String get metricScheduled => 'Programados';

  @override
  String get metricScheduledSub => 'Próximos en cola';

  @override
  String get metricPublished => 'Publicados';

  @override
  String get metricPublishedSub => 'En vivo';

  @override
  String get metricNeedsReview => 'Requiere Revisión';

  @override
  String get metricNeedsReviewSub => 'Acción requerida';

  @override
  String get queueSectionTitle => 'Cola de Publicación Próxima';

  @override
  String get queueEmptyTitle => 'Tu cola de publicación está vacía';

  @override
  String get queueEmptySubtitle =>
      'Planifica y encola publicaciones para mantener presencia constante.';

  @override
  String get recentActivityTitle => 'Actividad Reciente';

  @override
  String get recentActivitySub => 'Registro de auditoría y estado de entrega';

  @override
  String get noRecentActivity => 'Sin trabajos completados aún.';

  @override
  String get contentLibraryTitle => 'Biblioteca de Contenido Multiplataforma';

  @override
  String get searchHint => 'Buscar publicaciones, campañas o etiquetas...';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterDraft => 'Borradores';

  @override
  String get filterScheduled => 'Programadas';

  @override
  String get filterPublished => 'Publicadas';

  @override
  String get filterFailed => 'Fallidas / Bloqueadas';

  @override
  String get noPostsMatch => 'No hay publicaciones que coincidan.';

  @override
  String get noPostsMatchSub => 'Ajusta los filtros de búsqueda.';

  @override
  String get deleteDraftTitle => '¿Eliminar Borrador?';

  @override
  String deleteDraftConfirm(String title) {
    return '¿Seguro que deseas eliminar \"$title\"?';
  }

  @override
  String get draftDeletedSnack => 'Borrador eliminado.';

  @override
  String get calendarTitle => 'Calendario Editorial Programado';

  @override
  String get calendarEmptyTitle => 'La cola editorial está vacía';

  @override
  String get calendarEmptySub => 'No hay publicaciones programadas.';

  @override
  String get registryTitle => 'Registro de Marcas y Canales';

  @override
  String get connectedWorkspaceTitle => 'Espacio de Trabajo Social Conectado';

  @override
  String get connectedWorkspaceSub =>
      'Gestiona identidades multiplataforma y publica en Instagram, X, LinkedIn y YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Canales Sociales ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Grupos de Canales ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portafolio de Empresas ($count)';
  }

  @override
  String get noCompaniesTitle => 'Sin Empresas Registradas';

  @override
  String get noCompaniesSub =>
      'Registra tu empresa para conectar canales sociales.';

  @override
  String get noGroupsTitle => 'Sin Grupos de Canales';

  @override
  String get noGroupsSub =>
      '¡Los grupos te permiten agrupar múltiples perfiles para publicar en todos con un clic!';

  @override
  String get noChannelsForBrand => 'Sin cuentas sociales para esta marca.';

  @override
  String get btnConnectBrandChannel => '+ Conectar Canal';

  @override
  String get registerCompanyDialogTitle => 'Registrar Empresa / Marca';

  @override
  String get companyNameLabel => 'Nombre de Empresa / Marca *';

  @override
  String get companyNameHint => 'ej. Acme Corporación';

  @override
  String get brandSlugLabel => 'Slug de Marca *';

  @override
  String get brandSlugHint => 'ej. acme-corp';

  @override
  String get brandDescLabel => 'Descripción';

  @override
  String get brandDescHint => 'Resumen de esta empresa o marca';

  @override
  String get websiteUrlLabel => 'URL del Sitio Web (Opcional)';

  @override
  String get connectChannelDialogTitle => 'Conectar Canal Social';

  @override
  String get connectChannelDialogSub =>
      'Vincula un perfil social para programar publicaciones.';

  @override
  String get selectCompanyLabel => 'Empresa / Marca Asociada *';

  @override
  String get selectPlatformLabel => 'Plataforma de Red Social *';

  @override
  String get displayNameLabel => 'Nombre para Mostrar *';

  @override
  String get displayNameHint => 'ej. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / ID de Usuario *';

  @override
  String get handleHint => 'ej. @acme_oficial';

  @override
  String get disconnectConfirmTitle => 'Desconectar Canal';

  @override
  String disconnectConfirmMessage(String handle) {
    return '¿Desconectar $handle? El historial permanecerá guardado.';
  }

  @override
  String get createGroupDialogTitle => 'Crear Grupo de Canales';

  @override
  String get createGroupDialogSub =>
      'Agrupa cuentas del mismo producto para publicar en todas a la vez.';

  @override
  String get groupNameLabel => 'Nombre del Grupo *';

  @override
  String get groupNameHint => 'ej. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Descripción del Grupo (Opcional)';

  @override
  String get groupDescHint => 'ej. Identidades principales de marketing global';

  @override
  String groupSelectChannels(int count) {
    return 'Seleccionar Canales ($count seleccionados):';
  }

  @override
  String get composerTitle => 'Compositor de Publicaciones';

  @override
  String get composerEditTitle => 'Editar Publicación';

  @override
  String get stepChannelsTitle => '1. Seleccionar Canales y Grupos';

  @override
  String get stepChannelsEmptyBrands => 'Sin empresas registradas.';

  @override
  String get stepChannelsEmptyAccounts => 'Sin canales conectados.';

  @override
  String get brandIdentityLabel => 'Identidad de Marca / Empresa';

  @override
  String get quickSelectGroup => 'Selección rápida por Grupo:';

  @override
  String get destinationProfiles => 'Perfiles de Destino:';

  @override
  String get stepPostDetails => '2. Detalles de la Publicación';

  @override
  String get postTitleLabel => 'Título de la Publicación *';

  @override
  String get postTitleHint => 'Nombre interno de referencia...';

  @override
  String get campaignLabel => 'Nombre de Campaña (Opcional)';

  @override
  String get campaignHint => 'ej. Lanzamiento Verano 2026';

  @override
  String get tagsLabel => 'Etiquetas / Categorización';

  @override
  String get tagsHint => 'marketing, lanzamiento (separados por comas)';

  @override
  String get stepContentCopy => '3. Contenido y Textos';

  @override
  String get sharedCaptionTab => 'Compartido (Todas las Redes)';

  @override
  String get captionLabel => 'Texto Principal de la Publicación';

  @override
  String get captionHint => 'Escribe tu mensaje principal aquí...';

  @override
  String get sameCaptionToggle => 'Usar el mismo texto en todas las redes';

  @override
  String get stepMediaAssets => '4. Archivos Multimedia';

  @override
  String get stepMediaAssetsSub =>
      'Selecciona archivos existentes o agrega nuevos.';

  @override
  String get addMediaAssetBtn => 'Agregar Multimedia';

  @override
  String get livePreviewTitle => 'Vista Previa en Vivo';

  @override
  String get simulatedBadge => 'Simulado';

  @override
  String get previewEmptyPlaceholder =>
      'Selecciona al menos un canal de destino para previsualizar.';

  @override
  String get preflightRulesTitle => 'Reglas de Verificación Previa';

  @override
  String btnQueueForPublication(int count) {
    return 'Encolar para Publicación ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publicar Ahora ($count destinos)';
  }

  @override
  String get draftSavedSnack => 'Borrador guardado.';

  @override
  String get confirmPublishTitle => 'Confirmar Publicación Múltiple';

  @override
  String confirmPublishMessage(int count) {
    return '¿Listo para publicar en $count cuenta(s)?';
  }

  @override
  String get settingsTitle => 'Configuración del Espacio de Trabajo';

  @override
  String get settingsSubtitle =>
      'Gestiona preferencias e inspecciona eventos de auditoría.';

  @override
  String get dbManagementTitle => 'Gestión de Base de Datos';

  @override
  String get dbManagementSub =>
      'Administra registros locales de SQLite o carga datos de demostración.';

  @override
  String get wipeConfirmTitle => 'Confirmar Borrado';

  @override
  String get wipeConfirmMessage =>
      '¿Seguro que deseas eliminar TODOS los datos?';

  @override
  String get dbWipedSnack => 'Base de datos restablecida.';

  @override
  String get demoLoadedSnack => 'Datos de demostración cargados.';

  @override
  String get loginTitle => 'Bienvenido a no5ocial';

  @override
  String get loginSubtitle =>
      'Tu espacio de trabajo de publicación social todo en uno';

  @override
  String get loginWithGoogle => 'Continuar con Google';

  @override
  String get loginDisclaimer => 'Al continuar, aceptas nuestros';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get disclaimer => 'Descargo de Responsabilidad';

  @override
  String get loginLocalNote =>
      'Tus datos se almacenan localmente en este dispositivo.';

  @override
  String get andText => 'y';
}
