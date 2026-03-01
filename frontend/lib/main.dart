import 'package:flutter/material.dart';
import 'package:tdp_frontend/screens/student/student_home_screen.dart';

import 'core/models/task_model.dart';

void main() {
  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Demo aktif sipariş — ana sayfada görmek için
// ---------------------------------------------------------------------------
final _demoActiveTask = TaskModel(
  id: 99,
  status: TaskStatus.shopping, // Öğrenci kabul etti, yolda
  createdAt: DateTime(2026, 3, 1, 15, 55),
  volunteerName: 'Berat Yılmaz',
  totalAmountGiven: 200,
  shoppingList: const [
    ShoppingItem(name: 'Ekmek', qty: 2, unit: 'Adet'),
    ShoppingItem(name: 'Süt', qty: 2, unit: 'Lt'),
    ShoppingItem(name: 'Yumurta', qty: 1, unit: 'Koli'),
    ShoppingItem(name: 'Peynir', qty: 250, unit: 'gr'),
  ],
  note: 'Zili çalmayın, kapıyı tıklatın.',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genç El',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const StudentHomeScreen(
        studentName: 'Ahmet',
        completedTaskCount: 7,
        activeTask: null,
      ),
    );
  }
}
