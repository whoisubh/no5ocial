import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/monetization/offerwall_sheet.dart';
import 'package:no5ocial/presentation/widgets/monetization/upgrade_paywall_sheet.dart';

/// Interactive Day Pass banner for the Composer & Scheduler screens.
/// Enforces audience segmentation: completely hides from multi-person companies
/// and paid subscribers to preserve corporate polish and trust.
class DayPassBanner extends StatefulWidget {
  final AppState appState;

  const DayPassBanner({
    super.key,
    required this.appState,
  });

  @override
  State<DayPassBanner> createState() => _DayPassBannerState();
}

class _DayPassBannerState extends State<DayPassBanner> {
  bool _isWatching = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;
        final members = widget.appState.teamMembers;

        // AUDIENCE SEGMENTATION GUARD:
        // Completely hide from multi-person companies and paid subscribers!
        final shouldShow = monetization.shouldShowAds(
          workspaceMode: widget.appState.workspaceMode,
          memberCount: members.length,
        );

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        final dayPass = monetization.dayPassStatus;
        final ceiling = monetization.dailyCeiling;

        if (dayPass.isActive) {
          // --- State A: Active 24-Hour Day Pass ---
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '24-Hour Day Pass Active',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard scheduling unlocked • ${dayPass.remainingTimeString} remaining',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    UpgradePaywallSheet.show(
                      context,
                      bottleneck: SystemBottleneckType.dayPassExpired,
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF065F46),
                  ),
                  child: const Text('Go Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        // --- State B: Inactive / Expired Day Pass ---
        final isCeilingReached = ceiling.hasReachedDayPassLimit;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCeilingReached ? 'Daily Day Pass Limit Reached' : 'Day Pass Required to Schedule',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCeilingReached
                              ? 'Free accounts are limited to 1 Day Pass per 24h. Upgrade to Pro for unlimited scheduling.'
                              : 'Watch 3 short videos or complete an offerwall task to unlock 24 hours of standard publishing.',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (!isCeilingReached) ...[
                // Capped Video Sequence Progress Indicator
                Row(
                  children: [
                    for (int i = 0; i < DayPassStatus.requiredVideosInSequence; i++) ...[
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i < DayPassStatus.requiredVideosInSequence - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: i < dayPass.videosWatchedInSequence
                                ? const Color(0xFFD97706)
                                : const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '${dayPass.videosWatchedInSequence}/${DayPassStatus.requiredVideosInSequence}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons Row
              Row(
                children: [
                  if (!isCeilingReached) ...[
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: _isWatching
                            ? null
                            : () async {
                                setState(() => _isWatching = true);
                                final res = await monetization.advanceDayPassVideoSequence();
                                setState(() => _isWatching = false);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? AppColors.accent : AppColors.error,
                                    ),
                                  );
                                }
                              },
                        icon: _isWatching
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.play_circle_fill_rounded, size: 16),
                        label: Text(
                          dayPass.videosWatchedInSequence == 0
                              ? 'Watch Video (1/3)'
                              : 'Watch Video (${dayPass.videosWatchedInSequence + 1}/3)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          OfferwallSheet.show(
                            context,
                            userId: widget.appState.localUserId ?? 'user_solo',
                          );
                        },
                        icon: const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFD97706)),
                        label: const Text('Offerwall', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Color(0xFFFDE68A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          UpgradePaywallSheet.show(
                            context,
                            bottleneck: SystemBottleneckType.dailyRewardCeilingReached,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Upgrade to Solo Pro (Unlimited)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
