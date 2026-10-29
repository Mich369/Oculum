import 'dart:convert';
import 'dart:math' as math;

/// Generic targeted-part damage. It never applies body damage, changes rewards,
/// invents a weak point, or resolves a special creature's native part mechanics.
/// Call once, after the defender has settled Defense and all Shields, with the
/// final receipt's hpLost. The normal attack has already damaged the body.
const oculumAnatomicalPartStateVersion = 1;

int _partInt(Object? value, [int fallback = 0]) => value is num
    ? value.isFinite
          ? value.toInt()
          : fallback
    : int.tryParse('$value') ?? fallback;

/// Length-delimited JSON encoding avoids source/id delimiter collisions.
/// Identity validation still belongs to the authenticated combat receiver.
String oculumAnatomicalAttackReceiptId({
  required String sourceTag,
  required String targetTag,
  required String attackId,
}) => sourceTag.trim().isEmpty || targetTag.trim().isEmpty || attackId.isEmpty
    ? ''
    : jsonEncode([
        sourceTag.trim().toUpperCase(),
        targetTag.trim().toUpperCase(),
        attackId,
      ]);

Map<String, dynamic> _partMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Numerical defaults are editable balance data, not a second source of body
/// locations. The caller must supply the creature's actual, saved anatomy.
const oculumAnatomicalPartDefaultFractions = <String, double>{
  'body': 1,
  'torso': .60,
  'belly': .40,
  'head': .35,
  'eyes': .08,
  'arms': .30,
  'hands': .20,
  'legs': .35,
  'wings': .25,
  'tail': .25,
  'root': .35,
  'tentacles': .30,
  'tendrils': .30,
  'antennae': .10,
  'gills': .15,
  'joint': .20,
  'sensor': .10,
  'horns': .20,
  'sac': .20,
  'runes': .15,
  'wound': .20,
  'rim': .20,
  'fold': .25,
};

/// Conservative material recognition from PHYSICAL description only. An
/// armored humanoid is not made of metal merely because it wears armor.
String oculumAnatomicalPartMaterial({
  required String monsterId,
  required String physicalDescription,
  required Map part,
}) {
  if ('${part['material'] ?? ''}'.isNotEmpty) return '${part['material']}';
  final text = physicalDescription.toLowerCase();
  bool has(String pattern) => RegExp(pattern).hasMatch(text);
  if (monsterId == 'pawn_guardiano' ||
      has(
        r'corpo (?:interamente )?(?:meccanico|metallico|di metallo)|automa|robot',
      )) {
    return 'metal';
  }
  if (monsterId == 'pinepine' ||
      monsterId.contains('bramble') ||
      has(
        r'corpo (?:di legno|vegetale)|mostro di legno|pelle di corteccia|pigna umanoide|busto di corteccia|radici viventi|pianta carnivora',
      )) {
    return 'wood';
  }
  if (has(
    r'corpo (?:di pietra|minerale|di cristallo)|(?:colosso|golem|creatura) di (?:pietra|cristallo|vetro)',
  )) {
    return 'stone';
  }
  if (has(r'slime|corpo gelatinoso|melma viva|massa gelatinosa')) return 'gel';
  if (has(r'senza corpo|corpo incorporeo|spettro|fantasma')) return 'spectral';
  if (monsterId.contains('grofix') ||
      has(r'corpo fungino|fungo vivente|muschio vivente')) {
    return 'fiber';
  }
  if (has(r'esoscheletro|insetto|scorpione|ragno|coleottero')) return 'chitin';
  return 'flesh';
}

