import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/data/database/app_database.dart';

/// Represents a unified Country & Regional Profile that binds together
/// country identification, flag, primary language, and national currency.
class CountryProfile {
  final String code; // ISO-3166-1 alpha-2, e.g. 'IN', 'US', 'GB', 'DE'
  final String name; // e.g. 'India', 'United States'
  final String flag; // e.g. '🇮🇳', '🇺🇸'
  final String defaultLanguageCode; // e.g. 'en', 'hi', 'de', 'ja'
  final String languageName; // e.g. 'English', 'Deutsch', '日本語'
  final String currencyCode; // e.g. 'INR', 'USD', 'EUR'
  final String currencySymbol; // e.g. '₹', '$', '€'
  final String currencyName; // e.g. 'Indian Rupee', 'US Dollar'

  const CountryProfile({
    required this.code,
    required this.name,
    required this.flag,
    required this.defaultLanguageCode,
    required this.languageName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
  });

  String get summary => '$flag $name • $languageName • $currencyCode ($currencySymbol)';
}

/// Central service that manages the active Country & Regional Profile.
/// Changes to the country automatically propagate to both App Language (Locale)
/// and Pricing/Display Currency, storing all selections in SQLite & Cloud Firestore.
class CountryService {
  static final CountryService instance = CountryService._internal();

  CountryService._internal();

  static const String _prefsKey = 'user_selected_country_code';
  static const String _dbKey = 'user_country_code';

  CountryProfile? _cachedCountry;

  CountryProfile get activeCountry => _cachedCountry ?? getByCode('IN');

