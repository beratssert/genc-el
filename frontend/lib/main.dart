import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/screens/auth/login_screen.dart';
import 'package:tdp_frontend/screens/elderly/elderly_home_screen.dart';
import 'package:tdp_frontend/screens/institution/institution_dashboard_screen.dart';
import 'package:tdp_frontend/screens/student/student_home_screen.dart';
import 'package:tdp_frontend/services/location_service.dart';
import 'package:tdp_frontend/services/storage_service.dart';
import 'package:tdp_frontend/services/web_socket_service.dart';
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

    // Initialize Realtime services if authenticated
    authInitAsync.whenData((roleString) {
      if (roleString != null) {
        ref.read(webSocketServiceProvider).connect();
        ref.read(locationServiceProvider).startTrackingIfStudent();
      }
    });

    return MaterialApp(
      title: 'Genç El',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: authInitAsync.when(
        data: (roleString) {
          if (roleString == Role.INSTITUTION_ADMIN.name) {
            return const InstitutionDashboardScreen();
          } else if (roleString == Role.STUDENT.name) {
            return const StudentHomeScreen();
          } else if (roleString == Role.ELDERLY.name) {
            return const ElderlyHomeScreen();
          } else {
            return LoginScreen(selectedType: 'elderly');
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => LoginScreen(selectedType: 'elderly'),
      ),
    );
  }
}
