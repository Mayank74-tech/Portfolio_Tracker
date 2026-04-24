import 'dart:async';
import '../../entities/holding_entity.dart';

abstract class PortfolioRepository {
  Future<HoldingEntity> addHolding({
    required String symbol,
    required int quantity,
    required double buyPrice,
  });
}

class AddHoldingParams {
  final String symbol;
  final int quantity;
  final double buyPrice;

  AddHoldingParams({
    required this.symbol,
    required this.quantity,
    required this.buyPrice,
  });
}

class AddHoldingUseCase {
  final PortfolioRepository repository;

  AddHoldingUseCase(this.repository);

  Future<HoldingEntity> call(AddHoldingParams params) async {
    if (params.symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    if (params.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0.');
    }
    if (params.buyPrice <= 0) {
      throw ArgumentError('Buy price must be greater than 0.');
    }
    return await repository.addHolding(
      symbol: params.symbol,
      quantity: params.quantity,
      buyPrice: params.buyPrice,
    );
  }
}
