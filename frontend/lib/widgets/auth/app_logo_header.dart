import 'package:flutter/material.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({super.key, required this.selectedType});

  final String selectedType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: selectedType == 'elderly'
                ? const Color(0xFFDCFCE7)
                : Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            selectedType == 'elderly'
                ? Icons.person_outline_rounded
                : Icons.school_outlined,
            size: 40,
            color: selectedType == 'elderly'
                ? const Color(0xFF16A34A)
                : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          selectedType == 'elderly'
              ? 'İhtiyaç Sahibi Girişi'
              : 'Öğrenci Girişi',
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
