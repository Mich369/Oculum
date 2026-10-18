part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

enum OculumCombatAbilityRole { attack, defense, support }

OculumCombatAbilityRole oculumCombatAbilityRole(
  Iterable<OculumStructuredEffect> effects, {
  String explicitType = '',
}) {
  final declared = oculumNormalizeText(explicitType);
  if (declared.contains('support') || declared.contains('cura')) {
    return OculumCombatAbilityRole.support;
  }
  if (declared.contains('difes')) return OculumCombatAbilityRole.defense;
  if (declared.contains('attacc')) return OculumCombatAbilityRole.attack;
  final active = effects.where((e) => e.enabled).toList();
  if (active.any((e) => e.recipient == 'alleato') &&
      active.every(
        (e) => e.recipient == 'alleato' || e.recipient == 'se_stesso',
      )) {
    return OculumCombatAbilityRole.support;
  }
  if (active.any(
    (e) =>
        const {'danno', 'danno_percentuale'}.contains(e.type) ||
        e.recipient != 'se_stesso' &&
            (e.type == 'stato' || e.mode == 'diminuzione'),
  )) {
    return OculumCombatAbilityRole.attack;
  }
  if (active.any(
    (e) =>
        const {'cura', 'hp_temporanei'}.contains(e.type) ||
        e.recipient == 'alleato',
  )) {
    return OculumCombatAbilityRole.support;
  }
  return OculumCombatAbilityRole.defense;
}

