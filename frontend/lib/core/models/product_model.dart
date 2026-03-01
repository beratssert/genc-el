import 'package:flutter/material.dart';

/// Ürün kategorisi.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  final int id;
  final String name;
  final String emoji;
  final Color color;
}

/// Tek bir ürün.
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
  });

  final int id;
  final int categoryId;
  final String name;

  /// Birim (Adet, Kg, Lt, Paket…)
  final String unit;
}
