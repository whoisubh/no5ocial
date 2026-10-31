// ignore_for_file: camel_case_types
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_theme.dart';
import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/group_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/composite_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/unsupported_platform_adapter.dart';
import 'package:no5ocial/domain/adapters/instagram_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/linkedin_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/threads_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/x_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/youtube_publishing_adapter.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/presentation/navigation/main_scaffold.dart';
import 'package:no5ocial/presentation/screens/auth/login_screen.dart';
import 'package:no5ocial/presentation/screens/invite/invite_accept_screen.dart';
import 'package:no5ocial/presentation/screens/landing/landing_screen.dart';
import 'package:no5ocial/presentation/screens/legal/disclaimer_screen.dart';
import 'package:no5ocial/presentation/screens/legal/privacy_screen.dart';
import 'package:no5ocial/presentation/screens/legal/terms_screen.dart';
import 'package:no5ocial/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:no5ocial/presentation/screens/splash/splash_screen.dart';
import 'package:no5ocial/presentation/screens/welcome/mobile_welcome_screen.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';
import 'package:no5ocial/core/services/biometric_lock_service.dart';
import 'package:no5ocial/core/services/oauth_callback_service.dart';
import 'package:no5ocial/core/services/sync_service.dart';
import 'package:no5ocial/core/utils/url_strategy_helper.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/biometric_lock_overlay.dart';
import 'package:no5ocial/presentation/widgets/session_expired_sheet.dart';
import 'package:no5ocial/core/config/firebase_config.dart';
import 'package:no5ocial/core/services/firebase_sync_service.dart';
import 'package:no5ocial/core/services/applovin_max_mediation_service.dart';
import 'package:no5ocial/core/services/monetization_service.dart';
import 'package:no5ocial/core/services/fcm_notification_service.dart';
import 'package:no5ocial/core/services/connectivity_service.dart';
import 'package:no5ocial/core/services/package_info_service.dart';
import 'package:no5ocial/core/services/crashlytics_service.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:no5ocial/core/services/firebase_analytics_service.dart';
import 'package:no5ocial/core/services/play_billing_service.dart';
import 'package:no5ocial/core/services/schedule_runner_service.dart';

void main() async {
  final resolvedFlavor = appFlavor == 'prod' ? AppFlavor.prod : AppFlavor.dev;
  await bootstrap(flavor: resolvedFlavor);
}

