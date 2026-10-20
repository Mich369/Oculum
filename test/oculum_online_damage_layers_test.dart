import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';

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
  final sent = <(String, Map<String, dynamic>)>[];
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add((event, Map<String, dynamic>.from(payload)));
    return true;
  }
}

void main() {
  testWidgets('selected defender consumes defense and all HP layers once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    final directory = Directory(
      'build/damage-layers-${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.absolute.path,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => ['none'],
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const OculumHomePage()),
    );
    final dynamic state = tester.state(find.byType(OculumHomePage));
    state.tutorialDialogPending = true;
    final probe = OculumPerformanceProbe(state);
    await tester.runAsync(() async {
      state.saveBlobDirectoryFuture = Future<Directory>.value(directory);
      state.sharedPreferencesFuture = Future<SharedPreferences>.value(
        await SharedPreferences.getInstance(),
      );
      await probe.reloadSave();
    });
    expect(state.datiCaricati, isTrue);
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
    final transport = _LayerTransport();
    state.realtimeService = transport;
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
    state.activeStructuredEffects
      ..clear()
      ..add({
        'effectId': 'permanent-fire-resistance',
        'type': 'elemental_resistance',
        'element': 'fuoco',
        'preset': 'Alta Resistenza',
        'remaining': -1,
      });
    expect(probe.incomingDamagePreset('fuoco'), 'Alta Resistenza');
    expect(probe.incomingDamagePreset('acqua'), 'Normale');
    state.activeStructuredEffects.single['remaining'] = 0;
    expect(probe.incomingDamagePreset('fuoco'), 'Normale');
    state.activeStructuredEffects.clear();
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
      // Resilience 100 supports the HP fixture but also grants Resistance 50.
      // Cancel only that derived passive to isolate the resource-layer order.
      if (stat.id == 'resistenza') stat.valore = -50;
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
      final packet = <String, dynamic>{
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
      };
      if (result.$3 == 5) {
        final readySnapshot = state.realtimeVisibleInitiativeSnapshot;
        state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
        probe.receiveCombat('combat_attack', packet);
        expect(
          state.onlineCombatRequests.containsKey(id),
          isFalse,
          reason:
              'A browser without the encounter cannot yet accept the attack',
        );
        state.realtimeVisibleInitiativeSnapshot = readySnapshot;
      }
      probe.receiveCombat('combat_attack', packet);
      expect(
        state.onlineCombatRequests.containsKey(id),
        isTrue,
        reason: 'Retry after encounter sync must deliver the original request',
      );
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
      expect(
        state.scudoOculumController.text,
        '${10 - spentOculumShield}',
        reason:
            'case $result, defense $defense: ${(state.logEventi as List).reversed.take(4).join("\n")}',
      );
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
    // One-shot penetration must leave no armed defensive toggle behind.
    state.scudoOculumController.text = '10';
    state.scudoController.text = '20';
    state.hpTempController.text = '0';
    state.currentHpController.text = '1000';
    state.dannoOltreDifesa = true;
    state.dannoOltreScudi = true;
    state.dannoBonusScudoPercentController.text = '25';
    probe.invalidateDerivedCaches();
    await tester.runAsync(() => probe.damageResolved(40));
    expect(state.currentHpController.text, '960');
    expect(state.scudoController.text, '20');
    expect(state.dannoOltreDifesa, isFalse);
    expect(state.dannoOltreScudi, isFalse);
    expect(state.dannoBonusScudoPercentController.text, '0');
    await tester.runAsync(() => probe.damageResolved(40));
    expect(
      int.parse(state.scudoController.text),
      lessThan(20),
      reason: 'The next hit uses shields again',
    );

    // Superior revival is a saved, single-use transition in the real damage path.
    state.schedePersonaggio[0]['monsterBookSourceId'] =
        'aberrazione_oro_marmo_superiore_solare';
    state.livelloController.text = '5';
    state.currentHpController.text = '10';
    state.scudoOculumController.text = '0';
    state.scudoController.text = '0';
    // Earlier cases intentionally exercise critical-stage damage presets.
    // Isolate the phase-transition assertions from that per-element state.
    state.incomingDamagePresets.clear();
    state.modificatoreDannoSelezionato = 'Normale';
    state.dannoSubitoPercentController.clear();
    state.activeConditions.clear();
    state.schivataOculumRiduzionePronta = 0;
    state.schivataOculumEtichettaPronta = '';
    state.scudoSalvataggioAttivo = false;
    probe.invalidateDerivedCaches();
    final maximum = probe.maximumHp();
    await tester.runAsync(
      () =>
          probe.damageResolved(10000, bypassDefense: true, bypassShields: true),
    );
    expect(int.parse(state.currentHpController.text), (maximum * .75).ceil());
    expect(state.schedePersonaggio[0]['aberrationPhase'], 3);
    expect(
      (state.activeStructuredEffects as List)
          .where((e) => e['effectId'] == 'aberration_final_phase')
          .single['value'],
      10,
    );
    await tester.runAsync(
      () =>
          probe.damageResolved(10000, bypassDefense: true, bypassShields: true),
    );
    expect(state.currentHpController.text, '0');
    state.schedePersonaggio[0].remove('monsterBookSourceId');
    state.activeStructuredEffects.clear();
    state.livelloController.text = '0';
    state.currentHpController.text = '1000';
    final last = state.onlineCombatRequests.values.last as Map<String, dynamic>;
    last['status'] = 'pending';
    last['damage'] = 0;
    final defending = probe.useCombatRoll(OculumCombatAbilityRole.defense);
    await tester.pump();
    await tester.runAsync(() async {
      await defending.timeout(const Duration(seconds: 15));
    });
    expect(
      last['status'],
      'resolved',
      reason: 'The ordinary Defense button must answer the pending attack',
    );
    expect(last['defenseChoice'], 'cm');
    state.realtimeVisibleInitiativeSnapshot['tokens'] = [
      {'id': owner, 'name': 'Rose'},
      {'id': enemy, 'name': 'Avversario'},
      {'id': 'OTHER', 'name': 'Altro mostro'},
    ];
    state.activeStructuredEffects.clear();
    state.buffMalusRapidiController.text = '@Danni+8';
    probe.invalidateDerivedCaches();
    final singleDamage = probe.damageTotal();
    probe.applyEffects([
      OculumStructuredEffect(
        id: 'single-damage-flat-bonus',
        type: 'danno',
        valueExpression: 'danni',
        recipient: 'nemico',
      ),
    ]);
    final singlePlan = probe.planAttack(minimum: 1, maximum: 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.text('Dichiara e tira'));
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pump();
    await tester.runAsync(() async => await singlePlan);
    final singlePacket = (state.onlineCombatRequests.values as Iterable)
        .singleWhere((request) => request['attackGroupId'] != null);
    expect(
      singlePacket['damage'],
      singleDamage,
      reason: 'A skill using Danni already contains the flat +8 exactly once.',
    );
    state.onlineCombatRequests.remove(singlePacket['id']);
    state.buffMalusRapidiController.clear();
    state.activeStructuredEffects.clear();
    probe.invalidateDerivedCaches();
    final planned = probe.planAttack(minimum: 2, maximum: 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Altro mostro'));
    await tester.pump();
    await tester.ensureVisible(find.text('Dichiara e tira'));
    await tester.tap(find.text('Dichiara e tira'));
    await tester.pump();
    await tester.runAsync(() async => await planned);
    final grouped = (state.onlineCombatRequests.values as Iterable)
        .where((request) => request['attackGroupId'] != null)
        .toList();
    expect(grouped, hasLength(2));
    expect(grouped.map((r) => r['targetTag']).toSet(), {enemy, 'OTHER'});
    expect(grouped.map((r) => r['attackGroupId']).toSet(), hasLength(1));
    expect(grouped.map((r) => r['attack']).toSet(), hasLength(1));
    transport.sent.clear();
    await tester.runAsync(() => probe.retryCombat());
    expect(
      transport.sent.where((e) => e.$1 == 'combat_attack'),
      hasLength(2),
      reason:
          'Server acceptance alone must not stop retries before recipient receipt',
    );
    final outgoing = grouped.firstWhere((r) => r['targetTag'] == enemy);
    final acknowledgement = <String, dynamic>{
      'id': outgoing['id'],
      'sourceTag': owner,
      'targetTag': enemy,
      'scope': probe.permissionScope,
      'campaignId': state.activeCampaignId,
      'encounterId': 'fight',
      'sessionId': 'enemy-session',
      'senderTag': enemy,
      'senderRole': 'player',
      'phase': 'attack',
    };
    probe.receiveCombat('combat_ack', {
      ...acknowledgement,
      'sessionId': 'forged',
    });
    expect(outgoing['attackAcknowledged'], isNot(true));
    probe.receiveCombat('combat_ack', acknowledgement);
    expect(outgoing['attackAcknowledged'], isTrue);
    transport.sent.clear();
    await tester.runAsync(() => probe.retryCombat());
    expect(transport.sent.where((e) => e.$1 == 'combat_attack'), hasLength(1));
    expect(
      transport.sent
          .where((e) => e.$1 == 'combat_attack')
          .single
          .$2['targetTag'],
      'OTHER',
    );
    expect(
      (state.logEventi as List).join('\n'),
      contains('[ATTACCO RICEVUTO]'),
    );
    state.campaignDifficulty = 'normale';
    state.coreMasteryPoints.clear();
    state.esperienzaCriticaStatistiche['vc'] = 0;
    probe.invalidateDerivedCaches();
    final beforeVc = probe.vc();
    for (var i = 0; i < 3; i++) {
      probe.gainCoreMastery('vc', 20);
    }
    expect(state.coreMasteryPoints['vc'], 1);
    expect(state.esperienzaCriticaStatistiche['vc'], 50);
    expect(probe.vc(), beforeVc + 1);
    expect((state.logEventi as List).join('\n'), contains('[MAESTRIA] vc +1'));
    state.esperienzaCriticaStatistiche['aiuta_compagno'] = 0;
    for (var i = 0; i < 3; i++) {
      probe.gainCoreMastery('aiuta_compagno', 10, faces: 10);
    }
    expect(state.coreMasteryPoints['aiuta_compagno'], 1);
    expect(state.esperienzaCriticaStatistiche['aiuta_compagno'], 50);
    final helpPacket = <String, dynamic>{
      'id': 'help-packet',
      'scope': probe.permissionScope,
      'campaignId': state.activeCampaignId,
      'encounterId': 'fight',
      'sessionId': 'enemy-session',
      'senderTag': enemy,
      'senderRole': 'player',
      'sourceTag': enemy,
      'sourceName': 'Avversario',
      'targetTag': owner,
      'targetName': 'Rose',
      'helpBonus': 7,
    };
    probe.receiveCombat('combat_help', {...helpPacket, 'sessionId': 'forged'});
    expect(probe.consumeHelp(), 0);
    probe.receiveCombat('combat_help', helpPacket);
    probe.receiveCombat('combat_help', helpPacket);
    expect(probe.consumeHelp(), 7);
    expect(probe.consumeHelp(), 0);
    probe.receiveCombat('combat_help', helpPacket);
    expect(
      probe.consumeHelp(),
      0,
      reason: 'A retry after consumption must not restore the bonus',
    );
    expect(
      (state.logEventi as List).join('\n'),
      contains('[AIUTO CONSUMATO] +7'),
    );
    probe.receiveCombat('combat_help', {
      ...helpPacket,
      'id': 'negative-help',
      'helpBonus': -4,
    });
    expect(probe.consumeHelp(), -4);
    expect(probe.consumeHelp(), 0);
    probe.receiveCombat('combat_help', {
      ...helpPacket,
      'id': 'negative-help',
      'helpBonus': -4,
    });
    expect(
      probe.consumeHelp(),
      0,
      reason: 'A repeated negative help packet must not apply twice',
    );
    expect(
      (state.logEventi as List).join('\n'),
      contains('[AIUTO CONSUMATO] -4'),
    );
    state.currentHpController.text = '900';
    final hpBeforeSupport = int.parse(state.currentHpController.text as String);
    final supportPacket = {
      ...helpPacket,
      'id': 'heal-once',
      'helpMode': 'effects',
      'effects': [
        OculumStructuredEffect(
          type: 'cura',
          resource: 'vita',
          valueExpression: '7',
          duration: '0',
          recipient: 'alleato',
        ).toJson(),
      ],
    };
    probe.receiveCombat('combat_help', supportPacket);
    expect(
      int.parse(state.currentHpController.text as String),
      hpBeforeSupport + 7,
    );
    probe.receiveCombat('combat_help', supportPacket);
    expect(
      int.parse(state.currentHpController.text as String),
      hpBeforeSupport + 7,
      reason: 'A retry must not heal twice',
    );
    final inactive = <String, dynamic>{
      'id': '003-ALLY',
      'sheetTag': '003-ALLY',
      'nome': 'Alleato',
      'resilienza': '10',
      'currentResilienza': '10',
      'currentHp': '30',
      'grado': '0',
      'livello': '0',
    };
    state.schedePersonaggio.add(inactive);
    (state.realtimeVisibleInitiativeSnapshot['tokens'] as List).add({
      'id': '003-ALLY',
    });
    final inactivePacket = <String, dynamic>{
      ...supportPacket,
      'id': 'inactive-support',
      'targetTag': '003-ALLY',
      'effects': [
        OculumStructuredEffect(
          type: 'cura',
          resource: 'vita',
          valueExpression: '7',
          duration: '0',
          recipient: 'alleato',
        ).toJson(),
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'sanguinamento',
          valueExpression: '1',
          duration: '2',
          recipient: 'alleato',
        ).toJson(),
      ],
    };
    probe.receiveCombat('combat_help', inactivePacket);
    expect(state.schedaCorrente, 0);
    expect(int.parse('${state.schedePersonaggio[2]['currentHp']}'), 37);
    expect(state.schedePersonaggio[2]['conditions'], isNotEmpty);
    probe.receiveCombat('combat_help', inactivePacket);
    expect(
      int.parse('${state.schedePersonaggio[2]['currentHp']}'),
      37,
      reason:
          'Inactive-sheet support must apply once without changing the open sheet.',
    );
    expect(
      transport.sent.any(
        (entry) =>
            entry.$1 == 'combat_ack' &&
            entry.$2['id'] == 'inactive-support' &&
            entry.$2['senderTag'] == '003-ALLY',
      ),
      isTrue,
      reason:
          'Support receipt missing: ${transport.sent} · ${state.schedePersonaggio[2]['sheetTag']}',
    );
    // Earlier random combat rolls may activate a Force state that legitimately
    // suppresses penalties. Isolate the herb aftereffect from that bonus.
    state.statoForzaAttivo = '';
    state.statoForzaTiriRimanenti = 0;
    probe.invalidateDerivedCaches();
    final herbsOffer = oculumSmokingHerbsOffer('alchemist-test');
    expect(herbsOffer['cost'], inInclusiveRange(30, 50));
    final herbs = probe.merchantItem(herbsOffer);
    state.inventario.add(herbs);
    await probe.useMerchantItem(herbs);
    expect(probe.herbalBonus('volonta'), 6);
    expect(probe.herbalBonus('materia'), 4);
    expect(state.inventario.contains(herbs), isFalse);
    final difficultyBeforeHerbs = probe.difficultyRollModifier();
    for (var turn = 0; turn < 3; turn++) {
      probe.advanceHerbs('turn');
    }
    expect(probe.herbalBonus('volonta'), 0);
    expect(
      (state.activeConditions as List).any(
        (dynamic c) => c.conditionType == 'confuso_erbe',
      ),
      isTrue,
    );
    expect(probe.difficultyRollModifier(), difficultyBeforeHerbs - 2);
    probe.applyHealing(1);
    expect(
      (state.activeConditions as List).any(
        (dynamic c) => c.conditionType == 'confuso_erbe',
      ),
      isFalse,
    );
    final scoutPacket = {
      ...helpPacket,
      'id': 'scout-once',
      'scoutPhase': 'request',
      'kind': 'scout',
      'natural': 20,
      'total': 10000,
    };
    probe.receiveCombat('combat_scout', {
      ...scoutPacket,
      'sessionId': 'forged',
    });
    expect(state.onlineCombatRequests.containsKey('scout-once'), isFalse);
    probe.receiveCombat('combat_scout', scoutPacket);
    expect(state.onlineCombatRequests['scout-once']['scoutPhase'], 'result');
    expect(state.onlineCombatRequests['scout-once']['weakPoint'], isTrue);
    final scoutLogs = (state.logEventi as List)
        .where((e) => '$e'.contains('[OSSERVAZIONE]'))
        .length;
    probe.receiveCombat('combat_scout', scoutPacket);
    expect(
      (state.logEventi as List)
          .where((e) => '$e'.contains('[OSSERVAZIONE]'))
          .length,
      scoutLogs,
    );
    for (var i = 0; i < 4; i++) {
      final run = {
        'chainedFate': {
          'id': 'fate-test-$i',
          'status': 'completed',
          'participants': [owner],
          'name': 'Dungeon prova',
        },
      };
      probe.completeFate(run);
      probe.completeFate(run);
    }
    expect(state.chainedFateCompletedIds.length, 4);
    state.realtimeVisibleInitiativeSnapshot['chainedFate'] = {
      'id': 'fate-active',
      'status': 'active',
      'participants': [owner],
    };
    expect(probe.fateExperienceMultiplier(), 3);
    state.realtimeVisibleInitiativeSnapshot['chainedFate']['status'] =
        'cancelled';
    expect(probe.fateExperienceMultiplier(), 1);
    state.realtimeService = null;
    state.schedePersonaggio[1]['realtimeSharedSheet'] = false;
    final helping = probe.helpAlly();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Chi vuoi aiutare?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Avversario'),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async => await helping);
    final pendingHelp = state.schedePersonaggio[1]['combatHelpPending'];
    expect(pendingHelp, isA<int>());
    final helpLog = (state.logEventi as List)
        .map((entry) => '$entry')
        .firstWhere((entry) => entry.contains('[AIUTA COMPAGNO]'));
    final loggedBonus = RegExp(
      r': ([+-]?\d+) al prossimo tiro',
    ).firstMatch(helpLog);
    expect(loggedBonus, isNotNull);
    expect(int.parse(loggedBonus!.group(1)!), pendingHelp);
    expect(helpLog, contains('→ Avversario'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}

