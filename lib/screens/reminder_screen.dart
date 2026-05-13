import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../services/user_service.dart';
import '../widgets/common/sky_loader.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = await UserService.getUserId();
    if (mounted) setState(() => _userId = id);
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    int selectedDay = 1;
    String selectedEmoji = '📋';
    final emojis = [
      '📋', '💡', '🏠', '💊', '📚', '🎯',
      '💳', '🚗', '💻', '🎵', '🌿', '⚡',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
                  AppSpacing.md,
          top: AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('🔔', style: TextStyle(fontSize: 24)),
                SizedBox(width: AppSpacing.sm),
                Text('Thêm nhắc nhở',
                    style: AppTextStyles.heading3),
              ]),
              const SizedBox(height: AppSpacing.md),

              // Emoji picker
              const Text('Biểu tượng',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: emojis.map((e) {
                  final isSel = selectedEmoji == e;
                  return GestureDetector(
                    onTap: () =>
                        setModal(() => selectedEmoji = e),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryLight
                            : AppColors.background,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Text(e,
                              style:
                                  const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhắc nhở',
                  hintText: 'VD: Trả tiền điện, Học phí...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền ước tính (đ)',
                  prefixIcon:
                      Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Day picker
              Row(
                children: [
                  const Text('Ngày hàng tháng: ',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedDay,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.primaryLight,
                      ),
                      items: List.generate(28, (i) => i + 1)
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('Ngày $d'),
                              ))
                          .toList(),
                      onChanged: (v) => setModal(
                          () => selectedDay = v ?? 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text
                            .trim()
                            .isEmpty ||
                        _userId == null) return;
                    await FirebaseFirestore.instance
                        .collection('reminders')
                        .add({
                      'userId': _userId,
                      'title': titleController.text.trim(),
                      'amount': double.tryParse(
                              amountController.text
                                  .trim()) ??
                          0,
                      'dayOfMonth': selectedDay,
                      'emoji': selectedEmoji,
                      'isActive': true,
                      'createdAt':
                          FieldValue.serverTimestamp(),
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content:
                              Text('✅ Đã thêm nhắc nhở!')),
                    );
                  },
                  child: const Text('Thêm nhắc nhở'),
                ),
              ),
            ],
          ),
        ),
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
            Text('🔔', style: TextStyle(fontSize: 20)),
            SizedBox(width: AppSpacing.sm),
            Text('Nhắc nhở định kỳ'),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 20),
            ),
            onPressed: _showAddReminderDialog,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _userId == null
          ? const SkyLoader()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reminders')
                  .where('userId', isEqualTo: _userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SkyLoader(
                      message: 'Đang tải...');
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔔',
                            style:
                                TextStyle(fontSize: 56)),
                        const SizedBox(
                            height: AppSpacing.md),
                        const Text('Chưa có nhắc nhở nào',
                            style: AppTextStyles.heading3),
                        const SizedBox(
                            height: AppSpacing.xs),
                        const Text(
                          'Thêm nhắc nhở để không bỏ lỡ\ncác khoản thanh toán định kỳ',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(
                            height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed:
                              _showAddReminderDialog,
                          icon:
                              const Icon(Icons.add_rounded),
                          label:
                              const Text('Thêm nhắc nhở'),
                        ),
                      ],
                    ),
                  );
                }

                // Group by upcoming day
                final today = DateTime.now().day;
                final upcoming = docs.where((d) {
                  final day = (d.data()
                          as Map<String, dynamic>)[
                      'dayOfMonth'] as int? ?? 1;
                  return day >= today;
                }).toList()
                  ..sort((a, b) {
                    final da = (a.data()
                            as Map<String, dynamic>)[
                        'dayOfMonth'] as int? ?? 1;
                    final db = (b.data()
                            as Map<String, dynamic>)[
                        'dayOfMonth'] as int? ?? 1;
                    return da.compareTo(db);
                  });
                final past = docs.where((d) {
                  final day = (d.data()
                          as Map<String, dynamic>)[
                      'dayOfMonth'] as int? ?? 1;
                  return day < today;
                }).toList();

                return ListView(
                  padding:
                      const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const Text('Sắp tới',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  AppColors.textSecondary,
                              fontSize: 13)),
                      const SizedBox(
                          height: AppSpacing.sm),
                      ...upcoming.map((doc) =>
                          _buildReminderCard(doc)),
                      const SizedBox(
                          height: AppSpacing.md),
                    ],
                    if (past.isNotEmpty) ...[
                      const Text('Đã qua tháng này',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  AppColors.textSecondary,
                              fontSize: 13)),
                      const SizedBox(
                          height: AppSpacing.sm),
                      ...past.map((doc) =>
                          _buildReminderCard(doc,
                              isPast: true)),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _buildReminderCard(QueryDocumentSnapshot doc,
      {bool isPast = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? '';
    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0;
    final day = data['dayOfMonth'] as int? ?? 1;
    final emoji = data['emoji'] as String? ?? '📋';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isPast
            ? AppColors.background
            : AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppRadius.lg),
        border: !isPast
            ? Border.all(
                color:
                    AppColors.primary.withOpacity(0.2))
            : null,
        boxShadow: !isPast
            ? [
                BoxShadow(
                  color:
                      AppColors.primary.withOpacity(0.06),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPast
                ? Colors.grey.withOpacity(0.1)
                : AppColors.primaryLight,
            borderRadius:
                BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(emoji,
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPast
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            )),
        subtitle: Text(
          'Ngày $day hàng tháng',
          style: TextStyle(
            fontSize: 12,
            color: isPast
                ? AppColors.textSecondary
                : AppColors.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (amount > 0)
              Text(
                '~${_formatAmount(amount)} đ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isPast
                      ? AppColors.textSecondary
                      : AppColors.expense,
                ),
              ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade300),
              onPressed: () =>
                  doc.reference.delete(),
            ),
          ],
        ),
      ),
    );
  }
}