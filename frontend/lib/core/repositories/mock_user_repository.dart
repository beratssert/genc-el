import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class MockUserRepository {
  static final MockUserRepository _instance = MockUserRepository._internal();
  factory MockUserRepository() => _instance;
  MockUserRepository._internal();

  final List<Map<String, dynamic>> recentUsers = [
    {'name': 'Ahmet Yılmaz', 'type': 'Öğrenci', 'date': 'Bugün'},
    {'name': 'Ayşe Yılmaz', 'type': 'Yaşlı/Engelli', 'date': 'Bugün'},
    {'name': 'Mehmet Demir', 'type': 'Yaşlı/Engelli', 'date': 'Dün'},
  ];

  TaskModel? activeTask;
  final _taskController = StreamController<TaskModel?>.broadcast();
  Stream<TaskModel?> get taskStream => _taskController.stream;

  void updateActiveTask(TaskModel? task) {
    activeTask = task;
    _taskController.add(task);
  }

  void dispose() {
    _taskController.close();
  }

  final List<Map<String, dynamic>> elderlyUsers = [
    {
      'id': 1,
      'name': 'Ayşe Yılmaz',
      'phone': '0532 123 45 67',
      'address': 'Çankaya, Ankara',
      'activeOrders': 0,
    },
    {
      'id': 2,
      'name': 'Mehmet Demir',
      'phone': '0533 234 56 78',
      'address': 'Keçiören, Ankara',
      'activeOrders': 1,
    },
    {
      'id': 3,
      'name': 'Fatma Kaya',
      'phone': '0534 345 67 89',
      'address': 'Mamak, Ankara',
      'activeOrders': 0,
    },
    {
      'id': 4,
      'name': 'Ali Çelik',
      'phone': '0535 456 78 90',
      'address': 'Yenimahalle, Ankara',
      'activeOrders': 0,
    },
    {
      'id': 5,
      'name': 'Zeynep Arslan',
      'phone': '0536 567 89 01',
      'address': 'Etimesgut, Ankara',
      'activeOrders': 0,
    },
  ];

  final List<Map<String, dynamic>> studentUsers = [
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

  void addElderlyUser(Map<String, dynamic> user) {
    user['id'] = elderlyUsers.length + 1;
    if (!user.containsKey('activeOrders')) {
      user['activeOrders'] = 0;
    }
    elderlyUsers.insert(0, user);

    recentUsers.insert(0, {
      'name': user['name'],
      'type': 'Yaşlı/Engelli',
      'date': 'Şimdi',
    });
  }

  void addStudentUser(Map<String, dynamic> user) {
    user['id'] = studentUsers.length + 1;
    if (!user.containsKey('completedOrders')) {
      user['completedOrders'] = 0;
    }
    if (!user.containsKey('university')) {
      user['university'] = 'Bilinmeyen Üniversite';
    }
    studentUsers.insert(0, user);

    recentUsers.insert(0, {
      'name': user['name'],
      'type': 'Öğrenci',
      'date': 'Şimdi',
    });
  }
}
