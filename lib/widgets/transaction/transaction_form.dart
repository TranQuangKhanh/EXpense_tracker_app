import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/custom_category_model.dart';
import '../../models/wallet_model.dart';
import '../../services/user_service.dart';
import '../../services/category_service.dart';
import '../../services/wallet_service.dart';
import '../../widgets/common/loading_button.dart';

class TransactionForm extends StatefulWidget {
  final String defaultType;
  final TransactionModel? editTransaction; // ← THÊM để edit
  const TransactionForm({
    super.key,
    this.defaultType = 'expense',
    this.editTransaction,
  });

  @override
  State<TransactionForm> createState() =>
      _TransactionFormState();
}

class _TransactionFormState
    extends State<TransactionForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;
  late String _selectedType;
  String _selectedCategoryId = 'food';
  String? _selectedWalletId;
  String? _userId;
  DateTime _selectedDate = DateTime.now(); // ← THÊM

  Stream<List<CustomCategoryModel>>? _categoryStream;
  Stream<List<WalletModel>>? _walletStream;

  bool get _isEditMode => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    _selectedCategoryId =
        _selectedType == 'expense' ? 'food' : 'salary';

    // Nếu đang edit → điền sẵn dữ liệu cũ
    if (_isEditMode) {
      final t = widget.editTransaction!;
      _nameController.text = t.title;
      _amountController.text =
          t.amount.toStringAsFixed(0);
      _noteController.text = t.note ?? '';
      _selectedType = t.type;
      _selectedCategoryId = t.categoryId;
      _selectedWalletId = t.walletId;
      _selectedDate = t.date ?? DateTime.now();
    }

    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await UserService.getUserId();
    if (!mounted) return;
    setState(() {
      _userId = userId;
      if (userId != null) {
        _categoryStream =
            CategoryService.getUserCategories(userId);
        _walletStream =
            WalletService.getUserWallets(userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _selectedCategoryId =
          type == 'expense' ? 'food' : 'salary';
    });
  }

  double? _parseAmount(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .toLowerCase();
    if (cleaned.endsWith('k')) {
      final val = double.tryParse(
          cleaned.replaceAll('k', ''));
      return val != null ? val * 1000 : null;
    }
    if (cleaned.endsWith('m')) {
      final val = double.tryParse(
          cleaned.replaceAll('m', ''));
      return val != null ? val * 1000000 : null;
    }
    return double.tryParse(cleaned);
  }

  // Chọn ngày
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày giao dịch',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // Giữ giờ phút hiện tại nếu chọn hôm nay
      final now = DateTime.now();
      final isToday = picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day;
      setState(() {
        _selectedDate = isToday
            ? now
            : DateTime(
                picked.year,
                picked.month,
                picked.day,
                12,
                0,
              );
      });
    }
  }

  Future<void> _saveTransaction(
      List<WalletModel> wallets) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Số tiền không hợp lệ')),
      );
      return;
    }
    setState(() => _isAdding = true);
    try {
      final userId =
          _userId ?? await UserService.getUserId() ?? '';
      String? walletName;
      if (_selectedWalletId != null) {
        walletName = wallets
            .where((w) => w.id == _selectedWalletId)
            .firstOrNull
            ?.name;
      }

      final data = TransactionModel(
        id: _isEditMode
            ? widget.editTransaction!.id
            : '',
        title: _nameController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        date: _selectedDate,
        userId: userId,
        walletId: _selectedWalletId,
        walletName: walletName,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ).toMap();

      if (_isEditMode) {
        // Cập nhật giao dịch cũ
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.editTransaction!.id)
            .update(data);

        // Nếu đổi ví → cập nhật số dư
        final oldT = widget.editTransaction!;
        if (oldT.walletId != null) {
          // Hoàn lại số dư cũ
          await WalletService.updateBalance(
            walletId: oldT.walletId!,
            amount: oldT.amount,
            isIncome: oldT.isIncome
                ? false
                : true, // reverse
          );
        }
        if (_selectedWalletId != null) {
          await WalletService.updateBalance(
            walletId: _selectedWalletId!,
            amount: amount,
            isIncome: _selectedType == 'income',
          );
        }
      } else {
        // Tạo mới
        await FirebaseFirestore.instance
            .collection('expenses')
            .add(data);
        if (_selectedWalletId != null) {
          await WalletService.updateBalance(
            walletId: _selectedWalletId!,
            amount: amount,
            isIncome: _selectedType == 'income',
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? '✅ Đã cập nhật giao dịch'
              : _selectedType == 'expense'
                  ? '✅ Đã thêm chi tiêu'
                  : '✅ Đã thêm thu nhập'),
          backgroundColor: _selectedType == 'expense'
              ? AppColors.expense
              : AppColors.income,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday =
        today.subtract(const Duration(days: 1));
    final dtDate =
        DateTime(dt.year, dt.month, dt.day);

    if (dtDate == today) return 'Hôm nay';
    if (dtDate == yesterday) return 'Hôm qua';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == 'expense';

    return StreamBuilder<List<WalletModel>>(
      stream: _walletStream,
      builder: (context, walletSnap) {
        final wallets = walletSnap.data ?? [];
        if (_selectedWalletId == null &&
            wallets.isNotEmpty &&
            !_isEditMode) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) {
              setState(() =>
                  _selectedWalletId = wallets.first.id);
            }
          });
        }

        return StreamBuilder<List<CustomCategoryModel>>(
          stream: _categoryStream,
          builder: (context, catSnap) {
            final customCats = catSnap.data ?? [];
            final defaultCats = isExpense
                ? AppCategories.expense
                : AppCategories.income;

            return DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 0.5,
              maxChildSize: 1.0,
              expand: false,
              builder: (context, scrollController) =>
                  Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isExpense
                                  ? AppColors.gradientRose
                                  : AppColors.gradientMint,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                                    AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              isExpense ? '💸' : '💰',
                              style: const TextStyle(
                                  fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: AppSpacing.sm),
                        Text(
                          _isEditMode
                              ? 'Chỉnh sửa giao dịch'
                              : isExpense
                                  ? 'Thêm chi tiêu'
                                  : 'Thêm thu nhập',
                          style: AppTextStyles.heading3,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                              Icons.close_rounded),
                          color: AppColors.textSecondary,
                          onPressed: () =>
                              Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: AppSpacing.md),

                    // ── Toggle (chỉ hiện khi tạo mới)──
                    if (!_isEditMode) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.xl),
                        ),
                        padding:
                            const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildToggle(
                                '💸 Chi tiêu',
                                'expense',
                                AppColors.expense),
                            _buildToggle(
                                '💰 Thu nhập',
                                'income',
                                AppColors.income),
                          ],
                        ),
                      ),
                      const SizedBox(
                          height: AppSpacing.md),
                    ],

                    // ── Chọn ngày ──
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets
                            .symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.lg),
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_today_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(
                                width: AppSpacing.sm),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons
                                  .chevron_right_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: AppSpacing.md),

                    // ── Category ──
                    const Text('Danh mục',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(
                        height: AppSpacing.sm),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...defaultCats.map((cat) {
                            final isSelected =
                                _selectedCategoryId ==
                                    cat.id;
                            final emoji = AppMascots
                                    .categoryIcons[
                                        cat.id] ??
                                '💸';
                            return GestureDetector(
                              onTap: () =>
                                  setState(() =>
                                      _selectedCategoryId =
                                          cat.id),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                width: 70,
                                margin: const EdgeInsets
                                    .only(
                                        right:
                                            AppSpacing
                                                .sm),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cat.color
                                          .withOpacity(
                                              0.15)
                                      : AppColors
                                          .background,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              AppRadius
                                                  .lg),
                                  border: Border.all(
                                    color: isSelected
                                        ? cat.color
                                        : Colors
                                            .transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Text(emoji,
                                        style: const TextStyle(
                                            fontSize:
                                                24)),
                                    const SizedBox(
                                        height: 4),
                                    Text(
                                      cat.name,
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? cat.color
                                            : AppColors
                                                .textSecondary,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight
                                                    .w700
                                                : FontWeight
                                                    .w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (customCats.isNotEmpty)
                            Container(
                              width: 1,
                              height: 60,
                              margin: const EdgeInsets
                                  .symmetric(
                                horizontal:
                                    AppSpacing.sm,
                                vertical: 15,
                              ),
                              color: AppColors.divider,
                            ),
                          ...customCats.map((cat) {
                            final isSelected =
                                _selectedCategoryId ==
                                    cat.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() =>
                                      _selectedCategoryId =
                                          cat.id),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                width: 70,
                                margin: const EdgeInsets
                                    .only(
                                        right:
                                            AppSpacing
                                                .sm),
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
                                                  .lg),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors
                                            .primary
                                        : Colors
                                            .transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Text(cat.emoji,
                                        style: const TextStyle(
                                            fontSize:
                                                24)),
                                    const SizedBox(
                                        height: 4),
                                    Text(
                                      cat.name,
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? AppColors
                                                .primary
                                            : AppColors
                                                .textSecondary,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight
                                                    .w700
                                                : FontWeight
                                                    .w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: AppSpacing.md),

                    // ── Nguồn tiền ──
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nguồn tiền',
                            style:
                                AppTextStyles.bodySmall),
                        if (wallets.isEmpty)
                          const Text(
                            '+ Thêm ví trong Hồ Sơ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                        height: AppSpacing.sm),

                    if (wallets.isEmpty)
                      Container(
                        padding: const EdgeInsets
                            .symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.lg),
                          border: Border.all(
                              color: AppColors.divider),
                        ),
                        child: const Row(
                          children: [
                            Text('👛',
                                style: TextStyle(
                                    fontSize: 16)),
                            SizedBox(
                                width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Chưa có ví — vào Hồ Sơ → Nguồn tiền để thêm',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () => _selectedWalletId =
                                      null),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                margin: const EdgeInsets
                                    .only(
                                        right:
                                            AppSpacing
                                                .sm),
                                padding: const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                      AppSpacing.md,
                                  vertical:
                                      AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedWalletId ==
                                          null
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
                                    color: _selectedWalletId ==
                                            null
                                        ? AppColors
                                            .primary
                                        : Colors
                                            .transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    const Text('💳',
                                        style: TextStyle(
                                            fontSize:
                                                16)),
                                    const SizedBox(
                                        width: 4),
                                    Text(
                                      'Không chọn',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color: _selectedWalletId ==
                                                null
                                            ? AppColors
                                                .primary
                                            : AppColors
                                                .textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...wallets.map((wallet) {
                              final isSelected =
                                  _selectedWalletId ==
                                      wallet.id;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedWalletId =
                                        wallet.id),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 150),
                                  margin: const EdgeInsets
                                      .only(
                                          right: AppSpacing
                                              .sm),
                                  padding: const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                        AppSpacing.md,
                                    vertical:
                                        AppSpacing.sm,
                                  ),
                                  decoration:
                                      BoxDecoration(
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
                                          ? AppColors
                                              .primary
                                          : Colors
                                              .transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(wallet.emoji,
                                          style: const TextStyle(
                                              fontSize:
                                                  18)),
                                      const SizedBox(
                                          width: 6),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            wallet.name,
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  12,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                              color: isSelected
                                                  ? AppColors
                                                      .primary
                                                  : AppColors
                                                      .textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _formatBalance(
                                                wallet
                                                    .balance),
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  10,
                                              color: isSelected
                                                  ? AppColors
                                                      .primary
                                                  : AppColors
                                                      .textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(
                        height: AppSpacing.md),

                    // ── Tên giao dịch ──
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isExpense
                            ? 'Tên khoản chi'
                            : 'Tên khoản thu',
                        prefixIcon: const Icon(
                            Icons.edit_note_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập tên'
                              : null,
                    ),

                    const SizedBox(
                        height: AppSpacing.sm),

                    // ── Số tiền ──
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền',
                        hintText:
                            'VD: 390, 1500, 50k, 1.5m',
                        prefixIcon: Icon(
                            Icons.attach_money_rounded),
                        helperText:
                            'Hỗ trợ: 390đ, 50k, 1.5m',
                        helperStyle: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      keyboardType: const TextInputType
                          .numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null ||
                            v.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        final amt = _parseAmount(v);
                        if (amt == null || amt <= 0) {
                          return 'Số tiền không hợp lệ';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(
                        height: AppSpacing.sm),

                    // ── Ghi chú ──
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tuỳ chọn)',
                        prefixIcon:
                            Icon(Icons.notes_rounded),
                        hintText: 'Thêm ghi chú...',
                      ),
                    ),

                    const SizedBox(
                        height: AppSpacing.lg),

                    // ── Button ──
                    LoadingButton(
                      label: _isEditMode
                          ? 'Cập nhật'
                          : isExpense
                              ? 'Lưu chi tiêu'
                              : 'Lưu thu nhập',
                      isLoading: _isAdding,
                      onPressed: () =>
                          _saveTransaction(wallets),
                      color: _isEditMode
                          ? AppColors.primary
                          : isExpense
                              ? AppColors.expense
                              : AppColors.income,
                      icon: _isEditMode
                          ? Icons.save_rounded
                          : Icons.check_rounded,
                    ),

                    SizedBox(
                      height: MediaQuery.of(context)
                              .viewInsets
                              .bottom +
                          AppSpacing.md,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M đ';
    }
    if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(0)}K đ';
    }
    return '${balance.toStringAsFixed(0)} đ';
  }

  Widget _buildToggle(
      String label, String type, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color:
                isSelected ? color : Colors.transparent,
            borderRadius:
                BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}