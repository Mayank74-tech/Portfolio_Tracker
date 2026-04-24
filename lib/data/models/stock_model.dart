import 'package:cloud_firestore/cloud_firestore.dart';

class StockModel {
  final String symbol;
  final String name;
  final String? exchange;
  final String? currency;
  final String? type; // Equity, ETF, Index, Mutual Fund, etc.
  final double? currentPrice;
  final double? change;
  final double? changePercent;
  final double? open;
  final double? high;
  final double? low;
  final double? previousClose;
  final int? volume;
  final String? logoUrl;
  final bool isActive;
  final DateTime? lastUpdated;

  const StockModel({
    required this.symbol,
    required this.name,
    this.exchange,
    this.currency = 'INR',
    this.type = 'Equity',
    this.currentPrice,
    this.change,
    this.changePercent,
    this.open,
    this.high,
    this.low,
    this.previousClose,
    this.volume,
    this.logoUrl,
    this.isActive = true,
    this.lastUpdated,
  });

  // Computed properties
  bool get hasPriceData => currentPrice != null && currentPrice! > 0;
  bool get isGain => (change ?? 0) >= 0;
  double get profitLossPercent => changePercent ?? 0.0;
  String get displaySymbol => symbol.toUpperCase();
  String get fullName => '$name ($displaySymbol)';
  String get priceDisplay =>
      hasPriceData ? '₹${currentPrice!.toStringAsFixed(2)}' : '—';

  /// Factory for search results (most common use case)
  factory StockModel.fromSearch(Map<String, dynamic> map) {
    return StockModel(
      symbol: (map['symbol'] ?? map['Symbol'] ?? '').toString().toUpperCase(),
      name: (map['name'] ?? map['Name'] ?? map['companyName'] ?? 'Unknown')
          .toString(),
      exchange:
          map['exchange']?.toString() ?? map['Exchange']?.toString() ?? 'NSE',
      currency:
          map['currency']?.toString() ?? map['Currency']?.toString() ?? 'INR',
      type: map['type']?.toString() ?? map['Type']?.toString() ?? 'Equity',
      currentPrice:
          _toDouble(map['price'] ?? map['currentPrice'] ?? map['05. price']),
      change: _toDouble(map['change'] ?? map['09. change']),
      changePercent:
          _toDouble(map['changePercent'] ?? map['10. change percent']),
      logoUrl: map['logo']?.toString() ?? map['logoUrl']?.toString(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Factory from Finnhub quote
  factory StockModel.fromFinnhub(
      Map<String, dynamic> map, String symbol, String name) {
    final current = _toDouble(map['c']);
    final prev = _toDouble(map['pc']);
    return StockModel(
      symbol: symbol.toUpperCase(),
      name: name,
      exchange: map['exchange']?.toString() ?? 'NSE',
      currentPrice: current,
      change: _toDouble(map['d']),
      changePercent: _toDouble(map['dp']),
      open: _toDouble(map['o']),
      high: _toDouble(map['h']),
      low: _toDouble(map['l']),
      previousClose: prev,
      volume: _toInt(map['v']),
      lastUpdated: DateTime.now(),
    );
  }

  /// Factory from Firestore document
  factory StockModel.fromMap(Map<String, dynamic> map, String id) {
    return StockModel(
      symbol: id.toUpperCase(),
      name: map['name']?.toString() ?? '',
      exchange: map['exchange']?.toString(),
      currency: map['currency']?.toString() ?? 'INR',
      type: map['type']?.toString() ?? 'Equity',
      currentPrice: _toDouble(map['current_price']),
      change: _toDouble(map['change']),
      changePercent: _toDouble(map['change_percent']),
      open: _toDouble(map['open']),
      high: _toDouble(map['high']),
      low: _toDouble(map['low']),
      previousClose: _toDouble(map['previous_close']),
      volume: _toInt(map['volume']),
      logoUrl: map['logo_url']?.toString(),
      isActive: map['is_active'] as bool? ?? true,
      lastUpdated: map['last_updated'] is Timestamp
          ? (map['last_updated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'exchange': exchange,
      'currency': currency,
      'type': type,
      if (currentPrice != null) 'current_price': currentPrice,
      if (change != null) 'change': change,
      if (changePercent != null) 'change_percent': changePercent,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (previousClose != null) 'previous_close': previousClose,
      if (volume != null) 'volume': volume,
      if (logoUrl != null) 'logo_url': logoUrl,
      'is_active': isActive,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    };
  }

  StockModel copyWith({
    String? symbol,
    String? name,
    String? exchange,
    String? currency,
    String? type,
    double? currentPrice,
    double? change,
    double? changePercent,
    double? open,
    double? high,
    double? low,
    double? previousClose,
    int? volume,
    String? logoUrl,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return StockModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      previousClose: previousClose ?? this.previousClose,
      volume: volume ?? this.volume,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll('%', '').trim());
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  String toString() => 'StockModel($symbol - $name)';
}
