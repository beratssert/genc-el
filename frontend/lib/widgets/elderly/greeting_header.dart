import 'package:flutter/material.dart';

/// Sayfanın üstündeki kişiselleştirilmiş karşılama bölümü.
/// Kullanıcı adını ve tarih/saati gösterir.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.userName});

  final String userName;

  /// Saate göre uygun selamlama metnini döndürür.
  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7), // green-100
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 28,
            color: Color(0xFF16A34A), // green-600
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greetingText,',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // gray-500
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // gray-900
              ),
            ),
          ],
        ),
      ],
    );
  }
}
