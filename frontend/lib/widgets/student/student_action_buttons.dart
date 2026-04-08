import 'package:flutter/material.dart';

/// Öğrenci ana sayfasının alt buton alanı.
/// "Geçmiş Siparişler" her zaman görünür; aktif görev varken yeni görev butonu gizlenir.
class StudentActionButtons extends StatelessWidget {
  const StudentActionButtons({super.key, required this.onViewHistory});

  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Geçmiş siparişler
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewHistory,
            icon: const Icon(Icons.history_rounded, size: 20),
            label: const Text('Geçmiş Görevler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF93C5FD), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
