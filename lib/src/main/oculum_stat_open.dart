part of '../../main.dart';

const _statOpenKnights = 'will_knights_50';
const _statOpenResilience = 'res_stone_memory_50';
const _statOpenVitalEcho = 'stat_open_vital_echo';
const _statOpenLevels = [50, 100, 150, 200];
final _statOpenHealingBusy = Expando<bool>();

class _StatOpenTier {
  const _StatOpenTier(this.name, this.skill, this.values);

  final String name;
  final String skill;
  final Map<String, int> values;
}

const _statOpenTracks = {
  'res_stone_memory': (
    stat: 'resilienza',
    label: 'Resilienza',
    tiers: [
      _StatOpenTier('Memoria di Pietra', 'Pietra che Ricorda', {
        'durationTurns': 3,
        'cooldown': 5,
        'defenseBuffPercent': 8,
        'openingShield': 120,
        'allyShield': 30,
      }),
      _StatOpenTier('Bastione delle Ferite', 'Cicatrice del Bastione', {
        'durationTurns': 3,
        'cooldown': 5,
        'defenseBuffPercent': 12,
        'openingShield': 240,
        'allyShield': 50,
      }),
      _StatOpenTier('Cuore Infranto', 'Memoria del Cuore', {
        'durationTurns': 3,
        'cooldown': 6,
        'defenseBuffPercent': 16,
        'openingShield': 360,
        'allyShield': 75,
      }),
      _StatOpenTier('Cuore della Fortezza', 'Ritorno della Fortezza', {
        'durationTurns': 3,
        'cooldown': 6,
        'defenseBuffPercent': 20,
        'openingShield': 500,
        'allyShield': 100,
      }),
    ],
  ),
  'will_knights': (
    stat: 'volonta',
    label: 'Volontà · Forza Esteriore',
    tiers: [
      _StatOpenTier('Cavalieri Rossi', 'Carica dei Quattro', {
        'hits': 4,
        'damagePercent': 35,
        'cooldown': 4,
        'damageBuffPercent': 10,
        'rollBuff': 2,
      }),
      _StatOpenTier('Compagnia Scarlatta', 'Marcia della Compagnia', {
        'hits': 8,
        'damagePercent': 30,
        'cooldown': 5,
        'damageBuffPercent': 14,
        'rollBuff': 3,
      }),
      _StatOpenTier('Guardia del Vespro Rosso', 'Fendente del Vespro', {
        'hits': 16,
        'cost': 4,
        'damagePercent': 28,
        'cooldown': 5,
        'damageBuffPercent': 18,
        'rollBuff': 4,
      }),
      _StatOpenTier('Ordine della Corona Rossa', 'Ultima Carica dell’Ordine', {
        'hits': 36,
        'cost': 8,
        'damagePercent': 26,
        'cooldown': 6,
        'damageBuffPercent': 22,
        'rollBuff': 5,
      }),
    ],
  ),
  'will_oath': (
    stat: 'volonta',
    label: 'Volontà · Forza Interiore',
    tiers: [
      _StatOpenTier('Giuramento di Ferro', 'Ordine di Caduta', {
        'damagePercent': 100,
        'powerPercent': 10,
        'attackPenalty': 3,
        'penaltyBuff': 2,
        'defenseBuffPercent': 8,
        'maxTargets': 2,
        'cooldown': 4,
      }),
      _StatOpenTier('Trono della Pressione', 'Parola del Trono', {
        'damagePercent': 120,
        'powerPercent': 12,
        'attackPenalty': 4,
        'penaltyBuff': 2,
        'defenseBuffPercent': 12,
        'maxTargets': 3,
        'cooldown': 5,
      }),
      _StatOpenTier('Dominio del Silenzio', 'Decreto del Silenzio', {
        'damagePercent': 140,
        'powerPercent': 14,
        'attackPenalty': 5,
        'penaltyBuff': 3,
        'defenseBuffPercent': 16,
        'maxTargets': 4,
        'cooldown': 5,
      }),
      _StatOpenTier('Corona Inesorabile', 'Sentenza della Corona', {
        'damagePercent': 160,
        'powerPercent': 16,
        'attackPenalty': 6,
        'penaltyBuff': 3,
        'defenseBuffPercent': 20,
        'maxTargets': 5,
        'cooldown': 6,
      }),
    ],
  ),
  'matter_geometry': (
    stat: 'materia',
    label: 'Materia',
    tiers: [
      _StatOpenTier('Geometria dell’Istante', 'Passo sul Filo', {
        'damagePercent': 125,
        'movement': 4,
        'movementBuff': 2,
        'movePassive': 4,
        'precisionBonus': 3,
        'reflexesBuff': 2,
        'cooldown': 3,
      }),
      _StatOpenTier('Reticolo Mobile', 'Taglio sul Reticolo', {
        'damagePercent': 150,
        'movement': 6,
        'movementBuff': 2,
        'movePassive': 6,
        'precisionBonus': 4,
        'reflexesBuff': 3,
        'cooldown': 4,
      }),
      _StatOpenTier('Passaggio Azzurro', 'Varco Azzurro', {
        'damagePercent': 175,
        'movement': 8,
        'movementBuff': 3,
        'movePassive': 8,
        'precisionBonus': 5,
        'reflexesBuff': 4,
        'cooldown': 4,
      }),
      _StatOpenTier('Orizzonte Mobile', 'Lama all’Orizzonte', {
        'damagePercent': 200,
        'movement': 10,
        'movementBuff': 4,
        'movePassive': 10,
        'precisionBonus': 6,
        'reflexesBuff': 5,
        'cooldown': 5,
      }),
    ],
  ),
  'oculum_meridian': (
    stat: 'oculum',
    label: 'Oculum',
    tiers: [
      _StatOpenTier('Meridiano dell’Occhio', 'Scarica del Meridiano', {
        'damagePercent': 100,
        'cost': 6,
        'levelDamageMultiplier': 3,
        'levelBuffMultiplier': 1,
        'regen': 1,
        'maxTargets': 2,
        'cooldown': 4,
      }),
      _StatOpenTier('Occhio della Convergenza', 'Fenditura di Convergenza', {
        'damagePercent': 125,
        'cost': 8,
        'levelDamageMultiplier': 4,
        'levelBuffMultiplier': 1,
        'regen': 2,
        'maxTargets': 3,
        'cooldown': 5,
      }),
      _StatOpenTier('Orbita dell’Iride', 'Orbita Infranta', {
        'damagePercent': 150,
        'cost': 10,
        'levelDamageMultiplier': 5,
        'levelBuffMultiplier': 2,
        'regen': 3,
        'maxTargets': 4,
        'cooldown': 5,
      }),
      _StatOpenTier('Asse dell’Oculum', 'Rottura dell’Asse', {
        'damagePercent': 175,
        'cost': 12,
        'levelDamageMultiplier': 6,
        'levelBuffMultiplier': 2,
        'regen': 4,
        'maxTargets': 5,
        'cooldown': 6,
      }),
    ],
  ),
};

