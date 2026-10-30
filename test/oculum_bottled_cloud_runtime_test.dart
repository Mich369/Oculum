import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

class _FixedRoll implements Random {
  _FixedRoll(this.roll);
  final int roll;
  @override
  int nextInt(int max) => roll % max;
  @override
  bool nextBool() => roll.isEven;
  @override
  double nextDouble() => roll / 100;
}

CharacterArt _cloud() =>
    oculumMonsterBookArt(monsterBookEntryById('nuvola_in_bottiglia')!);

Future<(dynamic, OculumPerformanceProbe, CharacterArt)> _mount(
  WidgetTester tester,
) async {
  final (state, probe) = await fixtures.mountFight(tester);
  state.titoli.clear();
  state.arti.clear();
  state.skills.clear();
  state.trattiRazziali.clear();
  state.inventario.clear();
  state.activeStructuredEffects.clear();
  state.activeConditions.clear();
  state.livelloController.text = '3';
  state.gradoController.text = '0';
  state.resilienzaController.text = '10';
  state.currentResilienzaController.text = '10';
  state.volontaController.text = '10';
  state.currentVolontaController.text = '10';
  state.materiaController.text = '10';
  state.currentMateriaController.text = '10';
  state.oculumController.text = '50';
  state.currentOculumController.text = '50';
  state.currentHpController.text = '100';
  state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
      'nuvola_in_bottiglia';
  state.scudoController.text = '0';
  state.scudoOculumController.text = '0';
  state.scudoCriticoController.text = '0';
  state.hpTempController.text = '0';
  final art = _cloud()..hasIntegrity = false;
  state.arti.add(art);
  state.masterInitiativeActiveIndex = 0;
  state.masterInitiativeRound = 2;
  final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
  token.addAll(<String, dynamic>{
    'actionUsed': false,
    'actionTurnRound': 2,
    'kiExtraActions': 0,
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
  probe.invalidateDerivedCaches();
  probe.recordCurrentEncounter();
  return (state, probe, art);
}

Map<String, dynamic> _packet(
  OculumPerformanceProbe probe, {
  required String id,
  required String source,
  required String target,
  List<OculumStructuredEffect> effects = const [],
}) => {
  'id': id,
  'scope': probe.permissionScope,
  'encounterId': 'encounter_1',
  'sourceTag': source,
  'targetTag': target,
  'status': 'pending',
  'effects': effects.map((e) => e.toJson()).toList(),
};

void main() {
  test(
    'cloud Open starts its 15% increase at second target and clamps target cap',
    () {
      expect(oculumCloudOpenDamage(100, 1), 100);
      expect(oculumCloudOpenDamage(100, 2), 115);
      expect(oculumCloudOpenDamage(100, 12), 265);
      expect(oculumCloudOpenDamage(100, 13), 265);
      expect(oculumCloudOpenDamage(-1, 4), 0);
      expect(
        oculumCloudOpenDamage(
          100,
          4,
          percentPerExtraTarget: 20,
          maximumTargets: 3,
        ),
        140,
      );
    },
  );

  test(
    'phase thresholds add recovery, critical bottle takes precedence, lethal stays dead',
    () {
      ({int phase, int hp, int healed, bool bottleBroken}) resolve({
        int phase = 1,
        int hp = 15,
        int lost = 1,
        bool bottle = false,
      }) => oculumBottledCloudPhaseTransition(
        phase: phase,
        hpAfter: hp,
        maximumHp: 100,
        hpLost: lost,
        bottleCritical: bottle,
      );
      expect(resolve(hp: 16).phase, 1);
      expect(resolve().hp, 90);
      expect(resolve().healed, 75);
      expect(resolve(hp: 50, bottle: true).hp, 90);
      expect(resolve(hp: 90, bottle: true).hp, 100);
      expect(resolve(hp: 15, bottle: true).hp, 55);
      expect(resolve(hp: 0, lost: 50, bottle: true).hp, 0);
      expect(resolve(hp: -5, lost: 50, bottle: true).phase, 1);
      expect(resolve(lost: 0, bottle: true).phase, 1);
      expect(resolve(phase: 2, hp: 10, bottle: true).hp, 10);
      expect(
        oculumBottledCloudPhaseTransition(
          phase: 1,
          hpAfter: 20,
          maximumHp: 100,
          hpLost: 1,
          bottleCritical: false,
          thresholdPercent: 25,
          thresholdHealPercent: 50,
        ).hp,
        70,
      );
    },
  );

  test(
    'action interruption consumes only the paid action and preserves both reaction pools',
    () {
      final token = <String, dynamic>{
        'actionUsed': true,
        'kiExtraActions': 0,
        'reactionUsed': 0,
        'reactionFastUsed': 0,
      };
      expect(
        oculumApplyBottledCloudActionLoss(
          token,
          receiptId: 'fight:hit',
          ownTurn: true,
          interruptedAction: true,
        ),
        isTrue,
      );
      expect(token['bottledCloudPendingActions'], 0);
      expect(token['reactionUsed'], 0);
      expect(token['reactionFastUsed'], 0);
      expect(
        oculumApplyBottledCloudActionLoss(
          token,
          receiptId: 'fight:hit',
          ownTurn: true,
        ),
        isFalse,
      );
      final saved = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(token)) as Map,
      );
      expect(
        oculumApplyBottledCloudActionLoss(
          saved,
          receiptId: 'fight:hit',
          ownTurn: true,
        ),
        isFalse,
      );
      saved['actionUsed'] = false;
      expect(oculumConsumeBottledCloudPendingActions(saved), 0);
      expect(saved['actionUsed'], isFalse);
    },
  );

  test(
    'no running action queues exactly the next action, including extra actions',
    () {
      final token = <String, dynamic>{'actionUsed': true};
      oculumApplyBottledCloudActionLoss(
        token,
        receiptId: 'one',
        ownTurn: false,
      );
      expect(token['bottledCloudPendingActions'], 1);
      token['actionUsed'] = false;
      expect(oculumConsumeBottledCloudPendingActions(token), 1);
      expect(token['actionUsed'], isTrue);
      expect(oculumConsumeBottledCloudPendingActions(token), 0);
      token['actionUsed'] = false;
      expect(oculumConsumeBottledCloudPendingActions(token), 0);
      expect(token['actionUsed'], isFalse);
      token['kiExtraActions'] = 2;
      oculumApplyBottledCloudActionLoss(
        token,
        receiptId: 'multi',
        ownTurn: true,
        actions: 2,
      );
      expect(token['kiExtraActions'], 1);
      expect(token['bottledCloudPendingActions'], 0);
    },
  );

  test(
    'fresh cloud catalogue has independent editable effects, costs and cooldowns',
    () {
      final art = _cloud();
      expect(oculumBottledCloudArt(art), isTrue);
      expect(art.openDescriptionEffects.single.diceExpression, '2d50');
      expect(art.openDescriptionEffects.single.valueExpression, 'danni+25');
      expect(art.openDescriptionEffects.single.maximumTargets, 12);
      expect(oculumParseAbilityCost(art.openDescription)!.minimum, 6);
      expect(oculumParseAbilityCost(art.openSkill)!.minimum, 2);
      expect(art.openSkillCooldown!.amount, 3);
      expect(
        oculumCombatAbilityRoles(art.openSkillEffects),
        contains(OculumCombatAbilityRole.attack),
      );
      final stop = art.skills.firstWhere(
        (s) => s.nome == 'Fulmine ferma-azione',
      );
      for (var form = 1; form <= 3; form++) {
        expect(stop.effettiEvoluzione(form).single.recipient, 'nemico');
        expect(stop.effettiEvoluzione(form).single.valueExpression, '25');
        expect(stop.effettiEvoluzione(form).single.resource, '20');
        expect(stop.oculumMinimoPerLivello(form), form + 1);
      }
      art.openSkillEffects.single.valueExpression = '30';
      art.openSkillEffects.single.resource = '35';
      art.openSkillEffects.single.duration = '2';
      art.openSkillEffects.single.narrativeText =
          '{"empoweredDamagePercent":70,"empoweredChancePercent":85}';
      art.openSkillCooldown!.amount = 7;
      final restored = CharacterArt.fromJson(
        jsonDecode(jsonEncode(art.toJson())),
      );
      oculumCompleteMonsterOpen(
        restored,
        name: 'Nuvola in bottiglia',
        level: 3,
        grade: 0,
      );
      expect(restored.openSkillEffects.single.valueExpression, '30');
      expect(restored.openSkillEffects.single.resource, '35');
      expect(restored.openSkillEffects.single.duration, '2');
      expect(restored.openSkillCooldown!.amount, 7);
      expect(_cloud().openSkillEffects.single.resource, '20');
    },
  );

  testWidgets(
    'prepared stop freezes one roll and exact own-Open boost; another Open does not boost',
    (tester) async {
      final (state, probe, art) = await _mount(tester);
      final damage = probe.damageTotal();
      final prepared = probe.prepareBottledCloud(
        art.openSkillEffects,
        random: _FixedRoll(19),
      );
      final packet = _packet(
        probe,
        id: 'base',
        source: probe.ownerTag(),
        target: 'ENEMY',
        effects: prepared,
      );
      probe.claimBottledCloud(packet, 1);
      expect(packet['damage'], damage * 25 ~/ 100);
      expect(oculumBottledCloudStopData(packet)!['succeeded'], isTrue);
      final replayed = probe.prepareBottledCloud(
        prepared,
        random: _FixedRoll(99),
      );
      expect(replayed.single.narrativeText, prepared.single.narrativeText);
      final fail = _packet(
        probe,
        id: 'failed',
        source: probe.ownerTag(),
        target: 'ENEMY',
        effects: probe.prepareBottledCloud(
          art.openSkillEffects,
          random: _FixedRoll(20),
        ),
      );
      probe.claimBottledCloud(fail, 1);
      expect(fail['damage'], packet['damage']);
      expect(oculumBottledCloudStopData(fail)!['succeeded'], isFalse);
      final other = CharacterArt(
        nome: 'Altra',
        tipo: 'Art',
        descrizione: '',
        skills: [],
      )..openAttiva = true;
      state.arti.add(other);
      final unboosted = probe.prepareBottledCloud(
        art.openSkillEffects,
        random: _FixedRoll(30),
      );
      expect(jsonDecode(unboosted.single.narrativeText)['chancePercent'], 20);
      expect(probe.recordArtOpenCycle(0), isTrue);
      art.openAttiva = true;
      final empowered = probe.prepareBottledCloud(
        art.openSkillEffects,
        random: _FixedRoll(59),
      );
      final boosted = _packet(
        probe,
        id: 'boosted',
        source: probe.ownerTag(),
        target: 'ENEMY',
        effects: empowered,
      );
      probe.claimBottledCloud(boosted, 1);
      expect(boosted['damage'], probe.damageTotal() * 50 ~/ 100);
      expect(oculumBottledCloudStopData(boosted)!['succeeded'], isTrue);
      expect(art.openSkillEffects.single.valueExpression, '25');
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'bottle critical needs HP, preserves critical shields, is saved and cannot fire twice',
    (tester) async {
      final (state, probe, _) = await _mount(tester);
      Map<String, dynamic> hit(
        String id, {
        int hpLost = 10,
        bool shield = false,
      }) => _packet(probe, id: id, source: 'ENEMY', target: probe.ownerTag())
        ..['targetBodyPart'] = 'bottle'
        ..['criticalShieldProtected'] = shield
        ..['damageReceipt'] = {'hpLost': hpLost};
      state.currentHpController.text = '50';
      probe.bottledCloudPhase(hit('shield-only', hpLost: 0), critical: true);
      expect(probe.bottledCloudPhaseNumber(), 1);
      probe.bottledCloudPhase(
        hit('critical-protected', shield: true),
        critical: true,
      );
      expect(probe.bottledCloudPhaseNumber(), 1);
      final critical = hit('break-bottle');
      probe.bottledCloudPhase(critical, critical: true);
      expect(probe.currentHp(), 90);
      expect(probe.bottledCloudPhaseNumber(), 2);
      final saved = probe.snapshot();
      probe.load(saved);
      state.currentHpController.text = '40';
      probe.bottledCloudPhase(critical, critical: true);
      probe.bottledCloudPhase(hit('stale-bottle'), critical: true);
      expect(probe.currentHp(), 40);
      expect(probe.bottledCloudPhaseNumber(), 2);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'threshold phase heals 75 percent, lethal does not; foreign scope cannot mutate phase',
    (tester) async {
      final (state, probe, _) = await _mount(tester);
      Map<String, dynamic> hit(String id) =>
          _packet(probe, id: id, source: 'ENEMY', target: probe.ownerTag())
            ..['damageReceipt'] = {'hpLost': 1};
      state.currentHpController.text = '0';
      probe.bottledCloudPhase(
        hit('lethal')..['targetBodyPart'] = 'bottle',
        critical: true,
      );
      expect(probe.currentHp(), 0);
      state.currentHpController.text = '15';
      probe.bottledCloudPhase(
        hit('foreign')..['scope'] = 'foreign',
        critical: false,
      );
      expect(probe.currentHp(), 15);
      probe.bottledCloudPhase(hit('threshold'), critical: false);
      expect(probe.currentHp(), 90);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'real incoming damage receipt triggers the bottle only after actual HP damage',
    (tester) async {
      final (state, probe, _) = await _mount(tester);
      state.scudoSalvataggioAttivo = false;
      state.modificatoreDannoSelezionato = 'Normale';
      // Exercise a real surviving HP hit, independently of derived Defense.
      final maximum = probe.maximumHp();
      state.currentHpController.text = '$maximum';
      final incoming = probe.defense() + 6;
      final packet =
          _packet(
            probe,
            id: 'actual-bottle-hit',
            source: 'ENEMY',
            target: probe.ownerTag(),
          )..addAll({
            'sourceName': 'Nemico',
            'targetName': 'Nuvola',
            'targetBodyPart': 'bottle',
            'targetBodyPartLabel': 'Bottiglia',
            'choice': 'precisione',
            'natural': 20,
            'dieFaces': 20,
            'attack': 40,
            'damage': incoming,
            'baseDamage': incoming,
            'element': 'fisico',
            'level': 3,
            'grade': 0,
          });
      state.onlineCombatRequests[packet['id']] = packet;
      await probe.resolveCombatDefense(packet, 'cm', 10, natural: 10);
      final receipt = packet['damageReceipt'] as Map;
      expect(
        readIntValue(receipt['hpLost']),
        greaterThan(0),
        reason: '$packet',
      );
      expect(probe.bottledCloudPhaseNumber(), 2);
      expect(
        probe.currentHp(),
        min(
          maximum,
          maximum - readIntValue(receipt['hpLost']) + maximum * 40 ~/ 100,
        ),
      );
      expect(packet['bottledCloudPhaseReceipt'], isA<Map>());
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'stop cancels paid pending action without double debit; late packets and JSON replay stay cancelled',
    (tester) async {
      final (state, probe, art) = await _mount(tester);
      final owner = probe.ownerTag();
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      token['actionUsed'] = true;
      final outgoing =
          _packet(probe, id: 'running', source: owner, target: 'OTHER')
            ..['activityResource'] = 'azione'
            ..['attackGroupId'] = 'volley';
      state.onlineCombatRequests['running'] = outgoing;
      final reaction = _packet(
        probe,
        id: 'reaction',
        source: owner,
        target: 'OTHER',
      )..['activityResource'] = 'reazione';
      state.onlineCombatRequests['reaction'] = reaction;
      final stop = _packet(
        probe,
        id: 'stop',
        source: 'ENEMY',
        target: owner,
        effects: probe.prepareBottledCloud(
          art.openSkillEffects,
          random: _FixedRoll(0),
        ),
      );
      probe.bottledCloudStop(stop);
      expect(outgoing['status'], 'cancelled');
      expect(reaction['status'], 'pending');
      expect(token['bottledCloudPendingActions'], 0);
      expect(token['reactionUsed'], 0);
      expect(token['reactionFastUsed'], 0);
      final delayed = _packet(probe, id: 'late', source: owner, target: 'OTHER')
        ..['attackGroupId'] = 'volley';
      expect(probe.bottledCloudInterrupted(delayed), isTrue);
      expect(delayed['status'], 'cancelled');
      probe.bottledCloudStop(stop);
      expect(token['bottledCloudActionReceipts'], hasLength(1));
      state.masterInitiativeRound = 3;
      probe.refreshTurnResources(token);
      expect(token['actionUsed'], isFalse);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'pending stop waits for next personal action; own Open adds RV only once per personal turn',
    (tester) async {
      final (state, probe, art) = await _mount(tester);
      final token = state.masterInitiativeTokens.first as Map<String, dynamic>;
      state.masterInitiativeActiveIndex = 1;
      final stop = _packet(
        probe,
        id: 'queued-stop',
        source: 'ENEMY',
        target: probe.ownerTag(),
        effects: probe.prepareBottledCloud(
          art.openSkillEffects,
          random: _FixedRoll(0),
        ),
      );
      probe.bottledCloudStop(stop);
      expect(token['bottledCloudPendingActions'], 1);
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeRound = 3;
      probe.refreshTurnResources(token);
      expect(token['actionUsed'], isTrue);
      expect(token['bottledCloudPendingActions'], 0);
      expect(probe.recordArtOpenCycle(0), isTrue);
      art.openAttiva = true;
      final before = readIntValue(token['extraFastReactionCurrent']);
      probe.bottledCloudTurn(token, 'custom-turn');
      probe.bottledCloudTurn(token, 'custom-turn');
      expect(token['extraFastReactionCurrent'], before + 1);
      probe.bottledCloudTurn(token, 'next-turn');
      expect(token['extraFastReactionCurrent'], before + 2);
      // Production captures the active group before projecting its snapshot.
      probe.recordCurrentEncounter();
      final public = probe.publicEncounter(state.masterInitiativeGroups.first);
      final publicToken = (public['tokens'] as List)
          .whereType<Map>()
          .firstWhere((t) => t['id'] == probe.ownerTag());
      expect(publicToken['bottledCloudPendingActions'], 0);
      expect(publicToken['bottledCloudActionReceipts'], hasLength(1));
      await closeFixture(tester, probe);
    },
  );
}
