import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

CharacterArt _guardian() =>
    oculumMonsterBookArt(monsterById('guardiano_solare')!);

void _activate(OculumPerformanceProbe probe, CharacterArt art) {
  expect(probe.recordArtOpenCycle(0), isTrue);
  art.openAttiva = true;
}

Future<void> _confirm(WidgetTester tester, Future<void> activation) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Conferma').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await activation;
}

Future<(dynamic, OculumPerformanceProbe, CharacterArt)> _mount(
  WidgetTester tester,
) async {
  final (state, probe) = await fixtures.mountFight(tester);
  final sheet = probe.snapshot()
    ..['livello'] = '8'
    ..['grado'] = '1'
    ..['oculum'] = '50'
    ..['currentOculum'] = '50'
    ..['normalCurrentOculum'] = 50
    ..['maxOculum'] = 50;
  probe.load(sheet);
  final art = _guardian()..hasIntegrity = false;
  state.arti
    ..clear()
    ..add(art);
  state.skills.clear();
  state.activeStructuredEffects.clear();
  state.masterInitiativeActiveIndex = 0;
  state.masterInitiativeRound = 2;
  final token = state.masterInitiativeTokens.first as Map;
  token['actionUsed'] = false;
  token['reactionPoolInitialized'] = true;
  token['reactionPoolRound'] = 2;
  token['reactionNormalFirstRoundLocked'] = false;
  token['reactionMax'] = 2;
  token['reactionUsed'] = 0;
  token['reactionUsedRound'] = 2;
  token['initialFastReactionExpired'] = false;
  token['reactionFastMax'] = 1;
  token['reactionFastUsed'] = 0;
  token['reactionFastTurnKey'] = '2';
  probe.recordCurrentEncounter();
  return (state, probe, art);
}

