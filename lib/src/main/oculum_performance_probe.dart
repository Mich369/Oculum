part of '../../main.dart';

/// Exercises production paths against an isolated fixture in automated tests.
/// No listeners, storage, or work are installed unless a test creates a probe.
@visibleForTesting
class OculumPerformanceProbe {
  OculumPerformanceProbe(State state) : _state = state as _OculumHomePageState;
  final _OculumHomePageState _state;
  Widget settings() => _state.settingsPage();
  void ensurePowerScanners() => _state.ensurePowerScannerOffers();
  InventoryItem scannerFromOffer(Map<String, dynamic> offer) =>
      _state.merchantItemFromOffer(offer);
  bool usableMerchantItem(InventoryItem item) =>
      _state.isMerchantConsumable(item);
  int totalPower(int index) => _state.scoutTotalPowerAt(index);
  Map<String, dynamic> powerReading(
    int index,
    int total, {
    bool success = true,
    bool perception = true,
  }) => _state.scoutAdditionalReading(
    index,
    18,
    success,
    100,
    total: total,
    perception: perception,
  );
  Future<void> revealWeakPoint(String id) => _state.masterDiscoverWeakPoint(id);
  List<Map<String, dynamic>> precisionParts() =>
      _state.currentPrecisionBodyParts;
  void hitBodyPart(Map<String, dynamic> request) =>
      _state.resolvePrecisionBodyHit(request);
  int weakArtPenalty(String source) => _state.artWeakPointRollPenalty(source);
  void weakArtAction() {
    _state.markArtWeakPointAction();
    _state.finishArtWeakPointAction();
  }

  double silkMultiplier(String element) =>
      _state.silkResistanceMultiplier(element);
  Future<void> reflectFairyCore(Map<String, dynamic> request) =>
      _state.applyFateCoreReflection(request);
  bool monsterWeakPointKnown(String id) =>
      _state.monsterBookPartyDiscoveries[_state.monsterBookPartyDiscoveryKey(
        id,
      )]?['weakPoint'] ==
      true;
  Future<Map<String, dynamic>?> selectPrecisionPart(
    Map<String, dynamic> token, {
    bool weakOnly = false,
  }) => _state.selectPrecisionBodyPart(token, weakOnly: weakOnly);
  Future<void> wingHit(
    Map<String, dynamic> request, {
    int hpLost = 1,
    bool critical = true,
    int fallRoll = 1,
  }) => _state.resolveWingCriticalDamage(
    request,
    hpLost: hpLost,
    critical: critical,
    fallRoll: fallRoll,
  );
  int flightBonus(int value) =>
      _state.wingAdjustedFlightBonus(value, 'Fluttuare');
  bool get grounded => _state.wingsGrounded;
  void fractureHit(Map<String, dynamic> request, {int? percentile}) =>
      _state.resolveLimbCriticalDamage(
        request,
        hpLost: 1,
        critical: true,
        percentile: percentile,
      );
  int fracturePenalty(String roll) => _state.fractureRollPenalty(roll);
  bool criticalEffectAllowed(Map request, OculumStructuredEffect effect) =>
      _state.planarIsCriticalEffectAllowed(request, effect);
  int fractureDamagePenalty() =>
      _state.conditionFlatModifier(OculumConditionTarget.danno);
  int fractureDefensePenalty() =>
      _state.conditionFlatModifier(OculumConditionTarget.difesa);

