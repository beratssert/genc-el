import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/services/api_service.dart';

/// Provider for the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepositoryImpl(apiService);
});

/// Abstract class defining the authentication repository interface.
abstract class AuthRepository {
  /// Logs in a user and returns a JWT token or similar.
  Future<Map<String, dynamic>> login(String username, String password);

  /// Refreshes the existing access token.
  Future<void> refreshToken();

  /// Changes the user's password.
  Future<void> changePassword(String oldPassword, String newPassword);
}

/// Concrete implementation of [AuthRepository] with placeholder logic.
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiService.post(
      '/api/v1/auth/login',
      data: {'email': username, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> refreshToken() async {
    throw UnimplementedError('refreshToken() has not been implemented');
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    throw UnimplementedError('changePassword() has not been implemented');
  }
}
