import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase/firestore_service.dart';
import '../services/remote/ollama_service.dart';

class AiRepository {
  AiRepository({
    OllamaService? ollamaService,
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  })  : _ollama = ollamaService ?? OllamaService(),
        _firestore = firestoreService ?? FirestoreService(),
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final OllamaService _ollama;
  final FirestoreService _firestore;
  final FirebaseAuth _auth;

  Future<bool> isAvailable() {
    return _ollama.isAvailable();
  }

  Future<String> sendChatMessage({
    required String message,
    required List<Map<String, dynamic>> holdings,
    Map<String, dynamic>? portfolioSummary,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    if (uid != null) {
      await _firestore.addChatMessage(
        userId: uid,
        data: {
          'message': message,
          'sender': 'user',
        },
      );
    }

    final response = await _ollama.generatePortfolioInsight(
      holdings: holdings,
      question: message,
      portfolioSummary: portfolioSummary,
    );

    if (uid != null) {
      await _firestore.addChatMessage(
        userId: uid,
        data: {
          'message': response,
          'sender': 'ai',
        },
      );
    }

    return response;
  }

  Future<String> getInsight({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) {
    return _ollama.generatePortfolioInsight(
      holdings: holdings,
      question: question,
      portfolioSummary: portfolioSummary,
    );
  }

  Stream<List<Map<String, dynamic>>> watchChatHistory({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .aiChats(uid)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
