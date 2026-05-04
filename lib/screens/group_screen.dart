import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_button.dart';
import 'group_detail_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '👨‍👩‍👧‍👦';
    final emojis = ['👨‍👩‍👧‍👦', '👫', '👬', '👭', '🏠', '💼', '🎮', '✈️'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tạo nhóm mới', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),

              // Chọn emoji
              const Text('Chọn biểu tượng', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: emojis.map((emoji) {
                  final isSelected = selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedEmoji = emoji),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhóm',
                  hintText: 'VD: Gia đình, Bạn bè...',
                  prefixIcon: Icon(Icons.group),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              LoadingButton(
                label: 'Tạo nhóm',
                isLoading: false,
                icon: Icons.add,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final group = await GroupService.createGroup(
                    name: nameController.text.trim(),
                    emoji: selectedEmoji,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (group != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: group),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm bạn bè'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '0901234567',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = await UserService.findUserByPhone(
                phoneController.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              if (user != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tìm thấy: ${user.displayName} ${user.avatar}',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không tìm thấy người dùng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: StreamBuilder<List<GroupModel>>(
        stream: GroupService.getUserGroups(_currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return EmptyState(
              emoji: '👥',
              title: 'Chưa có nhóm nào',
              subtitle: 'Tạo nhóm để quản lý chi tiêu cùng gia đình',
              buttonLabel: 'Tạo nhóm',
              onButtonPressed: _showCreateGroupDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: Text(
                    group.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  title: Text(group.name, style: AppTextStyles.heading3),
                  subtitle: Text(
                    '${group.memberIds.length} thành viên',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: group),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'search',
            onPressed: _showAddMemberDialog,
            backgroundColor: Colors.white,
            child: const Icon(Icons.search, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _showCreateGroupDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}