  /// Curated catalog of global countries and their regional mappings
  static const List<CountryProfile> supportedCountries = [
    CountryProfile(
      code: 'IN',
      name: 'India',
      flag: '🇮🇳',
      defaultLanguageCode: 'en',
      languageName: 'English (India)',
      currencyCode: 'INR',
      currencySymbol: '₹',
      currencyName: 'Indian Rupee',
    ),
    CountryProfile(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      defaultLanguageCode: 'en',
      languageName: 'English (US)',
      currencyCode: 'USD',
      currencySymbol: '\$',
      currencyName: 'US Dollar',
    ),
    CountryProfile(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      defaultLanguageCode: 'en',
      languageName: 'English (UK)',
      currencyCode: 'GBP',
      currencySymbol: '£',
      currencyName: 'British Pound',
    ),
    CountryProfile(
      code: 'CA',
      name: 'Canada',
      flag: '🇨🇦',
      defaultLanguageCode: 'en',
      languageName: 'English / Français',
      currencyCode: 'CAD',
      currencySymbol: 'C\$',
      currencyName: 'Canadian Dollar',
    ),
    CountryProfile(
      code: 'AU',
      name: 'Australia',
      flag: '🇦🇺',
      defaultLanguageCode: 'en',
      languageName: 'English (AU)',
      currencyCode: 'AUD',
      currencySymbol: 'A\$',
      currencyName: 'Australian Dollar',
    ),
    CountryProfile(
      code: 'DE',
      name: 'Germany (Deutschland)',
      flag: '🇩🇪',
      defaultLanguageCode: 'de',
      languageName: 'Deutsch',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'FR',
      name: 'France',
      flag: '🇫🇷',
      defaultLanguageCode: 'fr',
      languageName: 'Français',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'ES',
      name: 'Spain (España)',
      flag: '🇪🇸',
      defaultLanguageCode: 'es',
      languageName: 'Español',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'IT',
      name: 'Italy (Italia)',
      flag: '🇮🇹',
      defaultLanguageCode: 'it',
      languageName: 'Italiano',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'NL',
      name: 'Netherlands (Nederland)',
      flag: '🇳🇱',
      defaultLanguageCode: 'nl',
      languageName: 'Nederlands',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'JP',
      name: 'Japan (日本)',
      flag: '🇯🇵',
      defaultLanguageCode: 'ja',
      languageName: '日本語',
      currencyCode: 'JPY',
      currencySymbol: '¥',
      currencyName: 'Japanese Yen',
    ),
    CountryProfile(
      code: 'KR',
      name: 'South Korea (대한민국)',
      flag: '🇰🇷',
      defaultLanguageCode: 'ko',
      languageName: '한국어',
      currencyCode: 'KRW',
      currencySymbol: '₩',
      currencyName: 'South Korean Won',
    ),
    CountryProfile(
      code: 'BR',
      name: 'Brazil (Brasil)',
      flag: '🇧🇷',
      defaultLanguageCode: 'pt',
      languageName: 'Português',
      currencyCode: 'BRL',
      currencySymbol: 'R\$',
      currencyName: 'Brazilian Real',
    ),
    CountryProfile(
      code: 'PT',
      name: 'Portugal',
      flag: '🇵🇹',
      defaultLanguageCode: 'pt',
      languageName: 'Português',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'AE',
      name: 'United Arab Emirates (الإمارات)',
      flag: '🇦🇪',
      defaultLanguageCode: 'ar',
      languageName: 'العربية',
      currencyCode: 'AED',
      currencySymbol: 'د.إ',
      currencyName: 'UAE Dirham',
    ),
    CountryProfile(
      code: 'SA',
      name: 'Saudi Arabia (المملكة العربية السعودية)',
      flag: '🇸🇦',
      defaultLanguageCode: 'ar',
      languageName: 'العربية',
      currencyCode: 'SAR',
      currencySymbol: '﷼',
      currencyName: 'Saudi Riyal',
    ),
    CountryProfile(
      code: 'SG',
      name: 'Singapore',
      flag: '🇸🇬',
      defaultLanguageCode: 'en',
      languageName: 'English',
      currencyCode: 'SGD',
      currencySymbol: 'S\$',
      currencyName: 'Singapore Dollar',
    ),
    CountryProfile(
      code: 'CH',
      name: 'Switzerland (Schweiz)',
      flag: '🇨🇭',
      defaultLanguageCode: 'de',
      languageName: 'Deutsch / Français',
      currencyCode: 'CHF',
      currencySymbol: 'CHF',
      currencyName: 'Swiss Franc',
    ),
    CountryProfile(
      code: 'TR',
      name: 'Turkey (Türkiye)',
      flag: '🇹🇷',
      defaultLanguageCode: 'tr',
      languageName: 'Türkçe',
      currencyCode: 'TRY',
      currencySymbol: '₺',
      currencyName: 'Turkish Lira',
    ),
    CountryProfile(
      code: 'PL',
      name: 'Poland (Polska)',
      flag: '🇵🇱',
      defaultLanguageCode: 'pl',
      languageName: 'Polski',
      currencyCode: 'PLN',
      currencySymbol: 'zł',
      currencyName: 'Polish Złoty',
    ),
    CountryProfile(
      code: 'ID',
      name: 'Indonesia',
      flag: '🇮🇩',
      defaultLanguageCode: 'id',
      languageName: 'Bahasa Indonesia',
      currencyCode: 'IDR',
      currencySymbol: 'Rp',
      currencyName: 'Indonesian Rupiah',
    ),
    CountryProfile(
      code: 'SE',
      name: 'Sweden (Sverige)',
      flag: '🇸🇪',
      defaultLanguageCode: 'sv',
      languageName: 'Svenska',
      currencyCode: 'SEK',
      currencySymbol: 'kr',
      currencyName: 'Swedish Krona',
    ),
    CountryProfile(
      code: 'DK',
      name: 'Denmark (Danmark)',
      flag: '🇩🇰',
      defaultLanguageCode: 'da',
      languageName: 'Dansk',
      currencyCode: 'DKK',
      currencySymbol: 'kr',
      currencyName: 'Danish Krone',
    ),
    CountryProfile(
      code: 'UA',
      name: 'Ukraine (Україна)',
      flag: '🇺🇦',
      defaultLanguageCode: 'uk',
      languageName: 'Українська',
      currencyCode: 'UAH',
      currencySymbol: '₴',
      currencyName: 'Ukrainian Hryvnia',
    ),
    CountryProfile(
      code: 'MY',
      name: 'Malaysia',
      flag: '🇲🇾',
      defaultLanguageCode: 'ms',
      languageName: 'Bahasa Melayu',
      currencyCode: 'MYR',
      currencySymbol: 'RM',
      currencyName: 'Malaysian Ringgit',
    ),
    CountryProfile(
      code: 'MX',
      name: 'Mexico (México)',
      flag: '🇲🇽',
      defaultLanguageCode: 'es',
      languageName: 'Español',
      currencyCode: 'MXN',
      currencySymbol: '\$',
      currencyName: 'Mexican Peso',
    ),
    CountryProfile(
      code: 'ZA',
      name: 'South Africa',
      flag: '🇿🇦',
      defaultLanguageCode: 'en',
      languageName: 'English',
      currencyCode: 'ZAR',
      currencySymbol: 'R',
      currencyName: 'South African Rand',
    ),
    CountryProfile(
      code: 'NZ',
      name: 'New Zealand',
      flag: '🇳🇿',
      defaultLanguageCode: 'en',
      languageName: 'English',
      currencyCode: 'NZD',
      currencySymbol: 'NZ\$',
      currencyName: 'New Zealand Dollar',
    ),
    CountryProfile(
      code: 'CN',
      name: 'China (中国)',
      flag: '🇨🇳',
      defaultLanguageCode: 'zh',
      languageName: '中文',
      currencyCode: 'CNY',
      currencySymbol: '¥',
      currencyName: 'Chinese Yuan',
    ),
    CountryProfile(
      code: 'RU',
      name: 'Russia (Россия)',
      flag: '🇷🇺',
      defaultLanguageCode: 'ru',
      languageName: 'Русский',
      currencyCode: 'RUB',
      currencySymbol: '₽',
      currencyName: 'Russian Ruble',
    ),
    CountryProfile(
      code: 'IE',
      name: 'Ireland',
      flag: '🇮🇪',
      defaultLanguageCode: 'en',
      languageName: 'English',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'BE',
      name: 'Belgium (Belgique / België)',
      flag: '🇧🇪',
      defaultLanguageCode: 'fr',
      languageName: 'Français / Nederlands',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'AT',
      name: 'Austria (Österreich)',
      flag: '🇦🇹',
      defaultLanguageCode: 'de',
      languageName: 'Deutsch',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'FI',
      name: 'Finland (Suomi)',
      flag: '🇫🇮',
      defaultLanguageCode: 'en',
      languageName: 'English / Suomi',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
    CountryProfile(
      code: 'GR',
      name: 'Greece (Ελλάδα)',
      flag: '🇬🇷',
      defaultLanguageCode: 'en',
      languageName: 'English / Ελληνικά',
      currencyCode: 'EUR',
      currencySymbol: '€',
      currencyName: 'Euro',
    ),
  ];

  /// Find country profile by ISO code (case-insensitive)
  static CountryProfile getByCode(String code) {
    final upper = code.trim().toUpperCase();
    return supportedCountries.firstWhere(
      (c) => c.code == upper,
      orElse: () => supportedCountries.firstWhere(
        (c) => c.code == 'IN',
        orElse: () => supportedCountries.first,
      ),
    );
  }

  /// Load saved country from SQLite Database or auto-detect from IP/device locale
  Future<CountryProfile> getOrDetectCountry() async {
    // 1. Check local SQLite database first (authoritative persistent storage)
    try {
      final savedDbCode = await AppDatabase.instance.getSetting(_dbKey);
      if (savedDbCode != null && savedDbCode.trim().isNotEmpty) {
        _cachedCountry = getByCode(savedDbCode);
        return _cachedCountry!;
      }
    } catch (e) {
      debugPrint('CountryService: SQLite read error: $e');
    }

    // 2. Check SharedPreferences backup
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrefs = prefs.getString(_prefsKey);
      if (savedPrefs != null && savedPrefs.isNotEmpty) {
        _cachedCountry = getByCode(savedPrefs);
        // Ensure saved into SQLite DB as well
        await saveCountryToDb(_cachedCountry!.code);
        return _cachedCountry!;
      }
    } catch (_) {}

    // 3. Auto-detect from IP location
    final detected = await detectCountryFromIp();
    await saveCountryToDb(detected.code);
    _cachedCountry = detected;
    return detected;
  }