  void collectObserverCurrency(Map enemy, String encounter) =>
      _state.collectObserverTearCurrency(enemy, encounter);
  Future<bool> useConfiguredForTest(CharacterSkillForm form) =>
      _state.useConfiguredAbility(
        source: 'Test pagamento',
        effects: form.effettiStrutturati,
        cost: form.costoStrutturato,
        cooldown: form.cooldownStrutturato,
      );
  void controlOblivion(int total) => _state.applyOblivionMemoryControl(total);
  void oblivionTurn(Map<String, dynamic> token, int percentile) =>
      _state.resolveOblivionMemoryTurn(token, percentile: percentile);
  void damageSaltalungoTail(Map<String, dynamic> request, int hpLost) =>
      _state.resolveSaltalungoTail(request, hpLost);
  Future<void> chargeRabbitHat() => _state.useRabbitHat(charge: true);
  bool dollSpring(int percentile) =>
      _state.grantDollSpringReaction(90, percentile: percentile);
  int activeEffectBonus(String target) =>
      _state.activeStructuredEffectBonus(target);
  String buildMecha(
    InventoryItem item,
    int natural,
    int total, {
    bool crafting = false,
  }) => _state.resolveMechaConstruction(
    item,
    natural: natural,
    total: total,
    crafting: crafting,
  );
  Future<void> enterMecha(InventoryItem item) => _state.enterMecha(item);
  Future<void> exitMecha({bool destroyed = false, int? explosionPercentile}) =>
      _state.exitMecha(
        destroyed: destroyed,
        explosionPercentile: explosionPercentile,
      );
  Future<bool?> escapeMecha(String resource, int natural) =>
      _state.resolveMechaEscape(resource, natural: natural);
  bool destroyMechaWreck(InventoryItem item, int percentile) =>
      _state.destroyMechaWreck(item, percentile: percentile);
  ({int rolled, int restored, int temporary}) rechargeMatter(
    int form,
    int rolled,
  ) => _state.rechargePlasmaMatter(form, rolled: rolled);
  int spendMatter(int amount) =>
      _state.spendArtSkillCostResource('materia', amount);
  void maskedPower(String kind, int form) =>
      _state.activateMaskedPower(kind, form);
  void maskedTurn(int percentile) =>
      _state.maskedTurnStart(percentile: percentile);
  void maskedPassives() => _state.ensureMaskedPassives();
  int maskedAngelicHit(int lost) => _state.maskedAngelicHpHit(lost);
  bool maskedShadow() => _state.maskedShadowActive;
  void maskedAction() => _state.consumeMaskedShadowAction();
  void restoreCreatureAppearance(Map<String, dynamic> sheet) =>
      _state.restoreMonsterAppearance(sheet);
  bool get masterThemeAccess => _state.canManageAllThemes;
  bool colorThemeAvailable(String id) => _state.isColorThemeUnlocked(id);
  Future<bool> selectSheetRelic(String id) =>
      _state.selectCurrentSheetRelic(id);
  Future<void> chooseSheetRelic() => _state.chooseCurrentSheetRelic();
  bool brambleCritical(Map<String, dynamic> request) =>
      _state.claimBrambleChallenge(request);
  int brambleAbsorb(int damage, String element, {bool bypassShields = false}) =>
      _state.brambleAbsorbDamage(damage, element, bypassShields: bypassShields);
  String homeHeroArtwork() => _state.homeHeroImagePath;
  Future<void> activateKi(int natural) =>
      _state.activateMortalKi(natural: natural);
  int kiAmount() => _state.mortalKi;
  int spendKi(int value) => _state.spendMortalKi(value);
  void confirmFaunaKills(Iterable<Map> enemies) =>
      _state.faunaConfirmedKills(enemies, 'test');
  void faunaLongRest() => _state.longRestPlanarEffects();
  void deadlyWeaponAttack(String receipt) => _state.deadlyRecordAttack(receipt);
  void deadlySessionEnd() => _state.deadlyNewSession();
  void startFury() => _state.startFeralisFury();
  void stopFury() => _state.stopFeralisFury();
  int secondLife(int hp, String element, int roll) =>
      _state.tryFuocherelliSecondLife(hp, element, shieldRoll: roll);
  void coreRoll(String receipt) => _state.ogorCoreSuccessfulRoll(receipt);
  void coreRest() => _state.resetOgorCoreRest();
  void recordKills(Iterable<Map> enemies, String encounter) =>
      _state.recordAllMonsterKills(enemies, encounter);
  String killLabel(String id) => _state.monsterKillCountLabel(id);
  Widget masterMonsterBook() => _state.masterDashboardMonsterBookPanel();
  Widget monsterDossier(MonsterBookEntry monster) =>
      _state.monsterReadingDossier(monster);
  void unlockCreatureTheme(
    String id, {
    bool page = false,
    bool theme = false,
  }) => _state.rememberMonsterBookPartyDiscovery(
    id,
    pagePurchased: page,
    themeUnlocked: theme,
  );
  Map<String, dynamic>? creatureKnowledge(String id) =>
      _state.monsterBookPartyKnowledge(id);
  void startMaskedVolley(List<Map<String, dynamic>> packets) =>
      _state.startMaskedVolley(packets);
  void advanceMaskedVolley(
    Map<String, dynamic> request,
    int natural,
    int total,
  ) => _state.advanceMaskedVolley(request, natural, total);
  bool maskedInterrupt(Map<String, dynamic> payload) =>
      _state.receiveMaskedInterrupt(payload);
  bool toggleWillKingdom() => _state.toggleWillKingdom();
  double willKingdomWeight() => _state.willKingdomWeight;
  int kingdomValue(int value, {bool subtrait = false}) =>
      _state.applyWillKingdomBonus(value, subtrait: subtrait);
  void startFight(String id) => _state.startEncounterFight(id);
  bool fightActive() => _state.currentCombatIsActive();
  bool trackerActive() => _state.currentTurnTrackerIsActive();
  Future<void> abilityCatalogue() => _state.showAbilityCatalogue();
  List<Color> abilityCostColors(String cost) => _state.abilityCostColors(cost);
  Color abilityBenefitColor(List<OculumStructuredEffect> effects) =>
      _state.abilityBenefitColor(effects);
  Map<String, dynamic> planarStateSnapshot() =>
      Map<String, dynamic>.from(_state.planarState);
  int referenceAbsorb(int damage, {int mantle = 0, int shield = 0}) =>
      _state.referenceAbsorbDamage(damage, mantle, shield);
  int referenceHalo() => _state.referenceHaloDefense;
  void referenceRest({bool long = true}) =>
      long ? _state.referenceLongRest() : _state.referenceShortRest();
  int shieldTotal() => _state.scudo();
  int criticalShieldTotal() => _state.scudoCritico();
  Map<String, dynamic> lunarCrystals() =>
      Map<String, dynamic>.from(_state.lunarCrystalState);
  int planarIncoming(
    int damage, {
    String element = 'fisico',
    String kind = '',
    bool magical = false,
  }) => _state.planarModifyIncomingDamage(
    damage,
    element: element,
    attackKind: kind,
    magical: magical,
  );
  void fateGrade(int previous, int next, int roll) =>
      _state.rewardIdentityGrades(previous, next, percentile: roll);
  void chooseChaos(bool value) =>
      _state.planarState['identityFateChaos'] = value ? 'Chaos' : 'Fato';
  void chaosStats(List<int> values) => _state.refreshChaosStats(values: values);
  int chaosBonus(String stat) => _state.chaosStatBonus(stat);
  bool chaosProc(String opponent, int percentile) =>
      _state.rollChaosProc(opponent, percentile: percentile);
  Future<bool> spendScout(int subtrait, {int? percentile}) =>
      _state.spendScoutObservationResource(subtrait, percentile: percentile);
  void observeAura() => _state.scheduleAuraObservations();
  void syncSavedAura() => _state.syncSavedAuraPowerToMasterEncounters();
  bool auraReadsPower() => _state.auraCanReadPower;
  Map<String, dynamic> knownPower(String tag) => _state.knownPowerFor(tag);
  bool learnPower(String tag, Map<String, dynamic> read, {int? order}) =>
      _state.rememberKnownPower(tag, read, order: order);
  void auraBand(String tag, String band) => _state.rememberAuraBand(tag, band);
  void auraPermit(int index, String observer) =>
      _state.allowAuraExactObserver(index, observer);
  Map<String, dynamic> auraReply(int index, Map<String, dynamic> request) =>
      _state.passiveAuraReply(index, request);
  Widget powerBadge(String tag) => _state.knownPowerBadge(tag);
  void totalPowerBurst(int power, int die) =>
      _state.activateTotalPowerBurst(power, die);
  void burstAttack(Map<String, dynamic> packet) =>
      _state.applyTotalPowerBurstAttack(packet);
  void burstExposure(Map<String, dynamic> packet) =>
      _state.applyTotalPowerExposure(packet);
  int availableReactions(Map<String, dynamic> token) =>
      _state.masterInitiativeReactionAvailable(token);
  void refreshTurnResources(Map<String, dynamic> token) =>
      _state.restoreMasterInitiativeTurnResources(token);
  bool exhausted() => _state.totalPowerExhausted;
  int normalReactions() => _state.reazioniTotali();
  int fastReactions() => _state.reazioniVelociTotali();
  void tickPlanar() => _state.tickPlanarTurn();
  bool cycleGift(String donor, int percentile) =>
      _state.grantCycleFateGift(donor, percentile: percentile);
  int cycleGiftBonus() => _state.cycleFateGiftBonus;
  void cycleDay(int day) => _state.impostaGiornoOculum(day);
  String celestial() => _state.celestialAllegiance;
  void cycleCritical(
    Map<String, dynamic> request, {
    bool critical = true,
    bool hit = true,
  }) => _state.cycleIncomingCritical(request, critical: critical, hit: hit);
  bool cycleCloud(Map<String, dynamic> request, int percentile) =>
      _state.cycleCloudBlocksDefense(request, percentile: percentile);
  void cycleReaction(Map<String, dynamic> token) =>
      _state.cycleTurnReactions(token);
  int cycleFlight() => _state.cycleNaturalFlightBonus;
  String bestIncomingElement(List<String> elements, {int? tieIndex}) =>
      _state.mostEffectiveIncomingElement(elements, tieIndex: tieIndex);
  void barrierResponse(
    Map<String, dynamic> incoming,
    Map receipt,
    int natural,
  ) => _state.queueCloudBarrierResponse(incoming, receipt, natural: natural);
  void barrierCritical(Map<String, dynamic> request) =>
      _state.claimCloudBarrierCritical(request);
  int provokerAbsorb(int damage, {bool bypass = false}) =>
      _state.absorbProvokerShield(damage, bypassShields: bypass);
  OculumAttackPlan provoke(OculumAttackPlan plan, int percentile) =>
      _state.redirectProvokedAttack(plan, percentile: percentile);
  void provokerEvent(Map<String, dynamic> payload) =>
      _state.receiveProvokerState(payload);
  void escapeTurn(Map<String, dynamic> token, int percentile) =>
      _state.refreshEscapeTurn(token, percentile: percentile);
  void escapeNotice(Map<String, dynamic> record) =>
      _state.prepareEscapeNotice(record);
  Map<String, dynamic> escapeLedger() => _state.escapeLedger;
  void escapeEvent(Map<String, dynamic> payload) =>
      _state.receiveEscapeEvent(payload);
  void rewardCombatResult(Map<String, dynamic> request) =>
      _state.recordEncounterRewardCombatResult(request);
  List<String> applyRewardEffects(
    List<OculumStructuredEffect> effects,
    Map<String, dynamic> request,
  ) => _state.applyStructuredEffectsOnActivation(
    effects,
    source: 'Supporto test',
    applyFusionBonus: false,
    rewardRequest: request,
  );
  void rewardSupportReceipt(Map<String, dynamic> payload) =>
      _state.receiveRewardSupportReceipt(payload);
  Map<String, dynamic> rewardSupportOutbox() =>
      _state.rewardSupportOutbox(_state.sheetTagAt(_state.schedaCorrente));
  Future<void> replayRewardSupportReceipts() =>
      _state.replayRewardSupportReceipts();
  void attachRewardSupportReceipts(Map<String, dynamic> request) =>
      _state.attachRewardSupportReceipts(request);
  void rewardSupportAck(Map<String, dynamic> payload) =>
      _state.receiveRewardSupportAcknowledgement(payload);
  void rewardSupportReply(Map<String, dynamic> payload) =>
      _state.receiveRewardSupportReceiptsFromReply(payload);
  Future<void> attemptEscape() => _state.attemptEscape();
  Future<void> escapeForToken(String encounterId, String tag) =>
      _state.attemptEscapeForToken(encounterId, tag);
  Future<void> answerEscapeForToken(
    String encounterId,
    String escapeId,
    String actorTag,
    String kind,
  ) => _state.answerEscapeForToken(encounterId, escapeId, actorTag, kind);
  Map<String, int> resourceFightXp({
    required String encounterId,
    required String fightInstanceId,
  }) => _state.combatResourceExperienceSnapshot(
    encounterId: encounterId,
    fightInstanceId: fightInstanceId,
  );
  Map<String, int> subtraitFightXp({
    required String encounterId,
    required String fightInstanceId,
  }) => _state.combatSubtraitExperienceSnapshot(
    encounterId: encounterId,
    fightInstanceId: fightInstanceId,
  );
  Map<String, int> claimSubtraitFightXp({
    required String settlementId,
    required String encounterId,
    required String fightInstanceId,
    double multiplier = 1.3,
    Set<String> escapeBonusTraits = const {},
  }) => _state.grantCombatSubtraitExperienceBonus(
    settlementId: settlementId,
    encounterId: encounterId,
    fightInstanceId: fightInstanceId,
    multiplier: multiplier,
    escapeBonusTraits: escapeBonusTraits,
  );
  void recordSubtraitFightXp(String trait, int gain, String receipt) =>
      _state.recordCombatSubtraitExperience(trait, gain, receiptId: receipt);
  String subtraitFightId(String encounterId) =>
      _state.combatSubtraitExperienceFightId(encounterId);
  Set<String> escapeFightTraits({
    required String encounterId,
    required String fightInstanceId,
  }) => _state.combatEscapeSubtraitsSnapshot(
    encounterId: encounterId,
    fightInstanceId: fightInstanceId,
  );
  Widget masterEncounterStage() => _state.referenceEncounterPanel(
    tokens: _state.masterInitiativeTokens,
    activeIndex: _state.masterInitiativeActiveIndex,
    master: true,
  );
  void openMasterEncounterStage() => _state.openReferenceDetail(
    'Scontro',
    'master_participant_fixture',
    () => _state.referenceEncounterPanel(
      tokens: _state.masterInitiativeTokens,
      activeIndex: _state.masterInitiativeActiveIndex,
      master: true,
    ),
  );
  Future<void> participantMenu(
    String encounterId,
    Map<String, dynamic> token,
  ) => _state.showMasterParticipantMenu(encounterId, token);
  Future<void> participantCommand(
    String encounterId,
    Map<String, dynamic> token,
    String command,
  ) => _state.applyMasterParticipantCommand(
    _state.masterParticipantAnchor(encounterId, token),
    command,
  );
  Future<void> receiveParticipantControl(Map<String, dynamic> payload) =>
      _state.receiveMasterParticipantControl(payload);
  Widget escapeRequests() => _state.escapeRequestsPanel();
  Future<void> answerEscape(Map<String, dynamic> record, String kind) =>
      _state.answerEscape(record, kind);
  bool escapeAttackAllowed(Map<String, dynamic> packet) =>
      _state.escapeAttackAllowed(packet);
  int criticalModifier(int natural, int faces) =>
      _state.criticalDieModifier(natural, faces);
  int rollTotal(int natural, int faces, Iterable<int> bonuses) =>
      _state.rollTotalWithCritical(natural, faces, bonuses);
  Future<void> returnToFight(String mode) => _state.returnToFight(mode);
  void escapeDamage(Map<String, dynamic> request) =>
      _state.recordEscapeDamage(request);
  void escapeReturnBonus(Map<String, dynamic> request) =>
      _state.applyEscapeReturnBonus(request);
  void escapeReturnReply(
    Map<String, dynamic> request,
    Map<String, dynamic> reply,
  ) => _state.acceptEscapeReturnReply(request, reply);
  Widget roleFolder(Map<String, dynamic> group, {bool local = true}) =>
      _state.encounterRoleFolder(group, '${group['id']}', local: local);
  Widget encounterSlots() => _state.referenceEncounterSlots();
  Map<String, int> escapeExperience() => _state.escapeExperienceByParticipant();
  void moveToRole(String encounterId, Map<String, dynamic> token) =>
      _state.moveEncounterMemberToRole(encounterId, token);
  String cycleBite({bool lunar = true}) =>
      _state.cycleLunarBiteElement(chooseLunarOnTie: lunar);
  void restPlanar() => _state.longRestPlanarEffects();
  void finishPlanarFight() => _state.resetPlanarFight();
  List<Map<String, dynamic>> partyQuests() => _state.activePartyQuests;
  Future<void> growCharge() => _state.growPreparedSkill();
  Map<String, dynamic> releasePrepared(String kind) =>
      _state.takePreparedSkill(kind);
  Future<void> empowermentDialog() => _state.showRollEmpowermentDialog();
  int preparedRollAmount() => _state.oculumTiroPreparato();
  ({int spent, int bonus, int damageBonus}) consumeRollEmpowerment() =>
      _state.consumaOculumTiro(forAttack: true);
  Widget effectsEditor(List<OculumStructuredEffect> effects) =>
      _state.structuredEffectsEditor(
        effects: effects,
        onChanged: () {},
        storageId: 'windows_effects_regression',
      );
  bool interruptPrepared({int attackerGrade = 0, int? percentile}) =>
      _state.interruptPreparedSkill(
        attackerGrade: attackerGrade,
        percentile: percentile,
      );
  Widget vitalsHud() => _state.stackedVitalsHudPanel(dense: true);
  void makePartyQuests() => _state.ensurePartyQuests();
  void advanceQuests(Iterable<Map> enemies, String id) =>
      _state.advancePartyQuestKills(enemies, id);
  Map<String, dynamic> partyChestSnapshot() =>
      Map<String, dynamic>.from(_state.partyChest);
  String currentTag() => _state.sheetTagAt(_state.schedaCorrente);
  String get permissionCampaignId => _state.permissionCampaignId;
  bool partyKnowsMonsterName(String id) => _state.monsterBookPartyKnowsName(id);
  List<Map<String, dynamic>> monsterBookDiscoverySnapshotEntries() =>
      _state.monsterBookPartyDiscoverySnapshotEntries();
  void receiveMonsterBookDiscoverySnapshot(Map<String, dynamic> payload) =>
      _state.receiveMonsterBookPartyDiscoverySnapshot(payload);
  Future<bool> utilitySpend(String resource) =>
      _state.requestUtilitySpend(resource);
  Future<bool> spendCombatRoll() => _state.spendCombatRollResource();
  Future<void> showAssignSheets() => _state.showAssignSheetsDialog();
  Future<void> initialSheetLoad() => _state.initialSheetLoad;
  Map<String, dynamic> assignmentBody(int index) =>
      _state.sheetAssignmentBody(index);
  Future<bool> applyAssignment(
    Map<String, dynamic> receipt,
    Map<String, dynamic> body, {
    bool? preserveCopy,
  }) => _state.applySheetAssignment(
    receipt,
    body,
    preserveConflictingCopy: preserveCopy,
  );
  Widget combatTurnStatusBar() => _state.referenceTurnControls();
  String combatTurnStatus() => _state.referenceTurnStatusText();
  Map<String, dynamic> combatTurnEncounter() => _state.referenceTurnEncounter();
  Map<String, int> combatTurnResources() =>
      _state.currentSheetTurnResourceCounts();
  Future<bool> spendCounterAttack() => _state.spendCounterAttackResource();
  int takeReactionRollBonus() => _state.consumePendingReactionRollBonus();
  int takeReactionConsequenceBonus() =>
      _state.consumePendingFastReactionConsequenceBonus();
  Map<String, dynamic> turnResourceTestPacket(String id) {
    final tag = currentTag();
    final packet = <String, dynamic>{
      'id': id,
      'kind': 'help',
      'helpMode': 'turn_resource',
      'encounterId': _state.onlineCombatEncounterId,
      'sourceTag': tag,
      'targetTag': tag,
      'sourceName': _state.realtimeDisplayName(),
      'helpBonus': 0,
    };
    _state.attachPendingCombatTurnResources(packet);
    return _state.permissionEnvelope(packet);
  }

