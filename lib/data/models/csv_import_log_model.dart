import 'package:cloud_firestore/cloud_firestore.dart';

enum CsvImportStatus { pending, success, failed, partial }

class CsvImportLogModel {
  final String id;
  final String fileName;
  final int totalRows;
  final int successRows;
  final int failedRows;
  final CsvImportStatus status;
  final List<String> errors;
  final DateTime? importedAt;

  const CsvImportLogModel({
    required this.id,
    required this.fileName,
    required this.totalRows,
    required this.successRows,
    required this.failedRows,
    required this.status,
    required this.errors,
    this.importedAt,
  });

  bool get isSuccess => status == CsvImportStatus.success;
  bool get hasFailed => failedRows > 0;
  double get successRate =>
      totalRows == 0 ? 0 : (successRows / totalRows) * 100;

  factory CsvImportLogModel.fromMap(Map<String, dynamic> map, String id) {
    return CsvImportLogModel(
      id: id,
      fileName: map['file_name']?.toString() ?? 'unknown.csv',
      totalRows: _toInt(map['total_rows']),
      successRows: _toInt(map['success_rows']),
      failedRows: _toInt(map['failed_rows']),
      status: _parseStatus(map['status']?.toString()),
      errors: map['errors'] is List
          ? List<String>.from((map['errors'] as List).map((e) => e.toString()))
          : [],
      importedAt: map['imported_at'] is Timestamp
          ? (map['imported_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'file_name': fileName,
        'total_rows': totalRows,
        'success_rows': successRows,
        'failed_rows': failedRows,
        'status': status.name,
        'errors': errors,
      };

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static CsvImportStatus _parseStatus(String? value) {
    switch (value) {
      case 'success':
        return CsvImportStatus.success;
      case 'failed':
        return CsvImportStatus.failed;
      case 'partial':
        return CsvImportStatus.partial;
      default:
        return CsvImportStatus.pending;
    }
  }

  @override
  String toString() =>
      'CsvImportLogModel(file: $fileName, success: $successRows/$totalRows)';
}
