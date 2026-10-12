import 'package:flutter/material.dart';
import '../enums/platform_type.dart';

/// Represents a specific destination target subtype on a social platform.
/// For example:
/// - LinkedIn Personal Profile vs Company Page
/// - Facebook Page vs Group vs Personal Profile (Manual Handoff)
/// - Instagram Professional (Direct API) vs Personal (Manual Handoff)
/// - YouTube Standard Channel vs Brand Channel
class PlatformSubtype {
  final String id;
  final PlatformType platform;
  final String name;
  final String description;
  final List<String> scopes;
  final List<String> linkingConditions;
  final List<String> supportedFormats;
  final List<String> defaultFormats;
  final bool isManualOnly;
  final bool requiresAdminRole;
  final String? policyNotice;

  const PlatformSubtype({
    required this.id,
    required this.platform,
    required this.name,
    required this.description,
    required this.scopes,
    required this.linkingConditions,
    required this.supportedFormats,
    required this.defaultFormats,
    this.isManualOnly = false,
    this.requiresAdminRole = false,
    this.policyNotice,
  });
}

/// Central registry of platform targets, linking conditions, and posting formats.
class PlatformConfigRegistry {
  static const Map<String, String> formatLabels = {
    'text': 'Text / Status',
    'image': 'Single Image',
    'carousel': 'Carousel / Multi-Image',
    'video': 'Video',
    'reels_shorts': 'Shorts / Reels',
  };

  static const Map<String, IconData> formatIcons = {
    'text': Icons.article_outlined,
    'image': Icons.image_outlined,
    'carousel': Icons.view_carousel_outlined,
    'video': Icons.videocam_outlined,
    'reels_shorts': Icons.slow_motion_video_outlined,
  };

