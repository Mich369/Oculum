part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumConstructCoreMaximum(int maximumHp) => max(15, maximumHp ~/ 4);
int oculumConstructCoreSpillChance(int level) => max(1, 40 - max(0, level));
({int hp, int oculum}) oculumConstructLastStrength(
  int maximumHp,
  int currentOculum,
  int d150,
) => (
  hp: d150.clamp(1, 150) + max(0, maximumHp) ~/ 2,
  oculum: (max(0, currentOculum) + 3) * 3 ~/ 2,
);

extension _OculumRacialRuntime on _OculumHomePageState {
  String get activeRacialRulesText => trattiRazziali
      .where((t) => t.equipaggiato)
      .map((t) => '${t.buff}\n${t.skill}')
      .join('\n');
  bool get raceBreathesWater => activeRacialRulesText.contains('@RespiraAcqua');
  bool get racePerfectDarkvision =>
      activeRacialRulesText.contains('@VisioneBuio') ||
      trattiRazziali.any(
        (t) => t.equipaggiato && t.chiaveSistema == 'tutorial_race_mhunan',
      );
  bool get isConstructCharacter =>
      activeRacialRulesText.contains('@Costrutto') ||
      monsterBookEntryById(faunaCurrentMonsterId)?.formTags.any(
            (t) => const [
              'costrutto',
              'automa',
              'robot',
            ].contains(t.toLowerCase()),
          ) ==
          true;

  int racialSubtraitRollBonus(String id) {
    var bonus = 0;
    for (final match in RegExp(
      r'@RazzaVantaggio\s+(\w+)\s+(-?\d+)',
      caseSensitive: false,
    ).allMatches(activeRacialRulesText)) {
      if (match.group(1)?.toLowerCase() == id.toLowerCase()) {
        bonus = max(bonus, readIntValue(match.group(2)));
      }
    }
    return bonus;
  }

  Map<String, dynamic> get constructCore {
    if (planarState['constructCore'] is! Map<String, dynamic>) {
      planarState['constructCore'] = Map<String, dynamic>.from(
        planarState['constructCore'] as Map? ?? {},
      );
    }
    return planarState['constructCore'] as Map<String, dynamic>;
  }

  int get constructCoreMaximum => max(
    1,
    readIntValue(
      constructCore['maximumOverride'],
      fallback: oculumConstructCoreMaximum(maxHp()),
    ),
  );
  int get constructCoreHp => readIntValue(
    constructCore['hp'],
    fallback: constructCoreMaximum,
  ).clamp(0, constructCoreMaximum);
  bool get constructLastStrengthAvailable =>
      isConstructCharacter &&
      constructCoreHp > 0 &&
      constructCore['lastAttackCore'] != true &&
      constructCore['used'] != true;

