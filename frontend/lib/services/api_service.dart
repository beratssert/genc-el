import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [ApiService].
/// This will be used by all Repositories to make network calls.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// A service that handles all network-level logic.
/// Typically uses a client like Dio or Http.
class ApiService {
  // TODO: Initialize Dio or Http client here
  // Dio dio = Dio();

  /// Performs a GET request.
  /// Handles base URL, headers, and common errors.
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    // 1. URL'i oluştur
    // 2. Auth token varsa header'a ekle
    // 3. İsteği at ve sonucu kontrol et
    // 4. Hata varsa (401, 404, 500 vb.) özel exception fırlat
    throw UnimplementedError('GET method skeleton only');
  }

  /// Performs a POST request.
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    // 1. Body verisini hazırla
    // 2. İsteği at
    // 3. Response'u dön veya hata yönetimi yap
    throw UnimplementedError('POST method skeleton only');
  }

  /// Handles file uploads (e.g. receipt images for tasks).
  Future<dynamic> uploadFile(String endpoint, String filePath) async {
    // Multipart request logic here
    throw UnimplementedError('File upload skeleton only');
  }

  /// Common error handling logic for the entire app.
  void _handleError(dynamic error) {
    // 401: Logout logic
    // 500: Server error notification
    // Internet connection check
  }
}
