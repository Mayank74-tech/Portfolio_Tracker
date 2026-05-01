// lib/data/models/finance/bank_account_model.dart

import 'package:hive/hive.dart';
class BankAccountModel extends HiveObject {
  final String id;

  final String bankName;

  final String accountType; // 'savings', 'current'

  final String maskedNumber; // 'XXXX 1234'

  double balance;

  final DateTime connectedAt;

  DateTime lastSynced;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.maskedNumber,
    required this.balance,
    required this.connectedAt,
    required this.lastSynced,
  });
}
