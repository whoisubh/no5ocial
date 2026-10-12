// ignore_for_file: camel_case_types
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
import 'package:no5ocial/domain/adapters/fake_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/instagram_publishing_adapter.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/presentation/navigation/main_scaffold.dart';
import 'package:no5ocial/presentation/screens/auth/login_screen.dart';
import 'package:no5ocial/presentation/screens/landing/landing_screen.dart';
import 'package:no5ocial/presentation/screens/legal/disclaimer_screen.dart';
import 'package:no5ocial/presentation/screens/legal/privacy_screen.dart';
import 'package:no5ocial/presentation/screens/legal/terms_screen.dart';
import 'package:no5ocial/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:no5ocial/presentation/screens/splash/splash_screen.dart';
import 'package:no5ocial/presentation/screens/welcome/mobile_welcome_screen.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';
import 'package:no5ocial/core/utils/url_strategy_helper.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

void main() async {
  await bootstrap(flavor: AppFlavor.dev);
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

  // Platform publishing adapters with official Instagram Graph API integration
  final publishingAdapter = CompositePublishingAdapter(
    platformAdapters: {
      PlatformType.instagram: InstagramPublishingAdapter(),
    },
    fallbackAdapter: const FakePublishingAdapter(),
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

  runApp(no5ocialApp(appState: appState));
}

class no5ocialApp extends StatelessWidget {
  final AppState appState;

  const no5ocialApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'no5ocial — Social Publishing & Scheduling Workspace',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          locale: appState.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

            // 1. Root & Public Landing Page
            if (normalized == '/' || normalized == '/landing') {
              if (kIsWeb) {
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
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (_) => LoginScreen(appState: appState),
              );
            }

            // 4. Mobile Welcome Screen
            if (normalized == '/welcome') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/welcome'),
                builder: (_) => MobileWelcomeScreen(appState: appState),
              );
            }

            // 5. Dashboard Endpoints (Protected by Auth Guard)
            if (normalized == '/dashboard' || normalized.startsWith('/dashboard/')) {
              if (!appState.isLoggedIn) {
                return MaterialPageRoute(
                  settings: const RouteSettings(name: '/login'),
                  builder: (_) => LoginScreen(appState: appState),
                );
              }

              if (appState.brands.isEmpty) {
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
