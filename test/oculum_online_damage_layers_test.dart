import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _LayerTransport extends OculumRealtimeService {
  _LayerTransport()
    : super(
        roomId: 'layers',
        playerName: 'Rose',
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
}

void main() {
  testWidgets('selected defender consumes defense and all HP layers once', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    // Exercise real damage mutations without disk writes or threshold rewards;
    // persistence and transport have their own integration tests.
    state.datiCaricati = false;
    state.schedePersonaggio.clear();
    state.schedePersonaggio.addAll(<Map<String, dynamic>>[
      {'id': 'ROSE', 'sheetTag': 'ROSE', 'nome': 'Rose'},
      {
        'id': 'ENEMY',
        'sheetTag': 'ENEMY',
        'nome': 'Avversario',
        'realtimeSharedSheet': true,
        'currentHp': 999,
      },
    ]);
    state.schedaCorrente = 0;
    final owner = probe.ownerTag();
    final enemy = '${state.schedePersonaggio[1]['sheetTag']}';
    state.modalitaMaster = false;
    state.sonoCoMaster = false;
    state.realtimeService = _LayerTransport();
    state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
      'encounterId': 'fight',
      'tokens': [
        {'id': owner},
        {'id': enemy},
      ],
    };
    state.realtimeUsers = <Map<String, dynamic>>[
      {'sessionId': 'enemy-session', 'activeSheetTag': enemy, 'role': 'player'},
    ];
    state.campaignDifficulty = 'normale';
    state.titoli.clear();
    state.trattiRazziali.clear();
    state.skills.clear();
    state.arti.clear();
    state.inventario.clear();
    state.pawnGuardians.clear();
    state.livelloController.text = '0';
    state.gradoController.text = '0';
    state.resilienzaController.text = '100';
    state.currentResilienzaController.text = '100';
    state.materiaController.text = '0';
    state.currentMateriaController.text = '0';
    state.volontaController.text = '0';
    state.currentVolontaController.text = '0';
    state.oculumController.text = '0';
    state.currentOculumController.text = '0';
    state.dannoOltreDifesa = false;
    state.dannoOltreScudi = false;
    state.incomingDamagePresets.clear();
    state.modificatoreDannoSelezionato = 'Normale';
    state.schivataOculumRiduzionePronta = 0;
    state.activeConditions.clear();
    state.hiddenEyeStats.addAll([
      HiddenEyeStat(
        id: 'fortuna',
        nome: 'Fortuna',
        descrizione: '',
        unlocked: false,
      ),
    ]);
    for (final dynamic stat in state.hiddenEyeStats) {
      stat.valore = 0;
      if (stat.id == 'fortuna') stat.unlocked = false;
    }
    for (final result in [
      (18, 'full', 5),
      (18, 'full', 15),
      (18, 'full', 35),
      (18, 'full', 100),
      (13, 'reduced', 100),
      (10, 'avoided', 100),
    ]) {
      state.activeStructuredEffects.clear();
      state.scudoSalvataggioAttivo = false;
      state.scudoOculumMaxController.text = '10';
      state.scudoOculumController.text = '10';
      state.scudoController.text = '20';
      state.hpTempController.text = '20';
      state.currentHpController.text = '1000';
      probe.invalidateDerivedCaches();
      final defense = probe.defense();
      final raw = defense + result.$3;
      final id = 'layers-${result.$2}-${result.$3}';
      probe.receiveCombat('combat_attack', {
        'id': id,
        'scope': probe.permissionScope,
        'campaignId': state.activeCampaignId,
        'encounterId': 'fight',
        'sessionId': 'enemy-session',
        'senderTag': enemy,
        'senderRole': 'player',
        'sourceTag': enemy,
        'sourceName': 'Avversario',
        'targetTag': owner,
        'choice': 'vc',
        'attack': result.$1,
        'damage': raw,
        'level': 0,
        'difficulty': 'normale',
        'element': 'fisico',
      });
      final request = Map<String, dynamic>.from(
        state.onlineCombatRequests[id] as Map,
      );
      state.onlineCombatRequests[id] = request;
      await tester.runAsync(
        () => probe.resolveCombatDefense(request, 'cm', 10),
      );
      expect(request['outcome'], result.$2);
      final avoided = result.$2 == 'avoided';
      final absorbed = result.$2 == 'reduced'
          ? (defense * 1.5).ceil()
          : defense;
      var remaining = avoided ? 0 : max(1, raw - absorbed);
      final spentOculumShield = min(10, remaining);
      remaining -= spentOculumShield;
      final spentShield = min(20, remaining);
      remaining -= spentShield;
      final spentTemp = min(20, remaining);
      remaining -= spentTemp;
      expect(state.scudoOculumController.text, '${10 - spentOculumShield}');
      expect(state.scudoController.text, '${20 - spentShield}');
      expect(state.hpTempController.text, '${20 - spentTemp}');
      final expectedHp = 1000 - remaining;
      expect(state.currentHpController.text, '$expectedHp');
      expect(request['damageReceipt'], {
        'oculumShieldLost': spentOculumShield,
        'shieldLost': spentShield,
        'temporaryHpLost': spentTemp,
        'hpLost': remaining,
        'pawnPending': false,
      });
      expect((state.logEventi as List).join('\n'), contains('[DANNO RISOLTO]'));
      expect(state.schedePersonaggio[1]['currentHp'], 999);
      await tester.runAsync(
        () => probe.resolveCombatDefense(request, 'cm', 10),
      );
      expect(
        state.currentHpController.text,
        '$expectedHp',
        reason: 'Duplicate defense must not apply damage twice',
      );
    }
    state.realtimeService = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
