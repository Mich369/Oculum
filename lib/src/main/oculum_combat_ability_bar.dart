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
  Future<bool> defendPendingCombat(String choice) async {
    if (realtimeService?.isConnected != true) return false;
    final tag = sheetTagAt(schedaCorrente);
    final pending = onlineCombatRequests.values
        .where(
          (request) =>
              request['targetTag'] == tag &&
              request['status'] == 'pending' &&
              request['kind'] != 'help' &&
              request['scope'] == permissionScope &&
              request['encounterId'] == onlineCombatEncounterId,
        )
        .toList();
    if (pending.isEmpty) return false;
    Map<String, dynamic>? selected = pending.first;
    if (pending.length > 1) {
      selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: const Text('Quale attacco vuoi difendere?'),
          children: [
            for (final request in pending)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, request),
                child: Text('${request['sourceName']} · ${request['attack']}'),
              ),
          ],
        ),
      );
    }
    if (mounted && selected != null && sheetTagAt(schedaCorrente) == tag) {
      await defendOnlineAttack(selected, choice);
    }
    return true;
  }

  Future<void> useCombatRoll(
    OculumCombatAbilityRole role, {
    HiddenEyeStat? stat,
  }) async {
    final origin = currentSheetScrollId();
    if (role == OculumCombatAbilityRole.attack &&
        onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack(initialChoice: stat?.id ?? 'vc');
      return;
    }
    if (role == OculumCombatAbilityRole.defense &&
        await defendPendingCombat(stat?.id ?? 'cm')) {
      return;
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    if (stat != null) {
      await tiraSottotrattoOcchio(stat);
    } else {
      await tiraValoreSpeciale(
        role == OculumCombatAbilityRole.attack ? 'VC' : 'CM',
        role == OculumCombatAbilityRole.attack ? vc() : cm(),
        applyGlobalRollModifier: false,
      );
    }
  }

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
    final description =
        natural?.forme[chosen].descrizione ??
        artSkill!.testoEvoluzione(chosen + 1);
    final oculumBefore = currentOculum();
    final beforeEffects = jsonEncode(activeStructuredEffects);
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
    if (!mounted ||
        currentSheetScrollId() != origin ||
        beforeEffects == jsonEncode(activeStructuredEffects)) {
      return;
    }
    final spentOculum = max(0, oculumBefore - currentOculum());
    final targetLimits = oculumAttackTargetLimits(
      description,
      spentOculum > 0 ? spentOculum : oculumTotale(),
    );
    final pending = activeStructuredEffects
        .where(
          (e) =>
              e['type'] == 'pending_target' &&
              e['effect'] is Map &&
              (e['effect'] as Map)['recipient'] != 'alleato',
        )
        .toList();
    for (final effect in pending) {
      effect['minimumTargets'] = targetLimits.minimum;
      effect['maximumTargets'] = targetLimits.maximum;
    }
    if (pending.isNotEmpty && onlineAttackTokens().isNotEmpty) {
      await planOnlineAttack(
        minimumTargets: targetLimits.minimum,
        maximumTargets: targetLimits.maximum,
      );
    }
  }

  Future<void> showCombatActionPanel(OculumCombatAbilityRole role) async {
    final origin = currentSheetScrollId();
    final selected = await showDialog<VoidCallback>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(switch (role) {
          OculumCombatAbilityRole.attack => t('Attacco', 'Attack'),
          OculumCombatAbilityRole.defense => t('Difesa', 'Defense'),
          OculumCombatAbilityRole.support => t('Aiuta compagno', 'Help ally'),
        }),
        content: SizedBox(
          width: min(720, max(0, MediaQuery.sizeOf(dialog).width - 48)),
          child: combatAbilityQuickBar(
            onlyRole: role,
            onChoose: (action) => Navigator.pop(dialog, action),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
    if (mounted && selected != null && currentSheetScrollId() == origin) {
      selected();
    }
  }

  Widget combatAbilityQuickBar({
    OculumCombatAbilityRole? onlyRole,
    ValueChanged<VoidCallback>? onChoose,
  }) {
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
    if (onlyRole != null) {
      final attack = onlyRole == OculumCombatAbilityRole.attack;
      final support = onlyRole == OculumCombatAbilityRole.support;
      if (attack && onlineAttackTokens().isNotEmpty) {
        entries.add((
          name: 'Bersaglio del fight',
          role: onlyRole,
          color: eyePupilGlowColor,
          enabled: true,
          hint: 'Scegli il bersaglio e il tiro da inviare online.',
          use: () => unawaited(planOnlineAttack()),
        ));
      }
      entries.add((
        name: support
            ? t('Aiuta compagno', 'Help ally')
            : '${attack ? 'VC' : 'CM'} +${attack ? vc() : cm()}',
        role: onlyRole,
        color: support
            ? primaryColor
            : attack
            ? Colors.redAccent
            : Colors.blueAccent,
        enabled: true,
        hint: support ? 'Tiro di aiuto compagno' : 'Tiro ordinario',
        use: () {
          if (support) {
            unawaited(tiraAiutaCompagno());
          } else {
            unawaited(useCombatRoll(onlyRole));
          }
        },
      ));
      final allowed = switch (onlyRole) {
        OculumCombatAbilityRole.attack => const {
          'schianto',
          'forza',
          'riflessi',
          'manifestazione_potere',
        },
        OculumCombatAbilityRole.defense => const {
          'riflessi',
          'resistenza',
          'manifestazione_potere',
        },
        OculumCombatAbilityRole.support => const {'medicina'},
      };
      for (final stat in hiddenEyeStats.where(
        (s) => s.unlocked && allowed.contains(s.id),
      )) {
        entries.add((
          name:
              '${stat.nome} +${hiddenEyeTotal(stat) + hiddenEyeStatRollQuickBonus(stat) + tiroGlobaleBonus()}',
          role: onlyRole,
          color: hiddenEyeStatIdentityColor(stat),
          enabled: true,
          hint: 'Tiro alternativo: descrivi e motiva come lo usi.',
          use: () => unawaited(useCombatRoll(onlyRole, stat: stat)),
        ));
      }
    }
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
    Widget buildOptions(BuildContext context, BoxConstraints constraints) {
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
        final options = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in subset)
              Tooltip(
                message: '${e.name}\n${e.hint}',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 132,
                    maxWidth: 230,
                    minHeight: 48,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: e.enabled
                        ? () {
                            if (onChoose != null) {
                              onChoose(e.use);
                            } else {
                              e.use();
                            }
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: e.color,
                      side: BorderSide(color: e.color.withValues(alpha: .55)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                    ),
                    icon: Icon(switch (role) {
                      OculumCombatAbilityRole.attack => Icons.casino_outlined,
                      OculumCombatAbilityRole.defense => Icons.shield_outlined,
                      OculumCombatAbilityRole.support =>
                        Icons.volunteer_activism_outlined,
                    }, size: 18),
                    label: Text(
                      e.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        );
        if (onlyRole != null) return options;
        return ExpansionTile(
          key: PageStorageKey('combat_abilities_${role.name}'),
          title: Text(
            '$title · ${subset.length}',
            style: TextStyle(color: color),
          ),
          childrenPadding: const EdgeInsets.all(8),
          children: [options],
        );
      }

      if (onlyRole != null) return group(onlyRole);
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
    }

    if (onlyRole != null) return buildOptions(context, const BoxConstraints());
    return LayoutBuilder(builder: buildOptions);
  }
}
