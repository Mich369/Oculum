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

typedef OculumCatalogueEntry = ({
  String id,
  String label,
  ArtSkill art,
  CharacterSkill? natural,
});

int oculumCatalogueRequiredLevel(OculumCatalogueEntry entry, [int form = 1]) {
  if (entry.natural != null && entry.natural!.forme.length >= form) {
    return int.tryParse(entry.natural!.forme[form - 1].livello) ?? 0;
  }
  final text = entry.art.testoEvoluzione(form);
  return int.tryParse(
        RegExp(
              r'(?:richiede|richiesto|requires?)\s+(?:livello|level|lvl)\s*(\d+)',
              caseSensitive: false,
            ).firstMatch(text)?[1] ??
            '',
      ) ??
      (form - 1) * 3;
}

String oculumCatalogueElement(OculumCatalogueEntry entry) {
  final monster = monsterBookEntryById(entry.id.split(':').first);
  if (monster != null) return oculumNormalizeElementId(monster.elementId);
  return entry.art
      .effettiEvoluzione(1)
      .map((e) => oculumNormalizeElementId(e.elementType))
      .firstWhere((e) => e.isNotEmpty, orElse: () => 'oculum');
}

String oculumCatalogueProgressLabel(
  OculumCatalogueEntry entry,
  int characterLevel,
) {
  var usable = 0;
  for (var form = 1; form <= 3; form++) {
    if (oculumCatalogueRequiredLevel(entry, form) <= characterLevel) {
      usable = form;
    }
  }
  final next = min(3, usable + 1);
  return usable == 0
      ? 'Livello richiesto ${oculumCatalogueRequiredLevel(entry)}'
      : '${const ['I', 'II', 'III'][usable - 1]}${usable < 3 ? ' · prossima ${const ['I', 'II', 'III'][next - 1]}, lvl ${oculumCatalogueRequiredLevel(entry, next)}' : ''}';
}

List<OculumCatalogueEntry> oculumAbilityCatalogueEntries({
  List<CharacterArt> arts = const [],
  String? elementFilter,
}) {
  final entries =
      <({String id, String label, ArtSkill art, CharacterSkill? natural})>[];
  if (elementFilter == null || elementFilter == 'oculum') {
    for (final will in [false, true]) {
      entries.add((
        id: will ? 'total_power_will' : 'total_power_oculum',
        label: '${will ? 'Impeto totale' : 'Scarica totale'} · Attacco',
        art: oculumTotalPowerBurstSkill(will: will),
        natural: null,
      ));
    }
    entries.add((
      id: 'provoker_shield',
      label: 'Scudo del provocatore · Difesa',
      art: oculumProvokerShieldSkill(),
      natural: null,
    ));
  }
  for (final monster in monsterBookEntries) {
    if (elementFilter != null &&
        oculumNormalizeElementId(monster.elementId) != elementFilter) {
      continue;
    }
    final natural = {
      for (final skill in oculumMonsterBookSkills(monster)) skill.nome: skill,
    };
    for (final (index, skill) in oculumMonsterBookArt(monster).skills.indexed) {
      entries.add((
        id: '${monster.id}:$index',
        label: '${skill.nome} · ${monster.nameIt}',
        art: skill,
        natural: natural[skill.nome],
      ));
    }
  }
  // Include Art techniques alongside creature skills. Saved definitions are
  // read only; catalogue selections clone them before importing.
  final known = <String>{};
  for (final art in [...oculumStarterArtChoices(), ...arts]) {
    for (final (index, skill) in art.skills.indexed) {
      if (skill.nome.trim().isEmpty ||
          skill.testoEvoluzione(1).trim().isEmpty ||
          skill.testoEvoluzione(1).trim() == '???') {
        continue;
      }
      final signature = jsonEncode([
        skill.nome,
        for (var form = 1; form <= 3; form++)
          [
            skill.testoEvoluzione(form),
            skill.risorsaCostoPerLivello(form),
            skill.oculumMinimoPerLivello(form),
            skill.oculumMassimoPerLivello(form),
            skill.cooldownPerLivello[form - 1].amount,
            skill.effettiEvoluzione(form).map((e) => e.toJson()).toList(),
          ],
      ]);
      if (!known.add(signature)) continue;
      entries.add((
        id: 'catalogue_art:${entries.length}:$index',
        label: '${skill.nome} · ${art.nome} · Art',
        art: skill,
        natural: null,
      ));
    }
  }

  entries.sort((a, b) {
    final level = oculumCatalogueRequiredLevel(
      a,
    ).compareTo(oculumCatalogueRequiredLevel(b));
    return level != 0 ? level : a.label.compareTo(b.label);
  });
  return entries;
}

