// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Espaço de Trabalho de Publicação Social';

  @override
  String get proWorkspace => 'PLANO PRO';

  @override
  String get navQueue => 'Fila de Publicação';

  @override
  String get navContent => 'Biblioteca de Conteúdo';

  @override
  String get navCalendar => 'Calendário Editorial';

  @override
  String get navChannels => 'Canais Conectados';

  @override
  String get navSettings => 'Configurações';

  @override
  String get btnNewPost => 'Nova Publicação';

  @override
  String get btnCreatePost => 'Criar Publicação';

  @override
  String get btnComposePost => 'Redigir Publicação';

  @override
  String get btnQueuePost => 'Adicionar à Fila';

  @override
  String get btnSchedule => 'Agendar';

  @override
  String get btnShareNow => 'Compartilhar Agora';

  @override
  String get btnSaveDraft => 'Salvar Rascunho';

  @override
  String get btnConnectChannel => 'Conectar Canal';

  @override
  String get btnCreateChannelGroup => 'Criar Grupo de Canais';

  @override
  String get btnRegisterCompany => 'Registrar Empresa';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get btnSave => 'Salvar';

  @override
  String get btnConfirm => 'Confirmar';

  @override
  String get btnDelete => 'Excluir';

  @override
  String get btnClose => 'Fechar';

  @override
  String get btnDisconnect => 'Desconectar';

  @override
  String get btnSchedulePost => 'Agendar Publicação';

  @override
  String get btnConfirmWipe => 'Confirmar e Limpar Dados';

  @override
  String get btnClearAllData => 'Limpar Todos os Dados';

  @override
  String get btnLoadDemoData => 'Carregar Dados de Demonstração';

  @override
  String get consoleTitle => 'Console de Operações de Publicação';

  @override
  String get growthWorkspace => 'Espaço de Crescimento';

  @override
  String get selectTimezoneTitle => 'Selecionar Fuso Horário';

  @override
  String languageSetTo(String language) {
    return 'Idioma definido como: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Canais Ativos';
  }

  @override
  String channelsConnected(int count) {
    return '$count Canais Conectados';
  }

  @override
  String get heroTitle => 'Expanda Seu Alcance em Todas as Redes Sociais';

  @override
  String get heroSubtitle =>
      'Planeje e publique no Instagram, X, LinkedIn e YouTube de uma fila unificada.';

  @override
  String actionRequiredTitle(int count) {
    return 'Ação Necessária ($count problemas)';
  }

  @override
  String get actionRequiredSub =>
      'Um ou mais destinos requerem revisão manual.';

  @override
  String get metricDrafts => 'Rascunhos';

  @override
  String get metricDraftsSub => 'Ideias em andamento';

  @override
  String get metricScheduled => 'Agendadas';

  @override
  String get metricScheduledSub => 'Próximas na fila';

  @override
  String get metricPublished => 'Publicadas';

  @override
  String get metricPublishedSub => 'Ao vivo nos canais';

  @override
  String get metricNeedsReview => 'Precisa de Revisão';

  @override
  String get metricNeedsReviewSub => 'Ação necessária';

  @override
  String get queueSectionTitle => 'Próximas na Fila de Publicação';

  @override
  String get queueEmptyTitle => 'Sua fila de publicação está vazia';

  @override
  String get queueEmptySubtitle =>
      'Planeje publicações para manter presença constante.';

  @override
  String get recentActivityTitle => 'Atividade Recente';

  @override
  String get recentActivitySub => 'Log de auditoria e status de entrega';

  @override
  String get noRecentActivity => 'Nenhum trabalho concluído ainda.';

  @override
  String get contentLibraryTitle => 'Biblioteca de Conteúdo Multiplataforma';

  @override
  String get searchHint => 'Buscar publicações, campanhas ou tags...';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterDraft => 'Rascunhos';

  @override
  String get filterScheduled => 'Agendadas';

  @override
  String get filterPublished => 'Publicadas';

  @override
  String get filterFailed => 'Falhou / Bloqueada';

  @override
  String get noPostsMatch => 'Nenhuma publicação corresponde aos filtros.';

  @override
  String get noPostsMatchSub => 'Ajuste os critérios de busca.';

  @override
  String get deleteDraftTitle => 'Excluir Rascunho?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Excluir \"$title\"?';
  }

  @override
  String get draftDeletedSnack => 'Rascunho excluído.';

  @override
  String get calendarTitle => 'Calendário Editorial Agendado';

  @override
  String get calendarEmptyTitle => 'Fila editorial está vazia';

  @override
  String get calendarEmptySub => 'Nenhuma publicação agendada.';

  @override
  String get registryTitle => 'Registro de Marcas e Canais';

  @override
  String get connectedWorkspaceTitle => 'Espaço de Trabalho Social Conectado';

  @override
  String get connectedWorkspaceSub =>
      'Gerencie suas identidades multiplataforma e publique no Instagram, X, LinkedIn e YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Canais Sociais ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Grupos de Canais ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portfólio de Empresas ($count)';
  }

  @override
  String get noCompaniesTitle => 'Nenhuma Empresa Registrada';

  @override
  String get noCompaniesSub => 'Comece registrando sua empresa.';

  @override
  String get noGroupsTitle => 'Nenhum Grupo de Canais';

  @override
  String get noGroupsSub =>
      'Grupos permitem agrupar vários perfis para publicar de uma vez!';

  @override
  String get noChannelsForBrand => 'Nenhuma conta social para esta marca.';

  @override
  String get btnConnectBrandChannel => '+ Conectar Canal';

  @override
  String get registerCompanyDialogTitle => 'Registrar Empresa / Marca';

  @override
  String get companyNameLabel => 'Nome da Empresa / Marca *';

  @override
  String get companyNameHint => 'ex. Acme Corporation';

  @override
  String get brandSlugLabel => 'Identificador da Marca *';

  @override
  String get brandSlugHint => 'ex. acme-corp';

  @override
  String get brandDescLabel => 'Descrição';

  @override
  String get brandDescHint => 'Resumo desta empresa ou marca';

  @override
  String get websiteUrlLabel => 'URL do Site (Opcional)';

  @override
  String get connectChannelDialogTitle => 'Conectar Canal Social';

  @override
  String get connectChannelDialogSub =>
      'Vincule um perfil social para agendar publicações.';

  @override
  String get selectCompanyLabel => 'Empresa / Marca Associada *';

  @override
  String get selectPlatformLabel => 'Plataforma de Rede Social *';

  @override
  String get displayNameLabel => 'Nome de Exibição *';

  @override
  String get displayNameHint => 'ex. Acme Tech Global';

  @override
  String get handleLabel => 'Handle / ID de Usuário *';

  @override
  String get handleHint => 'ex. @acme_oficial';

  @override
  String get disconnectConfirmTitle => 'Desconectar Canal';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Desconectar $handle? O histórico permanecerá salvo.';
  }

  @override
  String get createGroupDialogTitle => 'Criar Grupo de Canais';

  @override
  String get createGroupDialogSub =>
      'Agrupe contas do mesmo produto para publicar de uma vez.';

  @override
  String get groupNameLabel => 'Nome do Grupo *';

  @override
  String get groupNameHint => 'ex. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Descrição do Grupo (Opcional)';

  @override
  String get groupDescHint => 'ex. Identidades de marketing global';

  @override
  String groupSelectChannels(int count) {
    return 'Selecionar Canais ($count selecionados):';
  }

  @override
  String get composerTitle => 'Compositor de Publicações';

  @override
  String get composerEditTitle => 'Editar Publicação';

  @override
  String get stepChannelsTitle => '1. Selecionar Canais e Grupos';

  @override
  String get stepChannelsEmptyBrands => 'Nenhuma empresa registrada.';

  @override
  String get stepChannelsEmptyAccounts => 'Nenhum canal conectado.';

  @override
  String get brandIdentityLabel => 'Identidade de Marca';

  @override
  String get quickSelectGroup => 'Seleção rápida por Grupo:';

  @override
  String get destinationProfiles => 'Perfis de Destino:';

  @override
  String get stepPostDetails => '2. Detalhes da Publicação';

  @override
  String get postTitleLabel => 'Título da Publicação *';

  @override
  String get postTitleHint => 'Nome de referência interna...';

  @override
  String get campaignLabel => 'Nome da Campanha (Opcional)';

  @override
  String get campaignHint => 'ex. Lançamento Verão 2026';

  @override
  String get tagsLabel => 'Tags / Categorização';

  @override
  String get tagsHint => 'marketing, lançamento (separados por vírgulas)';

  @override
  String get stepContentCopy => '3. Conteúdo e Legendas';

  @override
  String get sharedCaptionTab => 'Compartilhado (Todas as Redes)';

  @override
  String get captionLabel => 'Legenda Principal';

  @override
  String get captionHint => 'Escreva sua mensagem principal aqui...';

  @override
  String get sameCaptionToggle => 'Usar a mesma legenda em todas as redes';

  @override
  String get stepMediaAssets => '4. Mídias Anexadas';

  @override
  String get stepMediaAssetsSub =>
      'Selecione mídias existentes ou adicione novas.';

  @override
  String get addMediaAssetBtn => 'Adicionar Mídia';

  @override
  String get livePreviewTitle => 'Pré-visualização ao Vivo';

  @override
  String get simulatedBadge => 'Simulado';

  @override
  String get previewEmptyPlaceholder =>
      'Selecione pelo menos um canal para pré-visualizar.';

  @override
  String get preflightRulesTitle => 'Regras de Verificação Prévia';

  @override
  String btnQueueForPublication(int count) {
    return 'Adicionar à Fila ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publicar Agora ($count destinos)';
  }

  @override
  String get draftSavedSnack => 'Rascunho salvo.';

  @override
  String get confirmPublishTitle => 'Confirmar Publicação Múltipla';

  @override
  String confirmPublishMessage(int count) {
    return 'Pronto para publicar em $count conta(s)?';
  }

  @override
  String get settingsTitle => 'Configurações do Espaço de Trabalho';

  @override
  String get settingsSubtitle =>
      'Gerencie preferências e inspecione eventos de auditoria.';

  @override
  String get dbManagementTitle => 'Gerenciamento de Banco de Dados';

  @override
  String get dbManagementSub =>
      'Gerencie registros SQLite locais ou carregue dados de demonstração.';

  @override
  String get wipeConfirmTitle => 'Confirmar Limpeza';

  @override
  String get wipeConfirmMessage => 'Excluir TODOS os dados?';

  @override
  String get dbWipedSnack => 'Banco de dados redefinido.';

  @override
  String get demoLoadedSnack => 'Dados de demonstração carregados.';

  @override
  String get loginTitle => 'Bem-vindo ao no5ocial';

  @override
  String get loginSubtitle =>
      'Seu espaço de trabalho de publicação social tudo-em-um';

  @override
  String get loginWithGoogle => 'Continuar com Google';

  @override
  String get loginDisclaimer => 'Ao continuar, você concorda com nossos';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get disclaimer => 'Isenção de Responsabilidade';

  @override
  String get loginLocalNote =>
      'Seus dados são armazenados localmente neste dispositivo.';

  @override
  String get andText => 'e';
}
