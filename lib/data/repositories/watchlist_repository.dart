import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase/firestore_service.dart';
import 'stock_repository.dart';

class WatchlistRepository {
  WatchlistRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
    StockRepository? stockRepository,
  })  : _firestore = firestoreService ?? FirestoreService(),
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _stocks = stockRepository ?? StockRepository();

  final FirestoreService _firestore;
  final FirebaseAuth _auth;
  final StockRepository _stocks;

  Future<void> addToWatchlist({
    required String symbol,
    String? name,
    String? userId,
  }) {
    final uid = _resolveUserId(userId);
    return _firestore.watchlist(uid).doc(symbol.toUpperCase()).set({
      'symbol': symbol.toUpperCase(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromWatchlist({
    required String symbol,
    String? userId,
  }) {
    final uid = _resolveUserId(userId);
    return _firestore.watchlist(uid).doc(symbol.toUpperCase()).delete();
  }

  Future<List<Map<String, dynamic>>> getWatchlist({String? userId}) async {
    final uid = _resolveUserId(userId);
    final snapshot = await _firestore.watchlist(uid).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Stream<List<Map<String, dynamic>>> watchWatchlist({String? userId}) {
    final uid = _resolveUserId(userId);
    return _firestore.watchlist(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getWatchlistWithPrices({
    String? userId,
  }) async {
    final items = await getWatchlist(userId: userId);
    final enriched = <Map<String, dynamic>>[];

    for (final item in items) {
      final symbol = item['symbol']?.toString() ?? item['id']?.toString() ?? '';
      if (symbol.isEmpty) {
        enriched.add(item);
        continue;
      }

      try {
        final quote = await _stocks.getQuote(symbol);
        enriched.add({...item, 'quote': quote});
      } catch (_) {
        enriched.add(item);
      }
    }

    return enriched;
  }

  String _resolveUserId(String? userId) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in before accessing watchlist.');
    }
    return uid;
  }
}
