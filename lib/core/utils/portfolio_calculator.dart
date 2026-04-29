/// Portfolio calculation helpers used across controllers and repositories.
class PortfolioCalculator {
  PortfolioCalculator._();

  /// Total invested value: sum of (quantity × buyPrice).
  static double totalInvested(List<Map<String, dynamic>> holdings) =>
      holdings.fold(0.0, (sum, h) =>
          sum + _d(h['quantity']) * _d(h['buy_price']));

  /// Current portfolio value: sum of (quantity × currentPrice).
  static double totalCurrentValue(List<Map<String, dynamic>> holdings) =>
      holdings.fold(0.0, (sum, h) {
        final cur = _d(h['current_price'] ?? h['buy_price']);
        return sum + _d(h['quantity']) * cur;
      });

  /// Absolute profit/loss in currency.
  static double totalPL(List<Map<String, dynamic>> holdings) =>
      totalCurrentValue(holdings) - totalInvested(holdings);

  /// Overall P&L as a percentage.
  static double totalPLPercent(List<Map<String, dynamic>> holdings) {
    final invested = totalInvested(holdings);
    return invested == 0
        ? 0.0
        : (totalPL(holdings) / invested) * 100;
  }

  /// Per-holding P&L percentage.
  static double holdingPLPercent(Map<String, dynamic> holding) {
    final buy = _d(holding['buy_price']);
    final cur = _d(holding['current_price'] ?? buy);
    return buy == 0 ? 0.0 : ((cur - buy) / buy) * 100;
  }

  /// Holding weight as percentage of total portfolio.
  static double holdingWeight(
      Map<String, dynamic> holding, double totalValue) {
    if (totalValue == 0) return 0.0;
    final cur = _d(holding['current_price'] ?? holding['buy_price']);
    return (_d(holding['quantity']) * cur / totalValue) * 100;
  }

  /// Sector allocation map: { sectorName → weight% }.
  static Map<String, double> sectorAllocation(
      List<Map<String, dynamic>> holdings) {
    final total = totalCurrentValue(holdings);
    if (total == 0) return {};

    final map = <String, double>{};
    for (final h in holdings) {
      final sector = h['sector']?.toString() ??
          h['finnhubIndustry']?.toString() ??
          'Unknown';
      final cur = _d(h['current_price'] ?? h['buy_price']);
      final value = _d(h['quantity']) * cur;
      map[sector] = (map[sector] ?? 0) + (value / total) * 100;
    }
    return map;
  }

  /// Returns the top N holdings sorted by current value descending.
  static List<Map<String, dynamic>> topHoldings(
      List<Map<String, dynamic>> holdings,
      {int n = 5}) {
    final sorted = [...holdings];
    sorted.sort((a, b) {
      final va = _d(a['current_price'] ?? a['buy_price']) * _d(a['quantity']);
      final vb = _d(b['current_price'] ?? b['buy_price']) * _d(b['quantity']);
      return vb.compareTo(va);
    });
    return sorted.take(n).toList();
  }

  static double _d(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}
