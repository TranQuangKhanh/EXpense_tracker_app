import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String code;
  final String avatar;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.code,
    required this.avatar,
    required this.createdAt,
  });

  String get displayName => '$name#$code';

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      code: data['code'] ?? '',
      avatar: data['avatar'] ?? '🐱',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'code': code,
    'avatar': avatar,
    'createdAt': FieldValue.serverTimestamp(),
  };
}