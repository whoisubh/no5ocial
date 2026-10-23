import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for extracting and caching video thumbnail preview bytes.
class VideoThumbnailService {
  static final Map<String, Uint8List> _memoryCache = {};
  static const MethodChannel _channel = MethodChannel('com.shaadow.no5ocial/oauth_callback');

  /// Fetches or extracts thumbnail bytes for a video file path or URL.
  static Future<Uint8List?> getThumbnail(String path) async {
    if (path.isEmpty) return null;
    if (_memoryCache.containsKey(path)) {
      return _memoryCache[path];
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final result = await _channel.invokeMethod<Uint8List>('getVideoThumbnail', {'path': path});
        if (result != null && result.isNotEmpty) {
          _memoryCache[path] = result;
          return result;
        }
      } catch (e) {
        debugPrint('VideoThumbnailService error: $e');
      }
    }

    return null;
  }
}
