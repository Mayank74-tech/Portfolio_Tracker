class HoldingEntity {
  final String symbol;
  final String
      name; // Often redundant if stock data is joined, but useful for lists
  final int quantity;
  final double averageBuyPrice;
  final double currentPrice;
  final double totalInvestment;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercentage;

  HoldingEntity({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averageBuyPrice,
    required this.currentPrice,
    required this.totalInvestment,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
  });

  factory HoldingEntity.fromJson(Map<String, dynamic> json) {
    return HoldingEntity(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      averageBuyPrice: (json['averageBuyPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      totalInvestment: (json['totalInvestment'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      profitLoss: (json['profitLoss'] as num).toDouble(),
      profitLossPercentage: (json['profitLossPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'averageBuyPrice': averageBuyPrice,
      'currentPrice': currentPrice,
      'totalInvestment': totalInvestment,
      'currentValue': currentValue,
      'profitLoss': profitLoss,
      'profitLossPercentage': profitLossPercentage,
    };
  }
}
