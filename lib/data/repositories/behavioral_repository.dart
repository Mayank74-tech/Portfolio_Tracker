// lib/data/repositories/behavioral_repository.dart

import '../services/local/behavioral_tracker_service.dart';

class BehavioralRepository {
  BehavioralRepository({
    BehavioralTrackerService? tracker,
  }) : _tracker = tracker ?? BehavioralTrackerService();

  final BehavioralTrackerService _tracker;

  // ── Feature 1: Memory vs Reality ──────────────────────────────────────────

  /// Compare user belief against actual portfolio data
  Map<String, dynamic> analyzeMemoryVsReality({
    required String userBelief, // what user said is worst
    required List<Map<String, dynamic>> holdings,
  }) {
    if (holdings.isEmpty) {
      return {'error': 'No holdings to compare'};
    }

    // Calculate actual P&L % for each holding
    final ranked = holdings.map((h) {
      final buy = _toDouble(h['buy_price']);
      final cur = _toDouble(h['current_price'] ?? h['buy_price']);
      final plPct = buy == 0 ? 0.0 : ((cur - buy) / buy) * 100;
      return {
        'symbol': (h['stock_symbol'] ?? h['symbol']).toString(),
        'pl_percent': plPct,
      };
    }).toList()
      ..sort((a, b) =>
          (_toDouble(a['pl_percent'])).compareTo(_toDouble(b['pl_percent'])));

    // ranked[0] is actual worst
    final actualWorst = ranked.first['symbol'].toString();
    final actualBest = ranked.last['symbol'].toString();
    final wasCorrect = actualWorst.toUpperCase() ==
        userBelief.toUpperCase();

    // Find rank of what user said
    final userBeliefRank = ranked.indexWhere((r) =>
    r['symbol'].toString().toUpperCase() ==
        userBelief.toUpperCase()) +
        1;

    String explanation;
    if (wasCorrect) {
      explanation =
      'You correctly identified $actualWorst as your worst performer. '
          'Your memory is well-calibrated.';
    } else if (userBeliefRank <= 0) {
      explanation =
      'You mentioned $userBelief, but it\'s not in your portfolio. '
          'Your actual worst performer is $actualWorst.';
    } else {
      final ordinal = _ordinal(userBeliefRank);
      explanation =
      'You believe $userBelief is your worst performer, but it\'s actually '
          'your $ordinal worst. Your actual worst is $actualWorst. '
          'You\'re overweighing recent losses in $userBelief.';
    }

    return {
      'user_belief': userBelief,
      'actual_worst': actualWorst,
      'actual_best': actualBest,
      'was_correct': wasCorrect,
      'user_belief_rank': userBeliefRank,
      'explanation': explanation,
      'ranked': ranked,
    };
  }

  // ── Feature 3: Attention-Adjusted Value ───────────────────────────────────

  Map<String, dynamic> getAttentionAnalysis(
      List<Map<String, dynamic>> holdings) {
    final attentionMap = _tracker.getAttentionMap();
    int totalAttention = 0;
    for (final int v in attentionMap.values) {
      totalAttention = totalAttention + v;
    }

    if (totalAttention == 0) {
      return {'error': 'No attention data yet. Browse your stocks first.'};
    }

    final results = <Map<String, dynamic>>[];

    for (final h in holdings) {
      final symbol =
      (h['stock_symbol'] ?? h['symbol']).toString();
      final buy = _toDouble(h['buy_price']);
      final qty = _toDouble(h['quantity']);
      final cur = _toDouble(h['current_price'] ?? buy);

      final realValue = cur * qty;
      final attentionSeconds = attentionMap[symbol] ?? 0;
      final attentionPct = totalAttention == 0
          ? 0.0
          : (attentionSeconds / totalAttention) * 100;

      // Real allocation as % of total portfolio
      final totalPortfolio = holdings.fold(
        0.0,
            (sum, h2) =>
        sum +
            _toDouble(h2['current_price'] ?? h2['buy_price']) *
                _toDouble(h2['quantity']),
      );
      final realAllocationPct =
      totalPortfolio == 0 ? 0.0 : (realValue / totalPortfolio) * 100;

      results.add({
        'symbol': symbol,
        'real_allocation_pct': realAllocationPct,
        'attention_pct': attentionPct,
        'attention_seconds': attentionSeconds,
        'days_since_viewed': _tracker.daysSinceLastView(symbol),
        'gap': attentionPct - realAllocationPct,
        // positive = overattended, negative = underattended
      });
    }

    results.sort((a, b) =>
        (_toDouble(b['gap'])).compareTo(_toDouble(a['gap'])));

    final mostOverattended = results.isNotEmpty
        ? results.first['symbol'].toString()
        : null;
    final mostIgnored = results.isNotEmpty
        ? results.last['symbol'].toString()
        : null;

    return {
      'items': results,
      'most_overattended': mostOverattended,
      'most_ignored': mostIgnored,
      'insight': mostOverattended != null
          ? '$mostOverattended occupies '
          '${_toDouble(results.first['attention_pct']).toStringAsFixed(1)}% '
          'of your attention but only '
          '${_toDouble(results.first['real_allocation_pct']).toStringAsFixed(1)}% '
          'of your portfolio value.'
          : 'Keep browsing to build attention data.',
    };
  }

