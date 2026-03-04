import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/diet_plan.dart';
import 'diet_controller.dart';

final dietControllerProvider = AsyncNotifierProvider<DietController, DietPlan>(DietController.new);
