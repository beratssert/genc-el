import 'package:flutter/material.dart';
import '../models/product_model.dart';

// ---------------------------------------------------------------------------
// Demo Kategoriler (9 adet)
// ---------------------------------------------------------------------------
const List<Category> demoCategories = [
  Category(id: 1, name: 'Unlu Mamüller', emoji: '🥖', color: Color(0xFFF59E0B)),
  Category(id: 2, name: 'Süt Ürünleri', emoji: '🥛', color: Color(0xFF3B82F6)),
  Category(id: 3, name: 'Et & Tavuk', emoji: '🥩', color: Color(0xFFEF4444)),
  Category(id: 4, name: 'Sebze & Meyve', emoji: '🥕', color: Color(0xFF16A34A)),
  Category(id: 5, name: 'Konserve', emoji: '🥫', color: Color(0xFF8B5CF6)),
  Category(id: 6, name: 'İçecekler', emoji: '🧃', color: Color(0xFF06B6D4)),
  Category(id: 7, name: 'Temizlik', emoji: '🧹', color: Color(0xFF64748B)),
  Category(id: 8, name: 'Kişisel Bakım', emoji: '🧴', color: Color(0xFFEC4899)),
  Category(id: 9, name: 'Atıştırmalık', emoji: '🍬', color: Color(0xFFF97316)),
];

