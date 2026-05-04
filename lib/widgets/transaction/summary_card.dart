import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
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
            const Text(
              'Số dư',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${balance.toStringAsFixed(0)} đ',
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
                _buildItem('↓ Thu nhập', totalIncome, Colors.greenAccent),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildItem('↑ Chi tiêu', totalExpense, Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, double amount, Color color) {
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
}