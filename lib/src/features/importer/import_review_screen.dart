import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_date_utils.dart';
import '../../core/utils/meal_icon_utils.dart';
import '../../data/models/meal.dart';
import '../../state/diet_provider.dart';
import 'models/import_draft.dart';

class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.initialDraft,
  });

  final ImportDraft initialDraft;

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  static final _uuid = Uuid();
  late List<ParsedDay> _days;
  late DateTime _baseWeekStart;

  @override
  void initState() {
    super.initState();
    _baseWeekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
    _days = widget.initialDraft.days.map(_cloneDay).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisione import'),
        actions: [
          TextButton.icon(
            onPressed: _days.isEmpty ? null : _saveImport,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salva'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _ReviewTopCard(
            baseWeekStart: _baseWeekStart,
            days: _days,
            onPickBaseWeek: _pickBaseWeek,
            onAddDay: _addDay,
          ),
          const SizedBox(height: 14),
          if (_days.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessun giorno riconosciuto. Aggiungi manualmente una bozza.'),
              ),
            ),
          ...List<Widget>.generate(_days.length, (dayIndex) {
            final day = _days[dayIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DayReviewCard(
                day: day,
                dayIndex: dayIndex,
                onEditTitle: () => _editDayTitle(dayIndex),
                onPickDate: () => _pickDayDate(dayIndex),
                onSetWeekday: (weekday) => _setDayWeekday(dayIndex, weekday),
                onDelete: () => _deleteDay(dayIndex),
                onAddMeal: () => _editMeal(dayIndex),
                onEditMeal: (mealIndex) => _editMeal(dayIndex, mealIndex: mealIndex),
                onSetMealType: (mealIndex, type) => _setMealType(dayIndex, mealIndex, type),
                onDeleteMeal: (mealIndex) => _deleteMeal(dayIndex, mealIndex),
                onAddItem: (mealIndex) => _editItem(dayIndex, mealIndex),
                onEditItem: (mealIndex, itemIndex) => _editItem(dayIndex, mealIndex, itemIndex: itemIndex),
                onSetItemQuantity: (mealIndex, itemIndex, quantity, unit) =>
                    _setItemQuantity(dayIndex, mealIndex, itemIndex, quantity, unit),
                onDeleteItem: (mealIndex, itemIndex) => _deleteItem(dayIndex, mealIndex, itemIndex),
              ),
            );
          }),
          if (widget.initialDraft.unparsedLines.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Righe non parse (${widget.initialDraft.unparsedLines.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...widget.initialDraft.unparsedLines.take(8).map((line) => Text('- $line')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  ParsedDay _cloneDay(ParsedDay day) {
    return day.copyWith(
      meals: day.meals.map(_cloneMeal).toList(),
    );
  }

  ParsedMeal _cloneMeal(ParsedMeal meal) {
    return meal.copyWith(
      items: meal.items.map((item) => item.copyWith()).toList(),
    );
  }

  Future<void> _saveImport() async {
    final draft = ImportDraft(
      rawText: widget.initialDraft.rawText,
      days: _days,
      unparsedLines: widget.initialDraft.unparsedLines,
    );
    final dayPlans = draft.toDayPlans(_baseWeekStart);
    await ref.read(dietControllerProvider.notifier).mergeImportedDays(dayPlans);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import salvato: ${dayPlans.length} giorni aggiornati')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickBaseWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _baseWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _baseWeekStart = AppDateUtils.startOfWeekMonday(picked));
    }
  }

  void _addDay() {
    setState(() {
      _days.add(
        ParsedDay(
          id: _uuid.v4(),
          label: 'Nuovo giorno',
          date: null,
          uncertain: true,
          meals: const [],
        ),
      );
    });
  }

  Future<void> _editDayTitle(int dayIndex) async {
    final controller = TextEditingController(text: _days[dayIndex].label);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Titolo giorno'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Es. Lunedi'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() {
        _days[dayIndex] = _days[dayIndex].copyWith(label: value, uncertain: false);
      });
    }
  }

  Future<void> _pickDayDate(int dayIndex) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _days[dayIndex].date ?? _baseWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _days[dayIndex] = _days[dayIndex].copyWith(
          date: picked,
          uncertain: false,
        );
      });
    }
  }

  void _setDayWeekday(int dayIndex, int weekday) {
    if (weekday < 1 || weekday > 7) {
      return;
    }
    final targetDate = _baseWeekStart.add(Duration(days: weekday - 1));
    setState(() {
      _days[dayIndex] = _days[dayIndex].copyWith(
        label: _weekdayLabel(weekday),
        date: targetDate,
        uncertain: false,
      );
    });
  }

  void _deleteDay(int dayIndex) {
    setState(() => _days.removeAt(dayIndex));
  }

  Future<void> _editMeal(int dayIndex, {int? mealIndex}) async {
    final existing = mealIndex != null ? _days[dayIndex].meals[mealIndex] : null;
    final result = await showDialog<_ParsedMealFormResult>(
      context: context,
      builder: (context) => _ParsedMealDialog(initial: existing),
    );
    if (result == null) {
      return;
    }
    setState(() {
      final meals = [..._days[dayIndex].meals];
      final meal = ParsedMeal(
        id: existing?.id ?? _uuid.v4(),
        type: result.type,
        label: result.label,
        items: existing?.items ?? const [],
        uncertain: false,
      );
      if (mealIndex == null) {
        meals.add(meal);
      } else {
        meals[mealIndex] = meal;
      }
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  void _deleteMeal(int dayIndex, int mealIndex) {
    setState(() {
      final meals = [..._days[dayIndex].meals]..removeAt(mealIndex);
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  void _setMealType(int dayIndex, int mealIndex, MealType type) {
    setState(() {
      final meals = [..._days[dayIndex].meals];
      final meal = meals[mealIndex];
      final shouldReplaceLabel =
          meal.label.trim().isEmpty || meal.uncertain || meal.label.trim() == mealTypeLabel(meal.type);
      meals[mealIndex] = meal.copyWith(
        type: type,
        label: shouldReplaceLabel ? mealTypeLabel(type) : meal.label,
        uncertain: false,
      );
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  Future<void> _editItem(int dayIndex, int mealIndex, {int? itemIndex}) async {
    final existing = itemIndex != null ? _days[dayIndex].meals[mealIndex].items[itemIndex] : null;
    final result = await showDialog<ParsedMealItem>(
      context: context,
      builder: (context) => _ParsedMealItemDialog(initial: existing),
    );
    if (result == null) {
      return;
    }
    setState(() {
      final meals = [..._days[dayIndex].meals];
      final meal = meals[mealIndex];
      final items = [...meal.items];
      if (itemIndex == null) {
        items.add(result.copyWith(id: _uuid.v4(), uncertain: false));
      } else {
        items[itemIndex] = result.copyWith(id: existing?.id, uncertain: false);
      }
      meals[mealIndex] = meal.copyWith(items: items);
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  void _deleteItem(int dayIndex, int mealIndex, int itemIndex) {
    setState(() {
      final meals = [..._days[dayIndex].meals];
      final meal = meals[mealIndex];
      final items = [...meal.items]..removeAt(itemIndex);
      meals[mealIndex] = meal.copyWith(items: items);
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  void _setItemQuantity(int dayIndex, int mealIndex, int itemIndex, double quantity, String unit) {
    setState(() {
      final meals = [..._days[dayIndex].meals];
      final meal = meals[mealIndex];
      final items = [...meal.items];
      final item = items[itemIndex];
      items[itemIndex] = item.copyWith(
        quantity: quantity,
        unit: unit,
        uncertain: false,
      );
      meals[mealIndex] = meal.copyWith(items: items);
      _days[dayIndex] = _days[dayIndex].copyWith(meals: meals);
    });
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunedi';
      case 2:
        return 'Martedi';
      case 3:
        return 'Mercoledi';
      case 4:
        return 'Giovedi';
      case 5:
        return 'Venerdi';
      case 6:
        return 'Sabato';
      case 7:
        return 'Domenica';
      default:
        return 'Giorno';
    }
  }
}

class _ReviewTopCard extends StatelessWidget {
  const _ReviewTopCard({
    required this.baseWeekStart,
    required this.days,
    required this.onPickBaseWeek,
    required this.onAddDay,
  });

  final DateTime baseWeekStart;
  final List<ParsedDay> days;
  final VoidCallback onPickBaseWeek;
  final VoidCallback onAddDay;

  @override
  Widget build(BuildContext context) {
    final uncertain = ImportDraft(rawText: '', days: days).uncertainCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controlla i campi prima del salvataggio',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Giorni: ${days.length} - Campi incerti: $uncertain'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickBaseWeek,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Settimana base ${baseWeekStart.day}/${baseWeekStart.month}'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi giorno'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayReviewCard extends StatelessWidget {
  const _DayReviewCard({
    required this.day,
    required this.dayIndex,
    required this.onEditTitle,
    required this.onPickDate,
    required this.onSetWeekday,
    required this.onDelete,
    required this.onAddMeal,
    required this.onEditMeal,
    required this.onSetMealType,
    required this.onDeleteMeal,
    required this.onAddItem,
    required this.onEditItem,
    required this.onSetItemQuantity,
    required this.onDeleteItem,
  });

  final ParsedDay day;
  final int dayIndex;
  final VoidCallback onEditTitle;
  final VoidCallback onPickDate;
  final void Function(int weekday) onSetWeekday;
  final VoidCallback onDelete;
  final VoidCallback onAddMeal;
  final void Function(int mealIndex) onEditMeal;
  final void Function(int mealIndex, MealType type) onSetMealType;
  final void Function(int mealIndex) onDeleteMeal;
  final void Function(int mealIndex) onAddItem;
  final void Function(int mealIndex, int itemIndex) onEditItem;
  final void Function(int mealIndex, int itemIndex, double quantity, String unit) onSetItemQuantity;
  final void Function(int mealIndex, int itemIndex) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final warnColor = day.uncertain ? Colors.orange.withOpacity(0.16) : Colors.transparent;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: warnColor,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEditTitle,
                    child: Row(
                      children: [
                        Text(
                          day.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onPickDate,
                  icon: Icon(day.date == null ? Icons.event_busy_outlined : Icons.event_available_outlined),
                  tooltip: 'Imposta data',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Rimuovi giorno',
                ),
              ],
            ),
            const SizedBox(height: 4),
            _ConfidenceChip(level: _confidenceForDay(day)),
            if (day.uncertain)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Campo incerto da OCR', style: TextStyle(color: Colors.orange)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _QuickFixChip(label: 'Lun', onTap: () => onSetWeekday(1)),
                _QuickFixChip(label: 'Mar', onTap: () => onSetWeekday(2)),
                _QuickFixChip(label: 'Mer', onTap: () => onSetWeekday(3)),
                _QuickFixChip(label: 'Gio', onTap: () => onSetWeekday(4)),
                _QuickFixChip(label: 'Ven', onTap: () => onSetWeekday(5)),
                _QuickFixChip(label: 'Sab', onTap: () => onSetWeekday(6)),
                _QuickFixChip(label: 'Dom', onTap: () => onSetWeekday(7)),
              ],
            ),
            const SizedBox(height: 6),
            ...List<Widget>.generate(day.meals.length, (mealIndex) {
              final meal = day.meals[mealIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: meal.uncertain
                        ? Colors.orange.withOpacity(0.12)
                        : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(mealIconFromKey(mealTypeDefaultIcon(meal.type))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onEditMeal(mealIndex),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          IconButton(
                            onPressed: () => onDeleteMeal(mealIndex),
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ConfidenceChip(level: _confidenceForMeal(meal)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _QuickFixChip(
                            label: 'Colazione',
                            onTap: () => onSetMealType(mealIndex, MealType.breakfast),
                          ),
                          _QuickFixChip(
                            label: 'Spuntino',
                            onTap: () => onSetMealType(mealIndex, MealType.snack),
                          ),
                          _QuickFixChip(
                            label: 'Pranzo',
                            onTap: () => onSetMealType(mealIndex, MealType.lunch),
                          ),
                          _QuickFixChip(
                            label: 'Cena',
                            onTap: () => onSetMealType(mealIndex, MealType.dinner),
                          ),
                        ],
                      ),
                      ...List<Widget>.generate(meal.items.length, (itemIndex) {
                        final item = meal.items[itemIndex];
                        final itemWarn = item.uncertain;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: itemWarn
                                  ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                  : const Icon(Icons.check_circle_outline, size: 18),
                              title: Text(item.name),
                              subtitle: Text(_itemText(item)),
                              trailing: Wrap(
                                spacing: 2,
                                children: [
                                  IconButton(
                                    onPressed: () => onEditItem(mealIndex, itemIndex),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                  ),
                                  IconButton(
                                    onPressed: () => onDeleteItem(mealIndex, itemIndex),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: _ConfidenceChip(level: _confidenceForItem(item)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _QuickFixChip(
                                    label: '1 pz',
                                    onTap: () => onSetItemQuantity(mealIndex, itemIndex, 1, 'pz'),
                                  ),
                                  _QuickFixChip(
                                    label: '2 pz',
                                    onTap: () => onSetItemQuantity(mealIndex, itemIndex, 2, 'pz'),
                                  ),
                                  _QuickFixChip(
                                    label: '50 g',
                                    onTap: () => onSetItemQuantity(mealIndex, itemIndex, 50, 'g'),
                                  ),
                                  _QuickFixChip(
                                    label: '100 g',
                                    onTap: () => onSetItemQuantity(mealIndex, itemIndex, 100, 'g'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => onAddItem(mealIndex),
                          icon: const Icon(Icons.add),
                          label: const Text('Aggiungi elemento'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: onAddMeal,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi pasto'),
            ),
          ],
        ),
      ),
    );
  }

  String _itemText(ParsedMealItem item) {
    final qty = item.quantity == null ? item.unit : '${item.quantity!.toStringAsFixed(0)} ${item.unit}';
    final chunks = <String>[qty.trim()];
    if (item.kcal != null) {
      chunks.add('${item.kcal!.toStringAsFixed(0)} kcal');
    }
    if (item.protein != null) {
      chunks.add('P ${item.protein!.toStringAsFixed(0)}');
    }
    if (item.carbs != null) {
      chunks.add('C ${item.carbs!.toStringAsFixed(0)}');
    }
    if (item.fat != null) {
      chunks.add('F ${item.fat!.toStringAsFixed(0)}');
    }
    if (item.note.isNotEmpty) {
      chunks.add(item.note);
    }
    if (item.alternatives.isNotEmpty) {
      final altPreview = item.alternatives
          .map((alt) => alt.quantity == null ? alt.name : '${alt.name} ${alt.quantity!.toStringAsFixed(0)} ${alt.unit}')
          .join(', ');
      chunks.add('Alternative: $altPreview');
    }
    return chunks.where((it) => it.trim().isNotEmpty).join(' - ');
  }
}

enum _ConfidenceLevel { high, medium, low }

_ConfidenceLevel _confidenceForDay(ParsedDay day) {
  if (day.uncertain) {
    return _ConfidenceLevel.low;
  }
  if (day.date == null || day.meals.isEmpty) {
    return _ConfidenceLevel.medium;
  }
  return _ConfidenceLevel.high;
}

_ConfidenceLevel _confidenceForMeal(ParsedMeal meal) {
  if (meal.uncertain) {
    return _ConfidenceLevel.low;
  }
  if (meal.items.isEmpty || meal.label.trim().isEmpty) {
    return _ConfidenceLevel.medium;
  }
  return _ConfidenceLevel.high;
}

_ConfidenceLevel _confidenceForItem(ParsedMealItem item) {
  if (item.uncertain) {
    return _ConfidenceLevel.low;
  }
  if (item.quantity == null && item.unit.trim().isEmpty) {
    return _ConfidenceLevel.medium;
  }
  return _ConfidenceLevel.high;
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.level});

  final _ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (level) {
      case _ConfidenceLevel.high:
        label = 'Confidenza: alta';
        color = Colors.green;
        break;
      case _ConfidenceLevel.medium:
        label = 'Confidenza: media';
        color = Colors.orange;
        break;
      case _ConfidenceLevel.low:
        label = 'Confidenza: bassa';
        color = Colors.redAccent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _QuickFixChip extends StatelessWidget {
  const _QuickFixChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ParsedMealFormResult {
  const _ParsedMealFormResult({
    required this.label,
    required this.type,
  });

  final String label;
  final MealType type;
}

class _ParsedMealDialog extends StatefulWidget {
  const _ParsedMealDialog({this.initial});

  final ParsedMeal? initial;

  @override
  State<_ParsedMealDialog> createState() => _ParsedMealDialogState();
}

class _ParsedMealDialogState extends State<_ParsedMealDialog> {
  late final TextEditingController _labelController;
  late MealType _type;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initial?.label ?? '');
    _type = widget.initial?.type ?? MealType.custom;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nuovo pasto' : 'Modifica pasto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Nome pasto'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<MealType>(
            value: _type,
            items: MealType.values
                .map((type) => DropdownMenuItem(value: type, child: Text(mealTypeLabel(type))))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? MealType.custom),
            decoration: const InputDecoration(labelText: 'Tipo'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _ParsedMealFormResult(label: label, type: _type),
            );
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _ParsedMealItemDialog extends StatefulWidget {
  const _ParsedMealItemDialog({this.initial});

  final ParsedMealItem? initial;

  @override
  State<_ParsedMealItemDialog> createState() => _ParsedMealItemDialogState();
}

class _ParsedMealItemDialogState extends State<_ParsedMealItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _qtyController = TextEditingController(
      text: initial?.quantity != null ? initial!.quantity!.toStringAsFixed(0) : '',
    );
    _unitController = TextEditingController(text: initial?.unit ?? 'g');
    _kcalController =
        TextEditingController(text: initial?.kcal != null ? initial!.kcal!.toStringAsFixed(0) : '');
    _proteinController =
        TextEditingController(text: initial?.protein != null ? initial!.protein!.toStringAsFixed(0) : '');
    _carbsController =
        TextEditingController(text: initial?.carbs != null ? initial!.carbs!.toStringAsFixed(0) : '');
    _fatController =
        TextEditingController(text: initial?.fat != null ? initial!.fat!.toStringAsFixed(0) : '');
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nuovo elemento' : 'Modifica elemento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantita'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitController,
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
                    controller: _kcalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'kcal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'P'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'C'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'F'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              ParsedMealItem(
                id: widget.initial?.id ?? Uuid().v4(),
                name: name,
                quantity: _parse(_qtyController.text),
                unit: _unitController.text.trim(),
                kcal: _parse(_kcalController.text),
                protein: _parse(_proteinController.text),
                carbs: _parse(_carbsController.text),
                fat: _parse(_fatController.text),
                note: _noteController.text.trim(),
                uncertain: false,
              ),
            );
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }

  double? _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}

