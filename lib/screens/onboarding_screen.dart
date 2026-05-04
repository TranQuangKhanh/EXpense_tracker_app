import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/user_service.dart';
import '../widgets/common/avatar_picker.dart';
import '../widgets/common/loading_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedAvatar = '🐱';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await UserService.createUser(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: _selectedAvatar,
      );

      if (!mounted) return;

      if (user != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: const Text(
              'Tạo hồ sơ thành công! 🎉',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.avatar,
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.displayName,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Đây là tên hiển thị của bạn.\nNgười khác có thể tìm bạn qua tên này.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            actions: [
              LoadingButton(
                label: 'Bắt đầu sử dụng',
                isLoading: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra, vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),

                // Header
                const Text('Xin chào! 👋', style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tạo hồ sơ để bắt đầu quản lý chi tiêu',
                  style: AppTextStyles.bodySmall,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Avatar picker
                const Text('Chọn avatar', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                AvatarPicker(
                  selectedAvatar: _selectedAvatar,
                  onSelected: (avatar) =>
                      setState(() => _selectedAvatar = avatar),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tên hiển thị
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    hintText: 'VD: AnhTu',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    if (value.trim().length < 2) {
                      return 'Tên tối thiểu 2 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Số điện thoại
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'VD: 0901234567',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (value.trim().length < 10) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Nút tạo hồ sơ
                LoadingButton(
                  label: 'Bắt đầu',
                  isLoading: _isLoading,
                  onPressed: _createProfile,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}