import 'package:dio/dio.dart';
import 'api_interceptor.dart';

/// Factory for pre-configured Dio HTTP clients.
class HttpClient {
  HttpClient._();

  /// Creates a Dio instance with standard timeout and optional API key header.
  static Dio create({
    required String baseUrl,
    String? apiKey,
    String? apiKeyHeader,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, dynamic>? extraHeaders,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?extraHeaders,
        },
      ),
    );

    dio.interceptors.add(
      ApiInterceptor(apiKey: apiKey, apiKeyHeader: apiKeyHeader),
    );

    return dio;
  }
}
