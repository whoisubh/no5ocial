// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'no5ocial';

  @override
  String get appTagline => 'ソーシャルパブリッシング&スケジューリングワークスペース';

  @override
  String get proWorkspace => 'プロプラン';

  @override
  String get navQueue => '投稿キュー';

  @override
  String get navContent => 'コンテンツライブラリ';

  @override
  String get navCalendar => '編集カレンダー';

  @override
  String get navChannels => '接続チャンネル';

  @override
  String get navSettings => '設定';

  @override
  String get btnNewPost => '新規投稿';

  @override
  String get btnCreatePost => '投稿を作成';

  @override
  String get btnComposePost => '投稿を作成';

  @override
  String get btnQueuePost => 'キューに追加';

  @override
  String get btnSchedule => 'スケジュール';

  @override
  String get btnShareNow => '今すぐ共有';

  @override
  String get btnSaveDraft => '下書きとして保存';

  @override
  String get btnConnectChannel => 'チャンネルを接続';

  @override
  String get btnCreateChannelGroup => 'チャンネルグループを作成';

  @override
  String get btnRegisterCompany => '会社を登録';

  @override
  String get btnCancel => 'キャンセル';

  @override
  String get btnSave => '保存';

  @override
  String get btnConfirm => '確認';

  @override
  String get btnDelete => '削除';

  @override
  String get btnClose => '閉じる';

  @override
  String get btnDisconnect => '切断';

  @override
  String get btnSchedulePost => '投稿をスケジュール';

  @override
  String get btnConfirmWipe => '確認してデータを消去';

  @override
  String get btnClearAllData => 'すべてのデータを消去';

  @override
  String get btnLoadDemoData => 'デモデータを読み込む';

  @override
  String get consoleTitle => 'パブリッシングオペレーションコンソール';

  @override
  String get growthWorkspace => 'グロースワークスペース';

  @override
  String get selectTimezoneTitle => 'タイムゾーンを選択';

  @override
  String languageSetTo(String language) {
    return '言語を$languageに設定しました';
  }

  @override
  String channelsActive(int count) {
    return '$countチャンネルがアクティブ';
  }

  @override
  String channelsConnected(int count) {
    return '$countチャンネルが接続済み';
  }

  @override
  String get heroTitle => 'すべてのソーシャルネットワークでリーチを拡大';

  @override
  String get heroSubtitle =>
      'Instagram、X、LinkedIn、YouTubeへの投稿を一つのキューで計画・スケジュール。';

  @override
  String actionRequiredTitle(int count) {
    return 'アクションが必要($count件の問題)';
  }

  @override
  String get actionRequiredSub => '1つ以上の配信先で手動対応が必要です。';

  @override
  String get metricDrafts => '下書き';

  @override
  String get metricDraftsSub => '作成中のアイデア';

  @override
  String get metricScheduled => 'スケジュール済み';

  @override
  String get metricScheduledSub => '次のキュー';

  @override
  String get metricPublished => '投稿済み';

  @override
  String get metricPublishedSub => 'チャンネルでライブ';

  @override
  String get metricNeedsReview => '要確認';

  @override
  String get metricNeedsReviewSub => 'アクションが必要';

  @override
  String get queueSectionTitle => '次回の投稿キュー';

  @override
  String get queueEmptyTitle => '投稿キューが空です';

  @override
  String get queueEmptySubtitle => '一貫したソーシャルメディアプレゼンスを維持するために投稿をキューに追加してください。';

  @override
  String get recentActivityTitle => '最近のアクティビティ';

  @override
  String get recentActivitySub => '監査ログとリアルタイム配信ステータス';

  @override
  String get noRecentActivity => '完了したジョブはまだありません。';

  @override
  String get contentLibraryTitle => 'マルチプラットフォームコンテンツライブラリ';

  @override
  String get searchHint => '投稿、キャンペーン、タグを検索...';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterDraft => '下書き';

  @override
  String get filterScheduled => 'スケジュール済み';

  @override
  String get filterPublished => '投稿済み';

  @override
  String get filterFailed => '失敗 / ブロック';

  @override
  String get noPostsMatch => 'フィルターに一致する投稿がありません。';

  @override
  String get noPostsMatchSub => '検索条件を調整してください。';

  @override
  String get deleteDraftTitle => '下書きを削除しますか？';

  @override
  String deleteDraftConfirm(String title) {
    return '\"$title\"を削除しますか？';
  }

  @override
  String get draftDeletedSnack => '下書きを削除しました。';

  @override
  String get calendarTitle => 'スケジュール済み編集カレンダー';

  @override
  String get calendarEmptyTitle => '編集キューが空です';

  @override
  String get calendarEmptySub => 'スケジュールされた投稿はありません。';

  @override
  String get registryTitle => 'ブランド&チャンネルレジストリ';

  @override
  String get connectedWorkspaceTitle => '接続済みソーシャルワークスペース';

  @override
  String get connectedWorkspaceSub => 'マルチプラットフォームのアイデンティティを管理し、シームレスに投稿。';

  @override
  String tabSocialChannels(int count) {
    return 'ソーシャルチャンネル ($count)';
  }

  @override
  String tabChannelGroups(int count) {
    return 'チャンネルグループ ($count)';
  }

  @override
  String tabCompanyPortfolio(int count) {
    return '企業ポートフォリオ ($count)';
  }

  @override
  String get noCompaniesTitle => '会社が登録されていません';

  @override
  String get noCompaniesSub => 'まず会社を登録してチャンネルを接続してください。';

  @override
  String get noGroupsTitle => 'チャンネルグループがありません';

  @override
  String get noGroupsSub => 'グループを使用すると複数のプロフィールを一度に投稿できます！';

  @override
  String get noChannelsForBrand => 'このブランドのソーシャルアカウントはありません。';

  @override
  String get btnConnectBrandChannel => '+ チャンネルを接続';

  @override
  String get registerCompanyDialogTitle => '会社 / ブランドを登録';

  @override
  String get companyNameLabel => '会社 / ブランド名 *';

  @override
  String get companyNameHint => '例: Acme株式会社';

  @override
  String get brandSlugLabel => 'ブランドスラッグ *';

  @override
  String get brandSlugHint => '例: acme-jp';

  @override
  String get brandDescLabel => '説明';

  @override
  String get brandDescHint => '会社またはブランドの概要';

  @override
  String get websiteUrlLabel => 'ウェブサイトURL（任意）';

  @override
  String get connectChannelDialogTitle => 'ソーシャルチャンネルを接続';

  @override
  String get connectChannelDialogSub => 'ソーシャルプロフィールをリンクして投稿をスケジュール。';

  @override
  String get selectCompanyLabel => '関連する会社 / ブランド *';

  @override
  String get selectPlatformLabel => 'ソーシャルネットワークプラットフォーム *';

  @override
  String get displayNameLabel => '表示名 *';

  @override
  String get displayNameHint => '例: Acme Tech Global';

  @override
  String get handleLabel => 'ハンドル / ユーザーID *';

  @override
  String get handleHint => '例: @acme_official';

  @override
  String get disconnectConfirmTitle => 'チャンネルを切断';

  @override
  String disconnectConfirmMessage(String handle) {
    return '$handleを切断しますか？履歴は保持されます。';
  }

  @override
  String get createGroupDialogTitle => 'チャンネルグループを作成';

  @override
  String get createGroupDialogSub => '同一製品の複数アカウントをまとめて一度に投稿。';

  @override
  String get groupNameLabel => 'グループ名 *';

  @override
  String get groupNameHint => '例: Acmeグローバル (IG + X)';

  @override
  String get groupDescLabel => 'グループの説明（任意）';

  @override
  String get groupDescHint => '例: グローバルマーケティングID';

  @override
  String groupSelectChannels(int count) {
    return 'バンドルするチャンネルを選択 ($count選択済み):';
  }

  @override
  String get composerTitle => '投稿コンポーザー';

  @override
  String get composerEditTitle => '投稿を編集';

  @override
  String get stepChannelsTitle => '1. チャンネルとグループを選択';

  @override
  String get stepChannelsEmptyBrands => '会社が登録されていません。';

  @override
  String get stepChannelsEmptyAccounts => 'チャンネルが接続されていません。';

  @override
  String get brandIdentityLabel => 'ブランド / 会社のアイデンティティ';

  @override
  String get quickSelectGroup => 'グループで素早く選択:';

  @override
  String get destinationProfiles => '配信先プロフィール:';

  @override
  String get stepPostDetails => '2. 投稿の詳細';

  @override
  String get postTitleLabel => '投稿タイトル *';

  @override
  String get postTitleHint => '内部参照名...';

  @override
  String get campaignLabel => 'キャンペーン名（任意）';

  @override
  String get campaignHint => '例: サマーローンチ 2026';

  @override
  String get tagsLabel => 'タグ / カテゴリ';

  @override
  String get tagsHint => 'マーケティング, ローンチ（カンマ区切り）';

  @override
  String get stepContentCopy => '3. コンテンツとキャプション';

  @override
  String get sharedCaptionTab => '共通（全ネットワーク）';

  @override
  String get captionLabel => 'メインキャプション';

  @override
  String get captionHint => 'メインメッセージをここに書いてください...';

  @override
  String get sameCaptionToggle => '全ネットワークで同じキャプションを使用';

  @override
  String get stepMediaAssets => '4. 添付メディア';

  @override
  String get stepMediaAssetsSub => '既存のメディアを選択するか新しいものを追加。';

  @override
  String get addMediaAssetBtn => 'メディアを追加';

  @override
  String get livePreviewTitle => 'ライブプレビュー';

  @override
  String get simulatedBadge => 'シミュレート';

  @override
  String get previewEmptyPlaceholder => 'プレビューには少なくとも1つのチャンネルを選択してください。';

  @override
  String get preflightRulesTitle => 'プリフライトルール';

  @override
  String btnQueueForPublication(int count) {
    return 'キューに追加 ($count)';
  }

  @override
  String btnPublishNow(int count) {
    return '今すぐ投稿 ($count件)';
  }

  @override
  String get draftSavedSnack => '下書きを保存しました。';

  @override
  String get confirmPublishTitle => 'マルチ配信を確認';

  @override
  String confirmPublishMessage(int count) {
    return '$count件のアカウントに投稿する準備ができていますか？';
  }

  @override
  String get settingsTitle => 'ワークスペース設定';

  @override
  String get settingsSubtitle => '設定を管理し、監査イベントを確認。';

  @override
  String get dbManagementTitle => 'データベース管理';

  @override
  String get dbManagementSub => 'ローカルSQLiteレコードを管理またはデモデータを読み込む。';

  @override
  String get wipeConfirmTitle => '削除を確認';

  @override
  String get wipeConfirmMessage => 'すべてのデータを削除しますか？';

  @override
  String get dbWipedSnack => 'データベースをリセットしました。';

  @override
  String get demoLoadedSnack => 'デモデータを読み込みました。';

  @override
  String get loginTitle => 'no5ocialへようこそ';

  @override
  String get loginSubtitle => 'オールインワンソーシャルパブリッシングワークスペース';

  @override
  String get loginWithGoogle => 'Googleで続ける';

  @override
  String get loginDisclaimer => '続けることで、以下に同意します';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get disclaimer => '免責事項';

  @override
  String get loginLocalNote => 'データはこのデバイスにローカルで保存されます。';

  @override
  String get andText => 'および';
}
