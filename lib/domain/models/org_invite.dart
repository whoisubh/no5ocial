import 'dart:convert';
import 'package:no5ocial/domain/enums/org_role.dart';

enum InviteStatus {
  pending('Pending'),
  accepted('Accepted'),
  revoked('Revoked'),
  expired('Expired');

  const InviteStatus(this.label);
  final String label;

  static InviteStatus fromString(String? value) {
    if (value == null) return InviteStatus.pending;
    return InviteStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InviteStatus.pending,
    );
  }
}

/// Represents an invitation for a user to join an organization with a specific role.
class OrgInvite {
  final String id;
  final String orgId;
  final String token;
  final String invitedEmail;
  final OrgRole invitedRole;
  final List<String>? brandScope;
  final String invitedByUserId;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
  final InviteStatus status;

  const OrgInvite({
    required this.id,
    required this.orgId,
    required this.token,
    required this.invitedEmail,
    required this.invitedRole,
    this.brandScope,
    required this.invitedByUserId,
    required this.createdAtUtc,
    required this.expiresAtUtc,
    this.status = InviteStatus.pending,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);
  bool get isValid => status == InviteStatus.pending && !isExpired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'token': token,
        'invited_email': invitedEmail,
        'invited_role': invitedRole.name,
        'brand_scope': brandScope != null ? jsonEncode(brandScope) : null,
        'invited_by_user_id': invitedByUserId,
        'created_at_utc': createdAtUtc.toIso8601String(),
        'expires_at_utc': expiresAtUtc.toIso8601String(),
        'status': status.name,
      };

  factory OrgInvite.fromJson(Map<String, dynamic> json) {
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

    return OrgInvite(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      token: (json['token'] as String?) ?? '',
      invitedEmail: (json['invited_email'] as String?) ?? '',
      invitedRole: OrgRole.fromString(json['invited_role'] as String?),
      brandScope: parsedBrandScope,
      invitedByUserId: (json['invited_by_user_id'] as String?) ?? '',
      createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      expiresAtUtc: DateTime.tryParse(json['expires_at_utc'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(days: 7)),
      status: InviteStatus.fromString(json['status'] as String?),
    );
  }
}
