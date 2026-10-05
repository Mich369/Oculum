part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int? oculumScrollDropGrade(String subtraitId, int total) =>
    subtraitId == 'drop' && total >= 18 ? min(12, (total - 18) ~/ 10) : null;

int oculumScrollValue(int grade) =>
    300 * pow(grade.clamp(0, 12) + 1, 2).toInt();

String oculumScrollKindForElement(String element) => switch (element) {
  'gelo' || 'ghiaccio' => 'attack',
  'fuoco' || 'fiamma' => 'attack',
  'acqua' => 'heal',
  'terra' || 'pietra' => 'imprison',
  'pianta' || 'natura' || 'radice' => 'control',
  'luce' => 'ward',
  'ombra' => 'weaken',
  'fulmine' || 'elettricita' => 'stun',
  _ => 'attack',
};

int oculumScrollDifficulty(int grade) => 12 + 2 * grade.clamp(0, 12);

int oculumScrollWillCost(int grade) => 1 + grade.clamp(0, 12) ~/ 3;

int oculumScrollCooldown(int grade) => 3 + grade.clamp(0, 12) ~/ 3;

int oculumScrollEffectMagnitude(int grade) => 1 + grade.clamp(0, 12);

bool oculumScrollCanLearn(int natural, int total, int grade, int percentile) =>
    natural == 20 &&
    total >= 30 + 10 * grade.clamp(0, 12) &&
    percentile >= 0 &&
    percentile < 20;

InventoryItem oculumScrollItem(
  String element,
  String label,
  int grade,
  String kind,
) {
  final g = grade.clamp(0, 12);
  final selectedKind = kind == 'auto'
      ? oculumScrollKindForElement(element)
      : kind;
  final thorns = ['pianta', 'natura', 'radice'].contains(element);
  final name = switch (selectedKind) {
    'control' => 'Rovi di Spine',
    'ward' => 'Bastione di Luce',
    'heal' => 'Pioggia Rigenerante',
    'imprison' => "Gabbia d’Ossa",
    'weaken' => 'Marchio d’Ombra',
    'stun' => 'Saetta Paralizzante',
    _ => element == 'gelo' ? 'Dardo di Ghiaccio' : 'Lancia di $label',
  };
  final description = switch (selectedKind) {
    'control' =>
      '${thorns ? 'Dei rovi si generano sotto' : 'Un vincolo di $label rallenta'} '
          '${g == 0 ? 'un avversario' : 'fino a ${g + 1} avversari'}. '
          'Rallentamento per ${2 + g} turni; ottieni vantaggio +${2 + g} ai tiri '
          'per ${2 + g} tuoi turni.'
          '${g == 0 ? '' : ' Ogni bersaglio subisce ${(g * 50)}% dei tuoi danni.'}',
    'ward' =>
      'Un alleato scelto ottiene ${5 + 2 * g} scudo fino al suo prossimo turno. A ogni grado aggiunge +2 scudo.',
    'heal' =>
      'Cura un bersaglio nella turnistica di ${8 + 4 * g} HP; ogni grado aggiunge 4 HP.',
    'imprison' =>
      'Una gabbia d’ossa magiche si solleva dal terreno e imprigiona un bersaglio per un turno. Ai gradi superiori la gabbia assorbe ${5 + 5 * g} danni prima di cedere.',
    'weaken' =>
      'Il bersaglio scelto subisce -${1 + g ~/ 3} ai tiri fino alla fine del suo prossimo turno; ai gradi superiori il marchio dura ${1 + g ~/ 3} turni.',
    'stun' =>
      'La saetta infligge ${4 + 2 * g} danni e impone -${1 + g ~/ 4} al prossimo tiro del bersaglio.',
    _ =>
      'Dalla mano, senza impugnare la pergamena, lanci un dardo di $label: '
          '1d${8 + 6 * g} danni + i tuoi danni, elemento $label.'
          '${g == 0 ? '' : ' Con critico: ${element == 'gelo' ? 'applica Gelo e ' : ''}+${20 * g}% danni allo scudo.'}',
  };
  final data = <String, dynamic>{
    'id': '$element/$kind/$g',
    'element': element,
    'grade': g,
    'kind': selectedKind,
    'name': name,
    'description': description,
  };
  return InventoryItem(
    nome: '[$name] [Pergamena] [Grado $g]',
    peso: .1,
    quantita: 1,
    gradoOggetto: g,
    elementoDanno: element,
    note:
        '$description\nMonouso. Valore: ${oculumScrollValue(g)} Obser. '
        'Con 20 naturale e totale ≥ ${30 + 10 * g}: 20% di apprendere '
        'la skill, non evolvibile. Gli effetti sui bersagli sono dichiarati al Master.',
    craftData: {'scroll': data},
  );
}

