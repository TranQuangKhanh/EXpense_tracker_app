import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String categoryId;
  final DateTime? date;
  final String userId;
  final String status;
  final bool isAuto;
  final String? bankName;
  final String? originalText;
  final String? source;
  final String? walletId;    // ← THÊM
  final String? walletName;  // ← THÊM
  final String? note;        // ← THÊM

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.userId,
    this.status = 'confirmed',
    this.isAuto = false,
    this.bankName,
    this.originalText,
    this.source,
    this.walletId,
    this.walletName,
    this.note,
  });

  bool get isIncome => type == 'income';

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] ?? 'expense',
      categoryId: data['categoryId'] ?? 'other_expense',
      date: (data['date'] as Timestamp?)?.toDate(),
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'confirmed',
      isAuto: data['isAuto'] ?? false,
      bankName: data['bankName'],
      originalText: data['originalText'],
      source: data['source'],
      walletId: data['walletId'],
      walletName: data['walletName'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'date': date != null ? Timestamp.fromDate(date!) : FieldValue.serverTimestamp(),
    'userId': userId,
    'status': status,
    'isAuto': isAuto,
    if (bankName != null) 'bankName': bankName,
    if (originalText != null) 'originalText': originalText,
    if (source != null) 'source': source,
    if (walletId != null) 'walletId': walletId,
    if (walletName != null) 'walletName': walletName,
    if (note != null) 'note': note,
  };
}