import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/custom_category_model.dart';
import '../services/user_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../widgets/common/sky_loader.dart';
import 'onboarding_screen.dart';
import '../screens/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        title: const Text('Đăng xuất'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
                'Bạn có chắc muốn đăng xuất không?'),
            const SizedBox(height: AppSpacing.sm),
            if (_user?.phone.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.all(
                    AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Text('💡',
                        style:
                            TextStyle(fontSize: 14)),
                    const SizedBox(
                        width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Dùng SĐT ${_user!.phone} để đăng nhập lại',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
                backgroundColor: AppColors.expense),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '⭐';
    final emojis = [
      '⭐', '🎯', '🎨', '🎸', '🏋️', '🌿',
      '🐾', '💎', '🚀', '🎭', '🍜', '🎪',
      '🦋', '🌊', '🏔️', '🎃'
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
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('✨',
                    style: TextStyle(fontSize: 24)),
                SizedBox(width: AppSpacing.sm),
                Text('Tạo danh mục mới',
                    style: AppTextStyles.heading3),
              ]),
              const SizedBox(height: AppSpacing.lg),
              const Text('Chọn biểu tượng',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: emojis.map((emoji) {
                  final isSelected =
                      selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setModalState(
                        () => selectedEmoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.background,
                        borderRadius:
                            BorderRadius.circular(
                                AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(
                                fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'VD: Du lịch, Thú cưng...',
                  prefixText: '$selectedEmoji  ',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text
                        .trim()
                        .isEmpty) return;
                    await CategoryService
                        .createCategory(
                      name: nameController.text.trim(),
                      emoji: selectedEmoji,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            '✅ Đã tạo danh mục mới!'),
                      ),
                    );
                  },
                  child: const Text('Tạo danh mục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPhoneDialog() {
    final phoneController =
        TextEditingController(text: _user?.phone ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(children: const [
          Text('📱', style: TextStyle(fontSize: 24)),
          SizedBox(width: AppSpacing.sm),
          Text('Số điện thoại'),
        ]),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '0901234567',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone =
                  phoneController.text.trim();
              if (phone.length < 10) return;
              final error =
                  await UserService.updatePhone(phone);
              if (!mounted) return;
              Navigator.pop(context);
              if (error == null) {
                await _loadUser();
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                      content: Text(
                          '✅ Đã cập nhật SĐT!')),
                );
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ── Hướng dẫn hoạt động nền ──────────────────
  void _showBatteryGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.85,
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
          children: [
            Row(children: const [
              Text('⚡',
                  style: TextStyle(fontSize: 24)),
              SizedBox(width: AppSpacing.sm),
              Text('Tối ưu hoạt động nền',
                  style: AppTextStyles.heading3),
            ]),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Cần thiết để app tự động nhận thông báo ngân hàng',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGuideCard(
                      emoji: '📱',
                      brand:
                          'Xiaomi / Redmi / POCO (HyperOS/MIUI)',
                      steps: [
                        'Cài đặt → Ứng dụng → Quản lý ứng dụng',
                        'Tìm "Quản Lý Chi Tiêu"',
                        'Tự khởi động → BẬT ✅',
                        'Tiết kiệm pin → Không hạn chế ✅',
                        'Vào Quyền → Quyền truy cập thông báo → BẬT ✅',
                      ],
                      color: AppColors.expense,
                    ),
                    const SizedBox(
                        height: AppSpacing.sm),
                    _buildGuideCard(
                      emoji: '📲',
                      brand: 'Samsung (OneUI)',
                      steps: [
                        'Cài đặt → Bảo trì thiết bị → Pin',
                        'Ứng dụng ở chế độ ngủ',
                        'Xoá "Quản Lý Chi Tiêu" khỏi danh sách ngủ',
                      ],
                      color: AppColors.primary,
                    ),
                    const SizedBox(
                        height: AppSpacing.sm),
                    _buildGuideCard(
                      emoji: '🔋',
                      brand: 'Oppo / Vivo / Realme',
                      steps: [
                        'Cài đặt → Quản lý ứng dụng',
                        '"Quản Lý Chi Tiêu" → Tự chạy nền',
                        'Bật "Cho phép chạy nền" ✅',
                      ],
                      color: AppColors.income,
                    ),
                    const SizedBox(
                        height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await NotificationService
                              .openBatteryOptimization();
                        },
                        icon: const Icon(
                            Icons.battery_saver),
                        label: const Text(
                            'Mở cài đặt pin ngay'),
                      ),
                    ),
                    const SizedBox(
                        height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await NotificationService
                              .openPermissionSettings();
                        },
                        icon: const Icon(Icons
                            .notifications_active),
                        label: const Text(
                            'Cài đặt quyền thông báo'),
                      ),
                    ),
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

  Widget _buildGuideCard({
    required String emoji,
    required String brand,
    required List<String> steps,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(AppRadius.xl),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                brand,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SkyLoader();
    if (_user == null) {
      return const Center(
          child: Text('Không tìm thấy thông tin'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Header card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.gradientSky,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(AppRadius.xxl),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _user!.avatar,
                    style:
                        const TextStyle(fontSize: 44),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _user!.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_user!.phone.isNotEmpty)
                Text(
                  _user!.phone,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Info card ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppRadius.xl),
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
              _buildInfoTile(
                emoji: '🏷️',
                title: 'Mã ID',
                trailing: Text(
                  '#${_user!.code}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 64),
              _buildInfoTile(
                emoji: '📱',
                title: 'Số điện thoại',
                trailing: GestureDetector(
                  onTap: _showAddPhoneDialog,
                  child: Text(
                    _user!.phone.isNotEmpty
                        ? _user!.phone
                        : 'Thêm SĐT',
                    style: TextStyle(
                      color: _user!.phone.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Nguồn tiền + SĐT ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppRadius.xl),
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
                  child: const Center(
                    child: Text('👛',
                        style:
                            TextStyle(fontSize: 20)),
                  ),
                ),
                title: const Text('Nguồn tiền',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Quản lý ví & tài khoản',
                    style: AppTextStyles.caption),
                trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const WalletScreen()),
                ),
              ),
              if (_user!.phone.isEmpty) ...[
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.expenseLight,
                      borderRadius:
                          BorderRadius.circular(
                              AppRadius.md),
                    ),
                    child: const Center(
                      child: Text('📱',
                          style: TextStyle(
                              fontSize: 20)),
                    ),
                  ),
                  title: const Text(
                      'Thêm số điện thoại',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Cần có để đăng nhập lại & dùng nhóm',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.expense),
                  onTap: _showAddPhoneDialog,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Hoạt động nền ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withOpacity(0.06),
                blurRadius: 12,
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.expenseLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Text('⚡',
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            title: const Text('Hoạt động nền',
                style: TextStyle(
                    fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Thiết lập để nhận thông báo ngân hàng',
                style: AppTextStyles.caption),
            trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary),
            onTap: _showBatteryGuide,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Custom categories ──
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Row(children: const [
              Text('✨',
                  style: TextStyle(fontSize: 20)),
              SizedBox(width: AppSpacing.sm),
              Text('Danh mục của tôi',
                  style: AppTextStyles.heading3),
            ]),
            GestureDetector(
              onTap: _showAddCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.gradientSky),
                  borderRadius: BorderRadius.circular(
                      AppRadius.round),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Thêm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        StreamBuilder<List<CustomCategoryModel>>(
          stream: _user != null
              ? CategoryService.getUserCategories(
                  _user!.id)
              : const Stream.empty(),
          builder: (context, snapshot) {
            final cats = snapshot.data ?? [];
            if (cats.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(
                    AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                      AppRadius.xl),
                  border: Border.all(
                      color: AppColors.divider),
                ),
                child: Center(
                  child: Column(
                    children: const [
                      Text('🐇',
                          style: TextStyle(
                              fontSize: 36)),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Chưa có danh mục nào\nNhấn Thêm để tạo mới',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: cats.asMap().entries.map(
                  (entry) {
                    final idx = entry.key;
                    final cat = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.md),
                            ),
                            child: Center(
                              child: Text(cat.emoji,
                                  style: const TextStyle(
                                      fontSize: 20)),
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons
                                  .delete_outline_rounded,
                              color: Colors.grey.shade300,
                            ),
                            onPressed: () =>
                                CategoryService
                                    .deleteCategory(
                                        cat.id),
                          ),
                        ),
                        if (idx < cats.length - 1)
                          const Divider(
                              height: 1, indent: 64),
                      ],
                    );
                  },
                ).toList(),
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Logout ──
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.expense,
            side: BorderSide(
                color: AppColors.expense.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildInfoTile({
    required String emoji,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(title,
                  style: AppTextStyles.body)),
          trailing,
        ],
      ),
    );
  }
}