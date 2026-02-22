import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [UserRepo] implementation.
final userRepoProvider = Provider<UserRepo>((ref) {
  return UserRepoImpl();
});

/// Abstract class defining the user management repository interface.
abstract class UserRepo {
  /// Gets detailed information for a specific user.
  Future<Map<String, dynamic>> getUserDetail(String id);

  /// Gets the task history for a specific user.
  Future<List<Map<String, dynamic>>> getUserHistory(String id);
}

/// Concrete implementation of [UserRepo] with placeholder logic.
class UserRepoImpl implements UserRepo {
  @override
  Future<Map<String, dynamic>> getUserDetail(String id) async {
    throw UnimplementedError('getUserDetail() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getUserHistory(String id) async {
    throw UnimplementedError('getUserHistory() has not been implemented');
  }
}
