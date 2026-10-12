import 'dart:convert';
import 'package:http/http.dart' as http;

/// Real Instagram Account Profile Metadata retrieved via Meta / Instagram Graph API
class InstagramProfileInfo {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;

  const InstagramProfileInfo({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });
}

/// Official Meta / Instagram Graph API Integration Service
class InstagramService {
  static final InstagramService instance = InstagramService._internal();
  InstagramService._internal();

  static const String basicDisplayEndpoint = 'https://graph.instagram.com/me';
  static const String graphApiEndpoint = 'https://graph.facebook.com/v19.0';

  /// Fetches authenticated Instagram profile from Instagram / Meta Graph API
  Future<InstagramProfileInfo> fetchProfile({
    required String accessToken,
  }) async {
    final cleanToken = accessToken.trim();

    // 1. Try Instagram Basic Display / Professional User API
    final url = Uri.parse(
      '$basicDisplayEndpoint?fields=id,username,account_type&access_token=$cleanToken',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['id'] as String? ?? 'unknown';
      final username = data['username'] as String? ?? 'instagram_user';
      final formattedHandle = username.startsWith('@') ? username : '@$username';

      return InstagramProfileInfo(
        id: id,
        name: username,
        handle: formattedHandle,
      );
    }

    // 2. Try Meta Graph API (Facebook Pages linked to Instagram Professional accounts)
    final fbUrl = Uri.parse(
      '$graphApiEndpoint/me?fields=id,name,accounts{name,instagram_business_account{id,username,name,profile_picture_url}}&access_token=$cleanToken',
    );

    final fbResponse = await http.get(fbUrl);
    if (fbResponse.statusCode == 200) {
      final data = jsonDecode(fbResponse.body) as Map<String, dynamic>;
      final accounts = data['accounts']?['data'] as List<dynamic>?;
      if (accounts != null && accounts.isNotEmpty) {
        for (final page in accounts) {
          final ig = page['instagram_business_account'] as Map<String, dynamic>?;
          if (ig != null) {
            final id = ig['id'] as String? ?? page['id'] as String;
            final username = ig['username'] as String? ?? page['name'] as String;
            final name = ig['name'] as String? ?? page['name'] as String? ?? username;
            final avatar = ig['profile_picture_url'] as String?;
            final formattedHandle = username.startsWith('@') ? username : '@$username';

            return InstagramProfileInfo(
              id: id,
              name: name,
              handle: formattedHandle,
              avatarUrl: avatar,
            );
          }
        }
      }

      // If page exists without IG business link, fallback to Page profile
      final id = data['id'] as String? ?? 'unknown';
      final name = data['name'] as String? ?? 'Meta Page';
      return InstagramProfileInfo(
        id: id,
        name: name,
        handle: '@${name.replaceAll(RegExp(r'\s+'), '').toLowerCase()}',
      );
    }

    if (response.statusCode == 401 || fbResponse.statusCode == 401) {
      throw Exception(
        'Instagram / Meta access token is expired or unauthorized (401).',
      );
    }

    if (response.statusCode == 400 || fbResponse.statusCode == 400) {
      throw Exception(
        'Invalid Instagram / Meta access token or missing permissions (instagram_basic).',
      );
    }

    throw Exception(
      'Instagram API verification failed (HTTP ${response.statusCode}). Check access token.',
    );
  }
}
