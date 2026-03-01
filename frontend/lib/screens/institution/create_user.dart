import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/create_user_request.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/repositories/institution_repo.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  Role _selectedRole = Role.STUDENT;
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  String _password = '';
  String? _address;
  String? _iban;

  var _isSaving = false;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    try {
      final request = CreateUserRequest(
        role: _selectedRole,
        firstName: _firstName,
        lastName: _lastName,
        phoneNumber: _phoneNumber,
        email: _email,
        password: _password,
        address: _address?.isNotEmpty == true ? _address : null,
        iban: _selectedRole == Role.STUDENT && _iban?.isNotEmpty == true
            ? _iban
            : null,
      );
      print(request.toString());
      await ref.read(institutionRepoProvider).createUser(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully.')),
        );
        Navigator.of(context).pop(); // Go back to admin screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Role>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [Role.STUDENT, Role.ELDERLY].map((Role role) {
                  return DropdownMenuItem(value: role, child: Text(role.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                },
                onSaved: (value) => _firstName = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                },
                onSaved: (value) => _lastName = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                },
                onSaved: (value) => _phoneNumber = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  // Simple regex matching the backend pattern
                  if (!RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
                  ).hasMatch(value)) {
                    return 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                ),
                maxLines: 2,
                onSaved: (value) => _address = value,
              ),
              if (_selectedRole == Role.STUDENT) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'IBAN (Optional)',
                  ),
                  onSaved: (value) => _iban = value,
                ),
              ],
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Create User'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
