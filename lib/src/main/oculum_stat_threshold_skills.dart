part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

const oculumStatThresholdSkills = <String, List<Map<String, dynamic>>>{
  'volonta': [
    {
      'name': 'Schianto distruttivo',
      'cost': 1,
      'cd': 6,
      'kind': 'strike',
      'description':
          'Ti lanci contro il nemico: @Danni+20 danni. Questo attacco ignora le resistenze, mantenendo difesa e scudi.',
    },
    {
      'name': 'Voto del baluardo',
      'cost': 1,
      'cd': 6,
      'kind': 'shield',
      'amount': 20,
      'description':
          'La tua volontà si condensa: ottieni 20 Scudo. Non aumenta lo Scudo Oculum.',
    },
    {
      'name': 'Impeto indomito',
      'cost': 1,
      'cd': 6,
      'kind': 'impetus',
      'description':
          'Ottieni +4 Danni e +2 Difesa per un turno. Gli usi non si sommano.',
    },
  ],
  'resilienza': [
    {
      'name': 'Cura magica',
      'cost': 0,
      'cd': 4,
      'kind': 'heal',
      'description':
          'Recuperi HP pari a Medicina + Oculum immesso ×2, senza superare la Vita massima. Costo variabile: 1/6 Oculum.',
    },
    {
      'name': 'Radice vitale',
      'cost': 1,
      'cd': 6,
      'kind': 'heal_fixed',
      'description':
          'Recuperi 10 HP + Resilienza base, senza superare la Vita massima.',
    },
    {
      'name': 'Pelle del superstite',
      'cost': 1,
      'cd': 6,
      'kind': 'shield',
      'amount': 15,
      'description':
          'Ottieni 15 Scudo. La protezione assorbe i danni secondo le normali regole.',
    },
  ],
  'materia': [
    {
      'name': 'Doppio salto',
      'cost': 1,
      'cd': 3,
      'kind': 'jump',
      'description':
          'Esegui un secondo salto in aria: +3 Riflessi e +2 Materia soltanto per questa azione. Il tiro di Riflessi include i bonus e poi li rimuove.',
    },
    {
      'name': 'Passo del predatore',
      'cost': 1,
      'cd': 4,
      'kind': 'step',
      'description':
          'Ottieni +3 Iniziativa e +2 Controllo di Movimento per un turno.',
    },
    {
      'name': 'Colpo di leva',
      'cost': 1,
      'cd': 5,
      'kind': 'lever',
      'description':
          'Attacco preciso: @Danni+10 danni perforanti. Le resistenze restano applicabili.',
    },
  ],
  'oculum': [
    {
      'name': 'Raggio di Oculum',
      'cost': 2,
      'cd': 4,
      'kind': 'ray',
      'description':
          'Lanci un raggio: @Danni+5 danni Magia e @Danni+10 danni Oculum. Le due componenti mantengono il proprio elemento.',
    },
    {
      'name': 'Velo della pupilla',
      'cost': 2,
      'cd': 5,
      'kind': 'shield',
      'amount': 20,
      'description': 'Condensi il tuo potere in un velo che concede 20 Scudo.',
    },
    {
      'name': 'Eco del nucleo',
      'cost': 2,
      'cd': 5,
      'kind': 'echo',
      'description':
          'Emetti un impulso: @Danni+15 danni Oculum, soggetti alle normali resistenze.',
    },
  ],
};

String? oculumFirstThresholdStat(Map<String, int> baseStats) {
  for (final key in oculumStatThresholdSkills.keys) {
    if ((baseStats[key] ?? 0) >= 6) return key;
  }
  return null;
}

