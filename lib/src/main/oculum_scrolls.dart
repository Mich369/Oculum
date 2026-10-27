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

/// A grade difference lowers the Black Market corruption scroll by 20 points
/// per grade. Equal-grade and weaker targets start at 100%; five grades above
/// the scroll leaves no chance.
int oculumCorruptionScrollChance({
  required int scrollGrade,
  required int targetGrade,
}) => (100 - 20 * max(0, targetGrade - scrollGrade)).clamp(0, 100).toInt();

int oculumCorruptionChanceAfterResistance({
  required int chancePercent,
  required num resistancePercent,
}) =>
    (chancePercent.clamp(0, 100) *
            (100 - resistancePercent.clamp(0, 100)) /
            100)
        .floor();

int oculumFightStartCooldownSecondsRemaining({
  required DateTime? fightStartedAt,
  required int cooldownTurns,
  required int secondsPerTurn,
  DateTime? now,
}) {
  final turns = max<int>(0, cooldownTurns);
  final seconds = max<int>(0, secondsPerTurn);
  if (fightStartedAt == null) return turns * seconds;
  final total = turns * seconds;
  final elapsed = max(
    0,
    (now ?? DateTime.now()).difference(fightStartedAt).inSeconds,
  );
  return max<int>(0, total - elapsed);
}

/// Chosen initial price for this rare Black Market-only scroll. The offer keeps
/// the cost in its editable merchant profile, so a Master can tune it.
int oculumCorruptionScrollPrice(int grade) => 24000 + 2000 * grade.clamp(0, 12);

const int oculumCorruptionMasteryResistancePercent = 50;
const int oculumCorruptionMasteryTargetControlPercent = 90;

int oculumCorruptionRequiredFullHits({
  required int sourceLevel,
  required int targetLevel,
}) => max(0, targetLevel - sourceLevel);

bool oculumCanResistCorruption({
  required int targetLevel,
  required int sourceLevel,
}) => targetLevel >= sourceLevel;

int oculumCorruptionDefensePenalty({
  required int targetLevel,
  required int sourceLevel,
}) => targetLevel == sourceLevel ? 3 : 0;

bool oculumCorruptionDefenseSucceeds({
  required int targetLevel,
  required int sourceLevel,
  required int defenseTotal,
  required int sourceTotal,
}) =>
    oculumCanResistCorruption(
      targetLevel: targetLevel,
      sourceLevel: sourceLevel,
    ) &&
    defenseTotal -
            oculumCorruptionDefensePenalty(
              targetLevel: targetLevel,
              sourceLevel: sourceLevel,
            ) >=
        sourceTotal;

bool oculumIsCorruptionMastery(CharacterSkill skill) =>
    skill.scrollData['kind'] == 'corruption' ||
    oculumNormalizeText(skill.nome) == 'padrone della corruzione';

int oculumCorruptionMasteryBonus(Iterable<CharacterSkill> source) {
  final skill = source.where(oculumIsCorruptionMastery).firstOrNull;
  if (skill == null) return 0;
  return max(
    0,
    readIntValue(
      skill.scrollData['resistancePercent'],
      fallback: oculumCorruptionMasteryResistancePercent,
    ),
  );
}

double oculumCorruptionTotalResistance({
  required double existingResistancePercent,
  required int masteryBonusPercent,
}) => max(0.0, existingResistancePercent) + max(0, masteryBonusPercent);

InventoryItem oculumCorruptionScrollItem(int grade) {
  final g = grade.clamp(0, 12).toInt();
  const description =
      'Marchio di Corruzione · pergamena d’attacco monouso. In battaglia scegli un mostro: la possibilità di infettarlo è 100%; ogni Grado del mostro sopra il Grado della pergamena riduce la possibilità di 20 punti percentuali, fino a 0%. Un grado pari o inferiore non riduce la possibilità. La skill appresa, Padrone della Corruzione, aggiunge +50 punti percentuali alla resistenza alla Corruzione già presente e non ha altre forme.';
  final effects = oculumScrollCombatEffects({
    'grade': g,
    'kind': 'corruption',
  }).map((effect) => effect.toJson()).toList();
  return InventoryItem(
    nome: '[Marchio di Corruzione] [Pergamena d’attacco] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    elementoDanno: 'corruzione',
    note:
        '$description\nCosto iniziale: ${oculumCorruptionScrollPrice(g)} Obser, modificabile dal Master. La pergamena è venduta solo al Mercato Nero.',
    craftData: {
      'scroll': {
        'id': 'corruption/$g',
        'name': 'Padrone della Corruzione',
        'element': 'corruzione',
        'grade': g,
        'kind': 'corruption',
        'scrollCategory': 'attack',
        'description': description,
        'willCost': 0,
        'cooldownTurns': 2,
        'cooldownStart': 'fight_start',
        'preselectOutsideFight': true,
        'cooldownSecondsPerTurn': 6,
        'resistancePercent': oculumCorruptionMasteryResistancePercent,
        'targetControlPercent': oculumCorruptionMasteryTargetControlPercent,
        'effects': effects,
      },
    },
  );
}

int oculumGratitudineNextActionBonus(int grade) {
  final value = grade.clamp(0, 12).toInt();
  return value == 0 ? 1 : value * 6;
}

