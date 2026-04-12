import 'package:flutter/material.dart';

/// Öğrenci ana sayfasının üst karşılama bölümü.
/// Adı, toplam tamamlanan görev sayısını ve kısa motivasyon metnini gösterir.
class StudentGreetingHeader extends StatelessWidget {
  const StudentGreetingHeader({
    super.key,
    required this.studentName,
    this.completedCount = 0,
  });

  final String studentName;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFF2563EB),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),

        // Metin
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, $studentName 👋',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                completedCount == 0
                    ? 'Henüz görev tamamlamadın.'
                    : '$completedCount görev tamamladın 🎉',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B6E93)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
