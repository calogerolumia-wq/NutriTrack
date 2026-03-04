class MealAlternative {
  const MealAlternative({
    required this.name,
    this.quantity,
    this.unit = '',
    this.note = '',
  });

  final String name;
  final double? quantity;
  final String unit;
  final String note;

  MealAlternative copyWith({
    String? name,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    String? note,
  }) {
    return MealAlternative(
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit ?? this.unit,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'note': note,
    };
  }

  factory MealAlternative.fromJson(Map<String, dynamic> json) {
    return MealAlternative(
      name: (json['name'] as String?) ?? '',
      quantity: MealItem._toDouble(json['quantity']),
      unit: (json['unit'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
    );
  }
}

class MealItem {
  const MealItem({
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
  final List<MealAlternative> alternatives;

  MealItem copyWith({
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
    List<MealAlternative>? alternatives,
  }) {
    return MealItem(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'kcal': kcal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'note': note,
      'uncertain': uncertain,
      'alternatives': alternatives.map((it) => it.toJson()).toList(),
    };
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    final alternativesList = (json['alternatives'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MealAlternative.fromJson)
        .toList();
    return MealItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      quantity: _toDouble(json['quantity']),
      unit: (json['unit'] as String?) ?? 'g',
      kcal: _toDouble(json['kcal']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      note: (json['note'] as String?) ?? '',
      uncertain: (json['uncertain'] as bool?) ?? false,
      alternatives: alternativesList,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}
