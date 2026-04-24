class StockEntity {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercentage;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final int volume;

  StockEntity({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercentage,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.volume,
  });

  factory StockEntity.fromJson(Map<String, dynamic> json) {
    return StockEntity(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
      highPrice: (json['highPrice'] as num).toDouble(),
      lowPrice: (json['lowPrice'] as num).toDouble(),
      openPrice: (json['openPrice'] as num).toDouble(),
      volume: json['volume'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'change': change,
      'changePercentage': changePercentage,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'openPrice': openPrice,
      'volume': volume,
    };
  }
}
