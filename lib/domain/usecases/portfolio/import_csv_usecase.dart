import 'dart:async';

import '../../entities/holding_entity.dart';

abstract class PortfolioRepository {
  Future<List<HoldingEntity>> importHoldingsFromCsv(String csvContent);
}

class ImportCsvUseCase {
  final PortfolioRepository repository;

  ImportCsvUseCase(this.repository);

  Future<List<HoldingEntity>> call(String csvContent) async {
    if (csvContent.trim().isEmpty) {
      throw ArgumentError('CSV content cannot be empty.');
    }
    return await repository.importHoldingsFromCsv(csvContent);
  }
}
