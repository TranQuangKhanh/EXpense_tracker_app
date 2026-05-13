import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../services/user_service.dart';
import '../widgets/common/sky_loader.dart';
import 'stats_detail_screen.dart';

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
      if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; }
      else if (_selectedMonth < 1) { _selectedMonth = 12; _selectedYear--; }
    });
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) return '${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(abs / 1000).toStringAsFixed(0)}K';
    return abs.toStringAsFixed(0);
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
        if (userId == null) return const SkyLoader();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'confirmed')
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
              .where('date',
                  isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkyLoader(message: 'Đang tải...');
            }

            final transactions = snapshot.hasData
                ? snapshot.data!.docs
                    .map(TransactionModel.fromDoc)
                    .toList()
                : <TransactionModel>[];

            final totalIncome = transactions
                .where((t) => t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);
            final totalExpense = transactions
                .where((t) => !t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);
            final balance = totalIncome - totalExpense;
            final isPositive = balance >= 0;
            final savingRate = totalIncome > 0
                ? ((totalIncome - totalExpense) / totalIncome * 100)
                    .clamp(0, 100)
                : 0.0;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ── Month selector ──
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_left_rounded),
                        color: AppColors.primary,
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                          'Tháng $_selectedMonth/$_selectedYear',
                          style: AppTextStyles.heading3),
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_right_rounded),
                        color: AppColors.primary,
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),

                // ── Overview card — tap để vào chi tiết ──
                GestureDetector(
                  onTap: transactions.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatsDetailScreen(
                                month: _selectedMonth,
                                year: _selectedYear,
                                userId: userId,
                              ),
                            ),
                          ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPositive
                            ? AppColors.gradientSky
                            : AppColors.gradientRose,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: (isPositive
                                  ? AppColors.primary
                                  : AppColors.expense)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Mascot mờ góc phải
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Opacity(
                            opacity: 0.15,
                            child: const Text('🦉',
                                style:
                                    TextStyle(fontSize: 80)),
                          ),
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Label tháng
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(
                                        AppRadius.round),
                              ),
                              child: Text(
                                'Tháng $_selectedMonth/$_selectedYear',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // Balance lớn
                            Text(
                              '${isPositive ? '+' : ''}${_formatAmount(balance)} đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const Text('Số dư',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12)),

                            const SizedBox(height: AppSpacing.md),

                            // Thu / Chi
                            Row(
                              children: [
                                Expanded(
                                    child: _buildStatBox(
                                  label: 'Thu nhập',
                                  amount: totalIncome,
                                  icon: Icons
                                      .arrow_downward_rounded,
                                  color: const Color(0xFF80DEEA),
                                  isIncome: true,
                                )),
                                const SizedBox(
                                    width: AppSpacing.sm),
                                Expanded(
                                    child: _buildStatBox(
                                  label: 'Chi tiêu',
                                  amount: totalExpense,
                                  icon:
                                      Icons.arrow_upward_rounded,
                                  color: const Color(0xFFFFCC80),
                                  isIncome: false,
                                )),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Saving rate bar
                            if (totalIncome > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  const Text('Tỷ lệ tiết kiệm',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11)),
                                  Text(
                                      '${savingRate.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        AppRadius.round),
                                child: LinearProgressIndicator(
                                  value: savingRate / 100,
                                  backgroundColor:
                                      Colors.white24,
                                  valueColor:const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 5,
                                ),
                              ),
                            ],

                            // Hint tap vào xem chi tiết
                            if (transactions.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppRadius.round),
                                    ),
                                    child: const Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Xem chi tiết',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons
                                              .arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Empty hint ──
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primary.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🦉',
                            style: TextStyle(fontSize: 56)),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Chưa có dữ liệu',
                            style: AppTextStyles.heading3),
                        Text(
                          'Tháng $_selectedMonth/$_selectedYear\nchưa có giao dịch nào',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatBox({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${isIncome ? '+' : '-'}${_formatAmount(amount)} đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}