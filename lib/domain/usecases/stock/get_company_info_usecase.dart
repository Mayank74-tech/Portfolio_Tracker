import 'dart:async';

abstract class StockRepository {
  Future<CompanyInfoResult> getCompanyInfo(String symbol);
}

class CompanyInfoResult {
  final String symbol;
  final String name;
  final String sector;
  final String industry;
  final String description;
  final String website;
  final String ceo;
  final int employees;
  final String country;

  CompanyInfoResult({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.industry,
    required this.description,
    required this.website,
    required this.ceo,
    required this.employees,
    required this.country,
  });
}

class GetCompanyInfoUseCase {
  final StockRepository repository;

  GetCompanyInfoUseCase(this.repository);

  Future<CompanyInfoResult> call(String symbol) async {
    if (symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    return await repository.getCompanyInfo(symbol);
  }
}
