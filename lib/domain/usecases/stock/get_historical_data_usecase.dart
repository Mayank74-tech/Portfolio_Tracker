import 'dart:async';

abstract class StockRepository {
  Future<List<HistoricalPricePoint>> getHistoricalData({
    required String symbol,
    required String interval, // e.g., '1d', '1w', '1m', '1y'
    required DateTime from,
    required DateTime to,
  });
}

class HistoricalPricePoint {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HistoricalPricePoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class GetHistoricalDataParams {
  final String symbol;
  final String interval;
  final DateTime from;
  final DateTime to;

  GetHistoricalDataParams({
    required this.symbol,
    required this.interval,
    required this.from,
    required this.to,
  });
}

class GetHistoricalDataUseCase {
  final StockRepository repository;

  GetHistoricalDataUseCase(this.repository);

  Future<List<HistoricalPricePoint>> call(
      GetHistoricalDataParams params) async {
    if (params.symbol.trim().isEmpty) {
      throw ArgumentError('Symbol cannot be empty.');
    }
    if (params.from.isAfter(params.to)) {
      throw ArgumentError('From date cannot be after to date.');
    }
    if (!['1d', '1w', '1m', '1y'].contains(params.interval)) {
      throw ArgumentError('Interval must be one of: 1d, 1w, 1m, 1y.');
    }
    return await repository.getHistoricalData(
      symbol: params.symbol,
      interval: params.interval,
      from: params.from,
      to: params.to,
    );
  }
}
