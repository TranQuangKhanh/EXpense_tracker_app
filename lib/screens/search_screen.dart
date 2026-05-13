import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/user_service.dart';
import '../widgets/common/sky_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _userId;
  List<TransactionModel> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserService.getUserId();
    if (mounted) setState(() => _userId = id);
  }

  Future<void> _search(String query) async {
    if (_userId == null || query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);

    final snap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('date', descending: true)
        .get();

    final q = query.toLowerCase();
    final results = snap.docs
        .map(TransactionModel.fromDoc)
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.amount.toString().contains(q) ||
            (AppCategories.findById(t.categoryId)
                    ?.name
                    .toLowerCase()
                    .contains(q) ??
                false))
        .toList();

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000)
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000)
      return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên, số tiền, danh mục...',
            border: InputBorder.none,
            filled: false,
            hintStyle: AppTextStyles.bodySmall,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _results = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() => _query = val);
            _search(val);
          },
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🔍', style: TextStyle(fontSize: 56)),
                  SizedBox(height: AppSpacing.md),
                  Text('Nhập từ khóa để tìm kiếm',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            )
          : _isSearching
              ? const SkyLoader(message: 'Đang tìm...')
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('😕',
                              style: TextStyle(fontSize: 56)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Không tìm thấy "$_query"',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(
                          AppSpacing.md),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final t = _results[i];
                        final cat =
                            AppCategories.findById(t.categoryId);
                        final emoji =
                            AppMascots.categoryIcons[
                                    t.categoryId] ??
                                '💸';
                        final dateStr = t.date != null
                            ? '${t.date!.day}/${t.date!.month}/${t.date!.year}'
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                                AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (cat?.color ?? Colors.grey)
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
                            title: Text(t.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(
                              '${cat?.name ?? 'Khác'} • $dateStr',
                              style: AppTextStyles.caption,
                            ),
                            trailing: Text(
                              '${t.isIncome ? '+' : '-'}${_formatAmount(t.amount)} đ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: t.isIncome
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}