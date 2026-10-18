part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int? oculumScrollDropGrade(String subtraitId, int total) =>
    subtraitId == 'drop' && total >= 18 ? min(12, (total - 18) ~/ 10) : null;

int oculumScrollValue(int grade) =>
    300 * pow(grade.clamp(0, 12) + 1, 2).toInt();

String oculumScrollKindForElement(String element) => switch (element) {
  'gelo' || 'ghiaccio' => 'attack',
  'fuoco' || 'fiamma' => 'attack',
  'acqua' => 'heal',
  'terra' || 'pietra' => 'imprison',
  'pianta' || 'natura' || 'radice' => 'control',
  'luce' => 'ward',
  'ombra' => 'weaken',
  'fulmine' || 'elettricita' => 'stun',
  _ => 'attack',
};

int oculumScrollDifficulty(int grade) => 12 + 2 * grade.clamp(0, 12);

int oculumScrollWillCost(int grade) => 1 + grade.clamp(0, 12) ~/ 3;

int oculumScrollCooldown(int grade) => 3 + grade.clamp(0, 12) ~/ 3;

int oculumScrollEffectMagnitude(int grade) => 1 + grade.clamp(0, 12);

class OculumTechniqueScrollProfile {
  const OculumTechniqueScrollProfile(
    this.id,
    this.name,
    this.monster,
    this.element,
    this.effects,
  );
  final String id, name, monster, element;
  final List<OculumStructuredEffect> effects;
}

final List<OculumTechniqueScrollProfile> oculumTechniqueScrolls = () {
  final result = <OculumTechniqueScrollProfile>[];
  final names = <String>{};
  for (final monster in defaultMonsterBookEntries.where((m) => !m.isNpc)) {
    final art = oculumMonsterBookArt(monster);
    for (final (index, skill) in art.skills.indexed) {
      final name = skill.nome.trim();
      if (skill.tipoPerLivello(1).toLowerCase().contains('passiv') ||
          name.isEmpty ||
          names.contains(oculumNormalizeText(name))) {
        continue;
      }
      final effects = skill
          .effettiEvoluzione(1)
          .where(
            (effect) =>
                effect.enabled &&
                const {
                  'danno',
                  'danno_percentuale',
                  'difesa',
                  'cura',
                  'scudo',
                  'velocita',
                  'modifica_statistica',
                  'modifica_sottotratto',
                  'hp_temporanei',
                  'aggiungi_reazioni',
                }.contains(effect.type),
          )
          .toList();
      if (effects.isEmpty) continue;
      names.add(oculumNormalizeText(name));
      result.add(
        OculumTechniqueScrollProfile(
          '${monster.id}_$index',
          name,
          monster.nameIt,
          monster.elementId,
          effects,
        ),
      );
    }
  }
  return List<OculumTechniqueScrollProfile>.unmodifiable(result.take(120));
}();

