import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/domain/enums/org_role.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Screen displayed when a user opens a link-based workspace invitation.
/// Enforces that the invited user signs in with the exact Google account
/// matching the invitation email.
class InviteAcceptScreen extends StatefulWidget {
  final AppState appState;
  final String token;

  const InviteAcceptScreen({
    super.key,
    required this.appState,
    required this.token,
  });

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  OrgInvite? _invite;
  Brand? _brand;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = widget.token.trim();
      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No invitation token found in this link.';
        });
        return;
      }

      final invite = await widget.appState.getInviteByToken(token);
      if (invite == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invitation not found. The link may have expired or been revoked.';
        });
        return;
      }

      if (!invite.isValid) {
        setState(() {
          _isLoading = false;
          _invite = invite;
          _errorMessage = invite.isExpired
              ? 'This invitation has expired. Please ask your workspace lead for a new invite link.'
              : 'This invitation has already been ${invite.status.label.toLowerCase()}.';
        });
        return;
      }

      // Resolve brand name
      final brand = widget.appState.brands
          .cast<Brand?>()
          .firstWhere((b) => b?.id == invite.orgId, orElse: () => null);

      setState(() {
        _isLoading = false;
        _invite = invite;
        _brand = brand;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load invitation: $e';
      });
    }
  }

  Future<void> _handleAcceptAsCurrentLoggedInUser() async {
    final invite = _invite;
    if (invite == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await widget.appState.acceptInvite(
        invite: invite,
        userId: widget.appState.localUserId ?? 'user',
        userEmail: widget.appState.localUserEmail!,
        userName: widget.appState.localUserName ?? 'User',
        userPhotoUrl: widget.appState.localUserPhotoUrl,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessAndRedirect();
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept invitation. Please ensure your account matches the invited email.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting invitation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignInAndAccept() async {
    final invite = _invite;
    if (invite == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final GoogleSignInAccount? account = await GoogleAuthService.instance.signIn();

      if (account == null) {
        // User dismissed the Google picker
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final authenticatedEmail = account.email.trim().toLowerCase();
      final requiredEmail = invite.invitedEmail.trim().toLowerCase();

      // Check email match
      if (authenticatedEmail != requiredEmail) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showEmailMismatchDialog(authenticatedEmail, requiredEmail);
        return;
      }

      final rawDisplayName = (account.displayName != null && account.displayName!.trim().isNotEmpty)
          ? account.displayName!
          : account.email.split('@').first;
      final cleanDisplayName = InputValidator.sanitize(rawDisplayName);
      final displayName = cleanDisplayName.length > InputValidator.maxBrandNameLength
          ? cleanDisplayName.substring(0, InputValidator.maxBrandNameLength)
          : (cleanDisplayName.isEmpty ? 'Google User' : cleanDisplayName);

      final email = InputValidator.sanitize(account.email);
      final String? photoUrl = account.photoUrl;
      final String googleId = InputValidator.sanitize(account.id);

      String? accessToken;
      String? idToken;
      final String? serverAuthCode = account.serverAuthCode;

      try {
        final auth = await account.authentication;
        accessToken = auth.accessToken;
        idToken = auth.idToken;
      } catch (e) {
        debugPrint('Notice: could not extract auth token: $e');
      }

      if (!mounted) return;

      // 1. Establish session
      await widget.appState.signInLocally(
        name: displayName,
        email: email,
        photoUrl: photoUrl,
        id: googleId,
        provider: 'google',
        accessToken: accessToken,
        idToken: idToken,
        serverAuthCode: serverAuthCode,
        rawData: {
          'id': googleId,
          'email': email,
          'displayName': account.displayName,
          'photoUrl': photoUrl,
          'serverAuthCode': serverAuthCode,
        },
      );

      // 2. Accept invite and bind member role
      final success = await widget.appState.acceptInvite(
        invite: invite,
        userId: googleId,
        userEmail: email,
        userName: displayName,
        userPhotoUrl: photoUrl,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessAndRedirect();
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not accept invitation. Please check the invitation status.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showEmailMismatchDialog(String signedInEmail, String requiredEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF22304A)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Text(
              'Account Mismatch',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This invitation was created specifically for:',
              style: AppTypography.bodySecondary.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withAlpha(80)),
              ),
              child: Text(
                requiredEmail,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'You signed in with:',
              style: AppTypography.bodySecondary.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withAlpha(80)),
              ),
              child: Text(
                signedInEmail,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To accept this invitation and gain access to the workspace, please sign in with the invited email address.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleGoogleSignInAndAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndRedirect() {
    final workspaceName = _brand?.name ?? _invite?.workspaceName ?? 'Workspace';
    final roleLabel = _invite?.invitedRole.label ?? 'Member';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF22304A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withAlpha(30),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to $workspaceName!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You have joined successfully as an $roleLabel.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Open Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Official brand logo
                  Image.asset(
                    'assets/logo/no5ocial_white.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'no5ocial',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131A2B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF22304A) : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppColors.accent),
                          const SizedBox(height: 18),
                          Text(
                            'Loading workspace invitation...',
                            style: AppTypography.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    _buildErrorCard(isDark),
                  ] else if (_invite != null) ...[
                    _buildInviteDetailsCard(isDark),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF22304A) : AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withAlpha(25),
            ),
            child: const Icon(Icons.link_off_rounded, color: AppColors.warning, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            'Invalid or Expired Invitation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'This invitation link could not be verified.',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteDetailsCard(bool isDark) {
    final invite = _invite!;
    final workspaceName = _brand?.name ?? invite.workspaceName ?? 'Workspace';
    final role = invite.invitedRole;
    final isLoggedIn = widget.appState.isLoggedIn;
    final currentUserEmail = widget.appState.localUserEmail?.trim().toLowerCase();
    final invitedEmail = invite.invitedEmail.trim().toLowerCase();
    final isEmailMatching = isLoggedIn && currentUserEmail == invitedEmail;
    final daysLeft = invite.expiresAtUtc.difference(DateTime.now().toUtc()).inDays;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF22304A) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'WORKSPACE INVITATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Expires in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Join $workspaceName',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have been invited to collaborate on no5ocial publishing workspace.',
            style: AppTypography.bodySecondary.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Role Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A233A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF283656) : AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Assigned Role: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            role.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _getRoleColor(role),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Invited Email Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F33) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF22304A) : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Invited Email Address:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  invite.invitedEmail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To claim your access, you must sign in with this exact Google account.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Section
          if (!isLoggedIn) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleGoogleSignInAndAccept,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Image.asset(
                        'assets/logo/no5ocial_cropped.png',
                        height: 20,
                        width: 20,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login_rounded, size: 18),
                      ),
                label: Text(
                  _isProcessing ? 'Verifying...' : 'Sign in with Google to Accept',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (isEmailMatching) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signed in as $currentUserEmail (Matches invitation)',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleAcceptAsCurrentLoggedInUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isProcessing ? 'Joining...' : 'Accept & Join Workspace',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are currently signed in as $currentUserEmail, but this invitation was sent to $invitedEmail.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleGoogleSignInAndAccept,
                icon: const Icon(Icons.switch_account_rounded, size: 18),
                label: Text(
                  'Switch Account to $invitedEmail',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                child: const Text('Continue as current account', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(OrgRole role) {
    switch (role) {
      case OrgRole.owner:
        return const Color(0xFFF59E0B);
      case OrgRole.manager:
        return const Color(0xFF8B5CF6);
      case OrgRole.smm:
        return const Color(0xFF3B82F6);
      case OrgRole.uploader:
        return const Color(0xFF06B6D4);
      case OrgRole.analyst:
        return const Color(0xFF10B981);
    }
  }

  IconData _getRoleIcon(OrgRole role) {
    switch (role) {
      case OrgRole.owner:
        return Icons.stars_rounded;
      case OrgRole.manager:
        return Icons.admin_panel_settings_rounded;
      case OrgRole.smm:
        return Icons.edit_note_rounded;
      case OrgRole.uploader:
        return Icons.cloud_upload_rounded;
      case OrgRole.analyst:
        return Icons.analytics_rounded;
    }
  }
}
