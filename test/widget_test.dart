import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/fake_publishing_adapter.dart';
import 'package:no5ocial/main.dart';
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

    await tester.pumpWidget(No5ocialApp(appState: appState));
    await tester.pumpAndSettle();

    // Verify main app title
    expect(find.text('No5ocial Operations Console'), findsOneWidget);

    // Verify operational metrics cards
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    // Navigate to Content Library
    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Content Library'), findsOneWidget);

    // Navigate to Calendar
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Publishing Calendar'), findsOneWidget);

    // Navigate to Accounts
    await tester.tap(find.byIcon(Icons.group_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Brands & Connected Accounts'), findsOneWidget);
    expect(find.text('Shaadow'), findsWidgets);

    // Navigate to Settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('System Settings & Diagnostics'), findsOneWidget);
  });
}
