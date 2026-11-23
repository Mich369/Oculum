import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_fight_creator_rules.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'connected Master authority overrides local toggles; Co-Master is excluded',
    () {
      for (final localMaster in [false, true]) {
        for (final localHost in [false, true]) {
          for (final coMaster in [false, true]) {
            expect(
              oculumFightCreatorMasterAccess(
                connected: true,
                masterRole: false,
                coMasterRole: coMaster,
                localMasterMode: localMaster,
                localMasterHost: localHost,
              ),
              false,
            );
            expect(
              oculumFightCreatorMasterAccess(
                connected: true,
                masterRole: true,
                coMasterRole: coMaster,
                localMasterMode: localMaster,
                localMasterHost: localHost,
              ),
              true,
            );
          }
        }
      }
      expect(
        oculumFightCreatorMasterAccess(
          connected: false,
          masterRole: false,
          coMasterRole: false,
          localMasterMode: false,
          localMasterHost: false,
        ),
        false,
      );
      expect(
        oculumFightCreatorMasterAccess(
          connected: false,
          masterRole: false,
          coMasterRole: true,
          localMasterMode: true,
          localMasterHost: true,
        ),
        false,
      );
    },
  );

  test('sum distinct instances per team; reject duplicate identifiers', () {
    final result = oculumFightCreatorPowerSummary([
      (id: 'hero', teamId: 'ally', power: 100),
      (id: 'foe:1', teamId: 'enemy', power: 75),
      (id: 'foe:2', teamId: 'enemy', power: 75),
      (id: 'third', teamId: 'team:third', power: 40),
    ]);
    expect(result.total, 290);
    expect(result.teams, {'ally': 100, 'enemy': 150, 'team:third': 40});
    expect(result.count, 4);
    expect(
      () => oculumFightCreatorPowerSummary([
        (id: 'same', teamId: 'ally', power: 10),
        (id: 'same', teamId: 'enemy', power: 20),
      ]),
      throwsArgumentError,
    );
    expect(
      oculumFightCreatorRemainingEnemyPower(
        allyPower: 100,
        enemyPower: 50,
        targetPercent: 125,
      ),
      75,
    );
    expect(
      oculumFightCreatorRemainingEnemyPower(
        allyPower: 100,
        enemyPower: 150,
        targetPercent: 100,
      ),
      0,
    );
  });

  testWidgets(
    'three teams prepare a separate unstarted encounter; no private estimates in group JSON',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final owner = probe.ownerTag();
      final countBefore = state.masterInitiativeGroups.length as int;
      final base = probe.snapshot();
      probe.recordCurrentEncounter();
      // The existing initiative capture lazily initializes legacy reward
      // ledgers. The encounter identity, combat state and all other fields
      // must remain unchanged when preparing a separate encounter.
      String encounterWithoutRewardInitialization(Map group) => jsonEncode({
        ...group,
        'tokens': [
          for (final token in group['tokens'] as List)
            {
              for (final entry in (token as Map).entries)
                if (!'${entry.key}'.startsWith('rewardPower'))
                  entry.key: entry.value,
            },
        ],
      });
      final original = encounterWithoutRewardInitialization(
        state.masterInitiativeGroups.first,
      );
      state.schedePersonaggio.addAll(<Map<String, dynamic>>[
        {
          ...base,
          'id': 'FoeOcu:3690FC01',
          'sheetTag': 'FoeOcu:3690FC01',
          'nome': 'Foe',
          'masterSideOverride': 'enemy',
          'derivedResilienzaTotal': 25,
        },
        {
          ...base,
          'id': 'OtherOcu:3690FC02',
          'sheetTag': 'OtherOcu:3690FC02',
          'nome': 'Other',
          'masterSideOverride': 'neutral',
          'derivedResilienzaTotal': 40,
        },
      ]);
      final oldScope = probe.permissionScope;
      expect(
        probe.prepareFightCreator(
          assignments: {owner: 'ally'},
          scope: '$oldScope:stale',
        ),
        false,
      );
      expect(state.masterInitiativeGroups.length, countBefore);
      expect(probe.prepareFightCreator(assignments: {owner: 'unknown'}), false);
      expect(state.masterInitiativeGroups.length, countBefore);
      expect(
        probe.prepareFightCreator(
          assignments: {
            owner: 'ally',
            'FoeOcu:3690FC01': 'enemy',
            'OtherOcu:3690FC02': 'draft:third',
          },
          extraTeams: [
            (
              id: 'draft:third',
              name: 'Terza squadra',
              color: const Color(0xff654dbc),
            ),
          ],
          trainingMode: true,
        ),
        true,
      );
      expect(state.masterInitiativeGroups.length, countBefore + 1);
      expect(
        (state.masterInitiativeGroups.last as Map)['trainingMode'],
        true,
        reason: 'training mode is stored on its separate encounter group',
      );
      expect(
        encounterWithoutRewardInitialization(
          state.masterInitiativeGroups.first,
        ),
        original,
      );
      final group = state.masterInitiativeGroups.last as Map;
      expect(group['published'], false);
      expect(group['fightStarted'], isNot(true));
      final tokens = state.masterInitiativeTokens as List;
      expect(tokens.length, 3);
      expect(tokens.every((token) => token['initiativeRoll'] == 0), true);
      expect(
        tokens.singleWhere(
          (token) => token['sheetTag'] == 'OtherOcu:3690FC02',
        )['teamName'],
        'Terza squadra',
      );
      expect(
        tokens.singleWhere(
          (token) => token['sheetTag'] == 'OtherOcu:3690FC02',
        )['fightTeamId'],
        startsWith('team:'),
      );
      expect(
        RegExp(
          r'"(?:fightCreator|creator|suggestions|powerSummary)[^"]*":',
        ).hasMatch(jsonEncode(group)),
        false,
      );
      expect(group.keys, isNot(contains('totalPower')));
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'guardian is counted once, uses owner team and no dice; invalid guardian selection is rejected',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final owner = probe.ownerTag();
      state.pawnGuardians.clear();
      state.pawnGuardians.add(
        OculumPawnGuardian(
          id: 'creator-guard',
          ownerTag: owner,
          stats: {'resilienza': 3, 'volonta': 3, 'materia': 5, 'oculum': 0},
        ),
      );
      final before = state.masterInitiativeGroups.length;
      expect(
        probe.prepareFightCreator(
          assignments: {owner: 'ally'},
          guardianIds: {'missing'},
        ),
        false,
      );
      expect(state.masterInitiativeGroups.length, before);
      expect(
        probe.prepareFightCreator(
          assignments: {owner: 'draft:third'},
          extraTeams: [
            (
              id: 'draft:third',
              name: 'Guardia',
              color: const Color(0xff654dbc),
            ),
          ],
          guardianIds: {'creator-guard'},
        ),
        true,
      );
      final tokens = state.masterInitiativeTokens as List;
      expect(tokens, hasLength(2));
      final child = tokens.singleWhere(
        (token) => token['pawnId'] == 'creator-guard',
      );
      expect(child['sourceTokenId'], owner);
      expect(child['teamName'], 'Guardia');
      expect(child['initiativeRoll'], 0);
      await closeFixture(tester, probe);
    },
  );

  testWidgets('training damage knocks down without death saves', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final group = state.masterInitiativeGroups.first as Map;
    group['trainingMode'] = true;
    expect(
      probe.publicEncounter(Map<String, dynamic>.from(group))['trainingMode'],
      true,
    );
    await probe.damageResolved(9999);
    expect(probe.currentHp(), 0);
    final token = state.masterInitiativeTokens.firstWhere(
      (token) => token['sheetTag'] == probe.ownerTag(),
    );
    expect(token['status'], 'downed');
    expect(token['deathWounds'], 0);
    expect(token['friendlyFireDowned'], true);
    await closeFixture(tester, probe);
  });

  testWidgets('training cannot protect a sheet outside the fight', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.masterInitiativeGroups.first['trainingMode'] = true;
    final token = state.masterInitiativeTokens.firstWhere(
      (token) => token['sheetTag'] == probe.ownerTag(),
    );
    token['outsideFight'] = true;
    await probe.damageResolved(9999);
    expect(token['friendlyFireDowned'], isNot(true));
    await closeFixture(tester, probe);
  });

  testWidgets('suggestions use the selected submerged habitat', (tester) async {
    final (state, probe) = await mountFight(tester);
    state.schedePersonaggio[state.schedaCorrente]['selectedPlaneId'] =
        'affogato';
    final future = probe.showFightCreator();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Suggerimenti per area'));
    await tester.pump();
    final suggestions = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .where((tile) => '${tile.key}'.contains('fight-creator-suggestion-'))
        .toList();
    expect(suggestions, isNotEmpty);
    for (final tile in suggestions) {
      final id = (tile.key! as ValueKey<String>).value.replaceFirst(
        'fight-creator-suggestion-',
        '',
      );
      expect(
        monsterBookEntries.singleWhere((entry) => entry.id == id).planeIds,
        contains('affogato'),
      );
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Chiudi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await future;
    await closeFixture(tester, probe);
  });

  testWidgets(
    'Fight Creator combines different species with distinct combat skills',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.schedePersonaggio[state.schedaCorrente]['selectedPlaneId'] =
          'affogato';
      final existing = state.schedePersonaggio.length as int;
      var closed = false;
      final creator = probe.showFightCreator().then((_) => closed = true);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Suggerimenti per area'),
      );
      await tester.pumpAndSettle();
      final entry = monsterBookEntryById('piranha_mortale')!;
      await tester.enterText(
        find.widgetWithText(TextField, 'Cerca'),
        entry.nameIt,
      );
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('fight-creator-suggestion-${entry.id}'));
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();
      final count = find.byKey(const ValueKey('fight-creator-creature-count'));
      expect(count, findsOneWidget);
      await tester.enterText(count, '0');
      await tester.pumpAndSettle();
      final invalid = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Crea scheda'),
      );
      expect(invalid.onPressed, isNull);
      await tester.enterText(count, '3');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Crea 3 schede'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      final created = (state.schedePersonaggio as List)
          .skip(existing)
          .cast<Map>()
          .toList();
      expect(created, hasLength(3));
      expect(created.map((sheet) => sheet['sheetTag']).toSet(), hasLength(3));
      expect(count, findsNothing);
      for (final sheet in created) {
        expect(sheet['monsterBookSourceId'], entry.id);
        expect(sheet['masterOnlyDraft'], isTrue);
        final forms = (sheet['skills'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CharacterSkill.fromJson)
            .expand((skill) => skill.forme);
        final arts = (sheet['arti'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CharacterArt.fromJson);
        final effects = [
          for (final form in forms) ...form.effettiStrutturati,
          for (final art in arts)
            for (final skill in art.skills) ...skill.effettiPerLivello.first,
        ];
        expect(
          effects.any((effect) => effect.enabled && effect.type == 'danno'),
          isTrue,
        );
      }
      final currentArts = (state.arti as List).whereType<CharacterArt>();
      final currentSkills = (state.skills as List).whereType<CharacterSkill>();
      final damage =
          [
            for (final skill in currentSkills)
              ...skill.forme.first.effettiStrutturati,
            for (final art in currentArts)
              for (final skill in art.skills) ...skill.effettiPerLivello.first,
          ].firstWhere(
            (effect) =>
                effect.enabled &&
                effect.type == 'danno' &&
                effect.mode == 'prossima_azione',
          );
      probe.applyEffects([damage], spentResources: {'oculum': 1});
      expect(probe.consumeNextAttackEffects(), isTrue);
      expect(probe.consumeNextAttackEffects(), isFalse);

      final octopus = monsterBookEntryById('piovra_succhiasangue')!;
      await tester.enterText(
        find.widgetWithText(TextField, 'Cerca'),
        octopus.nameIt,
      );
      await tester.pump();
      final octopusRow = find.byKey(
        ValueKey('fight-creator-suggestion-${octopus.id}'),
      );
      await tester.ensureVisible(octopusRow);
      await tester.tap(
        find.descendant(of: octopusRow, matching: find.byType(IconButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(FilledButton, 'Crea scheda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      final mixed = (state.schedePersonaggio as List)
          .skip(existing)
          .cast<Map>()
          .toList();
      expect(mixed, hasLength(4));
      expect(mixed.last['monsterBookSourceId'], octopus.id);
      expect(mixed.last['masterOnlyDraft'], isTrue);
      final prepare = find.byKey(const ValueKey('fight-creator-prepare'));
      expect(tester.widget<FilledButton>(prepare).onPressed, isNotNull);
      await tester.tap(prepare);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(closed, isTrue);
      await creator;
      final participantTags = (state.masterInitiativeTokens as List)
          .cast<Map>()
          .map((token) => token['sheetTag'])
          .toSet();
      expect(
        participantTags,
        containsAll(mixed.map((sheet) => sheet['sheetTag'])),
      );
      await closeFixture(tester, probe);
    },
  );

  for (final size in [
    const Size(1920, 1080),
    const Size(1080, 1920),
    const Size(390, 844),
  ]) {
    testWidgets(
      'private dialog fits $size, closes on role revocation and cannot be reopened by Co-Master',
      (tester) async {
        final (state, probe) = await mountFight(tester);
        tester.view.physicalSize = size;
        state.updateOculumHomeUi(() {
          state.isMasterHost = false;
          state.sonoCoMaster = false;
        });
        final before = jsonEncode(state.masterInitiativeGroups);
        final future = probe.showFightCreator();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(
          find.byKey(const ValueKey('fight-creator-dialog')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('fight-creator-total')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(jsonEncode(state.masterInitiativeGroups), before);
        state.updateOculumHomeUi(() {
          state.modalitaMaster = false;
          state.sonoCoMaster = true;
        });
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 350));
        await future;
        expect(
          find.byKey(const ValueKey('fight-creator-dialog')),
          findsNothing,
        );
        expect(probe.fightCreatorAllowed, false);
        await probe.showFightCreator();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('fight-creator-dialog')),
          findsNothing,
        );
        expect(
          probe.prepareFightCreator(assignments: {probe.ownerTag(): 'ally'}),
          false,
        );
        expect(jsonEncode(state.masterInitiativeGroups), before);
        await closeFixture(tester, probe);
      },
    );
  }
}