List<OculumStructuredEffect> oculumScrollCombatEffects(
  Map<String, dynamic> data, {
  int? resolvedDamage,
}) {
  final configured = oculumReadStructuredEffects(data['effects']);
  if (configured.isNotEmpty) {
    for (final effect in configured.where((e) => e.type == 'preparazione')) {
      effect.sourceScrollGrade = data['learned'] == true
          ? 0
          : readIntValue(data['grade']).clamp(0, 12);
    }
    return configured;
  }
  final g = readIntValue(data['grade']).clamp(0, 12);
  final kind = '${data['kind']}';
  final duration = kind == 'imprison' ? 1 : 1 + g ~/ 3;
  final effects = <OculumStructuredEffect>[];
  if (kind == 'gratitudine') {
    effects.addAll([
      OculumStructuredEffect(
        id: 'gratitudine_fast_reaction_$g',
        type: 'aggiungi_reazioni_rapide',
        target: 'reazione_veloce',
        recipient: 'alleato',
        valueExpression: '1',
        duration: '1',
        durationUnit: 'turni',
        mode: 'temporaneo',
        stackable: true,
      ),
      OculumStructuredEffect(
        id: 'gratitudine_next_action_$g',
        type: 'modifica_sottotratto',
        target: 'tiro_globale',
        recipient: 'alleato',
        valueExpression: '${oculumGratitudineNextActionBonus(g)}',
        duration: '1',
        durationUnit: 'azioni',
        mode: 'prossima_azione',
        stackable: true,
      ),
    ]);
  } else if (kind == 'corruption') {
    effects.add(
      OculumStructuredEffect(
        id: 'corruption_scroll_infection',
        type: 'stato',
        recipient: 'nemico',
        appliedState: 'corruzione',
        valueExpression: '1',
        duration: '0',
        durationUnit: 'turni',
        resource: 'corruption_scroll:$g',
        stackable: false,
      ),
    );
  } else if (kind == 'attack') {
    effects.add(
      OculumStructuredEffect(
        type: 'danno',
        recipient: 'bersaglio',
        valueExpression: resolvedDamage == null
            ? '1d${8 + 6 * g}+danni'
            : '$resolvedDamage',
        elementType: '${data['element'] ?? 'fisico'}',
      ),
    );
  } else if (kind == 'shadow_clone') {
    effects.add(
      OculumStructuredEffect(
        id: 'shadow_living_$g',
        type: 'evocazione',
        target: 'clone_ombra',
        recipient: 'se_stesso',
        valueExpression: 'livello*5',
        mode: 'immediato',
        duration: '${g * 2 + 3}',
        durationUnit: 'turni',
        narrativeText: '${data['description'] ?? 'Ombra viva'}',
      ),
    );
  } else if (kind == 'heal' || kind == 'ward') {
    effects.add(
      OculumStructuredEffect(
        type: kind == 'heal' ? 'cura' : 'scudo',
        recipient: 'alleato',
        resource: 'vita',
        valueExpression: '${kind == 'heal' ? 8 + 4 * g : 5 + 2 * g}',
      ),
    );
  } else if (const {'imprison', 'control', 'weaken', 'stun'}.contains(kind)) {
    effects.add(
      OculumStructuredEffect(
        type: 'stato',
        recipient: 'bersaglio',
        appliedState: switch (kind) {
          'imprison' => 'immobilizzato',
          'control' => 'rallentato',
          'weaken' => 'indebolito',
          _ => 'stordito',
        },
        valueExpression: '${1 + g}',
        duration: '$duration',
      ),
    );
    if (kind == 'control' && g > 0) {
      effects.add(
        OculumStructuredEffect(
          type: 'danno',
          recipient: 'bersaglio',
          valueExpression: 'danni*$g*0.5',
          elementType: '${data['element']}',
        ),
      );
    }
  }
  if (kind == 'attack' && '${data['condition'] ?? ''}'.isNotEmpty) {
    effects.add(
      OculumStructuredEffect(
        type: 'stato',
        recipient: 'bersaglio',
        appliedState: '${data['condition']}',
        valueExpression: '1',
        duration: '${max(1, 1 + g ~/ 4)}',
      ),
    );
  }
  return effects.isNotEmpty
      ? effects
      : oculumResolveAbilityEffects([], '${data['description'] ?? ''}');
}

Set<OculumCombatAbilityRole> oculumScrollCombatRoles(
  Map<String, dynamic> data,
  Iterable<OculumStructuredEffect> effects,
) {
  switch ('${data['kind'] ?? ''}') {
    case 'gratitudine':
    case 'utility':
    case 'heal':
      return {OculumCombatAbilityRole.support};
    case 'ward':
      return {OculumCombatAbilityRole.defense};
    case 'corruption':
      return {OculumCombatAbilityRole.attack};
    case 'attack':
    case 'imprison':
    case 'control':
    case 'weaken':
    case 'stun':
      return {OculumCombatAbilityRole.attack};
    case 'technique':
      final active = effects.where((effect) => effect.enabled).toList();
      if (active.any(
        (effect) =>
            const {'danno', 'danno_percentuale'}.contains(effect.type) ||
            effect.recipient == 'nemico' && effect.type == 'stato',
      )) {
        return {OculumCombatAbilityRole.attack};
      }
      if (active.any(
        (effect) => const {
          'difesa',
          'scudo',
          'hp_temporanei',
          'elemental_resistance',
        }.contains(effect.type),
      )) {
        return {OculumCombatAbilityRole.defense};
      }
      return {OculumCombatAbilityRole.support};
    default:
      return oculumCombatAbilityRoles(effects);
  }
}