  Map<String, int> itemBonuses(InventoryItem item) =>
      _state.itemQuickBonuses(item);
  bool canEquip(InventoryItem item) => _state.canEquipInventoryItem(item);
  void addCondition(String type, {int stage = 1}) =>
      _state.applyCondition(type, stage: stage);
  int willTotal() => _state.volontaTotale();
  int veilSubtraitBonus() => _state.conditionSubtraitBonus('velo');
  int herbalBonus(String stat) => _state.merchantHerbalStatBonus(stat);
  int emblemBonus({bool subtrait = false}) =>
      _state.summoningEmblemBonus('resilienza', subtrait: subtrait);
  void expireEmblems(String encounterId) =>
      _state.expireSummoningEmblems(encounterId);
  void useTitleOpen(OculumTitle title) => _state.usaOpen(title);
  Widget inventory() => _state.referenceInventoryPage();
  Widget deferredInventorySection(WidgetBuilder builder) =>
      _state.dropdownSection(
        title: 'Lazy inventory test',
        icon: Icons.inventory_2_outlined,
        borderColor: _state.tertiaryColor,
        childBuilder: builder,
      );
  Widget masterCatalog({bool initiallyExpanded = true}) =>
      _state.masterItemGiftPanel(initiallyExpanded: initiallyExpanded);
  Widget catalogBrowserForTest(List<InventoryItem> Function() loadItems) =>
      _OculumMasterCatalogBrowser(owner: _state, loadItems: loadItems);
  void equipItem(InventoryItem item, bool value) =>
      _state.setInventoryItemEquipped(item, value);
  List<InventoryItem> masterCatalogItems() => _state._masterGiftCatalog();
  void advanceHerbs(String trigger) => _state.advanceSmokingHerbs(trigger);
  int difficultyRollModifier() => _state.modificatoreDifficoltaTiro();
  void applyHealing(int amount) =>
      _state.applyStructuredHealing('vita', amount);
  Map<String, int> willParts() => {
    'current': _state.currentVolonta(),
    'runtime': _state.runtimeCurrentStatBonus('volonta'),
    'food': _state.nourishmentStatBonus('volonta', _state.currentVolonta()),
    'flat': _state.conditionFlatModifier(OculumConditionTarget.volonta),
  };
  void encounterRewards(List<Map<String, dynamic>> rewards) =>
      _state.receiveEncounterRewards(rewards);
  bool dustExperience(String subtraitId, int die) =>
      _state.useAscensionDustForExperience(subtraitId, die: die);
  List<String> highestDustSubtraits() =>
      _state.dustExperienceHighestSubtraits().map((stat) => stat.id).toList();
  void masterRollRequests(Map<String, dynamic> group) =>
      _state.receiveMasterRollRequests(group);
  Future<void> requestedRoll(Map<String, dynamic> request) =>
      _state.performMasterRequestedRoll(request);
  void shopType(String type) => _state.selectMerchantShop(type);
  Future<void> buyShopOffer(Map<String, dynamic> offer) =>
      _state.buyMerchantOffer(offer);
  int get dustPrice => _state.merchantDustPrice;
  int shopCost(Map<String, dynamic> offer) => _state.merchantOfferCost(offer);
  List<Map<String, dynamic>> shopOffers() => _state.recommendedMerchantStock();
  List<OculumColorPreset> get themes => List.unmodifiable(_state.colorPresets);
  void applyTheme(String id) => _state.applicaColorPreset(id);
  Future<void> useCharacterSkill(CharacterSkill skill) =>
      _state.usaFormaSkill(skill, _state.skills.indexOf(skill), 0);
  Future<void> useArtSkill(
    int artIndex,
    int skillIndex,
    int form, {
    bool again = false,
  }) => _state.impostaLivelloSkillArt(
    artIndex: artIndex,
    skillIndex: skillIndex,
    nuovoLivello: form,
    riutilizza: again,
  );
  Future<OculumStructuredEffect?> editEffect(OculumStructuredEffect effect) =>
      _state.showStructuredEffectDialog(initial: effect);
  bool tickEffects(String unit) => _state.tickActiveStructuredEffects(unit);
  List<String> applyEffects(
    Iterable<OculumStructuredEffect> effects, {
    String source = 'Test effetto',
    Map<String, num> spentResources = const {},
  }) => _state.applyStructuredEffectsOnActivation(
    effects,
    source: source,
    spentResources: spentResources,
  );
  int movement() => _state.movimento();
  int maximumHp() => _state.maxHp();
  int maximumTemporaryHp() => _state.thresholdTemporaryHpLimit();
  String difficulty() => _state.normalizedCampaignDifficulty();
  int damageTotal() => _state.dannoTotale();
  bool consumeNextAttackEffects() =>
      _state.consumeNextAttackStructuredEffects();
  Future<void> rollSpecial(String name, int bonus) =>
      _state.tiraValoreSpeciale(name, bonus);
  List<OculumConditionInstance> get conditions =>
      List.unmodifiable(_state.activeConditions);
  int subtraitValue(String id) => _state.hiddenEyeTotal(
    _state.hiddenEyeStats.firstWhere((stat) => stat.id == id),
  );
  Future<void> spawnBookCreature(String id) =>
      _state.showMonsterBookQuickSpawnDialog(monsterById(id)!);
  List<OculumPawnGuardian> get pawns => List.unmodifiable(_state.pawnGuardians);
  int interceptPawnDamage(String tag, int amount) =>
      _state.redirectPawnHpDamage(tag, amount);
  Future<void> advancePawn(String id, int turn) =>
      _state.advancePawnTurn(id, turn);

