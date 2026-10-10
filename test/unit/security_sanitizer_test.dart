import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/core/utils/string_sanitizer.dart';

void main() {
  group('StringSanitizer Security Tests (SECURITY.md & AGENTS.md)', () {
    test('Redacts OAuth Bearer tokens completely', () {
      const rawHeader = 'Bearer ya29.a0AfH6SMD_secret_token_1234567890';
      final sanitized = StringSanitizer.redact(rawHeader);

      expect(sanitized, isNot(contains('ya29.a0AfH6SMD_secret_token_1234567890')));
      expect(sanitized, contains('[REDACTED_TOKEN]'));
    });

    test('Redacts sensitive URL parameters and client secrets', () {
      const rawUrl = 'https://api.provider.com/v1/publish?access_token=EAABwz_secret_999&client_secret=super_secret_key';
      final sanitized = StringSanitizer.redact(rawUrl);

      expect(sanitized, isNot(contains('EAABwz_secret_999')));
      expect(sanitized, isNot(contains('super_secret_key')));
      expect(sanitized, contains('access_token=[REDACTED]'));
      expect(sanitized, contains('client_secret=[REDACTED]'));
    });

    test('Redacts JSON authorization headers in exception payloads', () {
      const rawJson = '{"authorization": "Bearer secret_xyz_987", "status": 401}';
      final sanitized = StringSanitizer.redact(rawJson);

      expect(sanitized, isNot(contains('secret_xyz_987')));
      expect(sanitized, contains('[REDACTED_AUTH]'));
    });

    test('Leaves non-sensitive content untouched', () {
      const plain = 'Normal post caption with #tech and https://shaadow.io';
      expect(StringSanitizer.redact(plain), equals(plain));
    });
  });
}
