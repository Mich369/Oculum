part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int? oculumScrollDropGrade(String subtraitId, int total) =>
    subtraitId == 'drop' && total >= 18 ? min(12, (total - 18) ~/ 10) : null;

int oculumScrollValue(int grade) =>
    300 * pow(grade.clamp(0, 12) + 1, 2).toInt();

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
  final thorns = ['pianta', 'natura', 'radice'].contains(element);
  final name = switch (kind) {
    'control' => thorns ? 'Rovi di spine' : 'Vincolo di $label',
    'ward' => 'Egida di $label',
    _ => element == 'gelo' ? 'Dardo di Ghiaccio' : 'Dardo di $label',
  };
  final description = switch (kind) {
    'control' =>
      '${thorns ? 'Dei rovi si generano sotto' : 'Un vincolo di $label rallenta'} '
          '${g == 0 ? 'un avversario' : 'fino a ${g + 1} avversari'}. '
          'Rallentamento per ${2 + g} turni; ottieni vantaggio +${2 + g} ai tiri '
          'per ${2 + g} tuoi turni.'
          '${g == 0 ? '' : ' Ogni bersaglio subisce ${(g * 50)}% dei tuoi danni.'}',
    'ward' =>
      'Un’egida di $label ti protegge: +${3 + 3 * g} Difesa per '
          '${2 + g} tuoi turni. Non si cumula con un’altra egida della stessa skill.',
    _ =>
      'Dalla mano, senza impugnare la pergamena, lanci un dardo di $label: '
          '1d${8 + 6 * g} danni + i tuoi danni, elemento $label.'
          '${g == 0 ? '' : ' Con critico: ${element == 'gelo' ? 'applica Gelo e ' : ''}+${20 * g}% danni allo scudo.'}',
  };
  final data = <String, dynamic>{
    'id': '$element/$kind/$g',
    'element': element,
    'grade': g,
    'kind': kind,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${data['name']} · Grado ${data['grade']}'),
        content: SingleChildScrollView(
          child: Text(
            '${data['description']}\n\n${item == null ? 'Skill appresa, non evolvibile.' : 'Consuma una pergamena. Possibilità di apprendimento: 20% con 20 naturale e totale ≥ ${30 + 10 * readIntValue(data['grade'])}.'}'
            '\nIl tiro usa Volontà, bonus ai tiri, Oculum preparato e difficoltà. '
            'I bersagli e i loro effetti vengono dichiarati al Master.',
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
    final g = readIntValue(data['grade']).clamp(0, 12);
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
          'remaining': 2 + g,
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
                costo: '0',
                cooldown: '0',
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
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    notifyDiceResultChanged();
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
}