CharacterSkill oculumCreateThresholdSkill(
  String stat,
  int variant, {
  Random? random,
}) {
  final data = oculumStatThresholdSkills[stat]![variant.clamp(0, 2)];
  final rng = random ?? Random();
  final damageBonus = stat == 'volonta' ? 16 + rng.nextInt(10) : 0;
  final defenseBonus = stat == 'materia' ? 15 + rng.nextInt(6) : 0;
  final temporaryHpRests = stat == 'resilienza' ? 3 + rng.nextInt(9) : 0;
  final rewardText = stat == 'volonta'
      ? 'Bonus possesso: +3 Volontà e +$damageBonus Danni.'
      : stat == 'materia'
      ? 'Bonus possesso: +3 Materia e +$defenseBonus Difesa.'
      : stat == 'resilienza'
      ? 'Bonus possesso: +3 Resilienza. Ottieni una sola volta 50 HP temporanei per $temporaryHpRests riposi lunghi (1d9 + 3).'
      : '';
  final variable = data['kind'] == 'heal';
  final cost = variable
      ? '1/6 Oculum'
      : '${data['cost']} ${stat == 'volonta'
            ? 'Volontà'
            : stat == 'resilienza'
            ? 'Resilienza'
            : stat == 'materia'
            ? 'Materia'
            : 'Oculum'}';
  return CharacterSkill(
    thresholdData: {
      ...data,
      'stat': stat,
      if (stat == 'resilienza') 'temporaryHpRemaining': 50,
      if (stat == 'resilienza') 'longRestsRemaining': temporaryHpRests,
      if (stat == 'resilienza') 'longRestsGranted': temporaryHpRests,
    },
    resilienza: stat == 'resilienza' ? 3 : 0,
    volonta: stat == 'volonta' ? 3 : 0,
    materia: stat == 'materia' ? 3 : 0,
    danni: damageBonus,
    difesa: defenseBonus,
    nome: '${data['name']}',
    tipo: 'Skill di soglia · $stat',
    costo: cost,
    cooldown: '${data['cd']} turni',
    descrizione: '${data['description']}\n$rewardText',
    forme: [
      CharacterSkillForm(
        nome: 'Forma I',
        tipo: 'Skill di soglia · $stat',
        costo: cost,
        cooldown: '${data['cd']} turni',
        descrizione: '${data['description']}\n$rewardText',
        aumentoMassimoOculumAttivo: false,
        oculumMinimoUtilizzabile: variable
            ? 1
            : stat == 'oculum'
            ? data['cost'] as int
            : 0,
        oculumMassimoUtilizzabile: variable
            ? 6
            : stat == 'oculum'
            ? data['cost'] as int
            : 0,
        costoStrutturato: OculumSkillCost(
          resource: variable ? 'oculum' : stat,
          amountExpression: '${data['cost']}',
          variable: variable,
          minimum: variable ? 1 : 0,
          maximum: variable ? 6 : 0,
        ),
        cooldownStrutturato: OculumAbilityCooldown(amount: data['cd'] as int),
      ),
    ],
  );
}

extension _OculumStatThresholdSkills on _OculumHomePageState {
  int thresholdTemporaryHp() => skills.fold<int>(
    0,
    (total, skill) =>
        total +
        max(0, readIntValue(skill.thresholdData['temporaryHpRemaining'])),
  );

  int thresholdTemporaryHpLimit() =>
      oculumTemporaryHpLimit + thresholdTemporaryHp();

  void consumeThresholdTemporaryHp(int amount) {
    var remaining = max(0, amount);
    for (final skill in skills) {
      final pool = max(
        0,
        readIntValue(skill.thresholdData['temporaryHpRemaining']),
      );
      final spent = min(pool, remaining);
      if (spent == 0) continue;
      skill.thresholdData['temporaryHpRemaining'] = pool - spent;
      remaining -= spent;
    }
  }

  void restThresholdTemporaryHp() {
    for (final skill in skills) {
      final rests = readIntValue(skill.thresholdData['longRestsRemaining']);
      if (rests <= 0) continue;
      skill.thresholdData['longRestsRemaining'] = rests - 1;
      if (rests == 1) {
        final expired = readIntValue(
          skill.thresholdData['temporaryHpRemaining'],
        );
        skill.thresholdData['temporaryHpRemaining'] = 0;
        aggiungiLog(
          '${skill.nome}: scaduti $expired HP temporanei allo scadere dei riposi lunghi previsti.',
        );
      }
    }
  }

