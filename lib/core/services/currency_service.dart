import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';

/// Model representing currency information.
class CurrencyInfo {
  final String code; // e.g. 'USD', 'INR', 'EUR'
  final String name; // e.g. 'Indian Rupee'
  final String symbol; // e.g. '₹', '$', '€'
  final String flag; // e.g. '🇮🇳', '🇺🇸'

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  String get displayLabel => '$flag $code ($symbol) - $name';
}

/// Service that automatically detects the user's default currency based on their current IP location,
/// while allowing manual selection and persistent storage.
class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();

  CurrencyService._internal();

  static const String _prefsKey = 'user_preferred_currency';
  String? _cachedCurrencyCode;

  String get activeCurrencyCode => _cachedCurrencyCode ?? 'USD';

  /// Curated global currencies catalog
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: '\$', flag: '🇲🇽'),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    CurrencyInfo(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
    CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', flag: '🇳🇿'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
  ];

  static const Map<String, String> _countryCodeToCurrency = {
    'IN': 'INR',
    'US': 'USD',
    'GB': 'GBP',
    'CA': 'CAD',
    'AU': 'AUD',
    'JP': 'JPY',
    'AE': 'AED',
    'SG': 'SGD',
    'CH': 'CHF',
    'BR': 'BRL',
    'ZA': 'ZAR',
    'MX': 'MXN',
    'KR': 'KRW',
    'SE': 'SEK',
    'NZ': 'NZD',
    'SA': 'SAR',
    'DE': 'EUR',
    'FR': 'EUR',
    'IT': 'EUR',
    'ES': 'EUR',
    'NL': 'EUR',
    'BE': 'EUR',
    'AT': 'EUR',
    'IE': 'EUR',
    'PT': 'EUR',
    'FI': 'EUR',
    'GR': 'EUR',
  };

  /// Find currency info by code
  static CurrencyInfo getByCode(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => const CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    );
  }

  /// Load saved currency or detect by IP location
  Future<CurrencyInfo> getOrDetectCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefsKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        _cachedCurrencyCode = savedCode.toUpperCase();
        return getByCode(savedCode);
      }
    } catch (_) {}

    // No saved preference -> auto-detect from IP location
    final detected = await detectCurrencyFromIp();
    await saveCurrency(detected.code);
    return detected;
  }

  /// Automatically detect currency using current IP location
  Future<CurrencyInfo> detectCurrencyFromIp() async {
    // 1. Try ipapi.co (fast JSON API with country and currency fields)
    try {
      final res = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'User-Agent': 'no5ocial-client/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final currencyCode = data['currency'] as String?;
        if (currencyCode != null && currencyCode.isNotEmpty) {
          debugPrint('CurrencyService: IP location detected currency: $currencyCode (${data['country_name']})');
          return getByCode(currencyCode);
        }

        final countryCode = data['country_code'] as String?;
        if (countryCode != null && _countryCodeToCurrency.containsKey(countryCode.toUpperCase())) {
          return getByCode(_countryCodeToCurrency[countryCode.toUpperCase()]!);
        }
      }
    } catch (e) {
      debugPrint('CurrencyService: ipapi.co query failed: $e');
    }

    // 2. Fallback to ipwho.is
    try {
      final res = await http.get(
        Uri.parse('https://ipwho.is/'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final currency = data['currency'] as Map<String, dynamic>?;
          final currencyCode = currency?['code'] as String?;
          if (currencyCode != null && currencyCode.isNotEmpty) {
            debugPrint('CurrencyService: ipwho.is detected currency: $currencyCode');
            return getByCode(currencyCode);
          }

          final countryCode = data['country_code'] as String?;
          if (countryCode != null && _countryCodeToCurrency.containsKey(countryCode.toUpperCase())) {
            return getByCode(_countryCodeToCurrency[countryCode.toUpperCase()]!);
          }
        }
      }
    } catch (e) {
      debugPrint('CurrencyService: ipwho.is query failed: $e');
    }

    // Default fallback
    return const CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸');
  }

  /// Persist user's selected currency
  Future<void> saveCurrency(String currencyCode) async {
    try {
      _cachedCurrencyCode = currencyCode.toUpperCase();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, currencyCode.toUpperCase());
    } catch (e) {
      debugPrint('CurrencyService: Error saving currency: $e');
    }
  }

  /// Formatted localized subscription pricing as per currency
  static String getSubscriptionPrice(
    AccountPlanTier tier, {
    String? currencyCode,
  }) {
    final code = (currencyCode ?? instance.activeCurrencyCode).toUpperCase();
    final info = getByCode(code);

    switch (tier) {
      case AccountPlanTier.soloFree:
        return 'Free';

      case AccountPlanTier.soloPro:
        switch (code) {
          case 'INR':
            return '₹999';
          case 'EUR':
            return '€18';
          case 'GBP':
            return '£15';
          case 'CAD':
            return 'C\$26';
          case 'AUD':
            return 'A\$29';
          case 'JPY':
            return '¥2,900';
          case 'AED':
            return 'د.إ 69';
          case 'SGD':
            return 'S\$25';
          case 'CHF':
            return 'CHF 17';
          case 'BRL':
            return 'R\$99';
          case 'ZAR':
            return 'R 349';
          case 'MXN':
            return 'MX\$349';
          case 'KRW':
            return '₩25,000';
          case 'SEK':
            return '199 kr';
          case 'NZD':
            return 'NZ\$31';
          case 'SAR':
            return '﷼ 71';
          case 'USD':
          default:
            return '${info.symbol}19';
        }

      case AccountPlanTier.b2bTeam:
        switch (code) {
          case 'INR':
            return '₹3,499';
          case 'EUR':
            return '€46';
          case 'GBP':
            return '£39';
          case 'CAD':
            return 'C\$67';
          case 'AUD':
            return 'A\$75';
          case 'JPY':
            return '¥7,500';
          case 'AED':
            return 'د.إ 179';
          case 'SGD':
            return 'S\$65';
          case 'CHF':
            return 'CHF 44';
          case 'BRL':
            return 'R\$249';
          case 'ZAR':
            return 'R 899';
          case 'MXN':
            return 'MX\$899';
          case 'KRW':
            return '₩65,000';
          case 'SEK':
            return '519 kr';
          case 'NZD':
            return 'NZ\$79';
          case 'SAR':
            return '﷼ 184';
          case 'USD':
          default:
            return '${info.symbol}49';
        }

      case AccountPlanTier.b2bEnterprise:
        switch (code) {
          case 'INR':
            return '₹9,999';
          case 'EUR':
            return '€139';
          case 'GBP':
            return '£119';
          case 'CAD':
            return 'C\$205';
          case 'AUD':
            return 'A\$229';
          case 'JPY':
            return '¥22,800';
          case 'AED':
            return 'د.إ 549';
          case 'SGD':
            return 'S\$199';
          case 'CHF':
            return 'CHF 134';
          case 'BRL':
            return 'R\$749';
          case 'ZAR':
            return 'R 2,699';
          case 'MXN':
            return 'MX\$2,699';
          case 'KRW':
            return '₩199,000';
          case 'SEK':
            return '1,599 kr';
          case 'NZD':
            return 'NZ\$239';
          case 'SAR':
            return '﷼ 559';
          case 'USD':
          default:
            return '${info.symbol}149';
        }
    }
  }
}
