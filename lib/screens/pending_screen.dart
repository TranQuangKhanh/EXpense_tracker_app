import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/custom_category_model.dart';
import '../services/category_service.dart';
import '../services/user_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/sky_loader.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() =>
      _PendingScreenState();
}

class _PendingScreenState
    extends State<PendingScreen> {
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
      CategoryService.getUserCategories(userId)
          .listen((cats) {
        if (mounted) {
          setState(() => _customCategories = cats);
        }
      });
    }
  }

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
          content: Text('✅ Đã xác nhận giao dịch')),
    );
  }

  Future<void> _deleteTransaction(
      String docId) async {
    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(docId)
        .delete();
  }

  // Map bankName → asset path
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
      {double size = 32}) {
    final path = _bankLogos[bankName];
    if (path != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(AppRadius.sm),
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _buildBankFallback(bankName, size),
        ),
      );
    }
    return _buildBankFallback(bankName, size);
  }

  Widget _buildBankFallback(
      String bankName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius:
            BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(
        child: Text(
          bankName.isNotEmpty
              ? bankName[0].toUpperCase()
              : '🏦',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(
      TransactionModel transaction) {
    final defaultCats = transaction.isIncome
        ? AppCategories.income
        : AppCategories.expense;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
                  0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Text('🎯',
                  style: TextStyle(fontSize: 24)),
              SizedBox(width: AppSpacing.sm),
              Text('Chọn danh mục',
                  style: AppTextStyles.heading3),
            ]),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Danh mục mặc định',
                        style:
                            AppTextStyles.bodySmall),
                    const SizedBox(
                        height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children:
                          defaultCats.map((cat) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _confirmTransaction(
                                transaction.id,
                                cat.id);
                          },
                          child: Container(
                            padding: const EdgeInsets
                                .symmetric(
                              horizontal:
                                  AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: cat.color
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          AppRadius
                                              .round),
                              border: Border.all(
                                  color: cat.color
                                      .withOpacity(
                                          0.4)),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(cat.icon,
                                    color: cat.color,
                                    size: 16),
                                const SizedBox(
                                    width:
                                        AppSpacing.xs),
                                Text(cat.name,
                                    style: TextStyle(
                                      color: cat.color,
                                      fontWeight:
                                          FontWeight
                                              .w600,
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
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _confirmTransaction(
                                  transaction.id,
                                  cat.id);
                            },
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                horizontal:
                                    AppSpacing.md,
                                vertical:
                                    AppSpacing.sm,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: AppColors
                                    .primaryLight,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            AppRadius
                                                .round),
                                border: Border.all(
                                    color: AppColors
                                        .primary
                                        .withOpacity(
                                            0.4)),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Text(cat.emoji),
                                  const SizedBox(
                                      width: AppSpacing
                                          .xs),
                                  Text(cat.name,
                                      style:
                                          const TextStyle(
                                        color: AppColors
                                            .primary,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(
                        height: AppSpacing.md),
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
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
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
            Text('🔔',
                style: TextStyle(fontSize: 20)),
            SizedBox(width: AppSpacing.sm),
            Text('Chờ xác nhận'),
          ],
        ),
      ),
      body: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          return FutureBuilder<String?>(
            future: UserService.getUserId(),
            builder: (context, userSnap) {
              final userId =
                  userSnap.data ?? _userId;
              if (userId == null) {
                return const SkyLoader(
                    message: 'Đang tải...');
              }
              if (_userId != userId) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _userId = userId);
                    _loadData();
                  }
                });
              }
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('userId',
                        isEqualTo: userId)
                    .where('status',
                        isEqualTo: 'pending')
                    .orderBy('date',
                        descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SkyLoader(
                        message: 'Đang tải...');
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const EmptyState(
                      title:
                          'Không có giao dịch chờ',
                      subtitle:
                          'Tất cả giao dịch đã được xác nhận',
                    );
                  }
                  final transactions = snapshot
                      .data!.docs
                      .map(TransactionModel.fromDoc)
                      .toList();
                  final Map<String,
                      List<TransactionModel>> byBank =
                      {};
                  for (final t in transactions) {
                    final bank =
                        t.bankName ?? 'Khác';
                    byBank
                        .putIfAbsent(bank, () => [])
                        .add(t);
                  }
                  return ListView(
                    padding: const EdgeInsets.all(
                        AppSpacing.md),
                    children: byBank.entries
                        .map((entry) =>
                            _buildBankGroup(
                                entry.key,
                                entry.value))
                        .toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBankGroup(String bankName,
      List<TransactionModel> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bank — dùng logo thật
        Container(
          margin: const EdgeInsets.only(
              bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
                AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo ngân hàng
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: _buildBankLogo(bankName,
                    size: 28),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
                  '${transactions.length} giao dịch',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...transactions
            .map((t) => _buildPendingCard(t)),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildPendingCard(TransactionModel t) {
    final suggestedCat =
        AppCategories.findById(t.categoryId);
    final mascot =
        AppMascots.categoryIcons[t.categoryId] ??
            '💸';

    return Container(
      margin: const EdgeInsets.only(
          bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.isIncome
                        ? AppColors.incomeLight
                        : AppColors.expenseLight,
                    borderRadius:
                        BorderRadius.circular(
                            AppRadius.md),
                  ),
                  child: Center(
                    child: Text(mascot,
                        style: const TextStyle(
                            fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (suggestedCat != null)
                        Row(
                          children: [
                            const Text('Gợi ý: ',
                                style: AppTextStyles
                                    .caption),
                            Icon(suggestedCat.icon,
                                color:
                                    suggestedCat.color,
                                size: 12),
                            const SizedBox(width: 2),
                            Text(
                              suggestedCat.name,
                              style: TextStyle(
                                color:
                                    suggestedCat.color,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      // Hiển thị nguồn ngân hàng
                      if (t.bankName != null)
                        Row(
                          children: [
                            _buildBankLogo(
                                t.bankName!,
                                size: 14),
                            const SizedBox(width: 4),
                            Text(
                              t.bankName!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  '${t.isIncome ? '+' : '-'}${_formatAmount(t.amount)} đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: t.isIncome
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _confirmTransaction(
                            t.id, t.categoryId),
                    icon: const Icon(
                        Icons.check_rounded,
                        size: 16),
                    label: const Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showCategoryPicker(t),
                    icon: const Icon(
                        Icons.edit_rounded,
                        size: 16),
                    label: const Text('Đổi danh mục'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense
                        .withOpacity(0.6),
                  ),
                  onPressed: () =>
                      _deleteTransaction(t.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}