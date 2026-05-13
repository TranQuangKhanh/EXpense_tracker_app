import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  double balance;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.balance = 0,
  });

  factory WalletModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '💳',
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'emoji': emoji,
    'balance': balance,
    'createdAt': FieldValue.serverTimestamp(),
  };
}