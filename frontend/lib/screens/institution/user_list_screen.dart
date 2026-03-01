import 'package:flutter/material.dart';

enum UserType { elderly, student }

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _searchQuery = '';
  UserType _activeTab = UserType.elderly;

  final List<Map<String, dynamic>> _elderlyUsers = [
    {
      'id': 1,
      'name': 'Ayşe Yılmaz',
      'phone': '0532 123 45 67',
      'address': 'Çankaya, Ankara',
    },
    {
      'id': 2,
      'name': 'Mehmet Demir',
      'phone': '0533 234 56 78',
      'address': 'Keçiören, Ankara',
    },
    {
      'id': 3,
      'name': 'Fatma Kaya',
      'phone': '0534 345 67 89',
      'address': 'Mamak, Ankara',
    },
    {
      'id': 4,
      'name': 'Ali Çelik',
      'phone': '0535 456 78 90',
      'address': 'Yenimahalle, Ankara',
    },
    {
      'id': 5,
      'name': 'Zeynep Arslan',
      'phone': '0536 567 89 01',
      'address': 'Etimesgut, Ankara',
    },
  ];

  final List<Map<String, dynamic>> _studentUsers = [
    {
      'id': 1,
      'name': 'Ahmet Yılmaz',
      'phone': '0542 123 45 67',
      'university': 'Ankara Üniversitesi',
      'completedOrders': 142,
    },
    {
      'id': 2,
      'name': 'Berat Öztürk',
      'phone': '0543 234 56 78',
      'university': 'Gazi Üniversitesi',
      'completedOrders': 98,
    },
    {
      'id': 3,
      'name': 'Elif Şahin',
      'phone': '0544 345 67 89',
      'university': 'Hacettepe Üniversitesi',
      'completedOrders': 156,
    },
    {
      'id': 4,
      'name': 'Can Aydın',
      'phone': '0545 456 78 90',
      'university': 'ODTÜ',
      'completedOrders': 87,
    },
    {
      'id': 5,
      'name': 'Selin Koç',
      'phone': '0546 567 89 01',
      'university': 'Ankara Üniversitesi',
      'completedOrders': 124,
    },
  ];

  List<Map<String, dynamic>> get _filteredElderlyUsers {
    if (_searchQuery.isEmpty) return _elderlyUsers;
    return _elderlyUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      final phone = user['phone'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredStudentUsers {
    if (_searchQuery.isEmpty) return _studentUsers;
    return _studentUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      final phone = user['phone'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                width: double.infinity,
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kullanıcı Listesi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'Tüm kullanıcıları görüntüle',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Search
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'İsim veya telefon ara...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                              ), // gray-400
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF9CA3AF),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ), // gray-300
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 2,
                                ), // indigo-600
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SegmentedButton<UserType>(
                            segments: [
                              ButtonSegment(
                                value: UserType.elderly,
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Yaşlı / Engelli (${_filteredElderlyUsers.length})',
                                  ),
                                ),
                              ),
                              ButtonSegment(
                                value: UserType.student,
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Öğrenci (${_filteredStudentUsers.length})',
                                  ),
                                ),
                              ),
                            ],
                            selected: {_activeTab},
                            onSelectionChanged: (Set<UserType> newSelection) {
                              setState(() {
                                _activeTab = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return const Color(0xFFF3F4F6); // gray-100
                                  }),
                              side: WidgetStateProperty.all(
                                const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ), // gray-200
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List Content
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: _activeTab == UserType.elderly
                                ? _buildElderlyList()
                                : _buildStudentList(),
                          ),
                        ),
                      ],
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

  List<Widget> _buildElderlyList() {
    return _filteredElderlyUsers.map((user) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user['name']} profiline git (Mock)')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100, // bg-amber-100
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.green.shade700, // text-amber-600 equivalent
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              user['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (user['activeOrders'] > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['phone'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['address'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280), // text-gray-500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildStudentList() {
    return _filteredStudentUsers.map((user) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user['name']} profiline git (Mock)')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100, // bg-green-100
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.blue.shade600, // text-green-600
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              user['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF3F4F6,
                              ), // bg-gray-100 variant secondary
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${user['completedOrders']} görev',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151), // text-gray-700
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['phone'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['university'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280), // text-gray-500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