  static const List<PlatformSubtype> _allSubtypes = [
    // --- LinkedIn ---
    PlatformSubtype(
      id: 'linkedin_profile',
      platform: PlatformType.linkedin,
      name: 'Personal Profile',
      description: 'Publish updates, articles, and media to your personal LinkedIn network.',
      scopes: ['openid', 'profile', 'w_member_social'],
      linkingConditions: [
        'Requires personal LinkedIn member OAuth authorization.',
        'Posts directly under member identity (urn:li:person).',
        'Direct API publishing active via LinkedIn Share/Posts API.',
      ],
      supportedFormats: ['text', 'image', 'carousel', 'video'],
      defaultFormats: ['text', 'image', 'carousel', 'video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Max 3,000 characters. PDF document slide carousels and images supported.',
    ),
    PlatformSubtype(
      id: 'linkedin_page',
      platform: PlatformType.linkedin,
      name: 'Company / Organization Page',
      description: 'Publish updates and news officially on behalf of your company page.',
      scopes: ['w_organization_social', 'rw_organization_admin', 'openid', 'profile'],
      linkingConditions: [
        'Authenticated member MUST be an Administrator or Content Admin of the LinkedIn Page.',
        'Requires "Share on LinkedIn" or "Community Management API" permissions on developer app.',
        'Posts as organization entity (urn:li:organization).',
      ],
      supportedFormats: ['text', 'image', 'carousel', 'video'],
      defaultFormats: ['text', 'image', 'carousel', 'video'],
      isManualOnly: false,
      requiresAdminRole: true,
      policyNotice: 'Company posts display the official organization logo, name, and organic follower analytics.',
    ),

    // --- Facebook ---
    PlatformSubtype(
      id: 'facebook_page',
      platform: PlatformType.facebook,
      name: 'Facebook Page (Business / Brand)',
      description: 'Publish directly to your official Facebook Business or Brand Page feed.',
      scopes: ['pages_manage_posts', 'pages_read_engagement', 'public_profile'],
      linkingConditions: [
        'Requires Page Task or Admin access on the connected Facebook Page.',
        'Uses Page Access Token derived from user authentication.',
        'Direct automated publishing supported via Meta Graph API /{page-id}/feed.',
      ],
      supportedFormats: ['text', 'image', 'carousel', 'video', 'reels_shorts'],
      defaultFormats: ['text', 'image', 'carousel', 'video', 'reels_shorts'],
      isManualOnly: false,
      requiresAdminRole: true,
      policyNotice: 'Supports status text, photo carousels, videos, and Facebook Reels.',
    ),
    PlatformSubtype(
      id: 'facebook_group',
      platform: PlatformType.facebook,
      name: 'Facebook Group',
      description: 'Publish community updates or announcements to a Facebook Group.',
      scopes: ['groups_access_member_info', 'publish_to_groups'],
      linkingConditions: [
        'User must be a Group Administrator.',
        'App must be installed in Group Settings > Apps by group admin.',
      ],
      supportedFormats: ['text', 'image', 'video'],
      defaultFormats: ['text', 'image', 'video'],
      isManualOnly: false,
      requiresAdminRole: true,
      policyNotice: 'Subject to Meta Group API permissions and group member settings.',
    ),
    PlatformSubtype(
      id: 'facebook_personal',
      platform: PlatformType.facebook,
      name: 'Personal Profile (Manual Handoff)',
      description: 'Share updates to your personal Facebook profile timeline.',
      scopes: ['manual_workflow'],
      linkingConditions: [
        'Meta API policy explicitly bans third-party automated direct posting to personal profiles.',
        'Operates via no5ocial Manual Handoff workflow (copies text/media and opens Facebook).',
      ],
      supportedFormats: ['text', 'image', 'video'],
      defaultFormats: ['text', 'image', 'video'],
      isManualOnly: true,
      requiresAdminRole: false,
      policyNotice: 'Meta policy restriction: Automated API publishing is prohibited. Manual Handoff ensures full compliance without risk of account flag.',
    ),

    // --- Instagram ---
    PlatformSubtype(
      id: 'instagram_professional',
      platform: PlatformType.instagram,
      name: 'Professional Account (Business / Creator)',
      description: 'Direct API publishing for Feed posts, Carousels, and Reels.',
      scopes: ['instagram_content_publish', 'pages_show_list', 'instagram_basic'],
      linkingConditions: [
        'Account must be converted to Professional (Business or Creator) in Instagram app settings.',
        'Account must be linked to a Facebook Page managed by your account.',
        'Direct API publishing active via Meta Graph API.',
      ],
      supportedFormats: ['image', 'carousel', 'video', 'reels_shorts'],
      defaultFormats: ['image', 'carousel', 'video', 'reels_shorts'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Text-only posts are not supported by Instagram. High-res media required (max 2,200 chars, max 30 hashtags).',
    ),
    PlatformSubtype(
      id: 'instagram_personal',
      platform: PlatformType.instagram,
      name: 'Personal Profile (Manual Handoff)',
      description: 'Share to personal Instagram account using guided mobile workflow.',
      scopes: ['manual_workflow'],
      linkingConditions: [
        'Instagram Content Publishing API does not support personal accounts.',
        'Scheduled post sends a mobile reminder, copies caption to clipboard, downloads media, and opens Instagram.',
      ],
      supportedFormats: ['image', 'carousel', 'video', 'reels_shorts'],
      defaultFormats: ['image', 'carousel', 'video', 'reels_shorts'],
      isManualOnly: true,
      requiresAdminRole: false,
      policyNotice: 'Meta restriction: Personal profiles must use Manual Handoff workflow.',
    ),

    // --- YouTube ---
    PlatformSubtype(
      id: 'youtube_standard',
      platform: PlatformType.youtube,
      name: 'Standard Channel',
      description: 'Upload videos and shorts to your default Google account YouTube channel.',
      scopes: ['https://www.googleapis.com/auth/youtube.upload'],
      linkingConditions: [
        'Requires Google OAuth with YouTube upload scope.',
        'Channel must be phone-verified for videos longer than 15 minutes or custom thumbnails.',
        'Default privacy setting must be configured before publishing.',
      ],
      supportedFormats: ['video', 'reels_shorts'],
      defaultFormats: ['video', 'reels_shorts'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Video strictly required. Standalone text and images are not supported for uploads via Data API.',
    ),
    PlatformSubtype(
      id: 'youtube_brand',
      platform: PlatformType.youtube,
      name: 'Brand / Managed Channel',
      description: 'Upload videos to a designated YouTube Brand Account with team permissions.',
      scopes: ['https://www.googleapis.com/auth/youtube.upload'],
      linkingConditions: [
        'Google account must have Owner or Manager permissions on the YouTube Brand Account.',
        'Select the specific Brand Channel during Google OAuth login prompt.',
      ],
      supportedFormats: ['video', 'reels_shorts'],
      defaultFormats: ['video', 'reels_shorts'],
      isManualOnly: false,
      requiresAdminRole: true,
      policyNotice: 'Allows multiple workspace members to publish videos without sharing primary Google passwords.',
    ),

    // --- X (Twitter) ---
    PlatformSubtype(
      id: 'x_profile',
      platform: PlatformType.x,
      name: 'Standard Profile',
      description: 'Publish tweets, images, and videos up to 140s to your X profile.',
      scopes: ['tweet.read', 'tweet.write', 'users.read'],
      linkingConditions: [
        'Requires OAuth 2.0 User Context authorization.',
        'Monthly write quotas apply based on team X Developer API tier.',
      ],
      supportedFormats: ['text', 'image', 'video'],
      defaultFormats: ['text', 'image', 'video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Text max 280 characters. Up to 4 images or 1 video (<= 140s).',
    ),
    PlatformSubtype(
      id: 'x_premium',
      platform: PlatformType.x,
      name: 'X Premium / Verified Organization',
      description: 'Long-form posts (up to 25k chars), edit window, and longer video uploads.',
      scopes: ['tweet.read', 'tweet.write', 'users.read'],
      linkingConditions: [
        'Target account must have active X Premium or Verified Organization status.',
        'OAuth 2.0 User Access Token with write permission.',
      ],
      supportedFormats: ['text', 'image', 'video'],
      defaultFormats: ['text', 'image', 'video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Extended character limit and 1080p long-form video uploads supported.',
    ),

    // --- TikTok ---
    PlatformSubtype(
      id: 'tiktok_creator',
      platform: PlatformType.tiktok,
      name: 'Creator Account',
      description: 'Direct video and photo carousel publishing for creators.',
      scopes: ['video.publish', 'video.upload'],
      linkingConditions: [
        'Requires TikTok Content Posting API authorization.',
        'Privacy level (Public / Friends / Private) must be confirmed prior to posting.',
      ],
      supportedFormats: ['video', 'carousel'],
      defaultFormats: ['video', 'carousel'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Video strictly required (or TikTok photo mode). Text-only posts are not supported.',
    ),
    PlatformSubtype(
      id: 'tiktok_business',
      platform: PlatformType.tiktok,
      name: 'Business Account',
      description: 'Commercial brand publishing subject to TikTok Commercial Music rules.',
      scopes: ['video.publish', 'video.upload', 'business.account.info'],
      linkingConditions: [
        'Must be registered as a TikTok Business Account.',
        'Commercial sounds / music library policy strictly enforced.',
      ],
      supportedFormats: ['video'],
      defaultFormats: ['video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Only royalty-free / commercial licensed audio can be used for commercial business posts.',
    ),

    // --- Threads ---
    PlatformSubtype(
      id: 'threads_profile',
      platform: PlatformType.threads,
      name: 'Threads Profile',
      description: 'Publish updates, photos, carousels, and videos up to 5 min to Threads.',
      scopes: ['threads_basic', 'threads_content_publish'],
      linkingConditions: [
        'Authenticated via Meta Threads API linked to Instagram account.',
        'Rate limit: 250 published posts per 24-hour period.',
      ],
      supportedFormats: ['text', 'image', 'carousel', 'video'],
      defaultFormats: ['text', 'image', 'carousel', 'video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Supports up to 500 characters, up to 10 images, and videos up to 5 minutes.',
    ),

    // --- Pinterest ---
    PlatformSubtype(
      id: 'pinterest_business',
      platform: PlatformType.pinterest,
      name: 'Business Account / Board',
      description: 'Publish image and video Pins with title, description, and target board.',
      scopes: ['pins:write', 'boards:read'],
      linkingConditions: [
        'Requires Pinterest API v5 OAuth.',
        'Target Board ID and destination link required for published pins.',
      ],
      supportedFormats: ['image', 'video'],
      defaultFormats: ['image', 'video'],
      isManualOnly: false,
      requiresAdminRole: false,
      policyNotice: 'Media required. Text-only pins are not supported. Max title 100 chars, description 500 chars.',
    ),
    PlatformSubtype(
      id: 'pinterest_personal',
      platform: PlatformType.pinterest,
      name: 'Personal Account (Manual Handoff)',
      description: 'Save pins to personal boards via guided mobile flow.',
      scopes: ['manual_workflow'],
      linkingConditions: [
        'Direct automated pin creation requires Pinterest Business developer approval.',
      ],
      supportedFormats: ['image', 'video'],
      defaultFormats: ['image', 'video'],
      isManualOnly: true,
      requiresAdminRole: false,
      policyNotice: 'Manual Handoff workflow downloads media and opens the Pinterest app.',
    ),
  ];

  static List<PlatformSubtype> getSubtypes(PlatformType platform) {
    final list = _allSubtypes.where((s) => s.platform == platform).toList();
    if (list.isEmpty) {
      return [
        PlatformSubtype(
          id: '${platform.name}_standard',
          platform: platform,
          name: '${platform.displayName} ${platform.accountNoun}',
          description: 'Standard ${platform.displayName} destination target.',
          scopes: ['publish_posts'],
          linkingConditions: ['Requires official OAuth authorization.'],
          supportedFormats: ['text', 'image', 'video'],
          defaultFormats: ['text', 'image', 'video'],
        ),
      ];
    }
    return list;
  }

  static PlatformSubtype getDefaultSubtype(PlatformType platform) {
    return getSubtypes(platform).first;
  }

  static PlatformSubtype? findSubtypeById(String? id) {
    if (id == null) return null;
    try {
      return _allSubtypes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