  /// Runs only after a real damage path reaches zero; the spent flag is saved
  /// before any observer or online notification can run it again.
  bool tryConstructLastStrength({int? roll}) {
    if (hpCorrenti() > 0 || !constructLastStrengthAvailable) return false;
    final rolled = roll ?? Random.secure().nextInt(150) + 1;
    final result = oculumConstructLastStrength(
      maxHp(),
      currentOculum(),
      rolled,
    );
    constructCore['used'] = true;
    constructCore['overflowAllowed'] = true;
    constructCore['lastStrengthRoll'] = rolled;
    currentHpController.text = '${result.hp}';
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: result.oculum,
        temporary: 0,
        rollsRemaining: 0,
      ),
    );
    personaggioCaduto = false;
    personaggioSvenuto = false;
    aggiungiLog(
      '[ULTIME FORZE] Azione gratuita automatica: 1d150 ($rolled) + metà Vita massima = ${result.hp} Vita; (Oculum attuale + 3) ×1,5 = ${result.oculum} Oculum. Può superare i massimi.',
    );
    programmaSalvataggio();
    syncCurrentSheetDeathStateToInitiative();
    return true;
  }

  int applyConstructCoreDamage(int damage, {int? percentile}) {
    if (!isConstructCharacter) return damage;
    final before = constructCoreHp;
    constructCore['hp'] = max(0, before - max(0, damage));
    final chance = oculumConstructCoreSpillChance(activeCriticalLevel());
    final spill = (percentile ?? Random.secure().nextInt(100)) < chance
        ? max(0, damage) ~/ 4
        : 0;
    aggiungiLog(
      '[NUCLEO] Difesa e Scudi già applicati: $damage Danni al nucleo ($before → $constructCoreHp/$constructCoreMaximum); probabilità $chance%, $spill Danni anche al corpo.',
    );
    return spill;
  }

  void restConstructCore() {
    if (!isConstructCharacter) return;
    constructCore['hp'] = constructCoreMaximum;
    constructCore['used'] = false;
    constructCore['lastAttackCore'] = false;
    // An overflow already earned remains consumable; resting must not erase HP.
  }

  Future<void> repairOwnConstructCore() async {
    final candidates =
        hiddenEyeStats
            .where(
              (s) =>
                  s.unlocked && const ['meccanica', 'crafting'].contains(s.id),
            )
            .toList()
          ..sort((a, b) => hiddenEyeTotal(b).compareTo(hiddenEyeTotal(a)));
    if (!isConstructCharacter ||
        candidates.isEmpty ||
        !await spendCombatRollResource()) {
      return;
    }
    final owner = currentSheetScrollId();
    final difficulty = 15 + activeCriticalLevel();
    await tiraSottotrattoOcchio(
      candidates.first,
      actionLabel: 'Riparazione nucleo · DT $difficulty',
      resourceAlreadySpent: true,
      onResolved: (natural, total) {
        if (!mounted || owner != currentSheetScrollId()) return;
        if (natural != 1 && total >= difficulty) {
          constructCore['hp'] = constructCoreMaximum;
          aggiungiLog(
            '[NUCLEO] Riparato con ${candidates.first.nome}: $total, Vita $constructCoreHp.',
          );
          programmaSalvataggio();
          notifyActiveSheetSummaryChanged();
        } else {
          aggiungiLog(
            '[NUCLEO] Riparazione non riuscita: $total contro $difficulty.',
          );
        }
      },
    );
  }

  Widget racialCapabilitiesPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (raceBreathesWater)
        const Text('Respirazione acquatica · puoi respirare sott’acqua'),
      if (racePerfectDarkvision)
        const Text('Vista lunare · visione perfetta al buio'),
      if (racialSubtraitRollBonus('alchimia') > 0 ||
          racialSubtraitRollBonus('crafting') > 0)
        Text(
          'Madre Natura · Vantaggio Alchimia +${racialSubtraitRollBonus('alchimia')} / Crafting +${racialSubtraitRollBonus('crafting')}',
        ),
      if (isConstructCharacter) ...[
        Text(
          'Nucleo $constructCoreHp / $constructCoreMaximum · Ultime forze ${constructCore['used'] == true ? 'da recuperare al Riposo' : 'disponibile se il nucleo è valido'}',
        ),
        OutlinedButton.icon(
          onPressed: repairOwnConstructCore,
          icon: const Icon(Icons.build_outlined),
          label: const Text('Ripara il nucleo · Crafting / Meccanica'),
        ),
        ExpansionTile(
          title: const Text('Personalizza il nucleo'),
          children: [
            campoModello(
              label: 'Vita massima del nucleo (0: automatica)',
              initialValue: '${readIntValue(constructCore['maximumOverride'])}',
              onChanged: (v) {
                final n = readIntValue(v);
                n > 0
                    ? constructCore['maximumOverride'] = n
                    : constructCore.remove('maximumOverride');
                programmaSalvataggio();
              },
            ),
          ],
        ),
      ],
    ],
  );
}
