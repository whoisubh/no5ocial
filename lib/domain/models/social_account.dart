import '../enums/connection_status.dart';
import '../enums/platform_type.dart';

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

  factory SocialAccount.fromJson(Map<String, dynamic> json) => SocialAccount(
        id: json['id'] as String,
        brandId: json['brand_id'] as String,
        platform: PlatformType.values.byName(json['platform'] as String),
        displayName: json['display_name'] as String,
        handle: json['handle'] as String,
        externalAccountId: json['external_account_id'] as String?,
        connectionStatus: ConnectionStatus.values.byName(json['connection_status'] as String),
        capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? const [],
        scopes: (json['scopes'] as List<dynamic>?)?.cast<String>() ?? const [],
        lastVerifiedAtUtc: json['last_verified_at_utc'] != null
            ? DateTime.parse(json['last_verified_at_utc'] as String)
            : null,
        isManualOnly: json['is_manual_only'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SocialAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
