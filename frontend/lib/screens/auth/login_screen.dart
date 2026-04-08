import 'package:flutter/material.dart';
import '../../widgets/auth/app_logo_header.dart';
import '../../widgets/auth/login_form.dart';

/// Yaşlı/Engelli ve Öğrenci kullanıcılarının aynı ekrandan
/// giriş yapabildiği kimlik doğrulama sayfası.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.selectedType});

  final String selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Figma tasarımına uygun gradient arka plan (green-50 → emerald-100)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // green-50
              Color(0xFFD1FAE5), // emerald-100
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogoHeader(selectedType: selectedType),
                    SizedBox(height: 32),
                    LoginForm(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