/// Native mechanics take precedence. Core/heart/mask parts are conservative
/// delegates even for an unknown custom species: a generic HP pool must never
/// invent how a construct dies, how an Art breaks, or expose a hidden core.
bool oculumAnatomicalPartIsNative({
  required String monsterId,
  required Map part,
  bool constructCore = false,
  bool senkaMask = false,
}) {
  final id = '${part['id'] ?? ''}';
  final group = '${part['group'] ?? id}';
  if (part['nativeMechanic'] == true || part['genericPartHp'] == false) {
    return true;
  }
  if (id.startsWith('art_') || part['artKind'] != null) return true;
  if (id.startsWith('lunar_crystal_') || id == 'fairy_core') return true;
  if (const {'core', 'heart', 'mask'}.contains(group) ||
      const {'core', 'heart', 'mask'}.contains(id)) {
    return true;
  }
  if (constructCore && id.contains('core')) return true;
  if (senkaMask && (id.contains('mask') || group == 'mask')) return true;
  if (const {
        'guardian_lunare',
        'guardian_lunare_diabolico',
        'guardian_devil_moon',
        'guardiano_lunare',
      }.contains(monsterId) &&
      const {'armor', 'corazza', 'chest', 'torso', 'core'}.contains(id)) {
    return true;
  }
  if (monsterId == 'nuvola_in_bottiglia' &&
      (id.contains('bottle') || id.contains('bottiglia'))) {
    return true;
  }
  if (monsterId.contains('saltalungo_maculato') && group == 'tail') return true;
  return false;
}

List<String> oculumAnatomicalPartAffectedRolls(
  String group, {
  bool locomotor = false,
}) => switch (locomotor ? 'legs' : group) {
  'arms' || 'hands' => [
    'vc',
    'attacco',
    'precisione',
    'forza',
    'schianto',
    'fermezza',
    'meccanica',
    'crafting',
    'cm',
  ],
  'legs' ||
  'root' ||
  'tentacles' => ['riflessi', 'iniziativa', 'movimento', 'agilita'],
  'eyes' || 'sensor' || 'antennae' => ['percezione', 'investigazione'],
  _ => [],
};

String oculumAnatomicalInjuryLabel(String material) => switch (material) {
  'wood' || 'fiber' => 'Fibre lacerate',
  'metal' => 'Meccanismo danneggiato',
  'stone' || 'crystal' => 'Crepa strutturale',
  'chitin' => 'Carapace lesionato',
  'gel' => 'Massa destabilizzata',
  'spectral' => 'Contorno disperso',
  _ => 'Lesione',
};

/// Catalogue/row defaults are merged before explicit sheet overrides. Unknown
/// keys survive, so editor extensions and user JSON are not discarded.
Map<String, dynamic> oculumAnatomicalPartRule({
  required String monsterId,
  required String physicalDescription,
  required Map part,
  required int maximumBodyHp,
  Map overrides = const {},
}) {
  final group = '${part['group'] ?? part['id'] ?? ''}';
  final authored = <String, dynamic>{
    ..._partMap(part['integrity']),
    ...Map<String, dynamic>.from(overrides),
  };
  final material = oculumAnatomicalPartMaterial(
    monsterId: monsterId,
    physicalDescription: physicalDescription,
    part: {
      ...part,
      if (authored.containsKey('material')) 'material': authored['material'],
    },
  );
  final rule = <String, dynamic>{
    'enabled': true,
    'id': part['id'],
    'label': part['label'],
    'group': group,
    'material': material,
    'maximumHpFraction': oculumAnatomicalPartDefaultFractions[group] ?? .30,
    'minimumHp': 1,
    'criticalCanInjure': true,
    'legacyCriticalFracture':
        material == 'flesh' && const {'arms', 'legs'}.contains(group),
    'injuryLabel': material == 'flesh' && const {'arms', 'legs'}.contains(group)
        ? 'Frattura'
        : oculumAnatomicalInjuryLabel(material),
    'rollPenalty': 1,
    'affectedRolls': oculumAnatomicalPartAffectedRolls(
      group,
      locomotor: part['locomotor'] == true,
    ),
    'recovery': group == 'wings' ? 'long_rest' : 'appropriate_treatment',
    'revealsPartIds': <String>[],
    ...authored,
  };
  // Changing integrity cannot rename a physical limb or manufacture anatomy.
  rule['id'] = part['id'];
  rule['group'] = group;
  final fractionValue = rule['maximumHpFraction'];
  final parsedFraction = fractionValue is num
      ? fractionValue.toDouble()
      : double.tryParse('$fractionValue') ?? .30;
  final fraction = parsedFraction.isFinite && parsedFraction >= 0
      ? parsedFraction
      : .30;
  final minimum = math.max(1, _partInt(rule['minimumHp'], 1));
  rule['maximumHp'] = math.max(
    minimum,
    rule.containsKey('maximumHp')
        ? _partInt(rule['maximumHp'], minimum)
        : (math.max(1, maximumBodyHp) * math.max(0.0, fraction)).ceil(),
  );
  return rule;
}

