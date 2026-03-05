import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/app_date_utils.dart';
import '../data/models/day_plan.dart';
import '../data/models/diet_plan.dart';
import '../data/models/meal.dart';
import '../data/models/meal_item.dart';
import 'providers.dart';
import 'ui_preferences_controller.dart';

class DietController extends AsyncNotifier<DietPlan> {
  static final _uuid = Uuid();

  @override
  Future<DietPlan> build() async {
    final repo = ref.read(dietRepositoryProvider);
    final plan = await repo.loadPlan();
    if (plan != null) {
      return _sortPlanDays(plan);
    }
    final fallback = _sortPlanDays(
      DietPlan(
        id: _uuid.v4(),
        name: 'Dieta',
        createdAt: DateTime.now(),
      ),
    );
    await repo.savePlan(fallback);
    return fallback;
  }

  Future<void> renamePlan(String name, {String? note}) async {
    if (_isReadOnly()) {
      return;
    }
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final updated = current.copyWith(name: name, note: note ?? current.note);
    await _persist(updated);
  }

  Future<void> updateTargets(MacroTargets targets) async {
    if (_isReadOnly()) {
      return;
    }
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    await _persist(current.copyWith(targets: targets));
  }

  Future<void> resetData() async {
    if (_isReadOnly()) {
      return;
    }
    final resetPlan = _sortPlanDays(
      DietPlan(
        id: _uuid.v4(),
        name: 'Dieta',
        createdAt: DateTime.now(),
      ),
    );
    await _persist(resetPlan);
  }

