import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class _SleepTransport extends OculumRealtimeService {
  _SleepTransport(String role)
    : super(
        roomId: 'sleep-test',
        playerName: 'Sleep',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = role;
  }
  final sent = <Map<String, dynamic>>[];
  bool delivered = true;
  @override
  bool get isConnected => true;
  @override
  Future<bool> sendPermissionEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add({'event': event, ...payload});
    return delivered;
  }

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (authenticatedRole == 'player' && event == 'initiative_control') {
      throw StateError('The backend reserves this event for staff.');
    }
    sent.add({'event': event, ...payload});
    return delivered;
  }
}

Future<(dynamic, OculumPerformanceProbe)> _mount(WidgetTester tester) async {
  final (s, p) = await fixtures.mountFight(tester);
  s.arti.clear();
  s.skills.clear();
  s.titoli.clear();
  s.trattiRazziali.clear();
  s.inventario.clear();
  s.activeConditions.clear();
  s.activeStructuredEffects.clear();
  s.livelloController.text = '0';
  s.gradoController.text = '0';
  s.resilienzaController.text = '10';
  s.currentResilienzaController.text = '10';
  s.volontaController.text = '10';
  s.currentVolontaController.text = '1';
  s.materiaController.text = '10';
  s.currentMateriaController.text = '1';
  s.oculumController.text = '0';
  s.currentOculumController.text = '0';
  s.manualHpMaximumAdjustment = 0;
  s.tempResilienza = 0;
  s.tempVolonta = 0;
  s.tempMateria = 0;
  s.tempOculum = 0;
  s.cenereController.text = '0';
  s.currentHpController.text = '1';
  s.schedePersonaggio[0]['planarRuntime'] = <String, dynamic>{
    'personalNeedsEnabled': true,
  };
  p.invalidateDerivedCaches();
  p.setWorldClock({});
  expect(p.maximumHp(), 60);
  return (s, p);
}

void _reload(
  dynamic state,
  OculumPerformanceProbe probe,
  Map<String, dynamic> saved,
) {
  final restored = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
  state.schedePersonaggio[state.schedaCorrente] = restored;
  probe.load(restored);
}

