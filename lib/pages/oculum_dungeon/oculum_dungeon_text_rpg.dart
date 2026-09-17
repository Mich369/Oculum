part of '../oculum_dungeon_game.dart';

// Extension actions operate on the owning State.
// ignore_for_file: invalid_use_of_protected_member

extension _DungeonTextRpg on _OculumDungeonGameDialogState {
  void tryCaptureDungeonFallenEye(_EnemyInstance enemy) {
    if (isDungeonCoopClient ||
        fallenCompanions.length >= 3 ||
        valleyTrainingActive ||
        !dungeonFallenCaptureSucceeds(_random.nextInt(100))) {
      return;
    }
    final maximum = (enemy.maxHp ~/ 3).clamp(20, 120);
    final eye = DungeonFallenCompanion(
      id: 'run_eye_${DateTime.now().microsecondsSinceEpoch}',
      name: t(enemy.nameIt, enemy.nameEn),
      maxHp: maximum,
      hp: maximum,
      damage: (enemy.attack ~/ 3).clamp(2, 20),
      defense: (enemy.defense ~/ 3).clamp(0, 12),
      level: max(0, enemy.level),
      oculumRarity: _random.nextInt(100) < 5,
    );
    if (eye.oculumRarity && _random.nextInt(1000) == 0) eye.bond = 1000;
    fallenCompanions.add(eye);
    addLog(
      t(
        'Occhi dei Caduti: ${eye.name} sceglie di seguirti.',
        'Fallen Eyes: ${eye.name} chooses to follow you.',
      ),
    );
  }

  void dungeonFallenCompanionsAct() {
    for (final eye in fallenCompanions.where((eye) => !eye.dead)) {
      eye.summon('room_$room');
      final enemy = firstAliveEnemy();
      if (enemy == null) break;
      final damage = max(1, eye.damage - enemy.defense ~/ 3);
      applyDamageToEnemy(enemy, damage);
      textIt += '\n${eye.name} (Occhio dei Caduti): $damage Danni.';
      textEn += '\n${eye.name} (Fallen Eye): $damage Damage.';
    }
    defeatDeadEnemiesFromParty();
  }

  void restDungeonFallenEyes() {
    for (final eye in fallenCompanions) {
      if (eye.ownerLongRest('rest_${runCount}_$room')) {
        addLog(
          t(
            '${eye.name} rinasce al 10% Vita.',
            '${eye.name} is reborn at 10% HP.',
          ),
        );
      }
    }
  }

