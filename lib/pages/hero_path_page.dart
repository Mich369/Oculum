import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart' hide HeroMode;
import 'package:shared_preferences/shared_preferences.dart';
import '../game/hero_path/hero_engine.dart';
import '../services/oculum_save_profile.dart';

class HeroPathPage extends StatefulWidget {
  const HeroPathPage({
    super.key,
    this.initialName = '',
    this.onLegacy,
    this.initialRun,
  });
  final String initialName;
  final VoidCallback? onLegacy;
  final HeroRun? initialRun;
  @override
  State<HeroPathPage> createState() => _HeroPathPageState();
}

class _HeroPathPageState extends State<HeroPathPage> {
  HeroRun? run;
  bool loading = true, busy = false;
  String? saveError;
  int selectedTarget = 0;
  late final TextEditingController name;
  final seed = TextEditingController();
  HeroDifficulty difficulty = HeroDifficulty.medium;
  HeroMode mode = HeroMode.normal;
  final Set<String> selectedSkills = {};
  Set<String> meta = {};
  Future<void> saveQueue = Future.value();
  static const difficultyNames = ['Facile', 'Medio', 'Difficile', 'Oculum'];
  static const modeNames = ['Normale', 'Invecchiamento', 'Roguelite / Carte'];
  String get saveKey => oculumProfiledStorageKey('oculus.heroPath.run.v1');
  String get metaKey => oculumProfiledStorageKey('oculus.heroPath.meta.v1');
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initialName);
    if (widget.initialRun != null) {
      run = widget.initialRun;
      loading = false;
    } else {
      unawaited(load());
    }
  }

  @override
  void dispose() {
    name.dispose();
    seed.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      meta = (prefs.getStringList(metaKey) ?? []).toSet();
      final raw = prefs.getString(saveKey);
      if (raw != null) {
        final data = heroMap(jsonDecode(raw));
        if (heroInt(data['schema']) > 1) {
          throw const FormatException(
            'Salvataggio di una versione più recente',
          );
        }
        run = HeroRun.fromJson(data);
        run!.achievements.addAll(meta);
        meta.addAll(run!.achievements);
      }
    } catch (e) {
      saveError = 'Salvataggio conservato, caricamento non riuscito: $e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> persist() {
    final current = run;
    if (current == null) return Future.value();
    final payload = jsonEncode(current.toJson());
    meta.addAll(current.achievements);
    final achievements = meta.toList();
    saveQueue = saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final ok = await prefs.setString(saveKey, payload);
        final metaOk = await prefs.setStringList(metaKey, achievements);
        if (!ok || !metaOk) throw StateError('Scrittura non riuscita');
        if (mounted && saveError != null) setState(() => saveError = null);
      } catch (e) {
        if (mounted) setState(() => saveError = 'Salvataggio non riuscito: $e');
      }
    });
    return saveQueue;
  }

  void act(void Function() action) {
    if (busy) return;
    setState(() {
      action();
      run?.refreshSkillAchievements();
      selectedTarget = run == null
          ? 0
          : max(0, run!.enemies.indexWhere((e) => e.hp > 0));
    });
    unawaited(persist());
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Conferma'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> play(String id) async {
    final r = run!;
    final warning = r.cardWarning(id);
    if (warning.isNotEmpty && !await confirm('Sforzo sulla ferita', warning)) {
      return;
    }
    if (mounted) act(() => r.play(id, target: selectedTarget));
  }

  Widget button(String label, void Function()? action, {IconData? icon}) =>
      Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: OutlinedButton.icon(
          onPressed: action == null ? null : () => act(action),
          icon: Icon(icon ?? Icons.chevron_right, size: 18),
          label: Text(label),
        ),
      );
  Widget skillAchievementsPanel(Set<String> earned) => panel(
    'Achievement Art · ${heroSkillAchievements.where((a) => earned.contains(a.id)).length}/21',
    [
      const Text(
        '21 Skill sono disponibili da subito. Le altre 21 si sbloccano con questi Achievement e restano disponibili nelle run successive. Lo sblocco le aggiunge al catalogo e alle ricompense, non direttamente al mazzo.',
      ),
      for (final achievement in heroSkillAchievements)
        ListTile(
          leading: Icon(
            earned.contains(achievement.id)
                ? Icons.check_circle_outline
                : Icons.lock_outline,
          ),
          title: Text(achievement.name),
          subtitle: Text(
            '${achievement.requirement}\nSblocca: ${cardName(achievement.skillId)}',
          ),
        ),
    ],
  );

  Widget panel(String title, List<Widget> children, {bool open = false}) =>
      Card(
        child: ExpansionTile(
          initiallyExpanded: open,
          title: Text(title),
          childrenPadding: const EdgeInsets.all(12),
          children: children,
        ),
      );
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9574BA),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101017),
    ),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cammino dell’Eroe'),
          bottom: run?.inCombat == true
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(88),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Column(
                      children: [
                        Text(
                          'Vita ${run!.player.hp} · Oculum ${run!.player.oculum} · Scudo ${run!.player.shield}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'VOL ${run!.player.volonta} · MAT ${run!.player.materia} · Isp. ${run!.player.inspirations.join(" / ")}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Turno ${run!.turn + 1} · ${run!.actionsLeft} ${run!.actionsLeft == 1 ? 'azione disponibile' : 'azioni disponibili'}',
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                        if (run!.player.conditions.isNotEmpty)
                          Text(
                            run!.player.conditions.keys.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orangeAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Regole Oculus',
              onPressed: rules,
              icon: const Icon(Icons.menu_book_outlined),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (saveError != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(saveError!),
                            ),
                          ),
                        if (run == null) ...creation() else ...journey(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
  List<Widget> creation() => [
    const Text(
      'OCULUS',
      style: TextStyle(letterSpacing: 4, color: Color(0xFFBDA7D6)),
    ),
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text('Tre sentieri. Una vita.', style: TextStyle(fontSize: 26)),
    ),
    TextField(
      controller: name,
      maxLength: 32,
      decoration: const InputDecoration(labelText: 'Nome'),
    ),
    DropdownButtonFormField<HeroDifficulty>(
      initialValue: difficulty,
      decoration: const InputDecoration(labelText: 'Difficoltà'),
      items: [
        for (final d in HeroDifficulty.values)
          DropdownMenuItem(value: d, child: Text(difficultyNames[d.index])),
      ],
      onChanged: (v) => setState(() => difficulty = v!),
    ),
    DropdownButtonFormField<HeroMode>(
      initialValue: mode,
      decoration: const InputDecoration(labelText: 'Modalità'),
      items: [
        for (final m in HeroMode.values)
          DropdownMenuItem(value: m, child: Text(modeNames[m.index])),
      ],
      onChanged: (v) => setState(() => mode = v!),
    ),
    if (mode == HeroMode.aging)
      const Text(
        'Il tempo indebolisce gradualmente Volontà e Materia. La Foresta può insegnarti a resistere.',
      ),
    if (mode == HeroMode.roguelite)
      const Text(
        'Titoli e carte ricompensa più frequenti; lo stesso combattimento Oculus.',
      ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skill Art selezionate'),
        if (selectedSkills.isEmpty)
          const Text('Nessuna Skill selezionata.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in selectedSkills)
                InputChip(
                  label: Text(cardName(id)),
                  deleteButtonTooltipMessage: 'Deseleziona ${cardName(id)}',
                  onDeleted: () => setState(() => selectedSkills.remove(id)),
                ),
            ],
          ),
      ],
    ),
    panel('Oculum Art · scegli esattamente 3 Skill (${selectedSkills.length}/3)', [
      for (final element in heroSkills.map((s) => s.element).toSet())
        ExpansionTile(
          title: Text(element),
          children: [
            for (final s in heroSkills.where((s) => s.element == element))
              CheckboxListTile(
                value: selectedSkills.contains(s.id),
                title: Text(s.name),
                subtitle: Text(
                  '${s.description(0)}\n${s.cost} ${s.resource} · CD ${s.cooldown}'
                  '${heroSkillAvailable(s.id, meta) ? '' : '\nBloccata · ${heroSkillUnlock(s.id)!.name}: ${heroSkillUnlock(s.id)!.requirement}'}',
                ),
                secondary: heroSkillAvailable(s.id, meta)
                    ? null
                    : const Icon(Icons.lock_outline),
                onChanged: !heroSkillAvailable(s.id, meta)
                    ? null
                    : (value) => setState(() {
                        if (value == true && selectedSkills.length < 3) {
                          selectedSkills.add(s.id);
                        } else if (value != true) {
                          selectedSkills.remove(s.id);
                        }
                      }),
              ),
          ],
        ),
    ], open: true),
    panel('Seed e memorie', [
      TextField(
        controller: seed,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Seed opzionale'),
      ),
      Text('Memorie sbloccate: ${meta.length}'),
    ]),
    skillAchievementsPanel(meta),
    FilledButton(
      onPressed: selectedSkills.length == 3 && saveError == null
          ? () => act(() {
              run = HeroRun(
                seed:
                    int.tryParse(seed.text) ??
                    DateTime.now().millisecondsSinceEpoch % 2147483647,
                name: name.text.trim().isEmpty
                    ? 'Senza nome'
                    : name.text.trim(),
                difficulty: difficulty,
                mode: mode,
                art: selectedSkills.toList(),
                meta: meta,
              );
            })
          : null,
      child: const Text('Inizia il Cammino'),
    ),
    if (widget.onLegacy != null)
      TextButton(
        onPressed: widget.onLegacy,
        child: const Text('Archivio: contenuti e salvataggi precedenti'),
      ),
  ];
  List<Widget> journey() {
    final r = run!;
    final p = r.player;
    return [
      Text(
        '${p.name} · ${r.location}${r.scenario.isEmpty || r.location != 'Dungeon' ? '' : ' / ${r.scenario}'}',
        style: const TextStyle(fontSize: 22),
      ),
      Text(
        'Scena ${r.scene} · ${r.night ? 'Notte' : 'Giorno'} ${r.day + 1} · ${difficultyNames[r.difficulty.index]} · ${modeNames[r.mode.index]}',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final value in [
            'Vita ${p.hp}/${p.maxHp}',
            'Oculum ${p.oculum}/${p.maxOculum}',
            'Volontà ${p.volonta}',
            'Materia ${p.materia}',
            'Scudo ${p.shield}',
            'Isp. ${p.inspirations[0]} / Super ${p.inspirations[1]} / Oculum ${p.inspirations[2]}',
          ])
            Chip(label: Text(value), visualDensity: VisualDensity.compact),
        ],
      ),
      if (p.conditions.isNotEmpty)
        Text(
          p.conditions.entries
              .map(
                (e) =>
                    '${e.key}${e.value > 0 ? ' (${e.value}${e.key == 'Protezione Sanguinante' ? ' scene, +2' : ' turni'})' : ''}',
              )
              .join(' · '),
          style: const TextStyle(color: Colors.orangeAccent),
        ),
      if (r.mode == HeroMode.aging)
        Text(
          'Decadimento: −${r.agePenalty} Volontà / Materia${r.forestSurvival ? ' · Sopravvivenza della Foresta: +5 VOL / +3 MAT' : ''}',
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            r.text,
            style: const TextStyle(fontSize: 17, height: 1.4),
          ),
        ),
      ),
      if (r.rolls.isNotEmpty)
        panel('Dadi · ultimo risultato: ${r.rolls.last.total}', [
          for (final roll in r.rolls) HeroDieReadout(roll: roll),
        ], open: true),
      if (r.finished) ...[
        Text('La run è terminata. ${r.achievements.length} memorie restano.'),
        FilledButton(
          onPressed: () async {
            await persist();
            if (mounted) {
              setState(() {
                run = null;
                selectedSkills.clear();
              });
            }
          },
          child: const Text('Nuovo Cammino'),
        ),
      ] else if (r.pendingDeath) ...[
        if (r.canPlay('inspiration')) card('inspiration'),
        Text(
          'Solo il dado naturale di Volontà: d${p.dice['volonta']}, soglia ${OculusRules.deathThresholds[r.difficulty.index]}. Bonus e Ispirazioni non si applicano.',
        ),
        button(
          'Tiro contro la morte',
          r.resolveDeath,
          icon: Icons.casino_outlined,
        ),
      ] else ...[
        if (r.inCombat) ...combat(),
        if (!r.inCombat && r.titleOffers.isNotEmpty)
          panel('Scegli un Titolo', [
            for (final id in r.titleOffers)
              ListTile(
                title: Text(heroTitles.firstWhere((t) => t.id == id).name),
                subtitle: Text(
                  heroTitles.firstWhere((t) => t.id == id).description,
                ),
                onTap: () => act(() => r.chooseTitle(id)),
              ),
          ], open: true),
        if (!r.inCombat && r.cardOffers.isNotEmpty)
          panel('Scegli una carta', [
            for (final id in r.cardOffers)
              ListTile(
                title: Text(cardName(id)),
                subtitle: Text(cardEffect(id)),
                onTap: () => act(() => r.chooseCard(id)),
              ),
          ], open: true),
        if (!r.inCombat &&
            r.titleOffers.isEmpty &&
            r.cardOffers.isEmpty &&
            r.eventId.isNotEmpty)
          Wrap(
            children: [
              for (var i = 0; i < r.event.choices.length; i++)
                button(r.event.choices[i], () => r.choose(i)),
            ],
          ),
        if (!r.inCombat &&
            r.titleOffers.isEmpty &&
            r.cardOffers.isEmpty &&
            r.eventId.isEmpty) ...[
          Wrap(
            children: [
              for (final location in r.locations)
                button(
                  location,
                  () => r.travel(location),
                  icon: location == 'Dungeon'
                      ? Icons.door_front_door_outlined
                      : Icons.explore_outlined,
                ),
            ],
          ),
          button('Continua · prossima scena', r.nextScene),
          if (['Villaggio', 'Foresta'].contains(r.location))
            button(
              'Caccia · ${r.location == 'Foresta' ? 'carne e materiali' : 'Obser'}',
              r.startHunt,
            ),
          if (r.location == 'Villaggio') ...village(),
        ],
      ],
      panel('Borsa · ${r.obser} Obser · ${r.dust} Ascension Dust', inventory()),
      panel('Scheda · livello ${p.level} · ${p.points} punti disponibili', [
        actorSheet(p),
        Text('Potere d${p.powerDie} · Titolo ${p.titleLevel}/12'),
        Text('Arma: ${r.weapon} · +${r.weaponBonus} danno'),
        Text(
          'Destino ${r.destiny} · Tazza ${r.cup} · Follia ${r.madness} · Corruzione ${r.corruption}',
        ),
        for (final t in heroTitles.where((t) => r.titles.contains(t.id)))
          ListTile(title: Text(t.name), subtitle: Text(t.description)),
        for (final e in r.adaptation.entries)
          Text(
            '${e.key}: ${(e.value * 100).toStringAsFixed(2)}% adattamento (massimo ${OculusRules.adaptationCap * 100}%)',
          ),
      ]),
      panel('Quest e memorie', [
        for (final change in r.questHistory.reversed.take(3))
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text('Quest aggiornata: ${change['objective']}'),
            subtitle: Text('${change['reason']}'),
          ),
        for (final q in r.quests.entries)
          ListTile(
            leading: const Icon(Icons.radio_button_unchecked),
            title: Text(q.value),
          ),
        for (final q in r.completedQuests.values)
          ListTile(leading: const Icon(Icons.check), title: Text(q)),
        for (final a in r.achievements.where((a) => !a.startsWith('art_')))
          Text(a.replaceAll('_', ' ')),
        for (final npc in r.npcs.entries) Text('${npc.key}: ${npc.value}'),
      ]),
      skillAchievementsPanel(r.achievements),
      panel('Mazzo · potenziamenti', [
        for (final id in r.cards.keys)
          ListTile(
            title: Text('${cardName(id)} · Lv.${r.cards[id]}'),
            subtitle: Text(cardEffect(id)),
            trailing: IconButton(
              tooltip: 'Potenzia: ${OculusRules.upgradeCost} Dust',
              onPressed:
                  !r.inCombat &&
                      !r.finished &&
                      !r.pendingDeath &&
                      r.cards[id]! < 3 &&
                      r.dust >= OculusRules.upgradeCost
                  ? () => act(() => r.upgradeCard(id))
                  : null,
              icon: const Icon(Icons.upgrade),
            ),
          ),
      ]),
      panel('Diario e seed ${r.seed}', [
        for (final entry in r.journal.reversed.take(15))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(entry),
          ),
        button(
          'Salva adesso',
          () => unawaited(persist()),
          icon: Icons.save_outlined,
        ),
      ]),
    ];
  }

  Widget actorSheet(HeroActor a) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${a.kind == EntityKind.player
            ? 'PG'
            : a.kind == EntityKind.npc
            ? 'NPC'
            : 'Mostro'} · ${a.points} punti · ${a.dieSteps} aumenti dado',
      ),
      for (final k in OculusRules.stats)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$k d${a.dice[k]} +${a.stats[k]}'),
            button(
              '+1 Stat',
              a.points > 0 &&
                      !run!.inCombat &&
                      !run!.finished &&
                      !run!.pendingDeath
                  ? () => a.allocate(k)
                  : null,
            ),
            button(
              'Aumenta dado',
              a.dieSteps > 0 &&
                      a.dice[k]! < 20 &&
                      !run!.inCombat &&
                      !run!.finished &&
                      !run!.pendingDeath
                  ? () => a.advanceDie(k)
                  : null,
            ),
          ],
        ),
      button(
        'Assegnazione rapida',
        a.points + a.dieSteps > 0 &&
                !run!.inCombat &&
                !run!.finished &&
                !run!.pendingDeath
            ? a.quickAllocate
            : null,
      ),
    ],
  );
  List<Widget> combat() {
    final r = run!;
    return [
      Text(
        'Turno ${r.turn + 1} · ${r.actionsLeft} ${r.actionsLeft == 1 ? 'carta ancora giocabile' : 'carte ancora giocabili'}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      for (var i = 0; i < r.enemies.length; i++)
        Card(
          child: ListTile(
            selected: selectedTarget == i,
            title: Text(
              '${r.enemies[i].name} · Vita ${r.enemies[i].hp} · Scudo ${r.enemies[i].shield}',
            ),
            subtitle: Text(
              '${r.monster(r.enemies[i].id).description}\n${r.enemies[i].conditions.keys.join(', ')} · Isp. ${r.enemies[i].inspirations.join('/')}',
            ),
            onTap: r.enemies[i].hp > 0
                ? () => setState(() => selectedTarget = i)
                : null,
            trailing: IconButton(
              tooltip: 'Tecniche del nemico',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(r.enemies[i].name),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final skill
                            in heroMonsterTechniques[r
                                    .monster(r.enemies[i].id)
                                    .role] ??
                                <(String, String)>[])
                          ListTile(
                            title: Text(skill.$1),
                            subtitle: Text(skill.$2),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Chiudi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (r.pendingVictory || r.pendingEscape)
        button(
          r.pendingVictory ? 'Raccogli ricompense' : 'Conferma fuga',
          r.settleCombat,
        ),
      LayoutBuilder(
        builder: (context, constraints) {
          final deck = [
            for (final id in [...r.cards.keys, 'inspiration'])
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: card(id),
              ),
          ];
          return constraints.maxWidth < 600
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scorri le carte verso destra',
                      style: TextStyle(fontSize: 12),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: deck,
                      ),
                    ),
                  ],
                )
              : Wrap(children: deck);
        },
      ),
      const SizedBox(height: 10),
      Wrap(
        children: [
          button(
            'Termina turno',
            !r.pendingVictory && !r.pendingEscape ? r.endTurn : null,
          ),
          button(
            'Tenta fuga',
            !r.pendingVictory && !r.pendingEscape ? r.escape : null,
          ),
        ],
      ),
    ];
  }

  String cardName(String id) => id == 'attack'
      ? 'Attacca'
      : id == 'defend'
      ? 'Difenditi'
      : id == 'inspiration'
      ? 'Ispirazione'
      : heroSkills.where((s) => s.id == id).firstOrNull?.name ?? id;
  String cardEffect(String id) => id == 'attack'
      ? 'Attacco base Oculus. Tiro contrapposto.'
      : id == 'defend'
      ? 'La tua CM aumenta di +${OculusRules.defendCm + (run?.cards[id] ?? 0)}.'
      : id == 'inspiration'
      ? 'Annulla l’ultima azione e ritentala.'
      : heroSkills
                .where((s) => s.id == id)
                .firstOrNull
                ?.description(run?.cards[id] ?? 0) ??
            '';
  Widget card(String id) {
    final r = run!;
    final s = heroSkills.where((s) => s.id == id).firstOrNull;
    final color = switch (s?.resource) {
      'oculum' => Colors.purpleAccent,
      'volonta' => Colors.redAccent,
      'materia' => Colors.blueAccent,
      'vita' => Colors.greenAccent,
      _ => Colors.grey,
    };
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: r.canPlay(id) ? () => play(id) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cardName(id)}${r.cards.containsKey(id) ? ' · Lv.${r.cards[id]}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(cardEffect(id)),
            const SizedBox(height: 6),
            Text(
              s == null
                  ? id == 'inspiration'
                        ? '1 Ispirazione · non consuma azioni'
                        : 'Costo: 0'
                  : '${s.price(r.cards[id]!)} ${s.resource} · CD ${s.cd(r.cards[id]!)}',
            ),
            if ((r.cooldowns[id] ?? 0) > r.turn)
              Text('Disponibile tra ${r.cooldowns[id]! - r.turn} turni'),
            if (r.cardWarning(id).isNotEmpty)
              Text(
                r.cardWarning(id),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> village() => [
    panel('Villaggio · taverna e servizi', [
      for (final entry in heroFoods.entries)
        ListTile(
          title: Text(entry.key),
          subtitle: Text(
            '${entry.value.$1} Obser · +${entry.value.$4} ${entry.value.$2} · ${entry.value.$3}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.restaurant),
            tooltip: 'Mangia',
            onPressed: run!.obser >= entry.value.$1
                ? () => act(() => run!.eat(entry.key))
                : null,
          ),
        ),
      Wrap(
        children: [
          button(
            'Dormi · 2 Obser · solo notte',
            run!.night ? run!.sleep : null,
            icon: Icons.bed_outlined,
          ),
          button(
            'Guaritore · ${OculusRules.healCost} Obser',
            run!.healer,
            icon: Icons.healing,
          ),
          button('Parla con gli abitanti', run!.villageEvent),
        ],
      ),
      for (final e in const {
        'Benda improvvisata': 2,
        'Stivali da fuga': 6,
        'Mantello silente': 6,
        'Ferro opaco': 3,
      }.entries)
        button(
          '${e.key} · ${e.value} Obser',
          run!.obser >= e.value ? () => run!.buy(e.key) : null,
          icon: Icons.shopping_bag_outlined,
        ),
    ]),
  ];
  List<Widget> inventory() {
    final r = run!;
    return [
      for (final item in r.inventory.entries.where((e) => e.value > 0))
        ListTile(
          title: Text('${item.key} ×${item.value}'),
          subtitle: heroMinerals.containsKey(item.key)
              ? Text(
                  '${OculusRules.mineralCost} minerali → arma +${heroMinerals[item.key]} danno',
                )
              : item.key == 'Corna dell’Alce Cieco'
              ? const Text('Componente arma: +15 danno')
              : null,
          trailing: IconButton(
            tooltip: heroMinerals.containsKey(item.key)
                ? 'Potenzia arma'
                : 'Usa',
            icon: const Icon(Icons.touch_app_outlined),
            onPressed: r.finished || r.pendingDeath
                ? null
                : () => act(() {
                    if (heroMinerals.containsKey(item.key)) {
                      r.improveWeapon(item.key);
                    } else {
                      r.useItem(item.key);
                    }
                  }),
          ),
        ),
      button(
        'Crea benda · 1 Erba',
        !r.inCombat && !r.finished && (r.inventory['Erbe'] ?? 0) > 0
            ? r.craftBandage
            : null,
      ),
      for (final eye in r.eyes)
        panel(
          'Occhio dei Caduti · ${eye.actor.name} · ${['Comune', 'Non Comune', 'Raro', 'Oculum'][eye.rarity.index]}',
          [
            Text(
              'Sintonia ${eye.bond}/${OculusRules.maxBond} · Vita ${eye.actor.hp}/${eye.actor.maxHp} · ${eye.summoned ? 'Evocato' : 'Nella borsa'}',
            ),
            Text(
              'Reforge: ${eye.reforgeAttempts} tentativi · ${eye.failures} fallimenti consecutivi',
            ),
            actorSheet(eye.actor),
            for (final skill
                in (heroMonsterTechniques[r.monster(eye.sourceId).role] ??
                        <(String, String)>[])
                    .take(eye.rarity.index))
              ListTile(title: Text(skill.$1), subtitle: Text(skill.$2)),
            button(
              'Evoca',
              !r.finished && !r.pendingDeath && !r.inCombat && eye.actor.hp > 0
                  ? () {
                      final lastSummon = eye.lastSummon;
                      eye.summon(r.scene);
                      if (r.hasTitle('bond') && lastSummon != eye.lastSummon) {
                        eye.bond = min(OculusRules.maxBond, eye.bond + 1);
                      }
                    }
                  : null,
            ),
            OutlinedButton(
              onPressed:
                  !r.finished &&
                      !r.pendingDeath &&
                      !r.inCombat &&
                      r.dust > 0 &&
                      eye.bond < OculusRules.maxBond
                  ? () async {
                      final after = min(
                        OculusRules.maxBond,
                        eye.bond + OculusRules.dustBond,
                      );
                      if (await confirm(
                            'Ascension Dust',
                            'Possedute: ${r.dust}. Consuma 1 Dust: Sintonia ${eye.bond} → $after?',
                          ) &&
                          mounted) {
                        act(() => r.useDust(eye, 1));
                      }
                    }
                  : null,
              child: Text(
                '1 Dust → Sintonia ${min(OculusRules.maxBond, eye.bond + OculusRules.dustBond)}',
              ),
            ),
            if (eye.rarity != EyeRarity.oculum)
              OutlinedButton(
                onPressed:
                    !r.finished &&
                        !r.pendingDeath &&
                        !r.inCombat &&
                        r.dust >= OculusRules.reforgeCost(eye.rarity)
                    ? () async {
                        if (await confirm(
                              'Reforge',
                              '${['Comune', 'Non Comune', 'Raro', 'Oculum'][eye.rarity.index]} → ${['Comune', 'Non Comune', 'Raro', 'Oculum'][eye.rarity.index + 1]}\n${OculusRules.reforge[r.difficulty.index][eye.rarity.index]}% · ${OculusRules.reforgeCost(eye.rarity)} Dust anche in caso di fallimento. L’Occhio resta intatto.',
                            ) &&
                            mounted) {
                          act(() => r.reforge(eye));
                        }
                      }
                    : null,
                child: Text(
                  'Reforge · ${OculusRules.reforge[r.difficulty.index][eye.rarity.index]}% · ${OculusRules.reforgeCost(eye.rarity)} Dust',
                ),
              ),
          ],
        ),
    ];
  }

  void rules() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Oculus · regole del Cammino'),
      content: const SingleChildScrollView(
        child: Text(
          'Tiro: dado Stat + Potere + bonus. La progressione dei dadi è d4, d6, d8, d10, d12, d20.\n\nCritico contro il nemico: il tuo risultato è almeno il doppio del suo tiro contrapposto (14 contro 7).\n\nOgni turno consente 2 carte. Alcune carte aggiungono azioni; non possono creare un ciclo infinito. Puoi terminare il turno prima.\n\nSolo i PG tirano contro la morte: dado naturale di Volontà, senza bonus, Potere o Ispirazioni. Soglie: 8 / 10 / 12 / 15. Un dado troppo piccolo non può raggiungere la soglia.\n\nRinascita: Facile, tutte le Stats + Medicina; Medio, RES + VOL + Medicina; Difficile, RES + Medicina; Oculum, Medicina.\n\nTutti iniziano con 3 Ispirazioni, 2 Super e 1 Oculum. Ispirazione annulla solo l’ultima azione compatibile, prima di confermare ricompense o fuga.\n\nLa benda ferma Sanguinante, ma le azioni fisiche causano dolore. Una vera cura elimina il malus e dà +2 contro Sanguinante per 3 scene.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );
}

class HeroDieReadout extends StatelessWidget {
  const HeroDieReadout({super.key, required this.roll});
  final HeroRoll roll;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.casino_outlined, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(roll),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: Text(
              '${roll.label}: d${roll.faces} → ${roll.natural} naturale${roll.powerFaces > 0 ? ' · Potere d${roll.powerFaces} → ${roll.power} · bonus ${roll.bonus}' : ''} · finale ${roll.total}',
            ),
          ),
        ),
      ],
    ),
  );
}
