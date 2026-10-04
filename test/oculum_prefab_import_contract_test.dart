import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('shorter codes preserve full sheets and all previous formats', () {
    final sheet = oculumDecodeSheetShareText(
      File(
        'docs/chatgpt_handoff/prefab_character_generator/example_prefab_character.json',
      ).readAsStringSync(),
    ).single;
    sheet.addAll({
      'nome': 'Ève 🕯️',
      'campoFuturo': {'vuoto': '', 'zero': 0, 'falso': false, 'null': null},
      'ritrattoBase64': base64Encode(List.generate(4096, (i) => i % 256)),
      'diarioPagine': [
        {'testo': '[[Bosco Nero]] — esito incerto.'},
      ],
    });
    final previousV3Bytes = gzip.encode(
      utf8.encode(jsonEncode({'sheet': sheet})),
    );
    final previousV3 =
        'OC3:${oculumShareChecksum(previousV3Bytes)}:${base64UrlEncode(previousV3Bytes).replaceAll('=', '')}';
    final previousPayload = {
      'kind': 'oculum_sheets',
      'version': 2,
      'sheets': [sheet],
    };
    final previousV2Bytes = gzip.encode(
      utf8.encode(jsonEncode(previousPayload)),
    );
    final previousV2 =
        'OC2:${base64UrlEncode(previousV2Bytes).replaceAll('=', '')}';
    final previousV2Checked =
        'OC2:${oculumShareChecksum(previousV2Bytes)}:${base64UrlEncode(previousV2Bytes).replaceAll('=', '')}';
    final previousV1 =
        'OCULUM-SHEETS-v1:${base64UrlEncode(utf8.encode(jsonEncode(previousPayload)))}';
    final current = oculumEncodeSheetShareText([sheet]);
    expect(
      current.length,
      lessThan(previousV3.length),
      reason: 'The representative full sheet must shrink without losing data',
    );
    for (final code in [
      current,
      previousV3,
      previousV2,
      previousV2Checked,
      previousV1,
      jsonEncode(sheet),
    ]) {
      expect(oculumDecodeSheetShareText(code), [
        sheet,
      ], reason: 'Full data must survive new and legacy imports');
    }
    expect(oculumDecodeSheetShareText('$previousV1\n$current'), [sheet, sheet]);
    final damaged = current.replaceRange(
      4,
      12,
      current.substring(4, 12) == '00000000' ? 'ffffffff' : '00000000',
    );
    expect(() => oculumDecodeSheetShareText(damaged), throwsFormatException);
  });

  test('multi-sheet codes remove only transport metadata', () {
    final sheets = <Map<String, dynamic>>[
      {
        'nome': 'Hoshy',
        'inventario': [
          {'nome': 'Reliquia', 'quantita': 2},
        ],
      },
      {'nome': 'Elyra', 'currentHp': '0', 'diarioPagine': [], 'extra': null},
    ];
    final oldBytes = gzip.encode(
      utf8.encode(
        jsonEncode({
          'kind': 'oculum_sheets',
          'version': 2,
          'createdAt': '2026-10-03T18:00:00.000',
          'sheets': sheets,
        }),
      ),
    );
    final oldCode =
        'OC2:${oculumShareChecksum(oldBytes)}:${base64UrlEncode(oldBytes).replaceAll('=', '')}';
    final code = oculumEncodeSheetShareText(sheets);
    expect(code.length, lessThan(oldCode.length));
    expect(oculumDecodeSheetShareText(code), sheets);
    expect(oculumDecodeSheetShareText(oldCode), sheets);
  });

  test('future sheet fields cannot be mistaken for transport wrappers', () {
    final sheet = <String, dynamic>{
      'nome': 'Hoshy',
      'sheet': {'nome': 'Nota'},
      'sheets': [
        {'nome': 'Ricordo'},
      ],
      'schedePersonaggio': [],
    };
    expect(oculumDecodeSheetShareText(oculumEncodeSheetShareText([sheet])), [
      sheet,
    ]);
  });

  test('OC2 compatto e legacy v1 si decodificano senza perdita', () {
    final payload = <String, dynamic>{
      'kind': 'oculum_sheets',
      'version': 2,
      'sheets': [
        {'nome': 'Ève 🕯️', 'tipoScheda': 'Personaggio', 'inventario': []},
      ],
    };
    final v2 =
        'OC2:${base64UrlEncode(gzip.encode(utf8.encode(jsonEncode(payload)))).replaceAll('=', '')}';
    final v2Bytes = gzip.encode(utf8.encode(jsonEncode(payload)));
    final v2Checked =
        'OC2:${oculumShareChecksum(v2Bytes)}:${base64UrlEncode(v2Bytes).replaceAll('=', '')}';
    final v1 =
        'OCULUM-SHEETS-v1:${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';
    expect(oculumDecodeSheetShareText(v2), oculumDecodeSheetShareText(v1));
    expect(
      oculumDecodeSheetShareText(v2Checked),
      oculumDecodeSheetShareText(v1),
    );
    expect(
      () => oculumDecodeSheetShareText(
        v2Checked.replaceFirst('OC2:', 'OC2:00000000:'),
      ),
      throwsFormatException,
    );
  });

  test('OC3 singola scheda resta corto e compatibile col normalizzatore', () {
    final source = <String, dynamic>{
      'nome': 'Hoshy',
      'tipoScheda': 'Personaggio',
      'livello': '12',
      'grado': '2',
      'currentHp': '88',
      'background': 'Bosco Nero',
      'inventario': <dynamic>[],
      'diarioPagine': <dynamic>[],
      'realtimeOwnerTag': 'privato',
      'sheetTag': 'privato',
    };
    final bytes = gzip.encode(
      utf8.encode(
        jsonEncode({
          'sheet': {
            'nome': source['nome'],
            'tipoScheda': source['tipoScheda'],
            'livello': source['livello'],
            'grado': source['grado'],
            'currentHp': source['currentHp'],
            'background': source['background'],
          },
        }),
      ),
    );
    final code =
        'OC3:${oculumShareChecksum(bytes)}:${base64UrlEncode(bytes).replaceAll('=', '')}';
    final decoded = oculumDecodeSheetShareText(code);
    expect(decoded, hasLength(1));
    expect(decoded.single['nome'], 'Hoshy');
    expect(decoded.single['currentHp'], '88');
    expect(decoded.single.containsKey('realtimeOwnerTag'), isFalse);
    expect(code.length, lessThan(260));
  });

  test('il prefab ChatGPT rispetta il contratto import Oculum', () {
    final raw = File(
      'docs/chatgpt_handoff/prefab_character_generator/example_prefab_character.json',
    ).readAsStringSync();
    final sheets = oculumDecodeSheetShareText(raw);

    expect(sheets, hasLength(1));
    final sheet = sheets.single;
    expect(sheet['id'], isNull);
    expect(sheet['sheetTag'], isNull);

    final titles = (sheet['titoli'] as List).cast<Map>();
    final fateTitle = OculumTitle.fromJson(
      Map<String, dynamic>.from(titles.single),
    );
    expect(fateTitle.tipo, 'Titolo del Fato');
    expect(fateTitle.chiaveSistema, 'fate_title_1_first_art_skill_1_lvl_1');

    final traits = (sheet['trattiRazziali'] as List).cast<Map>();
    final racialTrait = OculumTitle.fromJson(
      Map<String, dynamic>.from(traits.single),
    );
    expect(racialTrait.tipo, 'Tratto Razziale');

    final arts = (sheet['arti'] as List).cast<Map>();
    final firstArt = CharacterArt.fromJson(
      Map<String, dynamic>.from(arts.first),
    );
    expect(firstArt.tipo, 'Oculum Art');
    expect(firstArt.skills, hasLength(3));
    expect(firstArt.skills.first.livello, 1);
    expect(firstArt.skills[1].livello, 0);
    expect(firstArt.skills[2].livello, 0);
    expect(firstArt.skills.first.risorsaCostoPerLivello(1), 'oculum');
    expect(firstArt.skills[1].risorsaCostoPerLivello(1), 'materia');
    expect(firstArt.skills[2].risorsaCostoPerLivello(1), 'volonta');
    expect(fateTitle.richiede, contains(firstArt.skills.first.nome));
    expect(fateTitle.richiede, contains('livello 1'));

    final restoredArt = CharacterArt.fromJson(firstArt.toJson());
    final restoredTitle = OculumTitle.fromJson(fateTitle.toJson());
    expect(restoredArt.skills.first.livello, 1);
    expect(restoredArt.skills[1].risorsaCostoPerLivello(1), 'materia');
    expect(restoredTitle.richiede, fateTitle.richiede);
  });
}
