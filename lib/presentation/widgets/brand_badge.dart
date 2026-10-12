import 'package:flutter/material.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';

export 'package:no5ocial/presentation/widgets/entity_badges.dart';

/// Legacy alias for CompanyBadge ensuring backward compatibility
class BrandBadge extends StatelessWidget {
  final Brand? brand;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;

  const BrandBadge({
    super.key,
    required this.brand,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CompanyBadge(
      brand: brand,
      isSelected: isSelected,
      onTap: onTap,
      isCompact: isCompact,
    );
  }
}
