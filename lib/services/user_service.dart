import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const _userIdKey = 'userId';
  static final _firestore = FirebaseFirestore.instance;
  static UserModel? _cachedUser;

  static String _generateCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  static Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<UserModel?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    final userId = await getUserId();
    if (userId == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      _cachedUser = UserModel.fromDoc(doc);
      return _cachedUser;
    } catch (e) {
      debugPrint('Lỗi lấy user: $e');
      return null;
    }
  }

  static Future<UserModel?> createUser({
    required String name,
    required String phone,
    required String avatar,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final userId = credential.user!.uid;
      final code = _generateCode();

      final user = UserModel(
        id: userId,
        name: name,
        phone: phone,
        code: code,
        avatar: avatar,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(user.toMap());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);

      _cachedUser = user;
      return user;
    } catch (e) {
      debugPrint('Lỗi tạo user: $e');
      return null;
    }
  }

  static Future<UserModel?> findUserByPhone(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromDoc(query.docs.first);
    } catch (e) {
      debugPrint('Lỗi tìm user: $e');
      return null;
    }
  }

  static void clearCache() => _cachedUser = null;
}