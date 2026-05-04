import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/note_model.dart';
import 'user_service.dart';

class GroupService {
  static final _firestore = FirebaseFirestore.instance;

  // Tạo nhóm mới
  static Future<GroupModel?> createGroup({
    required String name,
    required String emoji,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return null;

      final group = GroupModel(
        id: '',
        name: name,
        emoji: emoji,
        memberIds: [userId],
        createdBy: userId,
        createdAt: DateTime.now(),
      );

      final doc = await _firestore.collection('groups').add(group.toMap());
      return GroupModel(
        id: doc.id,
        name: group.name,
        emoji: group.emoji,
        memberIds: group.memberIds,
        createdBy: group.createdBy,
        createdAt: group.createdAt,
      );
    } catch (e) {
      debugPrint('Lỗi tạo nhóm: $e');
      return null;
    }
  }

  // Lấy danh sách nhóm của user
  static Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(GroupModel.fromDoc).toList());
  }

  // Thêm thành viên vào nhóm
  static Future<bool> addMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm thành viên: $e');
      return false;
    }
  }

  // Lấy notes của nhóm
  static Stream<List<NoteModel>> getGroupNotes(String groupId) {
    return _firestore
        .collection('notes')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NoteModel.fromDoc).toList());
  }

  // Thêm note
  static Future<bool> addNote({
    required String groupId,
    required String content,
  }) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) return false;

      final note = NoteModel(
        id: '',
        content: content,
        groupId: groupId,
        createdBy: user.id,
        creatorName: user.displayName,
        creatorAvatar: user.avatar,
      );

      await _firestore.collection('notes').add(note.toMap());
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm note: $e');
      return false;
    }
  }
}