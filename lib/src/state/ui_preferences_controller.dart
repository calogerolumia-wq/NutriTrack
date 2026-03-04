import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class UiPreferencesController extends Notifier<bool> {
  static const _showAdvancedDayMetricsKey = 'show_advanced_day_metrics_v1';

  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_showAdvancedDayMetricsKey) ?? false;
  }

  Future<void> setShowAdvancedDayMetrics(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_showAdvancedDayMetricsKey, value);
  }
}

final showAdvancedDayMetricsProvider =
    NotifierProvider<UiPreferencesController, bool>(UiPreferencesController.new);
