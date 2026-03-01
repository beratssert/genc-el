import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/screens/auth/institution_login.dart';
import 'package:tdp_frontend/screens/beneficiary/beneficiary_main_screen.dart';
import 'package:tdp_frontend/screens/institution/admin_screen.dart';
import 'package:tdp_frontend/screens/student/student_screen.dart';
import 'package:tdp_frontend/services/storage_service.dart';
import 'package:tdp_frontend/shared/theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// A provider that checks if the user is already logged in
/// Parses the token and the saved role
final authInitProvider = FutureProvider<String?>((ref) async {
  final storageService = ref.read(storageServiceProvider);
  final token = await storageService.getToken();
  if (token != null && token.isNotEmpty) {
    final role = await storageService.getRole();
    return role;
  }
  return null;
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authInitAsync = ref.watch(authInitProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: authInitAsync.when(
        data: (roleString) {
          if (roleString == Role.INSTITUTION_ADMIN.name) {
            return const AdminScreen();
          } else if (roleString == Role.STUDENT.name) {
            return const StudentScreen();
          } else if (roleString == Role.ELDERLY.name) {
            return const BeneficiaryMainScreen();
          } else {
            return const InstituionLogin();
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => const InstituionLogin(),
      ),
    );
  }
}
