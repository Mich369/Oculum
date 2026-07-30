import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

const _vars = <String, num>{
  'resilienza': 6,
  'volonta': 10,
  'materia': 12,
  'oculum': 8,
  'hp': 60,
  'hp_current': 45,
  'hp_temp': 3,
  'hp_temp_current': 2,
  'difesa': 4,
  'danni': 3,
  'scudo': 20,
  'scudo_current': 12,
  'scudo_oculum': 5,
  'scudo_oculum_current': 4,
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
  'reazione': 1,
  'reazione_veloce': 0,
  'resilienza_current': 5,
  'volonta_current': 7,
  'materia_current': 9,
  'oculum_current': 11,
};

Map<String, int> _typedTotals(String text, String key) {
  final totals = <String, int>{};
  for (final command in oculumParseFormulaCommands(text, _vars)) {
    if (!command.valid || command.key != key) continue;
    final element = command.elementId.isEmpty ? 'fisico' : command.elementId;
    totals.update(
      element,
      (current) => current + command.value,
      ifAbsent: () => command.value,
    );
  }
  return totals;
}

String _dominant(Map<String, int> totals) {
  var best = totals.entries.first;
  for (final entry in totals.entries.skip(1)) {
    if (entry.value > best.value) best = entry;
  }
  return best.key;
}

String _summary(Map<String, int> totals) {
  final keys = totals.keys.toList();
  final visible = keys.take(3).map(oculumElementDisplayIt).toList();
  if (keys.length > 3) visible.add('+${keys.length - 3}');
  return visible.join(' | ');
}

