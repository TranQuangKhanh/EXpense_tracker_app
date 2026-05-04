import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../services/user_service.dart';
import '../../widgets/common/loading_button.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;
  String _selectedType = 'expense';
  String _selectedCategoryId = 'food';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _selectedCategoryId = type == 'expense' ? 'food' : 'salary';
    });
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      final userId = await UserService.getUserId() ?? '';
      final transaction = TransactionModel(
        id: '',
        title: _nameController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        date: null,
        userId: userId,
      );

      await FirebaseFirestore.instance
          .collection('expenses')
          .add(transaction.toMap());

      _nameController.clear();
      _amountController.clear();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == 'expense';
    final categories =
        isExpense ? AppCategories.expense : AppCategories.income;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thêm giao dịch', style: AppTextStyles.heading3),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Toggle Thu/Chi
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  _buildToggle('💸 Chi tiêu', 'expense', AppColors.expense),
                  _buildToggle('💰 Thu nhập', 'income', AppColors.income),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Category
            const Text('Danh mục', style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategoryId = cat.id),
                    child: Container(
                      width: 65,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon,
                              color: isSelected ? cat.color : Colors.grey,
                              size: 24),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? cat.color : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isExpense ? 'Tên khoản chi' : 'Tên khoản thu',
                prefixIcon: const Icon(Icons.edit_note),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập tên'
                      : null,
            ),

            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền (đ)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập số tiền'
                      : null,
            ),

            const SizedBox(height: AppSpacing.md),

            LoadingButton(
              label: isExpense ? 'Lưu Chi Tiêu' : 'Lưu Thu Nhập',
              isLoading: _isAdding,
              onPressed: _addTransaction,
              color: isExpense ? AppColors.expense : AppColors.income,
              icon: Icons.add,
            ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, String type, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}