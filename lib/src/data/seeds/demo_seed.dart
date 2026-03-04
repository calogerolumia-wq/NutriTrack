import 'package:uuid/uuid.dart';

import '../../core/utils/app_date_utils.dart';
import '../models/day_plan.dart';
import '../models/diet_plan.dart';
import '../models/meal.dart';
import '../models/meal_item.dart';

class DemoSeed {
  static final _uuid = Uuid();

  static DietPlan defaultPlan() {
    final monday = AppDateUtils.startOfWeekMonday(DateTime.now());
    return DietPlan(
      id: _uuid.v4(),
      name: 'Dieta Settimanale',
      note: 'Piano demo modificabile',
      createdAt: DateTime.now(),
      targets: const MacroTargets(
        calories: 2100,
        protein: 140,
        carbs: 220,
        fat: 70,
        waterMl: 2200,
      ),
      days: List<DayPlan>.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        return DayPlan(
          date: date,
          meals: _mealsForDay(index),
        );
      }),
    );
  }

  static List<Meal> _mealsForDay(int dayOffset) {
    final lunchCarbs = dayOffset.isEven ? 80.0 : 90.0;
    final dinnerCarbs = dayOffset.isEven ? 70.0 : 60.0;
    return [
      Meal(
        id: _uuid.v4(),
        type: MealType.breakfast,
        label: 'Colazione',
        iconKey: mealTypeDefaultIcon(MealType.breakfast),
        items: [
          MealItem(
            id: _uuid.v4(),
            name: 'Yogurt greco',
            quantity: 170,
            unit: 'g',
            kcal: 120,
            protein: 16,
            carbs: 8,
            fat: 2,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Fiocchi d\'avena',
            quantity: 40,
            unit: 'g',
            kcal: 150,
            protein: 5,
            carbs: 25,
            fat: 3,
          ),
        ],
      ),
      Meal(
        id: _uuid.v4(),
        type: MealType.lunch,
        label: 'Pranzo',
        iconKey: mealTypeDefaultIcon(MealType.lunch),
        items: [
          MealItem(
            id: _uuid.v4(),
            name: 'Riso basmati',
            quantity: lunchCarbs,
            unit: 'g',
            kcal: 280,
            protein: 7,
            carbs: 62,
            fat: 1,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Petto di pollo',
            quantity: 160,
            unit: 'g',
            kcal: 260,
            protein: 48,
            carbs: 0,
            fat: 6,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Olio EVO',
            quantity: 10,
            unit: 'g',
            kcal: 90,
            fat: 10,
          ),
        ],
      ),
      Meal(
        id: _uuid.v4(),
        type: MealType.snack,
        label: 'Merenda',
        iconKey: mealTypeDefaultIcon(MealType.snack),
        items: [
          MealItem(
            id: _uuid.v4(),
            name: 'Mandorle',
            quantity: 20,
            unit: 'g',
            kcal: 120,
            protein: 4,
            carbs: 3,
            fat: 10,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Mela',
            quantity: 1,
            unit: 'pz',
            kcal: 80,
            carbs: 18,
          ),
        ],
      ),
      Meal(
        id: _uuid.v4(),
        type: MealType.dinner,
        label: 'Cena',
        iconKey: mealTypeDefaultIcon(MealType.dinner),
        items: [
          MealItem(
            id: _uuid.v4(),
            name: 'Salmone',
            quantity: 150,
            unit: 'g',
            kcal: 300,
            protein: 33,
            fat: 20,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Patate',
            quantity: dinnerCarbs,
            unit: 'g',
            kcal: 120,
            protein: 3,
            carbs: 26,
          ),
          MealItem(
            id: _uuid.v4(),
            name: 'Verdure',
            quantity: 250,
            unit: 'g',
            kcal: 70,
            carbs: 11,
          ),
        ],
      ),
    ];
  }
}
