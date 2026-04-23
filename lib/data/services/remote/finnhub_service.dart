import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

class FinnhubService {
  FinnhubService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('finnhub.io', '/api/v1');
  final http.Client _client;

  Future<Map<String, dynamic>> getQuote(String symbol) {
    return _getMap(
      '/quote',
      queryParameters: {'symbol': symbol.toUpperCase()},
    );
  }

  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final data = await _getMap(
      '/search',
      queryParameters: {'q': query.trim()},
    );
    final result = data['result'];
    if (result is List) {
      return result.whereType<Map>().map(_stringKeyedMap).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> getCompanyProfile(String symbol) {
    return _getMap(
      '/stock/profile2',
      queryParameters: {'symbol': symbol.toUpperCase()},
    );
  }

  Future<Map<String, dynamic>> getBasicFinancials(
    String symbol, {
    String metric = 'all',
  }) {
    return _getMap(
      '/stock/metric',
      queryParameters: {
        'symbol': symbol.toUpperCase(),
        'metric': metric,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCompanyNews({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) {
    return _getList(
      '/company-news',
      queryParameters: {
        'symbol': symbol.toUpperCase(),
        'from': _dateOnly(from),
        'to': _dateOnly(to),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMarketNews({
    String category = 'general',
    int? minId,
  }) {
    return _getList(
      '/news',
      queryParameters: {
        'category': category,
        if (minId != null) 'minId': minId,
      },
    );
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _get(path, queryParameters: queryParameters);
    if (data is Map) {
      return _stringKeyedMap(data);
    }
    throw const FormatException('Finnhub returned an unexpected response.');
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _get(path, queryParameters: queryParameters);
    if (data is List) {
      return data.whereType<Map>().map(_stringKeyedMap).toList();
    }
    throw const FormatException('Finnhub returned an unexpected response.');
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = ApiKeys.finnhub;
    if (token.isEmpty) {
      throw StateError('Missing FINNHUB_API_KEY in .env');
    }

    final response = await _client.get(
      _uri(path, {
        ...?queryParameters,
        'token': token,
      }),
    );
    return _decodeResponse(response, 'Finnhub');
  }

  Uri _uri(String path, Map<String, dynamic> queryParameters) {
    return _baseUri.replace(
      path: '${_baseUri.path}$path',
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  dynamic _decodeResponse(http.Response response, String serviceName) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? decoded['error'] ?? decoded['message'] ?? response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('$serviceName request failed: $message');
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
