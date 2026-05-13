import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_button.dart';
import '../widgets/common/sky_loader.dart';
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
    final emojis = [
      '👨‍👩‍👧‍👦', '👫', '👬', '👭', '🏠', '💼',
      '🎮', '✈️', '🦊', '🦌', '🐇', '🦉',
      '🌊', '🏔️', '🎯', '⭐'
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
          bottom: MediaQuery.of(context).viewInsets.bottom +
              AppSpacing.md,
          top: AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('💬',
                    style: TextStyle(fontSize: 24)),
                SizedBox(width: AppSpacing.sm),
                Text('Tạo nhóm mới',
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
                  final isSelected = selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setModalState(
                        () => selectedEmoji = emoji),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.background,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style:
                                const TextStyle(fontSize: 24)),
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
                  prefixIcon: Icon(Icons.group_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(
                label: 'Tạo nhóm',
                isLoading: false,
                icon: Icons.add_rounded,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty)
                    return;
                  final group =
                      await GroupService.createGroup(
                    name: nameController.text.trim(),
                    emoji: selectedEmoji,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (group != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupDetailScreen(group: group),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const SkyLoader();
    }

    final userId = _currentUser!.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<GroupModel>>(
        stream: GroupService.getUserGroups(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const SkyLoader(
                message: 'Đang tải nhóm...');
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return EmptyState(
              title: 'Chưa có nhóm nào',
              subtitle:
                  'Tạo nhóm để chat và chia tiền cùng nhau',
              buttonLabel: 'Tạo nhóm',
              onButtonPressed: _showCreateGroupDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupItem(group, userId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: AppColors.gradientSky),
            borderRadius:
                BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGroupItem(GroupModel group, String userId) {
    return StreamBuilder<int>(
      stream: GroupService.getUnreadCount(group.id, userId),
      builder: (context, unreadSnap) {
        final unreadCount = unreadSnap.data ?? 0;
        final hasUnread = unreadCount > 0;

        return GestureDetector(
          onTap: () async {
            // Đánh dấu đã đọc khi mở nhóm
            await GroupService.markAsRead(group.id, userId);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GroupDetailScreen(group: group),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(
                bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: hasUnread
                  ? AppColors.primaryLight
                      .withOpacity(0.5)
                  : AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppRadius.xl),
              border: hasUnread
                  ? Border.all(
                      color:
                          AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Avatar nhóm
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientSky,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.lg),
                        ),
                        child: Center(
                          child: Text(group.emoji,
                              style: const TextStyle(
                                  fontSize: 26)),
                        ),
                      ),
                      // Chấm xanh unread
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9
                                    ? '9+'
                                    : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Nội dung
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Tên nhóm + thời gian
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatTime(
                                  group.lastMessageAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Tin nhắn cuối
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.lastMessage != null
                                    ? '${group.lastMessageSender?.split('#').first ?? ''}: ${group.lastMessage}'
                                    : '${group.memberIds.toSet().length} thành viên',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread
                                      ? AppColors.textPrimary
                                      : AppColors
                                          .textSecondary,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets
                                    .only(left: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}