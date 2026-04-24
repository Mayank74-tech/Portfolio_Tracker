class PriceModel {
  final String symbol;
  final double currentPrice;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double previousClose;
  final double change;
  final double changePct;
  final int volume;
  final DateTime? timestamp;

  const PriceModel({
    required this.symbol,
    required this.currentPrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.change,
    required this.changePct,
    required this.volume,
    this.timestamp,
  });

  bool get isGain => change >= 0;

  factory PriceModel.fromFinnhubQuote(String symbol, Map<String, dynamic> map) {
    final current = _toDouble(map['c']);
    final prev = _toDouble(map['pc']);
    return PriceModel(
      symbol: symbol,
      currentPrice: current,
      openPrice: _toDouble(map['o']),
      highPrice: _toDouble(map['h']),
      lowPrice: _toDouble(map['l']),
      previousClose: prev,
      change: _toDouble(map['d']),
      changePct: _toDouble(map['dp']),
      volume: _toInt(map['v']),
      timestamp: map['t'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (_toDouble(map['t']) * 1000).toInt())
          : null,
    );
  }

  factory PriceModel.fromAlphaVantageQuote(
      String symbol, Map<String, dynamic> map) {
    final globalQuote = map['Global Quote'] as Map<String, dynamic>? ?? map;
    final current = _toDouble(globalQuote['05. price'] ?? globalQuote['price']);
    final prev = _toDouble(
        globalQuote['08. previous close'] ?? globalQuote['previous_close']);
    return PriceModel(
      symbol: symbol,
      currentPrice: current,
      openPrice: _toDouble(globalQuote['02. open'] ?? globalQuote['open']),
      highPrice: _toDouble(globalQuote['03. high'] ?? globalQuote['high']),
      lowPrice: _toDouble(globalQuote['04. low'] ?? globalQuote['low']),
      previousClose: prev,
      change: _toDouble(globalQuote['09. change'] ?? globalQuote['change']),
      changePct: _toDoubleFromPct(
          globalQuote['10. change percent'] ?? globalQuote['change_percent']),
      volume: _toInt(globalQuote['06. volume'] ?? globalQuote['volume']),
      timestamp: null,
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'current_price': currentPrice,
        'open_price': openPrice,
        'high_price': highPrice,
        'low_price': lowPrice,
        'previous_close': previousClose,
        'change': change,
        'change_pct': changePct,
        'volume': volume,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static double _toDoubleFromPct(Object? value) {
    final s = value?.toString().replaceAll('%', '').trim() ?? '';
    return double.tryParse(s) ?? 0.0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  String toString() =>
      'PriceModel(symbol: $symbol, price: $currentPrice, change: $changePct%)';
}
