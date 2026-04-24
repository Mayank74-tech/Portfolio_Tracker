import 'dart:async';
import '../../entities/holding_entity.dart';

abstract class PortfolioRepository {
  Future<HoldingEntity> updateHolding({
    required String symbol,
    required int quantity,
    required double buyPrice,
  });
}

class UpdateHoldingParams {
  final String symbol;
  final int quantity;
  final double buyPrice;

  UpdateHoldingParams({
    required this.symbol,
    required this.quantity,
    required this.buyPrice,
  });
}

class UpdateHoldingUseCase {
  final PortfolioRepository repository;

  UpdateHoldingUseCase(this.repository);

  Future<HoldingEntity> call(UpdateHoldingParams params) async {
    if (params.symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    if (params.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0.');
    }
    if (params.buyPrice <= 0) {
      throw ArgumentError('Buy price must be greater than 0.');
    }
    return await repository.updateHolding(
      symbol: params.symbol,
      quantity: params.quantity,
      buyPrice: params.buyPrice,
    );
  }
}
