import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
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
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _institutionIdKey = 'institution_id';

  /// Initializes the [SharedPreferences] instance.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Secure Storage (Token) ---

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // --- Shared Preferences ---

  Future<void> saveRole(String role) async {
    await _ensureInitialized();
    await _prefs?.setString(_userRoleKey, role);
  }

  Future<String?> getRole() async {
    await _ensureInitialized();
    return _prefs?.getString(_userRoleKey);
  }

  Future<void> saveUserId(String userId) async {
    await _ensureInitialized();
    await _prefs?.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    await _ensureInitialized();
    return _prefs?.getString(_userIdKey);
  }

  Future<void> saveEmail(String email) async {
    await _ensureInitialized();
    await _prefs?.setString(_userEmailKey, email);
  }

  Future<String?> getEmail() async {
    await _ensureInitialized();
    return _prefs?.getString(_userEmailKey);
  }

  Future<void> saveUserName(String firstName, String lastName) async {
    await _ensureInitialized();
    await _prefs?.setString(_userFirstNameKey, firstName);
    await _prefs?.setString(_userLastNameKey, lastName);
  }

  Future<String?> getUserFirstName() async {
    await _ensureInitialized();
    return _prefs?.getString(_userFirstNameKey);
  }

  Future<String?> getUserLastName() async {
    await _ensureInitialized();
    return _prefs?.getString(_userLastNameKey);
  }

  Future<void> saveInstitutionId(String? institutionId) async {
    await _ensureInitialized();
    if (institutionId == null) {
      await _prefs?.remove(_institutionIdKey);
    } else {
      await _prefs?.setString(_institutionIdKey, institutionId);
    }
  }

  Future<String?> getInstitutionId() async {
    await _ensureInitialized();
    return _prefs?.getString(_institutionIdKey);
  }

  Future<String> getUserFullName() async {
    final first = await getUserFirstName() ?? '';
    final last = await getUserLastName() ?? '';
    return '$first $last'.trim();
  }

  // --- Generic ---

  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs?.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs?.getBool(key);
  }

  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs?.setString(key, value);
  }

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

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}
