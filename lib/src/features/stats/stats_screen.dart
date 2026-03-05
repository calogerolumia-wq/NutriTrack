import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date_utils.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/diet_plan.dart';
import '../../state/diet_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dietControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Errore: $error')),
        data: (plan) => _StatsBody(plan: plan),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.plan});

  final DietPlan plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
    final days = List<DayPlan>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return _dayForDate(plan, date) ?? DayPlan(date: date);
    });
    final adherence = _adherence(days);
    final today = _dayForDate(plan, DateTime.now()) ?? DayPlan(date: DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kcal giornaliere (settimana corrente)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: _maxCalories(days),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List<BarChartGroupData>.generate(days.length, (index) {
                        final value = days[index].totalKcal;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              borderRadius: BorderRadius.circular(8),
                              width: 18,
                              color: colorScheme.secondary,
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= 7) {
                                return const SizedBox.shrink();
                              }
                              return Text(AppDateUtils.shortWeekdaysIt[i]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ripartizione macro di oggi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _MacroPieChart(day: today, colorScheme: colorScheme),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aderenza pasti',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text('${(adherence * 100).toStringAsFixed(0)}% pasti completati'),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: adherence,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DayPlan? _dayForDate(DietPlan plan, DateTime date) {
    for (final day in plan.days) {
      if (AppDateUtils.isSameDay(day.date, date)) {
        return day;
      }
    }
    return _templateDayForDate(plan, date);
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
    return DayPlan(
      date: AppDateUtils.startOfDay(targetDate),
      note: source.note,
      completed: false,
      meals: source.meals.map((meal) => meal.copyWith(completed: false)).toList(),
    );
  }

  double _adherence(List<DayPlan> days) {
    var totalMeals = 0;
    var completedMeals = 0;
    for (final day in days) {
      totalMeals += day.meals.length;
      completedMeals += day.completedMeals;
    }
    if (totalMeals == 0) {
      return 0;
    }
    return completedMeals / totalMeals;
  }

  double _maxCalories(List<DayPlan> days) {
    final max = days.fold<double>(0, (acc, day) => day.totalKcal > acc ? day.totalKcal : acc);
    if (max < 1000) {
      return 1200;
    }
    return (max * 1.2).ceilToDouble();
  }
}

class _MacroPieChart extends StatelessWidget {
  const _MacroPieChart({
    required this.day,
    required this.colorScheme,
  });

  final DayPlan day;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final p = day.totalProtein;
    final c = day.totalCarbs;
    final f = day.totalFat;
    final total = p + c + f;
    if (total <= 0) {
      return const Center(child: Text('Macro non disponibili per oggi'));
    }
    final sections = [
      PieChartSectionData(
        color: colorScheme.secondary,
        value: p,
        title: 'P',
        radius: 56,
      ),
      PieChartSectionData(
        color: colorScheme.tertiary,
        value: c,
        title: 'C',
        radius: 56,
      ),
      PieChartSectionData(
        color: colorScheme.primary,
        value: f,
        title: 'F',
        radius: 56,
      ),
    ];
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P ${p.toStringAsFixed(0)}g'),
            Text('C ${c.toStringAsFixed(0)}g'),
            Text('F ${f.toStringAsFixed(0)}g'),
          ],
        ),
      ],
    );
  }
}
