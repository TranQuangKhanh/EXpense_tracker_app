import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getCurrentUser();
    if (mounted) setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      UserService.clearCache();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text('Không tìm thấy thông tin'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Avatar + tên
        Center(
          child: Column(
            children: [
              Text(_user!.avatar,
                  style: const TextStyle(fontSize: 80)),
              const SizedBox(height: AppSpacing.sm),
              Text(_user!.displayName, style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xs),
              Text(_user!.phone, style: AppTextStyles.bodySmall),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Thông tin
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Mã ID'),
                trailing: Text(
                  '#${_user!.code}',
                  style: AppTextStyles.heading3,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Số điện thoại'),
                trailing: Text(_user!.phone),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Nút đăng xuất
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}