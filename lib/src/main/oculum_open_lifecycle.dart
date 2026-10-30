part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Recovery and empowered Skill duration are independent clocks. A completed
/// fight is a receipt, never a round or a click on the Open button.
class OculumOpenLifecycleProgress {
  OculumOpenLifecycleProgress({
    required this.id,
    this.used = false,
    this.buffActive = false,
    this.skillEmpowered = false,
    this.longRests = 0,
    this.shortRests = 0,
    this.skillBonus = -1,
    Set<String>? completedFightIds,
  }) : completedFightIds = {...?completedFightIds};

  factory OculumOpenLifecycleProgress.fromJson(
    Map json, {
    bool legacyUsed = false,
    bool legacyActive = false,
  }) {
    final migrated = json.isNotEmpty;
    return OculumOpenLifecycleProgress(
      id: '${json['id'] ?? ''}',
      used: migrated ? readBoolValue(json['used']) : legacyUsed || legacyActive,
      buffActive: migrated ? readBoolValue(json['buffActive']) : legacyActive,
      skillEmpowered: migrated
          ? readBoolValue(json['skillEmpowered'])
          : legacyActive,
      longRests: max(0, readIntValue(json['longRests'])),
      shortRests: max(0, readIntValue(json['shortRests'])),
      skillBonus: readIntValue(json['skillBonus'], fallback: -1),
      completedFightIds: (json['completedFightIds'] as List? ?? const [])
          .map((id) => '$id')
          .where((id) => id.isNotEmpty)
          .toSet(),
    );
  }

  String id;
  bool used;
  bool buffActive;
  bool skillEmpowered;
  int longRests;
  int shortRests;
  int skillBonus;
  final Set<String> completedFightIds;
  bool get ready => !used;

  bool activate() {
    if (!ready) return false;
    used = true;
    buffActive = true;
    skillEmpowered = true;
    longRests = 0;
    shortRests = 0;
    skillBonus = -1;
    completedFightIds.clear();
    return true;
  }

  void rest({required bool longRest, bool fate = false}) {
    if (!used && !skillEmpowered) return;
    if (longRest) {
      longRests++;
    } else {
      shortRests++;
    }
    if (used &&
        (longRests >= 2 || longRests >= 1 && shortRests >= (fate ? 2 : 3))) {
      used = false;
      buffActive = false;
    }
    if (skillEmpowered && longRests >= 1 && shortRests >= 2) {
      skillEmpowered = false;
    }
  }

  bool completeFight(String id) {
    if (!skillEmpowered || id.isEmpty || !completedFightIds.add(id)) {
      return false;
    }
    if (completedFightIds.length >= 3) skillEmpowered = false;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'used': used,
    'buffActive': buffActive,
    'skillEmpowered': skillEmpowered,
    'longRests': longRests,
    'shortRests': shortRests,
    'completedFightIds': completedFightIds.toList(),
    'skillBonus': skillBonus,
  };
}

extension _OculumOpenLifecycle on _OculumHomePageState {
  String _newOpenLifecycleId() =>
      'open:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}';

  OculumOpenLifecycleProgress artOpenLifecycle(CharacterArt art) {
    final state = OculumOpenLifecycleProgress.fromJson(
      art.openLifecycle,
      legacyUsed: art.openUsedSinceLongRest,
      legacyActive: art.openAttiva,
    );
    if (state.id.isEmpty) state.id = _newOpenLifecycleId();
    art.openLifecycle = state.toJson();
    return state;
  }

  OculumOpenLifecycleProgress titleOpenLifecycle(OculumTitle title) {
    final state = OculumOpenLifecycleProgress.fromJson(
      title.openLifecycle,
      legacyUsed: title.openUsedSinceLongRest,
      legacyActive: title.openAttiva,
    );
    if (state.id.isEmpty) state.id = _newOpenLifecycleId();
    title.openLifecycle = state.toJson();
    return state;
  }

  OculumOpenLifecycleProgress extraOpenLifecycle(TitleOpenEntry extra) {
    final state = OculumOpenLifecycleProgress.fromJson(
      extra.openLifecycle,
      legacyUsed: extra.usedSinceLongRest,
      legacyActive: extra.attiva,
    );
    if (state.id.isEmpty) state.id = _newOpenLifecycleId();
    extra.openLifecycle = state.toJson();
    return state;
  }

