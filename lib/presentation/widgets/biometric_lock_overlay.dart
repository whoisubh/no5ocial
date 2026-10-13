import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/biometric_lock_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';

/// Full-screen lock barrier rendered over the application when device screen lock is engaged.
class BiometricLockOverlay extends StatefulWidget {
  final Widget child;

  const BiometricLockOverlay({
    super.key,
    required this.child,
  });

  @override
  State<BiometricLockOverlay> createState() => _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends State<BiometricLockOverlay> {
  @override
  void initState() {
    super.initState();
    BiometricLockService.instance.addListener(_handleLockChange);
  }

  @override
  void dispose() {
    BiometricLockService.instance.removeListener(_handleLockChange);
    super.dispose();
  }

  void _handleLockChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = BiometricLockService.instance.isLocked;

    return Stack(
      children: [
        widget.child,
        if (isLocked)
          Positioned.fill(
            child: Material(
              color: AppColors.background,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Official brand logo
                        Image.asset(
                          'assets/logo/no5ocial_white.png',
                          height: 40,
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
                        const SizedBox(height: 36),

                        // Lock Graphic Container
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withAlpha(20),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(60),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            size: 48,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Workspace Locked',
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Biometric or screen lock verification is required to access your publishing workspace.',
                          style: AppTypography.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: 260,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await BiometricLockService.instance.authenticate();
                            },
                            icon: const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text(
                              'Unlock with Biometrics',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
