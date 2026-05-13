import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../widgets/transaction/transaction_list.dart';
import '../widgets/transaction/transaction_form.dart';
import '../widgets/common/empty_state.dart';
import 'stats_screen.dart';
import 'group_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _userId;

  final List<String> _titles = [
    'Chi Tiêu', 'Nhóm', 'Thống Kê', 'Hồ Sơ'
  ];
  final List<String> _emojis = [
    '💸', '👥', '📊', '🐾'
  ];
  final List<IconData> _icons = [
    Icons.wallet_rounded,
    Icons.people_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotification();
    _loadUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Check permission mỗi khi app resume
  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionSilently();
    }
  }

  Future<void> _checkPermissionSilently() async {
    final hasPermission =
        await NotificationService.hasPermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ Mất quyền đọc thông báo — nhấn để cấp lại'),
          backgroundColor: AppColors.expense,
          action: SnackBarAction(
            label: 'Cấp quyền',
            textColor: Colors.white,
            onPressed: () => NotificationService
                .openPermissionSettings(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadUserId() async {
    final id = await UserService.getUserId();
    if (mounted) setState(() => _userId = id);
  }

  Future<void> _setupNotification() async {
    await NotificationService.initialize();
    final hasPermission =
        await NotificationService.hasPermission();
    if (!hasPermission && mounted) {
      await Future.delayed(
          const Duration(seconds: 1));
      if (!mounted) return;
      _showSetupGuideDialog();
    }
  }

  // Dialog hướng dẫn setup lần đầu
  void _showSetupGuideDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        title: const Text(
          '⚙️ Cần thiết lập\nhoạt động nền',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Để tự động ghi nhận giao dịch '
              'ngân hàng, cần cấp đủ 3 quyền:',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStepTile(
              '1', '🔔',
              'Quyền đọc thông báo',
              'Bắt buộc để đọc thông báo ngân hàng',
              AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStepTile(
              '2', '🚀',
              'Tự khởi động (Auto Start)',
              'Quan trọng trên Xiaomi/Redmi/POCO',
              AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStepTile(
              '3', '🔋',
              'Không hạn chế pin',
              'Tránh bị kill khi màn hình tắt',
              AppColors.income,
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await NotificationService
                        .openPermissionSettings();
                    // Nhắc bước 2 sau 2 giây
                    await Future.delayed(
                        const Duration(seconds: 2));
                    if (mounted) {
                      _showAutoStartGuide();
                    }
                  },
                  icon: const Icon(
                      Icons.notifications_active),
                  label: const Text(
                      'Bước 1: Cấp quyền thông báo'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child: const Text('Để sau'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(
    String step,
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(emoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    )),
                Text(subtitle,
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoStartGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        title: const Text('🚀 Bật Auto Start',
            style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(
                    AppRadius.lg),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 Xiaomi / Redmi / POCO:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '1. Cài đặt\n'
                    '2. Ứng dụng → Quản lý ứng dụng\n'
                    '3. Tìm "Quản Lý Chi Tiêu"\n'
                    '4. Tự khởi động → BẬT ✅\n'
                    '5. Tiết kiệm pin → Không hạn chế ✅',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color:
                    AppColors.income.withOpacity(0.08),
                borderRadius: BorderRadius.circular(
                    AppRadius.lg),
              ),
              child: const Text(
                '💡 Sau khi bật xong, chuyển khoản thử '
                'để kiểm tra app có ghi nhận không.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService
                  .openBatteryOptimization();
            },
            icon: const Icon(Icons.battery_saver),
            label: const Text('Mở cài đặt pin'),
          ),
        ],
      ),
    );
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const TransactionList();
      case 1:
        return const GroupScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const EmptyState(
          title: 'Không tìm thấy',
          subtitle: 'Trang này không tồn tại',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton:
          _currentIndex == 0 ? _buildFAB() : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: AppColors.gradientSky),
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(_emojis[_currentIndex],
                  style:
                      const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(_titles[_currentIndex],
              style: AppTextStyles.heading3),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _openAddTransaction,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.gradientSky,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              final isSelected =
                  _currentIndex == index;
              if (index == 1) {
                return _buildGroupTabWithBadge(
                    isSelected);
              }
              return _buildNavItem(
                  index, isSelected, 0);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTabWithBadge(bool isSelected) {
    if (_userId == null) {
      return _buildNavItem(1, isSelected, 0);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: _userId)
          .snapshots(),
      builder: (context, groupSnap) {
        final groups = groupSnap.data?.docs ?? [];
        if (groups.isEmpty) {
          return _buildNavItem(1, isSelected, 0);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('group_read_status')
              .where('userId', isEqualTo: _userId)
              .snapshots(),
          builder: (context, readSnap) {
            final readMap = <String, DateTime>{};
            for (final doc
                in readSnap.data?.docs ?? []) {
              final data = doc.data()
                  as Map<String, dynamic>;
              final groupId =
                  data['groupId'] as String? ?? '';
              final lastReadAt =
                  (data['lastReadAt'] as Timestamp?)
                      ?.toDate();
              if (lastReadAt != null) {
                readMap[groupId] = lastReadAt;
              }
            }

            int groupsWithUnread = 0;
            for (final doc in groups) {
              final data = doc.data()
                  as Map<String, dynamic>;
              final lastMsgAt =
                  (data['lastMessageAt'] as Timestamp?)
                      ?.toDate();
              final lastSenderId =
                  data['lastMessageSenderId']
                      as String?;
              if (lastSenderId == _userId) continue;
              if (lastMsgAt != null) {
                final lastRead = readMap[doc.id];
                if (lastRead == null ||
                    lastMsgAt.isAfter(lastRead)) {
                  groupsWithUnread++;
                }
              }
            }

            return _buildNavItem(
                1, isSelected, groupsWithUnread);
          },
        );
      },
    );
  }

  Widget _buildNavItem(
      int index, bool isSelected, int badgeCount) {
    return GestureDetector(
      onTap: () =>
          setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected
              ? AppSpacing.md
              : AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _icons[index],
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.expense,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9
                            ? '9+'
                            : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                _titles[index],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}