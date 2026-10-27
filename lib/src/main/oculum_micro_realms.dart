part of '../../main.dart';

const oculumMicroRealmLore = <String, String>{
  'deserto_divoratore':
      'Un’unica micro realtà in due zone: Deserto Divoratore e Deserto di Vetro. La sabbia è cristallina, umida e tagliente. Piante mobili con un nucleo centrale cercano di divorare ciò che vedono. Forzieri di arenaria affiorano fra le dune. Sotto i piedi possono aprirsi discese piramidali verso l’interno di un occhio: conducono a wormhole e dimensioni segrete. Qui si trova la variante azzurra dell’Ancient Desert Dragon Claw, che trasforma in vetro anziché arenaria.',
  'reame_cristallo':
      'Caverne e laghi luminosi fra pilastri di cristallo. Colossi minerali, predatori smeraldo, figure di ossidiana e costrutti prismatici custodiscono vene proprie di questo luogo. Percezione e alternative coerenti possono rivelarle. Più alto il Grado, più raro il ritrovamento. Puoi decidere se estrarre e quanto: non puoi estrarre un materiale di Grado superiore al tuo. Il Metallo runico di Postea non si trova qui.',
  'orea_zalira':
      'Cielo e terra mutano in forme morbide e astratte sotto due soli privi di occhi. Creature buffe e innaturali abitano una natura viva e imprevedibile, con alberi flosci e altri rigidi, e fiumi che sembrano lava. Il tempo alterna velocità e lentezza. Il reame sembra osservare silenziosamente i visitatori, fra chaos e armonia. Lo controlla un essere ignoto, ancora senza nome, che non è fatato né del Chaos.',
  'carne_viva':
      'Un regno di carne viva sospeso nel vuoto più totale: nessun mondo, stella, luna o sole in lontananza. Terreno palpitante, sangue, pustole e membrane formano un ambiente organico abitato da creature di carne, tendini e ossa. Le forme dei suoi predatori e dei suoi manufatti derivano da questo stesso tessuto vivente.',
};

String oculumPlaneDescription(String id) {
  if (oculumMicroRealmLore[id] case final lore?) return lore;
  return switch (id) {
    'mezzano' =>
      'Regno mezzano: terre e città del mondo ordinario di Oculum, con mercati e creature di diversi habitat.',
    'postea' =>
      'Micro realtà di un futuro errato, fondata sulle rune: innesti riparabili, tecnologia runica e il mercato di Rusty.',
    'caramella' =>
      'Regno Caramella: cioccolato temprato, zucchero cristallino, candy cane e creature dolciarie.',
    'foresta_elementale' =>
      'Foresta elementale: habitat vivi, legno e foglie intrecciati a poteri di tutti gli elementi.',
    'morti' =>
      'Regno dei Morti: ossa, sudari e memorie; necromanzia, richiamo dei defunti e manufatti funerari.',
    'ghiaccio' =>
      'Terre di ghiaccio: gelo, vento e cristalli. Senza abiti pesanti subisci i malus ambientali previsti.',
    'nuvole_rocciose' =>
      'Rocce sospese fra nubi e correnti: Fulmine, Roccia, Nuvola e Vento.',
    'sacro' =>
      'Regno sacro: dominio Solare e Angelico, accesso dal Grado III; oro e ossa marmoree delle aberrazioni.',
    'angelico' =>
      'Regno angelico: manifatture e creature angeliche, piume, tessuti chiari e metallo consacrato.',
    'oblio' =>
      'Oblio: materia senza riflesso, creature contaminate e offerte del Mercante Nero.',
    'shadow_hell' =>
      'Shadow Hell: riflesso diabolico contaminato dall’Oblio, dal Grado IV; vi si incontra lo Shadow Devil.',
    'diabolico' =>
      'Regno diabolico: Fuoco, Lava e potere diabolico, dal Grado III.',
    'vero_inferno' =>
      'Il vero inferno: dominio estremo di Fuoco, Lava e potere diabolico, dal Grado IX.',
    'isole' => 'Isole volanti: correnti, nubi, acqua e ricevitori di fulmini.',
    'affogato' =>
      'Regno affogato: ambiente acquatico in cui si respira normalmente.',
    'sotterraneo' || 'sotterraneo_maggiore' =>
      'Regno sotterraneo: Roccia, Terra e Buio, cunicoli e vene minerali. Sottoterra non compaiono sole, luna o raggi dal cielo.',
    _ =>
      'Una realtà del mondo di Oculum. Ambienti, mercati e creature dipendono dal luogo selezionato.',
  };
}

