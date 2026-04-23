import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

class AlphaVantageService {
  AlphaVantageService({http.Client? client})
      : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('www.alphavantage.co', '/query');
  final http.Client _client;

  Future<Map<String, dynamic>> getDailyTimeSeries(
    String symbol, {
    String outputSize = 'compact',
  }) {
    return _query({
      'function': 'TIME_SERIES_DAILY',
      'symbol': symbol.toUpperCase(),
      'outputsize': outputSize,
    });
  }

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) {
    return _query({
      'function': 'TIME_SERIES_WEEKLY',
      'symbol': symbol.toUpperCase(),
    });
  }

  Future<Map<String, dynamic>> getRsi({
    required String symbol,
    String interval = 'daily',
    int timePeriod = 14,
    String seriesType = 'close',
  }) {
    return _query({
      'function': 'RSI',
      'symbol': symbol.toUpperCase(),
      'interval': interval,
      'time_period': timePeriod,
      'series_type': seriesType,
    });
  }

  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final data = await _query({
      'function': 'SYMBOL_SEARCH',
      'keywords': query.trim(),
    });

    final matches = data['bestMatches'];
    if (matches is List) {
      return matches.whereType<Map>().map(_stringKeyedMap).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> _query(Map<String, dynamic> parameters) async {
    final key = ApiKeys.alphaVantage;
    if (key.isEmpty) {
      throw StateError('Missing ALPHA_VANTAGE_API_KEY in .env');
    }

    final response = await _client.get(
      _baseUri.replace(
        queryParameters: {
          ...parameters.map(
            (paramKey, value) => MapEntry(paramKey, value.toString()),
          ),
          'apikey': key,
        },
      ),
    );

    final decoded = _decodeResponse(response);
    if (decoded is! Map) {
      throw const FormatException(
        'Alpha Vantage returned an unexpected response.',
      );
    }

    final data = _stringKeyedMap(decoded);
    final error = data['Error Message'] ?? data['Note'] ?? data['Information'];
    if (error != null) {
      throw Exception('Alpha Vantage error: $error');
    }
    return data;
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  static dynamic _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? decoded['Error Message'] ??
            decoded['message'] ??
            response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('Alpha Vantage request failed: $message');
  }
}
