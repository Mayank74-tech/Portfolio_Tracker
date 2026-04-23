import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase/firestore_service.dart';
import 'stock_repository.dart';

class PortfolioRepository {
  PortfolioRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
    StockRepository? stockRepository,
  })  : _firestore = firestoreService ?? FirestoreService(),
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _stocks = stockRepository ?? StockRepository();

  final FirestoreService _firestore;
  final FirebaseAuth _auth;
  final StockRepository _stocks;

  Future<String> addHolding(Map<String, dynamic> holding, {String? userId}) {
    final uid = _resolveUserId(userId);
    return _firestore.addHolding(
      userId: uid,
      data: _normalizeHolding(holding),
    );
  }

  Future<void> updateHolding({
    required String holdingId,
    required Map<String, dynamic> holding,
    String? userId,
  }) {
    final uid = _resolveUserId(userId);
    return _firestore.setHolding(
      userId: uid,
      holdingId: holdingId,
      data: _normalizeHolding(holding),
    );
  }

  Future<void> deleteHolding({
    required String holdingId,
    String? userId,
  }) {
    final uid = _resolveUserId(userId);
    return _firestore.deleteHolding(userId: uid, holdingId: holdingId);
  }

  Future<List<Map<String, dynamic>>> getHoldings({String? userId}) async {
    final uid = _resolveUserId(userId);
    final snapshot = await _firestore.getHoldings(uid);
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Stream<List<Map<String, dynamic>>> watchHoldings({String? userId}) {
    final uid = _resolveUserId(userId);
    return _firestore.watchHoldings(uid).map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<List<String>> importHoldings(
    List<Map<String, dynamic>> holdings, {
    String? userId,
  }) async {
    final ids = <String>[];
    for (final holding in holdings) {
      ids.add(await addHolding(holding, userId: userId));
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> getHoldingsWithPrices({
    String? userId,
  }) async {
    final holdings = await getHoldings(userId: userId);
    final enriched = <Map<String, dynamic>>[];

    for (final holding in holdings) {
      final symbol = _symbolFromHolding(holding);
      if (symbol.isEmpty) {
        enriched.add(holding);
        continue;
      }

      try {
        final quote = await _stocks.getQuote(symbol);
        final currentPrice = _number(quote['c']);
        enriched.add({
          ...holding,
          'quote': quote,
          'current_price': currentPrice,
          'current_value': currentPrice * _number(holding['quantity']),
          'today_change': _number(quote['d']) * _number(holding['quantity']),
          'today_change_percent': _number(quote['dp']),
        });
      } catch (_) {
        enriched.add(holding);
      }
    }

    return enriched;
  }

  Future<Map<String, dynamic>> getPortfolioSummary({String? userId}) async {
    final holdings = await getHoldingsWithPrices(userId: userId);

    var totalValue = 0.0;
    var totalInvestment = 0.0;
    var todayChange = 0.0;

    for (final holding in holdings) {
      final quantity = _number(holding['quantity']);
      final buyPrice = _number(holding['buy_price']);
      final currentPrice = _number(holding['current_price']);
      totalInvestment += buyPrice * quantity;
      totalValue += currentPrice * quantity;
      todayChange += _number(holding['today_change']);
    }

    final profitLoss = totalValue - totalInvestment;
    final profitLossPercent =
        totalInvestment == 0 ? 0.0 : (profitLoss / totalInvestment) * 100;

    return {
      'holdings': holdings,
      'holding_count': holdings.length,
      'total_value': totalValue,
      'total_investment': totalInvestment,
      'profit_loss': profitLoss,
      'profit_loss_percent': profitLossPercent,
      'today_change': todayChange,
    };
  }

  String _resolveUserId(String? userId) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in before accessing portfolio.');
    }
    return uid;
  }

  static Map<String, dynamic> _normalizeHolding(Map<String, dynamic> holding) {
    final symbol = _symbolFromHolding(holding);
    return {
      ...holding,
      if (symbol.isNotEmpty) 'stock_symbol': symbol,
      'quantity': _number(holding['quantity']),
      'buy_price': _number(holding['buy_price']),
    };
  }

  static String _symbolFromHolding(Map<String, dynamic> holding) {
    final value = holding['stock_symbol'] ?? holding['symbol'];
    return value?.toString().trim().toUpperCase() ?? '';
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
