import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the [StorageService].
/// This is an [AsyncValue] because [SharedPreferences] needs to be initialized asynchronously.
final storageServiceProvider = Provider<StorageService>((ref) {
  // Use a throw or handle initialization externally if needed.
  // For simplicity, we assume it's initialized or provide a way to access it.
  return StorageService();
});

/// A service responsible for local data persistence.
/// Wraps 'flutter_secure_storage' for tokens and 'shared_preferences' for other data.
class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Keys
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';

  /// Initializes the [SharedPreferences] instance.
  /// This should be called before using any methods that rely on SharedPreferences.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Secure Storage (Token) ---

  /// Saves the authentication token securely.
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the stored authentication token.
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Deletes the stored authentication token.
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // --- Shared Preferences ---

  /// Saves the user role.
  Future<void> saveRole(String role) async {
    await _ensureInitialized();
    await _prefs?.setString(_userRoleKey, role);
  }

  /// Retrieves the stored user role.
  Future<String?> getRole() async {
    await _ensureInitialized();
    return _prefs?.getString(_userRoleKey);
  }

  /// Saves a boolean value.
  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs?.setBool(key, value);
  }

  /// Retrieves a boolean value.
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs?.getBool(key);
  }

  /// Saves a string value.
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs?.setString(key, value);
  }

  /// Retrieves a string value.
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs?.getString(key);
  }

  /// Clears all stored data (used during logout).
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _ensureInitialized();
    await _prefs?.clear();
  }

  /// Ensures that SharedPreferences is initialized.
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}
