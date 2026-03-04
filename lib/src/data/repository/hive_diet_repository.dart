import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/diet_plan.dart';
import 'diet_repository.dart';

class HiveDietRepository implements DietRepository {
  HiveDietRepository(this._box);

  static const _planKey = 'diet_plan_json_v1';
  final Box<String> _box;

  @override
  Future<DietPlan?> loadPlan() async {
    final raw = _box.get(_planKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DietPlan.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlan(DietPlan plan) async {
    final encoded = jsonEncode(plan.toJson());
    await _box.put(_planKey, encoded);
  }

  @override
  Future<void> seedIfEmpty() async {}
}
