import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_theme.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/fake_publishing_adapter.dart';
import 'package:no5ocial/presentation/navigation/main_scaffold.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize data repositories with seed portfolio
  final brandRepo = InMemoryBrandRepository();
  final accountRepo = InMemoryAccountRepository();
  final postRepo = InMemoryPostRepository();
  final jobRepo = InMemoryJobRepository();
  final auditRepo = InMemoryAuditRepository();

  // Test fake adapter for simulation harness
  final fakeAdapter = FakePublishingAdapter();

  final appState = AppState(
    brandRepository: brandRepo,
    accountRepository: accountRepo,
    postRepository: postRepo,
    jobRepository: jobRepo,
    auditRepository: auditRepo,
    publishingAdapter: fakeAdapter,
  );

  runApp(No5ocialApp(appState: appState));
}

class No5ocialApp extends StatelessWidget {
  final AppState appState;

  const No5ocialApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No5ocial — Shaadow Publishing Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainScaffold(appState: appState),
    );
  }
}
