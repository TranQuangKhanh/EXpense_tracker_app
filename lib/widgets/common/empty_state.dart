import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class EmptyState extends StatelessWidget {
  final String? emoji;        // ← optional
  final IconData? icon;       // ← hoặc dùng icon
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    this.emoji,               // ← không bắt buộc nữa
    this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiện emoji nếu có, icon nếu có,
            // không thì hiện icon mặc định
            if (emoji != null)
              Text(emoji!,
                  style: const TextStyle(fontSize: 64))
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.inbox_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null &&
                onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}