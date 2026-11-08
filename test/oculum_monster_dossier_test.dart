import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'reading costs and prose preserve forms, custom JSON and canonical mechanics',
    () {
      final red = monsterById('uomo_maschera_rossa')!;
      final skill = oculumMonsterBookArt(red).skills.first;
      final before = jsonEncode(skill.toJson());
      expect(oculumMonsterReadingCost(skill, 1), 'Nessun costo statistico');
      expect(
        oculumMonsterOverview(red),
        isNot(contains('Skill per il giocatore:')),
      );
      expect(
        oculumMonsterReadableProse('I/@vol-3; forme II/III; hp_current'),
        'Volontà-3; forme II/III; Vita attuale',
      );
      expect(
        monsterBookSkillText('masked_oculum_shield'),
        isNot(contains('mask_violet')),
      );
      expect(
        oculumStructuredEffectDescription(
          OculumStructuredEffect(
            type: 'planar',
            valueExpression: '1',
            narrativeText: 'Scatto gratuito con una Reazione veloce.',
          ),
        ),
        'Scatto gratuito con una Reazione veloce.',
      );
      expect(jsonEncode(skill.toJson()), before);
      final hidden = red.copyWith(
        descIt: 'Un mantello rosso. Punto debole: la nuca. Combatte a pugni.',
      );
      expect(
        oculumMonsterOverview(hidden, weakPointKnown: false),
        isNot(contains('la nuca')),
      );
      expect(hidden.descIt, contains('la nuca'));
    },
  );

  test(
    'party drop knowledge records only delivered items for the exact entry',
    () {
      final monster = monsterById('costrutto_rinsecchito')!;
      final variant = monsterById('costrutto_rinsecchito_variante_corazzata')!;
      final chest = <String, dynamic>{};
      final drops = oculumGenerateMonsterLoot(
        monster: monster,
        level: 0,
        grade: 0,
        random: Random(1),
        killId: 'confirmed-fight',
        naturalDropRoll: 18,
        dropTotal: 30,
      );
      final core = drops.firstWhere(
        (item) => item.nome == 'Nucleo rotto debole',
      );
      final knownBefore = oculumPartyKnownMonsterDropIds(chest, monster.id);
      expect(knownBefore, isEmpty);
      expect(
        oculumMonsterBookDropLabel(
          monster,
          'cuore_rami_rinsecchiti',
          knownDropIds: knownBefore,
        ),
        '???',
      );
      expect(
        oculumMonsterBookDropLabel(monster, 'cuore_rami_rinsecchiti'),
        endsWith(' · 3% a DT Drop raggiunta'),
      );
      expect(
        oculumRecordDeliveredMonsterDrops(chest, [
          {'nome': 'Cuore Rami Rinsecchiti', 'quantita': 1},
          core.toJson(),
        ]),
        isTrue,
      );
      expect(
        oculumRecordDeliveredMonsterDrops(chest, [core.toJson()]),
        isFalse,
      );
      final restored = jsonDecode(jsonEncode(chest)) as Map;
      final known = oculumPartyKnownMonsterDropIds(restored, monster.id);
      expect(known, {'nucleo_rotto_debole'});
      expect(oculumPartyKnownMonsterDropIds(restored, variant.id), isEmpty);
      expect(
        oculumMonsterBookDropLabel(
          monster,
          'nucleo_rotto_debole',
          knownDropIds: known,
        ),
        'Nucleo Rotto Debole · Garantito a DT Drop raggiunta',
      );
      final described = monster.copyWith(
        descIt: 'Un costrutto. Drop: rami rinsecchiti.',
      );
      expect(
        oculumMonsterOverview(described, knownDropIds: known),
        'Un costrutto.',
      );
      expect(oculumMonsterOverview(described), contains('rami rinsecchiti'));
    },
  );

  test('drop labels distinguish conditional percentages and natural rolls', () {
    final sharp = monsterById('sharp')!;
    expect(
      oculumMonsterBookDropLabel(sharp, 'dente_sharp'),
      endsWith('45% (12+ naturale)'),
    );
    expect(
      oculumMonsterBookDropLabel(sharp, 'dente_sharp', dropBonus: -100),
      endsWith('45% (12+ naturale)'),
    );
    expect(
      oculumMonsterBookDropLabel(
        sharp,
        'dente_sharp',
        knownDropIds: {'scarti_metallici'},
      ),
      '???',
    );
    final ordinary = sharp.copyWith(
      id: 'ordinary_drop_test',
      dropIds: ['materiale_a', 'materiale_b'],
      dropChances: {'materiale_b': 60},
    );
    expect(
      oculumMonsterBookDropLabel(ordinary, 'materiale_a'),
      endsWith('35% a DT Drop raggiunta'),
    );
    expect(
      oculumMonsterBookDropLabel(ordinary, 'materiale_b'),
      endsWith('60% a DT Drop raggiunta'),
    );
    expect(
      oculumMonsterBookDropLabel(
        monsterById('fata_cacciatrice')!,
        'mezza_ala_fata',
      ),
      endsWith('Garantito con totale Drop ≥50 e DT raggiunta'),
    );
  });

  test(
    'a nominal d20 can make a drop impossible before the percentage roll',
    () {
      final monster = monsterById('sharp')!.copyWith(
        id: 'ordinary_dt_40',
        stats: {'level': 20, 'grade': 0},
        dropIds: ['materiale'],
      );
      final bonus = oculumEncounterDropBonus({
        'livello': '7',
        'difficoltaTiro': '2',
        'hiddenEyeStats': [
          {'id': 'drop', 'valore': 14},
        ],
      });
      expect(bonus, 19);
      expect(
        oculumMonsterBookDropLabel(monster, 'materiale', dropBonus: bonus),
        endsWith('Impossibile senza critico (0%)'),
      );
      expect(
        oculumMonsterBookDropLabel(monster, 'materiale', dropBonus: 20),
        endsWith('≈1,75%'),
      );
      expect(
        oculumMonsterBookDropLabel(monster, 'materiale', dropBonus: 39),
        endsWith('≈35%'),
      );
    },
  );

  test('pending encounter chest loot is known only after promotion', () {
    final chest = <String, dynamic>{
      'pendingLoot': [
        {
          'id': 'historical-receipt',
          'item': {
            'nome': 'Dente di Sharp',
            'peso': 0.1,
            'quantita': 1,
            'monsterLoot': {'id': 'old-fight:tooth', 'monsterId': 'sharp'},
          },
        },
      ],
    };
    oculumPromotePendingChestLoot(chest);
    expect(oculumPartyKnownMonsterDropIds(chest, 'sharp'), isEmpty);
    chest['members'] = {
      'ally': {'level': 0},
    };
    oculumPromotePendingChestLoot(chest);
    expect(oculumPartyKnownMonsterDropIds(chest, 'sharp'), {'dente_sharp'});
  });

  testWidgets(
    'monster dossier separates skills, Open, forms and drops on phone and desktop',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
        final dynamic state = await fixtures.mountSheet(tester, size);
        state.datiCaricati = false;
        final probe = OculumPerformanceProbe(state);
        final monster = monsterById('uomo_maschera_rossa')!;
        final overlay = OverlayEntry(
          builder: (_) => Positioned.fill(
            child: Material(
              color: const Color(0xff101219),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: probe.monsterDossier(monster),
                ),
              ),
            ),
          ),
        );
        Overlay.of(tester.element(find.byType(OculumHomePage))).insert(overlay);
        await tester.pump();
        expect(find.text('Aspetto'), findsOneWidget);
        expect(find.text('Comportamento e particolarità'), findsOneWidget);
        await tester.ensureVisible(find.text('Pugno serio'));
        await tester.tap(find.text('Pugno serio'));
        await tester.pump(const Duration(milliseconds: 300));
        for (final form in ['I', 'II', 'III']) {
          expect(find.text('Forma $form'), findsOneWidget);
        }
        expect(find.text('Costo: Nessun costo statistico'), findsNWidgets(3));
        expect(find.text('Buff Open'), findsOneWidget);
        expect(find.text('Skill Open'), findsOneWidget);
        expect(find.text('Drop e ricompense'), findsOneWidget);
        expect(tester.takeException(), isNull);
        overlay.remove();
        overlay.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
      }
    },
  );
}
