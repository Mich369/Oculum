part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumLunarGuardianArt(CharacterArt art) => art.openDescriptionEffects.any(
  (effect) => effect.target == 'lunar_guardian_stones',
);

/// Configure only a fresh Book Art; saved Arts remain independently editable.
CharacterArt oculumConfigureLunarGuardianArt(
  CharacterArt art, {
  bool infernal = false,
}) {
  art.monsterOpenSkill = true;
  art.openName = infernal
      ? 'Sepolcro della Devil Moon'
      : 'Risveglio della pietra lunare';
  art.openDescription =
      'Costo: 7 Oculum. Un solo tiro d’attacco per una raffica di 1d20 pietre, '
      'distribuibili fra gli avversari. Ogni pietra riuscita infligge 5 Danni fissi, '
      '10 contro i Solari: eccezione, non aggiunge i propri Danni. '
      'Chi è colpito non può ritentare la prima difesa spendendo una Reazione. '
      'Dopo l’impatto erompono spuntoni: 10 Danni fissi aggiuntivi (20 ai Solari), '
      'con una nuova schivata di Riflessi pagando una Reazione. '
      'Solo gli spuntoni contro i non Solari usano Luna o Buio, scegliendo la loro resistenza più debole. '
      'Difesa e Scudi restano validi per entrambi i colpi. Il recupero segue la regola globale delle Open.';
  art.openBuff =
      '@Danni+20 Luna; @Difesa+15 Luna; Il Buff persiste fino al recupero della Open. '
      'La durata del potenziamento della Skill Open è separata e segue la regola globale.';
  art.openSkill =
      'Cresta dell’ombra minerale. Costo: 4 Oculum. CD 3 turni personali. '
      'Sempre utilizzabile: una cresta di pietra e ombra colpisce un nemico con i Danni attuali +12. '
      'Con il potenziamento della propria Open diventa un anello: Danni attuali +20 '
      'e fino a due avversari, con un solo tiro confrontato con le loro difese. '
      'Il potenziamento non viene dato dall’Open di un’altra Art.';
  art.openDescriptionEffects = [
    OculumStructuredEffect(
      id: 'lunar_guardian_stones',
      type: 'planar',
      target: 'lunar_guardian_stones',
      valueExpression: '5',
      diceExpression: '1d20',
      recipient: 'nemico',
      elementType: 'lunare',
      maximumTargets: 20,
      mode: 'prossima_azione',
      duration: '0',
      includeLevel: false,
      includeGrade: false,
    ),
    OculumStructuredEffect(
      id: 'monster_open_ultimate_lunar_guardian',
      type: 'planar',
      target: 'lunar_guardian_catalogue',
      valueExpression: '0',
      recipient: 'se_stesso',
    ),
  ];
  art.openBuffEffects = [];
  art.openDescriptionCooldown = null;
  art.openBuffCooldown = null;
  art.openSkillEffects = [
    OculumStructuredEffect(
      id: 'lunar_guardian_shadow_crest',
      type: 'danno',
      target: 'lunar_guardian_shadow_crest',
      valueExpression: '12',
      recipient: 'nemico',
      elementType: 'buio',
      maximumTargets: 1,
      mode: 'immediato',
      duration: '0',
      includeLevel: false,
      includeGrade: false,
    ),
  ];
  art.openSkillCooldown = OculumAbilityCooldown(amount: 3);
  return art;
}

int oculumLunarGuardianStoneDamage(int perStone, {required bool solar}) =>
    max(0, perStone) * (solar ? 2 : 1);

extension _OculumLunarGuardians on _OculumHomePageState {
  bool get lunarGuardianOwnSkillEmpowered => arti.any(
    (art) =>
        art.sbloccata &&
        art.inUso &&
        oculumLunarGuardianArt(art) &&
        artOwnOpenSkillEmpowered(art),
  );

