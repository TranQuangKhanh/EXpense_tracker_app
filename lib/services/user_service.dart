import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const _userIdKey = 'userId';
  static const _firebaseUidKey = 'firebaseUid';
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
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
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      _cachedUser = UserModel.fromDoc(doc);
      return _cachedUser;
    } catch (e) {
      debugPrint('Lỗi lấy user: $e');
      return null;
    }
  }

  // Kiểm tra SĐT đã tồn tại chưa
  // QUAN TRỌNG: phải có Firebase Auth trước khi gọi
  static Future<bool> isPhoneRegistered(
      String phone) async {
    if (phone.trim().isEmpty) return false;
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      debugPrint(
          '=== isPhoneRegistered($phone): '
          '${query.docs.isNotEmpty}');
      return query.docs.isNotEmpty;
    } catch (e) {
      // Nếu lỗi → coi như đã tồn tại (safe default)
      // Tránh tạo duplicate account
      debugPrint('=== isPhoneRegistered ERROR: $e');
      return true;
    }
  }

  // Tạo tài khoản mới
  static Future<UserModel?> createUser({
    required String name,
    required String phone,
    required String avatar,
  }) async {
    try {
      // B1: signOut trước để clear session cũ
      try {
        await _auth.signOut();
      } catch (_) {}

      // B2: signIn anonymous TRƯỚC để có auth
      // khi query Firestore check phone
      final credential =
          await _auth.signInAnonymously();
      final firebaseUid = credential.user!.uid;
      debugPrint('=== createUser UID: $firebaseUid');

      // B3: Giờ mới check phone (đã có auth rồi)
      if (phone.trim().isNotEmpty) {
        final exists =
            await isPhoneRegistered(phone.trim());
        if (exists) {
          debugPrint(
              '=== Phone exists → block createUser');
          // signOut vì không tạo được account
          try {
            await _auth.signOut();
          } catch (_) {}
          return null;
        }
      }

      // B4: Tạo user document
      final code = _generateCode();
      final user = UserModel(
        id: firebaseUid,
        name: name,
        phone: phone.trim(),
        code: code,
        avatar: avatar,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUid)
          .set(user.toMap());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, firebaseUid);
      await prefs.setString(
          _firebaseUidKey, firebaseUid);

      _cachedUser = user;
      debugPrint(
          '=== createUser success: ${user.name}');
      return user;
    } catch (e) {
      debugPrint('Lỗi tạo user: $e');
      return null;
    }
  }

  // Logout — KHÔNG signOut Firebase
  // Giữ session để relogin dễ hơn
  static Future<void> logout() async {
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_firebaseUidKey);
    // KHÔNG gọi _auth.signOut()
    // → Firebase giữ currentUser
    // → createUser sẽ signOut khi cần
  }

  // Relogin bằng SĐT
  static Future<String?> reloginWithPhone(
      String phone) async {
    try {
      final cleanPhone = phone.trim();
      if (cleanPhone.isEmpty ||
          cleanPhone.length < 9) {
        return 'Số điện thoại không hợp lệ';
      }

      // Đảm bảo có Firebase Auth để query
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } catch (_) {}
      }

      // Tìm user — thử nhiều format SĐT
      UserModel? user =
          await findUserByPhone(cleanPhone);
      if (user == null &&
          cleanPhone.startsWith('0')) {
        user = await findUserByPhone(
            '+84${cleanPhone.substring(1)}');
      }
      if (user == null &&
          cleanPhone.startsWith('+84')) {
        user = await findUserByPhone(
            '0${cleanPhone.substring(3)}');
      }
      if (user == null) {
        return 'Không tìm thấy tài khoản.\n'
            'Kiểm tra lại SĐT đã đăng ký.';
      }

      final prefs = await SharedPreferences.getInstance();
      final currentUid = _auth.currentUser?.uid;

      debugPrint(
          '=== relogin currentUid: $currentUid');
      debugPrint(
          '=== relogin targetId: ${user.id}');

      if (currentUid == user.id) {
        // Đúng UID — cùng thiết bị chưa đổi account
        await prefs.setString(_userIdKey, user.id);
        await prefs.setString(
            _firebaseUidKey, user.id);
        _cachedUser = null;
        debugPrint('=== Same UID — relogin success');
        return null;
      }

      // UID khác → tạo mapping
      // Dùng currentUid làm key
      await _createMapping(
          currentUid!, user.id, cleanPhone);

      await prefs.setString(_userIdKey, user.id);
      await prefs.setString(
          _firebaseUidKey, currentUid);
      _cachedUser = null;

      debugPrint('=== mapping created — success');
      return null;
    } catch (e) {
      debugPrint('=== LỖI RELOGIN: $e');
      return 'Có lỗi xảy ra: $e';
    }
  }

  static Future<void> _createMapping(
    String firebaseUid,
    String originalUserId,
    String phone,
  ) async {
    await _firestore
        .collection('uid_mappings')
        .doc(firebaseUid)
        .set({
      'originalUserId': originalUserId,
      'phone': phone,
      'firebaseUid': firebaseUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint(
        '=== mapping: $firebaseUid → $originalUserId');
  }

  static Future<String?> updatePhone(
      String phone) async {
    try {
      if (phone.trim().isEmpty) {
        return 'SĐT không hợp lệ';
      }
      final exists =
          await isPhoneRegistered(phone.trim());
      if (exists) {
        return 'Số điện thoại đã được dùng';
      }
      final userId = await getUserId();
      if (userId == null) {
        return 'Không tìm thấy tài khoản';
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'phone': phone.trim()});
      _cachedUser = null;
      return null;
    } catch (e) {
      return 'Có lỗi xảy ra';
    }
  }

  static Future<UserModel?> findUserByPhone(
      String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromDoc(query.docs.first);
    } catch (e) {
      debugPrint('Lỗi tìm user: $e');
      return null;
    }
  }

  static Future<UserModel?> findUserByNameCode(
      String nameCode) async {
    try {
      final parts = nameCode.trim().split('#');
      if (parts.length != 2) return null;
      final name = parts[0].trim();
      final code = parts[1].trim();
      if (name.isEmpty || code.isEmpty) return null;
      final query = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .where('code', isEqualTo: code)
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