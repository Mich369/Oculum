part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

ArtSkill oculumAbilityWithEvolutions(ArtSkill original, int count) {
  final skill = ArtSkill.fromJson(original.toJson());
  if (count <= 3) return skill;
  for (final form in [4, 5]) {
    if (skill.testoEvoluzione(form).trim().isNotEmpty &&
        skill.testoEvoluzione(form) != '???') {
      continue;
    }
    final ratio = form == 4 ? 1.25 : 1.5;
    final source = skill.effettiEvoluzione(3);
    skill.effettiPerLivello[form - 1] = [
      for (final e in source)
        OculumStructuredEffect.fromJson({
          ...e.toJson(),
          'id': '${e.id}_defiled_$form',
          if (const {
            'danno',
            'danno_percentuale',
            'difesa',
            'cura',
            'scudo',
            'hp_temporanei',
          }.contains(e.type))
            'valueExpression': '(${e.valueExpression})*$ratio',
        }),
    ];
    final minCost = (skill.oculumMinimoPerLivello(3) * ratio).ceil();
    final maxCost = (skill.oculumMassimoPerLivello(3) * ratio).ceil();
    skill.impostaRisorsaCostoPerLivello(form, skill.risorsaCostoPerLivello(3));
    skill.impostaLimitiOculumPerLivello(
      form,
      minimo: minCost,
      massimo: maxCost,
    );
    skill.cooldownPerLivello[form - 1] = OculumAbilityCooldown.fromJson(
      skill.cooldownPerLivello[2].toJson(),
    );
    final desc =
        '${form == 4 ? "IV" : "V"}/Richiede livello ${form == 4 ? 15 : 20}. Evoluzione Defiled di ${skill.nome}: stessa tecnica della forma III; danni, cura, Scudo e Difesa sono potenziati del ${form == 4 ? 25 : 50}%. Costo ($minCost/$maxCost ${skill.risorsaCostoPerLivello(3)}).\n${skill.effettiPerLivello[form - 1].map(oculumStructuredEffectDescription).join("\n")}';
    if (form == 4) {
      skill.evo4 = desc;
    } else {
      skill.evo5 = desc;
    }
  }
  return skill;
}