  // ── Feature 4: Uncertainty Visualizer ─────────────────────────────────────

  Map<String, dynamic> getUncertaintyBands(
      List<Map<String, dynamic>> holdings) {
    double totalValue = 0;
    double weightedVolatility = 0;

    for (final h in holdings) {
      final buy = _toDouble(h['buy_price']);
      final cur = _toDouble(h['current_price'] ?? buy);
      final qty = _toDouble(h['quantity']);
      final value = cur * qty;
      totalValue += value;

      // Estimate volatility from P&L % as proxy
      final plPct =
      buy == 0 ? 0.0 : ((cur - buy) / buy).abs() * 100;
      weightedVolatility +=
          value * (plPct.clamp(2.0, 40.0) / 100);
    }

    if (totalValue == 0) return {'error': 'No portfolio data'};

    final avgVol = weightedVolatility / totalValue;

    // 1-month scenario bands
    final optimistic = totalValue * (1 + avgVol * 1.5);
    final likely_high = totalValue * (1 + avgVol * 0.8);
    final likely_low = totalValue * (1 - avgVol * 0.8);
    final pessimistic = totalValue * (1 - avgVol * 1.5);

    return {
      'current': totalValue,
      'optimistic': optimistic,
      'likely_high': likely_high,
      'likely_low': likely_low,
      'pessimistic': pessimistic,
      'volatility_pct': avgVol * 100,
      'confidence_interval':
      '₹${_fmt(likely_low)} – ₹${_fmt(likely_high)}',
    };
  }

  // ── Feature 5: Decision Half-Life ─────────────────────────────────────────

  List<Map<String, dynamic>> getDecisionHalfLives(
      List<Map<String, dynamic>> holdings) {
    return holdings.map((h) {
      final symbol =
      (h['stock_symbol'] ?? h['symbol']).toString();
      final buyDateRaw = h['buy_date']?.toString();
      final buyDate = buyDateRaw != null
          ? DateTime.tryParse(buyDateRaw) ?? DateTime.now()
          : DateTime.now();
      final ageDays =
      _tracker.decisionAgeDays(symbol, buyDate);
      final score = _tracker.halfLifeScore(ageDays);
      final label = _tracker.halfLifeLabel(ageDays);
      final buy = _toDouble(h['buy_price']);
      final cur =
      _toDouble(h['current_price'] ?? h['buy_price']);
      final plPct =
      buy == 0 ? 0.0 : ((cur - buy) / buy) * 100;

      return {
        'symbol': symbol,
        'age_days': ageDays,
        'score': score,
        'label': label,
        'pl_percent': plPct,
        'buy_date': buyDateRaw ?? 'Unknown',
        'needs_review': ageDays > 90,
      };
    }).toList()
      ..sort((a, b) =>
          (b['age_days'] as int).compareTo(a['age_days'] as int));
  }

  // ── Feature 8: Silence of Winners ─────────────────────────────────────────

