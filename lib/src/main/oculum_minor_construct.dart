part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Physical availability is independent of knowing or buying a Book page.
/// An explicitly authored Master anatomy remains the authority for that monster.
List<Map<String, dynamic>> oculumReferenceCreaturePrecisionParts(
  Iterable<Map> original, {
  required String monsterId,
  bool minorConstructCoreExposed = false,
  int bottledCloudPhase = 1,
  bool explicitMasterAnatomy = false,
}) {
  final parts = original.map((p) => Map<String, dynamic>.from(p)).toList();
  if (explicitMasterAnatomy) return parts;
  if (monsterId == 'nuvola_in_bottiglia' && bottledCloudPhase >= 2) {
    parts.removeWhere((p) => p['id'] == 'bottle' || p['group'] == 'bottle');
  }
  if (monsterId != 'costrutto_minore') return parts;
  parts.removeWhere((p) => p['id'] == 'core' || p['group'] == 'core');
  if (!parts.any((p) => p['id'] == 'box')) {
    parts.add({
      'id': 'box',
      'label': 'Scatola corazzata',
      'group': 'box',
      'material': 'metal',
      'penalty': 0,
      'weak': false,
    });
  }
  if (minorConstructCoreExposed) {
    parts.add({
      'id': 'core',
      'label': 'Nucleo interno esposto',
      'group': 'core',
      'material': 'metal',
      'penalty': 0,
      'weak': true,
      'nativeMechanic': true,
    });
  }
  return parts;
}

bool oculumMinorConstructBoxBroken(Map runtime) {
  final override = (runtime['minorConstructBoxRules'] as Map?)?['coreExposed'];
  if (override is bool) return override;
  final box = ((runtime['anatomicalParts'] as Map?)?['parts'] as Map?)?['box'];
  if (box is! Map) return false;
  final maximum = readIntValue(box['maximumHp']);
  return maximum > 0 && readIntValue(box['damageTaken']) >= maximum;
}

extension _OculumMinorConstruct on _OculumHomePageState {
  bool get minorConstructCoreExposed =>
      faunaCurrentMonsterId == 'costrutto_minore' &&
      oculumMinorConstructBoxBroken(planarState);

  bool get currentHasExplicitMasterAnatomy {
    final custom = monsterBookEntryById(
      faunaCurrentMonsterId,
    )?.encounterRules['precisionBodyParts'];
    return custom is List && custom.isNotEmpty;
  }

  bool referenceAnatomicalTargetAvailable(String? part) {
    if (part == null || part.isEmpty) return true;
    final guarded =
        faunaCurrentMonsterId == 'costrutto_minore' && part == 'core' ||
        faunaCurrentMonsterId == 'nuvola_in_bottiglia' && part == 'bottle' ||
        isArmadilloCreature && armadilloClosed;
    if (!guarded) return true;
    return currentPrecisionBodyParts.any((p) => p['id'] == part);
  }

  void publishReferenceCreatureAnatomyState() {
    if (!const {
      'costrutto_minore',
      'nuvola_in_bottiglia',
    }.contains(faunaCurrentMonsterId)) {
      return;
    }
    for (final token in _writableOnlineCombatTokens().where(
      (t) => combatTokenMatchesSheet(t, sheetTagAt(schedaCorrente)),
    )) {
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? const {}),
        if (faunaCurrentMonsterId == 'costrutto_minore')
          'minorConstructCoreExposed': minorConstructCoreExposed,
        if (faunaCurrentMonsterId == 'nuvola_in_bottiglia')
          'bottledCloudPhase': bottledCloudPhaseNumber,
      };
      token['precisionBodyParts'] = publicPrecisionBodyParts;
    }
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }
}
