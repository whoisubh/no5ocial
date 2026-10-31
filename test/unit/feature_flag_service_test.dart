import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/feature_flag_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FeatureFlagService.instance.init(userId: 'test_user_alpha');
  });

  tearDown(() async {
    await FeatureFlagService.instance.clearManualOverrides();
  });

  group('FeatureFlagService Unit Tests', () {
    test('Default feature flags return baseline values', () {
      final isVideoSchedulingEnabled =
          FeatureFlagService.instance.isEnabled(FeatureFlags.enableVideoScheduling);
      expect(isVideoSchedulingEnabled, isTrue);

      final isDirectXEnabled =
          FeatureFlagService.instance.isEnabled(FeatureFlags.enableDirectXPublish);
      expect(isDirectXEnabled, isTrue);

      final nonExistentFlag =
          FeatureFlagService.instance.isEnabled('non_existent_flag', defaultFallback: false);
      expect(nonExistentFlag, isFalse);
    });

    test('Manual flag overrides take precedence over defaults', () async {
      await FeatureFlagService.instance.setManualOverride(
        FeatureFlags.enableVideoScheduling,
        false,
      );

      final isVideoSchedulingEnabled =
          FeatureFlagService.instance.isEnabled(FeatureFlags.enableVideoScheduling);
      expect(isVideoSchedulingEnabled, isFalse);
    });

    test('Deterministic A/B test variant assignment produces consistent results for the same user', () {
      final variantFirstCall =
          FeatureFlagService.instance.getVariant(Experiments.monetizationPaywall);
      final variantSecondCall =
          FeatureFlagService.instance.getVariant(Experiments.monetizationPaywall);

      expect(variantFirstCall, equals(variantSecondCall));
      expect(
        ['standard_tiers', 'credits_emphasis', 'annual_discount_highlight'].contains(variantFirstCall),
        isTrue,
      );
    });

    test('Manual variant override forces exact variant', () async {
      await FeatureFlagService.instance.setManualOverride(
        Experiments.monetizationPaywall,
        'annual_discount_highlight',
      );

      final variant =
          FeatureFlagService.instance.getVariant(Experiments.monetizationPaywall);
      expect(variant, equals('annual_discount_highlight'));
    });

    test('Context switch to different user computes deterministic variant for new user', () {
      FeatureFlagService.instance.setUserId('user_charlie_123');
      final variantCharlie =
          FeatureFlagService.instance.getVariant(Experiments.onboardingFlow);

      FeatureFlagService.instance.setUserId('user_delta_999');
      final variantDelta =
          FeatureFlagService.instance.getVariant(Experiments.onboardingFlow);

      expect(['quick_connect', 'interactive_tour'].contains(variantCharlie), isTrue);
      expect(['quick_connect', 'interactive_tour'].contains(variantDelta), isTrue);
    });
  });
}
