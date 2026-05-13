import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../widgets/group/note_card.dart';
import '../widgets/common/sky_loader.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() =>
      _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _noteController = TextEditingController();
  String? _currentUserId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
  final user = await UserService.getCurrentUser();
  if (mounted) {
    setState(() {
      _currentUserId = user?.id;
      _currentUser = user;
    });
  }
  // Đánh dấu đã đọc khi vào nhóm
  if (user != null) {
    await GroupService.markAsRead(widget.group.id, user.id);
  }
}

Future<void> _sendNote() async {
  if (_noteController.text.trim().isEmpty) return;
  await GroupService.addNote(
    groupId: widget.group.id,
    content: _noteController.text.trim(),
  );
  _noteController.clear();
  // addNote đã tự markAsRead trong GroupService
}

  // Load danh sách thành viên — dùng Set tránh duplicate
  Future<List<UserModel>> _loadMembers() async {
    final members = <UserModel>[];
    final uniqueIds = widget.group.memberIds.toSet();
    for (final id in uniqueIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (doc.exists) {
          members.add(UserModel.fromDoc(doc));
        }
      } catch (_) {}
    }
    return members;
  }

  // Sheet xem danh sách thành viên
  void _showMemberListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Text('👥',
                      style: TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${widget.group.memberIds.toSet().length} thành viên',
                    style: AppTextStyles.heading3,
                  ),
                ]),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _loadMembers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final members = snapshot.data!;
                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final member = members[i];
                      final isMe =
                          member.id == _currentUserId;
                      final isCreator = member.id ==
                          widget.group.createdBy;
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(member.avatar,
                                style: const TextStyle(
                                    fontSize: 24)),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.displayName,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600),
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors
                                      .primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppRadius.round),
                                ),
                                child: const Text('Bạn',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          AppColors.primary,
                                      fontWeight:
                                          FontWeight.w700,
                                    )),
                              ),
                            ],
                            if (isCreator) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppRadius.round),
                                ),
                                child: const Text(
                                    '👑 Trưởng nhóm',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.accent,
                                      fontWeight:
                                          FontWeight.w700,
                                    )),
                              ),
                            ],
                          ],
                        ),
                        subtitle: member.phone.isNotEmpty
                            ? Text(member.phone,
                                style: AppTextStyles.caption)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tìm user bằng SĐT hoặc tên#code
  Future<UserModel?> _findUser(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.contains('#')) {
      return UserService.findUserByNameCode(cleaned);
    }
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return UserService.findUserByPhone(cleaned);
    }
    return null;
  }

  void _showAddMemberDialog() {
    final searchController = TextEditingController();
    UserModel? foundUser;
    bool isSearching = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: Row(
            children: const [
              Text('👥', style: TextStyle(fontSize: 24)),
              SizedBox(width: AppSpacing.sm),
              Text('Thêm thành viên'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'SĐT hoặc Tên#Code',
                  hintText:
                      'VD: 0901234567 hoặc AnhTu#1234',
                  prefixIcon:
                      const Icon(Icons.search_rounded),
                  errorText: errorMsg,
                  suffixIcon: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child:
                                CircularProgressIndicator(
                                    strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (val) async {
                  if (val.trim().length < 6) {
                    setDialog(() {
                      foundUser = null;
                      errorMsg = null;
                    });
                    return;
                  }
                  setDialog(() {
                    isSearching = true;
                    errorMsg = null;
                  });
                  final user = await _findUser(val);
                  setDialog(() {
                    foundUser = user;
                    isSearching = false;
                    errorMsg = user == null
                        ? 'Không tìm thấy người dùng'
                        : null;
                  });
                },
              ),
              if (foundUser != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Text(foundUser!.avatar,
                          style:
                              const TextStyle(fontSize: 32)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundUser!.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (foundUser!.phone.isNotEmpty)
                              Text(foundUser!.phone,
                                  style:
                                      AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.income),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: foundUser == null
                  ? null
                  : () async {
                      // Dùng Set để check duplicate chính xác
                      final currentIds = widget
                          .group.memberIds
                          .toSet();
                      if (currentIds
                          .contains(foundUser!.id)) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                                '${foundUser!.displayName} đã là thành viên'),
                          ),
                        );
                        return;
                      }
                      final success =
                          await GroupService.addMember(
                              widget.group.id,
                              foundUser!.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? '✅ Đã thêm ${foundUser!.displayName}'
                              : '❌ Có lỗi xảy ra'),
                          backgroundColor: success
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      );
                    },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  // Sheet chia tiền nhóm
  void _showExpensePostSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl)),
          ),
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                    AppSpacing.md,
            top: AppSpacing.lg,
            left: AppSpacing.md,
            right: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('💰', style: TextStyle(fontSize: 24)),
                SizedBox(width: AppSpacing.sm),
                Text('Chia tiền nhóm',
                    style: AppTextStyles.heading3),
              ]),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText:
                      'VD: Tiền ăn tối, Tiền xăng...',
                  prefixIcon: Icon(Icons.receipt_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tổng số tiền (đ)',
                  prefixIcon:
                      Icon(Icons.attach_money_rounded),
                ),
                onChanged: (_) => setModal(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'VD: Mọi người ck lại nhé!',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Preview chia đều
              Builder(builder: (context) {
                final memberCount = widget
                    .group.memberIds
                    .toSet()
                    .length;
                final amount = double.tryParse(
                        amountController.text) ??
                    0;
                final perPerson = memberCount > 1
                    ? amount / memberCount
                    : amount;
                return Container(
                  padding:
                      const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Text('ℹ️',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$memberCount người • Mỗi người: ${_formatAmount(perPerson)} đ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleController.text
                            .trim()
                            .isEmpty ||
                        _currentUser == null) return;
                    final amount = double.tryParse(
                            amountController.text
                                .trim()) ??
                        0;
                    final memberCount = widget
                        .group.memberIds
                        .toSet()
                        .length;

                    await FirebaseFirestore.instance
                        .collection('notes')
                        .add({
                      'groupId': widget.group.id,
                      'createdBy': _currentUser!.id,
                      'creatorName':
                          _currentUser!.displayName,
                      'creatorAvatar': _currentUser!.avatar,
                      'type': 'expense_post',
                      'content':
                          titleController.text.trim(),
                      'amount': amount,
                      'splitAmount': memberCount > 1
                          ? amount / memberCount
                          : amount,
                      'memberCount': memberCount,
                      'note': noteController.text.trim(),
                      'paidBack': [],
                      'createdAt':
                          FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Chia tiền'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.gradientSky),
                borderRadius:
                    BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(widget.group.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.group.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            color: AppColors.primary,
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Member bar — tap để xem thành viên ──
          GestureDetector(
            onTap: _showMemberListSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  const Text('👥',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${widget.group.memberIds.toSet().length} thành viên',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const Spacer(),
                  // Nút chia tiền
                  GestureDetector(
                    onTap: _showExpensePostSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.gradientMint),
                        borderRadius:
                            BorderRadius.circular(
                                AppRadius.round),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('💰',
                              style:
                                  TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'Chia tiền',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Chat list ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('groupId',
                      isEqualTo: widget.group.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SkyLoader(
                      message: 'Đang tải...');
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('💬',
                            style:
                                TextStyle(fontSize: 56)),
                        SizedBox(height: AppSpacing.md),
                        Text('Chưa có tin nhắn nào',
                            style:
                                AppTextStyles.heading3),
                        Text(
                            'Hãy gửi tin nhắn đầu tiên!',
                            style:
                                AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()
                        as Map<String, dynamic>;
                    final type =
                        data['type'] as String? ?? 'text';
                    final isMe = data['createdBy'] ==
                        _currentUserId;

                    if (type == 'expense_post') {
                      return _buildExpensePost(doc, isMe);
                    }

                    // Text hoặc payment_confirm
                    final note = NoteModel.fromDoc(doc);
                    return NoteCard(
                        note: note, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // ── Input ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
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
                            BorderRadius.circular(
                                AppRadius.round),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.primaryLight,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    onSubmitted: (_) => _sendNote(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: AppColors.gradientSky),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white),
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

  // ── Expense post card ──
  Widget _buildExpensePost(
      QueryDocumentSnapshot doc, bool isMe) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['content'] as String? ?? '';
    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0;
    final splitAmount =
        (data['splitAmount'] as num?)?.toDouble() ?? 0;
    final memberCount =
        data['memberCount'] as int? ?? 1;
    final note = data['note'] as String? ?? '';
    final creatorName =
        data['creatorName'] as String? ?? '';
    final creatorAvatar =
        data['creatorAvatar'] as String? ?? '🐱';
    final paidBack =
        List<String>.from(data['paidBack'] ?? []);
    final hasIPaidBack = _currentUserId != null &&
        paidBack.contains(_currentUserId);

    return Container(
      margin:
          const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.income.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.income.withOpacity(0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.income.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                Text(creatorAvatar,
                    style:
                        const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$creatorName đã chia tiền',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(title,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.income.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                        AppRadius.round),
                  ),
                  child: const Text(
                    '💰 Chia tiền',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.income,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Số tiền tổng / mỗi người
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng tiền',
                            style: AppTextStyles.caption),
                        Text(
                          '${_formatAmount(amount)} đ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        const Text('Mỗi người',
                            style: AppTextStyles.caption),
                        Text(
                          '${_formatAmount(splitAmount)} đ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Ghi chú
                if (note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                          AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Text('📝',
                            style:
                                TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(note,
                              style:
                                  AppTextStyles.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),

                // Progress ai đã ck lại
                Row(
                  children: [
                    Text(
                      '${paidBack.length}/$memberCount đã ck lại',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                                AppRadius.round),
                        child: LinearProgressIndicator(
                          value: memberCount > 0
                              ? paidBack.length /
                                  memberCount
                              : 0,
                          backgroundColor:
                              AppColors.primaryLight,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  AppColors.income),
                          minHeight: 5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Nút ck lại — chỉ hiện với người không phải creator
                if (!isMe)
                  SizedBox(
                    width: double.infinity,
                    child: hasIPaidBack
                        ? Container(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.income
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.lg),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: AppColors.income,
                                    size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Đã ck lại',
                                  style: TextStyle(
                                    color: AppColors.income,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              if (_currentUserId == null)
                                return;
                              await doc.reference.update({
                                'paidBack':
                                    FieldValue.arrayUnion(
                                        [_currentUserId]),
                              });
                              // Gửi tin nhắn xác nhận vào chat
                              await FirebaseFirestore
                                  .instance
                                  .collection('notes')
                                  .add({
                                'groupId': widget.group.id,
                                'createdBy': _currentUserId,
                                'creatorName': _currentUser
                                        ?.displayName ??
                                    '',
                                'creatorAvatar':
                                    _currentUser?.avatar ??
                                        '🐱',
                                'type': 'payment_confirm',
                                'content':
                                    '✅ Đã ck lại ${_formatAmount(splitAmount)} đ cho "$title"',
                                'createdAt': FieldValue
                                    .serverTimestamp(),
                              });
                            },
                            icon: const Icon(
                                Icons.check_rounded,
                                size: 16),
                            label:
                                const Text('Đã ck lại'),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.income,
                            ),
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