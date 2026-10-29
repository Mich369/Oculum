part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumLunarGuardianCoreMonsterIds = {
  'guardiano_lunare',
  'guardian_devil_moon',
};

int oculumLunarGuardianArmorMaximum(
  int grade, {
  int baseHits = 5,
  int hitsPerGrade = 3,
}) => 2 * max(1, baseHits + max(0, grade) * hitsPerGrade);

int oculumLunarGuardianArmorHitDamage(
  int maximum, {
  bool critical = false,
  bool doubleCritical = false,
}) => doubleCritical
    ? maximum
    : critical
    ? (maximum / 2).ceil()
    : 2;

int oculumLunarGuardianGraveChestDamage(
  int maximumHp, {
  int percent = 10,
  int minimum = 5,
}) => max(minimum, (max(0, maximumHp) * max(0, percent) / 100).ceil());

List<Map<String, dynamic>> oculumLunarGuardianCorePrecisionParts(
  Iterable<Map> original, {
  required String monsterId,
  bool coreExposed = false,
}) {
  final parts = original.map((p) => Map<String, dynamic>.from(p)).toList();
  if (!oculumLunarGuardianCoreMonsterIds.contains(monsterId)) return parts;
  parts.removeWhere(
    (p) => const {'core', 'armor', 'chest', 'torso'}.contains(p['id']),
  );
  parts.addAll([
    {
      'id': 'armor',
      'label': 'Corazza di pietra',
      'group': 'torso',
      'penalty': 0,
      'weak': false,
    },
    {
      'id': 'chest',
      'label': 'Petto',
      'group': 'torso',
      'penalty': 0,
      'weak': false,
    },
    if (coreExposed)
      {
        'id': 'core',
        'label': monsterId == 'guardian_devil_moon'
            ? 'Nucleo di ombra diabolica esposto'
            : 'Nucleo d’ombra esposto',
        'group': 'core',
        'penalty': 0,
        'weak': true,
      },
  ]);
  return parts;
}

/// Test-only access remains in this new part so concurrent work on the common
/// performance probe does not overwrite unrelated test hooks.
extension OculumLunarGuardianCoreProbe on OculumPerformanceProbe {
  Map<String, dynamic> lunarGuardianCoreState() =>
      _state.lunarGuardianCoreState;

  void lunarGuardianCoreHit(
    Map<String, dynamic> request, {
    bool hit = true,
    bool critical = false,
    bool doubleCritical = false,
    int hpLost = 0,
  }) => _state.lunarGuardianAfterIncomingAttack(
    request,
    hit: hit,
    critical: critical,
    doubleCritical: doubleCritical,
    receipt: {'hpLost': hpLost},
  );

  int lunarGuardianCoreDamage(int value, {String? requestId}) =>
      _state.applyLunarGuardianCoreDamage(value, requestId: requestId);
}

/// Applied to the exposed core instead of the stone body's resistance preset.
/// The infernal core deliberately has no intrinsic elemental fragility.
int oculumLunarGuardianCoreDamagePercent(
  String element, {
  bool infernal = false,
}) => switch (oculumNormalizeElementId(element)) {
  'buio' || 'oscuro' => 50,
  'lunare' => 75,
  'solare' => infernal ? 100 : 125,
  _ => 100,
};

/// Transfers a cumulative percentage, preventing per-hit rounding from making
/// repeated small hits exceed the exact exposure-time HP budget.
int oculumLunarGuardianTransferCoreDamage(
  Map<String, dynamic> state,
  int damage,
  int currentBodyHp,
) {
  final maximum = max(1, readIntValue(state['coreMaximum'], fallback: 1));
  final before = readIntValue(state['coreHp']).clamp(0, maximum).toInt();
  if (before <= 0 || damage <= 0) return 0;
  final after = max(0, before - damage);
  state['coreHp'] = after;
  final bodyAtExposure = max(
    1,
    readIntValue(state['bodyHpAtExposure'], fallback: currentBodyHp),
  );
  final cumulative = ((maximum - after) * bodyAtExposure / maximum).ceil();
  final previouslyTransferred = max(
    0,
    readIntValue(state['damageTransferred']),
  );
  state['damageTransferred'] = cumulative;
  if (after == 0) return max(0, currentBodyHp);
  return max(0, cumulative - previouslyTransferred);
}

