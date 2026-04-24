import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get alphaVantage => dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';

  static String get finnhub => dotenv.env['FINNHUB_API_KEY'] ?? '';

  static String get fmp => dotenv.env['FMP_API_KEY'] ?? '';

  static String get marketaux => dotenv.env['MARKETAUX_API_KEY'] ?? '';

  static String get ollamaBaseUrl =>
      dotenv.env['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';

  static String get ollamaModel => dotenv.env['OLLAMA_MODEL'] ?? 'llama3';

  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
}
