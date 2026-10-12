import 'dart:convert';
import 'package:http/http.dart' as http;

/// Real X (Twitter) Profile Metadata retrieved via Twitter API v2
class XProfileInfo {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;

  const XProfileInfo({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });
}

/// Official X (Twitter) API v2 Integration Service
class XService {
  static final XService instance = XService._internal();
  XService._internal();

  static const String authorizationEndpoint =
      'https://twitter.com/i/oauth2/authorize';
  static const String meEndpoint =
      'https://api.twitter.com/2/users/me?user.fields=profile_image_url,username,name';

  static const List<String> defaultScopes = [
    'users.read',
    'tweet.read',
    'tweet.write',
    'offline.access',
  ];

  /// Builds the official OAuth 2.0 PKCE authorization URL for X
  String buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String state,
    required String codeChallenge,
    List<String> scopes = defaultScopes,
  }) {
    final scopeParam = Uri.encodeComponent(scopes.join(' '));
    final encodedRedirect = Uri.encodeComponent(redirectUri);
    final encodedState = Uri.encodeComponent(state);
    return '$authorizationEndpoint?response_type=code&client_id=$clientId&redirect_uri=$encodedRedirect&scope=$scopeParam&state=$encodedState&code_challenge=$codeChallenge&code_challenge_method=S256';
  }

  /// Fetches authenticated user info from Twitter API v2:
  /// GET https://api.twitter.com/2/users/me
  Future<XProfileInfo> fetchUserProfile({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse(meEndpoint),
      headers: {
        'Authorization': 'Bearer ${accessToken.trim()}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception(
        'X / Twitter access token is expired or unauthorized (401).',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'X API permission denied (403). Ensure "users.read" scope is authorized.',
      );
    }

    if (response.statusCode == 429) {
      throw Exception('X API rate limit reached (429). Please wait a moment.');
    }

    if (response.statusCode != 200) {
      throw Exception('X API error (HTTP ${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final user = data['data'] as Map<String, dynamic>?;
    if (user == null) {
      throw Exception('Unexpected response format from X API.');
    }

    final id = user['id'] as String? ?? 'unknown';
    final name = user['name'] as String? ?? 'X Account';
    final username = user['username'] as String? ?? 'user';
    final avatar = user['profile_image_url'] as String?;

    return XProfileInfo(
      id: id,
      name: name,
      handle: username.startsWith('@') ? username : '@$username',
      avatarUrl: avatar,
    );
  }
}