final _statOpenForms = {
  for (final entry in _statOpenTracks.entries)
    for (var index = 0; index < _statOpenLevels.length; index++)
      '${entry.key}_${_statOpenLevels[index]}': (
        track: entry.key,
        stat: entry.value.stat,
        level: _statOpenLevels[index],
        tier: entry.value.tiers[index],
      ),
};

extension _OculumStatOpen on _OculumHomePageState {
  String statOpenTrack(String id) => _statOpenForms[id]?.track ?? '';
  int statOpenLevel(String id) => _statOpenForms[id]?.level ?? 0;
  String statOpenName(String id) => _statOpenForms[id]?.tier.name ?? '';
  String statOpenSkillName(String id) => _statOpenForms[id]?.tier.skill ?? '';

  int statOpenValue(String id, String key) => max(
    0,
    stat35Value(id, key, fallback: _statOpenForms[id]?.tier.values[key] ?? 0),
  );

  bool statOpenUnlocked(String id) {
    final form = _statOpenForms[id];
    return form != null &&
        activeCriticalLevel() >= statOpenLevel(id) &&
        stat20Choice(form.stat) != null &&
        stat35Choice(form.stat) != null;
  }

  bool get _statOpenCanAct =>
      mounted &&
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      !parasiteInfested &&
      !stat20OculumChargeActive &&
      controlsOnlineCombatSheet(sheetTagAt(schedaCorrente));

