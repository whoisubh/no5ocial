import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/brand.dart';

abstract class BrandRepository {
  List<Brand> getAllBrands();
  Brand? getBrandById(String id);
  void saveBrand(Brand brand);
  void deleteBrand(String id);
}

class SqliteBrandRepository implements BrandRepository {
  final Map<String, Brand> _brands = {};
  final AppDatabase _db = AppDatabase.instance;

  SqliteBrandRepository({List<Brand>? initialData}) {
    final data = initialData ?? const [];
    for (final brand in data) {
      _brands[brand.id] = brand;
    }
  }

  Future<void> init() async {
    final list = await _db.getAllBrands();
    _brands.clear();
    for (final brand in list) {
      _brands[brand.id] = brand;
    }
  }

  void clearCache() => _brands.clear();

  @override
  List<Brand> getAllBrands() {
    final list = _brands.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Brand? getBrandById(String id) => _brands[id];

  @override
  void saveBrand(Brand brand) {
    _brands[brand.id] = brand;
    _db.saveBrand(brand).catchError((_) {});
  }

  @override
  void deleteBrand(String id) {
    _brands.remove(id);
    _db.deleteBrand(id).catchError((_) {});
  }
}

class InMemoryBrandRepository extends SqliteBrandRepository {
  InMemoryBrandRepository({super.initialData});
}
