import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/bursary_history.dart';
import 'package:tdp_frontend/models/create_user_request.dart';
import 'package:tdp_frontend/models/dashboard_stats.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/services/api_service.dart';
import 'package:tdp_frontend/shared/api_url.dart';

/// Provider for the [InstitutionRepo] implementation.
final institutionRepoProvider = Provider<InstitutionRepo>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InstitutionRepoImpl(apiService);
});

/// Abstract class defining the institution management repository interface.
abstract class InstitutionRepo {
  /// Adds a new user (Student or Elderly) — Admin operation.
  Future<User> createUser(CreateUserRequest request);

  /// Lists users with optional role filter — Admin operation.
  Future<List<User>> getUsers({String? role});

  /// Gets dashboard statistics (Student or Institution Admin).
  Future<DashboardStats> getDashboardStats();

  /// Lists bursary records for institution (INSTITUTION_ADMIN).
  Future<List<BursaryHistory>> getBursaries({
    required int year,
    required int month,
  });

  /// Triggers bursary calculation for a specific month.
  Future<void> calculateBursary(int year, int month);

  /// Marks a specific bursary as paid.
  Future<BursaryHistory> markBursaryAsPaid(String bursaryId, {String? transactionReference});
}

/// Concrete implementation connected to the Spring Boot backend.
class InstitutionRepoImpl implements InstitutionRepo {
  final ApiService _apiService;

  InstitutionRepoImpl(this._apiService);

  @override
  Future<User> createUser(CreateUserRequest request) async {
    final response = await _apiService.post(
      ApiUrl.users,
      data: request.toJson(),
    );
    return User.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<User>> getUsers({String? role}) async {
    final Map<String, dynamic> queryParameters = {};
    if (role != null && role.isNotEmpty) {
      queryParameters['role'] = role;
    }

    final response = await _apiService.get(
      ApiUrl.users,
      queryParameters: queryParameters,
    );

    if (response is List) {
      return response
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<DashboardStats> getDashboardStats() async {
    final response = await _apiService.get(ApiUrl.dashboardStats);
    return DashboardStats.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<BursaryHistory>> getBursaries({
    required int year,
    required int month,
  }) async {
    final response = await _apiService.get(
      ApiUrl.institutionBursaries,
      queryParameters: {'year': year, 'month': month},
    );

    if (response is List) {
      return response
          .map((json) => BursaryHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> calculateBursary(int year, int month) async {
    await _apiService.post(
      ApiUrl.calculateBursaries,
      data: {'year': year, 'month': month},
    );
  }

  @override
  Future<BursaryHistory> markBursaryAsPaid(
    String bursaryId, {
    String? transactionReference,
  }) async {
    final response = await _apiService.put(
      ApiUrl.payBursary(bursaryId),
      data: transactionReference != null
          ? {'transactionReference': transactionReference}
          : null,
    );
    return BursaryHistory.fromJson(response as Map<String, dynamic>);
  }
}
