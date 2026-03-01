import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'user_list_screen.dart';

class InstitutionDashboardScreen extends StatelessWidget {
  const InstitutionDashboardScreen({super.key});

  // Mock stats
  final Map<String, dynamic> stats = const {
    'totalElderly': 45,
    'totalStudents': 78,
    'activeOrders': 12,
    'completedThisMonth': 234,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background: from-indigo-50 to-purple-100
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 448,
                    ), // max-w-md
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurum Paneli',
                              style: TextStyle(
                                fontSize: 20, // text-xl
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827), // gray-900
                              ),
                            ),
                            Text(
                              'Ankara Büyükşehir Belediyesi',
                              style: TextStyle(
                                fontSize: 14, // text-sm
                                color: Color(0xFF4B5563), // gray-600
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0), // p-4
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 448,
                      ), // max-w-md
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Stats Cards Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16, // gap-4
                            mainAxisSpacing: 16, // gap-4
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard(
                                stats['totalElderly'].toString(),
                                'Yaşlı/Engelli',
                                const Color(0xFF4F46E5), // indigo-600
                              ),
                              _buildStatCard(
                                stats['totalStudents'].toString(),
                                'Öğrenci',
                                const Color(0xFF9333EA), // purple-600
                              ),

                              _buildStatCard(
                                stats['completedThisMonth'].toString(),
                                'Bu Ay Tamamlanan',
                                const Color(0xFF2563EB), // blue-600
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // space-y-4
                          // Main Actions
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0), // p-6
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kullanıcı Yönetimi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w600, // font-semibold
                                      color: Color(0xFF111827), // gray-900
                                    ),
                                  ),
                                  const SizedBox(height: 16), // mb-4
                                  _buildActionButton(
                                    context,
                                    'Yeni Kullanıcı Ekle',
                                    Icons.person_add_outlined, // UserPlus
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateUserScreen(),
                                        ),
                                      );
                                    },
                                    isPrimary: true,
                                  ),
                                  const SizedBox(height: 12), // space-y-3
                                  _buildActionButton(
                                    context,
                                    'Kullanıcı Listesi',
                                    Icons.people_outline, // Users
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

                          // Quick Access (Recent Users)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0), // p-6
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
                                  ..._buildRecentUsers(),
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

  Widget _buildStatCard(String value, String label, Color valueColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0), // p-4
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 30, // text-3xl
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4), // mt-1
            Text(
              label,
              style: const TextStyle(
                fontSize: 14, // text-sm
                color: Color(0xFF4B5563), // gray-600
              ),
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
        height: 56, // h-14
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF4F46E5,
            ), // matching typical shadcn primary
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
        height: 56, // h-14
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24, color: Color(0xFF4F46E5)),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4F46E5),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111827), // gray-900
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: const BorderSide(color: Color(0xFF4F46E5)), // gray-200
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  List<Widget> _buildRecentUsers() {
    final users = [
      {'name': 'Mehmet Demir', 'type': 'Öğrenci', 'date': '25 Şub 2026'},
      {'name': 'Fatma Kaya', 'type': 'Yaşlı', 'date': '24 Şub 2026'},
      {'name': 'Ali Çelik', 'type': 'Öğrenci', 'date': '23 Şub 2026'},
    ];

    List<Widget> userWidgets = [];
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      userWidgets.add(
        Container(
          margin: EdgeInsets.only(
            bottom: i == users.length - 1 ? 0 : 12,
          ), // space-y-3
          padding: const EdgeInsets.all(12), // p-3
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // bg-gray-50
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
          child: Row(
            children: [
              Container(
                width: 40, // w-10
                height: 40, // h-10
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E7FF), // bg-indigo-100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person, // UserIcon
                  size: 20, // h-5 w-5
                  color: Color(0xFF4F46E5), // text-indigo-600
                ),
              ),
              const SizedBox(width: 12), // gap-3 equivalent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500, // font-medium
                        color: Color(0xFF111827), // text-gray-900
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${user['type']} • ${user['date']}',
                      style: const TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF4B5563), // text-gray-600
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return userWidgets;
  }
}