extension _OculumCombatAbilityBar on _OculumHomePageState {
  Widget titleCombatRoleEditor(String value, ValueChanged<String> changed) =>
      DropdownButtonFormField<String>(
        initialValue:
            const ['', 'attacco', 'difesa', 'supporto'].contains(value)
            ? value
            : '',
        decoration: const InputDecoration(
          labelText: 'Gruppo nella barra combattimento',
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('Automatico dagli effetti')),
          DropdownMenuItem(value: 'attacco', child: Text('Attacco')),
          DropdownMenuItem(value: 'difesa', child: Text('Difesa')),
          DropdownMenuItem(value: 'supporto', child: Text('Aiuta compagno')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => changed(value));
            programmaSalvataggio();
          }
        },
      );

  Color combatAbilityResourceColor(Iterable<String> resources) {
    final values = resources.map(oculumNormalizeText).toList();
    if (values.any((v) => v.contains('oculum'))) return eyePupilGlowColor;
    if (values.any((v) => v.contains('vol'))) return Colors.redAccent;
    if (values.any((v) => v.contains('materia'))) return Colors.blueAccent;
    if (values.any((v) => v.contains('resilienza') || v.contains('hp'))) {
      return Colors.greenAccent;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  Future<void> chooseCombatAbilityForm({
    CharacterSkill? natural,
    CharacterArt? art,
    ArtSkill? artSkill,
  }) async {
    final origin = currentSheetScrollId();
    final count = natural?.forme.length ?? (art == null ? 0 : artMaxLevel(art));
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(natural?.nome ?? artSkill?.nome ?? 'Abilità'),
        children: [
          for (var form = 0; form < count; form++)
            Builder(
              builder: (_) {
                final effectForm = natural?.forme[form];
                final description =
                    effectForm?.descrizione ??
                    artSkill!.testoEvoluzione(form + 1);
                final cost =
                    effectForm?.costo ??
                    '${artSkill!.oculumMinimoPerLivello(form + 1)}/${artSkill.oculumMassimoPerLivello(form + 1)} ${artSkill.risorsaCostoPerLivello(form + 1)}';
                final timer =
                    effectForm?.cooldownStrutturato ??
                    artSkill?.cooldownPerLivello[form];
                return SimpleDialogOption(
                  onPressed: timer?.ready == false
                      ? null
                      : () => Navigator.pop(dialog, form),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${artLevelRoman(form + 1)} · $cost${timer?.ready == false ? ' · recupero ${timer!.remaining} ${timer.unit}' : ''}',
                      ),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
    if (!mounted || chosen == null || currentSheetScrollId() != origin) return;
    if (natural != null && skills.contains(natural)) {
      await usaFormaSkill(natural, skills.indexOf(natural), chosen);
    } else if (art != null &&
        artSkill != null &&
        arti.contains(art) &&
        art.skills.contains(artSkill)) {
      await impostaLivelloSkillArt(
        artIndex: arti.indexOf(art),
        skillIndex: art.skills.indexOf(artSkill),
        nuovoLivello: chosen + 1,
        riutilizza: artSkill.livello == chosen + 1,
      );
    }
  }

  Widget combatAbilityQuickBar() {
    final entries =
        <
          ({
            String name,
            OculumCombatAbilityRole role,
            bool enabled,
            Color color,
            String hint,
            VoidCallback use,
          })
        >[];
    for (final title in {...titoli, ...trattiRazziali}) {
      void addTitleSkill(TitleExtraSkillEntry? extra) {
        final text = extra?.descrizione ?? title.skill;
        final configured = extra?.effects ?? title.skillEffects;
        if ((text.trim().isEmpty && configured.isEmpty) ||
            RegExp(r'^\s*passiva\b', caseSensitive: false).hasMatch(text)) {
          return;
        }
        final effects = configured.isNotEmpty
            ? configured
            : oculumParseAbilityMechanics(
                text,
                subtraits: hiddenEyeStats,
              ).effects;
        final cost = extra?.cost ?? title.skillCost;
        final cooldown =
            extra?.cooldown ?? (extra == null ? title.skillCooldown : null);
        final name = extra == null
            ? title.nome
            : '${extra.nome.trim().isEmpty ? 'Skill extra' : extra.nome} · ${title.nome}';
        entries.add((
          name: '$name · Titolo',
          role: oculumCombatAbilityRole(
            effects,
            explicitType: extra?.combatRole ?? title.skillCombatRole,
          ),
          color: combatAbilityResourceColor([
            cost?.resource ??
                oculumParseAbilityCost(text)?.resource ??
                'nessuna',
          ]),
          enabled: cooldown?.ready ?? true,
          hint:
              '${extra?.descrizione ?? title.skill}${cooldown?.ready == false ? '\nRicarica: ${cooldown!.remaining} ${cooldown.unit}' : ''}',
          use: () => usaSkillTitolo(title, skillExtra: extra),
        ));
      }

      addTitleSkill(null);
      for (final extra in title.skillExtra) {
        addTitleSkill(extra);
      }
    }
    for (final skill in skills.where((s) => s.equipaggiata && !s.passiva)) {
      skill.ensureForms();
      final forms = skill.forme
          .where((f) => !f.tipo.toLowerCase().contains('passiv'))
          .toList();
      if (forms.isEmpty) continue;
      final role = oculumCombatAbilityRole(
        forms.expand((f) => f.effettiStrutturati),
        explicitType: skill.tipo,
      );
      entries.add((
        name: skill.nome,
        role: role,
        color: combatAbilityResourceColor(
          forms.map(
            (f) =>
                f.costoStrutturato?.resource ??
                oculumParseAbilityCost(f.costo)?.resource ??
                f.costo,
          ),
        ),
        enabled: true,
        hint: 'Skill · scegli la forma e conferma il costo',
        use: () => chooseCombatAbilityForm(natural: skill),
      ));
    }
    for (final art in arti) {
      for (final skill in art.skills) {
        if (skill.tipiPerLivello
            .take(3)
            .every((t) => t.toLowerCase().contains('passiv'))) {
          continue;
        }
        final role = oculumCombatAbilityRole(
          skill.effettiPerLivello.expand((f) => f),
          explicitType: skill.tipoPerLivello(1),
        );
        entries.add((
          name: '${skill.nome} · ${art.nome}',
          role: role,
          color: combatAbilityResourceColor([
            for (var form = 1; form <= artMaxLevel(art); form++)
              effectiveArtCostResource(art, skill, form),
          ]),
          enabled: art.sbloccata && art.inUso,
          hint: art.inUso
              ? 'Art · scegli la forma e conferma il costo'
              : 'Seleziona prima questa Art nella scheda',
          use: () => chooseCombatAbilityForm(art: art, artSkill: skill),
        ));
      }
      if (art.openName.trim().isNotEmpty) {
        final role = oculumCombatAbilityRole(
          art.openSkillEffects,
          explicitType: art.openSkillType,
        );
        entries.add((
          name: '${art.openAttiva ? 'Chiudi' : 'Apri'} ${art.openName}',
          role: role,
          color: eyePupilGlowColor,
          enabled: art.sbloccata && art.inUso,
          hint: 'Open · usa requisiti e costi originali',
          use: () => usaOpenArt(arti.indexOf(art)),
        ));
        if (art.monsterOpenSkill && art.openAttiva) {
          entries.add((
            name: '${art.openName} · Skill Open',
            role: role,
            color: eyePupilGlowColor,
            enabled: art.openSkillCooldown?.ready ?? true,
            hint: 'Skill Open · cooldown originale',
            use: () => usaSkillOpenMostro(arti.indexOf(art)),
          ));
        }
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget group(OculumCombatAbilityRole role) {
          final subset = entries.where((e) => e.role == role).toList();
          final color = switch (role) {
            OculumCombatAbilityRole.attack => eyePupilGlowColor,
            OculumCombatAbilityRole.defense => secondaryColor,
            OculumCombatAbilityRole.support => primaryColor,
          };
          final title = switch (role) {
            OculumCombatAbilityRole.attack => 'Attacco',
            OculumCombatAbilityRole.defense => 'Difesa',
            OculumCombatAbilityRole.support => 'Aiuta compagno',
          };
          return ExpansionTile(
            key: PageStorageKey('combat_abilities_${role.name}'),
            title: Text(
              '$title · ${subset.length}',
              style: TextStyle(color: color),
            ),
            childrenPadding: const EdgeInsets.all(8),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in subset)
                    Tooltip(
                      message: e.hint,
                      child: OutlinedButton(
                        onPressed: e.enabled ? e.use : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: e.color,
                          side: BorderSide(
                            color: e.color.withValues(alpha: .55),
                          ),
                        ),
                        child: Text(e.name),
                      ),
                    ),
                ],
              ),
            ],
          );
        }

        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              for (final role in OculumCombatAbilityRole.values) group(role),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final role in OculumCombatAbilityRole.values)
              Expanded(child: group(role)),
          ],
        );
      },
    );
  }
}
