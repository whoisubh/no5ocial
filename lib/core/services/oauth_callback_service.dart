import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';

/// Listens for OAuth callback deep links (e.g. no5ocial://auth/callback?...)
/// and automatically connects authorized social accounts into local state & storage.
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

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onCallback') {
        final uriString = call.arguments as String?;
        if (uriString != null) {
          handleIncomingUri(uriString);
        }
      }
    });

    _checkInitialUri();
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

  void handleIncomingUri(String uriString) {
    debugPrint('Received OAuth callback deep link: $uriString');
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'no5ocial') return;

      final platformStr = uri.queryParameters['platform'] ?? 'instagram';
      final channelId = uri.queryParameters['channelId'];
      final channelTitle = uri.queryParameters['channelTitle'] ?? 'Connected Account';
      final channelHandle = uri.queryParameters['channelHandle'] ?? '@handle';
      final brandIdParam = uri.queryParameters['brandId'];

      if (channelId == null || channelId.isEmpty) return;

      final appState = _appState;
      if (appState == null) return;

      final PlatformType platform = PlatformType.values.firstWhere(
        (p) => p.name.toLowerCase() == platformStr.toLowerCase(),
        orElse: () => PlatformType.instagram,
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

      // Check if account is already connected to avoid duplicate entries
      final alreadyConnected = appState.accounts.any(
        (a) => a.externalAccountId == channelId && a.brandId == targetBrandId,
      );
      if (alreadyConnected) {
        debugPrint('Account $channelId is already linked to brand $targetBrandId');
        final context = _navigatorKey?.currentContext;
        if (context != null && context.mounted) {
          AppSheets.showChannelLinkedSheet(
            context,
            platformName: platform.displayName,
            handle: channelHandle,
            displayName: channelTitle,
          );
        }
        return;
      }

      final accountTypeParam = (uri.queryParameters['accountType'] ?? '').toUpperCase();
      final isLinkedInPage = platform == PlatformType.linkedin &&
          (accountTypeParam == 'PAGE' || channelId.startsWith('urn:li:organization:'));

      List<String> capabilities = const ['text', 'caption'];
      List<String> scopes = const [];

      if (platform == PlatformType.instagram) {
        capabilities = const ['image', 'carousel', 'video', 'reels', 'caption', 'insights', 'comments'];
        scopes = const [
          'instagram_business_basic',
          'instagram_business_content_publish',
          'instagram_business_manage_insights',
          'instagram_business_manage_comments',
          'instagram_business_manage_messages',
        ];
      } else if (platform == PlatformType.linkedin) {
        capabilities = isLinkedInPage
            ? const ['text', 'image', 'video', 'article', 'commentary', 'analytics']
            : const ['text', 'image', 'video', 'article', 'commentary'];
        scopes = isLinkedInPage
            ? const [
                'openid',
                'profile',
                'email',
                'w_member_social',
                'w_organization_social',
                'r_organization_social',
                'r_organization_admin',
              ]
            : const [
                'openid',
                'profile',
                'email',
                'w_member_social',
              ];
      } else if (platform == PlatformType.youtube) {
        capabilities = const ['video', 'shorts', 'title', 'description'];
        scopes = const ['youtube.upload', 'youtube.readonly'];
      }

      appState.connectAccount(
        brandId: targetBrandId,
        platform: platform,
        displayName: channelTitle,
        handle: channelHandle,
        externalAccountId: channelId,
        capabilities: capabilities,
        scopes: scopes,
      );

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
      debugPrint('Error handling OAuth deep link callback: $e');
    }
  }
}
