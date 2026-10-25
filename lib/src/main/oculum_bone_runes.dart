part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumMortalKiAmount(int current, int divisor) =>
    max(0, current) ~/ divisor.clamp(3, 6);
int oculumMortalKiHuntBonus(int die) => die.clamp(1, 10) >= 6 ? 10 : 5;
int oculumBoneSlashDamage(int base, int hits, int percent) =>
    (max(0, base) * .5 * (1 + max(0, hits) * max(0, percent) / 100)).floor();

extension _OculumBoneRunes on _OculumHomePageState {
  String get faunaCurrentMonsterId =>
      schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
      ? '${schedePersonaggio[schedaCorrente]['monsterBookSourceId'] ?? ''}'
      : '';
  int get mortalKi => max(0, readIntValue(planarState['mortalKi']));
  bool get mortalKiLocked =>
      readIntValue(planarState['mortalKiLock']) > 0 ||
      hasCondition('oculum_sigillato');
  int spendMortalKi(int amount) {
    if (amount < 0 || mortalKiLocked || mortalKi < amount) return 0;
    planarState['mortalKi'] = mortalKi - amount;
    programmaSalvataggio();
    return amount;
  }

  Future<void> activateMortalKi({int? natural}) async {
    if (mortalKiLocked) return;
    final level = max(0, leggiNumero(livelloController));
    final divisor = readIntValue(
      planarState['mortalKiDivisor'],
      fallback: 6,
    ).clamp(3, 6);
    final die = natural ?? tiraD20(countsAsCooldownRoll: false);
    var amount = oculumMortalKiAmount(oculumTotale(), divisor);
    if (planarState['mortalKiHuntBonus'] == true ||
        faunaPassive('monk_ki_hunt') != null) {
      amount += oculumMortalKiHuntBonus(Random.secure().nextInt(10) + 1);
    }
    if (die == 20) planarState['mortalKiDivisor'] = max(3, divisor - 1);
    if (amount < 5) {
      for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
        activeStructuredEffects.add({
          'effectId': 'mortal_ki_$stat',
          'source': 'Ki Mortale',
          'type': 'modifica_statistica',
          'target': stat,
          'value': amount,
          'mode': 'temporaneo',
          'remaining': 1,
          'unit': 'azioni',
        });
      }
      aggiungiLog(
        '[KI MORTALE] $amount Ki diventano +$amount alle quattro statistiche per una Azione.',
      );
    } else {
      planarState['mortalKi'] = mortalKi + amount;
      planarState['mortalKiMaximum'] = max(
        mortalKi,
        readIntValue(planarState['mortalKiMaximum']),
      );
      aggiungiLog(
        '[KI MORTALE] +$amount Ki verdi (Oculum attuale ÷$divisor), disponibili $mortalKi. Azione extra; 5 Ki per una Reazione veloce, oppure usali nei costi Oculum. Dado $die${die == 20 ? ': divisore migliorato per la prossima attivazione' : ''}. Livello $level.',
      );
    }
    await requestUtilitySpend('ki_grant_action', preferFreeReaction: false);
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  Future<void> mortalKiReaction() async {
    if (mortalKiLocked || mortalKi < 5) return;
    if (await requestUtilitySpend(
      'speed_grant_fast',
      preferFreeReaction: false,
    )) {
      spendMortalKi(5);
      aggiungiLog('[KI MORTALE] −5 Ki: una Reazione veloce extra.');
    }
  }

