import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../repositories/institution_repo.dart';

enum UserType { elderly, student }

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String _searchQuery = '';
  UserType _activeTab = UserType.elderly;
  List<User> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final institutionRepo = ref.read(institutionRepoProvider);
      final users = await institutionRepo.getUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<User> get _elderlyUsers => _allUsers
      .where((u) => u.role == Role.ELDERLY)
      .where((u) {
        if (_searchQuery.isEmpty) return true;
        final query = _searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(query) ||
            (u.phoneNumber?.toLowerCase().contains(query) ?? false) ||
            (u.email?.toLowerCase().contains(query) ?? false);
      })
      .toList();

  List<User> get _studentUsers => _allUsers
      .where((u) => u.role == Role.STUDENT)
      .where((u) {
        if (_searchQuery.isEmpty) return true;
        final query = _searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(query) ||
            (u.phoneNumber?.toLowerCase().contains(query) ?? false) ||
            (u.email?.toLowerCase().contains(query) ?? false);
      })
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF2FF),
              Color(0xFFF3E8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              // Search
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'İsim, telefon veya e-posta ara...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                    ),
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
                                      ),
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
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tabs
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: SegmentedButton<UserType>(
                                  segments: [
                                    ButtonSegment(
                                      value: UserType.elderly,
                                      label: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(
                                          'Yaşlı / Engelli (${_elderlyUsers.length})',
                                        ),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: UserType.student,
                                      label: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(
                                          'Öğrenci (${_studentUsers.length})',
                                        ),
                                      ),
                                    ),
                                  ],
                                  selected: {_activeTab},
                                  onSelectionChanged:
                                      (Set<UserType> newSelection) {
                                    setState(() {
                                      _activeTab = newSelection.first;
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(
                                            WidgetState.selected)) {
                                          return Colors.white;
                                        }
                                        return const Color(0xFFF3F4F6);
                                      },
                                    ),
                                    side: WidgetStateProperty.all(
                                      const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // List Content
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _loadUsers,
                                  child: ListView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    children: _activeTab == UserType.elderly
                                        ? _buildUserCards(_elderlyUsers,
                                            isStudent: false)
                                        : _buildUserCards(_studentUsers,
                                            isStudent: true),
                                  ),
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

  List<Widget> _buildUserCards(List<User> users, {required bool isStudent}) {
    if (users.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Kullanıcı bulunamadı.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          ),
        ),
      ];
    }

    return users.map((user) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
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
                  color: isStudent
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStudent ? Icons.school : Icons.person,
                  color: isStudent
                      ? Colors.blue.shade600
                      : Colors.green.shade700,
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
                            user.fullName,
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
                            color: user.isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.isActive ? 'Aktif' : 'Pasif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: user.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (user.phoneNumber != null)
                      Text(
                        user.phoneNumber!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (user.address != null &&
                        user.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.address!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
