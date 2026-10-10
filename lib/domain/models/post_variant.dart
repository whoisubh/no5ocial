import '../enums/privacy_status.dart';

/// Platform/account specific adaptation of a ContentPost.
class PostVariant {
  final String id;
  final String contentPostId;
  final String socialAccountId;
  final String? captionOverride;
  final List<String> mediaAssetIds;
  final String? firstComment;
  final String? altText;
  final PrivacyStatus privacyStatus;

  const PostVariant({
    required this.id,
    required this.contentPostId,
    required this.socialAccountId,
    this.captionOverride,
    this.mediaAssetIds = const [],
    this.firstComment,
    this.altText,
    this.privacyStatus = PrivacyStatus.public,
  });

  /// True if this variant specifies its own custom caption override.
  bool get hasCaptionOverride =>
      captionOverride != null && captionOverride!.trim().isNotEmpty;

  PostVariant copyWith({
    String? id,
    String? contentPostId,
    String? socialAccountId,
    String? captionOverride,
    List<String>? mediaAssetIds,
    String? firstComment,
    String? altText,
    PrivacyStatus? privacyStatus,
  }) {
    return PostVariant(
      id: id ?? this.id,
      contentPostId: contentPostId ?? this.contentPostId,
      socialAccountId: socialAccountId ?? this.socialAccountId,
      captionOverride: captionOverride ?? this.captionOverride,
      mediaAssetIds: mediaAssetIds ?? this.mediaAssetIds,
      firstComment: firstComment ?? this.firstComment,
      altText: altText ?? this.altText,
      privacyStatus: privacyStatus ?? this.privacyStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content_post_id': contentPostId,
        'social_account_id': socialAccountId,
        'caption_override': captionOverride,
        'media_asset_ids': mediaAssetIds,
        'first_comment': firstComment,
        'alt_text': altText,
        'privacy_status': privacyStatus.name,
      };

  factory PostVariant.fromJson(Map<String, dynamic> json) => PostVariant(
        id: json['id'] as String,
        contentPostId: json['content_post_id'] as String,
        socialAccountId: json['social_account_id'] as String,
        captionOverride: json['caption_override'] as String?,
        mediaAssetIds: (json['media_asset_ids'] as List<dynamic>?)?.cast<String>() ?? const [],
        firstComment: json['first_comment'] as String?,
        altText: json['alt_text'] as String?,
        privacyStatus: json['privacy_status'] != null
            ? PrivacyStatus.values.byName(json['privacy_status'] as String)
            : PrivacyStatus.public,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PostVariant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
