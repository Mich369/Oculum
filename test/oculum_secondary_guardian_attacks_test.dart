import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Map<String, dynamic> _original({
  String hero = 'HERO',
  bool reflection = false,
}) => {
  'id': 'original-one',
  'sourceTag': reflection ? hero : 'ENEMY',
  'targetTag': reflection ? 'ENEMY' : hero,
  'scope': 'scope',
  'encounterId': 'encounter_1',
  'status': 'resolved',
  'outcome': 'full',
  'attack': 1000000,
  'damage': 100,
  'kind': 'attack',
  'lunarGuardianStone': !reflection,
  'lunarGuardianEruptionDamage': 10,
  if (reflection) 'guardianGoldReflection': {'damage': 15},
};
Map<String, dynamic> _packet(
  Map original, {
  String fight = 'legacy:0',
  bool reflection = false,
}) => {
  'id': oculumGuardianSecondaryId(
    reflection ? 'gold_reflection' : 'lunar_eruption',
    '${original['id']}',
  ),
  'kind': 'guardian_secondary',
  'guardianSecondaryEvent': true,
  'guardianSecondaryStage': 'offer',
  'guardianSecondaryKind': reflection ? 'gold_reflection' : 'lunar_eruption',
  'status': 'pending',
  'originalAttackId': original['id'],
  'scope': original['scope'],
  'encounterId': original['encounterId'],
  'creatorTag': original[reflection ? 'targetTag' : 'sourceTag'],
  'sourceTag': original[reflection ? 'targetTag' : 'sourceTag'],
  'targetTag': original[reflection ? 'sourceTag' : 'targetTag'],
  'guardianSecondaryFightInstanceId': fight,
  'attack': original['attack'],
  'damage': reflection ? 15 : 10,
  'guardianSecondaryBaseDamage': reflection ? 15 : 10,
  'baseAttack': false,
  'natural': 10,
  'effects': <dynamic>[],
  'element': reflection ? 'solare' : 'lunare',
  'lunarGuardianEruption': !reflection,
  'abilityName': reflection
      ? 'Riflesso dello scudo d’oro'
      : 'Eruzione degli spuntoni lunari',
};

