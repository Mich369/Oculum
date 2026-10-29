import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _MasterTransport extends OculumRealtimeService {
  _MasterTransport({String role = 'master'})
    : super(
        roomId: 'npc-escape-ledger',
        playerName: 'Master',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  final sent = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add({'event': event, ...payload});
    return true;
  }
}

void _prepareNpc(dynamic state, OculumPerformanceProbe p, {int active = 0}) {
  state.masterInitiativeRound = 2;
  state.masterInitiativeActiveIndex = active;
  for (final token in state.masterInitiativeTokens as List) {
    token.addAll({
      'fightInstanceId': 'fight-npc',
      'reactionPoolInitialized': true,
      'reactionPoolRound': 2,
      'reactionNormalFirstRoundLocked': false,
      'reactionMax': 1,
      'reactionUsed': 0,
      'reactionUsedRound': 2,
      'reactionFastMax': 1,
      'reactionFastUsed': 0,
      'actionUsed': false,
      'riflessi': 7,
      'velo': 4,
      'movement': 11,
      'vc': 17,
      'damage': 23,
      'level': 3,
    });
  }
  p.recordCurrentEncounter();
}

Map<String, dynamic> _escapeRecord(
  dynamic state,
  OculumPerformanceProbe p, {
  String source = 'HERO',
  String side = 'party',
  String? actor,
}) {
  final record = <String, dynamic>{
    'id': 'pending-npc-escape',
    'kind': 'escape',
    'status': 'pending',
    'scope': p.permissionScope,
    'encounterId': 'encounter_1',
    'fightInstanceId': 'fight-npc',
    'sourceTag': source,
    'targetTag': source,
    'sourceName': 'Fuggitivo',
    'sourceSide': side,
    'noticed': <String, dynamic>{actor ?? 'ENEMY': true},
    'answers': <String, dynamic>{},
    'total': 20,
    'movement': 10,
  };
  state.onlineCombatRequests[record['id']] = record;
  return record;
}