InventoryItem oculumTechniqueScrollItem(
  OculumTechniqueScrollProfile profile,
  int grade,
) {
  final g = grade.clamp(0, 12).toInt();
  final effects = [
    for (final original in profile.effects)
      OculumStructuredEffect.fromJson({
        ...original.toJson(),
        'id': 'scroll_${profile.id}_$g/${original.id}',
        'recipient': 'se_stesso',
        'valueExpression':
            '(${original.valueExpression.replaceAll("oculum_spent", "${g + 1}")})*(1+$g/10)',
        'diceExpression': original.diceExpression,
        'mode': const {'cura', 'scudo', 'hp_temporanei'}.contains(original.type)
            ? 'immediato'
            : const {
                'danno',
                'danno_percentuale',
                'modifica_sottotratto',
                'velocita',
              }.contains(original.type)
            ? 'prossima_azione'
            : 'finche_attivo',
        'duration':
            const {'cura', 'scudo', 'hp_temporanei'}.contains(original.type)
            ? ''
            : '${1 + g ~/ 4}',
        'durationUnit': 'turni',
        'frequency': '',
        'stackable': false,
      }),
  ];
  final description =
      'L’impronta di ${profile.monster} prepara ${profile.name}. Gli effetti seguenti sono applicati al lanciatore; i bonus di attacco valgono per il prossimo attacco, le cure sono immediate. La pergamena contiene ${g + 1} Oculum impresso: non richiede una spesa Oculum aggiuntiva.\n${effects.map(oculumStructuredEffectDescription).join("\n")}';
  return InventoryItem(
    nome: '[${profile.name}] [Pergamena] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    elementoDanno: profile.element,
    note:
        '$description\nMonouso; apprendibile, non evolvibile. Costo ${oculumScrollWillCost(g)}/${oculumScrollWillCost(g)} Volontà; CD ${oculumScrollCooldown(g)} turni personali; DT ${oculumScrollDifficulty(g)}. Valore ${oculumScrollValue(g)} Obser.',
    craftData: {
      'scroll': {
        'id': 'technique/${profile.id}/$g',
        'name': profile.name,
        'element': profile.element,
        'grade': g,
        'kind': 'technique',
        'description': description,
        'sourceMonster': profile.monster,
        'effects': effects.map((e) => e.toJson()).toList(),
        'willCost': oculumScrollWillCost(g),
        'cooldownTurns': oculumScrollCooldown(g),
      },
    },
  );
}

const oculumMonsterEchoScrolls = [
  (
    id: 'spine_volley',
    name: 'L’ultima Orma del lancio di aculei',
    monster: 'Riccio Aculeo',
    element: 'perforante',
    asset: '',
    condition: '',
  ),
  (
    id: 'spine_precise',
    name: 'L’ultima Orma degli aculei precisi',
    monster: 'Riccio Aculeo',
    element: 'perforante',
    asset: '',
    condition: 'privo_reazioni',
  ),
  (
    id: 'spine_rain',
    name: 'L’ultima Orma della pioggia di aculei',
    monster: 'Riccio Aculeo',
    element: 'perforante',
    asset: '',
    condition: '',
  ),
  (
    id: 'spine_poison',
    name: 'L’ultima Orma degli aculei velenosi',
    monster: 'Riccio Aculeo Velenoso',
    element: 'veleno',
    asset: '',
    condition: 'veleno_putrido',
  ),
  (
    id: 'spine_ice',
    name: 'L’ultima Orma degli aculei di ghiaccio',
    monster: 'Riccio Aculeo di Ghiaccio',
    element: 'ghiaccio',
    asset: '',
    condition: 'gelo',
  ),
  (
    id: 'forest_slam',
    name: 'L’ultima Orma dello schianto del Forest Demon',
    monster: 'Forest Demon',
    element: 'natura',
    asset: 'assets/oculum_dungeon/generated_sprites/enemies/forest_demon.png',
    condition: 'privo_reazioni',
  ),
];

InventoryItem oculumMonsterEchoScrollItem(String id, int grade) {
  final profile = oculumMonsterEchoScrolls.firstWhere((p) => p.id == id);
  final g = grade.clamp(0, 12);
  final rule = switch (id) {
    'spine_precise' =>
      'Tira automaticamente Precisione: Danni +tiro +Oculum ×${1 + g ~/ 3}. Fragilità perforante sul lanciatore per un turno; bersaglio senza reazioni per ${1 + g ~/ 6} turni.',
    'spine_rain' =>
      'Pioggia di 1d${20 + 15 * g} aculei da un danno + Danni normali. Se CM del bersaglio supera il tiro della pergamena, dimezza l’intero totale.',
    'forest_slam' =>
      'Lo schianto infligge Danni +${6 + 5 * g}; il bersaglio colpito perde le reazioni per ${1 + g ~/ 6} turni.',
    _ =>
      'Lancio di aculei: Danni +${2 + 4 * g}.${profile.condition.isEmpty ? '' : ' Applica ${profile.condition} I per un turno, soltanto se colpisce.'}',
  };
  final description =
      'L’orma trasparente di ${profile.monster} compare, compie l’attacco e scompare. $rule Difesa e Scudi restano validi; nessuna evocazione permanente.';
  return InventoryItem(
    nome: '[${profile.name}] [Pergamena] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    elementoDanno: profile.element,
    note:
        '$description\nMonouso. Valore ${oculumScrollValue(g)} Obser. Apprendimento con le regole delle pergamene; non evolvibile.',
    craftData: {
      'scroll': {
        'id': 'echo/$id/$g',
        'echoId': id,
        'echoMonster': profile.monster,
        'echoAsset': profile.asset,
        'condition': profile.condition,
        'grade': g,
        'kind': 'attack',
        'element': profile.element,
        'name': profile.name,
        'description': description,
      },
    },
  );
}

