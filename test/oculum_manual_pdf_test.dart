import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manuale attivo e PDF restano completi e senza testo corrotto', () async {
    expect(activeManualSections, hasLength(24));
    for (final section in activeManualSections) {
      final text =
          '${section.titleIt}\n${section.contentIt}\n'
          '${section.titleEn}\n${section.contentEn}';
      expect(text, isNot(contains('Ã')));
      expect(text, isNot(contains('�')));
      expect(text, isNot(contains('â€')));
    }

    final bytes = await oculumBuildManualPdf(english: false);
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    final output = Directory('output/pdf');
    await output.create(recursive: true);
    final dated = File(
      '${output.path}${Platform.pathSeparator}Oculum_Manuale_Regole_2026-09-05.pdf',
    );
    await dated.writeAsBytes(bytes, flush: true);
    try {
      await File(
        '${output.path}${Platform.pathSeparator}Oculum_Manuale_Regole.pdf',
      ).writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      if (![32, 1224].contains(error.osError?.errorCode)) rethrow;
      // A PDF viewer may keep the previous edition mapped on Windows.
      // The dated artifact above is still the complete, verified output.
    }
  });
}
