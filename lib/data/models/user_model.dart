import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String preferredCurrency;
  final String preferredExchange;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    this.preferredCurrency = 'INR',
    this.preferredExchange = 'NSE',
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email']?.toString() ?? '',
      displayName: map['display_name']?.toString() ??
          map['displayName']?.toString() ??
          '',
      photoUrl: map['photo_url']?.toString() ?? map['photoURL']?.toString(),
      phone: map['phone']?.toString(),
      preferredCurrency: map['preferred_currency']?.toString() ?? 'INR',
      preferredExchange: map['preferred_exchange']?.toString() ?? 'NSE',
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : null,
      updatedAt: map['updated_at'] is Timestamp
          ? (map['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (phone != null) 'phone': phone,
        'preferred_currency': preferredCurrency,
        'preferred_exchange': preferredExchange,
        'notifications_enabled': notificationsEnabled,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? preferredCurrency,
    String? preferredExchange,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredExchange: preferredExchange ?? this.preferredExchange,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $displayName)';
}
