import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('stress save preserves many sheets and unknown legacy fields', () {
    final sheets = List<Map<String, dynamic>>.generate(1500, (sheetIndex) {
      return <String, dynamic>{
        'id': 'sheet_$sheetIndex',
        'nome': 'Scheda $sheetIndex',
        'currentHp': '${30 + sheetIndex}',
        'legacyUnknownField': <String, dynamic>{
          'source': 'legacy_$sheetIndex',
          'nested': List<int>.generate(12, (index) => sheetIndex + index),
        },
        'inventario': List<Map<String, dynamic>>.generate(
          20,
          (index) => <String, dynamic>{
            'nome': 'Oggetto $index',
            'quantita': index + 1,
            'unknownItemValue': 'keep_${sheetIndex}_$index',
          },
        ),
      };
    });
    final payload = <String, dynamic>{
      'saveVersion': 1,
      'multiScheda': true,
      'schedePersonaggio': sheets,
      'unknownTopLevel': <String, dynamic>{'mustSurvive': true},
    };

    final watch = Stopwatch()..start();
    final restored = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    watch.stop();

    final restoredSheets = restored['schedePersonaggio'] as List<dynamic>;
    expect(restoredSheets, hasLength(1500));
    expect(
      (restored['unknownTopLevel'] as Map<String, dynamic>)['mustSurvive'],
      isTrue,
    );
    expect(
      ((restoredSheets[1499] as Map<String, dynamic>)['legacyUnknownField']
          as Map<String, dynamic>)['source'],
      'legacy_1499',
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('stress parser handles a large active command catalogue', () {
    const variables = <String, num>{
      'resilienza': 12,
      'volonta': 9,
      'materia': 7,
      'oculum': 5,
      'livello': 20,
      'grado': 4,
    };
    final texts = List<String>.generate(
      5000,
      (index) =>
          '@Danni+${index % 17} Fuoco @Difesa+${index % 11} Fisico @Resilienza+Materia/2',
    );

    final watch = Stopwatch()..start();
    var commandCount = 0;
    for (final text in texts) {
      commandCount += oculumParseFormulaCommands(text, variables).length;
    }
    watch.stop();

    expect(commandCount, greaterThanOrEqualTo(texts.length * 3));
    expect(watch.elapsed, lessThan(const Duration(seconds: 15)));
  });
}
