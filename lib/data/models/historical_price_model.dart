class HistoricalPriceModel {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double adjustedClose;
  final int volume;

  const HistoricalPriceModel({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.adjustedClose,
    required this.volume,
  });

  double get priceChange => close - open;
  double get priceChangePct => open == 0 ? 0 : (priceChange / open) * 100;
  bool get isGain => close >= open;

  factory HistoricalPriceModel.fromMap(
      String dateKey, Map<String, dynamic> map) {
    return HistoricalPriceModel(
      date: DateTime.tryParse(dateKey) ?? DateTime.now(),
      open: _toDouble(map['1. open'] ?? map['open']),
      high: _toDouble(map['2. high'] ?? map['high']),
      low: _toDouble(map['3. low'] ?? map['low']),
      close: _toDouble(map['4. close'] ?? map['close']),
      adjustedClose: _toDouble(map['5. adjusted close'] ??
          map['adjusted_close'] ??
          map['4. close'] ??
          map['close']),
      volume: _toLong(map['6. volume'] ?? map['5. volume'] ?? map['volume']),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'adjusted_close': adjustedClose,
        'volume': volume,
      };

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toLong(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  String toString() =>
      'HistoricalPriceModel(date: ${date.toIso8601String()}, close: $close)';
}
