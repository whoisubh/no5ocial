import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';

/// Ad-supported Publishing Coins Sheet displayed when a quota bottleneck is hit.
/// Pro/paid subscription system is disabled/hidden in favor of the free ad-reward coin system.
class UpgradePaywallSheet extends StatefulWidget {
  final SystemBottleneckType bottleneck;
  final VoidCallback? onDayPassUnlockRequested;
  final VoidCallback? onOfferwallRequested;
  final String? currencyCode;

  const UpgradePaywallSheet({
    super.key,
    required this.bottleneck,
    this.onDayPassUnlockRequested,
    this.onOfferwallRequested,
    this.currencyCode,
  });

  static Future<bool?> show(
    BuildContext context, {
    required SystemBottleneckType bottleneck,
    VoidCallback? onDayPassUnlockRequested,
    VoidCallback? onOfferwallRequested,
    String? currencyCode,
  }) {
    return AppSheets.showAdaptiveFormSheet<bool>(
      context,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Earn Coins to Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      builder: (ctx, _) => UpgradePaywallSheet(
        bottleneck: bottleneck,
        onDayPassUnlockRequested: onDayPassUnlockRequested,
        onOfferwallRequested: onOfferwallRequested,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  State<UpgradePaywallSheet> createState() => _UpgradePaywallSheetState();
}

class _UpgradePaywallSheetState extends State<UpgradePaywallSheet> {
  bool _isWatchingAd = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Explanation Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have reached today\'s 10 free scheduled posts. Watch a short partner video ad to earn Coins and keep publishing immediately!',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Coin Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Coin Balance',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('🪙 ', style: TextStyle(fontSize: 16)),
                              Text(
                                '${monetization.postCoins} Coins',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        '1 Coin = 1 Post',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Primary Watch Ad Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isWatchingAd
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          final res = await monetization.watchAdForCoins(rewardAmount: 2);
                          if (!mounted) return;
                          setState(() => _isWatchingAd = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? const Color(0xFF059669) : AppColors.error,
                            ),
                          );
                          if (res.success) {
                            nav.pop(true);
                          }
                        },
                  icon: _isWatchingAd
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_circle_filled_rounded, size: 20),
                  label: Text(
                    _isWatchingAd ? 'Loading Video Ad...' : 'Watch Ad to Earn +2 Coins',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }
}
