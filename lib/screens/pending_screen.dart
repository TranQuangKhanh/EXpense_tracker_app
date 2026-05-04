import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/custom_category_model.dart';
import '../services/category_service.dart';
import '../services/user_service.dart';
import '../widgets/common/empty_state.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  String? _userId;
  List<CustomCategoryModel> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await UserService.getUserId();
    if (!mounted) return;
    setState(() => _userId = userId);

    if (userId != null) {
      CategoryService.getUserCategories(userId).listen((cats) {
        if (mounted) setState(() => _customCategories = cats);
      });
    }
  }

  // Xác nhận giao dịch với category đã chọn
  Future<void> _confirmTransaction(
      String docId, String categoryId) async {
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(docId)
        .update({
      'status': 'confirmed',
      'categoryId': categoryId,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xác nhận giao dịch ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Xóa giao dịch
  Future<void> _deleteTransaction(String docId) async {
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(docId)
        .delete();
  }

  // Hiện bottom sheet chọn category
  void _showCategoryPicker(
      TransactionModel transaction, List<CategoryModel> defaultCats) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn danh mục', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),

            // Danh mục mặc định
            const Text('Danh mục mặc định',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: defaultCats.map((cat) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmTransaction(transaction.id, cat.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      border: Border.all(
                          color: cat.color.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, color: cat.color, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(cat.name,
                            style: TextStyle(color: cat.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Danh mục tự tạo
            if (_customCategories.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Text('Danh mục của tôi',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _customCategories.map((cat) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _confirmTransaction(transaction.id, cat.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.round),
                        border: Border.all(
                            color: Colors.blueGrey.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji),
                          const SizedBox(width: AppSpacing.xs),
                          Text(cat.name),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chờ xác nhận'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: _userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              emoji: '✅',
              title: 'Không có giao dịch chờ',
              subtitle: 'Tất cả giao dịch đã được xác nhận',
            );
          }

          final transactions = snapshot.data!.docs
              .map(TransactionModel.fromDoc)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final suggestedCat =
                  AppCategories.findById(t.categoryId);

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề + số tiền
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(t.title,
                                style: AppTextStyles.heading3),
                          ),
                          Text(
                            '${t.isIncome ? '+' : '-'}${t.amount.toStringAsFixed(0)} đ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: t.isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Category gợi ý
                      Row(
                        children: [
                          const Text('Gợi ý: ',
                              style: AppTextStyles.bodySmall),
                          if (suggestedCat != null) ...[
                            Icon(suggestedCat.icon,
                                color: suggestedCat.color, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              suggestedCat.name,
                              style: TextStyle(
                                color: suggestedCat.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else
                            const Text('Không xác định'),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Nút hành động
                      Row(
                        children: [
                          // Xác nhận với category gợi ý
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmTransaction(
                                t.id,
                                t.categoryId,
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Xác nhận'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.income,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),

                          // Đổi category
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCategoryPicker(
                                t,
                                t.isIncome
                                    ? AppCategories.income
                                    : AppCategories.expense,
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Đổi danh mục'),
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),

                          // Xóa
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                _deleteTransaction(t.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}