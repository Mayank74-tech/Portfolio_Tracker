class UserEntity {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isVerified;
  final String? phoneNumber;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.isVerified,
    this.phoneNumber,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'phoneNumber': phoneNumber,
    };
  }
}
