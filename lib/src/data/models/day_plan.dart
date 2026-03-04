import '../../core/utils/app_date_utils.dart';
import 'meal.dart';

class DayPlan {
  const DayPlan({
    required this.date,
    this.meals = const [],
    this.note = '',
    this.completed = false,
  });

  final DateTime date;
  final List<Meal> meals;
  final String note;
  final bool completed;

  DayPlan copyWith({
    DateTime? date,
    List<Meal>? meals,
    String? note,
    bool? completed,
  }) {
    return DayPlan(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      note: note ?? this.note,
      completed: completed ?? this.completed,
    );
  }

  double get totalKcal => meals.fold<double>(0, (sum, meal) => sum + meal.totalKcal);
  double get totalProtein => meals.fold<double>(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbs => meals.fold<double>(0, (sum, meal) => sum + meal.totalCarbs);
  double get totalFat => meals.fold<double>(0, (sum, meal) => sum + meal.totalFat);

  int get completedMeals => meals.where((meal) => meal.completed).length;
  double get completionRate => meals.isEmpty ? 0 : completedMeals / meals.length;

  Map<String, dynamic> toJson() {
    return {
      'date': AppDateUtils.ymdKey(date),
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'note': note,
      'completed': completed,
    };
  }

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final dateRaw = (json['date'] as String?) ?? '';
    final date = DateTime.tryParse(dateRaw) ?? DateTime.now();
    final mealList = (json['meals'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Meal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return DayPlan(
      date: AppDateUtils.startOfDay(date),
      meals: mealList,
      note: (json['note'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
    );
  }
}
