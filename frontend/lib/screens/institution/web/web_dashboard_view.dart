import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/user.dart';

class WebDashboardView extends ConsumerWidget {
  const WebDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final usersAsync = ref.watch(institutionUsersProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App Bar equivalent for content area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Text(
            'Özet İstatistikler',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          (stats.totalElderlies ?? 0).toString(),
                          'Yaşlı/Engelli Sayısı',
                          const Color(0xFF4F46E5),
                          Icons.elderly_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                          (stats.totalStudents ?? 0).toString(),
                          'Öğrenci Sayısı',
                          const Color(0xFF9333EA),
                          Icons.school_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                          (stats.totalTasksThisMonth ?? 0).toString(),
                          'Bu Ay Tamamlanan Görev',
                          const Color(0xFF2563EB),
                          Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Hata: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Son Eklenen Kullanıcılar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: usersAsync.when(
                    data: (users) {
                      if (users.items.isEmpty) {
                         return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Henüz kullanıcı eklenmemiş.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        );
                      }
                      final recent = users.items.take(5).toList();
                      return Column(
                        children: recent.map((user) => _buildUserRow(user)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Hata: $e'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: color.withValues(alpha: 0.1),
               shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(User user) {
    final isStudent = user.role == Role.STUDENT;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isStudent ? Colors.blue.shade50 : Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isStudent ? Icons.school : Icons.person,
              color: isStudent ? Colors.blue.shade600 : Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  isStudent ? 'Öğrenci' : 'Yaşlı/Engelli',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            user.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
               color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
               borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.isActive ? 'Aktif' : 'Pasif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
