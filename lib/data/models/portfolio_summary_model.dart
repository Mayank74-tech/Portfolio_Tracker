class PortfolioSummaryModel {
  final double totalValue;
  final double totalInvestment;
  final double profitLoss;
  final double profitLossPct;
  final double todayChange;
  final double todayChangePct;
  final int holdingCount;
  final int gainers;
  final int losers;
  final String? topGainerSymbol;
  final String? topLoserSymbol;

  const PortfolioSummaryModel({
    required this.totalValue,
    required this.totalInvestment,
    required this.profitLoss,
    required this.profitLossPct,
    required this.todayChange,
    required this.todayChangePct,
    required this.holdingCount,
    required this.gainers,
    required this.losers,
    this.topGainerSymbol,
    this.topLoserSymbol,
  });

  bool get isOverallGain => profitLoss >= 0;
  bool get isTodayGain => todayChange >= 0;

  factory PortfolioSummaryModel.empty() => const PortfolioSummaryModel(
        totalValue: 0,
        totalInvestment: 0,
        profitLoss: 0,
        profitLossPct: 0,
        todayChange: 0,
        todayChangePct: 0,
        holdingCount: 0,
        gainers: 0,
        losers: 0,
      );

  factory PortfolioSummaryModel.fromMap(Map<String, dynamic> map) {
    return PortfolioSummaryModel(
      totalValue: _toDouble(map['total_value']),
      totalInvestment: _toDouble(map['total_investment']),
      profitLoss: _toDouble(map['profit_loss']),
      profitLossPct: _toDouble(map['profit_loss_percent']),
      todayChange: _toDouble(map['today_change']),
      todayChangePct: _toDouble(map['today_change_percent']),
      holdingCount: _toInt(map['holding_count'] ?? map['holdings_count']),
      gainers: _toInt(map['gainers']),
      losers: _toInt(map['losers']),
      topGainerSymbol: map['top_gainer_symbol']?.toString(),
      topLoserSymbol: map['top_loser_symbol']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'total_value': totalValue,
        'total_investment': totalInvestment,
        'profit_loss': profitLoss,
        'profit_loss_percent': profitLossPct,
        'today_change': todayChange,
        'today_change_percent': todayChangePct,
        'holding_count': holdingCount,
        'gainers': gainers,
        'losers': losers,
        if (topGainerSymbol != null) 'top_gainer_symbol': topGainerSymbol,
        if (topLoserSymbol != null) 'top_loser_symbol': topLoserSymbol,
      };

  PortfolioSummaryModel copyWith({
    double? totalValue,
    double? totalInvestment,
    double? profitLoss,
    double? profitLossPct,
    double? todayChange,
    double? todayChangePct,
    int? holdingCount,
    int? gainers,
    int? losers,
    String? topGainerSymbol,
    String? topLoserSymbol,
  }) {
    return PortfolioSummaryModel(
      totalValue: totalValue ?? this.totalValue,
      totalInvestment: totalInvestment ?? this.totalInvestment,
      profitLoss: profitLoss ?? this.profitLoss,
      profitLossPct: profitLossPct ?? this.profitLossPct,
      todayChange: todayChange ?? this.todayChange,
      todayChangePct: todayChangePct ?? this.todayChangePct,
      holdingCount: holdingCount ?? this.holdingCount,
      gainers: gainers ?? this.gainers,
      losers: losers ?? this.losers,
      topGainerSymbol: topGainerSymbol ?? this.topGainerSymbol,
      topLoserSymbol: topLoserSymbol ?? this.topLoserSymbol,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  String toString() =>
      'PortfolioSummaryModel(value: $totalValue, pl: $profitLoss)';
}
