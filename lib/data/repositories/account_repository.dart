import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/social_account.dart';

abstract class AccountRepository {
  List<SocialAccount> getAllAccounts();
  List<SocialAccount> getAccountsByBrand(String brandId);
  List<SocialAccount> getAccountsByPlatform(PlatformType platform);
  SocialAccount? getAccountById(String id);
  void saveAccount(SocialAccount account);
  void deleteAccount(String id);
  void updateConnectionStatus(String id, ConnectionStatus status);
}

class SqliteAccountRepository implements AccountRepository {
  final Map<String, SocialAccount> _accounts = {};
  final AppDatabase _db = AppDatabase.instance;

  SqliteAccountRepository({List<SocialAccount>? initialData}) {
    final data = initialData ?? const [];
    for (final acc in data) {
      _accounts[acc.id] = acc;
    }
  }

  Future<void> init() async {
    final list = await _db.getAllAccounts();
    _accounts.clear();
    for (final acc in list) {
      _accounts[acc.id] = acc;
    }
  }

  void clearCache() => _accounts.clear();

  @override
  List<SocialAccount> getAllAccounts() {
    final list = _accounts.values.toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

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
    _db.saveAccount(account).catchError((_) {});
  }

  @override
  void deleteAccount(String id) {
    _accounts.remove(id);
    _db.deleteAccount(id).catchError((_) {});
  }

  @override
  void updateConnectionStatus(String id, ConnectionStatus status) {
    final existing = _accounts[id];
    if (existing != null) {
      final updated = existing.copyWith(
        connectionStatus: status,
        lastVerifiedAtUtc: DateTime.now().toUtc(),
      );
      _accounts[id] = updated;
      _db.saveAccount(updated).catchError((_) {});
    }
  }
}

class InMemoryAccountRepository extends SqliteAccountRepository {
  InMemoryAccountRepository({super.initialData});
}