InventoryItem oculumGratitudineScrollItem(int grade) {
  final g = grade.clamp(0, 12).toInt();
  final bonus = oculumGratitudineNextActionBonus(g);
  final description =
      'Scroll di utility Reazione Fulminea. Scegli uno o più partecipanti alla turnistica: ciascuno riceve una Reazione Fulminea aggiuntiva e ottiene +$bonus alla prossima azione. Al Grado 0 il bonus è +1; dagli altri gradi è Grado × 6. Se impari la skill, non puoi selezionare te stesso: ha ricarica di 1 tuo turno e costa una Reazione, oppure la tua Azione se la usi nel tuo turno. Quando la risorsa rimane disponibile, il log riporta “Provi Gratitudine”.';
  return InventoryItem(
    nome: '[Reazione Fulminea] [Pergamena utility] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    note:
        '$description\nMonouso. Costo ${oculumScrollWillCost(g)} Volontà; DT ${oculumScrollDifficulty(g)}; valore ${oculumScrollValue(g)} Obser.',
    craftData: {
      'scroll': {
        'id': 'reazione_fulminea/$g',
        'name': 'Reazione Fulminea',
        'element': 'utility',
        'grade': g,
        'kind': 'gratitudine',
        'scrollCategory': 'utility',
        'description': description,
        'willCost': oculumScrollWillCost(g),
        'cooldownTurns': 1,
        'effects': oculumScrollCombatEffects({
          'grade': g,
          'kind': 'gratitudine',
          'description': description,
        }).map((effect) => effect.toJson()).toList(),
      },
    },
  );
}

InventoryItem oculumShadowLivingScrollItem(int grade) {
  final g = grade.clamp(0, 12).toInt();
  final duration = g * 2 + 3;
  final description =
      'Evoca una scheda Clone d’ombra alleata con Vita pari a 5 × il tuo livello; copia le tue statistiche tranne Resilienza. Dura $duration turni. Se sei in una turnistica online, la scheda viene inviata al Master e l’ingresso resta soggetto alla conferma della turnistica.';
  return InventoryItem(
    nome: '[Ombra viva] [Pergamena] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    note:
        '$description\nMonouso. Costo ${oculumScrollWillCost(g)} Volontà; CD ${oculumScrollDifficulty(g)}; ricarica ${oculumScrollCooldown(g)} turni. Valore ${oculumScrollValue(g)} Obser.',
    craftData: {
      'scroll': {
        'id': 'ombra_viva/$g',
        'name': 'Ombra viva',
        'element': 'ombra',
        'grade': g,
        'kind': 'shadow_clone',
        'description': description,
        'willCost': oculumScrollWillCost(g),
        'cooldownTurns': oculumScrollCooldown(g),
        'effects': oculumScrollCombatEffects({
          'grade': g,
          'kind': 'shadow_clone',
          'description': description,
        }).map((effect) => effect.toJson()).toList(),
      },
    },
  );
}

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
  final realmProfiles = <OculumTechniqueScrollProfile>[
    for (final spec in [
      ('raggio_angelico', 'Raggio Angelico', 'araldo_raggio_angelico', 0),
      ('richiamo_piranha', 'Richiamo dei Piranha', 'piranha_mortale', 2),
    ])
      OculumTechniqueScrollProfile(
        spec.$1,
        spec.$2,
        monsterBookEntryById(spec.$3)!.nameIt,
        monsterBookEntryById(spec.$3)!.elementId,
        oculumMonsterBookArt(
          monsterBookEntryById(spec.$3)!,
        ).skills[spec.$4].effettiEvoluzione(1),
      ),
  ];
  final result = <OculumTechniqueScrollProfile>[
    ...oculumPreparedScrollProfiles(),
  ];
  final names = {
    ...result.map((p) => oculumNormalizeText(p.name)),
    ...realmProfiles.map((p) => oculumNormalizeText(p.name)),
    'richiamo dei piccoli',
  };
  for (final monster in defaultMonsterBookEntries.where((m) => !m.isNpc)) {
    final skills = oculumMonsterBookSkills(monster);
    final ids = monsterBookUsableSkillIds(
      monster,
    ).where((id) => oculumMonsterTechniqueIsNatural(monster, id)).toList();
    for (final (index, skill) in skills.indexed) {
      final name = skill.nome.trim();
      if (skill.tipo.toLowerCase().contains('passiv') ||
          name.isEmpty ||
          names.contains(oculumNormalizeText(name))) {
        continue;
      }
      final effects = skill.forme.first.effettiStrutturati
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
                  'aggiungi_reazioni_rapide',
                }.contains(effect.type),
          )
          .toList();
      if (effects.isEmpty) continue;
      names.add(oculumNormalizeText(name));
      result.add(
        OculumTechniqueScrollProfile(
          '${monster.id}_${index < ids.length ? ids[index] : index}',
          name,
          monster.nameIt,
          monster.elementId,
          effects,
        ),
      );
    }
  }
  return List<OculumTechniqueScrollProfile>.unmodifiable([
    ...result,
    ...realmProfiles,
  ]);
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
        if (original.type == 'preparazione') 'sourceScrollGrade': g,
        'recipient': 'se_stesso',
        'valueExpression':
            '(${original.valueExpression.replaceAll("oculum_spent", "${g + 1}")})*(1+$g/10)',
        'diceExpression': original.diceExpression,
        'mode':
            const {
              'cura',
              'scudo',
              'hp_temporanei',
              'costrutto',
            }.contains(original.type)
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
      'L’impronta di ${profile.monster} prepara ${profile.name}. Gli effetti seguenti sono applicati al lanciatore; i bonus di attacco valgono per il prossimo attacco, le cure sono immediate. La pergamena contiene ${g + 1} Oculum impresso: non richiede una spesa Oculum aggiuntiva.\n${effects.map(oculumStructuredEffectDescription).join("\n")}${const {'raggio_angelico', 'richiamo_piranha'}.contains(profile.id) ? '\n${profile.effects.map((e) => e.narrativeText).where((s) => s.isNotEmpty).toSet().join('\n')}' : ''}';
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

