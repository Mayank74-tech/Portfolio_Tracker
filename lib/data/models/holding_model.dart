import 'package:cloud_firestore/cloud_firestore.dart';

class HoldingModel {
  final String id;
  final String stockSymbol;
  final String stockName;
  final String exchange;
  final double quantity;
  final double buyPrice;
  final double currentPrice;
  final String platform;
  final DateTime? buyDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HoldingModel({
    required this.id,
    required this.stockSymbol,
    required this.stockName,
    required this.exchange,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.platform,
    this.buyDate,
    this.createdAt,
    this.updatedAt,
  });

  // Computed fields
  double get currentValue => currentPrice * quantity;
  double get investedValue => buyPrice * quantity;
  double get profitLoss => currentValue - investedValue;
  double get profitLossPct =>
      investedValue == 0 ? 0 : (profitLoss / investedValue) * 100;
  bool get isGain => profitLoss >= 0;

  factory HoldingModel.fromMap(Map<String, dynamic> map, String id) {
    return HoldingModel(
      id: id,
      stockSymbol:
          map['stock_symbol']?.toString() ?? map['symbol']?.toString() ?? '',
      stockName: map['stock_name']?.toString() ?? map['name']?.toString() ?? '',
      exchange: map['exchange']?.toString() ?? '',
      quantity: _toDouble(map['quantity']),
      buyPrice: _toDouble(map['buy_price']),
      currentPrice: _toDouble(map['current_price'] ?? map['buy_price']),
      platform: map['platform']?.toString() ?? 'Manual',
      buyDate: _parseDate(map['buy_date']),
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : null,
      updatedAt: map['updated_at'] is Timestamp
          ? (map['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'stock_symbol': stockSymbol,
        'stock_name': stockName,
        'exchange': exchange,
        'quantity': quantity,
        'buy_price': buyPrice,
        'current_price': currentPrice,
        'platform': platform,
        if (buyDate != null) 'buy_date': buyDate!.toIso8601String(),
      };

  HoldingModel copyWith({
    String? id,
    String? stockSymbol,
    String? stockName,
    String? exchange,
    double? quantity,
    double? buyPrice,
    double? currentPrice,
    String? platform,
    DateTime? buyDate,
  }) {
    return HoldingModel(
      id: id ?? this.id,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      stockName: stockName ?? this.stockName,
      exchange: exchange ?? this.exchange,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      platform: platform ?? this.platform,
      buyDate: buyDate ?? this.buyDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'HoldingModel(symbol: $stockSymbol, qty: $quantity, pl: $profitLoss)';
}