void main() {
  test(
    'gold Open catalogue keeps exact costs, shield grade floor and editable independent JSON',
    () {
      final art = _guardian();
      expect(art.openName, 'Potere dell’oro');
      expect(oculumParseAbilityCost(art.openDescription)?.minimum, 8);
      expect(oculumParseAbilityCost(art.openSkill)?.minimum, 3);
      expect(art.openSkillCooldown!.amount, 3);
      expect(art.openSkill, contains('Sempre utilizzabile'));
      expect(art.openDescription, isNot(contains('Richiede livello')));
      final buffCommands = oculumParseFormulaCommands(art.openBuff, const {
        'livello': 8,
        'grado': 1,
      }).where((command) => command.valid);
      expect(buffCommands.singleWhere((c) => c.key == 'danni').value, 15);
      expect(buffCommands.singleWhere((c) => c.key == 'difesa').value, 10);
      final custom = CharacterArt.fromJson(
        jsonDecode(jsonEncode(art.toJson())),
      );
      custom.openSkillEffects
              .singleWhere((e) => e.target == 'guardian_gold_wall')
              .valueExpression =
          '9';
      custom.openSkillCooldown!.amount = 4;
      final restored = CharacterArt.fromJson(custom.toJson());
      expect(
        restored.openSkillEffects
            .singleWhere((e) => e.target == 'guardian_gold_wall')
            .valueExpression,
        '9',
      );
      expect(restored.openSkillCooldown!.amount, 4);
      expect(_guardian().openSkillCooldown!.amount, 3);
      expect(oculumGuardianGoldReleaseDifficulty(8, 1), 20);
      expect(oculumGuardianGoldReflection(100), 15);
      expect(oculumGuardianGoldReflection(0), 0);
    },
  );

  testWidgets(
    'Muro d’oro really pays 3 Oculum and works with own Open off or another Open active',
    (tester) async {
      for (final otherOpen in [false, true]) {
        final (state, probe, art) = await _mount(tester);
        if (otherOpen) {
          state.arti.add(
            CharacterArt(
              nome: 'Altra',
              tipo: 'Art Mostro',
              descrizione: '',
              skills: [],
              openAttiva: true,
            ),
          );
        }
        final before = probe.availableArtResource('oculum');
        await _confirm(tester, probe.useOpenSkill(0));
        expect(art.openAttiva, isFalse);
        expect(probe.availableArtResource('oculum'), before - 3);
        expect(probe.guardianGoldState()['wallActive'], isTrue);
        expect(art.openSkillCooldown!.remaining, 3);
        expect(probe.guardianGoldDefense({'sourceTag': 'ENEMY'}), 6);
        expect(
          probe.guardianGoldPenalty({
            'sourceTag': 'ENEMY',
            'guardianGoldPerceived': true,
          }),
          0,
        );
        expect(probe.guardianGoldPenalty({'sourceTag': 'ENEMY'}), 0);
        final after = probe.availableArtResource('oculum');
        await probe.useOpenSkill(0);
        expect(probe.availableArtResource('oculum'), after);
        await closeFixture(tester, probe);
      }
    },
  );

  testWidgets(
    'Open pays 8 and its actual Buff adds damage and 108 shield, with first three attempts once',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      final before = probe.availableArtResource('oculum');
      final shield = probe.shieldTotal();
      final damage = probe.damageTotal();
      await _confirm(tester, probe.useOpen(0));
      expect(art.openAttiva, isTrue);
      expect(probe.availableArtResource('oculum'), before - 8);
      expect(probe.shieldTotal(), shield + 108);
      expect(probe.damageTotal(), damage + 15);
      expect(probe.guardianGoldAttempt('a'), 1.5);
      expect(probe.guardianGoldAttempt('a'), 1.5);
      expect(probe.guardianGoldState()['swordAttempts'], 1);
      expect(probe.guardianGoldAttempt('ranged', melee: false), 1);
      expect(probe.guardianGoldAttempt('b'), 1.5);
      expect(probe.guardianGoldAttempt('c'), 1.5);
      expect(probe.guardianGoldAttempt('d'), 1);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'wall dissolves on own attack; own Open dome follows through attacks',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      probe.applyEffects(art.openSkillEffects, source: 'Muro d’oro');
      probe.guardianGoldAttempt('normal', melee: false);
      expect(probe.guardianGoldState()['wallActive'], isFalse);
      _activate(probe, art);
      probe.applyEffects(art.openSkillEffects, source: 'Muro d’oro');
      probe.guardianGoldAttempt('dome');
      expect(probe.guardianGoldState()['wallActive'], isTrue);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'only successful hitter and actual helpers become immune; recast clears immunity; all received attempts check concentration',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      probe.applyEffects(art.openSkillEffects, source: 'Muro d’oro');
      probe.guardianGoldState()['wall_concentration'] = 0;
      probe.guardianGoldIncoming(
        {'id': 'miss', 'sourceTag': 'ENEMY'},
        hit: false,
        natural: 20,
      );
      expect(probe.guardianGoldDefense({'sourceTag': 'ENEMY'}), 6);
      probe.guardianGoldIncoming(
        {
          'id': 'hit',
          'sourceTag': 'ENEMY',
          'guardianGoldHelpers': ['HELPER'],
        },
        hit: true,
        natural: 20,
      );
      expect(probe.guardianGoldDefense({'sourceTag': 'ENEMY'}), 0);
      expect(probe.guardianGoldDefense({'sourceTag': 'HELPER'}), 0);
      expect(probe.guardianGoldDefense({'sourceTag': 'OTHER'}), 6);
      probe.applyEffects(art.openSkillEffects, source: 'Muro d’oro');
      expect(probe.guardianGoldDefense({'sourceTag': 'ENEMY'}), 6);
      probe.guardianGoldState()['wall_concentration'] = 99999;
      probe.guardianGoldIncoming(
        {'id': 'nextMiss', 'sourceTag': 'ENEMY'},
        hit: false,
        natural: 1,
      );
      expect(probe.guardianGoldState()['wallActive'], isFalse);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'reflection uses total shield and body loss, excludes Lunar damage and ranged hits and is replay safe',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      _activate(probe, art);
      final reflected = probe.guardianGoldIncoming(
        {'id': 'melee', 'sourceTag': 'ENEMY', 'attackTotal': 37},
        hit: true,
        damage: 100,
      );
      expect(reflected!['damage'], 15);
      expect(reflected['difficulty'], 37);
      expect(reflected['freeReflexDefense'], isTrue);
      expect(reflected['paidReactionRetry'], isTrue);
      expect(
        probe.guardianGoldIncoming(
          {'id': 'melee', 'sourceTag': 'ENEMY'},
          hit: true,
          damage: 100,
        ),
        isNull,
      );
      expect(
        probe.guardianGoldIncoming(
          {'id': 'lunar', 'sourceTag': 'ENEMY'},
          hit: true,
          damage: 100,
          lunar: true,
        ),
        isNull,
      );
      expect(
        probe.guardianGoldIncoming(
          {'id': 'ranged', 'sourceTag': 'ENEMY'},
          hit: true,
          damage: 100,
          melee: false,
        ),
        isNull,
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'fight end clears the wall but preserves Open weapons and the first-three-attempt budget',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      _activate(probe, art);
      probe.applyEffects(art.openDescriptionEffects, source: 'Potere dell’oro');
      probe.applyEffects(art.openSkillEffects, source: 'Muro d’oro');
      expect(probe.guardianGoldAttempt('one'), 1.5);
      probe.guardianGoldReset();
      expect(art.openAttiva, isTrue);
      expect(probe.guardianGoldState()['wallActive'], isNot(true));
      expect(probe.guardianGoldState()['swordAttempts'], 1);
      expect(probe.guardianGoldAttempt('two'), 1.5);
      expect(probe.guardianGoldAttempt('three'), 1.5);
      expect(probe.guardianGoldAttempt('four'), 1);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'grade zero shield receives the minimum grade factor without an unsupported formula',
    (tester) async {
      final (state, probe, art) = await _mount(tester);
      state.gradoController.text = '0';
      final shield = probe.shieldTotal();
      probe.applyEffects(
        art.openDescriptionEffects
            .where((e) => e.target == 'guardian_gold_shield')
            .toList(),
        source: 'Scudo d’oro',
      );
      expect(probe.shieldTotal(), shield + 108);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'gold part penalty lasts one personal turn and whole body lasts two, persisted without rerolls',
    (tester) async {
      final (_, probe, art) = await _mount(tester);
      _activate(probe, art);
      final metadata = probe.guardianGoldMetadata();
      probe.guardianGoldCritical(
        {'id': 'part', ...metadata},
        1,
        bodyPart: 'braccio destro',
      );
      expect(probe.guardianGoldPartPenalty('braccio destro'), -3);
      expect(probe.guardianGoldPartPenalty('gamba sinistra'), 0);
      probe.guardianGoldCritical(
        {'id': 'part', ...metadata},
        1,
        bodyPart: 'braccio destro',
      );
      expect((probe.guardianGoldState()['goldParts'] as List), hasLength(1));
      probe.guardianGoldCritical({'id': 'whole', ...metadata}, 2);
      expect(
        probe.conditions.any((c) => c.conditionType == 'immobilizzato'),
        isTrue,
      );
      probe.load(probe.snapshot());
      expect((probe.guardianGoldState()['goldParts'] as List), hasLength(2));
      probe.guardianGoldTurn();
      expect(probe.guardianGoldPartPenalty('braccio destro'), 0);
      expect((probe.guardianGoldState()['goldParts'] as List), hasLength(1));
      probe.guardianGoldTurn();
      expect((probe.guardianGoldState()['goldParts'] as List), isEmpty);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'stale skill payment cannot spend or apply after encounter changes',
    (tester) async {
      final (state, probe, _) = await _mount(tester);
      final before = probe.availableArtResource('oculum');
      final activation = probe.useOpenSkill(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      state.selectedMasterInitiativeGroupId = 'other_encounter';
      await tester.tap(find.widgetWithText(FilledButton, 'Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await activation;
      expect(probe.availableArtResource('oculum'), before);
      expect(probe.guardianGoldState()['wallActive'], isNot(true));
      await closeFixture(tester, probe);
    },
  );
}
