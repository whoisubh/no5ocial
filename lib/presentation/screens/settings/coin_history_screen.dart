import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/utils/number_formatter.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Dedicated commercial Coin History screen.
/// Displays user coin activity divided by Month & Year, with sub-labeled dates,
/// running balances, and commercial product categorization.
class CoinHistoryScreen extends StatefulWidget {
  final AppState appState;

  const CoinHistoryScreen({super.key, required this.appState});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  final DateFormat _fullDateFormat = DateFormat('MMM d, y • h:mm a');

  @override
  void initState() {
    super.initState();
    final uid = widget.appState.localUserId;
    if (uid != null) {
      MonetizationService.instance.loadUserWallet(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationService.instance;
    final isDark = widget.appState.isDarkMode;
    final locale = widget.appState.currentLocale.languageCode;

    return ListenableBuilder(
      listenable: monetization,
      builder: (context, _) {
        final transactions = monetization.coinTransactions;

        // Group transactions by "Month Year" (e.g. "October 2026")
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final tx in transactions) {
          final date = _parseDate(tx['created_at_utc'] ?? tx['created_at']);
          final key = _monthYearFormat.format(date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F1523) : AppColors.background,
          appBar: AppBar(
            title: Text(
              'Coin History',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF0F1523) : AppColors.surface,
            foregroundColor: isDark ? Colors.white : AppColors.ink,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : AppColors.ink,
            ),
            elevation: 0,
          ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.appState.localUserId != null) {
            await monetization.loadUserWallet(widget.appState.localUserId!);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // 1. Balance Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
                ),
                boxShadow: isDark ? [] : AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${transactions.length} Total Events',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('🪙 ', style: TextStyle(fontSize: 26)),
                      Text(
                        NumberFormatter.formatInt(monetization.postCoins, locale: locale),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF92400E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '10 Coins = 2-Day Publishing Pass (2 posts across all connected channels)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Transaction Activity Grouped by Month & Year
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 48,
                        color: isDark ? Colors.white30 : AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Coin Activity Yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Watch video ads or activate publishing passes to see your history.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...grouped.entries.map((entry) {
                final monthYear = entry.key;
                final monthTxs = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month & Year Group Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 15,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            monthYear.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${monthTxs.length} ${monthTxs.length == 1 ? "entry" : "entries"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Month Container
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : AppColors.border,
                        ),
                        boxShadow: isDark ? [] : AppColors.cardShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: monthTxs.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark ? const Color(0xFF334155) : AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final tx = monthTxs[index];
                          final amount = tx['amount'] as int? ?? 0;
                          final isPositive = amount > 0;
                          final type = tx['type'] as String? ?? '';
                          final rawDate = _parseDate(tx['created_at_utc'] ?? tx['created_at']);
                          final dateStr = _fullDateFormat.format(rawDate.toLocal());
                          final balanceAfter = tx['balance_after'] as int?;

                          final title = _getCommercialTitle(type, tx['description'] as String?, isPositive);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Commercial Icon Indicator
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                        : (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCommercialIcon(type, isPositive),
                                    size: 16,
                                    color: isPositive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title and Sub-labeled Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (balanceAfter != null) ...[
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white38 : AppColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              'Balance: $balanceAfter Coins',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Trailing Coin Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                        : (isDark ? const Color(0xFF334155) : AppColors.surfaceSecondary),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPositive ? '+$amount' : '$amount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isPositive
                                          ? const Color(0xFF059669)
                                          : (amount == 0 ? AppColors.textSecondary : const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
          ],
        ),
      ),
    );
      },
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  String _getCommercialTitle(String type, String? rawDesc, bool isPositive) {
    if (rawDesc != null && rawDesc.trim().isNotEmpty) {
      return rawDesc.trim();
    }
    if (type == 'welcome_grant') return 'Welcome Bonus Coins (15 Coins)';
    if (type == 'company_registered') return 'First Company Registration Bonus (5 Coins)';
    if (type == 'channel_connected') return 'First Channel Connection Bonus (5 Coins)';
    if (type == 'first_post') return 'First Post Published Bonus (5 Coins)';
    if (type == 'rewarded_ad') return 'Video Ad Reward';
    if (type == 'pass_activation') return '2-Day Publishing Pass (2 Posts)';
    if (type == 'post_published') return 'Post Published';
    return isPositive ? 'Coins Earned' : 'Coins Used';
  }

  IconData _getCommercialIcon(String type, bool isPositive) {
    if (type == 'welcome_grant') return Icons.card_giftcard_rounded;
    if (type == 'company_registered') return Icons.business_center_rounded;
    if (type == 'channel_connected') return Icons.link_rounded;
    if (type == 'first_post') return Icons.rocket_launch_rounded;
    if (type == 'rewarded_ad') return Icons.play_circle_filled_rounded;
    if (type == 'pass_activation') return Icons.confirmation_number_rounded;
    if (type == 'post_published') return Icons.send_rounded;
    return isPositive ? Icons.add_rounded : Icons.remove_rounded;
  }
}
