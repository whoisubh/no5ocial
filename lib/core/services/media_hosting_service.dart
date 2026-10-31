import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/config/env_config.dart';

enum MediaHostingStrategy {
  r2Primary,   // Cloudflare R2 primary (free lifetime), fallback to Cloudinary/ImgBB
  balanced,    // Alternates between ImgBB and Cloudinary for images, Cloudinary for videos
  cloudinary,  // Cloudinary only
  imgbb,       // ImgBB for images, Cloudinary for videos
}

/// Unified media manager that supports Cloudflare R2 (10GB free lifetime, $0 egress),
/// Cloudinary, and ImgBB. Enforces file type validation, strict size limits, and rate limits.
class MediaHostingService {
  static final MediaHostingService instance = MediaHostingService._internal();
  MediaHostingService._internal();

  http.Client _client = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _client = client;

  static const String _prefStrategyKey = 'media_hosting_strategy';
  static const String _prefCloudinaryNameKey = 'cloudinary_cloud_name';
  static const String _prefCloudinaryPresetKey = 'cloudinary_upload_preset';
  static const String _prefImgbbApiKey = 'imgbb_api_key';
  static const String _prefR2DomainKey = 'r2_public_domain';
  static const String _prefCounterKey = 'media_upload_counter';

  // Defaults
  static const String defaultCloudName = 'no5ocial';
  static const String defaultUploadPreset = 'no5ocial_unsigned';
  static const String defaultR2Domain = 'https://pub-5e5439b590cb4d04a5e4f444072646d0.r2.dev';

  // Misuse Protection & Limits
  static const int maxImageSizeBytes = 15 * 1024 * 1024; // 15 MB
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  static const List<String> allowedVideoExtensions = ['mp4', 'mov', 'webm'];

  // Rate Limiting (misuse prevention)
  static final List<DateTime> _recentUploads = [];
  static const int maxUploadsPerMinute = 20;

