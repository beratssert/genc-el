import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [UserRepo] implementation.
final userRepoProvider = Provider<UserRepo>((ref) {
  return UserRepoImpl();
});

/// Abstract class defining the user management repository interface.
abstract class UserRepo {
  /// Adds a new user (Student or Elderly).
  Future<void> createUser(Map<String, dynamic> userData);

  /// Lists users with optional filters like role or region.
  Future<List<Map<String, dynamic>>> getUsers({String? role, String? region});

  /// Gets detailed information for a specific user.
  Future<Map<String, dynamic>> getUserDetail(String id);

  /// Updates user information.
  Future<void> updateUser(String id, Map<String, dynamic> userData);

  /// Deactivates a user (Soft delete).
  Future<void> deleteUser(String id);

  /// Gets the task history for a specific user.
  Future<List<Map<String, dynamic>>> getUserHistory(String id);
}

/// Concrete implementation of [UserRepo] with placeholder logic.
class UserRepoImpl implements UserRepo {
  @override
  Future<void> createUser(Map<String, dynamic> userData) async {
    throw UnimplementedError('createUser() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    String? region,
  }) async {
    throw UnimplementedError('getUsers() has not been implemented');
  }

  @override
  Future<Map<String, dynamic>> getUserDetail(String id) async {
    throw UnimplementedError('getUserDetail() has not been implemented');
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> userData) async {
    throw UnimplementedError('updateUser() has not been implemented');
  }

  @override
  Future<void> deleteUser(String id) async {
    throw UnimplementedError('deleteUser() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getUserHistory(String id) async {
    throw UnimplementedError('getUserHistory() has not been implemented');
  }
}
