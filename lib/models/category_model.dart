import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class AppCategories {
  static const List<CategoryModel> expense = [
    CategoryModel(id: 'food', name: 'Ăn uống', icon: Icons.restaurant, color: Colors.orange, type: 'expense'),
    CategoryModel(id: 'transport', name: 'Di chuyển', icon: Icons.directions_car, color: Colors.blue, type: 'expense'),
    CategoryModel(id: 'shopping', name: 'Mua sắm', icon: Icons.shopping_bag, color: Colors.pink, type: 'expense'),
    CategoryModel(id: 'health', name: 'Sức khỏe', icon: Icons.favorite, color: Colors.red, type: 'expense'),
    CategoryModel(id: 'education', name: 'Học tập', icon: Icons.school, color: Colors.purple, type: 'expense'),
    CategoryModel(id: 'entertainment', name: 'Giải trí', icon: Icons.movie, color: Colors.teal, type: 'expense'),
    CategoryModel(id: 'bills', name: 'Hóa đơn', icon: Icons.receipt, color: Colors.brown, type: 'expense'),
    CategoryModel(id: 'other_expense', name: 'Khác', icon: Icons.more_horiz, color: Colors.grey, type: 'expense'),
  ];

  static const List<CategoryModel> income = [
    CategoryModel(id: 'salary', name: 'Lương', icon: Icons.work, color: Colors.green, type: 'income'),
    CategoryModel(id: 'freelance', name: 'Freelance', icon: Icons.laptop, color: Colors.cyan, type: 'income'),
    CategoryModel(id: 'bonus', name: 'Thưởng', icon: Icons.card_giftcard, color: Colors.amber, type: 'income'),
    CategoryModel(id: 'invest', name: 'Đầu tư', icon: Icons.trending_up, color: Colors.indigo, type: 'income'),
    CategoryModel(id: 'other_income', name: 'Khác', icon: Icons.more_horiz, color: Colors.grey, type: 'income'),
  ];

  static CategoryModel? findById(String id) {
    final all = [...expense, ...income];
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}