const oculumRealmMaterials = <OculumAuthoredMaterial>[
  OculumAuthoredMaterial(
    'quarzo_risonante',
    'Quarzo risonante',
    0,
    .25,
    2,
    20,
    'Quarzo chiaro che risuona con gli urti delle caverne. Per lenti, lame e strumenti di orientamento; l’attivazione produce una piccola barriera.',
    passive: '@Danni+2',
    active: '@Scudo+5',
  ),
  OculumAuthoredMaterial(
    'prismarite',
    'Prismarite',
    1,
    .2,
    1.5,
    30,
    'Minerale esclusivo del Reame Cristallo, striato di verde e viola. Le sue facce deviano la luce e sono adatte a corazze e lenti.',
    passive: '@Difesa+2',
    active: '@Scudo+10',
  ),
  OculumAuthoredMaterial(
    'smeraldo_memoria',
    'Smeraldo della memoria',
    2,
    .1,
    .8,
    35,
    'Cristallo esclusivo custodito dai predatori smeraldo. Trattiene e restituisce risonanze: catalizzatori magici e intarsi.',
    passive: '@Oculum+1',
    active: '@Difesa+4',
  ),
  OculumAuthoredMaterial(
    'ossidiana_sussurrante',
    'Ossidiana sussurrante',
    2,
    .2,
    1.2,
    35,
    'Cristallo nero delle figure silenziose del reame. Assorbe i riflessi, utile per lame scure, maschere e segnalatori nascosti.',
    passive: '@Danni+5 Buio',
    active: '@Difesa+3',
  ),
  OculumAuthoredMaterial(
    'ambra_palpitante',
    'Ambra palpitante',
    3,
    .1,
    .6,
    45,
    'Ambra esclusiva delle vene profonde, pulsante come i nuclei dei quadribrachi. Stabilizza armature e oggetti di protezione.',
    passive: '@Resilienza+1',
    active: '@Scudo+18',
  ),
  OculumAuthoredMaterial(
    'cuore_prismatico',
    'Cuore prismatico',
    4,
    .05,
    .4,
    60,
    'Cristallo esclusivo raro che separa e ricompone la luce. Serve a catalizzatori, scudi e lavorazioni magiche di alto Grado.',
    passive: '@Materia+2',
    active: '@Scudo+25',
  ),
  OculumAuthoredMaterial(
    'vetro_azzurro_divoratore',
    'Vetro azzurro del Deserto',
    1,
    .2,
    2,
    30,
    'Vetro azzurro nato dalla sabbia umida e tagliente del Deserto di Vetro. Per lame, scudi e intarsi fragili e affilati.',
    passive: '@Danni+3 Tagliente',
    active: '@Difesa+2',
  ),
];

List<OculumAuthoredMaterial> oculumMineralsInRealm(String realm) => [
  if (realm == 'reame_cristallo')
    ...oculumRealmMaterials.where((m) => m.id != 'vetro_azzurro_divoratore'),
  if (realm == 'deserto_divoratore') oculumRealmMaterials.last,
];

int oculumMineralFindChance(int grade) =>
    (85 / pow(max(0, grade) + 1, 1.4)).floor().clamp(1, 85).toInt();
bool oculumMineralDiscovered({
  required int grade,
  required int natural,
  required int total,
  required int percentile,
}) =>
    natural != 1 &&
    (natural == 20 || total >= 12 + max(0, grade) * 4) &&
    percentile.clamp(0, 99) < oculumMineralFindChance(grade);
String oculumWormholeOutcome(int fortuneDie) => fortuneDie <= 1
    ? 'negativa_eccezionale'
    : fortuneDie >= 20
    ? 'positiva_eccezionale'
    : fortuneDie <= 10
    ? 'negativa'
    : 'positiva';

List<OculumRecipe> oculumRealmCraftingRecipes(String now) => [
  for (final m in oculumRealmMaterials)
    for (final target in ['weapon', 'armor', 'material'])
      OculumRecipe(
        id: 'core_realm_${m.id}_$target',
        name:
            '${target == 'weapon'
                ? 'Lama'
                : target == 'armor'
                ? 'Scudo'
                : 'Catalizzatore'} di ${m.name}',
        ingredients: [OculumRecipeIngredient(name: m.name, grams: '250')],
        resultName:
            '${target == 'weapon'
                ? 'Lama'
                : target == 'armor'
                ? 'Scudo'
                : 'Catalizzatore'} di ${m.name}',
        resultDescription: '${m.effect} ${m.passive} Attivazione: ${m.active}.',
        masterNotes:
            'Ricetta iniziale modificabile. Minerale del luogo, senza sostituzioni con metallo runico di Postea.',
        visibleToPlayers: true,
        createdAt: now,
        updatedAt: now,
        recipeKind: 'forge',
        forgeTarget: target,
        forgeWeightMinKg: '.25',
        forgeWeightMaxKg: '2',
        forgeDuration: '${m.minutes} minuti',
        forgeAttributes: 'Grado ${m.grade}',
        forgeEffectText: '${m.passive} ${m.active}',
        resultGrams: '250',
      ),
];

