import 'dart:async';
import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';

/// Modal bottom sheet / dialog shown when the user's session expires
/// (after 1 week on web, or 2 weeks on android/native).
/// Shows masked email of last logged in user, and disables the logout button for 2 seconds
/// so the user can read the notice before clicking to re-authenticate.
class SessionExpiredSheet extends StatefulWidget {
  final String maskedEmail;
  final VoidCallback onConfirmLogout;

  const SessionExpiredSheet({
    super.key,
    required this.maskedEmail,
    required this.onConfirmLogout,
  });

  /// Static helper to display the sheet modally without dismissal
  static Future<void> show(
    BuildContext context, {
    required String maskedEmail,
    required VoidCallback onConfirmLogout,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PopScope(
        canPop: false,
        child: SessionExpiredSheet(
          maskedEmail: maskedEmail,
          onConfirmLogout: onConfirmLogout,
        ),
      ),
    );
  }

  @override
  State<SessionExpiredSheet> createState() => _SessionExpiredSheetState();
}

class _SessionExpiredSheetState extends State<SessionExpiredSheet> {
  int _remainingSeconds = 2;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else {
            _remainingSeconds = 0;
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/logo/no5ocial_white.png'
        : 'assets/logo/no5ocial.png';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Official Brand Logo
          Center(
            child: Image.asset(
              logoAsset,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'no5ocial',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text(
                'Session Expired',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation
          const Text(
            'Your session lifetime has expired (1 week on Web / 2 weeks on Mobile). For security, you will now be logged out and asked to sign in again to your workspace.',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Masked Email Identity Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lastly logged in as:',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.maskedEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Text(
                    'Re-auth Needed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button with 2s Read Delay
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _remainingSeconds > 0
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onConfirmLogout();
                    },
              icon: Icon(
                _remainingSeconds > 0 ? Icons.timer_outlined : Icons.logout,
                size: 18,
              ),
              label: Text(
                _remainingSeconds > 0
                    ? 'Log Out & Sign In Again (${_remainingSeconds}s)'
                    : 'Log Out & Sign In Again',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.surfaceSecondary,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
