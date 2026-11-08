part of '../../main.dart';

const _stat35OculumOverflowKey = 'stat35OculumOverflow';

extension _OculumStat35Resource on _OculumHomePageState {
  bool get canUseStat35OculumBlast =>
      hasStat35Choice('oculum', 'oculum_blast') &&
      currentCombatIsActive() &&
      !outsideFight &&
      stat35Cooldown('oculum_blast') == 0 &&
      !hasCondition('oculum_sigillato') &&
      oculumTotale() >= stat35OculumBlastCost;

  int get stat35OculumBlastCost =>
      max(0, stat35Value('oculum_blast', 'cost', fallback: 4));

  int get stat35OculumBlastDamage =>
      stat35Value('oculum_blast', 'baseDamage', fallback: 100) +
      activeCriticalLevel() *
          stat35Value('oculum_blast', 'perLevel', fallback: 3);

  Future<void> activateStat35OculumBlast() async {
    if (canUseStat35OculumBlast) {
      await planOnlineAttack(stat35OculumBlast: true);
    }
  }

  bool commitStat35OculumBlast() {
    if (!canUseStat35OculumBlast) return false;
    final cost = stat35OculumBlastCost;
    if (cost > 0 && spendOculum(cost) != cost) return false;
    setStat35Cooldown(
      'oculum_blast',
      stat35Value('oculum_blast', 'cooldown', fallback: 5),
    );
    return true;
  }

  int get stat35OculumOverflow => min(
    temporaryOculum,
    max(0, readIntValue(planarState[_stat35OculumOverflowKey])),
  );

  void setStat35OculumOverflow(int value) {
    if (value <= 0) {
      planarState.remove(_stat35OculumOverflowKey);
    } else {
      planarState[_stat35OculumOverflowKey] = value;
    }
  }

  void endStat35OculumOverflow() {
    final amount = stat35OculumOverflow;
    if (amount == 0) return;
    final before = currentTemporaryOculumState();
    setStat35OculumOverflow(0);
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: before.normalCurrent,
        temporary: before.temporary - amount,
        rollsRemaining: before.rollsRemaining,
      ),
    );
  }

  Future<void> activateStat35OculumReload() async {
    const id = 'oculum_reload';
    if (!hasStat35Choice('oculum', id) ||
        !stat35RestReady(id) ||
        !currentCombatIsActive() ||
        outsideFight ||
        hasCondition('vuoto')) {
      return;
    }
    final origin = currentSheetScrollId();
    if (!await requestUtilitySpend('azione') ||
        !mounted ||
        currentSheetScrollId() != origin ||
        !stat35RestReady(id)) {
      return;
    }
    final faces = max(2, stat35Value(id, 'die', fallback: 10));
    final natural = 1 + Random.secure().nextInt(faces);
    final amount = natural + activeCriticalLevel();
    final before = currentTemporaryOculumState();
    final permanentGain = min(
      amount,
      max(0, _currentOculumCapacity - before.normalCurrent),
    );
    final overflow = amount - permanentGain;
    setStat35OculumOverflow(stat35OculumOverflow + overflow);
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: before.normalCurrent + permanentGain,
        temporary: before.temporary + overflow,
        rollsRemaining: before.rollsRemaining,
      ),
    );
    spendStat35RestUse(id, long: true);
    aggiungiLog(
      '[RICARICA RAPIDA] d$faces $natural + livello ${activeCriticalLevel()} · +$amount Oculum, di cui $overflow fino a fine fight.',
    );
    showSheetStatGain('oculum', amount);
    programmaSalvataggio();
    await flushPendingCombatTurnResources();
  }

  void recordStat35OculumHit(Map request) {
    final receipt = request['damageReceipt'];
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    if (encounter.isEmpty ||
        packet.isEmpty ||
        receipt is! Map ||
        !const [
          'hpLost',
          'temporaryHpLost',
          'shieldLost',
          'oculumShieldLost',
        ].any((key) => readIntValue(receipt[key]) > 0)) {
      return;
    }
    faunaForOwnedSheet('${request['sourceTag'] ?? ''}', () {
      const id = 'oculum_regen';
      if (!hasStat35Choice('oculum', id) ||
          encounter != onlineCombatEncounterId ||
          !currentCombatIsActive() ||
          !faunaReceipt('stat35-oculum:$encounter:$packet')) {
        return;
      }
      final fight = combatSubtraitExperienceFightId(encounter);
      final previous = planarState['stat35OculumHits'];
      final landedStrikes =
          statOpenTrack('${request['statOpenId'] ?? ''}') == 'will_knights'
          ? readIntValue(receipt['landedStrikes'], fallback: 1).clamp(1, 100)
          : 1;
      final hits =
          landedStrikes +
          (previous is Map && previous['fight'] == fight
              ? readIntValue(previous['count'])
              : 0);
      final threshold = max(1, stat35Value(id, 'hits', fallback: 6));
      planarState['stat35OculumHits'] = {
        'fight': fight,
        'count': hits % threshold,
      };
      if (hits >= threshold && normalCurrentOculum() < _currentOculumCapacity) {
        addOculum(
          min(
            _currentOculumCapacity - normalCurrentOculum(),
            (hits ~/ threshold) *
                max(0, stat35Value(id, 'amount', fallback: 1)),
          ),
        );
      }
      programmaSalvataggio();
    });
  }
}
