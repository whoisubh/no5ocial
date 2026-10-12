import 'dart:convert';
import '../enums/connection_status.dart';
import '../enums/platform_type.dart';
import 'platform_target_config.dart';

/// Represents a connected or manually managed destination account.
/// Examples: Instagram @boofer, YouTube channel Owl and Fowl Studios, LinkedIn Shaadow Platforms.
class SocialAccount {
  final String id;
  final String brandId;
  final PlatformType platform;
  final String displayName;
  final String handle;
  final String? externalAccountId;
  final ConnectionStatus connectionStatus;
  final List<String> capabilities;
  final List<String> scopes;
  final DateTime? lastVerifiedAtUtc;
  final bool isManualOnly;

  const SocialAccount({
    required this.id,
    required this.brandId,
    required this.platform,
    required this.displayName,
    required this.handle,
    this.externalAccountId,
    this.connectionStatus = ConnectionStatus.connected,
    this.capabilities = const ['post', 'caption', 'image', 'video'],
    this.scopes = const [],
    this.lastVerifiedAtUtc,
    this.isManualOnly = false,
  });

  bool get isPublishable => connectionStatus.isPublishable;

  /// Extracts the subtype ID if stored in capabilities (e.g. 'subtype:linkedin_page').
  String? get subtypeId {
    for (final c in capabilities) {
      if (c.startsWith('subtype:')) return c.substring(8);
    }
    return null;
  }

  /// Extracts configured default video privacy if stored (e.g. 'privacy:unlisted').
  String? get defaultPrivacy {
    for (final c in capabilities) {
      if (c.startsWith('privacy:')) return c.substring(8);
    }
    return null;
  }

  /// Human-friendly target sub-type name (e.g. 'Company Page', 'Personal Profile', 'Brand Channel').
  String get subtypeLabel {
    final subId = subtypeId;
    if (subId != null) {
      final config = PlatformConfigRegistry.findSubtypeById(subId);
      if (config != null) return config.name;
    }
    return platform.fullTargetName;
  }

  SocialAccount copyWith({
    String? id,
    String? brandId,
    PlatformType? platform,
    String? displayName,
    String? handle,
    String? externalAccountId,
    ConnectionStatus? connectionStatus,
    List<String>? capabilities,
    List<String>? scopes,
    DateTime? lastVerifiedAtUtc,
    bool? isManualOnly,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      platform: platform ?? this.platform,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      externalAccountId: externalAccountId ?? this.externalAccountId,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      capabilities: capabilities ?? this.capabilities,
      scopes: scopes ?? this.scopes,
      lastVerifiedAtUtc: lastVerifiedAtUtc ?? this.lastVerifiedAtUtc,
      isManualOnly: isManualOnly ?? this.isManualOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand_id': brandId,
        'platform': platform.name,
        'display_name': displayName,
        'handle': handle,
        'external_account_id': externalAccountId,
        'connection_status': connectionStatus.name,
        'capabilities': capabilities,
        'scopes': scopes,
        'last_verified_at_utc': lastVerifiedAtUtc?.toIso8601String(),
        'is_manual_only': isManualOnly,
      };

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    List<String> caps = [];
    if (json['capabilities'] is List) {
      caps = (json['capabilities'] as List).map((e) => e.toString()).toList();
    } else if (json['capabilities'] is String) {
      try {
        final dec = jsonDecode(json['capabilities'] as String);
        if (dec is List) caps = dec.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<String> scs = [];
    if (json['scopes'] is List) {
      scs = (json['scopes'] as List).map((e) => e.toString()).toList();
    } else if (json['scopes'] is String) {
      try {
        final dec = jsonDecode(json['scopes'] as String);
        if (dec is List) scs = dec.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    PlatformType plat = PlatformType.instagram;
    try {
      plat = PlatformType.values.byName(json['platform'] as String);
    } catch (_) {}

    ConnectionStatus stat = ConnectionStatus.connected;
    try {
      stat = ConnectionStatus.values.byName(json['connection_status'] as String);
    } catch (_) {}

    bool manual = false;
    if (json['is_manual_only'] is bool) {
      manual = json['is_manual_only'] as bool;
    } else if (json['is_manual_only'] is num) {
      manual = (json['is_manual_only'] as num) != 0;
    }

    return SocialAccount(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      platform: plat,
      displayName: json['display_name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      externalAccountId: json['external_account_id'] as String?,
      connectionStatus: stat,
      capabilities: caps,
      scopes: scs,
      lastVerifiedAtUtc: json['last_verified_at_utc'] != null
          ? DateTime.tryParse(json['last_verified_at_utc'] as String)
          : null,
      isManualOnly: manual,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SocialAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