extension _OculumAbilityCatalogue on _OculumHomePageState {
  Future<void> showMonsterBookMechanics(MonsterBookEntry monster) async {
    final art = oculumMonsterBookArt(monster);
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('${monster.nameIt} · abilità ed effetti'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gli effetti qui mostrati sono gli stessi importati nella scheda. Costi, durata e formule vengono letti dal catalogo.',
                ),
                for (final skill in art.skills)
                  ExpansionTile(
                    title: Text(skill.nome),
                    children: [
                      for (var form = 1; form <= 3; form++)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${artLevelRoman(form)} · ${skill.oculumMinimoPerLivello(form)}/${skill.oculumMassimoPerLivello(form)} ${skill.risorsaCostoPerLivello(form)}\n${skill.testoEvoluzione(form)}\n${skill.effettiEvoluzione(form).map(oculumStructuredEffectDescription).join('\n')}\n${skill.effettiEvoluzione(form).isEmpty ? 'Nessun effetto strutturato in questa forma: verifica il pannello dedicato o definisci gli effetti con il Master prima di applicarli.' : ''}',
                          ),
                        ),
                    ],
                  ),
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
    );
  }

  Future<void> showAbilityCatalogue({CharacterArt? destination}) async {
    final originSheet = currentSheetScrollId();
    final entries =
        <({String id, String label, ArtSkill art, CharacterSkill? natural})>[];
    for (final monster in monsterBookEntries) {
      final natural = {
        for (final skill in oculumMonsterBookSkills(monster)) skill.nome: skill,
      };
      for (final (index, skill) in oculumMonsterBookArt(
        monster,
      ).skills.indexed) {
        entries.add((
          id: '${monster.id}:$index',
          label: '${skill.nome} · ${monster.nameIt}',
          art: skill,
          natural: natural[skill.nome],
        ));
      }
    }
    final selected = <String>{};
    var query = '';
    final five =
        destination != null &&
        oculumRecognizedArtKind(destination) == 'defiled';
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          final visible = entries
              .where(
                (e) => oculumNormalizeText(
                  e.label,
                ).contains(oculumNormalizeText(query)),
              )
              .toList();
          return AlertDialog(
            title: Text('Catalogo abilità · ${five ? 5 : 3} evoluzioni'),
            content: SizedBox(
              width: 660,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cerca abilità o creatura',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => refresh(() => query = v),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        final art = oculumAbilityWithEvolutions(
                          entry.art,
                          five ? 5 : 3,
                        );
                        return ExpansionTile(
                          key: ValueKey(entry.id),
                          leading: Checkbox(
                            value: selected.contains(entry.id),
                            onChanged: (v) => refresh(() {
                              if (v == true) {
                                selected.add(entry.id);
                              } else {
                                selected.remove(entry.id);
                              }
                            }),
                          ),
                          title: Text(entry.label),
                          children: [
                            for (var form = 1; form <= (five ? 5 : 3); form++)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${artLevelRoman(form)} · ${entry.natural != null && !five ? entry.natural!.forme[min(form - 1, entry.natural!.forme.length - 1)].costo : "${art.oculumMinimoPerLivello(form)}/${art.oculumMassimoPerLivello(form)} ${art.risorsaCostoPerLivello(form)}"}\n${entry.natural != null && !five ? entry.natural!.forme[min(form - 1, entry.natural!.forme.length - 1)].descrizione : art.testoEvoluzione(form)}\n${(entry.natural != null && !five ? entry.natural!.forme[min(form - 1, entry.natural!.forme.length - 1)].effettiStrutturati : art.effettiEvoluzione(form)).map(oculumStructuredEffectDescription).join('\n')}',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(dialog, true),
                child: Text('Aggiungi ${selected.length} abilità'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted ||
        approved != true ||
        originSheet != currentSheetScrollId() ||
        destination != null && !arti.contains(destination)) {
      return;
    }
    setState(() {
      for (final entry in entries.where((e) => selected.contains(e.id))) {
        if (destination != null) {
          if (!destination.skills.any((s) => s.nome == entry.art.nome)) {
            destination.skills.add(
              oculumAbilityWithEvolutions(entry.art, five ? 5 : 3),
            );
          }
        } else {
          final skill = entry.natural != null
              ? CharacterSkill.fromJson(entry.natural!.toJson())
              : oculumEquipmentAbilityFromArt(
                  oculumAbilityWithEvolutions(entry.art, 3),
                );
          skill.tipo =
              entry.art.tipoPerLivello(1).toLowerCase().contains('passiv')
              ? 'Passiva del catalogo'
              : 'Skill del catalogo';
          if (!skills.any((s) => s.nome == skill.nome)) skills.add(skill);
        }
      }
      aggiungiLog(
        'Catalogo abilità: selezionate ${selected.length} tecniche${destination == null ? "" : " per ${destination.nome}"}.',
      );
      invalidateDerivedDataCaches();
    });
    programmaSalvataggio();
  }
}

/// Selected once at spawn. The resulting Skills, not the seed alone, are saved.
List<CharacterSkill> oculumEnemyAbilityVariants(
  MonsterBookEntry monster, {
  required int seed,
}) {
  if (monster.isNpc || monster.id.startsWith('pawn_guardiano')) {
    return [];
  }
  final body = oculumNormalizeText(
    '${monster.nameIt} ${monster.descIt} ${monster.formTags.join(" ")}',
  );
  final element = oculumNormalizeElementId(monster.elementId);
  final pool =
      <
        ({
          String name,
          String text,
          int cd,
          List<OculumStructuredEffect> effects,
          bool magic,
          bool multiTarget,
          List<int> targetCounts,
          List<double> damageRatios,
        })
      >[];
  OculumStructuredEffect effect(
    String type,
    String value, {
    String target = '',
    String mode = 'prossima_azione',
    String duration = '',
    int minimumTargets = 0,
    int maximumTargets = 0,
    String recipient = 'se_stesso',
  }) => OculumStructuredEffect(
    type: type,
    target: target,
    valueExpression: value,
    mode: mode,
    duration: duration,
    minimumTargets: minimumTargets,
    maximumTargets: maximumTargets,
    recipient: recipient,
    elementType: element,
  );
  void add(
    String name,
    String text,
    int cd,
    List<OculumStructuredEffect> effects, {
    bool magic = false,
    bool multiTarget = false,
    List<int> targetCounts = const [1, 1, 1],
    List<double> damageRatios = const [],
  }) {
    pool.add((
      name: name,
      text: text,
      cd: cd,
      effects: effects,
      magic: magic,
      multiTarget: multiTarget,
      targetCounts: targetCounts,
      damageRatios: damageRatios,
    ));
  }

  final winged = RegExp(
    r'\b(?:ala|ali|alat[oaie]|vola\w*|planare|planata)\b|pium|pipistrell|arpia',
  ).hasMatch(body);
  if (winged) {
    add(
      'Picchiata a spirale',
      'Ripieghi le ali e riprendi quota: +3 Precisione e +6 Movimento per la prossima azione.',
      4,
      [
        effect('modifica_sottotratto', '3', target: 'Precisione'),
        effect('velocita', '6'),
      ],
    );
    add(
      'Colpo d’aria delle ali',
      'Allarghi le ali di scatto: +1 Reazione per questo turno, ma -2 Difesa per un turno.',
      4,
      [
        effect('aggiungi_reazioni', '1', mode: 'finche_attivo', duration: '1'),
        effect('difesa', '-2', mode: 'finche_attivo', duration: '1'),
      ],
    );
  }
  if (RegExp('corn[oa]|palc[ho]|ariet|forest demon').hasMatch(body)) {
    add(
      'Incornata a testa bassa',
      'Affondi il corno nella carica: +30% Danni al prossimo attacco e -2 CM per un turno.',
      4,
      [
        effect('danno_percentuale', '30'),
        effect(
          'modifica_statistica',
          '-2',
          target: 'CM',
          mode: 'finche_attivo',
          duration: '1',
        ),
      ],
    );
    add(
      'Leva del palco',
      'Usi il peso del palco per mantenere la guardia: +4 Difesa per un turno e +2 Schianto alla prossima azione.',
      3,
      [
        effect('difesa', '4', mode: 'finche_attivo', duration: '1'),
        effect('modifica_sottotratto', '2', target: 'Schianto'),
      ],
    );
  }
  if (RegExp('artig|zann|mors|lupo|felin|predator').hasMatch(body)) {
    add(
      'Passo prima del morso',
      'Ti comprimi sulle zampe e scatti: +2 VC e +4 Danni al prossimo attacco.',
      3,
      [effect('modifica_statistica', '2', target: 'VC'), effect('danno', '4')],
    );
    add(
      'Finta dell’artiglio',
      'Mostri un artiglio e cambi appoggio: +3 Riflessi e +3 Precisione alla prossima azione.',
      3,
      [
        effect('modifica_sottotratto', '3', target: 'Riflessi'),
        effect('modifica_sottotratto', '3', target: 'Precisione'),
      ],
    );
  }
  if (RegExp('slime|gelatin|viscid|melma').hasMatch(body)) {
    add(
      'Membrana raccolta',
      'Contrai la membrana e raccogli la massa: ottieni 6 Scudo, che resta fino a consumarsi.',
      4,
      [effect('scudo', '6', mode: 'immediato')],
    );
    add(
      'Rimbalzo obliquo',
      'Deformi il corpo contro il terreno: +6 Movimento e +20% Danni per la prossima azione.',
      4,
      [effect('velocita', '6'), effect('danno_percentuale', '20')],
    );
  }
  if (RegExp(
    'carapace|corazz|scagli|basalt|rocc|golem|placch',
  ).hasMatch(body)) {
    add(
      'Sovrapporre le placche',
      'Ruoti il lato più spesso verso l’avversario: +5 Difesa per due turni e -3 Movimento per gli stessi due turni.',
      4,
      [
        effect('difesa', '5', mode: 'finche_attivo', duration: '2'),
        effect('velocita', '-3', mode: 'finche_attivo', duration: '2'),
      ],
    );
    add(
      'Impatto di spigolo',
      'Colpisci con il bordo duro del corpo: +6 Danni e +2 Schianto alla prossima azione.',
      3,
      [
        effect('danno', '6'),
        effect('modifica_sottotratto', '2', target: 'Schianto'),
      ],
    );
  }
  if (RegExp('scheletr|oss[ao]|non morto|cadaver').hasMatch(body)) {
    add(
      'Incastro delle ossa',
      'Blocchi le articolazioni in una posizione impossibile: +4 Difesa per un turno.',
      3,
      [effect('difesa', '4', mode: 'finche_attivo', duration: '1')],
    );
    add(
      'Scatto disarticolato',
      'Lasci cedere un’articolazione e ruoti di lato: +4 Riflessi alla prossima azione.',
      3,
      [effect('modifica_sottotratto', '4', target: 'Riflessi')],
    );
  }
  if (monster.canWieldWeapons ||
      RegExp('astut|agguat|assassin|cacci|intelligen').hasMatch(body)) {
    add(
      'Guardia che invita',
      'Offri una falsa apertura: +3 VC al prossimo attacco e +2 Difesa per un turno.',
      4,
      [
        effect('modifica_statistica', '3', target: 'VC'),
        effect('difesa', '2', mode: 'finche_attivo', duration: '1'),
      ],
    );
    add(
      'Passo oltre la linea',
      'Cambi lato tenendo il bersaglio davanti: +4 Movimento e +2 CM alla prossima azione.',
      3,
      [
        effect('velocita', '4'),
        effect('modifica_statistica', '2', target: 'CM'),
      ],
    );
  }
  if ((monster.stats['oculum'] ?? 0) > 0 &&
      element != 'fisico' &&
      element.isNotEmpty) {
    final shape = switch (element) {
      'fuoco' || 'lava' || 'magma' => 'Soffio della fornace',
      'gelo' || 'ghiaccio' => 'Scheggia trattenuta',
      'acido' => 'Goccia sotto pressione',
      'spirituale' || 'spiritualita' => 'Eco delle anime',
      'caos' || 'chaos' => 'Fenditura fuori asse',
      'sogno' || 'sogni' => 'Piega del sogno',
      _ => 'Nucleo di ${monster.elementId}',
    };
    add(
      shape,
      'Concentri $element nel prossimo attacco: +2 + Oculum immesso ×2 Danni. Il costo è realmente variabile da 1 a 3 Oculum.',
      4,
      [effect('danno', '2+oculum_spent*2')],
      magic: true,
    );
  }
  if ((monster.stats['oculum'] ?? 0) > 0 &&
      const {'luce', 'solare', 'angelico'}.contains(element)) {
    add(
      'Raggio di luce',
      'Concentri un fascio luminoso su un solo nemico: +4 + Oculum speso ×2 Danni al prossimo attacco. Il bersaglio può difendersi.',
      4,
      [effect('danno', '4+oculum_spent*2')],
      magic: true,
    );
    add(
      'Lame dell’aurora',
      'Due lame di luce convergono: +6 + Oculum speso Danni totali al prossimo attacco, senza duplicare il colpo.',
      4,
      [effect('danno', '6+oculum_spent')],
      magic: true,
    );
  }
  if ((monster.stats['oculum'] ?? 0) > 0 &&
      (monster.planeIds.contains('morti') ||
          RegExp('necromant|non morto|scheletr|cadaver').hasMatch(body))) {
    add(
      'Raggio necromantico',
      'Un filo di energia funebre colpisce un nemico: +3 + Oculum speso ×2 Danni al prossimo attacco; applica Vita Afona per un turno se il colpo supera la difesa.',
      5,
      [
        effect('danno', '3+oculum_spent*2'),
        OculumStructuredEffect(
          type: 'stato',
          target: 'vita_afona',
          appliedState: 'vita_afona',
          valueExpression: '1',
          recipient: 'nemico',
          duration: '1',
          elementType: element,
        ),
      ],
      magic: true,
    );
    add(
      'Mano del sepolcro',
      'Una mano d’ossa trattiene un nemico: Immobilizzato per un turno dopo una difesa fallita; nessun danno automatico.',
      5,
      [
        OculumStructuredEffect(
          type: 'stato',
          target: 'immobilizzato',
          appliedState: 'immobilizzato',
          valueExpression: '1',
          recipient: 'nemico',
          duration: '1',
          elementType: element,
        ),
      ],
      magic: true,
    );
  }
  if ((monster.stats['oculum'] ?? 0) > 0 &&
      const {'ghiaccio', 'gelo'}.contains(element)) {
    add(
      'Presa di ghiaccio',
      'Ghiaccio stringe le gambe di un nemico: Immobilizzato per un turno dopo una difesa fallita. Non toglie automaticamente tutte le reazioni.',
      4,
      [
        OculumStructuredEffect(
          type: 'stato',
          target: 'immobilizzato',
          appliedState: 'immobilizzato',
          valueExpression: '1',
          recipient: 'nemico',
          duration: '1',
          elementType: 'ghiaccio',
        ),
      ],
      magic: true,
    );
    add(
      'Raggio di brina',
      'Un getto sottile congela la superficie colpita: +4 + Oculum speso ×2 Danni al prossimo attacco.',
      4,
      [effect('danno', '4+oculum_spent*2')],
      magic: true,
    );
  }
  // Every non-NPC monster can roll one area technique at spawn. The packet is
  final piercingNames = switch (element) {
    'solare' => [
      'Ago della corona',
      'Lama del meriggio',
      'Raggio fra le crepe',
    ],
    'luce' ||
    'angelico' => ['Filo di luce', 'Sigillo penetrante', 'Lancia del giudizio'],
    'acqua' || 'ghiaccio' => [
      'Getto fra le giunture',
      'Ago di pressione',
      'Lama cristallina',
    ],
    'fuoco' || 'lava' => [
      'Fusione della guardia',
      'Dardo incandescente',
      'Taglio di brace',
    ],
    'buio' ||
    'spirituale' => ['Ferita incorporea', 'Filo d’ombra', 'Stoccata spettrale'],
    _ => [
      'Impatto di rottura',
      'Affondo nella guardia',
      'Pressione concentrata',
    ],
  };
  for (var variant = 0; variant < piercingNames.length; variant++) {
    add(
      piercingNames[variant],
      'Colpo preciso a un bersaglio: +${2 + variant} Danni, Oltre Difesa solo su questo colpo. Ricarica obbligatoria; non modifica la Difesa permanente della vittima.',
      2 + variant,
      [
        OculumStructuredEffect(
          type: 'danno',
          valueExpression: '${2 + variant}',
          recipient: 'nemico',
          mode: 'prossima_azione',
          bypassDefense: true,
          elementType: element,
        ),
      ],
      magic: element != 'fisico' && element.isNotEmpty,
    );
  }
  for (var variant = 0; variant < 3; variant++) {
    add(
      '${const ['Incrinare', 'Erodere', 'Spezzare'][variant]} la barriera',
      'Concentri $element contro un bersaglio: +2 Danni e +${20 + variant * 10}% danni ai suoi Scudi, solo per questo colpo.',
      3 + variant,
      [
        OculumStructuredEffect(
          type: 'danno',
          valueExpression: '2',
          recipient: 'nemico',
          mode: 'prossima_azione',
          shieldDamageBonusPercent: 20 + variant * 10,
          elementType: element,
        ),
      ],
      magic: element != 'fisico' && element.isNotEmpty,
    );
  }
  add(
    'Varco nella barriera',
    'Attraversi la barriera con un colpo controllato: +2 Danni, Oltre Scudi solo per questo attacco. La Difesa resta valida.',
    5,
    [
      OculumStructuredEffect(
        type: 'danno',
        valueExpression: '2',
        recipient: 'nemico',
        mode: 'prossima_azione',
        bypassShields: true,
        elementType: element,
      ),
    ],
    magic: element != 'fisico' && element.isNotEmpty,
  );
  // computed once from this creature, then split across the chosen hits. This
  // leaves one other random slot for a body/element-specific move.
  final areaResource = (monster.stats['volonta'] ?? 0) > 0
      ? 'volonta'
      : (monster.stats['materia'] ?? 0) > 0
      ? 'materia'
      : (monster.stats['oculum'] ?? 0) > 0
      ? 'oculum'
      : 'nessuna';
  final areaElement = element.isEmpty ? 'fisico' : element;
  add(
    'Spazzata a raggiera',
    'Colpisci in un arco largo fino a quattro bersagli. Il danno totale della mossa è diviso fra i colpi scelti, arrotondando per eccesso per ogni bersaglio; ogni bersaglio tira la propria difesa. Costo e ricarica si pagano una volta.',
    4,
    [
      effect(
        'danno',
        'danni*0.75',
        minimumTargets: 2,
        maximumTargets: 2,
        recipient: 'nemico',
      ),
    ],
    multiTarget: true,
    targetCounts: const [2, 3, 4],
    damageRatios: const [.75, 1, 1.25],
  );
  add(
    'Eco a catena',
    'Rilasci un impulso che salta fra fino a cinque bersagli. Il danno totale della mossa è diviso fra i colpi scelti, arrotondando per eccesso per ogni bersaglio; ciascuno tira la propria difesa. Costo e ricarica si pagano una volta.',
    5,
    [
      effect(
        'danno',
        'danni*0.6',
        minimumTargets: 3,
        maximumTargets: 3,
        recipient: 'nemico',
      ),
    ],
    magic: areaResource == 'oculum',
    multiTarget: true,
    targetCounts: const [3, 4, 5],
    damageRatios: const [.6, .8, 1],
  );
  // Ensure even bodies without a matching motif receive a single-target move.
  if (!pool.any((move) => !move.multiTarget)) {
    add(
      'Impatto diretto',
      'Concentri il peso in un solo colpo: +5 Danni al prossimo attacco contro un bersaglio.',
      3,
      [effect('danno', '5')],
    );
  }
  // Fallbacks describe universally available postures, not absent limbs.
  if (pool.length < 2) {
    add(
      'Raccogliere la presenza',
      'Riduci l’esposizione prima dello scatto: +3 Difesa per un turno.',
      3,
      [effect('difesa', '3', mode: 'finche_attivo', duration: '1')],
    );
    add(
      'Slancio interrotto',
      'Interrompi lo slancio prima dell’impatto e lo riprendi: +20% Danni alla prossima azione.',
      3,
      [effect('danno_percentuale', '20')],
    );
  }
  final random = Random(seed);
  pool.shuffle(random);
  final areaMoves = pool.where((move) => move.multiTarget).toList();
  final singleMoves = pool.where((move) => !move.multiTarget).toList();
  final chosenMoves =
      <
        ({
          String name,
          String text,
          int cd,
          List<OculumStructuredEffect> effects,
          bool magic,
          bool multiTarget,
          List<int> targetCounts,
          List<double> damageRatios,
        })
      >[];
  if (areaMoves.isNotEmpty) {
    chosenMoves.add(areaMoves[random.nextInt(areaMoves.length)]);
  }
  chosenMoves.addAll(singleMoves.take(2 - chosenMoves.length));
  if (chosenMoves.length < 2) {
    chosenMoves.addAll(
      areaMoves
          .where((move) => !chosenMoves.contains(move))
          .take(2 - chosenMoves.length),
    );
  }
  final result = <CharacterSkill>[];
  for (final move in chosenMoves) {
    final resource = move.magic
        ? 'oculum'
        : (monster.stats['volonta'] ?? 0) > 0
        ? 'volonta'
        : (monster.stats['materia'] ?? 0) > 0
        ? 'materia'
        : 'nessuna';
    final cost = OculumSkillCost(
      resource: resource,
      amountExpression: resource == 'nessuna' ? '0' : '1',
      variable: move.magic,
      minimum: move.magic ? 1 : 0,
      maximum: move.magic ? 3 : 0,
    );
    final text =
        '${move.text}\nVariante individuale di ${monster.nameIt}; scelta alla creazione e conservata nella scheda.';
    final targetMaximum = move.targetCounts.first;
    final firstEffects = [
      for (final (effectIndex, sourceEffect) in move.effects.indexed)
        oculumStatPaidEffect(
          OculumStructuredEffect.fromJson({
            ...sourceEffect.toJson(),
            'id': 'enemy_${monster.id}_${seed}_${move.name}_${effectIndex}_0',
            if (move.multiTarget) 'minimumTargets': targetMaximum,
            if (move.multiTarget) 'maximumTargets': targetMaximum,
            if (move.multiTarget) 'elementType': areaElement,
          }),
          resource,
        ),
    ];
    result.add(
      CharacterSkill(
        nome: '${move.name} — ${monster.nameIt}',
        tipo: 'Tecnica individuale mostro',
        costo: move.magic
            ? '1/3 Oculum'
            : resource == 'nessuna'
            ? 'Nessun costo'
            : '1/1 $resource',
        cooldown: '${move.cd} turni',
        descrizione: text,
        forme: [
          CharacterSkillForm(
            nome: 'I',
            tipo: 'Tecnica individuale mostro',
            costo: move.magic
                ? '1/3 Oculum'
                : resource == 'nessuna'
                ? 'Nessun costo'
                : '1/1 $resource',
            descrizione: move.multiTarget
                ? '${move.name} I: colpisce $targetMaximum volte. Scegli fino a $targetMaximum bersagli, anche ripetendo lo stesso; i colpi mancanti si assegnano a caso fra quelli scelti. Danno totale ${move.damageRatios.first * 100}% dei Danni, diviso fra i colpi e arrotondato per eccesso per bersaglio; ciascuno tira la propria difesa. Costo ${resource == 'nessuna' ? 'gratuito' : '1 $resource'}, ricarica ${move.cd} turni.\n$text'
                : text,
            costoStrutturato: cost,
            cooldownStrutturato: OculumAbilityCooldown(
              amount: move.cd,
              startsReady:
                  move.cd != 2 ||
                  !move.effects.any((effect) => effect.bypassDefense),
            ),
            effettiStrutturati: firstEffects,
            oculumLimitiConfiguratiManualmente: true,
          ),
        ],
      ),
    );
    final created = result.last;
    final first = created.forme.first;
    for (var form = 1; form < 3; form++) {
      final ratio = 1 + form * .25;
      final stageDamageRatio = move.multiTarget
          ? move.damageRatios[form]
          : ratio;
      final evolved = [
        for (final e in first.effettiStrutturati)
          OculumStructuredEffect.fromJson({
            ...e.toJson(),
            'id': '${monster.id}_${seed}_${move.name}_${e.id}_$form',
            if (move.multiTarget) 'minimumTargets': move.targetCounts[form],
            if (move.multiTarget) 'maximumTargets': move.targetCounts[form],
            if (const {
              'danno',
              'danno_percentuale',
              'difesa',
              'velocita',
              'scudo',
              'modifica_sottotratto',
              'modifica_statistica',
            }.contains(e.type))
              'valueExpression': move.multiTarget
                  ? 'danni*$stageDamageRatio'
                  : '(${e.valueExpression})*$ratio',
          }),
      ];
      final minCost = move.magic
          ? const [1, 4, 7][form]
          : resource == 'nessuna'
          ? 0
          : form + 1;
      final maxCost = move.magic ? const [3, 6, 10][form] : minCost;
      final costText = resource == 'nessuna'
          ? 'Nessun costo'
          : 'Costo $minCost/$maxCost $resource';
      final targetText = move.multiTarget
          ? 'Colpisce ${move.targetCounts[form]} volte; scegli fino a quel numero di bersagli. Puoi ripetere lo stesso bersaglio; i colpi mancanti si assegnano a caso fra quelli scelti. Il danno totale è diviso fra i colpi e arrotondato per eccesso per bersaglio; ognuno tira la propria difesa.'
          : '';
      created.forme.add(
        CharacterSkillForm(
          nome: const ['I', 'II', 'III'][form],
          tipo: created.tipo,
          livello: '${form * 5}',
          costo: resource == 'nessuna'
              ? 'Nessun costo'
              : '$minCost/$maxCost $resource',
          descrizione:
              "${move.name} ${form + 1}: ${evolved.map(oculumStructuredEffectDescription).join('; ')}.$targetText $costText. Ricarica ${move.cd + (move.multiTarget ? form : 0)} turni.",
          costoStrutturato: OculumSkillCost(
            resource: resource,
            amountExpression: '$minCost',
            variable: move.magic,
            minimum: minCost,
            maximum: maxCost,
          ),
          cooldownStrutturato: OculumAbilityCooldown(
            amount: move.cd + (move.multiTarget ? form : 0),
            startsReady:
                move.cd != 2 ||
                !move.effects.any((effect) => effect.bypassDefense),
          ),
          effettiStrutturati: evolved,
          oculumLimitiConfiguratiManualmente: true,
        ),
      );
    }
  }
  final alert = RegExp('vigila|occhi|occhio|osserv|sentinell').hasMatch(body);
  final target = alert
      ? 'Percezione'
      : winged
      ? 'Riflessi'
      : 'Tenacia';
  final passiveName = alert
      ? 'Veglia che non cede'
      : target == 'Riflessi'
      ? 'Equilibrio d’aria'
      : 'Istinto di permanenza';
  result.add(
    CharacterSkill(
      nome: '$passiveName — ${monster.nameIt}',
      tipo: 'Passiva individuale mostro',
      costo: 'Nessun costo',
      cooldown: '',
      descrizione:
          'Passiva: +1 $target, automatica mentre la creatura è presente.',
      forme: [
        CharacterSkillForm(
          nome: 'I',
          tipo: 'Passiva individuale mostro',
          descrizione: 'Passiva: +1 $target.',
          costoStrutturato: OculumSkillCost(resource: 'nessuna'),
          effettiStrutturati: [
            OculumStructuredEffect(
              id: 'enemy_${monster.id}_${seed}_passive_0',
              type: 'modifica_sottotratto',
              target: target,
              valueExpression: '1',
              mode: 'finche_attivo',
              duration: '-1',
            ),
          ],
        ),
      ],
    ),
  );
  for (var form = 1; form < 3; form++) {
    result.last.forme.add(
      CharacterSkillForm(
        nome: const ['I', 'II', 'III'][form],
        tipo: 'Passiva individuale mostro',
        livello: '${form * 5}',
        descrizione: 'Passiva: +${form + 1} $target.',
        costoStrutturato: OculumSkillCost(resource: 'nessuna'),
        effettiStrutturati: [
          OculumStructuredEffect(
            id: 'enemy_${monster.id}_${seed}_passive_$form',
            type: 'modifica_sottotratto',
            target: target,
            valueExpression: '${form + 1}',
            mode: 'finche_attivo',
            duration: '-1',
          ),
        ],
      ),
    );
  }
  if (monster.id.startsWith('aberrazione_oro_marmo_')) {
    final targets = monster.formTags.contains('Minore')
        ? 2
        : monster.formTags.contains('Intermedia')
        ? 3
        : 6;
    final bonus = targets == 2
        ? 10
        : targets == 3
        ? 25
        : 80;
    result.add(
      CharacterSkill(
        nome: element == 'solare'
            ? 'Raggi del sole infranto'
            : 'Raggi del marmo luminoso',
        tipo: 'Tecnica radiante multipla',
        costo: '1/1 Oculum',
        cooldown: '3 turni',
        descrizione:
            'Raggi di ${element == 'solare' ? 'Sole' : 'Luce'} contro $targets bersagli; forme e parametri modificabili.',
        equipaggiata: true,
        forme: [
          for (var form = 0; form < 3; form++)
            CharacterSkillForm(
              nome: const ['I', 'II', 'III'][form],
              livello: '${form * 5}',
              costoStrutturato: OculumSkillCost(
                resource: 'oculum',
                amountExpression: '${form + 1}',
              ),
              cooldownStrutturato: OculumAbilityCooldown(amount: 3 + form),
              descrizione:
                  '$targets raggi di ${element == 'solare' ? 'Sole' : 'Luce'} su $targets bersagli: danno base diviso per eccesso, +${(bonus * (form + 1) / 3).ceil()} Danni a ciascuno. Difesa separata per colpo. Ricarica ${3 + form} turni.',
              effettiStrutturati: [
                OculumStructuredEffect(
                  id: 'aberration_${monster.id}_rays_$form',
                  type: 'danno',
                  recipient: 'nemico',
                  mode: 'prossima_azione',
                  valueExpression: 'danni*0+${(bonus * (form + 1) / 3).ceil()}',
                  minimumTargets: targets,
                  maximumTargets: targets,
                  elementType: element,
                ),
              ],
            ),
        ],
      ),
    );
  }
  return result;
}
