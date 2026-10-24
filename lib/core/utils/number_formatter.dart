import 'package:intl/intl.dart';

/// Utilities for standard number, currency, and metric formatting across the app.
/// Ensures locale-aware number grouping (e.g. 1,00,000 in India vs 100,000 in US/UK),
/// compact metric display (e.g. 1.2K, 3.4M), and regional currency formatting.
abstract final class NumberFormatter {
  /// Formats an integer with locale-appropriate grouping separators (e.g. "1,250" or "1.250").
  static String formatInt(int number, {String? locale}) {
    try {
      return NumberFormat.decimalPattern(locale).format(number);
    } catch (_) {
      return number.toString();
    }
  }

  /// Formats numbers into human-readable compact notation (e.g. 1.2K, 3.4M).
  static String formatCompact(num number, {String? locale}) {
    try {
      return NumberFormat.compact(locale: locale).format(number);
    } catch (_) {
      if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
      if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
      return number.toString();
    }
  }

  /// Formats currency with national symbol and regional groupings.
  static String formatCurrency(
    num amount, {
    String? symbol,
    String? currencyCode,
    String? locale,
    int decimalDigits = 0,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: symbol ?? '\$',
        name: currencyCode,
        decimalDigits: decimalDigits,
      );
      return formatter.format(amount);
    } catch (_) {
      return '${symbol ?? "\$"}$amount';
    }
  }
}
