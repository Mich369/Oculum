import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _VampirismTransport extends OculumRealtimeService {
  _VampirismTransport()
    : super(
        roomId: 'vampirism-test',
        playerName: 'Vampiro',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      );
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async => true;
  @override
  Future<void> refreshPresence() async {}
}

void main() {
  testWidgets(
    'Authenticated damage receipt automatically heals without pressing Hit',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'VampiroOcu:3690FD5G',
        'sheetTag': 'VampiroOcu:3690FD5G',
        'nome': 'Vampiro',
      });
      state.schedaCorrente = 0;
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.realtimeService = _VampirismTransport();
      state.realtimeVisibleInitiativeSnapshot = {
        'encounterId': 'fight',
        'campaignId': state.activeCampaignId,
        'tokens': [
          {'id': probe.currentTag()},
          {'id': 'EnemyOcu:3690FD5H'},
        ],
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'enemy-session',
          'role': 'player',
          'activeSheetTag': 'EnemyOcu:3690FD5H',
        },
      ];
      state.currentHpController.text = '1';
      state.resilienzaController.text = '100';
      state.currentResilienzaController.text = '100';
      state.gradoController.text = '0';
      probe.addCondition('vampirismo');
      expect(
        probe.conditions.any((c) => c.conditionType == 'vampirismo'),
        isTrue,
      );
      final request = <String, dynamic>{
        'id': 'live-receipt',
        'attackGroupId': 'attack',
        'encounterId': 'fight',
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'sourceTag': probe.currentTag(),
        'targetTag': 'EnemyOcu:3690FD5H',
        'status': 'pending',
        'attack': 30,
        'damage': 500,
        'difficulty': 'normale',
      };
      state.onlineCombatRequests['live-receipt'] = request;
      final reply = {
        ...request,
        'sessionId': 'enemy-session',
        'senderRole': 'player',
        'senderTag': 'EnemyOcu:3690FD5H',
        'defense': 10,
        'defenseChoice': 'cm',
        'damageReceipt': {'hpLost': 100, 'shieldLost': 400},
      };
      probe.receiveCombat('combat_defense', {...reply, 'sessionId': 'forged'});
      expect(probe.currentHp(), 1);
      probe.receiveCombat('combat_defense', reply);
      expect(request['status'], 'resolved', reason: '$request');
      expect(request['damageReceipt'], isNotNull, reason: '$request');
      expect(request['vampirismClaimed'], isTrue, reason: '$request');
      expect(
        probe.currentHp(),
        4,
        reason: '$request; ${probe.conditions.map((c) => c.toJson())}',
      );
      expect(request['vampirismHealing'], 3);
      probe.receiveCombat('combat_defense', reply);
      expect(probe.currentHp(), 4);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  test(
    'Online vampirism scales actual HP damage, stage, difficulty and maximum HP',
    () {
      int heal(int damage, String difficulty, {int hp = 1000, int stage = 1}) =>
          oculumOnlineVampirismHealing(
            confirmedHpDamage: damage,
            maximumHp: hp,
            stage: stage,
            difficulty: difficulty,
          );
      expect(heal(1000, 'facile'), 37);
      expect(heal(1000, 'normale'), 30);
      expect(heal(1000, 'difficile'), 22);
      expect(heal(1000, 'oculum'), 15);
      expect(heal(100000, 'normale', hp: 100), 3);
      expect(heal(100000, 'normale', hp: 100, stage: 12), 36);
      expect(heal(0, 'normale'), 0);
      expect(heal(1, 'normale'), 1);
      expect(heal(100, 'normale', hp: 0), 0);
      expect(
        oculumOnlineVampirismHealing(
          confirmedHpDamage: 100,
          maximumHp: 1000,
          stage: 1,
          difficulty: 'normale',
          percentPerStage: 0,
        ),
        0,
      );
      expect(
        oculumOnlineVampirismHealing(
          confirmedHpDamage: 100,
          maximumHp: 1000,
          stage: 1,
          difficulty: 'normale',
          percentPerStage: 10,
          maxHpPercentPerStage: 1,
        ),
        10,
      );
    },
  );

  testWidgets(
    'Receipts heal once, share attack cap and ignore shields and declared damage',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'VampiroOcu:3690FD5G',
        'sheetTag': 'VampiroOcu:3690FD5G',
        'nome': 'Vampiro',
      });
      state.schedaCorrente = 0;
      state.currentHpController.text = '1';
      state.resilienzaController.text = '100';
      state.currentResilienzaController.text = '100';
      state.gradoController.text = '0';
      probe.addCondition('vampirismo');
      final tag = probe.currentTag();
      Map<String, dynamic> packet(
        String id,
        int lost, {
        String group = 'attack',
      }) => {
        'id': id,
        'attackGroupId': group,
        'encounterId': 'fight',
        'sourceTag': tag,
        'targetTag': 'target',
        'status': 'resolved',
        'outcome': 'full',
        'damage': 999999,
        'difficulty': 'normale',
        'damageReceipt': {
          'hpLost': lost,
          'shieldLost': 99999,
          'temporaryHpLost': 99999,
        },
      };
      final before = probe.currentHp();
      final maximum = probe.maximumHp();
      final shieldOnly = packet('shield', 0);
      probe.claimVampirism(shieldOnly);
      expect(probe.currentHp(), before);
      final first = packet('first', 500);
      probe.claimVampirism(first);
      final afterFirst = probe.currentHp();
      expect(
        afterFirst,
        before +
            oculumOnlineVampirismHealing(
              confirmedHpDamage: 500,
              maximumHp: maximum,
              stage: 1,
              difficulty: 'normale',
            ),
      );
      probe.claimVampirism({...first, 'vampirismClaimed': false});
      expect(probe.currentHp(), afterFirst);
      probe.claimVampirism(packet('second', 100000));
      final cap = oculumOnlineVampirismHealing(
        confirmedHpDamage: 100500,
        maximumHp: maximum,
        stage: 1,
        difficulty: 'normale',
      );
      expect(probe.currentHp(), before + cap);
      probe.claimVampirism(packet('third', 100000));
      expect(probe.currentHp(), before + cap);
      final roundTrip = OculumConditionInstance.fromJson(
        probe.conditions
            .firstWhere((c) => c.conditionType == 'vampirismo')
            .toJson(),
      );
      expect(roundTrip.metadata['onlineVampirismClaims'], isNotEmpty);
      final missingReceipt = packet('missing', 100)..remove('damageReceipt');
      probe.claimVampirism(missingReceipt);
      expect(probe.currentHp(), before + cap);
      final avoided = packet('avoided', 100, group: 'avoided')
        ..['outcome'] = 'avoided';
      probe.claimVampirism(avoided);
      expect(probe.currentHp(), before + cap);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
