import 'dart:convert';
import 'package:http/http.dart' as http;

/// Real LinkedIn Member Profile Metadata retrieved from the official LinkedIn API (OpenID Connect / v2)
class LinkedInProfileInfo {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;
  final String? email;

  const LinkedInProfileInfo({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.email,
  });
}

/// Official LinkedIn OAuth 2.0 & API Integration Service
class LinkedInService {
  static final LinkedInService instance = LinkedInService._internal();
  LinkedInService._internal();

  static const String authorizationEndpoint =
      'https://www.linkedin.com/oauth/v2/authorization';
  static const String tokenEndpoint =
      'https://www.linkedin.com/oauth/v2/accessToken';
  static const String userinfoEndpoint =
      'https://api.linkedin.com/v2/userinfo';

  /// Standard LinkedIn OAuth 2.0 Scopes for OpenID Connect + Member Posting
  static const List<String> defaultScopes = [
    'openid',
    'profile',
    'email',
    'w_member_social',
  ];

  /// Builds the official authorization redirect URL for LinkedIn OAuth 2.0
  String buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String state,
    List<String> scopes = defaultScopes,
  }) {
    final scopeParam = Uri.encodeComponent(scopes.join(' '));
    final encodedRedirect = Uri.encodeComponent(redirectUri);
    final encodedState = Uri.encodeComponent(state);
    return '$authorizationEndpoint?response_type=code&client_id=$clientId&redirect_uri=$encodedRedirect&state=$encodedState&scope=$scopeParam';
  }

  /// Exchanges an OAuth authorization code for an access token
  Future<String> exchangeAuthorizationCode({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code.trim(),
        'client_id': clientId.trim(),
        'client_secret': clientSecret.trim(),
        'redirect_uri': redirectUri.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to exchange authorization code (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('LinkedIn did not return an access token.');
    }
    return token;
  }

  /// Fetches authenticated member profile from LinkedIn OpenID Connect endpoint:
  /// GET https://api.linkedin.com/v2/userinfo
  Future<LinkedInProfileInfo> fetchMemberProfile({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse(userinfoEndpoint),
      headers: {
        'Authorization': 'Bearer ${accessToken.trim()}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception(
        'LinkedIn access token is invalid or expired. Re-authentication required.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'LinkedIn API permission denied (403). Ensure "openid" and "profile" products are enabled in LinkedIn Developer Portal.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'LinkedIn API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final sub = data['sub'] as String? ?? 'urn:li:person:unknown';
    final name = data['name'] as String? ??
        '${data['given_name'] ?? ''} ${data['family_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : 'LinkedIn Member';

    final givenName = data['given_name'] as String? ?? '';
    final familyName = data['family_name'] as String? ?? '';
    String handle = '';
    if (givenName.isNotEmpty || familyName.isNotEmpty) {
      handle = '@${givenName.toLowerCase()}${familyName.toLowerCase()}'.replaceAll(RegExp(r'\s+'), '');
    } else {
      handle = '@in_${sub.substring(0, sub.length.clamp(0, 8))}';
    }

    final picture = data['picture'] as String?;
    final email = data['email'] as String?;

    return LinkedInProfileInfo(
      id: sub,
      name: displayName,
      handle: handle,
      avatarUrl: picture,
      email: email,
    );
  }
}
