import 'package:no5ocial/data/local/seed_data.dart';
import 'package:no5ocial/domain/models/brand.dart';

abstract class BrandRepository {
  List<Brand> getAllBrands();
  Brand? getBrandById(String id);
  void saveBrand(Brand brand);
  void deleteBrand(String id);
}

class InMemoryBrandRepository implements BrandRepository {
  final Map<String, Brand> _brands = {};

  InMemoryBrandRepository({List<Brand>? initialData}) {
    final data = initialData ?? SeedData.initialBrands;
    for (final brand in data) {
      _brands[brand.id] = brand;
    }
  }

  @override
  List<Brand> getAllBrands() => _brands.values.toList();

  @override
  Brand? getBrandById(String id) => _brands[id];

  @override
  void saveBrand(Brand brand) {
    _brands[brand.id] = brand;
  }

  @override
  void deleteBrand(String id) {
    _brands.remove(id);
  }
}
