import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/user_service.dart';
import '../widgets/common/avatar_picker.dart';
import '../widgets/common/loading_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loginPhoneController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedAvatar = '🐱';
  bool _isLoading = false;
  bool _isLoginMode = false;
  bool _isLoginLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _loginPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPhone() async {
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập số điện thoại hợp lệ'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoginLoading = true);
    try {
      final error =
          await UserService.reloginWithPhone(phone);
      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Verify đã lưu userId
      final savedId = await UserService.getUserId();
      if (!mounted) return;
      if (savedId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Lỗi lưu phiên đăng nhập, thử lại'),
            backgroundColor: AppColors.expense,
          ),
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoginLoading = false);
      }
    }
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    setState(() => _isLoading = true);
    try {
      final user = await UserService.createUser(
        name: _nameController.text.trim(),
        phone: phone,
        avatar: _selectedAvatar,
      );
      if (!mounted) return;

      if (user == null) {
        // Kiểm tra xem có phải SĐT trùng không
        if (phone.isNotEmpty) {
          final exists =
              await UserService.isPhoneRegistered(
                  phone);
          if (!mounted) return;
          if (exists) {
            // Tự chuyển sang tab đăng nhập
            setState(() {
              _isLoginMode = true;
              _loginPhoneController.text = phone;
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  '📱 SĐT này đã đăng ký.\n'
                  'Đã chuyển sang Đăng nhập lại!',
                ),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra, thử lại')),
        );
        return;
      }

      // Tạo thành công
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppRadius.xl),
          ),
          title: const Text(
            'Tạo hồ sơ thành công! 🎉',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.avatar,
                  style:
                      const TextStyle(fontSize: 60)),
              const SizedBox(height: AppSpacing.md),
              Text(user.displayName,
                  style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(
                    AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.lg),
                ),
                child: Text(
                  user.phone.isNotEmpty
                      ? '📱 SĐT: ${user.phone}\n\n'
                          'Lưu lại để đăng nhập '
                          'trên thiết bị khác!'
                      : '💡 Bạn có thể thêm SĐT '
                          'sau trong Hồ sơ.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            LoadingButton(
              label: 'Bắt đầu sử dụng',
              isLoading: false,
              onPressed: () =>
                  Navigator.pop(context),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Toggle tạo mới / đăng nhập lại
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(
                          AppRadius.xl),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _isLoginMode =
                                false),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          padding: const EdgeInsets
                              .symmetric(
                                  vertical:
                                      AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: !_isLoginMode
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(
                                    AppRadius.lg),
                          ),
                          child: Text(
                            '✨ Tạo tài khoản',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 14,
                              color: !_isLoginMode
                                  ? Colors.white
                                  : AppColors
                                      .textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                            () =>
                                _isLoginMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          padding: const EdgeInsets
                              .symmetric(
                                  vertical:
                                      AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _isLoginMode
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(
                                    AppRadius.lg),
                          ),
                          child: Text(
                            '🔑 Đăng nhập lại',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 14,
                              color: _isLoginMode
                                  ? Colors.white
                                  : AppColors
                                      .textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              if (_isLoginMode)
                _buildLoginForm()
              else
                _buildRegisterForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đăng nhập lại 🔑',
            style: AppTextStyles.heading1),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Nhập số điện thoại đã đăng ký',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),

        Container(
          padding:
              const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withOpacity(0.08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('📱',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Mỗi SĐT liên kết với\n1 tài khoản duy nhất',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _loginPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'VD: 0935562066',
                  prefixIcon: const Icon(
                      Icons.phone_rounded),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            AppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(
                label: 'Đăng nhập',
                isLoading: _isLoginLoading,
                onPressed: _loginWithPhone,
                icon: Icons.login_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: () => setState(
                () => _isLoginMode = false),
            child: const Text(
              'Chưa có tài khoản? Tạo mới',
              style:
                  TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xin chào! 👋',
              style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tạo hồ sơ để bắt đầu quản lý chi tiêu',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Chọn avatar',
              style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          AvatarPicker(
            selectedAvatar: _selectedAvatar,
            onSelected: (avatar) => setState(
                () => _selectedAvatar = avatar),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị *',
              hintText: 'VD: AnhTu',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập tên';
              }
              if (v.trim().length < 2) {
                return 'Tên tối thiểu 2 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại (tuỳ chọn)',
              hintText: 'VD: 0935562066',
              prefixIcon: Icon(Icons.phone_rounded),
              helperText:
                  '💡 Dùng SĐT để đăng nhập lại & tính năng nhóm',
              helperStyle: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xl),

          LoadingButton(
            label: 'Bắt đầu',
            isLoading: _isLoading,
            onPressed: _createProfile,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}