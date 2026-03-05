import 'meal_item.dart';

enum MealType {
  breakfast,
  snack,
  lunch,
  merenda,
  dinner,
  custom,
}

MealType mealTypeFromString(String value) {
  return MealType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => MealType.custom,
  );
}

String mealTypeLabel(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'Colazione';
    case MealType.snack:
      return 'Spuntino';
    case MealType.lunch:
      return 'Pranzo';
    case MealType.merenda:
      return 'Merenda';
    case MealType.dinner:
      return 'Cena';
    case MealType.custom:
      return 'Pasto';
  }
}

String mealTypeDefaultIcon(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'sun';
    case MealType.snack:
      return 'apple';
    case MealType.lunch:
      return 'plate';
    case MealType.merenda:
      return 'apple';
    case MealType.dinner:
      return 'moon';
    case MealType.custom:
      return 'fork';
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.type,
    required this.label,
    required this.iconKey,
    this.items = const [],
    this.note = '',
    this.completed = false,
    this.uncertain = false,
  });

  final String id;
  final MealType type;
  final String label;
  final String iconKey;
  final List<MealItem> items;
  final String note;
  final bool completed;
  final bool uncertain;

  Meal copyWith({
    String? id,
    MealType? type,
    String? label,
    String? iconKey,
    List<MealItem>? items,
    String? note,
    bool? completed,
    bool? uncertain,
  }) {
    return Meal(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      iconKey: iconKey ?? this.iconKey,
      items: items ?? this.items,
      note: note ?? this.note,
      completed: completed ?? this.completed,
      uncertain: uncertain ?? this.uncertain,
    );
  }

  double get totalKcal => items.fold<double>(0, (sum, item) => sum + (item.kcal ?? 0));
  double get totalProtein => items.fold<double>(0, (sum, item) => sum + (item.protein ?? 0));
  double get totalCarbs => items.fold<double>(0, (sum, item) => sum + (item.carbs ?? 0));
  double get totalFat => items.fold<double>(0, (sum, item) => sum + (item.fat ?? 0));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'iconKey': iconKey,
      'items': items.map((item) => item.toJson()).toList(),
      'note': note,
      'completed': completed,
      'uncertain': uncertain,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MealItem.fromJson)
        .toList();
    return Meal(
      id: json['id'] as String,
      type: mealTypeFromString((json['type'] as String?) ?? 'custom'),
      label: (json['label'] as String?) ?? '',
      iconKey: (json['iconKey'] as String?) ?? 'fork',
      items: list,
      note: (json['note'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      uncertain: (json['uncertain'] as bool?) ?? false,
    );
  }
}
