import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [InstitutionRepo] implementation.
final institutionRepoProvider = Provider<InstitutionRepo>((ref) {
  return InstitutionRepoImpl();
});

/// Abstract class defining the institution and administrative management repository interface.
abstract class InstitutionRepo {
  /// Adds a new user (Student or Elderly) - Admin operation.
  Future<void> createUser(Map<String, dynamic> userData);

  /// Lists users with optional filters like role or region - Admin operation.
  Future<List<Map<String, dynamic>>> getUsers({String? role});

  /// Updates user information.
  Future<void> updateUser(String id, Map<String, dynamic> userData);

  /// Deactivates a user (Soft delete) - Admin operation.
  Future<void> deleteUser(String id);

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

/// Concrete implementation of [InstitutionRepo] with placeholder logic.
class InstitutionRepoImpl implements InstitutionRepo {
  @override
  Future<void> createUser(Map<String, dynamic> userData) async {
    throw UnimplementedError('createUser() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    throw UnimplementedError('getUsers() has not been implemented');
  }

  @override
  Future<void> deleteUser(String id) async {
    throw UnimplementedError('deleteUser() has not been implemented');
  }

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

  @override
  Future<void> updateUser(String id, Map<String, dynamic> userData) {
    throw UnimplementedError('updateUser() has not been implemented');
  }
}
