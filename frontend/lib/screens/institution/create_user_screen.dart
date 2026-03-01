import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';

enum UserType { elderly, student }

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _selectedType = UserType.elderly;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı başarıyla oluşturuldu!')),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEEF2FF), // indigo-50
                Color(0xFFF3E8FF), // purple-100
              ],
            ),
          ),
          child: Column(
            children: [
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

                              // Segment Button for User Type
                              SegmentedButton<UserType>(
                                segments: const [
                                  ButtonSegment(
                                    value: UserType.elderly,
                                    label: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text('Yaşlı / Engelli'),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: UserType.student,
                                    label: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                      WidgetStateProperty.resolveWith<Color>((
                                        Set<WidgetState> states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.selected,
                                        )) {
                                          return Colors.white;
                                        }
                                        return const Color(
                                          0xFFF3F4F6,
                                        ); // gray-100
                                      }),
                                  side: WidgetStateProperty.all(
                                    const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ), // gray-200
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    CustomTextField(
                                      label: 'Ad Soyad',
                                      hintText: 'Örn: Ayşe Yılmaz',
                                      prefixIcon: Icons.person_outline,
                                      controller: _nameController,
                                      keyboardType: TextInputType.name,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      label: 'Telefon Numarası',
                                      hintText: '0532 123 45 67',
                                      prefixIcon: Icons.phone_outlined,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      label: 'E-posta',
                                      hintText: 'ornek@email.com',
                                      prefixIcon: Icons.email_outlined,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      label: 'Adres',
                                      hintText: 'Tam adres giriniz',
                                      prefixIcon: Icons.location_on_outlined,
                                      controller: _addressController,
                                      minLines: 3,
                                      maxLines: 5,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      label: 'Geçici Şifre',
                                      hintText: 'İlk giriş şifresi',
                                      prefixIcon: Icons.lock_outline,
                                      controller: _passwordController,
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 24),

                                    // Buttons
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF4F46E5,
                                          ), // gray-900
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
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
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF111827,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
