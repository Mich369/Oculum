import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'end fight rolls only killed monsters present in the initiative order',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.updateOculumHomeUi(() {
        state.schedePersonaggio.clear();
        state.schedePersonaggio.addAll([
          <String, dynamic>{
            'id': 'PLAYER',
            'sheetTag': 'PLAYER',
            'nome': 'Avventuriera',
            'tipoScheda': 'Personaggio',
            'livello': 1,
            'grado': 0,
            'resilienza': 10,
            'volonta': 10,
            'materia': 10,
            'oculum': 0,
            'hiddenEyeStats': <Map<String, dynamic>>[
              {'id': 'drop', 'valore': 0},
            ],
          },
          <String, dynamic>{
            'id': 'GOBLIN-DEAD',
            'sheetTag': 'GOBLIN-DEAD',
            'nome': 'Goblin ucciso',
            'tipoScheda': 'Mostro',
            'monsterBookSourceId': 'goblin_base',
            'livello': 0,
            'grado': 0,
            'resilienza': 1,
            'volonta': 1,
            'materia': 1,
            'oculum': 0,
            'skills': <Map<String, dynamic>>[
              {
                'id': 'goblin-contained-skill',
                'nome': 'Artiglio del Goblin',
                'descrizione': 'Tecnica presente sulla creatura sorgente.',
              },
            ],
          },
          <String, dynamic>{
            'id': 'ROCK-SLIME-DEAD',
            'sheetTag': 'ROCK-SLIME-DEAD',
            'nome': 'Slime roccioso ucciso',
            'tipoScheda': 'Mostro',
            'monsterBookSourceId': 'slime_roccioso',
            'livello': 0,
            'grado': 0,
            'resilienza': 1,
            'volonta': 1,
            'materia': 1,
            'oculum': 0,
            'skills': <Map<String, dynamic>>[
              {
                'id': 'rock-slime-contained-skill',
                'nome': 'Urto roccioso',
                'descrizione': 'Tecnica presente sulla creatura sorgente.',
              },
            ],
          },
          <String, dynamic>{
            'id': 'GOBLIN-ALIVE',
            'sheetTag': 'GOBLIN-ALIVE',
            'nome': 'Goblin vivo',
            'tipoScheda': 'Mostro',
            'monsterBookSourceId': 'goblin_base',
            'livello': 0,
            'grado': 0,
            'resilienza': 1,
            'volonta': 1,
            'materia': 1,
            'oculum': 0,
          },
        ]);
        state.schedaCorrente = 0;
        state.nomeController.text = 'Avventuriera';
        state.livelloController.text = '1';
        state.gradoController.text = '0';
        state.masterInitiativeGroups.clear();
        state.masterInitiativeTokens
          ..clear()
          ..addAll([
            <String, dynamic>{
              'id': 'PLAYER',
              'sheetTag': 'PLAYER',
              'name': 'Avventuriera',
              'side': 'party',
              'status': 'ready',
            },
            <String, dynamic>{
              'id': 'GOBLIN-DEAD',
              'sheetTag': 'GOBLIN-DEAD',
              'monsterBookId': 'goblin_base',
              'name': 'Goblin ucciso',
              'side': 'enemy',
              'type': 'Mostro',
              'level': 0,
              'grade': 0,
              'statsTotal': 3,
              'status': 'dead',
            },
            <String, dynamic>{
              'id': 'ROCK-SLIME-DEAD',
              'sheetTag': 'ROCK-SLIME-DEAD',
              'monsterBookId': 'slime_roccioso',
              'name': 'Slime roccioso ucciso',
              'side': 'enemy',
              'type': 'Mostro',
              'level': 0,
              'grade': 0,
              'statsTotal': 3,
              'status': 'dead',
            },
            <String, dynamic>{
              'id': 'GOBLIN-ALIVE',
              'sheetTag': 'GOBLIN-ALIVE',
              'monsterBookId': 'goblin_base',
              'name': 'Goblin vivo',
              'side': 'enemy',
              'type': 'Mostro',
              'level': 0,
              'grade': 0,
              'statsTotal': 3,
              'status': 'ready',
            },
          ]);
        state.selectedMasterInitiativeGroupId = 'encounter_1';
      });
      probe.ensureSheetTags();
      probe.ensureEncounters();
      for (
        var index = 0;
        index < state.masterInitiativeTokens.length;
        index++
      ) {
        state.masterInitiativeTokens[index]['sheetTag'] =
            '${state.schedePersonaggio[index]['sheetTag']}';
      }
      probe.recordCurrentEncounter();

      var seed = 0;
      while (true) {
        final rolls = Random(seed);
        // Level-zero enemies cannot drop crystals for this level-one party;
        // no crystal percentile may shift the next monster's natural roll.
        final firstNatural = rolls.nextInt(20) + 1;
        final secondNatural = rolls.nextInt(20) + 1;
        if (firstNatural == 20 && secondNatural == 20) break;
        seed++;
      }
      final finish = probe.finishEncounter('encounter_1', random: Random(seed));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Termina, tira i Drop e assegna EXP'), findsOneWidget);
      await tester.tap(find.text('Termina, tira i Drop e assegna EXP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await finish;

      expect(
        (state.masterInitiativeGroups.first['rewards'] as List)
            .last['defeated'],
        hasLength(2),
      );
      final fightReward =
          (state.masterInitiativeGroups.first['rewards'] as List).last as Map;
      expect(fightReward['amount'], 6);
      final playerTag = '${state.schedePersonaggio[0]['sheetTag']}';
      final playerExperience =
          state.onlineCombatRequests.values
                  .where(
                    (request) =>
                        request['kind'] == 'encounter_reward' &&
                        request['targetTag'] == playerTag,
                  )
                  .single
              as Map;
      expect(playerExperience['amount'], 6);
      expect(playerExperience['discoveryEnemies'], hasLength(2));
      for (final index in [1, 2]) {
        expect(state.schedePersonaggio[index]['monsterLootGenerated'], isTrue);
        expect(state.schedePersonaggio[index]['monsterLootPending'], isFalse);
        expect(
          (state.schedePersonaggio[index]['monsterLootRoll'] as Map)['natural'],
          20,
        );
      }
      expect(state.schedePersonaggio[3]['monsterLootGenerated'], isNot(true));
      expect(state.occhiCaduti, hasLength(2));
      expect(
        state.occhiCaduti.map((eye) => eye['sourceKillId']).toSet(),
        hasLength(2),
      );
      final eyeSkillsBySource = {
        for (final eye in state.occhiCaduti)
          eye['sourceMonsterId']: (eye['originalSkills'] as List)
              .whereType<Map>()
              .map((skill) => skill['id'])
              .toSet(),
      };
      expect(
        eyeSkillsBySource['goblin_base'],
        contains('goblin-contained-skill'),
      );
      expect(
        eyeSkillsBySource['slime_roccioso'],
        contains('rock-slime-contained-skill'),
      );
      for (final eye in state.occhiCaduti) {
        expect(eye['ownerSheetId'], state.schedePersonaggio[0]['sheetTag']);
        expect(
          (eye['sheetData'] as Map)['monsterBookSourceId'],
          eye['sourceMonsterId'],
        );
        expect((eye['sheetData'] as Map)['tipoScheda'], 'Mostro');
      }
      // The updated manual keeps party members and friendly NPCs on the
      // initiative board after the fight; only enemies are removed.
      expect(state.masterInitiativeTokens, hasLength(1));
      expect(state.masterInitiativeTokens.single['id'], 'PLAYER');
      expect(state.masterInitiativeTokens.single['side'], 'party');
      expect(state.masterInitiativeGroups.first['combatEnded'], isTrue);
      final remainingGroupTokens =
          (state.masterInitiativeGroups.first['tokens'] as List)
              .whereType<Map>()
              .toList();
      expect(remainingGroupTokens, hasLength(1));
      expect(remainingGroupTokens.single['id'], 'PLAYER');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
