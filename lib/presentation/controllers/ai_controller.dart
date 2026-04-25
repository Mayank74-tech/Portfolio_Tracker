import 'package:get/get.dart';

import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/portfolio_repository.dart';

class AiController extends GetxController {
  AiController({
    AiRepository? aiRepository,
    PortfolioRepository? portfolioRepository,
  })  : _aiRepository = aiRepository ?? AiRepository(),
        _portfolioRepository = portfolioRepository ?? PortfolioRepository();

  final AiRepository _aiRepository;
  final PortfolioRepository _portfolioRepository;

  final RxBool isLoading = false.obs;
  final RxBool isAvailable = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  Future<void> checkAvailability() async {
    isAvailable.value = await _aiRepository.isAvailable();
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty) return;

    final userMessage = _chatMessage(sender: 'user', message: message);
    messages.add(userMessage);

    try {
      isLoading.value = true;
      errorMessage.value = '';

      Map<String, dynamic>? summary;
      List<Map<String, dynamic>> holdings = const [];

      try {
        final portfolioSummary =
            await _portfolioRepository.getPortfolioSummary();
        summary = portfolioSummary;
        final rawHoldings = portfolioSummary['holdings'];
        holdings = rawHoldings is List
            ? rawHoldings.whereType<Map>().map(_stringKeyedMap).toList()
            : <Map<String, dynamic>>[];
      } catch (_) {
        summary = null;
        holdings = const [];
      }

      final response = await _aiRepository.sendChatMessage(
        message: message,
        holdings: holdings,
        portfolioSummary: summary,
      );

      messages.add(_chatMessage(sender: 'ai', message: response));
    } catch (error) {
      errorMessage.value = error.toString();
      messages.add(
        _chatMessage(
          sender: 'ai',
          message: _friendlyError(error),
          error: true,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadChatHistory() async {
    messages.bindStream(_aiRepository.watchChatHistory());
  }

  void clearMessages() {
    messages.clear();
  }

  void clearError() {
    errorMessage.value = '';
  }

  static Map<String, dynamic> _chatMessage({
    required String sender,
    required String message,
    bool error = false,
  }) {
    return {
      'sender': sender,
      'message': message,
      'is_error': error,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  static String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('Missing GEMINI_API_KEY')) {
      return 'Gemini is not configured yet. Add GEMINI_API_KEY to your .env '
          'or start Ollama for local AI.';
    }

    if (text.contains('Both Gemini and Ollama are unavailable')) {
      return 'AI is unavailable right now. Add GEMINI_API_KEY to .env or make '
          'sure Ollama is running at the configured local URL.';
    }

    if (text.contains('User must be logged in')) {
      return 'Please sign in again so I can load your portfolio context.';
    }

    return 'I could not generate an insight right now.';
  }
}
