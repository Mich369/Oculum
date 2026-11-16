import 'dart:collection';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _GripRolls implements Random {
  _GripRolls(Iterable<int> results) : _results = Queue<int>.of(results);

  final Queue<int> _results;

  @override
  int nextInt(int max) => _results.removeFirst() - 1;

  @override
  bool nextBool() => throw UnsupportedError('nextBool');

  @override
  double nextDouble() => throw UnsupportedError('nextDouble');
}

void main() {
  test('grab and retention use the same level bands and highest subtrait', () {
    expect(oculumPiovraGripModifier(0, 7, 5, 6), 12);
    expect(oculumPiovraGripModifier(2, 5, 7, 6), 12);
    expect(oculumPiovraGripModifier(3, 5, 6, 7), 17);
    expect(oculumPiovraGripModifier(5, 7, 6, 5), 17);
    expect(oculumPiovraGripModifier(6, 6, 7, 5), 22);
    expect(oculumPiovraGripModifier(46, 6, 5, 7), 22);
    expect(oculumPiovraWinsGripContest(20, 20), isFalse);
    expect(oculumPiovraWinsGripContest(21, 20), isTrue);
  });

  test('life drain only rounds down the confirmed life loss', () {
    expect(oculumPiovraGripHealing(0), 0);
    expect(oculumPiovraGripHealing(1), 0);
    expect(oculumPiovraGripHealing(7), 3);
    expect(oculumPiovraGripHealing(7, percent: 30), 2);
    expect(oculumPiovraGripHealing(7, percent: 150), 7);
  });

  for (final clearWithForceState in [false, true]) {
    testWidgets(
      clearWithForceState
          ? 'vulnerability reset removes the grip from the board and the prey'
          : 'configured grip spends an action and drains on the target turn',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        final source = probe.ownerTag();
        const target = 'PreyOcu:3690GRIP';
        final sourceSheet = probe.snapshot()
          ..['monsterBookSourceId'] = 'piovra_succhiasangue'
          ..['currentHp'] = '20'
          ..['resilienza'] = '80'
          ..['currentResilienza'] = '80';
        state.schedePersonaggio[0] = sourceSheet;
        probe.load(sourceSheet);
        state.schedePersonaggio.add({
          ...sourceSheet,
          'id': target,
          'sheetTag': target,
          'nome': 'Preda di prova',
          'monsterBookSourceId': '',
          'currentHp': '40',
          'resilienza': '10',
          'currentResilienza': '10',
        });
        final tokens = (state.masterInitiativeTokens as List)
            .cast<Map<String, dynamic>>();
        final holder = tokens.first;
        holder['side'] = 'enemy';
        holder['fightInstanceId'] = 'grip-fixture';
        tokens
          ..removeRange(1, tokens.length)
          ..add({
            'id': target,
            'sheetTag': target,
            'name': 'Preda di prova',
            'side': 'party',
            'status': 'ready',
            'fightInstanceId': 'grip-fixture',
          });
        probe.recordCurrentEncounter();
        probe.setSheetRollRandom(natural: _GripRolls([19, 2]));
        final hpBefore = state.currentHpController.text;
        final selecting = probe.useConfiguredForTest(
          CharacterSkillForm(
            nome: 'I',
            livello: '0',
            effettiStrutturati: [
              OculumStructuredEffect(
                type: 'planar',
                target: oculumPiovraGripEffect,
                valueExpression: '7',
                bypassDefense: true,
                elementType: 'acqua',
                recipient: 'nemico',
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Preda di prova'), findsWidgets);
        await tester.tap(find.text('Preda di prova').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(await selecting, isTrue);
        expect(holder['actionUsed'], isTrue);
        expect(holder['piovraGrip'], isA<Map>());
        expect(holder['sheetTag'], source);
        expect(tokens.last['piovraGripTickId'], startsWith('piovra:'));
        final targetState = state.schedePersonaggio[1] as Map;
        expect(targetState['conditions'].toString(), contains('afferrato'));
        final lifeLost = 40 - int.parse('${targetState['currentHp']}');
        expect(
          lifeLost,
          inInclusiveRange(1, 7),
          reason: targetState['logEventi'].toString(),
        );
        expect(
          targetState['logEventi'].toString(),
          contains('Vita −$lifeLost'),
        );
        expect(
          int.parse(state.currentHpController.text),
          int.parse(hpBefore) + lifeLost ~/ 2,
        );
        if (clearWithForceState) {
          state.schedaCorrente = 1;
          probe.load(Map<String, dynamic>.from(targetState));
          probe.activateForce('azzeramento_vulnerabilita');
          expect(
            probe.snapshot()['conditions'].toString(),
            isNot(contains('afferrato')),
          );
          expect(holder['piovraGrip'], isNull);
          probe.saveSheet();
        } else {
          probe.clearMasterBoardForTest();
        }
        expect(
          state.schedePersonaggio[1]['conditions'].toString(),
          isNot(contains('afferrato')),
        );
        await closeFixture(tester, probe);
      },
    );
  }
}
