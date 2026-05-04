import 'package:flutter/material.dart';
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showTestButton = true; // ← ẩn sau khi test xong

  final List<String> _titles = [
    'Chi Tiêu', 'Nhóm', 'Thống Kê', 'Hồ Sơ'
  ];

  @override
  void initState() {
    super.initState();
    _setupNotification();
  }

  Future<void> _setupNotification() async {
    await NotificationService.initialize();
    final hasPermission = await NotificationService.hasPermission();

    if (!hasPermission && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Cấp quyền đọc thông báo'),
          content: const Text(
            'App cần quyền đọc thông báo để tự động ghi nhận '
            'giao dịch từ ngân hàng và ví điện tử.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bỏ qua'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await NotificationService.openPermissionSettings();
              },
              child: const Text('Cấp quyền ngay'),
            ),
          ],
        ),
      );
    }
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const TransactionForm(),
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
          emoji: '🔍',
          title: 'Không tìm thấy',
          subtitle: 'Trang này không tồn tại',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // ← Nút test tạm thời — xóa sau khi test xong
          if (_showTestButton)
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onSelected: (value) async {
                if (value == 'test_log') {
                  await NotificationService.testNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã lưu test log → xem Firebase Console'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else if (value == 'test_full') {
                  await NotificationService.testFullFlow();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Test full flow → xem Firebase Console'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else if (value == 'hide') {
                  setState(() => _showTestButton = false);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'test_log',
                  child: Row(children: [
                    Icon(Icons.save, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Test lưu debug_log'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'test_full',
                  child: Row(children: [
                    Icon(Icons.play_arrow, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Test full flow (MoMo)'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'hide',
                  child: Row(children: [
                    Icon(Icons.visibility_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Ẩn nút test'),
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Chi tiêu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Nhóm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}