class OculumAnatomicalPartHit {
  const OculumAnatomicalPartHit({
    required this.state,
    this.applied = false,
    this.duplicate = false,
    this.hpLost = 0,
    this.remainingHp = 0,
    this.becameInjured = false,
    this.reachedZero = false,
    this.validCritical = false,
    this.revealPartIds = const [],
  });
  final Map<String, dynamic> state;
  final bool applied, duplicate, becameInjured, reachedZero, validCritical;
  final int hpLost, remainingHp;
  final List<String> revealPartIds;
}

/// The attack ID belongs to the individual hit, not a multi-hit attack group.
/// Receipts are never cleared on repair/rest: replay cannot rebreak a healed
/// part. No source-state list or Map is mutated, including immutable snapshots.
OculumAnatomicalPartHit oculumApplyAnatomicalPartHit({
  required Map state,
  required Map rule,
  required String attackId,
  required int hpLost,
  required bool critical,
  required bool criticalShieldProtected,
}) {
  final next = <String, dynamic>{...Map<String, dynamic>.from(state)};
  final id = '${rule['id'] ?? ''}';
  if (id.isEmpty || attackId.isEmpty || rule['enabled'] == false) {
    return OculumAnatomicalPartHit(state: next);
  }
  final receipts = _partMap(next['receipts']);
  if (receipts.containsKey(attackId)) {
    return OculumAnatomicalPartHit(state: next, duplicate: true);
  }
  receipts[attackId] = id;
  next['receipts'] = receipts;
  next['version'] = oculumAnatomicalPartStateVersion;
  if (hpLost <= 0) return OculumAnatomicalPartHit(state: next);
  final parts = _partMap(next['parts']);
  final previous = _partMap(parts[id]);
  // Freeze each pool at first real damage. Temporary body-HP buffs, a form
  // toggle, or a catalogue update cannot silently regenerate a damaged part.
  final maximum = math.max(
    1,
    previous['recalibrateMaximumOnNextHit'] == true
        ? _partInt(rule['maximumHp'], 1)
        : _partInt(previous['maximumHp'], _partInt(rule['maximumHp'], 1)),
  );
  final oldDamage = _partInt(previous['damageTaken']).clamp(0, maximum).toInt();
  final damage = math.min(maximum, oldDamage + hpLost);
  final validCritical =
      critical &&
      !criticalShieldProtected &&
      rule['criticalCanInjure'] != false;
  final wasInjured = previous['injured'] == true;
  final injured = wasInjured || validCritical || damage >= maximum;
  final reachedZero = oldDamage < maximum && damage >= maximum;
  parts[id] = <String, dynamic>{
    ...previous,
    'maximumHp': maximum,
    'recalibrateMaximumOnNextHit': false,
    'damageTaken': damage,
    'injured': injured,
    'label': '${rule['label'] ?? id}',
    'group': '${rule['group'] ?? id}',
    'material': '${rule['material'] ?? 'flesh'}',
    'recovery': '${rule['recovery'] ?? 'appropriate_treatment'}',
    'rollPenalty': math.max(0, _partInt(rule['rollPenalty'])),
    'affectedRolls': rule['affectedRolls'] is List
        ? (rule['affectedRolls'] as List).map((r) => '$r').toList()
        : <String>[],
    'legacyCriticalFracture': rule['legacyCriticalFracture'] == true,
    'injuryLabel': '${rule['injuryLabel'] ?? 'Lesione'}',
  };
  next['parts'] = parts;
  return OculumAnatomicalPartHit(
    state: next,
    applied: true,
    hpLost: damage - oldDamage,
    remainingHp: maximum - damage,
    becameInjured: !wasInjured && injured,
    reachedZero: reachedZero,
    validCritical: validCritical,
    revealPartIds: !reachedZero || rule['revealsPartIds'] is! List
        ? const []
        : (rule['revealsPartIds'] as List).map((p) => '$p').toList(),
  );
}

