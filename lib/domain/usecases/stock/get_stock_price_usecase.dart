import 'dart:async';

import '../../entities/stock_entity.dart';

abstract class StockRepository {
  Future<StockEntity> getStockPrice(String symbol);
}

class GetStockPriceUseCase {
  final StockRepository repository;

  GetStockPriceUseCase(this.repository);

  Future<StockEntity> call(String symbol) async {
    if (symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    return await repository.getStockPrice(symbol);
  }
}
