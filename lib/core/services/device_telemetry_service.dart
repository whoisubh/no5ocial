import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

/// Service for collecting client device hardware, environment, network/IP, and advertising telemetry.
/// Strictly used for anti-abuse and single-claim verification for free trial resources and coin allocations.
class DeviceTelemetryService {
  static final DeviceTelemetryService instance = DeviceTelemetryService._internal();
  DeviceTelemetryService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Map<String, dynamic>? _cachedTelemetry;

  /// Gathers comprehensive device hardware, OS, network, and client environment telemetry
  Future<Map<String, dynamic>> getTelemetry() async {
    if (_cachedTelemetry != null) return _cachedTelemetry!;

    final data = <String, dynamic>{
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'is_web': kIsWeb,
      'collected_at_utc': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        data['device_id'] = 'web_${webInfo.userAgent.hashCode.abs()}';
        data['browser_name'] = webInfo.browserName.name;
        data['user_agent'] = webInfo.userAgent;
        data['language'] = webInfo.language;
        data['hardware_concurrency'] = webInfo.hardwareConcurrency;
        data['device_memory'] = webInfo.deviceMemory;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        data['device_id'] = 'and_${androidInfo.id}_${androidInfo.fingerprint.hashCode.abs()}';
        data['model'] = androidInfo.model;
        data['brand'] = androidInfo.brand;
        data['manufacturer'] = androidInfo.manufacturer;
        data['hardware'] = androidInfo.hardware;
        data['is_physical_device'] = androidInfo.isPhysicalDevice;
        data['os_version'] = androidInfo.version.release;
        data['sdk_int'] = androidInfo.version.sdkInt;
        data['fingerprint'] = androidInfo.fingerprint;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        data['device_id'] = 'ios_${iosInfo.identifierForVendor ?? iosInfo.utsname.machine}';
        data['model'] = iosInfo.model;
        data['name'] = iosInfo.name;
        data['system_name'] = iosInfo.systemName;
        data['system_version'] = iosInfo.systemVersion;
        data['is_physical_device'] = iosInfo.isPhysicalDevice;
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        data['device_id'] = 'win_${winInfo.deviceId}';
        data['computer_name'] = winInfo.computerName;
        data['os_version'] = '${winInfo.majorVersion}.${winInfo.minorVersion}.${winInfo.buildNumber}';
        data['core_count'] = winInfo.numberOfCores;
        data['memory_size_mb'] = winInfo.systemMemoryInMegabytes;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        data['device_id'] = 'mac_${macInfo.systemGUID ?? macInfo.computerName}';
        data['model'] = macInfo.model;
        data['os_version'] = macInfo.osRelease;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        data['device_id'] = 'lin_${linuxInfo.machineId ?? linuxInfo.name}';
        data['name'] = linuxInfo.name;
        data['version'] = linuxInfo.version;
      }
    } catch (e) {
      debugPrint('DeviceTelemetryService: hardware info collection error: $e');
      data['device_id'] = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Public IP & network info lookup
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        data['public_ip'] = json['ip'];
      }
    } catch (e) {
      debugPrint('DeviceTelemetryService: public IP lookup skipped: $e');
    }

    // Advertising & tracking environment markers
    data['ad_framework_ready'] = true;
    data['ad_partner'] = 'applovin_max_admob';

    _cachedTelemetry = data;
    return data;
  }

  /// Returns a unique hardware-based device signature
  Future<String> getDeviceSignature() async {
    final telemetry = await getTelemetry();
    return telemetry['device_id']?.toString() ?? 'unknown_device';
  }
}
