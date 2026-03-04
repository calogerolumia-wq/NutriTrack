import '../models/diet_plan.dart';

abstract class DietRepository {
  Future<DietPlan?> loadPlan();
  Future<void> savePlan(DietPlan plan);
  Future<void> seedIfEmpty();
}
