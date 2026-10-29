import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return value % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;
  @override
  double nextDouble() => nextInt(10000) / 10000;
}

class _ClockTransport extends OculumRealtimeService {
  _ClockTransport(String role)
    : super(
        roomId: 'world-clock',
        playerName: 'Clock',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  final messages = <Map<String, dynamic>>[];
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    messages.add({'event': event, ...payload});
    return true;
  }

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (authenticatedRole == 'player' && event == 'initiative_control') {
      throw StateError('The backend reserves this event for staff.');
    }
    messages.add({'event': event, ...payload});
    return true;
  }
}

void main() {
  test(
    'merchant visits require fifteen real minutes and only first and third grant at most two rests per day',
    () {
      final start = DateTime.utc(2026, 10, 29, 8);
      var state = <String, dynamic>{};
      state = oculumWorldMerchantVisit(state, day: 0, now: start);
      expect(state['grantRest'], isTrue);
      expect(state['rests'], 1);
      final early = oculumWorldMerchantVisit(
        state,
        day: 0,
        now: start.add(const Duration(minutes: 14, seconds: 59)),
      );
      expect(early['counted'], isFalse);
      expect(early['visits'], 1);
      state = oculumWorldMerchantVisit(
        state,
        day: 0,
        now: start.add(const Duration(minutes: 15)),
      );
      expect(state['grantRest'], isFalse);
      expect(state['visits'], 2);
      state = oculumWorldMerchantVisit(
        state,
        day: 0,
        now: start.add(const Duration(minutes: 30)),
      );
      expect(state['grantRest'], isTrue);
      expect(state['rests'], 2);
      state = oculumWorldMerchantVisit(
        state,
        day: 0,
        now: start.add(const Duration(minutes: 45)),
      );
      expect(state['grantRest'], isFalse);
      expect(state['rests'], 2);
      state = oculumWorldMerchantVisit(
        state,
        day: 1,
        now: start.add(const Duration(minutes: 60)),
      );
      expect(state['grantRest'], isTrue);
      expect(state['rests'], 1);
      expect(state['visits'], 1);
    },
  );

  test(
    'the nine-hour day has exact phase boundaries and repeats without a real timer',
    () {
      for (final (seconds, phase) in const [
        (0, 'mattina'),
        (10799, 'mattina'),
        (10800, 'primo_pomeriggio'),
        (14399, 'primo_pomeriggio'),
        (14400, 'pomeriggio'),
        (17999, 'pomeriggio'),
        (18000, 'buio'),
        (21599, 'buio'),
        (21600, 'notte'),
        (32399, 'notte'),
        (32400, 'mattina'),
      ]) {
        expect(oculumWorldPhase(seconds), phase);
      }
      expect(oculumWorldMonsterCoreBonus(18000, 8, 1, isMonster: true), 1);
      expect(oculumWorldMonsterCoreBonus(21600, 8, 1, isMonster: true), 16);
      expect(oculumWorldMonsterCoreBonus(21600, 8, 1, isMonster: false), 0);
    },
  );

  test(
    'turn receipts advance ten seconds once and reject non-forward deltas',
    () {
      final clock = OculumWorldClockProgress();
      expect(clock.advance(10, 'turn:one'), isTrue);
      expect(clock.advance(10, 'turn:one'), isFalse);
      expect(clock.advance(-10, 'back'), isFalse);
      expect(clock.advance(0, 'sync'), isFalse);
      expect(clock.seconds, 10);
      final restored = OculumWorldClockProgress.fromJson(
        jsonDecode(jsonEncode(clock.toJson())),
      );
      expect(restored.advance(10, 'turn:one'), isFalse);
      expect(restored.seconds, 10);
    },
  );

  test(
    'travel uses average movement and total 500 percent is five times, not six',
    () {
      expect(oculumWorldTravelSeconds(12000, [20, 40]), 4000);
      expect(
        oculumWorldTravelSeconds(12000, [20, 40], totalSpeedPercent: 500),
        800,
      );
      expect(oculumWorldTravelSeconds(1, [30]), 1);
      expect(() => oculumWorldTravelSeconds(100, []), throwsArgumentError);
      expect(() => oculumWorldTravelSeconds(100, [0]), throwsArgumentError);
      expect(
        () => oculumWorldTravelSeconds(double.infinity, [30]),
        throwsArgumentError,
      );
      expect(
        () => oculumWorldTravelSeconds(100, [30], totalSpeedPercent: 0),
        throwsArgumentError,
      );
    },
  );

  test(
    'travel checkpoints carry between trips, never count fight time, and never reroll duplicate commits',
    () {
      final rng = _FixedRandom(0), clock = OculumWorldClockProgress();
      clock.travel(
        duration: 600,
        receipt: 'a',
        chaos: false,
        realm: 'mezzano',
        party: [],
        random: rng,
      );
      clock.advance(1000, 'fight');
      expect(clock.checks, isEmpty);
      clock.travel(
        duration: 900,
        receipt: 'b',
        chaos: false,
        realm: 'mezzano',
        party: [],
        random: rng,
      );
      expect(clock.checks, hasLength(1));
      expect(clock.events, hasLength(1));
      expect(clock.events.single['worldSeconds'], 2500);
      expect(clock.seconds, 2500);
      expect(clock.travelRemainder, 0);
      expect(
        clock.travel(
          duration: 900,
          receipt: 'b',
          chaos: false,
          realm: 'mezzano',
          party: [],
          random: rng,
        ),
        isFalse,
      );
      expect(rng.calls, 1);
      expect(clock.seconds, 2500);
    },
  );

  test(
    '75 and 90 percent boundaries are exact and queue details are never public',
    () {
      for (final (roll, chaos, event) in const [
        (75, false, true),
        (76, false, false),
        (90, true, true),
        (91, true, false),
      ]) {
        final clock = OculumWorldClockProgress();
        clock.travel(
          duration: 1500,
          receipt: 'x',
          chaos: chaos,
          realm: 'carne_viva',
          party: [
            {'name': 'Segreto', 'power': 123},
          ],
          random: _FixedRandom(roll - 1),
        );
        expect(clock.events.isNotEmpty, event);
        expect(clock.publicJson().keys.toSet(), {
          'seconds',
          'revision',
          'day',
          'phase',
          'calendarOriginDay',
          'calendarOriginOrdinal',
          'rules',
          'restGrants',
        });
        expect(jsonEncode(clock.publicJson()), isNot(contains('Segreto')));
        expect(jsonEncode(clock.publicJson()), isNot(contains('mimic')));
      }
    },
  );

  test(
    'creature templates preserve exact PT, natural Oculum absence and Grade HP semantics',
    () {
      final mimic = monsterById('mimic_base')!;
      for (final power in [1, 10, 25, 130, 500]) {
        final build = oculumWorldTravelCreatureBuild(mimic, power),
            stats = build['stats'] as Map;
        final level = readIntValue(build['level']);
        final grade = readIntValue(build['grade']);
        final phase = level % 10;
        final hpMultiplier =
            (phase == 0
                ? 6
                : phase <= 2
                ? 9
                : 10) +
            5 * grade;
        final hpPower = hpMultiplier ~/ (grade == 0 ? 10 : 5);
        expect(
          stats.values.fold<int>(0, (sum, value) => sum + readIntValue(value)) +
              level +
              3 * grade +
              hpPower,
          power,
        );
        expect(readIntValue(stats['resilienza']), greaterThanOrEqualTo(1));
        expect(
          build['grade'],
          oculumGradeForLevel(readIntValue(build['level'])),
        );
      }
      final noOculum = monsterById('thunder_bot')!;
      expect(
        (oculumWorldTravelCreatureBuild(noOculum, 130)['stats']
            as Map)['oculum'],
        0,
      );
    },
  );

  test(
    'Mimic kill yields its own equipment plus d20 and level Grade Obser',
    () {
      final loot = oculumWorldMimicLoot(
        level: 13,
        grade: 1,
        killId: 'kill',
        random: _FixedRandom(19),
      );
      expect(loot['natural'], 20);
      expect(loot['obser'], 38);
      final item = InventoryItem.fromJson(
        Map<String, dynamic>.from(loot['item'] as Map),
      );
      expect(item.nome, contains('Mimic'));
      expect(item.arma || item.protegge, isTrue);
      expect(item.monsterLoot['id'], 'kill:mimic-equipment');
      expect(
        oculumWorldRealmMerchants(
          'carne_viva',
        ).any((m) => m['shopType'] == 'mercato_nero'),
        isTrue,
      );
      expect(
        oculumWorldRealmMerchants('reame_cristallo').first['name'],
        contains('Geodi'),
      );
    },
  );

  testWidgets(
    'Master turn clock is persisted per campaign and public snapshots exclude private events',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.setWorldClock({
        'seconds': 18000,
        'events': [
          {'id': 'secret', 'mimic': true},
        ],
        'revision': 1,
      });
      p.worldTurn('encounter_1', 'advance');
      p.worldTurn('encounter_1', 'advance');
      expect(p.worldSeconds(), 18010);
      final campaign = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.campaignSnapshot())),
      );
      state.activeCampaignId = 'other-campaign';
      expect(p.worldSeconds(), 0);
      p.worldTurn('encounter_1', 'other');
      expect(p.worldSeconds(), 10);
      p.loadCampaign(campaign);
      expect(p.worldSeconds(), 18010);
      expect((p.worldClockPrivate()['events'] as List).single['mimic'], isTrue);
      expect(jsonEncode(p.worldClockPublic()), isNot(contains('mimic')));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'individual rest requests aggregate and only one party confirmation advances time',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      p.setWorldClock({});
      p.worldRest(false);
      p.worldRest(false);
      p.worldRest(true);
      expect(p.worldSeconds(), 0);
      final rests = (p.worldClockPrivate()['rests'] as List)
          .whereType<Map>()
          .toList();
      expect(rests, hasLength(2));
      final short = rests.singleWhere((r) => r['longRest'] == false);
      final long = rests.singleWhere((r) => r['longRest'] == true);
      expect(p.worldConfirmRest('${short['id']}', 29), isFalse);
      expect(p.worldConfirmRest('${short['id']}', 30), isTrue);
      expect(p.worldConfirmRest('${short['id']}', 30), isFalse);
      expect(p.worldSeconds(), 1800);
      expect(p.worldConfirmRest('${long['id']}', 89), isFalse);
      expect(p.worldConfirmRest('${long['id']}', 90), isTrue);
      expect(p.worldSeconds(), 7200);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'real merchant rest is applied once and its receipt survives save reload',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      p.setWorldClock({});
      final start = DateTime.utc(2026, 10, 29, 8);
      p.merchantVisitAt('visit1', start);
      var visits = p.worldClockPrivate()['merchantVisits'] as Map;
      var visit = Map<String, dynamic>.from(visits[p.ownerTag()] as Map);
      expect(visit['rests'], 1);
      expect(
        (p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'],
        hasLength(1),
      );
      p.replayMerchantRest(
        Map<String, dynamic>.from(visit['lastGrant'] as Map),
      );
      expect(
        (p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'],
        hasLength(1),
      );
      p.load(p.snapshot());
      p.merchantVisitAt('visit2', start.add(const Duration(minutes: 15)));
      expect(
        (p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'],
        hasLength(1),
      );
      p.merchantVisitAt('visit3', start.add(const Duration(minutes: 30)));
      expect(
        (p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'],
        hasLength(2),
      );
      expect(
        p.worldSeconds(),
        0,
        reason: 'party elapsed time still awaits its one Master confirmation',
      );
      final campaign = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(p.campaignSnapshot())) as Map,
      );
      p.setWorldClock({});
      p.loadCampaign(campaign);
      visits = p.worldClockPrivate()['merchantVisits'] as Map;
      visit = Map<String, dynamic>.from(visits[p.ownerTag()] as Map);
      expect(visit['rests'], 2);
      expect(visit['visits'], 3);
      expect(
        visit['lastRealAtMs'],
        start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
      p.merchantVisitAt('visit3', start.add(const Duration(minutes: 30)));
      expect(
        (p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'],
        hasLength(2),
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'real initiative-control routing accepts a signed Master merchant rest once across save reload',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.setWorldClock({});
      state.realtimeService = _ClockTransport('player');
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master-session',
          'role': 'master',
          'activeSheetTag': 'MasterOcu:3690AAAA',
        },
      ];
      final payload = <String, dynamic>{
        'id': 'grant:merchant-rest:routed',
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'senderRole': 'master',
        'senderTag': 'MasterOcu:3690AAAA',
        'sessionId': 'master-session',
        'worldMerchantRestGrant': {
          'receipt': 'merchant-rest:routed',
          'targetTag': p.ownerTag(),
          'day': 0,
        },
      };
      p.setResourceCurrent('volonta', 0);
      p.receiveEncounterControl({...payload, 'senderRole': 'player'});
      expect(p.resourceCurrent('volonta'), 0);
      p.receiveEncounterControl({...payload, 'sessionId': 'forged-session'});
      expect(p.resourceCurrent('volonta'), 0);
      p.receiveEncounterControl(payload);
      expect(p.resourceCurrent('volonta'), greaterThan(0));
      expect((p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'], [
        'merchant-rest:routed',
      ]);
      p.setResourceCurrent('volonta', 0);
      final saved =
          jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
      p.load(saved);
      p.receiveEncounterControl(payload);
      expect(p.resourceCurrent('volonta'), 0);
      expect((p.snapshot()['planarRuntime'] as Map)['merchantRestReceipts'], [
        'merchant-rest:routed',
      ]);
      expect(p.worldSeconds(), 0);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'travel continues while a Mimic waits privately, its generated encounter is created once',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.setWorldClock({});
      final movement = p.movement();
      final metres = movement * 150.0;
      expect(
        p.worldTravel('trip', metres, [0], random: _FixedRandom(0)),
        isTrue,
      );
      final elapsed = p.worldSeconds();
      expect(elapsed, greaterThanOrEqualTo(1));
      final events = (p.worldClockPrivate()['events'] as List)
          .whereType<Map>()
          .toList();
      expect(events, isNotEmpty);
      final id = '${events.first['id']}';
      expect(p.worldChooseEvent(id, 'chest', random: _FixedRandom(0)), isTrue);
      final encoded = jsonEncode(p.worldClockPrivate());
      expect(p.worldChooseEvent(id, 'chest', random: _FixedRandom(99)), isTrue);
      expect(jsonEncode(p.worldClockPrivate()), encoded);
      final sheets = state.schedePersonaggio.length,
          groups = state.masterInitiativeGroups.length;
      final encounter = p.worldPrepareEncounter(id);
      expect(encounter, isNotEmpty);
      expect(p.worldPrepareEncounter(id), encounter);
      expect(state.schedePersonaggio.length, sheets + 1);
      expect(state.masterInitiativeGroups.length, groups + 1);
      final mimic = state.schedePersonaggio.last as Map;
      expect(mimic['travelMimic'], isTrue);
      expect(mimic['monsterBookSourceId'], 'mimic_base');
      expect((mimic['skills'] as List), isNotEmpty);
      expect(p.worldSeconds(), elapsed);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Fate fight uses 125 percent of the entire party, split among chosen creatures',
    (tester) async {
      final (_, p) = await fixtures.mountFight(tester);
      p.setWorldClock({
        'events': [
          {
            'id': 'event',
            'realm': 'mezzano',
            'status': 'pending',
            'party': [
              {'power': 100},
              {'power': 60},
            ],
          },
        ],
      });
      expect(
        p.worldChooseEvent(
          'event',
          'fight',
          monsterId: 'guardia_solare',
          count: 3,
        ),
        isTrue,
      );
      final event = (p.worldClockPrivate()['events'] as List).single as Map;
      expect(event['targetPower'], 200);
      expect(
        (event['creatures'] as List).whereType<Map>().fold<int>(
          0,
          (sum, creature) => sum + readIntValue(creature['power']),
        ),
        200,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'connected players cannot advance time and accept only authenticated fresh Master clocks',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.setWorldClock({});
      state.realtimeService = _ClockTransport('player');
      state.modalitaMaster = true;
      state.realtimeVisibleInitiativeSnapshot = {
        ...Map<String, dynamic>.from(
          state.realtimeVisibleInitiativeSnapshot as Map,
        ),
        'campaignId': state.activeCampaignId,
      };
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master-session',
          'role': 'master',
          'activeSheetTag': 'MasterOcu:3690AAAA',
        },
      ];
      p.worldTurn('encounter_1', 'illegal');
      expect(p.worldSeconds(), 0);
      final payload = <String, dynamic>{
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'senderRole': 'master',
        'senderTag': 'MasterOcu:3690AAAA',
        'sessionId': 'master-session',
        'worldClockSnapshot': {
          'seconds': 22000,
          'revision': 2,
          'events': [
            {'mimic': true},
          ],
        },
      };
      p.worldControl({...payload, 'senderRole': 'player'});
      expect(p.worldSeconds(), 0);
      p.worldControl(payload);
      expect(p.worldSeconds(), 22000);
      expect(
        jsonEncode(state.realtimeVisibleInitiativeSnapshot['worldClock']),
        isNot(contains('mimic')),
      );
      p.worldControl({
        ...payload,
        'worldClockSnapshot': {'seconds': 5, 'revision': 1},
      });
      expect(p.worldSeconds(), 22000);
      await closeFixture(tester, p);
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'the discreet clock remains readable without layout errors at $width',
      (tester) async {
        final (_, p) = await fixtures.mountFight(tester);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        p.setWorldClock({'seconds': 21600});
        final entry = OverlayEntry(
          builder: (_) => Align(
            alignment: Alignment.topCenter,
            child: Material(
              child: SizedBox(width: width, child: p.worldClockWidget()),
            ),
          ),
        );
        Overlay.of(tester.element(find.byType(Scaffold).first)).insert(entry);
        await tester.pump();
        expect(find.text('6:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
        entry.remove();
        await tester.pump();
        await closeFixture(tester, p);
      },
    );
  }
}