extension _OculumAbilityCatalogue on _OculumHomePageState {
  List<Color> abilityCostColors(String cost) {
    final text = oculumNormalizeText(cost);
    final colors = <Color>[];
    if (text.contains('oculum') || text.contains('@ocu')) {
      colors.add(const Color(0xFFB68CFF));
    }
    if (text.contains('vol')) colors.add(statFormulaColor('volonta'));
    if (RegExp(r'(^|[^a-z])mat(eria)?([^a-z]|$)').hasMatch(text)) {
      colors.add(statFormulaColor('materia'));
    }
    if (text.contains('res') || text.contains('vita') || text.contains('hp')) {
      colors.add(statFormulaColor('resilienza'));
    }
    if (text.contains('fortuna') || text.contains('@fort')) {
      colors.add(const Color(0xFFD4AF37));
    }
    if (text.contains('obser')) {
      colors.addAll(const [Color(0xFFADB1BA), Color(0xFF8B76B4)]);
    }
    if (text.contains('material') ||
        text.contains('@item') ||
        text.contains('oggett')) {
      colors.add(const Color(0xFF48484B));
    }
    return colors.isEmpty ? [primaryColor] : colors;
  }

  Color abilityBenefitColor(
    Iterable<OculumStructuredEffect> effects, {
    String fallback = '',
  }) {
    final targets = effects
        .where(
          (e) =>
              e.type == 'modifica_statistica' ||
              e.type == 'modifica_sottotratto',
        )
        .map((e) => oculumNormalizeText(e.target))
        .toList();
    if (targets.isEmpty && fallback.isNotEmpty) {
      targets.add(oculumNormalizeText(fallback));
    }
    if (fallback.isNotEmpty) {
      for (final match in RegExp(
        r'@([a-z_]+)\s*\+',
      ).allMatches(oculumNormalizeText(fallback))) {
        final key = match.group(1)!;
        targets.add(
          const {
                'res': 'resilienza',
                'vol': 'volonta',
                'mat': 'materia',
                'ocu': 'oculum',
              }[key] ??
              key,
        );
      }
    }
    for (final target in targets) {
      for (final stat in hiddenEyeStats) {
        if (target == oculumNormalizeText(stat.id) ||
            target == oculumNormalizeText(stat.nome)) {
          return hiddenEyeStatIdentityColor(stat);
        }
      }
      for (final key in const ['resilienza', 'volonta', 'materia', 'oculum']) {
        if (target == key) return statFormulaColor(key);
      }
    }
    return primaryColor;
  }

