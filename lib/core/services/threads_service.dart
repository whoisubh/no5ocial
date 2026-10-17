import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Real Threads Account Profile Metadata retrieved from official Meta Threads API v1.0
class ThreadsProfileInfo {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;

  const ThreadsProfileInfo({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });
}

/// Official Meta Threads API v1.0 Integration Service
class ThreadsService {
  static final ThreadsService instance = ThreadsService._internal();
  ThreadsService._internal();

  static const String graphApiBase = 'https://graph.threads.net/v1.0';

  /// Generates the server-side OAuth initialization URL for Threads linking
  String getOAuthStartUrl({
    required String brandId,
    String returnUrl = '/accounts',
  }) {
    final baseUrl = kIsWeb
        ? Uri.base.origin
        : 'https://no5ocial.vercel.app';
    return '$baseUrl/api/auth/threads/start?brandId=${Uri.encodeComponent(brandId)}&returnUrl=${Uri.encodeComponent(returnUrl)}';
  }

  /// Launches the official Threads OAuth flow in an external web browser
  Future<bool> launchOAuthConnection({
    required String brandId,
    String returnUrl = '/accounts',
  }) async {
    final urlString = getOAuthStartUrl(
      brandId: brandId,
      returnUrl: returnUrl,
    );
    final uri = Uri.parse(urlString);
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Fetches authenticated user info from Meta Threads API v1.0:
  /// GET https://graph.threads.net/v1.0/me?fields=id,username,name,threads_profile_picture_url
  Future<ThreadsProfileInfo> fetchProfile({
    required String accessToken,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$graphApiBase/me?fields=id,username,name,threads_profile_picture_url&access_token=$accessToken');

    final response = await httpClient.get(url);

    if (response.statusCode == 401) {
      throw Exception('Threads access token is expired or unauthorized (401).');
    }
    if (response.statusCode == 403) {
      throw Exception('Threads API permission denied (403). Ensure "threads_basic" scope is authorized.');
    }
    if (response.statusCode != 200) {
      throw Exception('Threads API error (HTTP ${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final id = data['id']?.toString() ?? '';
    final username = data['username'] as String? ?? 'threads_user';
    final name = (data['name'] as String?)?.isNotEmpty == true
        ? data['name'] as String
        : username;
    final avatarUrl = data['threads_profile_picture_url'] as String?;

    return ThreadsProfileInfo(
      id: id,
      name: name,
      handle: username.startsWith('@') ? username : '@$username',
      avatarUrl: avatarUrl,
    );
  }

  /// Creates and publishes a thread on Threads API v1.0:
  /// 1. POST https://graph.threads.net/v1.0/{user_id}/threads (create media container)
  /// 2. POST https://graph.threads.net/v1.0/{user_id}/threads_publish (publish container)
  Future<String> postThread({
    required String accessToken,
    required String userId,
    required String text,
    String? imageUrl,
    String? videoUrl,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final targetId = userId.trim().isNotEmpty ? userId.trim() : 'me';

    // Step 1: Create media container
    final containerUri = Uri.parse('$graphApiBase/$targetId/threads');
    final Map<String, String> containerParams = {
      'access_token': accessToken,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      containerParams['media_type'] = 'IMAGE';
      containerParams['image_url'] = imageUrl;
      if (text.trim().isNotEmpty) {
        containerParams['text'] = text;
      }
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      containerParams['media_type'] = 'VIDEO';
      containerParams['video_url'] = videoUrl;
      if (text.trim().isNotEmpty) {
        containerParams['text'] = text;
      }
    } else {
      containerParams['media_type'] = 'TEXT';
      containerParams['text'] = text;
    }

    final containerRes = await httpClient.post(
      containerUri,
      body: containerParams,
    );

    if (containerRes.statusCode != 200 && containerRes.statusCode != 201) {
      throw Exception('Threads container creation failed (${containerRes.statusCode}): ${containerRes.body}');
    }

    final containerData = jsonDecode(containerRes.body) as Map<String, dynamic>;
    final creationId = containerData['id']?.toString();
    if (creationId == null || creationId.isEmpty) {
      throw Exception('Threads container creation returned no container ID: ${containerRes.body}');
    }

    // Step 2: Publish media container
    final publishUri = Uri.parse('$graphApiBase/$targetId/threads_publish');
    final publishRes = await httpClient.post(
      publishUri,
      body: {
        'creation_id': creationId,
        'access_token': accessToken,
      },
    );

    if (publishRes.statusCode != 200 && publishRes.statusCode != 201) {
      throw Exception('Threads publishing failed (${publishRes.statusCode}): ${publishRes.body}');
    }

    final publishData = jsonDecode(publishRes.body) as Map<String, dynamic>;
    final publishedId = publishData['id']?.toString() ?? creationId;

    return publishedId;
  }
}
