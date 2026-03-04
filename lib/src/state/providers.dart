import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/diet_plan.dart';
import '../data/models/meal.dart';
import '../data/repository/diet_repository.dart';
import '../data/repository/hive_diet_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider non inizializzato'),
);

final hiveBoxProvider = Provider<Box<String>>(
  (_) => throw UnimplementedError('hiveBoxProvider non inizializzato'),
);

final dietRepositoryProvider = Provider<DietRepository>(
  (ref) => HiveDietRepository(ref.watch(hiveBoxProvider)),
);

final selectedDateProvider = StateProvider<DateTime>((_) => DateTime.now());

final mealClipboardProvider = StateProvider<List<Meal>>((_) => const []);
