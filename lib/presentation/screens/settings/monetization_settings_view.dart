import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/monetization/upgrade_paywall_sheet.dart';

/// Consumer-grade Settings Section for Workspace Plan, Tier Details, Quotas,
/// and the Publishing Coin (Credit) System for Free Users.
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
        final plan = monetization.currentPlan;
        final ceiling = monetization.dailyCeiling;
        final isMultiPerson = monetization.isMultiPersonCompany(
          workspaceMode: widget.appState.workspaceMode,
          memberCount: widget.appState.teamMembers.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Workspace Plan Card
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 460;
                      final iconBox = Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMultiPerson
                              ? const Color(0xFF7C3AED).withAlpha(20)
                              : AppColors.accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isMultiPerson ? Icons.business_center_rounded : Icons.workspace_premium_rounded,
                          color: isMultiPerson ? const Color(0xFF7C3AED) : AppColors.accent,
                          size: 22,
                        ),
                      );

                      final info = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: plan.isPaid ? const Color(0xFFECFDF5) : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: plan.isPaid ? const Color(0xFFA7F3D0) : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  plan.isPaid ? 'ACTIVE' : 'FREE TIER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: plan.isPaid ? const Color(0xFF059669) : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMultiPerson ? 'Team Workspace Account' : 'Personal Creator Account',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      );

                      final btn = ElevatedButton(
                        onPressed: () {
                          UpgradePaywallSheet.show(
                            context,
                            bottleneck: isMultiPerson
                                ? SystemBottleneckType.teamSeatExpansion
                                : SystemBottleneckType.dailyPostCeilingReached,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          plan.isPaid ? 'Manage Plan' : 'Upgrade Plan',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                iconBox,
                                const SizedBox(width: 12),
                                Expanded(child: info),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: btn),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          iconBox,
                          const SizedBox(width: 12),
                          Expanded(child: info),
                          btn,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Free Tier: Publishing Coins (Credits) Card & Daily Quota
            if (!plan.isPaid) ...[
              // Coins (Credit) Wallet Card
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
                                '1 Coin = 1 Scheduled or Published Post',
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
                      'Reached your daily free post limit? Watch a short partner video ad to earn Coins and keep publishing across all your social channels without upgrading.',
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

              // Daily Quota Metric Card
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
                      'Free plan includes 10 daily scheduled posts. Extra posts consume 1 Coin each.',
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
            ] else ...[
              // Paid Plan Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Unlimited Workspace Capacity',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your plan includes unlimited multi-destination post scheduling, concurrent queues, and priority API delivery with zero coins or quotas required.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
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
