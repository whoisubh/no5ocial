// ignore_for_file: camel_case_types
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
import 'package:no5ocial/presentation/state/app_state.dart';

void main() async {
  await bootstrap(flavor: AppFlavor.dev);
}

/// Universal application bootstrapper supporting flavors (dev, prod)
Future<void> bootstrap({AppFlavor flavor = AppFlavor.dev}) async {
  WidgetsFlutterBinding.ensureInitialized();

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
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? '/';

            // 0. Default Root: Custom Branded Splash Screen
            if (routeName == '/' || routeName == '/splash') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => SplashScreen(appState: appState),
              );
            }

            // 1. Authenticated Dashboard
            if (routeName == '/dashboard') {
              if (!appState.isLoggedIn) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => LoginScreen(appState: appState),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => MainScaffold(
                  appState: appState,
                  initialIndex: 0,
                ),
              );
            }

            // 2. Organization Onboarding
            if (routeName == '/onboarding') {
              return MaterialPageRoute(
                settings: settings,
                builder: (ctx) => OnboardingScreen(
                  appState: appState,
                  onComplete: () {
                    Navigator.of(ctx).pushReplacementNamed('/dashboard');
                  },
                ),
              );
            }

            // 3. Mobile Welcome / Public Landing
            if (routeName == '/welcome') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => MobileWelcomeScreen(appState: appState),
              );
            }

            if (routeName == '/landing') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => LandingScreen(appState: appState),
              );
            }

            if (routeName == '/login') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => LoginScreen(appState: appState),
              );
            }

            // Legal Pages
            if (routeName == '/terms') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const TermsScreen(),
              );
            }
            if (routeName == '/privacy') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const PrivacyScreen(),
              );
            }
            if (routeName == '/disclaimer') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const DisclaimerScreen(),
              );
            }

            // 2. Auth Guard for Dashboard & Onboarding
            // If user is not logged in, redirect strictly to LoginScreen
            if (!appState.isLoggedIn) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => LoginScreen(appState: appState),
              );
            }

            // 3. Mandatory Onboarding: If user has 0 registered companies, prompt onboarding
            if (appState.brands.isEmpty || routeName == '/onboarding') {
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

            // 4. Dashboard Endpoints
            int tabIndex = 0;
            switch (routeName) {
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
              settings: settings,
              builder: (_) => MainScaffold(
                appState: appState,
                initialIndex: tabIndex,
              ),
            );
          },
        );
      },
    );
  }
}
