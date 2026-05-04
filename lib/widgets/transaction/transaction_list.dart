import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../services/user_service.dart';
import '../../services/category_service.dart';
import '../../screens/pending_screen.dart';
import '../../widgets/common/empty_state.dart';
import 'summary_card.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  Future<void> _deleteTransaction(String docId) async {
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay =
        DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    return FutureBuilder<String?>(
      future: UserService.getUserId(),
      builder: (context, userSnapshot) {
        final userId = userSnapshot.data;
        if (userId == null) return const SizedBox();

        return Column(
          children: [
            _buildMonthSelector(userId),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('userId', isEqualTo: userId)
                    .where('status', isEqualTo: 'confirmed')
                    .where('date',
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(firstDay))
                    .where('date',
                        isLessThanOrEqualTo:
                            Timestamp.fromDate(lastDay))
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Lỗi: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const EmptyState(
                      emoji: '💸',
                      title: 'Chưa có giao dịch',
                      subtitle:
                          'Nhấn nút + để thêm giao dịch đầu tiên',
                    );
                  }

                  final transactions = snapshot.data!.docs
                      .map(TransactionModel.fromDoc)
                      .toList();

                  final totalIncome = transactions
                      .where((t) => t.isIncome)
                      .fold(0.0, (sum, t) => sum + t.amount);
                  final totalExpense = transactions
                      .where((t) => !t.isIncome)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  return Column(
                    children: [
                      SummaryCard(
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(
                                transactions[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Text(
              'Tháng $_selectedMonth/$_selectedYear',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),

          // Badge đỏ chờ xác nhận
          StreamBuilder<int>(
            stream: CategoryService.getPendingCount(userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox();
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.circular(AppRadius.round),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$count chờ xác nhận',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final category = AppCategories.findById(t.categoryId);
    final categoryIcon = category?.icon ?? Icons.more_horiz;
    final categoryColor = category?.color ?? Colors.grey;
    final categoryName = category?.name ?? 'Khác';
    final dateStr = t.date != null
        ? '${t.date!.day}/${t.date!.month}/${t.date!.year}'
        : 'Không rõ ngày';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: categoryColor.withOpacity(0.2),
        child: Icon(categoryIcon, color: categoryColor),
      ),
      title: Row(
        children: [
          Expanded(child: Text(t.title)),
          if (t.isAuto)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text(
                'Auto',
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '$categoryName • $dateStr',
        style: AppTextStyles.caption,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${t.isIncome ? '+' : '-'}${t.amount.toStringAsFixed(0)} đ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: t.isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _deleteTransaction(t.id),
          ),
        ],
      ),
    );
  }
}