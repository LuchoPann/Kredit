import 'package:flutter/material.dart';

const Map<String, IconData> financeIconMap = {
  // Ingresos
  'work': Icons.work_outline,
  'laptop': Icons.laptop_outlined,
  'store': Icons.store_outlined,
  'trending_up': Icons.trending_up,
  'account_balance': Icons.account_balance_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'attach_money': Icons.attach_money,
  // Gastos
  'restaurant': Icons.restaurant_outlined,
  'local_grocery_store': Icons.local_grocery_store_outlined,
  'directions_car': Icons.directions_car_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'home': Icons.home_outlined,
  'bolt': Icons.bolt_outlined,
  'water_drop': Icons.water_drop_outlined,
  'wifi': Icons.wifi_outlined,
  'phone': Icons.phone_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'medication': Icons.medication_outlined,
  'school': Icons.school_outlined,
  'menu_book': Icons.menu_book_outlined,
  'movie': Icons.movie_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'music_note': Icons.music_note_outlined,
  'checkroom': Icons.checkroom_outlined,
  'devices': Icons.devices_outlined,
  'flight': Icons.flight_outlined,
  'hotel': Icons.hotel_outlined,
  'pets': Icons.pets_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'savings': Icons.savings_outlined,
  'credit_card': Icons.credit_card_outlined,
  'swap_horiz': Icons.swap_horiz_outlined,
  'more_horiz': Icons.more_horiz,
};

IconData iconFromKey(String? key) =>
    key != null ? (financeIconMap[key] ?? Icons.label_outline) : Icons.label_outline;
