import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/custom_category_model.dart';
import '../services/category_service.dart';
import '../widgets/common/sky_loader.dart';

class StatsDetailScreen extends StatefulWidget {
  final int month;
  final int year;
  final String userId;

  const StatsDetailScreen({
    super.key,
    required this.month,
    required this.year,
    required this.userId,
  });

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  String? _selectedCategoryId;
  final Set<String> _expandedCategories = {};
  List<CustomCategoryModel> _customCategories = [];

  static const List<Color> _pieColors = [
    Color(0xFF29B6F6), Color(0xFFFF7096), Color(0xFF80DEEA),
    Color(0xFFFFB74D), Color(0xFFCE93D8), Color(0xFF80CBC4),
    Color(0xFFFFD54F), Color(0xFFA5D6A7), Color(0xFFEF9A9A),
    Color(0xFF90CAF9),
  ];

  @override
  void initState() {
    super.initState();
    CategoryService.getUserCategories(widget.userId).listen((cats) {
      if (mounted) setState(() => _customCategories = cats);
    });
  }

  String _getCategoryName(String id) {
    final def = AppCategories.findById(id);
    if (def != null) return def.name;
    return _customCategories.where((c) => c.id == id).firstOrNull?.name ?? 'Khác';
  }

  String _getCategoryEmoji(String id) {
    final icon = AppMascots.categoryIcons[id];
    if (icon != null) return icon;
    return _customCategories.where((c) => c.id == id).firstOrNull?.emoji ?? '💸';
  }

  Color _getCategoryColor(String id, int index) {
    final def = AppCategories.findById(id);
    if (def != null) return def.color;
    return _pieColors[index % _pieColors.length];
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) return '${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(abs / 1000).toStringAsFixed(0)}K';
    return abs.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(widget.year, widget.month, 1);
    final lastDay = DateTime(widget.year, widget.month + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Text('Tháng ${widget.month}/${widget.year}'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: widget.userId)
            .where('status', isEqualTo: 'confirmed')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkyLoader(message: 'Đang tải...');
          }

          final all = snapshot.hasData
              ? snapshot.data!.docs.map(TransactionModel.fromDoc).toList()
              : <TransactionModel>[];