extension _OculumLunarGuardianCore on _OculumHomePageState {
  bool get isLunarGuardianCoreCreature =>
      oculumLunarGuardianCoreMonsterIds.contains(faunaCurrentMonsterId);
  bool get lunarGuardianInfernalCore =>
      faunaCurrentMonsterId == 'guardian_devil_moon';

  Map<String, dynamic> get lunarGuardianCoreState {
    final raw = planarState['lunarGuardianCore'];
    final next = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map? ?? const {});
    final rules = planarState['lunarGuardianCoreRules'] as Map? ?? const {};
    next.putIfAbsent(
      'armorMaximum',
      () => oculumLunarGuardianArmorMaximum(
        activeCriticalGrade(),
        baseHits: max(1, readIntValue(rules['baseHits'], fallback: 5)),
        hitsPerGrade: max(0, readIntValue(rules['hitsPerGrade'], fallback: 3)),
      ),
    );
    next.putIfAbsent('armorIntegrity', () => next['armorMaximum']);
    final grade = max(0, activeCriticalGrade());
    next.putIfAbsent('armorGrade', () => grade);
    if (readIntValue(next['armorGrade']) != grade) {
      final oldMaximum = max(1, readIntValue(next['armorMaximum']));
      final updatedMaximum = oculumLunarGuardianArmorMaximum(
        grade,
        baseHits: max(1, readIntValue(rules['baseHits'], fallback: 5)),
        hitsPerGrade: max(0, readIntValue(rules['hitsPerGrade'], fallback: 3)),
      );
      next['armorIntegrity'] =
          (readIntValue(next['armorIntegrity']).clamp(0, oldMaximum) *
                  updatedMaximum /
                  oldMaximum)
              .floor();
      next['armorMaximum'] = updatedMaximum;
      next['armorGrade'] = grade;
    }
    next.putIfAbsent('coreExposed', () => false);
    next.putIfAbsent('receipts', () => <String>[]);
    planarState['lunarGuardianCore'] = next;
    return next;
  }

  bool get lunarGuardianCoreExposed =>
      isLunarGuardianCoreCreature &&
      lunarGuardianCoreState['coreExposed'] == true;

  Map<String, dynamic> get lunarGuardianCorePublicState =>
      !isLunarGuardianCoreCreature
      ? const {}
      : {
          'armorMaximum': lunarGuardianCoreState['armorMaximum'],
          'armorIntegrity': lunarGuardianCoreState['armorIntegrity'],
          'coreExposed': lunarGuardianCoreExposed,
          if (lunarGuardianCoreExposed) ...{
            'coreMaximum': lunarGuardianCoreState['coreMaximum'],
            'coreHp': lunarGuardianCoreState['coreHp'],
            'infernalCore': lunarGuardianInfernalCore,
          },
        };

  int lunarGuardianCoreDamagePercentFor(String element) {
    final normalized = oculumNormalizeElementId(element);
    final rules = planarState['lunarGuardianCoreRules'] as Map? ?? const {};
    final key = switch (normalized) {
      'buio' || 'oscuro' => 'darkPercent',
      'lunare' => 'moonPercent',
      'solare' => 'solarPercent',
      _ => '',
    };
    final fallback = oculumLunarGuardianCoreDamagePercent(
      element,
      infernal: lunarGuardianInfernalCore,
    );
    final value = key.isEmpty
        ? fallback
        : readIntValue(rules[key], fallback: fallback);
    return value.clamp(0, lunarGuardianInfernalCore ? 100 : 1000).toInt();
  }

  Future<void> editLunarGuardianCoreRules() async {
    final origin = currentSheetScrollId();
    final oldRules = planarState['lunarGuardianCoreRules'] as Map? ?? const {};
    final definitions = <(String, String, int)>[
      ('baseHits', 'Colpi mirati base contro la corazza', 5),
      ('hitsPerGrade', 'Colpi aggiuntivi per Grado', 3),
      ('gravePercent', 'Colpo grave: % della Vita massima', 10),
      ('graveMinimum', 'Colpo grave: Danni minimi', 5),
      ('darkPercent', 'Danni Buio al nucleo (%)', 50),
      ('moonPercent', 'Danni Luna al nucleo (%)', 75),
      (
        'solarPercent',
        'Danni Solari al nucleo (%)',
        lunarGuardianInfernalCore ? 100 : 125,
      ),
    ];
    final controllers = [
      for (final field in definitions)
        TextEditingController(
          text: '${readIntValue(oldRules[field.$1], fallback: field.$3)}',
        ),
    ];
    final dialogRoute = DialogRoute<Map<String, int>>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Corazza e nucleo lunare'),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'L’integrità già persa resta proporzionale. La Vita del nucleo già esposto rimane fissata; il nucleo diabolico non riceve fragilità elementali.',
                ),
                for (var i = 0; i < definitions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: controllers[i],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: definitions[i].$2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, {
              for (var i = 0; i < definitions.length; i++)
                definitions[i].$1: max(
                  definitions[i].$1 == 'baseHits' ||
                          definitions[i].$1 == 'graveMinimum'
                      ? 1
                      : 0,
                  int.tryParse(controllers[i].text) ?? definitions[i].$3,
                ),
            }),
            child: const Text('Applica'),
          ),
        ],
      ),
    );
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(dialogRoute);
    await dialogRoute.completed;
    for (final controller in controllers) {
      controller.dispose();
    }
    if (result == null ||
        !mounted ||
        currentSheetScrollId() != origin ||
        !isLunarGuardianCoreCreature) {
      return;
    }
    final state = lunarGuardianCoreState;
    final oldMax = max(1, readIntValue(state['armorMaximum']));
    final nextMax = oculumLunarGuardianArmorMaximum(
      activeCriticalGrade(),
      baseHits: result['baseHits']!,
      hitsPerGrade: result['hitsPerGrade']!,
    );
    state['armorIntegrity'] =
        (readIntValue(state['armorIntegrity']).clamp(0, oldMax) *
                nextMax /
                oldMax)
            .floor();
    state['armorMaximum'] = nextMax;
    planarState['lunarGuardianCoreRules'] = {...oldRules, ...result};
    publishLunarGuardianCoreState();
    if (mounted) setState(() {});
  }

  Widget lunarGuardianCorePanel() {
    if (!isLunarGuardianCoreCreature) return const SizedBox.shrink();
    final state = lunarGuardianCoreState;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Corazza di pietra lunare')),
                IconButton(
                  tooltip: 'Modifica regole di corazza e nucleo',
                  onPressed: haPermessiMaster
                      ? editLunarGuardianCoreRules
                      : null,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            Text(
              'Integrità ${state['armorIntegrity']}/${state['armorMaximum']} · Scudi normali ${scudo()} · Scudo Oculum ${scudoOculum()}',
            ),
            Text(
              lunarGuardianCoreExposed
                  ? 'Nucleo esposto: ${state['coreHp']}/${state['coreMaximum']}. Il danno si trasferisce in proporzione alla Vita fissata all’esposizione.'
                  : readIntValue(state['armorIntegrity']) <= 0
                  ? 'Corazza distrutta: serve un successivo colpo grave mirato al petto.'
                  : 'Gli Scudi proteggono la corazza. Un colpo mirato che li azzera può già danneggiarla.',
            ),
          ],
        ),
      ),
    );
  }

  void publishLunarGuardianCoreState() {
    for (final token in _writableOnlineCombatTokens().where(
      (t) => combatTokenMatchesSheet(t, sheetTagAt(schedaCorrente)),
    )) {
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? const {}),
        'lunarGuardianCore': lunarGuardianCorePublicState,
      };

      token['precisionBodyParts'] = publicPrecisionBodyParts;
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  /// Post-receipt: the ordinary hit has already damaged the body and passed
  /// through Defense and both shields. The hit that empties them counts too.
  void lunarGuardianAfterIncomingAttack(
    Map<String, dynamic> request, {
    required bool hit,
    required bool critical,
    required bool doubleCritical,
    required Map receipt,
  }) {
    if (!isLunarGuardianCoreCreature ||
        !hit ||
        request['guardianSecondaryEvent'] == true) {
      return;
    }
    final part = '${request['targetBodyPart'] ?? ''}';
    if (!const {'armor', 'chest', 'torso'}.contains(part) ||
        scudo() > 0 ||
        scudoOculum() > 0) {
      return;
    }
    final state = lunarGuardianCoreState;
    final receiptId = '${request['id'] ?? ''}';
    final receipts = (state['receipts'] as List? ?? const [])
        .map((v) => '$v')
        .toSet();
    if (receiptId.isEmpty || !receipts.add('armor:$receiptId')) return;
    state['receipts'] = receipts.toList();
    final brokenBefore = readIntValue(state['armorIntegrity']) <= 0;
    if (!brokenBefore) {
      final protectedCritical = request['criticalShieldProtected'] == true;
      final loss = oculumLunarGuardianArmorHitDamage(
        readIntValue(state['armorMaximum']),
        critical: critical && !protectedCritical,
        doubleCritical: doubleCritical && !protectedCritical,
      );
      state['armorIntegrity'] = max(
        0,
        readIntValue(state['armorIntegrity']) - loss,
      );
      aggiungiLog(
        '[CORAZZA LUNARE] Integrità ${state['armorIntegrity']}/${state['armorMaximum']}. Il colpo conserva il normale danno al corpo.',
      );
    } else if (!lunarGuardianCoreExposed &&
        const {'chest', 'torso'}.contains(part) &&
        hpCorrenti() > 0) {
      final rules = planarState['lunarGuardianCoreRules'] as Map? ?? const {};
      final grave = oculumLunarGuardianGraveChestDamage(
        maxHp(),
        percent: readIntValue(rules['gravePercent'], fallback: 10),
        minimum: readIntValue(rules['graveMinimum'], fallback: 5),
      );
      if (readIntValue(receipt['hpLost']) >= grave) {
        final body = hpCorrenti();
        state['coreExposed'] = true;
        state['bodyHpAtExposure'] = body;
        state['coreMaximum'] = max(1, body ~/ 3);
        state['coreHp'] = state['coreMaximum'];
        state['damageTransferred'] = 0;
        aggiungiLog(
          '[NUCLEO LUNARE] Il colpo grave apre il petto: nucleo ${state['coreHp']}/${state['coreMaximum']}, fissato a un terzo della Vita attuale.',
        );
      }
    }
    publishLunarGuardianCoreState();
  }

  /// Called exactly where final post-shield damage would reach body HP, before
  /// the construct-core branch. No HP undo and no duplicate loss ledger.
  int applyLunarGuardianCoreDamage(int finalDamage, {String? requestId}) {
    if (!lunarGuardianCoreExposed || finalDamage <= 0) return 0;
    final state = lunarGuardianCoreState;
    if (requestId != null && requestId.isNotEmpty) {
      final receipts = (state['receipts'] as List? ?? const [])
          .map((v) => '$v')
          .toSet();
      if (!receipts.add('core:$requestId')) return 0;
      state['receipts'] = receipts.toList();
    }
    final before = readIntValue(state['coreHp']);
    final bodyDamage = oculumLunarGuardianTransferCoreDamage(
      state,
      finalDamage,
      hpCorrenti(),
    );
    if (readIntValue(state['coreHp']) <= 0) {
      constructCore['lastAttackCore'] = true;
    }
    aggiungiLog(
      '[NUCLEO LUNARE] ${before - readIntValue(state['coreHp'])} Vita del nucleo persa; $bodyDamage Danni proporzionali al corpo${readIntValue(state['coreHp']) == 0 ? ' · nucleo distrutto, morte immediata' : ''}.',
    );
    publishLunarGuardianCoreState();
    return bodyDamage;
  }
}
