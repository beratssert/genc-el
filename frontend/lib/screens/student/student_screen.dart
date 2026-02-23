import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/screens/auth/auth_screen.dart';
import 'package:tdp_frontend/services/storage_service.dart';

class StudentScreen extends ConsumerStatefulWidget {
  const StudentScreen({super.key});

  @override
  ConsumerState<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends ConsumerState<StudentScreen> {
  @override
  Widget build(BuildContext context) {
    final storageService = ref.read(storageServiceProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              storageService.clearAll();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: Text('Student Screen')),
    );
  }
}