  Future<void> addMeal(DateTime date, Meal meal) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateDay(date, (day) => day.copyWith(meals: [...day.meals, meal]));
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> updateMeal(DateTime date, Meal meal) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateDay(date, (day) {
      final meals = day.meals.map((e) => e.id == meal.id ? meal : e).toList();
      return day.copyWith(meals: meals);
    });
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> deleteMeal(DateTime date, String mealId) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateDay(date, (day) {
      final meals = day.meals.where((meal) => meal.id != mealId).toList();
      return day.copyWith(meals: meals);
    });
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> toggleMealCompleted(DateTime date, String mealId, bool completed) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateDay(date, (day) {
      final meals = day.meals
          .map((meal) => meal.id == mealId ? meal.copyWith(completed: completed) : meal)
          .toList();
      return day.copyWith(meals: meals);
    });
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> addItem(DateTime date, String mealId, MealItem item) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateMealItems(date, mealId, (items) => [...items, item]);
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> updateItem(DateTime date, String mealId, MealItem item) async {
    if (_isReadOnly()) {
      return;
    }
    final updated = _updateMealItems(
      date,
      mealId,
      (items) => items.map((e) => e.id == item.id ? item : e).toList(),
    );
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> deleteItem(DateTime date, String mealId, String itemId) async {
    if (_isReadOnly()) {
      return;
    }
    final updated =
        _updateMealItems(date, mealId, (items) => items.where((item) => item.id != itemId).toList());
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> duplicateDay(DateTime sourceDate, DateTime targetDate) async {
    if (_isReadOnly()) {
      return;
    }
    final plan = state.valueOrNull;
    if (plan == null) {
      return;
    }
    final sourceDay = _dayFor(plan, sourceDate);
    if (sourceDay == null) {
      return;
    }
    final copiedMeals = sourceDay.meals.map(_cloneMeal).toList();
    final target = _dayFor(plan, targetDate) ?? DayPlan(date: AppDateUtils.startOfDay(targetDate));
    final newTarget = target.copyWith(meals: copiedMeals, note: sourceDay.note);
    final updated = _replaceDay(plan, newTarget);
    await _persist(updated);
  }

  Future<void> pasteMeals(DateTime date, List<Meal> clipboardMeals) async {
    if (_isReadOnly()) {
      return;
    }
    if (clipboardMeals.isEmpty) {
      return;
    }
    final copied = clipboardMeals.map(_cloneMeal).toList();
    final updated = _updateDay(date, (day) => day.copyWith(meals: copied));
    if (updated != null) {
      await _persist(updated);
    }
  }

  Future<void> mergeImportedDays(List<DayPlan> importedDays) async {
    if (_isReadOnly()) {
      return;
    }
    final plan = state.valueOrNull;
    if (plan == null || importedDays.isEmpty) {
      return;
    }
    var working = plan;
    for (final day in importedDays) {
      final normalized = day.copyWith(date: AppDateUtils.startOfDay(day.date));
      working = _replaceDay(working, normalized);
    }
    await _persist(working);
  }

  DietPlan? _updateDay(DateTime date, DayPlan Function(DayPlan day) updater) {
    final plan = state.valueOrNull;
    if (plan == null) {
      return null;
    }
    final targetDate = AppDateUtils.startOfDay(date);
    final existing = _dayFor(plan, targetDate) ?? _templateDayForDate(plan, targetDate) ?? DayPlan(date: targetDate);
    final updatedDay = updater(existing);
    return _replaceDay(plan, updatedDay);
  }

  DietPlan? _updateMealItems(
    DateTime date,
    String mealId,
    List<MealItem> Function(List<MealItem> items) updater,
  ) {
    return _updateDay(date, (day) {
      final meals = day.meals.map((meal) {
        if (meal.id != mealId) {
          return meal;
        }
        return meal.copyWith(items: updater(meal.items));
      }).toList();
      return day.copyWith(meals: meals);
    });
  }

  DayPlan? _dayFor(DietPlan plan, DateTime date) {
    for (final day in plan.days) {
      if (AppDateUtils.isSameDay(day.date, date)) {
        return day;
      }
    }
    return null;
  }

  DayPlan? _templateDayForDate(DietPlan plan, DateTime targetDate) {
    final sameWeekday = plan.days.where((day) => day.date.weekday == targetDate.weekday).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sameWeekday.isEmpty) {
      return null;
    }
    final source = sameWeekday.firstWhere(
      (day) => !day.date.isAfter(targetDate),
      orElse: () => sameWeekday.first,
    );
    return _copyDayForRepeat(source, targetDate);
  }

  DayPlan _copyDayForRepeat(DayPlan source, DateTime targetDate) {
    return DayPlan(
      date: AppDateUtils.startOfDay(targetDate),
      note: source.note,
      completed: false,
      meals: source.meals
          .map(
            (meal) => meal.copyWith(
              completed: false,
              items: meal.items.map((item) => item.copyWith()).toList(),
            ),
          )
          .toList(),
    );
  }

  DietPlan _replaceDay(DietPlan plan, DayPlan replacement) {
    final days = <DayPlan>[];
    var found = false;
    for (final day in plan.days) {
      if (AppDateUtils.isSameDay(day.date, replacement.date)) {
        days.add(replacement);
        found = true;
      } else {
        days.add(day);
      }
    }
    if (!found) {
      days.add(replacement);
    }
    return _sortPlanDays(plan.copyWith(days: days));
  }

  Meal _cloneMeal(Meal meal) {
    return meal.copyWith(
      id: _uuid.v4(),
      items: meal.items
          .map(
            (item) => item.copyWith(
              id: _uuid.v4(),
              uncertain: false,
            ),
          )
          .toList(),
      completed: false,
      uncertain: false,
    );
  }

  DietPlan _sortPlanDays(DietPlan plan) {
    final days = [...plan.days]..sort((a, b) => a.date.compareTo(b.date));
    return plan.copyWith(days: days);
  }

  Future<void> _persist(DietPlan plan) async {
    state = AsyncData(plan);
    await ref.read(dietRepositoryProvider).savePlan(plan);
  }

  bool _isReadOnly() => ref.read(dietReadOnlyProvider);
}
