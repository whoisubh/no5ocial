import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Central service for retrieving Google Play and application package metadata.
class PackageInfoService {
  PackageInfoService._();
  static final PackageInfoService instance = PackageInfoService._();

  PackageInfo? _info;
  bool _initialized = false;

  /// Initializes package metadata asynchronously.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _info = await PackageInfo.fromPlatform();
      _initialized = true;
    } catch (e) {
      debugPrint('PackageInfoService: Warning initializing package info: $e');
    }
  }

  /// The application name (e.g. 'no5ocial').
  String get appName => _info?.appName ?? 'no5ocial';

  /// The application package/bundle identifier (e.g. 'io.shaadow.no5ocial').
  String get packageName => _info?.packageName ?? 'io.shaadow.no5ocial';

  /// The display version string (e.g. '1.0.0').
  String get version => _info?.version ?? '1.0.0';

  /// The internal build number (e.g. '1').
  String get buildNumber => _info?.buildNumber ?? '1';

  /// Formatted version with build number (e.g. 'v1.0.0+1').
  String get formattedVersion => 'v$version+$buildNumber';
}
