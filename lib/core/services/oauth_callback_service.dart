import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'oauth_web_helper.dart';

/// Listens for OAuth callback deep links (e.g. no5ocial://auth/callback?...)
/// and web redirects (e.g. /accounts?connected=linkedin...), automatically
/// connecting authorized social accounts into local state & storage.
class OAuthCallbackService {
  static const _channel = MethodChannel('com.shaadow.no5ocial/oauth_callback');
  static final OAuthCallbackService instance = OAuthCallbackService._internal();
  OAuthCallbackService._internal();

  AppState? _appState;
  GlobalKey<NavigatorState>? _navigatorKey;

  void init({
    required AppState appState,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _appState = appState;
    _navigatorKey = navigatorKey;

    if (!kIsWeb) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onCallback') {
          final uriString = call.arguments as String?;
          if (uriString != null) {
            handleIncomingUri(uriString);
          }
        }
      });
      _checkInitialUri();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkWebOAuthCallback();
      });
    }
  }

  Future<void> _checkInitialUri() async {
    try {
      final initialUri = await _channel.invokeMethod<String>('getInitialUri');
      if (initialUri != null) {
        handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint('OAuth initial URI check error: $e');
    }
  }

  /// Checks browser query parameters or local storage for completed OAuth responses on Web.
  void checkWebOAuthCallback() {
    if (!kIsWeb) return;
    try {
      // 1. Check local storage first (for popup or background tab callbacks)
      final stored = getStoredWebChannel();
      if (stored != null && stored['channelId'] != null && stored['channelId']!.isNotEmpty) {
        debugPrint('Found stored OAuth channel from web localStorage: ${stored['channelId']}');
        handleCallbackParams(stored);
      }

      // 2. Check current browser URL query parameters
      final uri = Uri.base;
      Map<String, String> params = Map<String, String>.from(uri.queryParameters);
      if (!params.containsKey('connected') && !params.containsKey('platform') && uri.fragment.contains('?')) {
        final queryPart = uri.fragment.split('?').sublist(1).join('?');
        final fragUri = Uri(query: queryPart);
        params.addAll(fragUri.queryParameters);
      }

      final hasOAuthParams = params.containsKey('connected') ||
          (params.containsKey('platform') && params.containsKey('channelId'));

      if (hasOAuthParams) {
        debugPrint('Detected web OAuth callback in URL: $params');
        handleCallbackParams(params);
        clearWebQuery();
      }
    } catch (e) {
      debugPrint('Error checking web OAuth callback: $e');
    }
  }

  void handleIncomingUri(String uriString) {
    debugPrint('Received OAuth callback deep link: $uriString');
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'no5ocial') return;
      handleCallbackParams(uri.queryParameters);
    } catch (e) {
      debugPrint('Error handling OAuth deep link callback: $e');
    }
  }

  void handleCallbackParams(Map<String, String> params) {
    try {
      final platformStr = params['platform'] ?? params['connected'] ?? 'linkedin';
      final channelId = params['channelId'];
      final channelTitle = params['channelTitle'] ?? 'Connected Account';
      final channelHandle = params['channelHandle'] ?? '@handle';
      final brandIdParam = params['brandId'];
      final accessToken = params['accessToken'];

      if (channelId == null || channelId.isEmpty) return;

      final appState = _appState;
      if (appState == null) return;

      final PlatformType platform = PlatformType.values.firstWhere(
        (p) => p.name.toLowerCase() == platformStr.toLowerCase(),
        orElse: () => PlatformType.linkedin,
      );

      String targetBrandId = (brandIdParam != null && brandIdParam.isNotEmpty && brandIdParam != 'default')
          ? brandIdParam
          : (appState.brands.isNotEmpty ? appState.brands.first.id : '');

      if (targetBrandId.isEmpty) {
        final newBrand = appState.createBrand(
          name: 'Personal Workspace',
          description: 'Primary workspace organization',
        );
        targetBrandId = newBrand.id;
      }

      final accountTypeParam = (params['accountType'] ?? '').toUpperCase();
      final isLinkedInPage = platform == PlatformType.linkedin &&
          (accountTypeParam == 'PAGE' || channelId.startsWith('urn:li:organization:'));

      List<String> capabilities = const ['text', 'caption'];
      List<String> scopes = [];

      if (platform == PlatformType.instagram) {
        capabilities = [
          'image',
          'carousel',
          'video',
          'reels',
          'caption',
          'insights',
          'comments',
          'subtype:instagram_business',
        ];
        scopes = [
          'instagram_business_basic',
          'instagram_business_content_publish',
          'instagram_business_manage_insights',
          'instagram_business_manage_comments',
          'instagram_business_manage_messages',
        ];
      } else if (platform == PlatformType.linkedin) {
        capabilities = isLinkedInPage
            ? [
                'text',
                'image',
                'video',
                'article',
                'commentary',
                'organization_publishing',
                'analytics',
                'subtype:linkedin_page',
              ]
            : [
                'text',
                'image',
                'video',
                'article',
                'commentary',
                'subtype:linkedin_profile',
              ];
        scopes = isLinkedInPage
            ? [
                'openid',
                'profile',
                'email',
                'w_member_social',
                'w_organization_social',
                'r_organization_social',
                'r_organization_admin',
              ]
            : [
                'openid',
                'profile',
                'email',
                'w_member_social',
              ];
      } else if (platform == PlatformType.youtube) {
        capabilities = ['video', 'shorts', 'title', 'description', 'subtype:youtube_channel'];
        scopes = ['youtube.upload', 'youtube.readonly'];
      } else if (platform == PlatformType.x) {
        final isPremium = accountTypeParam == 'PREMIUM' || (params['subtype'] ?? '').contains('premium');
        capabilities = isPremium
            ? [
                'text',
                'image',
                'video',
                'character_limit_25000',
                'subtype:x_premium',
              ]
            : [
                'text',
                'image',
                'video',
                'character_limit_280',
                'subtype:x_profile',
              ];
        scopes = [
          'tweet.read',
          'tweet.write',
          'users.read',
          'offline.access',
        ];
      } else if (platform == PlatformType.threads) {
        capabilities = [
          'text',
          'image',
          'video',
          'carousel',
          'threads_publishing',
          'character_limit_500',
          'subtype:threads_profile',
        ];
        scopes = [
          'threads_basic',
          'threads_content_publish',
        ];
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        scopes.removeWhere((s) => s.startsWith('token:'));
        scopes.add('token:$accessToken');
      }

      // Check if account is already connected to avoid duplicate entries
      final existingAccountIndex = appState.accounts.indexWhere(
        (a) => a.externalAccountId == channelId && a.brandId == targetBrandId,
      );

      if (existingAccountIndex != -1) {
        debugPrint('Account $channelId is already linked to brand $targetBrandId — updating token and state');
        final existing = appState.accounts[existingAccountIndex];
        final updatedScopes = List<String>.from(existing.scopes.where((s) => !s.startsWith('token:')));
        if (accessToken != null && accessToken.isNotEmpty) {
          updatedScopes.add('token:$accessToken');
        }
        final updated = SocialAccount(
          id: existing.id,
          brandId: existing.brandId,
          platform: existing.platform,
          displayName: channelTitle.isNotEmpty ? channelTitle : existing.displayName,
          handle: channelHandle.isNotEmpty ? channelHandle : existing.handle,
          externalAccountId: existing.externalAccountId,
          connectionStatus: ConnectionStatus.connected,
          capabilities: capabilities.isNotEmpty ? capabilities : existing.capabilities,
          scopes: updatedScopes,
          lastVerifiedAtUtc: DateTime.now().toUtc(),
          isManualOnly: false,
        );
        appState.updateAccount(updated);
      } else {
        appState.connectAccount(
          brandId: targetBrandId,
          platform: platform,
          displayName: channelTitle,
          handle: channelHandle,
          externalAccountId: channelId,
          capabilities: capabilities,
          scopes: scopes,
        );
      }

      final context = _navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        AppSheets.showChannelLinkedSheet(
          context,
          platformName: platform.displayName,
          handle: channelHandle,
          displayName: channelTitle,
        );
      }
    } catch (e) {
      debugPrint('Error handling OAuth callback parameters: $e');
    }
  }
}
