import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// A service responsible for local data persistence.
/// Usually wraps 'flutter_secure_storage' (for tokens) or 'shared_preferences'.
class StorageService {
  // Keys
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';

  /// Saves the authentication token securely.
  Future<void> saveToken(String token) async {
    // SecureStorage use
  }

  /// Retrieves the stored authentication token.
  Future<String?> getToken() async {
    return null;
  }

  /// Clears all stored data (used during logout).
  Future<void> clearAll() async {
    // wipe storage
  }

  /// Saves simple flags or user preferences.
  Future<void> setBool(String key, bool value) async {
    // SharedPreferences use
  }
}
