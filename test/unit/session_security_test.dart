import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/passkey_credential.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PasskeyCredential', () {
    test('JSON serialization and deserialization roundtrip', () {
      final now = DateTime.now().toUtc();
      final credential = PasskeyCredential(
        id: 'test_cred_id_12345',
        name: 'Work Laptop Windows Hello',
        createdAtUtc: now,
        lastUsedAtUtc: now,
        transports: ['internal', 'hybrid'],
        clientDataJson: '{"type":"webauthn.create"}',
        attestationObject: 'base64_attestation',
      );

      final json = credential.toJson();
      final restored = PasskeyCredential.fromJson(json);

      expect(restored.id, equals('test_cred_id_12345'));
      expect(restored.name, equals('Work Laptop Windows Hello'));
      expect(restored.transports, equals(['internal', 'hybrid']));
      expect(restored.clientDataJson, equals('{"type":"webauthn.create"}'));
      expect(restored.attestationObject, equals('base64_attestation'));
    });

    test('listToJson and listFromJson handle empty and populated lists', () {
      expect(PasskeyCredential.listFromJson(''), isEmpty);
      expect(PasskeyCredential.listFromJson('[]'), isEmpty);

      final creds = [
        PasskeyCredential(
          id: 'cred_1',
          name: 'Fingerprint 1',
          createdAtUtc: DateTime.now().toUtc(),
        ),
        PasskeyCredential(
          id: 'cred_2',
          name: 'YubiKey 5',
          createdAtUtc: DateTime.now().toUtc(),
        ),
      ];

      final encoded = PasskeyCredential.listToJson(creds);
      final decoded = PasskeyCredential.listFromJson(encoded);

      expect(decoded.length, equals(2));
      expect(decoded[0].id, equals('cred_1'));
      expect(decoded[1].id, equals('cred_2'));
    });
  });

  group('SessionService - Email Masking', () {
    test('masks emails accurately with zero dummy fallback', () {
      final service = SessionService.instance;

      expect(service.getMaskedEmail('surya@gmail.com'), equals('su***a@gmail.com'));
      expect(service.getMaskedEmail('alexander@domain.com'), equals('al***r@domain.com'));
      expect(service.getMaskedEmail('ab@test.io'), equals('a***@test.io'));
      expect(service.getMaskedEmail('john@company.org'), equals('j***n@company.org'));
      expect(service.getMaskedEmail(null), equals('your email address'));
      expect(service.getMaskedEmail(''), equals('your email address'));
      expect(service.getMaskedEmail('invalid-email'), equals('your email address'));
    });
  });

  group('SessionService - Session Expiry Logic', () {
    test('fresh session is not expired', () async {
      final service = SessionService.instance;

      await service.saveSession(
        id: 'user_123',
        name: 'Surya Test',
        email: 'surya@example.com',
      );

      final isExpired = await service.isSessionExpired();
      expect(isExpired, isFalse);

      final session = await service.getSession();
      expect(session, isNotNull);
      expect(session!['email'], equals('surya@example.com'));
    });

    test('clearing session removes all stored credentials', () async {
      final service = SessionService.instance;

      await service.saveSession(
        id: 'user_123',
        name: 'Surya Test',
        email: 'surya@example.com',
      );

      await service.clearSession();
      final session = await service.getSession();
      expect(session, isNull);
    });

    test('expired session triggers isSessionExpired', () async {
      final service = SessionService.instance;
      final prefs = await service.prefs;

      // Seed an old session timestamp from 20 days ago (exceeding both 7 and 14 days)
      final twentyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 20));
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setString('auth_user_id', 'user_123');
      await prefs.setString('auth_user_email', 'surya@example.com');
      await prefs.setString('auth_session_created_at_utc', twentyDaysAgo.toIso8601String());

      final isExpired = await service.isSessionExpired();
      expect(isExpired, isTrue);
    });
  });

  group('SessionService - Biometric & Lock Settings', () {
    test('stores and retrieves biometric lock preferences', () async {
      final service = SessionService.instance;

      expect(await service.isBiometricLockEnabled(), isFalse);
      expect(await service.getLockTimeoutSeconds(), equals(0));

      await service.setBiometricLockEnabled(true);
      expect(await service.isBiometricLockEnabled(), isTrue);

      await service.setLockTimeoutSeconds(120);
      expect(await service.getLockTimeoutSeconds(), equals(120));

      await service.setLockTimeoutSeconds(0);
      expect(await service.getLockTimeoutSeconds(), equals(0));
    });

    test('manages registered passkeys CRUD operations', () async {
      final service = SessionService.instance;

      final initial = await service.getRegisteredPasskeys();
      expect(initial, isEmpty);

      final passkey = PasskeyCredential(
        id: 'cred_abc_123',
        name: 'Google Pixel 8 Fingerprint',
        createdAtUtc: DateTime.now().toUtc(),
      );

      await service.savePasskeyCredential(passkey);
      var list = await service.getRegisteredPasskeys();
      expect(list.length, equals(1));
      expect(list.first.name, equals('Google Pixel 8 Fingerprint'));

      await service.updatePasskeyLastUsed('cred_abc_123');
      list = await service.getRegisteredPasskeys();
      expect(list.first.lastUsedAtUtc, isNotNull);

      await service.deletePasskeyCredential('cred_abc_123');
      list = await service.getRegisteredPasskeys();
      expect(list, isEmpty);
    });
  });

  group('SessionService - Onboarding & Brand Cache Persistence', () {
    test('persists and retrieves onboarding completion state', () async {
      final service = SessionService.instance;

      expect(await service.hasCompletedOnboarding(), isFalse);

      await service.setCompletedOnboarding(true);
      expect(await service.hasCompletedOnboarding(), isTrue);

      await service.setCompletedOnboarding(false);
      expect(await service.hasCompletedOnboarding(), isFalse);
    });

    test('serializes and restores brands cache across restarts', () async {
      final service = SessionService.instance;

      expect(await service.getBrandsCache(), isEmpty);

      final now = DateTime.now().toUtc();
      final brand1 = Brand(
        id: 'brand_surya_123',
        name: 'Surya Workspace',
        slug: 'surya-workspace',
        description: 'Primary test brand',
        websiteUrl: 'https://shaadow.io',
        createdAtUtc: now,
      );
      final brand2 = Brand(
        id: 'brand_works_456',
        name: 'Shaadow Works',
        slug: 'shaadow-works',
        createdAtUtc: now,
      );

      await service.saveBrandsCache([brand1, brand2]);
      final restored = await service.getBrandsCache();

      expect(restored.length, equals(2));
      expect(restored[0].id, equals('brand_surya_123'));
      expect(restored[0].name, equals('Surya Workspace'));
      expect(restored[0].websiteUrl, equals('https://shaadow.io'));
      expect(restored[1].id, equals('brand_works_456'));
      expect(restored[1].name, equals('Shaadow Works'));
    });
  });
}