  Widget mortalKiBar() {
    if (mortalKi <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ki Mortale${mortalKiLocked ? ' · sigillato' : ''}',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ),
              Text(
                '$mortalKi/${max(1, readIntValue(planarState['mortalKiMaximum'], fallback: mortalKi))}',
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value:
                (mortalKi /
                        max(
                          1,
                          readIntValue(
                            planarState['mortalKiMaximum'],
                            fallback: mortalKi,
                          ),
                        ))
                    .clamp(0, 1),
            color: Colors.greenAccent,
            backgroundColor: Colors.black54,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: mortalKi >= 5 && !mortalKiLocked
                  ? () => unawaited(mortalKiReaction())
                  : null,
              child: const Text('5 Ki → Reazione veloce'),
            ),
          ),
        ],
      ),
    );
  }

  void tickBoneRuneTurn() {
    if (readIntValue(planarState['mortalKiLock']) > 0) {
      planarState['mortalKiLock'] =
          readIntValue(planarState['mortalKiLock']) - 1;
    }
  }

  void boneRuneAfterHpDamage() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    if (schedePersonaggio[schedaCorrente]['monsterBookSourceId'] == 'teirak' &&
        hpCorrenti() > 0 &&
        hpCorrenti() * 100 <= maxHp() * 60 &&
        planarState['teirakMemoryUsed'] != true) {
      planarState['teirakMemoryUsed'] = true;
      applyCondition('ricordo_vitale', duration: 6, source: 'Rune di Teirak');
      aggiungiLog(
        '[TEIRAK] Le rune custodiscono il ricordo della Vita: Ricordo Vitale per 6 turni.',
      );
    }
  }

  void restoreOgorEnergy() {
    if (planarState['ogorRestoreUsed'] == true) return;
    planarState.remove('mortalKiLock');
    for (final c
        in activeConditions
            .where((c) => c.conditionType == 'oculum_sigillato')
            .toList()) {
      removeCondition(c, force: true);
    }
    planarState['ogorRestoreUsed'] = true;
    addOculum(3);
    aggiungiLog(
      '[RIPRISTINA ENERGIA] Flusso Oculum riattivato, +3 Oculum entro il massimo.',
    );
  }

  void resolveBoneRuneWeakPoint(Map request, int lost) {
    if (lost <= 0 || request['targetWeakPointPrecision'] != true) return;
    final monster =
        '${schedePersonaggio[schedaCorrente]['monsterBookSourceId']}';
    final key = '${request['id'] ?? request['attackGroupId']}';
    if (!faunaReceipt('weak-bone:$key')) return;
    if (monster == 'teschio_quattro_lame' &&
        !criticalShieldBlocksDebuffs(request) &&
        (request['forcedCritical'] == true ||
            readIntValue(request['natural']) >= 20 ||
            oculumAttackIsCritical(
              readIntValue(request['attack']),
              readIntValue(request['defense']),
            ))) {
      final broken = (planarState['boneBrokenArmIds'] as List? ?? [])
          .map((id) => '$id')
          .toSet();
      final selected = '${request['targetBodyPart'] ?? ''}';
      final arm = selected.startsWith('arms_')
          ? selected
          : [
              for (var i = 1; i <= 4; i++) 'arms_$i',
            ].where((id) => !broken.contains(id)).firstOrNull;
      if (arm != null) broken.add(arm);
      planarState['boneBrokenArmIds'] = broken.toList();
      planarState['boneBrokenArms'] = broken.length.clamp(0, 4);
      aggiungiLog(
        '[PUNTO DEBOLE] Braccia spezzate ${planarState['boneBrokenArms']}/4.',
      );
    }
    if (monster == 'ogor') {
      planarState['ogorCoreHits'] = min(
        3,
        readIntValue(planarState['ogorCoreHits']) + 1,
      );
      aggiungiLog(
        '[NUCLEO] Colpi al nucleo ${planarState['ogorCoreHits']}/3${readIntValue(planarState['ogorCoreHits']) >= 3 ? ': rotto, Raggio Oculum bloccato' : ''}.',
      );
    }
    for (final item in inventario.where(
      (i) =>
          i.equipaggiata &&
          i.craftData['ogorCore'] == true &&
          i.craftData['broken'] != true,
    )) {
      final hits = min(3, readIntValue(item.craftData['weakPointHits']) + 1);
      item.craftData = {
        ...item.craftData,
        'weakPointHits': hits,
        'broken': hits >= 3,
      };
      if (hits >= 3) {
        aggiungiLog(
          '[NUCLEO DI OCULUM] Terzo colpo al punto debole: il nucleo equipaggiato si rompe.',
        );
      }
    }
  }

  void ogorCoreSuccessfulRoll(String receipt) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    if (!faunaReceipt('ogor-roll:$receipt')) return;
    if (schedePersonaggio[schedaCorrente]['monsterBookSourceId'] == 'ogor' &&
        readIntValue(planarState['ogorCoreHits']) < 3 &&
        readIntValue(planarState['ogorCoreRolls']) < 5) {
      if (addOculum(1) > 0) {
        planarState['ogorCoreRolls'] =
            readIntValue(planarState['ogorCoreRolls']) + 1;
      }
    }
    for (final item in inventario.where(
      (i) =>
          i.equipaggiata &&
          canEquipInventoryItem(i) &&
          i.craftData['ogorCore'] == true &&
          i.craftData['broken'] != true,
    )) {
      final used = readIntValue(item.craftData['successfulRolls']);
      if (used >= 5) continue;
      if (addOculum(1) > 0) {
        item.craftData = {...item.craftData, 'successfulRolls': used + 1};
        aggiungiLog(
          '[NUCLEO DI OCULUM] Tiro riuscito: +1 Oculum (${used + 1}/5 fino al riposo).',
        );
      }
      break;
    }
  }

  void resetBoneRuneFight() {
    for (final key in [
      'teirakMemoryUsed',
      'boneFourSlash',
      'boneBrokenArms',
      'boneBrokenArmIds',
    ]) {
      planarState.remove(key);
    }
  }

  void resetOgorCoreRest({bool long = false}) {
    planarState.remove('ogorCoreRolls');
    for (final item in inventario.where(
      (i) => i.craftData['ogorCore'] == true,
    )) {
      item.craftData = {...item.craftData, 'successfulRolls': 0};
    }
    if (long) planarState.remove('ogorRestoreUsed');
  }
}
