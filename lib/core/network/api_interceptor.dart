import 'package:dio/dio.dart';

/// Dio interceptor: attaches API keys, logs requests/errors.
class ApiInterceptor extends Interceptor {
  final String? apiKey;
  final String? apiKeyHeader;

  const ApiInterceptor({this.apiKey, this.apiKeyHeader});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach API key header if provided
    if (apiKey != null && apiKeyHeader != null && apiKey!.isNotEmpty) {
      options.headers[apiKeyHeader!] = apiKey;
    }
    // Always send JSON
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