  OculumOpenLifecycleProgress statOpenProgress(String id) {
    final value = _stat35Section('opens')[id];
    final state = value is Map
        ? OculumOpenLifecycleProgress.fromJson(value)
        : OculumOpenLifecycleProgress(id: 'stat_open:$id');
    if (state.id.isEmpty) state.id = 'stat_open:$id';
    return state;
  }

  void _saveStatOpenProgress(String id, OculumOpenLifecycleProgress state) =>
      _setStat35Value('opens', id, state.toJson());

  void clearStatOpenBuffs() {
    for (final id in _statOpenForms.keys) {
      final state = statOpenProgress(id);
      if (!state.buffActive) continue;
      state.buffActive = false;
      state.skillEmpowered = false;
      _saveStatOpenProgress(id, state);
      removeOpenLifecycleBuffEffects(state.id);
    }
  }

  void restStatOpens({required bool longRest}) {
    for (final id in _statOpenForms.keys) {
      final state = statOpenProgress(id);
      if (!state.used && !state.skillEmpowered) continue;
      state.rest(longRest: longRest);
      _saveStatOpenProgress(id, state);
      if (!state.buffActive) removeOpenLifecycleBuffEffects(state.id);
    }
  }

  void completeStatOpenFight(String fightId) {
    for (final id in _statOpenForms.keys) {
      final state = statOpenProgress(id);
      if (state.completeFight(fightId)) _saveStatOpenProgress(id, state);
    }
  }

  bool statOpenOwnBuff(String id) {
    if (!_statOpenForms.containsKey(id)) return false;
    final state = statOpenProgress(id);
    return state.buffActive && state.skillEmpowered;
  }

  String _statOpenCooldownKey(String track) => '${track}_50';

  int statOpenSkillCooldown(String id) {
    final track = statOpenTrack(id);
    if (track.isEmpty) return 0;
    var remaining = stat35Cooldown(_statOpenCooldownKey(track));
    for (final level in _statOpenLevels.skip(1)) {
      remaining = max(remaining, stat35Cooldown('${track}_$level'));
    }
    return remaining;
  }

  void _saveStatOpenSkillCooldown(String track, int remaining) {
    setStat35Cooldown(_statOpenCooldownKey(track), remaining);
    for (final level in _statOpenLevels.skip(1)) {
      final legacyId = '${track}_$level';
      if (stat35Cooldown(legacyId) > 0) setStat35Cooldown(legacyId, 0);
    }
  }

  bool statOpenSkillReady(String id) =>
      _statOpenCanAct && statOpenUnlocked(id) && statOpenSkillCooldown(id) == 0;

  void commitStatOpenSkill(String id) {
    final track = statOpenTrack(id);
    if (track.isEmpty) return;
    _saveStatOpenSkillCooldown(track, statOpenValue(id, 'cooldown'));
    if (track == 'will_knights') {
      aggiungiLog(
        '[${statOpenName(id)}] Due cavalieri spettrali eseguono ${statOpenKnightHitsFor(id)} colpi e scompaiono.',
      );
    }
    programmaSalvataggio();
  }

