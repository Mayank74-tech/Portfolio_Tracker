import 'dart:async';

abstract class PortfolioRepository {
  Future<void> deleteHolding(String symbol);
}

class DeleteHoldingUseCase {
  final PortfolioRepository repository;

  DeleteHoldingUseCase(this.repository);

  Future<void> call(String symbol) async {
    if (symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    await repository.deleteHolding(symbol);
  }
}
