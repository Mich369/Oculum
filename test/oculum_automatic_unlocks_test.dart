import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'three valid Solar Guards automatically evolve the authored lunar title, once, preserving level1 export and JSON',
    (tester) async {
      final file = File('output/characters/senka_kamaria/Senka_Kamaria.json');
      final original = file.readAsStringSync();
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = Map<String, dynamic>.from(jsonDecode(original) as Map)
        ..['id'] = p.ownerTag()
        ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      OculumTitle moon() =>
          (state.titoli as List).cast<OculumTitle>().singleWhere(
            (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
          );
      expect(moon().evoluto, false);
      Map<String, dynamic> enemy(String id, int power, {bool summon = false}) =>
          {
            'id': id,
            'monsterBookId': 'guardia_solare',
            'totalPower': power,
            'isSummon': summon,
          };
      p.recordPersonalKills(
        [
          enemy('one', 75),
          enemy('two', 75),
          enemy('weak', 74),
          enemy('summon', 100, summon: true),
        ],
        'f',
        power: 100,
      );
      expect(moon().evoluto, false);
      p.recordPersonalKills(
        [enemy('one', 75), enemy('two', 75)],
        'f',
        power: 100,
      );
      expect(moon().evoluto, false);
      p.recordPersonalKills([enemy('three', 75)], 'f', power: 100);
      expect(moon().evoluto, true);
      final saved = p.snapshot();
      p.load(saved);
      expect(moon().evoluto, true);
      expect(readIntValue(saved['livello']), 1);
      expect(file.readAsStringSync(), original);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'custom authored title goals remain intact and do not unlock at the default count',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final title = OculumTitle.fromJson({
        'nome': 'Ricordo personalizzato',
        'chiaveSistema': 'custom_lunar',
        'richiede': 'La mia richiesta',
        'buff': '@Danni+17',
        'openEffects': [
          {
            'type': 'planar',
            'target': 'senka_moon_open',
            'valueExpression': '25',
          },
        ],
      });
      state.titoli
        ..clear()
        ..add(title);
      final sheet = p.snapshot();
      final runtime = Map<String, dynamic>.from(
        sheet['planarRuntime'] as Map? ?? {},
      );
      final goal = {
        'speciesAny': ['guardia_solare'],
        'kills': 4,
      };
      runtime['authoredTitleRequirements'] = {'custom_lunar': goal};
      sheet['planarRuntime'] = runtime;
      // The production loader reads runtime from the roster entry. Importing
      // a changed sheet must replace that entry before loading its controls.
      state.schedePersonaggio[state.schedaCorrente] = sheet;
      p.load(sheet);
      expect(
        (p.planarStateSnapshot()['authoredTitleRequirements']
            as Map)['custom_lunar'],
        goal,
      );
      final enemies = [
        for (var i = 0; i < 4; i++)
          {'id': 'g$i', 'monsterBookId': 'guardia_solare', 'totalPower': 75},
      ];
      p.recordPersonalKills(enemies.take(3), 'f', power: 100);
      expect((state.titoli as List).cast<OculumTitle>().single.evoluto, false);
      expect(
        (p.planarStateSnapshot()['authoredTitleRequirements']
            as Map)['custom_lunar'],
        goal,
      );
      p.recordPersonalKills(enemies, 'f', power: 100);
      final restored = (state.titoli as List).cast<OculumTitle>().single;
      expect(restored.evoluto, true);
      expect(restored.richiede, 'La mia richiesta');
      expect(restored.buff, '@Danni+17');
      await closeFixture(tester, p);
    },
  );
  test(
    'a named Erik objective rejects anonymous elites and names, and records the real death only once',
    () {
      final anonymous = <String, dynamic>{
        'id': 'guard',
        'name': 'Erik I',
        'monsterBookId': 'guardia_solare_elite',
        'totalPower': 200,
      };
      final erik = <String, dynamic>{
        'id': 'erik-sheet',
        'canonicalNpc': 'erik_i',
        'monsterBookId': 'guardia_solare_elite',
        'totalPower': 184,
      };
      expect(
        oculumRecordNamedNpcProgressionKills({}, [anonymous], 'f', 100),
        isEmpty,
      );
      final ledger = oculumRecordNamedNpcProgressionKills(
        {},
        [anonymous, erik],
        'f',
        100,
      );
      expect((ledger['erik_i'] as Map)['count'], 1);
      expect(
        oculumRecordNamedNpcProgressionKills(ledger, [erik], 'f', 100),
        ledger,
      );
      expect(
        (oculumRecordNamedNpcProgressionKills({}, [erik], 'f', 210)['erik_i']
            as Map)['count'],
        1,
        reason: 'Erik is the explicit exception to the personal PT gate',
      );
      expect(
        oculumRecordNamedNpcProgressionKills(
          {},
          [
            {...erik, 'canonicalNpc': 'another_npc'},
          ],
          'f',
          210,
        ),
        isEmpty,
      );
      expect(
        oculumRecordPersonalProgressionKills({}, [erik], 'f', 210),
        isEmpty,
        reason: 'the exception never grants generic species kill progression',
      );
      expect(
        oculumRecordNamedNpcProgressionKills(
          {},
          [
            {...erik, 'isSummon': true},
          ],
          'f',
          100,
        ),
        isEmpty,
      );
      bool met(Map<String, int> named) => oculumSkillRequirementsMet(
        {
          'namedNpcKills': {'erik_i': 1},
        },
        level: 13,
        subtraits: {},
        kills: 100,
        elementalKills: {},
        skillCriticals: {},
        speciesKills: {'guardia_solare_elite': 100},
        namedNpcKills: named,
      );
      expect(met({}), false);
      expect(met({'erik_i': 1}), true);
    },
  );
  test(
    'personal kill progression compares each participant power, rejects summons and replays',
    () {
      final enemies = <Map>[
        {'id': 'weak', 'monsterBookId': 'guardia_solare', 'totalPower': 30},
        {'id': 'valid', 'monsterBookId': 'guardia_solare', 'totalPower': 60},
        {
          'id': 'summon',
          'monsterBookId': 'guardia_solare',
          'totalPower': 100,
          'isSummon': true,
        },
        {'id': 'unknown', 'monsterBookId': 'guardia_solare'},
      ];
      final weaker = oculumRecordPersonalProgressionKills(
        {},
        enemies,
        'fight',
        20,
      );
      final stronger = oculumRecordPersonalProgressionKills(
        {},
        enemies,
        'fight',
        56,
      );
      expect((weaker['guardia_solare'] as Map)['count'], 2);
      expect((stronger['guardia_solare'] as Map)['count'], 1);
      expect(
        oculumRecordPersonalProgressionKills(stronger, enemies, 'fight', 56),
        stronger,
      );
      expect(
        oculumRecordPersonalProgressionKills({}, enemies, 'fight', -1),
        isEmpty,
      );
    },
  );

  test(
    'the general power tolerance includes delta25 but excludes delta26 and unknown power',
    () {
      expect(oculumProgressionEnemyPowerEligible(75, 100), true);
      expect(oculumProgressionEnemyPowerEligible(74, 100), false);
      expect(oculumProgressionEnemyPowerEligible(-1, 0), false);
      expect(oculumProgressionEnemyPowerEligible(0, -1), false);
      final record = oculumRecordPersonalProgressionKills(
        {},
        [
          {
            'id': 'twentyfive',
            'monsterBookId': 'guardia_solare',
            'element': 'solare',
            'totalPower': 75,
          },
          {
            'id': 'twentysix',
            'monsterBookId': 'guardia_solare',
            'element': 'solare',
            'totalPower': 74,
          },
        ],
        'f',
        100,
      );
      expect((record['guardia_solare'] as Map)['count'], 1);
      expect(
        oculumSkillRequirementsMet(
          {
            'speciesKills': {'guardia_solare': 1},
            'element': 'solare',
            'elementKills': 1,
          },
          level: 1,
          subtraits: {},
          kills: 1,
          elementalKills: {'solare': 1},
          skillCriticals: {},
          speciesKills: {'guardia_solare': 1},
        ),
        true,
      );
    },
  );

  test(
    'item title kills accept delta25, reject delta26 and preserve authored absolute minimum power',
    () {
      InventoryItem item({int minimum = 0}) => InventoryItem(
        nome: 'Arma titolo',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        craftData: {
          'titleItem': true,
          'titleItemId': 'item',
          'titleEvolution': {
            'requiredKills': 3,
            'progress': 0,
            'minimumPower': minimum,
          },
        },
      );
      Map<String, dynamic> enemy(int power) => {
        'id': 'e$power',
        'monsterBookId': 'guardia_solare',
        'killerTag': 'owner',
        'titleItemIds': ['item'],
        'totalPower': power,
        'killerTotalPower': 100,
      };
      final ordinary = item();
      expect(
        oculumAdvanceItemTitleKills(ordinary, [enemy(75)], 'f', 'owner'),
        true,
      );
      expect(
        oculumAdvanceItemTitleKills(ordinary, [enemy(74)], 'f', 'owner'),
        false,
      );
      final absolute = item(minimum: 90);
      expect(
        oculumAdvanceItemTitleKills(absolute, [enemy(75)], 'f', 'owner'),
        false,
      );
      expect(
        oculumAdvanceItemTitleKills(absolute, [enemy(90)], 'f', 'owner'),
        true,
      );
    },
  );

  test('species, stat and grade requirements remain separate and editable', () {
    final r = {
      'grade': 1,
      'stat': 'materia',
      'statValue': 12,
      'species': 'guardia_solare',
      'speciesKills': 3,
    };
    bool met({int grade = 1, int matter = 12, int kills = 3}) =>
        oculumSkillRequirementsMet(
          r,
          level: 13,
          grade: grade,
          stats: {'materia': matter},
          subtraits: {},
          kills: 100,
          elementalKills: {},
          skillCriticals: {},
          speciesKills: {'guardia_solare': kills},
        );
    expect(met(), true);
    expect(met(grade: 0), false);
    expect(met(matter: 11), false);
    expect(met(kills: 2), false);
    expect(
      oculumSkillRequirementsMet(
        {
          'speciesKills': {'guardia_solare': 1},
        },
        level: 1,
        subtraits: {},
        kills: 1,
        elementalKills: {},
        skillCriticals: {},
        speciesKills: {'guardia_solare': 1},
      ),
      true,
    );
    expect(
      oculumSkillRequirementsMet(
        {
          'speciesKills': {'guardia_solare': 1},
        },
        level: 1,
        subtraits: {},
        kills: 100,
        elementalKills: {},
        skillCriticals: {},
        speciesKills: {},
      ),
      false,
    );
    final form = CharacterSkillForm(
      unlockRequirements: Map<String, dynamic>.from(r),
    );
    expect(CharacterSkillForm.fromJson(form.toJson()).unlockRequirements, r);
  });

  testWidgets(
    'temporary Matter does not unlock growth, attained permanent growth survives spending and JSON',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.titoli.clear();
      state.trattiRazziali.clear();
      state.arti.clear();
      state.skills.clear();
      state.inventario.clear();
      state.materiaController.text = '4';
      state.livelloController.text = '0';
      state.tempMateria = 100;
      p.invalidateDerivedCaches();
      expect(p.requirementsMet({'stat': 'materia', 'statValue': 12}), false);
      state.materiaController.text = '12';
      expect(p.requirementsMet({'stat': 'materia', 'statValue': 12}), true);
      final saved = p.snapshot();
      p.load(saved);
      state.materiaController.text = '1';
      state.tempMateria = 0;
      expect(p.requirementsMet({'stat': 'materia', 'statValue': 12}), true);
      expect(p.requirementsMet({'stat': 'materia', 'statValue': 13}), false);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'collect, possess and consume have distinct persistence and consumption preserves exact remaining mass',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.inventario.clear();
      final collect = <String, dynamic>{
        'material': 'gerin',
        'materialGrams': 150,
        'materialKind': 'collect',
      };
      final possess = {...collect, 'materialKind': 'possess'};
      final consume = {
        ...collect,
        'materialKind': 'consume',
        'consumptionKey': 'skill-a',
      };
      expect(p.requirementsMet(collect), false);
      p.progressionCollect('gerin', 150, 'mining:1');
      p.progressionCollect('gerin', 150, 'mining:1');
      expect(p.requirementsMet(collect), true);
      expect(p.requirementsMet({...collect, 'materialGrams': 151}), false);
      expect(p.requirementsMet(possess), false);
      state.inventario.add(
        InventoryItem(
          nome: 'Gerin',
          peso: .1,
          quantita: 2,
          note: '',
          craftData: {'material': 'gerin', 'grams': 100},
        ),
      );
      expect(p.requirementsMet(possess), true);
      expect(p.requirementsMet(consume), false);
      expect(p.progressionConsume(consume), true);
      final rest = (state.inventario as List).cast<InventoryItem>().single;
      expect(rest.quantita, 1);
      expect(rest.peso, .05);
      expect(rest.craftData['grams'], 50);
      expect(p.progressionConsume(consume), true);
      expect(
        rest.craftData['grams'],
        50,
        reason: 'a repeated unlock cannot consume twice',
      );
      expect(
        p.progressionConsume({...consume, 'consumptionKey': 'skill-b'}),
        false,
        reason: 'another skill needs its own real payment',
      );
      expect(p.requirementsMet(possess), false);
      expect(p.requirementsMet(collect), true);
      final saved = p.snapshot();
      p.load(saved);
      expect(p.requirementsMet(consume), true);
      expect(p.requirementsMet(collect), true);
      await closeFixture(tester, p);
    },
  );
}
