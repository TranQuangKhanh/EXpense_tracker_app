import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomCategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String userId;
  final DateTime? createdAt;

  CustomCategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.userId,
    this.createdAt,
  });

  // Dùng emoji làm icon
  IconData get icon => Icons.label;
  Color get color => Colors.blueGrey;

  factory CustomCategoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomCategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '📦',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
    'userId': userId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}