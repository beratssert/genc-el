import 'package:flutter/material.dart';
import 'labeled_text_field.dart';

/// Kullanıcı tipini (ELDERLY / STUDENT) seçip
/// e-posta ve şifre bilgileriyle giriş yapılan form.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedUserType = 'elderly'; // 'elderly' | 'student'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Gerçek auth servisiyle bağla
    if (_selectedUserType == 'elderly') {
      // Navigator.pushReplacementNamed(context, '/elderly/dashboard');
    } else {
      // Navigator.pushReplacementNamed(context, '/student/dashboard');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedUserType == 'elderly' ? 'Yaşlı' : 'Öğrenci'} olarak giriş yapılıyor…',
        ),
        backgroundColor: const Color(0xFF16A34A),
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
            onChanged: (type) => setState(() => _selectedUserType = type),
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label: 'E-posta',
            hintText: 'ornek@mail.com',
            prefixIcon: Icons.phone_outlined,
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
          LabeledTextField(
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
            onPressed: _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
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
            child: const Text('Giriş Yap'),
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
            label: '🧓  Yaşlı / Engelli',
            isSelected: selectedType == 'elderly',
            onTap: () => onChanged('elderly'),
          ),
          _TabButton(
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

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
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
