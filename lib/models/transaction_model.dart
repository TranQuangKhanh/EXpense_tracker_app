import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String categoryId;
  final DateTime? date;
  final String userId;
  final String? groupId;
  final String source;
  final String status;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.userId,
    this.groupId,
    this.source = 'manual',
    this.status = 'confirmed',
  });

  bool get isIncome => type == 'income';
  bool get isAuto => source == 'auto';
  bool get isPending => status == 'pending';

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] ?? 'expense',
      categoryId: data['categoryId'] ?? 'other_expense',
      date: (data['date'] as Timestamp?)?.toDate(),
      userId: data['userId'] ?? '',
      groupId: data['groupId'],
      source: data['source'] ?? 'manual',
      status: data['status'] ?? 'confirmed',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'date': FieldValue.serverTimestamp(),
    'userId': userId,
    'groupId': groupId,
    'source': source,
    'status': status,
  };
}