import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  Public data classes (unchanged API)
// ─────────────────────────────────────────────

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
  final String detectedBroker;

  const CsvParseResult({
    required this.rows,
    required this.warnings,
    required this.detectedBroker,
  });
}

// ─────────────────────────────────────────────
//  Broker definitions
// ─────────────────────────────────────────────

enum _Broker {
  groww,
  zerodha,
  upstox,
  angelOne,
  iifl,
  generic,
}

class _BrokerProfile {
  final _Broker broker;
  final String displayName;

  // Required field aliases
  final List<String> symbolAliases;
  final List<String> quantityAliases;
  final List<String> priceAliases;

  // Optional field aliases
  final List<String> nameAliases;
  final List<String> dateAliases;
  final List<String> exchangeAliases;
  final List<String> transactionTypeAliases;

  // How to detect this broker (subset of headers that must ALL be present)
  final List<String> fingerprint;

  // Transaction type values that mean BUY / SELL
  final List<String> buyValues;
  final List<String> sellValues;

  const _BrokerProfile({
    required this.broker,
    required this.displayName,
    required this.symbolAliases,
    required this.quantityAliases,
    required this.priceAliases,
    required this.fingerprint,
    this.nameAliases = const [],
    this.dateAliases = const [],
    this.exchangeAliases = const [],
    this.transactionTypeAliases = const [],
    this.buyValues = const ['buy', 'b'],
    this.sellValues = const ['sell', 's'],
  });
}

