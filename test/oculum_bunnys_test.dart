import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'Bunnys uses its ears for natural flight and keeps both healing skills',
    () {
      final bunny = monsterById('bunnys')!;
      final veteran = monsterById('bunnys_variante_veterana')!;
      for (final monster in [bunny, veteran]) {
        expect(monster.hasNaturalFlight, isTrue);
        final anatomy = oculumMonsterPrecisionAnatomy(monster);
        expect(anatomy.where((part) => part['group'] == 'ears'), hasLength(2));
        expect(anatomy.where((part) => part['group'] == 'wings'), isEmpty);
        final loadout = oculumMonsterBookLoadout(monster, random: Random(1));
        final death = loadout.skills.singleWhere(
          (skill) =>
              skill.passiva &&
              skill.forme.first.effettiStrutturati.any(
                (effect) => effect.target == oculumBunnysDeathHealSkill,
              ),
        );
        expect(
          death.forme.first.effettiStrutturati.single.valueExpression,
          '50',
        );
        final cure = loadout.skills.singleWhere(
          (skill) => skill.forme.first.effettiStrutturati.any(
            (effect) => effect.target == oculumBunnysHealSkill,
          ),
        );
        expect(cure.forme.first.effettiStrutturati.single.recipient, 'nemico');
        expect(
          cure.forme.first.effettiStrutturati.single.valueExpression,
          '25',
        );
      }
    },
  );

  testWidgets('Cura pays target level and confirmed death heals allies once', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final bunny = monsterById('bunnys')!;
    final own = probe.ownerTag();
    final base = probe.snapshot();
    final bunnysSkills = oculumMonsterBookSkills(bunny);
    final sheet = {
      ...base,
      'id': own,
      'sheetTag': own,
      'monsterBookSourceId': bunny.id,
      'oculum': '20',
      'currentOculum': '20',
      'normalCurrentOculum': 20,
      'temporaryOculum': 0,
      'temporaryOculumRollsRemaining': 0,
      'skills': bunnysSkills.map((skill) => skill.toJson()).toList(),
    };
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    expect(state.currentOculumController.text, '20');
    Map<String, dynamic> companion(String tag, int level) => {
      ...base,
      'id': tag,
      'sheetTag': tag,
      'nome': tag,
      'livello': '$level',
      'resilienza': '20',
      'currentResilienza': '20',
      'currentHp': '40',
      'conditions': const [],
      'planarRuntime': <String, dynamic>{},
    };
    state.schedePersonaggio.addAll(<Map<String, dynamic>>[
      companion('BunnysEnemyOcu:3690FD5G', 7),
      companion('BunnysAllyOcu:3690FD5G', 3),
    ]);
    probe.ensureSheetTags();
    for (final (index, side, name) in [
      (1, 'enemy', 'Nemico'),
      (2, 'party', 'Alleato'),
    ]) {
      final tag = '${state.schedePersonaggio[index]['sheetTag']}';
      final Map token = state.masterInitiativeTokens[index];
      token['id'] = token['sheetTag'] = tag;
      token['name'] = name;
      token['side'] = side;
      token['level'] = 99;
    }
    probe.recordCurrentEncounter();
    final CharacterSkill cure = (state.skills as List<CharacterSkill>)
        .singleWhere(
          (skill) => skill.forme.first.effettiStrutturati.any(
            (effect) => effect.target == oculumBunnysHealSkill,
          ),
        );

    Future<void> finishDialogTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    final operation = probe.useCharacterSkill(cure);
    await finishDialogTransition();
    expect(find.textContaining('Alleato ·'), findsNothing);
    final target = find.widgetWithText(SimpleDialogOption, 'Nemico · 7 Oculum');
    expect(target, findsOneWidget);
    expect(tester.widget<SimpleDialogOption>(target).onPressed, isNotNull);
    await tester.tap(target);
    await finishDialogTransition();
    await tester.tap(find.widgetWithText(FilledButton, 'Conferma'));
    await finishDialogTransition();
    await operation;
    expect(state.currentOculumController.text, '13');
    expect(state.schedePersonaggio[1]['currentHp'], '50');
    expect(state.schedePersonaggio[2]['currentHp'], '40');

    state.currentHpController.text = '0';
    state.feriteMorte = 0;
    probe.scostuSyncDeath();
    await tester.pump();
    expect(state.schedePersonaggio[2]['currentHp'], '40');

    state.feriteMorte = 3;
    probe.saveSheet();
    probe.scostuSyncDeath();
    probe.scostuSyncDeath();
    await tester.pump();
    expect(state.schedePersonaggio[2]['currentHp'], '60');
    expect(state.schedePersonaggio[1]['currentHp'], '50');
    await closeFixture(tester, probe);
  });
}
