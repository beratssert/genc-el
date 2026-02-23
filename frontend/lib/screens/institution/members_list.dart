import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/repositories/institution_repo.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  @override
  Widget build(BuildContext context) {
    final membersList = ref.watch(institutionRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Members List')),
      body: FutureBuilder(
        future: membersList.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final users = snapshot.data!;
            if (users.isEmpty) {
              return const Center(child: Text('No members found.'));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final member = users[index];
                return Card(
                  child: ListTile(
                    title: Text('${member['firstName']} ${member['lastName']}'),
                    subtitle: Text(member['email'] ?? 'No detail'),
                    trailing: Text(member['role']),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
