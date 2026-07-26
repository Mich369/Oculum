part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

class _StatoForzaDef {
  const _StatoForzaDef({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.descriptionIt,
    required this.descriptionEn,
    required this.weight,
  });

  final String id;
  final String nameIt;
  final String nameEn;
  final String descriptionIt;
  final String descriptionEn;
  final int weight;
}

enum OculumExplosionAftermath { oculumRollPenalty, ashOne, ashThree }

OculumExplosionAftermath oculumExplosionAftermathForRoll(int roll) {
  final value = roll.clamp(0, 100).toInt();
  if (value < 56) return OculumExplosionAftermath.oculumRollPenalty;
  if (value < 92) return OculumExplosionAftermath.ashOne;
  return OculumExplosionAftermath.ashThree;
}

extension _OculumHomeForceState on _OculumHomePageState {
  List<_StatoForzaDef> statoForzaDefs() => const [
    _StatoForzaDef(
      id: 'niente',
      nameIt: 'Niente',
      nameEn: 'Nothing',
      descriptionIt: 'Non accade nulla: il corpo non trova una scintilla.',
      descriptionEn: 'Nothing happens: the body finds no spark.',
      weight: 24,
    ),
    _StatoForzaDef(
      id: 'stanchezza',
      nameIt: 'Stanchezza',
      nameEn: 'Exhaustion',
      descriptionIt:
          '-2 ai tiri per colpire e difendersi, -5 - livello - grado ai danni.',
      descriptionEn:
          '-2 to attack and defense rolls, -5 - level - grade to damage.',
      weight: 16,
    ),
    _StatoForzaDef(
      id: 'occhi_attenti',
      nameIt: 'Occhi Attenti',
      nameEn: 'Sharp Eyes',
      descriptionIt: '+5 + livello + grado ai tiri di attacco e difesa.',
      descriptionEn: '+5 + level + grade to attack and defense rolls.',
      weight: 14,
    ),
    _StatoForzaDef(
      id: 'adrenalina',
      nameIt: 'Adrenalina',
      nameEn: 'Adrenaline',
      descriptionIt:
          'Ottieni 1 Reazione veloce e +5 + livello + grado iniziativa.',
      descriptionEn: 'Gain 1 fast Reaction and +5 + level + grade initiative.',
      weight: 12,
    ),
    _StatoForzaDef(
      id: 'corpo_non_mollare',
      nameIt: 'Corpo non Mollare',
      nameEn: 'Body, Do Not Give Up',
      descriptionIt:
          '+20 + livello + grado HP temporanei, +3 Volonta e +2 Materia.',
      descriptionEn:
          '+20 + level + grade temporary HP, +3 Will and +2 Materia.',
      weight: 10,
    ),
    _StatoForzaDef(
      id: 'esplosione_oculum',
      nameIt: 'Esplosione di Oculum',
      nameEn: 'Oculum Burst',
      descriptionIt:
          '+25 HP, Oculum pari alla vita anche oltre il massimo, danni pari a livello + grado e difesa pari alla meta di livello + grado. Dura almeno 9 tiri.',
      descriptionEn:
          '+25 HP, Oculum equal to life even above the maximum, damage equal to level + grade and defense equal to half level + grade. Lasts at least 9 rolls.',
      weight: 8,
    ),
    _StatoForzaDef(
      id: 'azzeramento_vulnerabilita',
      nameIt: 'Azzeramento delle vulnerabilita',
      nameEn: 'Vulnerability Reset',
      descriptionIt:
          'Resistenza ai colpi, rimozione dei malus temporanei negativi e della Cenere accumulata.',
      descriptionEn:
          'Resistance to hits, removal of negative temporary penalties and accumulated Ash.',
      weight: 6,
    ),
  ];

  _StatoForzaDef statoForzaDef(String id) {
    return statoForzaDefs().firstWhere(
      (def) => def.id == id,
      orElse: () => statoForzaDefs().first,
    );
  }

  int statoForzaLivelloGrado() {
    return max(0, leggiNumero(livelloController)) +
        max(0, leggiNumero(gradoController));
  }

  bool statoForzaRimuoveMalus() {
    return statoForzaAttivo == 'azzeramento_vulnerabilita';
  }

  int sogliaStatoForzaHp() {
    return max(1, (maxHp() / 4).ceil());
  }

