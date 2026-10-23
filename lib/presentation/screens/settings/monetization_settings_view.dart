import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/applovin_max_mediation_service.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/monetization/upgrade_paywall_sheet.dart';

/// Settings Section for Workspace Plan, Audience Segmentation, and RTB Mediation Diagnostics.
class MonetizationSettingsView extends StatelessWidget {
  final AppState appState;

  const MonetizationSettingsView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;
        final maxService = AppLovinMaxMediationService.instance;
        final plan = monetization.currentPlan;
        final ceiling = monetization.dailyCeiling;
        final isMultiPerson = monetization.isMultiPersonCompany(
          workspaceMode: appState.workspaceMode,
          memberCount: appState.teamMembers.length,
        );
        final adsVisible = monetization.shouldShowAds(
          workspaceMode: appState.workspaceMode,
          memberCount: appState.teamMembers.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workspace Mode & Segmentation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
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
                          isMultiPerson ? Icons.business_center_rounded : Icons.person_rounded,
                          color: isMultiPerson ? const Color(0xFF7C3AED) : AppColors.accent,
                          size: 22,
                        ),
                      );

                      final info = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMultiPerson ? 'B2B Corporate Organization' : 'Solo Creator / D2C Account',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                          ),
                          Text(
                            'Current Plan: ${plan.displayName}',
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
                                : SystemBottleneckType.dayPassExpired,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Change Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            const SizedBox(height: 10),
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
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Strict Audience Segmentation Status
                  Row(
                    children: [
                      Icon(
                        adsVisible ? Icons.visibility_outlined : Icons.visibility_off_rounded,
                        size: 16,
                        color: adsVisible ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          adsVisible
                              ? 'Ad Engine: Active (Solo D2C Free with Day Pass & Offerwall)'
                              : 'Ad Engine: Completely Hidden (Corporate Credibility Enforced)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: adsVisible ? const Color(0xFFD97706) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Free Tier Safeguards & Bot Ceilings (Only for Free accounts)
            if (!plan.isPaid) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Free-Tier Infrastructure Ceilings',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hardcoded limits protect backend server workers and social API quotas from automated botting.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    _buildCeilingMetric(
                      label: 'Daily Scheduled Posts Limit',
                      current: ceiling.scheduledPostsToday,
                      max: DailyRewardCeiling.maxFreeScheduledPostsPerDay,
                      unit: 'posts',
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _buildCeilingMetric(
                      label: 'Day Pass Unlocks Today',
                      current: ceiling.dayPassesUnlockedToday,
                      max: DailyRewardCeiling.maxDayPassesPerDay,
                      unit: 'pass',
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 10),
                    _buildCeilingMetric(
                      label: 'Offerwall Credits Today',
                      current: ceiling.offerwallCreditsEarnedToday,
                      max: DailyRewardCeiling.maxOfferwallCreditsPerDay,
                      unit: 'pts',
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AppLovin MAX RTB Demand Diagnostics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AppLovin MAX Mediation RTB Demand',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                            ),
                            Text(
                              'Real-Time Bidding aggregator for maximum eCPMs',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                          'CONNECTED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bidding Adapters Status
                  _buildDemandPartnerTile(
                    name: 'Google AdMob Bidding',
                    badge: 'RTB Demand',
                    ecpm: '\$22.40 eCPM',
                    status: 'Operational',
                    icon: Icons.g_mobiledata_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildDemandPartnerTile(
                    name: 'Meta Audience Network',
                    badge: 'RTB Demand',
                    ecpm: '\$24.10 eCPM',
                    status: 'Operational',
                    icon: Icons.campaign_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildDemandPartnerTile(
                    name: 'Unity Ads Exchange',
                    badge: 'RTB Demand',
                    ecpm: '\$19.80 eCPM',
                    status: 'Operational',
                    icon: Icons.videogame_asset_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildDemandPartnerTile(
                    name: 'Tapjoy Offerwall',
                    badge: 'Micro-Tasks',
                    ecpm: '\$32.50 eCPM',
                    status: 'Operational',
                    icon: Icons.assignment_turned_in_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildDemandPartnerTile(
                    name: 'ironSource Offerwall',
                    badge: 'Micro-Tasks',
                    ecpm: '\$26.00 eCPM',
                    status: 'Operational',
                    icon: Icons.rocket_launch_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Last Winning Bid Network:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${maxService.lastWinningNetwork} (\$${maxService.lastWinningEcpm.toStringAsFixed(2)})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // AdMob Rewarded Ad Interactive Player
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AdMob Rewarded Video Ad',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                            ),
                            Text(
                              maxService.isAdLoaded ? 'Ready to play (Ad Cached)' : 'Loading ad from AdMob...',
                              style: TextStyle(
                                fontSize: 12,
                                color: maxService.isAdLoaded ? const Color(0xFF059669) : AppColors.textSecondary,
                                fontWeight: maxService.isAdLoaded ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Launching AdMob Rewarded Video...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final completed = await maxService.showRewardedVideo();
                      if (completed) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Reward verified! Video playback completed successfully.'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.movie_creation_outlined, size: 18),
                    label: const Text('Watch Video Ad Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCeilingMetric({
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
        const SizedBox(height: 4),
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

  Widget _buildDemandPartnerTile({
    required String name,
    required String badge,
    required String ecpm,
    required String status,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ecpm,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }
}
