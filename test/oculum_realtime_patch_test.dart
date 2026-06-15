import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('patch realtime cambia solo il campo modificato', () {
    final original = <String, dynamic>{
      'nome': 'Hoshy',
      'currentHp': '120',
      'inventario': [
        {'nome': 'Reliquia'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final edited = <String, dynamic>{...original, 'currentHp': '90'};

    final patch = oculumRealtimeBuildSheetPatch(original, edited);

    expect(patch, {'currentHp': '90'});
  });

  test('merge patch HP preserva immagine, inventario e note', () {
    final existing = <String, dynamic>{
      'nome': 'Player',
      'currentHp': '120',
      'notePersonaggio': 'nota locale',
      'inventario': [
        {'nome': 'Chiave'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final patch = <String, dynamic>{
      'currentHp': '80',
      'notePersonaggio': '',
      'inventario': <Map<String, dynamic>>[],
      'immaginePersonaggioBase64': '',
    };

    final merged = oculumRealtimeMergeSheetPatch(existing, patch);

    expect(merged['currentHp'], '80');
    expect(merged['notePersonaggio'], 'nota locale');
    expect(merged['inventario'], existing['inventario']);
    expect(merged['immaginePersonaggioBase64'], 'image-data');
  });

  test('merge patch inventario applica solo inventario non vuoto', () {
    final existing = <String, dynamic>{
      'currentHp': '100',
      'inventario': [
        {'nome': 'Vecchio'},
      ],
      'immaginePersonaggioBase64': 'image-data',
    };
    final patch = <String, dynamic>{
      'inventario': [
        {'nome': 'Nuovo'},
      ],
    };

    final merged = oculumRealtimeMergeSheetPatch(existing, patch);

    expect(merged['currentHp'], '100');
    expect(merged['inventario'], [
      {'nome': 'Nuovo'},
    ]);
    expect(merged['immaginePersonaggioBase64'], 'image-data');
  });

  test('fallback patch non manda campi pesanti non autorizzati', () {
    final current = <String, dynamic>{
      'currentHp': '70',
      'immaginePersonaggioBase64': 'image-data',
      'background': 'testo lungo',
      'relayServerUrl': 'server privato',
    };

    final patch = oculumRealtimeFallbackEditablePatch(current);

    expect(patch['currentHp'], '70');
    expect(patch.containsKey('immaginePersonaggioBase64'), isFalse);
    expect(patch.containsKey('background'), isFalse);
    expect(patch.containsKey('relayServerUrl'), isFalse);
  });
}
