import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repo.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/institution_login_screen.dart';
import '../../screens/elderly/elderly_home_screen.dart';
import '../../screens/student/student_home_screen.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/web_socket_service.dart';
import '../../services/location_service.dart';

/// Kullanıcı tipini (ELDERLY / STUDENT) seçip
/// e-posta ve şifre bilgileriyle giriş yapılan form.
/// Backend'e gerçek API çağrısı yapar.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedUserType = 'elderly'; // 'elderly' | 'student'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);

      // Backend'e login isteği gönder
      final response = await authRepo.userLogin(email, password);

      // Token ve bilgileri kaydet
      final token = response['token'] as String;
      final role = response['role'] as String;
      final responseEmail = response['email'] as String;

      await storageService.saveToken(token);
      await storageService.saveRole(role);
      await storageService.saveEmail(responseEmail);
      
      // Also save IDs for WebSocket/Tracking
      if (response['userId'] != null) {
        await storageService.saveUserId(response['userId'].toString());
      }
      if (response['institutionId'] != null) {
        await storageService.saveInstitutionId(
          response['institutionId'].toString(),
        );
      }

      // Connect Realtime Services
      ref.read(webSocketServiceProvider).connect();
      ref.read(locationServiceProvider).startTrackingIfStudent();

      if (!mounted) return;

      // Rol kontrolü — seçilen tip ile backend'den dönen rol uyumlu mu?
      if (_selectedUserType == 'elderly' && role == 'ELDERLY') {
        _showSuccessAndNavigate(
          'Yaşlı olarak giriş yapılıyor…',
          const Color(0xFF16A34A),
          const ElderlyHomeScreen(),
        );
      } else if (_selectedUserType == 'student' && role == 'STUDENT') {
        _showSuccessAndNavigate(
          'Öğrenci olarak giriş yapılıyor…',
          Colors.blue,
          const StudentHomeScreen(),
        );
      } else if (role == 'ELDERLY') {
        // Kullanıcı doğru tipte giriş yapmadıysa (ama hesap geçerli), yönlendir
        _showSuccessAndNavigate(
          'Yaşlı olarak giriş yapılıyor…',
          const Color(0xFF16A34A),
          const ElderlyHomeScreen(),
        );
      } else if (role == 'STUDENT') {
        _showSuccessAndNavigate(
          'Öğrenci olarak giriş yapılıyor…',
          Colors.blue,
          const StudentHomeScreen(),
        );
      } else {
        _showError('Bu hesap tipi bu ekrandan giriş yapamaz.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessAndNavigate(String message, Color color, Widget screen) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserTypeSelector(
            selectedType: _selectedUserType,
            onChanged: (type) {
              setState(() {
                _selectedUserType = type;
              });
            },
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'E-posta',
            hintText: 'ornek@example.com',
            prefixIcon: Icons.mail_outline,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-posta boş bırakılamaz';
              }
              if (!value.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Şifre',
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordController,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre boş bırakılamaz';
              }
              if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: _selectedUserType == 'elderly'
                  ? const Color(0xFF16A34A)
                  : Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Giriş Yap'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstitutionLoginScreen(),
                ),
              );
            },
            child: const Text(
              'Kurum Girişi için Tıklayın',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kullanıcı tipi seçici — Yaşlı / Öğrenci toggle
// ---------------------------------------------------------------------------
class _UserTypeSelector extends StatelessWidget {
  const _UserTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // gray-100
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabButton(
            selectedType: selectedType,
            label: '🧓  Yaşlı / Engelli',
            isSelected: selectedType == 'elderly',
            onTap: () => onChanged('elderly'),
          ),
          _TabButton(
            selectedType: selectedType,
            label: '🎓  Öğrenci',
            isSelected: selectedType == 'student',
            onTap: () => onChanged('student'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedType,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String selectedType;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? selectedType == 'elderly'
                        ? const Color(0xFF16A34A)
                        : Colors.blue
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
