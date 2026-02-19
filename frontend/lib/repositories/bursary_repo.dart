import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [BursaryRepository] implementation.
final bursaryRepositoryProvider = Provider<BursaryRepository>((ref) {
  return BursaryRepositoryImpl();
});

/// Abstract class defining the institution and bursary management repository interface.
abstract class BursaryRepository {
  /// Gets general statistics for the institution.
  Future<Map<String, dynamic>> getInstitutionStats();

  /// Lists student bursary entitlements with optional date filters.
  Future<List<Map<String, dynamic>>> getBursaries({
    String? month,
    String? year,
  });

  /// Triggers bursary calculation for a specific period.
  Future<void> calculateBursary(String month, String year);

  /// Marks a specific bursary entitlement as paid.
  Future<void> markBursaryAsPaid(String bursaryId);
}

/// Concrete implementation of [BursaryRepository] with placeholder logic.
class BursaryRepositoryImpl implements BursaryRepository {
  @override
  Future<Map<String, dynamic>> getInstitutionStats() async {
    throw UnimplementedError('getInstitutionStats() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getBursaries({
    String? month,
    String? year,
  }) async {
    throw UnimplementedError('getBursaries() has not been implemented');
  }

  @override
  Future<void> calculateBursary(String month, String year) async {
    throw UnimplementedError('calculateBursary() has not been implemented');
  }

  @override
  Future<void> markBursaryAsPaid(String bursaryId) async {
    throw UnimplementedError('markBursaryAsPaid() has not been implemented');
  }
}
