// lib/data/models/behavioral/behavior_profile_model.dart

import 'package:hive/hive.dart';

part 'behavior_profile_model.g.dart';

@HiveType(typeId: 23)
class BehaviorProfileModel extends HiveObject {
  @HiveField(0)
  String investingStyle;

  @HiveField(1)
  String statedRiskTolerance;

  @HiveField(2)
  List<String> styleHistory;

  @HiveField(3)
  List<double> confidenceScores;

  @HiveField(4)
  List<double> actualReturns;

  @HiveField(5)
  List<int> decisionTimesSeconds;

  @HiveField(6)
  int rebalanceConsideredCount;

  @HiveField(7)
  int rebalanceActedCount;

  @HiveField(8)
  DateTime lastUpdated;

  BehaviorProfileModel({
    required this.investingStyle,
    required this.statedRiskTolerance,
    required this.styleHistory,
    required this.confidenceScores,
    required this.actualReturns,
    required this.decisionTimesSeconds,
    required this.rebalanceConsideredCount,
    required this.rebalanceActedCount,
    required this.lastUpdated,
  });
}