int oculumScrollLearningChance(String difficulty) => switch (difficulty) {
  'facile' => 20,
  'difficile' => 10,
  'oculum' => 5,
  _ => 15,
};

bool oculumScrollCanLearn(
  int natural,
  int total,
  int grade,
  int percentile, {
  String difficulty = 'normale',
}) =>
    natural == 20 &&
    total >= 30 + 10 * grade.clamp(0, 12) &&
    percentile >= 0 &&
    percentile < oculumScrollLearningChance(difficulty);

InventoryItem oculumScrollItem(
  String element,
  String label,
  int grade,
  String kind,
) {
  final g = grade.clamp(0, 12);
  final selectedKind = kind == 'auto'
      ? oculumScrollKindForElement(element)
      : kind;
  final thorns = ['pianta', 'natura', 'radice'].contains(element);
  final name = switch (selectedKind) {
    'control' => 'Rovi di Spine',
    'ward' => 'Bastione di Luce',
    'heal' => 'Pioggia Rigenerante',
    'imprison' => "Gabbia d’Ossa",
    'weaken' => 'Marchio d’Ombra',
    'stun' => 'Saetta Paralizzante',
    _ => element == 'gelo' ? 'Dardo di Ghiaccio' : 'Lancia di $label',
  };
  final description = switch (selectedKind) {
    'control' =>
      '${thorns ? 'Dei rovi si generano sotto' : 'Un vincolo di $label rallenta'} '
          '${g == 0 ? 'un avversario' : 'fino a ${g + 1} avversari'}. '
          'Rallentamento per ${2 + g} turni; ottieni vantaggio +${2 + g} ai tiri '
          'per ${2 + g} tuoi turni.'
          '${g == 0 ? '' : ' Ogni bersaglio subisce ${(g * 50)}% dei tuoi danni.'}',
    'ward' =>
      'Un alleato scelto ottiene ${5 + 2 * g} scudo fino al suo prossimo turno. A ogni grado aggiunge +2 scudo.',
    'heal' =>
      'Cura un bersaglio nella turnistica di ${8 + 4 * g} HP; ogni grado aggiunge 4 HP.',
    'imprison' =>
      'Una gabbia d’ossa magiche si solleva dal terreno e imprigiona un bersaglio per un turno. Ai gradi superiori la gabbia assorbe ${5 + 5 * g} danni prima di cedere.',
    'weaken' =>
      'Il bersaglio scelto subisce -${1 + g ~/ 3} ai tiri fino alla fine del suo prossimo turno; ai gradi superiori il marchio dura ${1 + g ~/ 3} turni.',
    'stun' =>
      'La saetta infligge ${4 + 2 * g} danni e impone -${1 + g ~/ 4} al prossimo tiro del bersaglio.',
    _ =>
      'Dalla mano, senza impugnare la pergamena, lanci un dardo di $label: '
          '1d${8 + 6 * g} danni + i tuoi danni, elemento $label.'
          '${g == 0 ? '' : ' Con critico: ${element == 'gelo' ? 'applica Gelo e ' : ''}+${20 * g}% danni allo scudo.'}',
  };
  final data = <String, dynamic>{
    'id': '$element/$kind/$g',
    'element': element,
    'grade': g,
    'kind': selectedKind,
    'name': name,
    'description': description,
  };
  return InventoryItem(
    nome: '[$name] [Pergamena] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    elementoDanno: element,
    note:
        '$description\nMonouso. Valore: ${oculumScrollValue(g)} Obser. '
        'Con 20 naturale e totale ≥ ${30 + 10 * g}: possibilità di apprendere '
        '(Facile 20%, Medio 15%, Difficile 10%, Oculum 5%) '
        'la skill, non evolvibile. Gli effetti sui bersagli sono dichiarati al Master.',
    craftData: {'scroll': data},
  );
}

