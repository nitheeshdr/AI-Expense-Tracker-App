import 'package:flutter/material.dart';

/// A category definition. [icon] is a Material icon (no emoji) and [color] is
/// the accent used in chips/charts.
class CategoryDef {
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const CategoryDef(this.name, this.icon, this.color, {this.isIncome = false});
}

/// Master catalog. Stored category rows reference these by [name].
class Categories {
  Categories._();

  static const List<CategoryDef> all = [
    // Income
    CategoryDef('Salary', Icons.payments_outlined, Color(0xFF12B98C), isIncome: true),
    CategoryDef('Freelance', Icons.work_outline, Color(0xFF2BD4C0), isIncome: true),
    CategoryDef('Business', Icons.business_center_outlined, Color(0xFF12B98C), isIncome: true),
    CategoryDef('Cashback', Icons.card_giftcard_outlined, Color(0xFF7CD992), isIncome: true),
    CategoryDef('Refund', Icons.undo_outlined, Color(0xFF5BD0A0), isIncome: true),
    CategoryDef('Investments', Icons.trending_up_outlined, Color(0xFF4DB6FF), isIncome: true),

    // Expenses
    CategoryDef('Food', Icons.lunch_dining_outlined, Color(0xFFFF8A4C)),
    CategoryDef('Groceries', Icons.shopping_cart_outlined, Color(0xFF7AC74F)),
    CategoryDef('Restaurants', Icons.restaurant_outlined, Color(0xFFFF7043)),
    CategoryDef('Coffee', Icons.coffee_outlined, Color(0xFFB07B52)),
    CategoryDef('Shopping', Icons.shopping_bag_outlined, Color(0xFFFF6B7D)),
    CategoryDef('Clothing', Icons.checkroom_outlined, Color(0xFFEC5C8E)),
    CategoryDef('Electronics', Icons.devices_outlined, Color(0xFF5C7CFA)),
    CategoryDef('Transport', Icons.directions_bus_outlined, Color(0xFF4DB6FF)),
    CategoryDef('Taxi', Icons.local_taxi_outlined, Color(0xFFFFC857)),
    CategoryDef('Fuel', Icons.local_gas_station_outlined, Color(0xFFFF9E4D)),
    CategoryDef('Parking', Icons.local_parking_outlined, Color(0xFF6C8AE0)),
    CategoryDef('Travel', Icons.flight_takeoff_outlined, Color(0xFF38BDF8)),
    CategoryDef('Hotels', Icons.hotel_outlined, Color(0xFF818CF8)),
    CategoryDef('Entertainment', Icons.movie_outlined, Color(0xFFA78BFA)),
    CategoryDef('Movies', Icons.local_movies_outlined, Color(0xFFC084FC)),
    CategoryDef('OTT', Icons.live_tv_outlined, Color(0xFFE879F9)),
    CategoryDef('Gaming', Icons.sports_esports_outlined, Color(0xFF8B5CF6)),
    CategoryDef('Healthcare', Icons.medical_services_outlined, Color(0xFF34D399)),
    CategoryDef('Pharmacy', Icons.medication_outlined, Color(0xFF2DD4BF)),
    CategoryDef('Insurance', Icons.shield_outlined, Color(0xFF60A5FA)),
    CategoryDef('Education', Icons.school_outlined, Color(0xFF38BDF8)),
    CategoryDef('Rent', Icons.home_outlined, Color(0xFFFB7185)),
    CategoryDef('Utilities', Icons.lightbulb_outline, Color(0xFFFBBF24)),
    CategoryDef('Electricity', Icons.bolt_outlined, Color(0xFFFACC15)),
    CategoryDef('Water', Icons.water_drop_outlined, Color(0xFF38BDF8)),
    CategoryDef('Gas', Icons.local_fire_department_outlined, Color(0xFFFB923C)),
    CategoryDef('Internet', Icons.wifi_outlined, Color(0xFF22D3EE)),
    CategoryDef('Mobile', Icons.smartphone_outlined, Color(0xFF34D399)),
    CategoryDef('EMI', Icons.account_balance_outlined, Color(0xFFF472B6)),
    CategoryDef('Loans', Icons.credit_card_outlined, Color(0xFFFB7185)),
    CategoryDef('Mutual Funds', Icons.pie_chart_outline, Color(0xFF60A5FA)),
    CategoryDef('SIP', Icons.repeat_outlined, Color(0xFF4ADE80)),
    CategoryDef('Stocks', Icons.show_chart_outlined, Color(0xFF38BDF8)),
    CategoryDef('Crypto', Icons.currency_bitcoin_outlined, Color(0xFFF59E0B)),
    CategoryDef('Family', Icons.family_restroom_outlined, Color(0xFFFB7185)),
    CategoryDef('Kids', Icons.child_care_outlined, Color(0xFFF472B6)),
    CategoryDef('Pets', Icons.pets_outlined, Color(0xFFFBBF24)),
    CategoryDef('Charity', Icons.volunteer_activism_outlined, Color(0xFF34D399)),
    CategoryDef('Taxes', Icons.receipt_long_outlined, Color(0xFF94A3B8)),
    CategoryDef('Gifts', Icons.redeem_outlined, Color(0xFFF472B6)),
    CategoryDef('Beauty', Icons.face_retouching_natural_outlined, Color(0xFFEC4899)),
    CategoryDef('Fitness', Icons.fitness_center_outlined, Color(0xFF22C55E)),
    CategoryDef('Home', Icons.chair_outlined, Color(0xFFA78BFA)),
    CategoryDef('Lifestyle', Icons.auto_awesome_outlined, Color(0xFFC084FC)),
    CategoryDef('Subscription', Icons.subscriptions_outlined, Color(0xFF818CF8)),
    CategoryDef('Miscellaneous', Icons.category_outlined, Color(0xFF94A3B8)),
  ];

  static final Map<String, CategoryDef> byName = {
    for (final c in all) c.name: c,
  };

  static CategoryDef of(String name) =>
      byName[name] ??
      const CategoryDef('Miscellaneous', Icons.category_outlined, Color(0xFF94A3B8));

  static List<CategoryDef> get expenses =>
      all.where((c) => !c.isIncome).toList();
  static List<CategoryDef> get incomes => all.where((c) => c.isIncome).toList();
}
