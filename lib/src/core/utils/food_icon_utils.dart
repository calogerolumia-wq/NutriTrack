import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class _FoodIconRule {
  const _FoodIconRule({
    required this.keywords,
    this.material,
    this.fa,
  });

  final List<String> keywords;
  final IconData? material;
  final IconData? fa;
}

const _rules = <_FoodIconRule>[
  _FoodIconRule(
    keywords: ['caffe', 'coffee', 'espresso', 'cappuccino'],
    fa: FontAwesomeIcons.mugHot,
  ),
  _FoodIconRule(
    keywords: ['yogurt', 'yoghurt'],
    material: FontAwesomeIcons.iceCream,
  ),
  _FoodIconRule(
    keywords: ['latte', 'milk'],
    material: Icons.local_drink_outlined,
  ),
  _FoodIconRule(
    keywords: ['uovo', 'uova', 'egg'],
    fa: FontAwesomeIcons.egg,
  ),
  _FoodIconRule(
    keywords: ['pollo', 'tacchino', 'carne', 'chicken', 'turkey'],
    fa: FontAwesomeIcons.drumstickBite,
  ),
  _FoodIconRule(
    keywords: ['pesce', 'salmone', 'tonno', 'fish'],
    fa: FontAwesomeIcons.fish,
  ),
  _FoodIconRule(
    keywords: ['pane', 'toast', 'fette biscottate'],
    material: FontAwesomeIcons.breadSlice,
  ),
  _FoodIconRule(
    keywords: ['pasta', 'riso', 'farro', 'cous', 'avena', 'cereali'],
    material: Icons.ramen_dining_outlined,
  ),
  _FoodIconRule(
    keywords: ['insalata', 'verdura', 'zucchine', 'carote', 'broccoli', 'finocchi'],
    material: Icons.eco_outlined,
  ),
  _FoodIconRule(
    keywords: ['frutta', 'mela', 'banana', 'kiwi', 'pera', 'arancia'],
    fa: FontAwesomeIcons.appleWhole,
  ),
  _FoodIconRule(
    keywords: ['formaggio', 'grana', 'parmigiano', 'mozzarella'],
    fa: FontAwesomeIcons.cheese,
  ),
  _FoodIconRule(
    keywords: ['acqua', 'water'],
    fa: FontAwesomeIcons.glassWater,
  ),
  _FoodIconRule(
    keywords: ['olio', 'oliva'],
    material: Icons.opacity_outlined,
  ),
  _FoodIconRule(
    keywords: ['pizza', 'hamburger', 'panino'],
    material: Icons.lunch_dining_outlined,
  ),
];

Widget foodIconForName(
  String rawName, {
  Color? color,
  double size = 20,
}) {
  final name = _normalize(rawName);
  for (final rule in _rules) {
    if (rule.keywords.any((key) => name.contains(key))) {
      if (rule.fa != null) {
        return FaIcon(rule.fa, color: color, size: size);
      }
      return Icon(rule.material ?? Icons.restaurant_menu_outlined, color: color, size: size);
    }
  }
  return Icon(Icons.restaurant_menu_outlined, color: color, size: size);
}

String _normalize(String input) {
  var text = input.toLowerCase().trim();
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  const accents = <String, String>{
    '\u00E0': 'a',
    '\u00E1': 'a',
    '\u00E2': 'a',
    '\u00E3': 'a',
    '\u00E4': 'a',
    '\u00E5': 'a',
    '\u00E8': 'e',
    '\u00E9': 'e',
    '\u00EA': 'e',
    '\u00EB': 'e',
    '\u00EC': 'i',
    '\u00ED': 'i',
    '\u00EE': 'i',
    '\u00EF': 'i',
    '\u00F2': 'o',
    '\u00F3': 'o',
    '\u00F4': 'o',
    '\u00F5': 'o',
    '\u00F6': 'o',
    '\u00F9': 'u',
    '\u00FA': 'u',
    '\u00FB': 'u',
    '\u00FC': 'u',
    '\u00E7': 'c',
  };

  for (final entry in accents.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text;
}
