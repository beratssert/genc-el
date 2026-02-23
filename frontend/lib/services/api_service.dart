import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/shared/api_url.dart';
import 'package:tdp_frontend/services/storage_service.dart';

/// Provider for the [ApiService].
/// This will be used by all Repositories to make network calls.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

/// A service that handles all network-level logic.
/// Typically uses a client like Dio or Http.
class ApiService {
  final Ref _ref;
  late final Dio dio;

  ApiService(this._ref) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiUrl.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = _ref.read(storageServiceProvider);
          final token = await storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
          );

          if (e.response?.statusCode == 401) {
            // Unauthorized - Clear storage and could notify UI to redirect to login
            final storage = _ref.read(storageServiceProvider);
            await storage.clearAll();
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// Performs a GET request.
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a POST request.
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a PUT request.
  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a DELETE request.
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handles file uploads (e.g. receipt images for tasks).
  Future<dynamic> uploadFile(String endpoint, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Common error handling logic for the entire app.
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      switch (statusCode) {
        case 400:
          // Try to extract detailed Spring Boot validation errors
          if (data is Map &&
              data.containsKey('errors') &&
              data['errors'] is List) {
            final List errorsList = data['errors'];
            final errorMessages = errorsList
                .map((e) => e['defaultMessage'] ?? e.toString())
                .join(',\n');
            return Exception('Validation failed:\n$errorMessages');
          }
          return Exception(data?['message'] ?? 'Bad Request: $data');
        case 401:
          // TODO: Trigger global logout or refresh token logic
          return Exception('Unauthorized access. Please login again.');
        case 403:
          return Exception('Forbidden access.');
        case 404:
          return Exception('Resource not found.');
        case 500:
          return Exception(
            'Internal Server Error. Please try again later.\nDetails: $data',
          );
        default:
          return Exception(
            'Something went wrong: ${error.message}\nResponse: $data',
          );
      }
    } else {
      // Something happened in setting up or sending the request that triggered an Error
      if (error.type == DioExceptionType.connectionTimeout) {
        return Exception('Connection Timeout');
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return Exception('Receive Timeout');
      } else if (error.type == DioExceptionType.connectionError) {
        return Exception('No Internet Connection');
      }
      return Exception('Network error: ${error.message}');
    }
  }
}
