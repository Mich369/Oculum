part of '../../main.dart';

const _fleshGolemFightKey = 'fleshGolemFight';

int oculumFleshGolemLifeLossBonus(
  int value, {
  required int lifeLost,
  required int maximumLife,
}) => value + (value * max(0, lifeLost) / max(1, maximumLife)).round();

extension _OculumFleshGolem on _OculumHomePageState {
  bool get _isFleshGolem => faunaCurrentMonsterId == 'golem_carne';

  String _fleshGolemFightId() =>
      '$permissionScope:$permissionCampaignId:$onlineCombatEncounterId:'
      '${combatSubtraitExperienceFightId(onlineCombatEncounterId)}';

  Map? _currentFleshGolemFight() {
    if (!_isFleshGolem || outsideFight || !currentCombatIsActive()) return null;
    final saved = planarState[_fleshGolemFightKey];
    return saved is Map && saved['fight'] == _fleshGolemFightId()
        ? saved
        : null;
  }

  void beginFleshGolemFight() {
    if (!_isFleshGolem ||
        outsideFight ||
        !currentCombatIsActive() ||
        _currentFleshGolemFight() != null ||
        realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente))) {
      return;
    }
    planarState[_fleshGolemFightKey] = {
      'fight': _fleshGolemFightId(),
      'maximumLife': maxHp(),
      'lifeLost': 0,
    };
  }

  void recordFleshGolemLifeLoss({required int hpLost, String? packetId}) {
    if (!_isFleshGolem ||
        hpLost <= 0 ||
        realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente))) {
      return;
    }
    beginFleshGolemFight();
    final fight = _currentFleshGolemFight();
    if (fight == null) return;
    if (packetId != null &&
        packetId.isNotEmpty &&
        !faunaReceipt('flesh-golem:${fight['fight']}:$packetId')) {
      return;
    }
    fight['lifeLost'] = max(0, readIntValue(fight['lifeLost'])) + hpLost;
  }

  int applyFleshGolemLifeLossBonus(int value) {
    final fight = _currentFleshGolemFight();
    if (fight == null) return value;
    return oculumFleshGolemLifeLossBonus(
      value,
      lifeLost: readIntValue(fight['lifeLost']),
      maximumLife: readIntValue(fight['maximumLife'], fallback: 1),
    );
  }

  void resetFleshGolemFight() {
    planarState.remove(_fleshGolemFightKey);
  }
}
