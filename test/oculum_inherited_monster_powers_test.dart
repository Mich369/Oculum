import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Book techniques have descriptive names and start inactive at form zero',
    () {
      for (final monster in defaultMonsterBookEntries) {
        final art = oculumMonsterBookArt(monster);
        expect(art.skills.length, monster.skillIds.length);
        for (final skill in art.skills) {
          expect(skill.livello, 0, reason: monster.id);
          expect(skill.nome.trim(), isNotEmpty);
          expect(skill.nome, isNot(startsWith('Pagina ')));
          expect(skill.evo1, startsWith('Richiede livello 0'));
          expect(skill.oculumMinimoPerLivello(1), greaterThanOrEqualTo(0));
        }
      }
    },
  );

  test(
    'passive skills stay equipped on load, save and attempts to unequip',
    () {
      final skill = CharacterSkill(
        nome: 'Pelle coriacea',
        tipo: 'Passiva',
        costo: '',
        cooldown: '',
        descrizione: '@Difesa+3',
      );
      expect(skill.equipaggiata, isTrue);
      skill.equipaggiata = false;
      expect(skill.equipaggiata, isTrue);
      expect(CharacterSkill.fromJson(skill.toJson()).equipaggiata, isTrue);
      skill.tipo = 'Attiva';
      expect(skill.equipaggiata, isFalse);
    },
  );

  test(
    'rarity unlocks original arts and skills without destroying customizations',
    () {
      final source = [
        for (var i = 0; i < 3; i++)
          CharacterArt(
            nome: 'Tecnica $i',
            tipo: 'Art Mostro',
            descrizione: '',
            skills: [
              ArtSkill(
                nome: 'Morso $i',
                livello: 2,
                evo1: 'Richiede livello 0\nI (1/4)',
                evo2: 'II (2/6)',
                evo3: 'III (3/8)',
              ),
            ],
          ).toJson(),
      ];
      final eye = <String, dynamic>{
        'rarity': 'comune',
        'originalArts': source,
        'originalSkills': [
          for (var i = 0; i < 3; i++) {'nome': 'Skill $i', 'tipo': 'Passiva'},
        ],
        'sheetData': <String, dynamic>{},
      };
      for (final rarity in ['comune', 'non_comune', 'raro', 'oculum']) {
        eye['rarity'] = rarity;
        oculumFallenEyeApplyInheritedPowers(eye);
        final data = eye['sheetData'] as Map;
        final arts = data['arti'] as List;
        expect(arts.length, 3);
        expect(
          arts.where((art) => art['sbloccata'] == true).length,
          oculumFallenEyeArtLimit(rarity),
        );
        expect(
          (data['skills'] as List).length,
          oculumFallenEyeArtLimit(rarity),
        );
        expect(arts.first['skills'][0]['livello'], 0);
      }
      final data = eye['sheetData'] as Map;
      data['arti'][0]['skills'][0]['evo1'] = 'La mia tecnica modificata';
      eye['rarity'] = 'comune';
      oculumFallenEyeApplyInheritedPowers(eye);
      eye['rarity'] = 'oculum';
      oculumFallenEyeApplyInheritedPowers(eye);
      expect(data['arti'][0]['skills'][0]['evo1'], 'La mia tecnica modificata');
      expect((data['skills'] as List).length, 3);
      expect(source.first['skills'][0]['livello'], 2);
    },
  );

  test(
    'snapshot copies detach mutable data without reserializing portraits',
    () {
      final portrait = 'A' * (1024 * 1024);
      final source = <String, dynamic>{
        'image': portrait,
        'items': [
          for (var i = 0; i < 12; i++) {'portrait': portrait, 'value': i},
        ],
      };
      final old = Stopwatch()..start();
      final legacy = jsonDecode(jsonEncode(source));
      old.stop();
      final timer = Stopwatch()..start();
      final copy = oculumCopyJsonTree(source) as Map;
      timer.stop();
      expect(copy, legacy);
      expect(identical(copy['image'], portrait), isTrue);
      copy['items'][0]['value'] = 99;
      expect((source['items'] as List).first['value'], 0);
      Directory('output/performance').createSync(recursive: true);
      File('output/performance/fallen-eye-snapshot.json').writeAsStringSync(
        jsonEncode({
          'fixture': '13 references to a 1 MiB portrait, debug test',
          'jsonRoundTripMicroseconds': old.elapsedMicroseconds,
          'treeCopyMicroseconds': timer.elapsedMicroseconds,
          'note': 'Snapshot benchmark only; not overall app FPS.',
        }),
      );
    },
  );
}