  int statoForzaQuickBonus(String key) {
    final livelloGrado = statoForzaLivelloGrado();
    final postExplosionPenalty = key == 'tiro_oculum'
        ? malusTiriOculumPostEsplosione
        : 0;
    switch (statoForzaAttivo) {
      case 'corpo_non_mollare':
        if (key == 'volonta') return postExplosionPenalty + 3;
        if (key == 'materia') return postExplosionPenalty + 2;
        return postExplosionPenalty;
      case 'occhi_attenti':
        if (key == 'tiro_attacco' || key == 'tiro_difesa') {
          return postExplosionPenalty + 5 + livelloGrado;
        }
        return postExplosionPenalty;
      case 'esplosione_oculum':
        if (key == 'danni') return postExplosionPenalty + livelloGrado;
        if (key == 'difesa') {
          return postExplosionPenalty + (livelloGrado / 2).ceil();
        }
        return postExplosionPenalty;
      case 'adrenalina':
        if (key == 'reazione_veloce') return postExplosionPenalty + 1;
        if (key == 'iniziativa') return postExplosionPenalty + 5 + livelloGrado;
        return postExplosionPenalty;
      case 'stanchezza':
        if (key == 'tiro_attacco' || key == 'tiro_difesa') {
          return postExplosionPenalty - 2;
        }
        if (key == 'danni') return postExplosionPenalty - 5 - livelloGrado;
        return postExplosionPenalty;
      default:
        return postExplosionPenalty;
    }
  }

  String statoForzaNomeAttivo() {
    if (statoForzaAttivo.trim().isEmpty) {
      return t('Nessuno stato di forza attivo', 'No force state active');
    }
    final def = statoForzaDef(statoForzaAttivo);
    return t(def.nameIt, def.nameEn);
  }

  String statoForzaDescrizioneAttiva() {
    if (statoForzaAttivo.trim().isEmpty) {
      return t(
        'Si tira quando gli HP scendono a un quarto o meno del massimo.',
        'Rolled when HP drop to one quarter or less of the maximum.',
      );
    }
    final def = statoForzaDef(statoForzaAttivo);
    return t(def.descriptionIt, def.descriptionEn);
  }

  _StatoForzaDef pescaStatoForza() {
    final defs = statoForzaDefs();
    final totalWeight = defs.fold<int>(0, (sum, def) => sum + def.weight);
    var roll = Random().nextInt(max(1, totalWeight));
    for (final def in defs) {
      if (roll < def.weight) return def;
      roll -= def.weight;
    }
    return defs.first;
  }

  String applicaEffettoImmediatoStatoForza(String id) {
    final livelloGrado = statoForzaLivelloGrado();
    switch (id) {
      case 'corpo_non_mollare':
        final hpTempBonus = 20 + livelloGrado;
        final hpTempPrima = hpTemp();
        impostaHpTempTotali(
          min(oculumTemporaryHpLimit, hpTempPrima + hpTempBonus),
        );
        final hpTempApplicati = hpTemp() - hpTempPrima;
        return t(
          '+$hpTempApplicati HP temporanei applicati (massimo $oculumTemporaryHpLimit).',
          '+$hpTempApplicati temporary HP applied (maximum $oculumTemporaryHpLimit).',
        );
      case 'esplosione_oculum':
        final prima = hpCorrenti();
        final hpDopo = min(maxHp(), prima + 25);
        currentHpController.text = hpDopo.toString();
        addOculum(max(0, hpDopo - oculumTotale()), scheduleSave: false);
        final oculumDopo = oculumTotale();
        statoForzaTiriRimanenti = max(statoForzaTiriRimanenti, 9);
        return t(
          '+25 HP applicati. Oculum attuale portato a $oculumDopo entro il limite temporaneo della difficolta.',
          '+25 HP applied. Current Oculum raised to $oculumDopo within the difficulty temporary limit.',
        );
      case 'azzeramento_vulnerabilita':
        tempResilienza = max(0, tempResilienza);
        tempVolonta = max(0, tempVolonta);
        tempMateria = max(0, tempMateria);
        tempOculum = max(0, tempOculum);
        cenereController.text = '0';
        cenereSvenimentoUltimoControllo = 0;
        return t(
          'Malus temporanei negativi rimossi e Cenere azzerata.',
          'Negative temporary penalties removed and Ash reset.',
        );
      default:
        return '';
    }
  }

