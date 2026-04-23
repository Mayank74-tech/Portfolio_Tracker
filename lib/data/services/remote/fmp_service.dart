import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

class FmpService {
  FmpService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('financialmodelingprep.com', '/api/v3');
  final http.Client _client;

  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    final rows = await _getList('/profile/${symbol.toUpperCase()}');
    return rows.isEmpty ? const {} : rows.first;
  }

  Future<List<Map<String, dynamic>>> getRatios(
    String symbol, {
    int limit = 1,
  }) {
    return _getList(
      '/ratios/${symbol.toUpperCase()}',
      queryParameters: {'limit': limit},
    );
  }

  Future<List<Map<String, dynamic>>> getIncomeStatement(
    String symbol, {
    int limit = 4,
  }) {
    return _getList(
      '/income-statement/${symbol.toUpperCase()}',
      queryParameters: {'limit': limit},
    );
  }

  Future<Map<String, dynamic>> getQuote(String symbol) async {
    final rows = await _getList('/quote/${symbol.toUpperCase()}');
    return rows.isEmpty ? const {} : rows.first;
  }

  Future<List<Map<String, dynamic>>> searchCompanies(
    String query, {
    int limit = 10,
    String exchange = '',
  }) {
    return _getList(
      '/search',
      queryParameters: {
        'query': query.trim(),
        'limit': limit,
        if (exchange.isNotEmpty) 'exchange': exchange,
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _get(path, queryParameters: queryParameters);
    if (data is List) {
      return data.whereType<Map>().map(_stringKeyedMap).toList();
    }
    if (data is Map) {
      final mapped = _stringKeyedMap(data);
      if (mapped['Error Message'] != null || mapped['error'] != null) {
        throw Exception(mapped['Error Message'] ?? mapped['error']);
      }
      return [mapped];
    }
    throw const FormatException('FMP returned an unexpected response.');
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final key = ApiKeys.fmp;
    if (key.isEmpty) {
      throw StateError('Missing FMP_API_KEY in .env');
    }

    final response = await _client.get(
      _uri(path, {
        ...?queryParameters,
        'apikey': key,
      }),
    );
    return _decodeResponse(response);
  }

  Uri _uri(String path, Map<String, dynamic> queryParameters) {
    return _baseUri.replace(
      path: '${_baseUri.path}$path',
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  dynamic _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? decoded['Error Message'] ?? decoded['error'] ?? response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('FMP request failed: $message');
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}
