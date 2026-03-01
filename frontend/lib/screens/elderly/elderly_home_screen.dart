import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import '../../screens/elderly/order_history_screen.dart';
import '../../screens/order/category_screen.dart';
import '../../widgets/elderly/greeting_header.dart';
import '../../widgets/elderly/active_order_card.dart';
import '../../widgets/elderly/home_action_buttons.dart';

/// Yaşlı/Engelli kullanıcısının ana sayfası.
///
/// İçerik (yukarıdan aşağıya):
///   1. Karşılama başlığı
///   2. Aktif sipariş kartı (varsa detay, yoksa boş durum)
///   3. Yeni Alışveriş Oluştur + Geçmiş Siparişler butonları
class ElderlyHomeScreen extends StatelessWidget {
  const ElderlyHomeScreen({
    super.key,
    this.userName = 'Mehmet Bey',
    this.activeTask,
    this.completedTasks = const [],
  });

  final String userName;

  /// null → aktif sipariş yok.
  final TaskModel? activeTask;

  /// Tamamlanmış / iptal geçmiş siparişler.
  final List<TaskModel> completedTasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Login sayfasıyla uyumlu gradient arka plan
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // green-50
              Color(0xFFD1FAE5), // emerald-100
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Karşılama ---
                GreetingHeader(userName: userName),
                const SizedBox(height: 28),

                // --- 2. Aktif Sipariş ---
                Expanded(
                  child: SingleChildScrollView(
                    child: ActiveOrderCard(activeTask: activeTask),
                  ),
                ),
                const SizedBox(height: 20),

                // --- 3. Aksiyon Butonları ---
                HomeActionButtons(
                  isOrderActive: activeTask != null,
                  onCreateOrder: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoryScreen()),
                    );
                  },
                  onViewHistory: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderHistoryScreen(completedTasks: completedTasks),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
