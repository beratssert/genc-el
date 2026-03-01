import 'package:flutter/material.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7), // green-100
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 40,
            color: Color(0xFF16A34A), // green-600
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kullanıcı Girişi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827), // gray-900
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hesabınıza giriş yapın',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280), // gray-500
          ),
        ),
      ],
    );
  }
}
