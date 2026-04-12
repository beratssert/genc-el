import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/user_page_response.dart';
import '../../repositories/institution_repo.dart';
import 'user_details_screen.dart';

enum UserType { elderly, student }

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  
  String _searchQuery = '';
  UserType _activeTab = UserType.elderly;
  
  List<User> _users = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  
  int _currentPage = 0;
  bool _hasNextPage = false;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchUsers(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasNextPage && !_isLoading && !_isLoadingMore) {
        _fetchUsers(refresh: false);
      }
    }
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _isLoading = true;
        _users.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final institutionRepo = ref.read(institutionRepoProvider);
      final roleString = _activeTab == UserType.elderly ? 'ELDERLY' : 'STUDENT';
      
      final UserPageResponse pageResponse = await institutionRepo.getUsers(
        role: roleString,
        page: _currentPage,
        size: 20,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          final newItems = pageResponse.items;
          if (refresh) {
            _users = List.from(newItems);
          } else {
            _users.addAll(newItems);
          }
          _currentPage++;
          _hasNextPage = pageResponse.hasNext;
          _totalElements = pageResponse.totalElements;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchUsers(refresh: true);
      }
    });
  }

  void _onTabChanged(UserType newType) {
    if (_activeTab != newType) {
      setState(() {
        _activeTab = newType;
      });
      _fetchUsers(refresh: true);
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kullanıcı Listesi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'Toplam $_totalElements kullanıcı bulundu',
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
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'İsim, telefon veya e-posta ara...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
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
                            segments: const [
                              ButtonSegment(
                                value: UserType.elderly,
                                label: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('Yaşlı / Engelli'),
                                ),
                              ),
                              ButtonSegment(
                                value: UserType.student,
                                label: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('Öğrenci'),
                                ),
                              ),
                            ],
                            selected: {_activeTab},
                            onSelectionChanged: (Set<UserType> newSelection) {
                              _onTabChanged(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return const Color(0xFFF3F4F6);
                                },
                              ),
                              side: WidgetStateProperty.all(
                                const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List Content
                        Expanded(
                          child: _isLoading && _users.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : RefreshIndicator(
                                  onRefresh: () => _fetchUsers(refresh: true),
                                  child: _users.isEmpty
                                      ? ListView(
                                          children: const [
                                            Padding(
                                              padding: EdgeInsets.all(32),
                                              child: Center(
                                                child: Text(
                                                  'Kullanıcı bulunamadı.',
                                                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          itemCount: _users.length + (_hasNextPage ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            if (index == _users.length) {
                                              return const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Center(child: CircularProgressIndicator()),
                                              );
                                            }
                                            
                                            final user = _users[index];
                                            final isStudent = user.role == Role.STUDENT;
                                            return _buildUserCard(user, isStudent);
                                          },
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

  Widget _buildUserCard(User user, bool isStudent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigate to details screen, and refresh on pop if data changed
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(userId: user.id),
            ),
          );
          if (result == true) {
            _fetchUsers(refresh: true);
          }
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
                  color: isStudent ? Colors.blue.shade100 : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStudent ? Icons.school : Icons.person,
                  color: isStudent ? Colors.blue.shade600 : Colors.green.shade700,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 4),
                    if (user.phoneNumber != null)
                      Text(
                        user.phoneNumber!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    if (user.address != null && user.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.address!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Align(
                alignment: Alignment.center,
                child: Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
