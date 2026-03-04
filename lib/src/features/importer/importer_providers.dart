import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/diet_text_parser.dart';
import 'services/ocr_service.dart';

final ocrServiceProvider = Provider<OcrService>((_) => const OcrService());
final dietTextParserProvider = Provider<DietTextParser>((_) => const DietTextParser());