extension _OculumScrolls on _OculumHomePageState {
  Future<void> useScrollAbility(
    Map<String, dynamic> data, {
    InventoryItem? item,
  }) async {
    if (!mounted ||
        (item != null && (!inventario.contains(item) || item.quantita <= 0))) {
      return;
    }
    final g = readIntValue(data['grade']).clamp(0, 12);
    final lastCastRound = readIntValue(data['lastCastRound'], fallback: -999);
    final cooldown = oculumScrollCooldown(g);
    if (item == null && masterInitiativeRound < lastCastRound + cooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Pergamena in ricarica fino al round ${lastCastRound + cooldown}.',
              'Scroll is on cooldown until round ${lastCastRound + cooldown}.',
            ),
          ),
        ),
      );
      return;
    }
    final cost = oculumScrollWillCost(g);
    if (currentVolonta() < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Volontà insufficiente: costo $cost.',
              'Not enough Will: cost $cost.',
            ),
          ),
        ),
      );
      return;
    }
    final targetKind =
        const {
          'attack',
          'heal',
          'imprison',
          'control',
          'weaken',
          'stun',
        }.contains('${data['kind']}') ||
        ('${data['kind']}' == 'ward' &&
            masterInitiativeTokens.any(
              (token) => masterInitiativeSheetIndexForToken(token) >= 0,
            ));
    final targets = targetKind
        ? await _selectScrollTargets('${data['kind']}', g)
        : <int>[];
    if (!mounted || (targetKind && targets.isEmpty)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${data['name']} · Grado ${data['grade']}'),
        content: SingleChildScrollView(
          child: Text(
            '${data['description']}\n\n${item == null ? 'Skill appresa, non evolvibile.' : 'Consuma una pergamena. Possibilità di apprendimento: 20% con 20 naturale e totale ≥ ${30 + 10 * readIntValue(data['grade'])}.'}'
            '\nCosto: $cost Volontà · CD ${oculumScrollDifficulty(g)} · ricarica ${oculumScrollCooldown(g)} turni. '
            'Il tiro usa Volontà, bonus e Oculum preparato. Il Master vede risultato e bersagli.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usa e tira'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        (item != null && (!inventario.contains(item) || item.quantita <= 0))) {
      return;
    }
    currentVolontaController.text = '${currentVolonta() - cost}';
    final natural = tiraD20();
    final spend = consumaOculumTiro();
    final bonus =
        volontaTotale() +
        runtimeQuickBonus('tiro_volonta') +
        tiroGlobaleBonus() +
        spend.bonus;
    final total = rollTotalWithCritical(natural, 20, [bonus]);
    final success =
        natural != 1 &&
        total >= oculumScrollDifficulty(g) &&
        (slotMachineRollsEnabled
            ? resolveSlotMachineSuccess(naturalRoll: natural)
            : total > 0);
    final formula = rollFormulaWithCritical(
      roll: natural,
      faces: 20,
      bonuses: [bonus],
    );
    final kind = '${data['kind']}';
    final source = 'pergamena/${data['element']}/$kind';
    var outcome = success
        ? '${data['description']}'
        : 'Tiro fallito: nessun effetto.';
    if (success && kind == 'attack') {
      final faces = 8 + 6 * g;
      final damage = Random.secure().nextInt(faces) + 1;
      outcome +=
          '\nDanni: $damage + ${dannoTotale()} = ${damage + dannoTotale()} '
          '(${elementDisplayName('${data['element']}')}).';
      if (natural == 20 && g > 0) {
        outcome +=
            '\nDanni allo scudo con critico: ${((damage + dannoTotale()) * (1 + .2 * g)).ceil()}.';
      }
      if (natural != 20) outcome += ' Effetti da critico non attivati.';
    } else if (success && kind == 'control' && g > 0) {
      outcome +=
          '\nDanni per bersaglio: ${(dannoTotale() * g * .5).ceil()}. Il Master conferma i bersagli.';
    }
    var learned = '';
    setState(() {
      dadoMostrato = formula;
      dadoMostratoFacce = 20;
      tiroCriticoUno = natural == 1;
      tiroCriticoVenti = natural == 20;
      slotMachineLastSucceeded = success;
      if (item != null) {
        item.quantita--;
        if (item.quantita == 0) inventario.remove(item);
      }
      if (success && (kind == 'ward' || kind == 'control')) {
        activeStructuredEffects.removeWhere(
          (effect) => effect['source'] == source,
        );
        activeStructuredEffects.add({
          'source': source,
          'target': kind == 'ward' ? 'difesa' : 'tiro_globale',
          'value': kind == 'ward' ? 3 + 3 * g : 2 + g,
          'remaining': 1 + g ~/ 3,
          'unit': 'turn',
          'frequency': '',
          'type': 'bonus',
          'stackable': false,
        });
      }
      if (item != null && natural == 20 && total >= 30 + 10 * g) {
        final percentile = Random.secure().nextInt(100);
        if (oculumScrollCanLearn(natural, total, g, percentile)) {
          if (!skills.any((skill) => skill.scrollData['id'] == data['id'])) {
            skills.add(
              CharacterSkill(
                nome: '${data['name']} [Grado $g]',
                tipo: 'Attiva',
                costo: '$cost VOL',
                cooldown: '${oculumScrollCooldown(g)}',
                descrizione:
                    '${data['description']}\nAppresa da pergamena: non evolvibile.',
                scrollData: Map<String, dynamic>.from(data),
              ),
            );
            learned =
                '\nSkill appresa (d100 ${percentile + 1} ≤ 20), non evolvibile.';
          } else {
            learned = '\nSkill già appresa: nessun duplicato.';
          }
        } else {
          learned = '\nSkill non appresa (d100 ${percentile + 1} > 20).';
        }
      }
      risultato =
          '${data['name']} [Grado $g]: $formula.${oculumTiroLogLabel(spend)}\n$outcome$learned';
      aggiungiLog(risultato);
    });
    if (success) {
      for (final sheetIndex in targets) {
        switch (kind) {
          case 'attack':
            applyMasterEnemyQuickHpAction(
              sheetIndex,
              damage: 8 + 6 * g + dannoTotale(),
            );
            break;
          case 'heal':
            applyMasterEnemyQuickHpAction(sheetIndex, heal: 8 + 4 * g);
            break;
          case 'ward':
            final shield = sheetIntValueAt(sheetIndex, 'scudo');
            setMasterEnemyLayerValue(sheetIndex, 'scudo', shield + 5 + 2 * g);
            break;
          case 'imprison':
          case 'control':
          case 'weaken':
          case 'stun':
            final tokenIndex = masterInitiativeTokens.indexWhere(
              (token) =>
                  masterInitiativeSheetIndexForToken(token) == sheetIndex,
            );
            if (tokenIndex >= 0) {
              final token = masterInitiativeTokens[tokenIndex];
              final effects = List<Map<String, dynamic>>.from(
                (token['scrollEffects'] as List? ?? const [])
                    .whereType<Map>()
                    .map((effect) => Map<String, dynamic>.from(effect)),
              );
              final oldNotes = effects
                  .where((effect) => '${effect['source']}' == source)
                  .map((effect) => '${effect['note'] ?? ''}')
                  .where((note) => note.isNotEmpty)
                  .toSet();
              effects.removeWhere((effect) => '${effect['source']}' == source);
              final duration = kind == 'imprison' ? 1 : 1 + g ~/ 3;
              final effectNote =
                  '${data['name']} · ${kind == 'imprison' ? 'imprigionato per 1 turno' : 'effetto per $duration turni'}';
              effects.add({
                'source': source,
                'name': '${data['name']}',
                'kind': kind,
                'remainingTurns': duration,
                'magnitude': 1 + g,
                'note': effectNote,
                if (kind == 'imprison') 'barrierHp': 5 + 5 * g,
              });
              token['scrollEffects'] = effects;
              final existing = '${token['notes'] ?? ''}'
                  .split('\n')
                  .where((line) => !oldNotes.contains(line))
                  .join('\n')
                  .trim();
              token['notes'] = [
                if (existing.isNotEmpty) existing,
                effectNote,
              ].join('\n');
            }
            break;
        }
      }
    }
    if (item == null) data['lastCastRound'] = masterInitiativeRound;
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    notifyDiceResultChanged();
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    mostraDadoCentrale(
      valore: formula,
      criticoUno: natural == 1,
      criticoVenti: natural == 20,
    );
    sendRealtimeDiceRoll(
      label: risultato,
      roll: natural,
      bonus: total - natural,
      total: total,
      forceMasterVisible: true,
    );
    programmaSalvataggio();
  }

  Future<List<int>> _selectScrollTargets(String kind, int grade) async {
    final options = <({int sheet, String name})>[];
    for (final token in masterInitiativeTokens) {
      final sheet = masterInitiativeSheetIndexForToken(token);
      if (sheet < 0 || options.any((option) => option.sheet == sheet)) continue;
      options.add((
        sheet: sheet,
        name: '${token['name'] ?? nomeSchedaPersonaggio(sheet)}',
      ));
    }
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Aggiungi prima i bersagli alla turnistica.',
              'Add targets to initiative first.',
            ),
          ),
        ),
      );
      return [];
    }
    final selected = <int>{};
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t('Scegli bersaglio', 'Choose target')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    CheckboxListTile(
                      value: selected.contains(option.sheet),
                      title: Text(option.name),
                      onChanged: (value) => update(() {
                        if (value == true) {
                          selected.add(option.sheet);
                        } else {
                          selected.remove(option.sheet);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected.toList()),
              child: Text(t('Conferma', 'Confirm')),
            ),
          ],
        ),
      ),
    );
    return result ?? const [];
  }
}
