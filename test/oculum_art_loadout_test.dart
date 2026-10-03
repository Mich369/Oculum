import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

CharacterArt art(String kind, {bool incorporated = false}) => CharacterArt(
  nome: kind,
  tipo: '',
  descrizione: 'Originale',
  skills: [ArtSkill(nome: 'Tecnica')],
  incorporata: incorporated,
);

void main() {
  test('Manual Art names recognize trailing Art and every letter case', () {
    for (final kind in ['illness', 'emblem', 'defiled', 'martial']) {
      for (final text in [
        '$kind art',
        '${kind.toUpperCase()} ART',
        'Art $kind',
        '${kind[0].toUpperCase()}${kind.substring(1)} Art',
      ]) {
        expect(oculumRecognizedArtKind(art(text)), kind);
      }
    }
  });
  test(
    'Legacy Arts retain availability; incorporation and interruption survive JSON',
    () {
      final old = CharacterArt.fromJson({'nome': 'Illness Art', 'skills': []});
      expect(old.inUso, isTrue);
      old.incorporata = true;
      old.switchPhase = 'interrotto';
      old.occhiCoinvolti = 'Occhio sinistro';
      final restored = CharacterArt.fromJson(old.toJson());
      expect(restored.incorporata, isTrue);
      expect(restored.switchPhase, 'interrotto');
      expect(restored.occhiCoinvolti, 'Occhio sinistro');
      expect(restored.inUso, isFalse);
    },
  );
  testWidgets(
    'Illness selection, cumulative Emblems, debt and interrupted awakening use production paths',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final data = Directory(
        'build/art-loadout-test-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => data.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      await tester.pumpWidget(const MaterialApp(home: OculumHomePage()));
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(seconds: 1));
      final probe = OculumPerformanceProbe(state);
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.activeGameMod = '';
        state.arti.clear();
        state.arti.addAll([
          art('ILLNESS ART', incorporated: true),
          art('emblem art', incorporated: true),
          art('ART EMBLEM', incorporated: true),
          art('Oculum Art', incorporated: true),
          art('Defiled Art', incorporated: true),
        ]);
      });
      final creation = probe.humanoidCreationDialog();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome').last,
        'Elyra Custode',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Livello').last,
        '6',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sottotratti al livello 6:'), findsOneWidget);
      await tester.ensureVisible(find.text('Crea').last);
      await tester.tap(find.text('Crea').last);
      await tester.pumpAndSettle();
      final choice = await creation;
      expect(choice!.name, 'Elyra Custode');
      expect(choice.level, 6);
      expect(probe.artBonuses()['volonta'], 3);
      expect(probe.artBonuses()['materia'], 2);
      probe.selectArt(0);
      expect(probe.artBonuses(), {
        'resilienza': 5,
        'volonta': 8,
        'materia': 7,
        'oculum': 5,
      });
      expect(probe.artCostResource(0), 'follia');
      expect(state.artSwitchActionDebt, 1);
      expect(state.artSwitchReactionDebt, 2);
      state.folliaController.text = '8';
      expect(probe.spendArtResource('follia', 3), 3);
      expect(state.folliaController.text, '5');
      probe.selectArt(1);
      expect(probe.artCostResource(1), 'nessuna');
      expect(probe.artBonuses()['resilienza'], 0);
      probe.selectArt(3);
      expect(state.arti[3].inUso, isFalse);
      probe.advanceArtTurn();
      expect(state.arti[3].switchPhase, 'risveglio');
      probe.hitDuringArtAwakening();
      probe.advanceArtTurn();
      expect(state.arti[3].switchPhase, 'interrotto');
      probe.selectArt(4);
      expect(state.arti[4].switchPhase, '');
      expect(state.arti[4].descrizione, 'Originale');
      state.masterInitiativeGroups.clear();
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.add({
        'id': 'legacy',
        'name': 'Vecchio combattente',
        'type': 'NPC',
      });
      probe.ensureEncounters();
      expect(state.masterInitiativeGroups.length, 5);
      probe.selectEncounter('encounter_2');
      expect(state.masterInitiativeTokens, isEmpty);
      state.masterInitiativeTokens.add({'id': 'secret', 'name': 'Segreto'});
      state.masterInitiativePublished = false;
      probe.selectEncounter('encounter_1');
      expect(state.masterInitiativeTokens.single['id'], 'legacy');
      state.masterInitiativePublished = true;
      final shared = probe.initiativeSnapshot();
      expect((shared['encounters'] as List).length, 1);
      expect(shared.toString(), isNot(contains('Segreto')));
      state.schedePersonaggio.add({
        'id': 'owned_fixture',
        'sheetTag': 'owned_fixture',
        'nome': 'Custode',
        'tipoScheda': 'Personaggio',
        'inMasterParty': true,
      });
      state.schedaCorrente = state.schedePersonaggio.length - 1;
      probe.enterEncounter('encounter_3');
      expect(state.masterInitiativeRound, 0);

      final firstRoll = state.masterInitiativeTokens.single['initiativeRoll'];
      expect(firstRoll, inInclusiveRange(1, 20));
      probe.enterEncounter('encounter_3');
      expect(state.masterInitiativeTokens.length, 1);
      expect(state.masterInitiativeTokens.single['initiativeRoll'], firstRoll);
      final entered = state.masterInitiativeTokens.single;
      if (firstRoll > 1 && firstRoll < 20) {
        expect(
          entered['initiativeTotal'],
          firstRoll + entered['initiativeBase'],
        );
      }
      state.gradoController.text = '2';
      state.hiddenEyeStats.add(
        HiddenEyeStat(id: 'riflessi', nome: 'Riflessi', descrizione: ''),
      );
      final reflexStat = state.hiddenEyeStats.firstWhere(
        (dynamic stat) => stat.id == 'riflessi',
      );
      reflexStat.valore = 50;
      reflexStat.masteryProgress = 0;
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll([
        {
          'id': 'slow',
          'name': 'Lento',
          'initiativeTotal': 25,
          'initiativeBase': 20,
          'reflexes': 2,
        },
        {
          'id': 'fast',
          'sheetTag': entered['sheetTag'],
          'name': 'Rapido',
          'initiativeTotal': 25,
          'initiativeBase': 5,
          'reflexes': 9,
        },
      ]);
      probe.sortInitiative();
      expect(state.masterInitiativeTokens.first['id'], 'fast');
      expect(reflexStat.masteryProgress, 12);
      probe.selectEncounter('encounter_1');
      probe.selectEncounter('encounter_3');
      probe.sortInitiative();
      expect(reflexStat.masteryProgress, 12);
      probe.sortInitiative();
      expect(state.masterInitiativeTokens.first['id'], 'fast');
      expect(reflexStat.masteryProgress, 12);
      state.masterInitiativeTokens[1]['status'] = 'active';
      state.masterInitiativeActiveIndex = 1;
      state.masterInitiativeTokens[1]['initiativeTotal'] = 40;
      probe.sortInitiative();
      expect(
        state.masterInitiativeTokens[state.masterInitiativeActiveIndex]['id'],
        'slow',
      );
      state.masterInitiativeTokens[0]['actionUsed'] = true;
      state.masterInitiativeTokens[0]['reactionUsed'] = 1;
      final revision = state.activeSheetSummaryRevision.value;
      probe.activateInitiative(0);
      expect(state.masterInitiativeTokens[0]['actionUsed'], isTrue);
      expect(state.masterInitiativeTokens[0]['reactionUsed'], 1);
      expect(state.activeSheetSummaryRevision.value, greaterThan(revision));
      state.masterInitiativeTokens.add({
        'id': 'extra_round_zero',
        'name': 'Extra',
        'temporaryTurn': true,
        'sourceTokenId': 'slow',
        'expiresRound': 0,
      });
      state.masterInitiativeRound = 0;
      probe.normalizeInitiative();
      expect(state.masterInitiativeTokens.last['expiresRound'], 0);
      state.masterInitiativeRound = 1;
      probe.normalizeInitiative();
      expect(
        state.masterInitiativeTokens.any(
          (dynamic token) => token['id'] == 'extra_round_zero',
        ),
        isFalse,
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
