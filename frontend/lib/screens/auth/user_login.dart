import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/repositories/auth_repo.dart';
import 'package:tdp_frontend/screens/auth/institution_login.dart';
import 'package:tdp_frontend/screens/beneficiary/beneficiary_main_screen.dart';
import 'package:tdp_frontend/screens/student/student_screen.dart';
import 'package:tdp_frontend/services/storage_service.dart';

class UserLogin extends ConsumerStatefulWidget {
  const UserLogin({super.key});

  @override
  ConsumerState<UserLogin> createState() {
    return _UserLoginState();
  }
}

class _UserLoginState extends ConsumerState<UserLogin> {
  final _form = GlobalKey<FormState>();

  var _enteredEmail = '';
  var _enteredPassword = '';
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      // show error message ...
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });

      // Call auth repository
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.userLogin(
        _enteredEmail,
        _enteredPassword,
      );

      // Save token and role if available
      final storageService = ref.read(storageServiceProvider);

      // Expected backend response structure: {"token": "...", "role": "..."}
      // Or similar. We will save what we can find.
      if (response['token'] != null) {
        await storageService.saveToken(response['token']);
      } else if (response['accessToken'] != null) {
        await storageService.saveToken(response['accessToken']);
      }

      if (response['role'] != null) {
        await storageService.saveRole(response['role'].toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
      }

      final roleString = response['role']?.toString();

      if (roleString == Role.STUDENT.name) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentScreen()),
        );
      } else if (roleString == Role.ELDERLY.name) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BeneficiaryMainScreen(),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('user login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const InstituionLogin(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }

                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 3) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                              child: const Text('Login'),
                            ),
                        ],
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
