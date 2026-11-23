part of '../../main.dart';

extension _OculumRebirthRuntime on _OculumHomePageState {
  String get rebirthCampaignDay =>
      '$activeCampaignId:${max(0, worldClockSeconds) ~/ oculumWorldDaySeconds}';

  bool get rebirthCriticalAvailable => oculumRebirthCriticalAvailable(
    rebirthed: rebirthato,
    campaignDay: rebirthCampaignDay,
    state: planarState,
  );

  bool consumeRebirthCritical() {
    if (!rebirthCriticalAvailable) return false;
    final next = oculumConsumeRebirthCritical(planarState, rebirthCampaignDay);
    planarState['rebirthCriticalDaysUsed'] = next['rebirthCriticalDaysUsed'];
    aggiungiLog('[REBIRTH] Critico negativo trasformato in positivo (100%). Uso del giorno della campagna consumato.');
    programmaSalvataggio();
    return true;
  }

  int get rebirthExperienceKillsRemaining {
    final raw = planarState['rebirthExperience'];
    return raw is Map ? max(0, readIntValue(raw['remaining'])) : 0;
  }
}

extension OculumRebirthProbe on OculumPerformanceProbe {
  Future<void> requestRebirth(bool value) => _state.toggleRebirth(value);
  bool get rebirthDailyCriticalAvailable => _state.rebirthCriticalAvailable;
  bool consumeRebirthDailyCritical() => _state.consumeRebirthCritical();
  int get rebirthKillsRemaining => _state.rebirthExperienceKillsRemaining;
}