  String applicaEsitoFineEsplosioneOculum() {
    final outcome = oculumExplosionAftermathForRoll(Random().nextInt(101));
    switch (outcome) {
      case OculumExplosionAftermath.oculumRollPenalty:
        malusTiriOculumPostEsplosione = -1;
        return t(
          'Fine Esplosione di Oculum: -1 ai tiri Oculum fino al prossimo riposo breve o lungo.',
          'Oculum Burst ended: -1 to Oculum rolls until the next short or long rest.',
        );
      case OculumExplosionAftermath.ashOne:
        final svenimento = modificaCenereControllata(1);
        return t(
          'Fine Esplosione di Oculum: +1 Cenere.${svenimento == null ? '' : '\n$svenimento'}',
          'Oculum Burst ended: +1 Ash.${svenimento == null ? '' : '\n$svenimento'}',
        );
      case OculumExplosionAftermath.ashThree:
        final svenimento = modificaCenereControllata(3);
        return t(
          'Fine Esplosione di Oculum: +3 Cenere.${svenimento == null ? '' : '\n$svenimento'}',
          'Oculum Burst ended: +3 Ash.${svenimento == null ? '' : '\n$svenimento'}',
        );
    }
  }

  String terminaStatoForzaAttivo({bool applicaEsitoEsplosione = true}) {
    final active = statoForzaAttivo;
    statoForzaAttivo = '';
    statoForzaPronto = true;
    statoForzaTiriRimanenti = 0;
    if (active == 'esplosione_oculum' && applicaEsitoEsplosione) {
      return applicaEsitoFineEsplosioneOculum();
    }
    return '';
  }

  String registraTiroStatoForza() {
    if (statoForzaAttivo != 'esplosione_oculum' ||
        statoForzaTiriRimanenti <= 0) {
      return '';
    }

    statoForzaTiriRimanenti = max(0, statoForzaTiriRimanenti - 1);
    if (statoForzaTiriRimanenti > 0) return '';

    if (hpCorrenti() > sogliaStatoForzaHp()) {
      final finale = terminaStatoForzaAttivo();
      return finale.isEmpty ? '' : '\n$finale';
    }

    return '';
  }

  List<int> svenimentoCenereDadi() => const [
    120,
    100,
    90,
    80,
    72,
    70,
    60,
    50,
    48,
    40,
    36,
    34,
    32,
    30,
    28,
    26,
    24,
    22,
    20,
    18,
    16,
    14,
    12,
    10,
    9,
    8,
    7,
    6,
    5,
    4,
    3,
    2,
  ];

  int dadoSvenimentoCenere(int cenere) {
    final dice = svenimentoCenereDadi();
    final index = (cenere - 3).clamp(0, dice.length - 1).toInt();
    return dice[index];
  }

  int difficoltaSvenimentoCenere(int cenere) => 20 + max(0, cenere) * 3;

  int bonusSvenimentoCenere() {
    return ((resilienzaTotale() ~/ 3) +
            max(0, leggiNumero(livelloController)) +
            max(0, leggiNumero(gradoController)) * 6 +
            malusFaticaTiri())
        .toInt();
  }

  String? impostaCenereControllata(
    int value, {
    int? precedente,
    bool controllaSvenimento = true,
  }) {
    final before = max(0, precedente ?? leggiNumero(cenereController));
    final next = max(0, value);
    cenereController.text = next.toString();
    if (next < 3) {
      cenereSvenimentoUltimoControllo = next;
      if (personaggioSvenuto) {
        personaggioSvenuto = false;
      }
      return null;
    }
    if (!controllaSvenimento || next <= before) {
      cenereSvenimentoUltimoControllo = max(
        cenereSvenimentoUltimoControllo,
        next,
      );
      return null;
    }
    return controllaSvenimentoPerCenere(before, next);
  }

  String? modificaCenereControllata(
    int delta, {
    bool controllaSvenimento = true,
  }) {
    final before = max(0, leggiNumero(cenereController));
    return impostaCenereControllata(
      before + delta,
      precedente: before,
      controllaSvenimento: controllaSvenimento,
    );
  }

  String? controllaCenereModificataManualmente() {
    final current = max(0, leggiNumero(cenereController));
    if (current < 3) {
      cenereSvenimentoUltimoControllo = current;
      if (personaggioSvenuto) personaggioSvenuto = false;
      return null;
    }

    if (current < cenereSvenimentoUltimoControllo) {
      cenereSvenimentoUltimoControllo = current;
      return null;
    }

    if (current <= cenereSvenimentoUltimoControllo) return null;
    return controllaSvenimentoPerCenere(
      cenereSvenimentoUltimoControllo,
      current,
    );
  }

