import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLayoutLine {
  const OcrLayoutLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
  double get height => (bottom - top).abs();
}

class OcrScanResult {
  const OcrScanResult({
    required this.rawText,
    required this.lines,
  });

  final String rawText;
  final List<OcrLayoutLine> lines;
}

class OcrService {
  const OcrService();

  Future<OcrScanResult> extractScan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      final lines = <OcrLayoutLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) {
            continue;
          }
          final box = line.boundingBox;
          if (box == null) {
            continue;
          }
          lines.add(
            OcrLayoutLine(
              text: text,
              left: box.left.toDouble(),
              top: box.top.toDouble(),
              right: box.right.toDouble(),
              bottom: box.bottom.toDouble(),
            ),
          );
        }
      }
      lines.sort((a, b) {
        final topCmp = a.top.compareTo(b.top);
        if (topCmp != 0) {
          return topCmp;
        }
        return a.left.compareTo(b.left);
      });
      return OcrScanResult(rawText: result.text, lines: lines);
    } finally {
      await recognizer.close();
    }
  }

  Future<String> extractText(String imagePath) async {
    final result = await extractScan(imagePath);
    return result.rawText;
  }
}
