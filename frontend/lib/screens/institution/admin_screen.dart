import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/screens/auth/institution_login.dart';
import 'package:tdp_frontend/screens/institution/create_user.dart';
import 'package:tdp_frontend/screens/institution/members_list.dart';
import 'package:tdp_frontend/services/storage_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    final storageService = ref.read(storageServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Screen'),
        actions: [
          IconButton(
            onPressed: () {
              storageService.clearAll();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const InstituionLogin(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateUserScreen(),
                  ),
                );
              },
              child: const Text('Create User'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MembersListScreen(),
                  ),
                );
              },
              child: const Text('Members List'),
            ),
          ],
        ),
      ),
    );
  }
}
