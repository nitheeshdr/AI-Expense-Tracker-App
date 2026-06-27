import 'package:flutter/material.dart';

import '../data/categories.dart';

/// Tinted rounded container holding the category's Material icon. Consistent
/// treatment wherever categories appear.
class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final def = Categories.of(category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: def.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(def.icon, color: def.color, size: size * 0.5),
    );
  }
}
