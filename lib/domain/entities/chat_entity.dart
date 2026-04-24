class ChatEntity {
  final String id;
  final String senderId;
  final String receiverId; // Could be a user ID or a room ID
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatEntity.fromJson(Map<String, dynamic> json) {
    return ChatEntity(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      senderName: json['senderName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
