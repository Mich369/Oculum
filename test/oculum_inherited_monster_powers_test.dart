import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'write_fresh_capture.dart';

void _expectAuthoredDurafurSource(MonsterBookEntry monster) {
  expect(monster.id, 'durafur');
  expect(monster.stats['level'], 0);
  expect(monster.skillIds, ['durafur_fur_fury']);
  final art = CharacterArt.fromJson(oculumMonsterBookArt(monster).toJson());
  expect(art.skills, hasLength(1));
  final skill = art.skills.single;
  expect(skill.nome, 'Furia del Pelo Ferrigno');
  expect(skill.livello, 1);
  expect(skill.unlockRequirementsPerLevel.every((r) => r.isEmpty), isTrue);
  const bonuses = [30, 40, 60];
  for (var index = 0; index < bonuses.length; index++) {
    final form = index + 1;
    final bonus = bonuses[index];
    expect(skill.testoEvoluzione(form), '+$bonus Danni per 3 turni.');
    expect(skill.tipoPerLivello(form), 'Supporto');
    expect(skill.risorsaCostoPerLivello(form), 'nessuna');
    expect(skill.oculumMinimoPerLivello(form), 0);
    expect(skill.oculumMassimoPerLivello(form), 0);
    final effect = skill.effettiEvoluzione(form).single;
    expect(effect.type, 'modifica_statistica');
    expect(effect.target, 'danni');
    expect(effect.valueExpression, '$bonus');
    expect(effect.mode, 'temporaneo');
    expect(effect.duration, '3');
    expect(effect.recipient, 'se_stesso');
    final cooldown = skill.cooldownPerLivello[index];
    expect(cooldown.amount, 5);
    expect(cooldown.enterCombat('durafur-authored-fixture'), isTrue);
    expect(cooldown.remaining, 2);
  }
}

List<CharacterArt> _authoritativeBookArts(MonsterBookEntry monster) => [
  oculumMonsterBookArt(monster),
  if (oculumIsSoulFighter(monster.id))
    ...oculumMonsterBookAdditionalArts(monster),
];

String? _documentedPendingTechnique(MonsterBookEntry monster, ArtSkill skill) {
  final ids = switch (monster.id.split('_variante_').first) {
    oculumOblyvuardId => const [
      oculumOblyvuardSilentThreshold,
      oculumOblyvuardOblivionSlash,
    ],
    oculumCynervailId => const [oculumCynervailVeil, oculumCynervailSeal],
    _ => const <String>[],
  };
  for (final id in ids) {
    if (monsterBookConcreteTechnique(id)?.name == skill.nome) return id;
  }
  return null;
}

