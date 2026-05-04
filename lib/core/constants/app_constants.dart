import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const primary = Color(0xFF2196F3);
  static const primaryLight = Color(0xFFBBDEFB);
  static const primaryDark = Color(0xFF1565C0);

  // Income/Expense
  static const income = Color(0xFF4CAF50);
  static const incomeLight = Color(0xFFC8E6C9);
  static const expense = Color(0xFFF44336);
  static const expenseLight = Color(0xFFFFCDD2);

  // Neutral
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFEEEEEE);
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const amount = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
 static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const round = 100.0;
}

class AppAvatars {
  static const list = [
    '🐱', '🐶', '🐼', '🐨', '🦊',
    '🐸', '🐯', '🦁', '🐮', '🐷',
    '🐙', '🦋', '🐬', '🦄', '🐧',
  ];
}