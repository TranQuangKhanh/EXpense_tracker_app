import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String content;
  final String groupId;
  final String createdBy;
  final String creatorName;
  final String creatorAvatar;
  final DateTime? createdAt;

  NoteModel({
    required this.id,
    required this.content,
    required this.groupId,
    required this.createdBy,
    required this.creatorName,
    required this.creatorAvatar,
    this.createdAt,
  });

  factory NoteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      content: data['content'] ?? '',
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorAvatar: data['creatorAvatar'] ?? '🐱',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'content': content,
    'groupId': groupId,
    'createdBy': createdBy,
    'creatorName': creatorName,
    'creatorAvatar': creatorAvatar,
    'createdAt': FieldValue.serverTimestamp(),
  };
}