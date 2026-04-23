import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

class MarketauxService {
  MarketauxService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('api.marketaux.com', '/v1');
  final http.Client _client;

  Future<List<Map<String, dynamic>>> getLatestNews({
    List<String> symbols = const [],
    String countries = 'in,us',
    String language = 'en',
    int limit = 10,
    bool filterEntities = true,
  }) async {
    final data = await _getMap(
      '/news/all',
      queryParameters: {
        if (symbols.isNotEmpty) 'symbols': symbols.join(','),
        'countries': countries,
        'language': language,
        'limit': limit,
        'filter_entities': filterEntities,
      },
    );
    return _extractNews(data);
  }

  Future<List<Map<String, dynamic>>> getNewsForSymbol(
    String symbol, {
    int limit = 10,
    String language = 'en',
  }) {
    return getLatestNews(
      symbols: [symbol.toUpperCase()],
      limit: limit,
      language: language,
    );
  }

  Future<List<Map<String, dynamic>>> searchNews({
    required String query,
    int limit = 10,
    String language = 'en',
  }) async {
    final data = await _getMap(
      '/news/all',
      queryParameters: {
        'search': query.trim(),
        'language': language,
        'limit': limit,
      },
    );
    return _extractNews(data);
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final key = ApiKeys.marketaux;
    if (key.isEmpty) {
      throw StateError('Missing MARKETAUX_API_KEY in .env');
    }

    final response = await _client.get(
      _uri(path, {
        ...?queryParameters,
        'api_token': key,
      }),
    );

    final decoded = _decodeResponse(response);
    if (decoded is Map) {
      final data = _stringKeyedMap(decoded);
      if (data['error'] != null) {
        throw Exception('Marketaux error: ${data['error']}');
      }
      return data;
    }
    throw const FormatException('Marketaux returned an unexpected response.');
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
        ? decoded['error'] ?? decoded['message'] ?? response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('Marketaux request failed: $message');
  }

  static List<Map<String, dynamic>> _extractNews(Map<String, dynamic> data) {
    final rows = data['data'];
    if (rows is List) {
      return rows.whereType<Map>().map(_stringKeyedMap).toList();
    }
    return const [];
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}
