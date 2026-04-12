import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/create_user_request.dart';
import '../../models/user.dart';
import '../../repositories/institution_repo.dart';
import '../../widgets/custom_text_field.dart';

enum UserType { elderly, student }

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _selectedType = UserType.elderly;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final institutionRepo = ref.read(institutionRepoProvider);

      final request = CreateUserRequest(
        role: _selectedType == UserType.elderly ? Role.ELDERLY : Role.STUDENT,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        iban: _selectedType == UserType.student &&
                _ibanController.text.trim().isNotEmpty
            ? _ibanController.text.trim()
            : null,
      );

      await institutionRepo.createUser(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kullanıcı başarıyla oluşturuldu!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF2FF),
              Color(0xFFF3E8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Kullanıcı',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'Kullanıcı bilgilerini girin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // User Type Header
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE0E7FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_add_outlined,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kullanıcı Tipi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          'Eklenecek kullanıcı türünü seçin',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Segment Button
                              SegmentedButton<UserType>(
                                segments: const [
                                  ButtonSegment(
                                    value: UserType.elderly,
                                    label: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text('Yaşlı / Engelli'),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: UserType.student,
                                    label: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text('Öğrenci'),
                                    ),
                                  ),
                                ],
                                selected: {_selectedType},
                                onSelectionChanged:
                                    (Set<UserType> newSelection) {
                                  setState(() {
                                    _selectedType = newSelection.first;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return Colors.white;
                                      }
                                      return const Color(0xFFF3F4F6);
                                    },
                                  ),
                                  side: WidgetStateProperty.all(
                                    const BorderSide(
                                        color: Color(0xFFE5E7EB)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Ad
                                    CustomTextField(
                                      label: 'Ad',
                                      hintText: 'Örn: Ayşe',
                                      prefixIcon: Icons.person_outline,
                                      controller: _firstNameController,
                                      keyboardType: TextInputType.name,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Ad zorunlu'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    // Soyad
                                    CustomTextField(
                                      label: 'Soyad',
                                      hintText: 'Örn: Yılmaz',
                                      prefixIcon: Icons.person_outline,
                                      controller: _lastNameController,
                                      keyboardType: TextInputType.name,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Soyad zorunlu'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    // Telefon
                                    CustomTextField(
                                      label: 'Telefon Numarası',
                                      hintText: '0532 123 45 67',
                                      prefixIcon: Icons.phone_outlined,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Telefon zorunlu'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    // E-posta
                                    CustomTextField(
                                      label: 'E-posta',
                                      hintText: 'ornek@email.com',
                                      prefixIcon: Icons.email_outlined,
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'E-posta zorunlu';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Geçerli bir e-posta girin';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Adres
                                    CustomTextField(
                                      label: 'Adres',
                                      hintText: 'Tam adres giriniz',
                                      prefixIcon: Icons.location_on_outlined,
                                      controller: _addressController,
                                      minLines: 2,
                                      maxLines: 4,
                                      keyboardType:
                                          TextInputType.multiline,
                                    ),
                                    const SizedBox(height: 16),
                                    // IBAN (sadece öğrenci)
                                    if (_selectedType == UserType.student) ...[
                                      CustomTextField(
                                        label: 'IBAN',
                                        hintText: 'TR...',
                                        prefixIcon:
                                            Icons.account_balance_outlined,
                                        controller: _ibanController,
                                        keyboardType: TextInputType.text,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // Şifre
                                    CustomTextField(
                                      label: 'Geçici Şifre',
                                      hintText:
                                          'Min 8 karakter, 1 büyük, 1 küçük, 1 rakam',
                                      prefixIcon: Icons.lock_outline,
                                      controller: _passwordController,
                                      obscureText: true,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Şifre zorunlu';
                                        }
                                        if (v.length < 8) {
                                          return 'Şifre en az 8 karakter olmalı';
                                        }
                                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                          return 'En az 1 büyük harf gerekli';
                                        }
                                        if (!RegExp(r'[a-z]').hasMatch(v)) {
                                          return 'En az 1 küçük harf gerekli';
                                        }
                                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                                          return 'En az 1 rakam gerekli';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Butonlar
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Kullanıcı Oluştur',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF111827),
                                          side: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'İptal',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
