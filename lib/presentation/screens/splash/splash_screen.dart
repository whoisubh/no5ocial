import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/presentation/navigation/main_scaffold.dart';
import 'package:no5ocial/presentation/screens/landing/landing_screen.dart';
import 'package:no5ocial/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:no5ocial/presentation/screens/welcome/mobile_welcome_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/session_expired_sheet.dart';

/// Premium animated Splash Screen UI for no5ocial.
/// Smoothly initializes the application, verifies local session state,
/// and redirects to the correct destination screen.
class SplashScreen extends StatefulWidget {
  final AppState appState;

  const SplashScreen({super.key, required this.appState});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  String _statusText = 'Initializing workspace...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _startInitialization();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    // Stage 1: Load saved session and settings from local SQLite storage
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _statusText = 'Checking session credentials...');
    }

    try {
      await widget.appState.loadSavedUserProfile();
      await widget.appState.loadSavedThemeMode();
    } catch (_) {
      // Local fallback handled gracefully in AppState
    }

    // Stage 2: Enforce minimum presentation duration for a smooth experience
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final appState = widget.appState;

    if (appState.isLoggedIn) {
      if (appState.isSessionExpired) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => MainScaffold(
              appState: appState,
              initialIndex: 0,
            ),
            transitionsBuilder: _fadeTransition,
          ),
          (route) => false,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SessionExpiredSheet.show(
            context,
            maskedEmail: appState.maskedEmail ?? 'your account',
            onConfirmLogout: () async {
              await appState.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          );
        });
        return;
      }

      if (appState.brands.isEmpty && !appState.hasCompletedOnboarding) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => OnboardingScreen(
              appState: appState,
              onComplete: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
              },
            ),
            transitionsBuilder: _fadeTransition,
          ),
          (route) => false,
        );
      } else {
        if (appState.brands.isEmpty) {
          appState.ensureDefaultBrandExists();
        }
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => MainScaffold(
              appState: appState,
              initialIndex: 0,
            ),
            transitionsBuilder: _fadeTransition,
          ),
          (route) => false,
        );
      }
      return;
    }

    // Unauthenticated: Direct to Welcome or Landing Screen based on platform
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => MobileWelcomeScreen(appState: appState),
          transitionsBuilder: _fadeTransition,
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (ctx, _, _) {
            if (MediaQuery.of(ctx).size.width < 700) {
              return MobileWelcomeScreen(appState: appState);
            }
            return LandingScreen(appState: appState);
          },
          transitionsBuilder: _fadeTransition,
        ),
        (route) => false,
      );
    }
  }

  Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Radial Background Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Center(
                  child: Container(
                    width: 320 * _glowAnimation.value,
                    height: 320 * _glowAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withAlpha(isDark ? 55 : 35),
                          AppColors.accent.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Center Logo, Title, and Animated Session Progress
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Card with glowing elevation
                  Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.accent.withAlpha(isDark ? 80 : 50),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withAlpha(isDark ? 90 : 50),
                          blurRadius: 36,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo/no5ocial_N.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.rocket_launch_rounded,
                        size: 48,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Name
                  Text(
                    'no5ocial',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle Tagline
                  Text(
                    'Social Publishing & Scheduling Workspace',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Status / Loading Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withAlpha(160)
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Security & Compliance Footer
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Direct Official Social APIs • Private Offline Vault',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
