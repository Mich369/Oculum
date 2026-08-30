part of '../../main.dart';

// Extension methods intentionally invoke the owning State's scoped rebuild.
// ignore_for_file: invalid_use_of_protected_member

/// Regole centrali e serializzabili degli Occhi dei Caduti.  Sono top-level
/// per poter essere testate senza widget e non dipendono dalla UI.
const Map<String, Map<String, int>> oculumFallenEyeReforgeChances = {
  'facile': {'non_comune': 80, 'raro': 70, 'oculum': 45},
  'medio': {'non_comune': 80, 'raro': 60, 'oculum': 35},
  'difficile': {'non_comune': 70, 'raro': 45, 'oculum': 25},
  'oculum': {'non_comune': 60, 'raro': 35, 'oculum': 15},
};

/// Configurazione unica degli EXP flat assegnati da un evento di evocazione.
const Map<String, int> oculumFallenEyeSummonXp = {
  'facile': 150,
  'medio': 100,
  'difficile': 75,
  'oculum': 50,
};

/// Costo per evocare un Occhio aggiuntivo: la prima evocazione è gratuita;
/// dalla seconda la difficoltà più alta richiede una soglia di Oculum maggiore.
/// Se l'Oculum corrente è 0, si può pagare la stessa soglia in Volontà.
const Map<String, int> oculumFallenEyeSummonOculumCost = {
  'facile': 1,
  'medio': 2,
  'difficile': 3,
  'oculum': 4,
};

/// Dal secondo Occhio creato la manifestazione va tenuta con un tiro alto.
/// Dal terzo in poi ogni Occhio aggiuntivo pesa davvero sulla concentrazione;
/// gli insuccessi consecutivi fanno crescere ulteriormente la pressione.
const int oculumFallenEyeMaintenanceBaseDifficulty = 18;
const int oculumFallenEyeMaintenanceExtraEyeDifficulty = 3;
const int oculumFallenEyeMaintenanceFailureDifficulty = 2;

/// Un Occhio appena custodito può risvegliare un solo attributo raro. La
/// scelta è del giocatore dopo il tiro, non viene mai riassegnata ai riavvii.
const int oculumFallenEyeRareAttributeChancePercent = 26;
const int oculumFallenEyeRareDamageBonus = 50;
const int oculumFallenEyeRareDefenseBonus = 35;

bool oculumFallenEyeWinsRareAttributeRoll(int roll) =>
    roll >= 0 && roll < oculumFallenEyeRareAttributeChancePercent;

String oculumFallenEyeRareAttributeLabel(String value) => switch (value) {
  'danno' => 'Danno Aggiuntivo',
  'difesa' => 'Difesa Aggiuntiva',
  _ => '',
};

int oculumFallenEyeRareAttributeBonusFor(String value) => switch (value) {
  'danno' => oculumFallenEyeRareDamageBonus,
  'difesa' => oculumFallenEyeRareDefenseBonus,
  _ => 0,
};

bool oculumFallenEyeNeedsMaintenance(int ownerEyeCount) => ownerEyeCount >= 2;

String oculumFallenEyeSourceClass(Map<String, dynamic> source) {
  final type = '${source['tipoScheda'] ?? source['type'] ?? ''}'
      .trim()
      .toLowerCase();
  if (type.contains('mini') && type.contains('boss')) return 'Mini-Boss';
  if (type.contains('boss')) return 'Boss';
  return 'Mostro';
}

int oculumFallenEyeMaintenanceDifficulty({
  required int ownerEyeCount,
  required int failureStreak,
}) =>
    oculumFallenEyeMaintenanceBaseDifficulty +
    max(0, ownerEyeCount - 2) * oculumFallenEyeMaintenanceExtraEyeDifficulty +
    max(0, failureStreak) * oculumFallenEyeMaintenanceFailureDifficulty;

/// Il primo cedimento è un avvertimento; dal secondo, la pressione intacca il
/// Nucleo. Il danno cresce se la catena di fallimenti continua.
int oculumFallenEyeCoreIntegrityLossForFailure(int failureStreak) =>
    max(0, failureStreak - 1);

int oculumFallenEyeWillChecksDueForHpLoss({
  required int previousHp,
  required int currentHp,
}) => max(0, previousHp - currentHp) ~/ 10;

/// Al grado Oculum (Epico) il Reforge non prova più una nuova rarità: la
/// ricompensa del tentativo Quest si trasforma direttamente in questa EXP.
const int oculumFallenEyeEpicReforgeXp = 100;

/// Ogni fallimento avvicina l'Occhio al Reforge dello stadio che sta tentando.
/// Il bonus è deliberatamente per stadio: un successo azzera la serie prima di
/// poter affrontare la rarità seguente.
const int oculumFallenEyeReforgeFailureBonusPerAttempt = 10;

/// Il Drop del sottotratto Oculus crea un Occhio soltanto con un 20 naturale:
/// bonus e totale non possono attivare la ricompensa.
bool oculumFallenEyeDropCreatesOnNaturalTwenty({
  required String subtraitId,
  required int naturalRoll,
}) => subtraitId == 'drop' && naturalRoll == 20;

/// Una singola curva per i mostri: base leggibile, mini-boss e boss crescono
/// senza salti esponenziali. Il tratto Ombra aggiunge versatilità, non danni
/// infiniti; è ispirato al fantasy d'azione ma resta una regola Oculum.
int oculumMonsterScaledPower({
  required int level,
  required bool miniBoss,
  required bool boss,
  required int slot,
}) {
  final tier = boss
      ? 18
      : miniBoss
      ? 10
      : 4;
  return max(3, level * 2 + tier + slot * 3);
}

const List<String> oculumFallenEyeRarities = [
  'comune',
  'non_comune',
  'raro',
  'oculum',
];

String oculumFallenEyeNormalizedDifficulty(String value) {
  switch (value.trim().toLowerCase()) {
    case 'normale':
    case 'medio':
      return 'medio';
    case 'facile':
      return 'facile';
    case 'difficile':
      return 'difficile';
    case 'oculum':
      return 'oculum';
    default:
      return 'medio';
  }
}

String oculumFallenEyeRollRarity(Random random) {
  final roll = random.nextInt(100);
  if (roll < 60) return 'comune';
  if (roll < 85) return 'non_comune';
  if (roll < 95) return 'raro';
  return 'oculum';
}

int oculumFallenEyeArtLimit(String rarity) => switch (rarity) {
  'non_comune' => 1,
  'raro' => 2,
  'oculum' => 3,
  _ => 0,
};
bool oculumFallenEyeCanRegenerate(String rarity) => rarity != 'comune';
bool oculumFallenEyeCanLevel(String rarity) =>
    rarity == 'raro' || rarity == 'oculum';
bool oculumFallenEyeCanHaveTitles(String rarity) => rarity == 'oculum';
String? oculumFallenEyeNextRarity(String rarity) {
  final index = oculumFallenEyeRarities.indexOf(rarity);
  return index < 0 || index >= oculumFallenEyeRarities.length - 1
      ? null
      : oculumFallenEyeRarities[index + 1];
}

int oculumFallenEyeReforgeChance(String difficulty, String targetRarity) =>
    oculumFallenEyeReforgeChances[oculumFallenEyeNormalizedDifficulty(
      difficulty,
    )]?[targetRarity] ??
    0;
int oculumFallenEyeReforgeFailureBonus(int failureStreak) =>
    max(0, failureStreak) * oculumFallenEyeReforgeFailureBonusPerAttempt;
int oculumFallenEyeReforgeChanceWithFailures({
  required String difficulty,
  required String targetRarity,
  required int failureStreak,
}) => min(
  100,
  oculumFallenEyeReforgeChance(difficulty, targetRarity) +
      oculumFallenEyeReforgeFailureBonus(failureStreak),
);
int oculumFallenEyeSummonXpForDifficulty(String difficulty) =>
    oculumFallenEyeSummonXp[oculumFallenEyeNormalizedDifficulty(difficulty)] ??
    100;

int oculumFallenEyeSummonCostForDifficulty(String difficulty) =>
    oculumFallenEyeSummonOculumCost[oculumFallenEyeNormalizedDifficulty(
      difficulty,
    )] ??
    2;

/// Un Occhio morto non torna disponibile, nemmeno dopo il riavvio. I vecchi
/// salvataggi non hanno questo campo e quindi restano evocabili finché non
/// subiscono una morte reale.
bool oculumFallenEyeIsDead(Map<String, dynamic> eye) =>
    readBoolValue(eye['perdutoPerSempre']) ||
    (readIntValue(eye['deathWounds']) >= 3 &&
        readIntValue(eye['currentHp']) <= 0);

/// Il salvataggio conserva gli Occhi sia nel blocco attivo sia nello snapshot
/// della campagna. Le versioni precedenti potevano avere lo snapshot più
/// vecchio del blocco attivo: in fase di apertura un elenco vuoto non deve mai
/// cancellare un Occhio valido. La fusione è per ID e conserva anche i campi
/// sconosciuti di entrambi i lati; il blocco attivo vince soltanto sui campi
/// che possiede davvero, perché è la fotografia appena salvata della campagna
/// aperta.
List<Map<String, dynamic>> oculumFallenEyesMergeForCampaignLoad({
  required Object? campaignEyes,
  required Object? activeEyes,
}) {
  List<Map<String, dynamic>> asMaps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((eye) => Map<String, dynamic>.from(eye))
            .toList()
      : <Map<String, dynamic>>[];

  final merged = <String, Map<String, dynamic>>{};
  var anonymous = 0;
  void addAll(Iterable<Map<String, dynamic>> eyes) {
    for (final eye in eyes) {
      final rawId = '${eye['id'] ?? ''}'.trim();
      final key = rawId.isEmpty ? '__legacy_${anonymous++}' : rawId;
      final previous = merged[key];
      merged[key] = previous == null
          ? eye
          : <String, dynamic>{...previous, ...eye};
    }
  }

  addAll(asMaps(campaignEyes));
  addAll(asMaps(activeEyes));
  return merged.values.toList(growable: false);
}

/// Una scheda libera può ospitare l'evocazione iniziale senza sovrascrivere
/// una scheda giocata, una copia online o la scheda del proprietario.
bool oculumFallenEyeIsBlankSummonSheet(Map<String, dynamic> sheet) {
  final name = '${sheet['nome'] ?? ''}'.trim();
  final type = '${sheet['tipoScheda'] ?? 'Personaggio'}'.trim();
  return (name.isEmpty || name == '???') &&
      type == 'Personaggio' &&
      readIntValue(sheet['livello']) == 0 &&
      !readBoolValue(sheet['occhioCaduto']) &&
      !readBoolValue(sheet['realtimeSharedSheet']);
}

