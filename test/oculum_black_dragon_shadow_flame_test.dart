import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'package:oculum/widgets/oculum_attack_planner.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _blackDragon = 'black_dragon_shield';

class _OpposedPreviewTransport extends OculumRealtimeService {
  _OpposedPreviewTransport()
    : super(
        roomId: 'black-dragon-preview',
        playerName: 'Cynervail',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );

  @override
  bool get isConnected => true;

  final defenseReplies = <Map<String, dynamic>>[];

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (event == 'combat_scout' &&
        payload['opposedRollReviewStage'] == 'defense') {
      defenseReplies.add(Map<String, dynamic>.from(payload));
    }
    return true;
  }
}

void main() {
  test('explicit species permissions remain valid for other actors', () {
    final dragon = monsterBookEntryById(_blackDragon)!;
    final other = dragon.copyWith(id: 'other_intangible_attacker');
    expect(oculumMonsterAttackCanHitIntangible(dragon), isFalse);
    expect(oculumMonsterAttackCanHitIntangible(other), isTrue);
    expect(oculumMonsterAttackCanHitIntangible(null), isFalse);
    expect(
      oculumMonsterAttackCanHitIntangible(other.copyWith(encounterRules: {})),
      isFalse,
    );
  });

  for (final (sourceId, form) in [
    (_blackDragon, 0),
    (_blackDragon, 1),
    (_blackDragon, 2),
    (_blackDragon, 3),
    ('', 1),
  ]) {
    testWidgets(
      form == 0
          ? 'BlackDragonShield: il Taglio ordinario perde il permesso anti-intangibilità'
          : 'Vampata forma $form · ${sourceId.isEmpty ? 'altro utilizzatore' : 'BlackDragonShield'}: il pacchetto conserva il permesso',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        final sheet = <String, dynamic>{
          ...probe.snapshot(),
          if (sourceId.isNotEmpty) 'monsterBookSourceId': sourceId,
          'skills': <dynamic>[],
          'arti': <dynamic>[],
        };
        state.schedePersonaggio[0] = sheet;
        probe.load(sheet);
        state.currentHpController.text = '${probe.maximumHp()}';
        probe.recordCurrentEncounter();

        if (form > 0) {
          final skill =
              oculumMonsterBookArt(
                monsterBookEntryById(_blackDragon)!,
              ).skills.singleWhere(
                (entry) => entry.nome == 'Vampata del drago d’ombra',
              );
          probe.applyEffects(skill.effettiEvoluzione(form), source: skill.nome);
        }
        final attack = probe.planAttack(total: 30, natural: 12);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final planner = find.byType(OculumAttackPlanner);
        expect(planner, findsOneWidget);
        final attackElement = form == 0
            ? 'taglio'
            : tester.widget<OculumAttackPlanner>(planner).initialElement;
        if (form > 0) expect(attackElement, 'buio');
        Navigator.of(
          tester.element(planner),
        ).pop(OculumAttackPlan('ENEMY', 'vc', 'Prova', element: attackElement));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await attack;
        final packet = (state.onlineCombatRequests as Map).values
            .whereType<Map>()
            .singleWhere((request) => request['attackGroupId'] != null);
        expect(packet['sourceMonsterBookId'], sourceId);
        expect(packet['element'], form == 0 ? 'taglio' : 'buio');
        expect(packet['canHitIntangible'] == true, form > 0);
        await closeFixture(tester, probe);
      },
    );
  }

  for (final (name, element, flames, part) in [
    ('Taglio al corpo', 'taglio', false, null),
    ('Vampata al corpo', 'buio', true, null),
    ('Taglio alla Lanterna', 'taglio', false, oculumCynervailLantern),
  ]) {
    testWidgets('Cynervail · $name: anteprima e risoluzione concordano', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      final target = probe.ownerTag();
      const source = 'BLACK-DRAGON';
      final sheet = <String, dynamic>{
        ...probe.snapshot(),
        'monsterBookSourceId': oculumCynervailId,
        'livello': '3',
        'grado': '0',
        'resilienza': '30',
        'currentResilienza': '30',
        'currentHp': '250',
      };
      state.schedePersonaggio[0] = sheet;
      probe.load(sheet);
      state.scudoController.text = '0';
      state.scudoOculumController.text = '0';
      state.scudoCriticoController.text = '0';
      state.hpTempController.text = '0';
      state.modalitaMaster = false;
      state.proponiFortunaDopoTiro = false;
      state.fortuna = 0;
      state.fatePactUsed = true;
      state.ispirazioniController.text = '0';
      state.superIspirazioniController.text = '0';
      state.ispirazioniOculumController.text = '0';
      final transport = _OpposedPreviewTransport();
      state.realtimeService = transport;
      state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'encounterId': 'cynervail-preview',
        'campaignId': state.activeCampaignId,
        'fightStarted': true,
        'round': 1,
        'activeIndex': 0,
        'tokens': [
          <String, dynamic>{
            'id': target,
            'sheetTag': target,
            'side': 'party',
            'status': 'active',
            'fightInstanceId': 'cynervail-instance',
          },
          <String, dynamic>{
            'id': source,
            'sheetTag': source,
            'side': 'enemy',
            'status': 'ready',
            'fightInstanceId': 'dragon-instance',
          },
        ],
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'dragon-session',
          'activeSheetTag': source,
          'role': 'player',
        },
      ];
      probe.invalidateDerivedCaches();

      final attack = <String, dynamic>{
        'id': 'attack-draft',
        'attackGroupId': 'attack-group',
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': 'cynervail-preview',
        'sessionId': 'dragon-session',
        'senderTag': source,
        'senderRole': 'player',
        'sourceTag': source,
        'sourceName': 'BlackDragonShield',
        'sourceMonsterBookId': _blackDragon,
        'sourceFightInstance': 'dragon-instance',
        'targetTag': target,
        'targetFightInstance': 'cynervail-instance',
        'choice': part == null ? 'vc' : 'precisione',
        'targetBodyPart': ?part,
        'element': element,
        'canHitIntangible': flames,
        'attackHasEffects': false,
        'attack': 100000,
        'difficulty': 'normale',
        'comparison': 'roll',
      };
      probe.receiveCombat('combat_scout', {
        ...attack,
        'opposedRollReviewStage': 'proposal',
      });
      final draft =
          state.onlineCombatRequests[attack['id']] as Map<String, dynamic>;
      await probe.defendCombat(draft, 'cm');
      final shouldPhase = !flames && part == null;
      expect(
        transport.defenseReplies.single['comparison'],
        shouldPhase ? 'avoid' : 'roll',
      );

      final hpBefore = probe.currentHp();
      final finalAttack = <String, dynamic>{
        ...attack,
        'id': 'attack-final',
        'status': 'pending',
        'natural': 10,
        'dieFaces': 20,
        'damage': probe.defense() + 60,
        'level': 0,
        'grade': 0,
        'effects': <Map<String, dynamic>>[],
      };
      state.onlineCombatRequests[finalAttack['id']] = finalAttack;
      await probe.resolveCombatDefense(finalAttack, 'cm', 20, natural: 10);
      expect(finalAttack['cynervailBodyPhased'] == true, shouldPhase);
      expect(probe.currentHp(), shouldPhase ? hpBefore : lessThan(hpBefore));
      state.realtimeService = null;
      await closeFixture(tester, probe);
    });
  }
}
