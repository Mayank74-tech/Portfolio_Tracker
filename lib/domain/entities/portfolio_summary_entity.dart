class PortfolioSummaryEntity {
  final double totalBalance;
  final double totalInvestment;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final double dayChange;
  final double dayChangePercentage;

  PortfolioSummaryEntity({
    required this.totalBalance,
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.dayChange,
    required this.dayChangePercentage,
  });

  factory PortfolioSummaryEntity.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryEntity(
      totalBalance: (json['totalBalance'] as num).toDouble(),
      totalInvestment: (json['totalInvestment'] as num).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] as num).toDouble(),
      totalProfitLossPercentage:
          (json['totalProfitLossPercentage'] as num).toDouble(),
      dayChange: (json['dayChange'] as num).toDouble(),
      dayChangePercentage: (json['dayChangePercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBalance': totalBalance,
      'totalInvestment': totalInvestment,
      'totalProfitLoss': totalProfitLoss,
      'totalProfitLossPercentage': totalProfitLossPercentage,
      'dayChange': dayChange,
      'dayChangePercentage': dayChangePercentage,
    };
  }
}