  void tickStatOpenBuffs() {
    for (final track in _statOpenTracks.keys) {
      if (_statOpenLevels
          .skip(1)
          .any((level) => stat35Cooldown('${track}_$level') > 0)) {
        _saveStatOpenSkillCooldown(track, statOpenSkillCooldown('${track}_50'));
      }
    }
    if (!currentCombatIsActive() || outsideFight || hpCorrenti() <= 0) return;
    for (final level in _statOpenLevels) {
      final id = 'oculum_meridian_$level';
      if (!statOpenProgress(id).buffActive) continue;
      final normalRoom = max(
        0,
        _currentOculumCapacity - currentTemporaryOculumState().normalCurrent,
      );
      final amount = min(statOpenValue(id, 'regen'), normalRoom);
      if (amount > 0) applyStructuredHealing('oculum', amount);
      break;
    }
  }

  void advanceInactiveSheetStatOpens(String tag, Map<String, dynamic> sheet) {
    final runtime = sheet['planarRuntime'];
    final stat35 = runtime is Map ? runtime['stat35'] : null;
    if (stat35 is! Map || !controlsOnlineCombatSheet(tag)) return;

    final cooldowns = stat35['cooldowns'];
    if (cooldowns is Map) {
      final next = <String, int>{
        for (final entry in cooldowns.entries)
          '${entry.key}': readIntValue(entry.value),
      };
      for (final track in _statOpenTracks.keys) {
        var remaining = 0;
        for (final level in _statOpenLevels) {
          remaining = max(
            remaining,
            readIntValue(next.remove('${track}_$level')),
          );
        }
        if (remaining > 1) next[_statOpenCooldownKey(track)] = remaining - 1;
      }
      stat35['cooldowns'] = next;
    }

    final opens = stat35['opens'];
    if (opens is Map &&
        _statOpenLevels.any((level) {
          final progress = opens['oculum_meridian_$level'];
          return progress is Map && readBoolValue(progress['buffActive']);
        })) {
      faunaForOwnedSheet(tag, tickStatOpenBuffs);
    }
  }

  void toggleStatOpen(String id) {
    if (!_statOpenCanAct || !statOpenUnlocked(id)) return;
    final state = statOpenProgress(id);
    if (state.buffActive) {
      state.buffActive = false;
      state.skillEmpowered = false;
      removeOpenLifecycleBuffEffects(state.id);
      _saveStatOpenProgress(id, state);
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
      return;
    }
    if (!state.activate()) return;
    disattivaTutteLeOpen();
    _saveStatOpenProgress(id, state);
    final name = statOpenName(id);
    final shield = statOpenValue(id, 'openingShield');
    const modifiers = {
      'damageBuffPercent': 'danno_percentuale',
      'defenseBuffPercent': 'difesa_percentuale',
      'movePassive': 'movimento',
      'reflexesBuff': 'riflessi',
    };
    applyStructuredEffectsOnActivation(
      [
        for (final modifier in modifiers.entries)
          if (statOpenValue(id, modifier.key) > 0)
            OculumStructuredEffect(
              id: 'stat_open:$id:${modifier.value}',
              type: modifier.value == 'danno_percentuale'
                  ? modifier.value
                  : 'modifica_statistica',
              target: modifier.value,
              valueExpression: '${statOpenValue(id, modifier.key)}',
              mode: 'finche_attivo',
            ),
        if (shield > 0)
          OculumStructuredEffect(type: 'scudo', valueExpression: '$shield'),
      ],
      source: name,
      applyFusionBonus: false,
    );
    tagOpenLifecycleBuffEffects(state.id, name);
    aggiungiLog('[OPEN] $name.');
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
  }

  int statOpenKnightHitsFor(String id) =>
      statOpenValue(id, 'hits').clamp(4, 100);

  int statOpenKnightDamageFor(String id) =>
      max(0, dannoTotale() * statOpenValue(id, 'damagePercent') ~/ 100);

  int statOpenKnightRollBonusFor(String id) =>
      statOpenOwnBuff(id) ? statOpenValue(id, 'rollBuff') : 0;

