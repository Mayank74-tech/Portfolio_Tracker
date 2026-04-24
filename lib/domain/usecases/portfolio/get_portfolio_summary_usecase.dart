import 'dart:async';

import '../../entities/portfolio_summary_entity.dart';

abstract class PortfolioRepository {
  Future<PortfolioSummaryEntity> getPortfolioSummary();
}

class GetPortfolioSummaryUseCase {
  final PortfolioRepository repository;

  GetPortfolioSummaryUseCase(this.repository);

  Future<PortfolioSummaryEntity> call() async {
    return await repository.getPortfolioSummary();
  }
}