          final expenses = all.where((t) => !t.isIncome).toList();
          final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);

          final Map<String, List<TransactionModel>> catTransactions = {};
          for (final t in expenses) {
            catTransactions.putIfAbsent(t.categoryId, () => []).add(t);
          }

          final Map<String, double> catTotals = {
            for (final e in catTransactions.entries)
              e.key: e.value.fold(0.0, (s, t) => s + t.amount),
          };

          final sorted = catTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final displayedCats = _selectedCategoryId != null
              ? sorted.where((e) => e.key == _selectedCategoryId).toList()
              : sorted;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDonutSection(sorted, catTransactions, totalExpense),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildWeeklyChart(expenses),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🦊', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _selectedCategoryId != null
                                  ? _getCategoryName(_selectedCategoryId!)
                                  : 'Tất cả danh mục',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                        if (_selectedCategoryId != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppRadius.round),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 2),
                                  Text(
                                    'Bỏ lọc',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...displayedCats.asMap().entries.map((e) {
                      final idx = sorted.indexWhere((s) => s.key == e.value.key);
                      return _buildExpandableCategoryCard(
                        index: idx,
                        categoryId: e.value.key,
                        transactions: catTransactions[e.value.key] ?? [],
                        total: e.value.value,
                        totalExpense: totalExpense,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonutSection(
    List<MapEntry<String, double>> sorted,
    Map<String, List<TransactionModel>> catTransactions,
    double total,
  ) {
    if (sorted.isEmpty) return const SizedBox();

    final colors = List.generate(
      sorted.length,
      (i) => _getCategoryColor(sorted[i].key, i),
    );

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              GestureDetector(
                onTapUp: (details) {
                  const center = Offset(90, 90);
                  final tap = details.localPosition - center;
                  if (tap.distance > 90 || tap.distance < 45) return;
                  double angle = math.atan2(tap.dy, tap.dx) + math.pi / 2;
                  if (angle < 0) angle += 2 * math.pi;
                  double cumulative = 0;
                  for (int i = 0; i < sorted.length; i++) {
                    final sweep = (sorted[i].value / total) * 2 * math.pi;
                    cumulative += sweep;
                    if (angle <= cumulative) {
                      setState(() {
                        _selectedCategoryId =
                            _selectedCategoryId == sorted[i].key
                                ? null
                                : sorted[i].key;
                      });
                      break;
                    }
                  }
                },
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      data: sorted,
                      total: total,
                      colors: colors,
                      selectedId: _selectedCategoryId,
                    ),
                    child: Center(
                      child: _selectedCategoryId != null
                          ? Builder(
                              builder: (context) {
                                final selectedTotal = catTransactions[_selectedCategoryId]
                                        ?.fold<double>(0.0, (s, t) => s + t.amount) ??
                                    0.0;
                                final selectedPct = total > 0
                                    ? (selectedTotal / total * 100).toStringAsFixed(0)
                                    : '0';
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getCategoryEmoji(_selectedCategoryId!),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    Text(
                                      '${_formatAmount(selectedTotal)} đ',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$selectedPct%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💸', style: TextStyle(fontSize: 20)),
                                Text(
                                  '${_formatAmount(total)} đ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Tổng chi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sorted.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final color = colors[idx];
                    final pct = total > 0
                        ? (entry.value / total * 100).toStringAsFixed(1)
                        : '0';
                    final isSelected = _selectedCategoryId == entry.key;

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategoryId = isSelected ? null : entry.key;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: isSelected
                              ? Border.all(color: color.withOpacity(0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_getCategoryEmoji(entry.key)} ${_getCategoryName(entry.key)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Tap vào biểu đồ hoặc legend để lọc',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<TransactionModel> expenses) {
    final Map<int, double> weekTotals = {1: 0, 2: 0, 3: 0, 4: 0};
    for (final t in expenses) {
      if (t.date == null) continue;
      final w = ((t.date!.day - 1) / 7).floor() + 1;
      weekTotals[w.clamp(1, 4)] = (weekTotals[w.clamp(1, 4)] ?? 0) + t.amount;
    }
    final maxVal = weekTotals.values.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('📅', style: TextStyle(fontSize: 16)),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Chi tiêu theo tuần',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekTotals.entries.map((e) {
              final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
              final isHighest = e.value == maxVal && maxVal > 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Text(
                        _formatAmount(e.value),
                        style: TextStyle(
                          fontSize: 9,
                          color: isHighest
                              ? AppColors.expense
                              : AppColors.textSecondary,
                          fontWeight: isHighest
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 80 * ratio + 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHighest
                                  ? AppColors.gradientRose
                                  : AppColors.gradientSky,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'T${e.key}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isHighest
                              ? AppColors.expense
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCategoryCard({
    required int index,
    required String categoryId,
    required List<TransactionModel> transactions,
    required double total,
    required double totalExpense,
  }) {
    final color = _getCategoryColor(categoryId, index);
    final emoji = _getCategoryEmoji(categoryId);
    final name = _getCategoryName(categoryId);
    final percent = totalExpense > 0 ? total / totalExpense : 0.0;
    final isExpanded = _expandedCategories.contains(categoryId);
    final isSelected = _selectedCategoryId == categoryId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isSelected
            ? Border.all(color: color.withOpacity(0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedCategories.remove(categoryId);
              } else {
                _expandedCategories.add(categoryId);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_formatAmount(total)} đ',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(percent * 100).toStringAsFixed(1)}% • ${transactions.length} giao dịch',
                              style: AppTextStyles.caption,
                            ),
                            Row(
                              children: [
                                Text(
                                  isExpanded ? 'Thu gọn' : 'Xem giao dịch',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: color,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: color.withOpacity(0.2)),
            ...transactions.map((t) {
              final dateStr = t.date != null
                  ? '${t.date!.day}/${t.date!.month}'
                  : '';
              return ListTile(
                dense: true,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                title: Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  '-${_formatAmount(t.amount)} đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;
  final List<Color> colors;
  final String? selectedId;

  const _DonutPainter({
    required this.data,
    required this.total,
    required this.colors,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final innerRadius = radius * 0.5;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * 2 * math.pi;
      final isSelected = selectedId == data[i].key;

      fillPaint.color = isSelected
          ? colors[i]
          : (selectedId != null ? colors[i].withOpacity(0.4) : colors[i]);

      final r = isSelected ? radius + 6 : radius;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: r),
          startAngle,
          sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);

      startAngle += sweep;
    }

    // Donut hole
    final holePaint = Paint()
      ..color = const Color(0xFFF0F9FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, holePaint);

    final holeBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, innerRadius, holeBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.selectedId != selectedId || old.data != data;
}