import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.appState,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _companyNameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _companyDescCtrl = TextEditingController();
  final _formKeyCompany = GlobalKey<FormState>();

  String _selectedCompanySize = 'Just me (1 person)';
  WorkspaceMode _selectedWorkspaceMode = WorkspaceMode.solo;

  static const List<String> _companySizes = [
    'Just me (1 person)',
    '2–10 team members',
    '11–50 employees',
    '50+ employees',
  ];

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _websiteCtrl.dispose();
    _companyDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCompany() async {
    if (!_formKeyCompany.currentState!.validate()) return;

    // Purge hardcoded demo seed brands so the workspace only contains the user's registered company
    await widget.appState.purgeDemoData();

    widget.appState.createBrand(
      name: _companyNameCtrl.text.trim(),
      websiteUrl: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      description: _companyDescCtrl.text.trim().isEmpty ? null : _companyDescCtrl.text.trim(),
      companySize: _selectedCompanySize,
    );

    await widget.appState.setWorkspaceMode(_selectedWorkspaceMode);
    await widget.appState.initOrgMembers();
    await widget.appState.ensureDefaultOrgOwner();

    widget.appState.hasCompletedOnboarding = true;
    await SessionService.instance.setCompletedOnboarding(true);
    await SessionService.instance.saveBrandsCache(widget.appState.brands);

    widget.appState.shouldShowWelcomeDialog = true;

    if (mounted) {
      widget.onComplete();
    }
  }

  Future<void> _skipToDashboard() async {
    await widget.appState.ensureDefaultBrandExists();
    await widget.appState.setWorkspaceMode(_selectedWorkspaceMode);
    await widget.appState.initOrgMembers();
    await widget.appState.ensureDefaultOrgOwner();
    widget.appState.hasCompletedOnboarding = true;
    await SessionService.instance.setCompletedOnboarding(true);
    if (mounted) {
      widget.onComplete();
    }
  }

  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // 1. Revoke and disconnect Google OAuth credentials
      await GoogleAuthService.instance.signOut();
      // 2. Clear local auth state and SQLite user profile session
      await widget.appState.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out exception: $e');
    } finally {
      if (mounted) {
        // Explicitly redirect to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final darkSelectionTheme = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF3865F6),
        selectionColor: Color(0x773865F6),
        selectionHandleColor: Color(0xFF3865F6),
      ),
    );

    return Theme(
      data: darkSelectionTheme,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF7F8FA),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                color: isDark ? const Color(0xFF101522) : Colors.white,
                elevation: isDark ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? const Color(0xFF222C40) : const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar with Brand Logo and Dark/Light Mode Theme Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            isDark ? 'assets/logo/no5ocial_white.png' : 'assets/logo/no5ocial.png',
                            height: 30,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/logo/no5ocial_cropped.png',
                              height: 24,
                            ),
                          ),
                          IconButton(
                            onPressed: widget.appState.toggleTheme,
                            icon: Icon(
                              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                              size: 20,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Authenticated Google User Card
                      _buildUserProfileCard(isDark),

                      // Company Registration Form
                      _buildCompanyStep(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyStep(bool isDark) {
    return Form(
      key: _formKeyCompany,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register Company',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your company workspace to manage social channels and schedule posts.',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Company Name
          Text(
            'Company Name *',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyNameCtrl,
            cursorColor: const Color(0xFF3865F6),
            cursorWidth: 2.0,
            enableInteractiveSelection: true,
            mouseCursor: SystemMouseCursors.text,
            inputFormatters: [
              LengthLimitingTextInputFormatter(InputValidator.maxBrandNameLength),
            ],
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'e.g. Acme Corporation or Nova Media',
              prefixIcon: Icons.business,
              helperText: '2–${InputValidator.maxBrandNameLength} characters',
            ),
            validator: InputValidator.validateBrandName,
          ),
          const SizedBox(height: 18),

          // Company Size
          Text(
            'Company Size *',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCompanySize,
            dropdownColor: isDark ? const Color(0xFF161D2E) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14,
            ),
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'Select company size',
              prefixIcon: Icons.people_outline_rounded,
            ),
            items: _companySizes.map((size) {
              return DropdownMenuItem<String>(
                value: size,
                child: Text(size),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedCompanySize = val;
                // Intelligently recommend workspace mode based on company size
                if (val.startsWith('Just me')) {
                  _selectedWorkspaceMode = WorkspaceMode.solo;
                } else {
                  _selectedWorkspaceMode = WorkspaceMode.team;
                }
              });
            },
          ),
          const SizedBox(height: 20),

          // Workspace Management Mode
          Text(
            'How is this workspace managed? *',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select whether you solely manage this workspace or collaborate with a team role hierarchy.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          _buildWorkspaceModeOption(
            isDark: isDark,
            mode: WorkspaceMode.solo,
            title: 'Just Me (Solo Mode)',
            description: 'You solely manage all content, channels, and scheduling yourself.',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildWorkspaceModeOption(
            isDark: isDark,
            mode: WorkspaceMode.team,
            title: 'Team & Role Hierarchy (Team Mode)',
            description: 'Collaborate with team members and assign granular roles (Owner, Manager, Social Media Manager, Uploader, Analyst).',
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 20),

          // Website URL
          Text(
            'Website (Optional)',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _websiteCtrl,
            cursorColor: const Color(0xFF3865F6),
            cursorWidth: 2.0,
            enableInteractiveSelection: true,
            mouseCursor: SystemMouseCursors.text,
            inputFormatters: [
              LengthLimitingTextInputFormatter(InputValidator.maxWebsiteUrlLength),
            ],
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'https://example.com',
              prefixIcon: Icons.language,
              helperText: 'Must begin with https:// or http://',
            ),
            validator: InputValidator.validateWebsiteUrl,
          ),
          const SizedBox(height: 18),

          // Description
          Text(
            'Description (Optional)',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyDescCtrl,
            cursorColor: const Color(0xFF3865F6),
            cursorWidth: 2.0,
            enableInteractiveSelection: true,
            mouseCursor: SystemMouseCursors.text,
            maxLines: 2,
            inputFormatters: [
              LengthLimitingTextInputFormatter(InputValidator.maxDescriptionLength),
            ],
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'e.g. Technology news & publication',
              prefixIcon: Icons.description_outlined,
              helperText: 'Max ${InputValidator.maxDescriptionLength} characters',
            ),
            validator: InputValidator.validateDescription,
          ),
          const SizedBox(height: 32),

          // Submit Step
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitCompany,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Complete Setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3865F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _skipToDashboard,
              child: Text(
                'Skip for now & use default workspace',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceModeOption({
    required bool isDark,
    required WorkspaceMode mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedWorkspaceMode == mode;
    final primaryColor = const Color(0xFF3865F6);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedWorkspaceMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF162344) : const Color(0xFFEFF4FF))
              : (isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF222C40) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E283D) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? primaryColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryColor : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                            width: isSelected ? 5.5 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
      helperText: helperText,
      helperStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 11),
      errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 11.5, fontWeight: FontWeight.w600),
      prefixIcon: Icon(prefixIcon, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 18),
      filled: true,
      fillColor: isDark ? const Color(0xFF161D2E) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF222C40) : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF222C40) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3865F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }


  Widget _buildUserProfileCard(bool isDark) {
    final userName = widget.appState.localUserName ?? 'Google User';
    final userEmail = widget.appState.localUserEmail ?? '';
    final photoUrl = widget.appState.localUserPhotoUrl;
    final isGoogle = widget.appState.localUserProvider == 'google';

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF22304A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x4D000000) : const Color(0x0A000000),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isGoogle ? const Color(0xFF3865F6) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: 2,
              ),
              boxShadow: [
                if (isGoogle)
                  const BoxShadow(
                    color: Color(0x593865F6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipOval(
              child: (photoUrl != null && photoUrl.isNotEmpty)
                  ? Image.network(
                      photoUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildAvatarFallback(userName),
                    )
                  : _buildAvatarFallback(userName),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  )
                : Icon(
                    Icons.logout,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
            label: Text(
              _isLoggingOut ? 'Signing out...' : 'Log out',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF22304A) : const Color(0xFFCBD5E1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'U';
    return Container(
      color: const Color(0xFF1E283D),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF60A5FA),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