int oculumFallenEyeRestIntegrityRecoveredValue({
  required int current,
  required int maximum,
  required bool longRest,
  String rarity = 'raro',
}) {
  final safeMaximum = max(1, maximum);
  final safeCurrent = current.clamp(0, safeMaximum).toInt();
  if (safeCurrent >= safeMaximum) return safeCurrent;
  var recovered = longRest ? safeMaximum : max(1, (safeMaximum * .25).ceil());
  // Non comune è il primo vero risveglio: recupera, ma a metà ritmo.
  if (rarity == 'non_comune') recovered = max(1, recovered ~/ 2);
  return min(safeMaximum, safeCurrent + recovered);
}

const List<String> oculumFallenEyeCommonStatKeys = [
  'resilienza',
  'volonta',
  'materia',
  'oculum',
];

/// Gli Occhi Oculum hanno un solo risveglio percentuale, volutamente basso:
/// dal 3% al 7%. L'effetto è memorizzato per non riassegnarlo a ogni evocazione.
const List<String> oculumFallenEyeOculumBuffTargets = [
  'hp',
  'oculum',
  'stat:resilienza',
  'stat:volonta',
  'stat:materia',
];

String oculumFallenEyeOculumBuffEffectForRoll({
  required int targetRoll,
  required int percentageRoll,
}) =>
    '${oculumFallenEyeOculumBuffTargets[targetRoll % oculumFallenEyeOculumBuffTargets.length]}:${3 + percentageRoll.clamp(0, 4)}';

int oculumFallenEyePercentageIncrease(int value, int percentage) =>
    value <= 0 || percentage <= 0
    ? 0
    : max(1, (value * percentage / 100).ceil());

String oculumFallenEyeOculumBuffLabel(String effect) {
  final pieces = effect.split(':');
  if (pieces.length == 2) {
    final label = switch (pieces.first) {
      'hp' => 'Vita',
      'oculum' => 'Oculum',
      _ => '',
    };
    return label.isEmpty ? '' : '+${pieces[1]}% $label';
  }
  if (pieces.length == 3 && pieces.first == 'stat') {
    final label = switch (pieces[1]) {
      'resilienza' => 'Resilienza',
      'volonta' => 'Volontà',
      'materia' => 'Materia',
      _ => '',
    };
    return label.isEmpty ? '' : '+${pieces[2]}% $label';
  }
  return '';
}

/// Applies the saved Oculum-rarity percentage bonus to values actually used by
/// the summoned creature. It is intentionally one-shot and save-compatible.
void oculumFallenEyeApplyOculumBuff(Map<String, dynamic> sheet, String effect) {
  final pieces = effect.split(':');
  if (pieces.length == 2) {
    final percentage = readIntValue(pieces[1]);
    final fields = switch (pieces[0]) {
      'hp' => const ['currentHp', 'maxHp'],
      'oculum' => const ['oculum', 'currentOculum', 'maxOculum'],
      _ => const <String>[],
    };
    for (final field in fields) {
      if (!sheet.containsKey(field)) continue;
      final value = readIntValue(sheet[field]);
      sheet[field] =
          (value + oculumFallenEyePercentageIncrease(value, percentage))
              .toString();
    }
    return;
  }
  if (pieces.length == 3 &&
      pieces.first == 'stat' &&
      oculumFallenEyeCommonStatKeys.contains(pieces[1])) {
    final value = readIntValue(sheet[pieces[1]]);
    final percentage = readIntValue(pieces[2]);
    sheet[pieces[1]] =
        (value + oculumFallenEyePercentageIncrease(value, percentage))
            .toString();
  }
}

/// The stored effect, rather than its display label, is the authoritative
/// record. This makes a common Eye's penalty survive summon, save/load, and
/// Reforge without being applied twice.
String oculumFallenEyeCommonMalusEffectForRoll({
  required int malusRoll,
  required int statRoll,
}) {
  switch (malusRoll.clamp(0, 4)) {
    case 0:
      return 'cm:-2';
    case 1:
      return 'vc:-1';
    case 2:
      return 'cm:-1';
    case 3:
      return 'vc:-2';
    default:
      return 'stat:${oculumFallenEyeCommonStatKeys[statRoll % oculumFallenEyeCommonStatKeys.length]}:-1';
  }
}

String oculumFallenEyeCommonMalusLabel(String effect) {
  switch (effect) {
    case 'cm:-2':
      return '-2 CM';
    case 'cm:-1':
      return '-1 CM';
    case 'vc:-2':
      return '-2 VC';
    case 'vc:-1':
      return '-1 VC';
  }
  final pieces = effect.split(':');
  if (pieces.length == 3 && pieces.first == 'stat') {
    final label = switch (pieces[1]) {
      'resilienza' => 'Resilienza',
      'volonta' => 'Volontà',
      'materia' => 'Materia',
      'oculum' => 'Oculum',
      _ => 'statistica',
    };
    return '${pieces[2]} $label';
  }
  return '';
}

/// Applies (or reverts with [multiplier] = -1) a saved Common-Eye penalty to
/// the real sheet values used by combat calculations.
void oculumFallenEyeApplyCommonMalus(
  Map<String, dynamic> sheet,
  String effect, {
  int multiplier = 1,
}) {
  final pieces = effect.split(':');
  if (pieces.length == 2 && (pieces[0] == 'cm' || pieces[0] == 'vc')) {
    final field = pieces[0] == 'cm' ? 'cmRapido' : 'attaccoRapido';
    sheet[field] =
        (readIntValue(sheet[field]) + readIntValue(pieces[1]) * multiplier)
            .toString();
    return;
  }
  if (pieces.length == 3 &&
      pieces[0] == 'stat' &&
      oculumFallenEyeCommonStatKeys.contains(pieces[1])) {
    sheet[pieces[1]] =
        (readIntValue(sheet[pieces[1]]) + readIntValue(pieces[2]) * multiplier)
            .toString();
  }
}

Color oculumFallenEyeColor(String rarity) => switch (rarity) {
  'comune' => const Color(0xFF8EEA89),
  'non_comune' => const Color(0xFF27853B),
  'raro' => const Color(0xFFFF8A32),
  _ => const Color(0xFF9B63E8),
};

String oculumFallenEyeLabel(String rarity) => switch (rarity) {
  'non_comune' => 'Non Comune',
  'raro' => 'Raro',
  'oculum' => 'Oculum',
  _ => 'Comune',
};

extension _OculumFallenEyes on _OculumHomePageState {
  void _touchFallenEyes() => fallenEyesRevision.value++;
  Map<String, dynamic>? fallenEyeForId(String id) {
    for (final eye in occhiCaduti) {
      if ('${eye['id']}' == id) return eye;
    }
    return null;
  }

  String fallenEyeDifficulty(Map<String, dynamic> eye) {
    final owner = '${eye['ownerSheetId'] ?? ''}';
    Map<String, dynamic>? sheet;
    for (final candidate in schedePersonaggio) {
      if ('${candidate['sheetTag']}' == owner) {
        sheet = candidate;
        break;
      }
    }
    return oculumFallenEyeNormalizedDifficulty(
      '${sheet?['campaignDifficulty'] ?? campaignDifficulty}',
    );
  }

