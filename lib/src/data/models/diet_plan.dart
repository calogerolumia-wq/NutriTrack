import 'day_plan.dart';

class MacroTargets {
  const MacroTargets({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.waterMl,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? waterMl;

  MacroTargets copyWith({
    double? calories,
    bool clearCalories = false,
    double? protein,
    bool clearProtein = false,
    double? carbs,
    bool clearCarbs = false,
    double? fat,
    bool clearFat = false,
    double? waterMl,
    bool clearWaterMl = false,
  }) {
    return MacroTargets(
      calories: clearCalories ? null : (calories ?? this.calories),
      protein: clearProtein ? null : (protein ?? this.protein),
      carbs: clearCarbs ? null : (carbs ?? this.carbs),
      fat: clearFat ? null : (fat ?? this.fat),
      waterMl: clearWaterMl ? null : (waterMl ?? this.waterMl),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'waterMl': waterMl,
    };
  }

  factory MacroTargets.fromJson(Map<String, dynamic> json) {
    return MacroTargets(
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      waterMl: _toDouble(json['waterMl']),
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

class DietPlan {
  const DietPlan({
    required this.id,
    required this.name,
    this.note = '',
    required this.createdAt,
    this.targets = const MacroTargets(),
    this.days = const [],
  });

  final String id;
  final String name;
  final String note;
  final DateTime createdAt;
  final MacroTargets targets;
  final List<DayPlan> days;

  DietPlan copyWith({
    String? id,
    String? name,
    String? note,
    DateTime? createdAt,
    MacroTargets? targets,
    List<DayPlan>? days,
  }) {
    return DietPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      targets: targets ?? this.targets,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'targets': targets.toJson(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    final dayList = (json['days'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => DayPlan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return DietPlan(
      id: (json['id'] as String?) ?? 'default-plan',
      name: (json['name'] as String?) ?? 'Piano Dieta',
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      targets: MacroTargets.fromJson(
        Map<String, dynamic>.from((json['targets'] as Map?) ?? <String, dynamic>{}),
      ),
      days: dayList,
    );
  }
}
