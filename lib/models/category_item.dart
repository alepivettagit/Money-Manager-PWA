import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<IconData> supportedIcons = [
    Icons.shopping_basket_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.sports_esports_rounded,
    Icons.shopping_bag_rounded,
    Icons.healing_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.school_rounded,
    Icons.subscriptions_rounded,
    Icons.local_cafe_rounded,
    Icons.music_note_rounded,
    Icons.computer_rounded,
    Icons.build_rounded,
    Icons.fastfood_rounded,
    Icons.beach_access_rounded,
    Icons.child_care_rounded,
    Icons.savings_rounded,
    Icons.work_rounded,
    Icons.card_giftcard_rounded,
    Icons.trending_up_rounded,
    Icons.electric_bolt_rounded,
    Icons.movie_rounded,
    Icons.local_hospital_rounded,
    Icons.category_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.arrow_downward_rounded,
    Icons.attach_money_rounded,
    Icons.money_off_rounded,
  ];

  static IconData iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.category_rounded;
    for (final icon in supportedIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category_rounded;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      name: map['name'] as String,
      icon: iconFromCodePoint(map['iconCodePoint'] as int?),
      color: Color(map['colorValue'] as int? ?? 0xFF6B7280),
    );
  }

  CategoryItem copyWith({String? name, IconData? icon, Color? color}) {
    return CategoryItem(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