extension _OculumScrolls on _OculumHomePageState {
  void showMonsterScrollEcho(String monster, String asset) {
    final assetText = asset.trim().isEmpty ? '' : ' ($asset)';
    aggiungiLog(
      'Orma trasparente evocata: $monster$assetText compie l’attacco e scompare.',
    );
    mostraDadoCentrale(
      valore: monster,
      facce: 20,
      criticoUno: false,
      criticoVenti: false,
    );
  }

  void applyMonsterEchoScrollCondition(
    Map<String, dynamic> data,
    int sheetIndex,
    int grade,
    String source,
  ) {
    final condition = '${data['condition'] ?? ''}'.trim();
    if (condition.isEmpty ||
        sheetIndex < 0 ||
        sheetIndex >= schedePersonaggio.length) {
      return;
    }
    final sheet = schedePersonaggio[sheetIndex];
    final conditions = List<dynamic>.from(
      sheet['conditions'] as List? ?? const [],
    );
    conditions.removeWhere(
      (raw) =>
          raw is Map &&
          raw['conditionType'] == condition &&
          raw['source'] == source,
    );
    conditions.add(
      OculumConditionInstance(
        id: 'echo_${condition}_${DateTime.now().microsecondsSinceEpoch}',
        conditionType: condition,
        category: OculumConditionCategory.special,
        duration: max(1, 1 + grade ~/ 4),
        tickTrigger: OculumConditionTickTrigger.endTurn,
        source: source,
      ).toJson(),
    );
    sheet['conditions'] = conditions;
    aggiungiLog(
      '$source: ${condition.toUpperCase()} applicato a ${nomeSchedaPersonaggio(sheetIndex)} per ${max(1, 1 + grade ~/ 4)} turni.',
    );
    if (modalitaMaster || isMasterHost || realtimeIsMasterRole) {
      sendRealtimeMasterVisibleTokenAt(sheetIndex);
    }
  }

