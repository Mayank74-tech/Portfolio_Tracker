// lib/data/models/behavioral/belief_log_model.dart

import 'package:hive/hive.dart';

part 'belief_log_model.g.dart';

@HiveType(typeId: 21)
class BeliefLogModel extends HiveObject {
  @HiveField(0)
  final String question; // "Which is your worst performer?"

  @HiveField(1)
  final String userBelief; // "HDFC"

  @HiveField(2)
  final String actualAnswer; // "INFY"

  @HiveField(3)
  final bool wasCorrect;

  @HiveField(4)
  final DateTime recordedAt;

  @HiveField(5)
  final String explanation;
  // "HDFC is actually your 2nd best. You're overweighing recent losses."

  BeliefLogModel({
    required this.question,
    required this.userBelief,
    required this.actualAnswer,
    required this.wasCorrect,
    required this.recordedAt,
    required this.explanation,
  });
}