import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'import_review_screen.dart';
import 'importer_providers.dart';
import 'models/import_draft.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _picker = ImagePicker();
  bool _isProcessing = false;
  String? _imagePath;
  ImportDraft? _draft;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importa dieta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _IntroCard(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _isProcessing ? null : () => _importFrom(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Scatta foto'),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _importFrom(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Scegli da galleria'),
              ),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(minHeight: 6),
            const SizedBox(height: 10),
            const Text('OCR e parsing in corso...'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_imagePath != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(_imagePath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 18),
            _ImportResultCard(draft: _draft!),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _openReview(_draft!),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Apri revisione import'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importFrom(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 95);
      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ritaglia dieta',
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Ritaglia dieta',
            rotateButtonsHidden: false,
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      final imagePath = cropped?.path ?? pickedFile.path;
      final ocr = await ref.read(ocrServiceProvider).extractScan(imagePath);
      final parsed = ref.read(dietTextParserProvider).parse(
            ocr.rawText,
            layoutLines: ocr.lines,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _imagePath = imagePath;
        _draft = parsed;
        _isProcessing = false;
      });
      await _openReview(parsed);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isProcessing = false;
        _error = 'Import non riuscito: $error';
      });
    }
  }

  Future<void> _openReview(ImportDraft draft) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(initialDraft: draft),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scansione on-device',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scatta o seleziona la foto del foglio dieta. L\'app usa OCR locale e parser euristico, poi ti porta alla revisione manuale.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportResultCard extends StatelessWidget {
  const _ImportResultCard({required this.draft});

  final ImportDraft draft;

  @override
  Widget build(BuildContext context) {
    final alternativesCount = draft.days
        .expand((day) => day.meals)
        .expand((meal) => meal.items)
        .fold<int>(0, (sum, item) => sum + item.alternatives.length);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risultato OCR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Giorni trovati: ${draft.days.length}'),
            Text('Alternative rilevate: $alternativesCount'),
            Text('Righe non parse: ${draft.unparsedLines.length}'),
          ],
        ),
      ),
    );
  }
}
