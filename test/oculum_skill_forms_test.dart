import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

const _vars = <String, num>{
  'resilienza': 6,
  'volonta': 10,
  'materia': 12,
  'oculum': 8,
  'hp': 60,
  'hp_temp': 0,
  'difesa': 4,
  'danni': 3,
  'scudo': 0,
  'scudo_oculum': 0,
  'vc': 2,
  'cm': 5,
  'iniziativa': 4,
  'movimento': 32,
  'tiro_attacco': 2,
  'tiro_difesa': 5,
  'tiro_resilienza': 4,
  'tiro_volonta': 5,
  'tiro_materia': 6,
  'tiro_oculum': 4,
};

void main() {
  test('Skill vecchia senza forme viene caricata come Forma 1', () {
    final skill = CharacterSkill.fromJson({
      'nome': 'Lama antica',
      'tipo': 'Tecnica',
      'costo': '3 Oculum',
      'cooldown': '1 turno',
      'descrizione': '@Danni+2 Fuoco',
      'equipaggiata': true,
    });

    expect(skill.forme, hasLength(1));
    expect(skill.forme.single.nome, 'Forma 1');
    expect(skill.forme.single.tipo, 'Tecnica');
    expect(skill.forme.single.costo, '3 Oculum');
    expect(skill.forme.single.cooldown, '1 turno');
    expect(skill.forme.single.descrizione, '@Danni+2 Fuoco');
  });

  test('Forme vengono salvate e ricaricate fino a massimo 12', () {
    final skill = CharacterSkill.fromJson({
      'nome': 'Sigillo',
      'tipo': 'Cerchio',
      'descrizione': 'Forma base',
      'forme': [
        {'nome': 'Forma 1', 'descrizione': '@Vol+1'},
        {'nome': 'Forma 2', 'buff': '@Mat+1'},
        {'nome': 'Forma 3', 'buff': '@Ocu+1'},
        {'nome': 'Forma 4', 'buff': '@Danni+1 Gelo'},
        {'nome': 'Forma 5', 'buff': '@Difesa+1 Cenere'},
        {'nome': 'Forma 6', 'buff': '@HP+999'},
      ],
    });

    expect(skill.forme, hasLength(6));

    final restored = CharacterSkill.fromJson(skill.toJson());
    expect(restored.forme, hasLength(6));
    expect(restored.forme[1].nome, 'Forma 2');
    expect(restored.forme[4].buff, '@Difesa+1 Cenere');
  });

  test('Forma 1 non duplica i vecchi campi nei comandi @', () {
    final skill = CharacterSkill.fromJson({
      'nome': 'Focus',
      'tipo': 'Tecnica',
      'descrizione': '@Vol+1',
      'forme': [
        {'nome': 'Forma 1', 'descrizione': '@Vol+1'},
      ],
    });

    final commands = <OculumFormulaCommand>[];
    for (final text in skill.forme.expand((form) => form.quickCommandTexts())) {
      commands.addAll(oculumParseFormulaCommands(text, _vars));
    }

    expect(commands.where((command) => command.key == 'volonta'), hasLength(1));
  });
}