void main() {
  test('formula aritmetica semplice funziona per danno e cura', () {
    final value = oculumEvaluateFormula('10+100-20', _vars);
    expect(oculumRoundFormulaResult(value), 90);
  });

  test('percentuali nude usano il bersaglio e quelle composte la sorgente', () {
    OculumFormulaCommand parseOne(String text) {
      final parsed = oculumParseFormulaCommands(text, _vars);
      expect(parsed, hasLength(1), reason: text);
      expect(parsed.single.valid, isTrue, reason: text);
      return parsed.single;
    }

    expect(parseOne('@Mat+50%').value, 6);
    expect(parseOne('@Mat-25%').value, -3);
    expect(parseOne('@Mat+12,5%').value, 2);
    expect(parseOne('@Danni+150%').value, 5);
    expect(parseOne('Mat+Vol50%').value, 5);
    expect(parseOne('@Mat+50%Vol').value, 5);
    expect(parseOne('@Mat+(Vol+Res)25%').value, 4);
  });

  test('percentuali nude si calcolano separatamente per Stats e TiroStats', () {
    final stats = oculumParseFormulaCommands('@Stats+50%', _vars);
    expect(stats.map((command) => command.key), <String>[
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ]);
    expect(stats.map((command) => command.value), <int>[3, 5, 6, 4]);

    final rolls = oculumParseFormulaCommands('@TiroStats+50%', _vars);
    expect(rolls.map((command) => command.key), <String>[
      'tiro_resilienza',
      'tiro_volonta',
      'tiro_materia',
      'tiro_oculum',
    ]);
    expect(rolls.map((command) => command.value), <int>[2, 3, 3, 2]);
  });

  test('il Punto Cieco entra nelle formule runtime del Titolo', () {
    final title = OculumTitle(
      nome: 'Titolo test',
      tipo: 'Attributo',
      ottenimento: '',
      buff: '@Mat+25%',
      puntoCieco: '@Mat-50%',
      skill: '',
      richiede: '',
      equipaggiato: true,
    );

    final texts = oculumActiveTitleFormulaTexts(title).toList();
    expect(texts, contains(title.puntoCieco));
    final commands = oculumParseFormulaCommands(
      texts.join(' '),
      _vars,
    ).where((command) => command.key == 'materia').toList();
    expect(commands.map((command) => command.value), <int>[3, -6]);
  });

  test('parser riconosce danni elementali dungeon e formule compatte', () {
    final cases = <String, MapEntry<String, int>>{
      '@Danni+15 Fulmine': const MapEntry('fulmine', 15),
      '@Danni+15Fulmine': const MapEntry('fulmine', 15),
      '@Danni+Vol/2 Fuoco': const MapEntry('fuoco', 5),
      '@Danni+Vol/2Fuoco': const MapEntry('fuoco', 5),
      '@Danni+Mat/3 Gelo': const MapEntry('gelo', 4),
      '@Danni+Mat/3Gelo': const MapEntry('gelo', 4),
      '@Danni+\u2153Mat Gelo': const MapEntry('gelo', 4),
      '@Danni+\u00BDVol Fuoco': const MapEntry('fuoco', 5),
      '@Danni+25%Ocu Lunare': const MapEntry('lunare', 2),
      '@Danni+25%OcuLunare': const MapEntry('lunare', 2),
      '@Danni+10 Vapium': const MapEntry('vapium', 10),
      '@Danni+8 Slime': const MapEntry('slime', 8),
      '@Danni+12 Cristallo': const MapEntry('cristallo', 12),
      '@Danni+5 Postea': const MapEntry('postea', 5),
      '@Danni+7 Radice': const MapEntry('radice', 7),
      '@Danni+10 Taglio': const MapEntry('taglio', 10),
      '@Danni+8 Cenere': const MapEntry('cenere', 8),
      '@Danni+5 Sonoro': const MapEntry('sonoro', 5),
      '@Danni+5 Non morto': const MapEntry('nonmorto', 5),
    };

    for (final entry in cases.entries) {
      final parsed = oculumParseFormulaCommands(entry.key, _vars);
      expect(parsed, hasLength(1), reason: entry.key);
      expect(parsed.single.valid, isTrue, reason: entry.key);
      expect(parsed.single.elementId, entry.value.key, reason: entry.key);
      expect(parsed.single.value, entry.value.value, reason: entry.key);
    }
  });

  test('difesa tipizzata resta numerica e somma duplicati', () {
    expect(_typedTotals('@Difesa+15 Cenere', 'difesa'), equals({'cenere': 15}));
    expect(
      _typedTotals('@Difesa+10 Osso @Difesa+5 Cenere', 'difesa'),
      equals({'osso': 10, 'cenere': 5}),
    );

    final totals = _typedTotals(
      '@Difesa+10 Cenere @Difesa+5 Cenere @Difesa+8 Osso',
      'difesa',
    );
    expect(totals, equals({'cenere': 15, 'osso': 8}));
    expect(_dominant(totals), 'cenere');

    expect(_typedTotals('@Difesa+8 Null', 'difesa'), equals({'vuoto': 8}));
    expect(
      _typedTotals('@Difesa+4 Non morto', 'difesa'),
      equals({'nonmorto': 4}),
    );
  });

  test('parser copre ogni statistica base e alias Stats italiani', () {
    final parsed = oculumParseFormulaCommands(
      '@Res+1 @Volonta+2 @Materia+3 @Oculum+4 @Statistiche+5',
      _vars,
    );

    final totals = <String, int>{};
    for (final command in parsed) {
      if (!command.valid) continue;
      totals.update(
        command.key,
        (current) => current + command.value,
        ifAbsent: () => command.value,
      );
    }

    expect(totals['resilienza'], 6);
    expect(totals['volonta'], 7);
    expect(totals['materia'], 8);
    expect(totals['oculum'], 9);
  });

  test('parser riconosce risorse e statistiche attuali nelle formule', () {
    expect(oculumStatKey('HPAttuali'), 'hp_current');
    expect(oculumStatKey('VitaAttuale'), 'hp_current');
    expect(oculumStatKey('OculumAttuale'), 'oculum_current');
    expect(oculumStatKey('MateriaAttuale'), 'materia_current');
    expect(oculumStatKey('VolontaAttuale'), 'volonta_current');

    final parsed = oculumParseFormulaCommands(
      '@Danni+HPAttuali/10 @Difesa+OculumAttuale/2 @Materia+VolontaAttuale/7',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'danni',
      'difesa',
      'materia',
    ]);
    expect(parsed.map((command) => command.value), [5, 6, 1]);
  });

  test('dettagli elemento si riallineano al totale reale', () {
    final difese = <String, int>{'fisico': 10, 'cenere': 15};

    oculumReconcileElementTotals(
      difese,
      expectedTotal: 20,
      fallbackElement: 'Fisico',
    );
    expect(difese, equals({'fisico': 5, 'cenere': 15}));

    oculumReconcileElementTotals(
      difese,
      expectedTotal: 8,
      fallbackElement: 'Fisico',
    );
    expect(difese, equals({'cenere': 8}));

    oculumReconcileElementTotals(
      difese,
      expectedTotal: 12,
      fallbackElement: 'Fisico',
    );
    expect(difese, equals({'cenere': 8, 'fisico': 4}));
  });

  test('fatica sotto meta risorsa scatta solo entrando in soglia', () {
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 6, after: 5, maximum: 10),
      isTrue,
    );
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 5, after: 4, maximum: 10),
      isFalse,
    );
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 4, after: 3, maximum: 10),
      isFalse,
    );
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 6, after: 6, maximum: 10),
      isFalse,
    );
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 6, after: 7, maximum: 10),
      isFalse,
    );
    expect(
      oculumShouldApplyHalfResourceFatigue(before: 6, after: 5, maximum: 0),
      isFalse,
    );
  });

  test('esplosione di Oculum usa gli esiti finali richiesti', () {
    expect(
      oculumExplosionAftermathForRoll(0),
      OculumExplosionAftermath.oculumRollPenalty,
    );
    expect(
      oculumExplosionAftermathForRoll(55),
      OculumExplosionAftermath.oculumRollPenalty,
    );
    expect(
      oculumExplosionAftermathForRoll(56),
      OculumExplosionAftermath.ashOne,
    );
    expect(
      oculumExplosionAftermathForRoll(91),
      OculumExplosionAftermath.ashOne,
    );
    expect(
      oculumExplosionAftermathForRoll(92),
      OculumExplosionAftermath.ashThree,
    );
    expect(
      oculumExplosionAftermathForRoll(100),
      OculumExplosionAftermath.ashThree,
    );
  });

  test('normalizzazione riconosce accenti reali e alias sicuri', () {
    expect(oculumNormalizeText('Volont\u00E0'), 'volonta');
    expect(oculumStatKey('Volont\u00E0'), 'volonta');
    expect(oculumStatKey('PV'), 'hp');
    expect(oculumStatKey('Dmg'), 'danni');
    expect(oculumStatKey('Reazioni'), 'reazione');
    expect(oculumStatKey('ReazioneVeloce'), 'reazione_veloce');
    expect(oculumStatKey('ReazioeVeloce'), 'reazione_veloce');
    expect(oculumNormalizeElementId('Normal'), 'fisico');
    expect(oculumNormalizeElementId('Niente'), 'vuoto');
    expect(oculumNormalizeElementId('Nothing'), 'vuoto');
  });

  test('parser riconosce reazioni normali e veloci', () {
    final parsed = oculumParseFormulaCommands(
      '@Reazione+1 @Reazioni+2 @ReazioneVeloce+1 @ReazioeVeloce+1',
      _vars,
    ).where((command) => command.valid).toList();

    final totals = <String, int>{};
    for (final command in parsed) {
      totals.update(
        command.key,
        (current) => current + command.value,
        ifAbsent: () => command.value,
      );
    }

    expect(totals['reazione'], 3);
    expect(totals['reazione_veloce'], 2);
  });

  test('duplicati danno, dominante, sconosciuti e sintesi breve', () {
    final damage = _typedTotals(
      '@Danni+10 Fuoco @Danni+5 Fuoco @Danni+8 Gelo',
      'danni',
    );
    expect(damage, equals({'fuoco': 15, 'gelo': 8}));
    expect(_dominant(damage), 'fuoco');

    final mixed = _typedTotals(
      '@Danni+10 Taglio @Danni+15 Fulmine @Danni+5 Oscuro',
      'danni',
    );
    expect(_dominant(mixed), 'fulmine');
    expect(mixed.keys.toSet(), equals({'taglio', 'fulmine', 'oscuro'}));

    final unknown = oculumParseFormulaCommands('@Danni+3 TipoMaiVisto', _vars);
    expect(unknown.single.valid, isTrue);
    expect(unknown.single.value, 3);
    expect(unknown.single.elementId, 'tipomaivisto');

    final longSummary = _summary(
      _typedTotals(
        '@Danni+1 Fuoco @Danni+1 Fulmine @Danni+1 Gelo @Danni+1 Osso',
        'danni',
      ),
    );
    expect(longSummary, 'Fuoco | Fulmine | Gelo | +1');
  });

  test('formule impossibili restano invalide senza bloccare il parser', () {
    final parsed = oculumParseFormulaCommands(
      '@Danni+10/0 Fuoco @Danni+2 Gelo',
      _vars,
    );

    expect(parsed, hasLength(2));
    expect(parsed.first.valid, isFalse);
    expect(parsed.first.value, 0);
    expect(parsed.first.elementId, 'fuoco');
    expect(parsed.first.error.toLowerCase(), contains('divisione'));
    expect(parsed.last.valid, isTrue);
    expect(parsed.last.elementId, 'gelo');
    expect(parsed.last.value, 2);
  });

  test('comandi effettivi convertono VC e CM in Volonta e Materia', () {
    final parsed = oculumParseEffectiveFormulaCommands(
      '@VC+1 @CM+1 @Danni+2',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'volonta',
      'materia',
      'danni',
    ]);
    expect(parsed.map((command) => command.value), [3, 2, 2]);
  });

  test('parser riconosce nuovi comandi vita, scudo oculum e tiri', () {
    final parsed = oculumParseFormulaCommands(
      '@Iniziativa+5 @Movimento+2 @HP+5 @Vita+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5 @SchivataOculum+1 @SchivateOculum+2 @TiroAttacco+1 @TiroDifesa+1 @TiroVC+2 @TiroCM+3 @TiroVolont\u00E0+1 @TiroRes+2 @TiroMateria+3 @TiroOculum+4',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'iniziativa',
      'movimento',
      'hp',
      'hp',
      'hp_temp',
      'scudo',
      'scudo_oculum',
      'schivata_oculum',
      'schivata_oculum',
      'tiro_attacco',
      'tiro_difesa',
      'tiro_attacco',
      'tiro_difesa',
      'tiro_volonta',
      'tiro_resilienza',
      'tiro_materia',
      'tiro_oculum',
    ]);
    expect(parsed.map((command) => command.value), [
      5,
      2,
      5,
      5,
      2,
      3,
      5,
      1,
      2,
      1,
      1,
      2,
      3,
      1,
      2,
      3,
      4,
    ]);
  });

  test('TiroStats espande i bonus dei tiri base senza toccare le stats', () {
    final parsed = oculumParseFormulaCommands('@TiroStats+1', _vars);

    expect(parsed.map((command) => command.key), [
      'tiro_resilienza',
      'tiro_volonta',
      'tiro_materia',
      'tiro_oculum',
    ]);
    expect(parsed.map((command) => command.value), [1, 1, 1, 1]);
  });

  test('Stats e OtherStats espandono le quattro statistiche senza loop', () {
    final allStats = oculumParseFormulaCommands('@Stats+1', _vars);
    expect(allStats.map((command) => command.key), [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ]);
    expect(allStats.map((command) => command.value), [1, 1, 1, 1]);

    final hpLoss = oculumParseFormulaCommands('@HP-10=Stats+1', _vars);
    expect(hpLoss.map((command) => command.key), [
      'volonta',
      'materia',
      'oculum',
    ]);
    expect(hpLoss.every((command) => command.triggerRaw == 'HP-10'), isTrue);

    final volLoss = oculumParseFormulaCommands('@Vol-1=Stats+1', _vars);
    expect(volLoss.map((command) => command.key), [
      'resilienza',
      'materia',
      'oculum',
    ]);
    expect(volLoss.every((command) => command.triggerRaw == 'Vol-1'), isTrue);

    final otherWill = oculumParseFormulaCommands(
      '@Will-1=OtherStats+1 @Vol-1=AltreStats+1',
      _vars,
    );
    expect(otherWill.map((command) => command.key), [
      'resilienza',
      'materia',
      'oculum',
      'resilienza',
      'materia',
      'oculum',
    ]);
  });

  test('parser preserva trigger, OnHit, divisioni e frazioni piccole', () {
    final parsed = oculumParseFormulaCommands(
      '@Danni+1OnHit Danni+2OnHit @Vol+1=-10HP @HP+1=Vol-1 @Difesa-\u00BC @Mat-1/3Vol @Mat-\u2153Vol',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'danni',
      'danni',
      'volonta',
      'hp',
      'difesa',
      'materia',
      'materia',
    ]);
    expect(parsed.map((command) => command.value), [1, 2, 1, 1, -1, -3, -3]);
    expect(parsed[0].triggerRaw, 'OnHit');
    expect(parsed[1].triggerRaw, 'OnHit');
    expect(parsed[2].triggerRaw, '-10HP');
    expect(parsed[3].triggerRaw, 'Vol-1');
  });

  test('parser riconosce trigger evento critici e scudo in italiano', () {
    final parsed = oculumParseFormulaCommands(
      '@Danni+1OnHit @Danni+2OnCrit @Danni+3OnMaxCrit @Danni+4On1Crit @Difesa+5OnShieldBreaks @HP+6 ad ogni colpo @Scudo+7 Critico Positivo @Materia+8 Critico Negativo @Volonta+9 Scudo Rotto',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'danni',
      'danni',
      'danni',
      'danni',
      'difesa',
      'hp',
      'scudo',
      'materia',
      'volonta',
    ]);
    expect(parsed.map((command) => command.value), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(parsed.map((command) => command.triggerRaw), [
      'OnHit',
      'OnCrit',
      'OnMaxCrit',
      'On1Crit',
      'OnShieldBreaks',
      'OnHit',
      'OnMaxCrit',
      'On1Crit',
      'OnShieldBreaks',
    ]);
  });

  test('parser riconosce trigger evento prima del comando', () {
    final parsed = oculumParseFormulaCommands(
      'OnMaxCrit+50HPAttuali @On1Crit-9HPAttuali OnHit+2Danni',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'hp_current',
      'hp_current',
      'danni',
    ]);
    expect(parsed.map((command) => command.value), [50, -9, 2]);
    expect(parsed.map((command) => command.triggerRaw), [
      'OnMaxCrit',
      'On1Crit',
      'OnHit',
    ]);
    expect(parsed.every((command) => command.valid), isTrue);
  });

  test('parser riconosce bonus ogni risorsa spesa o totale', () {
    final parsed = oculumParseFormulaCommands(
      '@Vol+1 ogni 10 HPSpesi @Danni+2 ogni 1 OcuSpeso @Difesa+1 ogni 5 HPSacrificati @Mat+1 ogni 3 ScudoSpeso @Res+1 ogni 20 VitaPersa @Ini+1 ogni 5 MatTotale',
      _vars,
    );

    expect(parsed.map((command) => command.key), [
      'volonta',
      'danni',
      'difesa',
      'materia',
      'resilienza',
      'iniziativa',
    ]);
    expect(parsed.map((command) => command.value), [1, 2, 1, 1, 1, 1]);
    expect(parsed.map((command) => command.triggerRaw), [
      'ogni 10 HPSpesi',
      'ogni 1 OcuSpeso',
      'ogni 5 HPSacrificati',
      'ogni 3 ScudoSpeso',
      'ogni 20 VitaPersa',
      'ogni 5 MatTotale',
    ]);
  });

  test('normalizza sorgenti dei trigger ogni', () {
    expect(oculumEveryTriggerSourceKey('HPSpesi'), 'hp_spent');
    expect(oculumEveryTriggerSourceKey('PVConsumati'), 'hp_spent');
    expect(oculumEveryTriggerSourceKey('VitaPersa'), 'hp_spent');
    expect(oculumEveryTriggerSourceKey('OcuSpeso'), 'oculum_spent');
    expect(oculumEveryTriggerSourceKey('VolontaSpesa'), 'volonta_spent');
    expect(oculumEveryTriggerSourceKey('WillSpeso'), 'volonta_spent');
    expect(oculumEveryTriggerSourceKey('MateriaSpesa'), 'materia_spent');
    expect(oculumEveryTriggerSourceKey('MateriaTotale'), 'materia_total');
    expect(oculumParseEveryTriggerSpec('ogni 5 MatTotale')?.divisor, 5);
    expect(oculumParseEveryTriggerSpec('ogni 1OculumSpeso')?.divisor, 1);
    expect(
      oculumParseEveryTriggerSpec('ogni 1OculumSpeso')?.sourceKey,
      'oculum_spent',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 2MateriaSpesa')?.sourceKey,
      'materia_spent',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 3VolontaSpesa')?.sourceKey,
      'volonta_spent',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 10HPAttuali')?.sourceKey,
      'hp_current',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 2OculumAttuale')?.sourceKey,
      'oculum_current',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 3MateriaAttuale')?.sourceKey,
      'materia_current',
    );
    expect(
      oculumParseEveryTriggerSpec('ogni 4VolontaAttuale')?.sourceKey,
      'volonta_current',
    );
  });

  test(
    'Stats e OtherStats con stat base spese non ridanno la stat consumata',
    () {
      final cases = <String, String>{
        '@Stats+1 ogni 1 VolontaSpesa': 'volonta',
        '@Stats+1 ogni 1 MateriaSpesa': 'materia',
        '@Stats+1 ogni 1 OcuSpeso': 'oculum',
        '@OtherStats+1 ogni 1 VolontaSpesa': 'volonta',
        '@OtherStats+1 ogni 1 MateriaSpesa': 'materia',
        '@OtherStats+1 ogni 1 OcuSpeso': 'oculum',
      };

      for (final entry in cases.entries) {
        final parsed = oculumParseFormulaCommands(entry.key, _vars);
        expect(
          parsed.map((command) => command.key),
          isNot(contains(entry.value)),
        );
        expect(parsed, hasLength(3), reason: entry.key);
        expect(
          parsed.every((command) => command.triggerRaw.startsWith('ogni 1 ')),
          isTrue,
          reason: entry.key,
        );
      }
    },
  );

  test(
    'Stats e OtherStats con HPSpesi non danno Resilienza e non creano loop',
    () {
      final everyStats = oculumParseFormulaCommands(
        '@Stats+1 ogni 50 HPSpesi',
        _vars,
      );

      expect(everyStats.map((command) => command.key), [
        'volonta',
        'materia',
        'oculum',
      ]);
      expect(everyStats.map((command) => command.value), [1, 1, 1]);
      expect(
        everyStats.every((command) => command.triggerRaw == 'ogni 50 HPSpesi'),
        isTrue,
      );

      final everyOtherStats = oculumParseFormulaCommands(
        '@OtherStats+1 ogni 50 HPSpesi',
        _vars,
      );

      expect(everyOtherStats.map((command) => command.key), [
        'volonta',
        'materia',
        'oculum',
      ]);
      expect(everyOtherStats.map((command) => command.value), [1, 1, 1]);
      expect(
        everyOtherStats.every(
          (command) => command.triggerRaw == 'ogni 50 HPSpesi',
        ),
        isTrue,
      );
    },
  );

  test('Stats ogni risorsa totale non HP resta completa', () {
    final matTotalStats = oculumParseFormulaCommands(
      '@Stats+1 ogni 5 MatTotale',
      _vars,
    );

    expect(matTotalStats.map((command) => command.key), [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ]);
    expect(matTotalStats.map((command) => command.value), [1, 1, 1, 1]);
  });

  test('parser gestisce due comandi con virgola e trigger ogni identici', () {
    final parsed = oculumParseFormulaCommands(
      '@Danni+2 ogni 1OculumSpeso, @Materia+1 ogni 1OculumSpeso',
      _vars,
    );

    expect(parsed, hasLength(2), reason: 'Dovrebbe parsare 2 comandi');
    expect(parsed[0].key, 'danni');
    expect(parsed[0].value, 2);
    expect(parsed[0].triggerRaw, 'ogni 1 OculumSpeso');
    expect(parsed[0].valid, isTrue);

    expect(parsed[1].key, 'materia');
    expect(parsed[1].value, 1);
    expect(parsed[1].triggerRaw, 'ogni 1 OculumSpeso');
    expect(parsed[1].valid, isTrue);
  });

  test(
    'ogni OculumSpeso calcola floor sorgente/divisore per Danni e Materia',
    () {
      int bonusFor(String text, int oculumSpent) {
        final parsed = oculumParseFormulaCommands(text, _vars);
        expect(parsed, hasLength(1));
        final command = parsed.single;
        final spec = oculumParseEveryTriggerSpec(command.triggerRaw);
        expect(spec?.sourceKey, 'oculum_spent');
        return command.value * (oculumSpent ~/ (spec?.divisor ?? 1));
      }

      for (final spent in <int>[0, 1, 3, 5]) {
        expect(
          bonusFor('@Danni+2 ogni 1OculumSpeso', spent),
          spent * 2,
          reason: 'Danni senza spazio, OculumSpeso=$spent',
        );
        expect(
          bonusFor('@Danni+2 ogni 1 OculumSpeso', spent),
          spent * 2,
          reason: 'Danni con spazio, OculumSpeso=$spent',
        );
        expect(
          bonusFor('@Materia+1 ogni 1OculumSpeso', spent),
          spent,
          reason: 'Materia senza spazio, OculumSpeso=$spent',
        );
        expect(
          bonusFor('@Materia+1 ogni 1 OculumSpeso', spent),
          spent,
          reason: 'Materia con spazio, OculumSpeso=$spent',
        );
        expect(
          bonusFor('@Danni+2 ogni 1OcuSpeso', spent),
          spent * 2,
          reason: 'Danni alias OcuSpeso, OculumSpeso=$spent',
        );
        expect(
          bonusFor('@Mat+1 ogni 1OcuSpeso', spent),
          spent,
          reason: 'Mat alias OcuSpeso, OculumSpeso=$spent',
        );
      }
    },
  );

  test('alias Oculum speso normalizzano tutti a oculum_spent', () {
    for (final alias in <String>[
      'OculumSpeso',
      'OculumSpesi',
      'OcuSpeso',
      'OcuSpesi',
      'OculumConsumati',
      'OculumConsumata',
      'OcuConsumati',
      'OcuConsumata',
      'OCSpeso',
      'OCSpesi',
    ]) {
      expect(oculumEveryTriggerSourceKey(alias), 'oculum_spent');
    }
  });

  test('@OculumSpeso+5 viene riconosciuto come comando diretto', () {
    final parsed = oculumParseFormulaCommands('@OculumSpeso+5', _vars);

    expect(parsed, hasLength(1));
    expect(parsed.single.key, 'oculum_spent');
    expect(parsed.single.value, 5);
    expect(parsed.single.valid, isTrue);
    expect(parsed.single.hasTrigger, isFalse);
  });

  test('un comando @ sconosciuto viene sempre segnalato', () {
    final parsed = oculumParseFormulaCommands(
      '@Danni+3 @ComandoCheNonEsiste+2',
      _vars,
    );
    expect(parsed.any((command) => command.valid), isTrue);
    expect(
      parsed.any(
        (command) =>
            !command.valid && command.error.contains('non riconosciuto'),
      ),
      isTrue,
    );
  });

  test('item conserva buff @ e stato equipaggiato nel salvataggio', () {
    final item = InventoryItem(
      nome: 'Reliquia Oculum',
      peso: 0.2,
      quantita: 1,
      note: 'Test',
      buff: '@HPTemp+Vol1/6 @ScudoOculum+5',
      equipaggiata: true,
    );

    final restored = InventoryItem.fromJson(item.toJson());

    expect(restored.buff, '@HPTemp+Vol1/6 @ScudoOculum+5');
    expect(restored.equipaggiata, isTrue);
    expect(restored.arma, isFalse);
    expect(restored.protegge, isFalse);
  });

  test('autocomplete completa comandi ed elementi senza cambiare altro', () {
    final commandController = TextEditingController(text: '@Dif');
    addTearDown(commandController.dispose);
    commandController.selection = TextSelection.collapsed(
      offset: commandController.text.length,
    );

    expect(
      oculumApplyCommandAutocomplete(commandController, linguaInglese: false),
      isTrue,
    );
    expect(commandController.text, '@Difesa');
    expect(
      commandController.selection.baseOffset,
      commandController.text.length,
    );

    final elementController = TextEditingController(text: '@Danni+10 Ful');
    addTearDown(elementController.dispose);
    elementController.selection = TextSelection.collapsed(
      offset: elementController.text.length,
    );

    expect(
      oculumApplyCommandAutocomplete(elementController, linguaInglese: false),
      isTrue,
    );
    expect(elementController.text, '@Danni+10 Fulmine');

    final multiWordController = TextEditingController(text: '@Difesa+4 Non');
    addTearDown(multiWordController.dispose);
    multiWordController.selection = TextSelection.collapsed(
      offset: multiWordController.text.length,
    );

    expect(
      oculumApplyCommandAutocomplete(multiWordController, linguaInglese: false),
      isTrue,
    );
    expect(multiWordController.text, '@Difesa+4 Non morto');
  });

  test('StatsSkill espande il comando rapido sulle quattro statistiche', () {
    final parsed = oculumParseFormulaCommands('@StatsSkill+2', _vars);
    expect(
      parsed.where((command) => command.valid).map((command) => command.key),
      containsAll(<String>['resilienza', 'volonta', 'materia', 'oculum']),
    );
  });

  test('accetta gli alias delle risorse immesse nelle Skill', () {
    expect(oculumStatKey('OculumImmesso'), 'oculum_spent');
    expect(oculumStatKey('OculumSkill'), 'oculum_spent');
    expect(oculumStatKey('ResilienzaSkill'), 'resilienza_spent');
    expect(oculumStatKey('VolontaSkill'), 'volonta_spent');
    expect(oculumStatKey('MateriaSkill'), 'materia_spent');
  });

  test('legge la percentuale libera del danno ricevuto', () {
    expect(oculumIncomingDamagePercentMultiplier('+25%'), 1.25);
    expect(oculumIncomingDamagePercentMultiplier('-20'), 0.8);
    expect(oculumIncomingDamagePercentMultiplier('-100%'), 0);
    expect(oculumIncomingDamagePercentMultiplier('boh'), isNull);
  });

  test('il critico porta la percentuale libera al gradino successivo', () {
    expect(oculumNextCriticalDamageMultiplier(1.15), 1.25);
    expect(oculumNextCriticalDamageMultiplier(1.25), 1.50);
    expect(oculumNextCriticalDamageMultiplier(0.80), 0.90);
    expect(oculumNextCriticalDamageMultiplier(6.0), 6.0);
  });

  test('il riposo breve recupera un quarto e non sottrae mai HP', () {
    expect(oculumShortRestQuarterRecovery(current: 0, maximum: 100), 25);
    expect(oculumShortRestQuarterRecovery(current: 99, maximum: 100), 100);
    expect(oculumShortRestHpAfter(current: 80, maximum: 60, d100: 1), 80);
    expect(oculumShortRestHpAfter(current: 40, maximum: 100, d100: 37), 77);
  });
}
