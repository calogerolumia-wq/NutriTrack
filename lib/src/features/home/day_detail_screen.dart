import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_date_utils.dart';
import '../../core/utils/food_icon_utils.dart';
import '../../core/utils/meal_icon_utils.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/diet_plan.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_item.dart';
import '../../state/diet_provider.dart';

class DayDetailView extends ConsumerWidget {
  const DayDetailView({
    super.key,
    required this.date,
    this.readOnly = false,
  });

  final DateTime date;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dietControllerProvider);
    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Errore: $error')),
      data: (plan) {
        final day = _dayForDate(plan, date);
        final sortedMeals = [...(day?.meals ?? const <Meal>[])]
          ..sort((a, b) => _mealOrder(a.type).compareTo(_mealOrder(b.type)));
        final hasMeals = sortedMeals.isNotEmpty;
        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 120),
          children: [
            if (readOnly) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Modalita solo lettura attiva'),
                  subtitle: const Text('Disattiva "Lock diet" dalla Home per modificare i pasti.'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!hasMeals)
              _EmptyDayState(
                readOnly: readOnly,
                onAddMeal: readOnly
                    ? null
                    : () async {
                        final meal = await showMealEditorDialog(context);
                        if (meal != null) {
                          await ref.read(dietControllerProvider.notifier).addMeal(date, meal);
                        }
                      },
              ),
            if (hasMeals)
              ...sortedMeals.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MealCard(
                    meal: meal,
                    date: date,
                    readOnly: readOnly,
                  ),
                ),
              ),
          ],
        );
      },
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

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({
    required this.readOnly,
    required this.onAddMeal,
  });

  final bool readOnly;
  final VoidCallback? onAddMeal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nessun pasto programmato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Aggiungi colazione, spuntino, pranzo, merenda, cena o pasti personalizzati.'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAddMeal,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(readOnly ? 'Modifica disabilitata' : 'Crea primo pasto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({
    required this.meal,
    required this.date,
    required this.readOnly,
  });

  final Meal meal;
  final DateTime date;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dietControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(mealIconFromKey(meal.iconKey), color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${meal.totalKcal.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: meal.completed,
                  onChanged: readOnly
                      ? null
                      : (value) {
                          notifier.toggleMealCompleted(date, meal.id, value ?? false);
                        },
                ),
                PopupMenuButton<String>(
                  enabled: !readOnly,
                  onSelected: readOnly
                      ? null
                      : (value) async {
                    if (value == 'edit') {
                      final updated = await showMealEditorDialog(context, initial: meal);
                      if (updated != null) {
                        await notifier.updateMeal(date, updated);
                      }
                    }
                    if (value == 'delete') {
                      await notifier.deleteMeal(date, meal.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(value: 'edit', child: Text('Modifica pasto')),
                    PopupMenuItem<String>(value: 'delete', child: Text('Elimina pasto')),
                  ],
                ),
              ],
            ),
            if (meal.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(meal.note, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            if (meal.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Nessun elemento', style: Theme.of(context).textTheme.bodySmall),
              ),
            if (meal.items.isNotEmpty)
              ...meal.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(_itemSubtitle(item)),
                  leading: foodIconForName(
                    item.name,
                    color: item.uncertain ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: readOnly
                            ? null
                            : () async {
                                final updated = await showMealItemDialog(context, initial: item);
                                if (updated != null) {
                                  await notifier.updateItem(date, meal.id, updated);
                                }
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: readOnly
                            ? null
                            : () {
                                notifier.deleteItem(date, meal.id, item.id);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: readOnly
                  ? null
                  : () async {
                      final item = await showMealItemDialog(context);
                      if (item != null) {
                        await notifier.addItem(date, meal.id, item);
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi elemento'),
            ),
          ],
        ),
      ),
    );
  }

  String _itemSubtitle(MealItem item) {
    final qty = item.quantity != null ? '${item.quantity!.toStringAsFixed(0)} ${item.unit}' : item.unit;
    final macros = <String>[];
    if (item.kcal != null) {
      macros.add('${item.kcal!.toStringAsFixed(0)} kcal');
    }
    if (item.protein != null) {
      macros.add('P ${item.protein!.toStringAsFixed(0)}');
    }
    if (item.carbs != null) {
      macros.add('C ${item.carbs!.toStringAsFixed(0)}');
    }
    if (item.fat != null) {
      macros.add('F ${item.fat!.toStringAsFixed(0)}');
    }
    final macroText = macros.isEmpty ? '' : ' - ${macros.join(' - ')}';
    final segments = <String>[];
    final base = '$qty$macroText'.trim();
    if (base.isNotEmpty) {
      segments.add(base);
    }
    if (item.note.isNotEmpty) {
      segments.add(item.note);
    }
    if (item.alternatives.isNotEmpty) {
      final altPreview = item.alternatives
          .map(
            (alt) => alt.quantity == null ? alt.name : '${alt.name} ${alt.quantity!.toStringAsFixed(0)} ${alt.unit}',
          )
          .join(', ');
      segments.add('Alternative: $altPreview');
    }
    return segments.join(' - ');
  }
}

Future<Meal?> showMealEditorDialog(BuildContext context, {Meal? initial}) async {
  const uuid = Uuid();
  final labelController = TextEditingController(text: initial?.label ?? '');
  final noteController = TextEditingController(text: initial?.note ?? '');
  var type = initial?.type ?? MealType.custom;
  var iconKey = initial?.iconKey ?? mealTypeDefaultIcon(type);

  return showDialog<Meal>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(initial == null ? 'Nuovo pasto' : 'Modifica pasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Titolo'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MealType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo pasto'),
                    items: MealType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(mealTypeLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          type = value;
                          iconKey = mealTypeDefaultIcon(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: iconKey,
                    decoration: const InputDecoration(labelText: 'Icona'),
                    items: mealIconEntries.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(entry.value),
                                const SizedBox(width: 8),
                                Text(entry.key),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => iconKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () {
                  final label = labelController.text.trim();
                  if (label.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(
                    Meal(
                      id: initial?.id ?? uuid.v4(),
                      type: type,
                      label: label,
                      iconKey: iconKey,
                      note: noteController.text.trim(),
                      items: initial?.items ?? const [],
                      completed: initial?.completed ?? false,
                      uncertain: initial?.uncertain ?? false,
                    ),
                  );
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<MealItem?> showMealItemDialog(BuildContext context, {MealItem? initial}) async {
  const uuid = Uuid();
  final nameController = TextEditingController(text: initial?.name ?? '');
  final quantityController = TextEditingController(
    text: initial?.quantity != null ? initial!.quantity!.toStringAsFixed(0) : '',
  );
  final unitController = TextEditingController(text: initial?.unit ?? 'g');
  final kcalController =
      TextEditingController(text: initial?.kcal != null ? initial!.kcal!.toStringAsFixed(0) : '');
  final proteinController =
      TextEditingController(text: initial?.protein != null ? initial!.protein!.toStringAsFixed(0) : '');
  final carbsController =
      TextEditingController(text: initial?.carbs != null ? initial!.carbs!.toStringAsFixed(0) : '');
  final fatController =
      TextEditingController(text: initial?.fat != null ? initial!.fat!.toStringAsFixed(0) : '');
  final noteController = TextEditingController(text: initial?.note ?? '');

  return showDialog<MealItem>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initial == null ? 'Nuovo elemento' : 'Modifica elemento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome alimento'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantita'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unita'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kcalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'kcal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Proteine'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carboidrati'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Grassi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                MealItem(
                  id: initial?.id ?? uuid.v4(),
                  name: name,
                  quantity: _parseDouble(quantityController.text),
                  unit: unitController.text.trim().isEmpty ? 'g' : unitController.text.trim(),
                  kcal: _parseDouble(kcalController.text),
                  protein: _parseDouble(proteinController.text),
                  carbs: _parseDouble(carbsController.text),
                  fat: _parseDouble(fatController.text),
                  note: noteController.text.trim(),
                  uncertain: false,
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      );
    },
  );
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

int _mealOrder(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 0;
    case MealType.snack:
      return 1;
    case MealType.lunch:
      return 2;
    case MealType.merenda:
      return 3;
    case MealType.dinner:
      return 4;
    case MealType.custom:
      return 5;
  }
}

