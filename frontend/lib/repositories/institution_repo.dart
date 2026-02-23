import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/create_user_request.dart';
import 'package:tdp_frontend/services/api_service.dart';

/// Provider for the [InstitutionRepo] implementation.
final institutionRepoProvider = Provider<InstitutionRepo>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InstitutionRepoImpl(apiService);
});

/// Abstract class defining the institution and administrative management repository interface.
abstract class InstitutionRepo {
  /// Adds a new user (Student or Elderly) - Admin operation.
  Future<void> createUser(CreateUserRequest request);

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
  final ApiService _apiService;

  InstitutionRepoImpl(this._apiService);

  @override
  Future<void> createUser(CreateUserRequest request) async {
    await _apiService.post('/api/v1/users', data: request.toJson());
  }

  @override
  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final Map<String, dynamic> queryParameters = {};
    if (role != null && role.isNotEmpty) {
      queryParameters['role'] = role;
    }

    final response = await _apiService.get(
      '/api/v1/users',
      queryParameters: queryParameters,
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
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
