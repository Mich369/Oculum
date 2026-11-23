import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  for (final id in [oculumSoulFighterId, oculumSoulFighterEliteId]) {
    testWidgets('guided $id assigns its fixed Arts and preserves edits', (
      tester,
    ) async {
      final (state, probe) = await mountFight(tester);
      state.tutorialGeneraMostro = true;
      state.tutorialMonsterPresetId = oculumSoulFighterId;
      state.tutorialMonsterVariantId = id;
      state.tutorialSubtraitPoints
        ..clear()
        ..addAll({'forza': 3, 'riflessi': 3, 'concentrazione': 3});
      probe.creationDraft.addAll({
        'wizardVersion': 2,
        'name': 'Combattente',
        'visited': [0, 1, 2, 3, 4, 5, 6],
        'skills': <String>[],
      });
      CharacterArt cutArt() => (state.arti as List<CharacterArt>).singleWhere(
        (art) => art.skills.any(
          (skill) => skill
              .effettiEvoluzione(1)
              .any((effect) => effect.id == oculumSoulFighterCutEffect),
        ),
      );

      expect(probe.creationPool(), isEmpty);
      expect(probe.creationPercent(), 100);
      expect(probe.applyCreation(), isTrue);
      expect(probe.snapshot()['monsterBookSourceId'], id);
      final monster = monsterBookEntryById(id)!;
      final expectedNames = [
        oculumMonsterBookImportArt(monster)!.nome,
        ...oculumMonsterBookAdditionalArts(monster).map((art) => art.nome),
      ];
      final arts = state.arti as List<CharacterArt>;
      for (final name in expectedNames) {
        expect(arts.where((art) => art.nome == name), hasLength(1));
      }
      expect(
        (state.skills as List<CharacterSkill>).any(
          (skill) => skill.nome == cutArt().skills.first.nome,
        ),
        isFalse,
      );

      final customArt = cutArt()..nome = 'Filo personalizzato';
      final customEffect = customArt.skills.first.effettiEvoluzione(1).single;
      customEffect.valueExpression = '27';
      final saved = probe.snapshot();
      probe.load(saved);
      expect(cutArt().nome, 'Filo personalizzato');
      expect(probe.applyCreation(), isTrue);
      expect(cutArt().nome, 'Filo personalizzato');
      expect(
        cutArt().skills.first.effettiEvoluzione(1).single.valueExpression,
        '27',
      );
      expect(
        (state.arti as List<CharacterArt>).where(
          (art) => art.nome == expectedNames.first,
        ),
        isEmpty,
      );
      for (final name in expectedNames.skip(1)) {
        expect(
          (state.arti as List<CharacterArt>).where((art) => art.nome == name),
          hasLength(1),
        );
      }
      await closeFixture(tester, probe);
    });
  }

  testWidgets('guided ordinary character still requires three choices', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    state.tutorialGeneraMostro = false;
    probe.generateCreation();
    final choices = probe.creationDraft['skills'] as List;
    expect(choices, hasLength(3));
    probe.creationDraft['skills'] = choices.take(2).toList();
    probe.creationDraft['wizardVersion'] = 2;
    expect(probe.applyCreation(), isFalse);
    expect(state.risultato, contains('esattamente tre Skill'));
    await closeFixture(tester, probe);
  });
}