  Future<void> activateStatOpenSkill(String id) async {
    if (!statOpenSkillReady(id)) return;
    final track = statOpenTrack(id);
    if (track == 'res_stone_memory') {
      await activateStatOpenResilience(id);
    } else {
      if (!canPayStatOpenAttack(id)) return;
      await planOnlineAttack(
        statOpenId: id,
        maximumTargets: track == 'will_knights'
            ? 4
            : statOpenValue(id, 'maxTargets').clamp(1, 100),
      );
    }
  }

  Future<void> activateStatOpenResilience([
    String id = _statOpenResilience,
  ]) async {
    if (statOpenTrack(id) != 'res_stone_memory' ||
        !statOpenSkillReady(id) ||
        _statOpenHealingBusy[this] == true) {
      return;
    }
    final own = sheetTagAt(schedaCorrente);
    final origin = (
      currentSheetScrollId(),
      permissionScope,
      onlineCombatEncounterId,
    );
    final tokens = onlineCombatTokens();
    final actor = tokens
        .where((token) => combatTokenMatchesSheet(token, own))
        .firstOrNull;
    if (actor == null) return;
    final allies = {
      for (final token in tokens)
        if (_stat35ResHealCanTarget(actor, token)) onlineCombatTokenTag(token),
    }.toList();
    _statOpenHealingBusy[this] = true;
    try {
      if (!await requestUtilitySpend('azione', preferFreeReaction: false) ||
          !_statOpenCanAct ||
          origin !=
              (
                currentSheetScrollId(),
                permissionScope,
                onlineCombatEncounterId,
              )) {
        return;
      }
      final turns = statOpenValue(id, 'durationTurns').clamp(1, 20);
      final shield = statOpenOwnBuff(id) ? statOpenValue(id, 'allyShield') : 0;
      final source = '${statOpenName(id)} · Skill Open';
      OculumStructuredEffect echo(String recipient) => OculumStructuredEffect(
        id: 'stat_open:vital_echo:$recipient',
        type: 'modifica_statistica',
        target: _statOpenVitalEcho,
        valueExpression: '1',
        mode: 'finche_attivo',
        duration: '$turns',
        recipient: recipient,
      );
      commitStatOpenSkill(id);
      applyStructuredEffectsOnActivation(
        [
          echo('se_stesso'),
          if (allies.isNotEmpty) echo('alleato'),
          if (allies.isNotEmpty && shield > 0)
            OculumStructuredEffect(
              type: 'scudo',
              valueExpression: '$shield',
              recipient: 'alleato',
            ),
        ],
        source: source,
        applyFusionBonus: false,
      );
      aggiungiLog(
        '[${statOpenSkillName(id)}] Restituisce la Vita persa dopo ogni colpo per $turns turni.',
      );
      if (allies.isNotEmpty) {
        await deliverPendingSupport(
          minimum: allies.length,
          maximum: allies.length,
          selectedTags: allies,
          excludeSelf: true,
          sourcePrefix: source,
        );
      }
      if (mounted &&
          origin ==
              (
                currentSheetScrollId(),
                permissionScope,
                onlineCombatEncounterId,
              )) {
        await flushPendingCombatTurnResources();
        programmaSalvataggio();
      }
    } finally {
      _statOpenHealingBusy[this] = null;
    }
  }

  void healStatOpenVitalEcho(int hpLost, {String? packetId}) {
    if (hpLost <= 0 ||
        hpCorrenti() <= 0 ||
        outsideFight ||
        !currentCombatIsActive() ||
        activeStructuredEffectBonus(_statOpenVitalEcho) <= 0) {
      return;
    }
    if (packetId != null && !faunaReceipt('stat-open-vital-echo:$packetId')) {
      return;
    }
    applyStructuredHealing('vita', hpLost, ignoreCurse: true);
    sendRealtimeHpChanged();
    programmaSalvataggio();
  }

  void clearStatOpenFightEffects() {
    activeStructuredEffects.removeWhere(
      (effect) => effect['target'] == _statOpenVitalEcho,
    );
  }

