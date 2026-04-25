import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../config/api_keys.dart';

class GeminiService {
  GeminiService() {
    final apiKey = ApiKeys.geminiApiKey;
    if (apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: ApiKeys.geminiModel,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are a smart financial assistant helping users understand their '
        'stock portfolio. Analyze holdings clearly and simply. '
        'Never give direct buy or sell advice. '
        'Format responses with bullet points where helpful. '
        'Keep answers concise and actionable.',
      ),
    );
    _chat = _model!.startChat();
  }

  GenerativeModel? _model;
  ChatSession? _chat;

  // Reset chat history (new conversation)
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  Future<bool> isAvailable() async {
    if (_model == null) return false;

    try {
      final result = await _model!.generateContent(
        [Content.text('ping')],
      );
      return result.text != null;
    } catch (_) {
      return false;
    }
  }

  Future<String> generatePortfolioInsight({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) async {
    if (_chat == null) {
      throw StateError('Missing GEMINI_API_KEY in .env');
    }

    try {
      final prompt = _buildPortfolioPrompt(
        holdings: holdings,
        question: question,
        portfolioSummary: portfolioSummary,
      );

      final response = await _chat!.sendMessage(Content.text(prompt));
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      return text.trim();
    } on GenerativeAIException catch (e) {
      throw Exception('Gemini error: ${e.message}');
    }
  }

  Future<String> generateOneShot(String prompt) async {
    if (_model == null) {
      throw StateError('Missing GEMINI_API_KEY in .env');
    }

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No response generated.';
    } on GenerativeAIException catch (e) {
      throw Exception('Gemini error: ${e.message}');
    }
  }

  static String _buildPortfolioPrompt({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) {
    final buffer = StringBuffer();

    if (portfolioSummary != null && portfolioSummary.isNotEmpty) {
      final totalValue = portfolioSummary['total_value'] ?? 0;
      final totalInvested = portfolioSummary['total_investment'] ?? 0;
      final pl = portfolioSummary['profit_loss'] ?? 0;
      final plPct = portfolioSummary['profit_loss_percent'] ?? 0;
      buffer.writeln('📊 Portfolio Summary:');
      buffer.writeln('  • Total Value: ₹$totalValue');
      buffer.writeln('  • Total Invested: ₹$totalInvested');
      buffer.writeln('  • P&L: ₹$pl (${(plPct as num).toStringAsFixed(2)}%)');
      buffer.writeln();
    }

    buffer.writeln('📈 Current Holdings:');
    if (holdings.isEmpty) {
      buffer.writeln('  No holdings available.');
    } else {
      for (final h in holdings) {
        final symbol = h['stock_symbol'] ?? h['symbol'] ?? 'Unknown';
        final qty = h['quantity'] ?? 0;
        final buyPrice = h['buy_price'] ?? 0;
        final currentPrice = h['current_price'] ?? buyPrice;
        final platform = h['platform'] ?? 'Manual';
        buffer.writeln(
          '  • $symbol — Qty: $qty, Buy: ₹$buyPrice, '
          'Current: ₹$currentPrice, Platform: $platform',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('❓ User Question: $question');

    return buffer.toString();
  }
}
