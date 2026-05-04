import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/user_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
            // Thanh chọn tháng
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.primaryLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    'Tháng $_selectedMonth/$_selectedYear',
                    style: AppTextStyles.heading3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('userId', isEqualTo: userId)
                    .where('date',
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(firstDay))
                    .where('date',
                        isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có dữ liệu\ntrong tháng này.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }

                  final transactions = snapshot.data!.docs
                      .map(TransactionModel.fromDoc)
                      .toList();

                  final Map<String, double> categoryTotals = {};
                  for (var t in transactions.where((t) => !t.isIncome)) {
                    categoryTotals[t.categoryId] =
                        (categoryTotals[t.categoryId] ?? 0) + t.amount;
                  }

                  final totalExpense = categoryTotals.values
                      .fold(0.0, (sum, v) => sum + v);
                  final totalIncome = transactions
                      .where((t) => t.isIncome)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  final sortedCategories =
                      categoryTotals.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildOverviewCard(totalIncome, totalExpense),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Chi tiêu theo danh mục',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...sortedCategories.map((entry) {
                        final category =
                            AppCategories.findById(entry.key);
                        final percent = totalExpense > 0
                            ? entry.value / totalExpense
                            : 0.0;
                        return _buildCategoryRow(
                          name: category?.name ?? 'Khác',
                          icon: category?.icon ?? Icons.more_horiz,
                          color: category?.color ?? Colors.grey,
                          amount: entry.value,
                          percent: percent,
                        );
                      }),
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

  Widget _buildOverviewCard(double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Text(
            'Tháng $_selectedMonth/$_selectedYear',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(income - expense).toStringAsFixed(0)} đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('↓ Thu nhập', income, Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildOverviewItem('↑ Chi tiêu', expense, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${amount.toStringAsFixed(0)} đ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required String name,
    required IconData icon,
    required Color color,
    required double amount,
    required double percent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${amount.toStringAsFixed(0)} đ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}