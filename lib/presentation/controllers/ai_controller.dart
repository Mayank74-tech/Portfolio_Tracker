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

      final summary = await _portfolioRepository.getPortfolioSummary();
      final rawHoldings = summary['holdings'];
      final holdings = rawHoldings is List
          ? rawHoldings.whereType<Map>().map(_stringKeyedMap).toList()
          : <Map<String, dynamic>>[];

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
          message: 'I could not generate an insight right now.',
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
}
