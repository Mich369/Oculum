import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  final encounters = <Map<String, dynamic>>[
    {
      'encounterId': 'first',
      'tokens': [
        {'id': 'rose'},
      ],
    },
    {
      'encounterId': 'second',
      'tokens': [
        {'id': 'slime'},
      ],
    },
    {
      'encounterId': 'merged',
      'mergedEncounterIds': ['old'],
      'tokens': [
        {'id': 'eye'},
      ],
    },
  ];
  test('sheet changes follow their own Master encounter', () {
    expect(
      oculumSelectSharedEncounter(
        encounters,
        sheetTag: 'slime',
        selectedId: 'first',
      )['encounterId'],
      'second',
    );
  });
  test('unlisted sheets do not inherit another fight', () {
    expect(
      oculumSelectSharedEncounter(
        encounters,
        sheetTag: 'outsider',
        selectedId: 'first',
      )['tokens'],
      isEmpty,
    );
  });
  test('explicit merges preserve participant selection', () {
    expect(
      oculumSelectSharedEncounter(
        encounters,
        sheetTag: 'eye',
        selectedId: 'old',
      )['encounterId'],
      'merged',
    );
  });
  test('Co-Master can inspect the selected Master encounter', () {
    expect(
      oculumSelectSharedEncounter(
        encounters,
        sheetTag: 'staff',
        selectedId: 'second',
        staff: true,
      )['encounterId'],
      'second',
    );
  });
}