  /// Automatically detect user's country code via IP geolocation
  Future<CountryProfile> detectCountryFromIp() async {
    // 1. Try ipapi.co
    try {
      final res = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'User-Agent': 'no5ocial-client/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final code = data['country_code'] as String?;
        if (code != null && code.isNotEmpty) {
          debugPrint('CountryService: IP geolocation detected: $code (${data['country_name']})');
          return getByCode(code);
        }
      }
    } catch (e) {
      debugPrint('CountryService: ipapi.co failed: $e');
    }

    // 2. Try ipwho.is fallback
    try {
      final res = await http.get(
        Uri.parse('https://ipwho.is/'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final code = data['country_code'] as String?;
          if (code != null && code.isNotEmpty) {
            debugPrint('CountryService: ipwho.is detected: $code');
            return getByCode(code);
          }
        }
      }
    } catch (e) {
      debugPrint('CountryService: ipwho.is failed: $e');
    }

    // 3. Fallback to device system locale
    try {
      final deviceCountry = PlatformDispatcher.instance.locale.countryCode;
      if (deviceCountry != null && deviceCountry.isNotEmpty) {
        return getByCode(deviceCountry);
      }
    } catch (_) {}

    // 4. Default to India (IN)
    return getByCode('IN');
  }

  /// Persists country code to local SQLite DB & SharedPreferences
  Future<void> saveCountryToDb(String countryCode) async {
    final country = getByCode(countryCode);
    _cachedCountry = country;

    try {
      // 1. Store in SQLite app_settings table
      await AppDatabase.instance.setSetting(_dbKey, country.code);
      await AppDatabase.instance.setSetting('user_currency', country.currencyCode);
      await AppDatabase.instance.setSetting('user_currency_symbol', country.currencySymbol);
      await AppDatabase.instance.setSetting('app_locale', country.defaultLanguageCode);

      // 2. Store in SharedPreferences for legacy sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, country.code);
      await prefs.setString('user_preferred_currency', country.currencyCode);
    } catch (e) {
      debugPrint('CountryService: Error saving country to DB: $e');
    }
  }
}
