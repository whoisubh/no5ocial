import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/utils/number_formatter.dart';
import 'package:no5ocial/presentation/screens/settings/coin_history_screen.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Publishing Coins (Credits) Wallet Card
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
                              '10 Coins = 2 Posts in 2 Days',
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
                              '${NumberFormatter.formatInt(monetization.postCoins, locale: widget.appState.currentLocale.languageCode)} Coins',
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
                    'Watch short partner video ads to earn Coins. 10 Coins unlocks a 2-Day Pass (2 posts), which you can activate directly inside Create Post.',
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
                              final res = await monetization.watchAdForCoins(
                                rewardAmount: 2,
                                userId: widget.appState.localUserId,
                              );
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

            // 2. Dedicated Coin History Navigation Card
            _buildCoinHistoryCard(context, monetization.coinTransactions.length),
          ],
        );
      },
    );
  }

  Widget _buildCoinHistoryCard(BuildContext context, int count) {
    final isDark = widget.appState.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
        boxShadow: isDark ? [] : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CoinHistoryScreen(appState: widget.appState),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF78350F).withAlpha(80)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coin History',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'No coin activity recorded yet'
                            : '$count transaction${count == 1 ? '' : 's'} recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : AppColors.border,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
