import 'package:no5ocial/data/local/seed_data.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/social_account.dart';

abstract class AccountRepository {
  List<SocialAccount> getAllAccounts();
  List<SocialAccount> getAccountsByBrand(String brandId);
  List<SocialAccount> getAccountsByPlatform(PlatformType platform);
  SocialAccount? getAccountById(String id);
  void saveAccount(SocialAccount account);
  void updateConnectionStatus(String id, ConnectionStatus status);
}

class InMemoryAccountRepository implements AccountRepository {
  final Map<String, SocialAccount> _accounts = {};

  InMemoryAccountRepository({List<SocialAccount>? initialData}) {
    final data = initialData ?? SeedData.initialAccounts;
    for (final acc in data) {
      _accounts[acc.id] = acc;
    }
  }

  @override
  List<SocialAccount> getAllAccounts() => _accounts.values.toList();

  @override
  List<SocialAccount> getAccountsByBrand(String brandId) =>
      _accounts.values.where((acc) => acc.brandId == brandId).toList();

  @override
  List<SocialAccount> getAccountsByPlatform(PlatformType platform) =>
      _accounts.values.where((acc) => acc.platform == platform).toList();

  @override
  SocialAccount? getAccountById(String id) => _accounts[id];

  @override
  void saveAccount(SocialAccount account) {
    _accounts[account.id] = account;
  }

  @override
  void updateConnectionStatus(String id, ConnectionStatus status) {
    final existing = _accounts[id];
    if (existing != null) {
      _accounts[id] = existing.copyWith(
        connectionStatus: status,
        lastVerifiedAtUtc: DateTime.now().toUtc(),
      );
    }
  }
}