  List<Map<String, dynamic>> getSilentWinners(
      List<Map<String, dynamic>> holdings) {
    final results = <Map<String, dynamic>>[];

    for (final h in holdings) {
      final symbol =
      (h['stock_symbol'] ?? h['symbol']).toString();
      final buy = _toDouble(h['buy_price']);
      final cur =
      _toDouble(h['current_price'] ?? buy);
      final plPct =
      buy == 0 ? 0.0 : ((cur - buy) / buy) * 100;
      final daysSince = _tracker.daysSinceLastView(symbol);

      // A "silent winner" = positive return + not viewed recently
      if (plPct > 5 && daysSince > 7) {
        results.add({
          'symbol': symbol,
          'pl_percent': plPct,
          'days_since_viewed': daysSince,
          'insight':
          'You haven\'t checked $symbol in $daysSince days, '
              'but it\'s up ${plPct.toStringAsFixed(1)}%.',
        });
      }
    }

    results.sort((a, b) =>
        (_toDouble(b['pl_percent']))
            .compareTo(_toDouble(a['pl_percent'])));
    return results;
  }

  // ── Feature 9: Cascading Failure ──────────────────────────────────────────

  Map<String, dynamic> getCascadingRisk(
      List<Map<String, dynamic>> holdings) {
    // Group by sector/finnhubIndustry
    final sectorMap = <String, double>{};
    double totalValue = 0;

    for (final h in holdings) {
      final sector = (h['sector'] ??
          h['finnhubIndustry'] ??
          'Unknown')
          .toString();
      final cur =
      _toDouble(h['current_price'] ?? h['buy_price']);
      final qty = _toDouble(h['quantity']);
      final value = cur * qty;
      sectorMap[sector] = (sectorMap[sector] ?? 0) + value;
      totalValue += value;
    }

    if (totalValue == 0) return {'error': 'No data'};

    final sectorPcts = sectorMap.map(
          (s, v) => MapEntry(s, (v / totalValue) * 100),
    );

    // Find dominant sector
    final sorted = sectorPcts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSector =
    sorted.isNotEmpty ? sorted.first.key : 'Unknown';
    final topPct =
    sorted.isNotEmpty ? sorted.first.value : 0.0;

    // Stocks in top sector
    final affected = holdings
        .where((h) =>
    (h['sector'] ??
        h['finnhubIndustry'] ??
        'Unknown')
        .toString() ==
        topSector)
        .map((h) =>
        (h['stock_symbol'] ?? h['symbol']).toString())
        .toList();

    return {
      'sector_breakdown': sectorPcts,
      'top_sector': topSector,
      'top_sector_pct': topPct,
      'affected_symbols': affected,
      'cascade_insight':
      'A drop in $topSector sector could impact '
          '${topPct.toStringAsFixed(1)}% of your portfolio '
          '(${affected.join(", ")}).',
      'is_concentrated': topPct > 40,
    };
  }

  // ── Feature 10: Identity Drift ─────────────────────────────────────────────

  Map<String, dynamic> getIdentityDrift(
      List<Map<String, dynamic>> holdings) {
    final profile = _tracker.getOrCreateProfile();
    final decisions = _tracker.getAllDecisions();

    // Analyze last 30 days vs older decisions
    final now = DateTime.now();
    final recent = decisions
        .where((d) =>
    now.difference(d.timestamp).inDays <= 30 &&
        d.action == 'buy')
        .toList();
    final older = decisions
        .where((d) =>
    now.difference(d.timestamp).inDays > 30 &&
        now.difference(d.timestamp).inDays <= 90 &&
        d.action == 'buy')
        .toList();

    // Infer style from holding periods
    String inferredStyle = 'unknown';
    if (recent.length >= 3) {
      // Multiple buys in 30 days = active trader
      inferredStyle = 'short_term';
    } else if (recent.isEmpty && older.isNotEmpty) {
      inferredStyle = 'long_term';
    } else {
      inferredStyle = 'moderate';
    }

    final hasDrifted =
        profile.investingStyle != 'unknown' &&
            profile.investingStyle != inferredStyle;

    final styleHistory = profile.styleHistory;

    return {
      'stated_style': profile.investingStyle,
      'inferred_style': inferredStyle,
      'has_drifted': hasDrifted,
      'style_history': styleHistory,
      'recent_buy_count': recent.length,
      'drift_insight': hasDrifted
          ? 'You identified as a "${_styleLabel(profile.investingStyle)}" '
          'investor, but your recent behavior suggests '
          '"${_styleLabel(inferredStyle)}" trading patterns.'
          : 'Your investing behavior is consistent with your stated style.',
      'statedRiskTolerance': profile.statedRiskTolerance,
    };
  }

