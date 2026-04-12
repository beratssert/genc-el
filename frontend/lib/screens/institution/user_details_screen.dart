import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/task.dart';
import '../../repositories/institution_repo.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  User? _user;
  List<Task>? _tasks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(institutionRepoProvider);
      final user = await repo.getUserById(widget.userId);
      final tasks = await repo.getUserHistory(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _tasks = tasks..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _softDeleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Pasife Al'),
        content: const Text(
            'Bu kullanıcıyı pasife almak istediğinize emin misiniz? Kullanıcı sisteme giriş yapamayacaktır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pasife Al', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(institutionRepoProvider).deleteUserById(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı pasife alındı.')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showEditSheet() {
    if (_user == null) return;
    
    final firstNameCtrl = TextEditingController(text: _user!.firstName);
    final lastNameCtrl = TextEditingController(text: _user!.lastName);
    final phoneCtrl = TextEditingController(text: _user!.phoneNumber);
    final addressCtrl = TextEditingController(text: _user!.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Kullanıcıyı Düzenle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Ad', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Soyad', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Adres', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(institutionRepoProvider).updateUserById(
                      widget.userId,
                      {
                        'firstName': firstNameCtrl.text.trim(),
                        'lastName': lastNameCtrl.text.trim(),
                        'phoneNumber': phoneCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        // Backend might expect more but let's provide basic fields
                      },
                    );
                    _loadData();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text('Kaydet', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kullanıcı Detayları')),
        body: const Center(child: Text('Kullanıcı bulunamadı.')),
      );
    }

    final isStudent = user.role == Role.STUDENT;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Kullanıcı Detayları', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4B5563)),
            onPressed: _showEditSheet,
            tooltip: 'Düzenle',
          ),
          if (user.isActive)
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: _softDeleteUser,
              tooltip: 'Pasife Al',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isStudent ? Colors.blue.shade100 : Colors.green.shade100,
                    child: Icon(
                      isStudent ? Icons.school : Icons.person,
                      size: 40,
                      color: isStudent ? Colors.blue.shade600 : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isActive ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.email_outlined, 'E-posta', user.email ?? '-'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.phone_outlined, 'Telefon', user.phoneNumber ?? '-'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.location_on_outlined, 'Adres', user.address ?? '-'),
                  if (user.iban != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(Icons.account_balance_outlined, 'IBAN', user.iban!),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Görev Geçmişi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ),
          ),
          if (_tasks == null || _tasks!.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Kullanıcının görev geçmişi yok.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = _tasks![index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(task.status.colorValue).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTaskIcon(task.status),
                          color: Color(task.status.colorValue),
                        ),
                      ),
                      title: Text(
                        task.status.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Alınacaklar: ${task.shoppingList.join(", ")}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (task.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Oluşturulma: ${task.createdAt!.toLocal().toString().split(".")[0]}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: _tasks!.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getTaskIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.PENDING:
        return Icons.hourglass_empty;
      case TaskStatus.ASSIGNED:
        return Icons.person;
      case TaskStatus.IN_PROGRESS:
        return Icons.shopping_cart;
      case TaskStatus.DELIVERED:
        return Icons.local_shipping;
      case TaskStatus.COMPLETED:
        return Icons.check_circle;
      case TaskStatus.CANCELLED:
        return Icons.cancel;
    }
  }
}
