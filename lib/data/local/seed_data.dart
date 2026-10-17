import 'package:uuid/uuid.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';

abstract final class SeedData {
  static const _uuid = Uuid();

  // Brands
  static final Brand brandShaadow = Brand(
    id: 'brand-shaadow',
    name: 'Shaadow',
    slug: 'shaadow',
    description: 'Flagship brand & technology products',
    websiteUrl: 'https://shaadow.io',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static final Brand brandShaadowWorks = Brand(
    id: 'brand-shaadow-works',
    name: 'Shaadow Works',
    slug: 'shaadow-works',
    description: 'Engineering lab, open source & behind-the-scenes',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static final Brand brandBoofer = Brand(
    id: 'brand-boofer',
    name: 'Boofer',
    slug: 'boofer',
    description: 'Creative social media & meme brand',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static final Brand brandFavtunes = Brand(
    id: 'brand-favtunes',
    name: 'Favtunes',
    slug: 'favtunes',
    description: 'Music curation & discovery showcase',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static final Brand brandGalaxious = Brand(
    id: 'brand-galaxious',
    name: 'Galaxious',
    slug: 'galaxious',
    description: 'Futuristic gaming and sci-fi franchise',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static final Brand brandOwlAndFowl = Brand(
    id: 'brand-owl-and-fowl',
    name: 'Owl and Fowl Studios',
    slug: 'owl-and-fowl',
    description: 'Animation & video entertainment studio',
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );

  static List<Brand> get initialBrands => [
    brandShaadow,
    brandShaadowWorks,
    brandBoofer,
    brandFavtunes,
    brandGalaxious,
    brandOwlAndFowl,
  ];

  // Social Accounts from PRD
  static final SocialAccount accInstaShaadow = SocialAccount(
    id: 'acc-ig-shaadow',
    brandId: brandShaadow.id,
    platform: PlatformType.instagram,
    displayName: 'Shaadow',
    handle: '@shaadow',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['post', 'carousel', 'reels'],
    scopes: const ['instagram_basic', 'instagram_content_publish'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 9, 8, 30),
  );

  static final SocialAccount accInstaWorks = SocialAccount(
    id: 'acc-ig-works',
    brandId: brandShaadowWorks.id,
    platform: PlatformType.instagram,
    displayName: 'Shaadow Works',
    handle: '@shaadowworks',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['post', 'carousel'],
    scopes: const ['instagram_basic', 'instagram_content_publish'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 8, 14, 0),
  );

  static final SocialAccount accInstaBoofer = SocialAccount(
    id: 'acc-ig-boofer',
    brandId: brandBoofer.id,
    platform: PlatformType.instagram,
    displayName: 'Boofer Official',
    handle: '@boofer',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['post', 'reels'],
    scopes: const ['instagram_basic', 'instagram_content_publish'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 9, 10, 15),
  );

  static final SocialAccount accInstaOwl = SocialAccount(
    id: 'acc-ig-owl',
    brandId: brandOwlAndFowl.id,
    platform: PlatformType.instagram,
    displayName: 'Owl & Fowl Studios',
    handle: '@owlandfowlstudios',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['post', 'carousel', 'reels'],
    scopes: const ['instagram_basic', 'instagram_content_publish'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 9, 12, 0),
  );

  static final SocialAccount accYtShaadow = SocialAccount(
    id: 'acc-yt-shaadow',
    brandId: brandShaadow.id,
    platform: PlatformType.youtube,
    displayName: 'Shaadow',
    handle: 'Shaadow Official',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['video_upload', 'shorts'],
    scopes: const ['youtube.upload'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 9, 9, 0),
  );

  static final SocialAccount accYtOwl = SocialAccount(
    id: 'acc-yt-owl',
    brandId: brandOwlAndFowl.id,
    platform: PlatformType.youtube,
    displayName: 'Owl & Fowl Studios',
    handle: 'Owl and Fowl Studios',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['video_upload', 'shorts'],
    scopes: const ['youtube.upload'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 8, 16, 20),
  );

  static final SocialAccount accLinkedInShaadow = SocialAccount(
    id: 'acc-li-shaadow',
    brandId: brandShaadow.id,
    platform: PlatformType.linkedin,
    displayName: 'Shaadow Platforms',
    handle: 'Shaadow Platforms Company Page',
    connectionStatus: ConnectionStatus.connected,
    capabilities: const ['company_post', 'image', 'document'],
    scopes: const ['w_organization_social', 'r_organization_social'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 9, 11, 45),
  );

  static final SocialAccount accXBoofer = SocialAccount(
    id: 'acc-x-boofer',
    brandId: brandBoofer.id,
    platform: PlatformType.x,
    displayName: 'Boofer',
    handle: '@boofer',
    connectionStatus: ConnectionStatus.connected,
    isManualOnly: false,
    capabilities: const ['text', 'media'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 1, 10, 0),
  );

  static final SocialAccount accXShaadow = SocialAccount(
    id: 'acc-x-shaadow',
    brandId: brandShaadow.id,
    platform: PlatformType.x,
    displayName: 'Shaadow',
    handle: '@shaadow',
    connectionStatus: ConnectionStatus.connected,
    isManualOnly: false,
    capabilities: const ['text', 'media'],
    lastVerifiedAtUtc: DateTime.utc(2026, 10, 1, 10, 0),
  );

  static List<SocialAccount> get initialAccounts => [
    accInstaShaadow,
    accInstaWorks,
    accInstaBoofer,
    accInstaOwl,
    accYtShaadow,
    accYtOwl,
    accLinkedInShaadow,
    accXBoofer,
    accXShaadow,
  ];

  // Sample media assets
  static final MediaAsset assetKeyVisual = MediaAsset(
    id: 'asset-hero-1',
    fileName: 'shaadow_v2_launch_card.png',
    mimeType: 'image/png',
    sizeBytes: 1420500, // ~1.4 MB
    width: 1920,
    height: 1080,
    mediaType: MediaType.image,
    createdAtUtc: DateTime.utc(2026, 10, 8, 10, 0),
  );

  static final MediaAsset assetTeaserVideo = MediaAsset(
    id: 'asset-video-1',
    fileName: 'no5ocial_feature_walkthrough.mp4',
    mimeType: 'video/mp4',
    sizeBytes: 18540000, // ~18.5 MB
    width: 1920,
    height: 1080,
    durationMs: 45000,
    mediaType: MediaType.video,
    createdAtUtc: DateTime.utc(2026, 10, 9, 8, 0),
  );

  static List<MediaAsset> get initialMediaAssets => [
    assetKeyVisual,
    assetTeaserVideo,
  ];

  // Initial Content Post with multi-destination variants
  static List<ContentPost> get initialPosts {
    final now = DateTime.now().toUtc();
    return [
      ContentPost(
        id: 'post-welcome',
        brandId: brandShaadow.id,
        title: 'Announcing Shaadow v2 Architecture',
        defaultCaption: 'Excited to present the next generation of Shaadow architecture: ultra-low latency internal workflows and modular publishing! #Shaadow #Tech #ProductEngineering',
        mediaAssetIds: [assetKeyVisual.id],
        destinationAccountIds: [
          accInstaShaadow.id,
          accLinkedInShaadow.id,
          accXShaadow.id,
        ],
        tags: const ['architecture', 'announcement'],
        campaign: 'Q4 Launch',
        status: PublishJobStatus.published,
        createdAtUtc: now.subtract(const Duration(days: 2)),
        updatedAtUtc: now.subtract(const Duration(days: 2)),
      ),
      ContentPost(
        id: 'post-draft-1',
        brandId: brandBoofer.id,
        title: 'Weekend Meme Drop: When the build passes first try',
        defaultCaption: 'That rare feeling when you run flutter test and zero red lines appear on screen. Pure tranquility. 🧘‍♂️ #Boofer #DevLife #CodingMeme',
        mediaAssetIds: [assetKeyVisual.id],
        destinationAccountIds: [accInstaBoofer.id, accXBoofer.id],
        tags: const ['meme', 'weekend'],
        campaign: 'Social Memes',
        status: PublishJobStatus.draft,
        createdAtUtc: now.subtract(const Duration(hours: 4)),
        updatedAtUtc: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  static List<PostVariant> get initialVariants {
    return [
      PostVariant(
        id: 'variant-shaadow-ig',
        contentPostId: 'post-welcome',
        socialAccountId: accInstaShaadow.id,
        captionOverride: 'Excited to present the next generation of Shaadow architecture: ultra-low latency internal workflows and modular publishing! ✨ Swipe for the architectural breakdown.\n\n#Shaadow #Tech #ProductEngineering #Architecture',
        mediaAssetIds: [assetKeyVisual.id],
      ),
      PostVariant(
        id: 'variant-shaadow-li',
        contentPostId: 'post-welcome',
        socialAccountId: accLinkedInShaadow.id,
        captionOverride: 'We are proud to share our latest milestone at Shaadow Platforms: an internal publishing suite designed for maximum operational reliability, explicit auditability, and zero recurring seat costs.\n\nRead more about our engineering choices in our whitepaper.',
        mediaAssetIds: [assetKeyVisual.id],
      ),
      PostVariant(
        id: 'variant-shaadow-x',
        contentPostId: 'post-welcome',
        socialAccountId: accXShaadow.id,
        captionOverride: 'Announcing Shaadow v2 Architecture: modular publishing, predictable costs, zero boilerplate.',
        mediaAssetIds: [assetKeyVisual.id],
      ),
      PostVariant(
        id: 'variant-boofer-ig',
        contentPostId: 'post-draft-1',
        socialAccountId: accInstaBoofer.id,
        captionOverride: null, // uses default
        mediaAssetIds: [assetKeyVisual.id],
      ),
      PostVariant(
        id: 'variant-boofer-x',
        contentPostId: 'post-draft-1',
        socialAccountId: accXBoofer.id,
        captionOverride:
            'That feeling when flutter test has 0 errors on first try. 🧘‍♂️',
        mediaAssetIds: [assetKeyVisual.id],
      ),
    ];
  }

  static List<PublishJob> get initialJobs {
    final now = DateTime.now().toUtc();
    return [
      PublishJob(
        id: 'job-1',
        contentPostId: 'post-welcome',
        postVariantId: 'variant-shaadow-ig',
        socialAccountId: accInstaShaadow.id,
        status: PublishJobStatus.published,
        isManual: true,
        publishedAtUtc: now.subtract(const Duration(days: 2)),
        idempotencyKey: _uuid.v4(),
        externalPostId: 'ig_post_9921827419',
        externalUrl: 'https://instagram.com/p/DB102391024',
        createdAtUtc: now.subtract(const Duration(days: 2)),
        updatedAtUtc: now.subtract(const Duration(days: 2)),
      ),
      PublishJob(
        id: 'job-2',
        contentPostId: 'post-welcome',
        postVariantId: 'variant-shaadow-li',
        socialAccountId: accLinkedInShaadow.id,
        status: PublishJobStatus.published,
        isManual: true,
        publishedAtUtc: now.subtract(const Duration(days: 2)),
        idempotencyKey: _uuid.v4(),
        externalPostId: 'li_share_830219481',
        externalUrl: 'https://linkedin.com/feed/update/urn:li:share:830219481',
        createdAtUtc: now.subtract(const Duration(days: 2)),
        updatedAtUtc: now.subtract(const Duration(days: 2)),
      ),
      PublishJob(
        id: 'job-3',
        contentPostId: 'post-welcome',
        postVariantId: 'variant-shaadow-x',
        socialAccountId: accXShaadow.id,
        status: PublishJobStatus.published,
        isManual: true,
        publishedAtUtc: now.subtract(const Duration(days: 2)),
        idempotencyKey: _uuid.v4(),
        externalPostId: 'x_status_18392019481',
        externalUrl: 'https://x.com/shaadow/status/18392019481',
        createdAtUtc: now.subtract(const Duration(days: 2)),
        updatedAtUtc: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<ChannelGroup> get initialGroups => [
    ChannelGroup(
      id: 'group-flagship',
      brandId: 'brand-shaadow',
      name: 'Flagship Launch Squad',
      description: 'All 4 primary channels (Instagram, X, LinkedIn, YouTube)',
      accountIds: const [
        'acc-ig-shaadow',
        'acc-x-shaadow',
        'acc-li-shaadow',
        'acc-yt-shaadow',
      ],
      createdAtUtc: DateTime.utc(2026, 1, 1),
    ),
    ChannelGroup(
      id: 'group-creators',
      brandId: 'brand-boofer',
      name: 'Viral Creators & Memes',
      description: 'High-engagement social channels',
      accountIds: const ['acc-ig-boofer', 'acc-x-favtunes'],
      createdAtUtc: DateTime.utc(2026, 1, 1),
    ),
    ChannelGroup(
      id: 'group-dev-lab',
      brandId: 'brand-shaadow-works',
      name: 'Engineering & Dev Lab',
      description: 'Behind-the-scenes engineering and open source updates',
      accountIds: const ['acc-ig-works', 'acc-x-shaadow'],
      createdAtUtc: DateTime.utc(2026, 1, 1),
    ),
  ];
}

