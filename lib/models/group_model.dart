import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String emoji;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;        // ← THÊM
  final DateTime? lastMessageAt;    // ← THÊM
  final String? lastMessageSender;  // ← THÊM

  GroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSender,
  });

  factory GroupModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '👨‍👩‍👧‍👦',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSender: data['lastMessageSender'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };
}