  _OculumStat35Option _statOpenEditorOption(String id) => _OculumStat35Option(
    id,
    statOpenName(id),
    '',
    _statOpenForms[id]!.tier.values,
  );

  String _statOpenSkillSummary(String id) => switch (statOpenTrack(id)) {
    'will_knights' =>
      '${statOpenAttackCost(id) > 0 ? '${statOpenAttackCost(id)} Volontà · ' : ''}${statOpenKnightHitsFor(id)} colpi da ${statOpenValue(id, 'damagePercent')}% dei Danni, un tiro di Volontà.',
    'res_stone_memory' =>
      'Cura la Vita persa da te e dai tuoi alleati per ${statOpenValue(id, 'durationTurns')} turni personali.',
    'will_oath' =>
      'Ripartisce i Danni su ${statOpenValue(id, 'maxTargets')} nemici, aggiunge il ${statOpenValue(id, 'powerPercent')}% della Potenza a ciascuno e penalizza il loro prossimo attacco.',
    'matter_geometry' =>
      'Riposizionamento fino a ${statOpenValue(id, 'movement')} m. Precisione +${statOpenValue(id, 'precisionBonus')} contro un nemico.',
    'oculum_meridian' =>
      '${statOpenValue(id, 'cost')} Oculum. Ripartisce i Danni su ${statOpenValue(id, 'maxTargets')} nemici.',
    _ => '',
  };

  List<Widget> _statOpenFormTiles(
    String id,
    void Function(VoidCallback) select,
  ) {
    final state = statOpenProgress(id);
    final cooldown = statOpenSkillCooldown(id);
    return [
      ListTile(
        leading: const Icon(Icons.auto_awesome),
        trailing: _stat35CanEdit
            ? IconButton(
                tooltip: 'Parametri Open',
                icon: const Icon(Icons.tune),
                onPressed: () => select(
                  () => unawaited(_editStat35(_statOpenEditorOption(id))),
                ),
              )
            : null,
        title: Text('Open · ${statOpenName(id)}'),
        subtitle: Text(
          'Livello ${statOpenLevel(id)} · ${state.buffActive
              ? 'Open Buff attivo'
              : state.ready
              ? 'Attiva il suo Open Buff'
              : 'Recupero ai riposi'}',
        ),
        onTap: _statOpenCanAct && (state.ready || state.buffActive)
            ? () => select(() => toggleStatOpen(id))
            : null,
      ),
      ListTile(
        leading: const Icon(Icons.bolt),
        title: Text(statOpenSkillName(id)),
        subtitle: Text(
          cooldown > 0
              ? 'Recupero del percorso · $cooldown turni personali'
              : '1 Azione · ${_statOpenSkillSummary(id)}',
        ),
        onTap: statOpenSkillReady(id) && canPayStatOpenAttack(id)
            ? () => select(() => unawaited(activateStatOpenSkill(id)))
            : null,
      ),
    ];
  }

  List<Widget> statOpenActionWidgets(
    OculumCombatAbilityRole role, {
    required void Function(VoidCallback) select,
  }) {
    final widgets = <Widget>[];
    for (final entry in _statOpenTracks.entries) {
      final trackRole = entry.key == 'res_stone_memory'
          ? OculumCombatAbilityRole.support
          : OculumCombatAbilityRole.attack;
      if (role != trackRole) continue;
      final unlocked = _statOpenLevels
          .map((level) => '${entry.key}_$level')
          .where(statOpenUnlocked)
          .toList();
      if (unlocked.isEmpty) continue;
      final tiles = [
        for (final id in unlocked) ..._statOpenFormTiles(id, select),
      ];
      if (unlocked.length == 1) {
        widgets.addAll(tiles);
      } else {
        widgets.add(
          ExpansionTile(
            key: ValueKey('stat-open:${entry.key}'),
            title: Text('Open · ${entry.value.label}'),
            subtitle: Text('${unlocked.length} forme sbloccate'),
            children: tiles,
          ),
        );
      }
    }
    return widgets;
  }
}
