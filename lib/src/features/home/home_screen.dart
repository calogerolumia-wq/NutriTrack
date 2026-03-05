import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date_utils.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/diet_plan.dart';
import '../../state/diet_provider.dart';
import '../../state/providers.dart';
import '../../state/ui_preferences_controller.dart';
import 'day_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _weekDayKeys = List<GlobalKey>.generate(7, (_) => GlobalKey());
  DateTime? _lastFocusedDate;

  void _focusSelectedDay(DateTime selectedDate, DateTime weekStart) {
    final index = selectedDate.difference(weekStart).inDays;
    if (index < 0 || index >= _weekDayKeys.length) {
      return;
    }
    if (_lastFocusedDate != null && AppDateUtils.isSameDay(_lastFocusedDate!, selectedDate)) {
      return;
    }
    _lastFocusedDate = selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = _weekDayKeys[index].currentContext;
      if (targetContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final planAsync = ref.watch(dietControllerProvider);
    final clipboardMeals = ref.watch(mealClipboardProvider);
    final readOnly = ref.watch(dietReadOnlyProvider);
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
            onPressed: plan == null || readOnly
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
                if (!hasMeals || readOnly) {
                  return;
                }
                ref.read(mealClipboardProvider.notifier).state = selectedDay!.meals;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pasti copiati negli appunti')),
                );
                return;
              }
              if (value == 'paste') {
                if (!canPaste || readOnly) {
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
                if (!hasMeals || readOnly) {
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
                enabled: hasMeals && !readOnly,
                child: const Text('Copia pasti'),
              ),
              PopupMenuItem<String>(
                value: 'paste',
                enabled: canPaste && !readOnly,
                child: const Text('Incolla pasti'),
              ),
              PopupMenuItem<String>(
                value: 'duplicate',
                enabled: hasMeals && !readOnly,
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
          _focusSelectedDay(selectedDate, weekStart);
          return Column(
            children: [
              SizedBox(
                height: 106,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final day = weekStart.add(Duration(days: index));
                    final isSelected = AppDateUtils.isSameDay(day, selectedDate);
                    final dayPlan = _dayForDate(plan, day);
                    return KeyedSubtree(
                      key: _weekDayKeys[index],
                      child: _WeekDayChip(
                        date: day,
                        selected: isSelected,
                        hasMeals: (dayPlan?.meals.isNotEmpty ?? false),
                        completionRate: dayPlan?.completionRate ?? 0,
                        onTap: () => ref.read(selectedDateProvider.notifier).state = day,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: _ReadOnlyBar(
                  readOnly: readOnly,
                  onChanged: (value) {
                    ref.read(dietReadOnlyProvider.notifier).setDietReadOnly(value);
                  },
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: DayDetailView(
                    key: ValueKey(AppDateUtils.ymdKey(selectedDate)),
                    date: selectedDate,
                    readOnly: readOnly,
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

class _ReadOnlyBar extends StatelessWidget {
  const _ReadOnlyBar({
    required this.readOnly,
    required this.onChanged,
  });

  final bool readOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: readOnly ? colorScheme.errorContainer.withOpacity(0.35) : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(readOnly ? Icons.lock_outline : Icons.lock_open_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Modalita solo lettura',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Switch(
              value: readOnly,
              onChanged: onChanged,
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppDateUtils.weekdayShortIt(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${date.day}',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
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
