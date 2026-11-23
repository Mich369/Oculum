import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

Iterable<CharacterArt> _savedArts(Map<String, dynamic> sheet) =>
    (sheet['arti'] as List).whereType<Map>().map(
      (art) => CharacterArt.fromJson(Map<String, dynamic>.from(art)),
    );

Iterable<CharacterArt> _anymareapArts(Map<String, dynamic> sheet) =>
    _savedArts(sheet).where(
      (art) => art.skills.any(
        (skill) => skill.effettiPerLivello.any(
          (effects) => effects.any((e) => e.id == oculumAnymareapEffect),
        ),
      ),
    );

void main() {
  testWidgets('legacy Elite gets one grant and can remove it permanently', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final customArt = CharacterArt(
      nome: 'Art personalizzata',
      tipo: 'Oculum Art',
      descrizione: 'Conservare la descrizione salvata.',
      skills: [ArtSkill(nome: 'Skill personalizzata', evo1: 'Valore scelto')],
    ).toJson();
    final sheet = <String, dynamic>{
      ...probe.snapshot(),
      'monsterBookSourceId': oculumSoulFighterEliteId,
      'arti': List<Map<String, dynamic>>.unmodifiable([customArt]),
    };
    void load(Map<String, dynamic> json) {
      state.schedePersonaggio[0] = json;
      probe.load(json);
    }

    load(sheet);
    expect(_anymareapArts(sheet), hasLength(1));
    expect((sheet['arti'] as List).first, customArt);
    load(sheet);
    final reloaded = _anymareapArts(probe.snapshot()).single;
    expect(reloaded.openName, isEmpty);

    final savedAfterDeletion = probe.snapshot()
      ..['arti'] = <Map<String, dynamic>>[customArt];
    load(savedAfterDeletion);
    expect(_anymareapArts(probe.snapshot()), isEmpty);
    expect(
      _savedArts(probe.snapshot())
          .singleWhere((art) => art.nome == 'Art personalizzata')
          .skills
          .singleWhere((skill) => skill.nome == 'Skill personalizzata')
          .evo1,
      'Valore scelto',
    );
    await closeFixture(tester, probe);
  });

  testWidgets('saved Art edits win and the normal preset gains no extra Art', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final edited = oculumAnymareapArt()
      ..nome = 'Nome scelto dal Master'
      ..descrizione = 'Descrizione personalizzata';
    final art = edited.toJson();
    final sheet = <String, dynamic>{
      ...probe.snapshot(),
      'monsterBookSourceId': oculumSoulFighterEliteId,
      'arti': [art],
    };
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    expect((sheet['arti'] as List).single, art);
    expect(_anymareapArts(probe.snapshot()).single.nome, edited.nome);

    final normal = <String, dynamic>{
      ...probe.snapshot(),
      'monsterBookSourceId': oculumSoulFighterId,
      'nome': 'Combattente dell’Anima Elité',
      'arti': <Map<String, dynamic>>[],
    };
    state.schedePersonaggio[0] = normal;
    probe.load(normal);
    expect(_anymareapArts(probe.snapshot()), isEmpty);
    await closeFixture(tester, probe);
  });
}
