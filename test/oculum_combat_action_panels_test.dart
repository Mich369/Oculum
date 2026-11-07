import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_realtime_service.dart';
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _MeditationTransport extends OculumRealtimeService {
  _MeditationTransport()
    : super(
        roomId: 'meditation-turn-spend',
        playerName: 'Eroe',
        onEvent: (_, _) {},
        onPresenceChanged: (_) {},
        onStatusChanged: (_) {},
      ) {
    authenticatedRole = 'player';
  }

  final sent = <(String, Map<String, dynamic>)>[];

  @override
  bool get isConnected => true;

  @override
  Future<bool> sendCombatEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    sent.add((event, payload));
    return true;
  }
}

void main() {
  testWidgets(
    'equipped monster relic skills appear in their combat action panels',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final weapon = InventoryItem(
        nome: 'Spada reliquia test',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        equipaggiata: true,
        ability: oculumEquipmentAbility('Spada reliquia test', 0),
      );
      final armor = InventoryItem(
        nome: 'Armatura reliquia test',
        peso: 1,
        quantita: 1,
        note: '',
        protegge: true,
        equipaggiata: true,
        ability: oculumEquipmentAbility('Armatura reliquia test', 0),
      );
      final support = InventoryItem(
        nome: 'Reliquia di cura test',
        peso: 1,
        quantita: 1,
        note: '',
        equipaggiata: true,
        ability: CharacterSkill(
          nome: 'Rimedio reliquiario',
          tipo: 'Skill equipaggiamento',
          costo: '',
          cooldown: '',
          descrizione: 'Cura 5 Vita a un alleato.',
          forme: [
            CharacterSkillForm(
              nome: 'I',
              tipo: 'Skill equipaggiamento',
              livello: '0',
              costo: '',
              descrizione: 'Cura 5 Vita a un alleato.',
              effettiStrutturati: [
                OculumStructuredEffect(
                  type: 'cura',
                  recipient: 'alleato',
                  valueExpression: '5',
                ),
              ],
            ),
          ],
        ),
      );
      state.updateOculumHomeUi(() {
        state.inventario
          ..add(weapon)
          ..add(armor)
          ..add(support);
      });
      final expected = {
        OculumCombatAbilityRole.attack: 'Spada reliquia test',
        OculumCombatAbilityRole.defense: 'Armatura reliquia test',
        OculumCombatAbilityRole.support: 'Reliquia di cura test',
      };
      for (final entry in expected.entries) {
        final opened = OculumPerformanceProbe(
          state,
        ).openCombatActionPanel(entry.key);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final panel = find.byType(AlertDialog).last;
        final action = find.descendant(
          of: panel,
          matching: find.textContaining(entry.value),
        );
        expect(action, findsOneWidget, reason: '${entry.key}: ${entry.value}');
        final button = tester.widget<OutlinedButton>(
          find
              .ancestor(of: action, matching: find.byType(OutlinedButton))
              .first,
        );
        expect(button.onPressed, isNotNull, reason: '${entry.key}: usable');
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(of: panel, matching: find.text('Chiudi')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opened;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'defense rolls can be added, saved and removed while CM stays available',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.hiddenEyeStats.clear();
      state.hiddenEyeStats.add(
        HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: ''),
      );
      final opening = probe.openCombatActionPanel(
        OculumCombatAbilityRole.defense,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('Forza +'), findsNothing);
      await tester.tap(
        find.widgetWithText(TextButton, 'Aggiungi tiro difensivo'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(SimpleDialogOption, 'Forza'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('Forza +'), findsOneWidget);
      expect(probe.snapshot()['combatDefenseRollIds'], contains('forza'));
      await tester.tap(find.byTooltip('Rimuovi Forza'));
      await tester.pump();
      expect(find.textContaining('Forza +'), findsNothing);
      expect(find.textContaining('CM +'), findsOneWidget);
      expect(
        probe.snapshot()['combatDefenseRollIds'],
        isNot(contains('forza')),
      );
      await tester.tap(find.text('Chiudi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await opening;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('combat panels separate rolls and abilities at $size', (
      tester,
    ) async {
      final dynamic state = await fixtures.mountSheet(tester, size);
      final probe = OculumPerformanceProbe(state);
      state.skills.clear();
      state.arti.clear();
      state.titoli.clear();
      state.trattiRazziali.clear();
      state.hiddenEyeStats.clear();
      state.hiddenEyeStats.addAll([
        HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: ''),
        HiddenEyeStat(id: 'resistenza', nome: 'Resistenza', descrizione: ''),
        HiddenEyeStat(id: 'medicina', nome: 'Medicina', descrizione: ''),
        HiddenEyeStat(
          id: 'riflessi',
          nome: 'Riflessi',
          descrizione: '',
          unlocked: false,
        ),
      ]);
      for (final role in OculumCombatAbilityRole.values) {
        final opened = probe.openCombatActionPanel(role);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final panel = find.byType(AlertDialog).last;
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: panel, matching: find.byType(Text)),
            )
            .map((t) => t.data ?? '')
            .join('\n');
        if (role == OculumCombatAbilityRole.attack) {
          expect(texts, contains('VC +'));
          expect(texts, contains('Forza'));
          expect(texts, isNot(contains('CM +')));
          expect(texts, isNot(contains('Medicina')));
        } else if (role == OculumCombatAbilityRole.defense) {
          expect(texts, contains('CM +'));
          expect(texts, contains('Resistenza'));
          expect(texts, isNot(contains('VC +')));
        } else {
          expect(texts, contains('Aiuta compagno'));
          expect(texts, contains('Medicina'));
          expect(texts, isNot(contains('VC +')));
        }
        // Subtraits remain usable as rolls even when their optional mastery
        // benefit is locked; support only lists support rolls.
        if (role != OculumCombatAbilityRole.support) {
          expect(texts, contains('Riflessi +0'));
        }
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(of: panel, matching: find.text('Chiudi')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opened;
      }
      final help = size.width < 500;
      final attackPanel = probe.openCombatActionPanel(
        help ? OculumCombatAbilityRole.support : OculumCombatAbilityRole.attack,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        help
            ? find.text('Aiuta compagno').last
            : find.textContaining('VC +').last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await attackPanel;
      expect(find.byType(AlertDialog), findsNothing);
      expect(state.mostraOverlayDado, isTrue);
      expect(state.dadoMostratoFacce, help ? 10 : 20);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('Sharpen restores only the selected eligible weapon', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final group = state.masterInitiativeGroups.first as Map<String, dynamic>;
    final actor = state.masterInitiativeTokens.first as Map<String, dynamic>;
    state.masterInitiativeActiveIndex = 0;
    probe.recordCurrentEncounter();
    group['fightStarted'] = true;
    expect(probe.fightActive(), isTrue);
    InventoryItem item(
      String name,
      int uses, {
      bool weapon = true,
      bool title = false,
      int level = 3,
    }) => InventoryItem(
      nome: name,
      peso: 1,
      quantita: 1,
      note: '',
      arma: weapon,
      protegge: !weapon,
      livelloOggetto: level,
      craftData: {
        'wearUsesRemaining': uses,
        'customMarker': 'preserved',
        if (title) 'titleItem': true,
      },
    );
    final sword = item('Spada consumata', 400);
    final dagger = item('Pugnale consumato', 800);
    final removed = item('Ascia consumata', 700);
    final earlyWeapon = item('Randello consumato', 200, level: 0);
    final broken = item('Lama rotta', 0);
    final full = item('Lancia nuova', 1000);
    final title = item('Titolo arma', 500, title: true);
    final armor = item('Armatura consumata', 500, weapon: false);
    state.inventario
      ..clear()
      ..addAll([
        sword,
        dagger,
        removed,
        earlyWeapon,
        broken,
        full,
        title,
        armor,
      ]);

    Future<void> tapAndSettle(Finder control) async {
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> openSharpener() async {
      final panel = probe.openCombatActionPanel(
        OculumCombatAbilityRole.support,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tapAndSettle(find.widgetWithText(ListTile, 'Riaffila'));
      await panel;
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Riaffila un’arma'), findsOneWidget);
    }

    await openSharpener();
    expect(find.text('400 → 550 / 1000'), findsOneWidget);
    expect(find.text('200 → 237 / 250'), findsOneWidget);
    for (final excluded in [broken, full, title, armor]) {
      expect(find.text(excluded.nome), findsNothing);
    }
    await tapAndSettle(find.text('Annulla').last);
    expect(readBoolValue(actor['actionUsed']), isFalse);

    await openSharpener();
    state.inventario.remove(removed);
    await tapAndSettle(find.text(removed.nome));
    expect(oculumEquipmentUses(removed), 700);
    expect(readBoolValue(actor['actionUsed']), isFalse);

    state.masterInitiativeActiveIndex = 1;
    actor['reactionMax'] = 1;
    actor['reactionUsed'] = 0;
    probe.recordCurrentEncounter();
    await openSharpener();
    await tapAndSettle(find.text(sword.nome));
    expect(oculumEquipmentUses(sword), 400);
    expect(readBoolValue(actor['actionUsed']), isFalse);
    expect(readIntValue(actor['reactionUsed']), 0);
    state.masterInitiativeActiveIndex = 0;
    probe.recordCurrentEncounter();

    await openSharpener();
    await tapAndSettle(find.text(sword.nome));
    expect(readBoolValue(actor['actionUsed']), isTrue);
    expect(oculumEquipmentUses(sword), 550);
    expect(oculumEquipmentUses(dagger), 800);
    expect(state.risultato, contains('+150 usi'));

    group['fightStarted'] = false;
    state.masterInitiativeTokens.clear();
    probe.recordCurrentEncounter();
    expect(probe.fightActive(), isFalse);
    await openSharpener();
    expect(find.text('550 → 850 / 1000'), findsOneWidget);
    expect(find.text('200 → 250 / 250'), findsOneWidget);
    await tapAndSettle(find.text(dagger.nome));
    expect(oculumEquipmentUses(dagger), 1000);
    expect(state.risultato, contains('+200 usi'));
    final restored = InventoryItem.fromJson(dagger.toJson());
    expect(oculumEquipmentUses(restored), 1000);
    expect(restored.craftData['customMarker'], 'preserved');
    await openSharpener();
    await tapAndSettle(find.text(sword.nome));
    expect(oculumEquipmentUses(sword), 850);
    expect(state.risultato, contains('+300 usi'));
    expect(oculumEquipmentUses(broken), 0);
    expect(oculumEquipmentUses(armor), 500);
    await closeFixture(tester, probe);
  });

  testWidgets(
    'Meditation publishes each online roleplay spend without banking a roll bonus',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final tag = probe.ownerTag();
      final service = _MeditationTransport();
      state.realtimeService = service;
      state.modalitaMaster = false;
      state.activeCampaignId = 'meditation-campaign';
      state.realtimeSelectedEncounterId = 'roleplay';
      final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;

      for (final resource in ['azione', 'reazione', 'reazione_veloce']) {
        sheet['planarRuntime'] = <String, dynamic>{};
        final actor = <String, dynamic>{
          'id': tag,
          'sheetTag': tag,
          'name': 'Eroe',
          'status': 'ready',
          'actionUsed': false,
          'reactionMax': 1,
          'reactionUsed': resource == 'reazione_veloce' ? 1 : 0,
          'reactionUsedRound': 1,
          'reactionFastMax': 1,
          'reactionFastUsed': 0,
          'reactionPoolInitialized': true,
          'reactionPoolRound': 1,
        };
        state.realtimeVisibleInitiativeSnapshot = <String, dynamic>{
          'encounterId': 'roleplay',
          'campaignId': state.activeCampaignId,
          'fightStarted': false,
          'round': 1,
          'activeIndex': resource == 'azione' ? 0 : 1,
          'tokens': [
            actor,
            {'id': 'ALLY', 'sheetTag': 'ALLY', 'status': 'ready'},
          ],
        };
        final sentBefore = service.sent.length;
        final opened = probe.openCombatActionPanel(
          OculumCombatAbilityRole.support,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final action = find.widgetWithText(ListTile, 'Meditazione');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opened;
        await tester.pump();

        final (event, payload) = service.sent.skip(sentBefore).single;
        expect(event, 'combat_help');
        expect(payload['helpMode'], 'turn_resource');
        expect(payload['encounterId'], 'roleplay');
        final spend = (payload['turnResourceSpends'] as List).single as Map;
        expect(spend['sheetTag'], tag);
        expect(spend['activityResource'], resource);
        expect(spend['grantFastRollBonus'], isFalse);
        expect(actor['actionUsed'], resource == 'azione');
        expect(actor['reactionUsed'], resource == 'azione' ? 0 : 1);
        expect(
          actor['reactionFastUsed'],
          resource == 'reazione_veloce' ? 1 : 0,
        );
        expect(readIntValue(actor['pendingFastReactionRollBonus']), 0);
      }
      state.realtimeService = null;
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'Meditation uses one natural d20 for both resources and recharges on long rest',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final group = state.masterInitiativeGroups.first as Map<String, dynamic>;
      final tokens = (state.masterInitiativeTokens as List)
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
      void setFight(bool active) {
        group['fightStarted'] = active;
        state.masterInitiativeTokens.clear();
        if (active) state.masterInitiativeTokens.addAll(tokens);
        probe.recordCurrentEncounter();
        expect(probe.fightActive(), active);
      }

      Future<void> checkButton(
        bool? enabled, {
        bool use = false,
        OculumCombatAbilityRole role = OculumCombatAbilityRole.support,
      }) async {
        final opened = probe.openCombatActionPanel(role);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final action = find.widgetWithText(ListTile, 'Meditazione');
        if (enabled == null) {
          expect(action, findsNothing);
        } else {
          expect(action, findsOneWidget);
          expect(tester.widget<ListTile>(action).onTap != null, enabled);
        }
        final target = use ? action : find.text('Chiudi').last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opened;
        await tester.pump();
      }

      setFight(true);
      await checkButton(null);
      setFight(false);
      await checkButton(null, role: OculumCombatAbilityRole.attack);
      await checkButton(null, role: OculumCombatAbilityRole.defense);

      state.updateOculumHomeUi(() {
        state.resilienzaController.text = '30';
        state.currentResilienzaController.text = '30';
        state.currentHpController.text = '5';
        state.oculumController.text = '30';
        probe.setResourceCurrent('oculum', 4);
        state.invalidateDerivedDataCaches();
      });
      final lifeBefore = probe.currentHp();
      final oculumBefore = probe.visibleResourceCurrent('oculum');
      await checkButton(true, use: true);

      final result = state.risultato as String;
      final natural = int.parse(
        RegExp(r'd20 (\d+)').firstMatch(result)!.group(1)!,
      );
      expect(natural, inInclusiveRange(1, 20));
      final gained = natural * 2 ~/ 3;
      expect(probe.currentHp(), lifeBefore + gained);
      expect(probe.visibleResourceCurrent('oculum'), oculumBefore + gained);
      expect(result, contains('Vita +$gained · Oculum +$gained'));

      final saved =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      expect(saved['planarRuntime']['meditationUsedSinceLongRest'], isTrue);
      final other = {...saved, 'id': 'MEDITATE2', 'sheetTag': 'MEDITATE2'}
        ..remove('planarRuntime');
      state.schedePersonaggio.add(other);
      state.schedaCorrente = 1;
      probe.load(other);
      await checkButton(true);

      state.schedaCorrente = 0;
      state.schedePersonaggio[0] = saved;
      probe.load(saved);
      await checkButton(false);
      probe.shortRest();
      await checkButton(false);
      probe.longRest(advanceWorldClock: false);
      await checkButton(true);
      expect(tester.takeException(), isNull);
      await closeFixture(tester, probe);
    },
  );
}
