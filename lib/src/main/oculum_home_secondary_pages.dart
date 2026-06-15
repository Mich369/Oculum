part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

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
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            cleanUiText(label),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
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
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
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
            color: const Color(0xFF080A12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.58)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cleanUiText(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
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

  Widget restPage() {
    return responsivePageList(
      pageKey: 'rest',
      maxColumns: 2,
      minColumnWidth: 330,
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
              campoTesto(label: 'Cenere', controller: cenereController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: campoTesto(
                      label: t(
                        'Sessioni senza bisogni',
                        'Sessions without needs',
                      ),
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
                  'Segna Sessione senza Mangiare / Bere / Dormire',
                  'Mark Session without Eating / Drinking / Sleeping',
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
                  'Il riposo breve è utile per recuperare parte delle penalità, ma non cancella completamente il peso della giornata. Il riposo lungo è più potente e refulla gli HP.',
                  'Short rest helps recover part of the penalties, but it does not fully erase the weight of the day. Long rest is stronger and refills HP.',
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
    VoidCallback? onUse,
    VoidCallback? onAltUse,
    String? useLabel,
    String? altUseLabel,
    Widget? customIcon,
    bool isMasterControl = false,
  }) {
    bool canEdit = !isMasterControl || haPermessiMaster;

    return gothicPanel(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              customIcon ?? Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                controller.text,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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

  Widget resourcesPage() {
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
          onUse: usaIspirazioneOculum,
          useLabel: t('Usa come critico mantenuto', 'Use as kept critical'),
          onAltUse: convertiIspirazioneOculum,
          altUseLabel: t('Converti in 2 base', 'Convert into 2 base'),
        ),
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
                  : Image.memory(image, fit: BoxFit.cover),
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
    Uint8List? image;
    if (imageRaw.isNotEmpty) {
      try {
        image = base64Decode(imageRaw);
      } catch (_) {
        image = null;
      }
    }

    final side = '${token['side'] ?? 'ally'}';
    final color = side == 'enemy'
        ? Colors.redAccent
        : side == 'neutral'
        ? Colors.orangeAccent
        : Colors.greenAccent;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: const Color(0xFF10121A),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Icon(
              side == 'enemy'
                  ? Icons.bolt
                  : side == 'neutral'
                  ? Icons.remove_red_eye
                  : Icons.shield,
              color: color,
            )
          : Image.memory(image, fit: BoxFit.cover),
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
                  masterPartySheetCard(i),
              ],
            ),
          ),
        ],
      ),
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
              'Crea velocemente NPC, mostri, boss, alleati o comparse senza uscire dalla partita.',
              'Quickly create NPCs, monsters, bosses, allies or secondary characters without leaving the session.',
            ),
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t('Nome nuova scheda', 'New sheet name'),
            controller: quickSheetNameController,
            numero: false,
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
            onPressed: creaSchedaRapidaMaster,
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
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Crea Scheda Rapida', 'Create Quick Sheet'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Usa questo pannello per creare velocemente NPC, mostri, boss, alleati o personaggi secondari senza uscire dalla partita.',
                  'Use this panel to quickly create NPCs, monsters, bosses, allies or secondary characters without leaving the session.',
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Nome nuova scheda', 'New sheet name'),
                controller: quickSheetNameController,
                numero: false,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: quickSheetType,
                dropdownColor: const Color(0xFF11131A),
                decoration: fieldDecoration(
                  t('Tipo nuova scheda', 'New sheet type'),
                ),
                items: tipiScheda
                    .map(
                      (tipo) => DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => quickSheetType = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: campoTesto(
                      label: t('Livello iniziale', 'Starting level'),
                      controller: quickSheetLevelController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: campoTesto(
                      label: t('Grado iniziale', 'Starting grade'),
                      controller: quickSheetGradeController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: creaSchedaRapidaMaster,
                icon: const Icon(Icons.add_circle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                label: Text(t('Crea scheda', 'Create sheet')),
              ),
            ],
          ),
        ),
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
