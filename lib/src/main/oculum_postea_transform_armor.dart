part of '../../main.dart';

const _posteaTransformKey = 'posteaTransformArmorRuntime';
const _posteaTransformStats = ['resilienza', 'volonta', 'materia', 'oculum'];
const _posteaTransformResources = ['hp', ..._posteaTransformStats];
final _posteaTransformTrackingPaused = Expando<bool>();

extension _OculumPosteaTransformArmor on _OculumHomePageState {
  Map? get _posteaTransformState {
    final value = planarState[_posteaTransformKey];
    return value is Map ? value : null;
  }

  int get posteaTransformTurns =>
      max(0, readIntValue(_posteaTransformState?['turns']));

  InventoryItem? get equippedPosteaTransformArmor => protezioniEquipaggiate()
      .where(
        (item) =>
            item.quantita > 0 && item.craftData['posteaTransformArmor'] == true,
      )
      .firstOrNull;

  bool get posteaTransformArmorUsed => _posteaTransformState?['used'] == true;

  bool get canActivatePosteaTransformArmor =>
      equippedPosteaTransformArmor != null &&
      !posteaTransformArmorUsed &&
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      (realtimeService?.isConnected != true ||
          controlsOnlineCombatSheet(sheetTagAt(schedaCorrente)));

  TextEditingController _posteaTransformController(String key) =>
      key == 'hp' ? currentHpController : currentStatController(key);

  int _posteaTransformRaw(String key) {
    final raw = leggiNumero(_posteaTransformController(key));
    return key == 'oculum' ? raw - max(0, temporaryOculum) : raw;
  }

  int posteaTransformBuffer(String key) {
    final buffers = _posteaTransformState?['buffers'];
    return buffers is Map ? max(0, readIntValue(buffers[key])) : 0;
  }

  int get posteaTransformShieldRemaining =>
      max(0, readIntValue(_posteaTransformState?['shield']));

  void installPosteaTransformResourceTracking() {
    for (final key in _posteaTransformResources) {
      _posteaTransformController(key).addListener(() {
        if (loadingThresholdSheet ||
            _posteaTransformTrackingPaused[this] == true) {
          return;
        }
        final state = _posteaTransformState;
        final buffers = state?['buffers'];
        final last = state?['last'];
        if (buffers is! Map || last is! Map) return;
        final value = _posteaTransformRaw(key);
        final spent = max(0, readIntValue(last[key], fallback: value) - value);
        if (spent > 0) {
          buffers[key] = max(0, readIntValue(buffers[key]) - spent);
        }
        last[key] = value;
      });
    }
  }

  T withoutPosteaTransformResourceTracking<T>(T Function() action) {
    final paused = _posteaTransformTrackingPaused[this];
    _posteaTransformTrackingPaused[this] = true;
    try {
      return action();
    } finally {
      _posteaTransformTrackingPaused[this] = paused;
    }
  }

  void activatePosteaTransformArmor() {
    if (!canActivatePosteaTransformArmor) return;
    final item = equippedPosteaTransformArmor!;
    final data = item.craftData;
    final hpPercent = readIntValue(
      data['posteaTransformHpPercent'],
      fallback: 150,
    ).clamp(100, 500).toInt();
    final statsPercent = readIntValue(
      data['posteaTransformStatsPercent'],
      fallback: 130,
    ).clamp(100, 500).toInt();
    final turns = max(
      1,
      readIntValue(data['posteaTransformDurationTurns'], fallback: 3),
    );
    final shield = max(
      0,
      readIntValue(data['posteaTransformShield'], fallback: 400),
    );
    final buffs = {
      'hp': hpCorrenti() * (hpPercent - 100) ~/ 100,
      for (final key in _posteaTransformStats)
        key: max(0, currentStatValue(key)) * (statsPercent - 100) ~/ 100,
    };
    final state = <String, dynamic>{
      'used': true,
      'turns': turns,
      'shield': shield,
      'buffers': buffs,
      'last': <String, int>{},
    };
    planarState[_posteaTransformKey] = state;
    withoutPosteaTransformResourceTracking(() {
      for (final entry in buffs.entries) {
        if (entry.value <= 0) continue;
        final controller = _posteaTransformController(entry.key);
        controller.text = '${leggiNumero(controller) + entry.value}';
      }
    });
    state['last'] = {
      for (final key in _posteaTransformResources)
        key: _posteaTransformRaw(key),
    };
    clearNormalShieldBreakPenaltyIfProtected();
    aggiungiLog(
      '[POSTEA] ${item.nome}: trasformazione per $turns turni personali.',
    );
    _publishPosteaTransformResources();
  }

  int normalShieldTargetAfterPosteaTransform(int target) {
    final temporary = posteaTransformShieldRemaining;
    if (temporary <= 0) return target;
    final spent = min(temporary, max(0, scudo() - target));
    final remaining = temporary - spent;
    if (spent > 0) _posteaTransformState!['shield'] = remaining;
    return max(0, target - remaining);
  }

  void tickPosteaTransformArmor() {
    final turns = posteaTransformTurns;
    if (turns == 1) {
      endPosteaTransformArmor();
    } else if (turns > 1) {
      _posteaTransformState!['turns'] = turns - 1;
    }
  }

  void resetPosteaTransformArmorAtLongRest() {
    endPosteaTransformArmor(publish: false);
    planarState.remove(_posteaTransformKey);
  }

  void endPosteaTransformArmor({bool publish = true}) {
    if (posteaTransformTurns <= 0) return;
    final left = {
      for (final key in _posteaTransformResources)
        key: posteaTransformBuffer(key),
    };
    planarState[_posteaTransformKey] = {'used': true};
    for (final entry in left.entries) {
      if (entry.value <= 0) continue;
      final controller = _posteaTransformController(entry.key);
      final value = leggiNumero(controller) - entry.value;
      controller.text = '${entry.key == 'hp' ? max(0, value) : value}';
    }
    invalidateDerivedDataCaches();
    if (publish) {
      aggiungiLog('[POSTEA] Trasformazione terminata.');
      _publishPosteaTransformResources();
    }
  }

  void _publishPosteaTransformResources() {
    invalidateDerivedDataCaches();
    syncVisibleCurrentStatEditors();
    notifyOculumResourceChanged();
    sendRealtimeHpChanged();
    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
  }
}
