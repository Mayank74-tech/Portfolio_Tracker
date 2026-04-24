import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String message;
  final String sender; // 'user' or 'ai'
  final String? aiProvider;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.sender,
    this.aiProvider,
    this.createdAt,
  });

  bool get isUser => sender == 'user';
  bool get isAi => sender == 'ai';

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      message: map['message']?.toString() ?? '',
      sender: map['sender']?.toString() ?? 'user',
      aiProvider: map['ai_provider']?.toString(),
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'message': message,
        'sender': sender,
        if (aiProvider != null) 'ai_provider': aiProvider,
      };

  ChatMessageModel copyWith({
    String? id,
    String? message,
    String? sender,
    String? aiProvider,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      aiProvider: aiProvider ?? this.aiProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ChatMessageModel(id: $id, sender: $sender, message: $message)';
}
