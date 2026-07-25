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
}
