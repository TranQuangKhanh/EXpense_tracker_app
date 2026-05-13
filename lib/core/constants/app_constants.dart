import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF29B6F6);
  static const primaryLight = Color(0xFFE1F5FE);
  static const primaryMedium = Color(0xFF81D4FA);
  static const primaryDark = Color(0xFF0288D1);
  static const primaryDeep = Color(0xFF01579B);
  static const accent = Color(0xFFFFD54F);
  static const accentPink = Color(0xFFFF8A9B);
  static const accentMint = Color(0xFF80DEEA);
  static const accentLavender = Color(0xFFCE93D8);
  static const accentPeach = Color(0xFFFFCC80);
  static const income = Color(0xFF26C6DA);
  static const incomeLight = Color(0xFFE0F7FA);
  static const expense = Color(0xFFFF7096);
  static const expenseLight = Color(0xFFFFE4EC);
  static const background = Color(0xFFF0F9FF);
  static const surface = Colors.white;
  static const cardBg = Color(0xFFFAFDFF);
  static const textPrimary = Color(0xFF1A2B3C);
  static const textSecondary = Color(0xFF7B9AB2);
  static const divider = Color(0xFFE3F2FD);
  static const gradientSky = [
    Color(0xFF29B6F6), Color(0xFF0288D1)];
  static const gradientMint = [
    Color(0xFF80DEEA), Color(0xFF26C6DA)];
  static const gradientSunset = [
    Color(0xFFFFD54F), Color(0xFFFFB74D)];
  static const gradientRose = [
    Color(0xFFFF8A9B), Color(0xFFFF7096)];
  static const gradientLavender = [
    Color(0xFFCE93D8), Color(0xFFAB47BC)];
}

class AppTextStyles {
  static const heading1 = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.5);
  static const heading2 = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3);
  static const heading3 = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);
  static const body = TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w400);
  static const bodySmall = TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400);
  static const caption = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400);
  static const amount = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5);
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
  static const xl = 24.0;
  static const xxl = 32.0;
  static const round = 100.0;
}

class AppMascots {
  static const tabIcons = ['💸', '🤝', '📊', '🐾'];

  static const categoryIcons = {
    'food': '🍜',
    'transport': '🚗',
    'shopping': '🛍️',
    'health': '💊',
    'education': '📚',
    'entertainment': '🎮',
    'bills': '📋',
    'salary': '💼',
    'bonus': '🎁',
    'freelance': '💻',
    'invest': '📈',
    'other_expense': '💸',
    'other_income': '💰',
  };
}

// ── Avatar — dùng cho hồ sơ người dùng ──────────
class AppAvatars {
  static const list = [
    // Động vật dễ thương
    '🦊', '🦌', '🐇', '🦉', '🐱',
    '🐕', '🐻', '🐼', '🐨', '🦋',
    '🐬', '🦄', '🐧', '🐸', '🐯',
    '🦁', '🐮', '🐷', '🐙', '🦀',
    '🐺', '🦝', '🦔', '🐿️', '🦦',
    '🦥', '🦜', '🦚', '🦩', '🐦',
    '🐣', '🐥', '🦆', '🐺', '🦊',
    // Nhân vật / biểu tượng
    '🧸', '🤖', '👾', '🎭', '🎪',
    '🌟', '⭐', '✨', '💫', '🌈',
    '🎯', '🏆', '💎', '🔮', '🎲',
  ];
}

// ── Emoji danh mục tự tạo ───────────────────────
class AppCategoryEmojis {
  static const list = [
    // Ẩm thực
    '🍜', '🍱', '🍣', '🍕', '🍔',
    '🌮', '🍦', '🧁', '☕', '🧃',
    // Di chuyển
    '🚗', '🏍️', '✈️', '🚂', '🛵',
    '🚲', '⛽', '🚕', '🛺', '🚌',
    // Mua sắm
    '🛒', '👗', '👟', '👜', '💄',
    '🛍️', '👒', '⌚', '💍', '🕶️',
    // Sức khoẻ
    '💊', '🏥', '🧘', '🏃', '🏋️',
    '🧬', '🩺', '💉', '🦷', '🩹',
    // Học tập
    '📚', '🎓', '✏️', '🖥️', '📐',
    '🔬', '🎨', '🎵', '📖', '🖊️',
    // Giải trí
    '🎮', '🎬', '🎤', '🎸', '🎯',
    '🏀', '⚽', '🎾', '🎳', '🎪',
    // Hoá đơn / tiện ích
    '⚡', '💧', '📱', '🌐', '📡',
    '🔌', '🏠', '🔑', '📦', '🗑️',
    // Thu nhập
    '💼', '💰', '📊', '🏦', '💳',
    '📈', '🤝', '🏅', '🎁', '💵',
    // Cuộc sống
    '🌿', '🌺', '🌊', '🏔️', '🌅',
    '🎃', '🎄', '🎆', '🌙', '☀️',
    // Gia đình / xã hội
    '👨‍👩‍👧', '👶', '🐾', '🏡', '🌻',
    '💝', '🎀', '🫂', '👫', '🤗',
    // Đặc biệt
    '🔮', '🧿', '🪄', '🎭', '🦋',
    '🌈', '⭐', '💫', '🎯', '🏆',
  ];
}

// ── Emoji nhóm chat ─────────────────────────────
class AppGroupEmojis {
  static const list = [
    // Gia đình / bạn bè
    '👨‍👩‍👧‍👦', '👫', '👬', '👭', '🫂',
    '👨‍👩‍👦', '👩‍👧‍👦', '🤝', '💑', '👩‍❤️‍👨',
    // Nhà / nơi chốn
    '🏠', '🏡', '🏢', '🏖️', '🏕️',
    '🏰', '🗼', '🌆', '🌇', '🌃',
    // Hoạt động nhóm
    '💼', '🎮', '✈️', '🎉', '🎊',
    '🏋️', '🏀', '⚽', '🎯', '🎪',
    // Chủ đề / mục tiêu
    '💰', '📊', '🎓', '🌿', '🍜',
    '🎵', '🎨', '📚', '🔬', '💡',
    // Biểu tượng đặc biệt
    '🦊', '🦌', '🐇', '🦉', '🌊',
    '🏔️', '🎯', '⭐', '🌈', '💎',
    '🚀', '🌟', '✨', '🔥', '💫',
    '🎭', '🎪', '🎲', '🃏', '🎸',
  ];
}