  bool canStartArtOpenCycle(CharacterArt art) => artOpenLifecycle(art).ready;
  bool canStartTitleOpenCycle(OculumTitle title) =>
      titleOpenLifecycle(title).ready;
  bool canStartExtraOpenCycle(OculumTitle title, TitleOpenEntry extra) =>
      extraOpenLifecycle(extra).ready;
  bool artOwnOpenSkillEmpowered(CharacterArt art) =>
      artOpenLifecycle(art).skillEmpowered;
  bool titleOwnOpenSkillEmpowered(OculumTitle title) =>
      titleOpenLifecycle(title).skillEmpowered;
  bool artOpenBuffActive(CharacterArt art) =>
      art.openAttiva && artOpenLifecycle(art).buffActive;

  List<OculumStructuredEffect> bindArtOpenSkillEffects(
    CharacterArt art,
    Iterable<OculumStructuredEffect> effects,
  ) {
    final state = artOpenLifecycle(art);
    var bonus = 0;
    if (state.skillEmpowered) {
      bonus = state.skillBonus >= 0
          ? state.skillBonus
          : art.openBuffEffects
                .where((effect) => effect.target == 'monster_open_power')
                .fold<int>(
                  0,
                  (sum, effect) =>
                      sum +
                      oculumEvaluateStructuredEffectValue(
                        effect,
                        variables: formulaValueContext(),
                        subtraits: hiddenEyeStats,
                      ),
                );
    }
    return [
      for (final effect in effects)
        OculumStructuredEffect.fromJson(effect.toJson())
          ..valueExpression = effect.valueExpression.replaceAll(
            RegExp(r'\bmonster_open_bonus\b'),
            '$bonus',
          )
          ..narrativeText = effect.target == 'bottled_cloud_stop'
              ? jsonEncode({
                  ...oculumBottledCloudEffectData(effect.narrativeText),
                  'ownOpenEmpowered': state.skillEmpowered,
                  'ownOpenLifecycleId': state.id,
                })
              : effect.narrativeText,
    ];
  }

  void deactivateArtOpenBuffCycle(CharacterArt art) {
    final state = artOpenLifecycle(art)..buffActive = false;
    art.openLifecycle = state.toJson();
    removeOpenLifecycleBuffEffects(state.id);
  }

  void deactivateTitleOpenBuffCycle(
    OculumTitle title, {
    TitleOpenEntry? extra,
  }) {
    final state = extra == null
        ? titleOpenLifecycle(title)
        : extraOpenLifecycle(extra);
    state.buffActive = false;
    if (extra == null) {
      title.openLifecycle = state.toJson();
    } else {
      extra.openLifecycle = state.toJson();
    }
    removeOpenLifecycleBuffEffects(state.id);
  }

  /// One-shot attacks, prepared hits and summoned objects retain their authored
  /// duration. Only continuing positive effects belong to the Open Buff clock.
  void tagOpenLifecycleBuffEffects(String cycleId, String source) {
    for (final art in arti) {
      final state = artOpenLifecycle(art);
      if (state.id != cycleId) continue;
      state.skillBonus = activeStructuredEffects
          .where(
            (effect) =>
                effect['source'] == source &&
                effect['target'] == 'monster_open_power',
          )
          .fold<int>(
            0,
            (sum, effect) => sum + max(0, readIntValue(effect['value'])),
          );
      art.openLifecycle = state.toJson();
    }
    for (final effect in activeStructuredEffects) {
      if ('${effect['source'] ?? ''}' != source ||
          effect['mode'] == 'prossima_azione' ||
          const {
            'pending_target',
            'costrutto',
            'evocazione',
            'shadow_clone',
          }.contains(effect['type']) ||
          readIntValue(effect['value']) < 0) {
        continue;
      }
      effect['openLifecycleId'] = cycleId;
      effect['remaining'] = -1;
      effect['unit'] = 'open_lifecycle';
    }
    for (final condition in activeConditions) {
      if (condition.source != source || oculumConditionIsNegative(condition)) {
        continue;
      }
      condition.metadata['openLifecycleId'] = cycleId;
      condition.durationType = OculumConditionDurationType.narrative;
      condition.duration = 0;
    }
  }

