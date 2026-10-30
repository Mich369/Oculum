part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumArmadilloStateIsClosed(
  Map state, {
  required String fightKey,
  required int currentHp,
}) =>
    currentHp > 0 &&
    fightKey.isNotEmpty &&
    state['fightKey'] == fightKey &&
    state['closed'] == true;

/// Pure public projection: no hidden weak point or state from a past fight.
List<Map<String, dynamic>> oculumArmadilloPrecisionParts(
  Iterable<Map<String, dynamic>> parts, {
  required bool closed,
}) => [
  for (final part in parts)
    if (!closed || part['hiddenWhileArmadilloClosed'] != true)
      Map<String, dynamic>.from(part),
];

extension _OculumArmadilloCreatures on _OculumHomePageState {
  bool get isArmadilloCreature => oculumArmadilloSpeciesIds.contains(
    faunaCurrentMonsterId.split('_variante_').first,
  );

  String get armadilloFightKey {
    final tag = sheetTagAt(schedaCorrente);
    final token = onlineCombatTokens()
        .where((t) => combatTokenMatchesSheet(t, tag))
        .firstOrNull;
    return '$onlineCombatEncounterId:${token?['fightInstanceId'] ?? ''}';
  }

  Map<String, dynamic> get armadilloState => Map<String, dynamic>.from(
    planarState['armadillo'] is Map
        ? planarState['armadillo'] as Map
        : const {},
  );

  bool get armadilloClosed =>
      isArmadilloCreature &&
      currentCombatIsActive() &&
      !outsideFight &&
      oculumArmadilloStateIsClosed(
        armadilloState,
        fightKey: armadilloFightKey,
        currentHp: hpCorrenti(),
      );

  int get armadilloCmBonus =>
      armadilloClosed ? max(0, readIntValue(armadilloState['cmBonus'])) : 0;

  Map<String, dynamic> get armadilloPublicState => {
    'closed': armadilloClosed,
    'cmBonus': armadilloCmBonus,
    'fightKey': armadilloFightKey,
  };

  /// Call before the cost dialog and again before paying. This does not spend
  /// A/R: the ordinary utility/payment transaction consumes exactly one pool.
  bool armadilloCanUseAbility(Iterable<OculumStructuredEffect> effects) {
    final targets = effects
        .where((e) => e.enabled)
        .map((e) => e.target)
        .toSet();
    if (!targets.any((target) => target.startsWith('armadillo_'))) return true;
    if (!isArmadilloCreature ||
        !currentCombatIsActive() ||
        outsideFight ||
        hpCorrenti() <= 0) {
      return false;
    }
    if (targets.contains('armadillo_roll_up') && armadilloClosed) return false;
    if ((targets.contains('armadillo_uncurl') ||
            targets.contains('armadillo_closed_required')) &&
        !armadilloClosed) {
      return false;
    }
    return true;
  }

  bool activateArmadilloEffect(OculumStructuredEffect effect, int value) {
    if (effect.target == 'armadillo_closed_required') return true;
    if (!const {
      'armadillo_roll_up',
      'armadillo_uncurl',
    }.contains(effect.target)) {
      return false;
    }
    if (!armadilloCanUseAbility([effect])) return true;
    final closed = effect.target == 'armadillo_roll_up';
    planarState['armadillo'] = {
      ...armadilloState,
      'fightKey': armadilloFightKey,
      'closed': closed,
      'cmBonus': closed ? max(0, value) : 0,
      'lastChangedPersonalTurn': playerReportedTurn,
    };
    invalidateDerivedDataCaches();
    for (final token in _writableOnlineCombatTokens().where(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    )) {
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? {}),
        'armadillo': armadilloPublicState,
      };
      token['precisionBodyParts'] = publicPrecisionBodyParts;
    }
    aggiungiLog(
      closed
          ? '[APPALLOTTOLAMENTO] +$value CM finché chiuso; rotolamento e '
                'speronamento restano possibili. Una sola Azione o Reazione.'
          : '[APPALLOTTOLAMENTO] Carapace riaperto; bonus CM terminato.',
    );
    programmaSalvataggio();
    notifyDiceResultChanged();
    return true;
  }
}

/// Low-grade, species-specific materials; the old generic material drops remain
/// unchanged. The dedicated loot builder carries weight and crafting metadata.
const oculumArmadilloMaterials = <OculumAuthoredMaterial>[
  OculumAuthoredMaterial(
    'placche_di_armadillo',
    'Placche di armadillo',
    0,
    .1,
    .6,
    15,
    'Placche cornee elastiche per giunti e protezioni: +1 Difesa '
        'all’equipaggiamento in cui vengono lavorate.',
    passive: '@Difesa+1',
  ),
  OculumAuthoredMaterial(
    'placche_sabbiose_di_armadillo',
    'Placche sabbiose di armadillo',
    0,
    .1,
    .6,
    15,
    'Placche ruvide che distribuiscono gli urti: +4 Scudo '
        'all’equipaggiamento in cui vengono lavorate.',
    passive: '@Scudo+4',
  ),
  OculumAuthoredMaterial(
    'quarzo_corazzato_di_armadillo',
    'Quarzo corazzato di armadillo',
    0,
    .1,
    .6,
    20,
    'Facce di quarzo basso e opaco: +2 Danni Roccia '
        'all’equipaggiamento in cui vengono lavorate.',
    passive: '@Danni+2 roccia',
  ),
  OculumAuthoredMaterial(
    'corteccia_flessibile_di_armadillo',
    'Corteccia flessibile di armadillo',
    0,
    .1,
    .6,
    15,
    'Fibre e corteccia vive per imbottiture leggere: +3 Scudo '
        'all’equipaggiamento in cui vengono lavorate.',
    passive: '@Scudo+3',
  ),
];

InventoryItem? oculumArmadilloMaterialDrop(
  String dropName, {
  required int level,
  required int grade,
  required String receiptId,
  required Map<String, dynamic> metadata,
}) {
  final material = oculumArmadilloMaterials
      .where(
        (m) => oculumNormalizeText(m.name) == oculumNormalizeText(dropName),
      )
      .firstOrNull;
  if (material == null) return null;
  final safeLevel = max(0, level);
  final safeGrade = grade.clamp(0, 12).toInt();
  return InventoryItem(
    nome: material.name,
    peso: .2,
    quantita: 1,
    livelloOggetto: safeLevel,
    gradoOggetto: safeGrade,
    gradoRichiesto: safeGrade,
    note:
        'Materiale (200 g). ${material.effect} '
        'Livello $safeLevel, Grado $safeGrade. Minimo d’inserimento 50 g; '
        'la lavorazione resta soggetta alle regole del fabbro.',
    craftData: {
      'material': material.id,
      'materialLevel': safeLevel,
      'materialGrade': safeGrade,
      'materialStrength': 2 + safeGrade * 3 + safeLevel ~/ 3,
      'inlayMinimumGrams': 50,
      'grams': 200,
      'effect': material.effect,
      'passiveBuff': material.passive,
    },
    monsterLoot: {
      ...metadata,
      'id': receiptId,
      'material': true,
      'weaponBonus': safeLevel,
      'armorBonus': safeGrade,
    },
  );
}
