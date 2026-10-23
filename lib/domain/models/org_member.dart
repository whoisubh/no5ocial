import 'dart:convert';
import 'package:no5ocial/domain/enums/org_role.dart';

/// Represents a team member belonging to an organization workspace with a designated OrgRole.
class OrgMember {
  final String id;
  final String orgId;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final OrgRole role;
  final List<String>? brandScope;
  final String? invitedByUserId;
  final DateTime joinedAtUtc;
  final bool isActive;

  const OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    required this.role,
    this.brandScope,
    this.invitedByUserId,
    required this.joinedAtUtc,
    this.isActive = true,
  });

  bool get isOrgWide => brandScope == null || brandScope!.isEmpty;

  bool hasBrandAccess(String brandId) {
    if (isOrgWide) return true;
    return brandScope!.contains(brandId);
  }

  OrgMember copyWith({
    String? id,
    String? orgId,
    String? userId,
    String? userEmail,
    String? userName,
    String? userPhotoUrl,
    OrgRole? role,
    List<String>? brandScope,
    String? invitedByUserId,
    DateTime? joinedAtUtc,
    bool? isActive,
  }) {
    return OrgMember(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      role: role ?? this.role,
      brandScope: brandScope ?? this.brandScope,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      joinedAtUtc: joinedAtUtc ?? this.joinedAtUtc,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName,
        'user_photo_url': userPhotoUrl,
        'role': role.name,
        'brand_scope': brandScope != null ? jsonEncode(brandScope) : null,
        'invited_by_user_id': invitedByUserId,
        'joined_at_utc': joinedAtUtc.toIso8601String(),
        'is_active': isActive ? 1 : 0,
      };

  factory OrgMember.fromJson(Map<String, dynamic> json) {
    List<String>? parsedBrandScope;
    final rawScope = json['brand_scope'];
    if (rawScope is String && rawScope.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawScope);
        if (decoded is List) {
          parsedBrandScope = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (rawScope is List) {
      parsedBrandScope = rawScope.map((e) => e.toString()).toList();
    }

    return OrgMember(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String,
      userEmail: (json['user_email'] as String?) ?? '',
      userName: (json['user_name'] as String?) ?? 'Team Member',
      userPhotoUrl: json['user_photo_url'] as String?,
      role: OrgRole.fromString(json['role'] as String?),
      brandScope: parsedBrandScope,
      invitedByUserId: json['invited_by_user_id'] as String?,
      joinedAtUtc: DateTime.tryParse(json['joined_at_utc'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
    );
  }
}
