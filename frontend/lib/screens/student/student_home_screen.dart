import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import '../../widgets/student/student_greeting_header.dart';
import '../../widgets/student/availability_card.dart';
import '../../widgets/student/student_task_card.dart';
import '../../widgets/student/student_action_buttons.dart';
import '../../widgets/student/incoming_order_sheet.dart';
import '../../core/repositories/mock_user_repository.dart';
import 'student_order_history_screen.dart';

/// Öğrenci kullanıcısının ana ekranı.
///
/// Özellikler:
/// - Mavi gradient arka plan (yaşlı ekranında yeşil kullanılmıştı)
/// - Müsaitlik toggle (aktif/deaktif)
/// - Atanmış aktif görev kartı veya bekleme durumu
/// - Gelen sipariş bildirimi: [showIncomingOrderSheet] ile tam ekran modal
/// - Alt kısımda geçmiş siparişler butonu
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    this.studentName = 'Ahmet',
    this.activeTask,
    this.completedTaskCount = 0,
    this.completedTasks,
  });

  final String studentName;
  final TaskModel? activeTask;
  final int completedTaskCount;
  final List<TaskModel>? completedTasks;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final MockUserRepository _userRepo = MockUserRepository();
  bool _isAvailable = true;
  TaskModel? _currentActiveTask;

  @override
  void initState() {
    super.initState();
    _currentActiveTask = _userRepo.activeTask ?? widget.activeTask;

    // Listen for incoming orders
    _userRepo.taskStream.listen((task) {
      if (mounted) {
        setState(() {
          _currentActiveTask = task;
        });

        // Show incoming order sheet if a pending task arrives and student is available
        if (task != null && task.status == TaskStatus.pending && _isAvailable) {
          _showIncomingOrderSheet(task);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Demo: gelen sipariş göster
  // ---------------------------------------------------------------------------
  static const _demoOrder = IncomingOrder(
    id: 42,
    elderlyName: 'Ayşe Hanım',
    distanceKm: 1.2,
    estimatedMinutes: 20,
    note: 'Zili çalmayın, kapıyı tıklatın.',
    shoppingList: [
      ShoppingItem(name: 'Ekmek', qty: 2, unit: 'Adet'),
      ShoppingItem(name: 'Süt', qty: 2, unit: 'Lt'),
      ShoppingItem(name: 'Yumurta', qty: 1, unit: 'Koli'),
      ShoppingItem(name: 'Peynir', qty: 250, unit: 'gr'),
      ShoppingItem(name: 'Domates', qty: 1, unit: 'Kg'),
    ],
  );

  // ---------------------------------------------------------------------------
  // Demo geçmiş sipariş verisi (Sadece UI testi için)
  // ---------------------------------------------------------------------------
  static final _demoCompletedTasks = [
    TaskModel(
      id: 101,
      status: TaskStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      elderlyName: 'Mehmet Demir',
      shoppingCost: 185,
      totalAmountGiven: 200,
      changeAmount: 15,
      shoppingList: const [
        ShoppingItem(name: 'Yoğurt', qty: 1, unit: 'Kg'),
        ShoppingItem(name: 'Elma', qty: 2, unit: 'Kg'),
        ShoppingItem(name: 'Ekmek', qty: 3, unit: 'Adet'),
      ],
    ),
    TaskModel(
      id: 102,
      status: TaskStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      elderlyName: 'Fatma Kaya',
      shoppingCost: 320,
      totalAmountGiven: 400,
      changeAmount: 80,
      shoppingList: const [
        ShoppingItem(name: 'Tavuk', qty: 1, unit: 'Kg'),
        ShoppingItem(name: 'Pirinç', qty: 2, unit: 'Kg'),
        ShoppingItem(name: 'Sıvı Yağ', qty: 1, unit: 'Lt'),
      ],
    ),
    TaskModel(
      id: 103,
      status: TaskStatus.cancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      elderlyName: 'Leyla Aydın',
      shoppingList: const [
        ShoppingItem(name: 'İlaç (Parol)', qty: 1, unit: 'Kutu'),
      ],
      note: 'Eczane kapalıydı, iptal edildi.',
    ),
  ];

  void _showIncomingOrderSheet(TaskModel task) {
    // Demo verisini gerçek task objesinden dönüştürüyoruz
    final incomingOrder = IncomingOrder(
      id: task.id,
      elderlyName: task.elderlyName ?? 'Bilinmeyen Müşteri',
      distanceKm: 1.2,
      estimatedMinutes: 20,
      note: task.note,
      shoppingList: task.shoppingList,
    );

    showIncomingOrderSheet(
      context,
      order: incomingOrder,
      onAccepted: () {
        // Update task status and broadcast
        final acceptedTask = TaskModel(
          id: task.id,
          status: TaskStatus.assigned,
          shoppingList: task.shoppingList,
          createdAt: task.createdAt,
          volunteerName: widget.studentName,
          elderlyName: task.elderlyName,
          note: task.note,
        );
        _userRepo.updateActiveTask(acceptedTask);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Sipariş kabul edildi! Göreve git.'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      onRejected: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Sipariş reddedildi.'),
            backgroundColor: const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveTask = widget.activeTask != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFDBEAFE), // blue-100
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- 1. Karşılama ---
                StudentGreetingHeader(
                  studentName: widget.studentName,
                  completedCount: widget.completedTaskCount,
                ),
                const SizedBox(height: 24),

                // --- 2. Müsaitlik Toggle ---
                AvailabilityCard(
                  isAvailable: _isAvailable,
                  isTaskActive: hasActiveTask,
                  onToggle: (value) => setState(() => _isAvailable = value),
                ),
                const SizedBox(height: 24),

                // --- 3. Aktif Görev Kartı ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StudentTaskCard(
                          activeTask: _currentActiveTask,
                          isAvailable: _isAvailable,
                        ),

                        // Gerçek task test butonu
                        if (!hasActiveTask && _isAvailable) ...[
                          const SizedBox(height: 24),
                          _DemoTriggerButton(
                            onTap: () {
                              _showIncomingOrderSheet(
                                TaskModel(
                                  id: _demoOrder.id,
                                  status: TaskStatus.pending,
                                  createdAt: DateTime.now(),
                                  elderlyName: _demoOrder.elderlyName,
                                  shoppingList: _demoOrder.shoppingList,
                                  note: _demoOrder.note,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // --- 4. Alt Butonlar ---
                const SizedBox(height: 12),
                StudentActionButtons(
                  onViewHistory: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentOrderHistoryScreen(
                          completedTasks:
                              widget.completedTasks ?? _demoCompletedTasks,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo tetikleyici — sadece geliştirme sürecinde kullanılır
// ---------------------------------------------------------------------------
class _DemoTriggerButton extends StatelessWidget {
  const _DemoTriggerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF93C5FD),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notification_add_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            SizedBox(width: 8),
            Text(
              'Demo: Sipariş Bildirimi Simüle Et',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
