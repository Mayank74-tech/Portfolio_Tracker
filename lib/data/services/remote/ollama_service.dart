import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

class OllamaService {
  OllamaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> isAvailable() async {
    try {
      final response = await _client.get(_uri('/api/tags'));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<String> generate({
    required String prompt,
    String? system,
    String? model,
    Map<String, dynamic>? options,
  }) async {
    final response = await _generateRaw(
      prompt: prompt,
      system: system,
      model: model,
      options: options,
    );

    final text = response['response'];
    if (text is String) return text.trim();
    throw const FormatException('Ollama returned an empty response.');
  }

  Future<String> generatePortfolioInsight({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) {
    return generate(
      system: 'You are a financial assistant. Analyze the user portfolio in '
          'clear, simple language. Do not give direct buy or sell advice.',
      prompt: buildPortfolioPrompt(
        holdings: holdings,
        question: question,
        portfolioSummary: portfolioSummary,
      ),
    );
  }

  Future<Map<String, dynamic>> _generateRaw({
    required String prompt,
    String? system,
    String? model,
    Map<String, dynamic>? options,
  }) async {
    final response = await _client.post(
      _uri('/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model ?? ApiKeys.ollamaModel,
        'prompt': prompt,
        'stream': false,
        if (system != null && system.trim().isNotEmpty) 'system': system,
        if (options != null) 'options': options,
      }),
    );

    final decoded = _decodeResponse(response);
    if (decoded is Map) {
      final data = _stringKeyedMap(decoded);
      if (data['error'] != null) {
        throw Exception('Ollama error: ${data['error']}');
      }
      return data;
    }
    throw const FormatException('Ollama returned an unexpected response.');
  }

  Uri _uri(String path) {
    final base = Uri.parse(ApiKeys.ollamaBaseUrl);
    return base.replace(path: path);
  }

  static String buildPortfolioPrompt({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) {
    final buffer = StringBuffer();

    if (portfolioSummary != null && portfolioSummary.isNotEmpty) {
      buffer.writeln('Portfolio summary: $portfolioSummary');
    }

    buffer.writeln('Holdings:');
    if (holdings.isEmpty) {
      buffer.writeln('No holdings available.');
    } else {
      for (final holding in holdings) {
        buffer.writeln('- $holding');
      }
    }

    buffer
      ..writeln()
      ..writeln('User question: $question');

    return buffer.toString();
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  static dynamic _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? decoded['error'] ?? decoded['message'] ?? response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('Ollama request failed: $message');
  }
}
