import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../models/task.dart';
import '../../../repositories/institution_repo.dart';
import '../../../core/providers.dart';
import '../create_user_screen.dart';

enum UserType { elderly, student }

class WebUserManagementView extends ConsumerStatefulWidget {
  const WebUserManagementView({super.key});

  @override
  ConsumerState<WebUserManagementView> createState() =>
      _WebUserManagementViewState();
}

class _WebUserManagementViewState extends ConsumerState<WebUserManagementView> {
  Timer? _debounce;
  String _searchQuery = '';
  UserType _activeTab = UserType.elderly;
  int _currentPage = 0;
  final int _pageSize = 15;

  List<User> _users = [];
  bool _isLoading = false;
  int _totalElements = 0;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(institutionRepoProvider);
      final roleStr = _activeTab == UserType.elderly ? 'ELDERLY' : 'STUDENT';

      final response = await repo.getUsers(
        role: roleStr,
        page: _currentPage,
        size: _pageSize,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _users = response.items;
          _totalElements = response.totalElements;
          _hasNextPage = response.hasNext;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
          _currentPage = 0;
        });
        _fetchUsers();
      }
    });
  }

  void _showCreateUserDialog({User? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            height: MediaQuery.of(context).size.height * 0.8,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: CreateUserScreen(existingUser: user),
          ),
        );
      },
    ).then((_) {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(institutionUsersProvider(null));
      _fetchUsers();
    });
  }

  Future<void> _softDeleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Pasife Al'),
        content: const Text(
          'Bu kullanıcıyı pasife almak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Pasife Al',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(institutionRepoProvider).deleteUserById(userId);
        _fetchUsers();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kullanıcı Yönetimi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Yeni Kullanıcı Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filters & Search
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'İsim, e-posta veya telefon ile ara...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF4F46E5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SegmentedButton<UserType>(
                segments: const [
                  ButtonSegment(
                    value: UserType.elderly,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Yaşlı / Engelli'),
                    ),
                  ),
                  ButtonSegment(
                    value: UserType.student,
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Öğrenci'),
                    ),
                  ),
                ],
                selected: {_activeTab},
                onSelectionChanged: (Set<UserType> newSelection) {
                  setState(() {
                    _activeTab = newSelection.first;
                    _currentPage = 0;
                  });
                  _fetchUsers();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading)
                  const LinearProgressIndicator(color: Color(0xFF4F46E5))
                else
                  const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB),
                      ),
                      dataRowMaxHeight: 64,
                      columns: [
                        const DataColumn(
                          label: Text(
                            'KULLANICI',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'İLETİŞİM BİLGİLERİ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'DURUM',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            _activeTab == UserType.student
                                ? 'GÖREV İSTATİSTİKLERİ'
                                : 'ADRES/DETAY',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'İŞLEMLER',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      rows: _users.map((user) => _buildDataRow(user)).toList(),
                    ),
                  ),
                ),
                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam $_totalElements kayıttan ${_users.length} tanesi gösteriliyor.',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() => _currentPage--);
                                    _fetchUsers();
                                  }
                                : null,
                          ),
                          Text(
                            'Sayfa ${_currentPage + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _hasNextPage
                                ? () {
                                    setState(() => _currentPage++);
                                    _fetchUsers();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(User user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: user.role == Role.STUDENT
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.role == Role.STUDENT ? Icons.school : Icons.person,
                  size: 18,
                  color: user.role == Role.STUDENT
                      ? Colors.blue.shade600
                      : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.phoneNumber != null)
                Text(user.phoneNumber!, style: const TextStyle(fontSize: 13)),
              if (user.email != null)
                Text(
                  user.email!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
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
                color: user.isActive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ),
        DataCell(
          _activeTab == UserType.student
              ? _StudentTaskStatsWidget(userId: user.id)
              : Text(
                  user.address ?? '-',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
                onPressed: () => _showCreateUserDialog(user: user),
                tooltip: 'Düzenle',
              ),
              if (user.isActive)
                IconButton(
                  icon: const Icon(
                    Icons.block_outlined,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _softDeleteUser(user.id),
                  tooltip: 'Pasife Al',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentTaskStatsWidget extends ConsumerWidget {
  final String userId;
  const _StudentTaskStatsWidget({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Task>>(
      future: ref.read(institutionRepoProvider).getUserHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('-', style: TextStyle(color: Colors.red));
        }
        final tasks = snapshot.data!;
        final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
        final recentTasks = tasks
            .where(
              (t) => t.createdAt != null && t.createdAt!.isAfter(oneMonthAgo),
            )
            .toList();
        final completed = recentTasks
            .where(
              (t) =>
                  t.status == TaskStatus.COMPLETED ||
                  t.status == TaskStatus.DELIVERED,
            )
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Son 1 Ay Toplam: ${recentTasks.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              'Tamamlanan: $completed',
              style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)),
            ),
          ],
        );
      },
    );
  }
}
