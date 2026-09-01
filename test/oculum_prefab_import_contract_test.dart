import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
