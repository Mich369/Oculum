import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

List<Map<String, dynamic>> sourceArts() => [
  for (var i = 0; i < 3; i++)
    CharacterArt(
      nome: 'Art originale $i',
      tipo: 'Art Mostro',
      descrizione: 'Tecniche del mostro vivo',
      skills: [
        ArtSkill(
          nome: 'Tecnica reale $i',
          livello: 1,
          evo1: 'Richiede livello 0. Costa 3 Materia. Difesa +5.',
          evo2: 'Richiede livello 2. Costa 4 Materia. Difesa +8.',
          evo3: 'Richiede livello 4. Costa 5 Materia. Difesa +11.',
          risorseCostoPerLivello: List.filled(5, 'materia'),
          oculumMinimiPerLivello: [3, 4, 5, 0, 0],
          oculumMassimiPerLivello: [3, 4, 5, 0, 0],
          oculumLimitiManualiPerLivello: List.filled(5, true),
          tipiPerLivello: List.filled(5, 'Difesa'),
          cooldownPerLivello: [
            for (var j = 0; j < 5; j++) OculumAbilityCooldown(amount: 2),
          ],
          effettiPerLivello: [
            for (final amount in [5, 8, 11, 0, 0])
              [
                OculumStructuredEffect(
                  type: 'difesa',
                  valueExpression: '$amount',
                  recipient: 'se_stesso',
                  duration: '1',
                ),
              ],
          ],
        ),
      ],
    ).toJson(),
];

void main() {
  test(
    'Art Skill inheritance retains real forms, costs and effects for every rarity without replacing user edits',
    () {
      final arts = sourceArts();
      final eye = <String, dynamic>{
        'sourceMonsterId': 'custom_monster',
        'rarity': 'comune',
        'originalArts': oculumCopyJsonTree(arts),
        'originalSkills': [for (final art in arts) ...(art['skills'] as List)],
        'sheetData': <String, dynamic>{},
      };
      for (final rarity in ['comune', 'non_comune', 'raro', 'oculum']) {
        eye['rarity'] = rarity;
        oculumFallenEyeApplyInheritedPowers(eye);
        final data = eye['sheetData'] as Map;
        final activeArts = (data['arti'] as List).where(
          (a) => a['sbloccata'] == true,
        );
        expect(activeArts.length, oculumFallenEyeEffectiveArtLimit(eye));
        final skill = CharacterSkill.fromJson(
          Map<String, dynamic>.from((data['skills'] as List).first as Map),
        );
        expect(skill.forme, hasLength(3));
        for (var i = 0; i < 3; i++) {
          final form = skill.forme[i];
          expect(form.costoStrutturato!.resource, 'materia');
          expect(form.costoStrutturato!.minimum, 3 + i);
          expect(form.costoStrutturato!.maximum, 3 + i);
          expect(form.cooldownStrutturato!.amount, 2);
          expect(
            form.effettiStrutturati.single.valueExpression,
            '${5 + 3 * i}',
          );
          expect(form.descrizione, isNotEmpty);
        }
      }
      final data = eye['sheetData'] as Map;
      final raw = (data['skills'] as List).first as Map;
      (raw['forme'] as List).first['costoStrutturato']['minimum'] = 7;
      (raw['forme'] as List).first['effettiStrutturati'][0]['valueExpression'] =
          '99';
      final restored = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(eye)) as Map,
      );
      oculumFallenEyeApplyInheritedPowers(restored);
      final custom = CharacterSkill.fromJson(
        Map<String, dynamic>.from(
          (restored['sheetData']['skills'] as List).first as Map,
        ),
      );
      expect(custom.forme.first.costoStrutturato!.minimum, 7);
      expect(
        custom.forme.first.effettiStrutturati.single.valueExpression,
        '99',
      );
      expect(arts.first['skills'][0]['livello'], 1);
    },
  );
  test('ordinary CharacterSkill JSON is preserved without Art conversion', () {
    final original = CharacterSkill(
      nome: 'Morso naturale',
      tipo: 'Attacco',
      costo: '2 Materia',
      cooldown: '3 turni',
      descrizione: 'Tecnica naturale',
      forme: [
        CharacterSkillForm(
          nome: 'Morso',
          tipo: 'Attacco',
          costo: '2 Materia',
          costoStrutturato: OculumSkillCost(
            resource: 'materia',
            minimum: 2,
            maximum: 2,
            amountExpression: '2',
          ),
          effettiStrutturati: [
            OculumStructuredEffect(type: 'danno', valueExpression: '9'),
          ],
        ),
      ],
    ).toJson();
    expect(oculumFallenEyeInheritedSkill(original), original);
  });
  testWidgets(
    'actual creature body preserves Velo and combat stats independently of the original source',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      final source = p.snapshot()
        ..['monsterBookSourceId'] = 'custom_monster'
        ..['resilienza'] = '10'
        ..['volonta'] = '20'
        ..['materia'] = '30'
        ..['oculum'] = '40'
        ..['hiddenEyeStats'] = [
          {'id': 'velo', 'nome': 'Velo', 'valore': 17},
        ]
        ..['difesaRapida'] = '7'
        ..['vcRapido'] = '4'
        ..['fortuna'] = 3
        ..['manualHpMaximumAdjustment'] = -10;
      final body = p.fallenEyeBodyFromSource(source);
      expect(body['resilienza'], '10');
      expect(body['volonta'], '20');
      expect(body['materia'], '30');
      expect(body['oculum'], '40');
      expect(body['hiddenEyeStats'][0]['valore'], 17);
      expect(body['difesaRapida'], '7');
      expect(body['vcRapido'], '4');
      expect(body['fortuna'], 3);
      expect(body['manualHpMaximumAdjustment'], -10);
      body['hiddenEyeStats'][0]['valore'] = 18;
      expect(source['hiddenEyeStats'][0]['valore'], 17);
      final restored = jsonDecode(jsonEncode(body)) as Map;
      expect(restored['hiddenEyeStats'][0]['valore'], 18);
      await closeFixture(tester, p);
    },
  );
}