  Widget abilityColorFrame({
    required String cost,
    required Iterable<OculumStructuredEffect> effects,
    required Widget child,
    String benefitText = '',
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
  }) {
    final colors = abilityCostColors(cost);
    final benefit = abilityBenefitColor(effects, fallback: benefitText);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [...colors, Color.lerp(colors.last, benefit, 0.38)!],
        ),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: const Color(0xFF14110F),
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(
                colors.first.withValues(alpha: .07),
                const Color(0xFF14110F),
              ),
              Color.alphaBlend(
                benefit.withValues(alpha: .035),
                const Color(0xFF14110F),
              ),
            ],
          ),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  Future<void> showMonsterBookMechanics(MonsterBookEntry monster) async {
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('${monster.nameIt} · abilità ed effetti'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(child: monsterReadingDossier(monster)),
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

  Future<void> showAbilityCatalogue({
    CharacterArt? destination,
    List<OculumCatalogueEntry>? choices,
    void Function(CharacterSkill)? onPicked,
    OculumCombatAbilityRole? initialRole,
    String initialElement = '',
    int? catalogueLevel,
    Set<String> excludedNames = const {},
  }) async {
    final originSheet = currentSheetScrollId();
    catalogueLevel ??= leggiNumero(livelloController);
    final entries = choices ?? oculumAbilityCatalogueEntries(arts: arti);
    final selected = <String>{};
    var query = '';
    var role = initialRole;
    var element = initialElement;
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
              .where(
                (e) => !excludedNames.contains(oculumNormalizeText(e.art.nome)),
              )
              .where(
                (e) => element.isEmpty || oculumCatalogueElement(e) == element,
              )
              .where(
                (e) =>
                    role == null ||
                    oculumCombatAbilityRoles(
                      e.art.effettiEvoluzione(1),
                      explicitType: e.art.tipoPerLivello(1),
                    ).contains(role),
              )
              .toList();
          return AlertDialog(
            title: Text('Catalogo abilità · ${five ? 5 : 3} evoluzioni'),
            content: SizedBox(
              width: 1000,
              height: min(620.0, MediaQuery.sizeOf(dialog).height * .72),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cerca abilità, creatura o Art',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => refresh(() => query = v),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      DropdownButton<OculumCombatAbilityRole>(
                        hint: const Text('Tutti i ruoli'),
                        value: role,
                        items: [
                          for (final r in OculumCombatAbilityRole.values)
                            DropdownMenuItem(
                              value: r,
                              child: Text(
                                r == OculumCombatAbilityRole.attack
                                    ? 'Attacco'
                                    : r == OculumCombatAbilityRole.defense
                                    ? 'Difesa'
                                    : 'Supporto',
                              ),
                            ),
                        ],
                        onChanged: (v) => refresh(() => role = v),
                      ),
                      DropdownButton<String>(
                        hint: const Text('Tutti gli elementi'),
                        value: element.isEmpty ? null : element,
                        items: [
                          for (final e
                              in (entries
                                  .map(oculumCatalogueElement)
                                  .toSet()
                                  .toList()
                                ..sort()))
                            DropdownMenuItem(
                              value: e,
                              child: Text(elementDisplayName(e)),
                            ),
                        ],
                        onChanged: (v) => refresh(() => element = v ?? ''),
                      ),
                      TextButton(
                        onPressed: () => refresh(() {
                          role = null;
                          element = '';
                        }),
                        child: const Text('Azzera filtri'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 580
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - 10 * (columns - 1)) /
                            columns;
                        return ListView.builder(
                          itemCount: (visible.length / columns).ceil(),
                          itemBuilder: (context, row) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final entry
                                    in visible
                                        .skip(row * columns)
                                        .take(columns))
                                  SizedBox(
                                    width: width,
                                    child: Builder(
                                      builder: (context) {
                                        final art = oculumAbilityWithEvolutions(
                                          entry.art,
                                          five ? 5 : 3,
                                        );
                                        final natural = entry.natural;
                                        String cost(int form) =>
                                            natural != null &&
                                                !five &&
                                                natural.forme.isNotEmpty
                                            ? natural
                                                  .forme[min(
                                                    form - 1,
                                                    natural.forme.length - 1,
                                                  )]
                                                  .costo
                                            : oculumMonsterReadingCost(
                                                art,
                                                form,
                                              );
                                        final effects = art.effettiEvoluzione(
                                          1,
                                        );
                                        return abilityColorFrame(
                                          cost: cost(1),
                                          effects: effects,
                                          padding: EdgeInsets.zero,
                                          child: Tooltip(
                                            waitDuration: const Duration(
                                              milliseconds: 900,
                                            ),
                                            showDuration: const Duration(
                                              seconds: 12,
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth: min(
                                                480,
                                                MediaQuery.sizeOf(
                                                      dialog,
                                                    ).width -
                                                    32,
                                              ),
                                            ),
                                            message: [
                                              for (
                                                var form = 1;
                                                form <= 3;
                                                form++
                                              )
                                                '${artLevelRoman(form)} · Livello ${oculumCatalogueRequiredLevel(entry, form)} · ${cost(form)} · CD ${art.cooldownPerLivello[form - 1].amount}\n${natural != null && natural.forme.length >= form ? natural.forme[form - 1].descrizione : art.testoEvoluzione(form)}\n${art.effettiEvoluzione(form).map(oculumStructuredEffectDescription).join(' · ')}',
                                            ].join('\n\n'),
                                            child: ExpansionTile(
                                              key: ValueKey(entry.id),
                                              tilePadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              leading: Checkbox(
                                                value: selected.contains(
                                                  entry.id,
                                                ),
                                                onChanged: (value) => refresh(
                                                  () {
                                                    if (value == true) {
                                                      if (onPicked != null) {
                                                        selected.clear();
                                                      }
                                                      selected.add(entry.id);
                                                    } else {
                                                      selected.remove(entry.id);
                                                    }
                                                  },
                                                ),
                                              ),
                                              title: Text(
                                                entry.label,
                                                style: TextStyle(
                                                  color: abilityBenefitColor(
                                                    effects,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Livello richiesto ${oculumCatalogueRequiredLevel(entry)} · ${cost(1)}${catalogueLevel == null ? '' : ' · ${oculumCatalogueProgressLabel(entry, catalogueLevel)}'}',
                                                style: TextStyle(
                                                  color: abilityCostColors(
                                                    cost(1),
                                                  ).first,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              children: [
                                                for (
                                                  var form = 1;
                                                  form <= (five ? 5 : 3);
                                                  form++
                                                )
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    child: Text(
                                                      '${artLevelRoman(form)} · ${cost(form)}\n${natural != null && !five && natural.forme.isNotEmpty ? natural.forme[min(form - 1, natural.forme.length - 1)].descrizione : art.testoEvoluzione(form)}\n${(natural != null && !five && natural.forme.isNotEmpty ? natural.forme[min(form - 1, natural.forme.length - 1)].effettiStrutturati : art.effettiEvoluzione(form)).map(oculumStructuredEffectDescription).join('\n')}',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                child: Text(
                  onPicked == null
                      ? 'Aggiungi ${selected.length} abilità'
                      : 'Scegli skill',
                ),
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
    if (onPicked != null) {
      final entry = entries.firstWhere((e) => selected.contains(e.id));
      onPicked(
        entry.natural != null
            ? CharacterSkill.fromJson(entry.natural!.toJson())
            : oculumEquipmentAbilityFromArt(entry.art),
      );
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
  if (monster.isNpc ||
      monster.id.startsWith('pawn_guardiano') ||
      monster.id.startsWith('uomo_maschera') ||
      monster.id == 'ombra_ignota' ||
      const {'nuvi', 'thunder_bot'}.contains(monster.id) ||
      monster.id.contains('larva')) {
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
