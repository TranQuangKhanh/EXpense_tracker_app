import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final int month;
  final int year;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    this.month = 0,
    this.year = 0,
    this.onAddExpense,
    this.onAddIncome,
  });

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) return '${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(abs / 1000).toStringAsFixed(0)}K';
    return abs.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;
    final isPositive = balance >= 0;
    final savingRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome * 100).clamp(0, 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? AppColors.gradientSky
                : AppColors.gradientRose,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: [
            BoxShadow(
              color: (isPositive ? AppColors.primary : AppColors.expense)
                  .withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Mascot trang trí góc phải
            Positioned(
              right: 16,
              top: 12,
              child: Opacity(
                opacity: 0.18,
                child: Text(
                  isPositive ? '🦌' : '🐇',
                  style: const TextStyle(fontSize: 72),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Row 1 — Label tháng
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.round),
                        ),
                        child: Text(
                          month > 0
                              ? 'Tháng $month/$year'
                              : 'Tổng quan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Row 2 — Số dư lớn
                  Text(
                    '${isPositive ? '+' : ''}${_formatAmount(balance)} đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'Số dư',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Row 3 — Thu / Chi
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          label: 'Thu nhập',
                          amount: totalIncome,
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF80DEEA),
                          isIncome: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatBox(
                          label: 'Chi tiêu',
                          amount: totalExpense,
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFFFCC80),
                          isIncome: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Row 4 — Tiến độ tiết kiệm
                  if (totalIncome > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tỷ lệ tiết kiệm',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${savingRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      child: LinearProgressIndicator(
                        value: savingRate / 100,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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