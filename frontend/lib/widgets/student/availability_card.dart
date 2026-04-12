import 'package:flutter/material.dart';

/// Öğrencinin "Görev almaya hazırım / Müsait değilim" durumunu
/// gösteren ve değiştiren kart widget'ı.
class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.onToggle,
    this.isTaskActive = false,
  });

  /// true → aktif (görev alabilir), false → deaktif.
  final bool isAvailable;
  final ValueChanged<bool> onToggle;

  /// Aktif görev varsa toggle devre dışı bırakılır.
  final bool isTaskActive;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF2563EB);
    final inactiveColor = const Color(0xFF64748B);
    final currentColor = isAvailable ? activeColor : inactiveColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // İkon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: currentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAvailable
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              color: currentColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),

          // Başlık + açıklama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'Görev Almaya Hazırım' : 'Şu An Müsait Değilim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: currentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTaskActive
                      ? 'Aktif bir görevin var, önce tamamla.'
                      : isAvailable
                      ? 'Yeni görev bildirimleri alıyorsunuz.'
                      : 'Bildirimler duraklatıldı.',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Toggle
          Switch.adaptive(
            value: isAvailable,
            onChanged: isTaskActive ? null : onToggle,
          ),
        ],
      ),
    );
  }
}