// ---------------------------------------------------------------------------
// Demo Ürünler
// ---------------------------------------------------------------------------
const List<Product> demoProducts = [
  // Unlu Mamüller (cat 1)
  Product(id: 101, categoryId: 1, name: 'Ekmek', unit: 'Adet'),
  Product(id: 102, categoryId: 1, name: 'Simit', unit: 'Adet'),
  Product(id: 103, categoryId: 1, name: 'Pide', unit: 'Adet'),
  Product(id: 104, categoryId: 1, name: 'Un', unit: 'Kg'),
  Product(id: 105, categoryId: 1, name: 'Makarna', unit: 'Paket'),
  Product(id: 106, categoryId: 1, name: 'Pirinç', unit: 'Kg'),
  Product(id: 107, categoryId: 1, name: 'Bulgur', unit: 'Kg'),
  Product(id: 108, categoryId: 1, name: 'Poğaça', unit: 'Adet'),
  Product(id: 109, categoryId: 1, name: 'Bisküvi', unit: 'Paket'),

  // Süt Ürünleri (cat 2)
  Product(id: 201, categoryId: 2, name: 'Süt', unit: 'Lt'),
  Product(id: 202, categoryId: 2, name: 'Yoğurt', unit: 'Kg'),
  Product(id: 203, categoryId: 2, name: 'Peynir', unit: 'Kg'),
  Product(id: 204, categoryId: 2, name: 'Tereyağı', unit: 'Paket'),
  Product(id: 205, categoryId: 2, name: 'Kaymak', unit: 'Paket'),
  Product(id: 206, categoryId: 2, name: 'Ayran', unit: 'Adet'),
  Product(id: 207, categoryId: 2, name: 'Kefir', unit: 'Adet'),
  Product(id: 208, categoryId: 2, name: 'Labne', unit: 'Paket'),
  Product(id: 209, categoryId: 2, name: 'Yumurta', unit: 'Koli'),

  // Et & Tavuk (cat 3)
  Product(id: 301, categoryId: 3, name: 'Tavuk Göğsü', unit: 'Kg'),
  Product(id: 302, categoryId: 3, name: 'Kıyma', unit: 'Kg'),
  Product(id: 303, categoryId: 3, name: 'Dana Eti', unit: 'Kg'),
  Product(id: 304, categoryId: 3, name: 'Tavuk But', unit: 'Kg'),
  Product(id: 305, categoryId: 3, name: 'Sucuk', unit: 'Paket'),
  Product(id: 306, categoryId: 3, name: 'Sosis', unit: 'Paket'),
  Product(id: 307, categoryId: 3, name: 'Pastırma', unit: 'Paket'),
  Product(id: 308, categoryId: 3, name: 'Balık', unit: 'Kg'),
  Product(id: 309, categoryId: 3, name: 'Hindi', unit: 'Kg'),

  // Sebze & Meyve (cat 4)
  Product(id: 401, categoryId: 4, name: 'Domates', unit: 'Kg'),
  Product(id: 402, categoryId: 4, name: 'Salatalık', unit: 'Kg'),
  Product(id: 403, categoryId: 4, name: 'Patates', unit: 'Kg'),
  Product(id: 404, categoryId: 4, name: 'Soğan', unit: 'Kg'),
  Product(id: 405, categoryId: 4, name: 'Elma', unit: 'Kg'),
  Product(id: 406, categoryId: 4, name: 'Portakal', unit: 'Kg'),
  Product(id: 407, categoryId: 4, name: 'Muz', unit: 'Kg'),
  Product(id: 408, categoryId: 4, name: 'Limon', unit: 'Kg'),
  Product(id: 409, categoryId: 4, name: 'Ispanak', unit: 'Demet'),

  // Konserve (cat 5)
  Product(id: 501, categoryId: 5, name: 'Salça', unit: 'Kutu'),
  Product(id: 502, categoryId: 5, name: 'Ton Balığı', unit: 'Kutu'),
  Product(id: 503, categoryId: 5, name: 'Nohut', unit: 'Kutu'),
  Product(id: 504, categoryId: 5, name: 'Fasulye', unit: 'Kutu'),
  Product(id: 505, categoryId: 5, name: 'Mercimek', unit: 'Kg'),
  Product(id: 506, categoryId: 5, name: 'Bezelye', unit: 'Kutu'),
  Product(id: 507, categoryId: 5, name: 'Mısır', unit: 'Kutu'),
  Product(id: 508, categoryId: 5, name: 'Zeytin', unit: 'Kg'),
  Product(id: 509, categoryId: 5, name: 'Turşu', unit: 'Kavanoz'),

  // İçecekler (cat 6)
  Product(id: 601, categoryId: 6, name: 'Su', unit: 'Lt'),
  Product(id: 602, categoryId: 6, name: 'Soda', unit: 'Adet'),
  Product(id: 603, categoryId: 6, name: 'Meyve Suyu', unit: 'Adet'),
  Product(id: 604, categoryId: 6, name: 'Çay', unit: 'Paket'),
  Product(id: 605, categoryId: 6, name: 'Kahve', unit: 'Paket'),
  Product(id: 606, categoryId: 6, name: 'Kola', unit: 'Adet'),
  Product(id: 607, categoryId: 6, name: 'Gazoz', unit: 'Adet'),
  Product(id: 608, categoryId: 6, name: 'Bitkisel Çay', unit: 'Paket'),
  Product(id: 609, categoryId: 6, name: 'Şeker', unit: 'Kg'),

  // Temizlik (cat 7)
  Product(id: 701, categoryId: 7, name: 'Deterjan', unit: 'Paket'),
  Product(id: 702, categoryId: 7, name: 'Bulaşık Sıvısı', unit: 'Adet'),
  Product(id: 703, categoryId: 7, name: 'Çöp Torbası', unit: 'Rulo'),
  Product(id: 704, categoryId: 7, name: 'Tuvalet Kağıdı', unit: 'Paket'),
  Product(id: 705, categoryId: 7, name: 'Kağıt Havlu', unit: 'Paket'),
  Product(id: 706, categoryId: 7, name: 'Bez', unit: 'Adet'),
  Product(id: 707, categoryId: 7, name: 'Çamaşır Suyu', unit: 'Adet'),
  Product(id: 708, categoryId: 7, name: 'Yer Temizleyici', unit: 'Adet'),
  Product(id: 709, categoryId: 7, name: 'Cam Sileceği', unit: 'Adet'),

  // Kişisel Bakım (cat 8)
  Product(id: 801, categoryId: 8, name: 'Şampuan', unit: 'Adet'),
  Product(id: 802, categoryId: 8, name: 'Sabun', unit: 'Adet'),
  Product(id: 803, categoryId: 8, name: 'Diş Macunu', unit: 'Adet'),
  Product(id: 804, categoryId: 8, name: 'Diş Fırçası', unit: 'Adet'),
  Product(id: 805, categoryId: 8, name: 'Tıraş Jeli', unit: 'Adet'),
  Product(id: 806, categoryId: 8, name: 'Islak Mendil', unit: 'Paket'),
  Product(id: 807, categoryId: 8, name: 'Bakım Kremi', unit: 'Adet'),
  Product(id: 808, categoryId: 8, name: 'Deodorant', unit: 'Adet'),
  Product(id: 809, categoryId: 8, name: 'Kolonya', unit: 'Adet'),

  // Atıştırmalık (cat 9)
  Product(id: 901, categoryId: 9, name: 'Çikolata', unit: 'Adet'),
  Product(id: 902, categoryId: 9, name: 'Gofret', unit: 'Adet'),
  Product(id: 903, categoryId: 9, name: 'Cips', unit: 'Paket'),
  Product(id: 904, categoryId: 9, name: 'Fındık', unit: 'Kg'),
  Product(id: 905, categoryId: 9, name: 'Leblebi', unit: 'Paket'),
  Product(id: 906, categoryId: 9, name: 'Kek', unit: 'Adet'),
  Product(id: 907, categoryId: 9, name: 'Kraker', unit: 'Paket'),
  Product(id: 908, categoryId: 9, name: 'Lokum', unit: 'Paket'),
  Product(id: 909, categoryId: 9, name: 'Baklava', unit: 'Kg'),
];

/// Belirli kategoriye ait ürünleri döndürür.
List<Product> productsForCategory(int categoryId) =>
    demoProducts.where((p) => p.categoryId == categoryId).toList();
