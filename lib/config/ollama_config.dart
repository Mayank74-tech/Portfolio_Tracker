import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ollama local LLM configuration loaded from .env.
class OllamaConfig {
  OllamaConfig._();

  static String get baseUrl =>
      dotenv.env['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';

  static String get model =>
      dotenv.env['OLLAMA_MODEL'] ?? 'llama3';

  static Duration get timeout => const Duration(seconds: 60);

  /// Returns true if Ollama is configured with a non-default base URL,
  /// indicating the user intends to use it.
  static bool get isConfigured =>
      dotenv.env['OLLAMA_BASE_URL']?.isNotEmpty == true;

  static String get generateEndpoint => '$baseUrl/api/generate';
  static String get tagsEndpoint => '$baseUrl/api/tags';
}
