import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase/firestore_service.dart';
import '../services/remote/gemini_service.dart';
import '../services/remote/ollama_service.dart';

class AiRepository {
  AiRepository({
    GeminiService? geminiService,
    OllamaService? ollamaService,
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  })  : _gemini = geminiService ?? GeminiService(),
        _ollama = ollamaService ?? OllamaService(),
        _firestore = firestoreService ?? FirestoreService(),
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final GeminiService _gemini;
  final OllamaService _ollama;
  final FirestoreService _firestore;
  final FirebaseAuth _auth;

  // Track which AI is active
  bool _usingGemini = true;

  Future<bool> isAvailable() async {
    // Try Gemini first, fallback to Ollama
    final geminiOk = await _gemini.isAvailable();
    if (geminiOk) {
      _usingGemini = true;
      return true;
    }
    final ollamaOk = await _ollama.isAvailable();
    _usingGemini = false;
    return ollamaOk;
  }

  String get activeAiName => _usingGemini ? 'Gemini' : 'Ollama';

  void resetChatHistory() {
    _gemini.resetChat();
  }

  Future<String> sendChatMessage({
    required String message,
    required List<Map<String, dynamic>> holdings,
    Map<String, dynamic>? portfolioSummary,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    // Save user message to Firestore
    if (uid != null) {
      await _firestore.addChatMessage(
        userId: uid,
        data: {
          'message': message,
          'sender': 'user',
          'ai_provider': activeAiName,
        },
      );
    }

    // Try Gemini → fallback to Ollama
    String response;
    try {
      response = await _gemini.generatePortfolioInsight(
        holdings: holdings,
        question: message,
        portfolioSummary: portfolioSummary,
      );
      _usingGemini = true;
    } catch (e) {
      // Gemini failed — try Ollama
      try {
        response = await _ollama.generatePortfolioInsight(
          holdings: holdings,
          question: message,
          portfolioSummary: portfolioSummary,
        );
        _usingGemini = false;
      } catch (_) {
        throw Exception(
          'Both Gemini and Ollama are unavailable. Check your internet connection.',
        );
      }
    }

    // Save AI response to Firestore
    if (uid != null) {
      await _firestore.addChatMessage(
        userId: uid,
        data: {
          'message': response,
          'sender': 'ai',
          'ai_provider': activeAiName,
        },
      );
    }

    return response;
  }

  Future<String> getInsight({
    required List<Map<String, dynamic>> holdings,
    required String question,
    Map<String, dynamic>? portfolioSummary,
  }) async {
    try {
      return await _gemini.generatePortfolioInsight(
        holdings: holdings,
        question: question,
        portfolioSummary: portfolioSummary,
      );
    } catch (_) {
      return _ollama.generatePortfolioInsight(
        holdings: holdings,
        question: question,
        portfolioSummary: portfolioSummary,
      );
    }
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
