import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistItemModel {
  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final double? currentPrice;
  final double? change;
  final double? changePct;
  final String? alertType; // 'above', 'below', null
  final double? alertPrice;
  final bool alertTriggered;
  final DateTime? addedAt;

  const WatchlistItemModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    this.currentPrice,
    this.change,
    this.changePct,
    this.alertType,
    this.alertPrice,
    this.alertTriggered = false,
    this.addedAt,
  });

  bool get isGain => (changePct ?? 0) >= 0;
  bool get hasAlert => alertType != null && alertPrice != null;

  bool get shouldTriggerAlert {
    if (!hasAlert || currentPrice == null) return false;
    if (alertType == 'above') return currentPrice! >= alertPrice!;
    if (alertType == 'below') return currentPrice! <= alertPrice!;
    return false;
  }

  factory WatchlistItemModel.fromMap(Map<String, dynamic> map, String id) {
    return WatchlistItemModel(
      id: id,
      symbol:
          map['symbol']?.toString() ?? map['stock_symbol']?.toString() ?? '',
      name: map['name']?.toString() ?? map['stock_name']?.toString() ?? '',
      exchange: map['exchange']?.toString() ?? '',
      currentPrice: _toDouble(map['current_price']),
      change: _toDouble(map['change']),
      changePct: _toDouble(map['change_pct']),
      alertType: map['alert_type']?.toString(),
      alertPrice: _toDouble(map['alert_price']),
      alertTriggered: map['alert_triggered'] as bool? ?? false,
      addedAt: map['added_at'] is Timestamp
          ? (map['added_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'name': name,
        'exchange': exchange,
        if (currentPrice != null) 'current_price': currentPrice,
        if (change != null) 'change': change,
        if (changePct != null) 'change_pct': changePct,
        if (alertType != null) 'alert_type': alertType,
        if (alertPrice != null) 'alert_price': alertPrice,
        'alert_triggered': alertTriggered,
      };

  WatchlistItemModel copyWith({
    String? id,
    String? symbol,
    String? name,
    String? exchange,
    double? currentPrice,
    double? change,
    double? changePct,
    String? alertType,
    double? alertPrice,
    bool? alertTriggered,
  }) {
    return WatchlistItemModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePct: changePct ?? this.changePct,
      alertType: alertType ?? this.alertType,
      alertPrice: alertPrice ?? this.alertPrice,
      alertTriggered: alertTriggered ?? this.alertTriggered,
      addedAt: addedAt,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  String toString() =>
      'WatchlistItemModel(symbol: $symbol, price: $currentPrice)';
}