  Map<String, dynamic> _cloneJsonMap(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  Map<String, dynamic> _newFallenEye(
    Map<String, dynamic> source, {
    String? name,
    String? rarity,
  }) {
    final selectedRarity = oculumFallenEyeRarities.contains(rarity)
        ? rarity!
        : oculumFallenEyeRollRarity(Random.secure());
    final id =
        'fallen_eye_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(999999)}';
    final current = _cloneJsonMap(source);
    // Un Occhio dei Perduti è una creatura indipendente: eredita soltanto
    // corpo, immagine e statistiche della fonte, mai le sue conoscenze.
    current['arti'] = <dynamic>[];
    current['skills'] = <dynamic>[];
    current['titoli'] = <dynamic>[];
    current['fallenEyeOriginalArts'] = <dynamic>[];
    final commonEffect = selectedRarity == 'comune'
        ? oculumFallenEyeCommonMalusEffectForRoll(
            malusRoll: Random.secure().nextInt(5),
            statRoll: Random.secure().nextInt(
              oculumFallenEyeCommonStatKeys.length,
            ),
          )
        : '';
    final malus = oculumFallenEyeCommonMalusLabel(commonEffect);
    if (commonEffect.isNotEmpty) {
      oculumFallenEyeApplyCommonMalus(current, commonEffect);
    }
    final oculumBuffEffect = selectedRarity == 'oculum'
        ? oculumFallenEyeOculumBuffEffectForRoll(
            targetRoll: Random.secure().nextInt(
              oculumFallenEyeOculumBuffTargets.length,
            ),
            percentageRoll: Random.secure().nextInt(5),
          )
        : '';
    if (oculumBuffEffect.isNotEmpty) {
      oculumFallenEyeApplyOculumBuff(current, oculumBuffEffect);
    }
    if (name != null && name.trim().isNotEmpty) current['nome'] = name.trim();
    current['occhioCadutoId'] = id;
    current['occhioCaduto'] = true;
    current['tipoScheda'] = 'Mostro';
    return <String, dynamic>{
      'id': id,
      'ownerSheetId': sheetTagAt(schedaCorrente),
      'originalCreatureId': '${source['sheetTag'] ?? ''}',
      'sourceMonsterId': '${source['monsterBookSourceId'] ?? ''}',
      'sourceClass': oculumFallenEyeSourceClass(source),
      'name': '${current['nome'] ?? 'Occhio Caduto'}',
      'rarity': selectedRarity,
      'commonMalus': malus,
      'commonMalusHistorical': malus,
      'commonMalusEffect': commonEffect,
      'commonMalusApplied': commonEffect.isNotEmpty,
      'oculumBuffEffect': oculumBuffEffect,
      'oculumBuffApplied': oculumBuffEffect.isNotEmpty,
      'originalArts': <dynamic>[],
      'activeArts': <dynamic>[],
      'integrityCurrent': max(
        1,
        (readIntValue(current['currentHp'], fallback: 1) * .35).round(),
      ),
      'integrityMax': max(
        1,
        (readIntValue(current['currentHp'], fallback: 1) * .35).round(),
      ),
      'active': false,
      'perdutoPerSempre': false,
      'perdutoIl': '',
      'reforgeHistory': <Map<String, dynamic>>[],
      'reforgeQuestCredits': 0,
      'reforgeQuestNote': '',
      'reforgeFailureStreak': 0,
      // Riusa i token/preset già presenti nella normale scheda; il badge di
      // rarità resta indipendente e non viene mai sovrascritto da un Reforge.
      'theme': <String, dynamic>{
        'primaryColor': current['primaryColor'],
        'secondaryColor': current['secondaryColor'],
        'tertiaryColor': current['tertiaryColor'],
        'eyePupilGlowColor': current['eyePupilGlowColor'],
        'colorPreset': current['colorPreset'],
        'colorDecorationPresetId': current['colorDecorationPresetId'],
        'colorGuiPresetId': current['colorGuiPresetId'],
        'themeDecorationIntensityScale':
            current['themeDecorationIntensityScale'],
      },
      'xpBySource': <String, int>{'summon_flat': 0, 'owner': 0, 'other': 0},
      'lastSummonXp': 0,
      'lastSummonAt': '',
      'rareAttributeEligible':
          selectedRarity == 'raro' &&
          oculumFallenEyeWinsRareAttributeRoll(Random.secure().nextInt(100)),
      'rareAttribute': '',
      'rareAttributeBonus': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'sheetData': current,
    };
  }

  Map<String, dynamic> _fallenEyeSourceFromMonsterBook(
    MonsterBookEntry monster, {
    required String name,
    required int level,
  }) {
    final source = statoVuotoPersonaggio(
      nome: name.trim().isEmpty ? monster.nameIt : name.trim(),
      tipo: monster.presetType,
      livello: max(0, level),
      grado: monster.isBoss
          ? 3
          : monster.isMiniBoss
          ? 2
          : 1,
    );
    final stats = monster.stats;
    final res = max(1, stats['resilienza'] ?? 6);
    final vol = max(0, stats['volonta'] ?? 3);
    final mat = max(0, stats['materia'] ?? 3);
    final ocu = max(0, stats['oculum'] ?? 2);
    source.addAll({
      'resilienza': '$res',
      'currentResilienza': '$res',
      'volonta': '$vol',
      'currentVolonta': '$vol',
      'materia': '$mat',
      'currentMateria': '$mat',
      'oculum': '$ocu',
      'currentOculum': '$ocu',
      'maxOculum': ocu,
      'currentHp': '${max(1, stats['hp'] ?? (res * 10))}',
      'spriteAssetPath': monster.spriteAssetPath,
      'immaginePersonaggioBase64': monster.imageBase64,
      'background': monster.descIt,
      'notePersonaggio':
          'Monster Book: ${monster.nameIt} • Elemento: ${monster.elementId}',
      'monsterBookSourceId': monster.id,
      'shadowScaling': monster.elementId.toLowerCase() == 'shadow',
    });
    source['skills'] = <dynamic>[];
    return source;
  }

  Future<MonsterBookEntry?> _pickMonsterBookForFallenEye() async {
    final search = TextEditingController();
    MonsterBookEntry? result;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = oculumNormalizeText(search.text);
          final entries = monsterBookEntries
              .where((entry) {
                return query.isEmpty ||
                    oculumNormalizeText(
                      '${entry.nameIt} ${entry.nameEn} ${entry.presetType} ${entry.elementId}',
                    ).contains(query);
              })
              .toList(growable: false);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.menu_book),
                SizedBox(width: 8),
                Text('Monster Book'),
              ],
            ),
            content: SizedBox(
              width: 560,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    controller: search,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cerca per nome, tipo o elemento',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemExtent: 70,
                      itemBuilder: (_, index) {
                        final entry = entries[index];
                        return ListTile(
                          leading: monsterBookEntryPreview(entry),
                          title: Text(
                            entry.nameIt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${entry.presetType} • ${elementDisplayName(entry.elementId)} • HP ${entry.stats['hp'] ?? 0} • Skill ${entry.skillIds.length}',
                          ),
                          onTap: () {
                            result = entry;
                            Navigator.pop(dialog);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Indietro'),
              ),
            ],
          );
        },
      ),
    );
    search.dispose();
    return result;
  }

  Future<void> createFallenEyeFromSource(
    Map<String, dynamic> source, {
    String? name,
    String? rarity,
  }) async {
    final eye = _newFallenEye(source, name: name, rarity: rarity);
    setState(() {
      occhiCaduti.add(eye);
      _touchFallenEyes();
    });
    await salvaDati();
    await _chooseFallenEyeRareAttributeIfAvailable(eye);
    if (mounted) _showFallenEyeReveal(eye);
  }

  /// Crea una nuova custodia senza modificare la scheda sorgente. Art, Skill
  /// e Titoli vengono già rimossi da _newFallenEye secondo le regole Oculum.
  Future<void> copyCurrentSheetAsFallenEye() async {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    final source = _cloneJsonMap(schedePersonaggio[schedaCorrente]);
    await createFallenEyeFromSource(
      source,
      name: '${source['nome'] ?? 'Creatura'} — Occhio Caduto',
    );
  }

  /// Invia una fotografia dell'Occhio a amici e Master/Co-Master RealTime.
  /// È sempre una copia in sola visualizzazione: non trasferisce proprietà,
  /// non evoca l'Occhio e non può rimuoverlo dalla collezione locale.
  Future<bool> sendFallenEyeToRealtime(Map<String, dynamic> eye) async {
    final service = realtimeService;
    if (service?.isConnected != true) {
      _fallenEyeMessage('Realtime non connesso: Occhio non inviato.');
      return false;
    }
    final targets = realtimeFullSheetTargetTags();
    if (targets.isEmpty) {
      _fallenEyeMessage('Nessun amico o partecipante RealTime disponibile.');
      return false;
    }
    final ownerTag = normalizeOculumFriendTag('${eye['ownerSheetId'] ?? ''}');
    final eyeId = '${eye['id'] ?? ''}'.trim();
    final source = eye['sheetData'];
    if (ownerTag.isEmpty || eyeId.isEmpty || source is! Map) {
      _fallenEyeMessage('Occhio non inviabile: dati incompleti.');
      return false;
    }
    final shareId = '${ownerTag}_fallen_$eyeId';
    final sheet =
        realtimeSafeSheetJson(
            Map<String, dynamic>.from(source),
            includeImage: true,
          )
          ..['id'] = shareId
          ..['sheetTag'] = shareId
          ..['occhioCaduto'] = true
          ..['occhioCadutoId'] = eyeId
          ..['occhioCadutoCondiviso'] = true
          ..['occhioCadutoRarita'] = '${eye['rarity'] ?? 'comune'}'
          ..['occhioCadutoClasseFonte'] = '${eye['sourceClass'] ?? 'Mostro'}'
          ..['occhioCadutoEvocato'] = readBoolValue(eye['active'])
          ..['occhioCadutoProprietario'] = ownerTag
          ..['publicVisibleTitleName'] = ''
          ..['publicVisibleTitleLegend'] = '';
    final sent = await service!.sendSharedSheetConfirmed(
      sheet: sheet,
      campaignId: activeCampaignId,
      campaignName: activeCampaignName(),
      sheetId: shareId,
      sheetName: '${eye['name'] ?? 'Occhio Caduto'} — Occhio Caduto',
      ownerTag: ownerTag,
      senderRole: 'fullShare',
      targetAudience: 'friends_party_full',
      fromMaster: realtimeIsMasterRole,
      masterParty: false,
      targetTags: targets,
    );
    _fallenEyeMessage(
      sent
          ? 'Occhio inviato a ${targets.length} destinatario/i. La custodia locale resta invariata.'
          : 'Invio Occhio non confermato: controlla stanza e connessione RealTime.',
    );
    return sent;
  }

  int fallenEyeRareAttributeBonusFor(String target) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return 0;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (!readBoolValue(sheet['occhioCaduto']) ||
        '${sheet['fallenEyeRareAttribute'] ?? ''}' != target) {
      return 0;
    }
    return max(
      0,
      readIntValue(
        sheet['fallenEyeRareAttributeBonus'],
        fallback: oculumFallenEyeRareAttributeBonusFor(target),
      ),
    );
  }

  Future<void> _chooseFallenEyeRareAttributeIfAvailable(
    Map<String, dynamic> eye,
  ) async {
    if (!readBoolValue(eye['rareAttributeEligible']) ||
        '${eye['rareAttribute'] ?? ''}'.trim().isNotEmpty ||
        !mounted) {
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: const Text('ATTRIBUTO RARO RISVEGLIATO'),
        content: const Text(
          'Questo Occhio ha superato il tiro raro del 26%. Scegli un solo attributo permanente.',
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(dialog, 'difesa'),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Difesa Aggiuntiva +35'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialog, 'danno'),
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('Danno Aggiuntivo +50'),
          ),
        ],
      ),
    );
    if (selected == null) return;
    setState(() {
      eye['rareAttribute'] = selected;
      eye['rareAttributeChosenAt'] = DateTime.now().toIso8601String();
      final bonus = oculumFallenEyeRareAttributeBonusFor(selected);
      eye['rareAttributeBonus'] = bonus;
      final data = Map<String, dynamic>.from(eye['sheetData'] as Map? ?? {});
      data['fallenEyeRareAttribute'] = selected;
      data['fallenEyeRareAttributeBonus'] = bonus;
      eye['sheetData'] = data;
      final activeIndex = schedePersonaggio.indexWhere(
        (sheet) => '${sheet['occhioCadutoId'] ?? ''}' == '${eye['id']}',
      );
      if (activeIndex >= 0) {
        schedePersonaggio[activeIndex] = _cloneJsonMap(data);
      }
      _touchFallenEyes();
    });
    await salvaDati();
  }

  void _showFallenEyeReveal(Map<String, dynamic> eye) {
    final color = oculumFallenEyeColor('${eye['rarity']}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color.withValues(alpha: .92),
        content: Text(
          'OCCHIO CADUTO — ${oculumFallenEyeLabel('${eye['rarity']}').toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// L'evocazione non è bloccata dalla turnistica: se il proprietario ha il
  /// turno attivo con un'azione pronta, quell'azione viene usata; altrimenti
  /// l'Occhio può essere evocato o disevocato lo stesso.
  bool _spendFallenEyeSummonAction(Map<String, dynamic> eye, String verb) {
    if (masterInitiativeTokens.isEmpty) return true;
    final activeIndex = masterInitiativeActiveIndex
        .clamp(0, masterInitiativeTokens.length - 1)
        .toInt();
    final token = masterInitiativeTokens[activeIndex];
    if ('${token['sheetTag'] ?? ''}' != '${eye['ownerSheetId'] ?? ''}' ||
        !masterInitiativeTokenCanAct(token) ||
        masterInitiativeActionUsed(token)) {
      return true;
    }
    setState(() {
      token['actionUsed'] = true;
      token['updatedAt'] = DateTime.now().toIso8601String();
      risultato = 'Azione usata: ${token['name']}. $verb Occhio Caduto.';
      aggiungiLog(risultato);
    });
    sendRealtimeInitiativeSnapshotIfPublished();
    return true;
  }

  bool _spendFallenEyeSummonResource(Map<String, dynamic> eye) {
    salvaSchedaCorrenteInMemoria();
    final ownerIndex = schedePersonaggio.indexWhere(
      (sheet) => '${sheet['sheetTag'] ?? ''}' == '${eye['ownerSheetId'] ?? ''}',
    );
    if (ownerIndex < 0) {
      _fallenEyeMessage(
        'Scheda proprietaria non disponibile per l’evocazione.',
      );
      return false;
    }
    final owner = schedePersonaggio[ownerIndex];
    final cost = oculumFallenEyeSummonCostForDifficulty(
      fallenEyeDifficulty(eye),
    );
    final currentOculum = readIntValue(owner['currentOculum']);
    final currentWill = readIntValue(owner['currentVolonta']);
    if (currentOculum >= cost) {
      owner['currentOculum'] = '${currentOculum - cost}';
      eye['summonPayment'] = 'oculum';
      eye['willMaintenanceDebt'] = 0;
      if (ownerIndex == schedaCorrente) {
        currentOculumController.text = '${currentOculum - cost}';
      }
      return true;
    }
    if (currentOculum == 0 && currentWill >= cost) {
      owner['currentVolonta'] = '${currentWill - cost}';
      eye['summonPayment'] = 'volonta';
      eye['willMaintenanceDebt'] = 0;
      eye['willMaintenanceLastHp'] = readIntValue(owner['currentHp']);
      if (ownerIndex == schedaCorrente) {
        currentVolontaController.text = '${currentWill - cost}';
      }
      return true;
    }
    _fallenEyeMessage(
      currentOculum == 0
          ? 'Evocazione bloccata: servono $cost Volontà (Oculum a 0).'
          : 'Evocazione bloccata: servono $cost Oculum alla difficoltà ${fallenEyeDifficulty(eye)}.',
    );
    return false;
  }

  /// Il mantenimento dipende soltanto dagli Occhi effettivamente evocati.
  /// Quelli custoditi ma disevocati non impongono né spese né tiri.
  int _activeFallenEyeOwnerCount(Map<String, dynamic> eye) => occhiCaduti
      .where(
        (candidate) =>
            '${candidate['ownerSheetId'] ?? ''}' ==
                '${eye['ownerSheetId'] ?? ''}' &&
            readBoolValue(candidate['active']) &&
            !oculumFallenEyeIsDead(candidate),
      )
      .length;

  Map<String, dynamic>? _activeFallenEyeForCurrentOwner() {
    final ownerId = sheetTagAt(schedaCorrente);
    for (final eye in occhiCaduti) {
      if ('${eye['ownerSheetId'] ?? ''}' == ownerId &&
          readBoolValue(eye['active']) &&
          !oculumFallenEyeIsDead(eye)) {
        return eye;
      }
    }
    return null;
  }

  /// Osserva i danni reali alla Vita della scheda. Per un Occhio pagato con
  /// Volontà crea un debito persistente di un tiro ogni 10 Vita persi: non è
  /// legato a una singola schermata o a un particolare pulsante di danno.
  void registraPerditaVitaMantenimentoOcchiCaduti({
    required String ownerSheetId,
    required int previousHp,
    required int currentHp,
  }) {
    if (currentHp >= previousHp) return;
    for (final eye in occhiCaduti) {
      if ('${eye['ownerSheetId'] ?? ''}' != ownerSheetId ||
          !readBoolValue(eye['active']) ||
          '${eye['summonPayment'] ?? 'oculum'}' != 'volonta') {
        continue;
      }
      final due = oculumFallenEyeWillChecksDueForHpLoss(
        previousHp: previousHp,
        currentHp: currentHp,
      );
      if (due <= 0) continue;
      eye['willMaintenanceDebt'] =
          readIntValue(eye['willMaintenanceDebt']) + due;
      eye['willMaintenanceLastHp'] = currentHp;
      _touchFallenEyes();
    }
  }

  Future<void> processFallenEyeMaintenanceRoll({
    required String subtraitId,
    required int naturalRoll,
    required int total,
  }) async {
    final eye = _activeFallenEyeForCurrentOwner();
    if (eye == null ||
        !oculumFallenEyeNeedsMaintenance(_activeFallenEyeOwnerCount(eye))) {
      return;
    }
    final paidWithWill = '${eye['summonPayment'] ?? 'oculum'}' == 'volonta';
    final isOculumHold =
        subtraitId == 'manifestazione_potere' ||
        hiddenEyeStatGroup(subtraitId) == 'oculum';
    final isWillHold =
        subtraitId == 'resistenza' ||
        subtraitId == 'eco' ||
        subtraitId == 'volonta_mantenimento_occhio';
    if ((!paidWithWill && !isOculumHold) ||
        (paidWithWill &&
            (readIntValue(eye['willMaintenanceDebt']) <= 0 || !isWillHold))) {
      return;
    }

    final failures = readIntValue(eye['maintenanceFailureStreak']);
    final difficulty = oculumFallenEyeMaintenanceDifficulty(
      ownerEyeCount: _activeFallenEyeOwnerCount(eye),
      failureStreak: failures,
    );
    final success =
        naturalRoll == 20 || (naturalRoll != 1 && total >= difficulty);
    final nextStreak = success ? 0 : failures + 1;
    final integrityLoss = success
        ? 0
        : oculumFallenEyeCoreIntegrityLossForFailure(nextStreak);
    var dismiss = false;

    setState(() {
      eye['maintenanceChecks'] = readIntValue(eye['maintenanceChecks']) + 1;
      eye['maintenanceLastAt'] = DateTime.now().toIso8601String();
      eye['maintenanceLastDifficulty'] = difficulty;
      eye['maintenanceFailureStreak'] = nextStreak;
      if (success) {
        if (paidWithWill) {
          eye['willMaintenanceDebt'] = max(
            0,
            readIntValue(eye['willMaintenanceDebt']) - 1,
          );
        }
      } else {
        eye['maintenanceFailures'] =
            readIntValue(eye['maintenanceFailures']) + 1;
        if (paidWithWill) {
          // Il tiro richiesto dalla Vita persa fallisce: l'evocazione cede.
          dismiss = true;
        } else {
          final before = currentOculum();
          currentOculumController.text = '${max(0, before - 1)}';
          schedePersonaggio[schedaCorrente]['currentOculum'] =
              currentOculumController.text;
          eye['maintenanceOculumLost'] =
              readIntValue(eye['maintenanceOculumLost']) + (before > 0 ? 1 : 0);
          // La perdita di controllo non è certa, ma resta davvero pericolosa.
          dismiss = Random.secure().nextBool();
        }
      }
      _touchFallenEyes();
    });

    if (integrityLoss > 0) {
      final candidates = <int>[];
      for (var i = 0; i < arti.length; i++) {
        ensureArtIntegrityValue(i);
        if (arti[i].integritaCorrente > 0) candidates.add(i);
      }
      if (candidates.isNotEmpty) {
        candidates.sort(
          (a, b) =>
              arti[a].integritaCorrente.compareTo(arti[b].integritaCorrente),
        );
        setArtIntegrityValue(
          candidates.first,
          max(0, arti[candidates.first].integritaCorrente - integrityLoss),
          immediateSave: true,
        );
      }
    }

    final source = paidWithWill ? 'Resistenza/Eco' : 'Oculum/Manifestazione';
    final outcome = success ? 'riuscito' : 'FALLITO';
    final coreText = integrityLoss > 0
        ? ' Nucleo: -$integrityLoss Integrità.'
        : '';
    final dismissText = dismiss
        ? paidWithWill
              ? ' L’Occhio svanisce per il cedimento della Volontà.'
              : ' Il controllo si spezza: l’Occhio è disevocato.'
        : '';
    final text =
        'Mantenimento Occhio ($source): $total contro DT $difficulty — $outcome.$coreText$dismissText';
    aggiungiLog(text);
    _fallenEyeMessage(text);
    if (dismiss) await deactivateFallenEye(eye);
    await salvaDati();
  }

  Future<void> tiraMantenimentoOcchioConVolonta(
    Map<String, dynamic> eye,
  ) async {
    if (!readBoolValue(eye['active']) ||
        '${eye['ownerSheetId'] ?? ''}' != sheetTagAt(schedaCorrente)) {
      _fallenEyeMessage(
        'Apri la scheda proprietaria mentre l’Occhio è evocato.',
      );
      return;
    }
    if ('${eye['summonPayment'] ?? 'oculum'}' != 'volonta' ||
        readIntValue(eye['willMaintenanceDebt']) <= 0) {
      _fallenEyeMessage(
        'Non c’è alcun tiro di Volontà richiesto in questo momento.',
      );
      return;
    }
    final roll = tiraD20();
    final total = roll + volontaTotale() ~/ 2 + tiroGlobaleBonus();
    await processFallenEyeMaintenanceRoll(
      subtraitId: 'volonta_mantenimento_occhio',
      naturalRoll: roll,
      total: total,
    );
  }

  Future<void> activateFallenEye(Map<String, dynamic> eye) async {
    if (readBoolValue(eye['active'])) return;
    if (oculumFallenEyeIsDead(eye)) {
      _fallenEyeMessage('Questo Occhio è morto e non può più essere evocato.');
      return;
    }
    _ensureCommonEyeMalusApplied(eye);
    _ensureOculumEyeBuffApplied(eye);
    final sheet = _cloneJsonMap(
      Map<String, dynamic>.from(eye['sheetData'] as Map),
    );
    sheet['occhioCadutoId'] = eye['id'];
    sheet['occhioCaduto'] = true;
    final ownerId = '${eye['ownerSheetId'] ?? ''}';
    final blankIndex = schedePersonaggio.indexWhere(
      (candidate) =>
          '${candidate['sheetTag'] ?? ''}' != ownerId &&
          oculumFallenEyeIsBlankSummonSheet(candidate),
    );
    setState(() {
      // La prima evocazione occupa una scheda vuota; se l'utente non ne ha
      // lasciata una, ne creiamo una vuota e la riempiamo nello stesso gesto.
      // In entrambi i casi le statistiche sono quelle scelte in creazione.
      final slot = blankIndex >= 0
          ? Map<String, dynamic>.from(schedePersonaggio[blankIndex])
          : statoVuotoPersonaggio();
      final slotTag = '${slot['sheetTag'] ?? slot['id'] ?? ''}';
      if (slotTag.isNotEmpty) {
        sheet['id'] = slotTag;
        sheet['sheetTag'] = slotTag;
      }
      final summonedIndex = blankIndex >= 0
          ? blankIndex
          : schedePersonaggio.length;
      if (blankIndex >= 0) {
        schedePersonaggio[blankIndex] = sheet;
      } else {
        schedePersonaggio.add(sheet);
      }
      assicuraTagSchede();
      eye['sheetData'] = _cloneJsonMap(schedePersonaggio[summonedIndex]);
      eye['summonedSheetTag'] =
          '${schedePersonaggio[summonedIndex]['sheetTag'] ?? ''}';
      eye['usesBlankSummonSlot'] = true;
      eye['active'] = true;
      _touchFallenEyes();
    });
    await salvaDati();
  }

  /// Evento di gioco esplicito. L'attivazione della scheda e i rebuild non lo
  /// chiamano: ogni invocazione reale può assegnare una sola volta il premio.
  Future<void> summonFallenEye(Map<String, dynamic> eye) async {
    if (oculumFallenEyeIsDead(eye)) {
      _fallenEyeMessage('Questo Occhio è morto e non può più essere evocato.');
      return;
    }
    // Puoi evocare più Occhi. Il primo non costa nulla; una spesa e il
    // mantenimento iniziano soltanto quando ne chiami un altro mentre uno è
    // già presente.
    final hasAnotherActiveEye = _activeFallenEyeOwnerCount(eye) > 0;
    if (hasAnotherActiveEye && !_spendFallenEyeSummonResource(eye)) return;
    if (!hasAnotherActiveEye) eye['summonPayment'] = 'nessuno';
    if (!_spendFallenEyeSummonAction(eye, 'evocare')) return;
    await activateFallenEye(eye);
    final rarity = '${eye['rarity'] ?? 'comune'}';
    if (!oculumFallenEyeCanLevel(rarity)) {
      _showFallenEyeSummonNotice(
        eye,
        summoned: true,
        detail: '${oculumFallenEyeLabel(rarity)} — EXP non disponibile.',
      );
      return;
    }
    final amount = oculumFallenEyeSummonXpForDifficulty(
      fallenEyeDifficulty(eye),
    );
    await grantFallenEyeXp(eye, amount: amount, source: 'summon_flat');
    setState(() {
      eye['lastSummonXp'] = amount;
      eye['lastSummonAt'] = DateTime.now().toIso8601String();
      _touchFallenEyes();
    });
    await salvaDati();
    _showFallenEyeSummonNotice(
      eye,
      summoned: true,
      detail: '+$amount EXP • ${oculumFallenEyeLabel(rarity)}',
    );
  }

  /// Punto unico per l'EXP dell'Occhio. La sorgente rimane nel salvataggio per
  /// audit e non viene usata dalla UI per riassegnare premi al riavvio.
  Future<void> grantFallenEyeXp(
    Map<String, dynamic> eye, {
    required int amount,
    required String source,
  }) async {
    if (amount <= 0 || !oculumFallenEyeCanLevel('${eye['rarity'] ?? ''}')) {
      return;
    }
    final data = Map<String, dynamic>.from(
      eye['sheetData'] as Map? ?? const {},
    );
    final nextXp = readIntValue(data['exp']) + amount;
    data['exp'] = '$nextXp';
    eye['sheetData'] = data;
    final sources = Map<String, dynamic>.from(
      eye['xpBySource'] as Map? ?? const {},
    );
    sources[source] = readIntValue(sources[source]) + amount;
    eye['xpBySource'] = sources;
    final activeIndex = schedePersonaggio.indexWhere(
      (x) => '${x['occhioCadutoId'] ?? ''}' == '${eye['id']}',
    );
    if (activeIndex >= 0) schedePersonaggio[activeIndex]['exp'] = '$nextXp';
    _touchFallenEyes();
  }

  /// Trasferimento esplicito fuori o dentro combattimento. La fonte proprietaria
  /// viene scalata una sola volta, mentre l'EXP flat non passa mai da qui.
  Future<void> grantFallenEyeOwnerXp(
    Map<String, dynamic> eye,
    int amount,
  ) async {
    if (amount <= 0 || !oculumFallenEyeCanLevel('${eye['rarity'] ?? ''}')) {
      return;
    }
    final owner = schedePersonaggio
        .where((x) => '${x['sheetTag']}' == '${eye['ownerSheetId']}')
        .toList();
    if (owner.isEmpty) {
      _fallenEyeMessage('Scheda proprietaria non disponibile.');
      return;
    }
    final ownerSheet = owner.first;
    final available = readIntValue(ownerSheet['exp']);
    final transfer = min(amount, available);
    if (transfer <= 0) {
      _fallenEyeMessage('Il proprietario non ha EXP trasferibile.');
      return;
    }
    ownerSheet['exp'] = '${available - transfer}';
    await grantFallenEyeXp(eye, amount: transfer, source: 'owner');
    await salvaDati();
  }

  Future<void> cycleFallenEyeTheme(Map<String, dynamic> eye) async {
    final theme = Map<String, dynamic>.from(eye['theme'] as Map? ?? const {});
    final options = <Map<String, dynamic>>[
      {
        'primaryColor': const Color(0xFF3B82F6).toARGB32(),
        'secondaryColor': const Color(0xFF080B14).toARGB32(),
        'colorPreset': 'fallen_blue',
      },
      {
        'primaryColor': const Color(0xFFE03A3A).toARGB32(),
        'secondaryColor': const Color(0xFF160707).toARGB32(),
        'colorPreset': 'fallen_red',
      },
      {
        'primaryColor': const Color(0xFFE6D8BD).toARGB32(),
        'secondaryColor': const Color(0xFF08050B).toARGB32(),
        'colorPreset': 'classic_reliquary',
      },
    ];
    final current = '${theme['colorPreset'] ?? ''}';
    final index = options.indexWhere((x) => x['colorPreset'] == current);
    eye['theme'] = options[(index + 1) % options.length];
    _touchFallenEyes();
    await salvaDati();
  }

  Future<void> scegliImmagineOcchioCaduto(Map<String, dynamic> eye) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 90,
    );
    if (picked == null) return;
    final cropped = await mostraEditorCropEsagono(await picked.readAsBytes());
    if (cropped == null || cropped.isEmpty || !mounted) return;
    final encoded = base64Encode(cropped);
    setState(() {
      eye['portraitBase64'] = encoded;
      eye['portraitUpdatedAt'] = DateTime.now().toIso8601String();
      final data = Map<String, dynamic>.from(
        eye['sheetData'] as Map? ?? const {},
      );
      data['immaginePersonaggioBase64'] = encoded;
      eye['sheetData'] = data;
      final activeIndex = schedePersonaggio.indexWhere(
        (sheet) => '${sheet['occhioCadutoId'] ?? ''}' == '${eye['id']}',
      );
      if (activeIndex >= 0) {
        schedePersonaggio[activeIndex]['immaginePersonaggioBase64'] = encoded;
      }
      _touchFallenEyes();
    });
    await salvaDati();
  }

  Future<void> rimuoviImmagineOcchioCaduto(Map<String, dynamic> eye) async {
    setState(() {
      eye.remove('portraitBase64');
      eye.remove('portraitUpdatedAt');
      _touchFallenEyes();
    });
    await salvaDati();
  }

  Future<void> deactivateFallenEye(Map<String, dynamic> eye) async {
    final id = '${eye['id']}';
    var index = schedePersonaggio.indexWhere(
      (x) => '${x['occhioCadutoId'] ?? ''}' == id,
    );
    // Alcuni salvataggi precedenti possiedono solo il tag evocato: usalo come
    // secondo riferimento, così Disevoca resta affidabile anche dopo riordini
    // o una sincronizzazione RealTime.
    if (index < 0) {
      final summonedTag = '${eye['summonedSheetTag'] ?? ''}'.trim();
      if (summonedTag.isNotEmpty) {
        index = schedePersonaggio.indexWhere(
          (sheet) =>
              '${sheet['sheetTag'] ?? ''}' == summonedTag &&
              readBoolValue(sheet['occhioCaduto']),
        );
      }
    }
    if (index >= 0) {
      if (index == schedaCorrente && schedePersonaggio.length > 1) {
        await cambiaSchedaPersonaggio(index == 0 ? 1 : 0);
      }
      setState(() {
        // Conserva ogni modifica fatta all'Occhio prima di liberare lo slot.
        eye['sheetData'] = _cloneJsonMap(schedePersonaggio[index]);
        if (readBoolValue(eye['usesBlankSummonSlot'])) {
          final previous = schedePersonaggio[index];
          final blank = statoVuotoPersonaggio();
          blank['id'] = previous['id'] ?? '';
          blank['sheetTag'] = previous['sheetTag'] ?? '';
          schedePersonaggio[index] = blank;
        } else {
          schedePersonaggio.removeAt(index);
        }
      });
    }
    // Anche se lo slot è stato già rimosso (vecchio salvataggio/sync), lo
    // stato persistente deve sempre passare a disevocato.
    setState(() {
      eye['active'] = false;
      eye['summonedSheetTag'] = '';
      _touchFallenEyes();
    });
    await salvaDati();
  }

  Future<void> dismissFallenEye(Map<String, dynamic> eye) async {
    if (!readBoolValue(eye['active'])) return;
    if (!_spendFallenEyeSummonAction(eye, 'disevocare')) return;
    await deactivateFallenEye(eye);
    _showFallenEyeSummonNotice(
      eye,
      summoned: false,
      detail: 'L’Occhio torna nell’ombra.',
    );
  }

  /// Il riposo appartiene alla scheda del proprietario: l'Occhio recupera
  /// soltanto fuori evocazione e soltanto se la rarità glielo permette.
  String rigeneraOcchiCadutiDelProprietarioDaRiposo({required bool lungo}) {
    final ownerId = sheetTagAt(schedaCorrente);
    final recovered = <String>[];
    for (final eye in occhiCaduti) {
      if ('${eye['ownerSheetId'] ?? ''}' != ownerId ||
          readBoolValue(eye['active']) ||
          oculumFallenEyeIsDead(eye) ||
          !oculumFallenEyeCanRegenerate('${eye['rarity'] ?? 'comune'}')) {
        continue;
      }
      final maximum = max(
        1,
        readIntValue(
          eye['integrityMax'],
          fallback: readIntValue(eye['integrityCurrent'], fallback: 1),
        ),
      );
      final current = readIntValue(eye['integrityCurrent']).clamp(0, maximum);
      final next = oculumFallenEyeRestIntegrityRecoveredValue(
        current: current.toInt(),
        maximum: maximum,
        longRest: lungo,
        rarity: '${eye['rarity'] ?? 'comune'}',
      );
      if (next == current) continue;
      eye['integrityCurrent'] = next;
      eye['integrityMax'] = maximum;
      recovered.add('${eye['name']} +${next - current}');
    }
    if (recovered.isNotEmpty) _touchFallenEyes();
    return recovered.isEmpty
        ? ''
        : 'Occhi dei Caduti disevocati: ${recovered.join(', ')} Integrità.';
  }

  /// Viene chiamato dalle regole di morte, non dalla UI: la perdita resta
  /// scritta nella collezione anche se la scheda evocata viene poi rimossa.
  void segnaFallenEyeMortoDaScheda(Map<String, dynamic> sheet) {
    final id = '${sheet['occhioCadutoId'] ?? ''}'.trim();
    if (id.isEmpty) return;
    final eye = fallenEyeForId(id);
    if (eye == null || oculumFallenEyeIsDead(eye)) return;
    eye['perdutoPerSempre'] = true;
    eye['perdutoIl'] = DateTime.now().toIso8601String();
    eye['deathWounds'] = 3;
    eye['currentHp'] = 0;
    eye['active'] = false;
    final data = Map<String, dynamic>.from(eye['sheetData'] as Map? ?? sheet);
    data['currentHp'] = '0';
    data['feriteMorte'] = 3;
    data['personaggioCaduto'] = false;
    eye['sheetData'] = data;
    _touchFallenEyes();
    programmaSalvataggio();
  }

  /// Chiamato dal salvataggio della scheda: la collezione legge sempre lo stesso
  /// ID e riceve l'ultimo snapshot, senza salvare tutte le altre schede.
  void syncFallenEyeFromSheet(Map<String, dynamic> sheet) {
    final id = '${sheet['occhioCadutoId'] ?? ''}';
    if (id.isEmpty) return;
    final eye = fallenEyeForId(id);
    if (eye == null) return;
    eye['sheetData'] = _cloneJsonMap(sheet);
    eye['name'] = '${sheet['nome'] ?? eye['name']}';
    if (readIntValue(sheet['feriteMorte']) >= 3 &&
        readIntValue(sheet['currentHp']) <= 0) {
      segnaFallenEyeMortoDaScheda(sheet);
    }
    _touchFallenEyes();
  }

  /// Older saves only kept the Common penalty as text. On their first summon,
  /// give that text a concrete, persistent effect before copying the sheet.
  void _ensureCommonEyeMalusApplied(Map<String, dynamic> eye) {
    if ('${eye['rarity'] ?? 'comune'}' != 'comune' ||
        readBoolValue(eye['commonMalusApplied'])) {
      return;
    }
    var effect = '${eye['commonMalusEffect'] ?? ''}';
    if (effect.isEmpty) {
      final legacy = '${eye['commonMalus'] ?? ''}';
      effect = switch (legacy) {
        '-2 CM' => 'cm:-2',
        '-1 CM' => 'cm:-1',
        '-2 VC' => 'vc:-2',
        '-1 VC' => 'vc:-1',
        _ => oculumFallenEyeCommonMalusEffectForRoll(
          malusRoll: 4,
          statRoll: Random.secure().nextInt(
            oculumFallenEyeCommonStatKeys.length,
          ),
        ),
      };
    }
    final data = _cloneJsonMap(
      Map<String, dynamic>.from(eye['sheetData'] as Map? ?? const {}),
    );
    oculumFallenEyeApplyCommonMalus(data, effect);
    eye['sheetData'] = data;
    eye['commonMalusEffect'] = effect;
    eye['commonMalus'] = oculumFallenEyeCommonMalusLabel(effect);
    eye['commonMalusApplied'] = true;
  }

  /// Older Epic/Oculum Eyes receive their one low-percentage buff on the first
  /// summon. Reforged Eyes receive it immediately through the same path.
  void _ensureOculumEyeBuffApplied(Map<String, dynamic> eye) {
    if ('${eye['rarity'] ?? ''}' != 'oculum' ||
        readBoolValue(eye['oculumBuffApplied'])) {
      return;
    }
    var effect = '${eye['oculumBuffEffect'] ?? ''}';
    if (effect.isEmpty) {
      effect = oculumFallenEyeOculumBuffEffectForRoll(
        targetRoll: Random.secure().nextInt(
          oculumFallenEyeOculumBuffTargets.length,
        ),
        percentageRoll: Random.secure().nextInt(5),
      );
    }
    final data = _cloneJsonMap(
      Map<String, dynamic>.from(eye['sheetData'] as Map? ?? const {}),
    );
    oculumFallenEyeApplyOculumBuff(data, effect);
    eye['sheetData'] = data;
    eye['oculumBuffEffect'] = effect;
    eye['oculumBuffApplied'] = true;
    final activeIndex = schedePersonaggio.indexWhere(
      (sheet) => '${sheet['occhioCadutoId'] ?? ''}' == '${eye['id']}',
    );
    if (activeIndex >= 0) schedePersonaggio[activeIndex] = _cloneJsonMap(data);
  }

  Future<void> reforgeFallenEye(Map<String, dynamic> eye) async {
    final current = '${eye['rarity'] ?? 'comune'}';
    final target = oculumFallenEyeNextRarity(current);
    final credits = readIntValue(eye['reforgeQuestCredits']);
    if (credits <= 0) {
      _fallenEyeMessage(
        'Reforge bloccato: serve una ricompensa Quest “tentativo di Reforge”.',
      );
      return;
    }
    if (target == null) {
      await grantFallenEyeXp(
        eye,
        amount: oculumFallenEyeEpicReforgeXp,
        source: 'epic_reforge',
      );
      setState(() {
        eye['reforgeQuestCredits'] = credits - 1;
        (eye['reforgeHistory'] as List).add({
          'at': DateTime.now().toIso8601String(),
          'from': current,
          'to': current,
          'kind': 'epic_xp',
          'xp': oculumFallenEyeEpicReforgeXp,
          'success': true,
        });
        _touchFallenEyes();
      });
      await salvaDati();
      _fallenEyeMessage(
        'REFORGE OCULUM (EPICO): +$oculumFallenEyeEpicReforgeXp EXP',
      );
      return;
    }
    final difficulty = fallenEyeDifficulty(eye);
    final failureStreak = readIntValue(eye['reforgeFailureStreak']);
    final baseChance = oculumFallenEyeReforgeChance(difficulty, target);
    final failureBonus = oculumFallenEyeReforgeFailureBonus(failureStreak);
    final chance = oculumFallenEyeReforgeChanceWithFailures(
      difficulty: difficulty,
      targetRarity: target,
      failureStreak: failureStreak,
    );
    final success = Random.secure().nextInt(100) < chance;
    setState(() {
      eye['reforgeQuestCredits'] = credits - 1;
      (eye['reforgeHistory'] as List).add({
        'at': DateTime.now().toIso8601String(),
        'from': current,
        'to': target,
        'difficulty': difficulty,
        'baseChance': baseChance,
        'failureBonus': failureBonus,
        'chance': chance,
        'failureStreakBefore': failureStreak,
        'success': success,
      });
      if (success) {
        eye['rarity'] = target;
        eye['reforgeFailureStreak'] = 0;
        if (current == 'comune') {
          final effect = '${eye['commonMalusEffect'] ?? ''}';
          if (readBoolValue(eye['commonMalusApplied']) && effect.isNotEmpty) {
            final data = _cloneJsonMap(
              Map<String, dynamic>.from(eye['sheetData'] as Map? ?? const {}),
            );
            oculumFallenEyeApplyCommonMalus(data, effect, multiplier: -1);
            eye['sheetData'] = data;
            final activeIndex = schedePersonaggio.indexWhere(
              (sheet) => '${sheet['occhioCadutoId'] ?? ''}' == '${eye['id']}',
            );
            if (activeIndex >= 0) {
              schedePersonaggio[activeIndex] = _cloneJsonMap(data);
            }
          }
          eye['commonMalusApplied'] = false;
          eye['commonMalusRemovedAt'] = DateTime.now().toIso8601String();
        }
        if (target == 'raro' && !readBoolValue(eye['rareAttributeEligible'])) {
          eye['rareAttributeEligible'] = oculumFallenEyeWinsRareAttributeRoll(
            Random.secure().nextInt(100),
          );
        }
        if (target == 'oculum') _ensureOculumEyeBuffApplied(eye);
      } else {
        eye['reforgeFailureStreak'] = failureStreak + 1;
      }
      _touchFallenEyes();
    });
    await salvaDati();
    if (success && target == 'raro') {
      await _chooseFallenEyeRareAttributeIfAvailable(eye);
    }
    _fallenEyeMessage(
      success
          ? 'REFORGE RIUSCITO: ${oculumFallenEyeLabel(target)}'
          : 'REFORGE FALLITO: il prossimo tentativo ha +$oculumFallenEyeReforgeFailureBonusPerAttempt% (serie ${failureStreak + 1}).',
    );
  }

  void _showFallenEyeSummonNotice(
    Map<String, dynamic> eye, {
    required bool summoned,
    required String detail,
  }) {
    final color = oculumFallenEyeColor('${eye['rarity'] ?? 'comune'}');
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 4),
        content: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: messenger.hideCurrentSnackBar,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10121A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: .9),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .22), blurRadius: 16),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    summoned ? Icons.visibility : Icons.visibility_off,
                    color: color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summoned
                            ? 'OCCHIO CADUTO EVOCATO'
                            : 'OCCHIO CADUTO DISEVOCATO',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${eye['name'] ?? 'Occhio Caduto'} • $detail',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fallenEyeMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Widget fallenEyesPage() => ValueListenableBuilder<int>(
    valueListenable: fallenEyesRevision,
    builder: (context, _, _) {
      final eyes = occhiCaduti.where((eye) {
        final name = '${eye['name'] ?? ''}'.toLowerCase();
        return '${eye['ownerSheetId'] ?? ''}' == sheetTagAt(schedaCorrente) &&
            (fallenEyesSearch.isEmpty ||
                name.contains(fallenEyesSearch.toLowerCase())) &&
            (fallenEyesRarityFilter == 'tutte' ||
                eye['rarity'] == fallenEyesRarityFilter) &&
            (fallenEyesActiveFilter == null ||
                readBoolValue(eye['active']) == fallenEyesActiveFilter);
      }).toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'OCCHI DEI CADUTI',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateFallenEyeDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crea Occhio Caduto'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: copyCurrentSheetAsFallenEye,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copia come Occhio'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    onChanged: (v) => setState(() {
                      fallenEyesSearch = v;
                    }),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cerca Occhio',
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: fallenEyesRarityFilter,
                  items: ['tutte', ...oculumFallenEyeRarities]
                      .map(
                        (x) => DropdownMenuItem(
                          value: x,
                          child: Text(
                            x == 'tutte'
                                ? 'Tutte le rarità'
                                : oculumFallenEyeLabel(x),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    fallenEyesRarityFilter = v ?? 'tutte';
                  }),
                ),
                FilterChip(
                  label: const Text('Attivi'),
                  selected: fallenEyesActiveFilter == true,
                  onSelected: (v) => setState(() {
                    fallenEyesActiveFilter = v ? true : null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              // Ogni carta contiene la Quest sempre scrivibile: non tenere
              // vivi tutti i TextFormField fuori dallo schermo e non
              // precostruire una seconda schermata di carte.
              addAutomaticKeepAlives: false,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 330,
                mainAxisExtent: 285,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: eyes.length,
              itemBuilder: (_, i) => _fallenEyeCard(eyes[i]),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _showCreateFallenEyeDialog({
    Map<String, dynamic>? editingEye,
  }) async {
    var draft = _cloneJsonMap(
      editingEye == null
          ? schedePersonaggio[schedaCorrente]
          : Map<String, dynamic>.from(editingEye['sheetData'] as Map),
    );
    final name = TextEditingController(text: '${draft['nome'] ?? ''}');
    final level = TextEditingController(text: '${draft['livello'] ?? '1'}');
    final hp = TextEditingController(text: '${draft['currentHp'] ?? ''}');
    final res = TextEditingController(text: '${draft['resilienza'] ?? ''}');
    final vol = TextEditingController(text: '${draft['volonta'] ?? ''}');
    final mat = TextEditingController(text: '${draft['materia'] ?? ''}');
    final ocu = TextEditingController(text: '${draft['oculum'] ?? ''}');
    final cm = TextEditingController(text: '${draft['cmRapido'] ?? ''}');
    final vc = TextEditingController(text: '${draft['attaccoRapido'] ?? ''}');
    String? selectedRarity = editingEye == null
        ? null
        : '${editingEye['rarity'] ?? 'comune'}';
    final artNames = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    void loadDraft(Map<String, dynamic> source) {
      draft = _cloneJsonMap(source);
      name.text = '${draft['nome'] ?? ''}';
      level.text = '${draft['livello'] ?? '1'}';
      hp.text = '${draft['currentHp'] ?? ''}';
      res.text = '${draft['resilienza'] ?? ''}';
      vol.text = '${draft['volonta'] ?? ''}';
      mat.text = '${draft['materia'] ?? ''}';
      ocu.text = '${draft['oculum'] ?? ''}';
      cm.text = '${draft['cmRapido'] ?? ''}';
      vc.text = '${draft['attaccoRapido'] ?? ''}';
      final arts =
          (draft['fallenEyeOriginalArts'] ?? draft['arti'] ?? []) as List;
      for (var i = 0; i < artNames.length; i++) {
        artNames[i].text = i < arts.length && arts[i] is Map
            ? '${(arts[i] as Map)['nome'] ?? ''}'
            : '';
      }
    }

    loadDraft(draft);
    MonsterBookEntry? selectedMonster;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text(
            editingEye == null
                ? 'Crea Occhio Caduto'
                : 'Modifica Occhio Caduto',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Compila liberamente oppure parti da una creatura già salvata. Il Monster Book non verrà mai modificato.',
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Apri Monster Book',
                        icon: const Icon(Icons.menu_book),
                        onPressed: () async {
                          final picked = await _pickMonsterBookForFallenEye();
                          if (picked == null) return;
                          dialogSetState(() {
                            selectedMonster = picked;
                            loadDraft(
                              _fallenEyeSourceFromMonsterBook(
                                picked,
                                name: picked.nameIt,
                                level: max(1, int.tryParse(level.text) ?? 1),
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedMonster == null
                        ? 'Creazione manuale'
                        : 'Dal Monster Book: ${selectedMonster!.nameIt}',
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome del mostro',
                    ),
                  ),
                  TextField(
                    controller: level,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => dialogSetState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Livello',
                      helperText:
                          'Grado automatico: ${gradoAutomaticoDaLivello(max(0, int.tryParse(level.text) ?? 0), false)}',
                    ),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedRarity,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Rarità',
                      helperText:
                          'Lascia “Casuale” per estrarla alla creazione.',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Casuale'),
                      ),
                      ...oculumFallenEyeRarities.map(
                        (rarity) => DropdownMenuItem<String?>(
                          value: rarity,
                          child: Text(oculumFallenEyeLabel(rarity)),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        dialogSetState(() => selectedRarity = value),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Statistiche',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: hp,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Vita'),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: res,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Resilienza',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: vol,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Volontà',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: mat,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Materia',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: ocu,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Oculum',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: cm,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CM'),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: vc,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'VC'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Art originali',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  for (var i = 0; i < artNames.length; i++)
                    TextField(
                      controller: artNames[i],
                      decoration: InputDecoration(
                        labelText: 'Art ${i + 1}',
                        hintText: '???',
                      ),
                    ),
                  Text(
                    'Lascia vuoto un campo per salvare un Art ancora sconosciuta: verrà mostrata come ???.',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(editingEye == null ? 'CREA' : 'SALVA MODIFICHE'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      final parsedLevel = max(0, int.tryParse(level.text) ?? 1);
      draft.addAll({
        'nome': name.text.trim(),
        'livello': '$parsedLevel',
        'grado': '${gradoAutomaticoDaLivello(parsedLevel, false)}',
        'currentHp': '${max(1, int.tryParse(hp.text) ?? 1)}',
        'resilienza': '${max(1, int.tryParse(res.text) ?? 1)}',
        'currentResilienza': '${max(1, int.tryParse(res.text) ?? 1)}',
        'volonta': '${max(0, int.tryParse(vol.text) ?? 0)}',
        'currentVolonta': '${max(0, int.tryParse(vol.text) ?? 0)}',
        'materia': '${max(0, int.tryParse(mat.text) ?? 0)}',
        'currentMateria': '${max(0, int.tryParse(mat.text) ?? 0)}',
        'oculum': '${max(0, int.tryParse(ocu.text) ?? 0)}',
        'currentOculum': '${max(0, int.tryParse(ocu.text) ?? 0)}',
        'cmRapido': cm.text,
        'attaccoRapido': vc.text,
        'fallenEyeOriginalArts': [
          for (final controller in artNames)
            {
              'nome': controller.text.trim(),
              'known': controller.text.trim().isNotEmpty,
            },
        ],
      });
      if (editingEye == null) {
        await createFallenEyeFromSource(
          draft,
          name: name.text,
          rarity: selectedRarity,
        );
      } else {
        final rarity = selectedRarity ?? '${editingEye['rarity'] ?? 'comune'}';
        final originalArts = (draft['fallenEyeOriginalArts'] as List)
            .whereType<Map>()
            .map((art) => Map<String, dynamic>.from(art))
            .toList();
        draft['occhioCadutoId'] = editingEye['id'];
        draft['occhioCaduto'] = true;
        setState(() {
          editingEye['name'] = draft['nome'];
          editingEye['rarity'] = rarity;
          editingEye['originalArts'] = originalArts;
          editingEye['activeArts'] = originalArts
              .take(oculumFallenEyeArtLimit(rarity))
              .toList();
          editingEye['sheetData'] = _cloneJsonMap(draft);
          final activeIndex = schedePersonaggio.indexWhere(
            (sheet) =>
                '${sheet['occhioCadutoId'] ?? ''}' == '${editingEye['id']}',
          );
          if (activeIndex >= 0) {
            schedePersonaggio[activeIndex] = _cloneJsonMap(draft);
          }
          _touchFallenEyes();
        });
        await salvaDati();
        _fallenEyeMessage('Occhio Caduto modificato.');
      }
    }
    name.dispose();
    level.dispose();
    hp.dispose();
    res.dispose();
    vol.dispose();
    mat.dispose();
    ocu.dispose();
    cm.dispose();
    vc.dispose();
    for (final controller in artNames) {
      controller.dispose();
    }
  }

  Widget _fallenEyeCard(Map<String, dynamic> eye) {
    final rarity = '${eye['rarity'] ?? 'comune'}';
    final color = oculumFallenEyeColor(rarity);
    final activeOwnerEyes = _activeFallenEyeOwnerCount(eye);
    final needsMaintenance = oculumFallenEyeNeedsMaintenance(activeOwnerEyes);
    final maintenanceDifficulty = oculumFallenEyeMaintenanceDifficulty(
      ownerEyeCount: activeOwnerEyes,
      failureStreak: readIntValue(eye['maintenanceFailureStreak']),
    );
    final paidWithWill = '${eye['summonPayment'] ?? 'oculum'}' == 'volonta';
    final data = Map<String, dynamic>.from(
      eye['sheetData'] as Map? ?? const {},
    );
    final image = decodedBase64ImageCached(
      '${eye['portraitBase64'] ?? data['immaginePersonaggioBase64'] ?? ''}',
    );
    return GestureDetector(
      onTap: () => _showFallenEyeDetail(eye),
      onSecondaryTap: () => _showFallenEyeMenu(eye),
      onLongPress: () => _showFallenEyeMenu(eye),
      child: Card(
        color: const Color(0xFF12141C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: image == null
                            ? Image.asset(
                                'assets/icon/oculum_eye.png',
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              )
                            : Image.memory(
                                image,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                cacheWidth: 152,
                              ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: IconButton.filledTonal(
                          tooltip: 'Sostituisci immagine',
                          icon: const Icon(Icons.add_a_photo, size: 17),
                          onPressed: () => scegliImmagineOcchioCaduto(eye),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${eye['name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          oculumFallenEyeLabel(rarity),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Origine: ${eye['sourceClass'] ?? oculumFallenEyeSourceClass(data)}',
                        ),
                        Text('Difficoltà: ${fallenEyeDifficulty(eye)}'),
                        Text(
                          'Vita ${data['currentHp'] ?? 0}  •  Integrità ${eye['integrityCurrent']}/${eye['integrityMax']}',
                        ),
                        if ('${eye['oculumBuffEffect'] ?? ''}'.isNotEmpty)
                          Text(
                            'RISVEGLIO OCULUM: ${oculumFallenEyeOculumBuffLabel('${eye['oculumBuffEffect']}')}',
                            style: const TextStyle(
                              color: Color(0xFFB58CFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        if ('${eye['rareAttribute'] ?? ''}'.isNotEmpty)
                          Text(
                            'ATTRIBUTO RARO: ${oculumFallenEyeRareAttributeLabel('${eye['rareAttribute']}')} +${readIntValue(eye['rareAttributeBonus'])}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          oculumFallenEyeIsDead(eye)
                              ? 'MORTO — NON EVOCABILE'
                              : readBoolValue(eye['active'])
                              ? 'EVOCATO'
                              : 'DISEVOCATO',
                          style: TextStyle(
                            color: oculumFallenEyeIsDead(eye)
                                ? Colors.redAccent
                                : readBoolValue(eye['active'])
                                ? Colors.lightGreen
                                : Colors.grey,
                          ),
                        ),
                        if (needsMaintenance)
                          Text(
                            paidWithWill
                                ? 'TENUTA: ${readIntValue(eye['willMaintenanceDebt'])} tiro Vita • DT $maintenanceDifficulty'
                                : 'TENUTA: Oculum/Manifestazione • DT $maintenanceDifficulty',
                            style: TextStyle(
                              color: readBoolValue(eye['active'])
                                  ? Colors.amberAccent
                                  : Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            'TENUTA STABILE — un solo Occhio',
                            style: TextStyle(
                              color: Colors.lightGreen,
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'Art ${(eye['activeArts'] as List? ?? []).length}/${oculumFallenEyeArtLimit(rarity)}',
                        ),
                        if (oculumFallenEyeCanLevel(rarity))
                          Text(
                            'Lv ${data['livello'] ?? 0} • EXP ${data['exp'] ?? 0}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: .55)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 17, color: color),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'QUEST REFORGE',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          'Tentativi: ${readIntValue(eye['reforgeQuestCredits'])}',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: ValueKey('fallen_eye_reforge_quest_${eye['id']}'),
                      initialValue: '${eye['reforgeQuestNote'] ?? ''}',
                      minLines: 1,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText:
                            'Scrivi qui cosa serve per tentare il Reforge',
                      ),
                      onChanged: (value) {
                        eye['reforgeQuestNote'] = value;
                        programmaSalvataggio();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFallenEyeMenu(Map<String, dynamic> eye) => showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifica'),
            onTap: () {
              Navigator.pop(context);
              _showCreateFallenEyeDialog(editingEye: eye);
            },
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('Invia Occhio Caduto'),
            subtitle: const Text(
              'Condivide una copia ad amici e Master RealTime senza trasferire né eliminare l’Occhio.',
            ),
            onTap: () {
              Navigator.pop(context);
              sendFallenEyeToRealtime(eye);
            },
          ),
          ListTile(
            leading: Icon(
              readBoolValue(eye['active'])
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            title: Text(
              oculumFallenEyeIsDead(eye)
                  ? 'Morto — non evocabile'
                  : readBoolValue(eye['active'])
                  ? 'Disevoca Occhio Caduto'
                  : 'Evoca Occhio Caduto',
            ),
            subtitle: Text(
              oculumFallenEyeIsDead(eye)
                  ? 'La perdita è definitiva.'
                  : 'Usa 1 azione se il turno del proprietario è attivo; funziona anche senza.',
            ),
            onTap: () {
              Navigator.pop(context);
              if (oculumFallenEyeIsDead(eye)) return;
              readBoolValue(eye['active'])
                  ? dismissFallenEye(eye)
                  : summonFallenEye(eye);
            },
          ),
          if (readBoolValue(eye['active']) &&
              '${eye['summonPayment'] ?? 'oculum'}' == 'volonta' &&
              readIntValue(eye['willMaintenanceDebt']) > 0)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Tiro tenuta — Volontà'),
              subtitle: Text(
                '${readIntValue(eye['willMaintenanceDebt'])} debito/i da Vita persa • puoi usare anche Resistenza o Eco dalla scheda',
              ),
              onTap: () {
                Navigator.pop(context);
                tiraMantenimentoOcchioConVolonta(eye);
              },
            ),
          if (readBoolValue(eye['active']) &&
              oculumFallenEyeNeedsMaintenance(
                _activeFallenEyeOwnerCount(eye),
              ) &&
              '${eye['summonPayment'] ?? 'oculum'}' != 'volonta')
            ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('Tenuta tramite Oculum / Manifestazione'),
              subtitle: Text(
                'Fai il tiro nella scheda proprietaria. DT ${oculumFallenEyeMaintenanceDifficulty(ownerEyeCount: _activeFallenEyeOwnerCount(eye), failureStreak: readIntValue(eye['maintenanceFailureStreak']))}; con un fallimento perdi 1 Oculum e hai il 50% di disevocazione.',
              ),
              onTap: () => Navigator.pop(context),
            ),
          ListTile(
            leading: const Icon(Icons.upgrade),
            title: Text(
              oculumFallenEyeNextRarity('${eye['rarity']}') == null
                  ? 'Reforge Oculum (Epico) — EXP'
                  : 'Reforge → ${oculumFallenEyeLabel(oculumFallenEyeNextRarity('${eye['rarity']}')!)}',
            ),
            subtitle: Text(
              oculumFallenEyeNextRarity('${eye['rarity']}') == null
                  ? 'Quest: ${readIntValue(eye['reforgeQuestCredits'])} tentativi • +$oculumFallenEyeEpicReforgeXp EXP'
                  : 'Quest: ${readIntValue(eye['reforgeQuestCredits'])} tentativi • Reforge ${oculumFallenEyeReforgeChanceWithFailures(difficulty: fallenEyeDifficulty(eye), targetRarity: oculumFallenEyeNextRarity('${eye['rarity']}')!, failureStreak: readIntValue(eye['reforgeFailureStreak']))}% (+${oculumFallenEyeReforgeFailureBonus(readIntValue(eye['reforgeFailureStreak']))}% dai fallimenti)',
            ),
            onTap: () {
              Navigator.pop(context);
              reforgeFallenEye(eye);
            },
          ),
          if (!readBoolValue(eye['active']) && !oculumFallenEyeIsDead(eye))
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Evoca e assegna EXP'),
              subtitle: Text(
                'Usa 1 azione solo se disponibile. ${oculumFallenEyeCanLevel('${eye['rarity']}') ? '+${oculumFallenEyeSummonXpForDifficulty(fallenEyeDifficulty(eye))} EXP flat' : 'Level Up bloccato dalla rarità'}',
              ),
              onTap: () {
                Navigator.pop(context);
                summonFallenEye(eye);
              },
            ),
          if (oculumFallenEyeCanLevel('${eye['rarity']}'))
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Usa 100 EXP del proprietario'),
              subtitle: const Text('Trasferimento esplicito con fonte OWNER'),
              onTap: () {
                Navigator.pop(context);
                grantFallenEyeOwnerXp(eye, 100);
              },
            ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Personalizza tema'),
            subtitle: Text(
              '${(eye['theme'] as Map?)?['colorPreset'] ?? 'tema scheda'}',
            ),
            onTap: () {
              Navigator.pop(context);
              cycleFallenEyeTheme(eye);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo),
            title: const Text('Sostituisci immagine'),
            subtitle: const Text('Prende il posto dell’occhio sulla carta.'),
            onTap: () {
              Navigator.pop(context);
              scegliImmagineOcchioCaduto(eye);
            },
          ),
          if ('${eye['portraitBase64'] ?? ''}'.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: const Text('Ripristina occhio standard'),
              onTap: () {
                Navigator.pop(context);
                rimuoviImmagineOcchioCaduto(eye);
              },
            ),
        ],
      ),
    ),
  );

  void _showFallenEyeDetail(Map<String, dynamic> eye) => showDialog<void>(
    context: context,
    builder: (dialog) {
      final rarity = '${eye['rarity']}';
      final target = oculumFallenEyeNextRarity(rarity);
      return AlertDialog(
        title: Text('${eye['name']} — OCCHIO CADUTO'),
        content: Text(
          'Origine: ${eye['sourceClass'] ?? oculumFallenEyeSourceClass(Map<String, dynamic>.from(eye['sheetData'] as Map? ?? const {}))}\nRarità: ${oculumFallenEyeLabel(rarity)}\nStato: ${oculumFallenEyeIsDead(eye)
              ? 'Morto — non evocabile'
              : readBoolValue(eye['active'])
              ? 'Evocato'
              : 'Disevocato'}\nEvoca/Disevoca: usa 1 azione solo se disponibile\nDifficoltà proprietaria: ${fallenEyeDifficulty(eye)}\nRigenerazione: ${oculumFallenEyeCanRegenerate(rarity) ? '✓' : '🔒'}\nArt: ${(eye['activeArts'] as List? ?? []).length}/${oculumFallenEyeArtLimit(rarity)}\nArt originali: ${((eye['originalArts'] as List? ?? []).map((art) {
            final item = art is Map ? art : const <String, dynamic>{};
            return item['known'] == false || '${item['nome'] ?? ''}'.trim().isEmpty ? '???' : '${item['nome']}';
          }).join(', '))}\nConoscenze ereditate: nessuna (Art, Skill e Titoli restano separati dall’evocatore).\nLivelli: ${oculumFallenEyeCanLevel(rarity) ? '✓' : '🔒'}\nTitoli: ${oculumFallenEyeCanHaveTitles(rarity) ? '✓' : '🔒'}\nTema: ${(eye['theme'] as Map?)?['colorPreset'] ?? 'tema scheda'}${oculumFallenEyeCanLevel(rarity) ? '\nEXP: ${(eye['sheetData'] as Map?)?['exp'] ?? 0} • ultima evocazione +${eye['lastSummonXp'] ?? 0}' : ''}${target == null ? '\nReforge Oculum (Epico): +$oculumFallenEyeEpicReforgeXp EXP per tentativo Quest.' : '\nReforge $rarity → $target: ${oculumFallenEyeReforgeChanceWithFailures(difficulty: fallenEyeDifficulty(eye), targetRarity: target, failureStreak: readIntValue(eye['reforgeFailureStreak']))}% (base ${oculumFallenEyeReforgeChance(fallenEyeDifficulty(eye), target)}% + ${oculumFallenEyeReforgeFailureBonus(readIntValue(eye['reforgeFailureStreak']))}% fallimenti)'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Chiudi'),
          ),
        ],
      );
    },
  );
}