void main() {
  testWidgets(
    'legacy XP counters are namespaced by encounter and migrate only their matching board',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      for (final token in state.masterInitiativeTokens as List) {
        token.remove('fightInstanceId');
      }
      p.recordCurrentEncounter();
      final one = p.subtraitFightId('encounter_1');
      final saved = p.snapshot();
      saved['planarRuntime'] = <String, dynamic>{
        'combatSubtraitExperienceLedger': {
          'legacy:0': {
            'encounterId': 'encounter_1',
            'fightInstanceId': 'legacy:0',
            'earned': {'velo': 8},
            'receipts': <String>[],
            'bonusClaims': <String>[],
          },
        },
      };
      state.schedePersonaggio[0] = saved;
      p.load(saved);
      expect(
        p.subtraitFightXp(encounterId: 'encounter_1', fightInstanceId: one),
        {'velo': 8},
      );
      expect(
        p.subtraitFightXp(
          encounterId: 'second-board',
          fightInstanceId: 'legacy:second-board:0',
        ),
        isEmpty,
      );
      expect(one, 'legacy:encounter_1:0');
      final ledger =
          p.planarStateSnapshot()['combatSubtraitExperienceLedger'] as Map;
      expect(ledger.containsKey('legacy:0'), false);
      expect(ledger.containsKey(one), true);
      await closeFixture(tester, p);
    },
  );
  for (final online in [false, true]) {
    testWidgets(
      'NPC escape spends its Action, preserves the open character ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        _prepareNpc(state, p, active: 1);
        final transport = online ? _MasterTransport() : null;
        state.realtimeService = transport;
        final before = p.coreStats();
        final originalSheet = state.schedaCorrente;
        await p.escapeForToken('encounter_1', 'ENEMY');
        final actor =
            (state.masterInitiativeTokens as List).firstWhere(
                  (t) => t['id'] == 'ENEMY',
                )
                as Map;
        expect(actor['actionUsed'], true);
        expect(actor['reactionUsed'], 0);
        expect(state.masterInitiativeActiveIndex, isNot(1));
        expect(state.schedaCorrente, originalSheet);
        expect(p.coreStats(), before);
        final record = (state.onlineCombatRequests as Map).values
            .whereType<Map>()
            .singleWhere((r) => r['kind'] == 'escape');
        expect(record['sourceTag'], 'ENEMY');
        expect(record['movement'], 11);
        expect(record['subtraitId'], 'riflessi');
        expect(record['total'], isA<int>());
        expect(record['natural'], inInclusiveRange(1, 20));
        if (online) {
          expect(
            transport!.sent.where((e) => e['stage'] == 'offer'),
            hasLength(1),
          );
          final offer = transport.sent.firstWhere((e) => e['stage'] == 'offer');
          expect(offer['senderTag'], p.ownerTag());
          expect(offer['sourceTag'], 'ENEMY');
        }
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );

    testWidgets(
      'NPC escape outside its turn spends only its Reaction ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        _prepareNpc(state, p);
        state.realtimeService = online ? _MasterTransport() : null;
        await p.escapeForToken('encounter_1', 'ENEMY');
        final actor = (state.masterInitiativeTokens as List)[1] as Map;
        expect(actor['reactionUsed'], 1);
        expect(actor['actionUsed'], false);
        expect(state.masterInitiativeActiveIndex, 0);
        await p.escapeForToken('encounter_1', 'ENEMY');
        expect(
          actor['reactionUsed'],
          1,
        ); // Existing pending offer is not paid twice.
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );

    testWidgets(
      'Master NPC can block once without consuming the open PG ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        _prepareNpc(state, p);
        state.realtimeService = online ? _MasterTransport() : null;
        final record = _escapeRecord(state, p, source: p.ownerTag());
        final before = p.coreStats();
        await p.answerEscapeForToken(
          'encounter_1',
          '${record['id']}',
          'ENEMY',
          'block',
        );
        final answer = (record['answers'] as Map)['ENEMY'] as Map;
        expect(answer['answer'], 'block');
        expect(answer['movement'], 11);
        expect(answer['natural'], inInclusiveRange(1, 20));
        expect(answer['total'], isA<int>());
        expect(state.masterInitiativeTokens[1]['reactionUsed'], 1);
        expect(state.masterInitiativeTokens.first['reactionUsed'], 0);
        expect(state.masterInitiativeActiveIndex, 0);
        expect(p.coreStats(), before);
        await p.answerEscapeForToken(
          'encounter_1',
          '${record['id']}',
          'ENEMY',
          'block',
        );
        expect(state.masterInitiativeTokens[1]['reactionUsed'], 1);
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );

    testWidgets(
      'NPC last aggressor intercepts the fleeing target with a real d16 ${online ? 'online' : 'offline'}',
      (tester) async {
        final (state, p) = await fixtures.mountFight(tester);
        _prepareNpc(state, p);
        final transport = online ? _MasterTransport() : null;
        state.realtimeService = transport;
        final record = _escapeRecord(state, p, source: p.ownerTag())
          ..['lastAggressor'] = 'ENEMY';
        await p.answerEscapeForToken(
          'encounter_1',
          '${record['id']}',
          'ENEMY',
          'attack',
        );
        final packet = (state.onlineCombatRequests as Map).values
            .whereType<Map>()
            .singleWhere((r) => r['escapeNpcInterception'] == true);
        expect(packet['natural'], inInclusiveRange(1, 16));
        expect(packet['dieFaces'], 16);
        expect(packet['targetTag'], p.ownerTag());
        expect(packet['sourceTag'], 'ENEMY');
        expect(packet['damage'], 23);
        expect(packet['choice'], 'vc');
        expect(packet['turnResourceSpends'], isEmpty);
        expect(state.masterInitiativeTokens[1]['reactionUsed'], 0);
        expect(state.masterInitiativeActiveIndex, 0);
        expect((record['answers'] as Map)['ENEMY']['pending'], true);
        if (online) {
          final sent = transport!.sent.singleWhere(
            (e) => e['event'] == 'combat_attack',
          );
          expect(sent['senderTag'], p.ownerTag());
          expect(sent['sourceTag'], 'ENEMY');
          expect(sent['dieFaces'], 16);
        }
        state.realtimeService = null;
        await closeFixture(tester, p);
      },
    );
  }

  testWidgets(
    'NPC proxy rejects a player actor and a request it did not notice',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final record = _escapeRecord(
        state,
        p,
        source: 'OTHER',
        side: 'enemy',
        actor: p.ownerTag(),
      );
      await p.answerEscapeForToken(
        'encounter_1',
        '${record['id']}',
        p.ownerTag(),
        'help',
      );
      expect(record['answers'], isEmpty);
      (record['noticed'] as Map).clear();
      await p.answerEscapeForToken(
        'encounter_1',
        '${record['id']}',
        'ENEMY',
        'help',
      );
      expect(record['answers'], isEmpty);
      expect(state.masterInitiativeTokens[1]['reactionUsed'], 0);
      await closeFixture(tester, p);
    },
  );

  testWidgets('NPC proxy cannot be invoked by an online player', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    _prepareNpc(state, p);
    final transport = _MasterTransport(role: 'player');
    state.realtimeService = transport;
    state.modalitaMaster = false;
    state.isMasterHost = false;
    await p.escapeForToken('encounter_1', 'ENEMY');
    expect(transport.sent, isEmpty);
    expect(state.onlineCombatRequests, isEmpty);
    state.realtimeService = null;
    await closeFixture(tester, p);
  });

  testWidgets('linked NPC escape uses its saved subtraits and movement', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    _prepareNpc(state, p);
    const linkedTag = 'GuardiaOcu:3690ENEM';
    final linked = p.snapshot()
      ..addAll({
        'id': linkedTag,
        'sheetTag': linkedTag,
        'tipoScheda': 'Mostro',
        'nome': 'Mostro personalizzato',
        'derivedRiflessi': 88,
        'derivedVelo': 99,
        'derivedMovimento': 42,
        'derivedUnwoundedMovimento': 42,
      });
    state.schedePersonaggio.add(linked);
    state.masterInitiativeTokens[1]['sheetTag'] = linkedTag;
    final before = p.snapshot();
    await p.escapeForToken('encounter_1', linkedTag);
    final record = (state.onlineCombatRequests as Map).values
        .whereType<Map>()
        .singleWhere((r) => r['kind'] == 'escape');
    expect(record['movement'], 42);
    expect(record['subtraitId'], 'velo');
    expect(record['stealth'], true);
    expect(state.schedaCorrente, 0);
    expect(p.ownerTag(), before['sheetTag']);
    await closeFixture(tester, p);
  });

  testWidgets(
    'explicit NPC fight is used and the previous selection is restored',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final other = <String, dynamic>{
        'id': 'npc-only',
        'fightStarted': true,
        'round': 2,
        'activeIndex': 0,
        'tokens': <Map<String, dynamic>>[
          {
            'id': 'NPC',
            'side': 'enemy',
            'status': 'active',
            'name': 'NPC',
            'fightInstanceId': 'different-fight',
            'movement': 19,
            'riflessi': 6,
          },
          {
            'id': 'OTHER-NPC',
            'side': 'enemy',
            'status': 'ready',
            'name': 'Altro NPC',
            'fightInstanceId': 'different-fight',
            'initiativeTotal': 1,
          },
        ],
      };
      state.masterInitiativeGroups.add(other);
      await p.escapeForToken('npc-only', 'NPC');
      expect(state.selectedMasterInitiativeGroupId, 'encounter_1');
      expect(
        (state.masterInitiativeTokens as List).every(
          (t) => t['actionUsed'] == false,
        ),
        true,
      );
      final record = (state.onlineCombatRequests as Map).values
          .whereType<Map>()
          .singleWhere((r) => r['sourceTag'] == 'NPC' && r['kind'] == 'escape');
      expect(record['encounterId'], 'npc-only');
      expect(record['movement'], 19);
      final savedOther = (state.masterInitiativeGroups as List)
          .cast<Map>()
          .firstWhere((g) => g['id'] == 'npc-only');
      expect((savedOther['tokens'] as List).first['actionUsed'], true);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'fight EXP receipts add only extra XP once and survive save reload',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final id = p.subtraitFightId('encounter_1');
      final HiddenEyeStat reflex = (state.hiddenEyeStats as List)
          .cast<HiddenEyeStat>()
          .firstWhere((s) => s.id == 'riflessi');
      reflex.masteryProgress = 98;
      reflex.masteryLevels = 0;
      p.recordSubtraitFightXp('riflessi', 10, 'real-roll-1');
      p.recordSubtraitFightXp('riflessi', 10, 'real-roll-1');
      p.recordSubtraitFightXp('velo', 0, 'no-earned-XP');
      expect(
        p.subtraitFightXp(encounterId: 'encounter_1', fightInstanceId: id),
        {'riflessi': 10},
      );
      expect(
        p.claimSubtraitFightXp(
          settlementId: 'end-1',
          encounterId: 'encounter_1',
          fightInstanceId: id,
        ),
        {'riflessi': 3},
      );
      expect(reflex.masteryLevels, 1);
      expect(reflex.masteryProgress, 1);
      expect(
        p.claimSubtraitFightXp(
          settlementId: 'end-1-replayed',
          encounterId: 'encounter_1',
          fightInstanceId: id,
        ),
        isEmpty,
      );
      final saved = p.snapshot();
      p.load(saved);
      expect(
        p.claimSubtraitFightXp(
          settlementId: 'end-1-after-reload',
          encounterId: 'encounter_1',
          fightInstanceId: id,
        ),
        isEmpty,
      );
      expect(
        p.subtraitFightXp(encounterId: 'encounter_1', fightInstanceId: id),
        {'riflessi': 10},
      );
      await closeFixture(tester, p);
    },
  );

  for (final factor in [1.2, 1.7]) {
    testWidgets('single trait factor $factor floors only the additional part', (
      tester,
    ) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final id = p.subtraitFightId('encounter_1');
      p.recordSubtraitFightXp('riflessi', 10, 'factor-roll');
      expect(
        p.claimSubtraitFightXp(
          settlementId: 'end',
          encounterId: 'encounter_1',
          fightInstanceId: id,
          multiplier: factor,
        ),
        {'riflessi': factor == 1.2 ? 2 : 7},
      );
      await closeFixture(tester, p);
    });
  }

  testWidgets(
    'successful escape records its real subtrait and adds 25 percent after the fight factor',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      state.masterInitiativeTokens.add(<String, dynamic>{
        'id': 'ALLY',
        'side': 'party',
        'status': 'ready',
      });
      p.recordCurrentEncounter();
      final record = _escapeRecord(state, p, source: p.ownerTag())
        ..['subtraitId'] = 'velo';
      p.recordSubtraitFightXp('velo', 10, 'veil-real-XP');
      p.recordSubtraitFightXp('riflessi', 10, 'reflex-real-XP');
      final id = p.subtraitFightId('encounter_1');
      p.escapeEvent({
        'id': 'result',
        'stage': 'result',
        'escapeId': record['id'],
        'sourceTag': p.ownerTag(),
        'scope': p.permissionScope,
        'encounterId': 'encounter_1',
        'success': true,
      });
      final traits = p.escapeFightTraits(
        encounterId: 'encounter_1',
        fightInstanceId: id,
      );
      expect(traits, {'velo'});
      expect(
        p.claimSubtraitFightXp(
          settlementId: 'end',
          encounterId: 'encounter_1',
          fightInstanceId: id,
          escapeBonusTraits: traits,
        ),
        {'velo': 6, 'riflessi': 3},
      );
      expect(
        p.subtraitFightXp(encounterId: 'encounter_1', fightInstanceId: id),
        {'velo': 10, 'riflessi': 10},
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'ordinary real subtrait roll records the granted gain, including threshold wrap',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final HiddenEyeStat reflex = (state.hiddenEyeStats as List)
          .cast<HiddenEyeStat>()
          .firstWhere((s) => s.id == 'riflessi');
      reflex.masteryLevels = 0;
      reflex.masteryProgress = 99;
      state.gradoController.text = '0';
      final id = p.subtraitFightId('encounter_1');
      await p.rollSubtrait('riflessi');
      final ledger = p.subtraitFightXp(
        encounterId: 'encounter_1',
        fightInstanceId: id,
      );
      final gained =
          reflex.masteryProgress + (reflex.masteryLevels > 0 ? 100 : 0) - 99;
      expect(ledger['riflessi'] ?? 0, gained);
      expect(gained, anyOf(0, 15, 16, 17, 18, 19, 60));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Oculum ledger excludes failed cost and includes only committed spending across reload',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final sheet = p.snapshot()
        ..addAll({
          'oculum': '20',
          'currentOculum': '20',
          'normalCurrentOculum': 20,
          'temporaryOculum': 0,
        });
      p.load(sheet);
      final id = p.subtraitFightId('encounter_1');
      final available = p.availableArtResource('oculum');
      expect(available, greaterThan(3));
      expect(p.spendArtResource('oculum', available + 1), 0);
      expect(p.availableArtResource('oculum'), available);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        0,
      );
      expect(p.spendArtResource('oculum', 3), 3);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        3,
      );
      p.recoverOculum(2);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        3,
      );
      p.load(p.snapshot());
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        3,
      );
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['statsSpent'],
        3,
        reason: 'One Oculum payment is counted once despite refund and reload',
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'only committed core resource costs add statsSpent, HP sacrifices never do',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final id = p.subtraitFightId('encounter_1');
      var expected = 0;
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        final available = p.availableArtResource(stat);
        expect(p.spendArtResource(stat, available + 1), 0);
        expect(
          p.resourceFightXp(
            encounterId: 'encounter_1',
            fightInstanceId: id,
          )['statsSpent'],
          expected,
        );
        if (available <= 0) continue;
        expect(p.spendArtResource(stat, 1), 1);
        expected++;
        expect(
          p.resourceFightXp(
            encounterId: 'encounter_1',
            fightInstanceId: id,
          )['statsSpent'],
          expected,
        );
        expect(
          p.resourceFightXp(
            encounterId: 'encounter_1',
            fightInstanceId: id,
          )['statsSpent_$stat'],
          1,
        );
      }
      if (p.currentHp() > 1) {
        expect(p.spendArtResource('hp', 1), 1);
        expect(
          p.resourceFightXp(
            encounterId: 'encounter_1',
            fightInstanceId: id,
          )['statsSpent'],
          expected,
        );
        expect(
          p.resourceFightXp(
            encounterId: 'encounter_1',
            fightInstanceId: id,
          )['hpLost'],
          0,
        );
      }
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'HP ledger counts actual lost health after shields and preserves the instance through merge',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final id = p.subtraitFightId('encounter_1');
      state.resilienzaController.text = '20';
      state.currentResilienzaController.text = '20';
      state.currentHpController.text = '150';
      state.hpTempController.text = '0';
      state.hpTempBonusConsumati = 0;
      state.skills.clear();
      state.titoli.clear();
      state.inventario.clear();
      state.activeStructuredEffects.clear();
      state.activeConditions.clear();
      state.buffMalusRapidiController.clear();
      state.scudoOculumController.text = '0';
      state.scudoController.text = '20';
      final before = p.currentHp();
      await p.damageResolved(7, bypassDefense: true, resolvedResistance: true);
      expect(p.currentHp(), before);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['hpLost'],
        0,
      );
      await p.damageResolved(
        7,
        bypassDefense: true,
        bypassShields: true,
        resolvedResistance: true,
      );
      final realLoss = before - p.currentHp();
      expect(realLoss, greaterThan(0), reason: '${state.risultato}');
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['hpLost'],
        realLoss,
      );
      // A joined encounter preserves token fightInstanceId; its ledger is keyed by that ID.
      expect(
        p.resourceFightXp(
          encounterId: 'merged-encounter',
          fightInstanceId: id,
        )['hpLost'],
        realLoss,
      );
      p.load(p.snapshot());
      expect(
        p.resourceFightXp(
          encounterId: 'merged-encounter',
          fightInstanceId: id,
        )['hpLost'],
        realLoss,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'mask Oculum reserve spending is counted even when the normal reserve is empty',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      _prepareNpc(state, p);
      final sheet =
          Map<String, dynamic>.from(
            jsonDecode(
                  File(
                    'output/characters/senka_kamaria/Senka_Kamaria.json',
                  ).readAsStringSync(),
                )
                as Map,
          )..addAll({
            'id': p.ownerTag(),
            'sheetTag': p.ownerTag(),
            'currentOculum': '0',
            'normalCurrentOculum': 0,
            'temporaryOculum': 0,
          });
      p.load(sheet);
      final mask = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      p.manifestSenkaMask(mask, true);
      final id = p.subtraitFightId('encounter_1');
      expect(p.availableArtResource('oculum'), greaterThanOrEqualTo(1));
      expect(p.spendArtResource('oculum', 1), 1);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        1,
      );
      p.manifestSenkaMask(mask, false);
      p.manifestSenkaMask(mask, true);
      expect(
        p.resourceFightXp(
          encounterId: 'encounter_1',
          fightInstanceId: id,
        )['oculumSpent'],
        1,
      );
      await closeFixture(tester, p);
    },
  );
}
