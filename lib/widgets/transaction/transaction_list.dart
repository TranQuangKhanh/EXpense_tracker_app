import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/custom_category_model.dart';
import '../../services/user_service.dart';
import '../../services/category_service.dart';
import '../../screens/pending_screen.dart';
import '../../widgets/common/sky_loader.dart';
import '../../widgets/transaction/transaction_form.dart';
import '../../screens/stats_detail_screen.dart';
import 'summary_card.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() =>
      _TransactionListState();
}

class _TransactionListState
    extends State<TransactionList> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<CustomCategoryModel> _customCategories = [];
  String? _userId;

  static const _bankLogos = {
    'MoMo': 'assets/banks/momo.png',
    'Vietcombank': 'assets/banks/vcb.png',
    'MBBank': 'assets/banks/mbbank.png',
    'Techcombank': 'assets/banks/techcombank.png',
    'BIDV': 'assets/banks/bidv.png',
    'Agribank': 'assets/banks/agribank.png',
    'TPBank': 'assets/banks/tpbank.png',
    'VPBank': 'assets/banks/vpbank.png',
    'ACB': 'assets/banks/acb.png',
    'Sacombank': 'assets/banks/sacombank.png',
    'Vietinbank': 'assets/banks/vietinbank.png',
    'SHB': 'assets/banks/shb.png',
    'ZaloPay': 'assets/banks/zalopay.png',
    'ShopeePay': 'assets/banks/shopeepay.png',
    'VNPay': 'assets/banks/vnpay.png',
    'GrabPay': 'assets/banks/grabpay.png',
    'ViettelPay': 'assets/banks/viettelpay.png',
    'ViettelMoney': 'assets/banks/viettelpay.png',
  };

  Widget _buildBankLogo(String bankName,
      {double size = 16}) {
    final path = _bankLogos[bankName];
    if (path != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(AppRadius.xs),
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text('🏦',
              style: TextStyle(fontSize: size * 0.8)),
        ),
      );
    }
    return Text('🏦',
        style: TextStyle(fontSize: size * 0.8));
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserService.getUserId();
    if (!mounted) return;
    setState(() => _userId = id);
    if (id != null) {
      CategoryService.getUserCategories(id)
          .listen((cats) {
        if (mounted) {
          setState(() => _customCategories = cats);
        }
      });
    }
  }

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

  // ← Confirm dialog trước khi xoá
  Future<void> _deleteTransaction(
      String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        title: const Text('Xoá giao dịch'),
        content: const Text(
          'Bạn có chắc muốn xoá giao dịch này không? '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(docId)
        .delete();
  }

  void _openAddTransaction(
      {String defaultType = 'expense'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(
        defaultType: defaultType,
      ),
    );
  }

  Map<String, String> _getCategoryInfo(
      String categoryId) {
    final defaultCat =
        AppCategories.findById(categoryId);
    if (defaultCat != null) {
      return {
        'name': defaultCat.name,
        'emoji':
            AppMascots.categoryIcons[categoryId] ??
                '💸',
      };
    }
    final customCat = _customCategories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    if (customCat != null) {
      return {
        'name': customCat.name,
        'emoji': customCat.emoji,
      };
    }
    return {'name': 'Khác', 'emoji': '💸'};
  }

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(
        _selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        return FutureBuilder<String?>(
          future: UserService.getUserId(),
          builder: (context, userSnapshot) {
            final userId =
                userSnapshot.data ?? _userId;
            if (userId == null) {
              return const SkyLoader(
                  message: 'Đang tải...');
            }
            if (_userId != userId) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _userId = userId);
                  _loadUserId();
                }
              });
            }
            return Column(
              children: [
                _buildMonthSelector(userId),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expenses')
                        .where('userId',
                            isEqualTo: userId)
                        .where('status',
                            isEqualTo: 'confirmed')
                        .where('date',
                            isGreaterThanOrEqualTo:
                                Timestamp.fromDate(
                                    firstDay))
                        .where('date',
                            isLessThanOrEqualTo:
                                Timestamp.fromDate(
                                    lastDay))
                        .orderBy('date',
                            descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SkyLoader(
                            message: 'Đang tải...');
                      }
                      final transactions =
                          snapshot.hasData
                              ? snapshot.data!.docs
                                  .map(TransactionModel
                                      .fromDoc)
                                  .toList()
                              : <TransactionModel>[];
                      final totalIncome = transactions
                          .where((t) => t.isIncome)
                          .fold(0.0,
                              (s, t) => s + t.amount);
                      final totalExpense = transactions
                          .where((t) => !t.isIncome)
                          .fold(0.0,
                              (s, t) => s + t.amount);
                      final Map<String,
                          List<TransactionModel>>
                          grouped = {};
                      for (final t in transactions) {
                        final key = t.date != null
                            ? '${t.date!.day}/${t.date!.month}/${t.date!.year}'
                            : 'Không rõ';
                        grouped
                            .putIfAbsent(key, () => [])
                            .add(t);
                      }
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SummaryCard(
                            totalIncome: totalIncome,
                            totalExpense: totalExpense,
                            month: _selectedMonth,
                            year: _selectedYear,
                          ),
                          const SizedBox(
                              height: AppSpacing.md),
                          _buildQuickActions(),
                          const SizedBox(
                              height: AppSpacing.md),
                          if (transactions.isEmpty)
                            _buildEmptyState()
                          else
                            Padding(
                              padding: const EdgeInsets
                                  .symmetric(
                                      horizontal:
                                          AppSpacing.md),
                              child: Column(
                                children: grouped.entries
                                    .map((e) =>
                                        _buildDateGroup(
                                            e.key,
                                            e.value))
                                    .toList(),
                              ),
                            ),
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMonthSelector(String userId) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md,
          AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
                Icons.chevron_left_rounded),
            color: AppColors.primary,
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
            icon: const Icon(
                Icons.chevron_right_rounded),
            color: AppColors.primary,
            onPressed: () => _changeMonth(1),
          ),
          StreamBuilder<int>(
            stream: CategoryService.getPendingCount(
                userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) {
                return const SizedBox(
                    width: AppSpacing.sm);
              }
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PendingScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(
                      right: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.gradientRose),
                    borderRadius:
                        BorderRadius.circular(
                            AppRadius.round),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔔',
                          style: TextStyle(
                              fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
                left: 4, bottom: AppSpacing.sm),
            child: Text(
              'Thao tác nhanh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  emoji: '💸',
                  label: 'Thêm\nchi tiêu',
                  gradient: AppColors.gradientRose,
                  onTap: () => _openAddTransaction(
                      defaultType: 'expense'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionButton(
                  emoji: '💰',
                  label: 'Thêm\nthu nhập',
                  gradient: AppColors.gradientMint,
                  onTap: () => _openAddTransaction(
                      defaultType: 'income'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionButton(
                  emoji: '🔔',
                  label: 'Chờ xác\nnhận',
                  gradient: AppColors.gradientSunset,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const PendingScreen()),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionButton(
                  emoji: '📈',
                  label: 'Thống\nkê',
                  gradient: AppColors.gradientSky,
                  onTap: () async {
                    final userId = _userId ??
                        await UserService.getUserId();
                    if (userId == null || !mounted) {
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StatsDetailScreen(
                          month: _selectedMonth,
                          year: _selectedYear,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji,
                style:
                    const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
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
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/mascots/fox.png',
                  width: 56,
                  height: 56,
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/mascots/cat.png',
                  width: 56,
                  height: 56,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Chưa có giao dịch',
                style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Nhấn nút bên dưới để thêm\ngiao dịch đầu tiên!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                _buildMiniAddButton(
                  '💸 Chi tiêu',
                  AppColors.expense,
                  () => _openAddTransaction(
                      defaultType: 'expense'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildMiniAddButton(
                  '💰 Thu nhập',
                  AppColors.income,
                  () => _openAddTransaction(
                      defaultType: 'income'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAddButton(
      String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius:
              BorderRadius.circular(AppRadius.round),
          border: Border.all(
              color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroup(String date,
      List<TransactionModel> transactions) {
    final dayTotal = transactions.fold<double>(
      0,
      (sum, t) =>
          t.isIncome ? sum + t.amount : sum - t.amount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.round),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                    height: 1,
                    color: AppColors.divider),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${dayTotal >= 0 ? '+' : ''}${_formatAmount(dayTotal)} đ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dayTotal >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
        ...transactions
            .map((t) => _buildTransactionItem(t)),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final info = _getCategoryInfo(t.categoryId);
    final category =
        AppCategories.findById(t.categoryId);
    final categoryColor =
        category?.color ?? AppColors.primary;

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      // ← Confirm trước khi xoá bằng swipe
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppRadius.xl),
            ),
            title: const Text('Xoá giao dịch'),
            content: const Text(
              'Bạn có chắc muốn xoá giao dịch này không?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                ),
                child: const Text('Xoá'),
              ),
            ],
          ),
        );
        return confirm == true;
      },
      onDismissed: (_) =>
          _deleteTransaction(t.id),
      background: Container(
        margin: const EdgeInsets.only(
            bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius:
              BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(
            right: AppSpacing.lg),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () =>
            _showTransactionOptions(t),
        child: Container(
          margin: const EdgeInsets.only(
              bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            leading: GestureDetector(
              onTap: () =>
                  _showChangeCategorySheet(t),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      categoryColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.md),
                  border: Border.all(
                    color:
                        categoryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(info['emoji']!,
                          style: const TextStyle(
                              fontSize: 22)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 1.5),
                        ),
                        child: const Icon(Icons.edit,
                            size: 8,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    t.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (t.isAuto && t.bankName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      Container(
                        width: 18,
                        height: 18,
                        padding:
                            const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: _buildBankLogo(
                            t.bankName!,
                            size: 14),
                      ),
                    ],
                  )
                else if (t.isAuto)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(
                              AppRadius.sm),
                    ),
                    child: const Text('Auto',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight:
                                FontWeight.w600)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(info['name']!,
                    style: AppTextStyles.caption),
                if (t.walletName != null &&
                    t.walletName!.isNotEmpty)
                  Text(
                    '👛 ${t.walletName}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '${t.isIncome ? '+' : '-'}${_formatAmount(t.amount)} đ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: t.isIncome
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(TransactionModel t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(
                    AppRadius.round),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.md),
                ),
                child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Chỉnh sửa',
                  style: TextStyle(
                      fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Sửa tên, số tiền, ngày...',
                  style: AppTextStyles.caption),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      TransactionForm(
                    defaultType: t.type,
                    editTransaction: t,
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.expense
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.md),
                ),
                child: Icon(Icons.delete_rounded,
                    color: AppColors.expense
                        .withOpacity(0.8)),
              ),
              title: const Text('Xoá giao dịch',
                  style: TextStyle(
                      fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Không thể hoàn tác',
                  style: AppTextStyles.caption),
              // ← Confirm trước khi xoá
              onTap: () {
                Navigator.pop(context);
                _deleteTransaction(t.id);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showChangeCategorySheet(TransactionModel t) {
    final defaultCats = t.isIncome
        ? AppCategories.income
        : AppCategories.expense;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                      AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                            AppRadius.md),
                  ),
                  child: const Text('🎯',
                      style:
                          TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Đổi danh mục',
                          style:
                              AppTextStyles.heading3),
                      Text(t.title,
                          style: AppTextStyles.caption,
                          overflow:
                              TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Danh mục mặc định',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children:
                          defaultCats.map((cat) {
                        final isSelected =
                            t.categoryId == cat.id;
                        final emoji = AppMascots
                                .categoryIcons[
                                    cat.id] ??
                            '💸';
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await FirebaseFirestore
                                .instance
                                .collection('expenses')
                                .doc(t.id)
                                .update({
                              'categoryId': cat.id
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Đổi sang ${cat.name}'),
                                backgroundColor:
                                    AppColors.income,
                              ));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets
                                .symmetric(
                              horizontal:
                                  AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color
                                      .withOpacity(0.15)
                                  : AppColors.background,
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.round),
                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Text(emoji),
                                const SizedBox(
                                    width: 4),
                                Text(cat.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? cat.color
                                          : AppColors
                                              .textPrimary,
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 13,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_customCategories
                        .isNotEmpty) ...[
                      const SizedBox(
                          height: AppSpacing.md),
                      const Text('Danh mục của tôi',
                          style:
                              AppTextStyles.bodySmall),
                      const SizedBox(
                          height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _customCategories
                            .map((cat) {
                          final isSelected =
                              t.categoryId == cat.id;
                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await FirebaseFirestore
                                  .instance
                                  .collection(
                                      'expenses')
                                  .doc(t.id)
                                  .update({
                                'categoryId': cat.id
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(
                                        context)
                                    .showSnackBar(
                                        SnackBar(
                                  content: Text(
                                      'Đổi sang ${cat.name}'),
                                  backgroundColor:
                                      AppColors.income,
                                ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                horizontal:
                                    AppSpacing.md,
                                vertical:
                                    AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors
                                        .primaryLight
                                    : AppColors
                                        .background,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            AppRadius
                                                .round),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors
                                          .transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Text(cat.emoji),
                                  const SizedBox(
                                      width: 4),
                                  Text(cat.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors
                                                .primary
                                            : AppColors
                                                .textPrimary,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(
                        height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) {
      return '${(abs / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(abs / 1000).toStringAsFixed(0)}K';
    }
    return abs.toStringAsFixed(0);
  }
}