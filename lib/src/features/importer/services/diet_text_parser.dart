import 'package:uuid/uuid.dart';

import '../../../data/models/meal.dart';
import '../models/import_draft.dart';
import 'ocr_service.dart';

class DietTextParser {
  const DietTextParser();

  static final _uuid = Uuid();
  static final _spaces = RegExp(r'\s+');
  static final _datePattern = RegExp(r'(\d{1,2})[\/\-.](\d{1,2})(?:[\/\-.](\d{2,4}))?');
  static final _dateOnlyLinePattern = RegExp(r'^\d{1,2}[\/\-.]\d{1,2}(?:[\/\-.]\d{2,4})?$');
  static final _kcalPattern = RegExp(r'(\d+(?:[.,]\d+)?)\s*kcal', caseSensitive: false);
  static final _proteinPattern = RegExp(r'(?:\bP\b|proteine?|protein)\s*[:=]?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false);
  static final _carbsPattern = RegExp(r'(?:\bC\b|carboidrati?|carb)\s*[:=]?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false);
  static final _fatPattern = RegExp(r'(?:\bF\b|grassi?|fat)\s*[:=]?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false);
  static final _qtyWithUnitInParensPattern = RegExp(
    r'^(.+?)\s*[\(\[]\s*(\d+(?:[.,]\d+)?)\s*(g|gr|grammi|kg|ml|l|pz|pezzi|uovo|uova|fette?)\s*[\)\]]\s*(.*)$',
    caseSensitive: false,
  );
  static final _qtyWithUnitInParensAtStartPattern = RegExp(
    r'^[\(\[]\s*(\d+(?:[.,]\d+)?)\s*(g|gr|grammi|kg|ml|l|pz|pezzi|uovo|uova|fette?)\s*[\)\]]\s*(?:di\s+)?(.+)$',
    caseSensitive: false,
  );
  static final _qtyWithUnitPattern = RegExp(
    r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*(g|gr|grammi|kg|ml|l|pz|pezzi|uovo|uova|fette?)\b(.*)$',
    caseSensitive: false,
  );
  static final _qtyWithUnitAtStartPattern = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*(g|gr|grammi|kg|ml|l|pz|pezzi|uovo|uova|fette?)\s+(?:di\s+)?(.+)$',
    caseSensitive: false,
  );
  static final _qtyNoUnitPattern = RegExp(r'^(.+?)\s+(\d+(?:[.,]\d+)?)(.*)$', caseSensitive: false);
  static final _qtyNoUnitAtStartPattern = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(?:di\s+)?(.+)$',
    caseSensitive: false,
  );
  static final _qtyWordAtStartPattern = RegExp(
    r"^(un|uno|una|due|tre|quattro|cinque|sei|sette|otto|nove|dieci)\b(?:\s+|')(?:(?:di)\s+)?(.+)$",
    caseSensitive: false,
  );

  static const _numberWordMap = <String, int>{
    'un': 1,
    'uno': 1,
    'una': 1,
    'due': 2,
    'tre': 3,
    'quattro': 4,
    'cinque': 5,
    'sei': 6,
    'sette': 7,
    'otto': 8,
    'nove': 9,
    'dieci': 10,
  };

  static const _weekdayTokens = <int, List<String>>{
    1: ['lunedi', 'lun', 'monday'],
    2: ['martedi', 'mar', 'tuesday'],
    3: ['mercoledi', 'mer', 'wednesday'],
    4: ['giovedi', 'gio', 'thursday'],
    5: ['venerdi', 'ven', 'friday'],
    6: ['sabato', 'sab', 'saturday'],
    7: ['domenica', 'dom', 'sunday'],
  };

  static const _mealTokens = <MealType, List<String>>{
    MealType.breakfast: ['colazione', 'breakfast'],
    MealType.snack: ['spuntino', 'merenda', 'snack'],
    MealType.lunch: ['pranzo', 'lunch'],
    MealType.dinner: ['cena', 'dinner'],
  };

  ImportDraft parse(String rawText, {List<OcrLayoutLine>? layoutLines}) {
    final lines = _buildInputLines(rawText, layoutLines ?? const []);

    if (lines.isEmpty) {
      return const ImportDraft(rawText: '', days: []);
    }

    final days = <ParsedDay>[];
    final unparsed = <String>[];

    ParsedDay? currentDay;
    ParsedMeal? currentMeal;

    for (final line in lines) {
      final dayDetected = _detectDay(line.text);
      if (dayDetected != null) {
        currentDay = ParsedDay(
          id: _uuid.v4(),
          label: dayDetected.label,
          date: dayDetected.date,
          uncertain: dayDetected.uncertain,
        );
        days.add(currentDay);
        currentMeal = null;
        continue;
      }

      final mealDetected = _detectMeal(line.text);
      if (mealDetected != null) {
        currentDay ??= _newDraftDay();
        if (!days.any((day) => day.id == currentDay!.id)) {
          days.add(currentDay);
        }
        currentMeal = ParsedMeal(
          id: _uuid.v4(),
          type: mealDetected.type,
          label: mealDetected.label,
          uncertain: mealDetected.uncertain,
        );
        currentDay = currentDay.copyWith(meals: [...currentDay.meals, currentMeal]);
        _replaceDay(days, currentDay);
        continue;
      }

      final mainAndInlineAlternatives = _splitMainAndInlineAlternatives(line.text);
      var parsedItem = _parseMealItem(mainAndInlineAlternatives.mainText);
      if (parsedItem != null) {
        final alternatives = _parseAlternatives(
          [...line.sideAlternativeTexts, ...mainAndInlineAlternatives.inlineAlternatives],
        );
        if (alternatives.isNotEmpty) {
          parsedItem = parsedItem.copyWith(alternatives: alternatives, uncertain: false);
        }
        currentDay ??= _newDraftDay();
        if (!days.any((day) => day.id == currentDay!.id)) {
          days.add(currentDay);
        }
        currentMeal ??= ParsedMeal(
          id: _uuid.v4(),
          type: MealType.custom,
          label: 'Pasto libero',
          uncertain: true,
        );
        if (!currentDay.meals.any((meal) => meal.id == currentMeal!.id)) {
          currentDay = currentDay.copyWith(meals: [...currentDay.meals, currentMeal]);
        }
        final updatedMeal = currentMeal.copyWith(items: [...currentMeal.items, parsedItem]);
        currentMeal = updatedMeal;
        final meals = currentDay.meals.map((meal) => meal.id == updatedMeal.id ? updatedMeal : meal).toList();
        currentDay = currentDay.copyWith(meals: meals);
        _replaceDay(days, currentDay);
      } else {
        unparsed.add(line.text);
      }
    }

    if (days.isEmpty && lines.isNotEmpty) {
      days.add(
        ParsedDay(
          id: _uuid.v4(),
          label: 'Bozza importata',
          uncertain: true,
          meals: [
            ParsedMeal(
              id: _uuid.v4(),
              type: MealType.custom,
              label: 'Da rivedere',
              uncertain: true,
              items: lines
                  .map(
                    (line) => ParsedMealItem(
                      id: _uuid.v4(),
                      name: line.text,
                      unit: '',
                      uncertain: true,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    return ImportDraft(
      rawText: rawText,
      days: days,
      unparsedLines: unparsed,
    );
  }

  List<_InputLine> _buildInputLines(String rawText, List<OcrLayoutLine> layoutLines) {
    if (layoutLines.isEmpty) {
      return rawText
          .split(RegExp(r'\r?\n'))
          .map((line) => line.replaceAll(_spaces, ' ').trim())
          .where((line) => line.isNotEmpty)
          .map((text) => _InputLine(text: text))
          .toList();
    }
    return _buildInputLinesFromLayout(layoutLines);
  }

  List<_InputLine> _buildInputLinesFromLayout(List<OcrLayoutLine> layoutLines) {
    final lines = layoutLines.where((line) => line.text.trim().isNotEmpty).toList()
      ..sort((a, b) {
        final topCmp = a.top.compareTo(b.top);
        if (topCmp != 0) {
          return topCmp;
        }
        return a.left.compareTo(b.left);
      });

    if (lines.length < 4) {
      return lines.map((line) => _InputLine(text: line.text.trim())).toList();
    }

    var minLeft = lines.first.left;
    var maxRight = lines.first.right;
    for (final line in lines) {
      if (line.left < minLeft) {
        minLeft = line.left;
      }
      if (line.right > maxRight) {
        maxRight = line.right;
      }
    }
    final width = maxRight - minLeft;
    if (width < 120) {
      return lines.map((line) => _InputLine(text: line.text.trim())).toList();
    }
    final splitX = minLeft + width * 0.56;

    final leftLines = lines.where((line) => line.centerX <= splitX).toList();
    final rightLines = lines.where((line) => line.centerX > splitX).toList();
    if (leftLines.isEmpty || rightLines.isEmpty) {
      return lines.map((line) => _InputLine(text: line.text.trim())).toList();
    }

    final usedRight = <int>{};
    final output = <_InputLine>[];
    for (final left in leftLines) {
      final alternatives = <String>[];
      for (var i = 0; i < rightLines.length; i++) {
        final right = rightLines[i];
        if (usedRight.contains(i)) {
          continue;
        }
        final tolerance = left.height < 14 ? 14 : left.height * 0.85;
        if ((right.centerY - left.centerY).abs() <= tolerance) {
          alternatives.add(right.text.trim());
          usedRight.add(i);
        }
      }
      output.add(_InputLine(text: left.text.trim(), sideAlternativeTexts: alternatives));
    }

    for (var i = 0; i < rightLines.length; i++) {
      if (usedRight.contains(i)) {
        continue;
      }
      output.add(_InputLine(text: rightLines[i].text.trim()));
    }

    return output.where((line) => line.text.isNotEmpty).toList();
  }

  _MainLineSplit _splitMainAndInlineAlternatives(String text) {
    final normalizedText = _normalizeApostrophes(text).trim();
    final marker =
        RegExp(r'\b(?:oppure|in alternativa|alternativa)\b', caseSensitive: false).firstMatch(normalizedText);
    if (marker == null) {
      return _MainLineSplit(mainText: normalizedText);
    }
    final mainText = normalizedText.substring(0, marker.start).trim();
    final tail = normalizedText.substring(marker.end).trim();
    final alternatives = _splitAlternativeTexts(tail);
    return _MainLineSplit(
      mainText: mainText.isEmpty ? normalizedText : mainText,
      inlineAlternatives: alternatives,
    );
  }

  List<String> _splitAlternativeTexts(String input) {
    final clean = input.trim();
    if (clean.isEmpty) {
      return const [];
    }
    final parts = clean
        .split(
          RegExp(
            r'\s*(?:\||/|;|,|\boppure\b|\bin alternativa\b|\balternativa\b|\bo\b)\s*',
            caseSensitive: false,
          ),
        )
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts;
  }

  List<ParsedAlternativeItem> _parseAlternatives(List<String> rawAlternatives) {
    final alternatives = <ParsedAlternativeItem>[];
    final seen = <String>{};
    for (final raw in rawAlternatives) {
      final parts = _splitAlternativeTexts(raw);
      final candidates = parts.isEmpty ? [raw.trim()] : parts;
      for (final candidate in candidates) {
        final alt = _parseAlternativeItem(candidate);
        if (alt == null) {
          continue;
        }
        final key = _normalize('${alt.name}|${alt.quantity ?? ''}|${alt.unit}');
        if (seen.contains(key)) {
          continue;
        }
        seen.add(key);
        alternatives.add(alt);
      }
    }
    return alternatives;
  }

  ParsedAlternativeItem? _parseAlternativeItem(String text) {
    final item = _parseMealItem(text);
    if (item == null) {
      return null;
    }
    return ParsedAlternativeItem(
      id: _uuid.v4(),
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      note: item.note,
      uncertain: item.uncertain,
    );
  }

  ParsedDay _newDraftDay() {
    return ParsedDay(
      id: _uuid.v4(),
      label: 'Bozza OCR',
      uncertain: true,
    );
  }

  void _replaceDay(List<ParsedDay> days, ParsedDay updated) {
    for (var i = 0; i < days.length; i++) {
      if (days[i].id == updated.id) {
        days[i] = updated;
        return;
      }
    }
    days.add(updated);
  }

  _DetectedDay? _detectDay(String line) {
    final normalized = _normalize(line);

    final weekdayIndex = _detectWeekdayIndex(normalized);
    final weekdayFound = weekdayIndex != 0;
    final date = _extractDate(line);
    if (!weekdayFound && date == null) {
      return null;
    }
    if (!weekdayFound && !_dateOnlyLinePattern.hasMatch(normalized)) {
      return null;
    }
    final label = weekdayFound ? _labelFromWeekday(weekdayIndex) : line;
    final uncertain = !(weekdayFound && date != null);
    return _DetectedDay(label: label, date: date, uncertain: uncertain);
  }

  _DetectedMeal? _detectMeal(String line) {
    final normalized = _stripListPrefix(_normalize(line));
    for (final entry in _mealTokens.entries) {
      final token = entry.value.firstWhere(
        (keyword) => normalized.startsWith(keyword),
        orElse: () => '',
      );
      if (token.isNotEmpty) {
        final cleaned = line
            .replaceFirst(RegExp(r'^[\s\-\*\u2022]+'), '')
            .replaceFirst(RegExp('^$token\\s*[:\\-]?', caseSensitive: false), '')
            .trim();
        final label = cleaned.isEmpty ? mealTypeLabel(entry.key) : cleaned;
        return _DetectedMeal(type: entry.key, label: label, uncertain: false);
      }
    }
    return null;
  }

  ParsedMealItem? _parseMealItem(String line) {
    final cleanLine = _normalizeApostrophes(line).replaceAll(RegExp(r'^[\s\-\*\u2022]+'), '').trim();
    if (cleanLine.isEmpty) {
      return null;
    }

    final withUnitInParensMatch = _qtyWithUnitInParensPattern.firstMatch(cleanLine);
    final withUnitInParensAtStartMatch = _qtyWithUnitInParensAtStartPattern.firstMatch(cleanLine);
    final withUnitMatch = _qtyWithUnitPattern.firstMatch(cleanLine);
    final withUnitAtStartMatch = _qtyWithUnitAtStartPattern.firstMatch(cleanLine);
    final wordQtyAtStartMatch = _qtyWordAtStartPattern.firstMatch(cleanLine);
    String name = cleanLine;
    double? quantity;
    String unit = 'g';
    String trailing = '';
    var uncertain = false;

    if (withUnitInParensMatch != null) {
      name = withUnitInParensMatch.group(1)?.trim() ?? cleanLine;
      quantity = _toDouble(withUnitInParensMatch.group(2));
      unit = (withUnitInParensMatch.group(3) ?? 'g').toLowerCase();
      trailing = (withUnitInParensMatch.group(4) ?? '').trim();
    } else if (withUnitInParensAtStartMatch != null) {
      quantity = _toDouble(withUnitInParensAtStartMatch.group(1));
      unit = (withUnitInParensAtStartMatch.group(2) ?? 'g').toLowerCase();
      name = withUnitInParensAtStartMatch.group(3)?.trim() ?? cleanLine;
    } else if (withUnitMatch != null) {
      name = withUnitMatch.group(1)?.trim() ?? cleanLine;
      quantity = _toDouble(withUnitMatch.group(2));
      unit = (withUnitMatch.group(3) ?? 'g').toLowerCase();
      trailing = (withUnitMatch.group(4) ?? '').trim();
    } else if (withUnitAtStartMatch != null) {
      quantity = _toDouble(withUnitAtStartMatch.group(1));
      unit = (withUnitAtStartMatch.group(2) ?? 'g').toLowerCase();
      name = withUnitAtStartMatch.group(3)?.trim() ?? cleanLine;
    } else {
      final noUnitMatch = _qtyNoUnitPattern.firstMatch(cleanLine);
      final noUnitAtStartMatch = _qtyNoUnitAtStartPattern.firstMatch(cleanLine);
      if (noUnitMatch != null) {
        name = noUnitMatch.group(1)?.trim() ?? cleanLine;
        quantity = _toDouble(noUnitMatch.group(2));
        unit = '';
        trailing = (noUnitMatch.group(3) ?? '').trim();
        uncertain = true;
      } else if (noUnitAtStartMatch != null) {
        quantity = _toDouble(noUnitAtStartMatch.group(1));
        name = noUnitAtStartMatch.group(2)?.trim() ?? cleanLine;
        if (quantity != null && quantity! <= 20) {
          unit = 'pz';
          uncertain = false;
        } else {
          unit = '';
          uncertain = true;
        }
      } else if (wordQtyAtStartMatch != null) {
        quantity = _numberWordToDouble(wordQtyAtStartMatch.group(1));
        unit = 'pz';
        name = wordQtyAtStartMatch.group(2)?.trim() ?? cleanLine;
        uncertain = false;
      } else {
        uncertain = true;
      }
    }

    final kcal = _extractNumeric(_kcalPattern, cleanLine);
    final protein = _extractNumeric(_proteinPattern, cleanLine);
    final carbs = _extractNumeric(_carbsPattern, cleanLine);
    final fat = _extractNumeric(_fatPattern, cleanLine);

    if (name.length < 2) {
      return null;
    }

    return ParsedMealItem(
      id: _uuid.v4(),
      name: name,
      quantity: quantity,
      unit: unit,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      note: trailing,
      uncertain: uncertain,
    );
  }

  int _detectWeekdayIndex(String normalizedLine) {
    for (final entry in _weekdayTokens.entries) {
      final matches = entry.value.any((token) => _containsTokenAsWord(normalizedLine, token));
      if (matches) {
        return entry.key;
      }
    }
    return 0;
  }

  bool _containsTokenAsWord(String normalizedLine, String token) {
    final pattern = RegExp('(^|\\s)${RegExp.escape(token)}(\\s|\$)');
    return pattern.hasMatch(normalizedLine);
  }

  String _stripListPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[\s\-\*\u2022]+'), '');
  }

  String _normalizeApostrophes(String value) {
    return value.replaceAll('’', '\'').replaceAll('`', '\'');
  }

  String _normalize(String line) {
    return _normalizeApostrophes(line)
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ã¬', 'i')
        .replaceAll('ã©', 'e')
        .replaceAll('ã¨', 'e')
        .replaceAll('ã ', 'a')
        .replaceAll('ã²', 'o')
        .replaceAll('ã¹', 'u')
        .replaceAll(RegExp(r'[^a-z0-9/\-\. ]'), ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  DateTime? _extractDate(String text) {
    final match = _datePattern.firstMatch(text);
    if (match == null) {
      return null;
    }
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '') ?? DateTime.now().year;
    if (year < 100) {
      year = 2000 + year;
    }
    if (day == null || month == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _labelFromWeekday(int weekday) {
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

  double? _extractNumeric(RegExp pattern, String line) {
    final match = pattern.firstMatch(line);
    if (match == null) {
      return null;
    }
    return _toDouble(match.group(1));
  }

  double? _numberWordToDouble(String? value) {
    if (value == null) {
      return null;
    }
    final key = _normalize(value).trim();
    final number = _numberWordMap[key];
    return number?.toDouble();
  }

  double? _toDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.replaceAll(',', '.'));
  }
}

class _DetectedDay {
  const _DetectedDay({
    required this.label,
    required this.date,
    required this.uncertain,
  });

  final String label;
  final DateTime? date;
  final bool uncertain;
}

class _DetectedMeal {
  const _DetectedMeal({
    required this.type,
    required this.label,
    required this.uncertain,
  });

  final MealType type;
  final String label;
  final bool uncertain;
}

class _InputLine {
  const _InputLine({
    required this.text,
    this.sideAlternativeTexts = const [],
  });

  final String text;
  final List<String> sideAlternativeTexts;
}

class _MainLineSplit {
  const _MainLineSplit({
    required this.mainText,
    this.inlineAlternatives = const [],
  });

  final String mainText;
  final List<String> inlineAlternatives;
}


