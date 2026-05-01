// lib/data/models/behavioral/decision_event_model.dart

import 'package:hive/hive.dart';

part 'decision_event_model.g.dart';

@HiveType(typeId: 22)
class DecisionEventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String action; // 'view', 'buy', 'consider_sell', 'rebalance_skipped'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final double portfolioValueAtTime;

  @HiveField(5)
  final double stockPriceAtTime;

  @HiveField(6)
  final int secondsSinceLastView;
  // for Decision Friction Score

  @HiveField(7)
  final Map<String, dynamic> context;
  // snapshot: { sector_allocation, top_movers, market_mood }

  DecisionEventModel({
    required this.id,
    required this.symbol,
    required this.action,
    required this.timestamp,
    required this.portfolioValueAtTime,
    required this.stockPriceAtTime,
    required this.secondsSinceLastView,
    required this.context,
  });
}