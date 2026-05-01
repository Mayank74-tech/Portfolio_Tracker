// lib/data/models/finance/transaction_model.dart

import 'package:hive/hive.dart';
class TransactionModel extends HiveObject {
  final String id;

  final String accountId;

  final double amount;

  final String type; // 'debit' or 'credit'

  final String category;
  // 'food', 'transport', 'shopping', 'investment',
  // 'utilities', 'entertainment', 'health', 'other'

  final String description;

  final DateTime date;

  final String merchantName;

  final double balanceAfter;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.merchantName,
    required this.balanceAfter,
  });
}
