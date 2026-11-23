import 'package:flutter/material.dart'
    show
        AlertDialog,
        DecoratedBox,
        FilledButton,
        GestureDetector,
        HitTestBehavior;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/main.dart'
    show
        CharacterSkillForm,
        OculumPerformanceProbe,
        OculumStructuredEffect,
        oculumCorallwhirlCrossing;

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test('the signature technique grants movement and shield damage', () {
    final creature = monsterBookEntryById(oculumCorallwhirlId)!;
    final skill = oculumPlanarTechnique(oculumCorallwhirlDashSkillId)!;
    expect(
      creature.encounterRules['signatureSkillId'],
      oculumCorallwhirlDashSkillId,
    );
    expect(creature.skillIds, contains(oculumCorallwhirlDashSkillId));
    for (final form in skill.forms) {
      final effect = form.singleWhere(
        (effect) => effect.target == oculumCorallwhirlDashEffect,
      );
      expect(effect.formula, '3');
      expect(effect.shieldDamageBonusPercent, 120);
    }
    expect(oculumDamagePerTarget(31, 3, flatBonusPerTarget: 7), 18);
  });

  test('the dash crosses enemies on the actual segment at its elevation', () {
    double? crossing(double x, double y, {double elevation = 0}) =>
        oculumCorallwhirlCrossing(
          Offset.zero,
          const Offset(12, 0),
          Offset(x, y),
          elevationDifference: elevation,
          radius: 0.5,
        );
    expect(crossing(3, 0.5), 0.25);
    expect(crossing(9, 0.3, elevation: 0.4), 0.75);
    expect(crossing(12, 0), 1);
    expect(crossing(7, 0.55), isNull);
    expect(crossing(6, 0.4, elevation: 0.4), isNull);
    expect(crossing(13, 0), isNull);
  });
  testWidgets('replacement with the same tag cancels the confirmed dash', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final sheet = probe.snapshot()
      ..['monsterBookSourceId'] = oculumCorallwhirlId
      ..['currentHp'] = '200'
      ..['resilienza'] = '100'
      ..['currentResilienza'] = '100';
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    state.modalitaMaster = true;
    state.isMasterHost = true;
    state.isConnectedToMaster = false;
    state.relayConnected = false;
    await verifyCorallwhirlRejectsReplacement(tester, state, probe);
    await closeFixture(tester, probe);
  });
}

Future<void> verifyCorallwhirlRejectsReplacement(
  WidgetTester tester,
  dynamic state,
  OculumPerformanceProbe probe,
) async {
  final actor = state.masterInitiativeTokens.first as Map<String, dynamic>;
  final target = state.masterInitiativeTokens[1] as Map<String, dynamic>;
  actor.addAll({
    'id': probe.ownerTag(),
    'sheetTag': probe.ownerTag(),
    'status': 'active',
    'mapTokenId': 'dash-source',
    'fightInstanceId': 'dash-source-fight',
    'actionUsed': false,
    'reactionUsed': 0,
    'reactionFastUsed': 0,
  });
  target.addAll({
    'mapTokenId': 'dash-target',
    'fightInstanceId': 'dash-target-original',
  });
  final position = <String, dynamic>{
    'id': 'dash-source',
    'x': 0.30,
    'y': 0.50,
    'movementMaxMeters': 50,
  };
  state.localMapTokens
    ..clear()
    ..addAll(<Map<String, dynamic>>[
      position,
      {'id': 'dash-target', 'x': 0.36, 'y': 0.50},
    ]);
  probe.recordCurrentEncounter();
  expect(probe.currentHp(), 200);
  final requestsBefore = (state.onlineCombatRequests as Map).keys.toSet();
  final dash = probe.useConfiguredForTest(
    CharacterSkillForm(
      nome: 'Scatto delle Tre Maree',
      livello: '0',
      effettiStrutturati: [
        OculumStructuredEffect(
          type: 'planar',
          target: oculumCorallwhirlDashEffect,
          valueExpression: '3',
          recipient: 'nemico',
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  final route = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector &&
          widget.child is DecoratedBox &&
          widget.behavior == HitTestBehavior.opaque &&
          widget.onTapUp != null,
    ),
  );
  expect(
    route,
    findsOneWidget,
    reason: (state.logEventi as List).take(10).join('\n'),
  );
  final rect = tester.getRect(route);
  await tester.tapAt(rect.topLeft + Offset(rect.width * .41, rect.height * .5));
  await tester.pump();
  expect(find.textContaining(target['name'] as String), findsWidgets);
  expect(
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Scatta'))
        .onPressed,
    isNotNull,
  );
  target['fightInstanceId'] = 'dash-target-replacement';
  await tester.tap(find.text('Scatta'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  expect(await dash, isFalse);
  expect(actor['actionUsed'], isFalse);
  expect(position['x'], .30);
  expect((state.onlineCombatRequests as Map).keys.toSet(), requestsBefore);
}