  Future<void> useScrollAbility(
    Map<String, dynamic> data, {
    InventoryItem? item,
  }) async {
    final origin = currentSheetScrollId();
    if (!mounted ||
        (item != null && (!inventario.contains(item) || item.quantita <= 0))) {
      return;
    }
    final g = readIntValue(data['grade']).clamp(0, 12);
    final lastCastRound = readIntValue(
      data['lastCastPersonalTurn'],
      fallback: -999,
    );
    final cooldown = oculumScrollCooldown(g);
    if (item == null && playerReportedTurn < lastCastRound + cooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Pergamena in ricarica fino al round ${lastCastRound + cooldown}.',
              'Scroll is on cooldown until round ${lastCastRound + cooldown}.',
            ),
          ),
        ),
      );
      return;
    }
    final cost = oculumScrollWillCost(g);
    if (currentVolonta() < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Volontà insufficiente: costo $cost.',
              'Not enough Will: cost $cost.',
            ),
          ),
        ),
      );
      return;
    }
    final targetKind =
        const {
          'attack',
          'heal',
          'imprison',
          'control',
          'weaken',
          'stun',
        }.contains('${data['kind']}') ||
        ('${data['kind']}' == 'ward' &&
            masterInitiativeTokens.any(
              (token) => masterInitiativeSheetIndexForToken(token) >= 0,
            ));
    final targets = targetKind
        ? await _selectScrollTargets('${data['kind']}', g)
        : <int>[];
    if (!mounted ||
        (item == null && currentSheetScrollId() != origin) ||
        (item != null && !inventario.contains(item)) ||
        (targetKind && targets.isEmpty)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${data['name']} · Grado ${data['grade']}'),
        content: SingleChildScrollView(
          child: Text(
            '${data['description']}\n\n${item == null ? 'Skill appresa, non evolvibile.' : 'Consuma una pergamena. Possibilità di apprendimento: ${oculumScrollLearningChance(normalizedCampaignDifficulty())}% con 20 naturale e totale ≥ ${30 + 10 * readIntValue(data['grade'])}.'}'
            '\nCosto: $cost Volontà · CD ${oculumScrollDifficulty(g)} · ricarica ${oculumScrollCooldown(g)} turni. '
            'Il tiro usa Volontà, bonus e Oculum preparato. Il Master vede risultato e bersagli.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usa e tira'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        (item == null && currentSheetScrollId() != origin) ||
        (item != null && (!inventario.contains(item) || item.quantita <= 0))) {
      return;
    }
    currentVolontaController.text = '${currentVolonta() - cost}';
    final natural = tiraD20();
    final spend = consumaOculumTiro();
    final bonus =
        volontaTotale() +
        runtimeQuickBonus('tiro_volonta') +
        tiroGlobaleBonus() +
        spend.bonus;
    final total = rollTotalWithCritical(natural, 20, [bonus]);
    final success =
        natural != 1 &&
        total >= oculumScrollDifficulty(g) &&
        (slotMachineRollsEnabled
            ? resolveSlotMachineSuccess(naturalRoll: natural)
            : total > 0);
    final formula = rollFormulaWithCritical(
      roll: natural,
      faces: 20,
      bonuses: [bonus],
    );
    final kind = '${data['kind']}';
    final source = 'pergamena/${data['element']}/$kind';
    var outcome = success
        ? '${data['description']}'
        : 'Tiro fallito: nessun effetto.';
    var resolvedAttackDamage = 0;
    if (success && kind == 'technique') {
      final effects = oculumReadStructuredEffects(data['effects']);
      outcome +=
          '\n${applyStructuredEffectsOnActivation(effects, source: source).join("\n")}';
    }
    if (success && kind == 'attack') {
      final faces = 8 + 6 * g;
      final damage = Random.secure().nextInt(faces) + 1;
      resolvedAttackDamage = damage + dannoTotale();
      if (data['echoId'] != null) {
        final echo = '${data['echoId']}';
        if (echo == 'spine_precise') {
          var precision = 0;
          await tiraSottotrattoOcchio(
            hiddenEyeStats.firstWhere((s) => s.id == 'precisione'),
            actionLabel: '${data['name']}',
            onResolved: (_, value) => precision = value,
          );
          resolvedAttackDamage =
              dannoTotale() + precision + oculumTotale() * (1 + g ~/ 3);
          activeStructuredEffects.add({
            'effectId': 'spine_piercing_weakness',
            'source': source,
            'type': 'elemental_resistance',
            'element': 'perforante',
            'preset': 'Fragilità',
            'remaining': 1,
            'unit': 'turni',
          });
        } else if (echo == 'spine_rain') {
          resolvedAttackDamage =
              dannoTotale() + Random.secure().nextInt(20 + 15 * g) + 1;
        } else {
          resolvedAttackDamage =
              dannoTotale() + (echo == 'forest_slam' ? 6 + 5 * g : 2 + 4 * g);
        }
        showMonsterScrollEcho('${data['echoMonster']}', '${data['echoAsset']}');
      }
      outcome +=
          '\nDanni risolti: $resolvedAttackDamage '
          '(${elementDisplayName('${data['element']}')}).';
      if (natural == 20 && g > 0) {
        outcome +=
            '\nDanni allo scudo con critico: ${((damage + dannoTotale()) * (1 + .2 * g)).ceil()}.';
      }
      if (natural != 20) outcome += ' Effetti da critico non attivati.';
    } else if (success && kind == 'control' && g > 0) {
      outcome +=
          '\nDanni per bersaglio: ${(dannoTotale() * g * .5).ceil()}. Il Master conferma i bersagli.';
    }
    var learned = '';
    setState(() {
      dadoMostrato = formula;
      dadoMostratoFacce = 20;
      tiroCriticoUno = natural == 1;
      tiroCriticoVenti = natural == 20;
      slotMachineLastSucceeded = success;
      if (item != null) {
        item.quantita--;
        if (item.quantita == 0) inventario.remove(item);
        aggiungiLog(
          'Pergamena consumata: ${data['name']}. Esemplari rimasti: ${item.quantita}. L’uso non assegna automaticamente la skill.',
        );
      }
      if (success && (kind == 'ward' || kind == 'control')) {
        activeStructuredEffects.removeWhere(
          (effect) => effect['source'] == source,
        );
        activeStructuredEffects.add({
          'source': source,
          'target': kind == 'ward' ? 'difesa' : 'tiro_globale',
          'value': kind == 'ward' ? 3 + 3 * g : 2 + g,
          'remaining': 1 + g ~/ 3,
          'unit': 'turn',
          'frequency': '',
          'type': 'bonus',
          'stackable': false,
        });
      }
      if (item != null && natural == 20 && total >= 30 + 10 * g) {
        final percentile = Random.secure().nextInt(100);
        final chance = oculumScrollLearningChance(
          normalizedCampaignDifficulty(),
        );
        if (oculumScrollCanLearn(
          natural,
          total,
          g,
          percentile,
          difficulty: normalizedCampaignDifficulty(),
        )) {
          if (!skills.any((skill) => skill.scrollData['id'] == data['id'])) {
            skills.add(
              CharacterSkill(
                nome: '${data['name']} [Grado $g]',
                tipo: 'Attiva',
                costo: '$cost VOL',
                cooldown: '${oculumScrollCooldown(g)}',
                descrizione:
                    '${data['description']}\nAppresa da pergamena: non evolvibile.',
                scrollData: Map<String, dynamic>.from(data),
              ),
            );
            learned =
                '\nSkill appresa (d100 ${percentile + 1} ≤ $chance), non evolvibile.';
          } else {
            learned = '\nSkill già appresa: nessun duplicato.';
          }
        } else {
          learned = '\nSkill non appresa (d100 ${percentile + 1} > $chance).';
        }
      }
      risultato =
          '${data['name']} [Grado $g]: $formula.${oculumTiroLogLabel(spend)}\n$outcome$learned';
      aggiungiLog(risultato);
    });
    if (success) {
      for (final sheetIndex in targets) {
        switch (kind) {
          case 'attack':
            applyMasterEnemyQuickHpAction(
              sheetIndex,
              damage: resolvedAttackDamage,
            );
            if (data['echoId'] != null) {
              applyMonsterEchoScrollCondition(data, sheetIndex, g, source);
            }
            break;
          case 'heal':
            applyMasterEnemyQuickHpAction(sheetIndex, heal: 8 + 4 * g);
            break;
          case 'ward':
            final shield = sheetIntValueAt(sheetIndex, 'scudo');
            setMasterEnemyLayerValue(sheetIndex, 'scudo', shield + 5 + 2 * g);
            break;
          case 'imprison':
          case 'control':
          case 'weaken':
          case 'stun':
            final tokenIndex = masterInitiativeTokens.indexWhere(
              (token) =>
                  masterInitiativeSheetIndexForToken(token) == sheetIndex,
            );
            if (tokenIndex >= 0) {
              final token = masterInitiativeTokens[tokenIndex];
              final effects = List<Map<String, dynamic>>.from(
                (token['scrollEffects'] as List? ?? const [])
                    .whereType<Map>()
                    .map((effect) => Map<String, dynamic>.from(effect)),
              );
              final oldNotes = effects
                  .where((effect) => '${effect['source']}' == source)
                  .map((effect) => '${effect['note'] ?? ''}')
                  .where((note) => note.isNotEmpty)
                  .toSet();
              effects.removeWhere((effect) => '${effect['source']}' == source);
              final duration = kind == 'imprison' ? 1 : 1 + g ~/ 3;
              final effectNote =
                  '${data['name']} · ${kind == 'imprison' ? 'imprigionato per 1 turno' : 'effetto per $duration turni'}';
              effects.add({
                'source': source,
                'name': '${data['name']}',
                'kind': kind,
                'remainingTurns': duration,
                'magnitude': 1 + g,
                'note': effectNote,
                if (kind == 'imprison') 'barrierHp': 5 + 5 * g,
              });
              token['scrollEffects'] = effects;
              final existing = '${token['notes'] ?? ''}'
                  .split('\n')
                  .where((line) => !oldNotes.contains(line))
                  .join('\n')
                  .trim();
              token['notes'] = [
                if (existing.isNotEmpty) existing,
                effectNote,
              ].join('\n');
            }
            break;
        }
      }
      if (kind == 'attack' && resolvedAttackDamage > 0) {
        final resolvedElement = oculumCombatElementId('${data['element']}');
        oculumCombatTheme.resolveOutgoingAction(
          actionId:
              'scroll-${data['id']}-$masterInitiativeRound-${DateTime.now().microsecondsSinceEpoch}',
          hitDamageByElement: [
            for (var index = 0; index < targets.length; index++)
              <String, int>{resolvedElement: resolvedAttackDamage},
          ],
        );
        oculumCombatTheme.react(
          natural == 20 ? 'critical' : 'outgoing',
          elementId: resolvedElement,
        );
      } else if (kind == 'heal') {
        oculumCombatTheme.react('heal');
      } else if (kind == 'ward') {
        oculumCombatTheme.react('shield');
      } else if (kind == 'imprison' || kind == 'control' || kind == 'stun') {
        oculumCombatTheme.react('open', elementId: '${data['element']}');
      }
    }
    if (item == null) {
      data['lastCastRound'] = masterInitiativeRound;
      data['lastCastPersonalTurn'] = playerReportedTurn;
    }
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    notifyDiceResultChanged();
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    mostraDadoCentrale(
      valore: formula,
      criticoUno: natural == 1,
      criticoVenti: natural == 20,
    );
    sendRealtimeDiceRoll(
      label: risultato,
      roll: natural,
      bonus: total - natural,
      total: total,
      forceMasterVisible: true,
    );
    programmaSalvataggio();
  }

  Future<List<int>> _selectScrollTargets(String kind, int grade) async {
    final options = <({int sheet, String name})>[];
    for (final token in masterInitiativeTokens) {
      final sheet = masterInitiativeSheetIndexForToken(token);
      if (sheet < 0 || options.any((option) => option.sheet == sheet)) continue;
      options.add((
        sheet: sheet,
        name: '${token['name'] ?? nomeSchedaPersonaggio(sheet)}',
      ));
    }
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Aggiungi prima i bersagli alla turnistica.',
              'Add targets to initiative first.',
            ),
          ),
        ),
      );
      return [];
    }
    final selected = <int>{};
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t('Scegli bersaglio', 'Choose target')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    CheckboxListTile(
                      value: selected.contains(option.sheet),
                      title: Text(option.name),
                      onChanged: (value) => update(() {
                        if (value == true) {
                          selected.add(option.sheet);
                        } else {
                          selected.remove(option.sheet);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected.toList()),
              child: Text(t('Conferma', 'Confirm')),
            ),
          ],
        ),
      ),
    );
    return result ?? const [];
  }
}
