import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';

/// Interactive Offerwall Sheet for Solo Creators (Tapjoy / ironSource)
/// Replaces low-yield video loops with high-payout micro-task completions.
class OfferwallSheet extends StatefulWidget {
  final String userId;

  const OfferwallSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, {required String userId}) {
    return AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 8),
          Text('Offerwall Micro-Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      builder: (ctx, _) => OfferwallSheet(userId: userId),
    );
  }

  @override
  State<OfferwallSheet> createState() => _OfferwallSheetState();
}

class _OfferwallSheetState extends State<OfferwallSheet> {
  String _selectedProvider = 'tapjoy';
  bool _isProcessingTask = false;

  final List<Map<String, dynamic>> _tapjoyTasks = [
    {
      'title': 'Developer Tooling & Cloud Feedback Survey',
      'category': 'Survey • 4 mins',
      'reward': 25,
      'ecpm': '\$28.50 eCPM',
      'badge': 'UNLOCKS DAY PASS',
    },
    {
      'title': 'Register Verified Developer Sandbox Account',
      'category': 'Sign-up • Free',
      'reward': 40,
      'ecpm': '\$42.00 eCPM',
      'badge': 'TOP PAYOUT',
    },
    {
      'title': 'Brief Consumer Media Sentiment Poll',
      'category': 'Poll • 2 mins',
      'reward': 15,
      'ecpm': '\$18.00 eCPM',
      'badge': 'QUICK',
    },
  ];

  final List<Map<String, dynamic>> _ironSourceTasks = [
    {
      'title': 'Install & Launch Mobile Code Editor',
      'category': 'Engagement • 3 mins',
      'reward': 30,
      'ecpm': '\$32.00 eCPM',
      'badge': 'UNLOCKS DAY PASS',
    },
    {
      'title': 'Evaluate SaaS Productivity Dashboard',
      'category': 'Micro-trial • Instant',
      'reward': 20,
      'ecpm': '\$22.50 eCPM',
      'badge': 'FEATURED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationService.instance;
    final ceiling = monetization.dailyCeiling;
    final currentTasks = _selectedProvider == 'tapjoy' ? _tapjoyTasks : _ironSourceTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Ceiling Info Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Ceiling: ${ceiling.offerwallCreditsEarnedToday}/${DailyRewardCeiling.maxOfferwallCreditsPerDay} credits used today.',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'Balance: ${monetization.offerwallCredits} pts',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Provider Switcher Tabs (Tapjoy vs ironSource)
        Row(
          children: [
            Expanded(
              child: _buildProviderTab(
                id: 'tapjoy',
                title: 'Tapjoy Offerwall',
                subtitle: 'High Payout Surveys',
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildProviderTab(
                id: 'ironsource',
                title: 'ironSource Tasks',
                subtitle: 'App Engagement',
                icon: Icons.rocket_launch_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        const Text(
          'Available Micro-Tasks:',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),

        // Tasks List
        ...currentTasks.map((t) => _buildTaskCard(t)),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildProviderTab({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedProvider == id;

    return InkWell(
      onTap: () => setState(() => _selectedProvider = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final reward = task['reward'] as int;
    final ecpm = task['ecpm'] as String;
    final badge = task['badge'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ecpm,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task['title'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  task['category'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isProcessingTask
                ? null
                : () async {
                    setState(() => _isProcessingTask = true);
                    final res = await MonetizationService.instance.launchOfferwallTask(
                      provider: _selectedProvider,
                      userId: widget.userId,
                    );
                    setState(() => _isProcessingTask = false);

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? AppColors.accent : AppColors.error,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 14),
                Text(
                  '$reward pts',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
