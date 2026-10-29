part of '../../main.dart';

// Targeted-part state is applied after the normal body-damage settlement.
extension _OculumAnatomicalParts on _OculumHomePageState {
  Map<String, dynamic> get anatomicalPartState =>
      Map<String, dynamic>.from(planarState['anatomicalParts'] as Map? ?? {});

  Map<String, dynamic> anatomicalPartRuleFor(Map<String, dynamic> part) {
    final monster = monsterBookEntryById(faunaCurrentMonsterId);
    final catalogue = monster?.encounterRules['anatomicalPartRules'];
    final saved = planarState['anatomicalPartRules'];
    final id = '${part['id']}';
    final defaults = catalogue is Map && catalogue[id] is Map
        ? Map<String, dynamic>.from(catalogue[id] as Map)
        : <String, dynamic>{};
    final custom = saved is Map && saved[id] is Map
        ? Map<String, dynamic>.from(saved[id] as Map)
        : <String, dynamic>{};
    return oculumAnatomicalPartRule(
      monsterId: faunaCurrentMonsterId,
      physicalDescription: monster == null
          ? ''
          : oculumMonsterPhysicalDescription(monster),
      part: part,
      maximumBodyHp: maxHp(),
      overrides: {...defaults, ...custom},
    );
  }

  /// Only the final defender executes this. Body HP has already been settled
  /// by the ordinary damage function; never call applicaDanno a second time.
  Future<void> resolveAnatomicalTargetHit(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
  }) async {
    final monster = monsterBookEntryById(faunaCurrentMonsterId);
    final point = currentPrecisionBodyParts
        .where((p) => p['id'] == request['targetBodyPart'])
        .firstOrNull;
    // Generic part HP is for creatures from the Monster Book. Existing
    // character/Art/Senka mechanics remain exact and have no inferred pools.
    if (monster == null || point == null) {
      resolveLimbCriticalDamage(request, hpLost: hpLost, critical: critical);
      await resolveWingCriticalDamage(
        request,
        hpLost: hpLost,
        critical: critical,
      );
      return;
    }
    final rule = anatomicalPartRuleFor(point);
    final native =
        oculumAnatomicalPartIsNative(
          monsterId: faunaCurrentMonsterId,
          part: {...point, ...rule},
          constructCore: isConstructCharacter,
          senkaMask: senkaMaskItem != null,
        ) ||
        planarState['doppioneCopy'] == true ||
        isLunarGuardianCoreCreature &&
            const {'armor', 'torso', 'chest', 'core'}.contains(point['id']);
    if (native) return;
    final result = oculumApplyAnatomicalPartHit(
      state: anatomicalPartState,
      rule: rule,
      attackId: oculumAnatomicalAttackReceiptId(
        sourceTag: '${request['sourceTag'] ?? ''}',
        targetTag: '${request['targetTag'] ?? sheetTagAt(schedaCorrente)}',
        attackId: '${request['id'] ?? ''}',
      ),
      hpLost: hpLost,
      critical: critical,
      criticalShieldProtected: criticalShieldBlocksDebuffs(request),
    );
    if (result.duplicate) return;
    planarState['anatomicalParts'] = result.state;
    if (!result.applied) return;
    // Preserve the confirmed critical shortcut AND add zero-integrity damage.
    // Non-bony appendages use structural penalties rather than Frattura.
    if (rule['legacyCriticalFracture'] == true) {
      resolveLimbCriticalDamage(
        request,
        hpLost: hpLost,
        critical: result.validCritical,
        partDestroyed: result.reachedZero,
      );
    }
    if (point['group'] == 'wings') {
      await resolveWingCriticalDamage(
        request,
        hpLost: hpLost,
        critical: result.validCritical,
        partDestroyed: result.reachedZero,
      );
    }
    // Reveals are explicit references to EXISTING anatomy only. The normal
    // weak-point hit discovery remains in resolvePrecisionBodyHit unchanged.
    for (final id in result.revealPartIds) {
      final exposed = currentPrecisionBodyParts
          .where((p) => p['id'] == id && p['weak'] == true)
          .firstOrNull;
      if (exposed != null) {
        rememberMonsterBookPartyDiscovery(
          faunaCurrentMonsterId,
          seen: true,
          weakPoint: true,
          broadcast: true,
        );
      }
    }
    aggiungiLog(
      '[PARTE] ${rule['label']}: −${result.hpLost} Vita parte, '
      '${result.remainingHp} rimanente. Il corpo ha già subito $hpLost Danni.'
      '${result.becameInjured ? ' ${rule['injuryLabel']}.' : ''}',
    );
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  int anatomicalPartRollPenalty(String roll) =>
      oculumAnatomicalPartRollPenalty(anatomicalPartState, roll);

  /// This does not heal body HP. Appropriate-treatment must only be called
  /// after an authorized cure; the editor's Master repair is an explicit override.
  void restoreAnatomicalPartsByRecovery(
    String method, {
    bool fracturesOnly = false,
  }) {
    var state = anatomicalPartState;
    final raw = state['parts'];
    if (raw is! Map || raw.isEmpty) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (final entry in raw.entries) {
      if (entry.value is! Map) continue;
      final part = entry.value as Map;
      if (fracturesOnly && part['legacyCriticalFracture'] != true) continue;
      state = oculumRepairAnatomicalPart(
        state: state,
        partId: '${entry.key}',
        method: method,
        receiptId: 'repair:$method:$stamp:${entry.key}',
      );
    }
    planarState['anatomicalParts'] = state;
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  Widget anatomicalPartsSummary() {
    final state = anatomicalPartState;
    final raw = state['parts'];
    final parts = raw is Map ? raw : <String, dynamic>{};
    if (parts.isEmpty) {
      return canManageAllThemes
          ? TextButton(
              onPressed: openAnatomicalPartRulesEditor,
              child: const Text('Master · Modifica integrità parti'),
            )
          : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Parti danneggiate',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
        ),
        for (final part in parts.values.whereType<Map>())
          Text(
            '${part['label']}: '
            '${max(0, readIntValue(part['maximumHp']) - readIntValue(part['damageTaken']))}'
            '/${part['maximumHp']}'
            '${part['injured'] == true ? ' · ${part['injuryLabel']}' : ''}',
          ),
        if (canManageAllThemes)
          Wrap(
            children: [
              TextButton(
                onPressed: openAnatomicalPartRulesEditor,
                child: const Text('Master · Modifica parti'),
              ),
              TextButton(
                onPressed: () {
                  final fracture = getCondition('frattura');
                  if (fracture != null) removeCondition(fracture, force: true);
                  restoreAnatomicalPartsByRecovery('master_repair');
                  restoreDamagedWings();
                  aggiungiLog(
                    '[MASTER] Parti riparate; Vita del corpo invariata.',
                  );
                  refreshOculumHome(() {});
                },
                child: const Text('Master · Ripara parti'),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> openAnatomicalPartRulesEditor() async {
    if (!canManageAllThemes) return;
    final tag = sheetTagAt(schedaCorrente), scope = permissionScope;
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent(
        '  ',
      ).convert(planarState['anatomicalPartRules'] ?? <String, dynamic>{}),
    );
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Integrità parti · regole modificabili'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: form,
            child: TextFormField(
              controller: controller,
              minLines: 6,
              maxLines: 16,
              decoration: const InputDecoration(
                helperText:
                    'Per ID: maximumHp o maximumHpFraction, material, rollPenalty, '
                    'affectedRolls, recovery, criticalCanInjure. '
                    'Le parti già danneggiate conservano il massimo fino alla riparazione.',
              ),
              validator: (text) {
                try {
                  if (jsonDecode(text ?? '') is Map) return null;
                } catch (_) {}
                return 'Inserisci un oggetto JSON valido.';
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState?.validate() == true) {
                Navigator.pop(
                  dialogContext,
                  Map<String, dynamic>.from(jsonDecode(controller.text) as Map),
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted ||
        result == null ||
        !canManageAllThemes ||
        scope != permissionScope ||
        tag != sheetTagAt(schedaCorrente)) {
      return;
    }
    planarState['anatomicalPartRules'] = result;
    programmaSalvataggio();
    refreshOculumHome(() {});
  }
}

/// Small test seam. Defense, Shields, body HP and permissions still belong to
/// the production settlement; this exposes no direct body damage shortcut.
extension OculumAnatomicalPartsProbe on OculumPerformanceProbe {
  Map<String, dynamic> anatomicalPartsSnapshot() => _state.anatomicalPartState;
  List<Map<String, dynamic>> anatomicalPartsForCurrentSheet() =>
      _state.currentPrecisionBodyParts;
  Future<void> anatomicalTargetHit(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
  }) => _state.resolveAnatomicalTargetHit(
    request,
    hpLost: hpLost,
    critical: critical,
  );
  void repairAnatomicalParts(String method) =>
      _state.restoreAnatomicalPartsByRecovery(method);
}
