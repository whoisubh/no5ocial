import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Dedicated Native Mobile Welcome & Authentication Screen for Android & iOS.
/// Completely decoupled from the desktop web landing page to eliminate caching,
/// overflow, and responsiveness issues on mobile devices.
class MobileWelcomeScreen extends StatefulWidget {
  final AppState appState;

  const MobileWelcomeScreen({super.key, required this.appState});

  @override
  State<MobileWelcomeScreen> createState() => _MobileWelcomeScreenState();
}

class _MobileWelcomeScreenState extends State<MobileWelcomeScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

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
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showGoogleConfigNotice(e.toString());
      }
    }
  }

  void _showGoogleConfigNotice(String errorDetail) {
    final isDeveloperError = errorDetail.contains('10') || errorDetail.contains('DEVELOPER_ERROR');

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
            const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isDeveloperError ? 'Google OAuth Setup Required' : 'Google Sign-In Notice',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDeveloperError) ...[
              Text(
                'Google Play Services returned ApiException 10 (DEVELOPER_ERROR). On Android, Google requires registering your app\'s SHA-1 fingerprint in Google Cloud Console under an Android OAuth Client ID.',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFCBD5E1),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B101D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package Name:',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SelectableText(
                      'com.shaadow.no5ocial',
                      style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SHA-1 Certificate Fingerprint:',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SelectableText(
                      '6E:BC:D7:D2:98:FC:8D:B4:18:C5:7C:14:C4:43:43:CD:9B:4C:1D:E5',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Android OAuth Client ID:',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SelectableText(
                      GoogleAuthService.androidClientId,
                      style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                errorDetail,
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Dismiss',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -120,
            left: screenWidth / 2 - 200,
            child: Container(
              width: 400,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF254394).withValues(alpha: 0.45),
                    const Color(0xFF1E1B4B).withValues(alpha: 0.18),
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
                // Top App Bar: Brand Logo & Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/logo/no5ocial_white.png',
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/logo/no5ocial_cropped.png',
                          height: 28,
                        ),
                      ),
                      const Spacer(),
                      _buildLanguagePill(),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                                  '100% On-Device Vault • Private & Secure',
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

                        // Native Hero Title
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
                        _buildFeatureCard(
                          icon: Icons.hub_rounded,
                          iconColor: const Color(0xFF60A5FA),
                          title: 'Multi-Channel Composer',
                          description: 'Compose once, then customize titles, captions & tags for Instagram, YouTube, X & LinkedIn.',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureCard(
                          icon: Icons.shield_rounded,
                          iconColor: const Color(0xFF34D399),
                          title: 'Zero Cloud Telemetry',
                          description: 'Your connected accounts, media assets, and post history remain private in your phone\'s secure local vault.',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureCard(
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

                // Thumb-Friendly Bottom Action Dock
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
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
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
                          _buildLegalLink('Terms', () => Navigator.of(context).pushNamed('/legal/terms')),
                          const Text(' • ', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          _buildLegalLink('Privacy', () => Navigator.of(context).pushNamed('/legal/privacy')),
                          const Text(' • ', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          _buildLegalLink('Disclaimer', () => Navigator.of(context).pushNamed('/legal/disclaimer')),
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

  Widget _buildFeatureCard({
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

  Widget _buildLegalLink(String label, VoidCallback onTap) {
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
}