  void openDice() => _state.openReferenceDetail(
    'Sessione Dadi',
    'sheet_dice',
    _state.sheetDiceRollPanel,
  );
  void openResistances() => _state.openResistanceDetails();
  Future<void> showCreateFallenEye({Map<String, dynamic>? editingEye}) =>
      _state._showCreateFallenEyeDialog(editingEye: editingEye);
  Widget skillsPage() => _state.skillsPage();
  Widget contextActionAnchor({
    required Widget child,
    required VoidCallback activate,
    required VoidCallback roll,
  }) => _state.quickContextMenuAnchor(
    label: 'Volontà',
    child: child,
    onActivate: activate,
    onRoll: roll,
    conditionTarget: OculumConditionTarget.volonta,
  );
  void openSubtraits() => _state.openReferenceDetail(
    'Sottotratti',
    'sheet_subtraits',
    _state.referenceSubtraitsPanel,
  );
  Future<void> rollSubtrait(String id) => _state.tiraSottotrattoOcchio(
    _state.hiddenEyeStats.firstWhere((stat) => stat.id == id),
  );
  Widget resistancePanel() => _state.resistanceDetailsPanel();
  Future<void> useScroll(InventoryItem item) =>
      _state.useMerchantConsumable(item);
  int defense() => _state.difesa();
  String attackElement() => _state.elementoDannoDominante();
  String defenseElement([Map request = const {}]) =>
      _state.resolveCombatDefenseElement(request);
  void refillStatsAndHealth() => _state.refullVita();
  bool activateNurseBuff() => _state.activateHeroicNurseBuffForCurrentBattle();
  List<Map<String, dynamic>> structuredEffects() =>
      List<Map<String, dynamic>>.from(
        _state.activeStructuredEffects.map(
          (effect) => Map<String, dynamic>.from(effect),
        ),
      );
  String incomingDamagePreset(String element) =>
      _state.configuredIncomingDamagePreset(element);
  int incomingParserDamage(int damage, String element) =>
      _state.applicaParserDanniSubiti(damage, element);
  double resistanceCommandMultiplier(String command) =>
      _state.damageRuleMultiplierForCommand(command);
  int abilityResistance(String element) =>
      _state.abilityElementResistancePercent(element);
  bool manifestTitleItem(InventoryItem item, bool manifested) =>
      _state.setTitleItemManifested(item, manifested);
  bool manifestSenkaMask(InventoryItem item, bool active) =>
      _state.setSenkaMaskManifested(item, active);
  int repairSenkaMask(int roll) => _state.repairSenkaMaskShield(roll);
  void senkaDamageReceipt(Map request) => _state.senkaConfirmDamage(request);
  int senkaClone(int hp) => _state.createSenkaShadowClone(hp);
  int senkaFusion() => _state.absorbSenkaShadows();
  int senkaCloneCount() => _state.senkaClonesCreated;
  bool senkaShadowEvades(Map request) => _state.senkaEvadesAsShadow(request);
  void senkaMaskHit(Map<String, dynamic> request, {bool critical = true}) =>
      _state.senkaResolveMaskHit(request, critical: critical);
  void senkaStartTurn() => _state.senkaTurnStart();
  void senkaEndFight() => _state.senkaFightEnd();
  void claimSenkaAttack(Map<String, dynamic> request) =>
      _state.claimSenkaAttack(request);
  List<OculumStructuredEffect>? prepareSenka(
    List<OculumStructuredEffect> effects, {
    int seed = 1,
  }) => _state.prepareSenkaEffects(effects, random: Random(seed));
  void scostuCoordination(Map<String, dynamic> request) =>
      _state.scostuResolveCoordination(request);
  int scostuAccuracy(String target) =>
      _state.scostuVeteranAccuracyAgainst(target);
  void scostuNonLethal(String id) =>
      _state.scostuNonLethalDefeat(banditSourceId: id);
  void scostuSyncDeath() => _state.syncCurrentSheetDeathStateToInitiative();
  Future<void> readRecipeBook(InventoryItem item) =>
      _state.readRecipeBook(item);
  bool recipeKnown(OculumRecipe recipe) => _state.recipeKnown(recipe);
  void retainRecipes() => _state.retainPartyRecipeKnowledge();
  void recordPersonalKills(Iterable<Map> enemies, String id, {int? power}) =>
      _state.recordPersonalProgressionKills(enemies, id, ownerPower: power);
  Widget recipeDemandPanel() => _state._craftingDemandPanel();
  void progressionCollect(String material, int grams, String receipt) =>
      _state.recordProgressionMaterialCollection(material, grams, receipt);
  bool progressionConsume(Map requirement) => _state
      .consumeProgressionRequirement(Map<String, dynamic>.from(requirement));
  void cardsTurnStart() => _state.rechargeExplosiveCards();
  bool claimCards(Map request) => _state.claimExplosiveCards(request);
  List<OculumStructuredEffect>? prepareLusierTitle(
    List<OculumStructuredEffect> effects, {
    int seed = 1,
  }) => _state.prepareLusierTitleEffects(effects, random: Random(seed));
  void claimLusierTitle(Map<String, dynamic> request, {int targets = 1}) =>
      _state.claimLusierTitleAttack(request, targets);
  void confirmLusierTitle(Map request) =>
      _state.confirmLusierRegalStrike(request);
  int lusierConditionGuard() => _state.lusierConditionGuard;
  bool lusierConditionResisted(String type, int roll) =>
      _state.lusierPreventsNegativeCondition(
        type,
        'Nemico di prova',
        percentile: roll,
      );
  void grantSolarVitalium() => _state.grantLusierSolarVitalium();
  void applySolarVitalium() => _state.useLusierSolarVitalium();
  int itemSaleValue(InventoryItem item) => _state.merchantSaleValue(item);
  ({int accuracy, int beyondDefense}) lusierReply(
    String target, {
    bool consume = false,
  }) => _state.lusierReplyBonus(target, consume: consume);
  void setIncomingDamagePreset(String element, String preset) =>
      _state.incomingDamagePresets[element] = preset;
  double corruptionResistance() => _state.currentCorruptionResistancePercent();
  double corruptionResistanceForSheet(Map<String, dynamic> sheet) =>
      _state.oculumCorruptionResistanceInSheet(sheet);
  void queueCorruption({
    required String targetTag,
    required int sourceLevel,
    required int sourceTotal,
    String requestId = 'test-corruption',
  }) => _state.queueCorruptionApplication(
    targetTag: targetTag,
    scrollGrade: 12,
    sourceTag: 'corruption-source',
    sourceName: 'Fonte Corruzione',
    sourceTotal: sourceTotal,
    sourceLevel: sourceLevel,
    requestId: requestId,
  );
  Widget corruptionRequests() => _state.onlineCombatRequestsPanel();
  Future<void> resistCorruption(Map<String, dynamic> request, String choice) =>
      _state.defendCorruptionApplication(request, choice);
  void convertItemTitle(InventoryItem item) =>
      _state.convertInventoryItemToTitle(item);
  bool itemTitleAvailable(InventoryItem item, CharacterSkillForm form) =>
      _state.itemTitleFormAvailable(item, form);
  Future<void> useEquipment(InventoryItem item, CharacterSkillForm form) =>
      _state.useEquipmentQuickAbility(
        item,
        form,
        oculumCombatAbilityRole(
          form.effettiStrutturati,
          explicitType: form.tipo,
        ),
      );
  Widget itemTitleEditor(InventoryItem item) =>
      _state.equipmentAbilityEditor(item);
  void repairItemTitles() => _state.repairConvertedItemTitles();
  void tickEquipmentCooldowns() =>
      _state.tickStructuredAbilityCooldowns('turni', scheduleSave: false);
  int itemShield(InventoryItem item) => _state.itemShieldBonus(item);
  String get planeId => _state.selectedPlaneId;
  Future<void> useNecromancy(InventoryItem item) =>
      _state.useNecromancyEquipment(item);
  void skullHit() => _state.advanceSkullFormHit();
  Widget dicePanel() => _state.sheetDiceRollPanel(dense: true);
  Widget subtraitsPanel() => _state.referenceSubtraitsPanel();
  void resetEncounter({bool increment = false}) =>
      _state.resetMasterInitiativeRound(increment: increment);
  void reportedTurn(int value) =>
      _state.setPlayerReportedTurn(value, broadcast: false);
  void removeParticipant(int index) =>
      _state.removeMasterInitiativeTokenAt(index);
  void damage(int amount) => _state.applicaDannoSubito(dannoEsplicito: amount);
  Future<void> damageResolved(
    int amount, {
    bool critical = false,
    bool doubleCritical = false,
    bool criticalShieldAlreadyBroken = false,
    String? packetId,
    int? sandLavaPercentile,
    int criticalMultiplier = 1,
    double defenseMultiplier = 1,
    int enemyLevel = 0,
    String difficulty = 'normale',
    bool resolvedResistance = false,
    bool bypassDefense = false,
    bool bypassShields = false,
    int shieldDamageBonusPercent = 0,
    int resistanceBypassDamage = 0,
  }) => _state.applicaDannoSubito(
    dannoEsplicito: amount,
    critico: critical,
    doubleCritical: doubleCritical,
    criticalShieldAlreadyBroken: criticalShieldAlreadyBroken,
    damagePacketId: packetId,
    sandLavaPercentile: sandLavaPercentile,
    criticalBonusMultiplier: criticalMultiplier,
    defenseMultiplier: defenseMultiplier,
    enemyDifficulty: difficulty,
    enemyLevel: enemyLevel,
    resolvedResistance: resolvedResistance,
    bypassDefense: bypassDefense,
    bypassShields: bypassShields,
    shieldDamageBonusPercent: shieldDamageBonusPercent,
    resistanceBypassDamage: resistanceBypassDamage,
  );

