// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Ruang Kerja Penerbitan & Penjadualan Media Sosial';

  @override
  String get proWorkspace => 'RUANG KERJA PRO';

  @override
  String get navQueue => 'Barisan Penerbitan';

  @override
  String get navContent => 'Pustaka Kandungan';

  @override
  String get navCalendar => 'Kalendar Penerbitan';

  @override
  String get navChannels => 'Saluran Bersambung';

  @override
  String get navSettings => 'Tetapan Ruang Kerja';

  @override
  String get btnNewPost => 'Hantaran Baharu';

  @override
  String get btnCreatePost => 'Cipta Hantaran';

  @override
  String get btnComposePost => 'Tulis Hantaran';

  @override
  String get btnQueuePost => 'Masukkan Barisan';

  @override
  String get btnSchedule => 'Jadualkan';

  @override
  String get btnShareNow => 'Kongsi Sekarang';

  @override
  String get btnSaveDraft => 'Simpan Draf';

  @override
  String get btnConnectChannel => 'Sambung Saluran';

  @override
  String get btnCreateChannelGroup => 'Cipta Kumpulan Saluran';

  @override
  String get btnRegisterCompany => 'Daftar Syarikat';

  @override
  String get btnCancel => 'Batal';

  @override
  String get btnSave => 'Simpan';

  @override
  String get btnConfirm => 'Sahkan';

  @override
  String get btnDelete => 'Padam';

  @override
  String get btnClose => 'Tutup';

  @override
  String get btnDisconnect => 'Putuskan';

  @override
  String get btnSchedulePost => 'Jadualkan Hantaran';

  @override
  String get btnConfirmWipe => 'Sahkan & Padam Data';

  @override
  String get btnClearAllData => 'Kosongkan Semua Data & Mula Semula';

  @override
  String get btnLoadDemoData => 'Muat Data Demo';

  @override
  String get consoleTitle => 'Konsol Operasi Penerbitan';

  @override
  String get growthWorkspace => 'Ruang Kerja Pertumbuhan';

  @override
  String get selectTimezoneTitle => 'Pilih Zon Masa Penerbitan';

  @override
  String languageSetTo(String language) {
    return 'Bahasa ditetapkan kepada: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Saluran Aktif';
  }

  @override
  String channelsConnected(int count) {
    return '$count Saluran Bersambung';
  }

  @override
  String get heroTitle => 'Tingkatkan Jangkauan Anda di Semua Rangkaian Sosial';

  @override
  String get heroSubtitle =>
      'Rancang, bekerjasama dan jadualkan hantaran di Instagram, X, LinkedIn dan YouTube dari satu barisan bersepadu.';

  @override
  String actionRequiredTitle(int count) {
    return 'Tindakan Diperlukan ($count Isu Destinasi)';
  }

  @override
  String get actionRequiredSub =>
      'Satu atau lebih destinasi mengalami tamat masa atau memerlukan tindakan manual. Semak dan selesaikan di bawah:';

  @override
  String get metricDrafts => 'Draf';

  @override
  String get metricDraftsSub => 'Idea & sedang diproses';

  @override
  String get metricScheduled => 'Dijadualkan';

  @override
  String get metricScheduledSub => 'Seterusnya dalam barisan';

  @override
  String get metricPublished => 'Diterbitkan';

  @override
  String get metricPublishedSub => 'Langsung di saluran';

  @override
  String get metricNeedsReview => 'Perlu Semakan';

  @override
  String get metricNeedsReviewSub => 'Tindakan diperlukan';

  @override
  String get queueSectionTitle => 'Barisan Penerbitan Akan Datang';

  @override
  String get queueEmptyTitle => 'Barisan penerbitan anda kosong';

  @override
  String get queueEmptySubtitle =>
      'Rancang dan bariskan hantaran untuk mengekalkan kehadiran media sosial yang konsisten.';

  @override
  String get recentActivityTitle => 'Aktiviti Penerbitan Terkini';

  @override
  String get recentActivitySub =>
      'Log audit pelaksanaan & status penghantaran masa nyata';

  @override
  String get noRecentActivity =>
      'Tiada tugasan selesai lagi. Hantaran yang diterbitkan akan dipaparkan di sini.';

  @override
  String get contentLibraryTitle => 'Pustaka Kandungan Pelbagai Platform';

  @override
  String get searchHint => 'Cari hantaran, kapsyen, kempen atau tag...';

  @override
  String get filterAll => 'Semua Hantaran';

  @override
  String get filterDraft => 'Draf';

  @override
  String get filterScheduled => 'Dijadualkan';

  @override
  String get filterPublished => 'Diterbitkan';

  @override
  String get filterFailed => 'Gagal / Disekat';

  @override
  String get noPostsMatch => 'Tiada hantaran yang sepadan dengan penapis anda.';

  @override
  String get noPostsMatchSub => 'Cuba laraskan carian atau penapis jenama.';

  @override
  String get deleteDraftTitle => 'Padam Draf Hantaran?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Adakah anda pasti mahu memadam \"$title\"? Ini akan membatalkan tugasan berkaitan.';
  }

  @override
  String get draftDeletedSnack => 'Draf hantaran dipadamkan.';

  @override
  String get calendarTitle => 'Kalendar Editorial Dijadualkan';

  @override
  String get calendarEmptyTitle => 'Barisan editorial kosong';

  @override
  String get calendarEmptySub =>
      'Tiada hantaran akan datang dijadualkan dalam zon masa anda.';

  @override
  String get registryTitle => 'Pendaftaran Jenama & Saluran';

  @override
  String get connectedWorkspaceTitle => 'Ruang Kerja Sosial Bersambung';

  @override
  String get connectedWorkspaceSub =>
      'Urus identiti pelbagai platform anda, gabungkan profil ke dalam Kumpulan, dan terbitkan dengan lancar ke Instagram, X, LinkedIn dan YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Saluran Sosial ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kumpulan Saluran ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portfolio Syarikat ($count)';
  }

  @override
  String get noCompaniesTitle => 'Tiada Syarikat Didaftarkan Lagi';

  @override
  String get noCompaniesSub =>
      'Mulakan dengan mendaftarkan syarikat anda untuk menyambung saluran sosial.';

  @override
  String get noGroupsTitle => 'Tiada Kumpulan Saluran Dicipta Lagi';

  @override
  String get noGroupsSub =>
      'Kumpulan membolehkan anda menggabungkan profil untuk produk yang sama untuk diterbitkan dengan satu klik!';

  @override
  String get noChannelsForBrand =>
      'Tiada akaun sosial didaftarkan untuk jenama ini lagi.';

  @override
  String get btnConnectBrandChannel => '+ Sambung Saluran';

  @override
  String get registerCompanyDialogTitle => 'Daftar Syarikat / Jenama';

  @override
  String get companyNameLabel => 'Nama Syarikat / Jenama *';

  @override
  String get companyNameHint => 'cth. Acme Corporation atau Nova Media';

  @override
  String get brandSlugLabel => 'Slug Jenama *';

  @override
  String get brandSlugHint => 'cth. acme-corp';

  @override
  String get brandDescLabel => 'Penerangan';

  @override
  String get brandDescHint => 'Ringkasan ringkas syarikat atau jenama ini';

  @override
  String get websiteUrlLabel => 'URL Laman Web (Pilihan)';

  @override
  String get connectChannelDialogTitle => 'Sambung Saluran Sosial';

  @override
  String get connectChannelDialogSub =>
      'Pautkan profil sosial untuk menjadualkan dan menerbitkan hantaran.';

  @override
  String get selectCompanyLabel => 'Syarikat / Jenama Berkaitan *';

  @override
  String get selectPlatformLabel => 'Platform Rangkaian Sosial *';

  @override
  String get displayNameLabel => 'Nama Paparan *';

  @override
  String get displayNameHint => 'cth. Acme Tech Global';

  @override
  String get handleLabel => 'Nama Pengguna / ID *';

  @override
  String get handleHint => 'cth. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Putuskan Sambungan Saluran';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Adakah anda pasti mahu memutuskan sambungan $handle? Sejarah hantaran terdahulu akan kekal disimpan.';
  }

  @override
  String get createGroupDialogTitle => 'Cipta Kumpulan Saluran';

  @override
  String get createGroupDialogSub =>
      'Gabungkan beberapa akaun untuk produk yang sama (cth. Acme Instagram + Acme X) untuk diterbitkan ke semua serentak.';

  @override
  String get groupNameLabel => 'Nama Kumpulan *';

  @override
  String get groupNameHint => 'cth. Acme Global (IG + X)';

  @override
  String get groupDescLabel => 'Penerangan Kumpulan (Pilihan)';

  @override
  String get groupDescHint => 'cth. Identiti pemasaran utama global';

  @override
  String groupSelectChannels(int count) {
    return 'Pilih Saluran untuk Digabungkan ($count dipilih):';
  }

  @override
  String get composerTitle => 'Pengarang Hantaran Komersial';

  @override
  String get composerEditTitle => 'Edit Hantaran';

  @override
  String get stepChannelsTitle => '1. Pilih Saluran & Kumpulan';

  @override
  String get stepChannelsEmptyBrands =>
      'Tiada syarikat didaftarkan lagi. Daftar syarikat di Saluran Bersambung.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Tiada saluran sosial bersambung lagi. Pergi ke Saluran Bersambung untuk memautkan akaun.';

  @override
  String get brandIdentityLabel => 'Identiti Jenama / Syarikat';

  @override
  String get quickSelectGroup => 'Pilih Pantas mengikut Kumpulan Saluran:';

  @override
  String get destinationProfiles => 'Profil Sasaran:';

  @override
  String get stepPostDetails => '2. Butiran Hantaran';

  @override
  String get postTitleLabel => 'Tajuk Hantaran *';

  @override
  String get postTitleHint => 'Nama rujukan dalaman untuk kempen ini...';

  @override
  String get campaignLabel => 'Nama Kempen (Pilihan)';

  @override
  String get campaignHint => 'cth. Pelancaran Musim Panas 2026';

  @override
  String get tagsLabel => 'Tag / Pengkategorian';

  @override
  String get tagsHint => 'pemasaran, pelancaran (dipisahkan dengan koma)';

  @override
  String get stepContentCopy => '3. Kandungan & Kapsyen';

  @override
  String get sharedCaptionTab => 'Kongsi (Semua Rangkaian)';

  @override
  String get captionLabel => 'Kapsyen Hantaran Utama';

  @override
  String get captionHint => 'Tulis mesej utama anda di sini...';

  @override
  String get sameCaptionToggle => 'Gunakan Kapsyen Sama di Semua Rangkaian';

  @override
  String get stepMediaAssets => '4. Aset Media Dilampirkan';

  @override
  String get stepMediaAssetsSub =>
      'Pilih aset sedia ada dari pustaka atau klik \"Tambah Aset Media\".';

  @override
  String get addMediaAssetBtn => 'Tambah Aset Media';

  @override
  String get livePreviewTitle => 'Pratonton Media Sosial Langsung';

  @override
  String get simulatedBadge => 'Disimulasikan';

  @override
  String get previewEmptyPlaceholder =>
      'Pilih sekurang-kurangnya satu saluran sasaran untuk melihat pratonton.';

  @override
  String get preflightRulesTitle => 'Peraturan Pra-Penerbitan';

  @override
  String btnQueueForPublication(int count) {
    return 'Masukkan Barisan ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Terbitkan Sekarang ($count Sasaran)';
  }

  @override
  String get draftSavedSnack => 'Draf disimpan ke pustaka.';

  @override
  String get confirmPublishTitle => 'Sahkan Penerbitan Pelbagai Destinasi';

  @override
  String confirmPublishMessage(int count) {
    return 'Adakah anda bersedia untuk menerbitkan ke $count akaun sasaran? Setiap akaun akan diterbitkan secara berasingan.';
  }

  @override
  String get settingsTitle => 'Tetapan Ruang Kerja';

  @override
  String get settingsSubtitle =>
      'Urus keutamaan ruang kerja, periksa peristiwa audit dan konfigurasikan tetapan.';

  @override
  String get dbManagementTitle => 'Pengurusan Pangkalan Data & Ruang Kerja';

  @override
  String get dbManagementSub =>
      'Urus rekod SQLite tempatan, tetapkan semula ruang kerja atau muat data demo.';

  @override
  String get wipeConfirmTitle => 'Sahkan Pengosongan Pangkalan Data';

  @override
  String get wipeConfirmMessage =>
      'Adakah anda pasti mahu memadam SEMUA data? Ini akan memadam jenama, akaun, kumpulan dan draf dari SQLite tempatan.';

  @override
  String get dbWipedSnack =>
      'Pangkalan data ruang kerja ditetapkan semula (0 rekod).';

  @override
  String get demoLoadedSnack => 'Sampel data demo dimuatkan ke SQLite.';

  @override
  String get loginTitle => 'Selamat Datang ke no5ocial';

  @override
  String get loginSubtitle =>
      'Ruang kerja penerbitan sosial semua-dalam-satu anda';

  @override
  String get loginWithGoogle => 'Teruskan dengan Google';

  @override
  String get loginDisclaimer => 'Dengan meneruskan, anda bersetuju dengan';

  @override
  String get termsOfService => 'Syarat Perkhidmatan';

  @override
  String get privacyPolicy => 'Dasar Privasi';

  @override
  String get disclaimer => 'Penafian';

  @override
  String get loginLocalNote =>
      'Data anda disimpan secara tempatan pada peranti ini sahaja.';

  @override
  String get andText => 'dan';
}