  bool grantFirstStatThresholdSkill({String? changedStat, int? variant}) {
    if (!datiCaricati ||
        loadingThresholdSheet ||
        statThresholdReward.isNotEmpty ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final stats = <String, int>{
      'resilienza': leggiNumero(resilienzaController),
      'volonta': leggiNumero(volontaController),
      'materia': leggiNumero(materiaController),
      'oculum': leggiNumero(oculumController),
    };
    final stat = changedStat != null && (stats[changedStat] ?? 0) >= 6
        ? changedStat
        : oculumFirstThresholdStat(stats);
    if (stat == null) return false;
    final skill = oculumCreateThresholdSkill(
      stat,
      variant ?? Random().nextInt(3),
    );
    statThresholdReward = '$stat:${skill.nome}';
    skills.add(skill);
    applicaBonusSkillAttuali(skill, 1);
    schedePersonaggio[schedaCorrente]['statThresholdReward'] =
        statThresholdReward;
    aggiungiLog(
      'Prima statistica base a 6: $stat. Skill ottenuta: ${skill.nome} · ${skill.costo} · CD ${skill.cooldown}. Bonus: +${skill.resilienza} Resilienza, +${skill.volonta} Volontà, +${skill.materia} Materia, +${skill.danni} Danni, +${skill.difesa} Difesa${stat == 'resilienza' ? ', +50 HP temporanei per ${skill.thresholdData['longRestsGranted']} riposi lunghi (1d9 + 3)' : ''}.',
    );
    return true;
  }

  Future<void> useStatThresholdSkill(CharacterSkill skill) async {
    final data = skill.thresholdData;
    if (data.isEmpty) return;
    final stat = '${data['stat']}';
    final form = skill.forme.first;
    final cooldown = form.cooldownStrutturato;
    if (cooldown != null && !cooldown.ready) {
      aggiungiLog('${skill.nome}: CD ${cooldown.remaining} ${cooldown.unit}.');
      return;
    }
    var cost = data['cost'] as int;
    var resource = stat;
    final configuredCost = form.costoStrutturato;
    if (configuredCost != null && !configuredCost.variable) {
      resource = configuredCost.resource;
      cost = max(
        0,
        oculumEvaluateStructuredEffectValue(
          OculumStructuredEffect(
            valueExpression: configuredCost.amountExpression,
          ),
          variables: formulaValueContext(),
          subtraits: hiddenEyeStats,
        ),
      );
    }
    if (data['kind'] == 'heal') {
      final selected = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: backgroundBottomColor,
          title: Text('Cura magica', style: TextStyle(color: tertiaryColor)),
          content: Text(
            'Medicina + Oculum immesso ×2 HP',
            style: TextStyle(color: primaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            for (
              var amount = max(1, form.oculumMinimoUtilizzabile);
              amount <= form.oculumMassimoUtilizzabile;
              amount++
            )
              TextButton(
                onPressed: amount <= oculumTotale()
                    ? () => Navigator.pop(ctx, amount)
                    : null,
                child: Text('$amount Oculum'),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      cost = selected;
      resource = 'oculum';
    }
    final available = resource == 'oculum'
        ? oculumTotale()
        : resource == 'volonta'
        ? currentVolonta()
        : resource == 'materia'
        ? currentMateria()
        : currentResilienza();
    if (available < cost) {
      aggiungiLog('${skill.nome}: $resource insufficiente, servono $cost.');
      return;
    }
    final damage = dannoTotale();
    final medicine = hiddenEyeStats
        .where((stat) => stat.id == 'medicina')
        .firstOrNull;
    final kind = data['kind'];
    final effects = <OculumStructuredEffect>[];
    String details = skill.descrizione;
    if (kind == 'heal' || kind == 'heal_fixed') {
      final healing = kind == 'heal'
          ? (medicine == null ? 0 : hiddenEyeTotal(medicine)) + cost * 2
          : 10 + leggiNumero(resilienzaController);
      effects.add(
        OculumStructuredEffect(
          type: 'cura',
          resource: 'vita',
          valueExpression: '$healing',
        ),
      );
      details = '$healing HP di cura (entro Vita massima).';
    } else if (kind == 'shield') {
      effects.add(
        OculumStructuredEffect(
          type: 'scudo',
          valueExpression: '${data['amount']}',
        ),
      );
    } else if (kind == 'jump' || kind == 'impetus' || kind == 'step') {
      final bonuses = kind == 'jump'
          ? {'riflessi': 3, 'materia': 2}
          : kind == 'impetus'
          ? {'danni': 4, 'difesa': 2}
          : {'iniziativa': 3, 'controllo_movimento': 2};
      for (final entry in bonuses.entries) {
        effects.add(
          OculumStructuredEffect(
            id: 'threshold:${skill.nome}:${entry.key}',
            type: entry.key == 'riflessi' || entry.key == 'controllo_movimento'
                ? 'modifica_sottotratto'
                : 'modifica_statistica',
            target: entry.key,
            valueExpression: '${entry.value}',
            duration: kind == 'jump' ? '0' : '1',
            durationUnit: 'turni',
          ),
        );
      }
    } else {
      details = kind == 'strike'
          ? '${damage + 20} danni · ignora resistenze; difesa e scudi applicabili.'
          : kind == 'ray'
          ? '${damage + 5} danni Magia + ${damage + 10} danni Oculum.'
          : kind == 'lever'
          ? '${damage + 10} danni perforanti.'
          : '${damage + 15} danni Oculum.';
    }
    if (spendArtSkillCostResource(resource, cost) != cost) return;
    cooldown?.activate();
    final messages = applyStructuredEffectsOnActivation([
      ...effects,
      ...form.effettiStrutturati,
    ], source: skill.nome);
    setState(() {
      risultato =
          '${skill.nome}: $details\nCosto: $cost $resource · CD ${cooldown?.amount ?? 0} ${cooldown?.unit ?? 'turni'}.${messages.isEmpty ? '' : '\n${messages.join('\n')}'}';
      aggiungiLog(risultato);
    });
    if (realtimeService?.isConnected == true) {
      unawaited(realtimeService!.sendPartyLog(risultato));
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    if (kind == 'jump') {
      ensureHiddenEyeDefaults();
      final reflexes = hiddenEyeStats
          .where((stat) => stat.id == 'riflessi')
          .firstOrNull;
      try {
        if (reflexes != null) {
          await tiraSottotrattoOcchio(reflexes, actionLabel: 'Doppio salto');
        }
      } finally {
        activeStructuredEffects.removeWhere(
          (effect) =>
              '${effect['effectId']}'.startsWith('threshold:Doppio salto:'),
        );
        invalidateDerivedDataCaches();
        aggiungiLog(
          'Doppio salto: azione conclusa, rimossi +3 Riflessi e +2 Materia.',
        );
        programmaSalvataggio();
        notifyActiveSheetSummaryChanged();
      }
    }
  }
}