  bool get masterPermissions => _state.haPermessiMaster;
  bool get canActWithoutApproval => _state.canActWithoutMasterApproval;
  String get permissionScope => _state.permissionScope;
  void receivePermission(String event, Map<String, dynamic> payload) =>
      _state.receivePermissionEvent(event, payload);
  void receiveCombat(String event, Map<String, dynamic> payload) =>
      _state.receiveOnlineCombatEvent(event, payload);
  Future<void> connectOnline() => _state.connectRealtimeOculum();
  Future<void> disconnectOnline() async {
    _state.realtimeAutoReconnectEnabled = false;
    await _state.realtimeService?.disconnect();
  }

  void publishTurnOrder() => _state.publishRealtimeInitiativeSnapshot();
  void syncMasterTurnOrder() =>
      _state.sendRealtimeInitiativeSnapshotIfPublished();
  void shareMasterParty() => _state.sendRealtimeMasterVisiblePartyTokens();
  Future<void> resolveSheetIdentity(String tag) =>
      _state.showRealtimeSheetIdentityConflict(tag);
  void receiveRealtime(String event, Map<String, dynamic> payload) =>
      _state.handleRealtimeEvent(event, payload);
  Future<void> requestPlayerSheets() => _state.requestRealtimePlayerSheets();
  Future<void> sendCurrentSheet() => _state.sendRealtimeCurrentSheetManually();
  void recordCurrentEncounter() => _state.captureActiveMasterInitiativeGroup();
  Future<void> finishEncounter(String id, {Random? random}) =>
      _state.finishEncounter(id, random: random);
  bool ensureSheetTags() => _state.assicuraTagSchede();
  Future<void> syncOwnedStaffSheets() =>
      _state.sendRealtimeActiveSheetToStaff();
  Future<void> joinMasterEncounter(Map<String, dynamic> group) =>
      _state.joinSharedMasterEncounter(group);
  Future<void> retryEncounterJoins() => _state.retryPendingEncounterJoins();
  void receiveEncounterJoin(Map<String, dynamic> payload) =>
      _state.receiveRealtimeReportedTurn(payload);
  void shareStaffTurnOrderSheets() => _state.sendRealtimeStaffTurnOrderSheets();
  bool receiveStaffSheet(Map<String, dynamic> payload) =>
      _state.receiveRealtimeSharedSheet(payload);
  List<String> ownedPresenceTags() => _state.ownedOculumTags();
  Widget combatRequestsPanel() => _state.onlineCombatRequestsPanel();
  void claimVampirism(Map<String, dynamic> request) =>
      _state.claimOnlineVampirism(request);
  bool recordCorruptionHit(Map<String, dynamic> request) =>
      _state.recordCorruptionMasteryHit(request);
  String corruptor(Map<String, dynamic> token) =>
      _state.corruptionOwnerForToken(token);
  int corruptionControlChance(Map<String, dynamic> token) =>
      _state.corruptionControlChanceForToken(token);
  Widget combatAbilityBar() => _state.combatAbilityQuickBar();
  Future<void> openCombatActionPanel(OculumCombatAbilityRole role) =>
      _state.showCombatActionPanel(role);
  Future<void> requestDefenseRetry(Map<String, dynamic> request) =>
      _state.requestDefenseRetry(request);
  Future<void> useCombatRoll(OculumCombatAbilityRole role) =>
      _state.useCombatRoll(role);
  List<String> attackTargetTags() =>
      _state.onlineAttackTokens().map(_state.onlineCombatTokenTag).toList();
  Color combatAbilityColor(String resource) =>
      _state.combatAbilityResourceColor([resource]);
  Future<void> defendCombat(Map<String, dynamic> request, String choice) =>
      _state.defendOnlineAttack(request, choice);
  Future<void> defendReferenceMantle(
    Map<String, dynamic> request,
    String resource,
  ) => _state.defendWithReferenceMantle(request, resource);
  Future<void> resolveCombatDefense(
    Map<String, dynamic> request,
    String choice,
    int total, {
    int natural = 0,
  }) => _state.applyResolvedOnlineDefense(
    request,
    choice,
    total,
    defenseNatural: natural,
  );
  List<OculumStructuredEffect> prepareBottledCloud(
    List<OculumStructuredEffect> effects, {
    Random? random,
  }) => _state.prepareBottledCloudEffects(effects, random: random);
  void claimBottledCloud(Map<String, dynamic> request, int targets) =>
      _state.claimBottledCloudAttack(request, targets);
  void bottledCloudPhase(
    Map<String, dynamic> request, {
    required bool critical,
  }) => _state.resolveBottledCloudPhase(request, critical: critical);
  void bottledCloudStop(
    Map<String, dynamic> request, {
    bool hit = true,
    Map<String, dynamic>? resolution,
  }) => _state.applyBottledCloudStopResult(
    request,
    hit: hit,
    resolution: resolution,
  );
  bool bottledCloudInterrupted(Map<String, dynamic> request) =>
      _state.bottledCloudAttackInterrupted(request);
  void bottledCloudTurn(Map<String, dynamic> token, String stamp) =>
      _state.bottledCloudPersonalTurn(token, stamp);
  int bottledCloudPhaseNumber() => _state.bottledCloudPhaseNumber;
  Future<void> applyLocalTargetEffect(Map<String, dynamic> pending) =>
      _state.applyPendingTargetEffectLocally(pending);
  void receiveRole(Map<String, dynamic> payload) =>
      _state.applyRealtimeRoleUpdate(payload);
  void requestAction(String action, String description) =>
      _state.requestMasterAction(action, description);
  Future<void> showRequests() => _state.showMasterRequests();
  Future<void> decideRequest(Map<String, dynamic> request, bool allowed) =>
      _state.decideMasterRequest(request, allowed);
  bool grantThreshold({String? stat, int? variant}) =>
      _state.grantFirstStatThresholdSkill(changedStat: stat, variant: variant);
  Future<void> useThreshold(CharacterSkill skill) =>
      _state.useStatThresholdSkill(skill);
  String activateForce(String id) {
    _state.statoForzaAttivo = id;
    return _state.applicaEffettoImmediatoStatoForza(id);
  }

