part of '../../main.dart';

extension _OculumNecromancerRuntime on _OculumHomePageState {
  bool isNecromancerSheet(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    return '${schedePersonaggio[index]['monsterBookSourceId'] ?? ''}'
        .startsWith('necromante_');
  }

  int necromancerMaxHpAt(int index) {
    final dashboardHp = masterDashboardEnemyMaxHpAt(index);
    if (dashboardHp > 0) return dashboardHp;
    return max(1, sheetIntValueAt(index, 'currentHp', fallback: 1));
  }

  List<Map<String, dynamic>> necromancerServantsAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return const [];
    final raw = schedePersonaggio[index]['necromancerServants'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: true);
  }

  bool ensureNecromancerServants(int index) {
    if (!isNecromancerSheet(index)) return false;
    final sheet = schedePersonaggio[index];
    final existing = necromancerServantsAt(index);
    if (existing.any((servant) => readIntValue(servant['currentHp']) > 0)) {
      return false;
    }
    final cooldownUntil = readIntValue(sheet['necromancerSummonCooldownUntil']);
    if (masterInitiativeRound < cooldownUntil) return false;
    final raiseLevel = (readIntValue(
      sheet['necromancerRaiseDeadLevel'],
      fallback: 1,
    )).clamp(1, 3).toInt();
    final levelBonus = switch (raiseLevel) {
      1 => 0,
      2 => 10,
      _ => 20,
    };
    // The summon uses the selected Oculum when the skill is activated. A
    // monster sheet without an activation uses that form's minimum cost.
    final defaultInvestment = switch (raiseLevel) {
      1 => 1,
      2 => 5,
      _ => 11,
    };
    final oculumInvestment = max(
      0,
      readIntValue(
        sheet['necromancerRaiseDeadOculum'],
        fallback: defaultInvestment,
      ),
    );
    final servantHp =
        10 + necromancerMaxHpAt(index) ~/ 3 + levelBonus + oculumInvestment;
    sheet['necromancerServants'] = [
      {
        'id': '${sheetTagAt(index)}:pawn:1',
        'name': 'Servitore d’ossa I',
        'currentHp': servantHp,
        'maxHp': servantHp,
      },
      {
        'id': '${sheetTagAt(index)}:pawn:2',
        'name': 'Servitore d’ossa II',
        'currentHp': servantHp,
        'maxHp': servantHp,
      },
    ];
    sheet['necromancerSummonCount'] =
        readIntValue(sheet['necromancerSummonCount']) + 1;
    aggiungiLog(
      '${nomeSchedaPersonaggio(index)} crea due servitori d’ossa: $servantHp HP ciascuno '
      '(grado $raiseLevel, Oculum immesso $oculumInvestment).',
    );
    return true;
  }

  int redirectNecromancerDamage(int index, int damage) {
    if (damage <= 0 || !isNecromancerSheet(index)) return max(0, damage);
    ensureNecromancerServants(index);
    final servants = necromancerServantsAt(index);
    if (servants.isEmpty) return damage;
    var remaining = damage;
    for (final servant in servants) {
      if (remaining <= 0) break;
      final current = max(0, readIntValue(servant['currentHp']));
      final absorbed = min(current, remaining);
      servant['currentHp'] = current - absorbed;
      remaining -= absorbed;
      if (absorbed > 0) {
        aggiungiLog(
          '${servant['name'] ?? 'Servitore scheletrico'} perde $absorbed HP '
          '(${servant['currentHp']}/${servant['maxHp']}): aiuta il necromante.',
        );
      }
    }
    schedePersonaggio[index]['necromancerServants'] = servants;
    if (servants.isNotEmpty &&
        servants.every((s) => readIntValue(s['currentHp']) <= 0)) {
      final until = masterInitiativeRound + 10;
      schedePersonaggio[index]['necromancerSummonCooldownUntil'] = until;
      aggiungiLog(
        '${nomeSchedaPersonaggio(index)} perde i servitori: richiamo disponibile al turno $until.',
      );
    }
    return remaining;
  }

  Widget necromancerServantsStatus(int index) {
    if (!isNecromancerSheet(index)) return const SizedBox.shrink();
    final servants = necromancerServantsAt(index);
    final alive = servants
        .where((s) => readIntValue(s['currentHp']) > 0)
        .length;
    final cooldown = readIntValue(
      schedePersonaggio[index]['necromancerSummonCooldownUntil'],
    );
    final label = alive > 0
        ? 'Servitori $alive/2 · danno assorbito'
        : cooldown > masterInitiativeRound
        ? 'Servitori caduti · richiamo R$cooldown'
        : 'Servitori pronti · si evocano al prossimo danno';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        label,
        key: ValueKey('necromancer_servants_${sheetTagAt(index)}'),
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  int companionAidCountAt(int index) {
    var count = 0;
    if (isNecromancerSheet(index)) {
      count += necromancerServantsAt(
        index,
      ).where((servant) => readIntValue(servant['currentHp']) > 0).length;
    }
    final tag = sheetTagAt(index);
    count += pawnGuardians
        .where(
          (pawn) =>
              pawn.alive &&
              !pawn.pendingRegistration &&
              pawn.targets.contains(tag),
        )
        .length;
    return count;
  }

  bool armCompanionAid(int index) {
    final count = companionAidCountAt(index);
    if (count <= 0) return false;
    schedePersonaggio[index]['companionAidPending'] = count;
    aggiungiLog(
      '${nomeSchedaPersonaggio(index)} prepara aiuto compagno +$count al prossimo tiro.',
    );
    // The extension is part of the State library and must refresh the Master
    // card immediately after arming the companion bonus.
    // ignore: invalid_use_of_protected_member
    setState(() {});
    programmaSalvataggio();
    return true;
  }
}
