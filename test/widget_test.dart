import 'package:flutter_test/flutter_test.dart';
import 'package:smart_portfolio_tracker/core/utils/csv_parser.dart';

void main() {
  group('CsvParser', () {
    test('parses valid rows with common headers', () {
      const csv = '''
Symbol,Quantity,Buy Price,Buy Date,Platform,Stock Name,Exchange
RELIANCE,10,2400,2025-04-03,Zerodha,Reliance Industries,NSE
TCS,5,3500,03/04/2025,Groww,Tata Consultancy Services,NSE
''';

      final result = CsvParser.parse(csv);

      expect(result.rows, hasLength(2));
      expect(result.warnings, isEmpty);
      expect(result.rows.first.stockSymbol, 'RELIANCE');
      expect(result.rows.first.quantity, 10);
      expect(result.rows.first.buyPrice, 2400);
      expect(result.rows.first.platform, 'Zerodha');
      expect(result.rows.last.stockName, 'Tata Consultancy Services');
    });

    test('skips invalid rows but keeps valid ones', () {
      const csv = '''
Ticker,Qty,Price,Platform
INFY,12,1450,Angel One
,3,100,Manual
WIPRO,0,250,Manual
''';

      final result = CsvParser.parse(csv);

      expect(result.rows, hasLength(1));
      expect(result.rows.single.stockSymbol, 'INFY');
      expect(result.warnings, hasLength(2));
    });
  });
}