  // ── Feature 11: Confidence Illusion ───────────────────────────────────────

  Map<String, dynamic> getConfidenceIllusion() {
    final profile = _tracker.getOrCreateProfile();
    final scores = profile.confidenceScores;
    final returns = profile.actualReturns;

    if (scores.length < 3) {
      return {
        'error':
        'Need at least 3 decisions to analyze confidence patterns.',
        'count': scores.length,
      };
    }

    // Calculate correlation between confidence and return
    final n = scores.length;
    final avgConf =
        scores.fold(0.0, (a, b) => a + b) / n;
    final avgRet =
        returns.fold(0.0, (a, b) => a + b) / n;

    double numerator = 0;
    double denomConf = 0;
    double denomRet = 0;
    for (int i = 0; i < n; i++) {
      numerator += (scores[i] - avgConf) * (returns[i] - avgRet);
      denomConf += (scores[i] - avgConf) * (scores[i] - avgConf);
      denomRet += (returns[i] - avgRet) * (returns[i] - avgRet);
    }

    final correlation = (denomConf * denomRet) == 0
        ? 0.0
        : numerator /
        (denomConf * denomRet == 0
            ? 1
            : (denomConf * denomRet));

    String insight;
    if (correlation > 0.3) {
      insight =
      'Your confidence is a good predictor of returns. Well calibrated.';
    } else if (correlation < -0.1) {
      insight =
      'Higher confidence actually correlates with lower returns for you. '
          'Overconfidence may be hurting your decisions.';
    } else {
      insight =
      'Your confidence has no meaningful relationship with your actual returns. '
          'Consider slowing down before high-confidence decisions.';
    }

    return {
      'correlation': correlation,
      'data_points': n,
      'avg_confidence': avgConf,
      'avg_return': avgRet,
      'insight': insight,
      'scores': scores,
      'returns': returns,
    };
  }

  // ── Feature 12: Friction Score ─────────────────────────────────────────────

  Map<String, dynamic> getDecisionFriction() {
    final avgSeconds =
    _tracker.averageDecisionFrictionSeconds();
    final label = _tracker.frictionLabel();
    final decisions = _tracker
        .getAllDecisions()
        .where((d) => d.action == 'buy')
        .toList();

    return {
      'avg_seconds': avgSeconds,
      'avg_minutes': (avgSeconds / 60).toStringAsFixed(1),
      'label': label,
      'total_buy_decisions': decisions.length,
      'is_impulsive': avgSeconds < 120 && decisions.length >= 3,
      'insight': avgSeconds == 0
          ? 'Make your first purchase to track decision speed.'
          : 'On average you make buy decisions in '
          '${(avgSeconds / 60).toStringAsFixed(0)} minutes. $label',
    };
  }

  // ── Feature 13: What You Didn't Do ────────────────────────────────────────

  Map<String, dynamic> getInactionAnalysis() {
    final profile = _tracker.getOrCreateProfile();
    final considered = profile.rebalanceConsideredCount;
    final acted = profile.rebalanceActedCount;
    final skipped = considered - acted;

    // Portfolio drift = how much allocation has shifted
    // (simplified — in real app compare current vs target allocation)
    final driftScore =
    skipped > 0 ? (skipped * 3.0).clamp(0.0, 30.0) : 0.0;

    return {
      'rebalance_considered': considered,
      'rebalance_acted': acted,
      'rebalance_skipped': skipped,
      'drift_estimate_pct': driftScore,
      'insight': skipped == 0
          ? 'No skipped rebalancing events recorded yet.'
          : 'You considered rebalancing $considered times but only acted $acted times. '
          'Your portfolio may have drifted by ~${driftScore.toStringAsFixed(1)}% '
          'from your intended allocation.',
    };
  }

