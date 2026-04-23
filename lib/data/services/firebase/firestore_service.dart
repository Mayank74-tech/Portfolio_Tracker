import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> holdings(String userId) {
    return users.doc(userId).collection('holdings');
  }

  CollectionReference<Map<String, dynamic>> watchlist(String userId) {
    return users.doc(userId).collection('watchlist');
  }

  CollectionReference<Map<String, dynamic>> aiChats(String userId) {
    return users.doc(userId).collection('ai_chats');
  }

  Future<void> upsertUser({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return users.doc(userId).set({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) {
    return users.doc(userId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String userId) {
    return users.doc(userId).snapshots();
  }

  Future<String> addHolding({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final doc = await holdings(userId).add(_withTimestamps(data));
    return doc.id;
  }

  Future<void> setHolding({
    required String userId,
    required String holdingId,
    required Map<String, dynamic> data,
  }) {
    return holdings(userId).doc(holdingId).set(
          _withTimestamps(data, includeCreatedAt: false),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteHolding({
    required String userId,
    required String holdingId,
  }) {
    return holdings(userId).doc(holdingId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHoldings(String userId) {
    return holdings(userId).orderBy('created_at', descending: true).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHoldings(String userId) {
    return holdings(userId).orderBy('created_at', descending: true).get();
  }

  Future<String> addChatMessage({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final doc = await aiChats(userId).add(_withTimestamps(data));
    return doc.id;
  }

  Map<String, dynamic> _withTimestamps(
    Map<String, dynamic> data, {
    bool includeCreatedAt = true,
  }) {
    return {
      ...data,
      if (includeCreatedAt) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