void main() {
  test(
    'Book Art forms have usable costs and increasing level requirements',
    () {
      for (final monster in defaultMonsterBookEntries) {
        if (monster.id.startsWith('hero_path_')) continue;
        if (monster.id == 'durafur') {
          _expectAuthoredDurafurSource(monster);
          continue;
        }
        for (final sourceArt in _authoritativeBookArts(monster)) {
          final art = CharacterArt.fromJson(sourceArt.toJson());
          for (final skill in art.skills) {
            if (oculumIsSoulFighter(monster.id)) {
              // This authored kit defines one form, not three generated
              // evolutions. Do not invent level gates or costs for its ???s.
              expect(monster.stats['level'], 0, reason: monster.id);
              expect(
                skill.unlockRequirementsPerLevel.every((r) => r.isEmpty),
                isTrue,
                reason: monster.id,
              );
              expect(skill.evo1, isNot('???'), reason: monster.id);
              expect(skill.evo2, '???', reason: monster.id);
              expect(skill.evo3, '???', reason: monster.id);
              expect(
                skill.risorsaCostoPerLivello(1),
                'oculum',
                reason: monster.id,
              );
              expect(
                skill.oculumMinimoPerLivello(1),
                greaterThan(0),
                reason: monster.id,
              );
              expect(
                skill.oculumMassimoPerLivello(1),
                greaterThanOrEqualTo(skill.oculumMinimoPerLivello(1)),
                reason: monster.id,
              );
              expect(
                skill.effettiEvoluzione(1),
                isNotEmpty,
                reason: monster.id,
              );
              expect(
                skill.cooldownPerLivello.first.amount,
                greaterThan(0),
                reason: monster.id,
              );
              continue;
            }
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
              final resource = skill.risorsaCostoPerLivello(form);
              final manualId = _documentedPendingTechnique(monster, skill);
              if (manualId != null) {
                // The zero fields are undefined authoring placeholders, not a
                // newly free or automated ability. Only these four IDs qualify.
                final technique = monsterBookConcreteTechnique(manualId)!;
                expect(
                  technique.costDescription,
                  'Costo e recupero da definire.',
                  reason: manualId,
                );
                expect(
                  text,
                  contains('Risoluzione manuale del Master'),
                  reason: manualId,
                );
                expect(
                  text,
                  contains('Costo e recupero da definire.'),
                  reason: manualId,
                );
                expect(resource, 'nessuna', reason: manualId);
                expect(skill.oculumMinimoPerLivello(form), 0, reason: manualId);
                expect(
                  skill.oculumMassimoPerLivello(form),
                  0,
                  reason: manualId,
                );
                expect(
                  skill.cooldownPerLivello[form - 1].amount,
                  0,
                  reason: manualId,
                );
              } else if (monster.id.split('_variante_').first ==
                      oculumNecthrallId &&
                  skill.nome == 'Necthbind') {
                // One Action is the authored cost. No extra resource was added.
                expect(
                  monsterBookConcreteTechnique(
                    oculumNecthrallBind,
                  )!.costDescription,
                  'Un’Azione.',
                );
                expect(text, contains('Spendi un’Azione.'));
                expect(text, contains('Volontà contro la DT del Boss'));
                expect(text, contains('fino al prossimo turno personale'));
                expect(text, contains('finché viene rotto il fuso'));
                expect(resource, 'nessuna');
                expect(skill.oculumMinimoPerLivello(form), 0);
                expect(skill.oculumMassimoPerLivello(form), 0);
                expect(skill.cooldownPerLivello[form - 1].amount, 0);
                final effect = skill.effettiEvoluzione(form).single;
                expect(effect.type, 'planar');
                expect(effect.target, oculumNecthrallBind);
                expect(effect.valueExpression, '0');
              } else if (skill
                  .effettiEvoluzione(form)
                  .any(
                    (effect) =>
                        effect.type == 'planar' &&
                        effect.target == oculumBunnysHealSkill,
                  )) {
                // Bunnys' resource payment is imposed by the selected target's
                // level; these zero fields are not a freely selected payment.
                expect(
                  skill.nome,
                  monsterBookConcreteTechnique(oculumBunnysHealSkill)!.name,
                );
                expect(
                  text,
                  contains('Costo Oculum pari al livello del bersaglio.'),
                );
                expect(resource, 'oculum');
                expect(skill.oculumMinimoPerLivello(form), 0);
                expect(skill.oculumMassimoPerLivello(form), 0);
                final effect = skill.effettiEvoluzione(form).single;
                expect(effect.valueExpression, '25');
                expect(effect.maximumTargets, 1);
                expect(effect.recipient, 'nemico');
              } else {
                final free =
                    skill.nome == 'Esplosione suicida' ||
                    (art.tipo == 'Capacità Pawn' &&
                        !skill.nome.contains(' · ')) ||
                    (monster.id == 'larva_bianca' &&
                        !skill.nome.contains(' · ')) ||
                    text.toLowerCase().contains('nessun costo') ||
                    skill.tipoPerLivello(form).toLowerCase().contains('passiv');
                expect(
                  resource,
                  free ? 'nessuna' : isNot('nessuna'),
                  reason:
                      '${monster.id}/${skill.nome}: form $form resource; $text',
                );
                expect(
                  skill.oculumMinimoPerLivello(form),
                  free ? 0 : greaterThan(0),
                  reason:
                      '${monster.id}/${skill.nome}: form $form amount; $text',
                );
              }
              expect(
                skill.oculumMassimoPerLivello(form),
                greaterThanOrEqualTo(skill.oculumMinimoPerLivello(form)),
                reason: '${monster.id}/${skill.nome}: form $form maximum',
              );
            }
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
        if (skill.effettiPerLivello.first.isEmpty ||
            !const {
              'danno',
              'difesa',
              'scudo',
              'velocita',
              'modifica_sottotratto',
              'modifica_statistica',
            }.contains(skill.effettiPerLivello.first.first.type)) {
          continue;
        }
        var previous = -1;
        for (var form = 0; form < 3; form++) {
          final value = oculumEvaluateStructuredEffectValue(
            skill.effettiPerLivello[form].first,
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
      expect(entries, hasLength(16));
      for (final monster in entries) {
        expect(monster.stats['level'], 0, reason: monster.id);
        expect(monster.spriteAssetPath, isEmpty, reason: monster.id);
        expect(monster.imageBase64, isEmpty, reason: monster.id);
        expect(
          monster.descIt,
          contains('Base di livello 0'),
          reason: monster.id,
        );
        expect(monster.skillIds, hasLength(15), reason: monster.id);
        final art = oculumMonsterBookArt(monster);
        expect(art.skills, hasLength(15), reason: monster.id);
        for (final skill in art.skills) {
          expect(
            skill.effettiPerLivello
                .take(3)
                .every((effects) => effects.isNotEmpty),
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
        final sourceArts = _authoritativeBookArts(monster);
        final soulFighter = oculumIsSoulFighter(monster.id);
        final rawStartsSelected = soulFighter || monster.id == 'durafur';
        var arts = sourceArts;
        if (rawStartsSelected) {
          final expectedNames = <String>[
            if (monster.id == 'durafur')
              'Furia del Pelo Ferrigno'
            else ...[
              'Taglio dell’Ultimo Respiro',
              'Mano della Veglia',
              'Marchio dei Senza Nome',
              if (monster.id == oculumSoulFighterEliteId) 'Anymareap',
            ],
          ];
          expect(
            sourceArts.expand((art) => art.skills).map((skill) => skill.nome),
            unorderedEquals(expectedNames),
            reason: monster.id,
          );
          final eye = <String, dynamic>{
            'rarity': 'oculum',
            'sourceMonsterId': monster.id,
            'originalArts': [for (final art in sourceArts) art.toJson()],
            'originalSkills': <Map<String, dynamic>>[],
            'sheetData': <String, dynamic>{},
          };
          oculumFallenEyeApplyInheritedPowers(eye);
          final data = eye['sheetData'] as Map<String, dynamic>;
          arts = [
            for (final raw in data['arti'] as List)
              CharacterArt.fromJson(Map<String, dynamic>.from(raw as Map)),
          ];
          expect(
            arts.map((art) => art.nome),
            sourceArts.map((art) => art.nome),
          );
          expect(
            sourceArts
                .expand((art) => art.skills)
                .every((skill) => skill.livello == 1),
            isTrue,
            reason: 'Inheritance must not rewrite authored source Arts',
          );
        }
        final allSkills = arts.expand((art) => art.skills).toList();
        expect(
          allSkills.length,
          monster.skillIds.length +
              (monster.id == oculumSoulFighterEliteId ? 1 : 0),
          reason: '${monster.id}: tecniche distribuite nelle Art autorevoli',
        );
        for (final art in arts) {
          expect(art.openAttiva, isFalse, reason: monster.id);
          for (final skill in art.skills) {
            expect(skill.livello, 0, reason: monster.id);
            expect(skill.activeTurnsRemaining, 0, reason: monster.id);
            expect(skill.nome.trim(), isNotEmpty);
            expect(skill.nome, isNot(startsWith('Pagina ')));
            if (rawStartsSelected) {
              expect(skill.evo1, isNot('???'), reason: monster.id);
              expect(
                skill.effettiEvoluzione(1),
                isNotEmpty,
                reason: monster.id,
              );
            } else {
              expect(
                skill.evo1,
                contains(RegExp(r'Richiede livello \d+')),
                reason: monster.id,
              );
            }
            expect(skill.oculumMinimoPerLivello(1), greaterThanOrEqualTo(0));
          }
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
      writeFreshCapture(
        File('output/performance/fallen-eye-snapshot.json'),
        utf8.encode(
          jsonEncode({
            'fixture': '13 references to a 1 MiB portrait, debug test',
            'jsonRoundTripMicroseconds': old.elapsedMicroseconds,
            'treeCopyMicroseconds': timer.elapsedMicroseconds,
            'note': 'Snapshot benchmark only; not overall app FPS.',
          }),
        ),
      );
    },
  );
}
