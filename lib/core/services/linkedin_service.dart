import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:no5ocial/core/config/env_config.dart';

/// Real LinkedIn Member Profile Metadata retrieved from official LinkedIn OpenID Connect API
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

/// Real LinkedIn Company Page Metadata retrieved from official LinkedIn Organizations API
class LinkedInOrganizationInfo {
  final String urn;
  final String id;
  final String name;
  final String handle;
  final String? logoUrl;
  final String? role;

  const LinkedInOrganizationInfo({
    required this.urn,
    required this.id,
    required this.name,
    required this.handle,
    this.logoUrl,
    this.role,
  });
}

/// Official LinkedIn OAuth 2.0 & REST API Integration Service
class LinkedInService {
  static final LinkedInService instance = LinkedInService._internal();
  LinkedInService._internal();

  static const String authorizationEndpoint =
      'https://www.linkedin.com/oauth/v2/authorization';
  static const String tokenEndpoint =
      'https://www.linkedin.com/oauth/v2/accessToken';
  static const String userinfoEndpoint =
      'https://api.linkedin.com/v2/userinfo';
  static const String organizationAclsEndpoint =
      'https://api.linkedin.com/rest/organizationAcls';
  static const String legacyOrganizationAclsEndpoint =
      'https://api.linkedin.com/v2/organizationalEntityAcls';
  static const String postsEndpoint =
      'https://api.linkedin.com/rest/posts';

  /// Standard LinkedIn OAuth 2.0 Scopes for OpenID Connect + Member Posting
  static const List<String> memberScopes = [
    'openid',
    'profile',
    'email',
    'w_member_social',
  ];

  /// Standard LinkedIn OAuth 2.0 Scopes for Company Page Posting
  static const List<String> organizationScopes = [
    'openid',
    'profile',
    'email',
    'w_member_social',
    'w_organization_social',
    'r_organization_social',
    'r_organization_admin',
    'rw_organization_admin',
  ];

  /// Generates the server-side OAuth initialization URL for LinkedIn linking
  String getOAuthStartUrl({
    required String brandId,
    String accountType = 'personal',
    String returnUrl = '/accounts',
  }) {
    final baseUrl = kIsWeb ? '' : EnvConfig.webBaseUrl;
    return '$baseUrl/api/auth/linkedin/start?brandId=${Uri.encodeComponent(brandId)}&accountType=${Uri.encodeComponent(accountType)}&returnUrl=${Uri.encodeComponent(returnUrl)}';
  }

  /// Launches the official server-side OAuth flow via Vercel backend
  Future<bool> launchOAuthConnection({
    required String brandId,
    String accountType = 'personal',
    String returnUrl = '/accounts',
  }) async {
    final startPath = getOAuthStartUrl(
      brandId: brandId,
      accountType: accountType,
      returnUrl: returnUrl,
    );
    final uri = Uri.parse(startPath);
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Builds the direct authorization redirect URL for LinkedIn OAuth 2.0
  String buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String state,
    List<String> scopes = memberScopes,
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
      id: sub.startsWith('urn:li:person:') ? sub : 'urn:li:person:$sub',
      name: displayName,
      handle: handle,
      avatarUrl: picture,
      email: email,
    );
  }

  /// Fetches organizations/company pages that the authenticated user administers
  Future<List<LinkedInOrganizationInfo>> fetchAdministeredOrganizations({
    required String accessToken,
  }) async {
    final cleanToken = accessToken.trim();
    final organizations = <LinkedInOrganizationInfo>[];

    // Try modern versioned endpoint
    http.Response res = await http.get(
      Uri.parse('$organizationAclsEndpoint?q=roleAssignee'),
      headers: {
        'Authorization': 'Bearer $cleanToken',
        'X-Restli-Protocol-Version': '2.0.0',
        'LinkedIn-Version': '202401',
        'Accept': 'application/json',
      },
    );

    // Fallback to legacy endpoint if required
    if (res.statusCode != 200) {
      res = await http.get(
        Uri.parse('$legacyOrganizationAclsEndpoint?q=roleAssignee&state=APPROVED'),
        headers: {
          'Authorization': 'Bearer $cleanToken',
          'X-Restli-Protocol-Version': '2.0.0',
          'Accept': 'application/json',
        },
      );
    }

    if (res.statusCode != 200) {
      debugPrint('Failed to query LinkedIn organizations (${res.statusCode}): ${res.body}');
      return organizations;
    }

    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? const [];

      for (final item in elements) {
        final orgUrn = item['organization'] as String? ?? item['organizationalTarget'] as String?;
        final role = item['role'] as String?;
        if (orgUrn != null) {
          final numericId = orgUrn.split(':').last;
          organizations.add(
            LinkedInOrganizationInfo(
              urn: orgUrn.startsWith('urn:li:organization:') ? orgUrn : 'urn:li:organization:$numericId',
              id: numericId,
              name: 'LinkedIn Company Page ($numericId)',
              handle: '@org_$numericId',
              role: role,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing LinkedIn organization ACLs: $e');
    }

    return organizations;
  }
}
