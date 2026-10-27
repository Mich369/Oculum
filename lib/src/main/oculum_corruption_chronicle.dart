part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

String oculumCorruptionKind(Map metadata) =>
    switch ('${metadata['corruptionKind'] ?? 'viola'}'.toLowerCase()) {
      'rossa' || 'red' => 'rossa',
      'base' => 'base',
      _ => 'viola',
    };
int oculumCorruptionCommandChance(
  String kind,
  int sourceLevel,
  int targetLevel,
) =>
    ((kind == 'rossa'
                ? 50
                : kind == 'viola'
                ? 80
                : 13) +
            max(0, sourceLevel - targetLevel) * 2)
        .clamp(0, 99);
int oculumCorruptionFreeCommandChance(int sourceLevel, int targetLevel) =>
    (50 + max(0, sourceLevel - targetLevel)).clamp(0, 99).toInt();
int oculumCorruptionEffectiveNights(Map metadata) => max(
  0,
  readIntValue(metadata['elapsedNights']) -
      readIntValue(metadata['antiCorruptionDoses']),
);
int oculumCorruptionControlLimit(Map metadata) => max(
  1,
  readIntValue(
    metadata['controlNightLimit'],
    fallback: switch (oculumCorruptionKind(metadata)) {
      'rossa' => 3,
      'viola' => 2,
      _ => 6,
    },
  ),
);
int oculumCorruptionCureDoses(Map metadata) => max(
  1,
  readIntValue(
    metadata['cureDoses'],
    fallback: switch (oculumCorruptionKind(metadata)) {
      'rossa' => 3,
      'viola' => 6,
      _ => 1,
    },
  ),
);
int oculumCorruptionRandomAttackChance(Map metadata) {
  final nights = oculumCorruptionEffectiveNights(metadata);
  if (nights >= oculumCorruptionControlLimit(metadata)) return 100;
  final kind = oculumCorruptionKind(metadata);
  final initial = readIntValue(
    metadata['randomAttackBase'],
    fallback: kind == 'viola'
        ? 25
        : kind == 'rossa'
        ? 15
        : 5,
  );
  final daily = readIntValue(
    metadata['randomAttackPerNight'],
    fallback: kind == 'viola'
        ? 30
        : kind == 'rossa'
        ? 25
        : 12,
  );
  return (initial + nights * daily).clamp(0, 99);
}

extension _OculumCorruptionChronicle on _OculumHomePageState {
  bool get ownsCorruptionPage => planarState['corruptionPagePurchased'] == true;
  Map<String, dynamic> get currentCorruptionMetadata =>
      getCondition('corruzione')?.metadata ?? {};
  bool get hasChronicleCorruption =>
      getCondition('corruzione') != null &&
      readIntValue(currentCorruptionMetadata['corruptionRulesVersion']) >= 2;
  double get corruptionThemeProgress => getCondition('corruzione') == null
      ? 0
      : (oculumCorruptionEffectiveNights(currentCorruptionMetadata) /
                oculumCorruptionControlLimit(currentCorruptionMetadata))
            .clamp(0.0, 1.0);

  void advanceCorruptionNight() {
    final condition = getCondition('corruzione');
    if (condition == null || !hasChronicleCorruption) return;
    condition.metadata['elapsedNights'] =
        readIntValue(condition.metadata['elapsedNights']) + 1;
    aggiungiLog(
      '[CORRUZIONE ${oculumCorruptionKind(condition.metadata).toUpperCase()}] Notti effettive ${oculumCorruptionEffectiveNights(condition.metadata)}/${oculumCorruptionControlLimit(condition.metadata)}; attacco casuale ${oculumCorruptionRandomAttackChance(condition.metadata)}%.',
    );
  }

  void useAntiCorruption(InventoryItem item) {
    final condition = getCondition('corruzione');
    if (condition == null || !inventario.contains(item) || item.quantita <= 0) {
      return;
    }
    final metadata = condition.metadata;
    metadata['corruptionRulesVersion'] = 2;
    metadata['corruptionKind'] = oculumCorruptionKind(metadata);
    metadata['antiCorruptionDoses'] =
        readIntValue(metadata['antiCorruptionDoses']) + 1;
    metadata['suicideAtFightEnd'] = false;
    final dose = readIntValue(metadata['antiCorruptionDoses']);
    final needed = oculumCorruptionCureDoses(metadata);
    item.quantita--;
    if (item.quantita <= 0) inventario.remove(item);
    if (dose >= needed) {
      removeCondition(condition, force: true);
      for (final request in onlineCombatRequests.values.where(
        (r) =>
            r['targetTag'] == sheetTagAt(schedaCorrente) &&
            const ['corruption', 'corruption_command'].contains(r['kind']) &&
            r['status'] == 'pending',
      )) {
        request['status'] = 'cancelled';
      }
      aggiungiLog(
        '[ANTI-CORRUZIONE] $dose/$needed dosi cumulative: Corruzione rimossa.',
      );
    } else {
      aggiungiLog(
        '[ANTI-CORRUZIONE] $dose/$needed dosi cumulative. Perdita di controllo rinviata di un Riposo Lungo; probabilità attuale ${oculumCorruptionRandomAttackChance(metadata)}%.',
      );
    }
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
    if (mounted) setState(() {});
  }

