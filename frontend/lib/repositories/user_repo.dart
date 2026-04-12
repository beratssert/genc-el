import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/services/api_service.dart';
import 'package:tdp_frontend/shared/api_url.dart';

/// Provider for the [UserRepo] implementation.
final userRepoProvider = Provider<UserRepo>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepoImpl(apiService);
});

/// Abstract class defining the user profile repository interface.
abstract class UserRepo {
  /// Gets the currently logged-in user's profile.
  Future<User> getMyProfile();

  /// Updates the currently logged-in user's profile.
  Future<User> updateMyProfile(Map<String, dynamic> data);

  /// Deactivates the current user's account.
  Future<void> deactivateMyAccount();

  /// Updates current user's location (lat, lon).
  Future<void> updateLocation(double lat, double lon);
}

/// Concrete implementation of [UserRepo] connected to backend.
class UserRepoImpl implements UserRepo {
  final ApiService _apiService;

  UserRepoImpl(this._apiService);

  @override
  Future<User> getMyProfile() async {
    final response = await _apiService.get(ApiUrl.myProfile);
    return User.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<User> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put(ApiUrl.myProfile, data: data);
    return User.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deactivateMyAccount() async {
    await _apiService.delete(ApiUrl.myProfile);
  }

  @override
  Future<void> updateLocation(double lat, double lon) async {
    await _apiService.put(
      ApiUrl.myLocation,
      data: {'latitude': lat, 'longitude': lon},
    );
  }
}
