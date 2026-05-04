import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/note_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../widgets/group/note_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _noteController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserService.getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  Future<void> _sendNote() async {
    if (_noteController.text.trim().isEmpty) return;
    await GroupService.addNote(
      groupId: widget.group.id,
      content: _noteController.text.trim(),
    );
    _noteController.clear();
  }

  void _showAddMemberDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '0901234567',
            prefixIcon: Icon(Icons.phone),
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

              if (user != null) {
                // Kiểm tra đã là thành viên chưa
                if (widget.group.memberIds.contains(user.id)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${user.displayName} đã là thành viên rồi',
                      ),
                    ),
                  );
                  return;
                }

                // Thêm vào nhóm
                final success = await GroupService.addMember(
                  widget.group.id,
                  user.id,
                );
                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã thêm ${user.displayName} ${user.avatar}'
                          : 'Có lỗi xảy ra',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không tìm thấy người dùng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.group.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.group.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Thêm thành viên',
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Danh sách note
          Expanded(
            child: StreamBuilder<List<NoteModel>>(
              stream: GroupService.getGroupNotes(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào\nHãy gửi tin nhắn đầu tiên!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  );
                }

                final notes = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isMe = note.createdBy == _currentUserId;
                    return NoteCard(note: note, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input gửi note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Nhắn tin...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.round),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    onSubmitted: (_) => _sendNote(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendNote,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}