import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('il database diario conserva testo e caratteri senza modificarli', () {
    const testo =
        'È già notte\r\nSimboli: àèìòù — “occhio” 👁️  doppio  spazio ';
    final entry = JournalEntry(
      title: 'Diario – Sessione «Ω»',
      description: testo,
      cycleDay: 7,
      phase: 'Luna piena',
      location: 'Città dell’Occhio',
      legacyPageIndex: 3,
    );

    final restored = JournalEntry.fromJson(entry.toJson());

    expect(restored.title, entry.title);
    expect(restored.description, testo);
    expect(restored.phase, entry.phase);
    expect(restored.location, entry.location);
    expect(restored.legacyPageIndex, 3);
  });

  test('le vecchie voci strutturate restano compatibili', () {
    final entry = JournalEntry.fromJson(<String, dynamic>{
      'title': 'Vecchio diario',
      'description': 'Testo originale',
      'cycleDay': 2,
      'phase': 'Alba',
      'location': 'Rovine',
      'createdAt': '2026-01-02T03:04:05.000',
    });

    expect(entry.legacyPageIndex, isNull);
    expect(entry.description, 'Testo originale');
  });

  test('backup e recupero diario partono solo dopo il primo frame', () {
    final source = File(
      'lib/src/main/oculum_home_persistence.dart',
    ).readAsStringSync();
    final loadStart = source.indexOf(
      'Future<void> caricaDati({bool allowBackupRecovery = true})',
    );
    final firstFrameReady = source.indexOf(
      "oculumProfileMark('save_load_first_frame_ready')",
      loadStart,
    );
    final maintenanceScheduled = source.indexOf(
      '_schedulePostLoadMaintenance(',
      firstFrameReady,
    );

    expect(loadStart, greaterThanOrEqualTo(0));
    expect(firstFrameReady, greaterThan(loadStart));
    expect(maintenanceScheduled, greaterThan(firstFrameReady));
    expect(
      source.substring(loadStart, firstFrameReady),
      isNot(contains('_recoverDiariesFromRecentSaves(')),
    );
    expect(
      source.substring(loadStart, firstFrameReady),
      contains('datiCaricati = true'),
    );
  });
}
