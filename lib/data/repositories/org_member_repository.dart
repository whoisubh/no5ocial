import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/domain/models/org_member.dart';

abstract class OrgMemberRepository {
  List<OrgMember> getMembers(String orgId);
  OrgMember? getMemberByUser(String orgId, String userId);
  void saveMember(OrgMember member);
  void removeMember(String memberId);

  List<OrgInvite> getInvites(String orgId);
  OrgInvite? getInviteByToken(String token);
  Future<OrgInvite?> findInviteByToken(String token);
  void saveInvite(OrgInvite invite);
  void updateInviteStatus(String inviteId, InviteStatus status);
  void removeInvite(String inviteId);
}

class SqliteOrgMemberRepository implements OrgMemberRepository {
  final Map<String, OrgMember> _members = {};
  final Map<String, OrgInvite> _invites = {};
  final AppDatabase _db = AppDatabase.instance;

  SqliteOrgMemberRepository();

  Future<void> init(String orgId) async {
    _members.clear();
    _invites.clear();
    final membersList = await _db.getOrgMembers(orgId);
    for (final m in membersList) {
      _members[m.id] = m;
    }
    final invitesList = await _db.getOrgInvites(orgId);
    for (final inv in invitesList) {
      _invites[inv.id] = inv;
    }
  }

  void clearCache() {
    _members.clear();
    _invites.clear();
  }

  @override
  List<OrgMember> getMembers(String orgId) {
    final list = _members.values.where((m) => m.orgId == orgId && m.isActive).toList();
    list.sort((a, b) => b.role.level.compareTo(a.role.level)); // Highest level first
    return list;
  }

  @override
  OrgMember? getMemberByUser(String orgId, String userId) {
    try {
      return _members.values.firstWhere(
        (m) => m.orgId == orgId && m.userId == userId && m.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void saveMember(OrgMember member) {
    _members[member.id] = member;
    _db.upsertOrgMember(member).catchError((_) {});
  }

  @override
  void removeMember(String memberId) {
    _members.remove(memberId);
    _db.deleteOrgMember(memberId).catchError((_) {});
  }

  @override
  List<OrgInvite> getInvites(String orgId) {
    final list = _invites.values.where((inv) => inv.orgId == orgId).toList();
    list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return list;
  }

  @override
  OrgInvite? getInviteByToken(String token) {
    try {
      return _invites.values.firstWhere((inv) => inv.token == token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrgInvite?> findInviteByToken(String token) async {
    final cached = getInviteByToken(token);
    if (cached != null) return cached;
    final fromDb = await _db.getOrgInviteByToken(token);
    if (fromDb != null) {
      _invites[fromDb.id] = fromDb;
    }
    return fromDb;
  }

  @override
  void saveInvite(OrgInvite invite) {
    _invites[invite.id] = invite;
    _db.insertOrgInvite(invite).catchError((_) {});
  }

  @override
  void updateInviteStatus(String inviteId, InviteStatus status) {
    final existing = _invites[inviteId];
    if (existing != null) {
      _invites[inviteId] = OrgInvite(
        id: existing.id,
        orgId: existing.orgId,
        token: existing.token,
        invitedEmail: existing.invitedEmail,
        invitedRole: existing.invitedRole,
        brandScope: existing.brandScope,
        invitedByUserId: existing.invitedByUserId,
        createdAtUtc: existing.createdAtUtc,
        expiresAtUtc: existing.expiresAtUtc,
        status: status,
      );
    }
    _db.updateOrgInviteStatus(inviteId, status).catchError((_) {});
  }

  @override
  void removeInvite(String inviteId) {
    _invites.remove(inviteId);
    _db.deleteOrgInvite(inviteId).catchError((_) {});
  }
}
