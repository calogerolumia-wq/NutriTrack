import 'package:flutter/material.dart';

IconData mealIconFromKey(String key) {
  switch (key) {
    case 'sun':
      return Icons.wb_sunny_outlined;
    case 'croissant':
      return Icons.breakfast_dining_outlined;
    case 'apple':
      return Icons.apple_outlined;
    case 'plate':
      return Icons.dinner_dining_outlined;
    case 'moon':
      return Icons.nights_stay_outlined;
    case 'water':
      return Icons.local_drink_outlined;
    case 'fork':
    default:
      return Icons.restaurant_menu_outlined;
  }
}

const mealIconEntries = <String, IconData>{
  'sun': Icons.wb_sunny_outlined,
  'croissant': Icons.breakfast_dining_outlined,
  'apple': Icons.apple_outlined,
  'plate': Icons.dinner_dining_outlined,
  'moon': Icons.nights_stay_outlined,
  'water': Icons.local_drink_outlined,
  'fork': Icons.restaurant_menu_outlined,
};
