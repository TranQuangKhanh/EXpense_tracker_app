import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/wallet_model.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';
import '../widgets/common/sky_loader.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() =>
      _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String? _userId;

  static const _presets = [
    {'logo': 'assets/banks/momo.png', 'name': 'MoMo'},
    {'logo': 'assets/banks/zalopay.png', 'name': 'ZaloPay'},
    {'logo': 'assets/banks/shopeepay.png', 'name': 'ShopeePay'},
    {'logo': 'assets/banks/vcb.png', 'name': 'Vietcombank'},
    {'logo': 'assets/banks/mbbank.png', 'name': 'MBBank'},
    {'logo': 'assets/banks/techcombank.png', 'name': 'Techcombank'},
    {'logo': 'assets/banks/bidv.png', 'name': 'BIDV'},
    {'logo': 'assets/banks/agribank.png', 'name': 'Agribank'},
    {'logo': 'assets/banks/tpbank.png', 'name': 'TPBank'},
    {'logo': 'assets/banks/vpbank.png', 'name': 'VPBank'},
    {'logo': 'assets/banks/acb.png', 'name': 'ACB'},
    {'logo': 'assets/banks/sacombank.png', 'name': 'Sacombank'},
    {'logo': 'assets/banks/vietinbank.png', 'name': 'Vietinbank'},
    {'logo': 'assets/banks/shb.png', 'name': 'SHB'},
    {'logo': 'assets/banks/vnpay.png', 'name': 'VNPay'},
    {'logo': 'assets/banks/grabpay.png', 'name': 'GrabPay'},
    {'logo': 'assets/banks/viettelpay.png', 'name': 'ViettelPay'},
  ];

  static const _bankLogos = {
    'MoMo': 'assets/banks/momo.png',
    'Vietcombank': 'assets/banks/vcb.png',
    'MBBank': 'assets/banks/mbbank.png',
    'Techcombank': 'assets/banks/techcombank.png',
    'BIDV': 'assets/banks/bidv.png',
    'Agribank': 'assets/banks/agribank.png',
    'TPBank': 'assets/banks/tpbank.png',
    'VPBank': 'assets/banks/vpbank.png',
    'ACB': 'assets/banks/acb.png',
    'Sacombank': 'assets/banks/sacombank.png',
    'Vietinbank': 'assets/banks/vietinbank.png',
    'SHB': 'assets/banks/shb.png',
    'ZaloPay': 'assets/banks/zalopay.png',
    'ShopeePay': 'assets/banks/shopeepay.png',
    'VNPay': 'assets/banks/vnpay.png',
    'GrabPay': 'assets/banks/grabpay.png',
    'ViettelPay': 'assets/banks/viettelpay.png',
    'ViettelMoney': 'assets/banks/viettelpay.png',
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = await UserService.getUserId();
    if (mounted) setState(() => _userId = id);
  }

  Widget _buildLogo(String? logoPath,
      {double size = 32}) {
    if (logoPath != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(AppRadius.sm),
        child: Image.asset(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.6,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Icon(
      Icons.account_balance_wallet_rounded,
      size: size * 0.6,
      color: AppColors.primary,
    );
  }

  String? _getLogoForWallet(WalletModel wallet) {
    return _bankLogos[wallet.name];
  }

  void _showAddWalletSheet() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedName = '';
    String? selectedLogo;

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
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 24),
                SizedBox(width: AppSpacing.sm),
                Text('Thêm nguồn tiền',
                    style: AppTextStyles.heading3),
              ]),
              const SizedBox(height: AppSpacing.md),

              const Text('Chọn nhanh',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final isSelected =
                        selectedName == preset['name'];
                    return GestureDetector(
                      onTap: () {
                        setModal(() {
                          selectedName =
                              preset['name']!;
                          selectedLogo =
                              preset['logo']!;
                          nameController.text =
                              preset['name']!;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 150),
                        margin: const EdgeInsets.only(
                            right: AppSpacing.sm),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.background,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.lg),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding:
                                  const EdgeInsets.all(
                                      4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            AppRadius
                                                .sm),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(
                                            0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: _buildLogo(
                                  preset['logo'],
                                  size: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preset['name']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors
                                        .textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              const Text('Hoặc tự đặt tên',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên ví',
                  prefixIcon: selectedLogo != null
                      ? Padding(
                          padding:
                              const EdgeInsets.all(10),
                          child: _buildLogo(
                              selectedLogo,
                              size: 24),
                        )
                      : const Icon(Icons
                          .account_balance_wallet_rounded),
                ),
                onChanged: (val) => setModal(() {
                  if (val != selectedName) {
                    selectedLogo = null;
                    selectedName = '';
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: balanceController,
                keyboardType: const TextInputType
                    .numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Số dư hiện tại (đ)',
                  hintText: 'VD: 500000',
                  prefixIcon:
                      Icon(Icons.account_balance_wallet),
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
                    final balance = double.tryParse(
                            balanceController.text
                                .trim()) ??
                        0;
                    await WalletService.createWallet(
                      name: nameController.text.trim(),
                      emoji: '',
                      initialBalance: balance,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content:
                            Text('Đã thêm nguồn tiền'),
                      ),
                    );
                  },
                  child: const Text('Thêm nguồn tiền'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M đ';
    }
    if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(0)}K đ';
    }
    return '${balance.toStringAsFixed(0)} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Nguồn tiền'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 20),
            ),
            onPressed: _showAddWalletSheet,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _userId == null
          ? const SkyLoader()
          : StreamBuilder<List<WalletModel>>(
              stream: WalletService.getUserWallets(
                  _userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SkyLoader(
                      message: 'Đang tải...');
                }

                final wallets = snapshot.data ?? [];
                final totalBalance = wallets.fold(
                    0.0, (sum, w) => sum + w.balance);

                if (wallets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .account_balance_wallet_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(
                            height: AppSpacing.md),
                        const Text(
                            'Chưa có nguồn tiền nào',
                            style:
                                AppTextStyles.heading3),
                        const SizedBox(
                            height: AppSpacing.xs),
                        const Text(
                          'Thêm ví để theo dõi\ntừng nguồn tiền riêng biệt',
                          textAlign: TextAlign.center,
                          style:
                              AppTextStyles.bodySmall,
                        ),
                        const SizedBox(
                            height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed:
                              _showAddWalletSheet,
                          icon: const Icon(
                              Icons.add_rounded),
                          label: const Text(
                              'Thêm nguồn tiền'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(
                      AppSpacing.md),
                  children: [
                    // Tổng số dư
                    Container(
                      padding: const EdgeInsets.all(
                          AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors:
                                AppColors.gradientSky),
                        borderRadius:
                            BorderRadius.circular(
                                AppRadius.xxl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Tổng số dư',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            _formatBalance(totalBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                              height: AppSpacing.sm),
                          Text(
                            '${wallets.length} nguồn tiền',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: AppSpacing.lg),

                    // Danh sách ví
                    ...wallets.map((wallet) {
                      final logoPath =
                          _getLogoForWallet(wallet);
                      final ratio = totalBalance > 0
                          ? (wallet.balance /
                                  totalBalance)
                              .clamp(0.0, 1.0)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(
                            AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(
                                  AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.06),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding:
                                      const EdgeInsets
                                          .all(8),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                AppRadius
                                                    .md),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .black
                                            .withOpacity(
                                                0.08),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: logoPath != null
                                      ? _buildLogo(
                                          logoPath,
                                          size: 36)
                                      : Center(
                                          child: Text(
                                            wallet.name
                                                    .isNotEmpty
                                                ? wallet
                                                    .name[0]
                                                    .toUpperCase()
                                                : 'W',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  22,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              color: AppColors
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(
                                    width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        wallet.name,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${(ratio * 100).toStringAsFixed(0)}% tổng số dư',
                                        style:
                                            AppTextStyles
                                                .caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .end,
                                  children: [
                                    Text(
                                      _formatBalance(
                                          wallet.balance),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        fontSize: 16,
                                        color: AppColors
                                            .primary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons
                                            .delete_outline_rounded,
                                        color: Colors
                                            .grey.shade300,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () async {
                                        await WalletService
                                            .deleteWallet(
                                                wallet.id);
                                        if (!mounted)
                                          return;
                                        ScaffoldMessenger
                                                .of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Đã xoá ví'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: AppSpacing.sm),
                            // ← FIX: AlwaysStoppedAnimation<Color>
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.round),
                              child:
                                  LinearProgressIndicator(
                                value: ratio,
                                backgroundColor:
                                    AppColors.primaryLight,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}