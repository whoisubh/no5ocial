import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class LandingScreen extends StatefulWidget {
  final AppState appState;

  const LandingScreen({super.key, required this.appState});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _compareKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  int _selectedPreviewTab = 0;
  bool _isLoggingIn = false;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleMobileGoogleLogin() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);
    try {
      final account = await GoogleAuthService.instance.signIn();
      if (account != null) {
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
        } catch (_) {}

        if (mounted) {
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
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        if (mounted) setState(() => _isLoggingIn = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 680 && screenWidth < 1024;
    final isMobile = screenWidth < 700 ||
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS));

    if (isMobile) {
      return _buildMobileWelcomeView(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(
            top: -120,
            left: screenWidth / 2 - 380,
            child: Container(
              width: 760,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF254394).withValues(alpha: 0.35),
                    const Color(0xFF1E1B4B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Main CustomScrollView with pinned frosted glass navbar
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. PINNED BLURRED SLIVER APP BAR
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF070A11).withValues(alpha: 0.85),
                expandedHeight: 72,
                toolbarHeight: 72,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    // Brand Logo
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo/no5ocial_white.png',
                              height: 34,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Image.asset(
                                'assets/logo/no5ocial_N.png',
                                height: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isDesktop) ...[
                      const SizedBox(width: 38),
                      _NavHeaderLink(label: 'Workflow', onTap: () => _scrollTo(_workflowKey)),
                      const SizedBox(width: 8),
                      _NavHeaderLink(label: 'Features', onTap: () => _scrollTo(_featuresKey)),
                      const SizedBox(width: 8),
                      _NavHeaderLink(label: 'Why no5ocial', onTap: () => _scrollTo(_compareKey)),
                      const SizedBox(width: 8),
                      _NavHeaderLink(label: 'FAQ', onTap: () => _scrollTo(_faqKey)),
                    ],
                  ],
                ),
                actions: [
                  _buildLanguagePill(),
                  const SizedBox(width: 12),

                  // Sign In Pill Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _NavbarSignInButton(
                      onTap: () => Navigator.of(context).pushNamed('/login'),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),

              // 2. MAIN BODY SECTIONS
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeroSection(isDesktop, isTablet),
                    _buildMetricsStrip(isDesktop),
                    _buildWorkflowSection(_workflowKey, isDesktop),
                    _buildBentoFeaturesSection(_featuresKey, isDesktop),
                    _buildComparisonSection(_compareKey, isDesktop),
                    _buildDataSovereigntySection(isDesktop),
                    _buildFaqSection(_faqKey, isDesktop),
                    _buildFinalCtaSection(isDesktop),
                    _buildFooter(context, isDesktop),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill() {
    return PopupMenuButton<Locale>(
      tooltip: 'Change Language',
      offset: const Offset(0, 48),
      color: const Color(0xFF111726),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF22304A)),
      ),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF22304A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 15, color: Color(0xFF94A3B8)),
            const SizedBox(width: 7),
            Text(
              widget.appState.currentLocale.languageCode.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
      onSelected: (Locale locale) => widget.appState.setLocale(locale),
      itemBuilder: (context) {
        return AppState.supportedLocales.map((locale) {
          final isSelected =
              locale.languageCode == widget.appState.currentLocale.languageCode;
          final name =
              AppState.localeDisplayNames[locale.languageCode] ??
              locale.languageCode;
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 15,
                  color: isSelected ? const Color(0xFF3865F6) : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  // ==========================================
  // NATIVE MOBILE WELCOME VIEW FOR ANDROID
  // ==========================================
  Widget _buildMobileWelcomeView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 200,
            child: Container(
              width: 400,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF254394).withValues(alpha: 0.4),
                    const Color(0xFF1E1B4B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Mobile Bar: Brand Logo & Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/logo/no5ocial_white.png',
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/logo/no5ocial_N.png',
                          height: 28,
                        ),
                      ),
                      const Spacer(),
                      _buildLanguagePill(),
                    ],
                  ),
                ),

                // Scrollable Native Mobile Welcome Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        // Vault status badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121B2C),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF283A5E)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '100% On-Device Vault • SQLite Powered',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFBFDBFE),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Main Typography
                        Text(
                          'Publish Everywhere.\nKeep 100% Data.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The privacy-first social publishing studio for Android. Schedule & publish across Instagram, YouTube, X, and LinkedIn with smart preflights.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Native Mobile Feature Cards
                        _buildMobileFeatureCard(
                          icon: Icons.hub_rounded,
                          iconColor: const Color(0xFF60A5FA),
                          title: 'Multi-Channel Composer',
                          description: 'Compose once, then customize titles, captions & tags for Instagram, YouTube, X & LinkedIn.',
                        ),
                        const SizedBox(height: 10),
                        _buildMobileFeatureCard(
                          icon: Icons.shield_rounded,
                          iconColor: const Color(0xFF34D399),
                          title: 'Zero Cloud Telemetry',
                          description: 'Your OAuth tokens, media assets, and post history remain private in your phone\'s local SQLite vault.',
                        ),
                        const SizedBox(height: 10),
                        _buildMobileFeatureCard(
                          icon: Icons.verified_user_rounded,
                          iconColor: const Color(0xFFA78BFA),
                          title: 'Preflight Safety Engine',
                          description: 'Live validation checks character limits, aspect ratios, and platform policies before you publish.',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Pinned Bottom Actions for Thumb Reach
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF090D17),
                    border: Border(
                      top: BorderSide(color: Color(0xFF1E283D), width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Google Sign-In Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoggingIn ? null : _handleMobileGoogleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F2937)),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.g_mobiledata,
                                        size: 24,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Footer Legal Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMobileLegalLink('Terms', () => Navigator.of(context).pushNamed('/legal/terms')),
                          const Text(' • ', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          _buildMobileLegalLink('Privacy', () => Navigator.of(context).pushNamed('/legal/privacy')),
                          const Text(' • ', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          _buildMobileLegalLink('Disclaimer', () => Navigator.of(context).pushNamed('/legal/disclaimer')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1523),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2A3F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLegalLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: HERO + INTERACTIVE DEMO PREVIEW
  // ==========================================
  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 64 : 20,
        isDesktop ? 60 : 36,
        isDesktop ? 64 : 20,
        isDesktop ? 80 : 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            children: [
              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF121B2C),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF283A5E)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3865F6).withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '100% Free Workspace • Zero Cloud Lock-in • Local SQLite • 20+ Languages',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFBFDBFE),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Hero Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 56 : (isTablet ? 40 : 32),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                    height: 1.14,
                    color: Colors.white,
                  ),
                  children: [
                    const TextSpan(text: 'Publish to Every Social Network.\nOrganize Once. '),
                    WidgetSpan(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFFA78BFA), Color(0xFF38BDF8)],
                        ).createShader(bounds),
                        child: Text(
                          'Keep 100% of Your Data.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isDesktop ? 56 : (isTablet ? 40 : 32),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.6,
                            height: 1.14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Hero Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'The privacy-first Buffer alternative built for creators, growth teams, and agencies. Schedule campaigns across Instagram, X, LinkedIn, and YouTube with unified channel groups, smart preflights, and zero cloud telemetry.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 18 : 15,
                    color: const Color(0xFF94A3B8),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // CTA Row
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  _HeroPrimaryCtaButton(
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  _HeroSecondaryGhostButton(
                    label: 'Explore How It Works ↓',
                    onTap: () => _scrollTo(_workflowKey),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Micro trust proof
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'No remote API keys stored • Works offline • No credit card required',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 52),

              // HIGH-FIDELITY INTERACTIVE MOCKUP SHOWCASE
              _buildInteractiveAppShowcase(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveAppShowcase(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22304D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3865F6).withValues(alpha: 0.16),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: const Color(0xFF0D121F),
          child: Column(
            children: [
              // Mock Window Titlebar & Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0E18),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1B2438), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // macOS dots
                    Row(
                      children: [
                        Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // URL / Status Omnibar
                    Expanded(
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121828),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1F2B42)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'no5ocial://workspace/local-sqlite-vault  (Offline • Zero Telemetry)',
                                style: GoogleFonts.firaCode(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Database indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            'SQLite Active',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mock Tab Switcher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D121F),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1B2438), width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MockTabButton(
                        label: 'Multi-Channel Queue',
                        badge: '3',
                        icon: Icons.layers_rounded,
                        isSelected: _selectedPreviewTab == 0,
                        onTap: () => setState(() => _selectedPreviewTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _MockTabButton(
                        label: 'Preflight Safety Engine',
                        badge: 'PASS',
                        icon: Icons.check_circle_outline_rounded,
                        isSelected: _selectedPreviewTab == 1,
                        onTap: () => setState(() => _selectedPreviewTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _MockTabButton(
                        label: 'Connected Channel Matrix',
                        badge: '4 Active',
                        icon: Icons.hub_rounded,
                        isSelected: _selectedPreviewTab == 2,
                        onTap: () => setState(() => _selectedPreviewTab = 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Preview Body
              Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedPreviewTab == 0
                      ? _buildQueuePreviewTab()
                      : (_selectedPreviewTab == 1
                          ? _buildPreflightPreviewTab()
                          : _buildChannelMatrixPreviewTab()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueuePreviewTab() {
    return Column(
      key: const ValueKey('queue_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Multi-Destination Publishing Queue',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 3),
                Text(
                  'All timestamps normalized to configured timezone (UTC+5:30)',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3865F6), Color(0xFF4F70ED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Compose Post',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Queue Item 1
        _MockDetailedQueueCard(
          title: 'Introducing Shaadow v2.0 Architecture & Local-First Doctrine',
          timeStr: 'Today • 18:30 IST',
          status: 'SCHEDULED',
          statusColor: const Color(0xFF3B82F6),
          destinations: const [
            _PlatformBadge(platform: 'X / Twitter', color: Color(0xFF1E293B), iconColor: Colors.white, note: '210/280 chars'),
            _PlatformBadge(platform: 'LinkedIn', color: Color(0xFF0A66C2), iconColor: Colors.white, note: 'Article Card'),
            _PlatformBadge(platform: 'Instagram', color: Color(0xFFE1306C), iconColor: Colors.white, note: '4:5 Carousel'),
            _PlatformBadge(platform: 'YouTube', color: Color(0xFFEF4444), iconColor: Colors.white, note: 'Community Post'),
          ],
        ),
        const SizedBox(height: 12),

        // Queue Item 2
        _MockDetailedQueueCard(
          title: 'Engineering Deep Dive: Zero-Leak OAuth Tokens & SQLite Isolates',
          timeStr: 'Tomorrow • 10:00 IST',
          status: 'PREFLIGHT READY',
          statusColor: const Color(0xFF10B981),
          destinations: const [
            _PlatformBadge(platform: 'LinkedIn', color: Color(0xFF0A66C2), iconColor: Colors.white, note: 'Ready'),
            _PlatformBadge(platform: 'X / Twitter', color: Color(0xFF1E293B), iconColor: Colors.white, note: 'Thread (1/3)'),
          ],
        ),
        const SizedBox(height: 12),

        // Queue Item 3
        _MockDetailedQueueCard(
          title: 'Customer Showcase: How Apex Media Scaled to 14 Brands Without SaaS Subscriptions',
          timeStr: 'Friday • 15:00 IST',
          status: 'IN DRAFT QUEUE',
          statusColor: const Color(0xFFF59E0B),
          destinations: const [
            _PlatformBadge(platform: 'Instagram', color: Color(0xFFE1306C), iconColor: Colors.white, note: 'Media Pending'),
            _PlatformBadge(platform: 'YouTube', color: Color(0xFFEF4444), iconColor: Colors.white, note: 'Draft'),
          ],
        ),
      ],
    );
  }

  Widget _buildPreflightPreviewTab() {
    return Column(
      key: const ValueKey('preflight_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destination Preflight Engine Validation',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Checks platform-specific rules before enqueuing to prevent silent API failures',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Text(
                '4 / 4 DESTINATIONS PASS',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        const _PreflightCheckRow(
          platform: 'X / Twitter',
          badgeColor: Color(0xFF1E293B),
          rule: 'Character Count & Handles',
          status: 'Passed (184 / 280 max characters)',
          isPassed: true,
        ),
        const SizedBox(height: 10),
        const _PreflightCheckRow(
          platform: 'Instagram',
          badgeColor: Color(0xFFE1306C),
          rule: 'Aspect Ratio & Media Attachment',
          status: 'Passed (1080x1350 4:5 Portrait validated)',
          isPassed: true,
        ),
        const SizedBox(height: 10),
        const _PreflightCheckRow(
          platform: 'LinkedIn',
          badgeColor: Color(0xFF0A66C2),
          rule: 'Company Organization Scope',
          status: 'Passed (w_member_social & r_organization_social authorized)',
          isPassed: true,
        ),
        const SizedBox(height: 10),
        const _PreflightCheckRow(
          platform: 'YouTube',
          badgeColor: Color(0xFFEF4444),
          rule: 'Community Post Quota Guard',
          status: 'Passed (Channel tier verified for rich community updates)',
          isPassed: true,
        ),
      ],
    );
  }

  Widget _buildChannelMatrixPreviewTab() {
    return Column(
      key: const ValueKey('channel_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel Matrix — Shaadow Core Brands (Channel Group)',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bundle multiple social profiles to push unified campaigns with one click',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E283D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3865F6).withValues(alpha: 0.5)),
              ),
              child: Text(
                'UNLIMITED CHANNELS (FREE)',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF60A5FA),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Row(
          children: const [
            Expanded(
              child: _MockChannelCard(
                platform: 'Instagram',
                handle: '@shaadow_official',
                color: Color(0xFFE1306C),
                icon: Icons.camera_alt_outlined,
                followers: '48.2k followers',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MockChannelCard(
                platform: 'X / Twitter',
                handle: '@shaadow_hq',
                color: Color(0xFF1E293B),
                icon: Icons.tag,
                followers: '29.4k followers',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _MockChannelCard(
                platform: 'LinkedIn',
                handle: 'Shaadow Engineering',
                color: Color(0xFF0A66C2),
                icon: Icons.business,
                followers: '14.1k connections',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MockChannelCard(
                platform: 'YouTube',
                handle: 'Shaadow Tech',
                color: Color(0xFFEF4444),
                icon: Icons.play_circle_fill,
                followers: '8.7k subscribers',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2: PROOF & ARCHITECTURE STRIP
  // ==========================================
  Widget _buildMetricsStrip(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B101D),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF1A2338)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 24,
            spacing: 36,
            children: const [
              _MetricCard(metric: '4-in-1', label: 'Multi-Destination Bundle', sub: 'Instagram, X, LinkedIn, YT'),
              _MetricCard(metric: '100%', label: 'Local SQLite Storage', sub: 'Zero remote drafts or logs'),
              _MetricCard(metric: '20+', label: 'Global Languages', sub: 'Native offline Flutter l10n'),
              _MetricCard(metric: '0 Paywalls', label: 'Completely Free Forever', sub: 'Unlimited brands & channels'),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 3: WORKFLOW (3 STEPS)
  // ==========================================
  Widget _buildWorkflowSection(Key key, bool isDesktop) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 90 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionBadge(tag: 'STREAMLINED WORKFLOW'),
              const SizedBox(height: 14),
              Text(
                'From Draft to Multi-Network Dispatch in 3 Steps',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Eliminate endless tab switching and unreliable copy-pasting across disparate dashboards.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 52),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: _WorkflowCard(
                            stepNumber: '01',
                            title: 'Register Brands & Channel Groups',
                            desc: 'Connect your accounts once. Group multiple handles into Channel Groups to push identical or tailored copy simultaneously.',
                            icon: Icons.account_tree_rounded,
                            tag: 'Group Bundling',
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _WorkflowCard(
                            stepNumber: '02',
                            title: 'Deterministic Preflight Engine',
                            desc: 'Automatic client-side rules verify character boundaries (280 for X), aspect ratio (4:5 for IG), and tokens before queueing.',
                            icon: Icons.verified_user_rounded,
                            tag: 'Zero Silent Fails',
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _WorkflowCard(
                            stepNumber: '03',
                            title: 'Isolated Publishing & Local Audit',
                            desc: 'Each network runs on independent queue jobs. If one rate-limits, others succeed uninterrupted with clear manual-handoff options.',
                            icon: Icons.history_edu_rounded,
                            tag: 'Fault Isolated',
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: const [
                        _WorkflowCard(
                          stepNumber: '01',
                          title: 'Register Brands & Channel Groups',
                          desc: 'Connect your accounts once. Group multiple handles into Channel Groups to push identical or tailored copy simultaneously.',
                          icon: Icons.account_tree_rounded,
                          tag: 'Group Bundling',
                        ),
                        SizedBox(height: 20),
                        _WorkflowCard(
                          stepNumber: '02',
                          title: 'Deterministic Preflight Engine',
                          desc: 'Automatic client-side rules verify character boundaries (280 for X), aspect ratio (4:5 for IG), and tokens before queueing.',
                          icon: Icons.verified_user_rounded,
                          tag: 'Zero Silent Fails',
                        ),
                        SizedBox(height: 20),
                        _WorkflowCard(
                          stepNumber: '03',
                          title: 'Isolated Publishing & Local Audit',
                          desc: 'Each network runs on independent queue jobs. If one rate-limits, others succeed uninterrupted with clear manual-handoff options.',
                          icon: Icons.history_edu_rounded,
                          tag: 'Fault Isolated',
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4: BENTO FEATURES GRID
  // ==========================================
  Widget _buildBentoFeaturesSection(Key key, bool isDesktop) {
    return Container(
      key: key,
      width: double.infinity,
      color: const Color(0xFF0A0F1B),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 90 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionBadge(tag: 'CORE SYSTEM FEATURES'),
              const SizedBox(height: 14),
              Text(
                'Engineered for Correctness & Data Independence',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No vanity features. Only rock-solid publishing infrastructure designed for real growth.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 52),

              GridView.count(
                crossAxisCount: isDesktop ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 22,
                mainAxisSpacing: 22,
                childAspectRatio: isDesktop ? 1.25 : 1.7,
                children: const [
                  _BentoCard(
                    icon: Icons.hub_rounded,
                    color: Color(0xFF3865F6),
                    title: 'Channel Groups & Multi-Brand',
                    desc: 'Group multiple social handles by brand or product line. Post to your entire ecosystem with one unified composer without duplicate work.',
                    badge: 'Multi-Network',
                  ),
                  _BentoCard(
                    icon: Icons.fact_check_rounded,
                    color: Color(0xFFA855F7),
                    title: 'Destination Preflight Engine',
                    desc: 'Instant rule checks detect platform policy violations, missing media, and token expirations prior to job creation.',
                    badge: 'Prevent Fails',
                  ),
                  _BentoCard(
                    icon: Icons.security_rounded,
                    color: Color(0xFF10B981),
                    title: 'Zero Cloud Storage / 100% Local',
                    desc: 'Drafts, media references, and queue statuses reside strictly in your local device SQLite database. Zero remote telemetry.',
                    badge: 'Privacy First',
                  ),
                  _BentoCard(
                    icon: Icons.schedule_send_rounded,
                    color: Color(0xFFF59E0B),
                    title: 'Timezone-Aware Scheduling',
                    desc: 'Calendar and queue schedules honor your specified timezone with UTC persistence for deterministic accuracy.',
                    badge: 'UTC Native',
                  ),
                  _BentoCard(
                    icon: Icons.translate_rounded,
                    color: Color(0xFF06B6D4),
                    title: '20+ Global Languages',
                    desc: 'First-class l10n support spanning English, Spanish, Arabic, Japanese, German, Hindi, and 14 other languages natively.',
                    badge: 'Global Ready',
                  ),
                  _BentoCard(
                    icon: Icons.manage_history_rounded,
                    color: Color(0xFFEC4899),
                    title: 'Immutable Audit Trail',
                    desc: 'All publish attempts, timeouts, retry actions, and manual handoffs are logged in SQLite for transparent inspection.',
                    badge: 'Audited',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: HONEST COMPARISON TABLE
  // ==========================================
  Widget _buildComparisonSection(Key key, bool isDesktop) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 90 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              const _SectionBadge(tag: 'ARCHITECTURAL ADVANTAGE'),
              const SizedBox(height: 14),
              Text(
                'How no5ocial Compares to Cloud Social Schedulers',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'An honest architectural breakdown against traditional subscription-based tools.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 48),

              // Modern Glassmorphic Table Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1424),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E283D)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF141C30),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'CAPABILITY',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3865F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'no5ocial',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF60A5FA),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Buffer / Hootsuite',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    const _ModernCompareRow(
                      feature: 'Data Storage & Privacy',
                      no5ocial: '100% Local SQLite',
                      no5ocialHighlight: true,
                      competitor: 'Remote Cloud Servers',
                    ),
                    const _ModernCompareRow(
                      feature: 'Pricing & Licensing',
                      no5ocial: '100% Free / No Paid Tiers',
                      no5ocialHighlight: true,
                      competitor: '\$18 - \$120 / mo (Paywalled)',
                    ),
                    const _ModernCompareRow(
                      feature: 'Connected Channel Limits',
                      no5ocial: 'Unlimited Channels (Free)',
                      no5ocialHighlight: true,
                      competitor: '3 channels cap on free tier',
                    ),
                    const _ModernCompareRow(
                      feature: 'Multi-Network Channel Groups',
                      no5ocial: 'Included for All Brands',
                      no5ocialHighlight: true,
                      competitor: 'Locked behind Enterprise tier',
                    ),
                    const _ModernCompareRow(
                      feature: 'Preflight Safety Engine',
                      no5ocial: 'Client-side rules per platform',
                      no5ocialHighlight: true,
                      competitor: 'Basic server error on fail',
                    ),
                    const _ModernCompareRow(
                      feature: 'Multi-Destination Isolation',
                      no5ocial: 'Independent target tracking',
                      no5ocialHighlight: true,
                      competitor: 'Global failure rollbacks',
                    ),
                    const _ModernCompareRow(
                      feature: 'Language Availability',
                      no5ocial: '20+ Global Languages',
                      no5ocialHighlight: true,
                      competitor: 'Usually 1-4 languages',
                    ),
                    const _ModernCompareRow(
                      feature: 'Account Credential Security',
                      no5ocial: 'Zero secrets stored on server',
                      no5ocialHighlight: true,
                      competitor: 'Tokens held on central cloud',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 6: DATA SOVEREIGNTY / SECURITY
  // ==========================================
  Widget _buildDataSovereigntySection(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF090D17),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 80 : 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 48 : 28),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.8),
                radius: 1.4,
                colors: [
                  const Color(0xFF152238),
                  const Color(0xFF0E1424),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF22314E)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 36, color: Color(0xFF34D399)),
                ),
                const SizedBox(height: 22),
                Text(
                  'Your Social Publishing Data Belongs to You. Completely.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Text(
                    'We strictly adhere to a zero-telemetry doctrine. no5ocial never harvests credentials, tracks private post ideas, or mirrors marketing media to remote databases. You can export, inspect, or wipe your SQLite database at any time from Workspace Settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: const [
                    _SecurityTag(label: 'Zero Remote Cookies'),
                    _SecurityTag(label: 'AES Local Storage'),
                    _SecurityTag(label: 'Short-Lived Signed URLs'),
                    _SecurityTag(label: 'Full DB Export Anytime'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 7: FAQ SECTION
  // ==========================================
  Widget _buildFaqSection(Key key, bool isDesktop) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 90 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const _SectionBadge(tag: 'FREQUENTLY ASKED QUESTIONS'),
              const SizedBox(height: 14),
              Text(
                'Everything You Need to Know',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clear answers about architecture, security, and scheduling workflows.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 48),

              const _ModernFaqAccordion(
                question: 'Does no5ocial store my post ideas or media on remote servers?',
                answer: 'No. All posts, campaigns, image references, and channel groups are persisted strictly in your local device SQLite database. We operate zero cloud analytics or telemetry servers.',
              ),
              const SizedBox(height: 14),
              const _ModernFaqAccordion(
                question: 'What happens if one social platform fails during a multi-publish job?',
                answer: 'no5ocial publishes each destination independently. If X rejects a character count or Instagram has a connection issue, your LinkedIn and YouTube jobs still complete successfully. You can then review and retry or manually hand off the failing platform.',
              ),
              const SizedBox(height: 14),
              const _ModernFaqAccordion(
                question: 'How do Channel Groups work?',
                answer: 'Channel Groups bundle multiple social profiles associated with a single product or brand (e.g. Acme Instagram + Acme X). In the composer, selecting the group automatically prepares preflight rules for all bundled targets.',
              ),
              const SizedBox(height: 14),
              const _ModernFaqAccordion(
                question: 'Are 20+ languages available offline?',
                answer: 'Yes. All 20 language translations are compiled natively with Flutter localizations and work offline without needing active network requests to translation APIs.',
              ),
              const SizedBox(height: 14),
              const _ModernFaqAccordion(
                question: 'Is no5ocial completely free?',
                answer: 'Yes, no5ocial has no paywalls, hidden tiers, or artificial caps. You can connect unlimited channels and register unlimited brands without recurring credit card charges.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 8: FINAL CALL TO ACTION
  // ==========================================
  Widget _buildFinalCtaSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 80 : 50,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0C111E),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF1A243B)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Text(
                'Take Control of Your Social Publishing Today',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Join marketing teams, product builders, and creators who demand clean, deterministic publishing without SaaS subscription traps.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _HeroPrimaryCtaButton(
                onTap: () => Navigator.of(context).pushNamed('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 9: RICH FOOTER
  // ==========================================
  Widget _buildFooter(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF060910),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Column
                  Expanded(
                    flex: isDesktop ? 4 : 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo/no5ocial_white.png',
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Image.asset('assets/logo/no5ocial_N.png', height: 26),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The local-first social publishing and scheduling workspace engineered for correctness, transparency, and low operating cost.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1626),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1E2B42)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                'Shaadow Product Engineering',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),

                  // Product Links
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRODUCT',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FooterLink(label: 'Publishing Queue', onTap: () => _scrollTo(_workflowKey)),
                        _FooterLink(label: 'Preflight Rules', onTap: () => _scrollTo(_featuresKey)),
                        _FooterLink(label: 'Channel Groups', onTap: () => _scrollTo(_featuresKey)),
                        _FooterLink(label: 'Comparison', onTap: () => _scrollTo(_compareKey)),
                      ],
                    ),
                  ),

                  // Legal Links
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEGAL & COMPLIANCE',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FooterLink(
                          label: 'Terms of Service',
                          onTap: () => Navigator.of(context).pushNamed('/legal/terms'),
                        ),
                        _FooterLink(
                          label: 'Privacy Policy',
                          onTap: () => Navigator.of(context).pushNamed('/legal/privacy'),
                        ),
                        _FooterLink(
                          label: 'Disclaimer',
                          onTap: () => Navigator.of(context).pushNamed('/legal/disclaimer'),
                        ),
                      ],
                    ),
                  ),

                  // Access Links
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCESS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FooterLink(
                          label: 'Sign In to Workspace',
                          onTap: () => Navigator.of(context).pushNamed('/login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const Divider(color: Color(0xFF161F31)),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  Text(
                    '© 2026 no5ocial by Shaadow. All rights reserved. Zero remote tracking.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                  ),
                  Text(
                    'Local-First SQLite Architecture • Multi-Destination Engine',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// REUSABLE MODERN COMPONENTS
// ==========================================

class _NavbarSignInButton extends StatefulWidget {
  final VoidCallback onTap;

  const _NavbarSignInButton({required this.onTap});

  @override
  State<_NavbarSignInButton> createState() => _NavbarSignInButtonState();
}

class _NavbarSignInButtonState extends State<_NavbarSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            gradient: _hovered
                ? const LinearGradient(colors: [Color(0xFF436AF7), Color(0xFF5D84FF)])
                : const LinearGradient(colors: [Color(0xFF3865F6), Color(0xFF4A72F8)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3865F6).withValues(alpha: _hovered ? 0.45 : 0.25),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Sign In',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPrimaryCtaButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HeroPrimaryCtaButton({required this.onTap});

  @override
  State<_HeroPrimaryCtaButton> createState() => _HeroPrimaryCtaButtonState();
}

class _HeroPrimaryCtaButtonState extends State<_HeroPrimaryCtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: _hovered
                ? const LinearGradient(colors: [Color(0xFF4268F8), Color(0xFF6289FF)])
                : const LinearGradient(colors: [Color(0xFF3659D9), Color(0xFF4F70ED)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3865F6).withValues(alpha: _hovered ? 0.55 : 0.35),
                blurRadius: _hovered ? 28 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Open Publishing Workspace',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSecondaryGhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeroSecondaryGhostButton({required this.label, required this.onTap});

  @override
  State<_HeroSecondaryGhostButton> createState() => _HeroSecondaryGhostButtonState();
}

class _HeroSecondaryGhostButtonState extends State<_HeroSecondaryGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? const Color(0xFF4A68A0) : const Color(0xFF263554),
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _hovered ? Colors.white : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavHeaderLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavHeaderLink({required this.label, required this.onTap});

  @override
  State<_NavHeaderLink> createState() => _NavHeaderLinkState();
}

class _NavHeaderLinkState extends State<_NavHeaderLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.07) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              color: _hovered ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MockTabButton extends StatelessWidget {
  final String label;
  final String badge;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MockTabButton({
    required this.label,
    required this.badge,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2942) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3865F6).withValues(alpha: 0.6) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3865F6).withValues(alpha: 0.3) : const Color(0xFF1A2234),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockDetailedQueueCard extends StatelessWidget {
  final String title;
  final String timeStr;
  final String status;
  final Color statusColor;
  final List<_PlatformBadge> destinations;

  const _MockDetailedQueueCard({
    required this.title,
    required this.timeStr,
    required this.status,
    required this.statusColor,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222F4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.send_rounded, color: statusColor, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1D283E), height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: destinations,
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String platform;
  final Color color;
  final Color iconColor;
  final String note;

  const _PlatformBadge({
    required this.platform,
    required this.color,
    required this.iconColor,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B243B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF293755)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            platform,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '•  $note',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreflightCheckRow extends StatelessWidget {
  final String platform;
  final Color badgeColor;
  final String rule;
  final String status;
  final bool isPassed;

  const _PreflightCheckRow({
    required this.platform,
    required this.badgeColor,
    required this.rule,
    required this.status,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF222F4A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              platform,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _MockChannelCard extends StatelessWidget {
  final String platform;
  final String handle;
  final Color color;
  final IconData icon;
  final String followers;

  const _MockChannelCard({
    required this.platform,
    required this.handle,
    required this.color,
    required this.icon,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222F4A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$platform • $followers',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String metric;
  final String label;
  final String sub;

  const _MetricCard({
    required this.metric,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          metric,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final String tag;

  const _SectionBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF141F33),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF283A5E)),
      ),
      child: Text(
        tag,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF60A5FA),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _WorkflowCard extends StatefulWidget {
  final String stepNumber;
  final String title;
  final String desc;
  final IconData icon;
  final String tag;

  const _WorkflowCard({
    required this.stepNumber,
    required this.title,
    required this.desc,
    required this.icon,
    required this.tag,
  });

  @override
  State<_WorkflowCard> createState() => _WorkflowCardState();
}

class _WorkflowCardState extends State<_WorkflowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF121A2C) : const Color(0xFF0D1322),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? const Color(0xFF3865F6).withValues(alpha: 0.7) : const Color(0xFF1E283D),
            width: 1.2,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: const Color(0xFF3865F6).withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.stepNumber,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3865F6),
                    letterSpacing: -1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2438),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.tag,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF8896B3),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String badge;

  const _BentoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.badge,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF141D30) : const Color(0xFF0E1424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.color.withValues(alpha: 0.6) : const Color(0xFF1F2A3F),
            width: 1.2,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182236),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badge,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                widget.desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF8896B3),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernCompareRow extends StatelessWidget {
  final String feature;
  final String no5ocial;
  final bool no5ocialHighlight;
  final String competitor;

  const _ModernCompareRow({
    required this.feature,
    required this.no5ocial,
    required this.no5ocialHighlight,
    required this.competitor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1A2438))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    no5ocial,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF34D399),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    competitor,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTag extends StatelessWidget {
  final String label;

  const _SecurityTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF152033),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF233554)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: Color(0xFF34D399)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernFaqAccordion extends StatefulWidget {
  final String question;
  final String answer;

  const _ModernFaqAccordion({
    required this.question,
    required this.answer,
  });

  @override
  State<_ModernFaqAccordion> createState() => _ModernFaqAccordionState();
}

class _ModernFaqAccordionState extends State<_ModernFaqAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isExpanded ? const Color(0xFF121A2C) : const Color(0xFF0D1322),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded ? const Color(0xFF3865F6).withValues(alpha: 0.6) : const Color(0xFF1D283E),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _isExpanded ? const Color(0xFF60A5FA) : const Color(0xFF64748B),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8896B3),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
