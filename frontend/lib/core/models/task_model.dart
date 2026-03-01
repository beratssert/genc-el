/// Görevin anlık durumu (backend ile uyumlu).
enum TaskStatus {
  pending, // Öğrenci aranıyor
  assigned, // Öğrenci kabul etti, yolda
  atHomeInitial, // Öğrenci eve vardı, para teyidi bekleniyor
  shopping, // Öğrenci alışverişte
  atHomeFinal, // Öğrenci döndü, teslimat aşaması
  completed, // Tamamlandı
  cancelled, // İptal edildi
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Öğrenci Aranıyor…';
      case TaskStatus.assigned:
        return 'Öğrenci Yolda';
      case TaskStatus.atHomeInitial:
        return 'Öğrenci Kapıda — Para Teyidi';
      case TaskStatus.shopping:
        return 'Alışveriş Yapılıyor';
      case TaskStatus.atHomeFinal:
        return 'Teslimat Yapılıyor';
      case TaskStatus.completed:
        return 'Tamamlandı';
      case TaskStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  /// Durum rengini döndürür.
  int get colorValue {
    switch (this) {
      case TaskStatus.pending:
        return 0xFFF59E0B; // amber-500
      case TaskStatus.assigned:
      case TaskStatus.atHomeInitial:
        return 0xFF3B82F6; // blue-500
      case TaskStatus.shopping:
      case TaskStatus.atHomeFinal:
        return 0xFF8B5CF6; // violet-500
      case TaskStatus.completed:
        return 0xFF16A34A; // green-600
      case TaskStatus.cancelled:
        return 0xFFEF4444; // red-500
    }
  }
}

/// Alışveriş listesindeki tek bir ürün.
class ShoppingItem {
  const ShoppingItem({
    required this.name,
    required this.qty,
    required this.unit,
  });

  final String name;
  final int qty;
  final String unit;
}

/// Bir görevi (alışveriş talebini) temsil eden model.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.status,
    required this.shoppingList,
    required this.createdAt,
    this.volunteerName,
    this.totalAmountGiven,
    this.shoppingCost,
    this.changeAmount,
    this.note,
  });

  final int id;
  final TaskStatus status;
  final List<ShoppingItem> shoppingList;
  final DateTime createdAt;
  final String? volunteerName;

  /// Yaşlının öğrenciye teslim ettiği para (Teslim Edilen).
  final double? totalAmountGiven;

  /// Öğrencinin markette harcadığı gerçek tutar (Alışveriş Tutarı).
  final double? shoppingCost;

  /// Para üstü: totalAmountGiven - shoppingCost (İade Alınan).
  final double? changeAmount;

  final String? note;
}