  void endForce() =>
      _state.terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
  void loseResilienceBuff(int amount) =>
      _state.rimarginaHpDaAumentoResilienza(-amount);
  int currentHp() => _state.hpCorrenti();
  int broodHp() => _state.broodRemainingHp();
  int broodMaxHp() => _state.broodMaximumHp();
  int absorbBroodDamage(int value) => _state.absorbLarvalBroodDamage(value);
  void useWitheredHeart(InventoryItem item) => _state.useWitheredHeart(item);
  void tickConditions(OculumConditionTickTrigger trigger) =>
      _state.processConditionTick(trigger);
  void moveSheetFolderEntry(String tag, String parent, {int? beforeIndex}) =>
      _state.moveSidebarEntry(tag, parent, beforeIndex: beforeIndex);
  Future<void> showSheetFolders() => _state.showSheetFoldersDialog();
  Map<String, dynamic> campaignSnapshot() => _state.currentCampaignSnapshot();
  void loadCampaign(Map<String, dynamic> data) =>
      _state.loadCampaignSnapshot(data);
  int currentTemporaryHp() => _state.hpTemp();
  void increaseBaseStat(String key, int amount) =>
      _state.aumentaStatBaseEAttuale(key, amount);
  void invalidateDerivedCaches() => _state.invalidateDerivedDataCaches();
  int vc() => _state.vc();
  int consumeHelp() => _state.consumeCombatHelp();
  void completeFate(Map<String, dynamic> group) =>
      _state.applyChainedFateCompletion(group);
  int fateExperienceMultiplier() => _state.chainedFateExperienceMultiplier();
  void openReputations() => _state.openReputationManagerSheet();
  Future<void> deliverSupport(List<String> tags) =>
      _state.deliverPendingSupport(selectedTags: tags);
  Future<void> helpAlly() => _state.tiraAiutaCompagno();
  Future<void> retryCombat() =>
      _state.replayOnlineCombatRequests(retryOnly: true);
  Future<void> planAttack({
    int minimum = 1,
    int maximum = 1,
    int? total,
    int? natural,
    String? escapeReactionOf,
  }) => _state.planOnlineAttack(
    minimumTargets: minimum,
    maximumTargets: maximum,
    preparedAttackTotal: total,
    preparedAttackNatural: natural,
    escapeReactionOf: escapeReactionOf,
    resourceAlreadySpent: escapeReactionOf != null,
  );
  bool prepareSandTail(String mode, {int? percent, int? cooldown}) => _state
      .prepareSandTail(mode, receivedPercent: percent, cooldown: cooldown);
  bool get sandTailReady => _state.sandTailReady;
  int defenseTotal() => _state.difesa();
  Map<String, dynamic> sandRuntime() =>
      Map<String, dynamic>.from(_state.planarState);
  String gainCoreMastery(String key, int natural, {int faces = 20}) =>
      _state.registraEsperienzaCriticaStat(
        key: key,
        dado: natural,
        totale: natural,
        faces: faces,
      );
  Map<String, int> levelUpBonuses() => {
    for (final name in _state.statsLevelUp)
      name: _state.bonusLevelUpPerStat(name),
  };
  Map<String, int> coreStats() => {
    'resilienza': _state.resilienzaTotale(),
    'volonta': _state.volontaTotale(),
    'materia': _state.materiaTotale(),
    'oculum': _state.oculumTotale(),
  };
  Map<String, dynamic> snapshot() => _state.statoCorrenteJson();
  bool triggerPackLeaderPhase() => _state.applicaFaseCapobrancoSeServe();
  Map<String, dynamic> fallenEyeBodyFromSource(Map<String, dynamic> source) =>
      _state._fallenEyeBodyFromSource(source);
  Future<void> activateFallenEye(Map<String, dynamic> eye) =>
      _state.activateFallenEye(eye);
  Future<void> deactivateFallenEye(Map<String, dynamic> eye) =>
      _state.deactivateFallenEye(eye);
  int repairFallenEyeSheets() => _state.repairMissingFallenEyeSheets();
  Future<OculumHumanoidChoice?> humanoidCreationDialog() =>
      _state.askHumanoidRole(
        4,
        initialName: 'NPC',
        initialLevel: 0,
        budgetAtLevel: (level) => 4 + level * 4,
      );
  Future<void> useOpen(int index) => _state.usaOpenArt(index);
  Future<void> useOpenSkill(int index) => _state.usaSkillOpenMostro(index);
  Map<String, dynamic> worldClockPrivate() => _state.worldClockCampaignJson();
  Map<String, dynamic> worldClockPublic() => _state.worldClockPublicSnapshot();
  int worldSeconds() => _state.worldClockSeconds;
  void setWorldClock(Map<String, dynamic> value) =>
      _state.loadWorldClockCampaign({
        'id': _state.activeCampaignId,
        'worldClock': value,
      });
  void worldTurn(String encounter, String receipt) =>
      _state.advanceWorldClockTurn(encounter, receipt);
  void worldControl(Map<String, dynamic> payload) =>
      _state.receiveWorldClockControl(payload);
  void selectSharedEncounterForSheet() =>
      _state.selectSharedEncounterForCurrentSheet();
  void worldRest(bool longRest) =>
      _state.notifyWorldRestState(longRest: longRest);
  bool worldConfirmRest(String id, int minutes) =>
      _state.confirmWorldPartyRest(id, minutes);
  bool worldTravel(
    String receipt,
    double metres,
    List<int> members, {
    bool chaos = false,
    String mode = 'walk',
    double percent = 100,
    Random? random,
  }) => _state.commitWorldTravel(
    receipt: receipt,
    metres: metres,
    members: members,
    chaos: chaos,
    mode: mode,
    totalSpeedPercent: percent,
    random: random,
  );
  bool worldChooseEvent(
    String id,
    String choice, {
    String? monsterId,
    int count = 1,
    List<int> merchants = const [],
    Random? random,
  }) => _state.chooseWorldTravelEvent(
    id,
    choice,
    monsterId: monsterId,
    enemyCount: count,
    merchantIndexes: merchants,
    random: random,
  );
  String worldPrepareEncounter(String id) =>
      _state.prepareWorldTravelEncounter(id);
  int worldMonsterBonus(int index) => _state.worldMonsterCoreBonusAt(index);
  void requestSleepRest({bool longRest = true}) =>
      _state.requestWorldPartyRest(longRest: longRest);
  void satisfyNeed(String need) => _state.satisfyPersonalNeed(need);
  Future<void> flushRestRequests() => _state.flushWorldRestRequests();
  Map<String, dynamic> needsSnapshot() => _state.worldNeedsData;
  int needsStatPenalty(String stat) => _state.worldNeedStatPenalty(stat);
  int effectiveAsh() => _state.worldNeedsEffectiveAsh();
  void syncWorldNeeds(Map<String, dynamic> clock) =>
      _state.syncOwnedWorldCalendarAndNeeds(clock);
  bool advanceWorldTime(String receipt, int seconds, String campaignId) =>
      _state.advanceWorldTime(
        receipt: receipt,
        seconds: seconds,
        campaignId: campaignId,
      );
  Widget worldClockWidget() => _state.worldClockBar();
  Widget restCalendarWidget() => _state.restCalendarPanel();
  Future<void> showWorldClock() => _state.showWorldClockPanel();
  void merchantVisitAt(String id, DateTime now) =>
      _state.receiveWorldMerchantVisit(
        _state.permissionEnvelope({
          'id': id,
          'sourceTag': _state.sheetTagAt(_state.schedaCorrente),
        }),
        local: true,
        now: now,
      );
  void replayMerchantRest(Map<String, dynamic> grant) =>
      _state.sendWorldMerchantRestGrant(grant);
  bool recordArtOpenCycle(int index) =>
      _state.recordArtOpenCycleActivation(_state.arti[index]);
  List<OculumStructuredEffect> prepareLunarGuardian(
    List<OculumStructuredEffect> effects, {
    Random? random,
  }) => _state.prepareLunarGuardianEffects(effects, random: random);
  Map<String, dynamic>? lunarGuardianVolley() =>
      _state.lunarGuardianVolleyPending;
  void lunarGuardianIncoming(Map<String, dynamic> request) =>
      _state.lunarGuardianResolveIncomingElement(request);
  Map<String, dynamic>? lunarGuardianEruption(
    Map<String, dynamic> request, {
    required bool hit,
  }) => _state.lunarGuardianPendingEruption(request, hit: hit);
  Future<void> guardianSecondaryDispatch(Map original, {Map? reflection}) =>
      _state.dispatchGuardianSecondaryAttack(original, reflection: reflection);
  Future<void> guardianSecondaryReceive(
    Map<String, dynamic> payload, {
    bool local = false,
  }) => _state.receiveGuardianSecondaryAttack(payload, local: local);
  Future<void> guardianSecondaryRetryOffers() =>
      _state.retryGuardianSecondaryOffers();
  Future<void> guardianSecondaryDefend(
    Map<String, dynamic> request, {
    bool retry = false,
    bool acceptDamage = false,
    int? natural,
  }) => _state.guardianSecondaryDefense(
    request,
    retry: retry,
    acceptDamage: acceptDamage,
    naturalOverride: natural,
  );
  Widget guardianSecondaryPanel() => _state.guardianSecondaryPanel();
  Map<String, dynamic> guardianGoldState() => _state.guardianGoldState;
  double guardianGoldAttempt(String id, {bool melee = true}) =>
      _state.guardianGoldBeforeOutgoingAttack(actionId: id, melee: melee);
  Map<String, dynamic> guardianGoldMetadata({bool melee = true}) =>
      _state.guardianGoldAttackMetadata(melee: melee);
  int guardianGoldDefense(Map<String, dynamic> request) =>
      _state.guardianGoldDefenseBonus(request);
  int guardianGoldPenalty(Map<String, dynamic> request) =>
      _state.guardianGoldIncomingRollPenalty(request);
  Map<String, dynamic>? guardianGoldIncoming(
    Map<String, dynamic> request, {
    required bool hit,
    int damage = 0,
    bool melee = true,
    bool lunar = false,
    int? natural,
  }) => _state.guardianGoldAfterIncomingAttack(
    request,
    hit: hit,
    receivedDamage: damage,
    melee: melee,
    lunar: lunar,
    concentrationNatural: natural,
  );
  void guardianGoldCritical(
    Map<String, dynamic> request,
    int criticalCount, {
    String bodyPart = '',
  }) => _state.receiveGuardianGoldCritical(
    request,
    criticalCount: criticalCount,
    bodyPart: bodyPart,
  );
  int guardianGoldPartPenalty(String part) =>
      _state.guardianGoldPartPenalty(part);
  void guardianGoldTurn() => _state.tickGuardianGoldTurn();
  void guardianGoldReset() => _state.resetGuardianGoldFight();
  void enterEncounter(String id) => _state.enterLocalReferenceEncounter(id);
  void ensureEncounters() => _state.ensureMasterInitiativeGroups();
  void selectEncounter(String id) => _state.selectMasterInitiativeGroup(id);
  Map<String, dynamic> initiativeSnapshot() =>
      _state.buildRealtimeInitiativeSnapshot();
  bool knowsCombatWeakPoint(Map<String, dynamic> token) =>
      _state.combatTokenWeakPointKnown(token);
  void rememberMonsterPage(String monsterId) =>
      _state.rememberMonsterBookPartyDiscovery(monsterId, pagePurchased: true);
  void rememberMonsterDiscovery(
    String monsterId, {
    bool seen = false,
    bool weakPoint = false,
    bool nameKnown = false,
  }) => _state.rememberMonsterBookPartyDiscovery(
    monsterId,
    seen: seen,
    weakPoint: weakPoint,
    nameKnown: nameKnown,
  );
  Future<void> showMonsterBookEntry(String monsterId) =>
      _state.showMonsterBookPartyEntry(monsterById(monsterId)!);
  int combatScoutVeloAt(int index, {String? observerSide}) =>
      _state.sheetCombatScoutVeloAt(index, observerSide: observerSide);
  void refreshEncounterResources(Map<String, dynamic> token) =>
      _state.restoreMasterInitiativeTurnResources(token);
  Map<String, dynamic> publicEncounter(Map<String, dynamic> group) =>
      _state.publicEncounterSnapshot(group);
  String encounterPortrait(Map<String, dynamic> token) =>
      _state.realtimeEncounterPortrait(token);
  void receiveInitiative(Map<String, dynamic> payload) =>
      _state.receiveRealtimeInitiativeSnapshot(payload);
  void receiveEncounterControl(Map<String, dynamic> payload) =>
      _state.receiveEncounterControl(payload);
  int attackBonus() => _state.bonusAttaccoRapido();
  void selectArt(int index) => _state.selectIncorporatedArt(_state.arti[index]);
  void advanceArtTurn() => _state.advanceArtSwitchTurn();
  void hitDuringArtAwakening() => _state.interruptArtAwakening();
  Map<String, int> artBonuses() => {
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
      key: _state.artQuickBonus(key),
  };
  String artCostResource(int index) => _state.effectiveArtCostResource(
    _state.arti[index],
    _state.arti[index].skills.first,
    1,
  );
  int spendArtResource(String resource, int amount) =>
      _state.spendArtSkillCostResource(resource, amount);
  int availableArtResource(String resource) =>
      _state.artSkillCostResourceAvailable(resource);
  bool payArtResources(Map<String, int> payments) =>
      _state.spendArtSkillPayments(payments);
  void settleMonsterRewards(
    Iterable<Map> enemies,
    String encounterId,
    Iterable<String> participants,
  ) {
    _state.recordPlanarMonsterRewards(
      enemies,
      encounterId,
      participantTags: participants,
    );
    _state.settlePartyQuestRewards();
  }

