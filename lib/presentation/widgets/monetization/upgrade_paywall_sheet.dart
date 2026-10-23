import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/core/services/currency_service.dart';

/// Clean, high-converting Paywall & Upgrade Sheet displayed at all system bottlenecks.
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

  static Future<void> show(
    BuildContext context, {
    required SystemBottleneckType bottleneck,
    VoidCallback? onDayPassUnlockRequested,
    VoidCallback? onOfferwallRequested,
    String? currencyCode,
  }) {
    return AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Text(bottleneck.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  AccountPlanTier _selectedPlan = AccountPlanTier.soloPro;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationService.instance;
    final isTeamBottleneck = widget.bottleneck == SystemBottleneckType.teamSeatExpansion;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bottleneck Explanation Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isTeamBottleneck ? Icons.group_work_rounded : Icons.info_outline_rounded,
                  color: isTeamBottleneck ? const Color(0xFF7C3AED) : AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.bottleneck.description,
                    style: const TextStyle(
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
          const SizedBox(height: 18),

          // Plan Comparison Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choose your operational plan:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${CurrencyService.getByCode(widget.currencyCode ?? CurrencyService.instance.activeCurrencyCode).flag} ${CurrencyService.getByCode(widget.currencyCode ?? CurrencyService.instance.activeCurrencyCode).code}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Solo Pro Card
          _buildPlanTierCard(
            tier: AccountPlanTier.soloPro,
            name: 'Solo Pro',
            price: CurrencyService.getSubscriptionPrice(
              AccountPlanTier.soloPro,
              currencyCode: widget.currencyCode,
            ),
            period: '/month',
            badge: 'MOST POPULAR',
            features: [
              'Zero ads & zero video loops',
              'Unlimited scheduled posts & queues',
              'Multi-platform batch publishing',
              'Priority backend API throughput',
            ],
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),

          // B2B Team Card
          _buildPlanTierCard(
            tier: AccountPlanTier.b2bTeam,
            name: 'B2B Team Workspace',
            price: CurrencyService.getSubscriptionPrice(
              AccountPlanTier.b2bTeam,
              currencyCode: widget.currencyCode,
            ),
            period: '/month',
            badge: isTeamBottleneck ? 'RECOMMENDED FOR TEAMS' : 'BUSINESS',
            features: [
              'Strictly zero ad placements (Corporate Polish)',
              'Multi-seat collaboration (up to 10 seats)',
              'Post approval & review workflows',
              'Custom corporate brand workspaces',
            ],
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 10),

          // Enterprise Card
          _buildPlanTierCard(
            tier: AccountPlanTier.b2bEnterprise,
            name: 'Enterprise Organization',
            price: CurrencyService.getSubscriptionPrice(
              AccountPlanTier.b2bEnterprise,
              currencyCode: widget.currencyCode,
            ),
            period: '/month',
            badge: 'CUSTOM SLA',
            features: [
              'Dedicated queue workers & webhooks',
              'Passkey / SSO organization enforcement',
              'Unlimited workspace seats & brands',
              'Direct engineering SLA support',
            ],
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(height: 20),

          // Upgrade CTA Button
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isProcessing = true);
                    await monetization.upgradePlan(_selectedPlan);
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Successfully upgraded to ${_selectedPlan.displayName}!'),
                        backgroundColor: AppColors.accent,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    'Upgrade to ${_selectedPlan.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),

          // Free Alternative Options (Only for Solo Free users when Day Pass is the bottleneck)
          if (!isTeamBottleneck && widget.bottleneck == SystemBottleneckType.dayPassExpired) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR CONTINUE ON FREE TIER', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),

            // Unlock Day Pass Video Sequence Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDayPassUnlockRequested?.call();
              },
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20, color: AppColors.accent),
              label: const Text(
                'Watch 3 Short Videos (Unlock 24h Day Pass)',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),

            // Complete Offerwall Micro-Task Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOfferwallRequested?.call();
              },
              icon: const Icon(Icons.stars_rounded, size: 20, color: Color(0xFFD97706)),
              label: const Text(
                'Complete Micro-Task on Offerwall (High Payout)',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPlanTierCard({
    required AccountPlanTier tier,
    required String name,
    required String price,
    required String period,
    required String badge,
    required List<String> features,
    required Color color,
  }) {
    final isSelected = _selectedPlan == tier;

    return InkWell(
      onTap: () => setState(() => _selectedPlan = tier),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(price, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                          Text(period, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
