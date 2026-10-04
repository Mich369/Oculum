import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'Book Art forms have usable costs and increasing level requirements',
    () {
      for (final monster in defaultMonsterBookEntries) {
        if (monster.id.startsWith('hero_path_')) continue;
        final art = CharacterArt.fromJson(
          oculumMonsterBookArt(monster).toJson(),
        );
        for (final skill in art.skills) {
          var previousRequirement = -1;
          for (var form = 1; form <= 3; form++) {
            final text = skill.testoEvoluzione(form);
            final requirement = int.parse(
              RegExp(
                r'Richiede livello (\d+)',
                caseSensitive: false,
              ).firstMatch(text)!.group(1)!,
            );
            expect(
              requirement,
              greaterThanOrEqualTo(previousRequirement),
              reason: '${monster.id}/${skill.nome}: form $form level',
            );
            previousRequirement = requirement;
            expect(
              skill.oculumMinimoPerLivello(form),
              greaterThan(0),
              reason: '${monster.id}/${skill.nome}: form $form cost; $text',
            );
            expect(
              skill.oculumMassimoPerLivello(form),
              greaterThanOrEqualTo(skill.oculumMinimoPerLivello(form)),
              reason: '${monster.id}/${skill.nome}: form $form maximum',
            );
          }
        }
      }
    },
  );
  test('Generated offense and defense become stronger at each evolution', () {
    for (final monster in defaultMonsterBookEntries.where(
      (monster) => monster.id.startsWith('generated_'),
    )) {
      final art = oculumMonsterBookArt(monster);
      for (final skill in art.skills) {
        if (skill.effettiPerLivello.first.isEmpty) continue;
        var previous = -1;
        for (var form = 0; form < 3; form++) {
          final value = oculumEvaluateStructuredEffectValue(
            skill.effettiPerLivello[form].single,
            variables: {'danni': 10},
            spentResources: {'oculum': 4},
          );
          expect(
            value,
            greaterThan(previous),
            reason: '${monster.id}/${skill.nome}: evolution ${form + 1}',
          );
          previous = value;
        }
      }
    }
  });
  test(
    'Reference creatures have level zero descriptions, stats and three Arts',
    () {
      final entries = defaultMonsterBookEntries
          .where(
            (monster) =>
                monster.id.startsWith('inspired_') &&
                !monster.id.contains('_variante_'),
          )
          .toList();
      expect(entries, hasLength(11));
      for (final monster in entries) {
        expect(monster.stats['level'], 0, reason: monster.id);
        expect(monster.spriteAssetPath, isEmpty, reason: monster.id);
        expect(monster.imageBase64, isEmpty, reason: monster.id);
        expect(monster.descIt, contains('Base di livello 0'), reason: monster.id);
        expect(monster.skillIds, hasLength(3), reason: monster.id);
        final art = oculumMonsterBookArt(monster);
        expect(art.skills, hasLength(3), reason: monster.id);
        for (final skill in art.skills) {
          expect(
            skill.effettiPerLivello.take(3).every((effects) => effects.isNotEmpty),
            isTrue,
            reason: '${monster.id}/${skill.nome}',
          );
        }
      }
    },
  );
  test(
    'Book techniques have descriptive names and start inactive at form zero',
    () {
      for (final monster in defaultMonsterBookEntries) {
        final art = oculumMonsterBookArt(monster);
        expect(
          art.skills.length,
          monster.skillIds.length,
          reason:
              '${monster.id}: le tecniche generate devono rispettare il Book',
        );
        for (final skill in art.skills) {
          expect(skill.livello, 0, reason: monster.id);
          expect(skill.nome.trim(), isNotEmpty);
          expect(skill.nome, isNot(startsWith('Pagina ')));
          expect(
            skill.evo1,
            contains(RegExp(r'Richiede livello \d+')),
            reason: monster.id,
          );
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
