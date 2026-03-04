import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/diet_plan.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_item.dart';
import '../../state/diet_provider.dart';
import '../../state/theme_controller.dart';
import '../../state/ui_preferences_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final showAdvancedDayMetrics = ref.watch(showAdvancedDayMetricsProvider);
    final planAsync = ref.watch(dietControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Errore: $error')),
        data: (plan) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _PlanCard(
                plan: plan,
                onEditName: () => _editPlanInfo(context, ref, plan),
              ),
              const SizedBox(height: 14),
              _TargetsCard(
                targets: plan.targets,
                onEdit: () => _editTargets(context, ref, plan.targets),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
                        },
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  value: showAdvancedDayMetrics,
                  title: const Text('Mostra metriche avanzate'),
                  subtitle: const Text('Mostra P/C/F e aderenza nella scheda del giorno'),
                  onChanged: (value) {
                    ref.read(showAdvancedDayMetricsProvider.notifier).setShowAdvancedDayMetrics(value);
                  },
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
                        'Export PDF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text('Genera un PDF con la dieta completa e salvalo/condividilo.'),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _exportDietPdf(context, plan),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Esporta dieta in PDF'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editPlanInfo(BuildContext context, WidgetRef ref, DietPlan plan) async {
    final nameController = TextEditingController(text: plan.name);
    final noteController = TextEditingController(text: plan.note);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Piano dieta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome piano'),
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
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salva')),
        ],
      ),
    );
    if (result == true) {
      await ref.read(dietControllerProvider.notifier).renamePlan(
            nameController.text.trim().isEmpty ? plan.name : nameController.text.trim(),
            note: noteController.text.trim(),
          );
    }
  }

  Future<void> _editTargets(BuildContext context, WidgetRef ref, MacroTargets initial) async {
    final calories = TextEditingController(text: _text(initial.calories));
    final protein = TextEditingController(text: _text(initial.protein));
    final carbs = TextEditingController(text: _text(initial.carbs));
    final fat = TextEditingController(text: _text(initial.fat));
    final water = TextEditingController(text: _text(initial.waterMl));

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obiettivi giornalieri'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calories,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Calorie target'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: protein,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Proteine (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbs,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Carboidrati (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fat,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Grassi (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: water,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Acqua (ml)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salva')),
        ],
      ),
    );

    if (shouldSave == true) {
      final targets = MacroTargets(
        calories: _parse(calories.text),
        protein: _parse(protein.text),
        carbs: _parse(carbs.text),
        fat: _parse(fat.text),
        waterMl: _parse(water.text),
      );
      await ref.read(dietControllerProvider.notifier).updateTargets(targets);
    }
  }

  Future<void> _exportDietPdf(BuildContext context, DietPlan plan) async {
    try {
      final document = pw.Document();
      final sortedDays = [...plan.days]..sort((a, b) => a.date.compareTo(b.date));
      final exportedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      document.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            margin: pw.EdgeInsets.all(28),
          ),
          build: (pw.Context context) {
            final content = <pw.Widget>[
              pw.Text(
                plan.name,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              if (plan.note.trim().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(plan.note),
              ],
              pw.SizedBox(height: 6),
              pw.Text('Export: $exportedAt'),
              pw.SizedBox(height: 14),
            ];

            if (sortedDays.isEmpty) {
              content.add(pw.Text('Nessun giorno pianificato.'));
              return content;
            }

            for (final day in sortedDays) {
              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _dayTitle(day.date),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'kcal ${day.totalKcal.toStringAsFixed(0)} - '
                        'P ${day.totalProtein.toStringAsFixed(0)} - '
                        'C ${day.totalCarbs.toStringAsFixed(0)} - '
                        'F ${day.totalFat.toStringAsFixed(0)}',
                      ),
                      if (day.meals.isEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Nessun pasto'),
                      ],
                      if (day.meals.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        ...day.meals.map(
                          (meal) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '${mealTypeLabel(meal.type)} - ${meal.label}',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                ),
                                if (meal.items.isEmpty) pw.Text('  - Nessun elemento'),
                                ...meal.items.map(
                                  (item) => pw.Text(
                                    '  - ${item.name}${_itemSuffix(item)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            return content;
          },
        ),
      );

      final bytes = await document.save();
      final filename = 'NutriTrack_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generato. Scegli dove salvarlo/condividerlo.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore export PDF: $error')),
      );
    }
  }

  String _dayTitle(DateTime date) {
    const weekdays = <String>[
      'Lunedi',
      'Martedi',
      'Mercoledi',
      'Giovedi',
      'Venerdi',
      'Sabato',
      'Domenica',
    ];
    const months = <String>[
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month ${date.year}';
  }

  String _itemSuffix(MealItem item) {
    final qty = item.quantity == null ? '' : ' ${item.quantity!.toStringAsFixed(0)} ${item.unit}';
    final kcal = item.kcal == null ? '' : ' (${item.kcal!.toStringAsFixed(0)} kcal)';
    return '$qty$kcal';
  }

  String _text(double? value) => value == null ? '' : value.toStringAsFixed(0);

  double? _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onEditName,
  });

  final DietPlan plan;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(onPressed: onEditName, icon: const Icon(Icons.edit_outlined)),
              ],
            ),
            if (plan.note.isNotEmpty) Text(plan.note),
          ],
        ),
      ),
    );
  }
}

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({
    required this.targets,
    required this.onEdit,
  });

  final MacroTargets targets;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    String value(double? v, String suffix) => v == null ? '-' : '${v.toStringAsFixed(0)} $suffix';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Obiettivi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifica'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Calorie: ${value(targets.calories, 'kcal')}'),
            Text('Proteine: ${value(targets.protein, 'g')}'),
            Text('Carboidrati: ${value(targets.carbs, 'g')}'),
            Text('Grassi: ${value(targets.fat, 'g')}'),
            Text('Acqua: ${value(targets.waterMl, 'ml')}'),
          ],
        ),
      ),
    );
  }
}
