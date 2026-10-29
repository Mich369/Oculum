import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

OculumTitle _title({String name = 'Titolo', String type = 'Standard'}) =>
    OculumTitle(
      nome: name,
      tipo: type,
      ottenimento: '',
      buff: '',
      puntoCieco: '',
      skill: '',
      richiede: '',
      evoluto: true,
      equipaggiato: true,
      openName: 'Open $name',
      openBuff: '@danni+5',
    );

void main() {
  testWidgets(
    'unequipping a renamed Title removes its persistent Open effect and keeps Skill boost',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final title = _title()
        ..openEffects.add(
          OculumStructuredEffect(
            id: 'persistent-defense',
            type: 'difesa',
            valueExpression: '7',
            duration: '1',
          ),
        );
      state.titoli.add(title);
      p.useTitleOpen(title);
      expect(p.activeEffectBonus('difesa'), 7);
      title.nome = 'Titolo rinominato';
      title.openName = 'Open rinominata';
      title.equipaggiato = false;
      p.normalizeOpenCycles();
      expect(p.activeEffectBonus('difesa'), 0);
      expect(title.openAttiva, false);
      expect(title.openLifecycle['buffActive'], false);
      expect(title.openUsedSinceLongRest, true);
      expect(p.titleOpenBoost(title), true);
      p.tickOpenRest(longRest: true);
      p.tickOpenRest(longRest: true);
      expect(p.activeEffectBonus('difesa'), 0);
      expect(title.openUsedSinceLongRest, false);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'normalizing restored concurrent Open removes the losing Buff by stable ID',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final first = _title(name: 'Primo'), second = _title(name: 'Secondo');
      state.titoli.addAll([first, second]);
      p.useTitleOpen(first);
      second.openLifecycle = (OculumOpenLifecycleProgress(
        id: 'conflicting-cycle',
      )..activate()).toJson();
      second.openAttiva = true;
      second.openUsedSinceLongRest = true;
      second.openName = 'Nome cambiato dopo il salvataggio';
      state.activeStructuredEffects.add(<String, dynamic>{
        'source': 'Vecchio nome',
        'type': 'difesa',
        'target': 'difesa',
        'value': 11,
        'mode': 'finche_attivo',
        'remaining': -1,
        'unit': 'open_lifecycle',
        'openLifecycleId': 'conflicting-cycle',
      });
      expect(p.activeEffectBonus('difesa'), 11);
      p.normalizeOpenCycles();
      expect(p.activeEffectBonus('difesa'), 0);
      expect(first.openAttiva, true);
      expect(second.openAttiva, false);
      expect(second.openLifecycle['buffActive'], false);
      expect(p.titleOpenBoost(second), true);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'recovering an Art clears orphaned Buff effects even when its raw flag was already off',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final art = CharacterArt(
        nome: 'Art rinominata',
        tipo: 'Elementale',
        descrizione: '',
        skills: [],
        openLifecycle: (OculumOpenLifecycleProgress(
          id: 'orphaned-art',
        )..activate()).toJson(),
      );
      state.arti.add(art);
      state.activeStructuredEffects.add(<String, dynamic>{
        'source': 'Vecchio nome Art',
        'type': 'difesa',
        'target': 'difesa',
        'value': 9,
        'mode': 'finche_attivo',
        'remaining': -1,
        'unit': 'open_lifecycle',
        'openLifecycleId': 'orphaned-art',
      });
      p.tickOpenRest(longRest: true);
      expect(p.activeEffectBonus('difesa'), 9);
      p.tickOpenRest(longRest: true);
      expect(p.activeEffectBonus('difesa'), 0);
      expect(p.artOpenBoost(art), true);
      await closeFixture(tester, p);
    },
  );
  test('one Long Rest never recovers a newly activated Open', () {
    final cycle = OculumOpenLifecycleProgress(id: 'one');
    expect(cycle.activate(), true);
    expect(cycle.activate(), false);
    cycle.rest(longRest: true);
    expect(cycle.ready, false);
    expect(cycle.buffActive, true);
    cycle.rest(longRest: true);
    expect(cycle.ready, true);
    expect(cycle.buffActive, false);
    expect(
      cycle.skillEmpowered,
      true,
      reason: 'Skill boost has its independent duration',
    );
  });

  for (final order in ['LSSS', 'SSSL', 'SLSS']) {
    test('normal Open recovers at 1 Long plus 3 Short in order $order', () {
      final cycle = OculumOpenLifecycleProgress(id: 'normal')..activate();
      for (var i = 0; i < order.length; i++) {
        cycle.rest(longRest: order[i] == 'L');
        expect(cycle.ready, i == order.length - 1);
      }
      expect(cycle.buffActive, false);
      expect(cycle.skillEmpowered, false);
    });
  }

  for (final order in ['LSS', 'SSL', 'SLS']) {
    test('Fate Open recovers at 1 Long plus 2 Short in order $order', () {
      final cycle = OculumOpenLifecycleProgress(id: 'fate')..activate();
      for (var i = 0; i < order.length; i++) {
        cycle.rest(longRest: order[i] == 'L', fate: true);
        expect(cycle.ready, i == order.length - 1);
      }
      expect(cycle.buffActive, false);
      expect(cycle.skillEmpowered, false);
    });
  }

  test(
    'Skill boost ends at two Short and one Long before normal Open recovery',
    () {
      final cycle = OculumOpenLifecycleProgress(id: 'separate')..activate();
      cycle.rest(longRest: false);
      cycle.rest(longRest: true);
      expect(cycle.skillEmpowered, true);
      cycle.rest(longRest: false);
      expect(cycle.skillEmpowered, false);
      expect(cycle.ready, false);
      expect(cycle.buffActive, true);
    },
  );

  test(
    'three concluded fight receipts end only the Skill boost and ignore replays',
    () {
      final cycle = OculumOpenLifecycleProgress(id: 'fights')..activate();
      expect(cycle.completeFight('one'), true);
      expect(cycle.completeFight('one'), false);
      cycle.completeFight('two');
      expect(cycle.skillEmpowered, true);
      cycle.completeFight('three');
      expect(cycle.skillEmpowered, false);
      expect(cycle.used, true);
      expect(cycle.buffActive, true);
      expect(cycle.completedFightIds, hasLength(3));
    },
  );

  test(
    'legacy spent flags migrate without inventing elapsed rests or free power',
    () {
      final cycle = OculumOpenLifecycleProgress.fromJson({}, legacyUsed: true);
      expect(cycle.ready, false);
      expect(cycle.skillEmpowered, false);
      cycle.rest(longRest: true);
      expect(cycle.ready, false);
      final restored = OculumOpenLifecycleProgress.fromJson(
        jsonDecode(jsonEncode(cycle.toJson())) as Map,
      );
      restored.rest(longRest: true);
      expect(restored.ready, true);
    },
  );

  test(
    'all three model types preserve lifecycle data, custom costs and renamed identity',
    () {
      final state =
          (OculumOpenLifecycleProgress(id: 'stable')
                ..activate()
                ..rest(longRest: false))
              .toJson();
      final title = _title()..openLifecycle = state;
      final extra = TitleOpenEntry(
        nome: 'Extra',
        usedSinceLongRest: true,
        openLifecycle: state,
      );
      title.openExtra.add(extra);
      final art = CharacterArt(
        nome: 'Art',
        tipo: 'Elementale',
        descrizione: '',
        skills: [],
        openLifecycle: state,
        openSkillCooldown: OculumAbilityCooldown(amount: 7),
      );
      final titleCopy = OculumTitle.fromJson(
        jsonDecode(jsonEncode(title.toJson())) as Map<String, dynamic>,
      );
      final artCopy = CharacterArt.fromJson(
        jsonDecode(jsonEncode(art.toJson())) as Map<String, dynamic>,
      );
      titleCopy.nome = 'Nome modificato';
      artCopy.nome = 'Art modificata';
      expect(titleCopy.openLifecycle, state);
      expect(titleCopy.openExtra.single.openLifecycle, state);
      expect(artCopy.openLifecycle, state);
      expect(artCopy.openSkillCooldown!.amount, 7);
    },
  );

  testWidgets(
    'title activation, rest and concluded fights use the production lifecycle',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final title = _title();
      state.titoli.add(title);
      p.useTitleOpen(title);
      expect(title.openAttiva, true);
      expect(title.openUsedSinceLongRest, true);
      final id = title.openLifecycle['id'];
      p.tickOpenRest(longRest: true);
      expect(title.openAttiva, true);
      expect(title.openUsedSinceLongRest, true);
      p.tickOpenRest(longRest: true);
      expect(title.openAttiva, false);
      expect(title.openUsedSinceLongRest, false);
      expect(p.titleOpenBoost(title), true);
      p.completeOpenFight('first');
      p.completeOpenFight('first');
      p.completeOpenFight('second');
      expect(p.titleOpenBoost(title), true);
      p.completeOpenFight('third');
      expect(p.titleOpenBoost(title), false);
      expect(title.openLifecycle['id'], id);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'another Open replaces the Buff but leaves its independent Skill boost usable',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final first = _title(name: 'Primo'), second = _title(name: 'Secondo');
      state.titoli.addAll([first, second]);
      p.useTitleOpen(first);
      p.useTitleOpen(second);
      expect(first.openAttiva, false);
      expect(first.openLifecycle['buffActive'], false);
      expect(second.openAttiva, true);
      expect(p.titleOpenBoost(first), true);
      expect(p.titleOpenBoost(second), true);
      p.useTitleOpen(first);
      expect(first.openAttiva, false, reason: 'a switch cannot reset recovery');
      expect(second.openAttiva, true);
      await closeFixture(tester, p);
    },
  );

  testWidgets('replayed old settlement cannot shorten a later Open cycle', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    final title = _title();
    state.titoli.add(title);
    p.useTitleOpen(title);
    p.completeOpenFight('finished-old');
    p.tickOpenRest(longRest: true);
    p.tickOpenRest(longRest: true);
    p.useTitleOpen(title);
    expect(title.openLifecycle['completedFightIds'], isEmpty);
    p.completeOpenFight('finished-old');
    expect(title.openLifecycle['completedFightIds'], isEmpty);
    expect(p.titleOpenBoost(title), true);
    await closeFixture(tester, p);
  });
  testWidgets(
    'legacy Item Title Open survives the first real Long Rest and recovers at the second',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final item = InventoryItem(
        nome: 'Titolo prova',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        craftData: {
          'titleItem': true,
          'titleOpenUsedSinceLongRest': true,
          'titleOpenUsedStages': [0],
          'titleEvolution': {'progress': 5, 'requiredKills': 5},
        },
      );
      item.titleAbility = CharacterSkill(
        nome: 'Open oggetto',
        costo: '',
        cooldown: '',
        tipo: 'Difesa',
        descrizione: '',
        forme: [
          CharacterSkillForm(nome: 'Open', tipo: 'Difesa', livello: '0'),
          CharacterSkillForm(nome: 'Skill Open', tipo: 'Attacco', livello: '0'),
        ],
      );
      state.inventario.add(item);
      p.longRest(advanceWorldClock: false);
      expect(item.craftData['titleOpenUsedSinceLongRest'], true);
      expect(oculumItemTitleOpenIsActive(item, item.titleAbility!), true);
      await tester.pump(const Duration(milliseconds: 500));
      p.longRest(advanceWorldClock: false);
      expect(item.craftData['titleOpenUsedSinceLongRest'], false);
      expect(oculumItemTitleOpenIsActive(item, item.titleAbility!), false);
      expect(
        (item.craftData['titleOpenLifecycle'] as Map)['0']['skillEmpowered'],
        true,
      );
      await closeFixture(tester, p);
    },
  );
}
