import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'massive giant manual distinguishes catalogue bases and creation growth',
    () {
      final text = activeManualSections
          .map((section) => section.contentIt)
          .join('\n');
      expect(text, contains('Gigante Massiccio: variante distinta'));
      expect(text, contains('10–14 metri, livello consigliato 6'));
      expect(text, contains('Basi di catalogo: RES 18, VOL 10, MAT 10, OCU 5'));
      expect(
        text,
        contains(
          'alla creazione della scheda si aggiunge la crescita ordinaria',
        ),
      );
      expect(
        text,
        contains(
          'Condivide il massimo di tre bersagli e la formula Danni del Comune',
        ),
      );
      final english = activeManualSections
          .map((section) => section.contentEn)
          .join('\n');
      expect(
        english,
        contains('catalogue bases RES 18, VOL 10, MAT 10, OCU 5'),
      );
      expect(
        english,
        contains('ordinary creation growth is added to these bases'),
      );
    },
  );

  test('manuale attivo e PDF restano completi e senza testo corrotto', () async {
    expect(activeManualSections.length, oculumManualSections.length + 1);
    expect(
      activeManualSections.map((section) => section.titleIt),
      contains(
        'Aggiornamento — Costrutto Rinsecchito, Larva Bianca e cartelle',
      ),
    );
    for (final section in activeManualSections) {
      final text =
          '${section.titleIt}\n${section.contentIt}\n'
          '${section.titleEn}\n${section.contentEn}';
      expect(text, isNot(contains('Ã')));
      expect(text, isNot(contains('�')));
      expect(text, isNot(contains('â€')));
      expect(text, isNot(contains('Errante con la Sedia')));
      expect(text, isNot(contains('Chair Wanderer')));
      expect(text, isNot(contains('Errante con Ombrello')));
      expect(text, isNot(contains('Umbrella Wanderer')));
      expect(text, isNot(contains('Ragno dei Fili Giurati')));
      expect(text, isNot(contains('ciclo_ragno_fili_giurati')));
      expect(text, isNot(contains('Rondine del Respiro Lieve')));
      expect(text, isNot(contains('Viandante dei Ricordi Spenti')));
      expect(text, isNot(contains('Lepre del Fiato di Vetro')));
    }

    final bytes = await oculumBuildManualPdf(english: false);
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    const captureLabel = String.fromEnvironment('OculumBenchmarkLabel');
    final output = Directory(
      captureLabel.isEmpty
          ? 'output/pdf'
          : 'output/pdf/${captureLabel.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}',
    );
    await output.create(recursive: true);
    var dated = File(
      '${output.path}${Platform.pathSeparator}Oculum_Manuale_Regole_2026-09-05.pdf',
    );
    try {
      await dated.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      if (![32, 1224].contains(error.osError?.errorCode)) rethrow;
      dated = File(
        '${output.path}${Platform.pathSeparator}Oculum_Manuale_Regole_${DateTime.now().microsecondsSinceEpoch}.pdf',
      );
      await dated.writeAsBytes(bytes, flush: true);
    }
    expect(await dated.length(), bytes.length);
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
