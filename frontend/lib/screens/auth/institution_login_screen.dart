import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import '../institution/institution_dashboard_screen.dart';

class InstitutionLoginScreen extends StatefulWidget {
  const InstitutionLoginScreen({super.key});

  @override
  State<InstitutionLoginScreen> createState() => _InstitutionLoginScreenState();
}

class _InstitutionLoginScreenState extends State<InstitutionLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InstitutionDashboardScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // bg-gradient-to-br from-indigo-50 to-blue-100
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF2FF), // indigo-50
              Color(0xFFDBEAFE), // blue-100
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              // max-w-md
              constraints: const BoxConstraints(maxWidth: 448),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  // p-8
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      // text-center mb-8
                      Column(
                        children: [
                          // inline-flex items-center justify-center w-16 h-16 bg-indigo-100 rounded-full mb-4
                          Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0E7FF), // indigo-100
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.business,
                              size: 32,
                              color: Color(0xFF4F46E5), // indigo-600
                            ),
                          ),
                          // text-2xl font-bold text-gray-900 mb-2
                          const Text(
                            'Kurum Girişi',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          const SizedBox(height: 8),
                          // text-gray-600
                          const Text(
                            'Yönetim paneline erişim',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4B5563), // gray-600
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Form Section (space-y-6)
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              label: 'E-posta',
                              hintText: 'kurum@ornek.com',
                              prefixIcon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              userType: 'institution',
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              label: 'Şifre',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              userType: 'institution',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF4F46E5,
                                  ), // indigo-600
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Giriş Yap',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
