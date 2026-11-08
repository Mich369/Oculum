part of '../../main.dart';

const _stat20OculumSphere = 'oculum_sphere';
const _stat20OculumReload = 'oculum_still_reload';
const _stat20OculumChargeKey = 'stat20OculumCharge';
final _stat20OculumCharging = Expando<bool>();

extension _OculumStat20Resource on _OculumHomePageState {
  bool get _stat20OculumCanAct =>
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      controlsOnlineCombatSheet(sheetTagAt(schedaCorrente));

  bool get stat20OculumChargeActive =>
      currentCombatIsActive() &&
      planarState[_stat20OculumChargeKey] == onlineCombatEncounterId;

  bool get stat20OculumSphereReady =>
      _stat20OculumCanAct &&
      stat20Choice('oculum') == _stat20OculumSphere &&
      !hasCondition('oculum_sigillato') &&
      !stat20OculumChargeActive;

  int get stat20OculumSphereDamage => max(
    0,
    dannoTotale() +
        stat35Value(_stat20OculumSphere, 'baseDamage', fallback: 30),
  );

  int get stat20OculumSphereFactor => stat35Value(
    _stat20OculumSphere,
    'noOculumFactor',
    fallback: 2,
  ).clamp(1, 10);

  int stat20OculumSphereDamageOnTarget(int damage, int factor) =>
      oculumMassimoNaturale() > 0 ? damage : damage * factor.clamp(1, 10);

  Future<void> activateStat20OculumSphere() async {
    if (stat20OculumSphereReady) {
      await planOnlineAttack(stat20OculumSphere: true);
    }
  }

  bool get stat20OculumCanStartCharge =>
      _stat20OculumCanAct &&
      stat20Choice('oculum') == _stat20OculumReload &&
      !stat20OculumChargeActive &&
      !hasCondition('oculum_sigillato') &&
      normalCurrentOculum() < _currentOculumCapacity;

  Future<void> activateStat20OculumReload() async {
    if (!stat20OculumCanStartCharge || _stat20OculumCharging[this] == true) {
      return;
    }
    final origin = (
      currentSheetScrollId(),
      permissionScope,
      onlineCombatEncounterId,
    );
    _stat20OculumCharging[this] = true;
    try {
      if (!await requestUtilitySpend('azione', preferFreeReaction: false) ||
          !mounted ||
          origin !=
              (
                currentSheetScrollId(),
                permissionScope,
                onlineCombatEncounterId,
              ) ||
          !stat20OculumCanStartCharge) {
        return;
      }
      planarState[_stat20OculumChargeKey] = onlineCombatEncounterId;
      aggiungiLog(
        '[RICARICA DELL’OCULUM] In carica fino al prossimo turno personale.',
      );
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
      await flushPendingCombatTurnResources();
    } finally {
      _stat20OculumCharging[this] = null;
    }
  }

  void interruptStat20OculumCharge() {
    if (!stat20OculumChargeActive) return;
    planarState.remove(_stat20OculumChargeKey);
    aggiungiLog(
      '[RICARICA DELL’OCULUM] Il colpo ha superato gli Scudi e interrotto la carica.',
    );
    programmaSalvataggio();
  }

  void tickStat20OculumCharge() {
    if (!stat20OculumChargeActive) return;
    planarState.remove(_stat20OculumChargeKey);
    if (hpCorrenti() <= 0 || outsideFight || hasCondition('oculum_sigillato')) {
      return;
    }
    final faces = stat35Value(
      _stat20OculumReload,
      'die',
      fallback: 25,
    ).clamp(2, 250);
    final natural = Random.secure().nextInt(faces) + 1;
    final before = normalCurrentOculum();
    addOculum(natural);
    final recovered = max(0, normalCurrentOculum() - before);
    aggiungiLog(
      '[RICARICA DELL’OCULUM] 1d$faces = $natural · +$recovered Oculum.',
    );
    if (recovered > 0) showSheetStatGain('oculum', recovered);
    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
  }
}