/// Recovery is explicit. The caller must authorize appropriate treatment or a
/// Master repair; an ordinary HP heal/Short Rest/fight end is never enough.
Map<String, dynamic> oculumRepairAnatomicalPart({
  required Map state,
  required String partId,
  required String method,
  required String receiptId,
}) {
  final next = Map<String, dynamic>.from(state);
  final parts = _partMap(next['parts']);
  final previous = _partMap(parts[partId]);
  if (receiptId.isEmpty || previous.isEmpty) return next;
  final receipts = _partMap(next['repairReceipts']);
  if (receipts.containsKey(receiptId)) return next;
  final allowed =
      method == 'master_repair' ||
      method == 'appropriate_treatment' ||
      method == 'long_rest' && previous['recovery'] == 'long_rest';
  if (!allowed) return next;
  parts[partId] = {
    ...previous,
    'damageTaken': 0,
    'injured': false,
    'recalibrateMaximumOnNextHit': true,
  };
  receipts[receiptId] = partId;
  next['parts'] = parts;
  next['repairReceipts'] = receipts;
  return next;
}

/// Non-bony injuries do not become the Frattura condition. A distinct, modest
/// penalty applies only to configured relevant rolls, capped at three. Native
/// fractures are left to the existing condition to avoid counting them twice.
int oculumAnatomicalPartRollPenalty(Map state, String roll) {
  final key = roll.trim().toLowerCase();
  final parts = _partMap(state['parts']);
  var penalty = 0;
  for (final value in parts.values.whereType<Map>()) {
    if (value['injured'] != true ||
        value['legacyCriticalFracture'] == true ||
        '${value['group']}' == 'wings') {
      continue;
    }
    final rawRolls = value['affectedRolls'];
    final rolls = (rawRolls is List ? rawRolls : const []).map(
      (v) => '$v'.toLowerCase(),
    );
    if (rolls.contains(key)) {
      penalty += math.max(0, _partInt(value['rollPenalty']));
    }
  }
  return penalty.clamp(0, 3).toInt();
}

/// Safe display projection. Full config, damage receipts, weak flags and reveal
/// links stay private. A broadcast caller must use the default false and an
/// explicit allowlist of already-known physical parts; a private owner/Master
/// editor can request all ordinary part statuses. It never exposes native cores.
List<Map<String, dynamic>> oculumPublicAnatomicalPartStatus({
  required Map state,
  Iterable<String> knownPartIds = const [],
  bool ownerOrMaster = false,
}) {
  final allowed = knownPartIds.toSet();
  final parts = _partMap(state['parts']);
  return [
    for (final entry in parts.entries)
      if ((ownerOrMaster || allowed.contains(entry.key)) &&
          entry.value is Map &&
          !oculumAnatomicalPartIsNative(
            monsterId: '',
            part: {...(entry.value as Map), 'id': entry.key},
          ))
        {
          'id': entry.key,
          'maximumHp': math.max(1, _partInt(entry.value['maximumHp'], 1)),
          'remainingHp':
              (_partInt(entry.value['maximumHp'], 1) -
                      _partInt(entry.value['damageTaken']))
                  .clamp(0, math.max(1, _partInt(entry.value['maximumHp'], 1))),
          'injured': entry.value['injured'] == true,
        },
  ];
}
