import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AvatarPicker extends StatelessWidget {
  final String selectedAvatar;
  final Function(String) onSelected;

  const AvatarPicker({
    super.key,
    required this.selectedAvatar,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: AppAvatars.list.map((avatar) {
        final isSelected = selectedAvatar == avatar;
        return GestureDetector(
          onTap: () => onSelected(avatar),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryLight
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}