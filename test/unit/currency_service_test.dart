import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/currency_service.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getByCode accurately resolves currency details and symbols', () {
      final inr = CurrencyService.getByCode('INR');
      expect(inr.code, equals('INR'));
      expect(inr.symbol, equals('₹'));
      expect(inr.name, equals('Indian Rupee'));
      expect(inr.flag, equals('🇮🇳'));

      final usd = CurrencyService.getByCode('USD');
      expect(usd.code, equals('USD'));
      expect(usd.symbol, equals('\$'));
      expect(usd.name, equals('US Dollar'));

      final eur = CurrencyService.getByCode('EUR');
      expect(eur.code, equals('EUR'));
      expect(eur.symbol, equals('€'));

      final gbp = CurrencyService.getByCode('GBP');
      expect(gbp.code, equals('GBP'));
      expect(gbp.symbol, equals('£'));
    });

    test('getByCode falls back to USD for unknown currency codes', () {
      final fallback = CurrencyService.getByCode('XYZ_UNKNOWN');
      expect(fallback.code, equals('USD'));
      expect(fallback.symbol, equals('\$'));
    });

    test('saveCurrency and getOrDetectCurrency persist and restore user preference', () async {
      final service = CurrencyService.instance;

      // Save INR
      await service.saveCurrency('INR');

      // Retrieve
      final saved = await service.getOrDetectCurrency();
      expect(saved.code, equals('INR'));
      expect(saved.symbol, equals('₹'));
    });

    test('detectCurrencyFromIp returns a valid supported currency', () async {
      final service = CurrencyService.instance;
      final detected = await service.detectCurrencyFromIp();

      expect(detected.code.isNotEmpty, isTrue);
      expect(detected.symbol.isNotEmpty, isTrue);
      expect(detected.name.isNotEmpty, isTrue);
    });

    test('getSubscriptionPrice formats pricing correctly as per currency', () {
      // USD Pricing
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloPro, currencyCode: 'USD'), equals('\$19'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bTeam, currencyCode: 'USD'), equals('\$49'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bEnterprise, currencyCode: 'USD'), equals('\$149'));

      // INR Pricing (Indian Rupee)
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloPro, currencyCode: 'INR'), equals('₹999'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bTeam, currencyCode: 'INR'), equals('₹3,499'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bEnterprise, currencyCode: 'INR'), equals('₹9,999'));

      // EUR Pricing (Euro)
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloPro, currencyCode: 'EUR'), equals('€18'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bTeam, currencyCode: 'EUR'), equals('€46'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bEnterprise, currencyCode: 'EUR'), equals('€139'));

      // GBP Pricing (British Pound)
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloPro, currencyCode: 'GBP'), equals('£15'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bTeam, currencyCode: 'GBP'), equals('£39'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bEnterprise, currencyCode: 'GBP'), equals('£119'));

      // JPY Pricing (Japanese Yen)
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloPro, currencyCode: 'JPY'), equals('¥2,900'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bTeam, currencyCode: 'JPY'), equals('¥7,500'));
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.b2bEnterprise, currencyCode: 'JPY'), equals('¥22,800'));

      // Free Tier
      expect(CurrencyService.getSubscriptionPrice(AccountPlanTier.soloFree, currencyCode: 'INR'), equals('Free'));
    });
  });
}