  bool antiCorruptionReservedForMerchant() {
    final profile = _activeMerchantProfile();
    final roll = readIntValue(
      profile.putIfAbsent(
        'antiCorruptionAvailabilityRoll',
        () => Random.secure().nextInt(100),
      ),
    );
    return roll < (getCondition('corruzione') != null ? 90 : 15);
  }

  Widget corruptionBackdrop() {
    final condition = getCondition('corruzione');
    if (condition == null) return const SizedBox.shrink();
    final kind = oculumCorruptionKind(condition.metadata);
    if (kind == 'base') return const SizedBox.shrink();
    final red = kind == 'rossa';
    final color = Color.lerp(
      red ? const Color(0xFFBD263D) : const Color(0xFF7B45CB),
      red ? const Color(0xFF490F26) : const Color(0xFF230D48),
      corruptionThemeProgress,
    )!;
    final width = MediaQuery.sizeOf(context).width;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: .2),
                      color.withValues(alpha: .65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Opacity(
                opacity: .68,
                child: Image.asset(
                  red
                      ? 'assets/oculum/home_art/creature_baghest_red_corruption_v1.png'
                      : 'assets/oculum/home_art/creature_oculian_purple_corruption_v1.png',
                  key: ValueKey(
                    red ? 'corruption_baghest' : 'corruption_oculian',
                  ),
                  width: min(240.0, width * .3),
                  height: min(340.0, MediaQuery.sizeOf(context).height * .42),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const corruptionPageOffer = <String, dynamic>{
    'id': 'corruption_reference_page',
    'kind': 'corruption_page',
    'name': 'Pagina · Corruzione',
    'cost': 30,
    'desc':
        'Origini, progressione e rimedi. Acquistata: −15% Danni ricevuti dai corrotti.',
  };
  static const antiCorruptionOffer = <String, dynamic>{
    'id': 'alchemy_anti_corruption',
    'kind': 'anti_corruption',
    'name': 'Anti-corruzione',
    'cost': 20,
    'desc':
        'Una dose rinvia di un Riposo Lungo la perdita di controllo. Dosi cumulative: Rossa 3, Viola 6; alla soglia cura la Corruzione.',
  };

  Widget corruptionBookLink() => ListTile(
    dense: true,
    leading: const Icon(Icons.menu_book_outlined),
    title: const Text('Corruzione'),
    subtitle: Text(
      ownsCorruptionPage
          ? 'Pagina acquistata · Resistenza ai corrotti +15%'
          : 'Pagina speciale · 30 Obser',
    ),
    onTap: showCorruptionPage,
  );

  void showCorruptionPage() => showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (_, update) => AlertDialog(
        title: const Text('Corruzione'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'In principio esisteva soltanto la Corruzione Viola degli Oculiani. La Corruzione Rossa e le altre forme più deboli sono nate in seguito, basandosi su di essa.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'La Corruzione Rossa alimenta gli istinti aggressivi e riduce il controllo fino a rendere totalmente succubi dopo tre notti. Ogni dose di Anti-corruzione rinvia la progressione di una notte effettiva e riduce il rischio di bersagli casuali; tre dosi cumulative curano la Rossa, sei la Viola.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'I bersagli casuali comprendono anche gli alleati. Chi ti ha colpito per ultimo ha un peso maggiore nella selezione. I comandi del corruttore consumano le risorse effettivamente disponibili e non concedono Azioni fuori turno.',
                ),
                if (ownsCorruptionPage)
                  const Text(
                    'Conoscenza acquisita: ricevi il 15% di Danni in meno dai corrotti.',
                  ),
                if (getCondition('corruzione') != null) ...[
                  Text(
                    'Corruzione ${oculumCorruptionKind(currentCorruptionMetadata)} · Notti ${oculumCorruptionEffectiveNights(currentCorruptionMetadata)} · Dosi ${readIntValue(currentCorruptionMetadata['antiCorruptionDoses'])}/${oculumCorruptionCureDoses(currentCorruptionMetadata)}',
                  ),
                  for (final pair in const [
                    ('controlNightLimit', 'Notti per la perdita di controllo'),
                    (
                      'randomAttackBase',
                      'Probabilità iniziale di attacco casuale',
                    ),
                    (
                      'randomAttackPerNight',
                      'Aumento della probabilità per notte',
                    ),
                    ('cureDoses', 'Dosi necessarie alla cura'),
                  ])
                    campoModello(
                      label: pair.$2,
                      initialValue:
                          '${readIntValue(currentCorruptionMetadata[pair.$1], fallback: pair.$1 == 'controlNightLimit'
                              ? oculumCorruptionControlLimit(currentCorruptionMetadata)
                              : pair.$1 == 'cureDoses'
                              ? oculumCorruptionCureDoses(currentCorruptionMetadata)
                              : pair.$1 == 'randomAttackBase'
                              ? (oculumCorruptionKind(currentCorruptionMetadata) == 'rossa' ? 15 : 25)
                              : 25)}',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        currentCorruptionMetadata[pair.$1] = max(
                          0,
                          readIntValue(v),
                        );
                        programmaSalvataggio();
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!ownsCorruptionPage)
            FilledButton(
              onPressed: () async {
                await buyMerchantOffer(
                  Map<String, dynamic>.from(corruptionPageOffer),
                );
                if (mounted) update(() {});
              },
              child: const Text('Acquista · 30 Obser'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    ),
  );
}