extension _OculumMicroRealms on _OculumHomePageState {
  Widget realmIndicator() => Tooltip(
    key: const ValueKey('current_realm_indicator'),
    message:
        '${selectedPlane.name}\n${oculumPlaneDescription(selectedPlaneId)}',
    waitDuration: const Duration(milliseconds: 900),
    triggerMode: TooltipTriggerMode.longPress,
    child: IconButton(
      onPressed: selectCurrentPlane,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.public),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    ),
  );

  Map<String, dynamic> get realmExploration =>
      planarState.putIfAbsent('realmExploration', () => <String, dynamic>{})
          as Map<String, dynamic>;

  Future<void> surveyRealm() async {
    final materials = oculumMineralsInRealm(selectedPlaneId);
    if (materials.isEmpty) return;
    final statId = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Cerca giacimenti · prova coerente'),
        children: [
          for (final s in hiddenEyeStats.where(
            (s) => const [
              'percezione',
              'alchimia',
              'sopravvivenza',
            ].contains(s.id),
          ))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, s.id),
              child: Text(
                '${s.nome}: ${s.id == 'alchimia'
                    ? 'riconosci vene e composizione'
                    : s.id == 'sopravvivenza'
                    ? 'segui tracce e affioramenti'
                    : 'osserva l’area'}',
              ),
            ),
        ],
      ),
    );
    if (!mounted || statId == null) return;
    final origin = currentSheetScrollId();
    final realm = selectedPlaneId;
    final stat = hiddenEyeStats.firstWhere((s) => s.id == statId);
    final candidate = materials[Random.secure().nextInt(materials.length)];
    await tiraSottotrattoOcchio(
      stat,
      actionLabel: 'Giacimenti · ${selectedPlane.name}',
      onResolved: (natural, total) {
        if (!mounted ||
            currentSheetScrollId() != origin ||
            selectedPlaneId != realm) {
          return;
        }
        final found = oculumMineralDiscovered(
          grade: candidate.grade,
          natural: natural,
          total: total,
          percentile: Random.secure().nextInt(100),
        );
        if (found) {
          final id = '${DateTime.now().microsecondsSinceEpoch}';
          final grams =
              (candidate.minKg * 1000).round() +
              Random.secure().nextInt(
                max(
                  1,
                  ((candidate.maxKg - candidate.minKg) * 1000).round() + 1,
                ),
              );
          final deposits = Map<String, dynamic>.from(
            realmExploration['deposits'] as Map? ?? {},
          );
          deposits[id] = {
            'id': id,
            'realm': realm,
            'material': candidate.id,
            'remainingGrams': grams,
          };
          realmExploration['deposits'] = deposits;
          aggiungiLog(
            '[GIACIMENTO] ${candidate.name}, Grado ${candidate.grade}: ${grams / 1000} kg individuati. Scegli se estrarre e quanto.',
          );
        } else {
          aggiungiLog(
            '[GIACIMENTO] Nessuna vena individuata con ${stat.nome} $total.',
          );
        }
        programmaSalvataggio();
        // ignore: invalid_use_of_protected_member
        setState(() {});
      },
    );
  }

  bool extractRealmDeposit(String id, int grams) {
    final deposits = realmExploration['deposits'] as Map? ?? {};
    final raw = deposits[id];
    if (raw is! Map ||
        raw['realm'] != selectedPlaneId ||
        grams <= 0 ||
        grams > readIntValue(raw['remainingGrams'])) {
      return false;
    }
    final material = oculumMineralsInRealm(
      selectedPlaneId,
    ).where((m) => m.id == raw['material']).firstOrNull;
    if (material == null || material.grade > leggiNumero(gradoController)) {
      return false;
    }
    raw['remainingGrams'] = readIntValue(raw['remainingGrams']) - grams;
    inventario.add(
      InventoryItem(
        nome: material.name,
        peso: grams / 1000,
        quantita: 1,
        note:
            '${material.effect} Estratto in ${selectedPlane.name}; ${material.minutes} minuti di lavorazione di riferimento per lotto. Quantità e ricette modificabili.',
        gradoOggetto: material.grade,
        gradoRichiesto: material.grade,
        craftData: {
          'material': material.id,
          'materialGrade': material.grade,
          'materialLevel': oculumDefaultMaterialLevels()[material.id] ?? 0,
          'grams': grams,
          'sourceRealm': selectedPlaneId,
          'active': false,
          'activeBuff': material.active,
          'effect': material.effect,
        },
      ),
    );
    aggiungiLog(
      '[ESTRAZIONE] ${material.name}: ${grams / 1000} kg. Restano ${readIntValue(raw['remainingGrams']) / 1000} kg nel giacimento.',
    );
    programmaSalvataggio();
    return true;
  }

  Future<void> showCurrentMicroRealm() async {
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(selectedPlane.name),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(oculumPlaneDescription(selectedPlaneId)),
                  if (selectedPlaneId == 'deserto_divoratore') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Due zone: Deserto Divoratore e Deserto di Vetro. Un critico dell’Artiglio azzurro trasforma il punto colpito in vetro; il teletrasporto rende di vetro anche il portatore.',
                    ),
                    TextButton(
                      onPressed: () {
                        final die = Random.secure().nextInt(20) + 1;
                        final outcome = oculumWormholeOutcome(die);
                        realmExploration['wormhole'] = {
                          'die': die,
                          'outcome': outcome,
                        };
                        aggiungiLog(
                          '[WORMHOLE] Fortuna naturale $die: dimensione segreta $outcome.',
                        );
                        programmaSalvataggio();
                        update(() {});
                      },
                      child: const Text(
                        'Entra nel wormhole · tiro Fortuna 1d20',
                      ),
                    ),
                    if (realmExploration['wormhole'] is Map)
                      Text(
                        'Ultimo passaggio: ${(realmExploration['wormhole'] as Map)['outcome']}',
                      ),
                  ],
                  if (oculumMineralsInRealm(selectedPlaneId).isNotEmpty) ...[
                    TextButton(
                      onPressed: () async {
                        await surveyRealm();
                        if (dialog.mounted) update(() {});
                      },
                      child: const Text(
                        'Percezione o alternativa · cerca giacimenti',
                      ),
                    ),
                    for (final row
                        in (realmExploration['deposits'] as Map? ?? {}).values
                            .whereType<Map>()
                            .where(
                              (r) =>
                                  r['realm'] == selectedPlaneId &&
                                  readIntValue(r['remainingGrams']) > 0,
                            ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          oculumRealmMaterials
                              .firstWhere((m) => m.id == row['material'])
                              .name,
                        ),
                        subtitle: Text(
                          '${readIntValue(row['remainingGrams']) / 1000} kg disponibili · Grado ${oculumRealmMaterials.firstWhere((m) => m.id == row['material']).grade}',
                        ),
                        trailing: TextButton(
                          onPressed:
                              oculumRealmMaterials
                                      .firstWhere(
                                        (m) => m.id == row['material'],
                                      )
                                      .grade >
                                  leggiNumero(gradoController)
                              ? null
                              : () async {
                                  final input = TextEditingController(
                                    text:
                                        '${min(250, readIntValue(row['remainingGrams']))}',
                                  );
                                  final amount = await showDialog<int>(
                                    context: context,
                                    builder: (d) => AlertDialog(
                                      title: const Text(
                                        'Estrai quanto vuoi o lascia perdere',
                                      ),
                                      content: TextField(
                                        controller: input,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Grammi da estrarre',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(d),
                                          child: const Text('Lascia perdere'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(
                                            d,
                                            int.tryParse(input.text),
                                          ),
                                          child: const Text('Estrai'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (dialog.mounted && amount != null) {
                                    extractRealmDeposit('${row['id']}', amount);
                                    update(() {});
                                  }
                                },
                          child: const Text('Estrai'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  void ensureMicroRealmOffers() {
    if (!oculumMicroRealmLore.containsKey(selectedPlaneId)) return;
    for (final material in oculumMineralsInRealm(selectedPlaneId)) {
      final id = 'realm_${selectedPlaneId}_${material.id}';
      if (merchantStock.any((o) => o['id'] == id)) continue;
      merchantStock.add({
        'id': id,
        'planeId': selectedPlaneId,
        'kind': 'gear',
        'name': 'Catalizzatore di ${material.name}',
        'level': max(0, leggiNumero(livelloController)),
        'grade': material.grade,
        'weapon': false,
        'protection': true,
        'defence': 1 + material.grade,
        'shield': 5 + material.grade * 5,
        'cost': 25 + material.grade * 55,
        'desc':
            '${material.effect} Manufatto disponibile soltanto nel luogo d’origine; effetti modificabili.',
      });
    }
  }
}