  // ── Feature 14: Delayed Truth ─────────────────────────────────────────────

  List<Map<String, dynamic>> getDelayedTruths(
      List<Map<String, dynamic>> holdings) {
    final decisions = _tracker
        .getAllDecisions()
        .where((d) =>
    d.action == 'buy' &&
        DateTime.now().difference(d.timestamp).inDays >= 7)
        .toList();

    final truths = <Map<String, dynamic>>[];

    for (final d in decisions) {
      // Find matching holding
      final holding = holdings.firstWhere(
            (h) =>
        (h['stock_symbol'] ?? h['symbol'])
            .toString()
            .toUpperCase() ==
            d.symbol.toUpperCase(),
        orElse: () => {},
      );
      if (holding.isEmpty) continue;

      final currentPrice =
      _toDouble(holding['current_price'] ?? holding['buy_price']);
      final priceThen = d.stockPriceAtTime;
      if (priceThen == 0) continue;

      final changeFromDecision =
          ((currentPrice - priceThen) / priceThen) * 100;
      final daysSince =
          DateTime.now().difference(d.timestamp).inDays;

      truths.add({
        'symbol': d.symbol,
        'days_ago': daysSince,
        'price_then': priceThen,
        'price_now': currentPrice,
        'change_pct': changeFromDecision,
        'insight': changeFromDecision >= 0
            ? 'Your decision to buy ${d.symbol} $daysSince days ago '
            'is up ${changeFromDecision.toStringAsFixed(1)}%. Good call.'
            : 'Your decision to buy ${d.symbol} $daysSince days ago '
            'is down ${changeFromDecision.abs().toStringAsFixed(1)}%. '
            'Worth reviewing your thesis.',
      });
    }

    truths.sort((a, b) =>
        (_toDouble(a['change_pct']))
            .compareTo(_toDouble(b['change_pct'])));
    return truths;
  }

  // ── Feature 15: Internal Conflict ─────────────────────────────────────────

  Map<String, dynamic> getInternalConflict(
      List<Map<String, dynamic>> holdings) {
    final profile = _tracker.getOrCreateProfile();
    final stated = profile.statedRiskTolerance;

    // Calculate actual risk from portfolio volatility proxy
    double totalVolatility = 0;
    int count = 0;
    for (final h in holdings) {
      final buy = _toDouble(h['buy_price']);
      final cur = _toDouble(h['current_price'] ?? buy);
      if (buy == 0) continue;
      totalVolatility += ((cur - buy) / buy).abs() * 100;
      count++;
    }
    final avgVolatility =
    count == 0 ? 0.0 : totalVolatility / count;

    String inferredRisk;
    if (avgVolatility < 10) {
      inferredRisk = 'low';
    } else if (avgVolatility < 25) {
      inferredRisk = 'medium';
    } else {
      inferredRisk = 'high';
    }

    final hasConflict = stated != inferredRisk &&
        stated != 'unknown';

    String insight;
    if (!hasConflict) {
      insight =
      'Your portfolio risk matches your stated preference. '
          'You are a $stated-risk investor in practice.';
    } else if (stated == 'low' && inferredRisk == 'high') {
      insight =
      'You describe yourself as risk-averse, but your portfolio '
          'shows high volatility (${avgVolatility.toStringAsFixed(1)}% avg swing). '
          'Your actions suggest higher risk tolerance than stated.';
    } else if (stated == 'high' && inferredRisk == 'low') {
      insight =
      'You describe yourself as a high-risk investor, but your '
          'portfolio is quite conservative. '
          'Consider if this matches your actual goals.';
    } else {
      insight =
      'Slight mismatch between your stated risk ($stated) '
          'and actual portfolio behavior ($inferredRisk).';
    }

    return {
      'stated_risk': stated,
      'inferred_risk': inferredRisk,
      'avg_volatility': avgVolatility,
      'has_conflict': hasConflict,
      'insight': insight,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  static String _styleLabel(String style) {
    switch (style) {
      case 'long_term': return 'long-term';
      case 'short_term': return 'short-term';
      case 'swing': return 'swing';
      default: return style;
    }
  }
}