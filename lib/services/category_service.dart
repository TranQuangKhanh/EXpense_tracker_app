import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/custom_category_model.dart';
import 'user_service.dart';

class CategoryService {
  static final _firestore = FirebaseFirestore.instance;

  // Lấy danh sách category tự tạo của user
  static Stream<List<CustomCategoryModel>> getUserCategories(
      String userId) {
    return _firestore
        .collection('custom_categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CustomCategoryModel.fromDoc).toList());
  }

  // Tạo category mới
  static Future<CustomCategoryModel?> createCategory({
    required String name,
    required String emoji,
  }) async {
    try {
      final userId = await UserService.getUserId() ?? '';
      final category = CustomCategoryModel(
        id: '',
        name: name,
        emoji: emoji,
        userId: userId,
      );
      final doc = await _firestore
          .collection('custom_categories')
          .add(category.toMap());
      return CustomCategoryModel(
        id: doc.id,
        name: name,
        emoji: emoji,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Lỗi tạo category: $e');
      return null;
    }
  }

  // Xóa category
  static Future<void> deleteCategory(String categoryId) async {
    await _firestore
        .collection('custom_categories')
        .doc(categoryId)
        .delete();
  }

  // Lấy số giao dịch chờ xác nhận
  static Stream<int> getPendingCount(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}