  Widget buildDungeonFollowers() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      Text(
        t(
          'Occhi dei Caduti · ${fallenCompanions.length}/3',
          'Fallen Eyes · ${fallenCompanions.length}/3',
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      if (fallenCompanions.isEmpty)
        Text(
          t(
            '20% dopo una sconfitta definitiva del nemico: una creatura può seguirti. Gli Occhi della run restano separati dalla campagna.',
            '20% after an enemy’s final defeat: a creature may follow you. Run Eyes remain separate from the campaign.',
          ),
        ),
      for (final eye in fallenCompanions)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${eye.name}${eye.awakened ? ' · RISVEGLIATO' : ''}'),
          subtitle: Text(
            eye.dead
                ? t(
                    'MORTO · ${eye.awakened || eye.rebirths > 0 ? 'Rinascita al Riposo Lungo' : 'Nessuna Rinascita disponibile'}',
                    'DEAD · ${eye.awakened || eye.rebirths > 0 ? 'Rebirth on Long Rest' : 'No rebirth available'}',
                  )
                : 'HP ${eye.hp}/${eye.maxHp} · ${t('Danno', 'Damage')} ${eye.damage} · ${t('Legame', 'Bond')} ${eye.bond}/1000',
          ),
          trailing: !inCombat && !isDungeonCoopClient
              ? IconButton(
                  tooltip: t('Congeda dalla run', 'Dismiss from run'),
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () {
                    setState(() => fallenCompanions.remove(eye));
                    unawaited(saveRunCheckpoint());
                  },
                )
              : null,
        ),
    ],
  );
  _CharacterOrigin monsterOrigin(MonsterBookEntry monster) {
    int stat(String key, String fallback, int base) =>
        (monster.stats[key] ?? monster.stats[fallback] ?? base).clamp(1, 18);
    final res = stat('resilienza', 'hp', 5);
    final vol = stat('volonta', 'atk', 5);
    final mat = stat('materia', 'def', 4);
    final ocu = stat('oculum', 'level', 3);
    return _CharacterOrigin(
      id: 'monster:${monster.id}',
      nameIt: monster.nameIt,
      nameEn: monster.nameEn,
      descIt:
          '${monster.descIt}\n\nCopia dungeon: +${res * 3} Vita, +$vol Danno, +${mat ~/ 2} Difesa, +${min(4, ocu ~/ 3)} Oculum. Tre tecniche adattate: Assalto, Carapace e Manifestazione.',
      descEn:
          '${monster.descEn}\n\nDungeon copy: +${res * 3} HP, +$vol Damage, +${mat ~/ 2} Defense, +${min(4, ocu ~/ 3)} Oculum. Three adapted techniques: Assault, Carapace and Manifestation.',
      spriteKind: 'monster',
      primaryColor: elementColor(monster.elementId),
      hpBonus: res * 3,
      shieldBonus: mat,
      damageBonus: vol,
      defenseBonus: mat ~/ 2,
      oculumBonus: min(4, ocu ~/ 3),
      partnerNameIt: '',
      partnerNameEn: '',
    );
  }

  Future<void> showPlayableMonsterPicker() async {
    var query = '';
    var category = 'Tutti';
    final selected = await showDialog<MonsterBookEntry>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final matches = monsterBookEntries.where((monster) {
            final type = monster.isBoss
                ? 'Boss'
                : monster.isMiniBoss
                ? 'Mini Boss'
                : 'Mostro';
            return (category == 'Tutti' || category == type) &&
                '${monster.nameIt} ${monster.nameEn} ${monster.elementId} ${monster.descIt}'
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();
          return AlertDialog(
            title: Text(t('Scegli il tuo mostro', 'Choose your monster')),
            content: SizedBox(
              width: 700,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => update(() => query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t(
                        'Nome, elemento, descrizione',
                        'Name, element, description',
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in [
                        'Tutti',
                        'Mostro',
                        'Mini Boss',
                        'Boss',
                      ])
                        ChoiceChip(
                          label: Text(value),
                          selected: category == value,
                          onSelected: (_) => update(() => category = value),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (_, index) {
                        final monster = matches[index];
                        final origin = monsterOrigin(monster);
                        return ListTile(
                          title: Text(t(monster.nameIt, monster.nameEn)),
                          subtitle: Text(
                            '${monster.elementId} · +${origin.hpBonus} HP · +${origin.damageBonus} ${t('Danno', 'Damage')} · +${origin.defenseBonus} ${t('Difesa', 'Defense')}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, monster),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('Indietro', 'Back')),
              ),
            ],
          );
        },
      ),
    );
    if (selected == null || !mounted || activeCharacterOrigin != null) return;
    // Serialize/copy the source: future Book edits cannot change a running build.
    chooseDungeonMonster(selected);
  }

  void useDungeonMonsterSkill(int index) {
    if (dungeonMonster == null ||
        !canUseCombatInput ||
        index < 0 ||
        index > 2 ||
        monsterSkillCooldown > 0) {
      return;
    }
    if (isDungeonCoopActive) return;
    if (oculumCharges < index) return;
    setState(() {
      if (playerStunTurns > 0) {
        playerStunTurns--;
        enemyTurn();
        return;
      }
      final target = firstAliveEnemy();
      if (target == null) return;
      clearChoices();
      oculumSkillActionsThisTurn = 0;
      oculumSkillTurnScheduleToken++;
      oculumCharges -= index;
      monsterSkillCooldown = index == 0 ? 1 : 3;
      if (index == 1) {
        final shield = 8 + totalDefense;
        gainPlayerShield(shield);
        textIt = '${dungeonMonster!.nameIt}: Carapace. +$shield Scudo.';
        textEn = '${dungeonMonster!.nameEn}: Carapace. +$shield Shield.';
      } else {
        final damage = max(
          1,
          totalDamage +
              (index == 2 ? totalCm : totalVc) ~/ 2 -
              target.defense ~/ 2,
        );
        applyDamageToEnemy(target, damage);
        if (index == 2 && target.hp > 0) {
          final element = dungeonMonster!.elementId.toLowerCase();
          if (['fuoco', 'fire', 'lava', 'sole', 'sun'].contains(element)) {
            target.burnTurns = max(target.burnTurns, 3);
            target.burnPotency = max(target.burnPotency, 4);
          } else if ([
            'gelo',
            'ice',
            'acqua',
            'water',
            'crystal',
          ].contains(element)) {
            target.slowTurns = max(target.slowTurns, 2);
          } else {
            target.bleedTurns = max(target.bleedTurns, 3);
            target.bleedPotency = max(target.bleedPotency, 4);
          }
        }
        textIt =
            '${dungeonMonster!.nameIt}: ${index == 0 ? 'Assalto' : 'Manifestazione'} (${dungeonMonster!.elementId}). $damage Danni prima dello Scudo.';
        textEn =
            '${dungeonMonster!.nameEn}: ${index == 0 ? 'Assault' : 'Manifestation'} (${dungeonMonster!.elementId}). $damage Damage before Shield.';
      }
      defeatDeadEnemiesFromParty();
      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }
      syncPrimaryEnemyFromParty();
      alliesAct();
      if (enemyParty.isEmpty) {
        completeCombatVictory();
        return;
      }
      enemyTurn();
    });
  }

  void recordOriginMastery() {
    final origin = activeCharacterOrigin;
    if (origin == null || room < 3 || !masteredOrigins.add(origin.id)) return;
    if (origin.id.startsWith('monster:')) {
      unlockedTitleIds.add('rpg_other_skin');
    }
    if (masteredOrigins.length >= 3) unlockedTitleIds.add('rpg_many_lives');
    if (masteredOrigins.length >= 6) unlockedTitleIds.add('rpg_changeling');
    addLog(
      t(
        'Cammino ricordato: ${origin.nameIt}. Personaggi padroneggiati: ${masteredOrigins.length}.',
        'Path remembered: ${origin.nameEn}. Mastered characters: ${masteredOrigins.length}.',
      ),
    );
    unawaited(_savePermanentProgress());
  }

  void explainDungeonTitle(_TitleDef title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(titleNameIt(title), titleNameEn(title))),
        content: SingleChildScrollView(
          child: Text(t(titleDetailIt(title), titleDetailEn(title))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

  Widget buildTextRpgPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              activeCharacterOrigin?.nameIt ?? 'Il viandante',
              activeCharacterOrigin?.nameEn ?? 'The wanderer',
            ),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            t(
              'Stanza $room · Piano $currentFloor · ${inCombat ? 'Combattimento a turni' : 'Esplorazione'}',
              'Room $room · Floor $currentFloor · ${inCombat ? 'Turn-based combat' : 'Exploration'}',
            ),
          ),
          if (equippedTitleIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: publicRunTitle?.id,
              hint: Text(t('Scegli il Titolo pubblico', 'Choose public Title')),
              items: [
                for (final title in publicRunTitleCandidates)
                  DropdownMenuItem(
                    value: title.id,
                    child: Text(
                      '${t(titleNameIt(title), titleNameEn(title))} · ×1,3',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: inCombat || isDungeonCoopClient
                  ? null
                  : selectPublicRunTitle,
            ),
            Text(
              t(
                'Titolo della run visibile anche agli alleati online. Bonus statistici ×1,3; precedenza ai Titoli di livello superiore a 1.',
                'Run Title also visible to online allies. Stat bonuses ×1.3; Titles above level 1 take priority.',
              ),
            ),
          ],
          if (dungeonMonster != null) ...[
            const SizedBox(height: 8),
            Text(
              t(
                'Forma: ${dungeonMonster!.elementId}. Le tecniche seguenti sono la copia adattata al dungeon.',
                'Form: ${dungeonMonster!.elementId}. These techniques are the dungeon adaptation.',
              ),
            ),
            if (inCombat) ...[
              if (isDungeonCoopActive)
                Text(
                  t(
                    'In cooperativa usa le azioni di combattimento condivise. Le tre tecniche della forma sono disponibili nella run singola.',
                    'In co-op, use the shared combat actions. The three form techniques are available in solo runs.',
                  ),
                ),
              Text(
                t(
                  'Assalto: VC, gratis. Carapace: 8 + Difesa Scudo, 1 carica. Manifestazione: CM + effetto elementale, 2 cariche. Recupero condiviso: ${monsterSkillCooldown > 0 ? monsterSkillCooldown : 0} turni.',
                  'Assault: VC, free. Carapace: 8 + Defense Shield, 1 charge. Manifestation: CM + elemental effect, 2 charges. Shared cooldown: $monsterSkillCooldown turns.',
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (var index = 0; index < 3; index++)
                    OutlinedButton(
                      onPressed:
                          !isDungeonCoopActive &&
                              canUseCombatInput &&
                              monsterSkillCooldown == 0 &&
                              oculumCharges >= index
                          ? () => useDungeonMonsterSkill(index)
                          : null,
                      child: Text(
                        t(
                          ['Assalto', 'Carapace', 'Manifestazione'][index],
                          ['Assault', 'Carapace', 'Manifestation'][index],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
          if (inCombat) ...[
            const Divider(),
            for (final enemy in enemyParty.where((enemy) => enemy.hp > 0))
              ListTile(
                dense: true,
                selected: enemyParty.indexOf(enemy) == selectedEnemyTargetIndex,
                onTap: () => selectEnemyTarget(enemyParty.indexOf(enemy)),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${t(enemy.nameIt, enemy.nameEn)} · ${enemy.elementId}',
                ),
                subtitle: Text(
                  'HP ${enemy.hp}/${enemy.maxHp} · ${t('Scudo', 'Shield')} ${enemy.shield} · ${t('Attacco', 'Attack')} ${enemy.attack} · ${t('Difesa', 'Defense')} ${enemy.defense}',
                ),
                trailing: Text(
                  enemy.stunTurns > 0
                      ? t('Stordito', 'Stunned')
                      : enemy.burnTurns > 0
                      ? t('Brucia', 'Burning')
                      : enemy.bleedTurns > 0
                      ? t('Sanguina', 'Bleeding')
                      : '',
                ),
              ),
          ],
          buildDungeonFollowers(),
          if (unlockedTitleIds.any((id) => id.startsWith('rpg_'))) ...[
            const Divider(),
            Text(
              t(
                'Eredità dei personaggi · clic destro o tieni premuto',
                'Character legacy · right-click or hold',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final title in _allTitles.where(
                  (title) =>
                      title.id.startsWith('rpg_') &&
                      unlockedTitleIds.contains(title.id),
                ))
                  GestureDetector(
                    onSecondaryTap: () => explainDungeonTitle(title),
                    onLongPress: () => explainDungeonTitle(title),
                    child: ActionChip(
                      label: Text(t(title.nameIt, title.nameEn)),
                      onPressed: () => explainDungeonTitle(title),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
