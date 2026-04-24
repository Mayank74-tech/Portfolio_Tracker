import 'dart:async';

import '../../entities/stock_entity.dart';

abstract class StockRepository {
  Future<List<StockEntity>> searchStock(String query);
}

class SearchStockUseCase {
  final StockRepository repository;

  SearchStockUseCase(this.repository);

  Future<List<StockEntity>> call(String query) async {
    if (query.trim().length < 2) {
      throw ArgumentError('Query must be at least 2 characters.');
    }
    return await repository.searchStock(query.trim());
  }
}