  /// Gets the currently selected hosting strategy
  Future<MediaHostingStrategy> getStrategy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefStrategyKey);
    if (raw == 'balanced') return MediaHostingStrategy.balanced;
    if (raw == 'cloudinary') return MediaHostingStrategy.cloudinary;
    if (raw == 'imgbb') return MediaHostingStrategy.imgbb;
    return MediaHostingStrategy.r2Primary; // Default to free lifetime Cloudflare R2
  }

  /// Sets the hosting strategy
  Future<void> setStrategy(MediaHostingStrategy strategy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefStrategyKey, strategy.name);
  }

  /// Backward compatibility for settings UI
  Future<MediaHostingStrategy> getProvider() => getStrategy();
  Future<void> setProvider(MediaHostingStrategy strategy) => setStrategy(strategy);

  /// Gets Cloudflare R2 public domain
  Future<String> getR2PublicDomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefR2DomainKey) ?? defaultR2Domain;
  }

  /// Updates Cloudflare R2 public domain
  Future<void> setR2PublicDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefR2DomainKey, domain.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  /// Gets Cloudinary settings
  Future<Map<String, String>> getCloudinaryConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'cloudName': prefs.getString(_prefCloudinaryNameKey) ?? defaultCloudName,
      'uploadPreset': prefs.getString(_prefCloudinaryPresetKey) ?? defaultUploadPreset,
    };
  }

  /// Updates Cloudinary settings
  Future<void> setCloudinaryConfig({
    required String cloudName,
    required String uploadPreset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCloudinaryNameKey, cloudName.trim());
    await prefs.setString(_prefCloudinaryPresetKey, uploadPreset.trim());
  }

  /// Gets ImgBB API key
  Future<String?> getImgbbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefImgbbApiKey);
  }

  /// Updates ImgBB API key
  Future<void> setImgbbApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefImgbbApiKey, apiKey.trim());
  }

  /// Validates media attributes to avoid abuse and invalid uploads
  void validateMedia({
    required String fileName,
    int? sizeBytes,
    required bool isVideo,
  }) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (isVideo) {
      if (!allowedVideoExtensions.contains(ext)) {
        throw ArgumentError('Unsupported video format: .$ext. Allowed: ${allowedVideoExtensions.join(", ")}');
      }
    } else {
      if (!allowedImageExtensions.contains(ext)) {
        throw ArgumentError('Unsupported image format: .$ext. Allowed: ${allowedImageExtensions.join(", ")}');
      }
    }

    if (sizeBytes != null && sizeBytes > 0) {
      final maxSize = isVideo ? maxVideoSizeBytes : maxImageSizeBytes;
      final maxMb = maxSize ~/ (1024 * 1024);
      if (sizeBytes > maxSize) {
        throw ArgumentError('File size exceeds limit of ${maxMb}MB.');
      }
    }

    final now = DateTime.now();
    _recentUploads.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_recentUploads.length >= maxUploadsPerMinute) {
      throw StateError('Upload rate limit reached ($maxUploadsPerMinute/min). Please slow down.');
    }
  }

  /// Uploads media asset with Cloudflare R2 primary and Cloudinary/ImgBB failovers.
  Future<String> uploadMedia({
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
    int? sizeBytes,
    bool isVideo = false,
  }) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    final resolvedName = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
    final resolvedSize = sizeBytes ?? fileBytes?.length;

    validateMedia(
      fileName: resolvedName,
      sizeBytes: resolvedSize,
      isVideo: isVideo,
    );

    _recentUploads.add(DateTime.now());

    final strategy = await getStrategy();
    final imgbbKey = await getImgbbApiKey();
    final hasImgbb = imgbbKey != null && imgbbKey.isNotEmpty;

    final config = await getCloudinaryConfig();
    final cloudName = config['cloudName']!;
    final uploadPreset = config['uploadPreset']!;

    // 1. Try Cloudflare R2 if strategy is r2Primary
    if (strategy == MediaHostingStrategy.r2Primary) {
      try {
        final r2Url = await _uploadToR2(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: resolvedName,
          isVideo: isVideo,
        );
        return r2Url;
      } catch (r2Error) {
        debugPrint('[MediaHostingService] R2 upload failed, failing over: $r2Error');
        // Continue to fallback below
      }
    }

    // 2. Videos fall back to Cloudinary
    if (isVideo) {
      return _uploadToCloudinary(
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: resolvedName,
        isVideo: true,
      );
    }

    // 3. Image routing across Cloudinary / ImgBB
    bool useImgbb = false;
    if (hasImgbb) {
      switch (strategy) {
        case MediaHostingStrategy.imgbb:
          useImgbb = true;
          break;
        case MediaHostingStrategy.cloudinary:
          useImgbb = false;
          break;
        case MediaHostingStrategy.balanced:
        case MediaHostingStrategy.r2Primary:
          final prefs = await SharedPreferences.getInstance();
          final counter = prefs.getInt(_prefCounterKey) ?? 0;
          await prefs.setInt(_prefCounterKey, counter + 1);
          useImgbb = (counter % 2 == 0);
          break;
      }
    }

    if (useImgbb && hasImgbb) {
      try {
        return await _uploadToImgbb(
          apiKey: imgbbKey,
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: resolvedName,
        );
      } catch (_) {
        return await _uploadToCloudinary(
          cloudName: cloudName,
          uploadPreset: uploadPreset,
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: resolvedName,
          isVideo: false,
        );
      }
    } else {
      try {
        return await _uploadToCloudinary(
          cloudName: cloudName,
          uploadPreset: uploadPreset,
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: resolvedName,
          isVideo: false,
        );
      } catch (_) {
        if (hasImgbb) {
          return await _uploadToImgbb(
            apiKey: imgbbKey,
            filePath: filePath,
            fileBytes: fileBytes,
            fileName: resolvedName,
          );
        }
        rethrow;
      }
    }
  }

  /// Uploads media directly to Cloudflare R2 via presigned PUT URL
  Future<String> _uploadToR2({
    required String filePath,
    Uint8List? fileBytes,
    required String fileName,
    required bool isVideo,
  }) async {
    final baseUrl = kIsWeb ? '' : EnvConfig.webBaseUrl;
    final presignedEndpoint = Uri.parse('$baseUrl/api/media?filename=${Uri.encodeComponent(fileName)}');
    final presignedRes = await _client.get(presignedEndpoint).timeout(const Duration(seconds: 15));

    if (presignedRes.statusCode != 200) {
      throw Exception('R2 Presign service unavailable (${presignedRes.statusCode})');
    }

    final json = jsonDecode(presignedRes.body) as Map<String, dynamic>;
    final uploadUrl = json['uploadUrl'] as String?;
    final publicUrl = json['publicUrl'] as String?;

    if (uploadUrl == null || publicUrl == null) {
      throw Exception('R2 Presign response missing uploadUrl or publicUrl');
    }

    // Direct HTTP PUT to Cloudflare R2 with real bytes
    Uint8List bytesToUpload;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      bytesToUpload = fileBytes;
    } else if (!kIsWeb && filePath.isNotEmpty) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Media file not found on device at path: $filePath');
      }
      bytesToUpload = await file.readAsBytes();
    } else {
      throw Exception('No media file content available to upload to Cloudflare R2.');
    }

    final uploadRes = await _client.put(
      Uri.parse(uploadUrl),
      body: bytesToUpload,
    ).timeout(const Duration(minutes: 5));

    if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
      throw Exception('Direct R2 PUT failed (${uploadRes.statusCode}): ${uploadRes.body}');
    }

    return publicUrl;
  }

  /// Direct client-to-Cloudinary unsigned multipart upload
  Future<String> _uploadToCloudinary({
    required String cloudName,
    required String uploadPreset,
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
    bool isVideo = false,
  }) async {
    final resourceType = isVideo ? 'video' : 'image';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;

    final resolvedName = fileName ?? filePath.split(RegExp(r'[\\/]')).last;

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: resolvedName,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: resolvedName,
      ));
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errMsg = body['error']?['message'] ?? 'Cloudinary upload failed (HTTP ${response.statusCode})';
      throw Exception('Media upload error: $errMsg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload returned no secure URL.');
    }

    return secureUrl;
  }

  /// Direct client-to-ImgBB multipart upload
  Future<String> _uploadToImgbb({
    required String apiKey,
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri);
    final resolvedName = fileName ?? filePath.split(RegExp(r'[\\/]')).last;

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: resolvedName,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        filePath,
        filename: resolvedName,
      ));
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errMsg = body['error']?['message'] ?? 'ImgBB upload failed (HTTP ${response.statusCode})';
      throw Exception('ImgBB upload error: $errMsg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final imgUrl = data['data']?['url'] as String? ?? data['data']?['display_url'] as String?;
    if (imgUrl == null || imgUrl.isEmpty) {
      throw Exception('ImgBB upload returned no image URL.');
    }

    return imgUrl;
  }
}
