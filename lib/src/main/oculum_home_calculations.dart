part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeCalculations on _OculumHomePageState {
  Iterable<OculumTitle> get titoliCalcolabili sync* {
    yield* titoli;
    yield* trattiRazziali;
  }
  // CALCOLI STATS / HP / DERIVATI
  // =====================================================

  // =====================================================
  // BUFF CONDIZIONALI / TITOLI
  // =====================================================

  int buffCondizionaleResilienza(OculumTitle titolo) {
    int totale = 0;

    for (final buff in titolo.titleConditionalBuffs) {
      if (buff.attivo) totale += buff.resilienza;
    }

    for (final buff in titolo.openConditionalBuffs) {
      if (titolo.openAttiva && buff.attivo) totale += buff.resilienza;
    }

    for (final open in titolo.openExtra) {
      for (final buff in open.conditionalBuffs) {
        if (open.attiva && buff.attivo) totale += buff.resilienza;
      }
    }

    return totale;
  }

  int buffCondizionaleVolonta(OculumTitle titolo) {
    int totale = 0;

    for (final buff in titolo.titleConditionalBuffs) {
      if (buff.attivo) totale += buff.volonta;
    }

    for (final buff in titolo.openConditionalBuffs) {
      if (titolo.openAttiva && buff.attivo) totale += buff.volonta;
    }

    for (final open in titolo.openExtra) {
      for (final buff in open.conditionalBuffs) {
        if (open.attiva && buff.attivo) totale += buff.volonta;
      }
    }

    return totale;
  }

  int buffCondizionaleMateria(OculumTitle titolo) {
    int totale = 0;

    for (final buff in titolo.titleConditionalBuffs) {
      if (buff.attivo) totale += buff.materia;
    }

    for (final buff in titolo.openConditionalBuffs) {
      if (titolo.openAttiva && buff.attivo) totale += buff.materia;
    }

    for (final open in titolo.openExtra) {
      for (final buff in open.conditionalBuffs) {
        if (open.attiva && buff.attivo) totale += buff.materia;
      }
    }

    return totale;
  }

  int buffCondizionaleOculum(OculumTitle titolo) {
    int totale = 0;

    for (final buff in titolo.titleConditionalBuffs) {
      if (buff.attivo) totale += buff.oculum;
    }

    for (final buff in titolo.openConditionalBuffs) {
      if (titolo.openAttiva && buff.attivo) totale += buff.oculum;
    }

    for (final open in titolo.openExtra) {
      for (final buff in open.conditionalBuffs) {
        if (open.attiva && buff.attivo) totale += buff.oculum;
      }
    }

    return totale;
  }

  int buffCondizionaleKarma(OculumTitle titolo) {
    int totale = 0;

    for (final buff in titolo.titleConditionalBuffs) {
      if (buff.attivo) totale += buff.karma;
    }

    for (final buff in titolo.openConditionalBuffs) {
      if (titolo.openAttiva && buff.attivo) totale += buff.karma;
    }

    for (final open in titolo.openExtra) {
      for (final buff in open.conditionalBuffs) {
        if (open.attiva && buff.attivo) totale += buff.karma;
      }
    }

    return totale;
  }

  int buffResilienza() {
    int totale = 0;

    for (final titolo in titoliCalcolabili) {
      if (titolo.equipaggiato) {
        totale += titolo.resilienza;
        totale += buffCondizionaleResilienza(titolo);
      }
    }

    return totale + titleQuickBonus('resilienza') + artQuickBonus('resilienza');
  }

  int buffVolonta() {
    int totale = 0;

    for (final titolo in titoliCalcolabili) {
      if (titolo.equipaggiato) {
        totale += titolo.volonta;
        totale += buffCondizionaleVolonta(titolo);
      }
    }

    return totale + titleQuickBonus('volonta') + artQuickBonus('volonta');
  }

  int buffMateria() {
    int totale = 0;

    for (final titolo in titoliCalcolabili) {
      if (titolo.equipaggiato) {
        totale += titolo.materia;
        totale += buffCondizionaleMateria(titolo);
      }
    }

    return totale + titleQuickBonus('materia') + artQuickBonus('materia');
  }

  int buffOculum() {
    int totale = 0;

    for (final titolo in titoliCalcolabili) {
      if (titolo.equipaggiato) {
        totale += titolo.oculum;
        totale += buffCondizionaleOculum(titolo);
      }
    }

    return totale + titleQuickBonus('oculum') + artQuickBonus('oculum');
  }

  int karmaTitoli() {
    int totale = 0;

    for (final titolo in titoliCalcolabili) {
      if (titolo.equipaggiato) {
        totale += titolo.karma;
        totale += buffCondizionaleKarma(titolo);
      }
    }

    return totale;
  }

  int karmaTotale() {
    return leggiNumero(karmaController) + karmaTitoli();
  }

  int resilienzaBase() => leggiNumero(resilienzaController);
  int volontaBase() => leggiNumero(volontaController);
  int materiaBase() => leggiNumero(materiaController);
  int oculumBase() => leggiNumero(oculumController);

  Iterable<String> skillQuickCommandTexts(CharacterSkill skill) sync* {
    skill.ensureForms();
    yield skill.nome;
    for (final form in skill.forme) {
      yield* form.quickCommandTexts();
    }
  }

  int directSkillNumericBonus(String key) {
    int totale = 0;

    for (final skill in skills) {
      if (!skill.equipaggiata) continue;

      switch (key) {
        case 'resilienza':
          totale += skill.resilienza;
          break;
        case 'volonta':
          totale += skill.volonta;
          break;
        case 'materia':
          totale += skill.materia;
          break;
        case 'oculum':
          totale += skill.oculum;
          break;
        case 'danni':
          totale += skill.danni;
          break;
        case 'difesa':
          totale += skill.difesa;
          break;
      }
    }

    for (final art in arti) {
      if (!art.sbloccata) continue;

      for (final skill in art.skills) {
        final livello = artSkillBonusLevel(skill);
        if (livello <= 0) continue;

        switch (key) {
          case 'resilienza':
            totale += skill.resilienza * livello;
            break;
          case 'volonta':
            totale += skill.volonta * livello;
            break;
          case 'materia':
            totale += skill.materia * livello;
            break;
          case 'oculum':
            totale += skill.oculum * livello;
            break;
          case 'danni':
            totale += skill.danni * livello;
            break;
          case 'difesa':
            totale += skill.difesa * livello;
            break;
        }
      }
    }

    return totale;
  }

  int skillTextQuickBonus(String key) {
    int total = 0;

    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      for (final text in skillQuickCommandTexts(skill)) {
        total += parseTitleQuickCommands(text)[key] ?? 0;
      }
    }

    return total;
  }

  int skillFormaBonus(String key) {
    return directSkillNumericBonus(key) + skillTextQuickBonus(key);
  }

  int rebirthLevelBonus() {
    if (!rebirthato) return 0;
    return max(0, leggiNumero(livelloController)) * 2;
  }

  int resilienzaMassimoNaturale() {
    return max(
      0,
      resilienzaBase() +
          buffResilienza() +
          tempResilienza +
          skillFormaBonus('resilienza') +
          itemQuickBonus('resilienza') +
          globalQuickBonus('resilienza') +
          rebirthLevelBonus(),
    );
  }

  int volontaMassimoNaturale() {
    return max(
      0,
      volontaBase() +
          buffVolonta() +
          tempVolonta +
          skillFormaBonus('volonta') +
          itemQuickBonus('volonta') +
          globalQuickBonus('volonta') +
          rebirthLevelBonus(),
    );
  }

  int materiaMassimoNaturale() {
    return max(
      0,
      materiaBase() +
          buffMateria() +
          tempMateria +
          skillFormaBonus('materia') +
          itemQuickBonus('materia') +
          globalQuickBonus('materia') +
          rebirthLevelBonus(),
    );
  }

  int oculumMassimoNaturale() {
    return max(
      0,
      oculumBase() +
          buffOculum() +
          tempOculum +
          skillFormaBonus('oculum') +
          itemQuickBonus('oculum') +
          globalQuickBonus('oculum') +
          rebirthLevelBonus(),
    );
  }

  int currentResilienza() => readIntValue(currentResilienzaController.text);
  int currentVolonta() => readIntValue(currentVolontaController.text);
  int currentMateria() => readIntValue(currentMateriaController.text);

  int resilienzaMassimo() =>
      max(resilienzaMassimoNaturale(), resilienzaTotale());
  int volontaMassimo() => max(volontaMassimoNaturale(), volontaTotale());
  int materiaMassimo() => max(materiaMassimoNaturale(), materiaTotale());

  int conditionalBuffStatBonus(String key) {
    int total = 0;

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;

      void addBuff(ConditionalBuffEntry buff) {
        if (!buff.attivo) return;

        switch (key) {
          case 'resilienza':
            total += buff.resilienza;
            break;
          case 'volonta':
            total += buff.volonta;
            break;
          case 'materia':
            total += buff.materia;
            break;
          case 'oculum':
            total += buff.oculum;
            break;
        }
      }

      for (final buff in titolo.titleConditionalBuffs) {
        addBuff(buff);
      }

      if (titolo.openAttiva) {
        for (final buff in titolo.openConditionalBuffs) {
          addBuff(buff);
        }
      }

      for (final open in titolo.openExtra) {
        if (!open.attiva) continue;
        for (final buff in open.conditionalBuffs) {
          addBuff(buff);
        }
      }
    }

    return total;
  }

  int runtimeCurrentStatBonus(String key) {
    return titleQuickBonus(key) +
        artQuickBonus(key) +
        itemQuickBonus(key) +
        globalQuickBonus(key) +
        conditionalBuffStatBonus(key) +
        skillTextQuickBonus(key) +
        tempStatBonus(key) +
        statoForzaQuickBonus(key) +
        rebirthLevelBonus();
  }

  int tempStatBonus(String key) {
    switch (key) {
      case 'resilienza':
        return tempResilienza;
      case 'volonta':
        return tempVolonta;
      case 'materia':
        return tempMateria;
      case 'oculum':
        return tempOculum;
      default:
        return 0;
    }
  }

  int currentStatWithRuntimeBuffs(String key, int current) {
    return max(0, current + runtimeCurrentStatBonus(key));
  }

  int resilienzaTotale() =>
      currentStatWithRuntimeBuffs('resilienza', currentResilienza());
  int volontaTotale() =>
      currentStatWithRuntimeBuffs('volonta', currentVolonta());
  int materiaTotale() =>
      currentStatWithRuntimeBuffs('materia', currentMateria());
  int oculumTotale() => currentStatWithRuntimeBuffs('oculum', currentOculum());

  String? titleQuickCommandKey(String rawCommand) {
    final command = rawCommand.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    switch (command) {
      case 'vc':
      case 'volontacombattiva':
        return 'vc';
      case 'cm':
      case 'cerchiomagico':
        return 'cm';
      case 'difesa':
      case 'def':
      case 'dif':
      case 'defense':
        return 'difesa';
      case 'reazione':
      case 'reazioni':
      case 'reaction':
      case 'reactions':
      case 'rea':
        return 'reazione';
      case 'reazioneveloce':
      case 'reazioniveloce':
      case 'reazioniveloci':
      case 'reazioeveloce':
      case 'fastreaction':
      case 'fastreactions':
      case 'quickreaction':
      case 'quickreactions':
        return 'reazione_veloce';
      case 'danno':
      case 'danni':
      case 'dan':
      case 'dmg':
      case 'damage':
        return 'danni';
      case 'hp':
      case 'vita':
      case 'life':
      case 'health':
        return 'hp';
      case 'hptemp':
      case 'hptemporanei':
      case 'hptemporaneo':
      case 'vitatemporanea':
      case 'vitetemporanee':
      case 'temp':
      case 'temporaryhp':
        return 'hp_temp';
      case 'scudo':
      case 'scu':
      case 'shield':
        return 'scudo';
      case 'scudooculum':
      case 'scudoocu':
      case 'scudooculare':
      case 'oculumshield':
      case 'eyeshield':
        return 'scudo_oculum';
      case 'schivataoculum':
      case 'schivateoculum':
      case 'schivataocu':
      case 'schivateocu':
      case 'schivataoculare':
      case 'schivateoculari':
      case 'oculumdodge':
      case 'oculumdodges':
      case 'eyedodge':
      case 'eyedodges':
        return 'schivata_oculum';
      case 'iniziativa':
      case 'ini':
      case 'initiative':
        return 'iniziativa';
      case 'mov':
      case 'move':
      case 'movement':
      case 'movimento':
        return 'movimento';
      case 'tiroattacco':
      case 'tirodiattacco':
      case 'tirovc':
      case 'tirovolontacombattiva':
      case 'attackroll':
        return 'tiro_attacco';
      case 'tirodifesa':
      case 'tirodifensivo':
      case 'tirocm':
      case 'tirocerchiomagico':
      case 'defenseroll':
        return 'tiro_difesa';
      case 'tirores':
      case 'tiroresilienza':
      case 'tiroresilience':
      case 'resroll':
        return 'tiro_resilienza';
      case 'tirovol':
      case 'tirovolont':
      case 'tirovolonta':
      case 'tirowill':
      case 'volroll':
      case 'willroll':
        return 'tiro_volonta';
      case 'tiromat':
      case 'tiromateria':
      case 'tiromatter':
      case 'matroll':
      case 'matterroll':
        return 'tiro_materia';
      case 'tiroocu':
      case 'tirooc':
      case 'tirooculum':
      case 'ocuroll':
      case 'oculumroll':
        return 'tiro_oculum';
      case 'tirostat':
      case 'tirostats':
      case 'tiroallstats':
      case 'tirostatistiche':
      case 'tiristats':
      case 'tiristatistiche':
      case 'statroll':
      case 'statsroll':
        return 'tiro_stats';
      case 'tirootherstats':
      case 'tiroaltrestats':
      case 'tiroaltrestatistiche':
      case 'otherstatsroll':
        return 'tiro_other_stats';
      case 'resilienza':
      case 'res':
        return 'resilienza';
      case 'volonta':
      case 'volont':
      case 'vol':
        return 'volonta';
      case 'materia':
      case 'mat':
        return 'materia';
      case 'oculum':
      case 'ocu':
        return 'oculum';
    }

    return null;
  }

  int quickCommandSortIndex(String key) {
    const order = [
      'danni',
      'hp',
      'hp_temp',
      'difesa',
      'reazione',
      'reazione_veloce',
      'vc',
      'cm',
      'iniziativa',
      'movimento',
      'tiro_attacco',
      'tiro_difesa',
      'tiro_resilienza',
      'tiro_volonta',
      'tiro_materia',
      'tiro_oculum',
      'scudo',
      'scudo_oculum',
      'schivata_oculum',
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ];

    final index = order.indexOf(key);
    return index < 0 ? order.length : index;
  }

  int directTitleStatBonus(String key) {
    var total = 0;

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;

      switch (key) {
        case 'resilienza':
          total += titolo.resilienza;
          break;
        case 'volonta':
          total += titolo.volonta;
          break;
        case 'materia':
          total += titolo.materia;
          break;
        case 'oculum':
          total += titolo.oculum;
          break;
      }
    }

    return total;
  }

  int safeFormulaStatValue(String key, int current, int temp) {
    return max(0, current + conditionalBuffStatBonus(key) + temp);
  }

  /// Contesto usato dal parser delle formule @...
  ///
  /// Non deve chiamare resilienzaTotale(), volontaTotale(), titleQuickBonus(),
  /// artQuickBonus(), dannoTotale() o difesa(): quelle funzioni leggono di nuovo
  /// le formule dei Titoli/Open/Art e causano ricorsione infinita.
  ///
  /// Qui usiamo solo valori gia disponibili e bonus numerici diretti: cosi le
  /// formule tipo @Mat-⅓Vol o @Danni+Scudo restano utili, ma non possono
  /// autodistruggere la build con uno StackOverflow.
  Map<String, num> formulaValueContext() {
    final res = safeFormulaStatValue(
      'resilienza',
      currentResilienza(),
      tempResilienza,
    );
    final vol = safeFormulaStatValue('volonta', currentVolonta(), tempVolonta);
    final mat = safeFormulaStatValue('materia', currentMateria(), tempMateria);
    final ocu = safeFormulaStatValue('oculum', currentOculum(), tempOculum);
    final livelloGrado = bonusLivelloGrado();
    final malusFatica = malusFaticaTiri();
    final vantaggio = vantaggioTiroBonus();
    final dif =
        ((vol + mat) ~/ 2) +
        livelloGrado +
        bonusDifesaRapido() +
        bonusDifesaEquipaggiamento() +
        directSkillNumericBonus('difesa');
    final baseDanni =
        vol +
        bonusDannoArmi() +
        livelloGrado +
        directSkillNumericBonus('danni');
    final baseHp = max(1, res) * moltiplicatoreHp();
    final baseMovimento = 30 + (mat ~/ 6);
    final grado = max(0, leggiNumero(gradoController));
    final baseSchivataOculum = grado ~/ 3;
    final baseReazioni = max(0, leggiNumero(reazioniController)) + (grado ~/ 6);
    final baseReazioniVeloci = max(0, leggiNumero(reazioniVelociController));
    final statRollBaseBonus = livelloGrado + malusFatica;

    return <String, num>{
      'resilienza': res,
      'volonta': vol,
      'materia': mat,
      'oculum': ocu,
      'livello': max(0, leggiNumero(livelloController)),
      'grado': grado,
      'livello_grado': livelloGrado,
      'vantaggio_tiro': vantaggio,
      'vantaggio': vantaggio,
      'fatica': max(0, leggiNumero(cenereController)),
      'cenere': max(0, leggiNumero(cenereController)),
      'hp': max(1, baseHp),
      'hp_current': max(0, leggiNumero(currentHpController)),
      'hp_temp': max(0, leggiNumero(hpTempController)),
      'hp_temp_current': max(0, leggiNumero(hpTempController)),
      'difesa': max(0, dif),
      'resilienza_current': res,
      'volonta_current': vol,
      'materia_current': mat,
      'oculum_current': ocu,
      'tiro_resilienza': max(0, (res ~/ 2) + statRollBaseBonus + vantaggio),
      'tiro_volonta': max(0, (vol ~/ 2) + statRollBaseBonus + vantaggio),
      'tiro_materia': max(0, (mat ~/ 2) + statRollBaseBonus + vantaggio),
      'tiro_oculum': max(0, (ocu ~/ 2) + statRollBaseBonus + vantaggio),
      'vc': max(
        0,
        livelloGrado +
            (vol ~/ 3) +
            bonusAttaccoRapido() +
            malusFatica +
            vantaggio,
      ),
      'cm': max(
        0,
        livelloGrado + (mat ~/ 2) + bonusCmRapido() + malusFatica + vantaggio,
      ),
      'iniziativa': max(0, livelloGrado + (mat ~/ 5) + malusFatica + vantaggio),
      'movimento': max(0, baseMovimento),
      'tiro_attacco': max(
        0,
        livelloGrado +
            (vol ~/ 3) +
            bonusAttaccoRapido() +
            malusFatica +
            vantaggio,
      ),
      'tiro_difesa': max(
        0,
        livelloGrado + (mat ~/ 2) + bonusCmRapido() + malusFatica + vantaggio,
      ),
      'danni': max(0, baseDanni),
      'reazione': max(0, baseReazioni),
      'reazioni': max(0, baseReazioni),
      'reazione_veloce': max(0, baseReazioniVeloci),
      'reazioni_veloci': max(0, baseReazioniVeloci),
      'scudo': max(0, leggiNumero(scudoController)),
      'scudo_current': max(0, leggiNumero(scudoController)),
      'scudo_oculum': max(0, leggiNumero(scudoOculumController)),
      'scudo_oculum_current': max(0, leggiNumero(scudoOculumController)),
      'schivata_oculum': max(0, baseSchivataOculum),
      'schivate_oculum': max(0, baseSchivataOculum),
    };
  }

  Map<String, int> parseTitleQuickCommands(String text) {
    final result = <String, int>{};
    if (text.trim().isEmpty) return result;

    for (final rawCommand in oculumParseFormulaCommands(
      text,
      formulaValueContext(),
    )) {
      final command = oculumEffectiveFormulaCommand(rawCommand);
      if (!command.valid) continue;
      final value = triggeredFormulaCommandValue(command);
      if (value == 0) continue;
      result.update(
        command.key,
        (current) => current + value,
        ifAbsent: () => value,
      );
    }

    return result;
  }

  List<OculumFormulaCommand> parseQuickCommandsDetailed(String text) {
    return oculumParseFormulaCommands(text, formulaValueContext());
  }

  int triggeredFormulaCommandValue(OculumFormulaCommand command) {
    if (!command.valid) return 0;
    final multiplier = formulaTriggerMultiplier(command);
    if (multiplier <= 0) return 0;
    return command.value * multiplier;
  }

  int formulaTriggerMultiplier(OculumFormulaCommand command) {
    final raw = command.triggerRaw.trim();
    if (raw.isEmpty) return 1;

    final everyMultiplier = formulaEveryTriggerMultiplier(raw);
    if (everyMultiplier != null) return everyMultiplier;

    final normalized = oculumNormalizeFormulaTriggerText(raw);
    if (normalized.isEmpty) return 1;

    final eventTrigger = oculumEventTriggerCanonical(raw);
    if (eventTrigger.isNotEmpty) {
      switch (eventTrigger) {
        case 'OnHit':
          final baseHp = (formulaValueContext()['hp'] ?? 0).round();
          return hpCorrenti() < baseHp ? 1 : 0;
        case 'OnCrit':
          return tiroCriticoVenti || tiroCriticoUno ? 1 : 0;
        case 'OnMaxCrit':
          return tiroCriticoVenti ? 1 : 0;
        case 'On1Crit':
          return tiroCriticoUno ? 1 : 0;
        case 'OnShieldBreaks':
          return scudoRefullTarget() > 0 && scudo() <= 0 ? 1 : 0;
      }
    }

    final keyThenDelta = RegExp(
      r'^([A-Za-zÀ-ÖØ-öø-ÿ_]+)([+-])(.+)$',
    ).firstMatch(normalized);
    if (keyThenDelta != null) {
      return formulaTriggerDeltaMultiplier(
        keyThenDelta.group(1) ?? '',
        keyThenDelta.group(2) ?? '-',
        keyThenDelta.group(3) ?? '',
      );
    }

    final deltaThenKey = RegExp(
      r'^([+-])(.+?)([A-Za-zÀ-ÖØ-öø-ÿ_]+)$',
    ).firstMatch(normalized);
    if (deltaThenKey != null) {
      return formulaTriggerDeltaMultiplier(
        deltaThenKey.group(3) ?? '',
        deltaThenKey.group(1) ?? '-',
        deltaThenKey.group(2) ?? '',
      );
    }

    return 0;
  }

  int? formulaEveryTriggerMultiplier(String rawTrigger) {
    final spec = oculumParseEveryTriggerSpec(rawTrigger);
    if (spec == null) return null;

    final sourceValue = formulaEveryTriggerSourceValue(spec.sourceKey);
    if (sourceValue <= 0) return 0;
    return max(0, sourceValue ~/ spec.divisor);
  }

  int formulaEveryTriggerSourceValue(String sourceKey) {
    if (_formulaTriggerSourceStack.contains(sourceKey)) return 0;

    _formulaTriggerSourceStack.add(sourceKey);
    try {
      return formulaEveryTriggerSourceValueUnchecked(sourceKey);
    } finally {
      _formulaTriggerSourceStack.removeLast();
    }
  }

  int formulaEveryTriggerSourceValueUnchecked(String sourceKey) {
    if (sourceKey.endsWith('_spent')) {
      final key = sourceKey.substring(0, sourceKey.length - '_spent'.length);
      final recordedSpent = formulaRecordedStatSpentValue(key);
      if (recordedSpent != null) return recordedSpent;
      return max(
        0,
        formulaSpentBaselineValue(key) - formulaSpentCurrentValue(key),
      );
    }

    if (sourceKey.endsWith('_total')) {
      final key = sourceKey.substring(0, sourceKey.length - '_total'.length);
      return max(0, formulaTriggerBaselineValue(key));
    }

    if (sourceKey.endsWith('_current')) {
      final key = sourceKey.substring(0, sourceKey.length - '_current'.length);
      return max(0, formulaTriggerCurrentValue(key));
    }

    return 0;
  }

  int? formulaRecordedStatSpentValue(String key) {
    switch (key) {
      case 'resilienza':
        return max(0, raccoltaResilienzaSpesa);
      case 'volonta':
        return max(0, raccoltaVolontaSpesa);
      case 'materia':
        return max(0, raccoltaMateriaSpesa);
      case 'oculum':
        return max(0, raccoltaOculumSpesa);
      default:
        return null;
    }
  }

  int formulaSpentBaselineValue(String key) {
    switch (key) {
      case 'resilienza':
      case 'volonta':
      case 'materia':
      case 'oculum':
        return statMassimo(key);
      case 'hp':
        return maxHp();
      case 'hp_temp':
        return max(
          0,
          leggiNumero(hpTempController) + max(0, runtimeQuickBonus('hp_temp')),
        );
      case 'scudo':
        return scudoRefullTarget();
      case 'scudo_oculum':
        return scudoOculumMax();
      default:
        return formulaTriggerBaselineValue(key);
    }
  }

  int formulaSpentCurrentValue(String key) {
    switch (key) {
      case 'resilienza':
      case 'volonta':
      case 'materia':
      case 'oculum':
        return currentStatValue(key);
      case 'hp':
        return hpCorrenti();
      case 'hp_temp':
        return hpTemp();
      case 'scudo':
        return scudo();
      case 'scudo_oculum':
        return scudoOculum();
      default:
        return formulaTriggerCurrentValue(key);
    }
  }

  int formulaBaseStatBaselineValue(String key) {
    int base;
    int temp;
    switch (key) {
      case 'resilienza':
        base = resilienzaBase();
        temp = tempResilienza;
        break;
      case 'volonta':
        base = volontaBase();
        temp = tempVolonta;
        break;
      case 'materia':
        base = materiaBase();
        temp = tempMateria;
        break;
      case 'oculum':
        base = oculumBase();
        temp = tempOculum;
        break;
      default:
        return (formulaValueContext()[key] ?? 0).round();
    }

    return max(
      0,
      base +
          directTitleStatBonus(key) +
          directSkillNumericBonus(key) +
          conditionalBuffStatBonus(key) +
          temp,
    );
  }

  String formulaEveryTriggerSourceLabel(String sourceKey) {
    if (sourceKey.endsWith('_spent')) {
      final key = sourceKey.substring(0, sourceKey.length - '_spent'.length);
      return '${formulaStatLabel(key)} spesi';
    }
    if (sourceKey.endsWith('_total')) {
      final key = sourceKey.substring(0, sourceKey.length - '_total'.length);
      return '${formulaStatLabel(key)} totale';
    }
    if (sourceKey.endsWith('_current')) {
      final key = sourceKey.substring(0, sourceKey.length - '_current'.length);
      return '${formulaStatLabel(key)} attuali';
    }
    return sourceKey;
  }

  String formulaStatLabel(String key) {
    switch (key) {
      case 'resilienza':
        return 'RES';
      case 'volonta':
        return 'VOL';
      case 'materia':
        return 'MAT';
      case 'oculum':
        return 'OCU';
      case 'hp':
        return 'HP';
      case 'scudo':
        return t('Scudo', 'Shield');
      case 'scudo_oculum':
        return t('Scudo Oculum', 'Oculum Shield');
      case 'danni':
        return t('Danni', 'Damage');
      case 'difesa':
        return t('Difesa', 'Defense');
      case 'iniziativa':
        return t('Iniziativa', 'Initiative');
      default:
        return key;
    }
  }

  String formulaTriggerDetail(OculumFormulaCommand command) {
    final raw = command.triggerRaw.trim();
    if (raw.isEmpty) return '';

    final spec = oculumParseEveryTriggerSpec(raw);
    if (spec != null) {
      final sourceValue = formulaEveryTriggerSourceValue(spec.sourceKey);
      final multiplier = max(0, sourceValue ~/ spec.divisor);
      return '${formulaEveryTriggerSourceLabel(spec.sourceKey)} $sourceValue / ${spec.divisor} = x$multiplier';
    }

    final multiplier = formulaTriggerMultiplier(command);
    return '$raw = x$multiplier';
  }

  int formulaTriggerDeltaMultiplier(
    String rawKey,
    String sign,
    String rawAmount,
  ) {
    final key = oculumStatKey(rawKey);
    if (key.isEmpty) return 0;

    double amountValue;
    try {
      amountValue = oculumEvaluateFormula(rawAmount, formulaValueContext());
    } catch (_) {
      return 0;
    }
    final amount = max(1, oculumRoundFormulaResult(amountValue).abs());
    final baseline = formulaTriggerBaselineValue(key);
    final current = formulaTriggerCurrentValue(key);
    final delta = sign == '-' ? baseline - current : current - baseline;
    if (delta <= 0) return 0;
    return max(0, delta ~/ amount);
  }

  int formulaTriggerBaselineValue(String key) {
    if (key.endsWith('_current')) {
      final baseKey = key.substring(0, key.length - '_current'.length);
      return formulaTriggerCurrentValue(baseKey);
    }
    if (key.endsWith('_total')) {
      final baseKey = key.substring(0, key.length - '_total'.length);
      return formulaTriggerBaselineValue(baseKey);
    }

    switch (key) {
      case 'resilienza':
      case 'volonta':
      case 'materia':
      case 'oculum':
        return formulaBaseStatBaselineValue(key);
      case 'hp':
        return max(1, formulaBaseStatBaselineValue('resilienza')) *
            moltiplicatoreHp();
      case 'hp_temp':
        return max(0, leggiNumero(hpTempController));
      case 'scudo':
        return max(0, leggiNumero(scudoController));
      case 'scudo_oculum':
        return max(0, leggiNumero(scudoOculumController));
      default:
        return (formulaValueContext()[key] ?? 0).round();
    }
  }

  int formulaTriggerCurrentValue(String key) {
    if (key.endsWith('_current')) {
      final baseKey = key.substring(0, key.length - '_current'.length);
      return formulaTriggerCurrentValue(baseKey);
    }
    if (key.endsWith('_total')) {
      final baseKey = key.substring(0, key.length - '_total'.length);
      return formulaTriggerBaselineValue(baseKey);
    }

    switch (key) {
      case 'resilienza':
        return safeFormulaStatValue(
          'resilienza',
          currentResilienza(),
          tempResilienza,
        );
      case 'volonta':
        return safeFormulaStatValue('volonta', currentVolonta(), tempVolonta);
      case 'materia':
        return safeFormulaStatValue('materia', currentMateria(), tempMateria);
      case 'oculum':
        return safeFormulaStatValue('oculum', currentOculum(), tempOculum);
      case 'hp':
        // Non usare hpCorrenti() qui: hpCorrenti() chiama maxHp(), maxHp()
        // legge i bonus rapidi e quindi puo rientrare nel parser dei comandi @.
        // Con trigger tipo @Stats+1 ogni 50 HPSpesi questo causava StackOverflow.
        // Per i trigger serve solo lo snapshot corrente scritto nella scheda.
        return max(0, leggiNumero(currentHpController));
      case 'hp_temp':
        return max(0, leggiNumero(hpTempController));
      case 'scudo':
        return max(0, leggiNumero(scudoController));
      case 'scudo_oculum':
        return max(0, leggiNumero(scudoOculumController));
      default:
        return (formulaValueContext()[key] ?? 0).round();
    }
  }

  void addTitleQuickCommands(Map<String, int> target, String text) {
    final parsed = parseTitleQuickCommands(text);
    for (final entry in parsed.entries) {
      target.update(
        entry.key,
        (current) => current + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }

  List<String> quickCommandDetailsForTexts(Iterable<String> texts, String key) {
    final details = <String>[];

    for (final text in texts) {
      for (final rawCommand in parseQuickCommandsDetailed(text)) {
        final command = oculumEffectiveFormulaCommand(rawCommand);
        if (!command.valid || command.key != key) continue;

        final multiplier = formulaTriggerMultiplier(command);
        if (multiplier <= 0) continue;

        final total = command.value * multiplier;
        if (total == 0) continue;

        final triggerDetail = formulaTriggerDetail(command);
        final sign = command.value >= 0 ? '+' : '';
        final totalSign = total >= 0 ? '+' : '';
        if (triggerDetail.isEmpty || multiplier == 1) {
          details.add(
            '@${command.key}$sign${command.value} = $totalSign$total',
          );
        } else {
          details.add(
            '@${command.key}$sign${command.value} ($triggerDetail) = $totalSign$total',
          );
        }
      }
    }

    return details;
  }

  List<String> quickCommandRuntimeDetails(String key) {
    final details = <String>[];

    void addDetails(String source, Iterable<String> texts) {
      for (final detail in quickCommandDetailsForTexts(texts, key)) {
        details.add('$source: $detail');
      }
    }

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;
      addDetails(
        titolo.nome.trim().isEmpty ? 'Titolo' : titolo.nome,
        activeTitleQuickTexts(titolo),
      );
    }

    for (final art in arti) {
      if (!art.sbloccata) continue;
      addDetails(
        art.nome.trim().isEmpty ? 'Art' : art.nome,
        activeArtQuickTexts(art),
      );
    }

    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      addDetails(
        item.nome.trim().isEmpty ? 'Oggetto' : item.nome,
        activeItemQuickTexts(item),
      );
    }

    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      addDetails(
        skill.nome.trim().isEmpty ? 'Skill' : skill.nome,
        skillQuickCommandTexts(skill),
      );
    }

    addDetails('Buff/Malus', [buffMalusRapidiController.text]);

    if (details.length <= 6) return details;
    return <String>[
      ...details.take(6),
      '+${details.length - 6} altri dettagli @',
    ];
  }

  Map<String, int> titleQuickBonuses(OculumTitle titolo) {
    final bonuses = <String, int>{};

    for (final text in activeTitleQuickTexts(titolo)) {
      addTitleQuickCommands(bonuses, text);
    }

    return bonuses;
  }

  String activeQuickCommandText() {
    final parts = <String>[];
    for (final titolo in titoli) {
      if (!titolo.equipaggiato) continue;
      parts.addAll(activeTitleQuickTexts(titolo));
    }
    for (final art in arti) {
      if (!art.sbloccata) continue;
      parts.addAll(activeArtQuickTexts(art));
    }
    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      parts.addAll(activeItemQuickTexts(item));
    }
    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      parts.addAll(skillQuickCommandTexts(skill));
    }
    parts.add(buffMalusRapidiController.text);
    return parts.where((text) => text.trim().isNotEmpty).join('\n');
  }

  int quickResilienzaBonusFromTexts(Iterable<String> texts) {
    var total = 0;
    for (final text in texts) {
      total += parseTitleQuickCommands(text)['resilienza'] ?? 0;
    }
    return total;
  }

  int titleQuickResilienzaBonus(OculumTitle titolo) {
    return quickResilienzaBonusFromTexts(activeTitleQuickTexts(titolo));
  }

  int skillQuickResilienzaBonus(CharacterSkill skill) {
    return quickResilienzaBonusFromTexts(skillQuickCommandTexts(skill));
  }

  int conditionalResilienzaBonus(Iterable<ConditionalBuffEntry> buffs) {
    var total = 0;
    for (final buff in buffs) {
      if (buff.attivo) total += buff.resilienza;
    }
    return total;
  }

  Iterable<String> activeTitleQuickTexts(OculumTitle titolo) sync* {
    yield titolo.buff;

    if (titolo.evoluto && titolo.openAttiva) {
      yield titolo.openBuff;
    }

    for (final open in titolo.openExtra) {
      if (!open.attiva) continue;
      yield open.openBuff;
    }
  }

  Map<String, int> detectedTitleQuickCommands(OculumTitle titolo) {
    final detected = <String, int>{};

    void add(String text) => addTitleQuickCommands(detected, text);

    add(titolo.buff);
    add(titolo.openBuff);

    for (final open in titolo.openExtra) {
      add(open.openBuff);
    }

    return detected;
  }

  int titleQuickBonus(String key) {
    int total = 0;
    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;
      total += titleQuickBonuses(titolo)[key] ?? 0;
    }
    return total;
  }

  bool isDefiledArt(CharacterArt art) {
    final normalized = oculumNormalizeText(cleanUiText(art.tipo));
    return normalized.contains('defiled');
  }

  bool isRuneArt(CharacterArt art) {
    final normalized = oculumNormalizeText(
      cleanUiText('${art.tipo} ${art.nome}'),
    );
    return normalized.contains('rune') ||
        normalized.contains('runica') ||
        normalized.contains('runico');
  }

  int artMaxLevel(CharacterArt art) {
    if (isDefiledArt(art)) return 5;
    if (isRuneArt(art)) return 4;
    return 3;
  }

  String artLevelRoman(int level) {
    switch (level) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      default:
        return '0';
    }
  }

  CharacterArt? parentArtForSkill(ArtSkill target) {
    for (final art in arti) {
      for (final skill in art.skills) {
        if (identical(skill, target)) return art;
      }
    }
    return null;
  }

  int artSkillMaxLevel(ArtSkill skill) {
    final art = parentArtForSkill(skill);
    return art == null ? 5 : artMaxLevel(art);
  }

  int artSkillBonusLevel(ArtSkill skill) {
    return skill.livello.clamp(0, artSkillMaxLevel(skill)).toInt();
  }

  bool artOpenSbloccata(CharacterArt art) {
    if (!art.sbloccata || art.skills.isEmpty) return false;
    final requiredLevel = artMaxLevel(art);
    return art.skills.every(
      (skill) => artSkillBonusLevel(skill) >= requiredLevel,
    );
  }

  int artLivelloComune(CharacterArt art) {
    if (art.skills.isEmpty) return 0;
    return art.skills
        .map((skill) => artSkillBonusLevel(skill))
        .reduce((value, element) => min(value, element));
  }

  String artSkillActiveLevelText(ArtSkill skill) {
    return artSkillTextForLevel(skill, artSkillBonusLevel(skill));
  }

  String artSkillTextForLevel(ArtSkill skill, int level) {
    switch (level.clamp(0, 5).toInt()) {
      case 1:
        return skill.evo1;
      case 2:
        return skill.evo2;
      case 3:
        return skill.evo3;
      case 4:
        return skill.evo4;
      case 5:
        return skill.evo5;
      default:
        return '';
    }
  }

  int artSkillQuickResilienzaBonusAtLevel(ArtSkill skill, int level) {
    return quickResilienzaBonusFromTexts([artSkillTextForLevel(skill, level)]);
  }

  int artOpenQuickResilienzaBonus(CharacterArt art) {
    return quickResilienzaBonusFromTexts([art.openBuff]);
  }

  int titleOpenRuntimeResilienzaBonus(OculumTitle titolo) {
    return quickResilienzaBonusFromTexts([titolo.openBuff]) +
        conditionalResilienzaBonus(titolo.openConditionalBuffs);
  }

  int extraOpenRuntimeResilienzaBonus(TitleOpenEntry open) {
    return quickResilienzaBonusFromTexts([open.openBuff]) +
        conditionalResilienzaBonus(open.conditionalBuffs);
  }

  int activeTitleOpenRuntimeResilienzaBonus(OculumTitle titolo) {
    var total = 0;
    if (titolo.openAttiva) {
      total += titleOpenRuntimeResilienzaBonus(titolo);
    }
    for (final open in titolo.openExtra) {
      if (open.attiva) total += extraOpenRuntimeResilienzaBonus(open);
    }
    return total;
  }

  void disattivaOpenDelTitolo(OculumTitle titolo) {
    final deltaRes = titolo.equipaggiato
        ? -activeTitleOpenRuntimeResilienzaBonus(titolo)
        : 0;
    titolo.openAttiva = false;
    for (final open in titolo.openExtra) {
      open.attiva = false;
    }
    if (deltaRes != 0) rimarginaHpDaAumentoResilienza(deltaRes);
  }

  void equipaggiaTitoloPerOpen(OculumTitle titolo) {
    if (titolo.equipaggiato) return;
    final runtimeRes =
        titleQuickResilienzaBonus(titolo) + buffCondizionaleResilienza(titolo);
    titolo.equipaggiato = true;
    applicaBonusTitoloAttuali(titolo, 1);
    rimarginaHpDaAumentoResilienza(runtimeRes);
  }

  void disattivaTutteLeOpen({
    OculumTitle? exceptTitle,
    TitleOpenEntry? exceptOpenExtra,
    CharacterArt? exceptArt,
  }) {
    void scanTitles(List<OculumTitle> list) {
      for (final titolo in list) {
        final keepMain =
            exceptTitle != null &&
            identical(titolo, exceptTitle) &&
            exceptOpenExtra == null;

        if (titolo.openAttiva && !keepMain) {
          if (titolo.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              -titleOpenRuntimeResilienzaBonus(titolo),
            );
          }
          titolo.openAttiva = false;
        }

        for (final open in titolo.openExtra) {
          final keepExtra =
              exceptTitle != null &&
              identical(titolo, exceptTitle) &&
              exceptOpenExtra != null &&
              identical(open, exceptOpenExtra);

          if (open.attiva && !keepExtra) {
            if (titolo.equipaggiato) {
              rimarginaHpDaAumentoResilienza(
                -extraOpenRuntimeResilienzaBonus(open),
              );
            }
            open.attiva = false;
          }
        }
      }
    }

    scanTitles(titoli);
    scanTitles(trattiRazziali);

    for (final art in arti) {
      if (isDefiledArt(art)) continue;
      if (art.openAttiva && !identical(art, exceptArt)) {
        if (art.sbloccata && artOpenSbloccata(art)) {
          rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
        }
        art.openAttiva = false;
      }
    }
  }

  void normalizzaOpenAttiveSingole() {
    var activeFound = false;

    void scanTitles(List<OculumTitle> list) {
      for (final titolo in list) {
        if (!titolo.evoluto || !titolo.equipaggiato) {
          titolo.openAttiva = false;
          for (final open in titolo.openExtra) {
            open.attiva = false;
          }
          continue;
        }

        if (titolo.openAttiva) {
          if (activeFound) {
            titolo.openAttiva = false;
          } else {
            activeFound = true;
          }
        }

        for (final open in titolo.openExtra) {
          if (!open.attiva) continue;
          if (activeFound) {
            open.attiva = false;
          } else {
            activeFound = true;
          }
        }
      }
    }

    scanTitles(titoli);
    scanTitles(trattiRazziali);

    for (final art in arti) {
      if (!art.sbloccata || !artOpenSbloccata(art)) {
        art.openAttiva = false;
        continue;
      }

      if (!art.openAttiva) continue;
      if (isDefiledArt(art)) continue;
      if (activeFound) {
        art.openAttiva = false;
      } else {
        activeFound = true;
      }
    }
  }

  Map<String, int> artQuickBonuses(CharacterArt art) {
    final bonuses = <String, int>{};
    if (!art.sbloccata) return bonuses;

    for (final text in activeArtQuickTexts(art)) {
      addTitleQuickCommands(bonuses, text);
    }

    return bonuses;
  }

  Iterable<String> activeArtQuickTexts(CharacterArt art) sync* {
    if (!art.sbloccata) return;

    for (final skill in art.skills) {
      if (artSkillBonusLevel(skill) <= 0) continue;
      yield artSkillActiveLevelText(skill);
    }

    if (isRuneArt(art)) {
      final runeCustomText = runeArtQuickCustomEffectText(art);
      if (runeCustomText.trim().isNotEmpty) yield runeCustomText;
    }

    if (art.openAttiva && artOpenSbloccata(art)) {
      yield art.openBuff;
    }
  }

  Map<String, int> detectedArtQuickCommands(CharacterArt art) {
    final detected = <String, int>{};
    if (!art.sbloccata) return detected;

    void add(String text) => addTitleQuickCommands(detected, text);

    for (final skill in art.skills) {
      add(skill.evo1);
      add(skill.evo2);
      add(skill.evo3);
      final maxLevel = artMaxLevel(art);
      if (maxLevel >= 4) add(skill.evo4);
      if (maxLevel >= 5) add(skill.evo5);
    }

    add(art.openBuff);

    return detected;
  }

  int artQuickBonus(String key) {
    int total = 0;
    for (final art in arti) {
      total += artQuickBonuses(art)[key] ?? 0;
    }
    return total;
  }

  Iterable<String> activeItemQuickTexts(InventoryItem item) sync* {
    if (!item.equipaggiata) return;
    yield item.buff;
  }

  Map<String, int> itemQuickBonuses(InventoryItem item) {
    final bonuses = <String, int>{};
    for (final text in activeItemQuickTexts(item)) {
      addTitleQuickCommands(bonuses, text);
    }
    return bonuses;
  }

  int itemQuickBonus(String key) {
    int total = 0;
    for (final item in inventario) {
      total += itemQuickBonuses(item)[key] ?? 0;
    }
    return total;
  }

  List<String> get titleCategoryOrder => const [
    'Titoli del Fato',
    'Titolo Azione',
    'Titolo Item',
    'Titolo Malanno',
    'Titolo Benessere',
    'Titoli Di Apprendimento',
    'Titolo Chaos',
    'Titoli Alchimia/Magia',
    'Titoli Attributo',
    'Altri Titoli',
  ];

  String normalizeTitleCategory(String rawType) {
    final type = rawType.toLowerCase().trim();

    if (type.contains('fato') || type.contains('fate')) {
      return 'Titoli del Fato';
    }
    if (type.contains('azione') || type.contains('action')) {
      return 'Titolo Azione';
    }
    if (type.contains('item') || type.contains('oggetto')) {
      return 'Titolo Item';
    }
    if (type.contains('malanno') || type.contains('illness')) {
      return 'Titolo Malanno';
    }
    if (type.contains('benessere') || type.contains('wellness')) {
      return 'Titolo Benessere';
    }
    if (type.contains('apprendimento') || type.contains('learning')) {
      return 'Titoli Di Apprendimento';
    }
    if (type.contains('chaos')) {
      return 'Titolo Chaos';
    }
    if (type.contains('alchimia') ||
        type.contains('magia') ||
        type.contains('alchemy') ||
        type.contains('magic')) {
      return 'Titoli Alchimia/Magia';
    }
    if (type.contains('attributo') || type.contains('attribute')) {
      return 'Titoli Attributo';
    }

    return 'Altri Titoli';
  }

  String titleCategorySlug(String category) {
    return category
        .toLowerCase()
        .replaceAll('/', '_')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String titleCategoryRules(String category) {
    switch (category) {
      case 'Titoli del Fato':
        return t(
          'Si ottengono alla prima forma della prima skill, alla seconda forma della seconda skill e alla terza forma della terza skill. Sono molto potenti, rarissimi anche in roleplay; con Chained Fate possono avere slot unici dedicati.',
          'Earned from the first form of the first skill, the second form of the second skill, and the third form of the third skill. They are very powerful, very rare in roleplay, and Chained Fate can reserve unique slots for them.',
        );
      case 'Titolo Azione':
        return t(
          'Titoli simili ai Titoli del Fato ma meno forti, legati ad azioni importanti, stile, imprese e ricorrenze di gioco.',
          'Titles similar to Fate Titles but weaker, tied to important actions, style, deeds and repeated play patterns.',
        );
      case 'Titolo Item':
        return t(
          'Titoli simili ai Titoli del Fato ma meno forti, legati a oggetti, reliquie, strumenti, armi o item narrativamente centrali.',
          'Titles similar to Fate Titles but weaker, tied to items, relics, tools, weapons or narratively central gear.',
        );
      case 'Titolo Malanno':
        return t(
          'Titoli obbligati da stati fisici, mentali o emotivi alterati. Non si rimuovono volontariamente; ogni 6 Resilienza si ottiene 1 slot Malanno. Se gli slot sono pieni possono sostituire temporaneamente un Titolo Evoluto. Non si masterano e possono evolvere in Titoli Oscuri o Maledetti.',
          'Forced titles from altered physical, mental or emotional states. They cannot be removed voluntarily; every 6 Resilience grants 1 Illness slot. If all slots are full, one Evolved Title may be temporarily displaced. They cannot be mastered and may evolve into Dark or Cursed Titles.',
        );
      case 'Titolo Benessere':
        return t(
          'Titoli aggiuntivi momentanei da benessere mentale, equilibrio fisico o crescita spirituale. Non occupano slot, durano finché resta lo stato positivo e scompaiono con malus gravi, crisi o traumi improvvisi.',
          'Temporary extra titles from mental wellness, physical balance or spiritual growth. They do not use slots, last while the positive state remains, and vanish after severe penalties, crises or sudden trauma.',
        );
      case 'Titoli Di Apprendimento':
        return t(
          'Derivano da addestramento, mastery o tiri critici. Con Rebirth, i primi 3 se Evoluti non occupano slot. Si usa uno slot per Grado.',
          'Come from training, mastery or critical rolls. With Rebirth, the first 3 do not use slots if Evolved. Uses one slot per Grade.',
        );
      case 'Titolo Chaos':
        return t(
          'Generati dall accettazione del Chaos. Arrivano già evoluti, danno buff molto potenti ma punti ciechi estremi. Possono avere slot separati tramite metodi rari e macabri; la Open e obbligatoria ma poi toglibile.',
          'Generated by accepting Chaos. They arrive already evolved, with very strong buffs and extreme blind spots. They can have separate slots through rare and grim methods; the Open is mandatory but can later be removed.',
        );
      case 'Titoli Alchimia/Magia':
        return t(
          'Legati a pratiche arcane, cerchi, elementi, Oculum e Materia. Rebirth concede uno slot gratuito; senza Rebirth si ottiene 1 slot per aumento di Grado. Non occupano slot standard e il massimo equipaggiabile e pari al Grado.',
          'Tied to arcane practice, circles, elements, Oculum and Materia. Rebirth grants one free slot; without Rebirth, gain 1 slot per Grade increase. They do not use standard slots and the equip cap equals Grade.',
        );
      case 'Titoli Attributo':
        return t(
          'Danno da +1 a +3 ai tiri, fino a +6 Evoluti, +7 Reforgiati, +9 Evoluti e Reforgiati, +1 per Grado e massimo +12. Se almeno 3 parole attive valgono sul tiro, il più aumenta del 25%. Le leggende possono contenere parole di Fato e parole di debolezza.',
          'Grant +1 to +3 on rolls, up to +6 Evolved, +7 Reforged, +9 Evolved and Reforged, +1 per Grade and a +12 cap. If at least 3 active words apply to a roll, the plus rises by 25%. Legends may include Fate words and weakness words.',
        );
      default:
        return t(
          'Titoli editabili liberi. Puoi rinominarli in una categoria regolata quando vuoi: tutti possono avere Open, e le Open restano modificabili.',
          'Free editable titles. You can rename them into a ruled category at any time: all can have Opens, and Opens remain editable.',
        );
    }
  }

  int oculumMassimo() => max(oculumMassimoNaturale(), oculumTotale());

  int statsMassimeTotali() {
    return resilienzaMassimo() +
        volontaMassimo() +
        materiaMassimo() +
        oculumMassimo();
  }

  int currentOculum() => readIntValue(currentOculumController.text);

  int follia() => max(0, leggiNumero(folliaController));

  int folliaPartyTotale() {
    final party = partyStatsCountIndexes();
    final source = party.isEmpty ? <int>[schedaCorrente] : party;
    if (source.isEmpty) return follia();
    var total = 0;
    for (final index in source) {
      if (index == schedaCorrente) {
        total += follia();
      } else if (index >= 0 && index < schedePersonaggio.length) {
        total += readIntValue(schedePersonaggio[index]['follia']);
      }
    }
    return max(0, total);
  }

  bool partyHaFolliaDaMostri() {
    final party = partyStatsCountIndexes();
    final source = party.isEmpty ? <int>[schedaCorrente] : party;
    for (final index in source) {
      if (index == schedaCorrente) {
        if (follia() > 0 && folliaDaMostri) return true;
      } else if (index >= 0 && index < schedePersonaggio.length) {
        final sheet = schedePersonaggio[index];
        if (readIntValue(sheet['follia']) > 0 &&
            readBoolValue(sheet['folliaDaMostri'])) {
          return true;
        }
      }
    }
    return false;
  }

  bool folliaGeneratoreSbloccato() {
    return folliaPartyTotale() > 0 || partyHaFolliaDaMostri();
  }

  int folliaDannoPassivo() {
    if (illnessArtSbloccata) return 0;
    return follia();
  }

  int folliaIncontroPercentuale() {
    final total = folliaPartyTotale();
    if (total <= 0) return 0;
    final difficultyBonus = switch (normalizedCampaignDifficulty()) {
      'oculum' => 18,
      'difficile' => 12,
      'facile' => 4,
      _ => 8,
    };
    final monsterBonus = partyHaFolliaDaMostri() ? 12 : 0;
    return (total * 7 + difficultyBonus + monsterBonus).clamp(5, 85).toInt();
  }

  int folliaDannoConvertibile({bool totale = false}) {
    final raw = totale
        ? folliaPartyTotale()
        : (folliaPartyTotale() * 0.5).ceil();
    final mitigation = max(0, difesa() ~/ 12);
    return max(0, raw - mitigation);
  }

  int oculumTiroLimiteRegola() {
    final level = max(0, leggiNumero(livelloController));
    final grade = max(0, leggiNumero(gradoController));
    final byLevel = level ~/ 3;
    final byGrade = grade <= 0
        ? (level >= 9 ? 3 : byLevel)
        : max(3, (grade ~/ 3) * 3);
    return max(0, min(byLevel, byGrade));
  }

  int oculumTiroSpendCap() {
    return min(oculumTiroLimiteRegola(), max(0, currentOculum()));
  }

  int oculumTiroPreparato() {
    final cap = oculumTiroSpendCap();
    final value = leggiNumero(oculumTiroController).clamp(0, cap).toInt();
    if (oculumTiroController.text != value.toString()) {
      oculumTiroController.text = value.toString();
    }
    return value;
  }

  void preparaOculumTiroDelta(int delta) {
    setState(() {
      final cap = oculumTiroSpendCap();
      final next = (oculumTiroPreparato() + delta).clamp(0, cap).toInt();
      oculumTiroController.text = next.toString();
      risultato = t(
        'Oculum per prossimo tiro fight: $next/$cap.',
        'Oculum for next fight roll: $next/$cap.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  ({int spent, int bonus}) consumaOculumTiro() {
    final spent = oculumTiroPreparato();
    if (spent <= 0) return (spent: 0, bonus: 0);

    currentOculumController.text = max(0, currentOculum() - spent).toString();
    oculumTiroController.text = '0';
    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
    return (spent: spent, bonus: spent * 3);
  }

  String oculumTiroLogLabel(({int spent, int bonus}) spend) {
    if (spend.spent <= 0) return '';
    return ' Oculum fight +${spend.bonus} (${spend.spent} pt).';
  }

  void modificaFollia(int delta, {bool daMostro = false}) {
    setState(() {
      final before = follia();
      final effectiveDelta = delta > 0 && illnessArtSbloccata
          ? delta * 2
          : delta;
      final next = max(0, before + effectiveDelta);
      final applied = next - before;
      folliaController.text = next.toString();
      if (daMostro && applied > 0) folliaDaMostri = true;

      var damageText = '';
      if (applied > 0 && !illnessArtSbloccata) {
        final hpBefore = hpCorrenti();
        currentHpController.text = max(0, hpBefore - applied).toString();
        damageText = ' HP -$applied.';
      }

      risultato = applied >= 0
          ? 'Follia +$applied ($next).$damageText'
          : 'Follia $applied ($next).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  double oculumRatio() {
    final massimo = oculumMassimo();
    if (massimo <= 0) return 0;
    return (oculumTotale() / massimo).clamp(0.0, 1.0);
  }

  void syncCurrentOculumToMax({bool resetToMax = false}) {
    final massimo = currentStatNaturalControllerMax('oculum');
    final current = resetToMax ? massimo : currentOculum();
    currentOculumController.text = current.toString();
  }

  void syncCurrentStatsToMax({
    bool resetResilienzaToMax = false,
    bool resetVolontaToMax = false,
    bool resetMateriaToMax = false,
    bool resetOculumToMax = false,
  }) {
    if (resetResilienzaToMax) {
      currentResilienzaController.text = currentStatNaturalControllerMax(
        'resilienza',
      ).toString();
    }

    if (resetVolontaToMax) {
      currentVolontaController.text = currentStatNaturalControllerMax(
        'volonta',
      ).toString();
    }

    if (resetMateriaToMax) {
      currentMateriaController.text = currentStatNaturalControllerMax(
        'materia',
      ).toString();
    }

    syncCurrentOculumToMax(resetToMax: resetOculumToMax);
  }

  void recuperaStatAttuale(TextEditingController controller, int massimo) {
    final current = max(0, readIntValue(controller.text));
    if (current >= massimo) {
      controller.text = current.toString();
      return;
    }

    final recupero = max(1, ((massimo - current) / 2).ceil());
    controller.text = min(massimo, current + recupero).toString();
  }

  void refullaStatsAttuali() {
    currentResilienzaController.text = currentStatNaturalControllerMax(
      'resilienza',
    ).toString();
    currentVolontaController.text = currentStatNaturalControllerMax(
      'volonta',
    ).toString();
    currentMateriaController.text = currentStatNaturalControllerMax(
      'materia',
    ).toString();
    currentOculumController.text = currentStatNaturalControllerMax(
      'oculum',
    ).toString();
  }

  void recuperaStatsAttualiConRiposoBreve() {
    final beforeRes = currentResilienza();
    recuperaStatAttuale(
      currentResilienzaController,
      currentStatNaturalControllerMax('resilienza'),
    );
    rimarginaHpDaAumentoResilienza(currentResilienza() - beforeRes);
    recuperaStatAttuale(
      currentVolontaController,
      currentStatNaturalControllerMax('volonta'),
    );
    recuperaStatAttuale(
      currentMateriaController,
      currentStatNaturalControllerMax('materia'),
    );
    recuperaStatAttuale(
      currentOculumController,
      currentStatNaturalControllerMax('oculum'),
    );
  }

  void applicaBonusAttuali({
    int resilienza = 0,
    int volonta = 0,
    int materia = 0,
    int oculum = 0,
    int segno = 1,
  }) {
    if (resilienza != 0) {
      final before = currentResilienza();
      final next = before + resilienza * segno;
      final appliedDelta = next - before;
      currentResilienzaController.text = next.toString();
      rimarginaHpDaAumentoResilienza(appliedDelta);
    }

    if (volonta != 0) {
      currentVolontaController.text = (currentVolonta() + volonta * segno)
          .toString();
    }

    if (materia != 0) {
      currentMateriaController.text = (currentMateria() + materia * segno)
          .toString();
    }

    if (oculum != 0) {
      currentOculumController.text = (currentOculum() + oculum * segno)
          .toString();
    }
  }

  void rimarginaHpDaAumentoResilienza(int delta) {
    if (delta == 0) return;

    final hpDelta = delta * moltiplicatoreHp();
    final nextHp = (leggiNumero(currentHpController) + hpDelta).clamp(
      0,
      maxHp(),
    );
    currentHpController.text = nextHp.toString();
  }

  TextEditingController baseStatController(String key) {
    switch (key) {
      case 'resilienza':
        return resilienzaController;
      case 'volonta':
        return volontaController;
      case 'materia':
        return materiaController;
      case 'oculum':
      default:
        return oculumController;
    }
  }

  int aumentaStatBaseEAttuale(String key, int delta) {
    if (delta == 0) return 0;

    final controller = baseStatController(key);
    final before = max(0, readIntValue(controller.text));
    final next = max(0, before + delta);
    final appliedDelta = next - before;
    controller.text = next.toString();

    switch (key) {
      case 'resilienza':
        applicaBonusAttuali(resilienza: appliedDelta);
        break;
      case 'volonta':
        applicaBonusAttuali(volonta: appliedDelta);
        break;
      case 'materia':
        applicaBonusAttuali(materia: appliedDelta);
        break;
      case 'oculum':
        applicaBonusAttuali(oculum: appliedDelta);
        if (appliedDelta != 0) scheduleRealtimeOculumChanged();
        break;
    }

    syncVisibleCurrentStatEditor(key);

    return appliedDelta;
  }

  void applicaBonusSkillAttuali(CharacterSkill skill, int segno) {
    applicaBonusAttuali(
      resilienza: skill.resilienza,
      volonta: skill.volonta,
      materia: skill.materia,
      oculum: skill.oculum,
      segno: segno,
    );
  }

  void applicaBonusTitoloAttuali(OculumTitle titolo, int segno) {
    applicaBonusAttuali(
      resilienza: titolo.resilienza,
      volonta: titolo.volonta,
      materia: titolo.materia,
      oculum: titolo.oculum,
      segno: segno,
    );
  }

  void applicaBonusArtSkillAttuali(ArtSkill skill, int segno) {
    applicaBonusAttuali(
      resilienza: skill.resilienza * segno,
      volonta: skill.volonta * segno,
      materia: skill.materia * segno,
      oculum: skill.oculum * segno,
    );
  }

  TextEditingController currentStatController(String key) {
    switch (key) {
      case 'resilienza':
        return currentResilienzaController;
      case 'volonta':
        return currentVolontaController;
      case 'materia':
        return currentMateriaController;
      case 'oculum':
      default:
        return currentOculumController;
    }
  }

  TextEditingController visibleCurrentStatController(String key) {
    switch (key) {
      case 'resilienza':
        return visibleCurrentResilienzaController;
      case 'volonta':
        return visibleCurrentVolontaController;
      case 'materia':
        return visibleCurrentMateriaController;
      case 'oculum':
      default:
        return visibleCurrentOculumController;
    }
  }

  String currentStatKeyForVisibleController(TextEditingController controller) {
    if (identical(controller, visibleCurrentResilienzaController)) {
      return 'resilienza';
    }
    if (identical(controller, visibleCurrentVolontaController)) {
      return 'volonta';
    }
    if (identical(controller, visibleCurrentMateriaController)) {
      return 'materia';
    }
    if (identical(controller, visibleCurrentOculumController)) return 'oculum';
    return '';
  }

  bool isVisibleCurrentStatController(TextEditingController controller) {
    return currentStatKeyForVisibleController(controller).isNotEmpty;
  }

  void syncVisibleCurrentStatEditor(String key) {
    final controller = visibleCurrentStatController(key);
    final text = currentStatValue(key).toString();
    if (controller.text == text) return;
    controller.text = text;
  }

  void syncVisibleCurrentStatEditors() {
    syncVisibleCurrentStatEditor('resilienza');
    syncVisibleCurrentStatEditor('volonta');
    syncVisibleCurrentStatEditor('materia');
    syncVisibleCurrentStatEditor('oculum');
  }

  void adjustRecordedStatSpentFromDelta(String key, int appliedDelta) {
    if (appliedDelta == 0) return;

    final deltaSpent = -appliedDelta;
    switch (key) {
      case 'resilienza':
        raccoltaResilienzaSpesa = max(0, raccoltaResilienzaSpesa + deltaSpent);
        break;
      case 'volonta':
        raccoltaVolontaSpesa = max(0, raccoltaVolontaSpesa + deltaSpent);
        break;
      case 'materia':
        raccoltaMateriaSpesa = max(0, raccoltaMateriaSpesa + deltaSpent);
        break;
      case 'oculum':
        raccoltaOculumSpesa = max(0, raccoltaOculumSpesa + deltaSpent);
        break;
    }
  }

  void setCurrentStatFromVisibleInput(
    String key,
    String value, {
    bool trackConsumption = true,
  }) {
    final before = currentStatValue(key);
    final visible = max(0, readIntValue(value));
    final runtimeBonus = runtimeCurrentStatBonus(key);
    currentStatController(key).text = (visible - runtimeBonus).toString();
    if (trackConsumption) {
      adjustRecordedStatSpentFromDelta(key, visible - before);
    }

    if (key == 'oculum') {
      scheduleRealtimeOculumChanged();
    }
  }

  int currentStatValue(String key) {
    switch (key) {
      case 'resilienza':
        return resilienzaTotale();
      case 'volonta':
        return volontaTotale();
      case 'materia':
        return materiaTotale();
      case 'oculum':
      default:
        return oculumTotale();
    }
  }

  int statMassimoNaturale(String key) {
    switch (key) {
      case 'resilienza':
        return resilienzaMassimoNaturale();
      case 'volonta':
        return volontaMassimoNaturale();
      case 'materia':
        return materiaMassimoNaturale();
      case 'oculum':
      default:
        return oculumMassimoNaturale();
    }
  }

  int currentStatNaturalControllerMax(String key) {
    final visibleMax = statMassimoNaturale(key);
    final runtimeBonus = runtimeCurrentStatBonus(key);
    return max(0, visibleMax - runtimeBonus);
  }

  int statMassimo(String key) {
    switch (key) {
      case 'resilienza':
        return resilienzaMassimo();
      case 'volonta':
        return volontaMassimo();
      case 'materia':
        return materiaMassimo();
      case 'oculum':
      default:
        return oculumMassimo();
    }
  }

  String statLabel(String key) {
    switch (key) {
      case 'resilienza':
        return t('Resilienza', 'Resilience');
      case 'volonta':
        return t('Volontà', 'Will');
      case 'materia':
        return 'Materia';
      case 'oculum':
      default:
        return 'Oculum';
    }
  }

  void modificaStatAttuale(String key, int delta, {bool silent = false}) {
    final controller = currentStatController(key);

    setState(() {
      final before = currentStatValue(key);
      final next = max(0, before + delta);
      final appliedDelta = next - before;
      final runtimeBonus = runtimeCurrentStatBonus(key);
      controller.text = (next - runtimeBonus).toString();
      adjustRecordedStatSpentFromDelta(key, appliedDelta);
      if (key == 'resilienza') {
        rimarginaHpDaAumentoResilienza(appliedDelta);
      }
      final massimo = statMassimo(key);
      String? cenereMessage;
      if (appliedDelta < 0 && massimo > 0 && next <= (massimo / 2).floor()) {
        cenereMessage = modificaCenereControllata(1);
      }

      if (!silent) {
        final label = statLabel(key);
        final total = currentStatValue(key);
        risultato = appliedDelta >= 0
            ? '$label attuale: +$appliedDelta ($total/$massimo).'
            : '$label attuale: $appliedDelta ($total/$massimo).';
        if (appliedDelta < 0 && cenereMessage != null) {
          risultato += '\n$cenereMessage';
        } else if (appliedDelta < 0 &&
            massimo > 0 &&
            next <= (massimo / 2).floor()) {
          risultato += '\nCenere/Fatica +1: risorsa usata sotto il 50%.';
        }
        aggiungiLog(risultato);
      }
    });

    programmaSalvataggio();
    if (key == 'oculum') {
      scheduleRealtimeOculumChanged();
    }
  }

  void resetStatAttuale(String key) {
    setState(() {
      final controller = currentStatController(key);
      final massimo = currentStatNaturalControllerMax(key);
      final before = currentStatValue(key);
      controller.text = massimo.toString();
      adjustRecordedStatSpentFromDelta(key, statMassimoNaturale(key) - before);
      risultato = '${statLabel(key)} attuale riportata al massimo.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    if (key == 'oculum') {
      scheduleRealtimeOculumChanged();
    }
  }

  void modificaOculumAttuale(int delta) {
    modificaStatAttuale('oculum', delta);
  }

  void resetOculumAttuale() {
    resetStatAttuale('oculum');
  }

  int bonusLivelloGrado() {
    final livello = max(0, leggiNumero(livelloController));
    final grado = max(0, leggiNumero(gradoController));
    return livello + grado * 6 + rebirthLevelBonus();
  }

  List<MapEntry<String, int>> vantaggioTiroOptions() {
    return const [
      MapEntry('Svantaggio Oculum', -12),
      MapEntry('Ultra Svantaggio', -9),
      MapEntry('Super Svantaggio', -6),
      MapEntry('Vero Svantaggio', -5),
      MapEntry('Svantaggio', -3),
      MapEntry('Svantaggio minore', -1),
      MapEntry('Normale', 0),
      MapEntry('Vantaggio minore', 1),
      MapEntry('Vantaggio', 3),
      MapEntry('Vero Vantaggio', 5),
      MapEntry('Super Vantaggio', 6),
      MapEntry('Ultra Vantaggio', 9),
      MapEntry('Vantaggio Oculum', 12),
    ];
  }

  String canonicalVantaggioTiroName(String raw) {
    final value = cleanUiText(raw).trim().toLowerCase();
    for (final option in vantaggioTiroOptions()) {
      if (option.key.toLowerCase() == value) return option.key;
    }
    return 'Normale';
  }

  int vantaggioTiroBonus() {
    final name = canonicalVantaggioTiroName(vantaggioTiroSelezionato);
    return vantaggioTiroOptions()
        .firstWhere((option) => option.key == name)
        .value;
  }

  int sogliaFaticaSenzaMalus() {
    return 3 + max(0, leggiNumero(gradoController));
  }

  int malusFaticaTiri() {
    if (statoForzaRimuoveMalus()) return 0;
    return -max(0, leggiNumero(cenereController));
  }

  int tiroGlobaleBonus() {
    return vantaggioTiroBonus() + malusFaticaTiri();
  }

  /// A positive DT makes every roll harder; a negative value makes it easier.
  /// It is kept separate from advantages so criticals always remain natural.
  int difficoltaTiro() {
    return int.tryParse(difficoltaTiroController.text.trim()) ?? 0;
  }

  int modificatoreDifficoltaTiro({int? difficulty}) {
    return -(difficulty ?? difficoltaTiro());
  }

  int moltiplicatoreHp() {
    final grado = max(0, leggiNumero(gradoController));
    return 10 + grado * 5;
  }

  int globalQuickBonus(String key) {
    return parseTitleQuickCommands(buffMalusRapidiController.text)[key] ?? 0;
  }

  int runtimeQuickBonus(String key) {
    return titleQuickBonus(key) +
        artQuickBonus(key) +
        itemQuickBonus(key) +
        skillTextQuickBonus(key) +
        globalQuickBonus(key) +
        statoForzaQuickBonus(key);
  }

  String statRollQuickBonusKey(String rawStat) {
    switch (oculumStatKey(rawStat)) {
      case 'resilienza':
      case 'resilienza_current':
        return 'tiro_resilienza';
      case 'volonta':
      case 'volonta_current':
        return 'tiro_volonta';
      case 'materia':
      case 'materia_current':
        return 'tiro_materia';
      case 'oculum':
      case 'oculum_current':
        return 'tiro_oculum';
      default:
        return '';
    }
  }

  int statRollQuickBonus(String rawStat) {
    final key = statRollQuickBonusKey(rawStat);
    return (key.isEmpty ? 0 : runtimeQuickBonus(key)) + tiroGlobaleBonus();
  }

  int reazioniBonusGrado() {
    return max(0, leggiNumero(gradoController)) ~/ 6;
  }

  int reazioniTotali() {
    return max(
      0,
      max(0, leggiNumero(reazioniController)) +
          reazioniBonusGrado() +
          runtimeQuickBonus('reazione'),
    );
  }

  int reazioniVelociTotali() {
    return max(
      0,
      max(0, leggiNumero(reazioniVelociController)) +
          runtimeQuickBonus('reazione_veloce'),
    );
  }

  int schivataOculumBase() {
    return max(0, leggiNumero(gradoController)) ~/ 3;
  }

  int schivateOculumTotali() {
    return max(0, schivataOculumBase() + runtimeQuickBonus('schivata_oculum'));
  }

  int schivateOculumDisponibili() {
    return max(0, schivateOculumTotali() - schivateOculumConsumate);
  }

  int maxHp() {
    return max(
      1,
      max(1, resilienzaTotale()) * moltiplicatoreHp() + runtimeQuickBonus('hp'),
    );
  }

  int hpCorrenti() {
    final hp = leggiNumero(currentHpController);
    final massimo = maxHp();

    if (hp < 0) return 0;
    if (hp > massimo) return massimo;

    return hp;
  }

  int hpTemp() {
    final bonus = runtimeQuickBonus('hp_temp');
    final spent = hpTempBonusConsumati.clamp(0, max(0, bonus)).toInt();
    return max(0, leggiNumero(hpTempController) + bonus - spent);
  }

  void impostaHpTempTotali(int value) {
    final target = max(0, value);
    final manual = max(0, leggiNumero(hpTempController));
    final bonus = runtimeQuickBonus('hp_temp');
    final positiveBonus = max(0, bonus);

    if (target >= manual) {
      hpTempBonusConsumati = (manual + positiveBonus - target)
          .clamp(0, positiveBonus)
          .toInt();
      return;
    }

    hpTempController.text = target.toString();
    hpTempBonusConsumati = positiveBonus;
  }

  int scudoAutomaticoTipoScheda() {
    final tipo = cleanUiText(tipoSchedaController.text).trim().toLowerCase();
    if (!tipo.contains('mostro')) return 0;
    final livello = max(1, leggiNumero(livelloController));
    final grado = max(0, leggiNumero(gradoController));
    final factor = tipo.contains('boss')
        ? 9
        : tipo.contains('mini')
        ? 6
        : 3;
    return livello * factor + grado * 6;
  }

  List<HiddenEyeStat> defaultHiddenEyeStats() {
    return [
      HiddenEyeStat(
        id: 'velo',
        nome: 'Velo',
        descrizione:
            'Furtivita, rapidita di mano, nascondersi, borseggio. Bonus base: Materia/2.',
      ),
      HiddenEyeStat(
        id: 'furbizia',
        nome: 'Furbizia',
        descrizione: 'Lama del Pensiero. Bonus: Resilienza/2.',
      ),
      HiddenEyeStat(
        id: 'inganno',
        nome: 'Inganno',
        descrizione: 'Lama del Pensiero. Bonus: Materia/2.',
      ),
      HiddenEyeStat(
        id: 'strategia',
        nome: 'Strategia',
        descrizione:
            'Lama del Pensiero. Bonus: Resilienza/2. Se il nemico perde contro la tua strategia riceve Fragilita.',
      ),
      HiddenEyeStat(
        id: 'eco',
        nome: 'Eco',
        descrizione:
            'Carisma, leadership, intimidazione. Bonus base: Volonta/2.',
      ),
      HiddenEyeStat(
        id: 'nodo',
        nome: 'Nodo',
        descrizione: 'Legami, diplomazia, alleanze. Bonus/malus: Karma totale.',
      ),
      HiddenEyeStat(
        id: 'crepa',
        nome: 'Crepa',
        descrizione: 'Trauma, follia, corruzione. Bonus: Volonta/2.',
      ),
      HiddenEyeStat(
        id: 'pressione',
        nome: 'Pressione',
        descrizione:
            'Istinto. Bonus: Volonta/2. Puo imporre Fragilita o togliere azione con critico negativo.',
      ),
      HiddenEyeStat(
        id: 'riflessi',
        nome: 'Riflessi',
        descrizione: 'Istinto. Bonus: Materia/2.',
      ),
      HiddenEyeStat(
        id: 'percezione',
        nome: 'Percezione',
        descrizione: 'Istinto. Bonus: Oculum/2.',
      ),
      HiddenEyeStat(
        id: 'sopravvivenza',
        nome: 'Sopravvivenza',
        descrizione: 'Istinto. Bonus: Resilienza/2.',
      ),
      HiddenEyeStat(
        id: 'crafting',
        nome: 'Crafting',
        descrizione: 'Mano. Bonus: Materia/2.',
      ),
      HiddenEyeStat(
        id: 'medicina',
        nome: 'Medicina',
        descrizione: 'Mano. Bonus: Resilienza/2.',
      ),
      HiddenEyeStat(
        id: 'riparazioni',
        nome: 'Riparazioni',
        descrizione: 'Mano. Bonus: Materia/2.',
      ),
      HiddenEyeStat(
        id: 'manifestazione_potere',
        nome: 'Manifestazione del Potere',
        descrizione: 'Sussurro. Bonus: maggiore tra Materia e Oculum / 2.',
      ),
      HiddenEyeStat(
        id: 'sussurro',
        nome: 'Sussurro',
        descrizione: 'Segreti, linguaggi, simboli. Bonus: Oculum/2.',
      ),
    ];
  }

  List<ReputationEntry> defaultReputations() {
    final karma = karmaTotale();
    return [
      ReputationEntry(
        cityName: 'Vaitern',
        value: (75 + karma).clamp(-100, 100).toInt(),
        baseValue: 75,
        lastKarmaApplied: karma,
      ),
      ReputationEntry(
        cityName: 'Virelion',
        value: (-25 + karma).clamp(-100, 100).toInt(),
        baseValue: -25,
        lastKarmaApplied: karma,
      ),
      ReputationEntry(
        cityName: 'Monster Forest',
        value: (10 + karma).clamp(-100, 100).toInt(),
        baseValue: 10,
        lastKarmaApplied: karma,
      ),
    ];
  }

  void ensureHiddenEyeDefaults() {
    final byId = {for (final stat in hiddenEyeStats) stat.id: stat};
    hiddenEyeStats
      ..clear()
      ..addAll(
        defaultHiddenEyeStats().map((base) {
          final existing = byId[base.id];
          if (existing == null) return base;
          existing.nome = existing.nome.trim().isEmpty
              ? base.nome
              : existing.nome;
          existing.descrizione = existing.descrizione.trim().isEmpty
              ? base.descrizione
              : existing.descrizione;
          existing.unlocked = true;
          return existing;
        }),
      );
  }

  bool hiddenEyeDefaultsReady() {
    final defaults = defaultHiddenEyeStats();
    if (hiddenEyeStats.length != defaults.length) return false;

    final byId = {for (final stat in hiddenEyeStats) stat.id: stat};
    for (final base in defaults) {
      final existing = byId[base.id];
      if (existing == null) return false;
      if (existing.nome.trim().isEmpty ||
          existing.descrizione.trim().isEmpty ||
          !existing.unlocked) {
        return false;
      }
    }

    return true;
  }

  String hiddenEyeStatGroup(String id) {
    switch (id) {
      case 'furbizia':
      case 'strategia':
      case 'sopravvivenza':
      case 'medicina':
        return 'resilienza';
      case 'eco':
      case 'crepa':
      case 'pressione':
        return 'volonta';
      case 'velo':
      case 'inganno':
      case 'riflessi':
      case 'crafting':
      case 'riparazioni':
        return 'materia';
      case 'nodo':
      case 'percezione':
      case 'sussurro':
        return 'oculum';
      case 'manifestazione_potere':
        return materiaTotale() >= oculumTotale() ? 'materia' : 'oculum';
      default:
        return 'materia';
    }
  }

  String hiddenEyeGroupLabel(String group) {
    switch (group) {
      case 'resilienza':
        return 'Resilienza';
      case 'volonta':
        return t('Volonta', 'Will');
      case 'materia':
        return 'Materia';
      case 'oculum':
        return 'Oculum';
      case 'karma':
        return 'Karma';
      default:
        return group;
    }
  }

  void ensureReputationDefaults() {
    if (reputationsManuallyCleared) return;
    if (reputations.isEmpty) {
      reputations.addAll(defaultReputations());
      return;
    }
    syncReputationsWithKarma();
  }

  void syncReputationsWithKarma() {
    final karma = karmaTotale();
    for (final entry in reputations) {
      if (entry.userModified) continue;
      if (entry.baseValue == 0 && entry.lastKarmaApplied != 0) {
        entry.baseValue = entry.value - entry.lastKarmaApplied;
      }
      entry.value = (entry.baseValue + karma).clamp(-100, 100).toInt();
      entry.lastKarmaApplied = karma;
    }
  }

  int hiddenEyeDerivedBonus(String id) {
    switch (id) {
      case 'velo':
      case 'inganno':
      case 'riflessi':
      case 'crafting':
      case 'riparazioni':
        return materiaTotale() ~/ 2;
      case 'furbizia':
      case 'strategia':
      case 'sopravvivenza':
      case 'medicina':
        return resilienzaTotale() ~/ 2;
      case 'eco':
      case 'crepa':
      case 'pressione':
        return volontaTotale() ~/ 2;
      case 'nodo':
        return leggiNumero(karmaController);
      case 'percezione':
      case 'sussurro':
        return oculumTotale() ~/ 2;
      case 'manifestazione_potere':
        return max(materiaTotale(), oculumTotale()) ~/ 2;
      default:
        return 0;
    }
  }

  int hiddenEyeTotal(HiddenEyeStat stat) {
    return stat.valore + hiddenEyeDerivedBonus(stat.id);
  }

  String karmaStateLabel() {
    final value = leggiNumero(karmaController);
    if (value >= 50) return t('Benedetto', 'Blessed');
    if (value >= 10) return t('Positivo', 'Positive');
    if (value > -10) return t('Neutrale', 'Neutral');
    if (value > -25) return t('Macchiato', 'Stained');
    if (value > -50) return t('Corrotto', 'Corrupted');
    if (value > -75) return t('Maledetto', 'Cursed');
    return t('Sfiorato dal Vuoto', 'Void Touched');
  }

  String reputationLabel(int value) {
    if (value >= 100) return t('Idolatrato', 'Idolized');
    if (value >= 75) return t('Amato', 'Loved');
    if (value >= 50) return t('Apprezzato', 'Appreciated');
    if (value >= 25) return t('Conosciuto', 'Known');
    if (value > -25) return t('Neutrale', 'Neutral');
    if (value > -50) return t('Sospetto', 'Suspicious');
    if (value > -75) return t('Malvisto', 'Disliked');
    if (value > -100) return t('Ricercato', 'Wanted');
    return t('Nemico Giurato', 'Sworn Enemy');
  }

  int scudo() {
    final bonus = runtimeQuickBonus('scudo') + scudoAutomaticoTipoScheda();
    final spent = scudoBonusConsumati.clamp(0, max(0, bonus)).toInt();
    return max(0, leggiNumero(scudoController) + bonus - spent);
  }

  int scudoRefullTarget() {
    return max(
      0,
      bonusScudoEquipaggiamento() +
          scudoAutomaticoTipoScheda() +
          max(0, runtimeQuickBonus('scudo')),
    );
  }

  void impostaScudoTotale(int value) {
    final target = max(0, value);
    final manual = max(0, leggiNumero(scudoController));
    final bonus = max(
      0,
      runtimeQuickBonus('scudo') + scudoAutomaticoTipoScheda(),
    );

    if (target >= manual) {
      scudoBonusConsumati = (manual + bonus - target).clamp(0, bonus).toInt();
      return;
    }

    scudoController.text = target.toString();
    scudoBonusConsumati = bonus;
  }

  int scudoCritico() {
    return max(0, leggiNumero(scudoCriticoController));
  }

  int scudoOculumBonusMassimo() {
    return runtimeQuickBonus('scudo_oculum');
  }

  int scudoOculumMassimoManuale() {
    return max(0, leggiNumero(scudoOculumMaxController));
  }

  int scudoOculumMax() {
    return max(0, scudoOculumMassimoManuale() + scudoOculumBonusMassimo());
  }

  int scudoOculum() {
    final massimo = scudoOculumMax();
    if (massimo <= 0) return 0;
    return max(0, leggiNumero(scudoOculumController)).clamp(0, massimo).toInt();
  }

  bool hasScudoOculum() {
    return scudoOculumMax() > 0 ||
        max(0, leggiNumero(scudoOculumController)) > 0;
  }

  bool shouldShowScudoOculum() {
    return mostraSempreScudoOculum || hasScudoOculum();
  }

  void ricaricaScudoOculum() {
    final massimo = scudoOculumMax();
    if (massimo > 0) {
      scudoOculumController.text = massimo.toString();
    }
  }

  void modificaScudoOculum(int delta) {
    if (delta == 0) return;
    final current = scudoOculum();
    final next = max(0, current + delta);
    final massimo = scudoOculumMax();
    if (next > massimo) {
      final bonus = scudoOculumBonusMassimo();
      scudoOculumMaxController.text = max(0, next - bonus).toString();
    }
    scudoOculumController.text = next.toString();
  }

  int bonusAttaccoRapido() {
    return leggiNumero(attaccoRapidoController);
  }

  int bonusDifesaRapido() {
    return leggiNumero(difesaRapidaController);
  }

  int bonusCmRapido() {
    return leggiNumero(cmRapidoController);
  }

  int vitaTotaleVisuale() {
    return maxHp() + hpTemp() + scudo() + scudoOculum() + scudoCritico();
  }

  double hpRatio() {
    final totale = vitaTotaleVisuale();
    if (totale <= 0) return 0;
    return hpCorrenti() / totale;
  }

  double tempRatio() {
    final totale = vitaTotaleVisuale();
    if (totale <= 0) return 0;
    return hpTemp() / totale;
  }

  double shieldRatio() {
    final totale = vitaTotaleVisuale();
    if (totale <= 0) return 0;
    return scudo() / totale;
  }

  double oculumShieldRatio() {
    final totale = vitaTotaleVisuale();
    if (totale <= 0) return 0;
    return scudoOculum() / totale;
  }

  double criticalShieldRatio() {
    final totale = vitaTotaleVisuale();
    if (totale <= 0) return 0;
    return scudoCritico() / totale;
  }

  int difesa() {
    return ((volontaTotale() + materiaTotale()) ~/ 2) +
        bonusLivelloGrado() +
        bonusDifesaRapido() +
        bonusDifesaEquipaggiamento() +
        titleQuickBonus('difesa') +
        artQuickBonus('difesa') +
        itemQuickBonus('difesa') +
        globalQuickBonus('difesa') +
        skillFormaBonus('difesa');
  }

  String formulaDifesaDettagliata() {
    final volonta = volontaTotale();
    final materia = materiaTotale();
    final livelloGrado = bonusLivelloGrado();
    final baseStats = (volonta + materia) ~/ 2;
    final base = baseStats + livelloGrado;
    final bonusTitoli = titleQuickBonus('difesa');
    final bonusArt = artQuickBonus('difesa');
    final bonusItem = itemQuickBonus('difesa');
    final bonusGlobal = globalQuickBonus('difesa');
    final bonusSkill = skillFormaBonus('difesa');
    final bonusEquip = bonusDifesaEquipaggiamento();
    final bonusRapido = bonusDifesaRapido();
    final details = quickCommandRuntimeDetails('difesa');
    final detailText = details.isEmpty ? '' : ' | ${details.join('; ')}';
    return '(VOL $volonta + MAT $materia) / 2 = $baseStats + Lv/Gr $livelloGrado = $base + Rapido $bonusRapido + Equip $bonusEquip + Titoli $bonusTitoli + Art/Open $bonusArt + Oggetti @ $bonusItem + Buff/Malus @ $bonusGlobal + Skill/Forme $bonusSkill = ${difesa()}$detailText';
  }

  List<InventoryItem> armiEquipaggiate() {
    final armi = inventario
        .where(
          (item) =>
              item.arma && item.equipaggiata && canEquipInventoryItem(item),
        )
        .toList();
    armi.sort((a, b) => itemAttackBonus(b).compareTo(itemAttackBonus(a)));
    return armi;
  }

  int bonusDannoArmi() {
    final armi = armiEquipaggiate();
    if (armi.isEmpty) return 0;
    return itemAttackBonus(armi.first);
  }

  InventoryItem? armaPiuForteEquipaggiata() {
    final armi = armiEquipaggiate();
    return armi.isEmpty ? null : armi.first;
  }

  List<InventoryItem> protezioniEquipaggiate() {
    return inventario
        .where(
          (item) =>
              item.protegge && item.equipaggiata && canEquipInventoryItem(item),
        )
        .toList();
  }

  int bonusDifesaEquipaggiamento() {
    return protezioniEquipaggiate().fold(
      0,
      (somma, item) => somma + itemDefenseBonus(item),
    );
  }

  int bonusScudoEquipaggiamento() {
    return protezioniEquipaggiate().fold(
      0,
      (somma, item) => somma + itemShieldBonus(item),
    );
  }

  void applicaScudoItemAttuale(InventoryItem item, int segno) {
    final bonus = itemShieldBonus(item);
    if (!item.protegge || bonus == 0 || !canEquipInventoryItem(item)) return;
    scudoController.text = max(
      0,
      leggiNumero(scudoController) + bonus * segno,
    ).toString();
  }

  int itemGrade(InventoryItem item) => item.gradoOggetto.clamp(0, 12).toInt();

  int requiredItemGrade(InventoryItem item) =>
      item.gradoRichiesto.clamp(0, 12).toInt();

  int itemAttackBonus(InventoryItem item) =>
      item.bonusDanno + itemGrade(item) * 5;

  int itemDefenseBonus(InventoryItem item) =>
      item.bonusDifesa + itemGrade(item) * 2;

  int itemShieldBonus(InventoryItem item) =>
      item.bonusScudo + itemGrade(item) * 5;

  bool canEquipInventoryItem(InventoryItem item) {
    final requiredGrade = requiredItemGrade(item);
    if (requiredGrade <= 0) return true;
    return max(0, leggiNumero(gradoController)) >= requiredGrade;
  }

  String nomeArmaPiuForteEquipaggiata() {
    final arma = armaPiuForteEquipaggiata();
    if (arma == null) {
      return t('Nessuna arma equipaggiata', 'No equipped weapon');
    }
    return arma.nome;
  }

  int dannoTotaleBaseSenzaComandi() {
    return volontaTotale() + bonusDannoArmi() + bonusLivelloGrado();
  }

  int dannoTotale() {
    return dannoTotaleBaseSenzaComandi() +
        titleQuickBonus('danni') +
        artQuickBonus('danni') +
        itemQuickBonus('danni') +
        globalQuickBonus('danni') +
        skillFormaBonus('danni');
  }

  String formulaDannoDettagliata() {
    final base = dannoTotaleBaseSenzaComandi();
    final bonusTitoli = titleQuickBonus('danni');
    final bonusArt = artQuickBonus('danni');
    final bonusItem = itemQuickBonus('danni');
    final bonusGlobal = globalQuickBonus('danni');
    final bonusSkill = skillFormaBonus('danni');
    final details = quickCommandRuntimeDetails('danni');
    final detailText = details.isEmpty ? '' : ' | ${details.join('; ')}';
    return 'VOL ${volontaTotale()} + Arma ${bonusDannoArmi()} + Lv/Gr ${bonusLivelloGrado()} = $base + Titoli $bonusTitoli + Art/Open $bonusArt + Oggetti @ $bonusItem + Buff/Malus @ $bonusGlobal + Skill/Forme $bonusSkill = ${dannoTotale()}$detailText';
  }

  String activeTypeSwitchElement() {
    final text = buffMalusRapidiController.text;
    if (text.trim().isEmpty) return '';

    final match = RegExp(
      r'@(?:type\s*switch|typeswitch|tipo\s*switch|cambio\s*tipo)\s*[:=]?\s*([^@,;\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return '';

    final raw = cleanUiText(match.group(1) ?? '').trim();
    if (raw.isEmpty) return '';
    final id = oculumNormalizeElementId(raw);
    return allDamageElementIds().contains(id) ? id : '';
  }

  Map<String, int> danniPerElemento({bool applyTypeSwitch = true}) {
    final result = <String, int>{};

    void add(String element, int value) {
      if (value <= 0) return;
      final id = oculumNormalizeElementId(element.isEmpty ? 'Fisico' : element);
      result.update(id, (current) => current + value, ifAbsent: () => value);
    }

    add(
      armaPiuForteEquipaggiata()?.elementoDanno ?? 'Fisico',
      volontaTotale() + bonusDannoArmi() + bonusLivelloGrado(),
    );

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;
      for (final text in activeTitleQuickTexts(titolo)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'danni') {
            final value = triggeredFormulaCommandValue(command);
            add(
              command.elementId.isEmpty ? 'Fisico' : command.elementId,
              value,
            );
          }
        }
      }
    }

    for (final art in arti) {
      for (final text in activeArtQuickTexts(art)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'danni') {
            final value = triggeredFormulaCommandValue(command);
            add(command.elementId.isEmpty ? 'Magia' : command.elementId, value);
          }
        }
      }
    }

    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      for (final text in activeItemQuickTexts(item)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'danni') {
            final value = triggeredFormulaCommandValue(command);
            add(
              command.elementId.isEmpty
                  ? item.elementoDanno
                  : command.elementId,
              value,
            );
          }
        }
      }
    }

    for (final command in parseQuickCommandsDetailed(
      buffMalusRapidiController.text,
    )) {
      if (command.valid && command.key == 'danni') {
        final value = triggeredFormulaCommandValue(command);
        add(command.elementId.isEmpty ? 'Fisico' : command.elementId, value);
      }
    }

    final skillDamage = directSkillNumericBonus('danni');
    if (skillDamage > 0) add('Magia', skillDamage);
    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      for (final text in skillQuickCommandTexts(skill)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'danni') {
            final value = triggeredFormulaCommandValue(command);
            add(command.elementId.isEmpty ? 'Magia' : command.elementId, value);
          }
        }
      }
    }

    oculumReconcileElementTotals(
      result,
      expectedTotal: dannoTotale(),
      fallbackElement: armaPiuForteEquipaggiata()?.elementoDanno ?? 'Fisico',
    );

    final switchedElement = applyTypeSwitch ? activeTypeSwitchElement() : '';
    if (switchedElement.isNotEmpty && result.isNotEmpty) {
      return <String, int>{switchedElement: dannoTotale()};
    }
    return result;
  }

  String elementoDannoDominante() {
    final parts = danniPerElemento();
    if (parts.isEmpty) return 'sconosciuto';
    var best = parts.entries.first;
    for (final entry in parts.entries.skip(1)) {
      if (entry.value > best.value) best = entry;
    }
    return best.key;
  }

  String elementiDannoTesto() {
    final keys = danniPerElemento().keys.toList();
    if (keys.isEmpty) return elementDisplayName('sconosciuto');
    if (keys.length > 3) {
      return '${keys.take(3).map(elementDisplayName).toSet().join(' • ')} • +${keys.length - 3}';
    }
    return keys.map(elementDisplayName).toSet().join(' • ');
  }

  Map<String, int> difesaPerElemento() {
    final result = <String, int>{};

    void add(String element, int value) {
      if (value <= 0) return;
      final id = oculumNormalizeElementId(element.isEmpty ? 'Fisico' : element);
      result.update(id, (current) => current + value, ifAbsent: () => value);
    }

    final base =
        ((materiaTotale() + volontaTotale() + bonusLivelloGrado()) ~/ 2) +
        bonusDifesaRapido();
    add('Fisico', base);
    for (final item in protezioniEquipaggiate()) {
      add(
        item.elementoDanno.isEmpty ? 'Fisico' : item.elementoDanno,
        item.bonusDifesa,
      );
    }

    for (final titolo in titoliCalcolabili) {
      if (!titolo.equipaggiato) continue;
      for (final text in activeTitleQuickTexts(titolo)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'difesa') {
            final value = triggeredFormulaCommandValue(command);
            add(
              command.elementId.isEmpty ? 'Fisico' : command.elementId,
              value,
            );
          }
        }
      }
    }

    for (final art in arti) {
      for (final text in activeArtQuickTexts(art)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'difesa') {
            final value = triggeredFormulaCommandValue(command);
            add(command.elementId.isEmpty ? 'Magia' : command.elementId, value);
          }
        }
      }
    }

    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      for (final text in activeItemQuickTexts(item)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'difesa') {
            final value = triggeredFormulaCommandValue(command);
            add(
              command.elementId.isEmpty
                  ? item.elementoDanno
                  : command.elementId,
              value,
            );
          }
        }
      }
    }

    for (final command in parseQuickCommandsDetailed(
      buffMalusRapidiController.text,
    )) {
      if (command.valid && command.key == 'difesa') {
        final value = triggeredFormulaCommandValue(command);
        add(command.elementId.isEmpty ? 'Fisico' : command.elementId, value);
      }
    }

    final skillDifesa = directSkillNumericBonus('difesa');
    if (skillDifesa > 0) add('Fisico', skillDifesa);
    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      for (final text in skillQuickCommandTexts(skill)) {
        for (final command in parseQuickCommandsDetailed(text)) {
          if (command.valid && command.key == 'difesa') {
            final value = triggeredFormulaCommandValue(command);
            add(
              command.elementId.isEmpty ? 'Fisico' : command.elementId,
              value,
            );
          }
        }
      }
    }

    oculumReconcileElementTotals(
      result,
      expectedTotal: difesa(),
      fallbackElement: 'Fisico',
    );
    return result;
  }

  String elementoDifesaDominante() {
    final parts = difesaPerElemento();
    if (parts.isEmpty || (parts.length == 1 && parts.containsKey('fisico'))) {
      return '';
    }
    final visibleParts = parts.entries.where((entry) => entry.key != 'fisico');
    final entries = visibleParts.isEmpty ? parts.entries : visibleParts;
    var best = entries.first;
    for (final entry in entries.skip(1)) {
      if (entry.value > best.value) best = entry;
    }
    return best.key;
  }

  String elementiDifesaTesto() {
    final keys = difesaPerElemento().keys.where((k) => k != 'fisico').toList();
    if (keys.isEmpty) return '';
    if (keys.length > 3) {
      return '${keys.take(3).map(elementDisplayName).toSet().join(' • ')} • +${keys.length - 3}';
    }
    return keys.map(elementDisplayName).toSet().join(' • ');
  }

  int iniziativa() {
    return bonusLivelloGrado() +
        materiaTotale() ~/ 5 +
        runtimeQuickBonus('iniziativa') +
        vantaggioTiroBonus() +
        malusFaticaTiri();
  }

  int movimento() {
    return max(0, 30 + (materiaTotale() ~/ 6) + runtimeQuickBonus('movimento'));
  }

  int vc() {
    return bonusLivelloGrado() +
        (volontaTotale() ~/ 3) +
        bonusAttaccoRapido() +
        titleQuickBonus('vc') +
        artQuickBonus('vc') +
        globalQuickBonus('vc') +
        skillTextQuickBonus('vc') +
        runtimeQuickBonus('tiro_attacco') +
        vantaggioTiroBonus() +
        malusFaticaTiri();
  }

  int cm() {
    return bonusLivelloGrado() +
        (materiaTotale() ~/ 2) +
        bonusCmRapido() +
        titleQuickBonus('cm') +
        artQuickBonus('cm') +
        globalQuickBonus('cm') +
        skillTextQuickBonus('cm') +
        runtimeQuickBonus('tiro_difesa') +
        vantaggioTiroBonus() +
        malusFaticaTiri();
  }

  double pesoMassimo() {
    return volontaTotale() * 3;
  }

  double pesoUsato() {
    return inventario.fold(
      0.0,
      (somma, item) => somma + (item.peso * item.quantita),
    );
  }

  double pesoRimanente() {
    return pesoMassimo() - pesoUsato();
  }

  int expCorrente() {
    final exp = leggiNumero(expController);

    if (exp < 0) return 0;
    if (exp > 999999) return 999999;

    return exp;
  }

  void refullaHp() {
    currentHpController.text = maxHp().toString();
  }

  // =====================================================
  // KARMA VISIVO
  // =====================================================

  double intensitaKarma(int karma) {
    final assoluto = karma.abs();

    if (assoluto <= 0) return 0;

    return (0.18 + (assoluto * 0.09)).clamp(0.18, 0.85);
  }

  Color coloreTestoKarma(int karma) {
    if (karma < 0) {
      return const Color(0xFF7A1026);
    }

    if (karma > 0) {
      return Colors.white;
    }

    return Colors.grey;
  }

  Color coloreBordoKarma(int karma) {
    if (karma < 0) {
      return const Color(0xFF7A1026);
    }

    if (karma > 0) {
      return tertiaryColor;
    }

    return Colors.grey.shade700;
  }

  List<Shadow> ombraKarma(int karma) {
    final intensita = intensitaKarma(karma);

    if (karma < 0) {
      return [
        Shadow(
          color: Colors.black.withValues(alpha: intensita),
          blurRadius: 8 + karma.abs().clamp(1, 8) * 2.4,
        ),
        Shadow(
          color: const Color(0xFF22000A).withValues(alpha: intensita * 0.75),
          blurRadius: 14 + karma.abs().clamp(1, 8) * 2.8,
        ),
      ];
    }

    if (karma > 0) {
      return [
        Shadow(
          color: tertiaryColor.withValues(alpha: intensita),
          blurRadius: 8 + karma.abs().clamp(1, 8) * 2.6,
        ),
        Shadow(
          color: const Color(0xFFFFD36A).withValues(alpha: intensita * 0.65),
          blurRadius: 16 + karma.abs().clamp(1, 8) * 3.0,
        ),
      ];
    }

    return [Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4)];
  }

  String descrizioneKarmaVisivo(int karma) {
    if (karma < 0) {
      return t(
        'Karma negativo: a pelle senti qualcosa di storto o pericoloso, ma il Karma può essere illuso. Non è una prova.',
        'Negative Karma: your gut feels something twisted or dangerous, but Karma can be deceived. It is not proof.',
      );
    }

    if (karma > 0) {
      return t(
        'Karma positivo: a pelle senti fiducia, favore o calore del Fato, ma anche questa sensazione può essere falsata.',
        'Positive Karma: your gut feels trust, favor, or warmth from Fate, but even this feeling can be falsified.',
      );
    }

    return t(
      'Karma neutro: non senti segnali forti. Potrebbe essere equilibrio, maschera o semplice silenzio.',
      'Neutral Karma: you feel no strong signal. It may be balance, a mask, or simple silence.',
    );
  }

  // =====================================================
}
