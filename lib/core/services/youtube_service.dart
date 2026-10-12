import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no5ocial/core/services/google_auth_service.dart';

/// Real YouTube Channel Metadata retrieved from the official YouTube Data API v3
class YouTubeChannelInfo {
  final String id;
  final String title;
  final String handle;
  final String? avatarUrl;
  final int? subscriberCount;
  final int? videoCount;

  const YouTubeChannelInfo({
    required this.id,
    required this.title,
    required this.handle,
    this.avatarUrl,
    this.subscriberCount,
    this.videoCount,
  });
}

/// Official YouTube Data API v3 Integration Service
class YouTubeService {
  static final YouTubeService instance = YouTubeService._internal();
  YouTubeService._internal();

  static const String youtubeReadOnlyScope =
      'https://www.googleapis.com/auth/youtube.readonly';

  /// Fetches the authenticated user's YouTube channel via the official YouTube Data API v3.
  Future<YouTubeChannelInfo> fetchMyChannel({String? accessToken}) async {
    String? token = accessToken;
    if (token == null || token.isEmpty) {
      token = await GoogleAuthService.instance.getOrRequestAccessToken(
        additionalScopes: [youtubeReadOnlyScope],
      );
    }

    if (token == null || token.isEmpty) {
      throw Exception(
        'Google OAuth token unavailable. Please sign in with Google to link YouTube.',
      );
    }

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Google OAuth session expired. Please re-authenticate your Google session.',
      );
    }

    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        final msg = body['error']?['message'] ?? 'Access forbidden.';
        throw Exception('YouTube API permission denied: $msg');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('YouTube API permission denied (403).');
      }
    }

    if (response.statusCode != 200) {
      throw Exception('YouTube API request failed (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final items = data['items'] as List<dynamic>?;

    if (items == null || items.isEmpty) {
      throw Exception(
        'No active YouTube channel was found under this Google account. Please create a channel at youtube.com/create_channel or configure as Manual Publishing destination.',
      );
    }

    final channelItem = items.first as Map<String, dynamic>;
    final channelId = channelItem['id'] as String;
    final snippet = channelItem['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = channelItem['statistics'] as Map<String, dynamic>? ?? {};

    final title = snippet['title'] as String? ?? 'YouTube Channel';
    final customUrl = snippet['customUrl'] as String?;
    final handle = (customUrl != null && customUrl.isNotEmpty)
        ? (customUrl.startsWith('@') ? customUrl : '@$customUrl')
        : '@${title.replaceAll(RegExp(r'\s+'), '').toLowerCase()}';

    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final avatarUrl = thumbnails['medium']?['url'] ??
        thumbnails['default']?['url'] ??
        thumbnails['high']?['url'];

    final subscriberCount =
        int.tryParse(statistics['subscriberCount']?.toString() ?? '');
    final videoCount = int.tryParse(statistics['videoCount']?.toString() ?? '');

    return YouTubeChannelInfo(
      id: channelId,
      title: title,
      handle: handle,
      avatarUrl: avatarUrl as String?,
      subscriberCount: subscriberCount,
      videoCount: videoCount,
    );
  }
}
