import 'dart:convert';
import '../enums/publish_status.dart';

/// Master content record representing a campaign post or piece of content.
class ContentPost {
  final String id;
  final String brandId;
  final String title;
  final String defaultCaption;
  final List<String> mediaAssetIds;
  final List<String> destinationAccountIds;
  final List<String> tags;
  final String? campaign;
  final PublishJobStatus status;
  final DateTime? scheduledAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  const ContentPost({
    required this.id,
    required this.brandId,
    required this.title,
    required this.defaultCaption,
    this.mediaAssetIds = const [],
    this.destinationAccountIds = const [],
    this.tags = const [],
    this.campaign,
    this.status = PublishJobStatus.draft,
    this.scheduledAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  ContentPost copyWith({
    String? id,
    String? brandId,
    String? title,
    String? defaultCaption,
    List<String>? mediaAssetIds,
    List<String>? destinationAccountIds,
    List<String>? tags,
    String? campaign,
    PublishJobStatus? status,
    DateTime? scheduledAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return ContentPost(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      title: title ?? this.title,
      defaultCaption: defaultCaption ?? this.defaultCaption,
      mediaAssetIds: mediaAssetIds ?? this.mediaAssetIds,
      destinationAccountIds: destinationAccountIds ?? this.destinationAccountIds,
      tags: tags ?? this.tags,
      campaign: campaign ?? this.campaign,
      status: status ?? this.status,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand_id': brandId,
        'title': title,
        'default_caption': defaultCaption,
        'media_asset_ids': mediaAssetIds,
        'destination_account_ids': destinationAccountIds,
        'tags': tags,
        'campaign': campaign,
        'status': status.name,
        'scheduled_at_utc': scheduledAtUtc?.toIso8601String(),
        'created_at_utc': createdAtUtc.toIso8601String(),
        'updated_at_utc': updatedAtUtc.toIso8601String(),
      };

  factory ContentPost.fromJson(Map<String, dynamic> json) {
    List<String> media = [];
    if (json['media_asset_ids'] is List) {
      media = (json['media_asset_ids'] as List).map((e) => e.toString()).toList();
    } else if (json['media_asset_ids'] is String) {
      try {
        final dec = jsonDecode(json['media_asset_ids'] as String);
        if (dec is List) media = dec.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<String> dests = [];
    if (json['destination_account_ids'] is List) {
      dests = (json['destination_account_ids'] as List).map((e) => e.toString()).toList();
    } else if (json['destination_account_ids'] is String) {
      try {
        final dec = jsonDecode(json['destination_account_ids'] as String);
        if (dec is List) dests = dec.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<String> postTags = [];
    if (json['tags'] is List) {
      postTags = (json['tags'] as List).map((e) => e.toString()).toList();
    } else if (json['tags'] is String) {
      try {
        final dec = jsonDecode(json['tags'] as String);
        if (dec is List) postTags = dec.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    PublishJobStatus st = PublishJobStatus.draft;
    try {
      st = PublishJobStatus.values.byName(json['status'] as String);
    } catch (_) {}

    return ContentPost(
      id: json['id'] as String,
      brandId: json['brand_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      defaultCaption: json['default_caption'] as String? ?? '',
      destinationAccountIds: dests,
      mediaAssetIds: media,
      campaign: json['campaign'] as String?,
      tags: postTags,
      status: st,
      scheduledAtUtc: json['scheduled_at_utc'] != null
          ? DateTime.tryParse(json['scheduled_at_utc'] as String)
          : null,
      createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
      updatedAtUtc: DateTime.tryParse(json['updated_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContentPost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
