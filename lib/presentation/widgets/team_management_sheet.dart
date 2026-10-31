import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/enums/org_role.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/domain/models/org_member.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class TeamManagementSheet extends StatefulWidget {
  final AppState appState;

  const TeamManagementSheet({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TeamManagementSheet(appState: appState),
    );
  }

  @override
  State<TeamManagementSheet> createState() => _TeamManagementSheetState();
}

class _TeamManagementSheetState extends State<TeamManagementSheet> {
  bool _showRoleGuide = false;

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final isDark = appState.isDarkMode;
    final currentRole = appState.currentRole;
    final isTeam = appState.isTeamMode;
    final members = appState.teamMembers;
    final invites = appState.pendingInvites;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101522) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF222C40) : AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Team & Roles',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleBadge(currentRole),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTeam
                            ? 'Role-based access hierarchy active'
                            : 'Solo management mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF222C40) : AppColors.border),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Workspace Mode Toggle Card
                _buildModeSwitchCard(isDark),
                const SizedBox(height: 16),

                // Role Hierarchy Guide Expandable
                _buildRoleGuideCard(isDark),
                const SizedBox(height: 20),

                if (isTeam) ...[
                  // Active Members Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Members (${members.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (appState.canInviteMembers)
                        ElevatedButton.icon(
                          onPressed: () => _showInviteDialog(context),
                          icon: const Icon(Icons.person_add_rounded, size: 15),
                          label: const Text('Invite Member'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Members List
                  if (members.isEmpty)
                    _buildEmptyState(
                      isDark: isDark,
                      icon: Icons.person_off_outlined,
                      message: 'No members registered yet in this workspace.',
                    )
                  else
                    ...members.map((m) => _buildMemberCard(m, isDark)),

                  const SizedBox(height: 24),

                  // Pending Invites Section Header
                  Row(
                    children: [
                      Text(
                        'Pending Invitations (${invites.where((i) => i.isValid).length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Invites List
                  if (invites.where((i) => i.isValid).isEmpty)
                    _buildEmptyState(
                      isDark: isDark,
                      icon: Icons.mail_outline_rounded,
                      message: 'No pending invitations. Invite team members using the button above.',
                    )
                  else
                    ...invites.where((i) => i.isValid).map((inv) => _buildInviteCard(inv, isDark)),
                ] else ...[
                  // Solo Mode Explanatory Card
                  _buildSoloNotice(isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(OrgRole role) {
    Color bg;
    Color fg;
    switch (role) {
      case OrgRole.owner:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case OrgRole.manager:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        break;
      case OrgRole.smm:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case OrgRole.uploader:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case OrgRole.analyst:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildModeSwitchCard(bool isDark) {
    final appState = widget.appState;
    final isTeam = appState.isTeamMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isTeam ? Icons.groups_rounded : Icons.person_rounded,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTeam ? 'Team Hierarchy Workspace' : 'Solo Workspace Mode',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isTeam
                      ? '5-role access permissions active for team members'
                      : 'All actions unrestricted for sole administrator',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (appState.currentRole.canDeleteOrg)
            Switch.adaptive(
              value: isTeam,
              activeTrackColor: AppColors.accent,
              onChanged: (val) async {
                final newMode = val ? WorkspaceMode.team : WorkspaceMode.solo;
                await appState.setWorkspaceMode(newMode);
                if (val) {
                  await appState.ensureDefaultOrgOwner();
                }
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoleGuideCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showRoleGuide = !_showRoleGuide),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '5 Role Hierarchy Permission Matrix (YouTube-style)',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showRoleGuide ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_showRoleGuide) ...[
            Divider(height: 1, color: isDark ? const Color(0xFF222C40) : AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: OrgRole.values.map((role) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoleBadge(role),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            role.description,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(OrgMember member, bool isDark) {
    final appState = widget.appState;
    final isMe = member.userId == appState.localUserId;
    final canManageThisMember = appState.currentRole.level > member.role.level &&
        (appState.currentRole.canInviteManagers || member.role.level < OrgRole.manager.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: member.userPhotoUrl != null ? NetworkImage(member.userPhotoUrl!) : null,
            child: member.userPhotoUrl == null
                ? Text(
                    member.userName.isNotEmpty ? member.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.userName,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E283D) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.userEmail,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildRoleBadge(member.role),
          if (canManageThisMember && !isMe) ...[
            const SizedBox(width: 4),
            PopupMenuButton<OrgRole>(
              tooltip: 'Change role',
              icon: Icon(Icons.more_vert, size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              onSelected: (newRole) async {
                await appState.updateMemberRole(member.id, newRole);
                setState(() {});
              },
              itemBuilder: (_) => OrgRole.values
                  .where((r) => r.level < appState.currentRole.level)
                  .map((r) => PopupMenuItem(value: r, child: Text(r.label)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteCard(OrgInvite invite, bool isDark) {
    final appState = widget.appState;
    final daysRemaining = invite.expiresAtUtc.difference(DateTime.now().toUtc()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.mail_outline_rounded, color: AppColors.warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.invitedEmail,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Expires in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildRoleBadge(invite.invitedRole),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Copy Invite Link',
            icon: const Icon(Icons.link_rounded, size: 18, color: AppColors.accent),
            onPressed: () {
              final link = _generateInviteLink(invite);
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation link copied to clipboard!')),
              );
            },
          ),
          IconButton(
            tooltip: 'Copy Invitation Message',
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            onPressed: () {
              final brandName = appState.brands
                  .cast<Brand?>()
                  .firstWhere((b) => b?.id == invite.orgId, orElse: () => null)
                  ?.name ?? 'Workspace';
              final message = _generateInviteMessage(invite, brandName);
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Full invitation message copied to clipboard!')),
              );
            },
          ),
          if (appState.canInviteMembers)
            IconButton(
              tooltip: 'Revoke Invite',
              icon: const Icon(Icons.close, size: 16, color: AppColors.error),
              onPressed: () async {
                await appState.revokeInvite(invite.id);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSoloNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_outline_rounded, size: 40, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'Solo Workspace Active',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are currently operating in Solo Mode. All features, publishing, and channel management are fully enabled for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'To collaborate and assign granular roles (Manager, SMM, Uploader, Analyst), switch the toggle above to Team Hierarchy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final appState = widget.appState;
    final isDark = appState.isDarkMode;
    final emailCtrl = TextEditingController();
    OrgRole selectedRole = OrgRole.uploader;

    // Filter available roles inviter can grant
    final availableRoles = OrgRole.values
        .where((r) => r.level < appState.currentRole.level || appState.currentRole == OrgRole.owner)
        .where((r) => r != OrgRole.owner) // Cannot invite co-owners directly via simple invite
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF101522) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              'Invite Team Member',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'colleague@company.com',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF222C40) : AppColors.border),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assigned Role *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<OrgRole>(
                    initialValue: selectedRole,
                    dropdownColor: isDark ? const Color(0xFF161D2E) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF222C40) : AppColors.border),
                      ),
                    ),
                    items: availableRoles.map((role) {
                      return DropdownMenuItem<OrgRole>(
                        value: role,
                        child: Text(role.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedRole.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address')),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();
                  final invite = await appState.inviteMember(email: email, role: selectedRole);
                  setState(() {});
                  if (context.mounted && invite != null) {
                    _showInviteCreatedDialog(context, invite);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Create Invite Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _generateInviteLink(OrgInvite invite) {
    final baseOrigin = kIsWeb ? Uri.base.origin : EnvConfig.webBaseUrl;
    return '$baseOrigin/#/invite?token=${invite.token}';
  }

  String _generateInviteMessage(OrgInvite invite, String workspaceName) {
    final link = _generateInviteLink(invite);
    return '''You've been invited to join the "$workspaceName" workspace on no5ocial as ${invite.invitedRole.label}!

Role: ${invite.invitedRole.label} (${invite.invitedRole.description})
Invited Email: ${invite.invitedEmail}

To accept your invitation, open this link and sign in with your Google account (${invite.invitedEmail}):
$link''';
  }

  void _showInviteCreatedDialog(BuildContext context, OrgInvite invite) {
    final appState = widget.appState;
    final workspaceName = appState.activeBrand?.name ?? 'Workspace';
    final inviteLink = _generateInviteLink(invite);
    final inviteMessage = _generateInviteMessage(invite, workspaceName);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _InviteCreatedFullScreen(
          invite: invite,
          workspaceName: workspaceName,
          inviteLink: inviteLink,
          inviteMessage: inviteMessage,
          isDark: appState.isDarkMode,
        ),
      ),
    );
  }
}

class _InviteCreatedFullScreen extends StatelessWidget {
  final OrgInvite invite;
  final String workspaceName;
  final String inviteLink;
  final String inviteMessage;
  final bool isDark;

  const _InviteCreatedFullScreen({
    required this.invite,
    required this.workspaceName,
    required this.inviteLink,
    required this.inviteMessage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1523) : AppColors.background;
    final cardBg = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF22304A) : AppColors.border;
    final innerBg = isDark ? const Color(0xFF0F1523) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        title: Text(
          'Invitation Link Ready',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withAlpha(25),
                          ),
                          child: const Icon(Icons.link_rounded, color: AppColors.success, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite to "$workspaceName"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Because direct email delivery is not configured, share this universal link or the pre-formatted invitation message directly with your invitee.',
                                style: TextStyle(fontSize: 12.5, color: textSec, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Invitee Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                invite.invitedEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                invite.invitedRole.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Access Level: ${invite.invitedRole.description}',
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Direct Link Section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DIRECT INVITATION LINK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: textSec,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: inviteLink));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invitation link copied to clipboard!')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Copy Link', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: SelectableText(
                            inviteLink,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontFamily: 'monospace',
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pre-formatted Message Preview
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRE-FORMATTED MESSAGE PREVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textSec,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: SelectableText(
                            inviteMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: inviteMessage));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Full invitation message copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            label: const Text('Copy Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Security & Cloud Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: innerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cloud Verified: This invitation is stored in the cloud database and can be claimed worldwide from any device or browser.',
                                style: TextStyle(fontSize: 11.5, color: textSec, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Role Enforcement: When your invitee opens this link, they must sign in with ${invite.invitedEmail} to claim their role.',
                                style: TextStyle(fontSize: 11.5, color: textSec, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
