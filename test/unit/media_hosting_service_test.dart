import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/core/services/media_hosting_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MediaHostingService Load Balancer & Misuse Protection Tests', () {
    test('Default strategy is r2Primary (Cloudflare R2)', () async {
      final strategy = await MediaHostingService.instance.getStrategy();
      expect(strategy, MediaHostingStrategy.r2Primary);
    });

    test('Can switch strategy to Cloudinary or ImgBB', () async {
      await MediaHostingService.instance.setStrategy(MediaHostingStrategy.cloudinary);
      expect(await MediaHostingService.instance.getStrategy(), MediaHostingStrategy.cloudinary);

      await MediaHostingService.instance.setStrategy(MediaHostingStrategy.imgbb);
      expect(await MediaHostingService.instance.getStrategy(), MediaHostingStrategy.imgbb);
    });

    test('Validates unsupported image formats and throws ArgumentError', () {
      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'malicious_script.exe',
          isVideo: false,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'document.pdf',
          isVideo: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validates allowed image formats without error', () {
      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'photo.jpg',
          sizeBytes: 5 * 1024 * 1024,
          isVideo: false,
        ),
        returnsNormally,
      );

      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'banner.png',
          sizeBytes: 8 * 1024 * 1024,
          isVideo: false,
        ),
        returnsNormally,
      );
    });

    test('Enforces maximum image size limit (15MB)', () {
      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'massive_photo.png',
          sizeBytes: 16 * 1024 * 1024, // 16MB
          isVideo: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Enforces maximum video size limit (100MB)', () {
      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'massive_video.mp4',
          sizeBytes: 105 * 1024 * 1024, // 105MB
          isVideo: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validates allowed video formats without error', () {
      expect(
        () => MediaHostingService.instance.validateMedia(
          fileName: 'reel.mp4',
          sizeBytes: 25 * 1024 * 1024,
          isVideo: true,
        ),
        returnsNormally,
      );
    });
  });
}
