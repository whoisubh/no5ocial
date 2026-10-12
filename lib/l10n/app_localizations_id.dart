// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Ruang Kerja Penerbitan & Penjadwalan Sosial';

  @override
  String get proWorkspace => 'RUANG KERJA PRO';

  @override
  String get navQueue => 'Antrean Penerbitan';

  @override
  String get navContent => 'Pustaka Konten';

  @override
  String get navCalendar => 'Kalender Penerbitan';

  @override
  String get navChannels => 'Saluran Terhubung';

  @override
  String get navSettings => 'Pengaturan Ruang Kerja';

  @override
  String get btnNewPost => 'Postingan Baru';

  @override
  String get btnCreatePost => 'Buat Postingan';

  @override
  String get btnComposePost => 'Tulis Postingan';

  @override
  String get btnQueuePost => 'Masukkan Antrean';

  @override
  String get btnSchedule => 'Jadwalkan';

  @override
  String get btnShareNow => 'Bagikan Sekarang';

  @override
  String get btnSaveDraft => 'Simpan Draf';

  @override
  String get btnConnectChannel => 'Hubungkan Saluran';

  @override
  String get btnCreateChannelGroup => 'Buat Grup Saluran';

  @override
  String get btnRegisterCompany => 'Daftarkan Perusahaan';

  @override
  String get btnCancel => 'Batal';

  @override
  String get btnSave => 'Simpan';

  @override
  String get btnConfirm => 'Konfirmasi';

  @override
  String get btnDelete => 'Hapus';

  @override
  String get btnClose => 'Tutup';

  @override
  String get btnDisconnect => 'Putuskan';

  @override
  String get btnSchedulePost => 'Jadwalkan Postingan';

  @override
  String get btnConfirmWipe => 'Konfirmasi & Hapus Data';

  @override
  String get btnClearAllData => 'Hapus Semua Data & Mulai Baru';

  @override
  String get btnLoadDemoData => 'Muat Data Demo';

  @override
  String get consoleTitle => 'Konsol Operasi Penerbitan';

  @override
  String get growthWorkspace => 'Ruang Kerja Pertumbuhan';

  @override
  String get selectTimezoneTitle => 'Pilih Zona Waktu Penerbitan';

  @override
  String languageSetTo(String language) {
    return 'Bahasa diatur ke: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Saluran Aktif';
  }

  @override
  String channelsConnected(int count) {
    return '$count Saluran Terhubung';
  }

  @override
  String get heroTitle => 'Tingkatkan Jangkauan Anda di Setiap Jaringan Sosial';

  @override
  String get heroSubtitle =>
      'Rencanakan, kolaborasi, dan jadwalkan postingan menarik di Instagram, X, LinkedIn, dan YouTube dari satu antrean terpadu.';

  @override
  String actionRequiredTitle(int count) {
    return 'Tindakan Diperlukan ($count Masalah Tujuan)';
  }

  @override
  String get actionRequiredSub =>
      'Satu atau lebih tujuan mengalami batas waktu atau memerlukan penanganan manual. Tinjau dan selesaikan di bawah:';

  @override
  String get metricDrafts => 'Draf';

  @override
  String get metricDraftsSub => 'Ide & sedang diproses';

  @override
  String get metricScheduled => 'Terjadwal';

  @override
  String get metricScheduledSub => 'Berikutnya dalam antrean';

  @override
  String get metricPublished => 'Diterbitkan';

  @override
  String get metricPublishedSub => 'Tayang di saluran';

  @override
  String get metricNeedsReview => 'Perlu Ditinjau';

  @override
  String get metricNeedsReviewSub => 'Tindakan diperlukan';

  @override
  String get queueSectionTitle => 'Antrean Penerbitan Mendatang';

  @override
  String get queueEmptyTitle => 'Antrean penerbitan Anda kosong';

  @override
  String get queueEmptySubtitle =>
      'Rencanakan dan antrekan postingan mendatang untuk menjaga kehadiran media sosial yang konsisten di seluruh jaringan Anda.';

  @override
  String get recentActivityTitle => 'Aktivitas Penerbitan Terkini';

  @override
  String get recentActivitySub =>
      'Log audit eksekusi & status pengiriman real-time';

  @override
  String get noRecentActivity =>
      'Belum ada tugas selesai. Postingan yang diterbitkan akan muncul di sini.';

  @override
  String get contentLibraryTitle => 'Pustaka Konten Multi-Platform';

  @override
  String get searchHint => 'Cari postingan, keterangan, kampanye, atau tag...';

  @override
  String get filterAll => 'Semua Postingan';

  @override
  String get filterDraft => 'Draf';

  @override
  String get filterScheduled => 'Terjadwal';

  @override
  String get filterPublished => 'Diterbitkan';

  @override
  String get filterFailed => 'Gagal / Diblokir';

  @override
  String get noPostsMatch =>
      'Tidak ada postingan yang cocok dengan filter Anda.';

  @override
  String get noPostsMatchSub =>
      'Coba sesuaikan kueri pencarian atau filter merek.';

  @override
  String get deleteDraftTitle => 'Hapus Draf Postingan?';

  @override
  String deleteDraftConfirm(String title) {
    return 'Apakah Anda yakin ingin menghapus \"$title\"? Ini akan membatalkan tugas terkait.';
  }

  @override
  String get draftDeletedSnack => 'Draf postingan dihapus.';

  @override
  String get calendarTitle => 'Kalender Editorial Terjadwal';

  @override
  String get calendarEmptyTitle => 'Antrean editorial kosong';

  @override
  String get calendarEmptySub =>
      'Tidak ada postingan mendatang yang dijadwalkan di zona waktu Anda.';

  @override
  String get registryTitle => 'Registri Merek & Saluran';

  @override
  String get connectedWorkspaceTitle => 'Ruang Kerja Sosial Terhubung';

  @override
  String get connectedWorkspaceSub =>
      'Kelola identitas multi-platform Anda, gabungkan profil produk yang sama ke dalam Grup, dan publikasikan dengan lancar ke Instagram, X (Twitter), LinkedIn, dan YouTube.';

  @override
  String tabSocialChannels(int count) {
    return 'Saluran Sosial ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Grup Saluran ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Portofolio Perusahaan ($count)';
  }

  @override
  String get noCompaniesTitle => 'Belum Ada Perusahaan Terdaftar';

  @override
  String get noCompaniesSub =>
      'Mulailah dengan mendaftarkan perusahaan Anda untuk menghubungkan saluran sosial.';

  @override
  String get noGroupsTitle => 'Belum Ada Grup Saluran Dibuat';

  @override
  String get noGroupsSub =>
      'Grup memungkinkan Anda menggabungkan beberapa profil sosial untuk produk yang sama guna mempublikasikan ke semuanya dengan sekali klik!';

  @override
  String get noChannelsForBrand =>
      'Belum ada akun sosial yang terdaftar untuk merek ini.';

  @override
  String get btnConnectBrandChannel => '+ Hubungkan Saluran';

  @override
  String get registerCompanyDialogTitle => 'Daftarkan Perusahaan / Merek';

  @override
  String get companyNameLabel => 'Nama Perusahaan / Merek *';

  @override
  String get companyNameHint => 'mis. Acme Corporation atau Nova Media';

  @override
  String get brandSlugLabel => 'Slug Merek *';

  @override
  String get brandSlugHint => 'mis. acme-corp';

  @override
  String get brandDescLabel => 'Deskripsi';

  @override
  String get brandDescHint => 'Ringkasan singkat perusahaan atau merek ini';

  @override
  String get websiteUrlLabel => 'URL Situs Web (Opsional)';

  @override
  String get connectChannelDialogTitle => 'Hubungkan Saluran Sosial';

  @override
  String get connectChannelDialogSub =>
      'Tautkan profil sosial di berbagai platform untuk menjadwalkan dan mempublikasikan postingan.';

  @override
  String get selectCompanyLabel => 'Perusahaan / Merek Terkait *';

  @override
  String get selectPlatformLabel => 'Platform Jaringan Sosial *';

  @override
  String get displayNameLabel => 'Nama Tampilan *';

  @override
  String get displayNameHint => 'mis. Acme Tech Global';

  @override
  String get handleLabel => 'Nama Pengguna / ID *';

  @override
  String get handleHint => 'mis. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Putuskan Sambungan Saluran';

  @override
  String disconnectConfirmMessage(String handle) {
    return 'Apakah Anda yakin ingin memutuskan sambungan $handle? Postingan sebelumnya yang merujuk pada saluran ini akan tetap disimpan.';
  }

  @override
  String get createGroupDialogTitle => 'Buat Grup Saluran';

  @override
  String get createGroupDialogSub =>
      'Gabungkan beberapa akun untuk produk yang sama (mis. Acme Instagram + Acme X) agar dapat menerbitkan ke semua sekaligus.';

  @override
  String get groupNameLabel => 'Nama Grup *';

  @override
  String get groupNameHint => 'mis. Acme Global Bundle (IG + X)';

  @override
  String get groupDescLabel => 'Deskripsi Grup (Opsional)';

  @override
  String get groupDescHint => 'mis. Identitas pemasaran utama global';

  @override
  String groupSelectChannels(int count) {
    return 'Pilih Saluran yang Digabung ($count dipilih):';
  }

  @override
  String get composerTitle => 'Penyusun Postingan Komersial';

  @override
  String get composerEditTitle => 'Edit Postingan';

  @override
  String get stepChannelsTitle => '1. Pilih Saluran & Grup';

  @override
  String get stepChannelsEmptyBrands =>
      'Belum ada perusahaan terdaftar. Daftarkan perusahaan di Saluran Terhubung untuk mengatur profil.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Belum ada saluran sosial yang terhubung. Buka Saluran Terhubung untuk menautkan akun.';

  @override
  String get brandIdentityLabel => 'Identitas Merek / Perusahaan';

  @override
  String get quickSelectGroup => 'Pilih Cepat berdasarkan Grup Saluran:';

  @override
  String get destinationProfiles => 'Profil Tujuan:';

  @override
  String get stepPostDetails => '2. Detail Postingan';

  @override
  String get postTitleLabel => 'Judul Postingan *';

  @override
  String get postTitleHint => 'Nama referensi internal untuk kampanye ini...';

  @override
  String get campaignLabel => 'Nama Kampanye (Opsional)';

  @override
  String get campaignHint => 'mis. Peluncuran Musim Panas 2026';

  @override
  String get tagsLabel => 'Tag / Kategorisasi';

  @override
  String get tagsHint =>
      'pemasaran, peluncuran, pembaruan (pisahkan dengan koma)';

  @override
  String get stepContentCopy => '3. Konten & Keterangan';

  @override
  String get sharedCaptionTab => 'Bersama (Semua Jaringan)';

  @override
  String get captionLabel => 'Keterangan Postingan Utama';

  @override
  String get captionHint => 'Tulis pesan postingan utama Anda di sini...';

  @override
  String get sameCaptionToggle => 'Gunakan Keterangan Sama di Semua Jaringan';

  @override
  String get stepMediaAssets => '4. Aset Media Terlampir';

  @override
  String get stepMediaAssetsSub =>
      'Pilih aset yang ada dari pustaka Anda atau klik \"Tambah Aset Media\" untuk menautkan gambar/video baru.';

  @override
  String get addMediaAssetBtn => 'Tambah Aset Media';

  @override
  String get livePreviewTitle => 'Pratinjau Media Sosial Langsung';

  @override
  String get simulatedBadge => 'Disimulasikan';

  @override
  String get previewEmptyPlaceholder =>
      'Pilih setidaknya satu saluran tujuan untuk melihat pratinjau.';

  @override
  String get preflightRulesTitle => 'Aturan Pra-Penerbitan';

  @override
  String btnQueueForPublication(int count) {
    return 'Masukkan Antrean ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Publikasikan Sekarang ($count Tujuan)';
  }

  @override
  String get draftSavedSnack => 'Draf disimpan ke pustaka.';

  @override
  String get confirmPublishTitle => 'Konfirmasi Publikasi Multi-Tujuan';

  @override
  String confirmPublishMessage(int count) {
    return 'Apakah Anda siap untuk mempublikasikan ke $count akun tujuan? Setiap akun akan diterbitkan secara independen.';
  }

  @override
  String get settingsTitle => 'Pengaturan Ruang Kerja';

  @override
  String get settingsSubtitle =>
      'Kelola preferensi ruang kerja, periksa peristiwa audit, dan konfigurasikan pengaturan.';

  @override
  String get dbManagementTitle => 'Manajemen Database & Ruang Kerja';

  @override
  String get dbManagementSub =>
      'Kelola catatan SQLite lokal, setel ulang status ruang kerja, atau muat data demo.';

  @override
  String get wipeConfirmTitle => 'Konfirmasi Pembersihan Database';

  @override
  String get wipeConfirmMessage =>
      'Apakah Anda yakin ingin menghapus SEMUA data? Ini akan menghapus merek, akun, grup, dan draf dari SQLite lokal.';

  @override
  String get dbWipedSnack =>
      'Database ruang kerja disetel ulang ke keadaan bersih (0 catatan).';

  @override
  String get demoLoadedSnack => 'Data demo sampel dimuat ke SQLite.';

  @override
  String get loginTitle => 'Selamat Datang di no5ocial';

  @override
  String get loginSubtitle => 'Ruang kerja penerbitan sosial lengkap Anda';

  @override
  String get loginWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get loginDisclaimer => 'Dengan melanjutkan, Anda menyetujui';

  @override
  String get termsOfService => 'Ketentuan Layanan';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get disclaimer => 'Penafian';

  @override
  String get loginLocalNote =>
      'Data Anda hanya disimpan secara lokal di perangkat ini.';

  @override
  String get andText => 'dan';
}