  int attackVc() => _state.vc();
  int levelGradeBonus() => _state.bonusLivelloGrado();
  int defenseCm() => _state.cm();
  int hpMultiplier() => _state.moltiplicatoreHp();
  int outgoingDamage() => _state.dannoTotale();
  Map<String, int> coreBonusAudit(String key) => {
    'raw': readIntValue(_state.currentStatController(key).text),
    'total': _state.currentStatValue(key),
    'visibleTitle': _state.visibleTitleStatBonus(key),
    'titleText': _state.titleQuickBonus(key),
    'artText': _state.artQuickBonus(key),
    'itemText': _state.itemQuickBonus(key),
    'globalText': _state.globalQuickBonus(key),
    'conditional': _state.conditionalBuffStatBonus(key),
    'skillText': _state.skillTextQuickBonus(key),
    'temporary': _state.tempStatBonus(key),
    'herbs': _state.merchantHerbalStatBonus(key),
    'strengthState': _state.statoForzaQuickBonus(key),
    'rebirth': _state.rebirthLevelBonus(),
    'emblem': _state.summoningEmblemBonus(key),
    'structured': _state.activeStructuredEffectBonus(key),
  };
  String damageFormula() => _state.formulaDannoDettagliata();
  Map<String, num> formulaContext() => _state.formulaValueContext();
  InventoryItem merchantItem(
    Map<String, dynamic> offer, {
    String titleType = '',
  }) => _state.merchantItemFromOffer(offer, titleType: titleType);
  int shieldBonus(InventoryItem item) => _state.itemShieldBonus(item);
  Future<void> useMerchantItem(InventoryItem item) =>
      _state.useMerchantConsumable(item);
  void createMerchantProfile() => _state.createRandomMerchantProfile();
  void switchMerchantProfile(String id) => _state.switchMerchantProfile(id);
  List<String> merchantOfferIds() =>
      _state.ensureMerchantStock().map((offer) => '${offer['id']}').toList();
  List<Map<String, dynamic>> realmOffers(String plane) {
    _state.schedePersonaggio[_state.schedaCorrente]['selectedPlaneId'] = plane;
    _state.ensurePlaneOffers();
    _state.ensurePosteaOffers();
    return _state.merchantStock
        .where(_state.merchantOfferMatchesPlane)
        .toList();
  }

