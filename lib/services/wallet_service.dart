import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import 'user_service.dart';

class WalletService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<WalletModel>> getUserWallets(
      String userId) {
    return _db
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map(WalletModel.fromDoc).toList());
  }

  static Future<WalletModel?> createWallet({
    required String name,
    required String emoji,
    double initialBalance = 0,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return null;
      final wallet = WalletModel(
        id: '',
        userId: userId,
        name: name,
        emoji: emoji,
        balance: initialBalance,
      );
      final doc = await _db
          .collection('wallets')
          .add(wallet.toMap());
      return WalletModel(
        id: doc.id,
        userId: userId,
        name: name,
        emoji: emoji,
        balance: initialBalance,
      );
    } catch (e) {
      debugPrint('Lỗi tạo ví: $e');
      return null;
    }
  }

  static Future<void> deleteWallet(
      String walletId) async {
    await _db
        .collection('wallets')
        .doc(walletId)
        .delete();
  }

  static Future<void> updateBalance({
    required String walletId,
    required double amount,
    required bool isIncome,
  }) async {
    try {
      final delta = isIncome ? amount : -amount;
      await _db
          .collection('wallets')
          .doc(walletId)
          .update({
        'balance': FieldValue.increment(delta),
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật số dư: $e');
    }
  }
}