  void removeOpenLifecycleBuffEffects(String cycleId) {
    if (cycleId.isEmpty) return;
    activeStructuredEffects.removeWhere(
      (effect) => effect['openLifecycleId'] == cycleId,
    );
    activeConditions.removeWhere(
      (condition) => condition.metadata['openLifecycleId'] == cycleId,
    );
  }

  OculumOpenLifecycleProgress itemOpenLifecycle(
    InventoryItem item,
    CharacterSkill ability,
  ) {
    final index = oculumItemTitleAbilities(item).indexOf(ability);
    final saved = Map<String, dynamic>.from(
      item.craftData['titleOpenLifecycle'] as Map? ?? const {},
    );
    final legacy =
        (item.craftData['titleOpenUsedStages'] as List? ?? const []).contains(
          index,
        ) ||
        index == 0 && item.craftData['titleOpenUsedSinceLongRest'] == true;
    final state = OculumOpenLifecycleProgress.fromJson(
      saved['$index'] as Map? ?? const {},
      legacyUsed: legacy,
      legacyActive: legacy,
    );
    if (state.id.isEmpty) state.id = _newOpenLifecycleId();
    saved['$index'] = state.toJson();
    item.craftData = {...item.craftData, 'titleOpenLifecycle': saved};
    return state;
  }

  void saveItemOpenLifecycle(
    InventoryItem item,
    CharacterSkill ability,
    OculumOpenLifecycleProgress state,
  ) {
    final index = oculumItemTitleAbilities(item).indexOf(ability);
    final saved = Map<String, dynamic>.from(
      item.craftData['titleOpenLifecycle'] as Map? ?? const {},
    );
    saved['$index'] = state.toJson();
    final usedStages =
        (item.craftData['titleOpenUsedStages'] as List? ?? const [])
            .map((stage) => readIntValue(stage))
            .toSet();
    if (state.used) {
      usedStages.add(index);
    } else {
      usedStages.remove(index);
    }
    item.craftData = {
      ...item.craftData,
      'titleOpenLifecycle': saved,
      'titleOpenUsedStages': usedStages.toList(),
      if (index == 0) 'titleOpenUsedSinceLongRest': state.used,
    };
  }

  bool canStartItemOpenCycle(InventoryItem item, CharacterSkill ability) =>
      itemOpenLifecycle(item, ability).ready;
  bool itemOwnOpenSkillEmpowered(InventoryItem item, CharacterSkill ability) =>
      itemOpenLifecycle(item, ability).skillEmpowered;
  bool recordItemOpenCycleActivation(
    InventoryItem item,
    CharacterSkill ability,
  ) {
    final state = itemOpenLifecycle(item, ability);
    if (!state.activate()) return false;
    saveItemOpenLifecycle(item, ability, state);
    return true;
  }

  void deactivateItemOpenBuffs({
    InventoryItem? exceptItem,
    CharacterSkill? exceptAbility,
  }) {
    for (final item in inventario) {
      for (final ability in oculumItemTitleAbilities(item)) {
        if (identical(item, exceptItem) && identical(ability, exceptAbility)) {
          continue;
        }
        final state = itemOpenLifecycle(item, ability);
        if (!state.buffActive) continue;
        state.buffActive = false;
        saveItemOpenLifecycle(item, ability, state);
        removeOpenLifecycleBuffEffects(state.id);
      }
    }
  }

  void normalizeItemOpenBuffs({required bool anotherNormalBuffActive}) {
    var active = anotherNormalBuffActive;
    for (final item in inventario) {
      for (final ability in oculumItemTitleAbilities(item)) {
        final state = itemOpenLifecycle(item, ability);
        if (!state.buffActive) continue;
        if (active) {
          state.buffActive = false;
          saveItemOpenLifecycle(item, ability, state);
          removeOpenLifecycleBuffEffects(state.id);
        } else {
          active = true;
        }
      }
    }
  }

  bool recordArtOpenCycleActivation(CharacterArt art) {
    final state = artOpenLifecycle(art);
    if (!state.activate()) return false;
    art.openLifecycle = state.toJson();
    art.openUsedSinceLongRest = true;
    return true;
  }

