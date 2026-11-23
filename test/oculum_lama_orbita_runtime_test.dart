import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_lama_orbita_rules.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _OrbitNatural implements Random {
  int rolls = 0;

  @override
  int nextInt(int max) {
    rolls++;
    return 12 % max;
  }

  @override
  bool nextBool() => throw UnsupportedError('nextBool');

  @override
  double nextDouble() => throw UnsupportedError('nextDouble');
}

void main() {
  for (final fighting in [true, false]) {
    testWidgets(
      'Orbit Blade recovery requires contact and spends only during Fight ($fighting)',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        final token =
            state.masterInitiativeTokens.first as Map<String, dynamic>;
        token['actionUsed'] = false;
        if (!fighting) probe.clearMasterBoardForTest();
        final blade = InventoryItem(
          nome: 'Lama Orbita',
          peso: 1,
          quantita: 1,
          note: '',
          arma: true,
          craftData: {
            oculumLamaOrbitaId: {'affinity': 60, 'lost': true},
          },
        );
        state.inventario.add(blade);
        final recovery = probe.recoverLamaOrbitaForTest(blade);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Raccogli Lama Orbita'), findsOneWidget);
        expect((blade.craftData[oculumLamaOrbitaId] as Map)['lost'], true);
        await tester.tap(find.text('Conferma'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await recovery;
        expect((blade.craftData[oculumLamaOrbitaId] as Map)['lost'], isNull);
        expect(token['actionUsed'], fighting);
        await closeFixture(tester, probe);
      },
    );
  }

  for (final resource in ['Azione', 'Reazione']) {
    testWidgets(
      'Orbit Blade spends one $resource and replays the same area once',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        final owner = probe.ownerTag();
        state.proponiFortunaDopoTiro = false;
        state.masterInitiativeRound = 2;
        final opponents = [
          for (final (id, name) in [
            ('EnemyOcu:4317ORBT', 'Provocatore'),
            ('OtherOcu:4318ORBT', 'Altro nemico'),
          ])
            {
              ...probe.snapshot(),
              'id': id,
              'sheetTag': id,
              'nome': name,
              'resilienza': '200',
              'currentResilienza': '200',
              'currentHp': '700',
            },
        ];
        state.schedePersonaggio.addAll(opponents);
        probe.ensureSheetTags();
        final enemy = '${state.schedePersonaggio[1]['sheetTag']}';
        final other = '${state.schedePersonaggio[2]['sheetTag']}';
        final enemyToken = state.masterInitiativeTokens[1] as Map;
        final otherToken = state.masterInitiativeTokens[2] as Map;
        enemyToken['id'] = enemyToken['sheetTag'] = enemy;
        otherToken['id'] = otherToken['sheetTag'] = other;
        final token =
            state.masterInitiativeTokens.first as Map<String, dynamic>;
        token.addAll({
          'actionUsed': false,
          'actionTurnRound': 2,
          'reactionPoolInitialized': true,
          'reactionPoolRound': 2,
          'reactionNormalFirstRoundLocked': false,
          'reactionMax': 2,
          'reactionUsed': 0,
          'reactionUsedRound': 2,
          'reactionFastMax': 1,
          'reactionFastUsed': 0,
          'reactionFastTurnKey': '2',
          'initialFastReactionExpired': true,
        });
        probe.recordCurrentEncounter();
        final natural = _OrbitNatural();
        probe.setSheetRollRandom(natural: natural);
        final blade = InventoryItem(
          nome: 'Lama Orbita',
          peso: 1,
          quantita: 1,
          note: '',
          arma: true,
          equipaggiata: true,
          craftData: {
            oculumLamaOrbitaId: {
              'affinity': 220,
              'physicalId': 'orbit-fixture',
            },
          },
        );
        state.inventario
          ..clear()
          ..add(blade);
        probe.invalidateDerivedCaches();
        final launched = probe.launchLamaOrbitaForTest(blade);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Lancia Lama Orbita'), findsOneWidget);
        await tester.tap(find.text('1 $resource'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await launched;

        final runtime = probe.snapshot()['planarRuntime'] as Map;
        final flight = runtime['lamaOrbitaFlight'] as Map;
        final launchId = flight['id'];
        final firstTurn = flight['firstTurn'] as int;
        final attack = flight['attack'] as int;
        expect(flight['loops'], 5);
        expect(flight['natural'], 13);
        expect(natural.rolls, 1);
        expect(token['actionUsed'], resource == 'Azione');
        expect(token['reactionUsed'], resource == 'Reazione' ? 1 : 0);

        List<Map<String, dynamic>> packetsFor(int orbit) =>
            (state.onlineCombatRequests as Map).values
                .whereType<Map<String, dynamic>>()
                .where(
                  (request) =>
                      request['lamaOrbitaLaunchId'] == launchId &&
                      request['lamaOrbitaOrbit'] == orbit &&
                      request['lamaOrbitaCounterOf'] == null,
                )
                .toList();
        void settle(Map<String, dynamic> packet) {
          packet['status'] = 'resolved';
          packet['outcome'] = 'full';
          packet['damageReceipt'] = {'hpLost': 1};
          probe.claimLamaOrbitaForTest(packet);
        }

        Map ownerBladeData() {
          expect(probe.ownerTag(), owner);
          final inventory = probe.snapshot()['inventario'] as List;
          final data = inventory
              .whereType<Map>()
              .map((item) => (item['craftData'] as Map?)?[oculumLamaOrbitaId])
              .whereType<Map>()
              .singleWhere((entry) => entry['physicalId'] == 'orbit-fixture');
          return data;
        }

        int ownerAffinity() => ownerBladeData()['affinity'] as int;
        int cooldown() =>
            (ownerBladeData()['launchCooldown'] as Map?)?['remaining']
                as int? ??
            0;
        expect(cooldown(), 5);
        final first = packetsFor(0).single;
        probe.reportedTurn(firstTurn + 1);
        final nextOwnerTurn = {...token, 'reportedTurn': firstTurn + 1};
        probe.advanceLamaOrbitaOwnerTurnForTest(nextOwnerTurn);
        expect(cooldown(), 4);
        probe.advanceLamaOrbitaOwnerTurnForTest(nextOwnerTurn);
        expect(cooldown(), 4);
        await tester.pump();
        expect(packetsFor(1), isEmpty);
        settle(first);
        settle(first);
        final initial = packetsFor(0);
        expect(
          initial.map((packet) => packet['targetTag']),
          unorderedEquals([enemy, other]),
        );
        expect(initial.every((packet) => packet['attack'] == attack), isTrue);
        settle(initial.last);
        expect(ownerAffinity(), 230);

        probe.advanceLamaOrbitaForTest(firstTurn + 1);
        await tester.pump();
        final firstRepeated = packetsFor(1).single;
        probe.advanceLamaOrbitaForTest(firstTurn + 1);
        expect(packetsFor(1).single['id'], firstRepeated['id']);
        settle(firstRepeated);
        final repeated = packetsFor(1);
        expect(
          repeated.map((packet) => packet['targetTag']),
          unorderedEquals([enemy, other]),
        );
        expect(repeated.every((packet) => packet['natural'] == 13), isTrue);
        expect(
          repeated.every((packet) => packet['attack'] == attack - 5),
          isTrue,
        );
        settle(repeated.last);
        expect(ownerAffinity(), 240);
        final repeatedIds = repeated.map((packet) => packet['id']).toSet();
        probe.advanceLamaOrbitaForTest(firstTurn + 1);
        await tester.pump();
        expect(
          packetsFor(1).map((packet) => packet['id']),
          unorderedEquals(repeatedIds),
        );
        expect(natural.rolls, 1);

        settle(first);
        expect(ownerAffinity(), 240);

        Map<String, dynamic> missed(
          String id,
          int natural, {
          bool melee = true,
        }) => {
          'id': id,
          'scope': probe.permissionScope,
          'encounterId': probe.activeCombatEncounterId,
          'sourceTag': enemy,
          'targetTag': owner,
          'status': 'resolved',
          'outcome': 'avoided',
          'melee': melee,
          'natural': natural,
        };
        Iterable<Map<String, dynamic>> counters() =>
            (state.onlineCombatRequests as Map).values
                .whereType<Map<String, dynamic>>()
                .where((packet) => packet['lamaOrbitaCounterOf'] != null);
        probe.counterLamaOrbitaForTest(missed('ranged-miss', 1, melee: false));
        expect(counters(), isEmpty);
        final normalMiss = missed('melee-miss', 2);
        final naturalOne = missed('melee-fumble', 1);
        state.onlineCombatRequests['melee-miss'] = normalMiss;
        state.onlineCombatRequests['melee-fumble'] = naturalOne;
        probe.counterLamaOrbitaForTest(normalMiss);
        await tester.pump();
        probe.counterLamaOrbitaForTest(normalMiss);
        probe.counterLamaOrbitaForTest(naturalOne);
        await tester.pump();
        final byMiss = {
          for (final packet in counters())
            packet['lamaOrbitaCounterOf']: packet,
        };
        expect(counters(), hasLength(2));
        expect(byMiss['melee-miss']?['lamaOrbitaCritical'], isFalse);
        expect(byMiss['melee-fumble']?['lamaOrbitaCritical'], isTrue);
        expect(token['actionUsed'], resource == 'Azione');
        expect(token['reactionUsed'], resource == 'Reazione' ? 1 : 0);
        expect(natural.rolls, 1);
        await closeFixture(tester, probe);
      },
    );
  }
}