void main() {
  test(
    'night sleep reaches Morning while preserving minimum and longer choices',
    () {
      expect(oculumSleepDurationMinutes(6 * 3600, 90), 180);
      expect(oculumSleepDurationMinutes(8 * 3600, 90), 90);
      expect(oculumSleepDurationMinutes(8 * 3600 + 30 * 60, 180), 180);
      expect(oculumSleepDurationMinutes(3 * 3600, 90), 90);
      expect(oculumSleepDurationMinutes(8 * 3600 + 59 * 60 + 59, 1), 90);
    },
  );

  test(
    '90 minute baseline and gradual capped recovery preserve overmaximum',
    () {
      final rules = OculumSleepRecoveryRules();
      expect(oculumSleepHpTarget(20, 100, 90), 75);
      expect(oculumSleepHpTarget(20, 100, 120), 80);
      expect(oculumSleepHpTarget(20, 100, 180), 90);
      expect(oculumSleepHpTarget(20, 100, 10000), 100);
      expect(oculumSleepHpTarget(150, 100, 90), 150);
      expect(oculumSleepResilienceTarget(10, 30, 90), 20);
      expect(oculumSleepResilienceTarget(10, 30, 120), 22);
      expect(oculumSleepResilienceTarget(10, 30, 240), 30);
      expect(oculumSleepResilienceTarget(40, 30, 240), 40);
      expect(oculumSleepArtTarget(0, 100, 90), 25);
      expect(oculumSleepArtTarget(0, 100, 180), 40);
      expect(oculumSleepArtTarget(0, 100, 90, exhausted: true), 10);
      expect(oculumSleepArtTarget(0, 100, 180, exhausted: true), 16);
      expect(oculumSleepArtTarget(0, 100, 10000, exhausted: true), 40);
      expect(oculumSleepArtTarget(150, 100, 90), 150);
      expect(rules.hpPercent(119), 75);
    },
  );

  test(
    'custom recovery balance round trips without changing the base schema',
    () {
      final custom = OculumSleepRecoveryRules({
        'hpStepPercent': 7,
        'resilienceStepPercent': 12,
        'artStepPercent': 9,
        'exhaustedArtCapPercent': 35,
      });
      final copy = OculumSleepRecoveryRules(
        jsonDecode(jsonEncode(custom.toJson())),
      );
      expect(copy.hpPercent(120), 82);
      expect(copy.resiliencePercent(120), 62);
      expect(copy.artPercent(120), 34);
      expect(copy.artPercent(10000, exhausted: true), 35);
    },
  );

  test('dawn fade exact boundaries and shared clock round trip', () {
    const level = 5; // Full Night bonus is +10.
    for (final (at, expected) in const [
      (8 * 3600 + 29 * 60 + 59, 10),
      (8 * 3600 + 30 * 60, 10),
      (8 * 3600 + 45 * 60, 5),
      (9 * 3600 - 1, 0),
      (9 * 3600, 0),
    ]) {
      final clock = OculumWorldClockProgress.fromJson(
        jsonDecode(jsonEncode(OculumWorldClockProgress(seconds: at).toJson())),
      );
      expect(
        oculumWorldMonsterCoreBonus(clock.seconds, level, 0, isMonster: true),
        expected,
      );
    }
    expect(oculumWorldMonsterCoreBonus(5 * 3600, level, 0, isMonster: true), 1);
    expect(
      oculumWorldMonsterCoreBonus(8 * 3600, level, 0, isMonster: false),
      0,
    );
    expect(
      oculumWorldMonsterCoreBonus(
        8 * 3600 + 45 * 60,
        level,
        0,
        isMonster: true,
        dawnFadeSeconds: 3600,
      ),
      2,
    );
    final private = OculumWorldClockProgress.fromJson({
      'rules': {'dawnFadeSeconds': 1800, 'privateBalanceNote': 'Master only'},
      'events': [
        {'secret': 'Hidden encounter'},
      ],
    });
    expect(private.toJson()['rules']['privateBalanceNote'], 'Master only');
    expect(jsonEncode(private.publicJson()), isNot(contains('Master only')));
    expect(
      jsonEncode(private.publicJson()),
      isNot(contains('Hidden encounter')),
    );
  });

  test('calendar migration preserves saved date and wraps all 369 days', () {
    expect(
      oculumCalendarDayAt(
        20 * oculumSleepDaySeconds,
        originDay: 368,
        originOrdinal: 20,
      ),
      368,
    );
    expect(
      oculumCalendarDayAt(
        22 * oculumSleepDaySeconds,
        originDay: 368,
        originOrdinal: 20,
      ),
      1,
    );
    expect(
      oculumCalendarDayAt(
        23 * oculumSleepDaySeconds,
        originDay: 368,
        originOrdinal: 20,
      ),
      2,
    );
  });

  test(
    'independent snapshot channels cannot rewind clock or erase its origin',
    () {
      const current = {'revision': 7, 'seconds': 1200, 'calendarOriginDay': 20};
      expect(
        oculumWorldClockSnapshotFollows({
          'revision': 6,
          'seconds': 1300,
          'calendarOriginDay': 20,
        }, current),
        isFalse,
      );
      expect(
        oculumWorldClockSnapshotFollows({
          'revision': 8,
          'seconds': 1100,
          'calendarOriginDay': 20,
        }, current),
        isFalse,
      );
      expect(
        oculumWorldClockSnapshotFollows({
          'revision': 7,
          'seconds': 1200,
        }, current),
        isFalse,
      );
      expect(oculumWorldClockSnapshotFollows(current, current), isTrue);
      expect(
        oculumWorldClockSnapshotFollows({
          'revision': 8,
          'seconds': 1200,
          'calendarOriginDay': 50,
        }, current),
        isTrue,
      );
    },
  );

  test('food OR water has one shared penalty and independent satisfaction', () {
    final needs = OculumPersonalNeedsProgress.fromJson({}, now: 0);
    needs.advanceTo(oculumSleepDaySeconds, random: _ZeroRandom());
    expect(needs.episodes, hasLength(1));
    expect(needs.ash, 3);
    expect(needs.statPenalty('resilienza'), -1);
    needs.satisfy('food', oculumSleepDaySeconds);
    expect(needs.ash, 3, reason: 'Water deprivation still exists.');
    expect(needs.daysWithout('food', oculumSleepDaySeconds), 0);
    expect(needs.daysWithout('water', oculumSleepDaySeconds), 1);
    needs.satisfy('water', oculumSleepDaySeconds);
    expect(needs.ash, 0);
    expect(needs.statPenalty('resilienza'), 0);
  });

  test('only food is penalized if water was recently supplied', () {
    final needs = OculumPersonalNeedsProgress.fromJson({}, now: 0);
    needs.satisfy('water', 8 * 3600);
    needs.advanceTo(oculumSleepDaySeconds, random: _ZeroRandom());
    expect(needs.episodes.single['needs'], ['food']);
    needs.satisfy('food', oculumSleepDaySeconds);
    expect(needs.episodes, isEmpty);
  });

  test(
    'three sleepless days add two tagged stat penalties without food overlap',
    () {
      final needs = OculumPersonalNeedsProgress.fromJson({
        'config': {'foodEnabled': false, 'waterEnabled': false},
      }, now: 0);
      needs.advanceTo(3 * oculumSleepDaySeconds - 1);
      expect(needs.episodes, isEmpty);
      needs.advanceTo(3 * oculumSleepDaySeconds);
      expect(needs.statPenalty('resilienza'), -1);
      expect(needs.statPenalty('oculum'), -1);
      needs.advanceTo(6 * oculumSleepDaySeconds);
      expect(needs.statPenalty('resilienza'), -2);
      needs.satisfy('food', 6 * oculumSleepDaySeconds);
      expect(needs.statPenalty('resilienza'), -2);
      needs.satisfy('sleep', 6 * oculumSleepDaySeconds);
      expect(needs.statPenalty('resilienza'), 0);
      expect(needs.daysWithout('water', 6 * oculumSleepDaySeconds), 0);
    },
  );

  test(
    'round trip and repeated or older snapshots never duplicate deprivation',
    () {
      var needs = OculumPersonalNeedsProgress.fromJson({}, now: 0);
      needs.advanceTo(3 * oculumSleepDaySeconds, random: _ZeroRandom());
      final original = jsonEncode(needs.toJson());
      needs = OculumPersonalNeedsProgress.fromJson(
        jsonDecode(original),
        now: 3 * oculumSleepDaySeconds,
      );
      needs.advanceTo(3 * oculumSleepDaySeconds, random: _ZeroRandom());
      needs.advanceTo(oculumSleepDaySeconds, random: _ZeroRandom());
      expect(jsonEncode(needs.toJson()), original);
      expect(needs.ash, 9);
      expect(needs.episodes, hasLength(4));
    },
  );

  test(
    'a delayed sleep receipt does not erase deprivation after the real rest',
    () {
      final needs = OculumPersonalNeedsProgress.fromJson({}, now: 0);
      needs.advanceTo(4 * oculumSleepDaySeconds, random: _ZeroRandom());
      needs.satisfy('sleep', oculumSleepDaySeconds ~/ 2);
      needs.advanceTo(4 * oculumSleepDaySeconds, random: _ZeroRandom());
      expect(needs.ash, 12);
      expect(
        needs.episodes.where((e) => (e['needs'] as List).contains('sleep')),
        hasLength(1),
      );
      final restored = OculumPersonalNeedsProgress.fromJson(
        needs.toJson(),
        now: oculumSleepDaySeconds ~/ 4,
      );
      expect(
        restored.last['sleep'],
        oculumSleepDaySeconds ~/ 2,
        reason: 'An older snapshot must not rewind the last fulfilled need.',
      );
    },
  );

  testWidgets(
    'request does not heal; confirmed three-hour sleep applies once',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.masterInitiativeTokens.clear();
      final title = OculumTitle(
        nome: 'Riposo test',
        tipo: 'Standard',
        ottenimento: '',
        buff: '',
        puntoCieco: '',
        skill: '',
        richiede: '',
        evoluto: true,
        equipaggiato: true,
        openName: 'Open riposo',
      );
      s.titoli.add(title);
      p.useTitleOpen(title);
      // The evolved always-visible Title grants +5 RES at grade zero when
      // Oculum is absent. This test must include that real permanent bonus.
      expect(p.maximumHp(), 90);
      p.setWorldClock({'seconds': 6 * 3600});
      p.requestSleepRest();
      expect(p.currentHp(), 1);
      expect(p.resourceCurrent('volonta'), 1);
      final rest = (p.worldClockPrivate()['rests'] as List).single as Map;
      expect(p.worldConfirmRest('${rest['id']}', 89), isFalse);
      expect(p.worldConfirmRest('${rest['id']}', 90), isTrue);
      expect(p.worldSeconds(), 9 * 3600);
      expect(p.currentHp(), 81); // 180 minutes => at least 90% of 90.
      expect(p.resourceCurrent('volonta'), 10);
      expect(title.openLifecycle['longRests'], 1);
      expect(title.openLifecycle['shortRests'], 0);
      expect(title.openUsedSinceLongRest, isTrue);
      final after = p.snapshot();
      final clock = p.worldClockPublic();
      expect(p.worldConfirmRest('${rest['id']}', 180), isFalse);
      _reload(s, p, after);
      s.longRestInProgress = false;
      s.currentHpController.text = '2';
      p.syncWorldNeeds(clock);
      expect(p.currentHp(), 2, reason: 'Replayed grant must not heal again.');
      expect((p.needsSnapshot()['restReceipts'] as List), ['${rest['id']}']);
      await tester.pump(const Duration(milliseconds: 500));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'a Monster sleeping across dawn recovers using final daytime HP maximum, not cached nighttime power',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.tipoSchedaController.text = 'Mostro';
      s.schedePersonaggio[0]['tipoScheda'] = 'Mostro';
      p.setWorldClock({'seconds': 6 * 3600});
      expect(p.worldMonsterBonus(0), 5);
      expect(p.maximumHp(), 90); // Populate any derived cache at Night.
      expect(p.currentHp(), 1);
      p.requestSleepRest();
      final rest = (p.worldClockPrivate()['rests'] as List).single as Map;
      expect(p.worldConfirmRest('${rest['id']}', 90), true);
      expect(p.worldSeconds(), 9 * 3600);
      expect(p.worldMonsterBonus(0), 0);
      expect(p.maximumHp(), 60);
      expect(p.currentHp(), 54); // Three-hour sleep: 90% of daytime 60.
      expect(p.resourceCurrent('resilienza'), 10);
      await tester.pump(const Duration(milliseconds: 500));
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'legacy confirmed rest history is not paid a second time on upgrade',
    (tester) async {
      final (s, p) = await _mount(tester);
      p.setWorldClock({
        'seconds': 5400,
        'revision': 1,
        'rests': [
          {
            'id': 'legacy-rest',
            'status': 'confirmed',
            'longRest': true,
            'minutes': 90,
            'requestedBy': [p.ownerTag()],
          },
        ],
      });
      p.syncWorldNeeds(p.worldClockPublic());
      expect(p.currentHp(), 1);
      expect(p.resourceCurrent('volonta'), 1);
      expect(p.needsSnapshot()['restReceipts'], ['legacy-rest']);
      expect(
        (p.worldClockPrivate()['rests'] as List)
            .single['effectsAlreadyAppliedTags'],
        [p.ownerTag()],
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'waiting advances calendar/needs but grants no sleep or resource recovery',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.oculumCurrentDayController.text = '368';
      p.setWorldClock({});
      final id = '${s.activeCampaignId}';
      expect(
        p.advanceWorldTime('two-days', 2 * oculumSleepDaySeconds, id),
        isTrue,
      );
      expect(s.oculumCurrentDayController.text, '1');
      expect(p.currentHp(), 1);
      expect(p.resourceCurrent('volonta'), 1);
      expect(p.effectiveAsh(), 6);
      expect((p.needsSnapshot()['episodes'] as List), hasLength(2));
      expect(
        p.worldClockPrivate()['checks'],
        isEmpty,
        reason: 'Waiting never produces travel events.',
      );
      expect(
        p.advanceWorldTime('two-days', 2 * oculumSleepDaySeconds, id),
        isFalse,
      );
      expect(p.effectiveAsh(), 6);
      expect(p.advanceWorldTime('negative', -1, id), isFalse);
      expect(
        p.advanceWorldTime('oversized', 31 * oculumSleepDaySeconds, id),
        isFalse,
      );
      expect(p.advanceWorldTime('other', 600, 'different-campaign'), isFalse);
      final clock = jsonEncode(p.worldClockPrivate());
      s.modalitaMaster = false;
      s.isMasterHost = false;
      s.sonoCoMaster = false;
      expect(p.advanceWorldTime('player', 600, id), isFalse);
      expect(jsonEncode(p.worldClockPrivate()), clock);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'dawn fades temporary monster stats without healing or writing base stats',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.schedePersonaggio[0]['tipoScheda'] = 'Mostro';
      s.tipoSchedaController.text = 'Mostro';
      s.schedePersonaggio[0]['livello'] = '5';
      s.livelloController.text = '5';
      p.setWorldClock({'seconds': 8 * 3600 + 30 * 60});
      expect(p.worldMonsterBonus(0), 10);
      p.advanceWorldTime('dawn-half', 15 * 60, '${s.activeCampaignId}');
      expect(p.worldMonsterBonus(0), 5);
      expect(p.currentHp(), 1);
      expect(s.resilienzaController.text, '10');
      expect(p.resourceCurrent('resilienza'), 10);
      final saved = p.snapshot();
      _reload(s, p, saved);
      expect(p.worldMonsterBonus(0), 5);
      p.advanceWorldTime('dawn-end', 15 * 60, '${s.activeCampaignId}');
      expect(p.worldMonsterBonus(0), 0);
      expect(p.currentHp(), 1);
      expect(s.resilienzaController.text, '10');
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'three needs stay independent and unrelated debuffs survive meals',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.tempMateria = -4;
      p.advanceWorldTime(
        'three-days',
        3 * oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(p.effectiveAsh(), 9);
      final before = p.needsSnapshot();
      s.schedePersonaggio[0]['realtimeSharedSheet'] = true;
      expect(
        p.effectiveAsh(),
        9,
        reason: 'Staff copy can read the owner ledger.',
      );
      p.satisfyNeed('food');
      p.satisfyNeed('water');
      expect(
        p.effectiveAsh(),
        9,
        reason: 'A shared copy cannot clear owner needs.',
      );
      s.schedePersonaggio[0]['realtimeSharedSheet'] = false;
      p.satisfyNeed('food');
      expect(p.effectiveAsh(), 9);
      p.satisfyNeed('water');
      expect(p.effectiveAsh(), 0);
      expect(p.needsStatPenalty('resilienza'), -1);
      expect(p.needsStatPenalty('oculum'), -1);
      expect(s.tempMateria, -4);
      p.satisfyNeed('sleep');
      expect(p.needsStatPenalty('resilienza'), 0);
      expect(s.tempMateria, -4);
      expect(before['lastsleep'], 0);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'meeting needs removes only their Ash and preserves other fatigue',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.cenereController.text = '4';
      p.advanceWorldTime(
        'one-hungry-day',
        oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(p.effectiveAsh(), 7);
      p.satisfyNeed('food');
      p.satisfyNeed('water');
      expect(p.effectiveAsh(), 4);
      expect(s.cenereController.text, '4');
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'a hunger penalty cannot become an extra permanent resource after a Short Rest and meal',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.schedePersonaggio[0]['planarRuntime']['worldNeedsCampaigns'] =
          <String, dynamic>{
            '${s.activeCampaignId}': {
              'episodes': [
                {
                  'id': 'hunger-test',
                  'needs': ['food'],
                  'stats': {'resilienza': -1},
                  'ash': 3,
                },
              ],
            },
          };
      p.invalidateDerivedCaches();
      expect(p.needsStatPenalty('resilienza'), -1);
      expect(p.resourceCurrent('resilienza'), 10);
      expect(p.coreStats()['resilienza'], 9);
      expect(p.resourceMaximum('resilienza'), 10);
      p.recoverShortRestStats();
      expect(p.resourceCurrent('resilienza'), 10);
      p.satisfyNeed('food');
      expect(p.needsStatPenalty('resilienza'), 0);
      expect(p.coreStats()['resilienza'], 10);
      expect(p.resourceCurrent('resilienza'), 10);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Night increases effective monster power without reducing the normal resource recovery ceiling',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.tipoSchedaController.text = 'Mostro';
      s.schedePersonaggio[0]['tipoScheda'] = 'Mostro';
      s.currentResilienzaController.text = '2';
      p.setWorldClock({'seconds': 6 * 3600});
      p.invalidateDerivedCaches();
      expect(p.worldMonsterBonus(0), 5);
      expect(p.resourceMaximum('resilienza'), 10);
      p.recoverShortRestStats();
      expect(p.resourceCurrent('resilienza'), 4); // ceil((10-2)/4) =2.
      expect(p.coreStats()['resilienza'], 9);
      p.setWorldClock({'seconds': 9 * 3600});
      p.invalidateDerivedCaches();
      expect(p.coreStats()['resilienza'], 4);
      expect(p.resourceCurrent('resilienza'), 4);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'plasma temporary Materia keeps its existing compensation together with hunger and Night',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.tipoSchedaController.text = 'Mostro';
      s.schedePersonaggio[0]['tipoScheda'] = 'Mostro';
      s.schedePersonaggio[0]['planarRuntime']['plasmaTemporaryMatter'] = 3;
      s.schedePersonaggio[0]['planarRuntime']['worldNeedsCampaigns'] =
          <String, dynamic>{
            '${s.activeCampaignId}': {
              'episodes': [
                {
                  'id': 'matter-hunger',
                  'needs': ['food'],
                  'stats': {'materia': -1},
                  'ash': 3,
                },
              ],
            },
          };
      p.setWorldClock({'seconds': 6 * 3600});
      p.invalidateDerivedCaches();
      expect(p.needsStatPenalty('materia'), -1);
      expect(p.worldMonsterBonus(0), 5);
      expect(p.resourceMaximum('materia'), 10);
      p.recoverShortRestStats();
      expect(p.resourceCurrent('materia'), 4);
      expect(p.coreStats()['materia'], 11); //4 current +3plasma +5Night -1need.
      expect(
        s.schedePersonaggio[0]['planarRuntime']['plasmaTemporaryMatter'],
        3,
      );
      await closeFixture(tester, p);
    },
  );
  testWidgets('consumed meals and drinks satisfy only their declared need', (
    tester,
  ) async {
    final (s, p) = await _mount(tester);
    s.cenereController.text = '4';
    p.advanceWorldTime(
      'before-supplies',
      oculumSleepDaySeconds,
      '${s.activeCampaignId}',
    );
    final meal = p.merchantItem({
      'id': 'meal_test',
      'kind': 'food',
      'name': 'Provvista del test',
      'resilienza': 1,
    });
    s.inventario.add(meal);
    await p.useMerchantItem(meal);
    expect(p.needsSnapshot()['lastfood'], oculumSleepDaySeconds);
    expect(p.needsSnapshot()['lastwater'], 0);
    expect(p.effectiveAsh(), 7, reason: 'Water and unrelated fatigue remain.');
    final drink = p.merchantItem({
      'id': 'drink_test',
      'kind': 'food',
      'name': 'Acqua del test',
      'volonta': 1,
    });
    s.inventario.add(drink);
    await p.useMerchantItem(drink);
    expect(p.needsSnapshot()['lastwater'], oculumSleepDaySeconds);
    expect(p.effectiveAsh(), 4);
    expect(s.cenereController.text, '4');
    expect(p.needsSnapshot()['lastsleep'], 0);
    await closeFixture(tester, p);
  });

  testWidgets(
    'corruption counts actual nights while awake, not daytime sleeps',
    (tester) async {
      final (s, p) = await _mount(tester);
      p.addCondition('corruzione');
      final condition = p.conditions.singleWhere(
        (c) => c.conditionType == 'corruzione',
      );
      condition.metadata.addAll({
        'corruptionRulesVersion': 2,
        'corruptionKind': 'rossa',
        'elapsedNights': 4,
        'antiCorruptionDoses': 1,
      });
      p.advanceWorldTime(
        'two-awake-nights',
        2 * oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(condition.metadata['elapsedNights'], 6);
      expect(condition.metadata['antiCorruptionDoses'], 1);
      expect(
        p.advanceWorldTime(
          'two-awake-nights',
          oculumSleepDaySeconds,
          '${s.activeCampaignId}',
        ),
        isFalse,
      );
      expect(condition.metadata['elapsedNights'], 6);
      p.requestSleepRest();
      final rest = (p.worldClockPrivate()['rests'] as List).single as Map;
      p.worldConfirmRest('${rest['id']}', 90);
      expect(
        condition.metadata['elapsedNights'],
        6,
        reason: 'A daytime Long Rest is not an elapsed Night.',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'night sleep counts one corruption night, not one plus a rest tick',
    (tester) async {
      final (s, p) = await _mount(tester);
      p.setWorldClock({'seconds': 6 * 3600});
      p.addCondition('corruzione');
      final condition = p.conditions.singleWhere(
        (c) => c.conditionType == 'corruzione',
      );
      condition.metadata.addAll({
        'corruptionRulesVersion': 2,
        'corruptionKind': 'rossa',
        'elapsedNights': 2,
      });
      p.requestSleepRest();
      final rest = (p.worldClockPrivate()['rests'] as List).single as Map;
      p.worldConfirmRest('${rest['id']}', 90);
      expect(condition.metadata['elapsedNights'], 3);
      p.syncWorldNeeds(p.worldClockPublic());
      expect(condition.metadata['elapsedNights'], 3);
      await tester.pump(const Duration(milliseconds: 500));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'campaign ledgers and origins do not bleed into another campaign',
    (tester) async {
      final (s, p) = await _mount(tester);
      final first = '${s.activeCampaignId}';
      p.advanceWorldTime('first-day', oculumSleepDaySeconds, first);
      expect(p.effectiveAsh(), 3);
      s.activeCampaignId = 'second-campaign';
      s.oculumCurrentDayController.text = '80';
      p.setWorldClock({});
      expect(p.effectiveAsh(), 0);
      p.advanceWorldTime(
        'second-day',
        oculumSleepDaySeconds,
        'second-campaign',
      );
      expect(s.oculumCurrentDayController.text, '81');
      expect(p.effectiveAsh(), 3);
      s.activeCampaignId = first;
      expect(p.effectiveAsh(), 3);
      expect((p.needsSnapshot()['episodes'] as List), hasLength(1));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'loading a legacy campaign uses its saved date, not the previous campaign',
    (tester) async {
      final (s, p) = await _mount(tester);
      final target = p.campaignSnapshot();
      target['id'] = 'legacy-calendar-target';
      target['worldClock'] = {'seconds': 17 * oculumSleepDaySeconds};
      ((target['schedePersonaggio'] as List).first as Map)['oculumCurrentDay'] =
          '300';
      s.oculumCurrentDayController.text = '4';
      p.loadCampaign(target);
      expect(p.worldClockPrivate()['calendarOriginDay'], 300);
      expect(p.worldClockPrivate()['calendarOriginOrdinal'], 17);
      p.advanceWorldTime(
        'next-target-day',
        oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(s.oculumCurrentDayController.text, '301');
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'elapsed calendar days rot inventory once across the 369-day boundary',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.oculumCurrentDayController.text = '368';
      p.setWorldClock({});
      final item = InventoryItem(
        nome: 'Provvista',
        note: 'Fixture del tempo e della putrefazione.',
        peso: .2,
        quantita: 1,
        putrefazioneSessioni: 2,
        putrefazioneGiornoInizio: 368,
      );
      s.inventario.add(item);
      p.advanceWorldTime(
        'decay-one',
        oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(item.sessioniSegnate, 1);
      expect(item.putrefazioneSessioni, 2);
      p.advanceWorldTime(
        'decay-two',
        oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(s.oculumCurrentDayController.text, '1');
      expect(item.putrefazioneSessioni, 0);
      expect(item.note, contains('Putrefatto da Provvista'));
      final after = jsonEncode(item.toJson());
      expect(
        p.advanceWorldTime(
          'decay-two',
          oculumSleepDaySeconds,
          '${s.activeCampaignId}',
        ),
        isFalse,
      );
      expect(jsonEncode(item.toJson()), after);
      await closeFixture(tester, p);
    },
  );

  testWidgets('nonbiological Constructs need maintenance, not food or water', (
    tester,
  ) async {
    final (s, p) = await _mount(tester);
    s.trattiRazziali.add(
      OculumTitle(
        nome: 'Costrutto',
        tipo: 'Razziale',
        ottenimento: '',
        buff: '@Costrutto',
        puntoCieco: '',
        skill: '',
        richiede: '',
        evoluto: true,
        equipaggiato: true,
      ),
    );
    p.advanceWorldTime(
      'maintenance-due',
      3 * oculumSleepDaySeconds,
      '${s.activeCampaignId}',
    );
    expect(p.effectiveAsh(), 0);
    expect(p.needsStatPenalty('resilienza'), -1);
    expect(p.needsStatPenalty('oculum'), -1);
    // The exemption is derived from the body, not a permanent user override.
    expect(
      (p.needsSnapshot()['config'] as Map).containsKey('foodEnabled'),
      false,
    );
    expect(
      (p.needsSnapshot()['config'] as Map).containsKey('waterEnabled'),
      false,
    );
    p.satisfyNeed('food');
    p.satisfyNeed('water');
    expect(p.needsStatPenalty('resilienza'), -1);
    p.requestSleepRest();
    final rest = (p.worldClockPrivate()['rests'] as List).single as Map;
    p.worldConfirmRest('${rest['id']}', 90);
    expect(p.needsStatPenalty('resilienza'), 0);
    await tester.pump(const Duration(milliseconds: 500));
    await closeFixture(tester, p);
  });

  testWidgets('authenticated-control scope rejects foreign rest requests', (
    tester,
  ) async {
    final (s, p) = await _mount(tester);
    p.worldControl({
      'scope': 'foreign',
      'campaignId': s.activeCampaignId,
      'id': 'spoof',
      'worldClockCommand': 'rest_request',
      'longRest': true,
      'senderTag': p.ownerTag(),
    });
    expect(p.worldClockPrivate()['rests'], isEmpty);
    expect(p.currentHp(), 1);
    await closeFixture(tester, p);
  });

  testWidgets('clones and Eyes have no human needs unless explicitly enabled', (
    tester,
  ) async {
    final (s, p) = await _mount(tester);
    final saved = p.snapshot();
    saved['planarRuntime'] = <String, dynamic>{};
    saved['isSummon'] = true;
    _reload(s, p, saved);
    p.advanceWorldTime(
      'summon-time',
      4 * oculumSleepDaySeconds,
      '${s.activeCampaignId}',
    );
    expect(p.effectiveAsh(), 0);
    expect(p.needsStatPenalty('resilienza'), 0);
    expect((p.needsSnapshot()['episodes'] as List), isEmpty);
    await closeFixture(tester, p);
  });

  testWidgets(
    'a biological Monster Book character retains food water and sleep needs',
    (tester) async {
      final (s, p) = await _mount(tester);
      final saved = p.snapshot();
      saved['planarRuntime'] = <String, dynamic>{};
      saved['tipoScheda'] = 'Mostro';
      _reload(s, p, saved);
      p.advanceWorldTime(
        'biological-monster',
        3 * oculumSleepDaySeconds,
        '${s.activeCampaignId}',
      );
      expect(p.effectiveAsh(), 9);
      final episodes = (p.needsSnapshot()['episodes'] as List).whereType<Map>();
      expect(
        episodes.any((row) => (row['needs'] as List).contains('food')),
        isTrue,
      );
      expect(
        episodes.any((row) => (row['needs'] as List).contains('water')),
        isTrue,
      );
      expect(
        episodes.any((row) => (row['needs'] as List).contains('sleep')),
        isTrue,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'a delayed initiative snapshot cannot rewind a newer campaign clock',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.realtimeService = _SleepTransport('player');
      s.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master-clock-session',
          'role': 'master',
          'campaignId': 'shared-clock',
          'activeSheetTag': 'MasterOcu:3690AAAA',
        },
      ];
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'shared-clock',
      };
      p.worldControl({
        'scope': p.permissionScope,
        'campaignId': 'shared-clock',
        'senderRole': 'master',
        'senderTag': 'MasterOcu:3690AAAA',
        'sessionId': 'master-clock-session',
        'worldClockSnapshot': {
          'seconds': 1200,
          'revision': 7,
          'calendarOriginDay': 20,
          'calendarOriginOrdinal': 0,
        },
      });
      expect(p.worldSeconds(), 1200);
      final saved = p.snapshot();
      _reload(s, p, saved);
      p.receiveInitiative({
        'senderRole': 'master',
        'sessionId': 'master-clock-session',
        'campaignId': 'shared-clock',
        'revision': 1,
        'snapshot': {
          'tokens': [],
          'worldClock': {
            'seconds': 600,
            'revision': 6,
            'calendarOriginDay': 20,
            'calendarOriginOrdinal': 0,
          },
        },
      });
      expect(p.worldSeconds(), 1200);
      p.worldControl({
        'scope': p.permissionScope,
        'campaignId': 'shared-clock',
        'senderRole': 'master',
        'senderTag': 'MasterOcu:3690AAAA',
        'sessionId': 'master-clock-session',
        'worldClockSnapshot': {
          'seconds': 900,
          'revision': 8,
          'calendarOriginDay': 20,
          'calendarOriginOrdinal': 0,
        },
      });
      expect(
        p.worldSeconds(),
        1200,
        reason: 'A higher revision still cannot move elapsed time backwards.',
      );
      s.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'switching a shared encounter preserves canonical campaign scope and clock',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.realtimeService = _SleepTransport('player');
      s.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'other-device',
          'role': 'master',
          'campaignId': 'wrong-campaign',
        },
      ];
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'actual-campaign',
        'campaignName': 'Actual campaign',
        'worldClock': {'seconds': 2400, 'revision': 3},
      };
      s.realtimeEncounterSnapshots = <Map<String, dynamic>>[];
      p.selectSharedEncounterForSheet();
      expect(p.permissionCampaignId, 'actual-campaign');
      expect(p.worldSeconds(), 2400);
      s.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'closing the fight preserves public campaign clock and removes combat tokens',
    (tester) async {
      final (s, p) = await _mount(tester);
      s.realtimeService = _SleepTransport('player');
      s.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'closing-master',
          'role': 'master',
          'campaignId': 'shared-clock',
        },
      ];
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'shared-clock',
        'campaignName': 'Shared campaign',
        'worldClock': {'seconds': 2400, 'revision': 3},
        'tokens': <Map<String, dynamic>>[],
      };
      p.receiveInitiative({
        'senderRole': 'master',
        'sessionId': 'closing-master',
        'campaignId': 'shared-clock',
        'revision': 1,
        'closed': true,
      });
      expect(p.permissionCampaignId, 'shared-clock');
      expect(p.worldSeconds(), 2400);
      expect(
        s.realtimeVisibleInitiativeSnapshot.containsKey('tokens'),
        isFalse,
      );
      s.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'only the authenticated campaign Master can deliver a recovery grant',
    (tester) async {
      final (s, p) = await _mount(tester);
      final transport = _SleepTransport('player');
      s.realtimeService = transport;
      s.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'master-session',
          'role': 'master',
          'activeSheetTag': 'MasterOcu:3690AAAA',
        },
      ];
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': s.activeCampaignId,
      };
      p.requestSleepRest();
      expect(p.currentHp(), 1);
      expect(transport.sent.last['worldClockCommand'], 'rest_request');
      expect(transport.sent.last['event'], 'permission_request');
      expect(transport.sent.last['action'], 'world_clock');
      final payload = <String, dynamic>{
        'scope': p.permissionScope,
        'campaignId': p.permissionCampaignId,
        'senderRole': 'master',
        'senderTag': 'MasterOcu:3690AAAA',
        'sessionId': 'master-session',
        'worldClockSnapshot': {
          'seconds': 5400,
          'revision': 2,
          'calendarOriginDay': 40,
          'calendarOriginOrdinal': 0,
          'restGrants': [
            {
              'id': 'confirmed-90',
              'status': 'confirmed',
              'longRest': true,
              'minutes': 90,
              'endSeconds': 5400,
              'requestedBy': [p.ownerTag()],
              'requestIds': [transport.sent.last['id']],
            },
          ],
        },
      };
      p.worldControl({...payload, 'senderRole': 'player'});
      expect(p.currentHp(), 1);
      p.worldControl({...payload, 'scope': 'different-room'});
      expect(p.currentHp(), 1);
      p.receivePermission('permission_request', {
        ...payload,
        'action': 'world_clock',
        'worldClockCommand': 'rest_request',
      });
      expect(p.currentHp(), 1);
      expect(
        p.worldSeconds(),
        0,
        reason: 'A request channel cannot carry an authoritative grant.',
      );
      p.worldControl(payload);
      expect(p.currentHp(), 45);
      expect(s.oculumCurrentDayController.text, '40');
      expect(p.needsSnapshot()['restReceipts'], ['confirmed-90']);
      expect(p.needsSnapshot()['restRequests'], isEmpty);
      s.currentHpController.text = '2';
      s.longRestInProgress = false;
      p.worldControl(payload);
      expect(p.currentHp(), 2);
      p.worldControl({
        ...payload,
        'sessionId': 'forged-master-session',
        'worldClockSnapshot': {
          ...payload['worldClockSnapshot'] as Map,
          'revision': 3,
          'seconds': 9000,
        },
      });
      expect(p.worldSeconds(), 5400);
      s.realtimeService = null;
      await tester.pump(const Duration(milliseconds: 500));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'lost rest requests persist and retry the same ID only in their campaign',
    (tester) async {
      final (s, p) = await _mount(tester);
      final transport = _SleepTransport('player')..delivered = false;
      s.realtimeService = transport;
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'shared-sleep-campaign',
      };
      p.requestSleepRest();
      final id = transport.sent.last['id'];
      expect((p.needsSnapshot()['restRequests'] as List), hasLength(1));
      final saved =
          jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
      _reload(s, p, saved);
      transport.delivered = true;
      await p.flushRestRequests();
      expect(transport.sent.last['id'], id);
      expect(p.currentHp(), 1);
      final count = transport.sent.length;
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'different-shared-campaign',
      };
      await p.flushRestRequests();
      expect(transport.sent, hasLength(count));
      s.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
        'campaignId': 'shared-sleep-campaign',
      };
      p.requestSleepRest();
      expect(transport.sent.last['id'], id);
      expect((p.needsSnapshot()['restRequests'] as List), hasLength(1));
      s.realtimeService = null;
      await closeFixture(tester, p);
    },
  );

  test(
    'physiological defaults are not serialized and explicit configuration wins',
    () {
      final progress = OculumPersonalNeedsProgress.fromJson(
        {},
        now: 0,
        physiologicalDefaults: const {
          'foodEnabled': false,
          'waterEnabled': false,
        },
      );
      expect(progress.enabled('food'), false);
      expect(progress.enabled('water'), false);
      progress.advanceTo(oculumSleepDaySeconds, random: _ZeroRandom());
      final saved =
          jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>;
      expect((saved['config'] as Map).containsKey('foodEnabled'), false);
      final human = OculumPersonalNeedsProgress.fromJson(
        saved,
        now: oculumSleepDaySeconds,
      );
      expect(human.enabled('food'), true);
      human.advanceTo(2 * oculumSleepDaySeconds, random: _ZeroRandom());
      expect(
        human.ash,
        3,
        reason:
            'Only the biological day is hungry, not the earlier Construct day.',
      );
      final explicit = OculumPersonalNeedsProgress.fromJson({
        'config': {'foodEnabled': false, 'waterEnabled': false},
      }, now: 0);
      expect(explicit.enabled('food'), false);
      expect((explicit.toJson()['config'] as Map)['foodEnabled'], false);
      final constructWithOverride = OculumPersonalNeedsProgress.fromJson(
        {
          'config': {'foodEnabled': true},
        },
        now: 0,
        physiologicalDefaults: const {'foodEnabled': false},
      );
      expect(constructWithOverride.enabled('food'), true);
    },
  );

  for (final explicitExemption in [false, true]) {
    testWidgets(
      'Construct to biological after JSON recalculates only defaults; explicitExemption=$explicitExemption',
      (tester) async {
        final (s, p) = await _mount(tester);
        s.trattiRazziali.add(
          OculumTitle(
            nome: 'Costrutto',
            tipo: 'Razziale',
            ottenimento: '',
            buff: '@Costrutto',
            puntoCieco: '',
            skill: '',
            richiede: '',
            evoluto: true,
            equipaggiato: true,
          ),
        );
        if (explicitExemption) {
          final saved = p.snapshot();
          saved['planarRuntime'] = <String, dynamic>{
            ...Map<String, dynamic>.from(saved['planarRuntime'] as Map),
            'personalNeedsRules': {'foodEnabled': false, 'waterEnabled': false},
          };
          _reload(s, p, saved);
        }
        expect(
          p.advanceWorldTime(
            'construct-profile-day',
            oculumSleepDaySeconds,
            '${s.activeCampaignId}',
          ),
          true,
        );
        expect(p.effectiveAsh(), 0);
        _reload(s, p, p.snapshot());
        s.trattiRazziali.clear();
        p.invalidateDerivedCaches();
        expect(
          p.advanceWorldTime(
            'biological-profile-day',
            oculumSleepDaySeconds,
            '${s.activeCampaignId}',
          ),
          true,
        );
        expect(p.effectiveAsh(), explicitExemption ? 0 : 3);
        final config = p.needsSnapshot()['config'] as Map;
        if (explicitExemption) {
          expect(config['foodEnabled'], false);
          expect(config['waterEnabled'], false);
          _reload(s, p, p.snapshot());
          expect((p.needsSnapshot()['config'] as Map)['foodEnabled'], false);
        } else {
          expect(config.containsKey('foodEnabled'), false);
          expect(config.containsKey('waterEnabled'), false);
        }
        await closeFixture(tester, p);
      },
    );
  }
}