  bool recordTitleOpenCycleActivation(OculumTitle title) {
    final state = titleOpenLifecycle(title);
    if (!state.activate()) return false;
    title.openLifecycle = state.toJson();
    title.openUsedSinceLongRest = true;
    return true;
  }

  bool recordExtraOpenCycleActivation(OculumTitle title, TitleOpenEntry extra) {
    final state = extraOpenLifecycle(extra);
    if (!state.activate()) return false;
    extra.openLifecycle = state.toJson();
    extra.usedSinceLongRest = true;
    return true;
  }

  void tickOpenLifecycleRest({required bool longRest}) {
    for (final art in arti) {
      final state = artOpenLifecycle(art);
      final hadBuff = art.openAttiva;
      state.rest(longRest: longRest);
      art.openLifecycle = state.toJson();
      art.openUsedSinceLongRest = state.used;
      if (!state.buffActive) removeOpenLifecycleBuffEffects(state.id);
      if (hadBuff && !state.buffActive) {
        final index = arti.indexOf(art);
        if (index >= 0) {
          removeActiveStructuredEffectsForSourcePrefix(
            artOpenDisplayName(art, index),
          );
        }
        art.openAttiva = false;
        if (art.sbloccata && artOpenSbloccata(art)) {
          rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
        }
      }
    }
    for (final title in [...titoli, ...trattiRazziali]) {
      final fate = normalizeTitleCategory(title.tipo) == 'Titoli del Fato';
      final state = titleOpenLifecycle(title);
      final hadBuff = title.openAttiva;
      state.rest(longRest: longRest, fate: fate);
      title.openLifecycle = state.toJson();
      title.openUsedSinceLongRest = state.used;
      if (!state.buffActive) removeOpenLifecycleBuffEffects(state.id);
      if (hadBuff && !state.buffActive) {
        title.openAttiva = false;
        if (title.equipaggiato) {
          rimarginaHpDaAumentoResilienza(
            -titleOpenRuntimeResilienzaBonus(title),
          );
        }
      }
      for (final extra in title.openExtra) {
        final extraState = extraOpenLifecycle(extra);
        final hadExtraBuff = extra.attiva;
        extraState.rest(longRest: longRest, fate: fate);
        extra.openLifecycle = extraState.toJson();
        extra.usedSinceLongRest = extraState.used;
        if (!extraState.buffActive) {
          removeOpenLifecycleBuffEffects(extraState.id);
        }
        if (hadExtraBuff && !extraState.buffActive) {
          extra.attiva = false;
          if (title.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              -extraOpenRuntimeResilienzaBonus(extra),
            );
          }
        }
      }
    }
    for (final item in inventario) {
      for (final ability in oculumItemTitleAbilities(item)) {
        final state = itemOpenLifecycle(item, ability);
        final hadBuff = state.buffActive;
        state.rest(longRest: longRest);
        saveItemOpenLifecycle(item, ability, state);
        if (hadBuff && !state.buffActive) {
          removeOpenLifecycleBuffEffects(state.id);
        }
      }
    }
    syncSenkaMoonToFight();
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  void completeOpenLifecycleFight(String fightId) {
    if (fightId.isEmpty) return;
    final seen =
        (planarState['openLifecycleCompletedFightIds'] as List? ?? const [])
            .map((id) => '$id')
            .toSet();
    if (!seen.add(fightId)) return;
    planarState['openLifecycleCompletedFightIds'] = seen.toList();
    for (final art in arti) {
      final state = artOpenLifecycle(art);
      state.completeFight(fightId);
      art.openLifecycle = state.toJson();
    }
    for (final title in [...titoli, ...trattiRazziali]) {
      final state = titleOpenLifecycle(title);
      state.completeFight(fightId);
      title.openLifecycle = state.toJson();
      for (final extra in title.openExtra) {
        final extraState = extraOpenLifecycle(extra);
        extraState.completeFight(fightId);
        extra.openLifecycle = extraState.toJson();
      }
    }
    for (final item in inventario) {
      for (final ability in oculumItemTitleAbilities(item)) {
        final state = itemOpenLifecycle(item, ability);
        state.completeFight(fightId);
        saveItemOpenLifecycle(item, ability, state);
      }
    }
    programmaSalvataggio(invalidateCaches: false);
  }
}
