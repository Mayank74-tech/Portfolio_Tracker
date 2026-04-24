import 'dart:async';

import '../../entities/chat_entity.dart';

abstract class ChatRepository {
  Future<ChatEntity> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  });
}

class SendChatMessageParams {
  final String senderId;
  final String receiverId;
  final String message;

  SendChatMessageParams({
    required this.senderId,
    required this.receiverId,
    required this.message,
  });
}

class SendChatMessageUseCase {
  final ChatRepository repository;

  SendChatMessageUseCase(this.repository);

  Future<ChatEntity> call(SendChatMessageParams params) async {
    if (params.message.trim().isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }
    if (params.senderId.isEmpty || params.receiverId.isEmpty) {
      throw ArgumentError('Sender/receiver IDs are required.');
    }
    return await repository.sendMessage(
      senderId: params.senderId,
      receiverId: params.receiverId,
      message: params.message,
    );
  }
}
