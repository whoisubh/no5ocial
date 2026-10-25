import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/services/passkey_service.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/core/errors/app_error.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;

  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  DateTime? _lastLoginAttempt;
  bool _hasPasskeys = false;

  @override
  void initState() {
    super.initState();
    _checkPasskeys();
  }

  Future<void> _checkPasskeys() async {
    try {
      final list = await PasskeyService.instance.getRegisteredPasskeys();
      if (mounted && list.isNotEmpty) {
        setState(() => _hasPasskeys = true);
      }
    } catch (_) {}
  }

  Future<void> _handlePasskeyLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final verified = await PasskeyService.instance.authenticatePasskey();
      if (verified) {
        final session = await SessionService.instance.getSession();
        if (session != null) {
          await widget.appState.signInLocally(
            name: session['name'] ?? 'Passkey User',
            email: session['email'] ?? '',
            photoUrl: session['photo_url'],
            id: session['id'],
            provider: 'passkey',
            rawData: session['raw_data'],
          );
        } else {
          await widget.appState.signInLocally(
            name: 'Passkey User',
            email: widget.appState.localUserEmail ?? 'user@no5ocial.workspace',
            provider: 'passkey',
          );
        }
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e, st) {
      if (mounted) {
        AppErrorHandler.showError(
          context,
          e,
          stackTrace: st,
          overrideErrorId: AppErrorCode.authBiometricFailedId,
          fallbackTitle: 'Passkey Sign-In Failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Trigger real Google Identity Services Sign-In via official google_sign_in SDK
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    // Rate-limiting debounce to prevent popup spamming and rapid clicks
    final now = DateTime.now();
    if (_lastLoginAttempt != null && now.difference(_lastLoginAttempt!).inMilliseconds < 1500) {
      return;
    }
    _lastLoginAttempt = now;

    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? account = await GoogleAuthService.instance.signIn();

      if (account != null) {
        // Authenticated with real Google account from official Google Identity SDK
        final rawDisplayName = (account.displayName != null && account.displayName!.trim().isNotEmpty)
            ? account.displayName!
            : account.email.split('@').first;
        final cleanDisplayName = InputValidator.sanitize(rawDisplayName);
        final displayName = cleanDisplayName.length > InputValidator.maxBrandNameLength
            ? cleanDisplayName.substring(0, InputValidator.maxBrandNameLength)
            : (cleanDisplayName.isEmpty ? 'Google User' : cleanDisplayName);

        final email = InputValidator.sanitize(account.email);
        final emailError = InputValidator.validateEmail(email);
        if (emailError != null) {
          throw Exception('Google account returned an invalid email format: $email');
        }

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
          debugPrint('Notice: could not extract raw auth token details: $e');
        }

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
          // Navigate strictly to /dashboard (redirects to /onboarding if brand count is 0)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        // User dismissed the official Google sign-in popup
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.showError(
          context,
          e,
          stackTrace: st,
          overrideErrorId: AppErrorCode.authFailedId,
          fallbackTitle: 'Authentication Failed',
        );
        if (e.toString().contains('People API') || e.toString().contains('people.googleapis.com')) {
          _showGoogleConfigNotice(e.toString());
        }
      }
    }
  }

  /// Informative dialog displayed if Google Cloud configuration requires attention
  void _showGoogleConfigNotice(String errorDetail) {
    final isPeopleApiError = errorDetail.contains('People API') ||
        errorDetail.contains('people.googleapis.com');

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
            const SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPeopleApiError ? 'Enable Google People API' : 'Google OAuth Setup',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPeopleApiError) ...[
                Text(
                  'Great news: Google OAuth authentication succeeded and issued an access token! However, your Google Cloud project requires the People API enabled to allow reading your user profile.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
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
                        '1-Click Activation:',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF34D399),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=1030532523858',
                        style: GoogleFonts.firaCode(
                          color: const Color(0xFF60A5FA),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Open this URL in your browser and click "ENABLE".',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'The official Google Sign-In SDK was invoked. For Google to complete authentication, your OAuth 2.0 Client ID must be configured in Google Cloud Console.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
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
                        'Ensure Authorized JavaScript Origins:',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF60A5FA),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        kIsWeb
                            ? 'Add ${Uri.base.origin} to Authorized JavaScript Origins and Authorized redirect URIs in Google Cloud Console.'
                            : 'Add your package name and SHA-1 certificate fingerprint in Google Cloud Console.',
                        style: GoogleFonts.firaCode(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      if (errorDetail.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Reported Error:',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          errorDetail,
                          style: GoogleFonts.firaCode(
                            color: const Color(0xFFE2E8F0),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              const Color(0xFF1A2340).withValues(alpha: 0.6),
              const Color(0xFF0A0D14),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101522),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF222C40)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3865F6).withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Official Brand Logo (White variant for dark theme)
                      Image.asset(
                        'assets/logo/no5ocial_white.png',
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/logo/no5ocial_cropped.png',
                          height: 40,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        l10n?.loginTitle ?? 'Welcome to no5ocial',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.loginSubtitle ?? 'Your all-in-one social publishing workspace',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF8896B3),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Official Google Sign-In Button (Invokes official Google SDK)
                      _GoogleSignInButton(
                        onPressed: _handleGoogleLogin,
                        isLoading: _isLoading,
                        text: l10n?.loginWithGoogle ?? 'Continue with Google',
                      ),

                      if (_hasPasskeys) ...[
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFF222C40))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ),
                            Expanded(child: Divider(color: Color(0xFF222C40))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handlePasskeyLogin,
                            icon: const Icon(Icons.vpn_key_rounded, size: 18, color: Color(0xFF60A5FA)),
                            label: const Text(
                              'Sign in with Passkey',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              backgroundColor: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Local storage privacy reassurance
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142019),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E4620)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Color(0xFF34D399),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n?.loginLocalNote ??
                                    'Your data is stored locally on this device only.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Divider(height: 1, color: Color(0xFF222C40)),
                      const SizedBox(height: 20),

                      // Legal links: Terms, Privacy, Disclaimer
                      Text(
                        l10n?.loginDisclaimer ?? 'By continuing, you agree to our',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7A99),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _LegalLinkButton(
                            text: l10n?.termsOfService ?? 'Terms of Service',
                            onTap: () => Navigator.of(context).pushNamed('/legal/terms'),
                          ),
                          const Text('•', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
                          _LegalLinkButton(
                            text: l10n?.privacyPolicy ?? 'Privacy Policy',
                            onTap: () => Navigator.of(context).pushNamed('/legal/privacy'),
                          ),
                          const Text('•', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
                          _LegalLinkButton(
                            text: l10n?.disclaimer ?? 'Disclaimer',
                            onTap: () => Navigator.of(context).pushNamed('/legal/disclaimer'),
                          ),
                        ],
                      ),
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
}

class _LegalLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _LegalLinkButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF60A5FA),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF60A5FA),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Official Sign In with Google Button (Identity Services Branding Guidelines)
// ---------------------------------------------------------------------------

class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const _GoogleSignInButton({
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Material(
        color: _isHovered ? const Color(0xFFF8F9FA) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(4),
          hoverColor: const Color(0xFFF8F9FA),
          splashColor: const Color(0xFFE8EAED),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF747775),
                width: 1.0,
              ),
              boxShadow: _isHovered && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: _GoogleLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.text,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Official multi-color Google 'G' logo vector painter
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Blue (#4285F4)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green (#34A853)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24.0, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow (#FBBC05)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
      ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red (#EA4335)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24.0, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