  Map<String, dynamic>? get lunarGuardianVolleyPending {
    for (final entry in activeStructuredEffects) {
      final effect = entry['effect'];
      if (entry['type'] != 'pending_target' ||
          effect is! Map ||
          effect['target'] != 'lunar_guardian_stones') {
        continue;
      }
      try {
        final decoded = jsonDecode('${effect['narrativeText']}');
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  List<OculumStructuredEffect> prepareLunarGuardianEffects(
    List<OculumStructuredEffect> effects, {
    Random? random,
  }) => [
    for (final original in effects)
      (() {
        if (original.target != 'lunar_guardian_stones' &&
            original.target != 'lunar_guardian_shadow_crest') {
          return original;
        }
        final e = OculumStructuredEffect.fromJson(original.toJson());
        if (e.target == 'lunar_guardian_shadow_crest') {
          if (lunarGuardianOwnSkillEmpowered) {
            e.valueExpression = '(${e.valueExpression})+8';
            e.maximumTargets = max(2, e.maximumTargets);
          }
          return e;
        }
        final roll = oculumResolveStructuredEffectRoll(
          e,
          variables: formulaValueContext(),
          subtraits: hiddenEyeStats,
          random: random,
        );
        final stones = max(1, roll.dice.rolls.fold<int>(0, (a, b) => a + b));
        final perStone = max(
          0,
          oculumEvaluateFormula(
            e.valueExpression,
            formulaValueContext(),
          ).floor(),
        );
        e.narrativeText = jsonEncode({
          'cuts': stones,
          'damagePerCut': perStone,
          'lunarGuardian': true,
          'eruptionDamage': perStone * 2,
        });
        e.maximumTargets = stones;
        e.valueExpression = '0';
        e.diceExpression = '';
        e.includeLevel = e.includeGrade = false;
        return e;
      })(),
  ];

  Future<void> useLunarGuardianOpen(CharacterArt art, int index) async {
    if (!arti.contains(art) || !art.inUso || !artOpenSbloccata(art)) return;
    if (art.openAttiva) {
      art.openAttiva = false;
      invalidateDerivedDataCaches();
      programmaSalvataggio();
      if (mounted) setState(() {});
      return;
    }
    if (!canStartArtOpenCycle(art)) {
      aggiungiLog('Open lunare non ancora recuperata con i riposi.');
      return;
    }
    ensureArtIntegrityValue(index);
    final integrityCost =
        !art.hasIntegrity || oculumRecognizedArtKind(art) == 'emblem'
        ? 0
        : artUseCost(oculumArtActivationCost);
    if (art.hasIntegrity &&
        !oculumArtCanActivate(art.integritaCorrente, cost: integrityCost)) {
      aggiungiLog('Open lunare: integrità Art insufficiente.');
      return;
    }
    final owner = currentSheetScrollId();
    final encounter = onlineCombatEncounterId;
    final parsed = oculumParseAbilityCost(art.openDescription);
    final used = await useConfiguredAbility(
      source: artOpenDisplayName(art, index),
      effects: art.openDescriptionEffects,
      cost: OculumSkillCost(
        resource: parsed?.resource ?? 'oculum',
        amountExpression: '${parsed?.minimum ?? 7}',
        minimum: parsed?.minimum ?? 7,
        maximum: parsed?.maximum ?? 7,
        variable: parsed != null && parsed.minimum != parsed.maximum,
      ),
      cooldown: art.openDescriptionCooldown,
      valid: () =>
          currentSheetScrollId() == owner &&
          onlineCombatEncounterId == encounter &&
          arti.contains(art) &&
          art.sbloccata &&
          art.inUso &&
          !art.openAttiva &&
          artOpenSbloccata(art),
      onPaid: (_) {
        recordArtOpenCycleActivation(art);
        if (art.hasIntegrity) {
          consumeArtIntegrityAndResolveDebuff(
            index,
            integrityCost,
            skillLevel: 3,
          );
        }
        disattivaTutteLeOpen(exceptArt: art);
        art.openAttiva = true;
        art.openUsedSinceLongRest = true;
      },
    );
    if (!used || !mounted || currentSheetScrollId() != owner) return;
    invalidateDerivedDataCaches();
    notifyArtIntegrityChanged(index);
    scheduleArtIntegritySave(<int>[index], immediate: true);
    programmaSalvataggio();
    scheduleRealtimeOculumChanged();
    if (lunarGuardianVolleyPending != null) await planOnlineAttack();
  }

  void lunarGuardianConfigureOutgoingAttack(
    Map<String, dynamic> request,
    Map token,
    Map volley,
    int hit,
    int count,
  ) {
    if (volley['lunarGuardian'] != true) return;
    request['damage'] = max(
      0,
      readIntValue(volley['damagePerCut'], fallback: 5),
    );
    request['baseAttack'] = false;
    request['element'] = 'lunare';
    request['lunarGuardianStone'] = true;
    request['lunarGuardianEruptionDamage'] = max(
      0,
      readIntValue(volley['eruptionDamage'], fallback: 10),
    );
    request['abilityName'] = 'Pietra lunare · ${hit + 1}/$count';
  }

  /// The victim chooses its own weakest affinity; a hidden race or an old
  /// public token cannot cause an incorrect Solar multiplier on the source.
  void lunarGuardianResolveIncomingElement(Map<String, dynamic> request) {
    if ((request['lunarGuardianStone'] != true &&
            request['lunarGuardianEruption'] != true) ||
        request['lunarGuardianElementResolved'] == true) {
      return;
    }
    final solar =
        celestialAllegiance == 'solare' ||
        razzaController.text.toLowerCase().contains('solare');
    request['damage'] = oculumLunarGuardianStoneDamage(
      readIntValue(request['damage']),
      solar: solar,
    );
    request['element'] = solar || request['lunarGuardianEruption'] != true
        ? 'lunare'
        : mostEffectiveIncomingElement(['lunare', 'buio'], tieIndex: 0);
    request['lunarGuardianElementResolved'] = true;
  }

  /// This is a separate defense opportunity, not a retry of the first hit.
  /// The caller publishes it through the ordinary attack transport exactly once.
  Map<String, dynamic>? lunarGuardianPendingEruption(
    Map<String, dynamic> request, {
    required bool hit,
  }) {
    if (!hit ||
        request['lunarGuardianStone'] != true ||
        request['lunarGuardianEruptionCreated'] == true) {
      return null;
    }
    request['lunarGuardianEruptionCreated'] = true;
    final next = Map<String, dynamic>.from(request)
      ..['id'] = 'lunar-eruption:${request['id']}'
      ..['kind'] = 'attack'
      ..['status'] = 'pending'
      ..['damage'] = max(
        0,
        readIntValue(request['lunarGuardianEruptionDamage'], fallback: 10),
      )
      ..['baseAttack'] = false
      ..['lunarGuardianStone'] = false
      ..['lunarGuardianEruption'] = true
      ..['lunarGuardianReactionOnly'] = true
      ..['abilityName'] = 'Eruzione degli spuntoni lunari'
      ..['effects'] = <dynamic>[];
    for (final key in [
      'damageReceipt',
      'outcome',
      'defense',
      'defenseNatural',
      'lunarGuardianElementResolved',
      'guardianGoldIncoming',
      'retryUsed',
      'resolvedAt',
      'counterAttackResponse',
    ]) {
      next.remove(key);
    }
    return next;
  }
}
