import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/channel_group.dart';

abstract class GroupRepository {
  List<ChannelGroup> getAllGroups();
  ChannelGroup? getGroupById(String id);
  List<ChannelGroup> getGroupsByBrand(String brandId);
  void saveGroup(ChannelGroup group);
  void deleteGroup(String id);
}

class SqliteGroupRepository implements GroupRepository {
  final List<ChannelGroup> _cache = [];
  final AppDatabase _db = AppDatabase.instance;

  SqliteGroupRepository({List<ChannelGroup>? initialData}) {
    final data = initialData ?? const [];
    _cache.addAll(data);
  }

  Future<void> init() async {
    final groups = await _db.getAllGroups();
    _cache.clear();
    _cache.addAll(groups);
  }

  void clearCache() => _cache.clear();

  @override
  List<ChannelGroup> getAllGroups() => List.unmodifiable(_cache);

  @override
  ChannelGroup? getGroupById(String id) {
    try {
      return _cache.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<ChannelGroup> getGroupsByBrand(String brandId) {
    return _cache.where((g) => g.brandId == brandId).toList();
  }

  @override
  void saveGroup(ChannelGroup group) {
    _cache.removeWhere((g) => g.id == group.id);
    _cache.add(group);
    _db.saveGroup(group).catchError((_) {});
  }

  @override
  void deleteGroup(String id) {
    _cache.removeWhere((g) => g.id == id);
    _db.deleteGroup(id).catchError((_) {});
  }
}

class InMemoryGroupRepository extends SqliteGroupRepository {
  InMemoryGroupRepository({super.initialData});
}

