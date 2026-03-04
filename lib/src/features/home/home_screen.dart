import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date_utils.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/diet_plan.dart';
import '../../state/diet_provider.dart';
import '../../state/providers.dart';
import 'day_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final planAsync = ref.watch(dietControllerProvider);
    final clipboardMeals = ref.watch(mealClipboardProvider);
    final plan = planAsync.valueOrNull;
    final selectedDay = plan == null ? null : _dayForDate(plan, selectedDate);
    final hasMeals = selectedDay?.meals.isNotEmpty ?? false;
    final canPaste = clipboardMeals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriTrack', style: TextStyle(fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            tooltip: 'Aggiungi pasto',
            onPressed: plan == null
                ? null
                : () async {
                    final meal = await showMealEditorDialog(context);
                    if (meal != null) {
                      await ref.read(dietControllerProvider.notifier).addMeal(selectedDate, meal);
                    }
                  },
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<String>(
            tooltip: 'Azioni giorno',
            onSelected: (value) async {
              if (value == 'copy') {
                if (!hasMeals) {
                  return;
                }
                ref.read(mealClipboardProvider.notifier).state = selectedDay!.meals;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pasti copiati negli appunti')),
                );
                return;
              }
              if (value == 'paste') {
                if (!canPaste) {
                  return;
                }
                await ref.read(dietControllerProvider.notifier).pasteMeals(selectedDate, clipboardMeals);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pasti incollati nel giorno selezionato')),
                  );
                }
                return;
              }
              if (value == 'duplicate') {
                if (!hasMeals) {
                  return;
                }
                await ref
                    .read(dietControllerProvider.notifier)
                    .duplicateDay(selectedDate, selectedDate.add(const Duration(days: 1)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giorno duplicato su domani')),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'copy',
                enabled: hasMeals,
                child: const Text('Copia pasti'),
              ),
              PopupMenuItem<String>(
                value: 'paste',
                enabled: canPaste,
                child: const Text('Incolla pasti'),
              ),
              PopupMenuItem<String>(
                value: 'duplicate',
                enabled: hasMeals,
                child: const Text('Duplica su domani'),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
            },
            icon: const Icon(Icons.today_outlined),
            label: const Text('Oggi'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Errore caricamento dieta: $error'),
          ),
        ),
        data: (plan) {
          final weekStart = AppDateUtils.startOfWeekMonday(selectedDate);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _PlanSummaryCard(
                  plan: plan,
                  selectedDay: _dayForDate(plan, selectedDate),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final day = weekStart.add(Duration(days: index));
                    final isSelected = AppDateUtils.isSameDay(day, selectedDate);
                    final dayPlan = _dayForDate(plan, day);
                    return _WeekDayChip(
                      date: day,
                      selected: isSelected,
                      hasMeals: (dayPlan?.meals.isNotEmpty ?? false),
                      completionRate: dayPlan?.completionRate ?? 0,
                      onTap: () => ref.read(selectedDateProvider.notifier).state = day,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: DayDetailView(
                    key: ValueKey(AppDateUtils.ymdKey(selectedDate)),
                    date: selectedDate,
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.plan,
    required this.selectedDay,
  });

  final DietPlan plan;
  final DayPlan? selectedDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final calories = selectedDay?.totalKcal ?? 0;
    final target = plan.targets.calories;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Settimana attiva',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${calories.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (target != null)
                Text(
                  'target ${target.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.date,
    required this.selected,
    required this.hasMeals,
    required this.completionRate,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasMeals;
  final double completionRate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = selected ? colorScheme.onPrimary : colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppDateUtils.weekdayShortIt(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.circular(99),
              value: hasMeals ? completionRate : 0,
              backgroundColor: selected ? Colors.white24 : colorScheme.outlineVariant,
              color: selected ? Colors.white : colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
