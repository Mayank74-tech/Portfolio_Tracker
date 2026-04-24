import 'dart:async';

abstract class AIInsightRepository {
  Future<AIInsightResult> getInsightForStock(String symbol);
}

class AIInsightResult {
  final String summary;
  final List<String> keyPoints;
  final double sentimentScore; // -1.0 to 1.0
  final String modelVersion;

  AIInsightResult({
    required this.summary,
    required this.keyPoints,
    required this.sentimentScore,
    required this.modelVersion,
  });
}

class GetAIInsightUseCase {
  final AIInsightRepository repository;

  GetAIInsightUseCase(this.repository);

  Future<AIInsightResult> call({required String symbol}) async {
    if (symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    return await repository.getInsightForStock(symbol);
  }
}
