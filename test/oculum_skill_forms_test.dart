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
    expect(skill.forme.single.oculumMinimoUtilizzabile, 0);
    expect(skill.forme.single.oculumMassimoUtilizzabile, 0);
    expect(skill.forme.single.oculumMassimoMaestriaIniziale, 0);
    expect(skill.forme.single.usaOculumConfigurabile, isFalse);
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

  test('Ogni Forma conserva limiti Oculum indipendenti', () {
    final skill = CharacterSkill.fromJson({
      'nome': 'Trasmutazione',
      'forme': [
        {
          'nome': 'Forma rapida',
          'oculumMinimoUtilizzabile': 1,
          'oculumMassimoUtilizzabile': 3,
        },
        {
          'nome': 'Forma completa',
          'oculumMinimoUtilizzabile': 4,
          'oculumMassimoUtilizzabile': 9,
        },
      ],
    });

    expect(skill.forme[0].oculumMinimoUtilizzabile, 1);
    expect(skill.forme[0].oculumMassimoUtilizzabile, 3);
    expect(skill.forme[1].oculumMinimoUtilizzabile, 4);
    expect(skill.forme[1].oculumMassimoUtilizzabile, 9);

    final restored = CharacterSkill.fromJson(skill.toJson());
    expect(restored.forme[0].oculumMinimoUtilizzabile, 1);
    expect(restored.forme[0].oculumMassimoUtilizzabile, 3);
    expect(restored.forme[1].oculumMinimoUtilizzabile, 4);
    expect(restored.forme[1].oculumMassimoUtilizzabile, 9);
    expect(restored.forme[0].oculumMassimoMaestriaIniziale, 3);
    expect(restored.forme[1].oculumMassimoMaestriaIniziale, 9);
  });

  test('Alias inglesi e valori negativi vengono caricati in modo sicuro', () {
    final form = CharacterSkillForm.fromJson({
      'minimumUsableOculum': -3,
      'maximumUsableOculum': 7,
    });

    expect(form.oculumMinimoUtilizzabile, 0);
    expect(form.oculumMassimoUtilizzabile, 7);
  });

  test('Il massimo effettivo usa il minore tra massimo e disponibile', () {
    const aboveMaximum = OculumSkillUseLimits(
      minimum: 2,
      maximum: 6,
      available: 20,
    );
    const between = OculumSkillUseLimits(minimum: 2, maximum: 8, available: 5);

    expect(aboveMaximum.effectiveMaximum, 6);
    expect(aboveMaximum.accepts(6), isTrue);
    expect(aboveMaximum.accepts(7), isFalse);
    expect(between.effectiveMaximum, 5);
    expect(between.accepts(5), isTrue);
    expect(between.accepts(6), isFalse);
  });

  test('La configurazione 0/0 permette di spendere fino al disponibile', () {
    const limits = OculumSkillUseLimits(minimum: 0, maximum: 0, available: 8);

    expect(limits.unlimited, isTrue);
    expect(limits.effectiveMaximum, 8);
    expect(limits.accepts(0), isTrue);
    expect(limits.accepts(8), isTrue);
    expect(limits.accepts(9), isFalse);
  });

  test('Oculum inferiore al minimo blocca qualsiasi conferma', () {
    const limits = OculumSkillUseLimits(minimum: 4, maximum: 10, available: 3);

    expect(limits.hasEnoughOculum, isFalse);
    expect(limits.accepts(3), isFalse);
    expect(limits.accepts(4), isFalse);
  });

  test(
    'Valori sotto minimo, sopra massimo e configurazioni errate sono invalidi',
    () {
      const limits = OculumSkillUseLimits(
        minimum: 3,
        maximum: 7,
        available: 10,
      );
      const invalidLimits = OculumSkillUseLimits(
        minimum: 8,
        maximum: 2,
        available: 10,
      );

      expect(limits.accepts(2), isFalse);
      expect(limits.accepts(3), isTrue);
      expect(limits.accepts(7), isTrue);
      expect(limits.accepts(8), isFalse);
      expect(invalidLimits.configurationValid, isFalse);
      expect(invalidLimits.accepts(8), isFalse);
    },
  );

  test('Il parser accetta solo interi non negativi', () {
    expect(oculumParseSkillUseAmount('0'), 0);
    expect(oculumParseSkillUseAmount('12'), 12);
    expect(oculumParseSkillUseAmount(' 5 '), 5);
    expect(oculumParseSkillUseAmount(''), isNull);
    expect(oculumParseSkillUseAmount('-1'), isNull);
    expect(oculumParseSkillUseAmount('1.5'), isNull);
    expect(oculumParseSkillUseAmount('abc'), isNull);
    expect(oculumParseSkillUseAmount('2a'), isNull);
  });

  test('I limiti vengono letti solo dalla coppia valida a fine testo', () {
    final compact = oculumSkillTextLimitsAtEnd('Effetto 2 danni (1/5)');
    final spaced = oculumSkillTextLimitsAtEnd('Effetto\n( 2 / 8 )\n');
    final legacySpaces = oculumSkillTextLimitsAtEnd('Effetto (3 9)');

    expect(compact?.minimum, 1);
    expect(compact?.maximum, 5);
    expect(spaced?.minimum, 2);
    expect(spaced?.maximum, 8);
    expect(legacySpaces?.minimum, 3);
    expect(legacySpaces?.maximum, 9);
    expect(oculumSkillTextLimitsAtEnd('(1/5) altro testo'), isNull);
    expect(oculumSkillTextLimitsAtEnd('testo (5/1)'), isNull);
    expect(oculumSkillTextLimitsAtEnd('testo (-1/5)'), isNull);
    expect(oculumSkillTextLimitsAtEnd('testo (1.5/5)'), isNull);
    expect(oculumSkillTextLimitsAtEnd('testo (1/)'), isNull);
  });

  test('La descrizione configura i limiti solo come fallback iniziale', () {
    final automatic = CharacterSkillForm(
      descrizione: 'Forma automatica (1 / 5)\n',
    );
    final manual = CharacterSkillForm(
      descrizione: 'Forma testuale (1/5)',
      oculumMinimoUtilizzabile: 2,
      oculumMassimoUtilizzabile: 9,
    );
    final legacy = CharacterSkillForm.fromJson(<String, dynamic>{
      'descrizione': 'Salvataggio precedente (3/7)',
    });

    expect(automatic.oculumMinimoUtilizzabile, 1);
    expect(automatic.oculumMassimoUtilizzabile, 5);
    expect(automatic.oculumMassimoMaestriaIniziale, 5);
    expect(automatic.oculumLimitiConfiguratiManualmente, isFalse);
    expect(manual.oculumMinimoUtilizzabile, 2);
    expect(manual.oculumMassimoUtilizzabile, 9);
    expect(manual.oculumLimitiConfiguratiManualmente, isTrue);
    expect(legacy.oculumMinimoUtilizzabile, 3);
    expect(legacy.oculumMassimoUtilizzabile, 7);
  });

  test('Aggiornare il testo conserva la Maestria gia ottenuta', () {
    final form = CharacterSkillForm(descrizione: 'Forma (1/5)');
    form.oculumMassimoUtilizzabile = 7;
    form.descrizione = 'Forma aggiornata (2/6)';

    expect(form.aggiornaLimitiOculumDaDescrizione(), isTrue);
    expect(form.oculumMinimoUtilizzabile, 2);
    expect(form.oculumMassimoMaestriaIniziale, 6);
    expect(form.oculumMassimoUtilizzabile, 8);
  });

  test('La Maestria richiede almeno un Oculum realmente consumato', () {
    const zero = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 5,
      growthLimit: 15,
      selected: 0,
      validSelection: true,
    );
    const belowMaximum = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 5,
      growthLimit: 15,
      selected: 3,
      validSelection: true,
    );
    const exactMaximum = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 5,
      growthLimit: 15,
      selected: 5,
      validSelection: true,
    );

    expect(zero.appliedIncrease, 0);
    expect(zero.newMaximum, 5);
    expect(belowMaximum.appliedIncrease, 1);
    expect(exactMaximum.appliedIncrease, 2);
  });

  test('MAX limitato dall Oculum disponibile assegna solo uno', () {
    const limits = OculumSkillUseLimits(minimum: 0, maximum: 5, available: 3);
    final preview = OculumSkillMasteryPreview(
      minimum: limits.safeMinimum,
      currentMaximum: limits.safeMaximum,
      growthLimit: 15,
      selected: limits.effectiveMaximum,
      validSelection: limits.accepts(limits.effectiveMaximum),
    );

    expect(limits.effectiveMaximum, 3);
    expect(preview.appliedIncrease, 1);
  });

  test('Un cambiamento dell Oculum disponibile viene rivalidato', () {
    const initial = OculumSkillUseLimits(minimum: 3, maximum: 8, available: 8);
    const changed = OculumSkillUseLimits(minimum: 3, maximum: 8, available: 2);

    expect(initial.accepts(5), isTrue);
    expect(changed.accepts(5), isFalse);
  });

  test(
    'La guardia rende mutuamente esclusivi doppi click e conferme rapide',
    () {
      final guard = OculumSingleConfirmationGuard();

      expect(guard.tryStart(), isTrue);
      expect(guard.tryStart(), isFalse);
      expect(guard.tryStart(), isFalse);
      guard.release();
      expect(guard.tryStart(), isTrue);
    },
  );

  test('Maestria assegna +1 sotto il massimo e +2 sul massimo precedente', () {
    const below = OculumSkillMasteryPreview(
      minimum: 2,
      currentMaximum: 6,
      growthLimit: 12,
      selected: 5,
      validSelection: true,
    );
    const exactly = OculumSkillMasteryPreview(
      minimum: 2,
      currentMaximum: 6,
      growthLimit: 12,
      selected: 6,
      validSelection: true,
    );

    expect(below.appliedIncrease, 1);
    expect(below.newMaximum, 7);
    expect(exactly.appliedIncrease, 2);
    expect(exactly.newMaximum, 8);
  });

  test('Minimo uguale al massimo non aumenta la Maestria Skill', () {
    const fixedCost = OculumSkillMasteryPreview(
      minimum: 5,
      currentMaximum: 5,
      growthLimit: 15,
      selected: 5,
      validSelection: true,
    );
    const unlimitedZeroPair = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 0,
      growthLimit: 10,
      selected: 6,
      validSelection: true,
    );

    expect(fixedCost.requestedIncrease, 0);
    expect(fixedCost.appliedIncrease, 0);
    expect(fixedCost.newMaximum, 5);
    expect(unlimitedZeroPair.appliedIncrease, 0);
    expect(unlimitedZeroPair.newMaximum, 0);
  });

  test('Aumento +2 si ferma esattamente al limite della Forma successiva', () {
    final skill = CharacterSkill(
      nome: 'Sigillo',
      tipo: '',
      costo: '',
      cooldown: '',
      descrizione: '',
      forme: [
        CharacterSkillForm(
          nome: 'Forma I',
          oculumMinimoUtilizzabile: 2,
          oculumMassimoUtilizzabile: 7,
        ),
        CharacterSkillForm(
          nome: 'Forma II',
          oculumMinimoUtilizzabile: 5,
          oculumMassimoUtilizzabile: 8,
        ),
      ],
    );
    final limit = oculumSkillMasteryGrowthLimit(skill, 0);
    final preview = OculumSkillMasteryPreview(
      minimum: 2,
      currentMaximum: 7,
      growthLimit: limit,
      selected: 7,
      validSelection: true,
    );

    expect(limit, 8);
    expect(preview.requestedIncrease, 2);
    expect(preview.appliedIncrease, 1);
    expect(preview.newMaximum, 8);
  });

  test('Senza massimo della Forma successiva il limite è iniziale più 10', () {
    final skill = CharacterSkill(
      nome: 'Eco',
      tipo: '',
      costo: '',
      cooldown: '',
      descrizione: '',
      forme: [
        CharacterSkillForm(nome: 'Forma I', oculumMassimoUtilizzabile: 4),
        CharacterSkillForm(nome: 'Forma II'),
      ],
    );

    expect(oculumSkillMasteryGrowthLimit(skill, 0), 14);
    expect(oculumSkillMasteryGrowthLimit(skill, 1), 10);
  });

  test(
    'Il limite usa il massimo iniziale e non la Maestria della Forma dopo',
    () {
      final next = CharacterSkillForm(
        nome: 'Forma II',
        oculumMassimoUtilizzabile: 8,
      )..oculumMassimoUtilizzabile = 12;
      final skill = CharacterSkill(
        nome: 'Eco',
        tipo: '',
        costo: '',
        cooldown: '',
        descrizione: '',
        forme: [
          CharacterSkillForm(nome: 'Forma I', oculumMassimoUtilizzabile: 3),
          next,
        ],
      );

      expect(next.oculumMassimoMaestriaIniziale, 8);
      expect(oculumSkillMasteryGrowthLimit(skill, 0), 8);
    },
  );

  test('Il limite rilegge il costo non zero della Forma successiva', () {
    final skill = CharacterSkill(
      nome: 'Eco',
      tipo: '',
      costo: '',
      cooldown: '',
      descrizione: '',
      forme: [
        CharacterSkillForm(descrizione: 'Forma I (1 4)'),
        CharacterSkillForm(descrizione: 'Forma II (2 9)'),
      ],
    );

    expect(oculumSkillMasteryGrowthLimit(skill, 0), 9);
  });

  test('Al limite la Skill resta valida ma la Maestria mostra +0', () {
    const preview = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 10,
      growthLimit: 10,
      selected: 10,
      validSelection: true,
    );

    expect(preview.reached, isTrue);
    expect(preview.requestedIncrease, 0);
    expect(preview.appliedIncrease, 0);
    expect(preview.newMaximum, 10);
  });

  test('Anteprima non valida e annullamento non generano Maestria', () {
    const preview = OculumSkillMasteryPreview(
      minimum: 0,
      currentMaximum: 6,
      growthLimit: 10,
      selected: 6,
      validSelection: false,
    );

    expect(preview.appliedIncrease, 0);
    expect(preview.newMaximum, 6);
  });

  test('La Maestria resta separata tra Skill differenti', () {
    final first = CharacterSkill(
      nome: 'Prima',
      tipo: '',
      costo: '',
      cooldown: '',
      descrizione: '',
      forme: [CharacterSkillForm(oculumMassimoUtilizzabile: 4)],
    );
    final second = CharacterSkill(
      nome: 'Seconda',
      tipo: '',
      costo: '',
      cooldown: '',
      descrizione: '',
      forme: [CharacterSkillForm(oculumMassimoUtilizzabile: 9)],
    );
    final firstPreview = OculumSkillMasteryPreview(
      minimum: first.forme.single.oculumMinimoUtilizzabile,
      currentMaximum: first.forme.single.oculumMassimoUtilizzabile,
      growthLimit: oculumSkillMasteryGrowthLimit(first, 0),
      selected: 4,
      validSelection: true,
    );
    first.forme.single.oculumMassimoUtilizzabile = firstPreview.newMaximum;

    expect(first.forme.single.oculumMassimoUtilizzabile, 6);
    expect(second.forme.single.oculumMassimoUtilizzabile, 9);
  });

  test(
    'Molte Skill e Forme mantengono limiti corretti senza stato condiviso',
    () {
      final stopwatch = Stopwatch()..start();
      final skills = List<CharacterSkill>.generate(
        200,
        (skillIndex) => CharacterSkill(
          nome: 'Skill $skillIndex',
          tipo: '',
          costo: '',
          cooldown: '',
          descrizione: '',
          forme: List<CharacterSkillForm>.generate(
            12,
            (formIndex) => CharacterSkillForm(
              nome: 'Forma ${formIndex + 1}',
              oculumMinimoUtilizzabile: formIndex,
              oculumMassimoUtilizzabile: formIndex + skillIndex + 1,
            ),
          ),
        ),
      );
      final restored = skills
          .map((skill) => CharacterSkill.fromJson(skill.toJson()))
          .toList(growable: false);
      stopwatch.stop();

      expect(restored, hasLength(200));
      expect(restored[137].forme, hasLength(12));
      expect(restored[137].forme[9].oculumMinimoUtilizzabile, 9);
      expect(restored[137].forme[9].oculumMassimoUtilizzabile, 147);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    },
  );
}