/// Universal application bootstrapper supporting flavors (dev, prod)
Future<void> bootstrap({AppFlavor flavor = AppFlavor.dev}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure clean HTML5 URL routing without hash (#) on web
  configureAppUrlStrategy();

  // Initialize global error handler hooks (differentiating prod and dev presentation)
  AppErrorHandler.init();

  // Initialize dynamic environment configuration from .env assets
  await EnvConfig.init(flavor: flavor);

  // Initialize Firebase Cloud services (fail-safe for offline and local-first operation)
  await FirebaseConfig.initialize();
  await FirebaseSyncService.instance.init();

  // Initialize Google Crashlytics and Analytics
  await CrashlyticsService.instance.init();
  await FirebaseAnalyticsService.instance.init();

  // Initialize Package Info & Google Play In-App Billing
  await PackageInfoService.instance.init();
  await PlayBillingService.instance.init();

  // Initialize Network Connectivity and Push Notification services
  await ConnectivityService.instance.init();
  await FcmNotificationService.instance.init();

  // Initialize SQLite Database and Repositories
  try {
    await AppDatabase.instance.database;
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  final brandRepo = SqliteBrandRepository();
  await brandRepo.init();

  final accountRepo = SqliteAccountRepository();
  await accountRepo.init();

  final postRepo = SqlitePostRepository();
  await postRepo.init();

  final jobRepo = SqliteJobRepository();
  await jobRepo.init();

  final auditRepo = SqliteAuditRepository();
  await auditRepo.init();

  final groupRepo = SqliteGroupRepository();
  await groupRepo.init();

  // Platform publishing adapters with official Instagram, LinkedIn, X & Threads REST API integration
  final publishingAdapter = CompositePublishingAdapter(
    platformAdapters: {
      PlatformType.instagram: InstagramPublishingAdapter(),
      PlatformType.linkedin: LinkedInPublishingAdapter(),
      PlatformType.x: XPublishingAdapter(),
      PlatformType.threads: ThreadsPublishingAdapter(),
      PlatformType.youtube: YouTubePublishingAdapter(),
    },
    fallbackAdapter: const UnsupportedPlatformAdapter(),
  );

  final appState = AppState(
    brandRepository: brandRepo,
    accountRepository: accountRepo,
    postRepository: postRepo,
    jobRepository: jobRepo,
    auditRepository: auditRepo,
    groupRepository: groupRepo,
    publishingAdapter: publishingAdapter,
  );
  await appState.loadSavedUserProfile();
  await appState.loadSavedThemeMode();
  await appState.loadSavedWorkspaceMode();
  await appState.initOrgMembers();
  await appState.initCountryAndLocalization();

  // Initialize OAuth deep link listener
  OAuthCallbackService.instance.init(
    appState: appState,
    navigatorKey: no5ocialApp.navigatorKey,
  );

  // Initialize Local-First Sync Engine
  await SyncService.instance.init();

  // Initialize AppLovin MAX Mediation & Audience Segmentation Monetization Engine (non-blocking)
  unawaited(AppLovinMaxMediationService.instance.initialize(userId: appState.localUserId));
  unawaited(MonetizationService.instance.init());

  // Initialize automated schedule runner worker
  ScheduleRunnerService.instance.init(appState);

  runApp(no5ocialApp(appState: appState));
}

class no5ocialApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final AppState appState;

  const no5ocialApp({super.key, required this.appState});

  @override
  State<no5ocialApp> createState() => _no5ocialAppState();
}

class _no5ocialAppState extends State<no5ocialApp> with WidgetsBindingObserver {
  bool _hasCheckedSessionOnStartup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndSecurity();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      BiometricLockService.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      BiometricLockService.instance.onAppResumed(
        isUserLoggedIn: widget.appState.isLoggedIn,
      );
    }
  }

  void _checkSessionAndSecurity() {
    if (_hasCheckedSessionOnStartup) return;
    _hasCheckedSessionOnStartup = true;

    if (widget.appState.isSessionExpired) {
      final navContext = no5ocialApp.navigatorKey.currentContext;
      if (navContext != null) {
        SessionExpiredSheet.show(
          navContext,
          maskedEmail: widget.appState.maskedEmail ?? 'your account',
          onConfirmLogout: () async {
            await widget.appState.signOut();
            no5ocialApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          },
        );
      }
    } else if (widget.appState.isLoggedIn && !kIsWeb) {
      BiometricLockService.instance.onAppResumed(
        isUserLoggedIn: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final appState = widget.appState;
        return MaterialApp(
          navigatorKey: no5ocialApp.navigatorKey,
          scaffoldMessengerKey: AppErrorHandler.scaffoldMessengerKey,
          title: 'no5ocial — Social Publishing & Scheduling Workspace',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          locale: appState.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [
            if (FirebaseAnalyticsService.instance.observer != null)
              FirebaseAnalyticsService.instance.observer!,
          ],
          builder: (context, child) {
            return BiometricLockOverlay(
              child: child ?? const SizedBox.shrink(),
            );
          },
          onGenerateRoute: (settings) {
            String routeName = settings.name ?? '/';

            // On Web initial cold start, settings.name may be '/' while the browser has a deep link path
            if (kIsWeb && routeName == '/') {
              if (Uri.base.path.isNotEmpty && Uri.base.path != '/') {
                routeName = Uri.base.path;
              } else if (Uri.base.fragment.isNotEmpty) {
                final frag = Uri.base.fragment;
                routeName = frag.startsWith('/') ? frag : '/$frag';
              }
            }

            final cleanRoute = routeName.split('?').first.replaceAll(RegExp(r'/+$'), '');
            final normalized = cleanRoute.isEmpty ? '/' : cleanRoute;

            // 0. Legal Pages (Accessible publicly anytime without authentication)
            if (normalized == '/terms' || normalized == '/legal/terms' || normalized == '/legal') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/legal/terms'),
                builder: (_) => const TermsScreen(),
              );
            }
            if (normalized == '/privacy' || normalized == '/legal/privacy') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/legal/privacy'),
                builder: (_) => const PrivacyScreen(),
              );
            }
            if (normalized == '/disclaimer' || normalized == '/legal/disclaimer') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/legal/disclaimer'),
                builder: (_) => const DisclaimerScreen(),
              );
            }

            // Invite Route (Publicly accessible with invitation token)
            if (normalized == '/invite' || normalized.startsWith('/invite/')) {
              String token = '';
              final uri = Uri.tryParse(routeName);
              if (uri != null && uri.queryParameters.containsKey('token')) {
                token = uri.queryParameters['token']!;
              } else if (kIsWeb && Uri.base.queryParameters.containsKey('token')) {
                token = Uri.base.queryParameters['token']!;
              } else if (kIsWeb && Uri.base.fragment.isNotEmpty) {
                final fragUri = Uri.tryParse(Uri.base.fragment);
                if (fragUri != null && fragUri.queryParameters.containsKey('token')) {
                  token = fragUri.queryParameters['token']!;
                }
              }
              if (token.isEmpty && uri != null && uri.pathSegments.length > 1) {
                token = uri.pathSegments[1];
              }

              return MaterialPageRoute(
                settings: RouteSettings(name: routeName),
                builder: (_) => InviteAcceptScreen(
                  appState: appState,
                  token: token,
                ),
              );
            }

            // 1. Root & Public Landing Page
            if (normalized == '/' || normalized == '/landing') {
              if (kIsWeb) {
                // If user already has an active valid session, open dashboard directly!
                if (normalized == '/' && appState.isLoggedIn && !appState.isSessionExpired) {
                  return MaterialPageRoute(
                    settings: const RouteSettings(name: '/dashboard'),
                    builder: (_) => MainScaffold(
                      appState: appState,
                      initialIndex: 0,
                    ),
                  );
                }
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/'),
                  builder: (_) => LandingScreen(appState: appState),
                );
              }
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/splash'),
                builder: (_) => SplashScreen(appState: appState),
              );
            }

            // 2. Explicit Splash Screen
            if (normalized == '/splash') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/splash'),
                builder: (_) => SplashScreen(appState: appState),
              );
            }

            // 3. Explicit Login Screen
            if (normalized == '/login') {
              if (appState.isLoggedIn && !appState.isSessionExpired) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/dashboard'),
                  builder: (_) => MainScaffold(
                    appState: appState,
                    initialIndex: 0,
                  ),
                );
              }
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (_) => LoginScreen(appState: appState),
              );
            }

            // 4. Mobile Welcome Screen
            if (normalized == '/welcome') {
              if (appState.isLoggedIn && !appState.isSessionExpired) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/dashboard'),
                  builder: (_) => MainScaffold(
                    appState: appState,
                    initialIndex: 0,
                  ),
                );
              }
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/welcome'),
                builder: (_) => MobileWelcomeScreen(appState: appState),
              );
            }

            // 5. Dashboard Endpoints (Protected by Auth Guard)
            if (normalized == '/accounts' ||
                normalized == '/channels' ||
                normalized == '/dashboard' ||
                normalized.startsWith('/dashboard/')) {
              if (!appState.isLoggedIn) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/login'),
                  builder: (_) => LoginScreen(appState: appState),
                );
              }

              if (appState.brands.isEmpty && !appState.hasCompletedOnboarding) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/onboarding'),
                  builder: (ctx) => OnboardingScreen(
                    appState: appState,
                    onComplete: () {
                      Navigator.of(ctx).pushReplacementNamed('/dashboard');
                    },
                  ),
                );
              }

              if (appState.brands.isEmpty) {
                appState.ensureDefaultBrandExists();
              }

              int tabIndex = 0;
              switch (normalized) {
                case '/dashboard':
                case '/dashboard/queue':
                  tabIndex = 0;
                  break;
                case '/dashboard/library':
                  tabIndex = 1;
                  break;
                case '/dashboard/calendar':
                  tabIndex = 2;
                  break;
                case '/accounts':
                case '/channels':
                case '/dashboard/channels':
                  tabIndex = 3;
                  break;
                case '/dashboard/settings':
                  tabIndex = 4;
                  break;
                default:
                  tabIndex = 0;
              }

              return MaterialPageRoute(
                settings: RouteSettings(name: normalized),
                builder: (_) => MainScaffold(
                  appState: appState,
                  initialIndex: tabIndex,
                ),
              );
            }

            // 6. Organization Onboarding
            if (normalized == '/onboarding') {
              if (!appState.isLoggedIn) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/login'),
                  builder: (_) => LoginScreen(appState: appState),
                );
              }
              if (appState.hasCompletedOnboarding && appState.brands.isNotEmpty) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/dashboard'),
                  builder: (_) => MainScaffold(
                    appState: appState,
                    initialIndex: 0,
                  ),
                );
              }
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/onboarding'),
                builder: (ctx) => OnboardingScreen(
                  appState: appState,
                  onComplete: () {
                    Navigator.of(ctx).pushReplacementNamed('/dashboard');
                  },
                ),
              );
            }

            // 7. Unknown / Fallback Route (Public landing on web, splash on native)
            if (kIsWeb) {
              if (appState.isLoggedIn && !appState.isSessionExpired) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/dashboard'),
                  builder: (_) => MainScaffold(
                    appState: appState,
                    initialIndex: 0,
                  ),
                );
              }
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/'),
                builder: (_) => LandingScreen(appState: appState),
              );
            }
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/splash'),
              builder: (_) => SplashScreen(appState: appState),
            );
          },
        );
      },
    );
  }
}
