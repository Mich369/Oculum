part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeDialogsQuickEdit on _OculumHomePageState {
  void _openDungeonMiniGame({
    bool openOnlinePanel = false,
    Map<String, dynamic>? initialOnlineSession,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return OculumDungeonGameDialog(
          linguaInglese: linguaInglese,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          tertiaryColor: tertiaryColor,
          playerName: nomeController.text.trim().isEmpty
              ? '???'
              : nomeController.text.trim(),
          playerMaxHp: maxHp(),
          playerVc: vc(),
          playerCm: cm(),
          playerDefense: difesa(),
          playerDamage: dannoTotale(),
          playerInitiative: iniziativa(),
          playerLevel: leggiNumero(livelloController),
          playerGrade: leggiNumero(gradoController),
          onReward: ({int obser = 0, int ascensionDust = 0, String? log}) {
            setState(() {
              if (log != null && log.trim().isNotEmpty) {
                aggiungiLog(
                  '$log Risorse dungeon separate dalla scheda ufficiale.',
                );
              }
            });

            programmaSalvataggio();
          },
          onThemeUnlocked: unlockColorThemeFromDungeon,
          initialUnlockedThemePresetIds: [
            for (final preset in orderedColorPresets())
              if (isColorThemeUnlocked(preset.id)) preset.id,
          ],
          availableThemeUnlocks: [
            for (final preset in orderedColorPresets())
              if (preset.id != 'classic_reliquary' &&
                  !oculumThemeStartsUnlocked(preset.id))
                {
                  'id': preset.id,
                  'nameIt': preset.nameIt,
                  'nameEn': preset.nameEn,
                  'color': preset.tertiary,
                },
          ],
          hoshyLevelFiveUnlocked: schedePersonaggio.any((sheet) {
            final name = cleanUiText(
              '${sheet['nome'] ?? ''}',
            ).trim().toLowerCase();
            return name == 'hoshy' && readIntValue(sheet['livello']) >= 5;
          }),
          hiresSheetAvailable: schedePersonaggio.any((sheet) {
            final name = cleanUiText(
              '${sheet['nome'] ?? ''}',
            ).trim().toLowerCase();
            return name == 'hires';
          }),
          hiresLevelFiveAvailable: schedePersonaggio.any((sheet) {
            final name = cleanUiText(
              '${sheet['nome'] ?? ''}',
            ).trim().toLowerCase();
            return name == 'hires' && readIntValue(sheet['livello']) >= 5;
          }),
          openOnlinePanelInitially: openOnlinePanel,
          initialOnlineSession: initialOnlineSession,
          realtimeBridge: OculumDungeonRealtimeBridge(
            isConnected: () => realtimeService?.isConnected == true,
            localPlayerId: () {
              final tag = sheetTagAt(schedaCorrente).trim();
              return tag.isEmpty ? realtimeDisplayName() : tag;
            },
            playerIds: () => <String>{
              sheetTagAt(schedaCorrente),
              ...realtimeUsers.map(
                (user) =>
                    '${user['activeSheetTag'] ?? user['playerName'] ?? ''}',
              ),
            }.where((id) => id.trim().isNotEmpty).toList(),
            send: (payload) {
              final service = realtimeService;
              if (service?.isConnected != true) return;
              unawaited(
                service!.sendDungeonShared(<String, dynamic>{
                  ...payload,
                  'campaignId': activeCampaignId,
                  'campaignName': activeCampaignName(),
                }),
              );
            },
            messages: realtimeDungeonMessage,
          ),
        );
      },
    );
  }

  List<OculumQuickEditSection> quickEditSections() {
    syncVisibleCurrentStatEditors();
    return [
      OculumQuickEditSection(
        title: t('Identità', 'Identity'),
        entries: [
          OculumQuickEditEntry(
            label: t('Nome Scheda', 'Sheet Name'),
            controller: nomeController,
            isNumber: false,
          ),
          OculumQuickEditEntry(
            label: t('Tipo Scheda', 'Sheet Type'),
            controller: tipoSchedaController,
            isNumber: false,
          ),
          OculumQuickEditEntry(
            label: t('Razza visibile', 'Visible race'),
            controller: razzaController,
            isNumber: false,
          ),
          OculumQuickEditEntry(
            label: t('Livello', 'Level'),
            controller: livelloController,
          ),
          OculumQuickEditEntry(
            label: t('Grado', 'Grade'),
            controller: gradoController,
          ),
          OculumQuickEditEntry(label: 'EXP', controller: expController),
        ],
      ),
      OculumQuickEditSection(
        title: t('Statistiche Base', 'Base Stats'),
        entries: [
          OculumQuickEditEntry(
            label: t('Resilienza Base', 'Base Resilience'),
            controller: resilienzaController,
          ),
          OculumQuickEditEntry(
            label: t('Volontà Base', 'Base Will'),
            controller: volontaController,
          ),
          OculumQuickEditEntry(
            label: 'Materia Base',
            controller: materiaController,
          ),
          OculumQuickEditEntry(
            label: 'Oculum Base',
            controller: oculumController,
          ),
        ],
      ),
      OculumQuickEditSection(
        title: t('Statistiche Attuali', 'Current Stats'),
        entries: [
          OculumQuickEditEntry(
            label: t('Resilienza Attuale', 'Current Resilience'),
            controller: visibleCurrentResilienzaController,
            onChanged: (value) =>
                setCurrentStatFromVisibleInput('resilienza', value),
          ),
          OculumQuickEditEntry(
            label: t('Volontà Attuale', 'Current Will'),
            controller: visibleCurrentVolontaController,
            onChanged: (value) =>
                setCurrentStatFromVisibleInput('volonta', value),
          ),
          OculumQuickEditEntry(
            label: t('Materia Attuale', 'Current Materia'),
            controller: visibleCurrentMateriaController,
            onChanged: (value) =>
                setCurrentStatFromVisibleInput('materia', value),
          ),
          OculumQuickEditEntry(
            label: t('Oculum Attuale', 'Current Oculum'),
            controller: visibleCurrentOculumController,
            onChanged: (value) =>
                setCurrentStatFromVisibleInput('oculum', value),
          ),
        ],
      ),
      OculumQuickEditSection(
        title: t('Vita e Protezioni', 'Health and Protections'),
        entries: [
          OculumQuickEditEntry(
            label: t('HP Attuali', 'Current HP'),
            controller: currentHpController,
          ),
          OculumQuickEditEntry(
            label: t('HP Temporanei', 'Temporary HP'),
            controller: hpTempController,
          ),
          OculumQuickEditEntry(
            label: t('Scudo', 'Shield'),
            controller: scudoController,
          ),
          OculumQuickEditEntry(
            label: t('Scudo Critico', 'Critical Shield'),
            controller: scudoCriticoController,
          ),
          OculumQuickEditEntry(
            label: 'Scudo Oculum',
            controller: scudoOculumController,
          ),
          OculumQuickEditEntry(
            label: t('Massimo Scudo Oculum', 'Max Oculum Shield'),
            controller: scudoOculumMaxController,
          ),
        ],
      ),
      OculumQuickEditSection(
        title: t('Attacco e Difesa', 'Attack and Defense'),
        entries: [
          OculumQuickEditEntry(
            label: t('Bonus Attacco / VC', 'Attack / VC Bonus'),
            controller: attaccoRapidoController,
          ),
          OculumQuickEditEntry(
            label: t('Bonus CM', 'CM Bonus'),
            controller: cmRapidoController,
          ),
          OculumQuickEditEntry(
            label: t('Bonus Difesa', 'Defense Bonus'),
            controller: difesaRapidaController,
          ),
          OculumQuickEditEntry(
            label: t('Reazioni', 'Reactions'),
            controller: reazioniController,
          ),
          OculumQuickEditEntry(
            label: t('Reazioni veloci', 'Fast reactions'),
            controller: reazioniVelociController,
          ),
        ],
      ),
      OculumQuickEditSection(
        title: t('Danno / Cura', 'Damage / Healing'),
        entries: [
          OculumQuickEditEntry(
            label: t('Danno o Cura', 'Damage or Heal'),
            controller: dannoSubitoController,
          ),
        ],
      ),
      OculumQuickEditSection(
        title: t('Risorse', 'Resources'),
        entries: [
          OculumQuickEditEntry(
            label: 'Obser',
            controller: obserController,
            assetIconPath: 'assets/oculum/obser.png',
          ),
          OculumQuickEditEntry(
            label: 'Ascension Dust',
            controller: ascensionDustController,
          ),
          OculumQuickEditEntry(
            label: t('Ispirazioni', 'Inspirations'),
            controller: ispirazioniController,
          ),
          OculumQuickEditEntry(
            label: t('Super Ispirazioni', 'Super Inspirations'),
            controller: superIspirazioniController,
          ),
          OculumQuickEditEntry(
            label: t('Ispirazioni Oculum', 'Oculum Inspirations'),
            controller: ispirazioniOculumController,
          ),
          OculumQuickEditEntry(label: 'Karma', controller: karmaController),
          OculumQuickEditEntry(label: 'Cenere', controller: cenereController),
        ],
      ),
    ];
  }

  void mostraModificaRapida() {
    showDialog(
      context: context,
      builder: (context) {
        final compact = phoneCompactUi;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget quickField(
              String label,
              TextEditingController controller, {
              bool allowNegative = false,
            }) {
              return Row(
                children: [
                  SizedBox(
                    width: compact ? 86 : 110,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: compact ? 12.5 : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 34 : 44,
                      height: compact ? 34 : 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        final next = leggiNumero(controller) - 1;
                        controller.text = allowNegative
                            ? next.toString()
                            : max(0, next).toString();
                      });
                      setLocalState(() {});
                      programmaSalvataggio();
                    },
                    icon: const Icon(
                      Icons.remove_circle,
                      color: Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : null,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: fieldDecoration(label),
                      onChanged: (_) {
                        setLocalState(() {});
                        programmaSalvataggio();
                      },
                    ),
                  ),
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 34 : 44,
                      height: compact ? 34 : 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        controller.text = (leggiNumero(controller) + 1)
                            .toString();
                      });
                      setLocalState(() {});
                      programmaSalvataggio();
                    },
                    icon: Icon(Icons.add_circle, color: tertiaryColor),
                  ),
                ],
              );
            }

            Widget quickTextField(
              String label,
              TextEditingController controller,
            ) {
              return TextField(
                controller: controller,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : null,
                  fontWeight: FontWeight.bold,
                ),
                decoration: fieldDecoration(label),
                onChanged: (_) {
                  setLocalState(() {});
                  programmaSalvataggio();
                },
              );
            }

            Widget quickCounter({
              required String label,
              required String value,
              required VoidCallback onMinus,
              required VoidCallback onPlus,
            }) {
              return Row(
                children: [
                  SizedBox(
                    width: compact ? 86 : 110,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: compact ? 12.5 : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 34 : 44,
                      height: compact ? 34 : 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(onMinus);
                      setLocalState(() {});
                      programmaSalvataggio();
                    },
                    icon: const Icon(
                      Icons.remove_circle,
                      color: Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: compact ? 38 : 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tertiaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : null,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 34 : 44,
                      height: compact ? 34 : 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(onPlus);
                      setLocalState(() {});
                      programmaSalvataggio();
                    },
                    icon: Icon(Icons.add_circle, color: tertiaryColor),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              insetPadding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 40,
                vertical: compact ? 18 : 24,
              ),
              titlePadding: EdgeInsets.fromLTRB(
                compact ? 16 : 24,
                compact ? 14 : 24,
                compact ? 16 : 24,
                compact ? 8 : 12,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24,
                vertical: compact ? 8 : 12,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                compact ? 12 : 24,
                0,
                compact ? 12 : 24,
                compact ? 10 : 16,
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: tertiaryColor,
                    size: compact ? 20 : 24,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      t('Modifica Rapida', 'Quick Edit'),
                      style: TextStyle(
                        color: tertiaryColor,
                        fontSize: compact ? 19 : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      quickTextField(
                        t('Razza visibile', 'Visible race'),
                        razzaController,
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      Divider(color: tertiaryColor.withValues(alpha: 0.5)),
                      SizedBox(height: compact ? 8 : 14),
                      quickField(t('Livello', 'Level'), livelloController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(t('Grado', 'Grade'), gradoController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('HP Attuali', 'Current HP'),
                        currentHpController,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('HP Temp', hpTempController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(t('Scudo', 'Shield'), scudoController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Scudo Critico', 'Critical Shield'),
                        scudoCriticoController,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('Scudo Oculum', scudoOculumController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Massimo Scudo Oculum', 'Max Oculum Shield'),
                        scudoOculumMaxController,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Bonus Attacco / VC', 'Attack / VC Bonus'),
                        attaccoRapidoController,
                        allowNegative: true,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Bonus CM', 'CM Bonus'),
                        cmRapidoController,
                        allowNegative: true,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Bonus Difesa', 'Defense Bonus'),
                        difesaRapidaController,
                        allowNegative: true,
                      ),
                      SizedBox(height: compact ? 8 : 14),
                      Divider(color: tertiaryColor.withValues(alpha: 0.5)),
                      SizedBox(height: compact ? 8 : 14),
                      quickField(
                        t('Resilienza', 'Resilience'),
                        resilienzaController,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(t('Volontà', 'Will'), volontaController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('Materia', materiaController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('Oculum', oculumController),
                      SizedBox(height: compact ? 8 : 14),
                      Divider(color: tertiaryColor.withValues(alpha: 0.5)),
                      SizedBox(height: compact ? 8 : 14),
                      quickField('Obser', obserController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('Ascension Dust', ascensionDustController),
                      SizedBox(height: compact ? 6 : 10),
                      quickField(
                        t('Ispirazioni', 'Inspirations'),
                        ispirazioniController,
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      quickField('Karma', karmaController, allowNegative: true),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Chiudi', 'Close')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      aggiornaGradoAutomatico();
                      refullaHp();
                      risultato = t(
                        'Valori aggiornati rapidamente.',
                        'Values quickly updated.',
                      );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tertiaryColor,
                    foregroundColor: tertiaryColor.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                  ),
                  label: Text(t('Conferma', 'Confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
