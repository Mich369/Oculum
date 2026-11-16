import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Set<Object?> _sacs(Iterable<Map> parts) => parts
    .map((part) => part['id'])
    .where(oculumImbrytoadThroatSacs.contains)
    .toSet();

void main() {
  testWidgets(
    'Imbrytoad exposes both sacs only until the reacted-to Spit launches',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      final monster = monsterBookEntryById(oculumImbrytoadId)!;
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          monster.id;
      state.arti.clear();
      state.activeStructuredEffects.clear();
      state.activeConditions.clear();
      state.masterInitiativeRound = 2;
      state.masterInitiativeActiveIndex = 0;
      state.currentHpController.text = '40';
      state.livelloController.text = '4';
      state.currentOculumController.text = '10';
      state.oculumController.text = '10';
      state.masterInitiativeTokens.first.addAll({
        'monsterBookId': monster.id,
        'fightInstanceId': 'test-fight-1',
        'actionUsed': false,
        'actionTurnRound': 2,
      });
      state.masterInitiativeTokens[1].addAll({
        'reactionPoolInitialized': true,
        'reactionPoolRound': 2,
        'reactionMax': 1,
        'reactionUsed': 0,
        'initialFastReactionExpired': true,
      });
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'peer',
          'role': 'player',
          'localSheetTags': ['ENEMY'],
        },
      ];
      probe.recordCurrentEncounter();
      expect(
        _sacs(oculumMonsterPrecisionAnatomy(monster)),
        oculumImbrytoadThroatSacs,
      );
      expect(_sacs(probe.anatomicalPartsForCurrentSheet()), isEmpty);
      expect(
        probe.anatomicalWeakPointAccessible(state.masterInitiativeTokens.first),
        isFalse,
      );

      final art = oculumMonsterBookArt(monster)
        ..sbloccata = true
        ..incorporata = false;
      state.arti.add(art);
      final skillIndex = art.skills.indexWhere(
        (skill) => skill.nome == 'Sputo delle gronde',
      );
      expect(skillIndex, greaterThanOrEqualTo(0));
      final activation = probe.useArtSkill(0, skillIndex, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final confirm = find.widgetWithText(ElevatedButton, 'Attiva e spendi');
      expect(confirm, findsOneWidget);
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await activation;
      final window = probe.imbrytoadWindow()!;
      final id = window['id'] as int;
      expect(window['responders'], ['ENEMY']);
      expect(
        _sacs(probe.anatomicalPartsForCurrentSheet()),
        oculumImbrytoadThroatSacs,
      );
      expect(
        probe.anatomicalWeakPointAccessible(state.masterInitiativeTokens.first),
        isTrue,
      );
      expect(state.masterInitiativeTokens.first['actionUsed'], isFalse);
      expect(probe.imbrytoadReady(id), isFalse);
      final responder = state.masterInitiativeTokens[1];
      responder['reactionUsed'] = 1;
      expect(probe.imbrytoadReady(id), isTrue);

      final remote = <String, dynamic>{
        'id': 'ANOTHER-TOAD',
        'sheetTag': 'ANOTHER-TOAD',
        'monsterBookId': monster.id,
        'fightInstanceId': 'test-fight-2',
        'status': 'ready',
        'faunaPublic': {'imbrytoadSpit': window},
      };
      expect(_sacs(probe.anatomicalPartsForTarget(remote)), isEmpty);
      remote['fightInstanceId'] = 'test-fight-1';
      expect(
        _sacs(probe.anatomicalPartsForTarget(remote)),
        oculumImbrytoadThroatSacs,
      );

      final reaction = <String, dynamic>{
        'id': 'hostile-reaction',
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'targetTag': probe.ownerTag(),
        'imbrytoadSpitReaction': id,
        'status': 'pending',
      };
      state.onlineCombatRequests[reaction['id']] = reaction;
      expect(probe.imbrytoadReady(id), isFalse);
      reaction['status'] = 'resolved';
      expect(probe.imbrytoadReady(id), isTrue);

      final launch = probe.playImbrytoadSpit(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final planner = find.byType(OculumAttackPlanner);
      expect(planner, findsOneWidget);
      Navigator.of(
        tester.element(planner),
      ).pop(const OculumAttackPlan('ENEMY', 'vc', ''));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await launch;
      expect(probe.imbrytoadWindow(), isNull);
      expect(_sacs(probe.anatomicalPartsForCurrentSheet()), isEmpty);
      expect(
        probe.anatomicalWeakPointAccessible(state.masterInitiativeTokens.first),
        isFalse,
      );
      expect(
        probe.structuredEffects().any(
          (e) => oculumIsImbrytoadSpitEffect(e['effectId']),
        ),
        isFalse,
      );

      final before = probe.currentHp();
      final stale = <String, dynamic>{
        'id': 'stale-sac',
        'scope': probe.permissionScope,
        'encounterId': 'encounter_1',
        'sourceTag': 'ENEMY',
        'targetTag': probe.ownerTag(),
        'targetBodyPart': 'throat_sac_left',
        'status': 'pending',
        'attack': 1000,
        'choice': 'precisione',
        'damage': 100,
        'natural': 20,
        'dieFaces': 20,
        'element': 'fisico',
        'effects': <Map<String, dynamic>>[],
      };
      state.onlineCombatRequests[stale['id']] = stale;
      await probe.resolveCombatDefense(stale, 'cm', 10, natural: 10);
      expect(stale['referenceAnatomicalTargetUnavailable'], isTrue);
      expect(probe.currentHp(), before);
      await closeFixture(tester, probe);
    },
  );
}
