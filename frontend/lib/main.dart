import 'package:flutter/material.dart';
import 'package:tdp_frontend/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genç El',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(selectedType: 'elderly'),
    );
  }
}
