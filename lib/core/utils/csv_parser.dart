import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

class CsvImportRow {
  final String stockSymbol;
  final String stockName;
  final String platform;
  final String exchange;
  final double quantity;
  final double buyPrice;
  final DateTime? buyDate;

  const CsvImportRow({
    required this.stockSymbol,
    required this.stockName,
    required this.platform,
    required this.exchange,
    required this.quantity,
    required this.buyPrice,
    required this.buyDate,
  });

  Map<String, dynamic> toHoldingMap() {
    return {
      'stock_symbol': stockSymbol,
      if (stockName.isNotEmpty) 'stock_name': stockName,
      if (exchange.isNotEmpty) 'exchange': exchange,
      'quantity': quantity,
      'buy_price': buyPrice,
      'buy_date': (buyDate ?? DateTime.now()).toIso8601String(),
      'platform': platform.isEmpty ? 'Imported CSV' : platform,
    };
  }
}

class CsvParseResult {
  final List<CsvImportRow> rows;
  final List<String> warnings;

  const CsvParseResult({
    required this.rows,
    required this.warnings,
  });
}

class CsvParser {
  static CsvParseResult parse(String content) {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      throw const FormatException('The selected CSV file is empty.');
    }

    final table = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalizedContent);

    if (table.isEmpty) {
      throw const FormatException('The selected CSV file has no rows.');
    }

    final headers = table.first.map((cell) => cell.toString().trim()).toList();
    final indexes = _HeaderIndexes.fromHeaders(headers);
    final parsedRows = <CsvImportRow>[];
    final warnings = <String>[];

    for (int rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final rawRow = table[rowIndex];
      if (_isBlankRow(rawRow)) continue;

      try {
        final symbol = _cell(rawRow, indexes.symbol).toUpperCase();
        final quantity = _parseNumber(_cell(rawRow, indexes.quantity));
        final buyPrice = _parseNumber(_cell(rawRow, indexes.buyPrice));

        if (symbol.isEmpty) {
          throw const FormatException('Missing stock symbol.');
        }
        if (quantity <= 0) {
          throw const FormatException('Quantity must be greater than 0.');
        }
        if (buyPrice <= 0) {
          throw const FormatException('Buy price must be greater than 0.');
        }

        parsedRows.add(
          CsvImportRow(
            stockSymbol: symbol,
            stockName: _cell(rawRow, indexes.stockName),
            platform: _cell(rawRow, indexes.platform),
            exchange: _cell(rawRow, indexes.exchange),
            quantity: quantity,
            buyPrice: buyPrice,
            buyDate: _parseDate(_cell(rawRow, indexes.buyDate)),
          ),
        );
      } catch (error) {
        warnings.add('Row ${rowIndex + 1} skipped: $error');
      }
    }

    if (parsedRows.isEmpty) {
      throw FormatException(
        warnings.isEmpty
            ? 'No valid rows were found in the CSV file.'
            : warnings.first,
      );
    }

    return CsvParseResult(rows: parsedRows, warnings: warnings);
  }

  static String _cell(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  static bool _isBlankRow(List<dynamic> row) {
    return row.every((cell) => cell.toString().trim().isEmpty);
  }

  static double _parseNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;

    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    const patterns = [
      'dd/MM/yyyy',
      'd/M/yyyy',
      'dd-MM-yyyy',
      'd-M-yyyy',
      'MM/dd/yyyy',
      'M/d/yyyy',
      'yyyy/MM/dd',
      'dd MMM yyyy',
      'd MMM yyyy',
    ];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}

class _HeaderIndexes {
  final int symbol;
  final int quantity;
  final int buyPrice;
  final int? buyDate;
  final int? platform;
  final int? stockName;
  final int? exchange;

  const _HeaderIndexes({
    required this.symbol,
    required this.quantity,
    required this.buyPrice,
    required this.buyDate,
    required this.platform,
    required this.stockName,
    required this.exchange,
  });

  factory _HeaderIndexes.fromHeaders(List<String> headers) {
    final normalized = <String, int>{};
    for (int index = 0; index < headers.length; index++) {
      normalized[_normalizeHeader(headers[index])] = index;
    }

    int findRequired(List<String> options, String label) {
      for (final option in options) {
        final found = normalized[_normalizeHeader(option)];
        if (found != null) return found;
      }
      throw FormatException('Missing required column: $label');
    }

    int? findOptional(List<String> options) {
      for (final option in options) {
        final found = normalized[_normalizeHeader(option)];
        if (found != null) return found;
      }
      return null;
    }

    return _HeaderIndexes(
      symbol: findRequired(
        ['symbol', 'ticker', 'stock_symbol', 'trading_symbol'],
        'symbol',
      ),
      quantity: findRequired(
        ['quantity', 'qty', 'shares', 'units'],
        'quantity',
      ),
      buyPrice: findRequired(
        ['buy_price', 'buy price', 'price', 'avg_price', 'average_price'],
        'buy price',
      ),
      buyDate: findOptional(
        ['buy_date', 'buy date', 'purchase_date', 'date', 'transaction_date'],
      ),
      platform: findOptional(['platform', 'broker', 'broker_name']),
      stockName:
          findOptional(['stock_name', 'name', 'company', 'company_name']),
      exchange: findOptional(['exchange', 'market']),
    );
  }

  static String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
