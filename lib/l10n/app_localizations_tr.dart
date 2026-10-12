// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'Sosyal Medya Yayınlama ve Planlama Çalışma Alanı';

  @override
  String get proWorkspace => 'PRO ÇALIŞMA ALANI';

  @override
  String get navQueue => 'Yayın Sırası';

  @override
  String get navContent => 'İçerik Kütüphanesi';

  @override
  String get navCalendar => 'Yayın Takvimi';

  @override
  String get navChannels => 'Bağlı Kanallar';

  @override
  String get navSettings => 'Çalışma Alanı Ayarları';

  @override
  String get btnNewPost => 'Yeni Gönderi';

  @override
  String get btnCreatePost => 'Gönderi Oluştur';

  @override
  String get btnComposePost => 'Gönderi Yaz';

  @override
  String get btnQueuePost => 'Sıraya Ekle';

  @override
  String get btnSchedule => 'Planla';

  @override
  String get btnShareNow => 'Şimdi Paylaş';

  @override
  String get btnSaveDraft => 'Taslak Olarak Kaydet';

  @override
  String get btnConnectChannel => 'Kanal Bağla';

  @override
  String get btnCreateChannelGroup => 'Kanal Grubu Oluştur';

  @override
  String get btnRegisterCompany => 'Şirket Kaydet';

  @override
  String get btnCancel => 'İptal';

  @override
  String get btnSave => 'Kaydet';

  @override
  String get btnConfirm => 'Onayla';

  @override
  String get btnDelete => 'Sil';

  @override
  String get btnClose => 'Kapat';

  @override
  String get btnDisconnect => 'Bağlantıyı Kes';

  @override
  String get btnSchedulePost => 'Gönderi Planla';

  @override
  String get btnConfirmWipe => 'Onayla ve Verileri Sil';

  @override
  String get btnClearAllData => 'Tüm Verileri Temizle ve Sıfırla';

  @override
  String get btnLoadDemoData => 'Örnek Demo Verisi Yükle';

  @override
  String get consoleTitle => 'Yayın İşlemleri Konsolu';

  @override
  String get growthWorkspace => 'Büyüme Çalışma Alanı';

  @override
  String get selectTimezoneTitle => 'Yayın Saat Dilimini Seçin';

  @override
  String languageSetTo(String language) {
    return 'Dil ayarlandı: $language';
  }

  @override
  String channelsActive(int count) {
    return '$count Kanal Aktif';
  }

  @override
  String channelsConnected(int count) {
    return '$count Kanal Bağlı';
  }

  @override
  String get heroTitle => 'Tüm Sosyal Ağlarda Erişiminizi Artırın';

  @override
  String get heroSubtitle =>
      'Instagram, X, LinkedIn ve YouTube\'da etkileşimli gönderileri tek bir sıradan planlayın, işbirliği yapın ve yayınlayın.';

  @override
  String actionRequiredTitle(int count) {
    return 'İşlem Gerekiyor ($count Hedef Sorunu)';
  }

  @override
  String get actionRequiredSub =>
      'Bir veya daha fazla hedefte zaman aşımı oluştu veya manuel müdahale gerekiyor. Aşağıdan inceleyin ve çözün:';

  @override
  String get metricDrafts => 'Taslaklar';

  @override
  String get metricDraftsSub => 'Fikirler ve devam edenler';

  @override
  String get metricScheduled => 'Planlanmış';

  @override
  String get metricScheduledSub => 'Sıradaki gönderiler';

  @override
  String get metricPublished => 'Yayınlandı';

  @override
  String get metricPublishedSub => 'Kanallarda canlı';

  @override
  String get metricNeedsReview => 'İnceleme Gerekiyor';

  @override
  String get metricNeedsReviewSub => 'İşlem gerekiyor';

  @override
  String get queueSectionTitle => 'Yaklaşan Yayın Sırası';

  @override
  String get queueEmptyTitle => 'Yayın sıranız boş';

  @override
  String get queueEmptySubtitle =>
      'Tüm ağlarınızda tutarlı bir sosyal medya varlığı sürdürmek için gelecek gönderileri planlayın ve sıraya ekleyin.';

  @override
  String get recentActivityTitle => 'Son Yayın Etkinliği';

  @override
  String get recentActivitySub =>
      'Yürütme denetim günlüğü ve gerçek zamanlı teslimat durumu';

  @override
  String get noRecentActivity =>
      'Henüz tamamlanmış görev yok. Yayınlanan gönderiler burada görünecektir.';

  @override
  String get contentLibraryTitle => 'Çok Platformlu İçerik Kütüphanesi';

  @override
  String get searchHint =>
      'Gönderileri, açıklamaları, kampanyaları veya etiketleri arayın...';

  @override
  String get filterAll => 'Tüm Gönderiler';

  @override
  String get filterDraft => 'Taslaklar';

  @override
  String get filterScheduled => 'Planlanmış';

  @override
  String get filterPublished => 'Yayınlandı';

  @override
  String get filterFailed => 'Başarısız / Engellendi';

  @override
  String get noPostsMatch => 'Filtrelerinize uyan gönderi bulunamadı.';

  @override
  String get noPostsMatchSub =>
      'Arama sorgusunu veya marka filtresini ayarlamayı deneyin.';

  @override
  String get deleteDraftTitle => 'Gönderi Taslağını Sil?';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\" taslağını silmek istediğinizden emin misiniz? Bu işlem ilişkili görevleri iptal eder.';
  }

  @override
  String get draftDeletedSnack => 'Gönderi taslağı silindi.';

  @override
  String get calendarTitle => 'Planlanmış Yayın Takvimi';

  @override
  String get calendarEmptyTitle => 'Yayın takvimi boş';

  @override
  String get calendarEmptySub =>
      'Saat diliminizde planlanmış yaklaşan gönderi yok.';

  @override
  String get registryTitle => 'Marka ve Kanal Kaydı';

  @override
  String get connectedWorkspaceTitle => 'Bağlı Sosyal Çalışma Alanı';

  @override
  String get connectedWorkspaceSub =>
      'Çok platformlu kimliklerinizi yönetin, aynı ürün profillerini Gruplarda birleştirin ve Instagram, X (Twitter), LinkedIn ve YouTube\'da sorunsuz yayınlayın.';

  @override
  String tabSocialChannels(int count) {
    return 'Sosyal Kanallar ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'Kanal Grupları ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return 'Şirket Portföyü ($count)';
  }

  @override
  String get noCompaniesTitle => 'Henüz Kayıtlı Şirket Yok';

  @override
  String get noCompaniesSub =>
      'Sosyal kanalları bağlamak için şirketinizi kaydederek başlayın.';

  @override
  String get noGroupsTitle => 'Henüz Kanal Grubu Oluşturulmadı';

  @override
  String get noGroupsSub =>
      'Gruplar, aynı ürün için birden fazla profili birleştirerek tek tıklamayla hepsine yayın yapmanızı sağlar!';

  @override
  String get noChannelsForBrand =>
      'Bu marka için henüz kayıtlı sosyal hesap yok.';

  @override
  String get btnConnectBrandChannel => '+ Kanal Bağla';

  @override
  String get registerCompanyDialogTitle => 'Şirket / Marka Kaydet';

  @override
  String get companyNameLabel => 'Şirket / Marka Adı *';

  @override
  String get companyNameHint => 'ör. Acme Corporation veya Nova Media';

  @override
  String get brandSlugLabel => 'Marka Kısa Adı *';

  @override
  String get brandSlugHint => 'ör. acme-corp';

  @override
  String get brandDescLabel => 'Açıklama';

  @override
  String get brandDescHint => 'Bu şirket veya markanın kısa özeti';

  @override
  String get websiteUrlLabel => 'Web Sitesi URL (İsteğe Bağlı)';

  @override
  String get connectChannelDialogTitle => 'Sosyal Kanal Bağla';

  @override
  String get connectChannelDialogSub =>
      'Gönderi planlamak ve yayınlamak için platformlar arası bir sosyal profil bağlayın.';

  @override
  String get selectCompanyLabel => 'İlişkili Şirket / Marka *';

  @override
  String get selectPlatformLabel => 'Sosyal Ağ Platformu *';

  @override
  String get displayNameLabel => 'Görünen Ad *';

  @override
  String get displayNameHint => 'ör. Acme Tech Global';

  @override
  String get handleLabel => 'Kullanıcı Adı / ID *';

  @override
  String get handleHint => 'ör. @acme_official';

  @override
  String get disconnectConfirmTitle => 'Kanal Bağlantısını Kes';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handle bağlantısını kesmek istediğinizden emin misiniz? Bu kanala ait geçmiş gönderiler kayıtlı kalacaktır.';
  }

  @override
  String get createGroupDialogTitle => 'Kanal Grubu Oluştur';

  @override
  String get createGroupDialogSub =>
      'Aynı ürün için birden fazla hesabı paketleyin (ör. Acme Instagram + Acme X) ve hepsine aynı anda yayın yapın.';

  @override
  String get groupNameLabel => 'Grup Adı *';

  @override
  String get groupNameHint => 'ör. Acme Global Paketi (IG + X)';

  @override
  String get groupDescLabel => 'Grup Açıklaması (İsteğe Bağlı)';

  @override
  String get groupDescHint => 'ör. Küresel birincil pazarlama kimlikleri';

  @override
  String groupSelectChannels(int count) {
    return 'Paketlenecek Kanalları Seçin ($count seçildi):';
  }

  @override
  String get composerTitle => 'Profesyonel Gönderi Oluşturucu';

  @override
  String get composerEditTitle => 'Gönderiyi Düzenle';

  @override
  String get stepChannelsTitle => '1. Kanalları ve Grupları Seçin';

  @override
  String get stepChannelsEmptyBrands =>
      'Henüz kayıtlı şirket yok. Profilleri düzenlemek için Bağlı Kanallar bölümünden bir şirket kaydedin.';

  @override
  String get stepChannelsEmptyAccounts =>
      'Henüz bağlı sosyal kanal yok. Instagram, X, LinkedIn veya YouTube hesaplarını bağlamak için Bağlı Kanallar\'a gidin.';

  @override
  String get brandIdentityLabel => 'Marka / Şirket Kimliği';

  @override
  String get quickSelectGroup => 'Kanal Grubuna Göre Hızlı Seçim:';

  @override
  String get destinationProfiles => 'Hedef Profiller:';

  @override
  String get stepPostDetails => '2. Gönderi Ayrıntıları';

  @override
  String get postTitleLabel => 'Gönderi Başlığı *';

  @override
  String get postTitleHint => 'Bu kampanya için dahili referans adı...';

  @override
  String get campaignLabel => 'Kampanya Adı (İsteğe Bağlı)';

  @override
  String get campaignHint => 'ör. Yaz Lansmanı 2026';

  @override
  String get tagsLabel => 'Etiketler / Kategorizasyon';

  @override
  String get tagsHint => 'pazarlama, lansman, guncelleme (virgülle ayırın)';

  @override
  String get stepContentCopy => '3. İçerik ve Açıklamalar';

  @override
  String get sharedCaptionTab => 'Paylaşılan (Tüm Ağlar)';

  @override
  String get captionLabel => 'Ana Gönderi Metni';

  @override
  String get captionHint => 'Ana mesajınızı buraya yazın...';

  @override
  String get sameCaptionToggle => 'Tüm Ağlarda Aynı Metni Kullan';

  @override
  String get stepMediaAssets => '4. Ekli Medya Dosyaları';

  @override
  String get stepMediaAssetsSub =>
      'Kütüphanenizden varlıkları seçin veya yeni görseller/videolar eklemek için \"Medya Dosyası Ekle\"ye tıklayın.';

  @override
  String get addMediaAssetBtn => 'Medya Dosyası Ekle';

  @override
  String get livePreviewTitle => 'Canlı Sosyal Medya Önizlemesi';

  @override
  String get simulatedBadge => 'Simüle Edildi';

  @override
  String get previewEmptyPlaceholder =>
      'Önizlemeyi görmek için en az bir hedef kanal seçin.';

  @override
  String get preflightRulesTitle => 'Yayın Öncesi Kuralları';

  @override
  String btnQueueForPublication(int count) {
    return 'Yayın Sırasına Ekle ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return 'Şimdi Yayınla ($count Hedef)';
  }

  @override
  String get draftSavedSnack => 'Taslak kütüphaneye kaydedildi.';

  @override
  String get confirmPublishTitle => 'Çoklu Hedef Yayını Onayla';

  @override
  String confirmPublishMessage(int count) {
    return '$count hedef hesaba yayınlamaya hazır mısınız? Her hesap bağımsız olarak yayınlanacaktır.';
  }

  @override
  String get settingsTitle => 'Çalışma Alanı Ayarları';

  @override
  String get settingsSubtitle =>
      'Çalışma alanı tercihlerini yönetin, denetim etkinliklerini inceleyin ve ayarları yapılandırın.';

  @override
  String get dbManagementTitle => 'Veritabanı ve Çalışma Alanı Yönetimi';

  @override
  String get dbManagementSub =>
      'Yerel SQLite veritabanı kayıtlarını yönetin, çalışma alanı durumunu sıfırlayın veya demo verileri yükleyin.';

  @override
  String get wipeConfirmTitle => 'Veritabanını Sıfırlamayı Onayla';

  @override
  String get wipeConfirmMessage =>
      'TÜM verileri silmek istediğinizden emin misiniz? Bu işlem kayıtlı markaları, hesapları, grupları, taslakları ve işleri yerel SQLite\'tan kaldıracaktır.';

  @override
  String get dbWipedSnack => 'Çalışma alanı veritabanı sıfırlandı (0 kayıt).';

  @override
  String get demoLoadedSnack => 'Örnek demo verileri SQLite\'a yüklendi.';

  @override
  String get loginTitle => 'no5ocial\'a Hoş Geldiniz';

  @override
  String get loginSubtitle =>
      'Hepsi bir arada sosyal yayınlama çalışma alanınız';

  @override
  String get loginWithGoogle => 'Google ile Devam Et';

  @override
  String get loginDisclaimer => 'Devam ederek şunları kabul etmiş olursunuz:';

  @override
  String get termsOfService => 'Kullanım Koşulları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get disclaimer => 'Sorumluluk Reddi';

  @override
  String get loginLocalNote =>
      'Verileriniz yalnızca bu cihazda yerel olarak saklanır.';

  @override
  String get andText => 've';
}
