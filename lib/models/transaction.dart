import 'package:flutter/material.dart';

import 'category_item.dart';
export 'category_item.dart';

enum TransactionType { expense, income }

class TransactionCategories {
  static const List<CategoryItem> expenseCategories = [
    CategoryItem(
      name: 'Spesa e Cibo',
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFFF59E0B),
    ),
    CategoryItem(
      name: 'Ristoranti & Bar',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEF4444),
    ),
    CategoryItem(
      name: 'Trasporti & Auto',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6),
    ),
    CategoryItem(
      name: 'Casa & Bollette',
      icon: Icons.home_rounded,
      color: Color(0xFF8B5CF6),
    ),
    CategoryItem(
      name: 'Svago & Tempo Libero',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFEC4899),
    ),
    CategoryItem(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF10B981),
    ),
    CategoryItem(
      name: 'Salute & Cura',
      icon: Icons.healing_rounded,
      color: Color(0xFF14B8A6),
    ),
    CategoryItem(
      name: 'Altro',
      icon: Icons.category_rounded,
      color: Color(0xFF6B7280),
    ),
  ];

  static const List<CategoryItem> incomeCategories = [
    CategoryItem(
      name: 'Stipendio',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
    ),
    CategoryItem(
      name: 'Bonifico / Rimborso',
      icon: Icons.arrow_downward_rounded,
      color: Color(0xFF3B82F6),
    ),
    CategoryItem(
      name: 'Regalo',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFF59E0B),
    ),
    CategoryItem(
      name: 'Investimenti',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF8B5CF6),
    ),
    CategoryItem(
      name: 'Altro',
      icon: Icons.attach_money_rounded,
      color: Color(0xFF6B7280),
    ),
  ];

  static CategoryItem getCategory(String name, TransactionType type) {
    final list = type == TransactionType.expense
        ? expenseCategories
        : incomeCategories;
    return list.firstWhere(
      (cat) => cat.name == name,
      orElse: () => CategoryItem(
        name: name,
        icon: type == TransactionType.expense
            ? Icons.money_off_rounded
            : Icons.attach_money_rounded,
        color: type == TransactionType.expense
            ? Colors.redAccent
            : Colors.green,
      ),
    );
  }
}

class Transaction {
  final String id;
  final String accountId;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String? note;

  const Transaction({
    required this.id,
    required this.accountId,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'category': category,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      accountId: (map['accountId'] as String?) ?? 'default',
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: map['type'] == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      category: map['category'] as String,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      Transaction.fromMap(json);

  Transaction copyWith({
    String? id,
    String? accountId,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? category,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}
