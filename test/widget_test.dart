import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/fake_publishing_adapter.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/presentation/navigation/main_scaffold.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

void main() {
  testWidgets('No5ocial App Smoke Test — Renders Home and Navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState(
      brandRepository: InMemoryBrandRepository(),
      accountRepository: InMemoryAccountRepository(),
      postRepository: InMemoryPostRepository(),
      jobRepository: InMemoryJobRepository(),
      auditRepository: InMemoryAuditRepository(),
      publishingAdapter: const FakePublishingAdapter(),
    );
    appState.isLoggedIn = true;
    appState.localUserName = 'Test User';
    appState.createBrand(name: 'Shaadow', description: 'Internal workspace');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainScaffold(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main console title in desktop top bar
    expect(find.text('Publishing Operations Console'), findsOneWidget);

    // Verify operational metrics cards
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    // Navigate to Content Library via desktop sidebar
    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Multi-Platform Content Library'), findsOneWidget);

    // Navigate to Calendar
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Scheduled Editorial Calendar'), findsOneWidget);

    // Navigate to Accounts
    await tester.tap(find.byIcon(Icons.supervised_user_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Brand & Channel Registry'), findsOneWidget);
    expect(find.text('Shaadow'), findsWidgets);

    // Navigate to Settings
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Workspace Settings'), findsWidgets);
  });
}