  List<int> robotRepairTargets() => _state.meccanioRepairTargets();
  bool get robotEmpathyAvailable => _state.canUseMeccanioEmpathy;
  bool applyRobotEmpathy(
    int total, {
    bool deception = false,
    int natural = 20,
  }) => _state.applyMeccanioEmpathy(
    total,
    deception: deception,
    natural: natural,
  );
  void robotOwnerRest({required bool longRest}) =>
      _state.meccanioOwnerRest(longRest: longRest);
  bool tameRobot(int index, int total) => _state.tameMeccanio(index, total);
  void configureRobot(int index) => _state.configureMeccanio(index);
  void rewardRobotProtection(Map<String, dynamic> request, {int? reduction}) =>
      _state.rewardMeccanioProtection(request, reduction: reduction);
  bool repairRobot(String tag, {required int natural, required int total}) =>
      _state.applyMeccanioRepair(tag, natural: natural, total: total);
  void load(Map<String, dynamic> sheet) => _state.caricaStatoDaJson(sheet);
  Future<void> reloadSave() => _state.caricaDati();
  void saveSheet() => _state.salvaSchedaCorrenteInMemoria();
  Future<void> save() => _state.salvaDatiSoloLocale();
  Future<String?> savedRaw() async =>
      _state._readSaveBlob(await _state._prefs(), _OculumHomePageState.saveKey);
  Future<bool> writeBlob(String key, String value) async =>
      _state._writeSaveBlob(await _state._prefs(), key, value);
  Future<String?> readBlob(String key) async =>
      _state._readSaveBlob(await _state._prefs(), key);
  Widget storyPage() => _state.backgroundAndSkillsPageEfficient();
  void hp(int index) => _state.applyMasterEnemyQuickHpAction(index, damage: 1);
  void turn() => _state.nextMasterInitiativeTurn();
  void setTurn({required int round, int? activeIndex}) =>
      _state.setMasterInitiativeTurn(round: round, activeIndex: activeIndex);
  int masterRound() => _state.masterInitiativeRound;
  bool canUseInitiativeAction(int index) =>
      _state.masterInitiativeCanToggleAction(index);
  void toggleInitiativeAction(int index) =>
      _state.toggleMasterInitiativeActionUsed(index);
  int dodgeTotal() => _state.schivateOculumTotali();
  void quickEditDodge(int delta) => _state.modificaSchivateOculumRapide(delta);
  void activateInitiative(int index) =>
      _state.setMasterInitiativeActiveIndex(index);
  void normalizeInitiative() => _state.normalizeMasterInitiativeTokens();
  void normalizeOpenCycles() => _state.normalizzaOpenAttiveSingole();
  int initiative() => _state.iniziativa();
  int rawInitiative() => _state.iniziativaNonFerita();
  void rewardPowerSample(String tag, int value) =>
      _state.recordFightRewardPowerSample(tag, value);
  void beginRewardPowerTurn(Map<String, dynamic> token) =>
      _state.beginFightRewardPowerTurn(token);
  void showTutorial() => _state.mostraTutorial();
  Map<String, dynamic> get creationDraft => _state.creationDraft;
  List<CharacterSkill> creationPool() => _state.tutorialSkillPool();
  void generateCreation() => _state.generateTutorialDraft();
  bool applyCreation() => _state.applicaSettaggioTutorial();
  int creationPercent() => _state.tutorialCompletionPercent();
  bool requirementsMet(Map<String, dynamic> requirements) =>
      _state.progressionRequirementsMet(requirements);
  bool lastStrength(int roll) => _state.tryConstructLastStrength(roll: roll);
  Map<String, dynamic> get constructCore => _state.constructCore;
  int get constructCoreHp => _state.constructCoreHp;
  void restCore() => _state.restConstructCore();
  int racialRollBonus(String trait) => _state.racialSubtraitRollBonus(trait);
  Future<void> damageConstructCore(int amount) =>
      _state.applicaDannoSubito(dannoEsplicito: amount, hitBodyPart: 'core');
  void sortInitiative() =>
      _state.sortMasterInitiativeTokens(forceInitiative: true);
  void longRest({bool advanceWorldClock = true}) =>
      _state.riposoLungo(advanceWorldClock: advanceWorldClock);
  void recoverLongRestStats() => _state.ripristinaStatsRiposoLungo();
  void restoreStatsAndHp() => _state.ripristinaStatisticheEVita();
  String? changeAsh(int delta, {bool checkFainting = true}) => _state
      .modificaCenereControllata(delta, controllaSvenimento: checkFainting);
  int fatigueRollPenalty() => _state.malusFaticaTiri();
  Future<void> showEnemyCriticalDialog() => _state.mostraCriticoControNemico();
  OculumTitle? visibleTitle() => _state.titoloSempreVisibile;
  int visibleTitleBonus(String stat) => _state.visibleTitleStatBonus(stat);
  int visibleResourceCurrent(String key) => key == 'oculum'
      ? _state.oculumTotale()
      : _state.currentStatWithRuntimeBuffs(key, resourceCurrent(key));
  int visibleResourceMaximum(String key) => _state.statMassimoNaturale(key);
  void selectVisibleTitle(OculumTitle? selected) {
    if (selected != null &&
        !oculumTitleCanBeAlwaysVisible(selected, _state.titoliCalcolabili)) {
      return;
    }
    for (final title in _state.titoliCalcolabili) {
      title.sempreVisibile = identical(title, selected);
      title.visibleSelectionManual = identical(title, selected);
    }
    _state.titoloSempreVisibile;
  }

  void recoverShortRestStats() => _state.recuperaStatsAttualiConRiposoBreve();
  int resourceMaximum(String key) =>
      _state.currentStatNaturalControllerMax(key);
  int resourceCurrent(String key) =>
      readIntValue(_state.currentStatController(key).text);
  void setResourceCurrent(String key, int value) =>
      _state.currentStatController(key).text = '$value';
  int recoverOculum(int value) => _state.addOculum(value, scheduleSave: false);
  void shortRest() => _state.riposoBreve();
  void tickOpenRest({required bool longRest}) =>
      _state.tickOpenLifecycleRest(longRest: longRest);
  void completeOpenFight(String id) => _state.completeOpenLifecycleFight(id);
  bool artOpenBoost(CharacterArt art) => _state.artOwnOpenSkillEmpowered(art);
  bool titleOpenBoost(OculumTitle title) =>
      _state.titleOwnOpenSkillEmpowered(title);
  String ownerTag() => _state.sheetTagAt(_state.schedaCorrente);
  Widget fallenEyesPage() => _state.fallenEyesPage();
  Widget diaryEntryTile(int index) => _state.storyDiaryDatabaseTile(index);
  Map<String, int> titleBonuses(OculumTitle title) =>
      _state.titleQuickBonuses(title);
  Future<Uint8List> oculusFilledPdf() => _state.buildOculusFilledSheetPdf();
  MonsterBookEntry? lookup(String id) => monsterBookEntryById(id);
  void undo() => _state.annullaUltimaModifica();
  void redo() => _state.ripristinaModificaAnnullata();
  Widget hpConditionTile() => _state.quickStatTile(
    label: 'HP',
    value: '${_state.hpCorrenti()}/${_state.maxHp()}',
    icon: Icons.favorite,
    color: Colors.red,
  );
  void cancelPendingSave() {
    _state.autosaveTimer?.cancel();
    _state.inputUiRefreshTimer?.cancel();
  }
}
