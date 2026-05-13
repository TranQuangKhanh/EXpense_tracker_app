import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/note_model.dart';
import 'user_service.dart';

class GroupService {
  static final _firestore = FirebaseFirestore.instance;

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

      final doc = await _firestore
          .collection('groups')
          .add(group.toMap());

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

  static Stream<List<GroupModel>> getUserGroups(
      String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map(GroupModel.fromDoc).toList()
              ..sort((a, b) {
                final aTime =
                    a.lastMessageAt ?? a.createdAt;
                final bTime =
                    b.lastMessageAt ?? b.createdAt;
                return bTime.compareTo(aTime);
              }));
  }

  static Future<bool> addMember(
      String groupId, String userId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm thành viên: $e');
      return false;
    }
  }

  static Stream<List<NoteModel>> getGroupNotes(
      String groupId) {
    return _firestore
        .collection('notes')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NoteModel.fromDoc).toList());
  }

  static Future<bool> addNote({
    required String groupId,
    required String content,
    String type = 'text',
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

      await _firestore.collection('notes').add({
        ...note.toMap(),
        'type': type,
      });

      // ← QUAN TRỌNG: lưu userId (không phải displayName)
      // để check badge đỏ chính xác
      await _firestore
          .collection('groups')
          .doc(groupId)
          .update({
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': user.id, // ← userId
        'lastMessageSender': user.displayName, // hiển thị
      });

      // Đánh dấu đã đọc cho người gửi
      await markAsRead(groupId, user.id);

      return true;
    } catch (e) {
      debugPrint('Lỗi thêm note: $e');
      return false;
    }
  }

  static Future<void> markAsRead(
      String groupId, String userId) async {
    try {
      await _firestore
          .collection('group_read_status')
          .doc('${groupId}_$userId')
          .set({
        'groupId': groupId,
        'userId': userId,
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi mark read: $e');
    }
  }

  static Stream<int> getUnreadCount(
      String groupId, String userId) {
    return _firestore
        .collection('group_read_status')
        .doc('${groupId}_$userId')
        .snapshots()
        .asyncMap((readDoc) async {
      DateTime? lastReadAt;
      if (readDoc.exists) {
        lastReadAt =
            (readDoc.data()?['lastReadAt'] as Timestamp?)
                ?.toDate();
      }

      Query query = _firestore
          .collection('notes')
          .where('groupId', isEqualTo: groupId)
          .where('createdBy', isNotEqualTo: userId);

      if (lastReadAt != null) {
        query = query.where('createdAt',
            isGreaterThan:
                Timestamp.fromDate(lastReadAt));
      }

      final snap = await query.get();
      return snap.docs.length;
    });
  }
}