part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

class _MasterHexTokenClipper extends CustomClipper<Path> {
  const _MasterHexTokenClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.50, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.50, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant _MasterHexTokenClipper oldClipper) => false;
}

class _MasterHexTokenBorderPainter extends CustomPainter {
  const _MasterHexTokenBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _MasterHexTokenClipper().getClip(size);
    final fill = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, size.shortestSide * 0.025);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _MasterHexTokenBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

extension _OculumHomeSecondaryPages on _OculumHomePageState {
  // RIPOSO
  // =====================================================

  Future<void> mostraDialogValoreRiposo({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) async {
    final controller = TextEditingController(text: value.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        const dialogBackground = Color(0xFF10121A);
        final dialogAccent = readableOnTheme(
          tertiaryColor,
          background: dialogBackground,
          minRatio: 4.5,
        );
        return AlertDialog(
          backgroundColor: dialogBackground,
          title: Text(
            cleanUiText(label),
            style: TextStyle(color: dialogAccent, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: fieldDecoration(t('Valore', 'Value')),
            onSubmitted: (value) {
              Navigator.pop(context, int.tryParse(value.trim()) ?? 0);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Annulla', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  int.tryParse(controller.text.trim()) ?? 0,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogAccent,
                foregroundColor: readableOnTheme(
                  Colors.white,
                  background: dialogAccent,
                ),
              ),
              child: Text(t('Applica', 'Apply')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) return;
    onChanged(result);
  }

  Widget restEditableTile({
    required String label,
    required int value,
    required Color color,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required VoidCallback onTap,
    IconData icon = Icons.tune,
    bool allowNegative = true,
  }) {
    const tileFill = Color(0xFF080A12);
    final accentColor = readableOnTheme(
      color,
      background: tileFill,
      minRatio: 3.2,
    );
    final positive = value > 0;
    final negative = value < 0;
    final valueColor = negative
        ? Colors.redAccent
        : positive
        ? Colors.greenAccent
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tileFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.72)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cleanUiText(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${positive ? '+' : ''}$value',
                  maxLines: 1,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: IconButton.filledTonal(
                      tooltip: '-1',
                      onPressed: !allowNegative && value <= 0 ? null : onMinus,
                      icon: const Icon(Icons.remove),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: IconButton.filledTonal(
                      tooltip: '+1',
                      onPressed: onPlus,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget restEditableGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  Widget restCalendarPanel() {
    final currentDay = oculumCurrentDay();
    final currentPhase = oculumPhaseForDay(currentDay);
    final phaseDay = oculumDayInPhase(currentDay);
    final phases = oculumCalendarPhases();

    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Giorni e Ciclo Oculum', 'Oculum Days and Cycle'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Giorno = 9 ore. Tremana = 3 giorni, Semana = 6 giorni, Dodemana = 12 giorni. Nuova Fase = stagione mutabile. Ciclo Pieno = 369 giorni.',
              'Day = 9 hours. Tremana = 3 days, Semana = 6 days, Dodemana = 12 days. New Phase = mutable season. Full Cycle = 369 days.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: currentPhase.id,
                  dropdownColor: const Color(0xFF10121A),
                  decoration: fieldDecoration(t('Nuova Fase', 'New Phase')),
                  items: [
                    for (final phase in phases)
                      DropdownMenuItem(
                        value: phase.id,
                        child: Text(
                          cleanUiText(t(phase.nameIt, phase.nameEn)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final phase = phases.firstWhere(
                      (item) => item.id == value,
                      orElse: () => phases.first,
                    );
                    impostaGiornoOculum(phase.startDay);
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  initialValue: phaseDay
                      .clamp(1, currentPhase.duration)
                      .toInt(),
                  dropdownColor: const Color(0xFF10121A),
                  decoration: fieldDecoration(t('Giorno fase', 'Phase day')),
                  items: [
                    for (var i = 1; i <= currentPhase.duration; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text('$i/${currentPhase.duration}'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    impostaGiornoOculum(currentPhase.startDay + value - 1);
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: campoTesto(
                  label: t('Giorno ciclo', 'Cycle day'),
                  controller: oculumCurrentDayController,
                  helper: '1-369',
                ),
              ),
              IconButton.filledTonal(
                tooltip: t('Applica giorno', 'Apply day'),
                onPressed: () => impostaGiornoOculum(
                  leggiNumero(oculumCurrentDayController),
                ),
                icon: const Icon(Icons.check),
              ),
              IconButton.filledTonal(
                tooltip: t('Giorno precedente', 'Previous day'),
                onPressed: () => avanzaGiorniOculum(-1),
                icon: const Icon(Icons.remove),
              ),
              IconButton.filledTonal(
                tooltip: t('Giorno successivo', 'Next day'),
                onPressed: () => avanzaGiorniOculum(1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF080A12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanUiText(oculumCurrentPhaseLabel()),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                smallInfoText(
                  t(currentPhase.descriptionIt, currentPhase.descriptionEn),
                ),
                const SizedBox(height: 8),
                smallInfoText(
                  t(
                    'Tremana ${oculumTremanaDay(currentDay)}/3 - Semana ${oculumSemanaDay(currentDay)}/6 - Dodemana ${oculumDodemanaDay(currentDay)}/12.',
                    'Tremana ${oculumTremanaDay(currentDay)}/3 - Semana ${oculumSemanaDay(currentDay)}/6 - Dodemana ${oculumDodemanaDay(currentDay)}/12.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget restForceStatePanel() {
    final active = statoForzaAttivo.trim().isNotEmpty;
    final threshold = sogliaStatoForzaHp();
    final hp = hpCorrenti();

    return gothicPanel(
      borderColor: active ? Colors.orangeAccent : secondaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.local_fire_department : Icons.bolt,
                color: active ? Colors.orangeAccent : secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Stato di Forza', 'Force State'),
                  style: TextStyle(
                    color: active ? Colors.orangeAccent : secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cleanUiText(statoForzaNomeAttivo()),
            style: TextStyle(
              color: active ? Colors.orangeAccent : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          smallInfoText(statoForzaDescrizioneAttiva()),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Soglia: $hp/$threshold HP. Si attiva quando scendi a un quarto della vita massima o meno.',
              'Threshold: $hp/$threshold HP. It activates when you drop to one quarter of maximum life or lower.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: hp <= threshold ? controllaStatoForzaDopoHp : null,
                icon: const Icon(Icons.casino),
                label: Text(t('Controlla soglia', 'Check threshold')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    statoForzaAttivo = '';
                    statoForzaPronto = true;
                    statoForzaTiriRimanenti = 0;
                    risultato = t(
                      'Stato di forza resettato.',
                      'Force state reset.',
                    );
                    ultimoEventoRiposo = risultato;
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
                icon: const Icon(Icons.refresh),
                label: Text(t('Reset', 'Reset')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget restSurvivalOverviewPanel() {
    final cenere = max(0, leggiNumero(cenereController));
    final faces = cenere >= 3 ? dadoSvenimentoCenere(cenere) : 120;
    final difficulty = difficoltaSvenimentoCenere(cenere);
    final bonus = bonusSvenimentoCenere();

    Widget chip({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.66)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              cleanUiText(label),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              cleanUiText(value),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return gothicPanel(
      borderColor: personaggioSvenuto ? Colors.redAccent : eyePupilGlowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                personaggioSvenuto ? Icons.visibility_off : Icons.monitor_heart,
                color: personaggioSvenuto
                    ? Colors.redAccent
                    : eyePupilGlowColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Sopravvivenza rapida', 'Quick survival'),
                  style: TextStyle(
                    color: personaggioSvenuto
                        ? Colors.redAccent
                        : eyePupilGlowColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (personaggioSvenuto)
                OutlinedButton.icon(
                  onPressed: svegliaDaSvenimento,
                  icon: const Icon(Icons.visibility),
                  label: Text(t('Sveglia', 'Wake up')),
                ),
              if (schedaAttivaCaduta)
                OutlinedButton.icon(
                  onPressed: effettuaTiroMorteSchedaAttiva,
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(t('Tiro morte', 'Death save')),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(
                icon: Icons.local_fire_department,
                label: 'Cenere',
                value: '$cenere',
                color: Colors.orangeAccent,
              ),
              chip(
                icon: Icons.casino,
                label: t('Controllo', 'Check'),
                value: cenere >= 3 ? '1d$faces+$bonus > $difficulty' : '-',
                color: tertiaryColor,
              ),
              chip(
                icon: personaggioSvenuto
                    ? Icons.visibility_off
                    : Icons.visibility,
                label: t('Stato', 'State'),
                value: personaggioSvenuto
                    ? t('Incosciente', 'Unconscious')
                    : t('Cosciente', 'Conscious'),
                color: personaggioSvenuto ? Colors.redAccent : Colors.green,
              ),
              chip(
                icon: Icons.calendar_today,
                label: t('Giorno', 'Day'),
                value: '${oculumCurrentDay()}',
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Da 3 Cenere in poi ogni aumento controlla lo svenimento. Il tiro resta nei log completi; qui vedi solo lo stato e la soglia.',
              'From 3 Ash onward every increase checks fainting. The roll stays in the full logs; here you only see state and threshold.',
            ),
          ),
          if (cenere >= 3 && cenere > cenereSvenimentoUltimoControllo) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  final svenimento = controllaCenereModificataManualmente();
                  if (svenimento == null || svenimento.trim().isEmpty) {
                    risultato = t(
                      'La Cenere è già stata controllata fino al valore attuale.',
                      'Ash has already been checked up to the current value.',
                    );
                  } else {
                    risultato = svenimento;
                  }
                  ultimoEventoRiposo = risultato;
                  aggiungiLog(risultato);
                });
                programmaSalvataggio();
              },
              icon: const Icon(Icons.casino),
              label: Text(t('Controlla Cenere', 'Check Ash')),
            ),
          ],
        ],
      ),
    );
  }

  Widget restPage() {
    return responsivePageList(
      pageKey: 'rest',
      maxColumns: 2,
      minColumnWidth: 330,
      masonryColumns: true,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor(
          'rest_root',
          sectionTitle(t('Riposo / Stati', 'Rest / Conditions')),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Ultimo evento', 'Last event'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(ultimoEventoRiposo),
            ],
          ),
        ),
        restCalendarPanel(),
        restForceStatePanel(),
        restSurvivalOverviewPanel(),
        sectionTitle(
          t('Buff e Debuff Temporanei', 'Temporary Buffs and Debuffs'),
        ),
        restEditableGrid([
          restEditableTile(
            label: 'RES',
            value: tempResilienza,
            color: const Color(0xFF2ECC71),
            icon: Icons.favorite,
            onMinus: () =>
                impostaBuffTemporaneo('resilienza', tempResilienza - 1),
            onPlus: () =>
                impostaBuffTemporaneo('resilienza', tempResilienza + 1),
            onTap: () => mostraDialogValoreRiposo(
              label: t('Resilienza temporanea', 'Temporary Resilience'),
              value: tempResilienza,
              onChanged: (value) => impostaBuffTemporaneo('resilienza', value),
            ),
          ),
          restEditableTile(
            label: 'VOL',
            value: tempVolonta,
            color: const Color(0xFFE74C3C),
            icon: Icons.psychology,
            onMinus: () => impostaBuffTemporaneo('volonta', tempVolonta - 1),
            onPlus: () => impostaBuffTemporaneo('volonta', tempVolonta + 1),
            onTap: () => mostraDialogValoreRiposo(
              label: t('Volonta temporanea', 'Temporary Will'),
              value: tempVolonta,
              onChanged: (value) => impostaBuffTemporaneo('volonta', value),
            ),
          ),
          restEditableTile(
            label: 'MAT',
            value: tempMateria,
            color: const Color(0xFF44A7FF),
            icon: Icons.diamond,
            onMinus: () => impostaBuffTemporaneo('materia', tempMateria - 1),
            onPlus: () => impostaBuffTemporaneo('materia', tempMateria + 1),
            onTap: () => mostraDialogValoreRiposo(
              label: t('Materia temporanea', 'Temporary Materia'),
              value: tempMateria,
              onChanged: (value) => impostaBuffTemporaneo('materia', value),
            ),
          ),
          restEditableTile(
            label: 'OCU',
            value: tempOculum,
            color: oculumStatFormulaColor,
            icon: Icons.visibility,
            onMinus: () => impostaBuffTemporaneo('oculum', tempOculum - 1),
            onPlus: () => impostaBuffTemporaneo('oculum', tempOculum + 1),
            onTap: () => mostraDialogValoreRiposo(
              label: t('Oculum temporaneo', 'Temporary Oculum'),
              value: tempOculum,
              onChanged: (value) => impostaBuffTemporaneo('oculum', value),
            ),
          ),
        ]),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('Buff/Malus @ uniti', 'Unified @ Buffs/Debuffs'),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Scrivi qui bonus e malus rapidi con @. Esempi: @Difesa-¼, @Danni+1OnHit, @Vol+1=-10HP, @HP+1=Vol-1.',
                  'Write quick @ buffs and debuffs here. Examples: @Defense-¼, @Damage+1OnHit, @Will+1=-10HP, @HP+1=Will-1.',
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t(
                  'Buff/Malus e trigger testuali',
                  'Text buffs/debuffs and triggers',
                ),
                controller: buffMalusRapidiController,
                numero: false,
                maxLines: 4,
                enableCommandAutocomplete: true,
              ),
              const SizedBox(height: 10),
              smallInfoText(
                t(
                  'Fatica: oltre ${sogliaFaticaSenzaMalus()} stati di Cenere ricevi ${malusFaticaTiri()} ai tiri.',
                  'Fatigue: beyond ${sogliaFaticaSenzaMalus()} Ash states you receive ${malusFaticaTiri()} to rolls.',
                ),
              ),
            ],
          ),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Stati di Sopravvivenza', 'Survival Conditions'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'La Cenere rappresenta stanchezza, consumo interno, fame, sete, stress fisico e corrosione dell’Oculum. Alcune attività la aumentano, il riposo la riduce.',
                  'Ash represents exhaustion, inner consumption, hunger, thirst, physical stress and Oculum corrosion. Some activities increase it, rest reduces it.',
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: 'Cenere',
                controller: cenereController,
                onChanged: (_) {
                  setState(() {
                    final svenimento = controllaCenereModificataManualmente();
                    if (svenimento == null || svenimento.trim().isEmpty) {
                      return;
                    }
                    ultimoEventoRiposo =
                        '${t('Cenere aggiornata manualmente.', 'Ash updated manually.')}\n$svenimento';
                    risultato = ultimoEventoRiposo;
                    aggiungiLog(risultato);
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: campoTesto(
                      label: t('Giorni senza bisogni', 'Days without needs'),
                      controller: sessioniSenzaBisogniController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: campoTesto(
                      label: t(
                        'Giorni senza cibo/acqua',
                        'Days without food/water',
                      ),
                      controller: giorniSenzaCiboAcquaController,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        sectionTitle(t('Bisogni', 'Needs')),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            children: [
              restButton(
                label: t('Mangia e Bevi', 'Eat and Drink'),
                icon: Icons.restaurant,
                color: Colors.green.shade700,
                onPressed: mangiaEBevi,
              ),
              const SizedBox(height: 10),
              restButton(
                label: t(
                  'Segna Giorno senza Mangiare / Bere / Dormire',
                  'Mark Day without Eating / Drinking / Sleeping',
                ),
                icon: Icons.warning_amber,
                color: Colors.deepOrange.shade700,
                onPressed: segnaSessioneSenzaBisogni,
              ),
              const SizedBox(height: 10),
              restButton(
                label: t(
                  'Giorno senza Cibo o Acqua',
                  'Day without Food or Water',
                ),
                icon: Icons.dangerous,
                color: Colors.red.shade800,
                onPressed: segnaGiornoSenzaCiboAcqua,
              ),
            ],
          ),
        ),
        sectionTitle(t('Riposi', 'Rests')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallInfoText(
                t(
                  'Il riposo breve è utile per recuperare parte delle penalità, ma non cancella completamente il peso della giornata. Il riposo lungo porta gli HP ad almeno il 75% del massimale.',
                  'Short rest helps recover part of the penalties, but it does not fully erase the weight of the day. Long rest brings HP to at least 75% of maximum.',
                ),
              ),
              const SizedBox(height: 12),
              restButton(
                label: t('Riposo Breve', 'Short Rest'),
                icon: Icons.nightlight_round,
                color: secondaryColor,
                onPressed: riposoBreve,
              ),
              const SizedBox(height: 10),
              restButton(
                label: t(
                  'Riposo Lungo — 1 ora e mezza',
                  'Long Rest — 1.5 hours',
                ),
                icon: Icons.hotel,
                color: tertiaryColor,
                onPressed: riposoLungo,
              ),
            ],
          ),
        ),
        sectionTitle(t('Attività Pesanti', 'Heavy Activities')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallInfoText(
                t(
                  'Queste attività consumano temporaneamente il personaggio. Servono per raccolta, pesca, caccia, forgiatura o creazioni rituali.',
                  'These activities temporarily consume the character. They are used for gathering, fishing, hunting, forging or ritual crafting.',
                ),
              ),
              const SizedBox(height: 12),
              restButton(
                label: t(
                  'Raccolta / Pesca / Caccia: -1 Volontà, +1 Cenere',
                  'Gathering / Fishing / Hunting: -1 Will, +1 Ash',
                ),
                icon: Icons.forest,
                color: secondaryColor,
                onPressed: attivitaRaccoltaPescaCaccia,
              ),
              const SizedBox(height: 10),
              restButton(
                label: t(
                  'Forgiatura con Materia: -1 Materia, +1 Cenere',
                  'Forging with Materia: -1 Materia, +1 Ash',
                ),
                icon: Icons.hardware,
                color: primaryColor,
                onPressed: forgiaturaConMateria,
              ),
              const SizedBox(height: 10),
              restButton(
                label: t(
                  'Forgiatura con Oculum: -1 Oculum, +1 Cenere',
                  'Forging with Oculum: -1 Oculum, +1 Ash',
                ),
                icon: Icons.visibility,
                color: tertiaryColor,
                onPressed: forgiaturaConOculum,
              ),
            ],
          ),
        ),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Consumo registrato', 'Recorded consumption'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              restEditableGrid([
                restEditableTile(
                  label: t('RES spesa', 'Spent RES'),
                  value: raccoltaResilienzaSpesa,
                  color: const Color(0xFF2ECC71),
                  icon: Icons.favorite_border,
                  allowNegative: false,
                  onMinus: () => modificaConsumoRegistrato('resilienza', -1),
                  onPlus: () => modificaConsumoRegistrato('resilienza', 1),
                  onTap: () => mostraDialogValoreRiposo(
                    label: t('Resilienza spesa', 'Spent Resilience'),
                    value: raccoltaResilienzaSpesa,
                    onChanged: (value) =>
                        impostaConsumoRegistrato('resilienza', value),
                  ),
                ),
                restEditableTile(
                  label: t('VOL spesa', 'Spent VOL'),
                  value: raccoltaVolontaSpesa,
                  color: const Color(0xFFE74C3C),
                  icon: Icons.psychology_alt,
                  allowNegative: false,
                  onMinus: () => modificaConsumoRegistrato('volonta', -1),
                  onPlus: () => modificaConsumoRegistrato('volonta', 1),
                  onTap: () => mostraDialogValoreRiposo(
                    label: t('Volonta spesa', 'Spent Will'),
                    value: raccoltaVolontaSpesa,
                    onChanged: (value) =>
                        impostaConsumoRegistrato('volonta', value),
                  ),
                ),
                restEditableTile(
                  label: t('MAT spesa', 'Spent MAT'),
                  value: raccoltaMateriaSpesa,
                  color: const Color(0xFF44A7FF),
                  icon: Icons.diamond_outlined,
                  allowNegative: false,
                  onMinus: () => modificaConsumoRegistrato('materia', -1),
                  onPlus: () => modificaConsumoRegistrato('materia', 1),
                  onTap: () => mostraDialogValoreRiposo(
                    label: t('Materia spesa', 'Spent Materia'),
                    value: raccoltaMateriaSpesa,
                    onChanged: (value) =>
                        impostaConsumoRegistrato('materia', value),
                  ),
                ),
                restEditableTile(
                  label: t('OCU speso', 'Spent OCU'),
                  value: raccoltaOculumSpesa,
                  color: oculumStatFormulaColor,
                  icon: Icons.visibility_outlined,
                  allowNegative: false,
                  onMinus: () => modificaConsumoRegistrato('oculum', -1),
                  onPlus: () => modificaConsumoRegistrato('oculum', 1),
                  onTap: () => mostraDialogValoreRiposo(
                    label: t('Oculum speso', 'Spent Oculum'),
                    value: raccoltaOculumSpesa,
                    onChanged: (value) =>
                        impostaConsumoRegistrato('oculum', value),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              restButton(
                label: t(
                  'Reset Buff/Debuff Temporanei',
                  'Reset Temporary Buffs/Debuffs',
                ),
                icon: Icons.restart_alt,
                color: Colors.grey.shade700,
                onPressed: resetBuffDebuffTemporanei,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // RISORSE
  // =====================================================

  Widget obserStoneIcon() {
    return SizedBox(
      width: 44,
      height: 44,
      child: Image.asset(
        'assets/oculum/obser.png',
        cacheWidth: oculumImageCacheDimension(context, 44, max: 160),
        cacheHeight: oculumImageCacheDimension(context, 44, max: 160),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: const Size(44, 44),
          painter: ObserStonePainter(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            tertiaryColor: tertiaryColor,
          ),
        ),
      ),
    );
  }

  Widget resourceCounter({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    int? cap,
    VoidCallback? onUse,
    VoidCallback? onAltUse,
    String? useLabel,
    String? altUseLabel,
    Widget? customIcon,
    bool isMasterControl = false,
  }) {
    bool canEdit = !isMasterControl || haPermessiMaster;
    final current = leggiNumero(controller);
    final isFull = cap != null && cap > 0 && current >= cap;
    final activeColor = isFull ? Colors.redAccent : color;

    return gothicPanel(
      borderColor: activeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              customIcon ?? Icon(icon, color: activeColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                cap == null ? controller.text : '${controller.text}/$cap',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isFull ? Colors.redAccent : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(subtitle),
          if (canEdit) ...[
            const SizedBox(height: 12),
            campoTesto(
              label: t('Modifica rapidamente', 'Quick edit'),
              controller: controller,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => modificaRisorsa(controller, -1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('-1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => modificaRisorsa(controller, 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: color.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: const Text('+1'),
                  ),
                ),
              ],
            ),
          ],
          if (onUse != null) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.auto_awesome),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              label: Text(useLabel ?? t('Usa', 'Use')),
            ),
          ],
          if (onAltUse != null) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onAltUse,
              icon: const Icon(Icons.call_split),
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              label: Text(altUseLabel ?? t('Alternativa', 'Alternative')),
            ),
          ],
        ],
      ),
    );
  }

  Widget fortunaResourcePanel() {
    const color = Color(0xFF9BE564);
    return gothicPanel(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('Fortuna', 'Luck'),
                  style: const TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$fortuna',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Risorsa consumabile: puoi spenderla per aggiungere +1 a stats, attacco, difesa e iniziativa tramite bonus rapidi.',
              'Consumable resource: spend it to add +1 to stats, attack, defense and initiative through quick bonuses.',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => modificaFortuna(-1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('-1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => modificaFortuna(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('+1'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: fortuna > 0 ? usaFortunaRapida : null,
            icon: const Icon(Icons.add_task),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Usa Fortuna', 'Use Luck')),
          ),
        ],
      ),
    );
  }

  Widget schivataOculumResourcePanel() {
    final available = schivateOculumDisponibili();
    final total = schivateOculumTotali();
    return gothicPanel(
      borderColor: eyePupilGlowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: eyePupilGlowColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('Schivata Oculum', 'Oculum Dodge'),
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$available/$total',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Difesa consumabile: si prepara dal menu e viene consumata al prossimo danno. Non si ricarica con riposo, refull o turni.',
              'Consumable defense: prepare it from the menu and it is spent on the next damage. It does not recharge with rest, refill or turns.',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: available > 0 ? mostraMenuSchivataOculum : null,
            icon: const Icon(Icons.visibility),
            style: ElevatedButton.styleFrom(
              backgroundColor: eyePupilGlowColor,
              foregroundColor: eyePupilGlowColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Prepara Schivata', 'Prepare Dodge')),
          ),
        ],
      ),
    );
  }

  Widget oculumRollSpendPanel() {
    final cap = oculumTiroSpendCap();
    final prepared = oculumTiroPreparato();
    final ruleCap = oculumTiroLimiteRegola();
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ads_click, color: primaryColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('Oculum nei tiri fight', 'Oculum fight rolls'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$prepared/$cap',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Prepara punti Oculum per il prossimo tiro fight: 1 punto ogni 3 livelli, massimo 3 ogni 3 Gradi. Al livello 9 senza Grado arrivi a 3. Ogni punto vale +3.',
              'Prepare Oculum for the next fight roll: 1 point every 3 levels, max 3 every 3 Grades. At level 9 without Grade you reach 3. Each point is +3.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Limite regola: $ruleCap | Oculum attuale: ${currentOculum()}',
              'Rule cap: $ruleCap | Current Oculum: ${currentOculum()}',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: prepared > 0
                      ? () => preparaOculumTiroDelta(-1)
                      : null,
                  child: const Text('-1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: t('Preparati', 'Prepared'),
                  controller: oculumTiroController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: prepared < cap
                      ? () => preparaOculumTiroDelta(1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: primaryColor.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: const Text('+1'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget folliaResourcePanel() {
    final value = follia();
    final encounterChance = folliaIncontroPercentuale();
    final totalDamage = folliaDannoConvertibile(totale: true);
    final partialDamage = folliaDannoConvertibile();
    return gothicPanel(
      borderColor: Colors.purpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt,
                color: Colors.purpleAccent,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('Follia', 'Madness'),
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Fa vedere e toccare il soprannaturale, ma gli Incubi notano il personaggio. Se non hai Illness Art, ogni tick preso infligge 1 danno. Mangiare o riposare rimuove 1 tick.',
              'Lets the character see and touch the supernatural, but Nightmares notice them. Without Illness Art, each gained tick deals 1 damage. Eating or resting removes 1 tick.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Chance errati: $encounterChance% | Danno convertibile: $partialDamage parziale / $totalDamage totale',
              'Wrong-ghost chance: $encounterChance% | Convertible damage: $partialDamage partial / $totalDamage total',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: folliaDaMostri,
            onChanged: (value) {
              setState(() => folliaDaMostri = value);
              programmaSalvataggio();
            },
            title: Text(t('Follia data da mostri', 'Madness from monsters')),
            subtitle: Text(
              t(
                'Sblocca gli errati nel generatore Master se il party ha almeno 1 Follia.',
                'Unlocks wrong ghosts in the Master generator if the party has at least 1 Madness.',
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: illnessArtSbloccata,
            onChanged: (value) {
              setState(() => illnessArtSbloccata = value);
              programmaSalvataggio();
            },
            title: const Text('Illness Art'),
            subtitle: Text(
              t(
                'Non subisci il danno passivo, ma la Follia guadagnata raddoppia e aumenta la frequenza degli incontri piu forti.',
                'You avoid passive damage, but gained Madness doubles and stronger encounters become more frequent.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => modificaFollia(1),
                icon: const Icon(Icons.add),
                label: const Text('+1'),
              ),
              ElevatedButton.icon(
                onPressed: () => modificaFollia(1, daMostro: true),
                icon: const Icon(Icons.visibility_off),
                label: Text(t('+1 da mostro', '+1 from monster')),
              ),
              OutlinedButton.icon(
                onPressed: value > 0 ? () => modificaFollia(-1) : null,
                icon: const Icon(Icons.restaurant),
                label: Text(t('Mangia/Riposa -1', 'Eat/Rest -1')),
              ),
            ],
          ),
          if (rebirthato) ...[
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Nota Rinato: l immunita fino al precedente massimo stato di forza resta gestita dal Master sul limite narrativo.',
                'Reborn note: immunity up to the previous maximum force state remains Master-managed on the narrative threshold.',
              ),
              color: Colors.white54,
            ),
          ],
        ],
      ),
    );
  }

  Widget karmaPanel() {
    final karma = karmaTotale();

    return gothicPanel(
      borderColor: coloreBordoKarma(karma),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KARMA',
            style: TextStyle(
              color: coloreTestoKarma(karma),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: ombraKarma(karma),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('Karma base', 'Base Karma')}: ${karmaController.text}   '
            '${t('Karma titoli', 'Title Karma')}: ${karmaTitoli()}   '
            '${t('Totale', 'Total')}: $karma',
            style: TextStyle(
              color: Colors.grey.shade200,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(descrizioneKarmaVisivo(karma)),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Karma base manuale', 'Manual base Karma'),
            controller: karmaController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => modificaKarmaBase(-1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A1026),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('-1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => modificaKarmaBase(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tertiaryColor,
                    foregroundColor: tertiaryColor.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: const Text('+1'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget inspirationLimitsPanel() {
    Widget row(String type, TextEditingController controller) {
      final cap = inspirationCap(type);
      final current = leggiNumero(controller);
      final full = current >= cap;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: full ? Colors.redAccent : Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${inspirationLabelForType(type)}: $current/$cap',
                style: TextStyle(
                  color: full ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: current > 0
                  ? () => convertiIspirazioneInRicompense(type)
                  : null,
              icon: const Icon(Icons.currency_exchange, size: 16),
              label: Text(t('Converti 1', 'Convert 1')),
            ),
          ],
        ),
      );
    }

    return gothicPanel(
      borderColor: Colors.amber,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Limiti e conversioni Ispirazioni',
              'Inspiration caps and conversions',
            ),
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Gli extra oltre il massimale diventano automaticamente Obser, Ascension Dust e Fortuna in base alla difficolta.',
              'Extras beyond the cap automatically become Obser, Ascension Dust and Luck based on difficulty.',
            ),
          ),
          const SizedBox(height: 8),
          row('base', ispirazioniController),
          const SizedBox(height: 8),
          row('super', superIspirazioniController),
          const SizedBox(height: 8),
          row('oculum', ispirazioniOculumController),
        ],
      ),
    );
  }

  Widget resourcesPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) normalizeInspirationOverflow(silent: true);
    });

    return responsivePageList(
      pageKey: 'resources',
      maxColumns: 3,
      minColumnWidth: 290,
      children: [
        functionAnchor(
          'resources_root',
          sectionTitle(t('Risorse', 'Resources')),
        ),
        resourceCounter(
          title: 'Obser',
          subtitle: t(
            'Gli Obser non sono semplici soldi: sono pietre o monete con inciso un occhio. Possono rappresentare commercio, potere, memoria e valore rituale.',
            'Obser are not simple coins: they are stones or coins engraved with an eye. They can represent trade, power, memory and ritual value.',
          ),
          controller: obserController,
          icon: Icons.monetization_on,
          color: tertiaryColor,
          customIcon: obserStoneIcon(),
        ),
        resourceCounter(
          title: 'Ascension Dust',
          subtitle: t(
            'Polvere magica usata per forgiare, potenziare, ritualizzare e far ascendere oggetti o poteri. Può servire anche come costo narrativo per evoluzioni importanti.',
            'Magical dust used to forge, empower, ritualize and ascend items or powers. It can also serve as a narrative cost for important evolutions.',
          ),
          controller: ascensionDustController,
          icon: Icons.grain,
          color: primaryColor,
        ),
        resourceCounter(
          title: t('Ispirazioni', 'Inspirations'),
          subtitle: t(
            'Permettono di ritirare un tiro che non sia critico. Sono ricompense per roleplay, diario, scelte coerenti e momenti narrativi forti.',
            'Allow you to reroll a non-critical roll. They are rewards for roleplay, diary writing, coherent choices and strong narrative moments.',
          ),
          controller: ispirazioniController,
          icon: Icons.lightbulb,
          color: Colors.amber,
          cap: inspirationCap('base'),
          onUse: usaIspirazioneBase,
          useLabel: t('Usa Ispirazione', 'Use Inspiration'),
        ),
        resourceCounter(
          title: t('Super Ispirazioni', 'Super Inspirations'),
          subtitle: t(
            'Permettono di ritirare anche un critico. Sono più rare e vanno date per momenti veramente importanti.',
            'Allow you to reroll even a critical roll. They are rarer and should be granted for truly important moments.',
          ),
          controller: superIspirazioniController,
          icon: Icons.flash_on,
          color: Colors.orangeAccent,
          cap: inspirationCap('super'),
          onUse: usaSuperIspirazione,
          useLabel: t('Usa Super Ispirazione', 'Use Super Inspiration'),
        ),
        resourceCounter(
          title: t('Ispirazioni Oculum', 'Oculum Inspirations'),
          subtitle: t(
            'Permettono di ritirare un critico mantenendolo tale, oppure trasformarsi in 2 Ispirazioni base. Sono legate a momenti in cui l’Oculum del personaggio risponde alla storia.',
            'Allow you to reroll a critical while keeping it critical, or become 2 base Inspirations. They are tied to moments where the character’s Oculum answers the story.',
          ),
          controller: ispirazioniOculumController,
          icon: Icons.visibility,
          color: primaryColor,
          cap: inspirationCap('oculum'),
          onUse: usaIspirazioneOculum,
          useLabel: t('Usa come critico mantenuto', 'Use as kept critical'),
          onAltUse: convertiIspirazioneOculum,
          altUseLabel: t('Converti in 2 base', 'Convert into 2 base'),
        ),
        inspirationLimitsPanel(),
        fortunaResourcePanel(),
        schivataOculumResourcePanel(),
        oculumRollSpendPanel(),
        folliaResourcePanel(),
        karmaPanel(),
        diceResultPanel(),
      ],
    );
  }

  // =====================================================
  // MASTER
  // =====================================================

  Widget onlineStatusPanel({bool compatto = false}) {
    final online = onlineDisponibile;
    final color = online ? Colors.greenAccent : Colors.orangeAccent;

    return gothicPanel(
      borderColor: color,
      padding: EdgeInsets.all(compatto ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(online ? Icons.public : Icons.public_off, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online
                      ? t('Online disponibile', 'Online available')
                      : t('Modalità offline', 'Offline mode'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: compatto ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 6),
                smallInfoText(
                  online
                      ? t(
                          'I servizi live possono essere provati. Schede, tag e party restano salvati anche in locale.',
                          'Live services can be tried. Sheets, tags and party also remain saved locally.',
                        )
                      : t(
                          'Nessuna connessione verificata: la pagina Online resta aperta, ma realtime e relay possono mostrare errore finche la rete non risponde.',
                          'No verified connection: the Online page stays open, but realtime and relay may show errors until the network responds.',
                        ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t('Ricontrolla connessione', 'Recheck connection'),
            onPressed: controllaConnessioneOnline,
            icon: onlineCheckInCorso
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(Icons.refresh, color: color),
          ),
        ],
      ),
    );
  }

  Widget masterPartyAvatar(int index, {double size = 58}) {
    final image = immagineSchedaAt(index);
    final name = nomeSchedaPersonaggio(index);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tertiaryColor.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipPath(
        clipper: const HexagonClipper(),
        child: Container(
          color: secondaryColor,
          padding: const EdgeInsets.all(3),
          child: ClipPath(
            clipper: const HexagonClipper(),
            child: Container(
              color: const Color(0xFF0B0D14),
              child: image == null
                  ? Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: size * 0.34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Image.memory(
                      image,
                      fit: BoxFit.cover,
                      cacheWidth: oculumImageCacheDimension(
                        context,
                        size,
                        max: 256,
                      ),
                      cacheHeight: oculumImageCacheDimension(
                        context,
                        size,
                        max: 256,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget masterPartyHexBadge(int index) {
    final selected = sheetInMasterPartyAt(index);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => apriSchedaDaParty(index),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                masterPartyAvatar(index),
                Container(
                  decoration: BoxDecoration(
                    color: selected ? Colors.greenAccent : Colors.black87,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(
                    selected ? Icons.check : Icons.add,
                    color: selected ? Colors.black : primaryColor,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              nomeSchedaPersonaggio(index),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            Text(
              sheetTagAt(index),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tertiaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget masterPartyQuickRolls(int index) {
    final rolls = [
      ('resilienza', 'RES'),
      ('volonta', 'VOL'),
      ('materia', 'MAT'),
      ('oculum', 'OCU'),
      ('vc', 'VC'),
      ('cm', 'CM'),
      ('iniziativa', 'INI'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final roll in rolls)
          OutlinedButton(
            onPressed: () => tiraSchedaMasterParty(index, roll.$1),
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

  Widget masterPartySheetCard(int index) {
    final inParty = sheetInMasterPartyAt(index);
    final side = sheetSideAt(index);
    final sideColor = side == 'enemy'
        ? Colors.redAccent
        : side == 'neutral'
        ? Colors.orangeAccent
        : Colors.greenAccent;
    final sideOverride =
        '${schedePersonaggio[index]['masterSideOverride'] ?? ''}'.trim();

    return gothicPanel(
      borderColor: inParty ? sideColor : primaryColor,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final avatar = masterPartyHexBadge(index);
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${nomeSchedaPersonaggio(index)} • ${tipoSchedaPersonaggio(index)}',
                style: TextStyle(
                  color: inParty ? sideColor : tertiaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              smallInfoText(
                'Tag ${sheetTagAt(index)} • Lv ${sheetIntValueAt(index, 'livello')} • Grado ${sheetIntValueAt(index, 'grado')}',
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(
                  '${masterInitiativeSideLabel(side)}${sideOverride.isEmpty ? ' / Auto' : ''}',
                ),
                backgroundColor: sideColor.withValues(alpha: 0.14),
                side: BorderSide(color: sideColor.withValues(alpha: 0.72)),
                labelStyle: TextStyle(
                  color: sideColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              masterSheetMiniSummary(index),
              const SizedBox(height: 10),
              masterPartyQuickRolls(index),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => apriSchedaDaParty(index),
                    icon: const Icon(Icons.edit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: primaryColor,
                    ),
                    label: Text(t('Modifica scheda', 'Edit sheet')),
                  ),
                  if (side != 'enemy')
                    ElevatedButton.icon(
                      onPressed: () => setSheetSideOverride(index, 'enemy'),
                      icon: const Icon(Icons.flash_on),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(t('Segna nemico', 'Mark enemy')),
                    ),
                  if (side != 'ally')
                    ElevatedButton.icon(
                      onPressed: () => setSheetSideOverride(index, 'ally'),
                      icon: const Icon(Icons.shield),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        foregroundColor: Colors.black,
                      ),
                      label: Text(t('Segna alleato', 'Mark ally')),
                    ),
                  if (sideOverride.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => setSheetSideOverride(index, ''),
                      icon: const Icon(Icons.auto_fix_high),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.55),
                        ),
                      ),
                      label: Text(t('Auto lato', 'Auto side')),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => cambiaSchedaMasterParty(index, !inParty),
                    icon: Icon(inParty ? Icons.group_remove : Icons.group_add),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inParty
                          ? Colors.redAccent.shade700
                          : tertiaryColor,
                      foregroundColor: inParty
                          ? Colors.white
                          : tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(
                      inParty
                          ? t('Togli dal party', 'Remove from party')
                          : t('Aggiungi al party', 'Add to party'),
                    ),
                  ),
                  if (inParty)
                    ElevatedButton.icon(
                      onPressed: () => requestKickSheet(
                        targetId: sheetTagAt(index),
                        targetName: nomeSchedaPersonaggio(index),
                        sheetIndex: index,
                      ),
                      icon: const Icon(Icons.person_remove),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(t('Kicka', 'Kick')),
                    ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: avatar),
                const SizedBox(height: 10),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget initiativeTokenAvatar(Map<String, dynamic> token) {
    final imageRaw = '${token['imageBase64'] ?? ''}';
    final image = decodedBase64ImageCached(imageRaw);
    final spriteAssetPath = masterInitiativeTokenSpriteAsset(token);
    final size = masterInitiativeTokenSize(token).toDouble();
    final cacheSide = oculumImageCacheDimension(context, size, max: 320);
    final hexToken = masterInitiativeTokenUsesHex(token);

    final side = '${token['side'] ?? 'ally'}';
    final color = side == 'enemy'
        ? Colors.redAccent
        : side == 'neutral'
        ? Colors.orangeAccent
        : Colors.greenAccent;
    final fallbackIcon = Icon(
      side == 'enemy'
          ? Icons.bolt
          : side == 'neutral'
          ? Icons.remove_red_eye
          : Icons.shield,
      color: color,
      size: max(20, size * 0.48),
    );
    final content = image == null
        ? spriteAssetPath.isEmpty
              ? Center(child: fallbackIcon)
              : Image.asset(
                  spriteAssetPath,
                  fit: BoxFit.cover,
                  cacheWidth: cacheSide,
                  cacheHeight: cacheSide,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: fallbackIcon),
                )
        : Image.memory(
            image,
            fit: BoxFit.cover,
            cacheWidth: cacheSide,
            cacheHeight: cacheSide,
          );

    if (hexToken) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: const _MasterHexTokenClipper(),
              child: ColoredBox(color: const Color(0xFF10121A), child: content),
            ),
            CustomPaint(painter: _MasterHexTokenBorderPainter(color: color)),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: const Color(0xFF10121A),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget masterInitiativeTokenSizeControl(int index, {required bool compact}) {
    if (index < 0 || index >= masterInitiativeTokens.length) {
      return const SizedBox.shrink();
    }
    final size = masterInitiativeTokenSize(masterInitiativeTokens[index]);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: t('Rimpicciolisci token', 'Shrink token'),
            onPressed: size <= 36
                ? null
                : () => adjustMasterInitiativeTokenSize(index, -6),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_circle_outline, size: 18),
          ),
          Text(
            compact ? '$size' : '${t('Token', 'Token')} $size',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: t('Ingrandisci token', 'Enlarge token'),
            onPressed: size >= 96
                ? null
                : () => adjustMasterInitiativeTokenSize(index, 6),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_circle_outline, size: 18),
          ),
        ],
      ),
    );
  }

  Widget masterInitiativeReactionCounterControl(
    int index, {
    required bool compact,
  }) {
    if (index < 0 || index >= masterInitiativeTokens.length) {
      return const SizedBox.shrink();
    }
    final token = masterInitiativeTokens[index];
    final maxNormal = masterInitiativeReactionMax(token);
    final usedNormal = masterInitiativeReactionUsed(token);
    final maxFast = masterInitiativeFastReactionMax(token);
    final usedFast = masterInitiativeFastReactionUsedThisTurn(token);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: t('Togli una reazione', 'Remove one reaction'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
            onPressed: () => modificaMasterInitiativeReactionMax(index, -1),
            icon: const Icon(Icons.remove, size: 18),
            color: Colors.orangeAccent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              compact
                  ? 'R $usedNormal/$maxNormal'
                  : '${t('Reaz', 'React')} $usedNormal/$maxNormal',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: t('Aggiungi una reazione', 'Add one reaction'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
            onPressed: () => modificaMasterInitiativeReactionMax(index, 1),
            icon: const Icon(Icons.add, size: 18),
            color: Colors.orangeAccent,
          ),
          PopupMenuButton<String>(
            tooltip: t('Reazioni veloci', 'Fast reactions'),
            color: const Color(0xFF10121A),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.bolt,
              size: 18,
              color: maxFast > 0 ? tertiaryColor : Colors.grey,
            ),
            onSelected: (value) {
              if (value == 'fast_minus') {
                modificaMasterInitiativeReactionMax(index, -1, fast: true);
              } else if (value == 'fast_plus') {
                modificaMasterInitiativeReactionMax(index, 1, fast: true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${t('Veloci', 'Fast')} $usedFast/$maxFast',
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'fast_minus',
                child: Text(t('-1 veloce', '-1 fast')),
              ),
              PopupMenuItem(
                value: 'fast_plus',
                child: Text(t('+1 veloce', '+1 fast')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> mostraAggiungiSchedaIniziativa() async {
    final localIndexes = masterInitiativeAddableLocalSheetIndexes();
    final importedKeys = schedePersonaggio
        .map((sheet) => '${sheet['realtimeSourceKey'] ?? ''}')
        .where((key) => key.isNotEmpty)
        .toSet();
    final canUseShared = canUseSharedSheetsForMasterInitiative();
    final remoteIndexes = canUseShared
        ? [
            for (int i = 0; i < realtimeSharedSheets.length; i++)
              if (!importedKeys.contains(
                '${realtimeSharedSheets[i]['key'] ?? ''}',
              ))
                i,
          ]
        : <int>[];

    final items = <DropdownMenuItem<String>>[
      for (final index in localIndexes)
        DropdownMenuItem<String>(
          value: 'local:$index',
          child: Text(
            readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])
                ? '${t('Online', 'Online')} - ${schedePersonaggio[index]['realtimeOwnerName'] ?? '???'} - ${nomeSchedaPersonaggio(index)}'
                : '${index + 1}. ${nomeSchedaPersonaggio(index)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      for (final index in remoteIndexes)
        DropdownMenuItem<String>(
          value: 'remote:$index',
          child: Text(
            '${t('Online accesso', 'Online access')} - ${realtimeSharedSheets[index]['ownerName'] ?? '???'} - ${realtimeSharedSheets[index]['sheetName'] ?? '???'}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    if (items.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Nessuna scheda aggiungibile', 'No addable sheet'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            t(
              'Crea una scheda locale o connettiti come Master/Co-Master per vedere le schede online accessibili.',
              'Create a local sheet or connect as Master/Co-Master to see accessible online sheets.',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('OK', 'OK')),
            ),
          ],
        ),
      );
      return;
    }

    var selected = items.first.value ?? '';
    var rollInitiative = true;
    final result = await showDialog<Map<String, Object>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                t('Aggiungi da scheda', 'Add from sheet'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF11131A),
                      decoration: fieldDecoration(
                        t('Scheda disponibile', 'Available sheet'),
                      ),
                      items: items,
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => selected = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: rollInitiative,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: tertiaryColor,
                      title: Text(
                        t('Tira subito iniziativa', 'Roll initiative now'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        t(
                          'Se disattivo, entra con il solo bonus base.',
                          'If off, it enters with base bonus only.',
                        ),
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      onChanged: (value) {
                        setLocalState(() => rollInitiative = value);
                      },
                    ),
                    smallInfoText(
                      canUseShared
                          ? t(
                              'Come Master/Co-Master vedi anche le schede online accessibili. Nessun dato nuovo viene inviato online.',
                              'As Master/Co-Master you also see accessible online sheets. No new data is sent online.',
                            )
                          : t(
                              'Vedi solo le tue schede locali.',
                              'You see only your local sheets.',
                            ),
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Annulla', 'Cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, {
                    'value': selected,
                    'roll': rollInitiative,
                  }),
                  icon: const Icon(Icons.group_add),
                  label: Text(t('Aggiungi', 'Add')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final value = '${result['value'] ?? ''}';
    final roll = readBoolValue(result['roll'], fallback: true);
    final parts = value.split(':');
    if (parts.length != 2) return;
    final index = int.tryParse(parts[1]);
    if (index == null) return;

    if (parts.first == 'local') {
      addSheetToMasterInitiative(index, rollInitiative: roll);
      return;
    }

    if (parts.first == 'remote') {
      var localIndex = -1;
      setState(() {
        localIndex = ensureRealtimeSharedSheetForInitiative(index);
      });
      if (localIndex >= 0) {
        addSheetToMasterInitiative(localIndex, rollInitiative: roll);
        return;
      }
      setState(() {
        risultato = t(
          'Scheda online non disponibile per la turnistica.',
          'Online sheet not available for initiative.',
        );
        aggiungiLog(risultato);
      });
    }
  }

  Widget masterInitiativeTrackerPanel() {
    normalizeMasterInitiativeTokens();
    final compact = lightweightUi;
    final hasTokens = masterInitiativeTokens.isNotEmpty;
    final safeActive = hasTokens
        ? masterInitiativeActiveIndex
              .clamp(0, masterInitiativeTokens.length - 1)
              .toInt()
        : 0;
    final activeToken = hasTokens
        ? masterInitiativeTokens[safeActive]
        : <String, dynamic>{};

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t('Iniziativa Master', 'Master Initiative')} - ${t('Round', 'Round')} $masterInitiativeRound',
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  masterInitiativePublished
                      ? t('Live player', 'Player live')
                      : masterInitiativeManualOrder
                      ? t('Manuale', 'Manual')
                      : t('Auto', 'Auto'),
                ),
                backgroundColor: tertiaryColor.withValues(alpha: 0.16),
                side: BorderSide(color: tertiaryColor),
                labelStyle: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 9 : 12),
            decoration: BoxDecoration(
              color: tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tertiaryColor.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle, color: tertiaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasTokens
                        ? '${t('Turno attivo', 'Active turn')}: ${activeToken['name'] ?? '???'}'
                        : t('Nessun turno attivo', 'No active turn'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (hasTokens)
                  Text(
                    '${activeToken['initiativeTotal'] ?? 0}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 22 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Tracker da fight: player, NPC, neutrali, mostri, boss e summon. Pubblica ai player per far vedere l ordine finche lo chiudi o invii un aggiornamento.',
                'Fight tracker: players, NPCs, neutrals, monsters, bosses and summons. Publish to players to show the order until you close it or send an update.',
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => rollMasterInitiativeTokens(),
                icon: const Icon(Icons.casino),
                label: Text(
                  compact ? t('Tutti', 'All') : t('Rolla tutti', 'Roll all'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => rollMasterInitiativeTokens(npcOnly: true),
                icon: const Icon(Icons.smart_toy),
                label: Text(
                  compact ? 'NPC' : t('Rolla mostri/NPC', 'Roll monsters/NPCs'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: mostraAggiungiSchedaIniziativa,
                icon: const Icon(Icons.group_add),
                label: Text(
                  compact ? t('Scheda', 'Sheet') : t('Da scheda', 'From sheet'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => nextMasterInitiativeTurn(delta: -1),
                icon: const Icon(Icons.chevron_left),
                label: Text(
                  compact ? t('Prec.', 'Prev.') : t('Precedente', 'Previous'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => nextMasterInitiativeTurn(),
                icon: const Icon(Icons.chevron_right),
                label: Text(
                  compact ? t('Prox', 'Next') : t('Prossimo', 'Next'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => resetMasterInitiativeRound(),
                icon: const Icon(Icons.restart_alt),
                label: Text(
                  compact ? 'Reset' : t('Reset round', 'Reset round'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: resetMasterInitiativeActions,
                icon: const Icon(Icons.fact_check),
                label: Text(
                  compact
                      ? t('Azioni', 'Actions')
                      : t('Reset azioni', 'Reset actions'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => resetMasterInitiativeRound(increment: true),
                icon: const Icon(Icons.update),
                label: Text(compact ? '+Round' : t('Nuovo round', 'New round')),
              ),
              ElevatedButton.icon(
                onPressed: masterInitiativePublished
                    ? closeRealtimeInitiativeSnapshot
                    : publishRealtimeInitiativeSnapshot,
                icon: Icon(
                  masterInitiativePublished
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                label: Text(
                  masterInitiativePublished
                      ? t('Chiudi player', 'Close players')
                      : t('Pubblica Fight', 'Publish Fight'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    masterInitiativeManualOrder = false;
                    sortMasterInitiativeTokens(forceInitiative: true);
                    risultato = t(
                      'Ordine iniziativa automatico ripristinato.',
                      'Automatic initiative order restored.',
                    );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                  sendRealtimeInitiativeSnapshotIfPublished();
                },
                icon: const Icon(Icons.sort),
                label: Text(
                  compact ? t('Ordina', 'Sort') : t('Auto ordina', 'Auto sort'),
                ),
              ),
              TextButton.icon(
                onPressed: clearMasterInitiativeTokens,
                icon: const Icon(Icons.clear_all),
                label: Text(t('Pulisci', 'Clear')),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          gothicPanel(
            borderColor: primaryColor.withValues(alpha: 0.75),
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: masterInitiativeTokens.isEmpty,
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                title: Text(
                  t('Aggiungi partecipante manuale', 'Add manual participant'),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                leading: Icon(Icons.add, color: primaryColor),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 680;
                      final nameField = campoTesto(
                        label: t('Nome partecipante', 'Participant name'),
                        controller: masterInitiativeNameController,
                        numero: false,
                      );
                      final typeField = campoTesto(
                        label: t('Tipo', 'Type'),
                        controller: masterInitiativeTypeController,
                        numero: false,
                        helper: t(
                          'Player, NPC, Neutrale, Mostro, Boss, Summon.',
                          'Player, NPC, Neutral, Monster, Boss, Summon.',
                        ),
                      );
                      final bonusField = campoTesto(
                        label: t('Bonus iniziativa', 'Initiative bonus'),
                        controller: masterInitiativeBonusController,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          narrow
                              ? Column(
                                  children: [
                                    nameField,
                                    const SizedBox(height: 8),
                                    typeField,
                                    const SizedBox(height: 8),
                                    bonusField,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(flex: 2, child: nameField),
                                    const SizedBox(width: 8),
                                    Expanded(child: typeField),
                                    const SizedBox(width: 8),
                                    Expanded(child: bonusField),
                                  ],
                                ),
                          const SizedBox(height: 8),
                          campoTesto(
                            label: t('Note turno', 'Turn notes'),
                            controller: masterInitiativeNotesController,
                            numero: false,
                            maxLines: compact ? 1 : 2,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: addManualMasterInitiativeToken,
                              icon: const Icon(Icons.add),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tertiaryColor,
                                foregroundColor:
                                    tertiaryColor.computeLuminance() > 0.45
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              label: Text(t('Aggiungi', 'Add')),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          if (masterInitiativeTokens.isEmpty)
            smallInfoText(
              t(
                'Nessun partecipante. Aggiungine uno manualmente o tira iniziativa dalle schede del party Master.',
                'No participant. Add one manually or roll initiative from Master party sheets.',
              ),
            ),
          for (int i = 0; i < masterInitiativeTokens.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: i == masterInitiativeActiveIndex
                    ? tertiaryColor.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == masterInitiativeActiveIndex
                      ? tertiaryColor
                      : '${masterInitiativeTokens[i]['side'] ?? 'ally'}' ==
                            'enemy'
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : '${masterInitiativeTokens[i]['side'] ?? 'ally'}' ==
                            'neutral'
                      ? Colors.orangeAccent.withValues(alpha: 0.6)
                      : Colors.greenAccent.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: tertiaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      initiativeTokenAvatar(masterInitiativeTokens[i]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${masterInitiativeTokens[i]['name'] ?? '???'}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            smallInfoText(
                              '${masterInitiativeSideLabel('${masterInitiativeTokens[i]['side'] ?? 'ally'}')} - ${masterInitiativeTokens[i]['type'] ?? '???'} - Base ${masterInitiativeTokens[i]['initiativeBase'] ?? 0}',
                            ),
                            smallInfoText(
                              '${t('Tiro', 'Roll')} ${masterInitiativeTokens[i]['initiativeRoll'] ?? 0} - ${masterInitiativeStatusLabel('${masterInitiativeTokens[i]['status'] ?? 'ready'}')}',
                              color: masterInitiativeStatusColor(
                                '${masterInitiativeTokens[i]['status'] ?? 'ready'}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${masterInitiativeTokens[i]['initiativeTotal'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: t('Stato turno', 'Turn state'),
                        color: const Color(0xFF10121A),
                        icon: Icon(Icons.more_vert, color: tertiaryColor),
                        onSelected: (value) {
                          if (value == 'remove') {
                            removeMasterInitiativeTokenAt(i);
                            return;
                          }
                          if (value == 'up') {
                            moveMasterInitiativeToken(i, -1);
                            return;
                          }
                          if (value == 'down') {
                            moveMasterInitiativeToken(i, 1);
                            return;
                          }
                          if (value == 'active') {
                            setMasterInitiativeActiveIndex(i);
                            return;
                          }
                          setState(() {
                            masterInitiativeTokens[i]['status'] = value;
                            if (value == 'active') {
                              masterInitiativeActiveIndex = i;
                            }
                          });
                          programmaSalvataggio();
                          sendRealtimeInitiativeSnapshotIfPublished();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'active',
                            child: Text(masterInitiativeStatusLabel('active')),
                          ),
                          PopupMenuItem(
                            value: 'ready',
                            child: Text(masterInitiativeStatusLabel('ready')),
                          ),
                          PopupMenuItem(
                            value: 'acted',
                            child: Text(masterInitiativeStatusLabel('acted')),
                          ),
                          PopupMenuItem(
                            value: 'skipped',
                            child: Text(masterInitiativeStatusLabel('skipped')),
                          ),
                          PopupMenuItem(
                            value: 'downed',
                            child: Text(masterInitiativeStatusLabel('downed')),
                          ),
                          PopupMenuItem(
                            value: 'dead',
                            child: Text(masterInitiativeStatusLabel('dead')),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'up',
                            child: Text(t('Sposta su', 'Move up')),
                          ),
                          PopupMenuItem(
                            value: 'down',
                            child: Text(t('Sposta giu', 'Move down')),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(t('Rimuovi', 'Remove')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final token = masterInitiativeTokens[i];
                          final actionUsed = masterInitiativeActionUsed(token);
                          return OutlinedButton.icon(
                            onPressed: masterInitiativeCanToggleAction(i)
                                ? () => toggleMasterInitiativeActionUsed(i)
                                : null,
                            icon: Icon(
                              actionUsed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              foregroundColor: actionUsed
                                  ? Colors.greenAccent
                                  : primaryColor,
                              side: BorderSide(
                                color: actionUsed
                                    ? Colors.greenAccent
                                    : primaryColor,
                              ),
                            ),
                            label: Text(
                              compact
                                  ? t('Azione', 'Action')
                                  : actionUsed
                                  ? t('Azione fatta', 'Action used')
                                  : t('Azione pronta', 'Action ready'),
                            ),
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final token = masterInitiativeTokens[i];
                          final available = masterInitiativeReactionAvailable(
                            token,
                          );
                          final capacity = masterInitiativeReactionCapacity(
                            token,
                          );
                          final exhausted = capacity > 0 && available <= 0;
                          return OutlinedButton.icon(
                            onPressed: masterInitiativeCanUseReaction(i)
                                ? () => toggleMasterInitiativeReaction(i)
                                : null,
                            icon: Icon(
                              exhausted ? Icons.replay : Icons.reply,
                              size: 18,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              foregroundColor: exhausted
                                  ? Colors.orangeAccent
                                  : tertiaryColor,
                              side: BorderSide(
                                color: exhausted
                                    ? Colors.orangeAccent
                                    : tertiaryColor,
                              ),
                            ),
                            label: Text(
                              exhausted
                                  ? compact
                                        ? t('Reaz. OK', 'React OK')
                                        : t(
                                            'Ripristina reazioni',
                                            'Restore reactions',
                                          )
                                  : compact
                                  ? 'R $available/$capacity'
                                  : '${t('Usa reazione', 'Use reaction')} $available/$capacity',
                            ),
                          );
                        },
                      ),
                      masterInitiativeReactionCounterControl(
                        i,
                        compact: compact,
                      ),
                      masterInitiativeTokenSizeControl(i, compact: compact),
                      OutlinedButton.icon(
                        onPressed: () =>
                            tiraMasterInitiativeTokenQuickRoll(i, 'vc'),
                        icon: const Icon(Icons.flash_on, size: 18),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                        ),
                        label: const Text('VC'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            tiraMasterInitiativeTokenQuickRoll(i, 'cm'),
                        icon: const Icon(Icons.shield, size: 18),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: tertiaryColor,
                          side: BorderSide(color: tertiaryColor),
                        ),
                        label: const Text('CM'),
                      ),
                      if (masterInitiativeTokenIsDowned(
                        masterInitiativeTokens[i],
                      ))
                        ElevatedButton.icon(
                          onPressed: () => tryRaiseMasterInitiativeCompanion(i),
                          icon: const Icon(Icons.volunteer_activism),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(44, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: const Color(0xFF7DD3FC),
                            foregroundColor: Colors.black,
                          ),
                          label: Text(
                            compact
                                ? t('Rialza', 'Raise')
                                : t('Rialza compagno', 'Raise companion'),
                          ),
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: () => tiraMasterInitiativeHelp(i),
                          icon: const Icon(Icons.handshake),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(44, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: const Color(0xFF7EE7C8),
                            foregroundColor: Colors.black,
                          ),
                          label: Text(
                            compact
                                ? t('Aiuta', 'Help')
                                : t('Aiuta compagno', 'Help ally'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              tiraMasterInitiativeHelp(i, reaction: true),
                          icon: const Icon(Icons.reply, size: 18),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: const Color(0xFF7EE7C8),
                            side: const BorderSide(color: Color(0xFF7EE7C8)),
                          ),
                          label: Text(compact ? 'AR' : t('Aiuta R', 'Help R')),
                        ),
                      ],
                      ElevatedButton.icon(
                        onPressed: masterInitiativeCanDuplicateAction(i)
                            ? () => duplicateMasterInitiativeActionNow(i)
                            : null,
                        icon: const Icon(Icons.control_point_duplicate),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(44, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: secondaryColor,
                          foregroundColor: primaryColor,
                        ),
                        label: Text(
                          compact
                              ? t('Duplica', 'Duplicate')
                              : t('Duplica azione', 'Duplicate action'),
                        ),
                      ),
                      if (masterInitiativeTokenIsTemporary(
                        masterInitiativeTokens[i],
                      ))
                        Chip(
                          avatar: const Icon(Icons.flash_on, size: 16),
                          label: Text(
                            '${t('Azione extra', 'Extra action')} R${masterInitiativeTokens[i]['expiresRound'] ?? masterInitiativeRound}',
                          ),
                          backgroundColor: Colors.orangeAccent.withValues(
                            alpha: 0.18,
                          ),
                          side: const BorderSide(color: Colors.orangeAccent),
                          labelStyle: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (masterInitiativeReactionUsedThisRound(
                        masterInitiativeTokens[i],
                      ))
                        Builder(
                          builder: (context) {
                            final token = masterInitiativeTokens[i];
                            final used = masterInitiativeReactionUsedTotal(
                              token,
                            );
                            final capacity = masterInitiativeReactionCapacity(
                              token,
                            );
                            return Chip(
                              avatar: const Icon(Icons.reply, size: 16),
                              label: Text(
                                '${t('Reazioni usate', 'Reactions used')} $used/$capacity',
                              ),
                              backgroundColor: tertiaryColor.withValues(
                                alpha: 0.14,
                              ),
                              side: BorderSide(color: tertiaryColor),
                              labelStyle: TextStyle(
                                color: tertiaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  if (compact &&
                      '${masterInitiativeTokens[i]['notes'] ?? ''}'
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    smallInfoText(
                      '${masterInitiativeTokens[i]['notes'] ?? ''}',
                      color: Colors.grey.shade400,
                    ),
                  ],
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    campoModello(
                      fieldKey: ValueKey(
                        'master_init_note_${masterInitiativeTokens[i]['id'] ?? i}',
                      ),
                      label: t('Note', 'Notes'),
                      initialValue:
                          '${masterInitiativeTokens[i]['notes'] ?? ''}',
                      onChanged: (value) {
                        masterInitiativeTokens[i]['notes'] = value;
                      },
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget masterDashboardActiveSheetPanel() {
    if (schedePersonaggio.isEmpty) {
      return gothicPanel(
        borderColor: tertiaryColor,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Scheda attiva', 'Active sheet'),
              style: TextStyle(
                color: tertiaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Nessuna scheda disponibile. Crea una scheda rapida per iniziare.',
                'No sheet available. Create a quick sheet to start.',
              ),
            ),
          ],
        ),
      );
    }

    final index = schedaCorrente.clamp(0, schedePersonaggio.length - 1).toInt();
    final inParty = sheetInMasterPartyAt(index);
    final side = sheetSideAt(index);
    final sideColor = side == 'enemy'
        ? Colors.redAccent
        : side == 'neutral'
        ? Colors.orangeAccent
        : Colors.greenAccent;

    Widget statPill(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.48)),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }

    return gothicPanel(
      borderColor: sideColor,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Scheda attiva', 'Active sheet'),
                style: TextStyle(
                  color: sideColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nomeSchedaPersonaggio(index),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 3),
              smallInfoText(
                '${tipoSchedaPersonaggio(index)} - Tag ${sheetTagAt(index)} - ${masterInitiativeSideLabel(side)}',
                color: sideColor,
              ),
            ],
          );

          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  statPill(
                    'HP',
                    '${sheetIntValueAt(index, 'currentHp')}/${max(1, sheetIntValueAt(index, 'resilienza') * 10)}',
                    Colors.redAccent,
                  ),
                  statPill(
                    'RES',
                    '${sheetIntValueAt(index, 'resilienza')}',
                    Colors.greenAccent,
                  ),
                  statPill(
                    'VOL',
                    '${sheetIntValueAt(index, 'volonta')}',
                    Colors.red.shade300,
                  ),
                  statPill(
                    'MAT',
                    '${sheetIntValueAt(index, 'materia')}',
                    Colors.lightBlueAccent,
                  ),
                  statPill(
                    'OCU',
                    '${sheetIntValueAt(index, 'oculum')}',
                    oculumStatFormulaColor,
                  ),
                  statPill(
                    'VC',
                    '+${sheetRollBonusAt(index, 'vc')}',
                    primaryColor,
                  ),
                  statPill(
                    'CM',
                    '+${sheetRollBonusAt(index, 'cm')}',
                    primaryColor,
                  ),
                  statPill(
                    'INI',
                    '+${sheetRollBonusAt(index, 'iniziativa')}',
                    tertiaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              masterPartyQuickRolls(index),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => apriSchedaDaParty(index),
                    icon: const Icon(Icons.edit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: primaryColor,
                    ),
                    label: Text(t('Modifica scheda', 'Edit sheet')),
                  ),
                  if (side != 'enemy')
                    ElevatedButton.icon(
                      onPressed: () => setSheetSideOverride(index, 'enemy'),
                      icon: const Icon(Icons.flash_on),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(t('Segna nemico', 'Mark enemy')),
                    ),
                  if (side != 'ally')
                    ElevatedButton.icon(
                      onPressed: () => setSheetSideOverride(index, 'ally'),
                      icon: const Icon(Icons.shield),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        foregroundColor: Colors.black,
                      ),
                      label: Text(t('Segna alleato', 'Mark ally')),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => cambiaSchedaMasterParty(index, !inParty),
                    icon: Icon(inParty ? Icons.group_remove : Icons.group_add),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inParty
                          ? Colors.redAccent.shade700
                          : tertiaryColor,
                      foregroundColor: inParty
                          ? Colors.white
                          : tertiaryColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text(
                      inParty
                          ? t('Togli dal party', 'Remove from party')
                          : t('Aggiungi al party', 'Add to party'),
                    ),
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: masterPartyAvatar(index, size: 54)),
                const SizedBox(height: 10),
                heading,
                const SizedBox(height: 10),
                body,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              masterPartyAvatar(index, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 10), body],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget masterDashboardRosterPanel({bool initiallyExpanded = false}) {
    final partyIndexes = masterPartyIndexes();

    return gothicPanel(
      borderColor: const Color(0xFF7EE7C8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Party e schede', 'Party and sheets'),
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${partyIndexes.length}/${schedePersonaggio.length}',
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (partyIndexes.isEmpty)
            smallInfoText(
              t(
                'Nessuna scheda nel party Master.',
                'No sheet in the Master party.',
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final index in partyIndexes) masterPartyHexBadge(index),
              ],
            ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: primaryColor,
              collapsedIconColor: primaryColor,
              title: Text(
                t('Gestisci schede salvate', 'Manage saved sheets'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              children: [
                for (int i = 0; i < schedePersonaggio.length; i++)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    value: sheetInMasterPartyAt(i),
                    activeColor: Colors.greenAccent,
                    checkColor: Colors.black,
                    secondary: masterPartyAvatar(i, size: 36),
                    title: Text(
                      nomeSchedaPersonaggio(i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${tipoSchedaPersonaggio(i)} - ${sheetTagAt(i)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tertiaryColor, fontSize: 11),
                    ),
                    onChanged: (selected) =>
                        cambiaSchedaMasterParty(i, selected == true),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget monsterBookEntryPreview(MonsterBookEntry entry, {double size = 48}) {
    final cacheSide = oculumImageCacheDimension(context, size, max: 192);

    Widget fallback() {
      return Center(
        child: Icon(
          entry.isNpc ? Icons.person : Icons.pest_control,
          color: entry.isNpc ? Colors.greenAccent : Colors.redAccent,
          size: size * 0.55,
        ),
      );
    }

    Widget image = fallback();
    if (entry.imageBase64.isNotEmpty) {
      final bytes = decodedBase64ImageCached(entry.imageBase64);
      if (bytes != null) {
        image = Image.memory(
          bytes,
          fit: BoxFit.cover,
          cacheWidth: cacheSide,
          cacheHeight: cacheSide,
          errorBuilder: (context, error, stackTrace) => fallback(),
        );
      }
    } else if (entry.spriteAssetPath.isNotEmpty) {
      image = Image.asset(
        entry.spriteAssetPath,
        fit: BoxFit.cover,
        cacheWidth: cacheSide,
        cacheHeight: cacheSide,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: size,
          height: size,
          color: const Color(0xFF090B11),
          child: image,
        ),
      ),
    );
  }

  List<String> parseMonsterBookList(String raw) {
    return raw
        .split(RegExp(r'[\n,;]+'))
        .map((value) => cleanUiText(value).trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> showMonsterBookEditor([MonsterBookEntry? existing]) async {
    final nameItController = TextEditingController(text: existing?.nameIt);
    final nameEnController = TextEditingController(text: existing?.nameEn);
    final descriptionController = TextEditingController(text: existing?.descIt);
    final descriptionEnController = TextEditingController(
      text: existing?.descEn,
    );
    final elementController = TextEditingController(
      text: existing?.elementId ?? 'fisico',
    );
    final spriteController = TextEditingController(
      text: existing?.spriteAssetPath,
    );
    final dropsController = TextEditingController(
      text: existing?.dropIds.join(', '),
    );
    final skillsController = TextEditingController(
      text: existing?.skillIds.join(', '),
    );
    final weaponsController = TextEditingController(
      text: existing?.weaponTags.join(', '),
    );
    final armorController = TextEditingController(
      text: existing?.armorTags.join(', '),
    );
    final hpController = TextEditingController(
      text: '${existing?.stats['hp'] ?? 0}',
    );
    final attackController = TextEditingController(
      text: '${existing?.stats['atk'] ?? 0}',
    );
    final defenseController = TextEditingController(
      text: '${existing?.stats['def'] ?? 0}',
    );
    final speedController = TextEditingController(
      text: '${existing?.stats['spd'] ?? 0}',
    );
    var presetType = existing?.presetType ?? 'Mostro';
    var imageBase64 = existing?.imageBase64 ?? '';
    var canWieldWeapons = existing?.canWieldWeapons ?? false;
    var nullFateless = existing?.isNullFateless ?? false;

    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tertiaryColor),
        filled: true,
        fillColor: const Color(0xFF0C0E15),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      );
    }

    final result = await showDialog<MonsterBookEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget preview() {
            final draft = (existing ?? defaultMonsterBookEntries.first)
                .copyWith(
                  nameIt: nameItController.text,
                  spriteAssetPath: spriteController.text.trim(),
                  imageBase64: imageBase64,
                  isNpc: presetType == 'NPC',
                );
            return monsterBookEntryPreview(draft, size: 76);
          }

          return AlertDialog(
            backgroundColor: backgroundMidColor,
            title: Text(
              existing == null
                  ? t('Aggiungi preset', 'Add preset')
                  : t('Modifica preset', 'Edit preset'),
              style: TextStyle(color: primaryColor),
            ),
            content: SizedBox(
              width: min(MediaQuery.of(dialogContext).size.width * 0.92, 720),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: presetType,
                                dropdownColor: backgroundMidColor,
                                decoration: decoration(
                                  t('Categoria', 'Category'),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Mostro',
                                    child: Text('Mostro'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Mostro Mini Boss',
                                    child: Text('Mostro Mini Boss'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Mostro Boss',
                                    child: Text('Mostro Boss'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'NPC',
                                    child: Text('NPC'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() => presetType = value);
                                },
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final file = await _picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (file == null) return;
                                      final bytes = await file.readAsBytes();
                                      if (!dialogContext.mounted) return;
                                      setDialogState(() {
                                        imageBase64 = base64Encode(bytes);
                                      });
                                    },
                                    icon: const Icon(Icons.image),
                                    label: Text(
                                      t('Scegli immagine', 'Choose image'),
                                    ),
                                  ),
                                  if (imageBase64.isNotEmpty)
                                    IconButton(
                                      tooltip: t(
                                        'Rimuovi immagine',
                                        'Remove image',
                                      ),
                                      onPressed: () => setDialogState(
                                        () => imageBase64 = '',
                                      ),
                                      icon: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameItController,
                      decoration: decoration(t('Nome', 'Name')),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameEnController,
                      decoration: decoration(t('Nome inglese', 'English name')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: decoration(t('Descrizione', 'Description')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionEnController,
                      maxLines: 2,
                      decoration: decoration(
                        t('Descrizione inglese', 'English description'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: elementController,
                      decoration: decoration(t('Elemento', 'Element')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: spriteController,
                      decoration: decoration(
                        t('Percorso sprite asset', 'Sprite asset path'),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dropsController,
                      maxLines: 2,
                      decoration: decoration(
                        t(
                          'Drop inventario, separati da virgola',
                          'Inventory drops, comma separated',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: skillsController,
                      maxLines: 2,
                      decoration: decoration(
                        t(
                          'Skill, separate da virgola',
                          'Skills, comma separated',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          TextField(
                            controller: hpController,
                            keyboardType: TextInputType.number,
                            decoration: decoration('HP'),
                          ),
                          TextField(
                            controller: attackController,
                            keyboardType: TextInputType.number,
                            decoration: decoration('ATK'),
                          ),
                          TextField(
                            controller: defenseController,
                            keyboardType: TextInputType.number,
                            decoration: decoration('DEF'),
                          ),
                          TextField(
                            controller: speedController,
                            keyboardType: TextInputType.number,
                            decoration: decoration('SPD'),
                          ),
                        ];
                        if (constraints.maxWidth < 520) {
                          return Column(
                            children: [
                              for (final field in fields) ...[
                                field,
                                const SizedBox(height: 8),
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            for (var i = 0; i < fields.length; i++) ...[
                              Expanded(child: fields[i]),
                              if (i != fields.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        );
                      },
                    ),
                    TextField(
                      controller: weaponsController,
                      decoration: decoration(t('Tag armi', 'Weapon tags')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: armorController,
                      decoration: decoration(t('Tag armature', 'Armor tags')),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: canWieldWeapons,
                      title: Text(
                        t('Puo usare armi', 'Can wield weapons'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => canWieldWeapons = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: nullFateless,
                      title: const Text(
                        'Null / Fateless',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => nullFateless = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t('Annulla', 'Cancel')),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final nameIt = cleanUiText(nameItController.text).trim();
                  if (nameIt.isEmpty) return;
                  final id =
                      existing?.id ??
                      newMonsterBookEntryId(nameItController.text);
                  final isMiniBoss = presetType == 'Mostro Mini Boss';
                  final isBoss = presetType == 'Mostro Boss';
                  final isNpc = presetType == 'NPC';
                  Navigator.of(dialogContext).pop(
                    MonsterBookEntry(
                      id: id,
                      nameIt: nameIt,
                      nameEn: cleanUiText(nameEnController.text).trim().isEmpty
                          ? nameIt
                          : cleanUiText(nameEnController.text).trim(),
                      descIt: cleanUiText(descriptionController.text).trim(),
                      descEn:
                          cleanUiText(
                            descriptionEnController.text,
                          ).trim().isEmpty
                          ? cleanUiText(descriptionController.text).trim()
                          : cleanUiText(descriptionEnController.text).trim(),
                      elementId:
                          cleanUiText(elementController.text).trim().isEmpty
                          ? 'fisico'
                          : cleanUiText(elementController.text).trim(),
                      spriteAssetPath: spriteController.text.trim(),
                      imageBase64: imageBase64,
                      isMiniBoss: isMiniBoss,
                      isBoss: isBoss,
                      isNpc: isNpc,
                      isNullFateless: nullFateless,
                      stats: <String, int>{
                        'hp': readIntValue(hpController.text),
                        'atk': readIntValue(attackController.text),
                        'def': readIntValue(defenseController.text),
                        'spd': readIntValue(speedController.text),
                      },
                      skillIds: parseMonsterBookList(skillsController.text),
                      dropIds: parseMonsterBookList(dropsController.text),
                      canWieldWeapons: canWieldWeapons,
                      weaponTags: parseMonsterBookList(weaponsController.text),
                      armorTags: parseMonsterBookList(armorController.text),
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: Text(t('Salva', 'Save')),
              ),
            ],
          );
        },
      ),
    );

    for (final controller in [
      nameItController,
      nameEnController,
      descriptionController,
      descriptionEnController,
      elementController,
      spriteController,
      dropsController,
      skillsController,
      weaponsController,
      armorController,
      hpController,
      attackController,
      defenseController,
      speedController,
    ]) {
      controller.dispose();
    }
    if (result != null) {
      await upsertMonsterBookEntry(result);
    }
  }

  Widget masterDashboardMonsterBookPanel() {
    final query = oculumNormalizeText(monsterBookSearchController.text);
    final filtered = monsterBookEntries
        .where((entry) {
          if (query.isEmpty) return true;
          return oculumNormalizeText(
            '${entry.nameIt} ${entry.nameEn} ${entry.id} ${entry.elementId} ${entry.presetType}',
          ).contains(query);
        })
        .toList(growable: false);
    final visible = filtered.take(query.isEmpty ? 24 : 80).toList();

    return gothicPanel(
      borderColor: Colors.greenAccent.shade100,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monster Book',
                  style: TextStyle(
                    color: Colors.greenAccent.shade100,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${monsterBookEntries.length}',
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'Il Master puo cambiare nome, immagine, categoria, stats, skill e drop inventario; puo anche aggiungere o rimuovere mostri, mini boss, boss e NPC.',
              'The Master can change name, image, category, stats, skills and inventory drops; monsters, mini bosses, bosses and NPCs can also be added or removed.',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: monsterBookSearchController,
            decoration: InputDecoration(
              hintText: t('Cerca preset...', 'Search presets...'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: monsterBookSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t('Pulisci ricerca', 'Clear search'),
                      onPressed: () {
                        monsterBookSearchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: const Color(0xFF0C0E15),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => scheduleInputUiRefresh(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: showMonsterBookEditor,
                icon: const Icon(Icons.add),
                label: Text(t('Aggiungi preset', 'Add preset')),
              ),
              OutlinedButton.icon(
                onPressed:
                    monsterBookCustomEntries.isEmpty &&
                        monsterBookRemovedIds.isEmpty
                    ? null
                    : resetMonsterBookCustomization,
                icon: const Icon(Icons.restart_alt),
                label: Text(t('Ripristina originali', 'Restore originals')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            smallInfoText(t('Nessun preset trovato.', 'No presets found.'))
          else
            for (final entry in visible)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0D13),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (entry.isNpc ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: 0.28),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: monsterBookEntryPreview(entry),
                  title: Text(
                    entry.nameIt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.presetType} - ${elementDisplayName(entry.elementId)} - Drop ${entry.dropIds.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tertiaryColor, fontSize: 11),
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: t('Modifica', 'Edit'),
                        onPressed: () => showMonsterBookEditor(entry),
                        icon: const Icon(Icons.edit, size: 19),
                      ),
                      IconButton(
                        tooltip: t('Rimuovi', 'Remove'),
                        onPressed: () => removeMonsterBookEntry(entry),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (visible.length < filtered.length)
            smallInfoText(
              t(
                'Mostrati ${visible.length} di ${filtered.length}: usa la ricerca per restringere.',
                'Showing ${visible.length} of ${filtered.length}: use search to narrow the list.',
              ),
              color: Colors.white54,
            ),
        ],
      ),
    );
  }

  int masterDashboardEnemyMaxHpAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 1;
    final savedMax = sheetIntValueAt(index, 'maxHp');
    if (savedMax > 0) return savedMax;
    return max(1, sheetIntValueAt(index, 'resilienza') * 10);
  }

  void setMasterEnemyLayerValue(int index, String key, int value) {
    if (index < 0 || index >= schedePersonaggio.length) return;
    final clean = max(0, value).toString();
    schedePersonaggio[index][key] = clean;
    if (index == schedaCorrente) {
      switch (key) {
        case 'currentHp':
          currentHpController.text = clean;
          break;
        case 'hpTemp':
          hpTempController.text = clean;
          break;
        case 'scudo':
          scudoController.text = clean;
          break;
        case 'scudoOculum':
          scudoOculumController.text = clean;
          break;
      }
    }
  }

  void applyMasterEnemyQuickHpAction(
    int index, {
    int damage = 0,
    int heal = 0,
    bool ko = false,
    bool critical = false,
  }) {
    if (index < 0 || index >= schedePersonaggio.length) return;
    final maxHpEnemy = masterDashboardEnemyMaxHpAt(index);
    var hp = sheetIntValueAt(index, 'currentHp', fallback: maxHpEnemy);
    var tempHp = sheetIntValueAt(index, 'hpTemp');
    var shield = sheetIntValueAt(index, 'scudo');
    var oculumShield = sheetIntValueAt(index, 'scudoOculum');
    final originalHp = hp;
    final totalDamage = max(0, damage + (critical ? 5 : 0));
    var remaining = totalDamage;

    if (ko) {
      hp = 0;
      tempHp = 0;
      shield = 0;
      oculumShield = 0;
    } else if (remaining > 0) {
      final oculumAbsorbed = min(oculumShield, remaining);
      oculumShield -= oculumAbsorbed;
      remaining -= oculumAbsorbed;
      final shieldAbsorbed = min(shield, remaining);
      shield -= shieldAbsorbed;
      remaining -= shieldAbsorbed;
      final tempAbsorbed = min(tempHp, remaining);
      tempHp -= tempAbsorbed;
      remaining -= tempAbsorbed;
      hp = max(0, hp - remaining);
    } else if (heal > 0) {
      hp = min(maxHpEnemy, hp + heal);
    }

    setState(() {
      setMasterEnemyLayerValue(index, 'currentHp', hp);
      setMasterEnemyLayerValue(index, 'hpTemp', tempHp);
      setMasterEnemyLayerValue(index, 'scudo', shield);
      setMasterEnemyLayerValue(index, 'scudoOculum', oculumShield);
      risultato = ko
          ? t(
              '${nomeSchedaPersonaggio(index)} mandato a 0 HP dal pannello Master.',
              '${nomeSchedaPersonaggio(index)} set to 0 HP from the Master panel.',
            )
          : totalDamage > 0
          ? t(
              '${nomeSchedaPersonaggio(index)}: $totalDamage danni rapidi${critical ? ' (critico)' : ''}, HP $originalHp -> $hp.',
              '${nomeSchedaPersonaggio(index)}: $totalDamage quick damage${critical ? ' (critical)' : ''}, HP $originalHp -> $hp.',
            )
          : t(
              '${nomeSchedaPersonaggio(index)}: cura rapida +$heal, HP $originalHp -> $hp.',
              '${nomeSchedaPersonaggio(index)}: quick heal +$heal, HP $originalHp -> $hp.',
            );
    });
    if (index == schedaCorrente) salvaSchedaCorrenteInMemoria();
    aggiungiLog(risultato);
  }

  Widget masterEnemyVitalBar(int index) {
    final maxHpEnemy = masterDashboardEnemyMaxHpAt(index);
    final hp = sheetIntValueAt(index, 'currentHp', fallback: maxHpEnemy);
    final tempHp = sheetIntValueAt(index, 'hpTemp');
    final shield = sheetIntValueAt(index, 'scudo');
    final oculumShield = sheetIntValueAt(index, 'scudoOculum');
    final total = max(1, maxHpEnemy + tempHp + shield + oculumShield);
    double fraction(int value) => (max(0, value) / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: max(1, (fraction(hp) * 1000).round()),
                  child: Container(color: Colors.redAccent),
                ),
                if (tempHp > 0)
                  Expanded(
                    flex: max(1, (fraction(tempHp) * 1000).round()),
                    child: Container(color: Colors.purpleAccent),
                  ),
                if (shield > 0)
                  Expanded(
                    flex: max(1, (fraction(shield) * 1000).round()),
                    child: Container(color: Colors.lightBlueAccent),
                  ),
                if (oculumShield > 0)
                  Expanded(
                    flex: max(1, (fraction(oculumShield) * 1000).round()),
                    child: Container(color: oculumStatFormulaColor),
                  ),
                Expanded(
                  flex: max(
                    1,
                    ((1 -
                                    fraction(hp) -
                                    fraction(tempHp) -
                                    fraction(shield) -
                                    fraction(oculumShield))
                                .clamp(0.0, 1.0) *
                            1000)
                        .round(),
                  ),
                  child: Container(color: Colors.white10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        smallInfoText(
          'HP $hp/$maxHpEnemy  T $tempHp  S $shield  SO $oculumShield',
          color: Colors.white70,
        ),
      ],
    );
  }

  Widget masterEnemyQuickHpButtons(int index) {
    Widget valueField({
      required TextEditingController controller,
      required String label,
      required Color color,
    }) {
      return SizedBox(
        width: 86,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            labelStyle: TextStyle(color: color),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 1.3),
            ),
          ),
        ),
      );
    }

    Widget actionButton({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: color ?? Colors.white,
          side: BorderSide(
            color: (color ?? Colors.white).withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        valueField(
          controller: masterEnemyDamageController,
          label: t('Danno', 'Damage'),
          color: Colors.redAccent,
        ),
        actionButton(
          label: t('Danno', 'Damage'),
          icon: Icons.remove,
          color: Colors.redAccent,
          onPressed: () => applyMasterEnemyQuickHpAction(
            index,
            damage: max(0, readIntValue(masterEnemyDamageController.text)),
          ),
        ),
        actionButton(
          label: 'Crit',
          icon: Icons.auto_awesome,
          color: primaryColor,
          onPressed: () => applyMasterEnemyQuickHpAction(
            index,
            damage: max(0, readIntValue(masterEnemyDamageController.text)),
            critical: true,
          ),
        ),
        valueField(
          controller: masterEnemyHealController,
          label: t('Cura', 'Heal'),
          color: Colors.greenAccent,
        ),
        actionButton(
          label: t('Cura', 'Heal'),
          icon: Icons.add,
          color: Colors.greenAccent,
          onPressed: () => applyMasterEnemyQuickHpAction(
            index,
            heal: max(0, readIntValue(masterEnemyHealController.text)),
          ),
        ),
        actionButton(
          label: 'KO',
          icon: Icons.block,
          color: Colors.white70,
          onPressed: () => applyMasterEnemyQuickHpAction(index, ko: true),
        ),
      ],
    );
  }

  Widget masterDashboardEnemyCard(int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          masterPartyAvatar(index, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeSchedaPersonaggio(index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                smallInfoText(
                  'VC +${sheetRollBonusAt(index, 'vc')} - CM +${sheetRollBonusAt(index, 'cm')} - INI +${sheetRollBonusAt(index, 'iniziativa')}',
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 7),
                masterEnemyVitalBar(index),
                const SizedBox(height: 7),
                masterPartyQuickRolls(index),
                const SizedBox(height: 7),
                masterEnemyQuickHpButtons(index),
              ],
            ),
          ),
          IconButton(
            tooltip: t('Rimetti alleato', 'Mark ally'),
            onPressed: () => setSheetSideOverride(index, 'ally'),
            icon: const Icon(Icons.shield, color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget masterDashboardEnemiesPanel({bool compactNote = false}) {
    final enemies = masterPartyIndexes()
        .where((index) => sheetSideAt(index) == 'enemy')
        .toList();

    return gothicPanel(
      borderColor: Colors.redAccent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Nemici in scena', 'Enemies in scene'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${enemies.length}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!compactNote || enemies.isNotEmpty) ...[
            const SizedBox(height: 7),
            smallInfoText(
              enemies.isEmpty
                  ? t(
                      'Nessun nemico nel party Master.',
                      'No enemies in the Master party.',
                    )
                  : t(
                      'Nemici pronti per iniziativa e tiri rapidi.',
                      'Enemies ready for initiative and quick rolls.',
                    ),
            ),
          ],
          if (enemies.isNotEmpty) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                const gap = 8.0;
                final itemWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final index in enemies)
                      SizedBox(
                        width: itemWidth,
                        child: masterDashboardEnemyCard(index),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget masterDashboardQuickSheetPanel() {
    if (!haPermessiMaster) {
      return const SizedBox.shrink();
    }

    final generatorPresets =
        <
          ({
            String label,
            String type,
            String side,
            bool enemy,
            IconData icon,
            Color color,
          })
        >[
          (
            label: 'NPC',
            type: 'NPC',
            side: 'neutral',
            enemy: false,
            icon: Icons.record_voice_over,
            color: Colors.lightBlueAccent,
          ),
          (
            label: t('Nemico', 'Enemy'),
            type: 'NPC',
            side: 'enemy',
            enemy: true,
            icon: Icons.person_off,
            color: Colors.redAccent,
          ),
          (
            label: t('Mostro', 'Monster'),
            type: 'Mostro',
            side: 'enemy',
            enemy: true,
            icon: Icons.flash_on,
            color: Colors.deepOrangeAccent,
          ),
          (
            label: t('Mini Boss', 'Mini Boss'),
            type: 'Mostro Mini Boss',
            side: 'enemy',
            enemy: true,
            icon: Icons.warning_amber,
            color: Colors.orangeAccent,
          ),
          (
            label: t('Boss', 'Boss'),
            type: 'Mostro Boss',
            side: 'enemy',
            enemy: true,
            icon: Icons.whatshot,
            color: tertiaryColor,
          ),
        ];
    final folliaUnlocked = folliaGeneratoreSbloccato();
    final folliaTotal = folliaPartyTotale();
    final folliaChance = folliaIncontroPercentuale();

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Crea Scheda Rapida', 'Create Quick Sheet'),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          smallInfoText(
            t(
              'Generatore semplificato da Master: crea NPC, nemici, mostri, mini boss e boss gia bilanciati sul party selezionato.',
              'Simplified Master generator: create NPCs, enemies, monsters, mini bosses and bosses already balanced on the selected party.',
            ),
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t('Nome nuova scheda', 'New sheet name'),
            controller: quickSheetNameController,
            numero: false,
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t(
              'Descrizione / prompt mostro',
              'Monster description / prompt',
            ),
            controller: quickSheetDescriptionController,
            numero: false,
            maxLines: 3,
            helper: t(
              'Usata per scegliere tipo danno, difesa, skill, Art e note in turnistica.',
              'Used to choose damage type, defense, skills, Art and initiative notes.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: quickSheetType,
            dropdownColor: const Color(0xFF11131A),
            decoration: fieldDecoration(
              t('Tipo nuova scheda', 'New sheet type'),
            ),
            items: tipiScheda
                .map(
                  (tipo) =>
                      DropdownMenuItem<String>(value: tipo, child: Text(tipo)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => quickSheetType = value);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Quantita', 'Amount'),
                  controller: quickSheetCountController,
                  helper: '1-10',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: quickSheetArtMode,
                  dropdownColor: const Color(0xFF11131A),
                  decoration: fieldDecoration('Art'),
                  items: const [
                    DropdownMenuItem(value: 'random', child: Text('Random')),
                    DropdownMenuItem(value: 'none', child: Text('Solo skill')),
                    DropdownMenuItem(
                      value: 'martial',
                      child: Text('Martial Art'),
                    ),
                    DropdownMenuItem(
                      value: 'oculum',
                      child: Text('Oculum Art'),
                    ),
                    DropdownMenuItem(
                      value: 'emblem',
                      child: Text('Emblem Art'),
                    ),
                    DropdownMenuItem(
                      value: 'illness',
                      child: Text('Illness Art'),
                    ),
                    DropdownMenuItem(
                      value: 'grimorio',
                      child: Text('Grimorio'),
                    ),
                    DropdownMenuItem(
                      value: 'defiled',
                      child: Text('Defiled Art'),
                    ),
                    DropdownMenuItem(value: 'null', child: Text('Null Art')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => quickSheetArtMode = value);
                    }
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: quickSheetAddToInitiative,
            onChanged: (value) =>
                setState(() => quickSheetAddToInitiative = value),
            title: Text(t('Inserisci in turnistica', 'Add to initiative')),
            subtitle: Text(
              t(
                'I nemici generati entrano gia pronti con note modificabili.',
                'Generated enemies enter ready with editable notes.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - 16) / 3
                  : constraints.maxWidth >= 340
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in generatorPresets)
                    SizedBox(
                      width: itemWidth,
                      child: ElevatedButton.icon(
                        onPressed: () => creaSchedaRapidaMaster(
                          forcedType: preset.type,
                          fallbackName: preset.label,
                          sideOverride: preset.side,
                          forceEnemyProfile: preset.enemy,
                        ),
                        icon: Icon(preset.icon, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: preset.color.withValues(alpha: 0.92),
                          foregroundColor:
                              preset.color.computeLuminance() > 0.45
                              ? Colors.black
                              : Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(preset.label),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: itemWidth,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        quickSheetNameController.text = 'Patalpa Dolce';
                        quickSheetDescriptionController.text =
                            'Patalpa Dolce, creatura sotterranea prelibata e malvagia con pala viva.';
                        quickSheetArtMode = 'random';
                        creaSchedaRapidaMaster(
                          forcedType: 'Mostro',
                          fallbackName: 'Patalpa Dolce',
                          sideOverride: 'enemy',
                          forceEnemyProfile: true,
                        );
                      },
                      icon: const Icon(Icons.grass, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Patalpa Dolce'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            t('Generatore Follia', 'Madness generator'),
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          smallInfoText(
            folliaUnlocked
                ? t(
                    'Party Follia $folliaTotal: errati disponibili. Chance suggerita $folliaChance%. Per moddare, aggiungi preset in folliaGeneratorPresets o scrivi un prompt con Follia/Illness/errato.',
                    'Party Madness $folliaTotal: wrong ghosts available. Suggested chance $folliaChance%. For modding, add presets in folliaGeneratorPresets or write a prompt with Madness/Illness/wrong ghost.',
                  )
                : t(
                    'Bloccato: serve almeno 1 Follia nel party prima di generare mostri fantasma errati.',
                    'Locked: the party needs at least 1 Madness before generating wrong ghost monsters.',
                  ),
            color: folliaUnlocked
                ? Colors.purpleAccent.shade100
                : Colors.white54,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in folliaGeneratorPresets())
                OutlinedButton.icon(
                  onPressed: folliaUnlocked
                      ? () => creaSchedaRapidaFollia(preset.id)
                      : null,
                  icon: Icon(
                    preset.id == 'three_women'
                        ? Icons.groups_3
                        : Icons.psychology_alt,
                    size: 18,
                  ),
                  label: Text(preset.label),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t('Mostri sistema', 'System monsters'),
            style: TextStyle(
              color: Colors.greenAccent.shade100,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'Preset con immagine bitmap gia caricata, skill, Art e note modificabili dal Master.',
              'Presets with preloaded bitmap image, skills, Art and editable Master notes.',
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final presets = systemMonsterGeneratorPresets();
              final selected =
                  presets.any(
                    (preset) => preset.id == selectedSystemMonsterPresetId,
                  )
                  ? selectedSystemMonsterPresetId
                  : presets.isEmpty
                  ? null
                  : presets.first.id;
              if (selected != null &&
                  selectedSystemMonsterPresetId != selected) {
                selectedSystemMonsterPresetId = selected;
              }
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selected,
                      isExpanded: true,
                      dropdownColor: backgroundMidColor,
                      decoration: InputDecoration(
                        labelText: t(
                          'Preset Monster Book',
                          'Monster Book preset',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final preset in presets)
                          DropdownMenuItem(
                            value: preset.id,
                            child: Text(
                              '${preset.name} - ${preset.type}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedSystemMonsterPresetId = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: t('Crea dal preset', 'Create from preset'),
                    onPressed: selected == null
                        ? null
                        : () => creaSchedaRapidaMostroSistema(selected),
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final encounter in const [
                ('Molto facile', 'Mostro', 2),
                ('Facile', 'Mostro', 3),
                ('Medio', 'Mostro', 4),
                ('Difficile', 'Mostro Mini Boss', 5),
                ('Oculum', 'Mostro Boss', 6),
              ])
                OutlinedButton.icon(
                  onPressed: () {
                    quickSheetNameController.text =
                        encounter.$1 == 'Molto facile'
                        ? 'Creatura innocua'
                        : 'Incontro ${encounter.$1}';
                    quickSheetDescriptionController.text =
                        encounter.$1 == 'Molto facile'
                        ? 'Mostri carini e quasi innocui, piu curiosi che aggressivi.'
                        : 'Incontro ${encounter.$1} generato dal Master.';
                    quickSheetCountController.text = min(
                      10,
                      encounter.$3,
                    ).toString();
                    creaSchedaRapidaMaster(
                      forcedType: encounter.$2,
                      fallbackName: quickSheetNameController.text,
                      sideOverride: 'enemy',
                      forceEnemyProfile: true,
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(encounter.$1),
                ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Il campo Tipo sotto resta per casi speciali come Personaggio o Alleato.',
              'The Type field below stays for special cases such as Character or Ally.',
            ),
            color: Colors.white54,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final level = campoTesto(
                label: t('Livello iniziale', 'Starting level'),
                controller: quickSheetLevelController,
              );
              final grade = campoTesto(
                label: t('Grado iniziale', 'Starting grade'),
                controller: quickSheetGradeController,
              );

              if (narrow) {
                return Column(
                  children: [level, const SizedBox(height: 8), grade],
                );
              }

              return Row(
                children: [
                  Expanded(child: level),
                  const SizedBox(width: 8),
                  Expanded(child: grade),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => creaSchedaRapidaMaster(),
            icon: const Icon(Icons.add_circle),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Crea scheda', 'Create sheet')),
          ),
        ],
      ),
    );
  }

  Widget masterDashboardQuickControlsPanel() {
    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Controlli rapidi', 'Quick controls'),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: controllaTitoliDelFatoAutomatici,
            icon: const Icon(Icons.auto_awesome),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(
              t(
                'Controlla Titoli del Fato dalle Art',
                'Check Fate Titles from Arts',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: randomizzaStatsBilanciate,
            icon: const Icon(Icons.casino),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Randomizza stats', 'Randomize stats')),
          ),
        ],
      ),
    );
  }

  Widget masterDashboardNotePanel() {
    return gothicPanel(
      borderColor: primaryColor.withValues(alpha: 0.72),
      padding: const EdgeInsets.all(10),
      child: smallInfoText(
        t(
          'Nota Master: puoi creare un Mostro e poi trasformarlo in Personaggio dalla pagina Scheda se la lore cambia direzione.',
          'Master note: you can create a Monster and later turn it into a Character from the Sheet page if the lore changes direction.',
        ),
      ),
    );
  }

  Widget masterDashboardPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760 || phoneCompactUi;
        final padding = responsivePagePadding();
        final title = functionAnchor('master_root', sectionTitle('Master'));

        if (narrow) {
          return ListView(
            key: sheetScrollKey('master'),
            padding: padding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              title,
              masterDashboardActiveSheetPanel(),
              masterInitiativeTrackerPanel(),
              masterDashboardEnemiesPanel(compactNote: true),
              masterDashboardQuickControlsPanel(),
              masterDashboardQuickSheetPanel(),
              onlineStatusPanel(compatto: true),
              campaignPanel(),
              connectedSheetsPanel(),
              masterDashboardRosterPanel(),
              masterDashboardMonsterBookPanel(),
              masterDashboardNotePanel(),
            ],
          );
        }

        final sideWidth = min(
          constraints.maxWidth >= 1500 ? 460.0 : 410.0,
          max(320.0, constraints.maxWidth * 0.33),
        );

        return ListView(
          key: sheetScrollKey('master'),
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            title,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      masterInitiativeTrackerPanel(),
                      masterDashboardEnemiesPanel(),
                      masterDashboardRosterPanel(),
                      masterDashboardMonsterBookPanel(),
                      connectedSheetsPanel(),
                      masterDashboardNotePanel(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: sideWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      masterDashboardActiveSheetPanel(),
                      masterDashboardQuickControlsPanel(),
                      masterDashboardQuickSheetPanel(),
                      onlineStatusPanel(compatto: true),
                      campaignPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget masterPartyPanel() {
    final partyIndexes = masterPartyIndexes();

    return gothicPanel(
      borderColor: const Color(0xFF7EE7C8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Party',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Il Master può mettere nel party quante schede vuole. Ogni scheda resta salvata nella lista schede, con tag unico e tiri rapidi.',
              'The Master can put as many sheets as needed in the party. Every sheet remains saved in the sheet list, with a unique tag and quick rolls.',
            ),
          ),
          const SizedBox(height: 12),
          if (partyIndexes.isEmpty)
            smallInfoText(
              t(
                'Nessuna scheda nel party Master.',
                'No sheet in the Master party.',
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final index in partyIndexes) masterPartyHexBadge(index),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            t('Schede salvate', 'Saved sheets'),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < schedePersonaggio.length; i++)
            masterPartySheetCard(i),
        ],
      ),
    );
  }

  Widget masterEnemiesPanel() {
    final enemies = masterPartyIndexes()
        .where((index) => sheetSideAt(index) == 'enemy')
        .toList();

    return gothicPanel(
      borderColor: Colors.redAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Nemici in scena', 'Enemies in scene'),
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Le schede segnate nemiche restano modificabili come schede complete, ma in iniziativa e realtime vengono trattate come avversari.',
              'Sheets marked as enemies remain fully editable, but initiative and realtime treat them as opponents.',
            ),
          ),
          const SizedBox(height: 12),
          if (enemies.isEmpty)
            smallInfoText(
              t(
                'Nessun nemico nel party Master.',
                'No enemies in the Master party.',
              ),
            )
          else
            for (final index in enemies)
              gothicPanel(
                borderColor: Colors.redAccent.withValues(alpha: 0.80),
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    masterPartyAvatar(index, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeSchedaPersonaggio(index),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          smallInfoText(
                            'VC +${sheetRollBonusAt(index, 'vc')} - CM +${sheetRollBonusAt(index, 'cm')} - INI +${sheetRollBonusAt(index, 'iniziativa')}',
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 8),
                          masterPartyQuickRolls(index),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t('Rimetti alleato', 'Mark ally'),
                      onPressed: () => setSheetSideOverride(index, 'ally'),
                      icon: const Icon(Icons.shield, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget masterPage() {
    return responsivePageList(
      pageKey: 'master',
      maxColumns: 3,
      minColumnWidth: 350,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor('master_root', sectionTitle('Master')),
        onlineStatusPanel(),
        campaignPanel(),
        masterPartyPanel(),
        masterEnemiesPanel(),
        masterInitiativeTrackerPanel(),
        connectedSheetsPanel(),
        masterDashboardQuickSheetPanel(),
        gothicPanel(
          borderColor: primaryColor,
          child: smallInfoText(
            t(
              'Nota Master: puoi creare un Mostro e poi trasformarlo in Personaggio dalla pagina Scheda se la lore prende una piega inaspettata. Questa app non blocca la narrazione: ti dà strumenti, non catene.',
              'Master note: you can create a Monster and later turn it into a Character from the Sheet page if the lore takes an unexpected turn. This app does not lock the story: it gives you tools, not chains.',
            ),
          ),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Controlli rapidi', 'Quick controls'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: controllaTitoliDelFatoAutomatici,
                icon: const Icon(Icons.auto_awesome),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(
                  t(
                    'Controlla Titoli del Fato dalle Art',
                    'Check Fate Titles from Arts',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: randomizzaStatsBilanciate,
                icon: const Icon(Icons.casino),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(t('Randomizza stats', 'Randomize stats')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget onlinePage() {
    return responsivePageList(
      pageKey: 'online',
      maxColumns: 2,
      minColumnWidth: 420,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor('online_root', sectionTitle('Online')),
        onlineStatusPanel(),
        realtimeOculumPanel(),
        oculumFriendsPanel(),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Connessione P2P', 'P2P Connection'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Connettiti ai giocatori nella stessa rete locale (Wi-Fi).',
                  'Connect to players on the same local network (Wi-Fi).',
                ),
              ),
              const SizedBox(height: 14),
              if (!usingInternetRelay &&
                  !isMasterHost &&
                  !isConnectedToMaster) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 460;
                    final buttons = [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: startHosting,
                        icon: const Icon(Icons.hub),
                        label: Text(
                          t(
                            'Ospita Sessione (Master)',
                            'Host Session (Master)',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: startUdpListener,
                        icon: const Icon(Icons.sensors),
                        label: Text(
                          t('Vai Online (Giocatore)', 'Go Online (Player)'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ];

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons[0],
                          const SizedBox(height: 8),
                          buttons[1],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: buttons[0]),
                        const SizedBox(width: 10),
                        Expanded(child: buttons[1]),
                      ],
                    );
                  },
                ),
              ],
              if (!usingInternetRelay && isMasterHost) ...[
                Text(
                  t('Sei il Master (Host).', 'You are the Master (Host).'),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: scanForPlayers,
                  icon: const Icon(Icons.search),
                  label: Text(t('Cerca Giocatori', 'Scan for Players')),
                ),
                const SizedBox(height: 10),
                if (availablePlayers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: availablePlayers.map((p) {
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(
                            '${p['name'] ?? '???'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            t(
                              'Identificatore locale nascosto',
                              'Local identifier hidden',
                            ),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => invitePlayer('${p['ip'] ?? ''}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tertiaryColor,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(t('Invita', 'Invite')),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                if (partyMembri.any((p) => p.containsKey('id'))) ...[
                  Text(
                    t('Giocatori Connessi', 'Connected Players'),
                    style: TextStyle(
                      color: tertiaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...partyMembri.where((p) => p.containsKey('id')).map((p) {
                    final isCoMaster = readBoolValue(p['isCoMaster']);
                    final canToggle =
                        modalitaMaster ||
                        isMasterHost ||
                        (sonoCoMaster && coMasterCanSetCoMaster);
                    final id = '${p['id'] ?? ''}';
                    final name = '${p['nome'] ?? '???'}';
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          t(
                            'Livello ${p['livello'] ?? 0}',
                            'Level ${p['livello'] ?? 0}',
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Switch(
                              value: isCoMaster,
                              activeThumbColor: primaryColor,
                              onChanged: canToggle
                                  ? (val) {
                                      setState(() {
                                        p['isCoMaster'] = val;
                                      });
                                      setCoMasterStatus(id, val);
                                    }
                                  : null,
                            ),
                            IconButton(
                              tooltip: t('Kicka', 'Kick'),
                              onPressed: id.isEmpty
                                  ? null
                                  : () => requestKickSheet(
                                      targetId: id,
                                      targetName: name,
                                    ),
                              icon: const Icon(
                                Icons.person_remove,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
              if (!usingInternetRelay && isConnectedToMaster) ...[
                Text(
                  t('Connesso al Master.', 'Connected to Master.'),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: disconnectFromLocalMaster,
                  icon: const Icon(Icons.close),
                  label: Text(t('Disconnetti', 'Disconnect')),
                ),
              ],
            ],
          ),
        ),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Relay Internet', 'Internet Relay'),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Usa un server relay WebSocket pubblico per collegare Master e giocatori anche su reti diverse, rete mobile o hotspot. Il relay inoltra solo i messaggi della sessione.',
                  'Use a public WebSocket relay server to connect the Master and players across different networks, mobile data or hotspots. The relay only forwards session messages.',
                ),
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'L\'invito privato non mostra server/IP in chiaro. Per nascondere davvero il tuo IP usa un relay pubblico, non il tuo PC come server diretto.',
                  'The private invite does not show server/IP in plain text. To truly hide your IP, use a public relay instead of your PC as the direct server.',
                ),
                color: tertiaryColor,
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Server Relay', 'Relay Server'),
                controller: relayServerController,
                numero: false,
                helper: t(
                  'Si salva da solo. Puoi anche incollare un invito completo sotto.',
                  'It saves automatically. You can also paste a full invite below.',
                ),
              ),
              const SizedBox(height: 10),
              campoTesto(
                label: t('Codice stanza o invito', 'Room Code or Invite'),
                controller: relayRoomController,
                numero: false,
                helper: t(
                  'Il Master può lasciarlo vuoto per generarne uno.',
                  'The Master can leave this empty to generate one.',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tertiaryColor,
                        foregroundColor: tertiaryColor.computeLuminance() > 0.45
                            ? Colors.black
                            : Colors.white,
                      ),
                      onPressed: relayConnected || relayConnecting
                          ? null
                          : pasteRelayInviteAndJoin,
                      icon: const Icon(Icons.content_paste_go),
                      label: Text(
                        t('Incolla invito ed entra', 'Paste invite and join'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: relayAutoReconnect,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('Riconnessione automatica', 'Auto reconnect'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  t(
                    'Se la rete cade, l\'app riprova da sola.',
                    'If the network drops, the app retries by itself.',
                  ),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
                onChanged: (value) {
                  setState(() => relayAutoReconnect = value);
                  programmaSalvataggio();
                },
              ),
              const SizedBox(height: 8),
              if (relayStatus.isNotEmpty) ...[
                smallInfoText(relayStatus, color: tertiaryColor),
                const SizedBox(height: 10),
              ],
              if (relayConnected && relayLatencyMs > 0) ...[
                smallInfoText(
                  t(
                    'Ping relay: ${relayLatencyMs}ms',
                    'Relay ping: ${relayLatencyMs}ms',
                  ),
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 10),
              ],
              if (relayRoomCode.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        t('Stanza: $relayRoomCode', 'Room: $relayRoomCode'),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t('Copia codice', 'Copy code'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: relayRoomCode));
                        setState(() {
                          risultato = t(
                            'Codice stanza copiato.',
                            'Room code copied.',
                          );
                        });
                      },
                      icon: Icon(Icons.copy, color: primaryColor),
                    ),
                    if (usingInternetRelay && isMasterHost)
                      IconButton(
                        tooltip: t(
                          'Copia invito privato',
                          'Copy private invite',
                        ),
                        onPressed: copyRelayInvite,
                        icon: Icon(Icons.share, color: tertiaryColor),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: relayConnected || relayConnecting
                        ? null
                        : startInternetRelayAsMaster,
                    icon: const Icon(Icons.cloud),
                    label: Text(t('Crea stanza rapida', 'Create quick room')),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tertiaryColor,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: relayConnected || relayConnecting
                        ? null
                        : () => joinInternetRelayAsPlayer(),
                    icon: const Icon(Icons.login),
                    label: Text(t('Entra con codice', 'Join by Code')),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: relayConnected || relayConnecting
                        ? null
                        : waitForInternetInvite,
                    icon: const Icon(Icons.notifications_active),
                    label: Text(t('Attendi invito', 'Wait Invite')),
                  ),
                  if (relayConnected)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: disconnectInternetRelay,
                      icon: const Icon(Icons.close),
                      label: Text(t('Disconnetti relay', 'Disconnect Relay')),
                    ),
                ],
              ),
              if (usingInternetRelay && isMasterHost) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: refreshInternetPlayers,
                        icon: const Icon(Icons.person_search),
                        label: Text(
                          t(
                            'Cerca giocatori invitabili',
                            'Find Invitable Players',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (internetAvailablePlayers.isEmpty)
                  smallInfoText(
                    t(
                      'I giocatori devono premere "Attendi invito" sullo stesso relay.',
                      'Players must press "Wait Invite" on the same relay.',
                    ),
                  )
                else
                  ...internetAvailablePlayers.map((p) {
                    final id = '${p['id'] ?? ''}';
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${p['name'] ?? '???'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          id,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: ElevatedButton(
                          onPressed: id.isEmpty
                              ? null
                              : () => inviteInternetPlayer(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tertiaryColor,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(t('Invita', 'Invite')),
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // ARTI / SKILL / TITOLI DEL FATO
  // =====================================================

  void impostaLivelloSkillArt({
    required int artIndex,
    required int skillIndex,
    required int nuovoLivello,
  }) {
    if (artIndex < 0 || artIndex >= arti.length) return;
    if (skillIndex < 0 || skillIndex >= arti[artIndex].skills.length) return;

    setState(() {
      final art = arti[artIndex];
      final skill = arti[artIndex].skills[skillIndex];
      final livelloPrecedente = skill.livello;
      final livelloNuovo = nuovoLivello.clamp(0, artMaxLevel(art)).toInt();
      final openEraAttiva = art.openAttiva && artOpenSbloccata(art);

      skill.livello = livelloNuovo;

      if (art.sbloccata) {
        applicaBonusArtSkillAttuali(skill, livelloNuovo - livelloPrecedente);
        rimarginaHpDaAumentoResilienza(
          artSkillQuickResilienzaBonusAtLevel(skill, livelloNuovo) -
              artSkillQuickResilienzaBonusAtLevel(skill, livelloPrecedente),
        );
      }

      if (!artOpenSbloccata(art)) {
        if (art.sbloccata && openEraAttiva) {
          rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
        }
        art.openAttiva = false;
      }

      risultato = t(
        'Livello Skill aggiornato: ${arti[artIndex].nome} / ${skill.nome} → ${skill.livello}.',
        'Skill level updated: ${arti[artIndex].nome} / ${skill.nome} → ${skill.livello}.',
      );

      aggiungiLog(risultato);
    });

    controllaTitoliDelFatoAutomatici(silenzioso: true);
    programmaSalvataggio();
  }

  Widget skillLevelSelector({
    required int artIndex,
    required int skillIndex,
    required int livelloAttuale,
  }) {
    final maxLevel = artMaxLevel(arti[artIndex]);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int lvl = 0; lvl <= maxLevel; lvl++)
          ChoiceChip(
            selected: livelloAttuale == lvl,
            label: Text(lvl == 0 ? '0' : artLevelRoman(lvl)),
            selectedColor: tertiaryColor.withValues(alpha: 0.75),
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            labelStyle: TextStyle(
              color: livelloAttuale == lvl ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide(
              color: livelloAttuale == lvl
                  ? tertiaryColor
                  : primaryColor.withValues(alpha: 0.45),
            ),
            onSelected: (_) {
              impostaLivelloSkillArt(
                artIndex: artIndex,
                skillIndex: skillIndex,
                nuovoLivello: lvl,
              );
            },
          ),
      ],
    );
  }

  Widget evolutionFrame({
    required String livello,
    required String value,
    required void Function(String) onChanged,
    required Color colore,
    bool active = false,
  }) {
    final quickCommands = parseTitleQuickCommands(value).entries.toList()
      ..sort(
        (a, b) => quickCommandSortIndex(
          a.key,
        ).compareTo(quickCommandSortIndex(b.key)),
      );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? colore.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? tertiaryColor : colore.withValues(alpha: 0.70),
          width: active ? 1.6 : 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$livello / $value',
                  style: TextStyle(
                    color: active ? tertiaryColor : colore,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (active)
                Tooltip(
                  message: t(
                    'Forma attiva: i tag rapidi qui scritti sono nei calcoli.',
                    'Active form: quick tags written here are counted.',
                  ),
                  child: Icon(Icons.bolt, color: tertiaryColor, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          campoModello(
            label: '$livello / ???',
            initialValue: value,
            onChanged: onChanged,
            maxLines: 3,
            helper: '@VC+10 @Difesa+15 @Danni-5',
          ),
          if (quickCommands.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final entry in quickCommands)
                  Chip(
                    label: Text(
                      '@${entry.key} ${entry.value >= 0 ? '+' : ''}${entry.value}',
                    ),
                    avatar: Icon(
                      active
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    backgroundColor: active
                        ? tertiaryColor.withValues(alpha: 0.18)
                        : Colors.black26,
                    side: BorderSide(
                      color: active ? tertiaryColor : Colors.grey.shade700,
                    ),
                    labelStyle: TextStyle(
                      color: active ? tertiaryColor : Colors.grey.shade300,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget fateTitlesExplanationPanel() {
    return gothicPanel(
      borderColor: secondaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Titoli del Fato — Regola corretta',
              'Fate Titles — Correct Rule',
            ),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'I Titoli del Fato non si ottengono perché il personaggio sale di livello. Si ottengono quando le Skill della prima Art raggiungono determinate soglie. Questo rende il Titolo una conseguenza della crescita dell’Art, non della semplice esperienza numerica.',
              'Fate Titles are not gained because the character levels up. They are gained when the Skills of the first Art reach specific thresholds. This makes the Title a consequence of Art growth, not simple numerical experience.',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('Soglie:', 'Thresholds:'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              '• Primo Titolo del Fato: prima Skill della prima Art al livello 1.\n'
                  '• Secondo Titolo del Fato: seconda Skill della prima Art al livello 2.\n'
                  '• Terzo Titolo del Fato: terza Skill della prima Art al livello 3.',
              '• First Fate Title: first Skill of the first Art at level 1.\n'
                  '• Second Fate Title: second Skill of the first Art at level 2.\n'
                  '• Third Fate Title: third Skill of the first Art at level 3.',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('Mastery Skill:', 'Skill Mastery:'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'Usando certe Skill aumenti di 1 l\'Oculum spendibile su quella Skill; se la usi al massimo della potenza aumenta di 2. Quando la masteri ottieni un Titolo d\'Apprendimento e puoi usare la forma successiva con il suo massimale di Oculum.',
              'By using certain Skills, the spendable Oculum for that Skill increases by 1; if used at maximum power, it increases by 2. When mastered, it grants a Learning Title and lets you use the next form with its Oculum cap.',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: controllaTitoliDelFatoAutomatici,
            icon: const Icon(Icons.auto_awesome),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
            label: Text(
              t(
                'Controlla e crea Titoli del Fato',
                'Check and create Fate Titles',
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool artSkillBonusAttivo(ArtSkill target) {
    for (final art in arti) {
      if (!art.sbloccata) continue;
      for (final skill in art.skills) {
        if (identical(skill, target) && skill.livello > 0) {
          return true;
        }
      }
    }
    return false;
  }

  int artSkillLivelloAttivo(ArtSkill target) {
    for (final art in arti) {
      if (!art.sbloccata) continue;
      for (final skill in art.skills) {
        if (identical(skill, target)) return artSkillBonusLevel(skill);
      }
    }
    return 0;
  }

  Widget artSkillBonusFields(ArtSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Bonus forma / skill', 'Form / skill bonuses'),
          style: TextStyle(
            color: tertiaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        smallInfoText(
          t(
            'I bonus valgono quando questa Skill/Forma ha almeno livello 1.',
            'Bonuses count when this Skill/Form has at least level 1.',
          ),
          color: tertiaryColor,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: t('Resilienza +', 'Resilience +'),
                initialValue: '${skill.resilienza}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  final livello = artSkillLivelloAttivo(skill);
                  if (livello > 0) {
                    applicaBonusAttuali(
                      resilienza: (nuovo - skill.resilienza) * livello,
                    );
                  }
                  skill.resilienza = nuovo;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: t('Volontà +', 'Will +'),
                initialValue: '${skill.volonta}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  final livello = artSkillLivelloAttivo(skill);
                  if (livello > 0) {
                    applicaBonusAttuali(
                      volonta: (nuovo - skill.volonta) * livello,
                    );
                  }
                  skill.volonta = nuovo;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: 'Materia +',
                initialValue: '${skill.materia}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  final livello = artSkillLivelloAttivo(skill);
                  if (livello > 0) {
                    applicaBonusAttuali(
                      materia: (nuovo - skill.materia) * livello,
                    );
                  }
                  skill.materia = nuovo;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: 'Oculum +',
                initialValue: '${skill.oculum}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  final livello = artSkillLivelloAttivo(skill);
                  if (livello > 0) {
                    applicaBonusAttuali(
                      oculum: (nuovo - skill.oculum) * livello,
                    );
                  }
                  skill.oculum = nuovo;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: t('Danni +', 'Damage +'),
                initialValue: '${skill.danni}',
                onChanged: (value) => skill.danni = readIntValue(value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: t('Difesa +', 'Defense +'),
                initialValue: '${skill.difesa}',
                onChanged: (value) => skill.difesa = readIntValue(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color artAccentColor(int artIndex) {
    if (artIndex == 0) return primaryColor;
    if (artIndex == 1) return tertiaryColor;
    return secondaryColor;
  }

  String artOpenDefaultName(int artIndex) {
    return '${t('Open Art', 'Art Open')} ${artIndex + 1}';
  }

  String artOpenDisplayName(CharacterArt art, int artIndex) {
    final clean = art.openName.trim();
    return clean.isEmpty ? artOpenDefaultName(artIndex) : clean;
  }

  void usaOpenArt(int artIndex) {
    if (artIndex < 0 || artIndex >= arti.length) return;

    setState(() {
      final art = arti[artIndex];
      final requiredLevel = artMaxLevel(art);
      final requiredRoman = artLevelRoman(requiredLevel);
      if (!artOpenSbloccata(art)) {
        art.openAttiva = false;
        risultato = t(
          'Open Art bloccata: completa tutte le Skill di ${art.nome} al livello $requiredRoman.',
          'Art Open locked: complete every Skill of ${art.nome} to level $requiredRoman.',
        );
        aggiungiLog(risultato);
        return;
      }

      if (art.openAttiva) {
        rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
        art.openAttiva = false;
      } else {
        if (!isDefiledArt(art)) {
          disattivaTutteLeOpen(exceptArt: art);
        }
        art.openAttiva = true;
        rimarginaHpDaAumentoResilienza(artOpenQuickResilienzaBonus(art));
      }
      risultato = art.openAttiva
          ? '${t('Open Art attivata', 'Art Open activated')}: ${artOpenDisplayName(art, artIndex)}'
          : '${t('Open Art disattivata', 'Art Open deactivated')}: ${artOpenDisplayName(art, artIndex)}';
      aggiungiLog(risultato);
    });

    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
  }

  Widget artQuickCommandChips(CharacterArt art) {
    final detected = artQuickBonuses(art);
    if (detected.isEmpty) return const SizedBox.shrink();

    final active = art.sbloccata;
    final entries = detected.entries.toList()
      ..sort(
        (a, b) => quickCommandSortIndex(
          a.key,
        ).compareTo(quickCommandSortIndex(b.key)),
      );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Chip(
            label: Text(
              '@${entry.key} ${entry.value >= 0 ? '+' : ''}${entry.value}',
            ),
            avatar: Icon(
              active ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 17,
            ),
            backgroundColor: active
                ? tertiaryColor.withValues(alpha: 0.18)
                : Colors.black26,
            side: BorderSide(color: active ? tertiaryColor : Colors.grey),
            labelStyle: TextStyle(
              color: active ? tertiaryColor : Colors.grey.shade300,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }

  Widget artStatusPill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            cleanUiText(label),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget artSummaryCard(int artIndex) {
    final art = arti[artIndex];
    final color = artAccentColor(artIndex);
    final maxLevel = artMaxLevel(art);
    final totalMax = max(1, maxLevel * max(1, art.skills.length));
    final totalLevel = art.skills.fold<int>(
      0,
      (sum, skill) => sum + artSkillBonusLevel(skill),
    );
    final progress = (totalLevel / totalMax).clamp(0.0, 1.0);
    final commonLevel = artLivelloComune(art);
    final openUnlocked = artOpenSbloccata(art);
    final openLabel = openUnlocked
        ? art.openAttiva
              ? t('Open attiva', 'Open active')
              : t('Open pronta', 'Open ready')
        : t('Open bloccata', 'Open locked');
    final cleanName = art.nome.trim().isEmpty
        ? '${t('Art', 'Art')} ${artIndex + 1}'
        : art.nome.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => vaiAllaFunzione(
          page: 3,
          anchorId: 'art_$artIndex',
          logTitle: cleanName,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF090A12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: art.sbloccata
                  ? color.withValues(alpha: 0.70)
                  : Colors.grey.shade700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    art.sbloccata ? Icons.auto_awesome : Icons.lock_outline,
                    color: art.sbloccata ? color : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      cleanUiText('${t('Art', 'Art')} ${artIndex + 1}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: art.sbloccata ? color : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${artLevelRoman(commonLevel)}/${artLevelRoman(maxLevel)}',
                    style: TextStyle(
                      color: art.sbloccata ? tertiaryColor : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                cleanUiText(cleanName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: art.sbloccata ? color : Colors.grey,
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  artStatusPill(
                    label: art.sbloccata
                        ? t('Sbloccata', 'Unlocked')
                        : t('Bloccata', 'Locked'),
                    color: art.sbloccata ? color : Colors.grey,
                    icon: art.sbloccata ? Icons.lock_open : Icons.lock_outline,
                  ),
                  artStatusPill(
                    label: openLabel,
                    color: openUnlocked
                        ? (art.openAttiva ? tertiaryColor : color)
                        : Colors.grey,
                    icon: openUnlocked
                        ? (art.openAttiva ? Icons.flash_on : Icons.auto_awesome)
                        : Icons.lock_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget artSummaryStrip() {
    if (arti.isEmpty) return const SizedBox.shrink();

    return gothicPanel(
      borderColor: primaryColor.withValues(alpha: 0.65),
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 980
              ? min(3, arti.length)
              : constraints.maxWidth >= 620
              ? min(2, arti.length)
              : 1;
          const gap = 8.0;
          final itemWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (int i = 0; i < arti.length; i++)
                SizedBox(width: itemWidth, child: artSummaryCard(i)),
            ],
          );
        },
      ),
    );
  }

  Widget artOpenPanel(int artIndex) {
    final art = arti[artIndex];
    final color = artAccentColor(artIndex);
    final unlocked = artOpenSbloccata(art);
    final level = artLivelloComune(art);
    final requiredLevel = artMaxLevel(art);
    final requiredRoman = artLevelRoman(requiredLevel);
    final activeBonuses = artQuickBonuses(art);

    return functionAnchor(
      'art_${artIndex}_open',
      gothicPanel(
        borderColor: unlocked
            ? (art.openAttiva ? tertiaryColor : color)
            : Colors.grey.shade700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unlocked
                      ? (art.openAttiva ? Icons.lock_open : Icons.auto_awesome)
                      : Icons.lock_outline,
                  color: unlocked ? tertiaryColor : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    artOpenDisplayName(art, artIndex),
                    style: TextStyle(
                      color: unlocked ? tertiaryColor : Colors.grey.shade300,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            smallInfoText(
              unlocked
                  ? t(
                      'Open sbloccata: puoi attivarla. I tag rapidi scritti nella Open valgono finche resta attiva.',
                      'Open unlocked: you can activate it. Quick tags written in the Open count while it stays active.',
                    )
                  : t(
                      'Open bloccata: porta tutte le Skill di questa Art al livello $requiredRoman. Livello comune attuale: ${artLevelRoman(level)}/$requiredRoman.',
                      'Open locked: bring every Skill in this Art to level $requiredRoman. Current shared level: ${artLevelRoman(level)}/$requiredRoman.',
                    ),
              color: unlocked ? tertiaryColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_open_name'),
              label: t('Nome Open Art', 'Art Open Name'),
              initialValue: art.openName,
              onChanged: (value) => art.openName = value,
            ),
            const SizedBox(height: 8),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_open_description'),
              label: t('Descrizione Open Art', 'Art Open Description'),
              initialValue: art.openDescription,
              onChanged: (value) => art.openDescription = value,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_open_buff'),
              label: t('Open Buff @ Art', 'Art Open @ Buff'),
              initialValue: art.openBuff,
              onChanged: (value) => art.openBuff = value,
              maxLines: 2,
              helper: '@VC+10 @Difesa+15 @Danni+Vol/2 Fuoco @ScudoOculum+5',
            ),
            const SizedBox(height: 8),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_open_skill'),
              label: t('Open Skill', 'Open Skill'),
              initialValue: art.openSkill,
              onChanged: (value) => art.openSkill = value,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: unlocked ? () => usaOpenArt(artIndex) : null,
              icon: Icon(art.openAttiva ? Icons.lock_open : Icons.auto_awesome),
              style: ElevatedButton.styleFrom(
                backgroundColor: art.openAttiva
                    ? tertiaryColor
                    : secondaryColor,
                foregroundColor: art.openAttiva ? Colors.black : Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              label: Text(
                art.openAttiva
                    ? t('Open Art Attiva', 'Art Open Active')
                    : t('Usa Open Art', 'Use Art Open'),
              ),
            ),
            if (activeBonuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              smallInfoText(
                activeBonuses.entries
                    .map(
                      (entry) =>
                          '@${entry.key} ${entry.value >= 0 ? '+' : ''}${entry.value}',
                    )
                    .join('   '),
                color: tertiaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void cambiaSbloccoArt(int artIndex, bool sbloccata) {
    if (artIndex < 0 || artIndex >= arti.length) return;

    setState(() {
      final art = arti[artIndex];
      if (art.sbloccata == sbloccata) return;

      final openEraAttiva =
          art.sbloccata && art.openAttiva && artOpenSbloccata(art);
      for (final skill in art.skills) {
        if (skill.livello > 0) {
          final livello = artSkillBonusLevel(skill);
          applicaBonusArtSkillAttuali(skill, sbloccata ? livello : -livello);
          rimarginaHpDaAumentoResilienza(
            artSkillQuickResilienzaBonusAtLevel(skill, livello) *
                (sbloccata ? 1 : -1),
          );
        }
      }

      if (!sbloccata && openEraAttiva) {
        rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
      }

      art.sbloccata = sbloccata;
      if (!artOpenSbloccata(art)) {
        art.openAttiva = false;
      }
      risultato = sbloccata
          ? '${art.nome}: Art sbloccata.'
          : '${art.nome}: Art bloccata.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  Widget artLockedPanel(int artIndex) {
    final color = artAccentColor(artIndex);
    final art = arti[artIndex];

    return functionAnchor(
      'art_$artIndex',
      gothicPanel(
        borderColor: color.withValues(alpha: 0.55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t('Art bloccata', 'Locked Art')} ${artIndex + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            smallInfoText(
              t(
                '${art.nome} è pronta ma non ancora sbloccata.',
                '${art.nome} is ready but not unlocked yet.',
              ),
              color: tertiaryColor,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => cambiaSbloccoArt(artIndex, true),
              icon: const Icon(Icons.lock_open),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: color.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              label: Text(t('Sblocca Art', 'Unlock Art')),
            ),
          ],
        ),
      ),
    );
  }

  void aggiornaTipoArt(int artIndex, String value) {
    if (artIndex < 0 || artIndex >= arti.length) return;

    final art = arti[artIndex];
    final oldLevels = art.skills
        .map((skill) => artSkillBonusLevel(skill))
        .toList();
    final openEraAttiva = art.openAttiva && artOpenSbloccata(art);

    art.tipo = value;

    for (int i = 0; i < art.skills.length; i++) {
      final skill = art.skills[i];
      final newLevel = artSkillBonusLevel(skill);
      final diff = newLevel - oldLevels[i];
      if (diff != 0 && art.sbloccata) {
        applicaBonusArtSkillAttuali(skill, diff);
        rimarginaHpDaAumentoResilienza(
          artSkillQuickResilienzaBonusAtLevel(skill, newLevel) -
              artSkillQuickResilienzaBonusAtLevel(skill, oldLevels[i]),
        );
      }
    }

    if (openEraAttiva && !artOpenSbloccata(art)) {
      if (art.sbloccata) {
        rimarginaHpDaAumentoResilienza(-artOpenQuickResilienzaBonus(art));
      }
      art.openAttiva = false;
    }
  }

  Widget artDataPanel(int artIndex) {
    final color = artAccentColor(artIndex);
    final art = arti[artIndex];
    final maxLevel = artMaxLevel(art);
    final commonLevel = artLivelloComune(art);
    final totalMax = max(1, maxLevel * max(1, art.skills.length));
    final totalLevel = art.skills.fold<int>(
      0,
      (sum, skill) => sum + artSkillBonusLevel(skill),
    );
    final progress = (totalLevel / totalMax).clamp(0.0, 1.0);
    final openUnlocked = artOpenSbloccata(art);

    return functionAnchor(
      'art_$artIndex',
      gothicPanel(
        borderColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${t('Art', 'Art')} ${artIndex + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    IconButton(
                      tooltip: t('Copia / invia Art', 'Copy / send Art'),
                      onPressed: () => mostraDialogCopiaArt(art),
                      icon: Icon(Icons.send, color: primaryColor),
                    ),
                    IconButton(
                      tooltip: t('Blocca Art', 'Lock Art'),
                      onPressed: () => cambiaSbloccoArt(artIndex, false),
                      icon: Icon(Icons.lock_outline, color: color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                artStatusPill(
                  label:
                      '${t('Livello comune', 'Shared level')} ${artLevelRoman(commonLevel)}/${artLevelRoman(maxLevel)}',
                  color: commonLevel >= maxLevel ? tertiaryColor : color,
                  icon: Icons.account_tree,
                ),
                artStatusPill(
                  label: openUnlocked
                      ? art.openAttiva
                            ? t('Open attiva', 'Open active')
                            : t('Open pronta', 'Open ready')
                      : t('Open bloccata', 'Open locked'),
                  color: openUnlocked
                      ? (art.openAttiva ? tertiaryColor : color)
                      : Colors.grey,
                  icon: openUnlocked
                      ? (art.openAttiva ? Icons.flash_on : Icons.auto_awesome)
                      : Icons.lock_outline,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: color,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            if (artIndex == 0)
              smallInfoText(
                t(
                  'La prima Art è quella collegata ai tre Titoli del Fato automatici.',
                  'The first Art is the one linked to the three automatic Fate Titles.',
                ),
                color: tertiaryColor,
              ),
            const SizedBox(height: 12),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_name'),
              label: t('Nome Art', 'Art Name'),
              initialValue: art.nome,
              onChanged: (value) => art.nome = value,
            ),
            const SizedBox(height: 12),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_type'),
              label: t('Tipo Art', 'Art Type'),
              initialValue: art.tipo,
              onChanged: (value) => aggiornaTipoArt(artIndex, value),
              liveRefresh: true,
            ),
            const SizedBox(height: 12),
            campoModello(
              fieldKey: ValueKey('art_${artIndex}_description'),
              label: t('Descrizione Art', 'Art Description'),
              initialValue: art.descrizione,
              onChanged: (value) => art.descrizione = value,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            artOpenPanel(artIndex),
            const SizedBox(height: 8),
            artQuickCommandChips(art),
          ],
        ),
      ),
    );
  }

  String artFateThresholdText(int artIndex, int skillIndex) {
    if (artIndex != 0) return '';
    if (skillIndex == 0) {
      return t(
        'Soglia Fato: questa Skill crea il primo Titolo del Fato quando arriva al livello 1.',
        'Fate threshold: this Skill creates the first Fate Title when it reaches level 1.',
      );
    }
    if (skillIndex == 1) {
      return t(
        'Soglia Fato: questa Skill crea il secondo Titolo del Fato quando arriva al livello 2.',
        'Fate threshold: this Skill creates the second Fate Title when it reaches level 2.',
      );
    }
    return t(
      'Soglia Fato: questa Skill crea il terzo Titolo del Fato quando arriva al livello 3.',
      'Fate threshold: this Skill creates the third Fate Title when it reaches level 3.',
    );
  }

  Widget artSkillEditorTile(int artIndex, int skillIndex) {
    final art = arti[artIndex];
    final skill = art.skills[skillIndex];
    final color = artAccentColor(artIndex);
    final level = artSkillBonusLevel(skill);
    final maxLevel = artMaxLevel(art);
    final activeText = artSkillActiveLevelText(skill).trim();
    final skillName = skill.nome.trim().isEmpty
        ? '${t('Skill', 'Skill')} ${skillIndex + 1}'
        : skill.nome.trim();
    final hasNumericBonus =
        skill.resilienza != 0 ||
        skill.volonta != 0 ||
        skill.materia != 0 ||
        skill.oculum != 0 ||
        skill.danni != 0 ||
        skill.difesa != 0;
    final initiallyExpanded = false;
    final fateText = artFateThresholdText(artIndex, skillIndex);

    return functionAnchor(
      'art_${artIndex}_skill_$skillIndex',
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: level > 0
                ? tertiaryColor.withValues(alpha: 0.72)
                : color.withValues(alpha: 0.42),
            width: level > 0 ? 1.25 : 1.0,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: sheetExpansionKey('art_${artIndex}_skill_$skillIndex'),
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: const EdgeInsets.fromLTRB(10, 2, 8, 2),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            iconColor: level > 0 ? tertiaryColor : color,
            collapsedIconColor: level > 0 ? tertiaryColor : color,
            leading: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (level > 0 ? tertiaryColor : color).withValues(
                  alpha: level > 0 ? 0.18 : 0.10,
                ),
                border: Border.all(
                  color: level > 0
                      ? tertiaryColor
                      : color.withValues(alpha: 0.65),
                ),
              ),
              child: Text(
                level <= 0 ? '${skillIndex + 1}' : artLevelRoman(level),
                style: TextStyle(
                  color: level > 0 ? tertiaryColor : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              cleanUiText(skillName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: level > 0 ? tertiaryColor : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    artStatusPill(
                      label:
                          '${t('Livello', 'Level')} ${artLevelRoman(level)}/${artLevelRoman(maxLevel)}',
                      color: level > 0 ? tertiaryColor : Colors.grey,
                      icon: level > 0
                          ? Icons.auto_awesome
                          : Icons.radio_button_unchecked,
                    ),
                    if (hasNumericBonus)
                      artStatusPill(
                        label: t('Bonus attivi', 'Active bonuses'),
                        color: primaryColor,
                        icon: Icons.add_chart,
                      ),
                    if (activeText.isNotEmpty)
                      artStatusPill(
                        label: t('Forma pronta', 'Form ready'),
                        color: color,
                        icon: Icons.bolt,
                      ),
                  ],
                ),
                if (activeText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    cleanUiText(activeText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 11.5,
                      height: 1.18,
                    ),
                  ),
                ],
              ],
            ),
            children: [
              campoModello(
                label: t('Nome Skill', 'Skill Name'),
                initialValue: skill.nome,
                onChanged: (value) {
                  skill.nome = value;
                },
              ),
              const SizedBox(height: 10),
              Text(
                t('Livello Skill', 'Skill Level'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              skillLevelSelector(
                artIndex: artIndex,
                skillIndex: skillIndex,
                livelloAttuale: level,
              ),
              if (fateText.isNotEmpty) ...[
                const SizedBox(height: 8),
                smallInfoText(fateText, color: tertiaryColor),
              ],
              const SizedBox(height: 14),
              Text(
                t('Evoluzioni', 'Evolutions'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              evolutionFrame(
                livello: 'I',
                value: skill.evo1,
                active: level == 1,
                onChanged: (value) {
                  skill.evo1 = value.trim().isEmpty ? '???' : value;
                },
                colore: primaryColor,
              ),
              evolutionFrame(
                livello: 'II',
                value: skill.evo2,
                active: level == 2,
                onChanged: (value) {
                  skill.evo2 = value.trim().isEmpty ? '???' : value;
                },
                colore: tertiaryColor,
              ),
              evolutionFrame(
                livello: 'III',
                value: skill.evo3,
                active: level == 3,
                onChanged: (value) {
                  skill.evo3 = value.trim().isEmpty ? '???' : value;
                },
                colore: secondaryColor,
              ),
              if (isDefiledArt(art)) ...[
                evolutionFrame(
                  livello: 'IV',
                  value: skill.evo4,
                  active: level == 4,
                  onChanged: (value) {
                    skill.evo4 = value.trim().isEmpty ? '???' : value;
                  },
                  colore: primaryColor,
                ),
                evolutionFrame(
                  livello: 'V',
                  value: skill.evo5,
                  active: level == 5,
                  onChanged: (value) {
                    skill.evo5 = value.trim().isEmpty ? '???' : value;
                  },
                  colore: tertiaryColor,
                ),
              ],
              const SizedBox(height: 12),
              artSkillBonusFields(skill),
            ],
          ),
        ),
      ),
    );
  }

  Widget artFormsPanel(int artIndex) {
    final color = artAccentColor(artIndex);
    final art = arti[artIndex];

    return gothicPanel(
      borderColor: color.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Skill / Forme evolutive', 'Evolving Skills / Forms'),
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              artStatusPill(
                label:
                    '${art.skills.where((skill) => artSkillBonusLevel(skill) > 0).length}/${art.skills.length}',
                color: tertiaryColor,
                icon: Icons.auto_awesome,
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Apri solo la Skill che vuoi modificare. La riga mostra livello, forma attiva e bonus prima di entrare nell editor.',
              'Open only the Skill you want to edit. Each row shows level, active form and bonuses before entering the editor.',
            ),
            color: tertiaryColor,
          ),
          const SizedBox(height: 12),
          for (int skillIndex = 0; skillIndex < art.skills.length; skillIndex++)
            artSkillEditorTile(artIndex, skillIndex),
        ],
      ),
    );
  }

  Widget skillsPage() {
    return responsivePageList(
      pageKey: 'skills',
      maxColumns: 2,
      minColumnWidth: 340,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor('skills_root', sectionTitle(t('Skill', 'Skills'))),
        freeSkillsPanel(),
      ],
    );
  }

  Widget artOverviewPanel() {
    final intro = gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: smallInfoText(
        t(
          'Tre Art sbloccabili, con nome, tipo, descrizione e Skill/Forme evolutive come nella vecchia sezione Forme.',
          'Three unlockable Arts, with name, type, description and evolving Skills/Forms like the old Forms section.',
        ),
        color: tertiaryColor,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [intro, fateTitlesExplanationPanel()],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: intro),
            const SizedBox(width: 10),
            Expanded(child: fateTitlesExplanationPanel()),
          ],
        );
      },
    );
  }

  Widget artDashboardPanel(int artIndex) {
    if (!arti[artIndex].sbloccata) return artLockedPanel(artIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1040) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [artDataPanel(artIndex), artFormsPanel(artIndex)],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: artDataPanel(artIndex)),
            const SizedBox(width: 10),
            Expanded(flex: 6, child: artFormsPanel(artIndex)),
          ],
        );
      },
    );
  }

  Widget artDataPage() {
    return responsivePageList(
      pageKey: 'art',
      maxColumns: 1,
      minColumnWidth: 360,
      children: [
        functionAnchor('art_root', sectionTitle(t('Art', 'Arts'))),
        artSummaryStrip(),
        artOverviewPanel(),
        for (int artIndex = 0; artIndex < arti.length; artIndex++)
          artDashboardPanel(artIndex),
      ],
    );
  }

  // =====================================================
}
