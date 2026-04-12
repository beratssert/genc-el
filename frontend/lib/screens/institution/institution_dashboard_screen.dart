import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/login_screen.dart';
import 'create_user_screen.dart';
import 'user_list_screen.dart';

class InstitutionDashboardScreen extends ConsumerStatefulWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  ConsumerState<InstitutionDashboardScreen> createState() =>
      _InstitutionDashboardScreenState();
}

class _InstitutionDashboardScreenState
    extends ConsumerState<InstitutionDashboardScreen> {
  Future<void> _logout() async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(selectedType: 'elderly')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurum Paneli',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                userAsync.when(
                  data: (user) => Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  loading: () => const Text(
                    'Yükleniyor…',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                  error: (_, _) => const Text(
                    'Kurum Yöneticisi',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEEF2FF), // indigo-50
                Color(0xFFF3E8FF), // purple-100
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Stats Cards Grid
                          statsAsync.when(
                            data: (stats) => GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                _buildStatCard(
                                  (stats.totalElderlies ?? 0).toString(),
                                  'Yaşlı/Engelli',
                                  const Color(0xFF4F46E5),
                                ),
                                _buildStatCard(
                                  (stats.totalStudents ?? 0).toString(),
                                  'Öğrenci',
                                  const Color(0xFF9333EA),
                                ),
                                _buildStatCard(
                                  (stats.totalTasksThisMonth ?? 0).toString(),
                                  'Bu Ay Tamamlanan',
                                  const Color(0xFF2563EB),
                                ),
                              ],
                            ),
                            loading: () => GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                _buildStatCard(
                                  '…',
                                  'Yaşlı/Engelli',
                                  const Color(0xFF4F46E5),
                                ),
                                _buildStatCard(
                                  '…',
                                  'Öğrenci',
                                  const Color(0xFF9333EA),
                                ),
                                _buildStatCard(
                                  '…',
                                  'Bu Ay Tamamlanan',
                                  const Color(0xFF2563EB),
                                ),
                              ],
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'İstatistikler yüklenemedi: $e',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Kullanıcı Yönetimi
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kullanıcı Yönetimi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionButton(
                                    context,
                                    'Yeni Kullanıcı Ekle',
                                    Icons.person_add_outlined,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateUserScreen(),
                                        ),
                                      ).then((_) {
                                        // Stats'ı yeniden yükle
                                        ref.invalidate(dashboardStatsProvider);
                                        ref.invalidate(currentUserProvider);
                                      });
                                    },
                                    isPrimary: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    context,
                                    'Kullanıcı Listesi',
                                    Icons.people_outline,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const UserListScreen(),
                                        ),
                                      );
                                    },
                                    isPrimary: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Yakında eklenecek son kullanıcılar (backend'den)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Son Eklenen Kullanıcılar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRecentUsersFromBackend(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUsersFromBackend() {
    final usersAsync = ref.watch(institutionUsersProvider(null));
    return usersAsync.when(
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
        final recent = users.items.take(3).toList();
        return Column(
          children: recent.asMap().entries.map((entry) {
            final user = entry.value;
            final isLast = entry.key == recent.length - 1;
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: user.role == Role.STUDENT
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.role == Role.STUDENT ? Icons.school : Icons.person,
                      size: 20,
                      color: user.role == Role.STUDENT
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${user.role == Role.STUDENT ? "Öğrenci" : "Yaşlı/Engelli"} • ${user.email ?? ""}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Hata: $e',
          style: TextStyle(color: Colors.red.shade600, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color valueColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24, color: const Color(0xFF4F46E5)),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4F46E5),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111827),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: const BorderSide(color: Color(0xFF4F46E5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }
}