int oculumScrollLearningDifficulty(
  int scrollGrade, {
  int skillLevel = 0,
  int characterLevel = 0,
}) =>
    30 +
    10 * scrollGrade.clamp(0, 12) +
    2 * max(0, skillLevel - characterLevel);

Color oculumScrollLearningColor(int chance) => switch (chance) {
  <= 20 => Colors.redAccent,
  <= 40 => Colors.deepOrangeAccent,
  <= 55 => Colors.yellowAccent,
  <= 74 => const Color(0xffc6e35a),
  _ => Colors.greenAccent,
};

int oculumScrollLearningChance(
  String difficulty, {
  int bonusPercent = 0,
  int luck = 0,
  int characterGrade = 0,
  bool matchingElement = false,
}) {
  final base = switch (difficulty) {
    'facile' => 20,
    'difficile' => 10,
    'oculum' => 5,
    _ => 15,
  };
  return (base +
          bonusPercent.clamp(0, 3) +
          max(0, luck) +
          (matchingElement ? 15 : 0))
      .clamp(0, characterGrade >= 9 ? 90 : 75)
      .toInt();
}

bool oculumScrollCanLearn(
  int natural,
  int total,
  int grade,
  int percentile, {
  String difficulty = 'normale',
  int bonusPercent = 0,
  int luck = 0,
  int characterGrade = 0,
  int skillLevel = 0,
  int characterLevel = 0,
  bool matchingElement = false,
}) =>
    natural == 20 &&
    total >=
        oculumScrollLearningDifficulty(
          grade,
          skillLevel: skillLevel,
          characterLevel: characterLevel,
        ) &&
    percentile >= 0 &&
    percentile <
        oculumScrollLearningChance(
          difficulty,
          bonusPercent: bonusPercent,
          luck: luck,
          characterGrade: characterGrade,
          matchingElement: matchingElement,
        );

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
  int get scrollLearningLuck {
    final stat = hiddenEyeStats.where((s) => s.id == 'fortuna').firstOrNull;
    return oculumScrollLuck(
      stat == null ? 0 : hiddenEyeTotal(stat),
      rebirthed: rebirthato,
    );
  }

  bool scrollMatchesUsableElement(Map<String, dynamic> data) {
    final wanted = oculumNormalizeElementId('${data['element'] ?? ''}');
    if (wanted.isEmpty) return false;
    final elements = <String>{
      oculumNormalizeElementId(elementoDannoDominante()),
    };
    void addEffects(Iterable<OculumStructuredEffect> effects) {
      for (final effect in effects.where(
        (e) => e.enabled && e.elementType.trim().isNotEmpty,
      )) {
        elements.add(oculumNormalizeElementId(effect.elementType));
      }
    }

    final level = leggiNumero(livelloController);
    for (final item in inventario.where(
      (i) => i.equipaggiata && canEquipInventoryItem(i),
    )) {
      if (item.arma) {
        elements.add(oculumNormalizeElementId(item.elementoDanno));
      }
      for (final form in item.ability?.forme ?? <CharacterSkillForm>[]) {
        if (readIntValue(form.livello) <= level) {
          addEffects(form.effettiStrutturati);
        }
      }
    }
    for (final skill in skills.where((s) => s.equipaggiata)) {
      for (final form in skill.forme) {
        if (readIntValue(form.livello) <= level) {
          addEffects(form.effettiStrutturati);
        }
      }
    }
    for (final art in arti.where((a) => a.sbloccata)) {
      for (final skill in art.skills) {
        for (var form = 1; form <= artMaxLevel(art); form++) {
          final required =
              int.tryParse(
                RegExp(
                      r'Richiede livello\s+(\d+)',
                      caseSensitive: false,
                    ).firstMatch(skill.testoEvoluzione(form))?.group(1) ??
                    '',
              ) ??
              0;
          if (required <= level) addEffects(skill.effettiEvoluzione(form));
        }
      }
    }
    return elements.contains(wanted);
  }

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
    final learningDifficulty = oculumScrollLearningDifficulty(
      g,
      skillLevel: readIntValue(data['skillLevel']),
      characterLevel: leggiNumero(livelloController),
    );
    final learningBonus = currentCombatIsActive()
        ? Random.secure().nextInt(3) + 1
        : 0;
    final learningLuck = scrollLearningLuck;
    final learningGrade = activeCriticalGrade();
    final elementAffinity = scrollMatchesUsableElement(data);
    final previewChance = oculumScrollLearningChance(
      normalizedCampaignDifficulty(),
      bonusPercent: learningBonus,
      luck: learningLuck,
      characterGrade: learningGrade,
      matchingElement: elementAffinity,
    );
    final kind = '${data['kind']}';
    if (kind == 'corruption' && !currentCombatIsActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La pergamena si usa durante uno scontro.'),
        ),
      );
      return;
    }
    if (item == null &&
        oculumScrollCombatEffects(data).any((e) => e.type == 'preparazione')) {
      await useLearnedPreparedSkill(data);
      return;
    }
    if (item == null && kind == 'gratitudine') {
      await _useLearnedGratitudine(data);
      return;
    }
    final lastCastRound = readIntValue(
      data['lastCastPersonalTurn'],
      fallback: -999,
    );
    final cooldown = max(
      0,
      readIntValue(data['cooldownTurns'], fallback: oculumScrollCooldown(g)),
    );
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
    final cost = max(
      0,
      readIntValue(data['willCost'], fallback: oculumScrollWillCost(g)),
    );
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
    final gratitudeTargets = kind == 'gratitudine'
        ? await _selectScrollSupportTargets(excludeSelf: false)
        : <String>[];
    final targetKind =
        const {
          'attack',
          'corruption',
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
    final onlineFight =
        realtimeService?.isConnected == true &&
        onlineCombatTokens().any(
          (token) => onlineCombatTokenTag(token) == sheetTagAt(schedaCorrente),
        );
    final targets = targetKind && !onlineFight
        ? await _selectScrollTargets('${data['kind']}', g)
        : <int>[];
    final onlineCorruptionTarget = kind == 'corruption' && onlineFight
        ? await _selectOnlineCorruptionTarget()
        : null;
    if (!mounted ||
        (item == null && currentSheetScrollId() != origin) ||
        (item != null && !inventario.contains(item)) ||
        (targetKind && !onlineFight && targets.isEmpty) ||
        (kind == 'corruption' &&
            onlineFight &&
            onlineCorruptionTarget == null) ||
        (kind == 'gratitudine' && gratitudeTargets.isEmpty)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${data['name']} · Grado ${data['grade']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item != null && kind != 'corruption') ...[
                Text(
                  'Apprendimento $previewChance%',
                  style: TextStyle(
                    color: oculumScrollLearningColor(previewChance),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Fortuna +$learningLuck${elementAffinity ? ' · Elemento utilizzabile +15' : ''}${learningBonus > 0 ? ' · Battaglia +$learningBonus' : ''} · Limite ${learningGrade >= 9 ? 90 : 75}%',
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '${data['description']}\n\n${kind == 'corruption' ? 'La pergamena non richiede una prova di attivazione né Volontà. La possibilità indicata dipende solo dal Grado del bersaglio e dalla sua eventuale resistenza alla Corruzione.' : 'Consuma una pergamena. Per apprendere serve 20 naturale e totale ≥ $learningDifficulty: +2 DT per ogni livello richiesto dalla skill sopra il tuo.\nCosto: $cost Volontà · DT attivazione ${oculumScrollDifficulty(g)} · ricarica $cooldown turni. Il tiro usa Volontà, bonus e Oculum preparato.'} Il Master vede il risultato e i bersagli.',
              ),
            ],
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
    if (kind == 'corruption' &&
        currentCombatIsActive() &&
        !await spendCombatRollResource()) {
      return;
    }
    if (currentCombatIsActive() &&
        oculumScrollCombatEffects(data).any((e) => e.type == 'preparazione') &&
        !await requestUtilitySpend('azione')) {
      return;
    }
    currentVolontaController.text = '${currentVolonta() - cost}';
    final natural = tiraD20();
    final concentrationPreparation = oculumScrollCombatEffects(
      data,
    ).any((e) => e.type == 'preparazione');
    final spend = concentrationPreparation
        ? (spent: 0, bonus: 0, damageBonus: 0)
        : consumaOculumTiro();
    final bonus =
        volontaTotale() +
        runtimeQuickBonus('tiro_volonta') +
        tiroGlobaleBonus() +
        consumeCombatHelp() +
        spend.bonus;
    final total = rollTotalWithCritical(natural, 20, [bonus]);
    final success =
        kind == 'corruption' ||
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
    final source = 'pergamena/${data['element']}/$kind';
    var outcome = success
        ? '${data['description']}'
        : 'Tiro fallito: nessun effetto.';
    var resolvedAttackDamage = 0;
    if (success &&
        const {'technique', 'shadow_clone', 'gratitudine'}.contains(kind)) {
      final effects = oculumScrollCombatEffects(data)
          .map(
            (effect) => OculumStructuredEffect.fromJson(
              effect.toJson(),
            )..recipient = kind == 'gratitudine' ? 'alleato' : effect.recipient,
          )
          .toList();
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
      if (item != null && natural == 20 && total >= learningDifficulty) {
        final percentile = Random.secure().nextInt(100);
        final chance = oculumScrollLearningChance(
          normalizedCampaignDifficulty(),
          bonusPercent: learningBonus,
          luck: learningLuck,
          characterGrade: learningGrade,
          matchingElement: elementAffinity,
        );
        if (oculumScrollCanLearn(
          natural,
          total,
          g,
          percentile,
          difficulty: normalizedCampaignDifficulty(),
          bonusPercent: learningBonus,
          luck: learningLuck,
          characterGrade: learningGrade,
          matchingElement: elementAffinity,
          skillLevel: readIntValue(data['skillLevel']),
          characterLevel: leggiNumero(livelloController),
        )) {
          if (!skills.any((skill) => skill.scrollData['id'] == data['id'])) {
            skills.add(
              data['authoredSkill'] is Map
                  ? CharacterSkill.fromJson({
                      ...Map<String, dynamic>.from(
                        data['authoredSkill'] as Map,
                      ),
                      'scrollData': {
                        ...Map<String, dynamic>.from(data),
                        'learned': true,
                      },
                      'equipaggiata': true,
                    })
                  : CharacterSkill(
                      nome: '${data['name']} [Grado $g]',
                      tipo: kind == 'corruption' ? 'Passiva' : 'Attiva',
                      costo:
                          oculumScrollCombatEffects(
                            data,
                          ).any((e) => e.type == 'preparazione')
                          ? '2/2 Oculum'
                          : kind == 'corruption'
                          ? '0'
                          : kind == 'gratitudine'
                          ? '1 Reazione / Azione'
                          : '$cost VOL',
                      cooldown: kind == 'corruption'
                          ? '2 turni dallo scontro'
                          : '$cooldown',
                      descrizione:
                          '${data['description']}\nAppresa da pergamena: non evolvibile.${kind == 'corruption' ? '\nPassiva: resistenza alla Corruzione; al colpo pieno infetta i mostri di livello superiore. Ricarica iniziale: 2 turni dallo scontro (12 secondi a 6 secondi per turno). Il proprietario sceglie il bersaglio nel 90% degli attacchi del mostro corrotto.' : ''}',
                      scrollData: {
                        ...Map<String, dynamic>.from(data),
                        'learned': true,
                      },
                    ),
            );
            learned =
                '\nSkill appresa (d100 ${percentile + 1} ≤ $chance), non evolvibile.';
            if (data['authoredOpen'] is Map) {
              final open = CharacterArt.fromJson(
                Map<String, dynamic>.from(data['authoredOpen'] as Map),
              );
              if (!arti.any((a) => a.openName == open.openName)) {
                open.nome = 'Open appresa · ${open.openName}';
                arti.add(open);
              }
            }
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
    if (success && kind == 'corruption' && onlineFight) {
      final targetTag = onlineCorruptionTarget!;
      if (realtimeIsMasterRole) {
        _applyCorruptionToInitiativeTag(
          targetTag,
          scrollGrade: g,
          corruptorTag: sheetTagAt(schedaCorrente),
          sourceName: '${data['name']}',
          sourceTotal: total,
          sourceLevel: leggiNumero(livelloController),
        );
      } else {
        final request = <String, dynamic>{
          'id':
              'corruption:${sheetTagAt(schedaCorrente)}:${DateTime.now().microsecondsSinceEpoch}',
          'encounterId': onlineCombatEncounterId,
          'sourceTag': sheetTagAt(schedaCorrente),
          'sourceName': realtimeDisplayName(),
          'targetTag': targetTag,
          'scrollGrade': g,
          'source': 'scroll',
          'attack': total,
          'level': leggiNumero(livelloController),
          'scope': permissionScope,
          'kind': 'corruption',
          'status': 'pending',
        };
        attachPendingCombatTurnResources(request);
        onlineCombatRequests['${request['id']}'] = request;
        final sent = await realtimeService?.sendCombatEvent(
          'corruption_apply',
          permissionEnvelope(request),
        );
        aggiungiLog(
          sent == true
              ? '[CORRUZIONE] Richiesta inviata al Master per ${onlineCorruptionTargetName(targetTag)}.'
              : '[CORRUZIONE] Invio al Master non confermato; la richiesta non è stata applicata.',
        );
      }
    }
    if (success && kind == 'gratitudine') {
      await deliverPendingSupport(
        minimum: 1,
        maximum: gratitudeTargets.length,
        selectedTags: gratitudeTargets,
        sourcePrefix: source,
      );
    } else if (success &&
        onlineFight &&
        !const {'technique', 'shadow_clone', 'corruption'}.contains(kind)) {
      final effects = oculumScrollCombatEffects(
        data,
        resolvedDamage: max(0, resolvedAttackDamage - bonusDannoPiatto()),
      );
      for (final message in applyStructuredEffectsOnActivation(
        effects,
        source: '${data['name']} · Scroll',
      )) {
        aggiungiLog(message);
      }
      await finishParsedAbilityTargets(
        '${data['description'] ?? ''}',
        attackTotal: total,
        natural: natural,
      );
    } else if (success &&
        onlineFight &&
        const {'technique', 'shadow_clone'}.contains(kind)) {
      final hasPendingAttack = activeStructuredEffects.any(
        (effect) =>
            effect['type'] == 'pending_target' &&
            effect['effect'] is Map &&
            (effect['effect'] as Map)['recipient'] != 'alleato',
      );
      await finishParsedAbilityTargets(
        '${data['description'] ?? ''}',
        attackTotal: total,
        natural: natural,
      );
      if (!hasPendingAttack &&
          oculumCombatAbilityRoles(
            oculumScrollCombatEffects(data),
          ).contains(OculumCombatAbilityRole.attack) &&
          onlineAttackTokens().isNotEmpty) {
        await planOnlineAttack(
          preparedAttackTotal: total,
          preparedAttackNatural: natural,
        );
      }
    }
    if (success && !onlineFight) {
      for (final sheetIndex in targets) {
        switch (kind) {
          case 'corruption':
            queueCorruptionApplication(
              targetTag: sheetTagAt(sheetIndex),
              scrollGrade: g,
              sourceTag: sheetTagAt(schedaCorrente),
              sourceName: '${data['name']}',
              sourceTotal: total,
              sourceLevel: leggiNumero(livelloController),
            );
            break;
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
      if (kind == 'corruption' &&
          ('${token['side'] ?? ''}' != 'enemy' ||
              const {'dead', 'fled', 'expired'}.contains(token['status']))) {
        continue;
      }
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

  Future<String?> _selectOnlineCorruptionTarget() async {
    final own = sheetTagAt(schedaCorrente);
    final ownSide = onlineCombatTokens()
        .where((token) => onlineCombatTokenTag(token) == own)
        .firstOrNull?['side'];
    final targets = onlineCombatTokens().where((token) {
      if (const {'dead', 'fled', 'expired'}.contains(token['status'])) {
        return false;
      }
      if ('${token['side'] ?? ''}' == '${ownSide ?? 'ally'}') return false;
      return true;
    }).toList();
    if (targets.isEmpty) return null;
    return showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Marchio di Corruzione · scegli un bersaglio'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final token in targets)
                ListTile(
                  title: Text('${token['name'] ?? 'Mostro'}'),
                  subtitle: Text(
                    'Livello ${readIntValue(token['level'])} · Grado ${readIntValue(token['grade'])}',
                  ),
                  onTap: () =>
                      Navigator.pop(dialog, onlineCombatTokenTag(token)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }

  String onlineCorruptionTargetName(String tag) =>
      onlineCombatTokens()
          .where((token) => onlineCombatTokenTag(token) == tag)
          .firstOrNull?['name']
          ?.toString() ??
      tag;

  double oculumCorruptionResistanceInSheet(Map<String, dynamic> sheet) {
    final rawSkills = sheet['skills'];
    final savedSkills = rawSkills is List
        ? rawSkills.whereType<Map>().map(
            (raw) => CharacterSkill.fromJson(Map<String, dynamic>.from(raw)),
          )
        : const <CharacterSkill>[];
    final presets = sheet['incomingDamagePresets'] is Map
        ? sheet['incomingDamagePresets'] as Map
        : const {};
    final percentages = sheet['dannoSubitoPercentualePerTipo'] is Map
        ? sheet['dannoSubitoPercentualePerTipo'] as Map
        : const {};
    final custom =
        percentages['corrotto'] ??
        percentages['corruzione'] ??
        (presets.isEmpty && percentages.isEmpty
            ? sheet['dannoSubitoPercentuale']
            : null);
    final multiplier =
        oculumIncomingDamagePercentMultiplier('${custom ?? ''}') ??
        modificatoreDannoDaNome(
          '${presets['corrotto'] ?? presets['corruzione'] ?? 'Normale'}',
        ).multiplier;
    return oculumCorruptionTotalResistance(
      existingResistancePercent: (1 - multiplier) * 100,
      masteryBonusPercent: oculumCorruptionMasteryBonus(savedSkills),
    );
  }

  double currentCorruptionResistancePercent() {
    final multiplier =
        oculumIncomingDamagePercentMultiplier(
          configuredIncomingDamagePercentForType('corrotto'),
        ) ??
        modificatoreDannoDaNome(
          configuredIncomingDamagePreset('corrotto'),
        ).multiplier;
    return oculumCorruptionTotalResistance(
      existingResistancePercent: (1 - multiplier) * 100,
      masteryBonusPercent: oculumCorruptionMasteryBonus(skills),
    );
  }

  void _writeCorruptionConditionToSheet(
    Map<String, dynamic> sheet, {
    required String corruptorTag,
    required int chancePercent,
    required String sourceName,
    int controlChancePercent = oculumCorruptionMasteryTargetControlPercent,
    Map<String, dynamic>? metadata,
  }) {
    final conditions = List<dynamic>.from(
      sheet['conditions'] as List? ?? const [],
    );
    conditions.removeWhere(
      (raw) => raw is Map && raw['conditionType'] == 'corruzione',
    );
    conditions.add(
      OculumConditionInstance(
        id: 'corruzione_${DateTime.now().microsecondsSinceEpoch}',
        conditionType: 'corruzione',
        category: OculumConditionCategory.special,
        duration: 0,
        durationType: OculumConditionDurationType.permanent,
        source: sourceName,
        metadata: {
          ...?metadata,
          'corruptedByTag': corruptorTag,
          'targetControlChancePercent': controlChancePercent.clamp(0, 100),
          'infectionChancePercent': chancePercent,
        },
      ).toJson(),
    );
    sheet['conditions'] = conditions;
  }

  void _applyCorruptionToInitiativeTag(
    String targetTag, {
    required int scrollGrade,
    required String corruptorTag,
    required String sourceName,
    required int sourceTotal,
    required int sourceLevel,
  }) {
    queueCorruptionApplication(
      targetTag: targetTag,
      scrollGrade: scrollGrade,
      sourceTag: corruptorTag,
      sourceName: sourceName,
      sourceTotal: sourceTotal,
      sourceLevel: sourceLevel,
    );
  }

  Future<List<String>> _selectScrollSupportTargets({
    required bool excludeSelf,
  }) async {
    final own = sheetTagAt(schedaCorrente);
    final online = realtimeService?.isConnected == true;
    final rawTokens = online ? onlineCombatTokens() : masterInitiativeTokens;
    final candidates = <({String tag, String name})>[];
    for (final token in rawTokens) {
      if (const {'dead', 'fled', 'expired'}.contains(token['status'])) continue;
      final index = online
          ? localSheetIndexForOculumTag(onlineCombatTokenTag(token))
          : masterInitiativeSheetIndexForToken(token);
      if (!online && masterInitiativeTokens.isNotEmpty && index < 0) continue;
      final tag = online && !realtimeIsMasterRole
          ? onlineCombatTokenTag(token)
          : publicInitiativeSourceTag(token);
      if (tag.isEmpty || candidates.any((entry) => entry.tag == tag)) continue;
      candidates.add((
        tag: tag,
        name:
            '${token['name'] ?? (index >= 0 ? nomeSchedaPersonaggio(index) : '???')}',
      ));
    }
    if (candidates.isEmpty && !online) {
      for (var index = 0; index < schedePersonaggio.length; index++) {
        if (schedePersonaggio[index]['realtimeSharedSheet'] == true) continue;
        candidates.add((
          tag: sheetTagAt(index),
          name: nomeSchedaPersonaggio(index),
        ));
      }
    }
    final selectable = candidates
        .where(
          (entry) => entry.tag.isNotEmpty && (!excludeSelf || entry.tag != own),
        )
        .toList();
    if (selectable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            excludeSelf
                ? 'Nessun altro partecipante può ricevere Reazione Fulminea.'
                : 'Non ci sono partecipanti selezionabili.',
          ),
        ),
      );
      return [];
    }
    final selected = <String>{};
    return await showDialog<List<String>>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
              title: const Text('Reazione Fulminea · destinatari'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in selectable)
                        CheckboxListTile(
                          value: selected.contains(entry.tag),
                          title: Text(
                            entry.tag == own
                                ? '${entry.name} · tu'
                                : entry.name,
                          ),
                          onChanged: (value) => update(() {
                            if (value == true) {
                              selected.add(entry.tag);
                            } else {
                              selected.remove(entry.tag);
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
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, selected.toList()),
                  child: const Text('Conferma'),
                ),
              ],
            ),
          ),
        ) ??
        <String>[];
  }

  bool _gratitudineResourceAvailable() {
    if (!currentCombatIsActive()) return false;
    final online = realtimeService?.isConnected == true;
    final tokens = online ? onlineCombatTokens() : masterInitiativeTokens;
    final own = sheetTagAt(schedaCorrente);
    final index = tokens.indexWhere(
      (token) =>
          (online && !realtimeIsMasterRole
              ? onlineCombatTokenTag(token)
              : publicInitiativeSourceTag(token)) ==
          own,
    );
    if (index < 0) return false;
    final activeIndex = online && !realtimeIsMasterRole
        ? readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex'])
        : masterInitiativeActiveIndex;
    final token = tokens[index];
    if (index == activeIndex &&
        !readBoolValue(token['actionUsed']) &&
        artDebtForToken(token, 'action') <= 0) {
      return true;
    }
    final round = online && !realtimeIsMasterRole
        ? readIntValue(realtimeVisibleInitiativeSnapshot['round'])
        : masterInitiativeRound;
    return masterInitiativeReactionAvailable(
          token,
          round: round,
          turnKey: '$round',
        ) >
        0;
  }

  Future<void> _useLearnedGratitudine(Map<String, dynamic> data) async {
    final origin = currentSheetScrollId();
    const cooldown = 1;
    final lastTurn = readIntValue(data['lastCastPersonalTurn'], fallback: -999);
    if (playerReportedTurn < lastTurn + cooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reazione Fulminea in ricarica fino al tuo turno ${lastTurn + cooldown}.',
          ),
        ),
      );
      return;
    }
    final targets = await _selectScrollSupportTargets(excludeSelf: true);
    if (!mounted || currentSheetScrollId() != origin || targets.isEmpty) return;
    if (!_gratitudineResourceAvailable()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Serve un’Azione disponibile nel tuo turno o una Reazione.',
          ),
        ),
      );
      return;
    }
    final grade = readIntValue(data['grade']).clamp(0, 12).toInt();
    final bonus = oculumGratitudineNextActionBonus(grade);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reazione Fulminea'),
        content: Text(
          'Ogni partecipante selezionato riceve una Reazione Fulminea aggiuntiva e +$bonus alla prossima azione. Non puoi selezionare te stesso. Ricarica: 1 tuo turno. Costo: una Reazione o la tua Azione se è il tuo turno. Nel 6% dei casi la risorsa resta disponibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Usa skill'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        currentSheetScrollId() != origin ||
        !_gratitudineResourceAvailable()) {
      return;
    }
    final retainsResource = Random.secure().nextInt(100) < 6;
    if (!retainsResource && !await spendCombatRollResource()) return;
    if (!mounted || currentSheetScrollId() != origin) return;

    data['lastCastPersonalTurn'] = playerReportedTurn;
    data['lastCastRound'] = masterInitiativeRound;
    final effects = oculumScrollCombatEffects(data)
        .map(
          (effect) =>
              OculumStructuredEffect.fromJson(effect.toJson())
                ..recipient = 'alleato',
        )
        .toList();
    for (final message in applyStructuredEffectsOnActivation(
      effects,
      source: 'Reazione Fulminea',
    )) {
      aggiungiLog(message);
    }
    if (retainsResource) aggiungiLog('Provi Gratitudine');
    await deliverPendingSupport(
      minimum: 1,
      maximum: targets.length,
      selectedTags: targets,
      excludeSelf: true,
      sourcePrefix: 'Reazione Fulminea',
    );
    if (!mounted || currentSheetScrollId() != origin) return;
    aggiungiLog(
      'Reazione Fulminea: ${targets.length} partecipanti selezionati · +$bonus alla prossima azione.',
    );
    salvaSchedaCorrenteInMemoria();
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    if (mounted) setState(() {});
  }
}
