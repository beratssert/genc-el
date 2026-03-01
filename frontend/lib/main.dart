import 'package:flutter/material.dart';
import 'package:tdp_frontend/screens/elderly/elderly_home_screen.dart';
import 'package:tdp_frontend/screens/institution/institution_dashboard_screen.dart';
import 'core/models/task_model.dart';

void main() {
  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// Demo verisi — backend bağlandığında bu silinir
// ---------------------------------------------------------------------------
final _demoCompletedTasks = [
  TaskModel(
    id: 1,
    status: TaskStatus.completed,
    createdAt: DateTime(2026, 3, 1, 10, 15),
    volunteerName: 'Berat Yılmaz',
    totalAmountGiven: 160,
    shoppingCost: 156,
    changeAmount: 4,
    shoppingList: const [
      ShoppingItem(name: 'Ekmek', qty: 2, unit: 'Adet'),
      ShoppingItem(name: 'Süt', qty: 2, unit: 'Lt'),
      ShoppingItem(name: 'Yumurta', qty: 1, unit: 'Koli'),
    ],
    note: 'Zili çalmayın, kapıyı tıklatın.',
  ),
  TaskModel(
    id: 2,
    status: TaskStatus.completed,
    createdAt: DateTime(2026, 2, 25, 14, 30),
    volunteerName: 'Ayşe Kaya',
    totalAmountGiven: 100,
    shoppingCost: 83,
    changeAmount: 17,
    shoppingList: const [
      ShoppingItem(name: 'Peynir', qty: 250, unit: 'gr'),
      ShoppingItem(name: 'Zeytin', qty: 1, unit: 'Kg'),
      ShoppingItem(name: 'Domates', qty: 1, unit: 'Kg'),
    ],
  ),
  TaskModel(
    id: 3,
    status: TaskStatus.cancelled,
    createdAt: DateTime(2026, 2, 20, 9, 0),
    shoppingList: const [
      ShoppingItem(name: 'Makarna', qty: 3, unit: 'Paket'),
      ShoppingItem(name: 'Salça', qty: 1, unit: 'Kutu'),
    ],
    note: 'Uygun öğrenci bulunamadı.',
  ),
  TaskModel(
    id: 4,
    status: TaskStatus.completed,
    createdAt: DateTime(2026, 2, 15, 16, 45),
    volunteerName: 'Mehmet Demir',
    totalAmountGiven: 250,
    shoppingCost: 218,
    changeAmount: 32,
    shoppingList: const [
      ShoppingItem(name: 'Tavuk', qty: 1, unit: 'Kg'),
      ShoppingItem(name: 'Pirinç', qty: 2, unit: 'Kg'),
      ShoppingItem(name: 'Yağ', qty: 1, unit: 'Lt'),
      ShoppingItem(name: 'Tuz', qty: 1, unit: 'Paket'),
    ],
  ),
  TaskModel(
    id: 5,
    status: TaskStatus.completed,
    createdAt: DateTime(2026, 2, 10, 11, 20),
    volunteerName: 'Zeynep Arslan',
    totalAmountGiven: 150,
    shoppingCost: 134,
    changeAmount: 16,
    shoppingList: const [
      ShoppingItem(name: 'Portakal', qty: 2, unit: 'Kg'),
      ShoppingItem(name: 'Elma', qty: 1, unit: 'Kg'),
      ShoppingItem(name: 'Muz', qty: 1, unit: 'Kg'),
    ],
  ),
];

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
      home: ElderlyHomeScreen(completedTasks: _demoCompletedTasks),
    );
  }
}