const List<_BrokerProfile> _brokerProfiles = [
  // ── Groww ──────────────────────────────────────────────────────────────
  // Holdings export: Symbol, ISIN, Quantity, Average Buy Price, Exchange
  // Transaction export: Date, Stock Name, Transaction Type, Quantity, Price, Exchange
  _BrokerProfile(
    broker: _Broker.groww,
    displayName: 'Groww',
    fingerprint: ['stock name', 'transaction type'],
    symbolAliases: ['symbol', 'stock symbol', 'isin'],
    quantityAliases: ['quantity', 'qty'],
    priceAliases: ['price', 'average buy price', 'buy price', 'avg buy price'],
    nameAliases: ['stock name', 'name'],
    dateAliases: ['date', 'buy date', 'transaction date'],
    exchangeAliases: ['exchange'],
    transactionTypeAliases: ['transaction type', 'type'],
    buyValues: ['buy', 'b', 'purchase'],
    sellValues: ['sell', 's', 'sale'],
  ),
  // ── Groww Holdings (different format) ──────────────────────────────────
  _BrokerProfile(
    broker: _Broker.groww,
    displayName: 'Groww',
    fingerprint: ['average buy price', 'isin'],
    symbolAliases: ['symbol', 'stock symbol'],
    quantityAliases: ['quantity', 'qty'],
    priceAliases: ['average buy price', 'buy price'],
    nameAliases: ['stock name', 'name'],
    dateAliases: ['buy date', 'date'],
    exchangeAliases: ['exchange'],
    transactionTypeAliases: [],
  ),

  // ── Zerodha ─────────────────────────────────────────────────────────────
  // Console P&L / Trade Book: tradingsymbol, trade_type, quantity, price, exchange, trade_date
  _BrokerProfile(
    broker: _Broker.zerodha,
    displayName: 'Zerodha',
    fingerprint: ['tradingsymbol', 'trade_type'],
    symbolAliases: ['tradingsymbol', 'symbol'],
    quantityAliases: ['quantity', 'qty'],
    priceAliases: ['price', 'average_price', 'avg_price'],
    nameAliases: ['instrument_name', 'name'],
    dateAliases: ['trade_date', 'date', 'order_execution_time'],
    exchangeAliases: ['exchange', 'segment'],
    transactionTypeAliases: ['trade_type', 'transaction_type', 'type'],
    buyValues: ['buy', 'b'],
    sellValues: ['sell', 's'],
  ),

  // ── Upstox ──────────────────────────────────────────────────────────────
  // Trade Book: Instrument Name, Buy/Sell, Quantity, Average Price, Exchange, Order Date
  _BrokerProfile(
    broker: _Broker.upstox,
    displayName: 'Upstox',
    fingerprint: ['instrument name', 'buy/sell'],
    symbolAliases: ['symbol', 'instrument name', 'scrip'],
    quantityAliases: ['quantity', 'qty', 'traded qty'],
    priceAliases: ['average price', 'avg price', 'price', 'trade price'],
    nameAliases: ['instrument name', 'scrip', 'name'],
    dateAliases: ['order date', 'trade date', 'date'],
    exchangeAliases: ['exchange', 'market'],
    transactionTypeAliases: ['buy/sell', 'transaction type', 'trade type'],
    buyValues: ['buy', 'b'],
    sellValues: ['sell', 's'],
  ),

  // ── Angel One ────────────────────────────────────────────────────────────
  // Portfolio: Symbol, Net Qty, Avg. Cost Price, Exchange
  // Trade Book: Symbol, Buy/Sell, Qty, Net Rate, Exchange
  _BrokerProfile(
    broker: _Broker.angelOne,
    displayName: 'Angel One',
    fingerprint: ['net qty', 'avg. cost price'],
    symbolAliases: ['symbol', 'scrip', 'script'],
    quantityAliases: ['net qty', 'qty', 'quantity'],
    priceAliases: ['avg. cost price', 'avg cost price', 'net rate', 'price'],
    nameAliases: ['scrip', 'company name', 'name'],
    dateAliases: ['order date', 'trade date', 'date'],
    exchangeAliases: ['exchange'],
    transactionTypeAliases: ['buy/sell', 'transaction type'],
    buyValues: ['buy', 'b'],
    sellValues: ['sell', 's'],
  ),
  // Angel One Trade Book variant
  _BrokerProfile(
    broker: _Broker.angelOne,
    displayName: 'Angel One',
    fingerprint: ['net rate', 'buy/sell'],
    symbolAliases: ['symbol', 'scrip'],
    quantityAliases: ['qty', 'quantity'],
    priceAliases: ['net rate', 'avg. cost price', 'price'],
    nameAliases: ['scrip', 'name'],
    dateAliases: ['order date', 'trade date', 'date'],
    exchangeAliases: ['exchange'],
    transactionTypeAliases: ['buy/sell', 'transaction type'],
    buyValues: ['buy', 'b'],
    sellValues: ['sell', 's'],
  ),

  // ── IIFL ─────────────────────────────────────────────────────────────────
  _BrokerProfile(
    broker: _Broker.iifl,
    displayName: 'IIFL',
    fingerprint: ['scrip name', 'buy/sell indicator'],
    symbolAliases: ['symbol', 'scrip code', 'scrip name'],
    quantityAliases: ['quantity', 'qty'],
    priceAliases: ['rate', 'price', 'trade price'],
    nameAliases: ['scrip name', 'name'],
    dateAliases: ['trade date', 'date'],
    exchangeAliases: ['exchange', 'market'],
    transactionTypeAliases: ['buy/sell indicator', 'buy/sell', 'transaction type'],
    buyValues: ['buy', 'b', '1'],
    sellValues: ['sell', 's', '2'],
  ),

  // ── Generic fallback ──────────────────────────────────────────────────────
  _BrokerProfile(
    broker: _Broker.generic,
    displayName: 'Generic',
    fingerprint: [],
    symbolAliases: ['symbol', 'ticker', 'stock_symbol', 'trading_symbol', 'scrip'],
    quantityAliases: ['quantity', 'qty', 'shares', 'units', 'net qty'],
    priceAliases: [
      'buy_price', 'buy price', 'price', 'avg_price', 'average_price',
      'average buy price', 'avg. cost price', 'net rate', 'trade price',
    ],
    nameAliases: ['stock_name', 'name', 'company', 'company_name', 'scrip name', 'instrument name'],
    dateAliases: ['buy_date', 'buy date', 'purchase_date', 'date', 'transaction_date', 'trade date', 'order date'],
    exchangeAliases: ['exchange', 'market', 'segment'],
    transactionTypeAliases: [
      'transaction type', 'trade_type', 'buy/sell', 'type', 'buy/sell indicator',
    ],
    buyValues: ['buy', 'b', 'purchase', '1'],
    sellValues: ['sell', 's', 'sale', '2'],
  ),
];

