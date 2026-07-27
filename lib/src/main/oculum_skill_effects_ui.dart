part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumSkillEffectsUi on _OculumHomePageState {
  bool tickStructuredAbilityCooldowns(String unit, {bool scheduleSave = true}) {
    var changed = false;
    for (final skill in skills) {
      skill.ensureForms();
      for (final form in skill.forme) {
        changed = (form.cooldownStrutturato?.tick(unit) ?? false) || changed;
      }
    }
    for (final art in arti) {
      for (final skill in art.skills) {
        for (final cooldown in skill.cooldownPerLivello) {
          changed = cooldown.tick(unit) || changed;
        }
      }
      for (final cooldown in <OculumAbilityCooldown?>[
        art.openDescriptionCooldown,
        art.openSkillCooldown,
        art.openBuffCooldown,
      ]) {
        changed = (cooldown?.tick(unit) ?? false) || changed;
      }
    }
    changed = tickActiveStructuredEffects(unit) || changed;
    if (changed && scheduleSave) programmaSalvataggio(invalidateCaches: false);
    return changed;
  }

  Future<void> showReportedTurnEditor({int? masterTokenIndex}) async {
    final isMasterToken =
        masterTokenIndex != null &&
        masterTokenIndex >= 0 &&
        masterTokenIndex < masterInitiativeTokens.length;
    final current = isMasterToken
        ? max(
            0,
            readIntValue(
              masterInitiativeTokens[masterTokenIndex]['reportedTurn'],
            ),
          )
        : playerReportedTurn;
    final controller = TextEditingController(text: '$current');
    try {
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF120D18),
          title: Text(t('Riscrivi turno', 'Rewrite turn')),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: oculumNonNegativeIntegerFormatters,
            decoration: fieldDecoration(t('Turno attuale', 'Current turn')),
            onSubmitted: (value) =>
                Navigator.pop(dialogContext, max(0, readIntValue(value))),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, 0),
              icon: const Icon(Icons.restart_alt),
              label: Text(t('Reset', 'Reset')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                max(0, readIntValue(controller.text)),
              ),
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      );
      if (result == null || !mounted) return;
      if (isMasterToken) {
        setMasterTokenReportedTurn(masterTokenIndex, result);
      } else {
        setPlayerReportedTurn(result);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> showAutomaticAshTurnChanceDialog() async {
    final level = max(0, leggiNumero(livelloController));
    final freeTurns = oculumAutomaticAshFreeTurns(level);
    final firstAshTurn = freeTurns + 1;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF120D18),
        title: Text(
          t('Cenere dopo il turno $freeTurns', 'Ash after turn $freeTurns'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                'Dal turno $firstAshTurn viene effettuato un controllo percentuale a ogni '
                    'nuovo turno. La probabilita cresce, senza sostituire gli '
                    'altri modi gia esistenti di ottenere Cenere. Ogni 6 livelli '
                    'il personaggio ottiene 2 turni aggiuntivi senza questo controllo.',
                'From turn $firstAshTurn a percentage check runs on every new turn. '
                    'The chance increases without replacing any existing way '
                    'to gain Ash. Every 6 levels the character gains 2 additional '
                    'turns without this check.',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Facile: 5% + 5% per turno, massimo 50%'),
            const Text('Normale: 10% + 7% per turno, massimo 70%'),
            const Text('Difficile: 15% + 10% per turno, massimo 90%'),
            const Text('Oculum: 20% + 12% per turno, massimo 100%'),
            const SizedBox(height: 10),
            Text(
              t(
                'Sotto stress: +15 punti percentuali (massimo 100%).',
                'Under stress: +15 percentage points (maximum 100%).',
              ),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Soglie Vita e probabilita base',
                'Life thresholds and base chances',
              ),
              style: TextStyle(
                color: tertiaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              '75% HP: Facile 5%, Normale 10%, Difficile 20%, Oculum 30%',
            ),
            const Text(
              '50% HP: Facile 15%, Normale 20%, Difficile 30%, Oculum 40%',
            ),
            const Text(
              '25% HP: Facile 25%, Normale 30%, Difficile 40%, Oculum 50%',
            ),
            const Text(
              '0% HP: Facile 35%, Normale 40%, Difficile 50%, Oculum 60%',
            ),
            const SizedBox(height: 8),
            Text(t('Rottura Integrita Art: 50%.', 'Art Integrity break: 50%.')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

  Widget reportedTurnCard({int? masterTokenIndex, bool compact = false}) {
    final isMasterToken =
        masterTokenIndex != null &&
        masterTokenIndex >= 0 &&
        masterTokenIndex < masterInitiativeTokens.length;
    final current = isMasterToken
        ? max(
            0,
            readIntValue(
              masterInitiativeTokens[masterTokenIndex]['reportedTurn'],
            ),
          )
        : playerReportedTurn;

    void setValue(int value) {
      if (isMasterToken) {
        setMasterTokenReportedTurn(masterTokenIndex, value);
      } else {
        setPlayerReportedTurn(value);
      }
    }

    return GestureDetector(
      onLongPress: () =>
          unawaited(showReportedTurnEditor(masterTokenIndex: masterTokenIndex)),
      onSecondaryTap: () =>
          unawaited(showReportedTurnEditor(masterTokenIndex: masterTokenIndex)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: tertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: tertiaryColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            IconButton(
              tooltip: t('Diminuisci turno', 'Decrease turn'),
              visualDensity: VisualDensity.compact,
              onPressed: current > 0 ? () => setValue(current - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            if (!compact)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${t('Turno riportato', 'Reported turn')}: $current',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${t('Turno seguente', 'Next turn')}: ${current + 1}',
                      style: TextStyle(
                        color: tertiaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      t(
                        'Pressione continua o click destro per reset/riscrittura',
                        'Long press or right click to reset/rewrite',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    if (!isMasterToken)
                      TextButton.icon(
                        onPressed: () =>
                            unawaited(showAutomaticAshTurnChanceDialog()),
                        icon: const Icon(Icons.local_fire_department, size: 16),
                        label: Text(
                          current <
                                  oculumAutomaticAshFreeTurns(
                                    max(0, leggiNumero(livelloController)),
                                  )
                              ? t(
                                  'Cenere % dal turno ${oculumAutomaticAshFreeTurns(max(0, leggiNumero(livelloController))) + 1}',
                                  'Ash % from turn ${oculumAutomaticAshFreeTurns(max(0, leggiNumero(livelloController))) + 1}',
                                )
                              : '${t('Cenere turno seguente', 'Next-turn Ash')}: '
                                    '${oculumAutomaticAshChancePercent(turn: current + 1, difficulty: campaignDifficulty, level: max(0, leggiNumero(livelloController)), underStress: sottoStress)}%',
                        ),
                      ),
                  ],
                ),
              )
            else
              Text(
                '${t('Turno', 'Turn')} $current → ${current + 1}',
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            IconButton(
              tooltip: t('Aumenta turno', 'Increase turn'),
              visualDensity: VisualDensity.compact,
              onPressed: () => setValue(current + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  void setStoredCampaignTokenReportedTurn(
    int campaignIndex,
    int tokenIndex,
    int value,
  ) {
    if (campaignIndex < 0 || campaignIndex >= campagneOculum.length) return;
    final campaign = campagneOculum[campaignIndex];
    final rawTokens = campaign['masterInitiativeTokens'];
    if (rawTokens is! List ||
        tokenIndex < 0 ||
        tokenIndex >= rawTokens.length ||
        rawTokens[tokenIndex] is! Map) {
      return;
    }
    final safe = max(0, value);
    final token = Map<String, dynamic>.from(rawTokens[tokenIndex] as Map);
    token['reportedTurn'] = safe;
    token['updatedAt'] = DateTime.now().toIso8601String();
    setState(() {
      final updatedTokens = rawTokens
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: true);
      if (tokenIndex >= updatedTokens.length) return;
      updatedTokens[tokenIndex] = token;
      campaign['masterInitiativeTokens'] = updatedTokens;
      campaign['updatedAt'] = DateTime.now().toIso8601String();
    });
    programmaSalvataggio(invalidateCaches: false);
  }

  Widget masterAllBattlesTurnDashboard() {
    final campaigns = <Map<String, dynamic>>[
      for (final campaign in campagneOculum)
        Map<String, dynamic>.from(campaign),
    ];
    final activeIndex = campaigns.indexWhere(
      (campaign) => '${campaign['id'] ?? ''}' == activeCampaignId,
    );
    final activeSnapshot = currentCampaignSnapshot();
    if (activeIndex >= 0) {
      campaigns[activeIndex] = activeSnapshot;
    } else {
      campaigns.add(activeSnapshot);
    }

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Icon(Icons.dashboard_customize, color: tertiaryColor),
      title: Text(
        t(
          'Turni riportati - tutte le battaglie',
          'Reported turns - all battles',
        ),
        style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        t(
          'Il Master vede e gestisce il turno di ogni player in ogni campagna.',
          'The Master sees and manages every player turn in every campaign.',
        ),
      ),
      children: [
        for (final campaign in campaigns)
          Builder(
            builder: (context) {
              final campaignId = '${campaign['id'] ?? ''}';
              final isActive = campaignId == activeCampaignId;
              final rawTokens = campaign['masterInitiativeTokens'];
              final tokens = (rawTokens is List ? rawTokens : const [])
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .where(
                    (token) =>
                        '${token['type'] ?? ''}'.toLowerCase() == 'player' ||
                        '${token['sheetTag'] ?? ''}'.trim().isNotEmpty,
                  )
                  .toList(growable: false);
              final storedCampaignIndex = campagneOculum.indexWhere(
                (item) => '${item['id'] ?? ''}' == campaignId,
              );

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isActive
                      ? tertiaryColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isActive
                        ? tertiaryColor
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${campaign['name'] ?? t('Campagna', 'Campaign')}${isActive ? ' (${t('attiva', 'active')})' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (tokens.isEmpty)
                      smallInfoText(
                        t(
                          'Nessun player nella turnistica salvata.',
                          'No player in the saved turn tracker.',
                        ),
                      ),
                    for (final token in tokens)
                      Builder(
                        builder: (context) {
                          final current = max(
                            0,
                            readIntValue(token['reportedTurn']),
                          );
                          final liveIndex = isActive
                              ? masterInitiativeTokens.indexWhere(
                                  (item) =>
                                      '${item['id'] ?? ''}' ==
                                          '${token['id'] ?? ''}' ||
                                      ('${token['sheetTag'] ?? ''}'
                                              .trim()
                                              .isNotEmpty &&
                                          '${item['sheetTag'] ?? ''}' ==
                                              '${token['sheetTag'] ?? ''}'),
                                )
                              : -1;
                          void update(int value) {
                            if (isActive && liveIndex >= 0) {
                              setMasterTokenReportedTurn(liveIndex, value);
                            } else if (storedCampaignIndex >= 0) {
                              final storedRaw =
                                  campagneOculum[storedCampaignIndex]['masterInitiativeTokens'];
                              final storedTokens = storedRaw is List
                                  ? storedRaw
                                  : const [];
                              final storedIndex = storedTokens.indexWhere(
                                (item) =>
                                    item is Map &&
                                    ('${item['id'] ?? ''}' ==
                                            '${token['id'] ?? ''}' ||
                                        ('${token['sheetTag'] ?? ''}'
                                                .trim()
                                                .isNotEmpty &&
                                            '${item['sheetTag'] ?? ''}' ==
                                                '${token['sheetTag'] ?? ''}')),
                              );
                              setStoredCampaignTokenReportedTurn(
                                storedCampaignIndex,
                                storedIndex,
                                value,
                              );
                            }
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${token['name'] ?? 'Player'}: ${t('turno', 'turn')} $current - ${t('seguente', 'next')} ${current + 1}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: current > 0
                                    ? () => update(current - 1)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => update(current + 1),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  List<String> commandSuggestionsForText(String text) {
    final cursorText = text;
    final atIndex = cursorText.lastIndexOf('@');
    if (atIndex < 0) return const <String>[];
    final fragment = cursorText.substring(atIndex);
    if (fragment.contains(RegExp(r'[\s+\-*/=]'))) {
      return const <String>[];
    }
    final query = oculumNormalizeText(fragment).replaceAll('@', '');
    final dynamic = <String>[
      for (final stat in hiddenEyeStats.where((item) => item.unlocked))
        '@${stat.nome.trim().isEmpty ? stat.id : stat.nome.trim()}',
    ];
    final candidates = <String>{
      ...oculumCommandAutocompleteLabels,
      ...dynamic,
      '@OculumSpeso',
    };
    return candidates
        .where(
          (value) =>
              query.isEmpty ||
              oculumNormalizeText(value).replaceAll('@', '').startsWith(query),
        )
        .take(8)
        .toList(growable: false);
  }

  String commandNaturalPreview(String text) {
    if (!text.contains('@')) {
      return '';
    }
    final parsed = parseQuickCommandsDetailed(text);
    final invalid = parsed.where((command) => !command.valid).toList();
    if (invalid.isNotEmpty) {
      final error = invalid.first.error
          .replaceFirst('FormatException: ', '')
          .trim();
      return t(
        '! Parte non valida: $error Esempio corretto: @Danni+3',
        '! Invalid part: $error Correct example: @Danni+3',
      );
    }
    if (parsed.isEmpty) {
      return t(
        '! Comando non riconosciuto. Controlla il nome e usa una forma come @Difesa+2.',
        '! Command not recognized. Check its name and use a form such as @Difesa+2.',
      );
    }
    String describe(OculumFormulaCommand command) {
      final label = switch (command.key) {
        'danni' => t('Danno', 'Damage'),
        'difesa' => t('Difesa', 'Defense'),
        'hp' => t('Vita massima', 'Maximum Life'),
        'hp_temp' => t('HP temporanei', 'Temporary HP'),
        'scudo' => t('Scudo', 'Shield'),
        'oculum_spent' => t('Oculum speso', 'Spent Oculum'),
        'reazione' => t('Reazioni', 'Reactions'),
        'reazione_veloce' => t('Reazioni rapide', 'Quick reactions'),
        _ => command.key.replaceAll('_', ' '),
      };
      final sign = command.value >= 0 ? '+' : '';
      final trigger = command.triggerRaw.trim().isEmpty
          ? ''
          : ' (${command.triggerRaw})';
      return '$label $sign${command.value}$trigger';
    }

    return '${t('Anteprima', 'Preview')}: '
        '${parsed.take(4).map(describe).join(' · ')}';
  }

  Future<String?> showCommandManualInsertDialog(String currentText) async {
    final dynamicSubtraits = hiddenEyeStats
        .where((item) => item.unlocked)
        .map((item) => item.nome.trim().isEmpty ? item.id : item.nome.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final dynamicSubtrait = dynamicSubtraits.isEmpty
        ? null
        : dynamicSubtraits.first;
    final entries =
        <
          ({
            String category,
            String name,
            String syntax,
            String example,
            String result,
            String limits,
          })
        >[
          (
            category: t('Più usati', 'Most used'),
            name: t('Aumento danno', 'Increase damage'),
            syntax: '@Danni+Valore',
            example: '@Danni+3',
            result: t('Aumenta il danno di 3.', 'Increases damage by 3.'),
            limits: t(
              'Utilizzabile nei campi che supportano @.',
              'Available in fields that support @.',
            ),
          ),
          (
            category: t('Più usati', 'Most used'),
            name: t('Aumento difesa', 'Increase defense'),
            syntax: '@Difesa+Valore',
            example: '@Difesa+2',
            result: t('Aumenta la Difesa di 2.', 'Increases Defense by 2.'),
            limits: t(
              'Può essere seguito da un tipo, per esempio Cenere.',
              'It may be followed by a type, for example Ash.',
            ),
          ),
          (
            category: t('Risorse', 'Resources'),
            name: t('Vita e HP temporanei', 'Life and temporary HP'),
            syntax: '@HP+Valore / @HPTemp+Valore',
            example: '@HPTemp+5',
            result: t('Aggiunge 5 HP temporanei.', 'Adds 5 temporary HP.'),
            limits: t(
              'Il limite degli HP temporanei resta quello del gioco.',
              'The temporary HP game limit still applies.',
            ),
          ),
          (
            category: t('Risorse', 'Resources'),
            name: t('Oculum speso', 'Spent Oculum'),
            syntax: '@OculumSpeso+Valore',
            example: '@OculumSpeso+5',
            result: t(
              'Aggiunge 5 al conteggio usato dai trigger OculumSpeso.',
              'Adds 5 to the counter used by OculumSpeso triggers.',
            ),
            limits: t(
              'Non aumenta l’Oculum disponibile.',
              'It does not increase available Oculum.',
            ),
          ),
          (
            category: t('Statistiche', 'Stats'),
            name: t('Modifica statistica', 'Change stat'),
            syntax: '@NomeStatistica±Valore',
            example: '@Volonta+2',
            result: t('Aumenta Volontà di 2.', 'Increases Will by 2.'),
            limits: t(
              'Usa nomi realmente presenti nel parser.',
              'Use names actually supported by the parser.',
            ),
          ),
          if (dynamicSubtrait != null)
            (
              category: t('Sottotratti', 'Subtraits'),
              name: t('Modifica sottotratto', 'Change subtrait'),
              syntax: '@NomeSottotratto±Valore',
              example: '@$dynamicSubtrait+1',
              result: t(
                'Aumenta il sottotratto $dynamicSubtrait di 1.',
                'Increases the $dynamicSubtrait subtrait by 1.',
              ),
              limits: t(
                'I sottotratti non diventano risorse consumabili.',
                'Subtraits do not become consumable resources.',
              ),
            ),
          (
            category: t('Tiri', 'Rolls'),
            name: t('Bonus ai tiri statistica', 'Stat roll bonus'),
            syntax: '@TiroStats±Valore',
            example: '@TiroStats+1',
            result: t(
              'Aggiunge 1 ai tiri delle statistiche.',
              'Adds 1 to stat rolls.',
            ),
            limits: t(
              'Non modifica direttamente il valore base.',
              'Does not directly change the base value.',
            ),
          ),
          (
            category: t('Trigger', 'Triggers'),
            name: t('Ogni Oculum speso', 'Per Oculum spent'),
            syntax: '@Effetto+Valore ogni N OculumSpeso',
            example: '@Danni+2 ogni 1 OculumSpeso',
            result: t(
              'Aggiunge 2 Danni per ogni Oculum speso.',
              'Adds 2 Damage for every Oculum spent.',
            ),
            limits: t(
              'Il conteggio usa la raccolta corrente.',
              'The count uses the current tracked total.',
            ),
          ),
          (
            category: t('Trigger', 'Triggers'),
            name: t('Quando colpisci', 'On hit'),
            syntax: '@Effetto+Valore OnHit',
            example: '@Danni+2 OnHit',
            result: t(
              'Applica il bonus quando il trigger OnHit è attivo.',
              'Applies the bonus while the OnHit trigger is active.',
            ),
            limits: t(
              'Disponibile nei testi rapidi calcolabili.',
              'Available in calculable quick-command text.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Moltiplicazione', 'Multiplication'),
            syntax: '@Statistica+Variabile*Moltiplicatore',
            example: '@Danni+Volonta*2',
            result: t(
              'Somma al Danno due volte la Volontà attuale.',
              'Adds twice the current Will to Damage.',
            ),
            limits: t(
              'Usa *; moltiplicazioni e divisioni vengono calcolate prima di somme e sottrazioni.',
              'Use *; multiplication and division are evaluated before addition and subtraction.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Divisione', 'Division'),
            syntax: '@Statistica+Variabile/Divisore',
            example: '@Difesa+Resilienza/2',
            result: t(
              'Somma metà Resilienza alla Difesa.',
              'Adds half Resilience to Defense.',
            ),
            limits: t(
              'Il divisore non può essere zero. I risultati vengono arrotondati con le regole del parser.',
              'The divisor cannot be zero. Results follow parser rounding rules.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Percentuale di una statistica', 'Percentage of a stat'),
            syntax: '@Statistica+Percentuale%Variabile',
            example: '@Oculum+25%Materia',
            result: t(
              'Somma il 25% della Materia all’Oculum.',
              'Adds 25% of Materia to Oculum.',
            ),
            limits: t(
              'La statistica usata come base deve essere riconosciuta.',
              'The stat used as the base must be recognized.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Percentuale sul bersaglio', 'Percentage of target'),
            syntax: '@Statistica±Percentuale%',
            example: '@Danni+25%',
            result: t(
              'Aumenta il Danno del 25% del suo valore di riferimento.',
              'Increases Damage by 25% of its reference value.',
            ),
            limits: t(
              'Se non esiste una base valida, il comando viene mostrato come errore e non applicato.',
              'If no valid base exists, the command is shown as an error and is not applied.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Frazioni', 'Fractions'),
            syntax: '@Statistica±1/2Variabile',
            example: '@Materia-1/3Volonta',
            result: t(
              'Sottrae un terzo della Volontà dalla Materia.',
              'Subtracts one third of Will from Materia.',
            ),
            limits: t(
              'Sono accettate anche le frazioni ⅓, ¼, ½ e ¾.',
              'The fractions ⅓, ¼, ½ and ¾ are also accepted.',
            ),
          ),
          (
            category: t('Formule', 'Formulas'),
            name: t('Più comandi insieme', 'Multiple commands'),
            syntax: '@Comando1... @Comando2...',
            example: '@Danni+3, @Difesa+2; @Materia-1',
            result: t(
              'Valuta ogni comando separatamente.',
              'Evaluates every command separately.',
            ),
            limits: t(
              'Puoi separarli con spazio, virgola, punto e virgola o nuova riga. Ogni comando errato viene segnalato.',
              'Separate them with spaces, commas, semicolons, or new lines. Every invalid command is reported.',
            ),
          ),
          (
            category: t('Trigger', 'Triggers'),
            name: t('Costo che genera un bonus', 'Cost that grants a bonus'),
            syntax: '@Costo-Valore=Effetto+Valore',
            example: '@HP-10=Stats+1',
            result: t(
              'Ogni 10 HP persi aggiunge 1 alle statistiche consentite.',
              'Every 10 HP lost adds 1 to the allowed stats.',
            ),
            limits: t(
              'La statistica consumata non può rigenerare se stessa nello stesso comando.',
              'The spent stat cannot regenerate itself in the same command.',
            ),
          ),
          (
            category: t('Trigger', 'Triggers'),
            name: t(
              'Ogni totale o risorsa spesa',
              'Per total or spent resource',
            ),
            syntax: '@Effetto+Valore ogni N Sorgente',
            example: '@Danni+2 ogni 5 MateriaTotale',
            result: t(
              'Aggiunge 2 Danni per ogni blocco completo di 5 Materia totale.',
              'Adds 2 Damage for every complete block of 5 total Materia.',
            ),
            limits: t(
              'Sono supportate sorgenti totali, attuali e spese riconosciute dal parser.',
              'Parser-recognized total, current, and spent sources are supported.',
            ),
          ),
        ];
    var query = '';
    var category = t('Tutti', 'All');
    final categories = <String>{
      t('Tutti', 'All'),
      for (final entry in entries) entry.category,
    }.toList();
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = entries.where((entry) {
            final matchesCategory =
                category == t('Tutti', 'All') || entry.category == category;
            final haystack = oculumNormalizeText(
              '${entry.name} ${entry.syntax} ${entry.example} ${entry.result}',
            );
            return matchesCategory &&
                (query.isEmpty ||
                    haystack.contains(oculumNormalizeText(query)));
          }).toList();
          return AlertDialog(
            backgroundColor: const Color(0xFF120D18),
            title: Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t('Manuale dei comandi', 'Command Manual')),
                ),
              ],
            ),
            content: SizedBox(
              width: 680,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    decoration: fieldDecoration(
                      t('Cerca comando', 'Search command'),
                    ).copyWith(prefixIcon: const Icon(Icons.search)),
                    onChanged: (value) =>
                        setDialogState(() => query = value.trim()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: fieldDecoration(t('Categoria', 'Category')),
                    items: [
                      for (final value in categories)
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: (value) => setDialogState(
                      () => category = value ?? categories.first,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.045),
                          child: ListTile(
                            title: Text(entry.name),
                            subtitle: Text(
                              '${entry.syntax}\n'
                              '${t('Esempio', 'Example')}: ${entry.example}\n'
                              '${entry.result}\n${entry.limits}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 2,
                              children: [
                                IconButton(
                                  tooltip: t('Copia esempio', 'Copy example'),
                                  onPressed: () => Clipboard.setData(
                                    ClipboardData(text: entry.example),
                                  ),
                                  icon: const Icon(Icons.copy, size: 19),
                                ),
                                IconButton(
                                  tooltip: t(
                                    'Inserisci comando',
                                    'Insert command',
                                  ),
                                  onPressed: () => Navigator.pop(
                                    dialogContext,
                                    entry.example,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
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
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t('Chiudi', 'Close')),
              ),
            ],
          );
        },
      ),
    );
    if (selected == null || selected.trim().isEmpty) return null;
    final separator =
        currentText.isEmpty || RegExp(r'\s$').hasMatch(currentText) ? '' : ' ';
    return '$currentText$separator${selected.trim()}';
  }

  String structuredEffectTypeLabel(String type) {
    return switch (type) {
      'danno' => t('Danno', 'Damage'),
      'difesa' => t('Difesa', 'Defense'),
      'cura' => t('Cura / rigenerazione', 'Healing / regeneration'),
      'modifica_statistica' => t(
        'Aumento/diminuzione statistica',
        'Stat change',
      ),
      'modifica_sottotratto' => t(
        'Aumento/diminuzione sottotratto',
        'Subtrait change',
      ),
      'velocita' => t('Velocità', 'Speed'),
      'forza' => t('Forza', 'Strength'),
      'scudo' => t('Scudo', 'Shield'),
      'hp_temporanei' => t('HP temporanei', 'Temporary HP'),
      'rimuovi_vita' => t('Rimozione Vita', 'Remove Life'),
      'rimuovi_oculum' => t('Rimozione Oculum', 'Remove Oculum'),
      'rimuovi_azioni' => t('Rimozione azioni', 'Remove actions'),
      'rimuovi_reazioni' => t('Rimozione reazioni', 'Remove reactions'),
      'rimuovi_reazioni_rapide' => t(
        'Rimozione reazioni rapide',
        'Remove quick reactions',
      ),
      'aggiungi_reazioni' => t('Aggiunta reazioni', 'Add reactions'),
      'aggiungi_reazioni_rapide' => t(
        'Aggiunta reazioni rapide',
        'Add quick reactions',
      ),
      'consumo_risorsa' => t('Consumo risorsa', 'Consume resource'),
      'stato' => t('Applica stato', 'Apply condition'),
      _ => type,
    };
  }

  String structuredEffectResourceLabel(String key) {
    return switch (oculumNormalizeEffectResource(key)) {
      'vita' => t('Vita', 'Life'),
      'azioni' => t('Azioni', 'Actions'),
      'reazioni' => t('Reazioni', 'Reactions'),
      'reazioni_rapide' => t('Reazioni rapide', 'Quick reactions'),
      'utilizzi_skill' => t('Utilizzi Skill', 'Skill uses'),
      'materia' => 'Materia',
      'volonta' => t('Volontà', 'Will'),
      'resilienza' => t('Resilienza', 'Resilience'),
      'nessuna' => t('Nessuna', 'None'),
      _ => 'Oculum',
    };
  }

  List<String> structuredEffectTargetOptions(String type) {
    final values = <String>[];
    if (type == 'modifica_statistica') {
      values.addAll(<String>[
        'Resilienza',
        'Volontà',
        'Materia',
        'Oculum',
        'Danni',
        'Difesa',
        'Scudo',
        'Iniziativa',
        'CM',
        'Reazioni',
        'Reazioni rapide',
        'VC',
      ]);
    } else if (type == 'modifica_sottotratto') {
      values.addAll(
        hiddenEyeStats.where((stat) => stat.unlocked).map((stat) => stat.nome),
      );
    } else if (type == 'velocita') {
      values.addAll(<String>[
        'CM',
        'Controllo di Movimento',
        'Reazioni',
        'Reazioni rapide',
        'Iniziativa',
      ]);
    } else if (type == 'forza') {
      values.addAll(<String>['Forza', 'Danni', 'VC', 'Controlli di Forza']);
    }
    return values.toSet().where((value) => value.trim().isNotEmpty).toList();
  }

  Widget structuredCooldownEditor({
    required OculumAbilityCooldown? cooldown,
    required ValueChanged<OculumAbilityCooldown> onChanged,
    String storageId = '',
  }) {
    final value = cooldown ?? OculumAbilityCooldown();

    void update({int? amount, String? unit, bool? startsReady}) {
      final nextAmount = max(0, amount ?? value.amount);
      final nextStartsReady = startsReady ?? value.startsReady;
      onChanged(
        OculumAbilityCooldown(
          amount: nextAmount,
          unit: unit ?? value.unit,
          startsReady: nextStartsReady,
          remaining: startsReady != null
              ? (nextStartsReady ? 0 : nextAmount)
              : cooldown == null
              ? (nextStartsReady ? 0 : nextAmount)
              : value.remaining.clamp(0, nextAmount).toInt(),
        ),
      );
      programmaSalvataggio(invalidateCaches: false);
    }

    return ExpansionTile(
      key: ValueKey('structured_cooldown_$storageId'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        t('Cooldown strutturato', 'Structured cooldown'),
        style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        value.amount <= 0
            ? t('Nessun cooldown', 'No cooldown')
            : '${value.amount} ${value.unit} · '
                  '${value.startsReady ? t('parte carico', 'starts ready') : t('parte scarico', 'starts unavailable')}',
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: campoModello(
                fieldKey: ValueKey('cooldown_amount_$storageId'),
                label: t('Durata cooldown', 'Cooldown duration'),
                initialValue: '${value.amount}',
                keyboardType: TextInputType.number,
                inputFormatters: oculumNonNegativeIntegerFormatters,
                enableCommandAutocomplete: false,
                onChanged: (raw) => update(amount: readIntValue(raw)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: <String>['turni', 'tiri'].contains(value.unit)
                    ? value.unit
                    : 'turni',
                dropdownColor: const Color(0xFF10121A),
                decoration: fieldDecoration(t('Unità', 'Unit')),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'turni',
                    child: Text(t('Turni', 'Turns')),
                  ),
                  DropdownMenuItem(
                    value: 'tiri',
                    child: Text(t('Tiri', 'Rolls')),
                  ),
                ],
                onChanged: (next) => update(unit: next ?? 'turni'),
              ),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: value.startsReady,
          title: Text(
            t('Cooldown inizialmente carico', 'Cooldown initially ready'),
          ),
          subtitle: Text(
            t(
              'Se disattivato, parte con tutto il cooldown rimanente.',
              'When disabled, it starts with the full cooldown remaining.',
            ),
          ),
          onChanged: (next) => update(startsReady: next),
        ),
      ],
    );
  }

  Widget structuredCostEditor({
    required OculumSkillCost? cost,
    required String storageId,
    required ValueChanged<OculumSkillCost?> onChanged,
  }) {
    final enabled = cost != null;
    final current = cost ?? OculumSkillCost(resource: 'oculum');
    const resources = <String>[
      'oculum',
      'vita',
      'azioni',
      'reazioni',
      'reazioni_rapide',
      'utilizzi_skill',
      'materia',
      'volonta',
      'resilienza',
      'nessuna',
    ];

    void update(VoidCallback mutation) {
      mutation();
      onChanged(current);
      programmaSalvataggio(invalidateCaches: false);
    }

    return ExpansionTile(
      key: PageStorageKey<String>('structured_cost_$storageId'),
      tilePadding: EdgeInsets.zero,
      title: Text(t('Costo strutturato opzionale', 'Optional structured cost')),
      subtitle: Text(
        t(
          'Solo risorse consumabili: i sottotratti non possono essere costi.',
          'Consumable resources only: subtraits cannot be costs.',
        ),
      ),
      trailing: Switch(
        value: enabled,
        onChanged: (value) {
          onChanged(value ? current : null);
          programmaSalvataggio(invalidateCaches: false);
        },
      ),
      children: [
        if (enabled) ...[
          DropdownButtonFormField<String>(
            initialValue: resources.contains(current.resource)
                ? current.resource
                : 'oculum',
            decoration: fieldDecoration(t('Risorsa', 'Resource')),
            items: [
              for (final resource in resources)
                DropdownMenuItem(
                  value: resource,
                  child: Text(structuredEffectResourceLabel(resource)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              update(() => current.resource = value);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: current.amountExpression,
            decoration: fieldDecoration(
              t('Valore/formula del costo', 'Cost value/formula'),
            ),
            onChanged: (value) =>
                update(() => current.amountExpression = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: current.variable,
            title: Text(
              t('Costo scelto all attivazione', 'Cost chosen on use'),
            ),
            onChanged: (value) => update(() => current.variable = value),
          ),
          if (current.variable)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '${current.minimum}',
                    keyboardType: TextInputType.number,
                    inputFormatters: oculumNonNegativeIntegerFormatters,
                    decoration: fieldDecoration(t('Minimo', 'Minimum')),
                    onChanged: (value) =>
                        update(() => current.minimum = readIntValue(value)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: '${current.maximum}',
                    keyboardType: TextInputType.number,
                    inputFormatters: oculumNonNegativeIntegerFormatters,
                    decoration: fieldDecoration(t('Massimo', 'Maximum')),
                    onChanged: (value) =>
                        update(() => current.maximum = readIntValue(value)),
                  ),
                ),
              ],
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: current.perTurn,
            title: Text(t('Consumo per turno', 'Cost per turn')),
            onChanged: (value) => update(() => current.perTurn = value),
          ),
        ],
      ],
    );
  }

  Future<OculumStructuredEffect?> showStructuredEffectDialog({
    OculumStructuredEffect? initial,
  }) async {
    final seed = initial == null
        ? OculumStructuredEffect()
        : OculumStructuredEffect.fromJson(initial.toJson());
    var type = oculumStructuredEffectTypes.contains(seed.type)
        ? seed.type
        : 'danno';
    var mode = seed.mode;
    var resource = oculumNormalizeEffectResource(
      seed.resource.isEmpty ? 'vita' : seed.resource,
    );
    var recipient = seed.recipient;
    var durationUnit = seed.durationUnit;
    var diceDestination = seed.diceDestination;
    var enabled = seed.enabled;
    var stackable = seed.stackable;
    var includeLevel = seed.includeLevel;
    var includeGrade = seed.includeGrade;
    var bypassDefense = seed.bypassDefense;
    var bypassShields = seed.bypassShields;
    var advancedExpanded =
        seed.diceExpression.trim().isNotEmpty ||
        seed.includeLevel ||
        seed.includeGrade ||
        seed.minimum != null ||
        seed.maximum != null ||
        seed.stackable ||
        seed.customDisplayText.trim().isNotEmpty ||
        seed.narrativeText.trim().isNotEmpty;
    Timer? dialogRefreshTimer;
    final valueController = TextEditingController(text: seed.valueExpression);
    final targetController = TextEditingController(text: seed.target);
    final durationController = TextEditingController(text: seed.duration);
    final frequencyController = TextEditingController(text: seed.frequency);
    final diceController = TextEditingController(text: seed.diceExpression);
    final gradeValueController = TextEditingController(
      text: '${seed.gradeValue}',
    );
    final minimumController = TextEditingController(
      text: seed.minimum?.toString() ?? '',
    );
    final maximumController = TextEditingController(
      text: seed.maximum?.toString() ?? '',
    );
    final narrativeController = TextEditingController(text: seed.narrativeText);
    final customController = TextEditingController(
      text: seed.customDisplayText,
    );
    final elementTypeController = TextEditingController(text: seed.elementType);
    var appliedState = seed.appliedState.isEmpty
        ? 'sotto_stress'
        : seed.appliedState;
    String error = '';

    void scheduleDialogRefresh(StateSetter update) {
      dialogRefreshTimer?.cancel();
      dialogRefreshTimer = Timer(const Duration(milliseconds: 120), () {
        update(() => error = '');
      });
    }

    List<String> modesFor(String effectType) {
      return switch (effectType) {
        'cura' => <String>['immediato', 'rigenerazione'],
        'danno' || 'difesa' => <String>['immediato', 'finche_attivo'],
        'modifica_statistica' ||
        'modifica_sottotratto' ||
        'velocita' ||
        'forza' => <String>['aumento', 'diminuzione'],
        _ => <String>['immediato'],
      };
    }

    OculumStructuredEffect currentEffect() {
      return OculumStructuredEffect(
        id: seed.id,
        type: type,
        target: targetController.text.trim(),
        resource: resource,
        valueExpression: valueController.text.trim(),
        mode: mode,
        duration: durationController.text.trim(),
        durationUnit: durationUnit,
        frequency: frequencyController.text.trim(),
        recipient: recipient,
        diceExpression: diceController.text.trim(),
        diceDestination: diceDestination,
        includeLevel: includeLevel,
        includeGrade: includeGrade,
        gradeValue:
            double.tryParse(gradeValueController.text.replaceAll(',', '.')) ??
            1,
        enabled: enabled,
        stackable: stackable,
        minimum: int.tryParse(minimumController.text.trim()),
        maximum: int.tryParse(maximumController.text.trim()),
        narrativeText: narrativeController.text,
        customDisplayText: customController.text,
        elementType: elementTypeController.text.trim(),
        appliedState: appliedState,
        bypassDefense: bypassDefense,
        bypassShields: bypassShields,
      );
    }

    void applyQuickPreset(String preset, StateSetter update) {
      update(() {
        bypassDefense = false;
        bypassShields = false;
        frequencyController.clear();
        durationController.clear();
        durationUnit = 'turni';
        diceController.clear();
        includeLevel = false;
        includeGrade = false;
        minimumController.clear();
        maximumController.clear();
        stackable = false;
        error = '';

        switch (preset) {
          case 'muro':
            type = 'scudo';
            mode = 'immediato';
            recipient = 'se_stesso';
            valueController.text = 'OculumSpeso*2+3';
            elementTypeController.text = '';
          case 'cura':
            type = 'cura';
            mode = 'immediato';
            resource = 'vita';
            recipient = 'se_stesso';
            valueController.text = '10';
            elementTypeController.text = '';
          case 'bonus':
            type = 'modifica_statistica';
            mode = 'aumento';
            targetController.text = 'Resilienza';
            recipient = 'se_stesso';
            valueController.text = '2';
            durationController.text = '3';
          case 'periodico':
            type = 'danno';
            mode = 'immediato';
            recipient = 'bersaglio';
            valueController.text = '5';
            frequencyController.text = '3';
          case 'costo':
            type = 'consumo_risorsa';
            mode = 'immediato';
            resource = 'oculum';
            recipient = 'se_stesso';
            valueController.text = '1';
          default:
            type = 'danno';
            mode = 'immediato';
            recipient = 'bersaglio';
            valueController.text = '10';
            elementTypeController.text = '';
        }
      });
    }

    try {
      return await showDialog<OculumStructuredEffect>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final modes = modesFor(type);
              if (!modes.contains(mode)) mode = modes.first;
              final targetOptions = structuredEffectTargetOptions(type);
              final needsTarget = targetOptions.isNotEmpty;
              final isHealing = type == 'cura';
              final isCost = type == 'consumo_risorsa';
              final isState = type == 'stato';
              final hasFrequency =
                  oculumStructuredEffectFrequency(frequencyController.text) > 0;
              final supportsDuration =
                  mode == 'finche_attivo' ||
                  mode == 'rigenerazione' ||
                  hasFrequency ||
                  type == 'modifica_statistica' ||
                  type == 'modifica_sottotratto' ||
                  type == 'velocita' ||
                  type == 'forza' ||
                  type == 'stato';
              final preview = oculumStructuredEffectDescription(
                currentEffect(),
                subtraits: hiddenEyeStats,
              );

              return AlertDialog(
                backgroundColor: const Color(0xFF120D18),
                title: Text(
                  initial == null
                      ? t('Aggiungi effetto', 'Add effect')
                      : t('Modifica effetto', 'Edit effect'),
                ),
                content: SizedBox(
                  width: 620,
                  height: min(720, MediaQuery.sizeOf(context).height * 0.72),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('Configurazione rapida', 'Quick setup'),
                          style: TextStyle(
                            color: tertiaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final preset
                                in const <(String, IconData, String, String)>[
                                  ('danno', Icons.flash_on, 'Danno', 'Damage'),
                                  ('muro', Icons.shield, 'Muro', 'Wall'),
                                  ('cura', Icons.favorite, 'Cura', 'Healing'),
                                  (
                                    'bonus',
                                    Icons.trending_up,
                                    'Bonus',
                                    'Bonus',
                                  ),
                                  (
                                    'periodico',
                                    Icons.update,
                                    'Ogni 3 turni',
                                    'Every 3 turns',
                                  ),
                                  (
                                    'costo',
                                    Icons.remove_circle_outline,
                                    'Costo',
                                    'Cost',
                                  ),
                                ])
                              ActionChip(
                                avatar: Icon(preset.$2, size: 17),
                                label: Text(t(preset.$3, preset.$4)),
                                onPressed: () =>
                                    applyQuickPreset(preset.$1, setDialogState),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: enabled,
                          title: Text(
                            t('Effetto attivo', 'Effect enabled'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            enabled
                                ? t(
                                    'Verrà applicato quando usi questa capacità.',
                                    'It will be applied when this ability is used.',
                                  )
                                : t(
                                    'Resta salvato ma non viene applicato.',
                                    'It stays saved but is not applied.',
                                  ),
                          ),
                          onChanged: (value) =>
                              setDialogState(() => enabled = value),
                        ),
                        const Divider(height: 18),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          dropdownColor: const Color(0xFF10121A),
                          decoration: fieldDecoration(
                            t('Tipo di effetto', 'Effect type'),
                          ),
                          items: <DropdownMenuItem<String>>[
                            for (final value in oculumStructuredEffectTypes)
                              DropdownMenuItem<String>(
                                value: value,
                                child: Text(structuredEffectTypeLabel(value)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              type = value;
                              final nextModes = modesFor(type);
                              if (!nextModes.contains(mode)) {
                                mode = nextModes.first;
                              }
                              error = '';
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        if (modes.length > 1)
                          DropdownButtonFormField<String>(
                            initialValue: mode,
                            dropdownColor: const Color(0xFF10121A),
                            decoration: fieldDecoration(t('Modalità', 'Mode')),
                            items: <DropdownMenuItem<String>>[
                              for (final value in modes)
                                DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == 'rigenerazione'
                                        ? t('Rigenerazione', 'Regeneration')
                                        : value == 'finche_attivo'
                                        ? t('Finché attivo', 'While active')
                                        : value == 'diminuzione'
                                        ? t('Diminuzione', 'Decrease')
                                        : value == 'aumento'
                                        ? t('Aumento', 'Increase')
                                        : t('Immediato', 'Immediate'),
                                  ),
                                ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              mode = value ?? modes.first;
                            }),
                          ),
                        if (modes.length > 1) const SizedBox(height: 10),
                        if (type == 'danno') ...[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: bypassDefense,
                            title: Text(t('Oltre Difesa', 'Beyond Defense')),
                            subtitle: Text(
                              t(
                                'Il danno ignora la Difesa.',
                                'Damage ignores Defense.',
                              ),
                            ),
                            onChanged: (value) => setDialogState(() {
                              bypassDefense = value;
                            }),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: bypassShields,
                            title: Text(t('Oltre Scudi', 'Beyond Shields')),
                            subtitle: Text(
                              t(
                                'Il danno salta Scudo Oculum e Scudo.',
                                'Damage skips Oculum Shield and Shield.',
                              ),
                            ),
                            onChanged: (value) => setDialogState(() {
                              bypassShields = value;
                            }),
                          ),
                        ],
                        TextField(
                          controller: elementTypeController,
                          decoration:
                              fieldDecoration(
                                t(
                                  'Tipo / elemento opzionale',
                                  'Optional type / element',
                                ),
                              ).copyWith(
                                helperText: t(
                                  'Esempi: Ghiaccio, Fuoco, Cenere, Fisico',
                                  'Examples: Ice, Fire, Ash, Physical',
                                ),
                              ),
                          onChanged: (_) =>
                              scheduleDialogRefresh(setDialogState),
                        ),
                        const SizedBox(height: 10),
                        if (isState) ...[
                          DropdownButtonFormField<String>(
                            initialValue: appliedState,
                            dropdownColor: const Color(0xFF10121A),
                            decoration: fieldDecoration(
                              t('Stato applicato', 'Applied condition'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'sotto_stress',
                                child: Text(t('Sotto stress', 'Under stress')),
                              ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              appliedState = value ?? 'sotto_stress';
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (needsTarget) ...[
                          DropdownButtonFormField<String>(
                            initialValue:
                                targetOptions.contains(targetController.text)
                                ? targetController.text
                                : null,
                            dropdownColor: const Color(0xFF10121A),
                            decoration: fieldDecoration(
                              type == 'modifica_sottotratto'
                                  ? t('Sottotratto', 'Subtrait')
                                  : t('Valore modificato', 'Changed value'),
                            ),
                            items: <DropdownMenuItem<String>>[
                              for (final value in targetOptions)
                                DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              targetController.text = value ?? '';
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (isHealing || isCost) ...[
                          DropdownButtonFormField<String>(
                            initialValue: resource,
                            dropdownColor: const Color(0xFF10121A),
                            decoration: fieldDecoration(
                              isCost
                                  ? t('Risorsa consumata', 'Consumed resource')
                                  : t('Risorsa curata', 'Healed resource'),
                            ),
                            items: <DropdownMenuItem<String>>[
                              for (final value
                                  in isHealing
                                      ? const <String>['vita', 'oculum']
                                      : oculumEffectConsumableResourceKeys)
                                DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    structuredEffectResourceLabel(value),
                                  ),
                                ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              resource = value ?? 'oculum';
                              error = '';
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                        TextField(
                          controller: valueController,
                          decoration:
                              fieldDecoration(
                                t('Valore o formula', 'Value or formula'),
                              ).copyWith(
                                helperText:
                                    '10, @Res+1, 25% Forza, OculumSpeso x 1.3',
                              ),
                          onChanged: (_) =>
                              scheduleDialogRefresh(setDialogState),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: frequencyController,
                          keyboardType: TextInputType.number,
                          inputFormatters: oculumNonNegativeIntegerFormatters,
                          decoration:
                              fieldDecoration(
                                t(
                                  'Ripeti ogni N turni/tiri (opzionale)',
                                  'Repeat every N turns/rolls (optional)',
                                ),
                              ).copyWith(
                                helperText: t(
                                  'Esempio: 3 = agisce al 3°, 6°, 9° turno. Lascia vuoto per agire subito una volta.',
                                  'Example: 3 = acts on turns 3, 6 and 9. Leave empty to act once immediately.',
                                ),
                              ),
                          onChanged: (_) =>
                              scheduleDialogRefresh(setDialogState),
                        ),
                        if (supportsDuration) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: durationController,
                            decoration: fieldDecoration(t('Durata', 'Duration'))
                                .copyWith(
                                  helperText: hasFrequency
                                      ? t(
                                          'Lascia vuoto per continuare senza una scadenza automatica.',
                                          'Leave empty to continue without an automatic expiry.',
                                        )
                                      : null,
                                ),
                            onChanged: (_) =>
                                scheduleDialogRefresh(setDialogState),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue:
                                <String>['turni', 'tiri'].contains(durationUnit)
                                ? durationUnit
                                : 'turni',
                            dropdownColor: const Color(0xFF10121A),
                            decoration: fieldDecoration(
                              t('Durata misurata in', 'Duration measured in'),
                            ),
                            items: <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                value: 'turni',
                                child: Text(t('Turni', 'Turns')),
                              ),
                              DropdownMenuItem(
                                value: 'tiri',
                                child: Text(t('Tiri', 'Rolls')),
                              ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              durationUnit = value ?? 'turni';
                            }),
                          ),
                        ],
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: recipient,
                          dropdownColor: const Color(0xFF10121A),
                          decoration: fieldDecoration(
                            t('Bersaglio', 'Recipient'),
                          ),
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'se_stesso',
                              child: Text(t('Se stesso', 'Self')),
                            ),
                            DropdownMenuItem(
                              value: 'bersaglio',
                              child: Text(t('Bersaglio', 'Target')),
                            ),
                            DropdownMenuItem(
                              value: 'area',
                              child: Text(t('Area', 'Area')),
                            ),
                          ],
                          onChanged: (value) => setDialogState(() {
                            recipient = value ?? 'se_stesso';
                          }),
                        ),
                        const SizedBox(height: 10),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          initiallyExpanded: advancedExpanded,
                          onExpansionChanged: (value) {
                            advancedExpanded = value;
                          },
                          title: Text(
                            t('Opzioni avanzate', 'Advanced options'),
                            style: TextStyle(
                              color: tertiaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            TextField(
                              controller: diceController,
                              decoration: fieldDecoration(
                                t('Dadi all’attivazione', 'Dice on activation'),
                              ).copyWith(helperText: '1d6, 2d8+2'),
                              onChanged: (_) =>
                                  scheduleDialogRefresh(setDialogState),
                            ),
                            const SizedBox(height: 4),
                            smallInfoText(
                              t(
                                'I dadi vengono lanciati soltanto all’attivazione. I tick successivi non rilanciano mai i dadi.',
                                'Dice are rolled only on activation. Later ticks never roll dice.',
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: diceDestination,
                              dropdownColor: const Color(0xFF10121A),
                              decoration: fieldDecoration(
                                t('Il dado aumenta', 'Dice increases'),
                              ),
                              items: <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  value: 'valore',
                                  child: Text(
                                    isHealing
                                        ? t(
                                            'La cura dello stesso effetto',
                                            'Healing of this effect',
                                          )
                                        : t(
                                            'Il valore dell’effetto',
                                            'Effect value',
                                          ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'durata',
                                  child: Text(t('La durata', 'Duration')),
                                ),
                              ],
                              onChanged: (value) => setDialogState(() {
                                diceDestination = value ?? 'valore';
                              }),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: includeLevel,
                              title: Text(t('Aggiungi Livello', 'Add Level')),
                              onChanged: (value) => setDialogState(() {
                                includeLevel = value;
                              }),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: includeGrade,
                              title: Text(t('Aggiungi Grado', 'Add Grade')),
                              subtitle: Text(
                                t(
                                  'Decidi quanto vale ogni punto Grado.',
                                  'Choose the value of each Grade point.',
                                ),
                              ),
                              onChanged: (value) => setDialogState(() {
                                includeGrade = value;
                              }),
                            ),
                            if (includeGrade) ...[
                              TextField(
                                controller: gradeValueController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: fieldDecoration(
                                  t('Valore di ogni Grado', 'Value per Grade'),
                                ),
                                onChanged: (_) =>
                                    scheduleDialogRefresh(setDialogState),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minimumController,
                                    keyboardType: TextInputType.number,
                                    decoration: fieldDecoration('Min'),
                                    onChanged: (_) =>
                                        scheduleDialogRefresh(setDialogState),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: maximumController,
                                    keyboardType: TextInputType.number,
                                    decoration: fieldDecoration('Max'),
                                    onChanged: (_) =>
                                        scheduleDialogRefresh(setDialogState),
                                  ),
                                ),
                              ],
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: stackable,
                              title: Text(t('Accumulabile', 'Stackable')),
                              onChanged: (value) => setDialogState(() {
                                stackable = value;
                              }),
                            ),
                            TextField(
                              controller: customController,
                              maxLines: 2,
                              decoration: fieldDecoration(
                                t(
                                  'Testo mostrato personalizzato',
                                  'Custom display text',
                                ),
                              ),
                              onChanged: (_) =>
                                  scheduleDialogRefresh(setDialogState),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: narrativeController,
                              maxLines: 3,
                              decoration: fieldDecoration(
                                t(
                                  'Testo narrativo (non modifica il comando)',
                                  'Narrative text (does not change command)',
                                ),
                              ),
                              onChanged: (_) =>
                                  scheduleDialogRefresh(setDialogState),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tertiaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tertiaryColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 17,
                                    color: tertiaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t('Anteprima completa', 'Full preview'),
                                    style: TextStyle(
                                      color: tertiaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(preview),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  enabled
                                      ? t('attivo', 'enabled')
                                      : t('disattivato', 'disabled'),
                                  structuredEffectTypeLabel(type),
                                  recipient == 'se_stesso'
                                      ? t('su di te', 'on self')
                                      : recipient == 'area'
                                      ? t('in area', 'in an area')
                                      : t('sul bersaglio', 'on target'),
                                  if (hasFrequency)
                                    '${t('ogni', 'every')} ${frequencyController.text} $durationUnit',
                                  if (supportsDuration &&
                                      durationController.text.trim().isNotEmpty)
                                    '${t('durata', 'duration')}: ${durationController.text} $durationUnit',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final effect = currentEffect();
                      if (effect.valueExpression.trim().isEmpty) {
                        setDialogState(() {
                          error = t(
                            'Inserisci almeno un valore o una formula.',
                            'Enter at least one value or formula.',
                          );
                        });
                        return;
                      }
                      if (needsTarget && effect.target.trim().isEmpty) {
                        setDialogState(() {
                          error = t(
                            'Seleziona cosa modificare.',
                            'Select what to modify.',
                          );
                        });
                        return;
                      }
                      if (isCost &&
                          !oculumIsConsumableEffectResource(
                            effect.resource,
                            subtraits: hiddenEyeStats,
                          )) {
                        setDialogState(() {
                          error = t(
                            'Un sottotratto non può essere consumato.',
                            'A subtrait cannot be consumed.',
                          );
                        });
                        return;
                      }
                      if (effect.diceExpression.trim().isNotEmpty) {
                        try {
                          oculumRollEffectDice(
                            effect.diceExpression,
                            random: Random(1),
                          );
                        } catch (exception) {
                          setDialogState(() => error = '$exception');
                          return;
                        }
                      }
                      Navigator.pop(dialogContext, effect);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(t('Salva effetto', 'Save effect')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      dialogRefreshTimer?.cancel();
      valueController.dispose();
      targetController.dispose();
      durationController.dispose();
      frequencyController.dispose();
      diceController.dispose();
      gradeValueController.dispose();
      minimumController.dispose();
      maximumController.dispose();
      narrativeController.dispose();
      customController.dispose();
      elementTypeController.dispose();
    }
  }

  Widget structuredEffectsEditor({
    required List<OculumStructuredEffect> effects,
    required VoidCallback onChanged,
    String freeText = '',
    List<OculumStructuredEffect>? previousEffects,
    String storageId = '',
  }) {
    Future<void> editEffect(int? index) async {
      final updated = await showStructuredEffectDialog(
        initial: index == null ? null : effects[index],
      );
      if (updated == null || !mounted) return;
      setState(() {
        if (index == null) {
          effects.add(updated);
        } else {
          effects[index] = updated;
        }
        onChanged();
      });
      programmaSalvataggio();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tertiaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: tertiaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Effetti strutturati', 'Structured effects'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('${effects.length}'),
            ],
          ),
          const SizedBox(height: 5),
          smallInfoText(
            t(
              'Facoltativi: il testo libero resta invariato. Gli effetti sono risolti nell’ordine mostrato.',
              'Optional: free text stays unchanged. Effects resolve in the shown order.',
            ),
          ),
          if (effects.isNotEmpty) ...[
            const SizedBox(height: 8),
            ReorderableListView.builder(
              key: ValueKey('structured_effects_$storageId'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: effects.length,
              // Compatibilità Flutter 3.41/3.44: onReorderItem non è
              // disponibile nelle versioni locali precedenti.
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final effect = effects.removeAt(oldIndex);
                  effects.insert(newIndex, effect);
                  onChanged();
                });
                programmaSalvataggio();
              },
              itemBuilder: (context, index) {
                final effect = effects[index];
                return Card(
                  key: ValueKey('${storageId}_${effect.id}'),
                  color: Colors.white.withValues(alpha: 0.045),
                  child: ListTile(
                    leading: Switch.adaptive(
                      value: effect.enabled,
                      onChanged: (value) {
                        setState(() {
                          effect.enabled = value;
                          onChanged();
                        });
                        programmaSalvataggio();
                      },
                    ),
                    title: Text(structuredEffectTypeLabel(effect.type)),
                    subtitle: Text(
                      oculumStructuredEffectDescription(
                        effect,
                        subtraits: hiddenEyeStats,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => unawaited(editEffect(index)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          unawaited(editEffect(index));
                          return;
                        }
                        setState(() {
                          if (action == 'duplicate') {
                            effects.insert(index + 1, effect.copyWithNewId());
                          } else if (action == 'delete') {
                            effects.removeAt(index);
                          }
                          onChanged();
                        });
                        programmaSalvataggio();
                      },
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(t('Modifica', 'Edit')),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text(t('Duplica', 'Duplicate')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(t('Elimina', 'Delete')),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => unawaited(editEffect(null)),
                icon: const Icon(Icons.add),
                label: Text(t('Aggiungi effetto', 'Add effect')),
              ),
              if (previousEffects != null)
                OutlinedButton.icon(
                  onPressed: previousEffects.isEmpty
                      ? null
                      : () {
                          setState(() {
                            effects
                              ..clear()
                              ..addAll(
                                previousEffects.map(
                                  (effect) => effect.copyForNextForm(),
                                ),
                              );
                            onChanged();
                          });
                          programmaSalvataggio();
                        },
                  icon: const Icon(Icons.content_copy),
                  label: Text(
                    t(
                      'Copia dalla forma precedente',
                      'Copy from previous form',
                    ),
                  ),
                ),
              if (freeText.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    final parsed = oculumParseStructuredEffectsFromText(
                      freeText,
                      subtraits: hiddenEyeStats,
                    );
                    if (parsed.effects.isEmpty) {
                      setState(() {
                        risultato = t(
                          'Nessun effetto riconosciuto. Il testo originale è stato conservato.',
                          'No effect recognized. Original text was preserved.',
                        );
                      });
                      return;
                    }
                    setState(() {
                      effects.addAll(parsed.effects);
                      onChanged();
                      risultato = parsed.unrecognizedText.isEmpty
                          ? t(
                              'Effetti riconosciuti. Il testo originale è stato conservato.',
                              'Effects recognized. Original text was preserved.',
                            )
                          : '${t('Parte non riconosciuta', 'Unrecognized part')}: '
                                '${parsed.unrecognizedText}';
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    t('Riconosci testo libero', 'Recognize free text'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
