import 'package:uuid/uuid.dart';

import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/day_plan.dart';
import '../../../data/models/meal.dart';
import '../../../data/models/meal_item.dart';

final _uuid = Uuid();

class ImportDraft {
  const ImportDraft({
    required this.rawText,
    required this.days,
    this.unparsedLines = const [],
  });

  final String rawText;
  final List<ParsedDay> days;
  final List<String> unparsedLines;

  ImportDraft copyWith({
    String? rawText,
    List<ParsedDay>? days,
    List<String>? unparsedLines,
  }) {
    return ImportDraft(
      rawText: rawText ?? this.rawText,
      days: days ?? this.days,
      unparsedLines: unparsedLines ?? this.unparsedLines,
    );
  }

  int get uncertainCount {
    var count = 0;
    for (final day in days) {
      if (day.uncertain) {
        count++;
      }
      for (final meal in day.meals) {
        if (meal.uncertain) {
          count++;
        }
        for (final item in meal.items) {
          if (item.uncertain) {
            count++;
          }
          for (final alt in item.alternatives) {
            if (alt.uncertain) {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  List<DayPlan> toDayPlans(DateTime weekStart) {
    final normalizedWeek = AppDateUtils.startOfWeekMonday(weekStart);
    return List<DayPlan>.generate(days.length, (index) {
      final parsed = days[index];
      final fallbackDate = normalizedWeek.add(Duration(days: index));
      final date = parsed.date ?? _weekdayDateFromLabel(parsed.label, normalizedWeek) ?? fallbackDate;
      return DayPlan(
        date: AppDateUtils.startOfDay(date),
        note: parsed.uncertain ? 'Import automatico da verificare' : '',
        meals: parsed.meals
            .map(
              (meal) => Meal(
                id: _uuid.v4(),
                type: meal.type,
                label: meal.label.trim().isEmpty ? mealTypeLabel(meal.type) : meal.label.trim(),
                iconKey: mealTypeDefaultIcon(meal.type),
                uncertain: meal.uncertain,
                items: meal.items
                    .map(
                      (item) => MealItem(
                        id: _uuid.v4(),
                        name: item.name.trim().isEmpty ? 'Elemento non riconosciuto' : item.name.trim(),
                        quantity: item.quantity,
                        unit: item.unit,
                        kcal: item.kcal,
                        protein: item.protein,
                        carbs: item.carbs,
                        fat: item.fat,
                        note: item.note,
                        uncertain: item.uncertain,
                        alternatives: item.alternatives
                            .map(
                              (alt) => MealAlternative(
                                name: alt.name.trim().isEmpty ? 'Alternativa' : alt.name.trim(),
                                quantity: alt.quantity,
                                unit: alt.unit,
                                note: alt.note,
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    });
  }

  DateTime? _weekdayDateFromLabel(String label, DateTime weekStart) {
    final normalized = label.toLowerCase();
    const byIndex = {
      1: ['lun', 'lune', 'luned', 'monday'],
      2: ['mar', 'mart', 'marted', 'tuesday'],
      3: ['mer', 'merc', 'mercoled', 'wednesday'],
      4: ['gio', 'giov', 'gioved', 'thursday'],
      5: ['ven', 'venerd', 'friday'],
      6: ['sab', 'sabat', 'saturday'],
      7: ['dom', 'domen', 'sunday'],
    };
    for (final entry in byIndex.entries) {
      final hasMatch = entry.value.any((token) => normalized.contains(token));
      if (hasMatch) {
        return weekStart.add(Duration(days: entry.key - 1));
      }
    }
    return null;
  }
}

class ParsedDay {
  const ParsedDay({
    required this.id,
    required this.label,
    this.date,
    this.meals = const [],
    this.uncertain = false,
  });

  final String id;
  final String label;
  final DateTime? date;
  final List<ParsedMeal> meals;
  final bool uncertain;

  ParsedDay copyWith({
    String? id,
    String? label,
    DateTime? date,
    bool clearDate = false,
    List<ParsedMeal>? meals,
    bool? uncertain,
  }) {
    return ParsedDay(
      id: id ?? this.id,
      label: label ?? this.label,
      date: clearDate ? null : (date ?? this.date),
      meals: meals ?? this.meals,
      uncertain: uncertain ?? this.uncertain,
    );
  }
}

class ParsedMeal {
  const ParsedMeal({
    required this.id,
    required this.type,
    required this.label,
    this.items = const [],
    this.note = '',
    this.uncertain = false,
  });

  final String id;
  final MealType type;
  final String label;
  final List<ParsedMealItem> items;
  final String note;
  final bool uncertain;

  ParsedMeal copyWith({
    String? id,
    MealType? type,
    String? label,
    List<ParsedMealItem>? items,
    String? note,
    bool? uncertain,
  }) {
    return ParsedMeal(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      items: items ?? this.items,
      note: note ?? this.note,
      uncertain: uncertain ?? this.uncertain,
    );
  }
}

class ParsedMealItem {
  const ParsedMealItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit = 'g',
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.note = '',
    this.uncertain = false,
    this.alternatives = const [],
  });

  final String id;
  final String name;
  final double? quantity;
  final String unit;
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String note;
  final bool uncertain;
  final List<ParsedAlternativeItem> alternatives;

  ParsedMealItem copyWith({
    String? id,
    String? name,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    double? kcal,
    bool clearKcal = false,
    double? protein,
    bool clearProtein = false,
    double? carbs,
    bool clearCarbs = false,
    double? fat,
    bool clearFat = false,
    String? note,
    bool? uncertain,
    List<ParsedAlternativeItem>? alternatives,
  }) {
    return ParsedMealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit ?? this.unit,
      kcal: clearKcal ? null : (kcal ?? this.kcal),
      protein: clearProtein ? null : (protein ?? this.protein),
      carbs: clearCarbs ? null : (carbs ?? this.carbs),
      fat: clearFat ? null : (fat ?? this.fat),
      note: note ?? this.note,
      uncertain: uncertain ?? this.uncertain,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}

class ParsedAlternativeItem {
  const ParsedAlternativeItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit = '',
    this.note = '',
    this.uncertain = false,
  });

  final String id;
  final String name;
  final double? quantity;
  final String unit;
  final String note;
  final bool uncertain;

  ParsedAlternativeItem copyWith({
    String? id,
    String? name,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    String? note,
    bool? uncertain,
  }) {
    return ParsedAlternativeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit ?? this.unit,
      note: note ?? this.note,
      uncertain: uncertain ?? this.uncertain,
    );
  }
}
