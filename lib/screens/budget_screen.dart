import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/category_model.dart';
import '../services/user_service.dart';
import '../widgets/common/sky_loader.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final int _month = DateTime.now().month;
  final int _year = DateTime.now().year;
  String? _userId;
  Map<String, double> _budgets = {};
  Map<String, double> _spent = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = await UserService.getUserId();
    if (!mounted) return;
    setState(() => _userId = uid);
    if (uid == null) return;

    // Load budgets
    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc('${uid}_${_year}_$_month')
        .get();
    if (budgetDoc.exists) {
      final data = budgetDoc.data() as Map<String, dynamic>;
      _budgets = data.map(
          (k, v) => MapEntry(k, (v as num).toDouble()));
    }

    // Load spent this month
    final firstDay = DateTime(_year, _month, 1);
    final lastDay =
        DateTime(_year, _month + 1, 0, 23, 59, 59);
    final snap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'confirmed')
        .where('date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(firstDay))
        .where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
        .get();

    final Map<String, double> spent = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['type'] == 'expense') {
        final catId = data['categoryId'] as String? ?? '';
        spent[catId] =
            (spent[catId] ?? 0) + (data['amount'] as num).toDouble();
      }
    }

    if (mounted) {
      setState(() {
        _spent = spent;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBudget(String categoryId, double amount) async {
    if (_userId == null) return;
    setState(() => _budgets[categoryId] = amount);
    await FirebaseFirestore.instance
        .collection('budgets')
        .doc('${_userId}_${_year}_$_month')
        .set(_budgets);
  }

  void _showSetBudgetDialog(CategoryModel cat) {
    final controller = TextEditingController(
      text: _budgets[cat.id]?.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(
          children: [
            Text(AppMascots.categoryIcons[cat.id] ?? '💸',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.sm),
            Text('Ngân sách ${cat.name}'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền giới hạn (đ)',
            prefixIcon:
                Icon(Icons.attach_money_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(
                  controller.text.trim());
              if (val != null && val > 0) {
                _saveBudget(cat.id, val);
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000)
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000)
      return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🎯', style: TextStyle(fontSize: 20)),
            SizedBox(width: AppSpacing.sm),
            Text('Ngân sách tháng'),
          ],
        ),
      ),
      body: _isLoading
          ? const SkyLoader(message: 'Đang tải...')
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header card
                Container(
                  padding:
                      const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.gradientSky),
                    borderRadius:
                        BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯',
                          style: TextStyle(fontSize: 28)),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Ngân sách tháng',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                          Text(
                            'Tháng $_month/$_year',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                const Text(
                  'Nhấn vào danh mục để đặt giới hạn chi tiêu',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),

                // Category budget list
                ...AppCategories.expense.map((cat) {
                  final budget = _budgets[cat.id] ?? 0;
                  final spent = _spent[cat.id] ?? 0;
                  final ratio = budget > 0
                      ? (spent / budget).clamp(0.0, 1.0)
                      : 0.0;
                  final isOver = spent > budget && budget > 0;
                  final emoji =
                      AppMascots.categoryIcons[cat.id] ??
                          '💸';

                  return GestureDetector(
                    onTap: () => _showSetBudgetDialog(cat),
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: AppSpacing.sm),
                      padding:
                          const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg),
                        border: isOver
                            ? Border.all(
                                color: AppColors.expense
                                    .withOpacity(0.5),
                                width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: cat.color
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppRadius.md),
                                ),
                                child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(
                                          fontSize: 20)),
                                ),
                              ),
                              const SizedBox(
                                  width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(cat.name,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w600)),
                                    Text(
                                      budget > 0
                                          ? '${_formatAmount(spent)} / ${_formatAmount(budget)} đ'
                                          : 'Chưa đặt giới hạn',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOver
                                            ? AppColors
                                                .expense
                                            : AppColors
                                                .textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOver)
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        AppSpacing.sm,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors
                                        .expenseLight,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.round),
                                  ),
                                  child: const Text(
                                    '⚠️ Vượt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.expense,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors
                                      .textSecondary,
                                ),
                            ],
                          ),
                          if (budget > 0) ...[
                            const SizedBox(
                                height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.round),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: cat.color
                                    .withOpacity(0.1),
                                valueColor:
                                    AlwaysStoppedAnimation(
                                  isOver
                                      ? AppColors.expense
                                      : cat.color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}