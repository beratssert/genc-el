import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/login_screen.dart';
import '../../../services/storage_service.dart';
import 'web_dashboard_view.dart';
import 'web_user_management_view.dart';

class InstitutionWebShell extends ConsumerStatefulWidget {
  const InstitutionWebShell({super.key});

  @override
  ConsumerState<InstitutionWebShell> createState() => _InstitutionWebShellState();
}

class _InstitutionWebShellState extends ConsumerState<InstitutionWebShell> {
  int _selectedIndex = 0;

  Future<void> _logout() async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen(selectedType: 'elderly')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              children: [
                // Header / Logo area
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  color: const Color(0xFF4F46E5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Genç-El',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kurum Paneli',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      userAsync.when(
                        data: (user) => Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const Text('Yükleniyor…', style: TextStyle(color: Colors.white70)),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Özet İstatistikler',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.people_outline,
                        label: 'Kullanıcı Yönetimi',
                        index: 1,
                      ),
                    ],
                  ),
                ),
                // Bottom Area (Logout)
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                  title: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                  ),
                  onTap: _logout,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                WebDashboardView(),
                WebUserManagementView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
