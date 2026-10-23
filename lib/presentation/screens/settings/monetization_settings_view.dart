import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/monetization/upgrade_paywall_sheet.dart';

/// Consumer-grade Settings Section for Workspace Plan, Tier Details, and Usage Quotas.
class MonetizationSettingsView extends StatelessWidget {
  final AppState appState;

  const MonetizationSettingsView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;
        final plan = monetization.currentPlan;
        final ceiling = monetization.dailyCeiling;
        final isMultiPerson = monetization.isMultiPersonCompany(
          workspaceMode: appState.workspaceMode,
          memberCount: appState.teamMembers.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workspace Plan Card
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

            // Plan Usage Quotas (Free accounts) or Plan Perks (Paid accounts)
            if (!plan.isPaid) ...[
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
                          'Daily Publishing Quota',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Free plan includes up to 10 scheduled posts per calendar day. Upgrade to Solo Pro for unlimited scheduling.',
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
                      'Your plan includes unlimited multi-destination post scheduling, concurrent queues, and priority API delivery.',
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