  String controllaSvenimentoPerCenere(int previous, int current) {
    var mainMessage = '';
    final start = max(3, previous + 1);
    final random = Random();
    var checkedUntil = current;
    for (var cenere = start; cenere <= current; cenere++) {
      final faces = dadoSvenimentoCenere(cenere);
      final roll = random.nextInt(faces) + 1;
      final resilienzaBonus = resilienzaTotale() ~/ 3;
      final livello = max(0, leggiNumero(livelloController));
      final grado = max(0, leggiNumero(gradoController));
      final gradoBonus = grado * 6;
      final cenerePenalty = statoForzaRimuoveMalus() ? 0 : -cenere;
      final total = rollTotalWithCritical(
        roll,
        faces,
        [resilienzaBonus, livello, gradoBonus, cenerePenalty],
        level: livello,
        grade: grado,
      );
      final critical = criticalDieModifier(
        roll,
        faces,
        level: livello,
        grade: grado,
      );
      final difficulty = difficoltaSvenimentoCenere(cenere);
      final success = total > difficulty;
      checkedUntil = cenere;
      mainMessage = success
          ? t(
              'Riesci a non svenire nonostante la fatica, la vista si appanna leggermente.',
              'You manage not to faint despite the fatigue; your vision blurs slightly.',
            )
          : t(
              'Incosciente: la Cenere supera il corpo e la vista si spegne.',
              'Unconscious: the Ash overwhelms the body and vision fades.',
            );
      aggiungiLog(
        t(
          'Tiro svenimento Cenere $cenere: 1d$faces=$roll${critical == 0 ? '' : ' ${critical > 0 ? '+' : ''}$critical critico'} + Resilienza/3 $resilienzaBonus + Livello $livello + Grado x6 $gradoBonus ${signedRollPart(cenerePenalty)} Cenere = $total contro $difficulty. $mainMessage',
          'Ash fainting roll $cenere: 1d$faces=$roll${critical == 0 ? '' : ' ${critical > 0 ? '+' : ''}$critical critical'} + Resilience/3 $resilienzaBonus + Level $livello + Grade x6 $gradoBonus ${signedRollPart(cenerePenalty)} Ash = $total against $difficulty. $mainMessage',
        ),
      );
      if (!success) {
        personaggioSvenuto = true;
        checkedUntil = current;
        break;
      }
    }
    cenereSvenimentoUltimoControllo = max(
      cenereSvenimentoUltimoControllo,
      checkedUntil,
    );
    return mainMessage;
  }

  void svegliaDaSvenimento({bool salva = true}) {
    if (!personaggioSvenuto) return;
    setState(() {
      personaggioSvenuto = false;
      risultato = t(
        'Ti svegli: lo stato Incosciente viene rimosso.',
        'You wake up: the Unconscious state is removed.',
      );
      ultimoEventoRiposo = risultato;
      aggiungiLog(risultato);
    });
    if (salva) programmaSalvataggio();
  }

  void controllaStatoForzaDopoHp() {
    final hp = hpCorrenti();
    final soglia = sogliaStatoForzaHp();

    if (hp > soglia) {
      if (statoForzaAttivo == 'esplosione_oculum' &&
          statoForzaTiriRimanenti > 0) {
        return;
      }
      if (!statoForzaPronto || statoForzaAttivo.isNotEmpty) {
        setState(() {
          final finale = terminaStatoForzaAttivo();
          if (finale.isNotEmpty) {
            risultato = finale;
            ultimoEventoRiposo = risultato;
            aggiungiLog(risultato);
          }
        });
        programmaSalvataggio();
      }
      return;
    }

    if (!statoForzaPronto || statoForzaAttivo.isNotEmpty) return;

    final def = pescaStatoForza();
    setState(() {
      statoForzaPronto = false;
      statoForzaAttivo = def.id;
      statoForzaTiriRimanenti = def.id == 'esplosione_oculum' ? 9 : 0;
      final immediate = applicaEffettoImmediatoStatoForza(def.id);
      risultato = t(
        'Stato di forza attivato: ${t(def.nameIt, def.nameEn)}. ${t(def.descriptionIt, def.descriptionEn)}',
        'Force state activated: ${t(def.nameIt, def.nameEn)}. ${t(def.descriptionIt, def.descriptionEn)}',
      );
      if (immediate.isNotEmpty) risultato += '\n$immediate';
      ultimoEventoRiposo = risultato;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeHpChanged();
  }
}
