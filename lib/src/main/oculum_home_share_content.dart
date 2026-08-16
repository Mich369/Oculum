part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeShareContent on _OculumHomePageState {
  bool get haPermessiMaster =>
      realtimeIsMasterRole ||
      realtimeIsCoMasterRole ||
      modalitaMaster ||
      isMasterHost ||
      sonoCoMaster;

  void mostraSceltaRuoloSeNecessaria() {
    sceltaRuoloSessioneMostrata = true;
  }

  void mostraDialogSceltaRuolo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Entra nella sessione', 'Enter session'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallInfoText(
                t(
                  'Scegli se aprire la tua campagna come Master oppure entrare come giocatore. In una sessione deve esserci un solo Master; i Co-Master restano permessi delegati dal Master.',
                  'Choose whether to open your campaign as Master or enter as a player. A session must have only one Master; Co-Masters remain permissions delegated by the Master.',
                ),
                color: primaryColor,
              ),
              const SizedBox(height: 12),
              smallInfoText(
                t(
                  'La scelta Master abilita i pannelli e le note di sessione master locali. Hosting e relay si avviano comunque dalla pagina Online.',
                  'Master choice enables local master panels and session notes. Hosting and relay still start from the Online page.',
                ),
                color: tertiaryColor,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  modalitaMaster = false;
                  risultato = t(
                    'Ingresso come giocatore.',
                    'Entered as player.',
                  );
                  aggiungiLog(risultato);
                });
                programmaSalvataggio();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.person),
              label: Text(t('Giocatore', 'Player')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  modalitaMaster = true;
                  paginaCorrente = 9;
                  risultato = t(
                    'Modalita Master attiva per questa campagna.',
                    'Master mode enabled for this campaign.',
                  );
                  aggiungiLog(risultato);
                });
                programmaSalvataggio();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.admin_panel_settings),
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
              ),
              label: const Text('Master'),
            ),
          ],
        );
      },
    );
  }

  OculumTitle copiaTitolo(OculumTitle titolo) {
    return OculumTitle.fromJson(Map<String, dynamic>.from(titolo.toJson()));
  }

  CharacterSkill copiaSkill(CharacterSkill skill) {
    return CharacterSkill.fromJson(Map<String, dynamic>.from(skill.toJson()));
  }

  InventoryItem copiaOggetto(InventoryItem item) {
    return InventoryItem.fromJson(Map<String, dynamic>.from(item.toJson()));
  }

  CharacterArt copiaArt(CharacterArt art) {
    return CharacterArt.fromJson(Map<String, dynamic>.from(art.toJson()));
  }

  List<Map<String, dynamic>> _sheetMapList(int sheetIndex, String key) {
    final source = sheetIndex == schedaCorrente
        ? statoCorrenteJson()[key]
        : schedePersonaggio[sheetIndex][key];
    if (source is! List) return <Map<String, dynamic>>[];
    return source
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  List<int> _defaultContentTargets() {
    final indexes = List<int>.generate(
      schedePersonaggio.length,
      (i) => i,
    ).where((i) => i != schedaCorrente).toList();
    return indexes.isEmpty ? <int>[schedaCorrente] : indexes;
  }

  Widget _sheetTargetSelector(
    Set<int> selected,
    void Function(void Function()) setDialogState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Invia a schede', 'Send to sheets'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < schedePersonaggio.length; i++)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: tertiaryColor,
            value: selected.contains(i),
            title: Text(
              '${i + 1}. ${nomeSchedaPersonaggio(i)}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              i == schedaCorrente
                  ? t('copia nella scheda aperta', 'copy into open sheet')
                  : tipoSchedaPersonaggio(i),
              style: const TextStyle(color: Colors.white70),
            ),
            onChanged: (value) {
              setDialogState(() {
                if (value == true) {
                  selected.add(i);
                } else {
                  selected.remove(i);
                }
              });
            },
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _updatedRawList(
    Map<String, dynamic> sheet,
    String key,
  ) {
    final raw = sheet[key];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  Future<void> _afterContentSent(String label, Set<int> targets) async {
    setState(() {
      risultato = t(
        '$label copiato/inviato a ${targets.length} scheda/e.',
        '$label copied/sent to ${targets.length} sheet(s).',
      );
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  Future<void> _sendTitleToTargets(OculumTitle edited, Set<int> targets) async {
    if (targets.isEmpty) return;

    setState(() {
      for (final target in targets) {
        final copy = copiaTitolo(edited);
        if (target == schedaCorrente) {
          titoli.add(copy);
          if (copy.equipaggiato) {
            applicaBonusTitoloAttuali(copy, 1);
          }
        } else {
          final sheet = schedePersonaggio[target];
          final list = _updatedRawList(sheet, 'titoli');
          list.add(copy.toJson());
          sheet['titoli'] = list;
        }
      }
    });

    await _afterContentSent(t('Titolo', 'Title'), targets);
  }

  Future<void> _sendSkillToTargets(
    CharacterSkill edited,
    Set<int> targets,
  ) async {
    if (targets.isEmpty) return;

    setState(() {
      for (final target in targets) {
        final copy = copiaSkill(edited);
        if (target == schedaCorrente) {
          skills.add(copy);
          if (copy.equipaggiata) {
            applicaBonusSkillAttuali(copy, 1);
          }
        } else {
          final sheet = schedePersonaggio[target];
          final list = _updatedRawList(sheet, 'skills');
          list.add(copy.toJson());
          sheet['skills'] = list;
        }
      }
    });

    await _afterContentSent(t('Skill', 'Skill'), targets);
  }

  Future<void> _sendItemToTargets(
    InventoryItem edited,
    Set<int> targets,
  ) async {
    if (targets.isEmpty) return;

    setState(() {
      for (final target in targets) {
        final copy = copiaOggetto(edited);
        if (target == schedaCorrente) {
          inventario.add(copy);
          if (copy.equipaggiata) applicaScudoItemAttuale(copy, 1);
        } else {
          final sheet = schedePersonaggio[target];
          final list = _updatedRawList(sheet, 'inventario');
          list.add(copy.toJson());
          sheet['inventario'] = list;
        }
      }
    });

    await _afterContentSent(t('Oggetto', 'Item'), targets);
  }

  Future<void> _sendArtToTargets(CharacterArt edited, Set<int> targets) async {
    if (targets.isEmpty) return;

    setState(() {
      for (final target in targets) {
        final copy = copiaArt(edited);
        if (target == schedaCorrente) {
          arti.add(copy);
          if (copy.sbloccata) {
            for (final skill in copy.skills) {
              if (skill.livello > 0) {
                applicaBonusArtSkillAttuali(skill, artSkillBonusLevel(skill));
              }
            }
          }
        } else {
          final sheet = schedePersonaggio[target];
          final list = _updatedRawList(sheet, 'arti');
          list.add(copy.toJson());
          sheet['arti'] = list;
        }
      }
    });

    await _afterContentSent(t('Art', 'Art'), targets);
  }

  Future<void> mostraDialogCopiaTitolo(OculumTitle source) async {
    final edited = copiaTitolo(source);
    final targets = _defaultContentTargets().toSet();
    final nome = TextEditingController(text: edited.nome);
    final tipo = TextEditingController(text: edited.tipo);
    final ottenimento = TextEditingController(text: edited.ottenimento);
    final leggenda = TextEditingController(text: edited.leggenda);
    final buff = TextEditingController(text: edited.buff);
    final skill = TextEditingController(text: edited.skill);
    final res = TextEditingController(text: '${edited.resilienza}');
    final vol = TextEditingController(text: '${edited.volonta}');
    final mat = TextEditingController(text: '${edited.materia}');
    final ocu = TextEditingController(text: '${edited.oculum}');
    final karma = TextEditingController(text: '${edited.karma}');
    var equipped = false;
    var openActive = edited.openAttiva;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF10121A),
                title: Text(
                  t('Copia / invia Titolo', 'Copy / send Title'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        campoTesto(
                          label: t('Nome Titolo', 'Title Name'),
                          controller: nome,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Tipo', 'Type'),
                          controller: tipo,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Ottenimento', 'Obtained'),
                          controller: ottenimento,
                          numero: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Leggenda', 'Legend'),
                          controller: leggenda,
                          numero: false,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Buff', 'Buff'),
                          controller: buff,
                          numero: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Skill aggiunta', 'Added Skill'),
                          controller: skill,
                          numero: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: '+ RES',
                                controller: res,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: '+ VOL',
                                controller: vol,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: '+ MAT',
                                controller: mat,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: '+ OCU',
                                controller: ocu,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        campoTesto(label: 'Karma', controller: karma),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: equipped,
                          activeThumbColor: tertiaryColor,
                          title: Text(
                            t('Arriva equipaggiato', 'Arrives equipped'),
                          ),
                          onChanged: (value) {
                            setDialogState(() => equipped = value);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: openActive,
                          activeThumbColor: tertiaryColor,
                          title: Text(t('Open attiva', 'Open active')),
                          onChanged: edited.evoluto
                              ? (value) {
                                  setDialogState(() => openActive = value);
                                }
                              : null,
                        ),
                        const Divider(color: Colors.white24),
                        _sheetTargetSelector(targets, setDialogState),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: targets.isEmpty
                        ? null
                        : () async {
                            edited
                              ..nome = nome.text.trim().isEmpty
                                  ? source.nome
                                  : nome.text.trim()
                              ..tipo = tipo.text.trim()
                              ..ottenimento = ottenimento.text.trim()
                              ..leggenda = leggenda.text.trim()
                              ..buff = buff.text.trim()
                              ..skill = skill.text.trim()
                              ..resilienza = readIntValue(res.text)
                              ..volonta = readIntValue(vol.text)
                              ..materia = readIntValue(mat.text)
                              ..oculum = readIntValue(ocu.text)
                              ..karma = readIntValue(karma.text)
                              ..equipaggiato = equipped
                              ..openAttiva = openActive;
                            Navigator.pop(context);
                            await _sendTitleToTargets(edited, targets);
                          },
                    icon: const Icon(Icons.send),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(t('Invia copia', 'Send copy')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nome.dispose();
      tipo.dispose();
      ottenimento.dispose();
      leggenda.dispose();
      buff.dispose();
      skill.dispose();
      res.dispose();
      vol.dispose();
      mat.dispose();
      ocu.dispose();
      karma.dispose();
    }
  }

  Future<void> mostraDialogCopiaSkill(CharacterSkill source) async {
    final edited = copiaSkill(source);
    final targets = _defaultContentTargets().toSet();
    final nome = TextEditingController(text: edited.nome);
    final tipo = TextEditingController(text: edited.tipo);
    final costo = TextEditingController(text: edited.costo);
    final cooldown = TextEditingController(text: edited.cooldown);
    final descrizione = TextEditingController(text: edited.descrizione);
    final res = TextEditingController(text: '${edited.resilienza}');
    final vol = TextEditingController(text: '${edited.volonta}');
    final mat = TextEditingController(text: '${edited.materia}');
    final ocu = TextEditingController(text: '${edited.oculum}');
    final danni = TextEditingController(text: '${edited.danni}');
    final difesa = TextEditingController(text: '${edited.difesa}');
    var equipped = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF10121A),
                title: Text(
                  t('Copia / invia Skill', 'Copy / send Skill'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        campoTesto(
                          label: t('Nome Skill', 'Skill Name'),
                          controller: nome,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Tipo Skill', 'Skill Type'),
                          controller: tipo,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: t('Costo', 'Cost'),
                                controller: costo,
                                numero: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: 'Cooldown',
                                controller: cooldown,
                                numero: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Descrizione Skill', 'Skill Description'),
                          controller: descrizione,
                          numero: false,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: '+ RES',
                                controller: res,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: '+ VOL',
                                controller: vol,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: '+ MAT',
                                controller: mat,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: '+ OCU',
                                controller: ocu,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: t('Danni +', 'Damage +'),
                                controller: danni,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: t('Difesa +', 'Defense +'),
                                controller: difesa,
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: equipped,
                          activeThumbColor: tertiaryColor,
                          title: Text(
                            t('Arriva equipaggiata', 'Arrives equipped'),
                          ),
                          onChanged: (value) {
                            setDialogState(() => equipped = value);
                          },
                        ),
                        const Divider(color: Colors.white24),
                        _sheetTargetSelector(targets, setDialogState),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: targets.isEmpty
                        ? null
                        : () async {
                            edited
                              ..nome = nome.text.trim().isEmpty
                                  ? source.nome
                                  : nome.text.trim()
                              ..tipo = tipo.text.trim()
                              ..costo = costo.text.trim()
                              ..cooldown = cooldown.text.trim()
                              ..descrizione = descrizione.text.trim()
                              ..resilienza = readIntValue(res.text)
                              ..volonta = readIntValue(vol.text)
                              ..materia = readIntValue(mat.text)
                              ..oculum = readIntValue(ocu.text)
                              ..danni = readIntValue(danni.text)
                              ..difesa = readIntValue(difesa.text)
                              ..equipaggiata = equipped;
                            Navigator.pop(context);
                            await _sendSkillToTargets(edited, targets);
                          },
                    icon: const Icon(Icons.send),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(t('Invia copia', 'Send copy')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nome.dispose();
      tipo.dispose();
      costo.dispose();
      cooldown.dispose();
      descrizione.dispose();
      res.dispose();
      vol.dispose();
      mat.dispose();
      ocu.dispose();
      danni.dispose();
      difesa.dispose();
    }
  }

  Future<void> mostraDialogCopiaOggetto(InventoryItem source) async {
    final edited = copiaOggetto(source);
    final targets = _defaultContentTargets().toSet();
    final nome = TextEditingController(text: edited.nome);
    final peso = TextEditingController(text: '${edited.peso}');
    final quantita = TextEditingController(text: '${edited.quantita}');
    final bonusDanno = TextEditingController(text: '${edited.bonusDanno}');
    final bonusDifesa = TextEditingController(text: '${edited.bonusDifesa}');
    final bonusScudo = TextEditingController(text: '${edited.bonusScudo}');
    final bonusScudoOculum = TextEditingController(
      text: '${edited.bonusScudoOculum}',
    );
    final elemento = TextEditingController(text: edited.elementoDanno);
    final buff = TextEditingController(text: edited.buff);
    final note = TextEditingController(text: edited.note);
    var weapon = edited.arma;
    var protects = edited.protegge;
    var equipped = edited.equipaggiata;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF10121A),
                title: Text(
                  t('Copia / invia Oggetto', 'Copy / send Item'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        campoTesto(
                          label: t('Nome Oggetto', 'Item Name'),
                          controller: nome,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: t('Peso kg', 'Weight kg'),
                                controller: peso,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: t('Quantita', 'Quantity'),
                                controller: quantita,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Bonus Scudo Oculum', 'Oculum Shield Bonus'),
                          controller: bonusScudoOculum,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Bonus Danno', 'Damage Bonus'),
                          controller: bonusDanno,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: campoTesto(
                                label: t('Bonus Difesa', 'Defense Bonus'),
                                controller: bonusDifesa,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: campoTesto(
                                label: t('Bonus Scudo', 'Shield Bonus'),
                                controller: bonusScudo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t(
                            'Tipo danno / protezione',
                            'Damage / protection type',
                          ),
                          controller: elemento,
                          numero: false,
                          enableCommandAutocomplete: true,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Buff @ Oggetto', 'Item @ Buff'),
                          controller: buff,
                          numero: false,
                          maxLines: 2,
                          helper:
                              '@HP+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5',
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Note', 'Notes'),
                          controller: note,
                          numero: false,
                          maxLines: 3,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: weapon,
                          activeThumbColor: tertiaryColor,
                          title: Text(t('Danneggia', 'Deals damage')),
                          onChanged: (value) {
                            setDialogState(() {
                              weapon = value;
                              if (!weapon &&
                                  !protects &&
                                  buff.text.trim().isEmpty) {
                                equipped = false;
                              }
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: protects,
                          activeThumbColor: primaryColor,
                          title: Text(t('Protegge', 'Protects')),
                          onChanged: (value) {
                            setDialogState(() {
                              protects = value;
                              if (!weapon &&
                                  !protects &&
                                  buff.text.trim().isEmpty) {
                                equipped = false;
                              }
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: equipped,
                          activeThumbColor: tertiaryColor,
                          title: Text(
                            t('Arriva equipaggiata', 'Arrives equipped'),
                          ),
                          onChanged: (value) {
                            setDialogState(() => equipped = value);
                          },
                        ),
                        const Divider(color: Colors.white24),
                        _sheetTargetSelector(targets, setDialogState),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: targets.isEmpty
                        ? null
                        : () async {
                            edited
                              ..nome = nome.text.trim().isEmpty
                                  ? source.nome
                                  : nome.text.trim()
                              ..peso = readDoubleValue(peso.text)
                              ..quantita = max(
                                1,
                                readIntValue(quantita.text, fallback: 1),
                              )
                              ..bonusDanno = readIntValue(bonusDanno.text)
                              ..bonusDifesa = readIntValue(bonusDifesa.text)
                              ..bonusScudo = readIntValue(bonusScudo.text)
                              ..bonusScudoOculum = max(
                                0,
                                readIntValue(bonusScudoOculum.text),
                              )
                              ..elementoDanno = elemento.text.trim().isEmpty
                                  ? 'Fisico'
                                  : elemento.text.trim()
                              ..buff = buff.text.trim()
                              ..note = note.text.trim()
                              ..arma = weapon
                              ..protegge = protects
                              ..equipaggiata = equipped;
                            Navigator.pop(context);
                            await _sendItemToTargets(edited, targets);
                          },
                    icon: const Icon(Icons.send),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(t('Invia copia', 'Send copy')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nome.dispose();
      peso.dispose();
      quantita.dispose();
      bonusDanno.dispose();
      bonusDifesa.dispose();
      bonusScudo.dispose();
      bonusScudoOculum.dispose();
      elemento.dispose();
      buff.dispose();
      note.dispose();
    }
  }

  Future<void> mostraDialogCopiaArt(CharacterArt source) async {
    final edited = copiaArt(source);
    final targets = _defaultContentTargets().toSet();
    final nome = TextEditingController(text: edited.nome);
    final tipo = TextEditingController(text: edited.tipo);
    final descrizione = TextEditingController(text: edited.descrizione);
    final skillNames = [
      for (final skill in edited.skills)
        TextEditingController(text: skill.nome),
    ];
    final skillLevels = [
      for (final skill in edited.skills)
        TextEditingController(text: '${skill.livello}'),
    ];
    var unlocked = edited.sbloccata;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF10121A),
                title: Text(
                  t('Copia / invia Art', 'Copy / send Art'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        campoTesto(
                          label: t('Nome Art', 'Art Name'),
                          controller: nome,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Tipo Art', 'Art Type'),
                          controller: tipo,
                          numero: false,
                        ),
                        const SizedBox(height: 8),
                        campoTesto(
                          label: t('Descrizione Art', 'Art Description'),
                          controller: descrizione,
                          numero: false,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: unlocked,
                          activeThumbColor: tertiaryColor,
                          title: Text(
                            t('Arriva sbloccata', 'Arrives unlocked'),
                          ),
                          onChanged: (value) {
                            setDialogState(() => unlocked = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < skillNames.length; i++) ...[
                          Text(
                            '${t('Skill', 'Skill')} ${i + 1}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          campoTesto(
                            label: t('Nome Skill', 'Skill Name'),
                            controller: skillNames[i],
                            numero: false,
                          ),
                          const SizedBox(height: 6),
                          campoTesto(
                            label: t('Livello Skill', 'Skill Level'),
                            controller: skillLevels[i],
                          ),
                          const SizedBox(height: 10),
                        ],
                        smallInfoText(
                          t(
                            'I bonus delle Skill Art copiate valgono solo se la Art e sbloccata e la singola Skill ha livello almeno 1.',
                            'Copied Art Skill bonuses count only if the Art is unlocked and that Skill is at least level 1.',
                          ),
                          color: tertiaryColor,
                        ),
                        const Divider(color: Colors.white24),
                        _sheetTargetSelector(targets, setDialogState),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: targets.isEmpty
                        ? null
                        : () async {
                            edited
                              ..nome = nome.text.trim().isEmpty
                                  ? source.nome
                                  : nome.text.trim()
                              ..tipo = tipo.text.trim()
                              ..descrizione = descrizione.text.trim()
                              ..sbloccata = unlocked;
                            final maxSkillLevel = artMaxLevel(edited);
                            for (int i = 0; i < edited.skills.length; i++) {
                              edited.skills[i].nome = skillNames[i].text.trim();
                              edited.skills[i].livello = readIntValue(
                                skillLevels[i].text,
                              ).clamp(0, maxSkillLevel).toInt();
                            }
                            Navigator.pop(context);
                            await _sendArtToTargets(edited, targets);
                          },
                    icon: const Icon(Icons.send),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(t('Invia copia', 'Send copy')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nome.dispose();
      tipo.dispose();
      descrizione.dispose();
      for (final controller in skillNames) {
        controller.dispose();
      }
      for (final controller in skillLevels) {
        controller.dispose();
      }
    }
  }

  String _namesSummary(List<String> names, String empty) {
    final clean = names.where((x) => x.trim().isNotEmpty).toList();
    if (clean.isEmpty) return empty;
    final visible = clean.take(3).join(', ');
    final extra = clean.length > 3 ? ' +${clean.length - 3}' : '';
    return '$visible$extra';
  }

  String activeTitlesSummaryForSheet(int index) {
    final titles = _sheetMapList(index, 'titoli')
        .map(OculumTitle.fromJson)
        .where((title) => title.equipaggiato)
        .map((title) {
          final open = title.openAttiva ? ' / Open' : '';
          return '${title.nome}$open';
        })
        .toList();
    return _namesSummary(titles, t('Nessun titolo attivo', 'No active title'));
  }

  String activeSkillsSummaryForSheet(int index) {
    final active = _sheetMapList(index, 'skills')
        .map(CharacterSkill.fromJson)
        .where((skill) => skill.equipaggiata)
        .map((skill) => skill.nome)
        .toList();
    return _namesSummary(active, t('Nessuna skill attiva', 'No active skill'));
  }

  String artsSummaryForSheet(int index) {
    final active = _sheetMapList(index, 'arti')
        .map(CharacterArt.fromJson)
        .where((art) => art.sbloccata)
        .map((art) {
          final levels = art.skills.map((skill) => skill.livello).join('/');
          return '${art.nome} [$levels]';
        })
        .toList();
    return _namesSummary(active, t('Nessuna Art attiva', 'No active Art'));
  }

  Widget masterSheetMiniSummary(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallInfoText(
          '${t('Titoli attivi', 'Active titles')}: ${activeTitlesSummaryForSheet(index)}',
          color: tertiaryColor,
        ),
        const SizedBox(height: 4),
        smallInfoText(
          '${t('Skill attive', 'Active skills')}: ${activeSkillsSummaryForSheet(index)}',
        ),
        const SizedBox(height: 4),
        smallInfoText(
          '${t('Art attive', 'Active Arts')}: ${artsSummaryForSheet(index)}',
        ),
        const SizedBox(height: 8),
        artQuickUnlockButtonsForSheet(index),
      ],
    );
  }

  Widget artQuickUnlockButtonsForSheet(int index) {
    final maps = _sheetMapList(index, 'arti');
    if (maps.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (int i = 0; i < min(4, maps.length); i++)
          FilterChip(
            selected: readBoolValue(maps[i]['sbloccata'], fallback: true),
            showCheckmark: false,
            avatar: Icon(
              readBoolValue(maps[i]['sbloccata'], fallback: true)
                  ? Icons.lock_open
                  : Icons.lock_outline,
              size: 15,
            ),
            label: Text(
              '${maps[i]['nome'] ?? 'Art ${i + 1}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selectedColor: tertiaryColor.withValues(alpha: 0.24),
            backgroundColor: Colors.black26,
            side: BorderSide(color: primaryColor.withValues(alpha: 0.45)),
            labelStyle: TextStyle(
              color: readBoolValue(maps[i]['sbloccata'], fallback: true)
                  ? tertiaryColor
                  : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (value) => cambiaSbloccoArtScheda(index, i, value),
          ),
      ],
    );
  }

  Future<void> cambiaSbloccoArtScheda(
    int sheetIndex,
    int artIndex,
    bool unlocked,
  ) async {
    if (sheetIndex < 0 || sheetIndex >= schedePersonaggio.length) return;

    if (sheetIndex == schedaCorrente) {
      cambiaSbloccoArt(artIndex, unlocked);
      return;
    }

    setState(() {
      final sheet = schedePersonaggio[sheetIndex];
      final list = _updatedRawList(sheet, 'arti');
      while (list.length < artiBase().length) {
        list.add(artiBase()[list.length].toJson());
      }
      if (artIndex < 0 || artIndex >= list.length) return;
      list[artIndex]['sbloccata'] = unlocked;
      sheet['arti'] = list;
      risultato =
          '${nomeSchedaPersonaggio(sheetIndex)}: ${list[artIndex]['nome'] ?? 'Art'} ${unlocked ? 'sbloccata' : 'bloccata'}.';
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  int connectedSheetIntValue(Map<String, dynamic> sheet, String key) {
    final currentKey = switch (key) {
      'resilienza' => 'currentResilienza',
      'volonta' => 'currentVolonta',
      'materia' => 'currentMateria',
      'oculum' => 'currentOculum',
      _ => key,
    };
    return readIntValue(sheet[currentKey], fallback: readIntValue(sheet[key]));
  }

  int connectedSheetRollBonus(Map<String, dynamic> sheet, String key) {
    final derivedField = switch (key) {
      'vc' => 'derivedVC',
      'cm' => 'derivedCM',
      'iniziativa' => 'derivedIniziativa',
      _ => '',
    };
    if (derivedField.isNotEmpty && sheet.containsKey(derivedField)) {
      return readIntValue(sheet[derivedField]);
    }

    final levelGrade =
        readIntValue(sheet['livello']) + readIntValue(sheet['grado']) * 6;
    switch (key) {
      case 'vc':
        return levelGrade +
            connectedSheetIntValue(sheet, 'volonta') ~/ 3 +
            readIntValue(sheet['attaccoRapido']);
      case 'cm':
        return levelGrade +
            connectedSheetIntValue(sheet, 'materia') ~/ 2 +
            readIntValue(sheet['cmRapido']);
      case 'iniziativa':
        return levelGrade + connectedSheetIntValue(sheet, 'materia') ~/ 5;
      default:
        return connectedSheetIntValue(sheet, key) ~/ 2 + levelGrade;
    }
  }

  void tiraSchedaConnessa(Map<String, dynamic> sheet, String key) {
    final dado = tiraD20();
    final bonus = connectedSheetRollBonus(sheet, key);
    final level = max(0, readIntValue(sheet['livello']));
    final grade = max(0, readIntValue(sheet['grado']));
    final difficulty = readIntValue(sheet['difficoltaTiro']);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
    );
    final nome = '${sheet['nome'] ?? sheet['name'] ?? '???'}';
    final label = sheetRollLabel(key);

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 20;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 20;
      risultato = '$nome - $label: $testoDado';
      aggiungiLog('Tiro scheda connessa $nome [$label]: $testoDado.');
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
  }

  Widget connectedSheetQuickRolls(Map<String, dynamic> sheet) {
    final rolls = [
      ('resilienza', 'RES'),
      ('volonta', 'VOL'),
      ('materia', 'MAT'),
      ('oculum', 'OCU'),
      ('vc', 'VC'),
      ('cm', 'CM'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final roll in rolls)
          OutlinedButton(
            onPressed: () => tiraSchedaConnessa(sheet, roll.$1),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 34),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              roll.$2,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Future<void> apriSchedaConnessa(Map<String, dynamic> sheet) async {
    final id = '${sheet['id'] ?? sheet['sheetTag'] ?? ''}'.trim();
    if (id.isEmpty) return;

    salvaSchedaCorrenteInMemoria();
    final imported = preparaSchedeImportateUniche(<Map<String, dynamic>>[
      normalizzaSchedaImportata(sheet),
    ]).single;
    imported['inMasterParty'] = true;
    var targetIndex = -1;

    setState(() {
      schedePersonaggio.add(imported);
      assicuraTagSchede();
      targetIndex = schedePersonaggio.length - 1;
      risultato = t(
        'Scheda connessa importata come nuova copia: ${nomeSchedaPersonaggio(targetIndex)}. Le schede locali esistenti non sono state sovrascritte.',
        'Connected sheet imported as a new copy: ${nomeSchedaPersonaggio(targetIndex)}. Existing local sheets were not overwritten.',
      );
      aggiungiLog(risultato);
    });

    await salvaDati();
    await apriSchedaDaParty(targetIndex);
  }

  Widget connectedSheetCard(Map<String, dynamic> sheet) {
    final name = '${sheet['nome'] ?? sheet['name'] ?? '???'}';
    final id = '${sheet['id'] ?? sheet['sheetTag'] ?? ''}'.trim();
    return gothicPanel(
      borderColor: Colors.lightBlueAccent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cable, color: Colors.lightBlueAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (id.isNotEmpty)
                Text(
                  id,
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            'HP ${connectedSheetIntValue(sheet, 'currentHp')} - OCU ${connectedSheetIntValue(sheet, 'oculum')} - Lv ${readIntValue(sheet['livello'])} - Gr ${readIntValue(sheet['grado'])}',
          ),
          const SizedBox(height: 10),
          connectedSheetQuickRolls(sheet),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: id.isEmpty ? null : () => apriSchedaConnessa(sheet),
            icon: const Icon(Icons.open_in_new),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: primaryColor,
            ),
            label: Text(t('Apri / importa scheda', 'Open / import sheet')),
          ),
        ],
      ),
    );
  }

  Widget connectedSheetsPanel() {
    final connected = partyMembri
        .where(
          (member) =>
              '${member['id'] ?? member['sheetTag'] ?? ''}'.trim().isNotEmpty,
        )
        .map((member) => Map<String, dynamic>.from(member))
        .toList();

    if (connected.isEmpty) return const SizedBox.shrink();

    return gothicPanel(
      borderColor: Colors.lightBlueAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Schede connesse', 'Connected sheets'),
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Schede arrivate dalla sessione online/locale. Puoi tirare subito o importarle tra le schede della campagna.',
              'Sheets received from the online/local session. You can roll immediately or import them into the campaign sheets.',
            ),
          ),
          const SizedBox(height: 10),
          for (final sheet in connected) connectedSheetCard(sheet),
        ],
      ),
    );
  }
}