// ─────────────────────────────────────────────
//  Main Parser
// ─────────────────────────────────────────────

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

    // Strip metadata / summary rows some brokers prepend (e.g. "Report:" lines)
    final dataStartIndex = _findHeaderRow(table);
    if (dataStartIndex < 0) {
      throw const FormatException(
        'Could not find a valid header row in this CSV.',
      );
    }

    final rawHeaders = table[dataStartIndex]
        .map((cell) => cell.toString().trim())
        .toList();

    // Detect broker
    final profile = _detectBroker(rawHeaders);

    // Build column index map
    final colMap = _buildColumnMap(rawHeaders, profile);

    final parsedRows = <CsvImportRow>[];
    final warnings = <String>[];

    // For transaction-based CSVs we aggregate BUY/SELL per symbol
    final bool isTransactionCsv = colMap['transactionType'] != null;

    if (isTransactionCsv) {
      // ── Transaction mode: aggregate BUY/SELL → net holdings ───────────
      final aggregated = _aggregateTransactions(
        table: table,
        startRow: dataStartIndex + 1,
        colMap: colMap,
        profile: profile,
        warnings: warnings,
      );

      for (final entry in aggregated.entries) {
        final agg = entry.value;
        if (agg.netQuantity <= 0) {
          warnings.add(
            'Symbol ${entry.key} skipped: net quantity after BUY/SELL is 0 or negative.',
          );
          continue;
        }
        parsedRows.add(agg.toImportRow(profile.displayName));
      }
    } else {
      // ── Holdings mode: each row = one holding ─────────────────────────
      for (int rowIndex = dataStartIndex + 1; rowIndex < table.length; rowIndex++) {
        final rawRow = table[rowIndex];
        if (_isBlankRow(rawRow)) continue;

        try {
          parsedRows.add(
            _parseHoldingRow(
              rawRow: rawRow,
              rowIndex: rowIndex,
              colMap: colMap,
              platform: profile.displayName,
            ),
          );
        } catch (error) {
          warnings.add('Row ${rowIndex + 1} skipped: $error');
        }
      }
    }

    if (parsedRows.isEmpty) {
      throw FormatException(
        warnings.isEmpty
            ? 'No valid rows were found in the CSV file.'
            : warnings.first,
      );
    }

    return CsvParseResult(
      rows: parsedRows,
      warnings: warnings,
      detectedBroker: profile.displayName,
    );
  }

  // ── Broker detection ────────────────────────────────────────────────────

  static _BrokerProfile _detectBroker(List<String> headers) {
    final normalizedHeaders = headers.map(_normalizeHeader).toSet();

    for (final profile in _brokerProfiles) {
      if (profile.broker == _Broker.generic) continue;
      if (profile.fingerprint.isEmpty) continue;

      final allMatch = profile.fingerprint
          .every((fp) => normalizedHeaders.contains(_normalizeHeader(fp)));

      if (allMatch) return profile;
    }

    // Fall back to generic
    return _brokerProfiles.last;
  }

  // ── Column map builder ──────────────────────────────────────────────────

  static Map<String, int?> _buildColumnMap(
      List<String> headers,
      _BrokerProfile profile,
      ) {
    final indexMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      indexMap[_normalizeHeader(headers[i])] = i;
    }

    int findRequired(List<String> aliases, String label) {
      for (final alias in aliases) {
        final found = indexMap[_normalizeHeader(alias)];
        if (found != null) return found;
      }
      throw FormatException('Missing required column: $label');
    }

    int? findOptional(List<String> aliases) {
      for (final alias in aliases) {
        final found = indexMap[_normalizeHeader(alias)];
        if (found != null) return found;
      }
      return null;
    }

    return {
      'symbol': findRequired(profile.symbolAliases, 'Symbol'),
      'quantity': findRequired(profile.quantityAliases, 'Quantity'),
      'price': findRequired(profile.priceAliases, 'Price'),
      'name': findOptional(profile.nameAliases),
      'date': findOptional(profile.dateAliases),
      'exchange': findOptional(profile.exchangeAliases),
      'transactionType': findOptional(profile.transactionTypeAliases),
    };
  }

  // ── Header row finder (skips broker metadata lines) ─────────────────────

  static int _findHeaderRow(List<List<dynamic>> table) {
    for (int i = 0; i < table.length && i < 10; i++) {
      final cells = table[i].map((c) => c.toString().trim().toLowerCase()).toList();
      // A header row typically has at least 2 non-empty string cells
      // and contains at least one recognizable keyword
      final nonEmpty = cells.where((c) => c.isNotEmpty).toList();
      if (nonEmpty.length >= 2) {
        final hasKeyword = nonEmpty.any((c) =>
        c.contains('symbol') ||
            c.contains('qty') ||
            c.contains('quantity') ||
            c.contains('price') ||
            c.contains('stock') ||
            c.contains('scrip') ||
            c.contains('instrument') ||
            c.contains('isin'));
        if (hasKeyword) return i;
      }
    }
    return -1;
  }

  // ── Holdings row parser ─────────────────────────────────────────────────

  static CsvImportRow _parseHoldingRow({
    required List<dynamic> rawRow,
    required int rowIndex,
    required Map<String, int?> colMap,
    required String platform,
  }) {
    final symbol = _cell(rawRow, colMap['symbol']).toUpperCase();
    final quantity = _parseNumber(_cell(rawRow, colMap['quantity']));
    final buyPrice = _parseNumber(_cell(rawRow, colMap['price']));

    if (symbol.isEmpty) throw const FormatException('Missing stock symbol.');
    if (quantity <= 0) throw const FormatException('Quantity must be > 0.');
    if (buyPrice <= 0) throw const FormatException('Buy price must be > 0.');

    return CsvImportRow(
      stockSymbol: symbol,
      stockName: _cell(rawRow, colMap['name']),
      platform: platform,
      exchange: _cell(rawRow, colMap['exchange']),
      quantity: quantity,
      buyPrice: buyPrice,
      buyDate: _parseDate(_cell(rawRow, colMap['date'])),
    );
  }

  // ── Transaction aggregator ──────────────────────────────────────────────

  static Map<String, _AggregatedHolding> _aggregateTransactions({
    required List<List<dynamic>> table,
    required int startRow,
    required Map<String, int?> colMap,
    required _BrokerProfile profile,
    required List<String> warnings,
  }) {
    final holdings = <String, _AggregatedHolding>{};

    for (int i = startRow; i < table.length; i++) {
      final rawRow = table[i];
      if (_isBlankRow(rawRow)) continue;

      try {
        final symbol = _cell(rawRow, colMap['symbol']).toUpperCase();
        if (symbol.isEmpty) continue;

        final qty = _parseNumber(_cell(rawRow, colMap['quantity']));
        final price = _parseNumber(_cell(rawRow, colMap['price']));
        final typeRaw = _cell(rawRow, colMap['transactionType']).toLowerCase().trim();

        if (qty <= 0 || price <= 0) {
          warnings.add('Row ${i + 1} skipped: zero quantity or price.');
          continue;
        }

        final isBuy = profile.buyValues.any((v) => typeRaw.contains(v));
        final isSell = profile.sellValues.any((v) => typeRaw.contains(v));

        if (!isBuy && !isSell && typeRaw.isNotEmpty) {
          warnings.add('Row ${i + 1} skipped: unknown transaction type "$typeRaw".');
          continue;
        }

        holdings.putIfAbsent(
          symbol,
              () => _AggregatedHolding(
            symbol: symbol,
            name: _cell(rawRow, colMap['name']),
            exchange: _cell(rawRow, colMap['exchange']),
            firstDate: _parseDate(_cell(rawRow, colMap['date'])),
          ),
        );

        if (isBuy || typeRaw.isEmpty) {
          holdings[symbol]!.addBuy(qty, price);
        } else {
          holdings[symbol]!.addSell(qty);
        }
      } catch (error) {
        warnings.add('Row ${i + 1} skipped: $error');
      }
    }

    return holdings;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _cell(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  static bool _isBlankRow(List<dynamic> row) =>
      row.every((cell) => cell.toString().trim().isEmpty);

  static double _parseNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static String _normalizeHeader(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

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
      'dd-MMM-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(raw.split(' ').first);
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}

// ─────────────────────────────────────────────
//  Aggregated holding (for transaction CSVs)
// ─────────────────────────────────────────────

class _AggregatedHolding {
  final String symbol;
  final String name;
  final String exchange;
  final DateTime? firstDate;

  double _totalBuyQty = 0;
  double _totalBuyCost = 0;
  double _totalSellQty = 0;

  _AggregatedHolding({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.firstDate,
  });

  void addBuy(double qty, double price) {
    _totalBuyQty += qty;
    _totalBuyCost += qty * price;
  }

  void addSell(double qty) {
    _totalSellQty += qty;
  }

  double get netQuantity => _totalBuyQty - _totalSellQty;

  /// Weighted average buy price
  double get avgBuyPrice =>
      _totalBuyQty == 0 ? 0 : _totalBuyCost / _totalBuyQty;

  CsvImportRow toImportRow(String platform) {
    return CsvImportRow(
      stockSymbol: symbol,
      stockName: name,
      platform: platform,
      exchange: exchange,
      quantity: netQuantity,
      buyPrice: avgBuyPrice,
      buyDate: firstDate,
    );
  }
}