import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

const _learnedField = 'slimeFormLearned';
const _skillId = 'forma_slime';

Map<String, dynamic> _sheet(
  OculumPerformanceProbe probe, {
  required String race,
  required int baseMatter,
  int currentMatter = 0,
}) => probe.snapshot()
  ..remove(_learnedField)
  ..['razza'] = race
  ..['materia'] = '$baseMatter'
  ..['currentMateria'] = '$currentMatter'
  ..['skills'] = <Map<String, dynamic>>[]
  ..['trattiRazziali'] = <Map<String, dynamic>>[];

void _load(
  dynamic state,
  OculumPerformanceProbe probe,
  Map<String, dynamic> sheet,
) {
  state.schedePersonaggio[state.schedaCorrente] = sheet;
  probe.load(sheet);
}

List<CharacterSkill> _learnedSkills(dynamic state) =>
    (state.skills as List<CharacterSkill>)
        .where((skill) => skill.id == _skillId)
        .toList();

void main() {
  testWidgets('Slime learns at base 12 with an empty Matter reserve', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final sheet = _sheet(probe, race: ' Slime puro ', baseMatter: 12);
    _load(state, probe, Map<String, dynamic>.of(sheet)..['razza'] = 'Umano');
    final before = probe.snapshot();
    _load(state, probe, sheet);

    final skill = _learnedSkills(state).single;
    expect(sheet[_learnedField], isTrue);
    expect(skill.nome, 'Forma Slime');
    expect(skill.passiva, isTrue);
    expect(skill.costo, isEmpty);
    expect(skill.cooldown, isEmpty);
    expect(skill.forme.single.costoStrutturato, isNull);
    expect(skill.forme.single.effettiStrutturati, isEmpty);
    expect(skill.descrizione, contains('manualmente al tavolo'));
    expect(skill.forme.single.note, contains('3 in Forma II e 6 in Forma III'));
    final after = probe.snapshot();
    expect(after['currentMateria'], '0');
    expect(after['derivedDanno'], before['derivedDanno']);
    expect(after['derivedDifesa'], before['derivedDifesa']);

    final reopened =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    _load(state, probe, reopened);
    _load(state, probe, reopened);
    expect(_learnedSkills(state), hasLength(1));
    expect(reopened['skills'], hasLength(1));
    await closeFixture(tester, probe);
  });

  testWidgets('Mezzo Slime learns above threshold by its stored racial ID', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final sheet = _sheet(probe, race: 'Forma discreta', baseMatter: 13)
      ..['trattiRazziali'] = [
        {
          'nome': 'Origine personalizzata',
          'chiaveSistema': 'tutorial_race_mezzo_slime',
          'equipaggiato': true,
        },
      ];
    _load(state, probe, sheet);
    expect(_learnedSkills(state), hasLength(1));
    await closeFixture(tester, probe);
  });

  testWidgets('growth uses permanent Matter and rest does not revoke it', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    _load(
      state,
      probe,
      _sheet(probe, race: 'mezzo_slime', baseMatter: 11, currentMatter: 20),
    );
    state.datiCaricati = true;
    state.currentMateriaController.text = '20';
    probe.saveSheet();
    expect(_learnedSkills(state), isEmpty);

    state.occhiCaduti.add(<String, dynamic>{
      'id': 'temporary-fixture-eye',
      'ownerSheetId': probe.ownerTag(),
      'active': true,
      'summonStatBonuses': {'materia': 2},
    });
    probe.increaseBaseStat('materia', 2);
    probe.saveSheet();
    expect(
      _learnedSkills(state),
      isEmpty,
      reason: '11 permanent + 2 temporary',
    );

    probe.increaseBaseStat('materia', 1);
    probe.saveSheet();
    expect(_learnedSkills(state), hasLength(1));
    expect(probe.snapshot()[_learnedField], isTrue);

    probe.increaseBaseStat('materia', -3);
    state.occhiCaduti.clear();
    probe.shortRest();
    probe.saveSheet();
    final reopened =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    _load(state, probe, reopened);
    expect(reopened['materia'], '11');
    expect(_learnedSkills(state), hasLength(1));
    await closeFixture(tester, probe);
  });

  testWidgets('legacy ID and edited form survive learning and renaming', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final personal = CharacterSkill(
      id: 'slime_personale',
      nome: 'Forma Slime',
      tipo: 'Personalizzata',
      costo: '2 Oculum',
      cooldown: '4 turni',
      descrizione: 'Una descrizione del proprietario.',
    );
    personal.forme.single.effettiStrutturati.add(
      OculumStructuredEffect(
        id: 'custom_slime_effect',
        type: 'scudo',
        valueExpression: '7',
      ),
    );
    final sheet = _sheet(probe, race: 'Mezzo Slime', baseMatter: 11)
      ..['skills'] = [personal.toJson()];
    _load(state, probe, sheet);
    final edited = (state.skills as List<CharacterSkill>).single;
    expect(edited.toJson(), personal.toJson());
    expect(sheet[_learnedField], isTrue);

    edited.nome = 'Membrana personale';
    state.datiCaricati = true;
    probe.increaseBaseStat('materia', 2);
    probe.saveSheet();
    final reopened =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    _load(state, probe, reopened);
    final surviving = (state.skills as List<CharacterSkill>).single;
    expect(surviving.id, personal.id);
    expect(surviving.nome, 'Membrana personale');
    expect(surviving.forme.single.toJson(), personal.forme.single.toJson());

    final previousId = personal.toJson()
      ..['id'] = 'slime_form'
      ..['nome'] = 'Forma con nome già cambiato';
    final previousExport = _sheet(probe, race: 'Slime', baseMatter: 13)
      ..['skills'] = [previousId];
    _load(state, probe, previousExport);
    expect(previousExport[_learnedField], isTrue);
    expect((state.skills as List<CharacterSkill>).single.toJson(), previousId);
    await closeFixture(tester, probe);
  });

  testWidgets('unrelated races and foreign copies gain no extra skill', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    _load(state, probe, _sheet(probe, race: 'Custode Slime', baseMatter: 13));
    expect(_learnedSkills(state), isEmpty);

    final shared = _sheet(probe, race: 'slime', baseMatter: 12)
      ..['realtimeSharedSheet'] = true;
    _load(state, probe, shared);
    expect(_learnedSkills(state), isEmpty);
    expect(shared.containsKey(_learnedField), isFalse);
    await closeFixture(tester, probe);
  });
}
