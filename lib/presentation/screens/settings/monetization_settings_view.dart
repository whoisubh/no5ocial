import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Consumer Settings Section for the Ad-Supported Publishing & Coin System.
/// Pro subscription system is disabled/hidden for now in favor of ad-earned coins.
class MonetizationSettingsView extends StatefulWidget {
  final AppState appState;

  const MonetizationSettingsView({super.key, required this.appState});

  @override
  State<MonetizationSettingsView> createState() => _MonetizationSettingsViewState();
}

class _MonetizationSettingsViewState extends State<MonetizationSettingsView> {
  bool _isWatchingAd = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;
        final ceiling = monetization.dailyCeiling;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Publishing Coins (Credits) Wallet Card (Primary Ad-System Action)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Publishing Coins',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '1 Coin = 1 Multi-Platform Post',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙 ', style: TextStyle(fontSize: 13)),
                            Text(
                              '${monetization.postCoins} Coins',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reached your daily free post limit? Watch a short partner video ad to earn Coins and keep publishing across all your social channels.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isWatchingAd
                          ? null
                          : () async {
                              setState(() => _isWatchingAd = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await monetization.watchAdForCoins(rewardAmount: 2);
                              if (mounted) {
                                setState(() => _isWatchingAd = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res.message),
                                    backgroundColor: res.success ? const Color(0xFF059669) : AppColors.error,
                                  ),
                                );
                              }
                            },
                      icon: _isWatchingAd
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_circle_filled_rounded, size: 18),
                      label: Text(
                        _isWatchingAd ? 'Loading Video Ad...' : 'Watch Ad to Earn +2 Coins',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Active Free & Ad-Supported Plan Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.all_inclusive_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free & Ad-Supported',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '10 daily free posts • Unlimited with Coins',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Daily Quota Metric Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Daily Free Post Quota',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Includes 10 daily scheduled posts. Extra posts consume 1 Coin each.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  _buildQuotaMetric(
                    label: 'Scheduled Posts Today',
                    current: ceiling.scheduledPostsToday,
                    max: DailyRewardCeiling.maxFreeScheduledPostsPerDay,
                    unit: 'posts',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuotaMetric({
    required String label,
    required int current,
    required int max,
    required String unit,
    required Color color,
  }) {
    final progress = (current / max).clamp(0.0, 1.0);
    final isFull = current >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
            Text(
              '$current / $max $unit',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFull ? AppColors.error : AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(isFull ? AppColors.error : color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
