// lib/data/models/behavioral/attention_log_model.dart

import 'package:hive/hive.dart';

part 'attention_log_model.g.dart';

@HiveType(typeId: 20)
class AttentionLogModel extends HiveObject {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final DateTime viewedAt;

  @HiveField(2)
  final int durationSeconds; // how long they stayed on detail screen

  @HiveField(3)
  final String screenName; // 'stock_detail', 'dashboard', etc.

  AttentionLogModel({
    required this.symbol,
    required this.viewedAt,
    required this.durationSeconds,
    required this.screenName,
  });
}