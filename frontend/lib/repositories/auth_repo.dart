import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/services/api_service.dart';
import 'package:tdp_frontend/shared/api_url.dart';

/// Provider for the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepositoryImpl(apiService);
});

/// Abstract class defining the authentication repository interface.
abstract class AuthRepository {
  /// Logs in a user (STUDENT / ELDERLY) and returns LoginResponse.
  Future<Map<String, dynamic>> userLogin(String email, String password);

  /// Logs in an institution admin and returns LoginResponse.
  Future<Map<String, dynamic>> institutionLogin(String email, String password);
}

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> userLogin(String email, String password) async {
    final response = await _apiService.post(
      ApiUrl.userLogin,
      data: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> institutionLogin(
    String email,
    String password,
  ) async {
    final response = await _apiService.post(
      ApiUrl.institutionLogin,
      data: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }
}