void main() {
  test(
    'secondary packets cannot choose another damage, victim, creator, original or fight',
    () {
      final original = _original(), packet = _packet(_original());
      bool valid(Map p) => oculumGuardianSecondaryValid(
        p,
        original,
        scope: 'scope',
        encounterId: 'encounter_1',
        fightInstanceId: 'legacy:0',
      );
      expect(valid(packet), true);
      for (final change in [
        {'damage': 999},
        {'targetTag': 'OTHER'},
        {'sourceTag': 'OTHER'},
        {'creatorTag': 'OTHER'},
        {'originalAttackId': 'fake'},
        {'guardianSecondaryFightInstanceId': 'stale'},
        {'scope': 'other'},
        {'encounterId': 'other'},
      ]) {
        expect(valid({...packet, ...change}), false);
      }
      expect(
        oculumGuardianSecondaryValid(
          packet,
          {...original, 'guardianSecondaryEvent': true},
          scope: 'scope',
          encounterId: 'encounter_1',
          fightInstanceId: 'legacy:0',
        ),
        false,
      );
      expect(
        oculumGuardianSecondaryValid(
          packet,
          {...original, 'outcome': 'avoided'},
          scope: 'scope',
          encounterId: 'encounter_1',
          fightInstanceId: 'legacy:0',
        ),
        false,
      );
    },
  );
  test('Gold reflects real melee only, explicit range metadata prevails', () {
    expect(
      oculumGuardianMeleeAttack({'melee': true, 'abilityName': 'Colpo'}),
      true,
    );
    expect(
      oculumGuardianMeleeAttack({'ranged': true, 'abilityName': 'Spadone'}),
      false,
    );
    expect(
      oculumGuardianMeleeAttack({'ranged': false, 'abilityName': 'Colpo'}),
      true,
    );
    expect(
      oculumGuardianMeleeAttack({'melee': false, 'abilityName': 'Spadone'}),
      false,
    );
    expect(
      oculumGuardianMeleeAttack({'baseAttack': true, 'choice': 'vc'}),
      true,
    );
    for (final name in [
      'Raggio di fuoco',
      'Due frecce',
      'Lancio della mazza',
      'Boomerang',
      'Fulmine',
    ]) {
      expect(
        oculumGuardianMeleeAttack({
          'baseAttack': true,
          'choice': 'vc',
          'abilityName': name,
        }),
        false,
      );
    }
    expect(
      oculumGuardianMeleeAttack({'choice': 'vc', 'sourceFirearm': true}),
      false,
    );
    expect(
      oculumGuardianMeleeAttack({'abilityName': 'Magia sconosciuta'}),
      false,
    );
    expect(
      oculumGuardianMeleeAttack({'abilityName': 'Pugno in mischia'}),
      true,
    );
  });
  Future<(dynamic, OculumPerformanceProbe, Map<String, dynamic>)> mount(
    WidgetTester tester, {
    bool reflection = false,
  }) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.masterInitiativeRound = 2;
    state.masterInitiativeActiveIndex = 1;
    final token = state.masterInitiativeTokens.first as Map;
    token.addAll(<String, dynamic>{
      'reactionPoolInitialized': true,
      'reactionPoolRound': 2,
      'reactionNormalFirstRoundLocked': false,
      'reactionMax': 1,
      'reactionUsed': 0,
      'reactionUsedRound': 2,
      'reactionFastMax': 0,
      'reactionFastUsed': 0,
      'reactionFastTurnKey': '2',
    });
    p.recordCurrentEncounter();
    final original = _original(hero: p.ownerTag(), reflection: reflection)
      ..['scope'] = p.permissionScope;
    state.onlineCombatRequests['original-one'] = original;
    final packet = _packet(
      original,
      fight: p.subtraitFightId('encounter_1'),
      reflection: reflection,
    );
    await p.guardianSecondaryReceive(packet, local: true);
    return (
      state,
      p,
      state.onlineCombatRequests[packet['id']] as Map<String, dynamic>,
    );
  }

  testWidgets(
    'Lunar second defense consumes one reaction, stays on same turn, cannot retry or replay',
    (tester) async {
      final (state, p, request) = await mount(tester);
      final before = p.combatTurnResources();
      final turn = state.masterInitiativeActiveIndex;
      expect(before['reactions'], 1);
      await p.guardianSecondaryDefend(request, natural: 1);
      expect(p.combatTurnResources()['reactions'], 0);
      expect(state.masterInitiativeActiveIndex, turn);
      expect(request['status'], 'resolved');
      expect(request['damageReceipt'], isA<Map>());
      final hp = p.currentHp();
      await p.guardianSecondaryDefend(request, retry: true, natural: 20);
      await p.guardianSecondaryDefend(request, acceptDamage: true);
      expect(p.currentHp(), hp);
      expect(p.combatTurnResources()['reactions'], 0);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Lunar declining the dodge costs no reaction and applies the normal damage engine once',
    (tester) async {
      final (_, p, request) = await mount(tester);
      final before = p.combatTurnResources()['reactions'];
      await p.guardianSecondaryDefend(request, acceptDamage: true);
      expect(p.combatTurnResources()['reactions'], before);
      expect(request['status'], 'resolved');
      expect(request['damageReceipt'], isA<Map>());
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Gold has a free first Reflex roll and only one paid retry without initiative advance',
    (tester) async {
      final (state, p, request) = await mount(tester, reflection: true);
      final before = p.combatTurnResources()['reactions'],
          turn = state.masterInitiativeActiveIndex;
      await p.guardianSecondaryDefend(request, natural: 1);
      expect(request['status'], 'pending');
      expect(request['secondaryRetryOffered'], true);
      expect(p.combatTurnResources()['reactions'], before);
      await p.guardianSecondaryDefend(request, retry: true, natural: 1);
      expect(p.combatTurnResources()['reactions'], before! - 1);
      expect(state.masterInitiativeActiveIndex, turn);
      expect(request['status'], 'resolved');
      final hp = p.currentHp();
      await p.guardianSecondaryDefend(request, retry: true, natural: 20);
      expect(p.currentHp(), hp);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'secondary offers survive another selected fight without spending its resources',
    (tester) async {
      final (state, p, request) = await mount(tester);
      final id = '${request['id']}';
      final offer = Map<String, dynamic>.from(request);
      state.onlineCombatRequests.remove(id);
      state.masterInitiativeGroups.add(<String, dynamic>{
        'id': 'encounter_2',
        'name': 'Secondo Fight',
        'fightStarted': true,
        'tokens': <Map<String, dynamic>>[
          {
            'id': 'SECOND',
            'sheetTag': 'SECOND',
            'side': 'party',
            'status': 'active',
          },
          {
            'id': 'FOE2',
            'sheetTag': 'FOE2',
            'side': 'enemy',
            'status': 'ready',
          },
        ],
      });
      p.selectEncounter('encounter_2');
      await p.guardianSecondaryReceive(offer, local: true);
      final pending = state.onlineCombatRequests[id] as Map<String, dynamic>;
      expect(pending['status'], 'pending');
      final hp = p.currentHp();
      await p.guardianSecondaryDefend(pending, acceptDamage: true);
      expect(pending['status'], 'pending');
      expect(p.currentHp(), hp);
      expect(state.selectedMasterInitiativeGroupId, 'encounter_2');
      p.selectEncounter('encounter_1');
      await p.guardianSecondaryDefend(pending, acceptDamage: true);
      expect(pending['status'], 'resolved');
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'authenticated staff NPC reflection waits for the original receipt and stale fights reject replay',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.realtimeUsers = <Map<String, dynamic>>[
        {
          'sessionId': 'staff-session',
          'role': 'master',
          'activeSheetTag': 'MASTER',
          'localSheetTags': ['MASTER'],
        },
      ];
      final original = _original(hero: p.ownerTag(), reflection: true)
        ..remove('guardianGoldReflection')
        ..['scope'] = p.permissionScope;
      state.onlineCombatRequests['original-one'] = original;
      final packet =
          _packet(
              original,
              reflection: true,
              fight: p.subtraitFightId('encounter_1'),
            )
            ..['campaignId'] = p.permissionCampaignId
            ..['senderTag'] = 'MASTER'
            ..['senderRole'] = 'master'
            ..['sessionId'] = 'staff-session';
      await p.guardianSecondaryReceive(packet);
      final id = '${packet['id']}';
      expect(state.onlineCombatRequests[id]['status'], 'waiting_original');
      original['guardianGoldReflection'] = {'damage': 15};
      await p.guardianSecondaryRetryOffers();
      expect(state.onlineCombatRequests[id]['status'], 'pending');
      await p.guardianSecondaryReceive(packet);
      expect(
        state.onlineCombatRequests.values.where((r) => r['id'] == id),
        hasLength(1),
      );
      state.onlineCombatRequests.remove(id);
      state.masterInitiativeTokens[1]['fightInstanceId'] = 'next-fight';
      p.recordCurrentEncounter();
      await p.guardianSecondaryReceive(packet);
      expect(state.onlineCombatRequests.containsKey(id), false);
      await closeFixture(tester, p);
    },
  );
}
