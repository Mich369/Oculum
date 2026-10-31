part of '../../main.dart';

// MANUALE INTERNO BILINGUE
// =====================================================

const List<ManualSection> oculumManualSections = [
  ManualSection(
    titleIt: 'Manichini e anatomie confermate — 31 ottobre',
    titleEn: 'Puppets and confirmed anatomy — October 31',
    contentIt: r'''
Il Manichino della Spada ha lama nel braccio sinistro e occhio viola; il Manichino di Baghest è una variante distinta con lama destra, occhio rosso e cappotto blu ardesia. Quest’ultimo nasce già succube di Corruzione Rossa dopo tre Notti.
Purificazione specifica: un’Azione e una Pietra anti-corruzione posseduta; 1d20 + Riflessi propri + Memoria base del Manichino contro 1d20 + Riflessi del Manichino. La pietra si consuma soltanto al successo, mai come dose alchemica. Il Master esegue il confronto dal menu del partecipante scegliendo chi usa la pietra; online la risoluzione è riservata al Master della campagna. Fallimento spende l’Azione e conserva la pietra. Successo: il Manichino cade e ritorna gradualmente al terreno; viene rimosso dai partecipanti attivi come sconfitta pacifica, senza morte né premi da uccisione. Dati e risultato sono conservati nella scheda e nel log; nessun azzeramento della Vita per simulare un’uccisione.
Mostro Solare: due occhi laterali, uno per lato. Sciamano Malizioso Minore: testa lignea come punto debole, senza maschera. Navigatore d’Aria: busto e braccia materiali; vortice al posto di gambe e piedi. I materiali anatomici non aggiungono immunità e le parti personalizzate del Master restano prioritarie.
''',
    contentEn: r'''
The Sword Puppet has a left-arm blade and purple eye. The separate Baghest Puppet has a right-arm blade, red eye, slate-blue coat and three elapsed Nights of Red Corruption.
Specific purification uses one Action and an Anti-corruption Stone. Oppose 1d20 + purifier Reflexes + puppet base Memory against 1d20 + puppet Reflexes. Consume the stone only on success; failure spends only the Action. The campaign Master resolves the attempt from the participant menu. Success dissolves the puppet into the terrain as a peaceful defeat, without death or kill rewards. Preserve sheets, logs and custom definitions.
Solar Monster has two lateral eyes. Lesser Malicious Shaman has a wooden-head weak point, no mask. Air Navigator has material arms/torso and a lower vortex replacing legs/feet; no new immunity is inferred.
''',
  ),
  ManualSection(
    titleIt: 'Lupo Infernale del Ghiaccio — correzione del 31 ottobre',
    titleEn: 'Infernal Ice Wolf — October 31 correction',
    contentIt: r'''
Il Lupo Infernale del Ghiaccio vive nelle zone ghiacciate dell'Inferno. Il precedente morso rovente e la carica di cenere sono sostituiti da Morso glaciale infernale e Carica della brina infernale, entrambi di Ghiaccio. Resiste al Ghiaccio; le vecchie affinità al calore sono superate. Restano quattro zampe, due orecchie, due occhi e una coda, nessun soffio aggiuntivo. Valori e limiti delle tecniche invariati e modificabili; le forme superiori del Morso applicano Rallentamento al posto di Bruciatura. La scheggia del drop prende il nome di Scheggia di gelo infernale. Gli identificativi interni sono conservati per compatibilità; le schede personalizzate salvate non vengono riscritte.
''',
    contentEn: r'''
The Infernal Ice Wolf lives in the frozen Infernal regions. Its old ember bite and ash charge become Ice attacks: Infernal Glacial Bite and Infernal Frost Charge. It resists Ice; its old heat affinities are superseded. It retains four legs, two ears, two eyes and one tail, with no new breath attack. Attack values and limits remain editable and unchanged; higher Bite forms slow instead of burning. Its shard is named Infernal Frost Shard. Legacy identifiers and customized saved sheets are preserved.
''',
  ),
  ManualSection(
    titleIt: 'Oblivion Shield e percentuali Vita — 31 ottobre',
    titleEn: 'Oblivion Shield and HP percentages — October 31',
    contentIt: r'''
Oblivion Shield è il nuovo nome del Famelico dell’Oblio; conserva l’ID originale per compatibilità, senza riscrivere nomi o capacità personalizzate delle schede salvate. È un quadrupede nero-violaceo massiccio con quattro arti artigliati, due lunghe corna, lingua rossa e coda ad anello, secondo l’allegato canonico.
Fiammata del non ricordo: Danni attuali +4/8/12 Oblio, costo2/3/4Oculum, CD3turni personali, valori iniziali modificabili. Un critico che danneggia la Vita dopo Difesa e Scudi fa perdere la prima Azione, Reazione o Reazione Veloce successiva tentata; nel log compare «cosa stavo facendo?». Memoria% di resistere, più Fortuna% se del Fato, entro0–100%. Gli Scudi critici proteggono; un contrasto vincente contro la Fiammata evita colpo ed effetto. La Skill resta distinta dal Morso del ricordo vuoto a stadi.
Danno/Cura: puoi scrivere un numero, una formula oppure25% della Vita attuale;25%Tot usa la Vita massima, senza contare gli HP temporanei. Difesa, resistenze e Scudi continuano a funzionare; le opzioni Oltre Difesa e Oltre Scudi restano indipendenti. Cura usa la guarigione normale. Importi automatici e opzioni delle Skill non vengono sostituiti dal campo manuale.
Parser comune: costi come «Materia da1a10» o «Costo: da1a10Materia» restano minimi/massimi modificabili. Gli effetti secondari al nemico possono richiedere un critico e Danni alla Vita; testo non riconosciuto resta da verificare, senza diventare un bonus gratuito. Effetti strutturati salvati e personalizzazioni rimangono prioritari.
''',
    contentEn: r'''
Oblivion Shield keeps its legacy ID and preserves customized saved sheets. Forgetting Flame adds4/8/12Oblivion Damage, costs2/3/4Oculum and has a3personal-turn cooldown, all editable. A critical hit that removes real HP can deny the next attempted Action, Reaction or Fast Reaction. Resistance is Memory%, plus Luck% for Fate characters, capped at100%. Critical Shields and a winning counterattack against the Flame prevent its effect.
Damage/Healing accepts numbers, formulas,25%of current HP or25%Tot of maximum HP. Temporary HP is excluded from the base; Defense, Shields and independent bypass options still apply. Explicit automatic packets keep their own amounts. Saved structured effects take priority over text recognition.
''',
  ),
  ManualSection(
    titleIt: 'Nuvola, scatole e armadilli — 30 ottobre',
    titleEn: 'Cloud, boxes and armadillos — October 30',
    contentIt: r'''
Nuvola in bottiglia: un colpo letale la uccide prima che possa cambiare fase. Sopravvivendo, al 15% della Vita recupera il 75% della massima entro il massimo; rompere prima la bottiglia con un critico mirato che danneggia la Vita avvia invece la fase con recupero aggiuntivo del 40%. Difesa, Scudi e Scudi critici conservano la loro protezione. La bottiglia non rimane un bersaglio dopo il cambio di fase.
La scarica Open aggiunge i normali Danni attuali e 2d50+25 Fulmine, su massimo12 bersagli. L'aumento del15% per persona parte dal secondo bersaglio: uno0%, due15%, tre30%. Una Reazione veloce aggiuntiva per turno personale con il Buff. Fulmine ferma Azione è sempre utilizzabile: un quarto dei Danni attuali e20% di fermare un'Azione, oppure metà e60% con il potenziamento della propria Open. Se non c'è un'Azione in corso, consuma la prossima disponibile; non sottrae Reazioni o Reazioni veloci. Costi, probabilità, bersagli e recuperi restano modificabili.
Costrutto Minore: il nucleo è dentro la scatola e non è mirabile finché la scatola non viene rotta. Colpi mirati alla scatola danneggiano corpo e integrità dopo Difesa e Scudi. Vita scatola iniziale delegata:35% della massima, minimo3, modificabile nell'editor parti; un critico non la apre automaticamente. Le anatomie e gli override espliciti del Master sono conservati.
Pinepine ha la pigna integra e una squama naturalmente più tenera, non una ferita preesistente. Fragilità al Fuoco ed esplosione rimangono.
Mezzo Demone Massiccio: variante distinta e cosciente, più resistente e meno dotata nelle altre statistiche; base iniziale modificabile6RES/3VOL/2MAT/1OCU a livello2, stesso totale base del Mezzo Demone atletico3/4/3/2.
Armadilli: specie base e varianti Sabbia, Cristallo e Legno. Appallottolamento usa un'Azione oppure una Reazione e concede +6/+9/+16CM nelle formeI/II/III finché chiusi. Possono rotolare e speronare; non attaccare con gli artigli esposti finché chiusi. Il bilanciamento iniziale e i materiali restano modificabili, senza inventare immunità o eccezioni degli altri mostri.
''',
    contentEn: r'''
Bottled Cloud: a lethal hit kills it before phase change. A surviving cloud reaching15% HP gains75% maximum HP, capped; an earlier aimed critical that damages body HP breaks its bottle and starts phase two with40% additional recovery instead. Defense and all Shields retain their rules. The bottle is no longer targetable after phase change.
Its Open adds current Damage and2d50+25 Lightning against up to12 targets; +15% per target starts with the second. Its Buff adds a Fast Reaction each personal turn. The always-available stop skill deals25% current Damage with20% Action interruption, empowered to50% and60% respectively. If no Action is pending, consume the next available Action, preserving Reactions and Fast Reactions. Costs, chances, targets and cooldowns are editable.
Minor Construct core is untargetable until its box is broken. Aimed box hits damage both body and box after Defense and Shields; delegated editable initial box HP is35% maximum body HP, minimum3. Critical hits do not automatically open it. Explicit Master anatomy remains authoritative.
Pinepine has an intact cone with a naturally softer scale, preserving Fire vulnerability and explosion. The stocky conscious Half Demon is a separate variant, with editable base6/3/2/1 at level2, preserving the athletic variant3/4/3/2.
Armadillos have base, Sand, Crystal and Wood variants. Rolling up uses one Action or Reaction and grants6/9/16CM for formsI/II/III while closed. They can roll and ram, but not use exposed claws while closed. Delegated balance and materials remain editable without borrowing unrelated immunities.
''',
  ),
  ManualSection(
    titleIt: 'Sonno, bisogni e giorni automatici — 29 ottobre',
    titleEn: 'Sleep, needs and automatic days — October 29',
    contentIt: r'''
Il Master fa passare ore/minuti nella campagna corrente, con un'unica conferma per tutto il party. L'attesa avanza calendario, putrefazione e bisogni; non concede riposi, recuperi o eventi riservati ai viaggi. La giornata resta di nove ore. Il calendario di 369 giorni conserva la data salvata alla migrazione.
Riposo Breve: minimo 30 minuti e UN QUARTO delle statistiche attuali mancanti; questa conferma sostituisce il vecchio testo che indicava metà. Restano la cura 1d100, la riduzione ordinaria della Cenere e le eccezioni delle abilità. Mercanti: due Brevi al massimo per giornata, prima/terza visita valida, 15 minuti reali fra visite. Non sono sonno né pasti.
Riposo Lungo: minimo 90 minuti. Se iniziato di Notte, si dorme almeno fino alla prima Mattina. Si rispetta una durata scelta più lunga, anche se termina dopo quella Mattina. Una dormita è sempre UN solo Lungo per Open, recuperi a riposo e usi.
Bilanciamento iniziale delegato e modificabile: a 90 minuti Vita almeno 75%, metà RES mancante, VOL/MAT/OCU fino ai massimi, integrità Art +25% del massimo oppure +10% se completamente esaurita. Ogni 30 minuti ulteriori: +5 punti percentuali alla soglia Vita (cap100), +10 al recupero RES (cap100), +5 Art (cap100) o +2 Art esaurita (cap40). Non si perdono riserve già sopra il massimo e non si crea sovramassimale gratuito. Recuperi applicati alla scheda una volta sola dopo la durata confermata dal Master.
Fame, sete e sonno hanno registri separati sul tempo della campagna. Un giorno senza cibo O acqua dà +3 Cenere e −1 a una statistica casuale, una sola volta se mancano entrambi. Il malus condiviso rimane finché tutti i bisogni che l'hanno causato sono soddisfatti. Ogni tre giorni senza dormire: −1 RES e −1 OCU. Mangiare rimuove solo i malus della fame, bere quelli della sete, dormire quelli del sonno. Le penalità restano separate dai debuff di altre fonti. I Costrutti non biologici non hanno fame/sete ma richiedono riposo o manutenzione; profili ed esenzioni sono modificabili. Nessun bisogno umano è dedotto automaticamente per cloni, Occhi o specie di fisiologia non definita.
Corruzione: contano le Notti effettivamente trascorse, anche restando svegli, una volta al passaggio Notte→Mattina; un Lungo di giorno non aggiunge una Notte. Conservati notti già segnate e crediti Anti-corruzione.
Negli ultimi trenta minuti della Notte il Sole risbuca scendendo dalla copertura dell'Oblio presso le isole volanti. Il bonus notturno mostruoso cala proporzionalmente per difetto: +10 a trenta minuti dalla Mattina, +5 a quindici, zero al Mattino. Non aumenta livelli, non riscrive statistiche base né cura. Questa descrizione non aggiunge un Sole alle micro realtà sotterranee.
''',
    contentEn: r'''
The campaign Master advances shared hours/minutes once for the party. Waiting advances dates, decay and needs, but grants no rest, healing or travel events. The nine-hour day and saved 369-day calendar are preserved.
Short Rest: minimum30minutes and one quarter of missing current statistics, superseding the older half-recovery text. Merchant rests remain limited and do not count as food, water or sleep.
Long Rest: minimum90minutes; Night sleep lasts at least until the first Morning, preserving any longer chosen duration. One sleep is one Long Rest for Open and ability uses. Delegated editable initial balance at90minutes: HP at least75%, half missing Resilience, Will/Matter/Oculum up to maximum, Arts recover25% maximum or10% if exhausted. Each extra30minutes adds5percentage points to the HP floor(cap100),10to Resilience recovery(cap100),5to Arts(cap100),or2to exhausted Arts(cap40). Existing overflow is preserved. Apply recovery once after the Master confirms duration.
Food, water and sleep have separate campaign clocks. A day without food OR water causes3Ash and one random temporary stat loss, once even if both are missing. Shared penalties remain until both causes are resolved. Every3sleepless days causes−1Resilience and−1Oculum. Meeting one need never clears another or unrelated debuffs. Nonbiological Constructs need maintenance/rest but no food/water. Summons/Eyes/undefined creature physiology have editable exemptions.
Corruption counts actual Night→Morning crossings, including awake nights; daytime rest adds none. Preserve existing nights and Anti-corruption credit. During Night's final30minutes, monster bonuses fade linearly to zero as the Sun descends from Oblivion's cover near the floating islands. No base-stat changes or healing; no Sun is added to underground realms.
''',
  ),
  ManualSection(
    titleIt: 'Conferme del 29 ottobre — premi, Open e tempo condiviso',
    titleEn: 'October 29 confirmations — rewards, Open and shared time',
    contentIt: r'''
Parti anatomiche: salvo eccezioni specifiche, il colpo mirato danneggia sia la parte sia il corpo, dopo le normali protezioni. Restano le fratture da critico mirato valido; una parte può inoltre rompersi quando la sua Vita separata raggiunge zero. Legno, rovi, metallo e parti senza ossa richiedono effetti coerenti con la propria anatomia; nuclei, cristalli e corazze speciali mantengono le regole dedicate.

Schede canoniche aggiornate: Lusier III301 PT/690 Vita massima; Erik I131 PT/260 Vita massima, eccezione personale di circa130 prima del bonus Vita; Senka81 Vita massima senza maschera e135 con maschera al livello1/Grado0. Queste misure sostituiscono quelle storiche dei capitoli precedenti e cambiano se si personalizzano le schede.

Vita e PT: nei primi livelli di ogni Grado, Resilienza×(6+5×Grado) al livello0/10/20…, ×(9+5×Grado) ai livelli1–2/11–12/21–22…, poi×(10+5×Grado) dal3/13/23…. Esempi GradoI:11/14/14/15. Formule speciali di cloni e nuclei restano valide. Alla PT aggiungere floor(moltiplicatoreVita/10) alGrado0 e floor(moltiplicatoreVita/5) dalGradoI. Impostazioni: visibilità della propria PT separata per scheda; in modalità Master autorizzata tutte le PT note sono visibili, anche totale del party. Un totale con dati mancanti deve risultare parziale.
Le conferme più recenti prevalgono sui capitoli storici. Il metodo precedente dei premi resta selezionabile. Nel nuovo metodo, per ogni turno personale di PG e nemici si registra la PT massima raggiunta: a fine intero fight si usa la media dei massimi. Vale per EXP comune, premi PT, Obser e Cristalli; equipaggiamenti non Titoli Item esclusi, compresa la maschera di Senka. La PT visibile non cambia. Nessun premio anticipato per fuga individuale o doppione; solo mostri ostili morti danno bottino. L’EXP comune sottrae la media personale dalla somma nemica, con +20% per Grado superiore come prima.
Ultimo colpo: differenza PT positiva come EXP aggiuntiva e come Obser personali. Aiuto finale25%,50% se decisivo; colpi/contrattacchi/debuff/aiuti precedenti negli ultimi3round10%; cure reali sotto51%HP e difese assistite25%. Per nemico usare il ruolo migliore. EXP sottotratti realmente usati×1,3, oppure×1,2 per aiuti soltanto vecchi;+0,1 per aiuto dopo il primo,+0,2 per uccisione assistita al colpo finale. Nemico morto almeno3livelli sopra o di Grado superiore abilita floor((Oculum speso+HP persi per Danni)/5), esclusi costi HP e Scudi. Membro più debole, pari merito inclusi:+20%EXP dopo gli altri bonus in vittoria,+25%EXP sottotratto di fuga se il party fugge.
Cristallo Ascension Dust, uno nella cassa del party, taglia massima: differenza sommaPTmostriMORTI−sommaPTparty almeno75piccolo,120medio,200grande. Mostri fuggiti o vivi esclusi. Il cristallo non si distrugge automaticamente.
Nel party per il Cristallo contano PG, NPC e Occhi dei Caduti, non altri cloni/evocazioni. Ulteriori EXP per puntiStats realmente spesi e floor((VitaMassima−VitaAttuale)/10), solo con ostile morto almeno pari o fino25PTpiùdebole. Restano aggiuntive al premio risorse contro nemici di almeno3livelli sopra o Grado superiore. Le medie PT dei premi non cambiano i requisiti canonici degli sblocchi. EXP guadagnata nel log e aumenti di livello anche online, senza assegnare premi a chi riceve soltanto il messaggio.
Open recupera con2Riposi Lunghi oppure1Lungo+3Brevi; alleati del Fato1Lungo+2Brevi oppure2Lunghi. Buff fino al recupero dell’Open che lo genera, anche Senka/Lusier; nuova Open lo sostituisce. Una sola Open Buff, salvo una Defiled Art che può coesistere con un’altra Open. Defiled Art: cinque livelliI/II/III/IV/V. Open Skill sempre utilizzabile; potenziamento della propria Open dura3fight conclusi oppure2Brevi+1Lungo in qualsiasi ordine, al primo traguardo. Le altre Skill Open restano utilizzabili. Dicitura sempre Open, come Chaos.
Vita sotto50%: Movimento e Iniziativa già tirata/da tirare75%; sotto10%: Movimento50%,Iniziativa60%. Moltiplicare il valore originale, mai cumulativamente, e ripristinare con le cure senza ritirare dadi o cambiare il partecipante attivo.
Giornata condivisa per campagna:9ore,3Mattina/1PrimoPomeriggio/1Pomeriggio/1Buio/3Notte.10secondi per turno avanzato, non Reazione. Riposo Breve minimo30minuti; Lungo90minuti. Buio:+1tutte statistiche mostruose; Notte:+5+livello+3×Grado, tutti i mostruosi anche alleati/PG/evocazioni, come bonus temporaneo senza cambiare livello.
Mercante: massimo2Riposi Brevi al giornoOculum, prima e terza visita valide; almeno15minuti reali fra visite contate, senza timer mostrato. Viaggio: metri e mediaMovimento del party, un Movimento ogni10secondi; mezzo con percentuale modificabile,500%totale=×5. Il Master conferma il tempo della campagna. Ogni25minuti viaggio75%evento,90%conChaos, viaggio continua e coda privata al Master. Scelte del Fato: fight circa125%PTcomplessiva party, baule10%Mimic/50%RegnoCarneViva, mercanti scelti dal Master. Mimic circa110%PTpiùforte,+1minimo; drop1d20+livello+5×GradoObser e un equipMimic.
Potere dell’oro del Guardiano: Open8Oculum, Buff+15Danni/+10Difesa e(100+livello)×max(1,Grado)Scudo. Spadone primi3tentativi×1,5anche mancati; critico parte bloccata1turno/−3tiri pertinenti, doppio critico corpo2turni; liberazioneA/R Forza/Controllocorporeo/VolontàDT10+livello+2Grado. Scudo riflette15%Danni ravvicinati ricevuti, Scudi compresi, escluso tipoLuna; Riflessi gratis e possibileRper riprovare. Muro3Oculum/CD3, supervantaggio; propria Open cupola mobile/Percezione e svantaggio dei percepiti. Chi colpisce e suoi aiutanti superano la protezione per quell’attivazione. Ogni attacco ricevuto richiede Concentrazione; muro cede al proprio attacco, cupola resta. Senza propria Open scudo compare solo per eseguire la Skill e poi scompare.
Guardie Lunari comuni più deboli delle solari, Elité più forti delle Elité solari; Guardiani di pietra lunare pari al Solare, variante Devil Moon di pietra diabolica-lunare. Argento annerito, dettagli#6a4cb0normali/#8f1b5binfernali. Ik famiglia reale della regina Iris StarEyes, legata alla Luna prima che morisse: mantiene le stelle, non il Sole; ideale d’accoglienza e ricchezza condivisa. GuardieIk pari Elitélunari, ElitéIk più potenti. OpenLunare:1d20pietre distribuibili/un tiro,5fissi ciascuna/10Solar, niente Danni base; Rper evitare soltanto seconda esplosione, non ritentare primo impatto. Spuntoni Buio/Luna secondo debolezza dei nonSolari. Buff+20Danni/+15Difesa, Skill cresta di pietra/anello d’ombra potenziato. Valori delegati e regole complete nel registro confermato.
GuardianoLunare/DevilMoon con petto solido: nucleo nascosto. Corazza separata5+3×Grado colpi mirati riusciti; critico dimezza, doppio distrugge. Occorre Scudo e ScudoOculum a0, conta anche il colpo che li azzera; il danno alla corazza danneggia anche il corpo. Dopo corazza rotta serve un successivo colpo grave alpetto, soglia modificabile. NucleoHP fissato a1/3Vitaattuale all’esposizione; ogni sua percentuale perduta toglie la stessa percentuale della Vita delcorpo fissata allora. Nucleo distrutto significa morte; varianteDevilMoon senza fragilità. Precisione+3 apre scelta parte da mirare, rispettando la reale anatomia e le parti non ancora esposte.
''',
    contentEn: r'''
Maximum HP now uses RES times6+5×Grade on levels0/10/20,9+5×Grade on levels1–2/11–12/21–22, then10+5×Grade from3/13/23. Explicit clone/core HP formulas are preserved. Total Power adds floor(HP multiplier/10) atGrade0 and floor(HP multiplier/5) atGradeI+. Own power visibility is a separate saved sheet setting; authorized Master mode can see all known values and party totals, marking incomplete totals as partial.
The newest confirmations override historical chapters. New encounter rewards use the average of each participant's maximum reward power in each personal turn, excluding ordinary equipment (including Senka's mask) without changing displayed power. Rewards settle once after the entire fight; escaped or living monsters give no loot. Final blow gains positive power difference as extra EXP and Obser. Final attack help grants25%,50%when decisive; recent damage/debuffs10%, healing below51%and defense help25%. Shared Dust crystal thresholds are75/120/200 above total party power, counting dead monsters only. Legacy reward mode remains available.
Open recovers after two Long Rests or one Long plus three Short; Fate allies need one Long plus two Short or two Long. Its Buff persists until recovery and another Open replaces it. One Defiled Art Open may coexist. Own Open Skill empowerment ends after three completed fights or two Short plus one Long, whichever occurs first. Other Open Skills remain usable. Costs and cooldowns still apply.
Below50%HP movement and initiative are75%; below10%movement50%and initiative60%. Recompute from original values, never compound or reroll. Campaign time is shared: nine-hour day,10seconds per advanced combat turn, Short Rest30minutes minimum, Long Rest90minutes. Travel uses party mean movement, editable vehicle multiplier500%total=5times, with Master confirmation. Every25travel minutes has75%event chance,90%with Chaos; events remain in a private Master queue while travel continues.
See the confirmed rules register for the full authored Solar/Lunar Guardian mechanics, Iris StarEyes and Ik lore, merchant rest limits, night bonuses and editable values.
''',
  ),
  ManualSection(
    titleIt: 'Conferme del 28 ottobre — personaggi e progressione',
    titleEn: 'October 28 confirmations — characters and progression',
    contentIt: r'''
Queste correzioni prevalgono sulle diciture storiche successive. I requisiti di crescita considerano il totale permanente della scheda, inclusi derivata e bonus fissi, escludendo maschera e buff temporanei; lo sblocco raggiunto resta acquisito. Le uccisioni richieste valgono anche con un nemico fino a25 PT inferiore al partecipante; PT sconosciuta ed evocati sono esclusi.

Senka: Confluenza delle Ombre richiede Velo permanente13, senza livello minimo aggiuntivo. Mille Tagli richiede Riflessi permanenti9 e uccisione di Erik I, senza livello minimo; Erik vale anche oltre la tolleranza25 PT come eccezione nominale. La Skill usa maschera e coltello,1 Materia, una volta/Riposo Lungo; unico danno Danni attuali + tiro Riflessi + PT, Sfinimento a Senka. Le Open attivano insieme il Buff; le Skill Open restano utilizzabili anche a Open spenta o diversa, potenziate soltanto dalla propria Open, rispettando sblocchi, costi e cooldown.

Lusier III: PT attuale misurata298; Erik I livello8/Grado0:130, come eccezione personale confermata: la Guardia Elité generica conserva la crescita ordinaria. Sono valori delle schede distribuite, da ricalcolare se personalizzate. Vitalium Solare: aggiunge65% Vita attuale +10% Vita massima, per eccesso entro il massimo, senza cancellare un eccesso già presente; altre risorse e integrità Art metà del mancante per eccesso, più1 Scudo critico. Il mazzo personale di Lusier è dorato come eccezione; il generico acquistabile non è d'oro.

Errato e Veterano dell'Errato risolvono il furto soltanto a fine fight vittorioso sugli sconfitti rimasti:75% per Errato,100% e morte per Veterano; Titoli Item esclusi. Il75% degli oggetti riguarda il numero, non il valore:quattro oggetti singoli ne perdono tre. Aura Veterano non cumulativa: Errati+5% VOL,Veterano+15%; colpo riuscito concede solo agli Errati+2 contro quel bersaglio, rinnovato senza accumulo fino al turno seguente del Veterano o prima difesa riuscita del bersaglio.

Guardiano Solare — Mazza d’oro: evoca una mazza dorata e potenzia temporaneamente i Danni. Forma I:×1,2 per1d3 turni personali; II:×1,3 per1d3+2; III:×1,5 per1d3+3. Costi2/4/6Oculum, cooldown4/6/8turni personali, forme ai livelli0/3/6: bilanciamento delegato, modificabile negli editor. La durata viene estratta all’attivazione e non si ritira ricaricando. Gli attacchi contro la fuga usano1d16 per colpire; blocco e attacchi ordinari restano1d20.

Raccogli conserva lo storico del materiale; Possiedi controlla l'inventario attuale; Consuma paga davvero la quantità una volta per requisito. Un libro di ricette si consuma alla lettura e sblocca le sue ricette agli alleati del party; il Master può vedere tutte le ricette. Gli Occhi dei Caduti conservano statistiche, sottotratti, Skill e Art della creatura viva, rispettando i limiti della rarità e le personalizzazioni salvate.
''',
    contentEn: r'''
Latest confirmations override older wording. Growth uses permanent sheet totals, including derived and fixed bonuses, excluding the mask and temporary buffs. Eligible enemies may be up to25 total power below the participant. Unknown power and summons do not count. Senka's fusion requires permanent Veil13; Thousand Cuts requires permanent Reflexes9 and Erik I's confirmed death, with no level gate. Erik is a named exception to the power limit. Open and its Buff activate together; Open Skills remain usable without their own Open, retaining costs, unlocks and cooldowns. Current measured powers: Lusier298,Erik130 as a personal exception; generic Elite Guards retain normal growth. Solar Vitalium adds65% current HP plus10% maximum HP, capped; other resources recover half missing, rounded up, plus one critical shield. Recipe books are consumed and share their unlocks with the party. Fallen Eyes preserve the living creature's actual powers and stats within the existing rarity limits. Escape interception attacks roll1d16 to hit; ordinary attacks and escape-blocking rolls retain1d20.
''',
  ),
  ManualSection(
    titleIt: 'Lusier III, carte e lettura delle potenze basse',
    titleEn: 'Lusier III, cards and low-power readings',
    contentIt: r'''
Lusier III è una Guardia Solare Élite livello13, Grado I: base56 più i punti di livello e Grado distribuiti una sola volta, Volontà primaria e Oculum secondario. Possiede un abito protettivo di seta ricamata d’oro, una spada sacra +20 Danni Solari, un Vitalium Ridefinito separato, 1 Scudo critico e150 Scudo Oculum. La Potenza Totale va letta dalla scheda effettiva con gli equipaggiamenti attivi.

Derisione usa Inganno contro Volontà o difesa mentale coerente, senza Danni diretti. Difesa persa: −5 VOL. Pareggio o vittoria fino a5: −3 VOL. Vittoria oltre5: +3 VOL e Vantaggio contro Lusier fino a fine fight. Critico negativo suo o positivo della difesa: +5 al prossimo attacco contro di lui. Doppio critico positivo della difesa: +9 sostituisce +5, più10 Danni oltre Difesa nel prossimo attacco; gli Scudi si applicano ancora. Non sommare nuovamente il +9 generico al contrattacco.

Carte esplosive acquistabili, non d’oro, Grado I. Ogni carta infligge1d25 + un quinto per difetto dei Danni attuali del portatore, senza un altro Danno base. Fino a5 carte per attacco. I livello10: capienza5, recupero automatico1/turno personale. II livello12: capienza10, recupero2. III livello20: capienza15, recupero3. Lusier conserva l’eccezione personale: II con recupero3. Il mazzo personale è nei suoi drop alla morte confermata; gli evocati non generano premi duplicabili. Vendibile solo al Mercato Nero, con incasso effettivo180–250 Obser; valore iniziale modificabile215, eccezione al prezzo di riacquisto ordinario.

Percezione e alternative coerenti scoprono più facilmente bersagli fino a50 PT, ancora più facilmente fino a30,20 e10. Bilanciamento iniziale: requisito livello+Velo diviso rispettivamente2/3/5/8 per difetto. Per PT50 o inferiore, una lettura riuscita con margine di almeno+5 scopre sia punto debole sia PT esatta, senza valore naturale minimo del dado. Restano gli altri modi già consentiti, incluso20 naturale riuscito. Per il normale controllo probabilistico del numero PT: soglia totale10/5/3/1 e probabilità10/15/20/25 punti percentuali per punto oltre soglia, massimo100%. Una prova fallita non rivela automaticamente il numero.

Slime puro e Mezzo Slime imparano Forma Slime raggiungendo Materia base12 senza buff temporanei; lo sblocco è permanente. Elemento automatico d’attacco dal maggiore bonus Danni, difesa dal maggiore bonus Difesa; la Skill con elemento esplicito prevale. Skill, Art e Titoli equipaggiati/in uso aggiungono3 punti percentuali di resistenza elementale ciascuno, forme contate una volta, Art e Skill separatamente. Esclusi equipaggiamenti non Titoli Item. Resistenza complessiva limitata al90% senza indebolire immunità preesistenti.

Conferme di regola, test locali, app online reali e pubblicazione restano evidenze distinte. Le evoluzioni personali di Senka ancora in lavorazione non diventano automatizzate con la sola importazione del codice.
''',
    contentEn: r'''
Lusier III is a level13 GradeI Elite Solar Guard with all growth points assigned, Will first and Oculum second, one critical shield and150 Oculum shield. His sacred sword adds20 Solar Damage. Explosive cards have three editable forms at levels10/12/20, capacities5/10/15 and recovery1/2/3 each personal turn. Lusier retains his personal three-card recovery exception. Each card deals1d25 plus one fifth of current Damage, rounded down; at most five per attack. Cards sell only on the Black Market for an actual180–250 Obser payout. Confirmed deaths may deliver his actual customized deck; summons never farm it. Low-power observation becomes progressively easier at50/30/20/10 PT, while failed observations still do not reveal exact power. Confirmed rules, local tests and published behavior are separate claims.
''',
  ),
  ManualSection(
    titleIt: 'PT, costi generici e varianti personali — 27 ottobre 2026',
    titleEn:
        'Total Power, generic costs and personal variants — October 27, 2026',
    contentIt: r'''
PT indica la Potenza totale effettiva della scheda. Il parser riconosce @Danni+PT e formule frazionarie. PT non è consentita nelle passive. Usare tutto PT causa Sfinimento per almeno un turno personale, a qualsiasi livello e Grado; una quota causa la stessa probabilità: PT/2 50%, PT/4 25%. Le quote di tutti gli effetti della medesima attivazione si sommano fino al 100%, con un solo controllo. Durate maggiori già previste restano maggiori e uno Sfinimento in corso non viene accorciato.

I costi riconoscono Materia 1, 1 Materia e @mat-1 come quantità equivalente. L'editor permette scelta della risorsa con Minimo/Massimo generici oppure scrittura libera. Sono previsti Obser, HP, le risorse consumabili esistenti e gli oggetti dell'inventario; i sottotratti restano tiri. Un requisito Raccogli conserva il progresso dopo l'uso del materiale; Possiedi controlla l'inventario attuale; Consuma richiede una spesa reale, non ripetibile sulla stessa ricompensa. Uno sblocco di crescita raggiunto senza buff temporanei resta permanente. Testi non riconosciuti non autorizzano ricompense inventate.

Senka Kamaria, Mhunan lunare di livello1/Grado0, possiede la maschera come item indossabile, manifestazione del potere latente. È gratuita anche nella turnistica. Bonus mentre attiva: +6 RES, +5 VOL, +10 MAT, +5 OCU, +6 Danni, +3 Difesa; Vita aggiunta e cinque Oculum spendibili ricaricati a ogni attivazione. +10 Scudo soltanto alla prima attivazione del fight. Scudo Oculum normale20; su attacco che infligge Danni recupera min(6,1+max(0,livello nemico−livello Senka)), entro20, finché non spezzato. Riposo Breve/Lungo o riparazione del nucleo con Velo ripristinano lo spezzato. Riparazione solo sotto il massimo: recupero pari al tiro anche oltre20; se spezzato, tre quarti per eccesso. La maschera resta disattivata per un turno dopo un critico valido che la centra con capacità di colpire immateriali.

Mille Tagli infligge subito un unico danno pari a Danni attuali + totale del tiro Riflessi della Skill + PT; dà a Senka Sfinimento per un turno. Una volta per Riposo Lungo, costo Materia modificabile. Non è danno di tipo Sfinimento e non lo applica al bersaglio.

Il Clone d'ombra personale di Senka costa1–10 Materia e ha Vita=Materia spesa×2+livello; copia statistiche, sottotratti e Skill, senza creare altri cloni. Può usare il Mantello d’ombra copiato senza indossare la maschera; non eredita la protezione passiva di un oggetto che non possiede. Dura fino a fine fight o0 Vita. Alla nascita solo una Reazione veloce; nei suoi turni solo una Reazione normale e nessuna Azione. Limite totale per fight max(1,min(16,2×livello)), inclusi morti e assorbiti. Fusione a Velo permanente13 senza buff temporanei: un'Azione senza altre risorse assorbe tutti i propri cloni presenti. HP temporanei pari alla loro Vita attuale sommata; bonus VOL/MAT/OCU pari al decimo delle rispettive somme, per difetto; RES esclusa. Benefici fino a fine fight. Sono varianti personali: il Clone d'ombra precedente del manuale resta distinto.

Guardia Solare: Potenza13 a livello0, fragile e fastidiosa; élite56, equilibrata; Guardiano126, colosso lento e potente con due frecce d'oro e raggi. A queste basi si aggiungono i punti di livello e Grado previsti. Serafini Solari e Angelici sono nuovi miniboss distinti dal Serafino Boss precedente; sei ali, volti belli e inquietanti, occhi sulle ali. Angeli due ali, Arcangeli quattro nel canone di Oculum. La dicitura visibile è sempre Chaos.

Queste regole confermate non certificano che ogni automatismo sia già implementato e distribuito. Consultare il rapporto di verifica della versione.
''',
    contentEn: r'''
PT is the sheet's effective Total Power and is forbidden in passive abilities. Full use guarantees at least one personal turn of Exhaustion; fractions give the corresponding probability, summed across the same activation and capped at100%. Existing longer exhaustion is preserved. Costs support resource words and generic minimum/maximum fields. Gather, possess and consume are distinct requirements; permanent progression cannot be unlocked by temporary buffs. Senka's mask, clones, fusion and Thousand Cuts follow her confirmed personal variant, separate from the historical Shadow Clone. Solar Guard base powers at level0 are13/56/126; level and Grade growth is additional. Angels have two wings, Archangels four in Oculum, and Seraphs six. New Solar/Angelic miniboss Seraphs remain separate from the existing boss. Visible spelling is always Chaos. Rule confirmation is distinct from implemented and published automation.
''',
  ),
  ManualSection(
    titleIt: 'Fortuna magica, costi e creature del 27 ottobre 2026',
    titleEn: 'Magical Luck, costs and creatures of October 27, 2026',
    contentIt: r'''
La precedente Fortuna consumabile si chiama Fortuna magica. Ogni punto posseduto aggiunge sempre +1 a Fortuna; gli usi previsti continuano a consumare la riserva, senza cambiare il formato dei salvataggi. Ogni doppio critico positivo concede +1 Fortuna magica: 20 naturale e totale almeno doppio dell’avversario. Il premio riguarda il tiro effettivo una sola volta, anche su più bersagli o dopo un reinvio online e un caricamento JSON.

Il costo delle Skill riconosce Oculum, Resilienza, Materia, Obser, Volontà e oggetti specifici. Si può scrivere soltanto la risorsa nel campo Costo, oppure «Oggetto: nome preciso», e impostare separatamente Minimo e Massimo, senza la dicitura Oculum. I costi aggiuntivi e le personalizzazioni rimangono salvati. Per la Resilienza, la disponibilità considera prima la Vita già persa, convertita con il moltiplicatore Vita della scheda. Pagare riduce la Resilienza e il massimale di Vita; la Vita corrente resta invariata finché non supera il nuovo massimo. Con 20 Resilienza e 150/200 Vita: costo 2 → 18 Resilienza e 150/180; costo 6 → 14 Resilienza e 140/140.

Shadow Devil è un diavolo contaminato dall’Oblio dello Shadow Hell. Ucciderlo fa sentire la sua gratitudine: chi dà l’ultimo colpo riceve +3 Fortuna magica, gli altri partecipanti +1, una sola volta per uccisione. Questo premio non si applica agli altri mostri. Ogni fight concluso con nemici uccisi concede almeno 1 Ascension Dust ai partecipanti aventi diritto; restano gli eventuali premi maggiori contro nemici più forti e le regole già confermate per cristalli, equipaggiamenti, scroll e Occhi dei Caduti. La sola Vita a zero o un KO non confermano una morte.

Mostro di sabbia è un miniboss; Mezzo demone cosciente può essere aggressivo e ha il punto debole alla bocca dello stomaco. Oro e ossa marmoree caratterizzano le aberrazioni rapide e resistenti: la variante Solare è meno resistente e più aggressiva, l’Angelica è molto resistente e segue gli ordini del proprio angelo. Le immagini fornite rimangono riferimenti descrittivi. I valori iniziali di nuove tecniche, costi, livelli, durata e cooldown sono bilanciamenti modificabili, non ulteriori regole confermate.
''',
    contentEn: r'''
Consumable Luck is now Magical Luck. Each point held adds +1 to Luck. Each positive double critical grants one point, once per resolved roll including replay and JSON reload. Skill costs accept their resource or a named inventory item, with generic Minimum and Maximum fields. Resilience costs account for missing HP first, then reduce Resilience and maximum HP without subtracting current HP again: 150/200 becomes 150/180 when paying two, or 140/140 when paying six at ten HP per Resilience.

Only Shadow Devil grants three Magical Luck to its killer and one to other participants, once per kill. Completed fights with killed enemies grant at least one Ascension Dust to eligible participants; existing larger rewards and crystal, equipment, scroll and Fallen Eye rules remain. The Sand Beast is a miniboss. The conscious Half Demon may be aggressive and is weak at the pit of its stomach. Solar gold-and-marble-bone aberrations are more aggressive and less resilient; Angelic ones are very resilient and obey their own angel. Reference images are descriptive; initial balance values remain editable.
''',
  ),
  ManualSection(
    titleIt: 'Trasparenza e correzioni dei tiri del 26 ottobre 2026',
    titleEn: 'Transparency and roll fixes of October 26, 2026',
    contentIt: r'''
Le superfici trasparenti aumentano gradualmente di opacità fino alla piena visibilità in tre secondi quando il puntatore le evidenzia. Il tocco evidenzia il pannello per la stessa durata; le preferenze di accessibilità per ridurre le animazioni sono rispettate. Testi, icone e bersagli cliccabili restano visibili. Le due trasparenze di base rimangono regolabili separatamente da 0 a 40%.

Un tiro richiesto dal Master è completato soltanto dopo il lancio effettivo. Se mancano le risorse previste, la richiesta resta disponibile per riprovare. Una richiesta di Percezione del Master effettua direttamente il tiro richiesto. Le Azioni supplementari possono pagare i tiri; Sfinimento continua a bloccare le Reazioni, conservando le Azioni.

Chi è fuori fight può utilizzare le risorse già previste per le utilità consentite e per rientrare. Fuga e rientro sincronizzano la spesa con il Master senza ripeterla sui reinvii; iniziare un nuovo fight chiude le precedenti richieste di fuga. L'EXP della fuga resta personale, calcolata sulla Vita reale secondo la regola confermata, assegnata una sola volta e conservata nel JSON. Le formule dell'EXP ordinaria restano basate sul Grado di ciascun destinatario e su tutti i nemici sconfitti.
''',
    contentEn:
        r'''Transparent surfaces progressively become fully visible over three seconds on hover. Touch highlights the panel for the same duration; reduced motion is respected. Base panel and control transparency remain independently editable. Master roll requests complete only after a real roll, remain retryable when resources are unavailable, and requested Perception rolls directly. Extra actions pay for rolls; Exhaustion still permits actions. Fled participants retain the confirmed utility and return resources. Escape and return synchronize resource spending without duplicate consumption. Starting a new fight closes old escape requests. Escape experience uses actual HP loss and persists exactly once in JSON; normal encounter rewards still compare each defeated enemy against each recipient's Grade.''',
  ),
  ManualSection(
    titleIt: 'Aura e Potenza conosciuta',
    titleEn: 'Aura and known power',
    contentIt: r'''
## Aura, numeri scoperti e osservazione mirata

- Con Lettura dell’aura almeno +20 conosci la tua Potenza totale esatta e confronti automaticamente la tua forza con quella dei bersagli osservati, senza ricevere il loro numero se non lo hai ancora scoperto.
- Il valore esatto degli altri si scopre con una lettura mirata riuscita di Percezione o del migliore sottotratto di osservazione disponibile: Percezione, Investigazione, Furbizia, Valutazione o Lettura dell’aura. Bersaglio sotto 100 Potenza: soglia oltre 20; da 100 in su: oltre 40. Probabilità = 5% per ogni punto oltre la soglia, massimo 100%.
- L’ultima Potenza esatta scoperta resta in piccolo accanto al nome del PG e nella turnistica di nemici e compagni, anche dagli incontri precedenti. Con Aura +20 i numeri già scoperti si aggiornano automaticamente quando cambiano; sotto +20 rimane l’ultimo valore conosciuto fino a una nuova lettura. Le risposte vecchie non sovrascrivono scoperte più recenti.
- I rilevatori conservano la propria lettura stimata ±10% e la portata: la stima è indicata con ≈ e non sostituisce un precedente numero esatto. Il confronto qualitativo e una lettura fallita non eliminano numeri conosciuti.
- Un’osservazione mirata eseguibile ha probabilità pari al valore del sottotratto usato, massimo 95%, di non consumare Azione/Reazione. Esempi: +32 → 32%, +110 → 95%. Fuori combattimento non c’è costo di turnistica. Lo Sfinimento continua a bloccare le Reazioni.
- Le conoscenze sono memorizzate nella scheda e nel JSON per osservatore, campagna e identità del bersaglio. L’Aura usa confronti autenticati e aggiornamenti su variazione della Potenza; nessuna interrogazione continua. La snapshot pubblica contiene solo una revisione, mai le statistiche o la Potenza interna nascosta.
''',
    contentEn:
        r'''Aura Reading +20 reveals your own total power and automatically compares observed targets qualitatively. Previously discovered exact numbers remain beside character names and in initiative and refresh automatically with Aura +20. Exact first discovery requires a successful targeted observation: each point over 20 gives 5 percent when target power is below 100; the threshold is 40 otherwise, capped at 100 percent. Observation uses Perception or the best available reading subtrait. Each targeted observation has a chance equal to the used subtrait, capped at 95 percent, to preserve its action/reaction. Scanner estimates remain marked approximately and never replace exact knowledge. Saved knowledge persists; stale responses cannot roll it back.''',
  ),
  ManualSection(
    titleIt: 'Potenza totale, Sfinimento e connessione alla stanza',
    titleEn: 'Total power, exhaustion and room connection',
    contentIt: r'''
## Potenza totale nei mercanti e colpo potenziato — 26 ottobre 2026

Conferme esplicite: i mercanti considerano anche la Potenza totale per proporre oggetti adatti. Il valore usa Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. La selezione aggiunge la compatibilità con la potenza a livello, disponibilità e preferenze; prezzi e acquisti conservati non cambiano.

Scarica totale e Impeto totale aggiungono la propria Potenza totale ai Danni di un singolo attacco, una sola volta anche con raffiche e più bersagli. Il prossimo tiro per colpire e il primo tiro nemico per colpirti ricevono +max(2, 10 − Adattamento). Il bonus si consuma quando il singolo attacco viene dichiarato, anche se manca il bersaglio.

Sfinimento: azzera immediatamente tutte le Reazioni disponibili, normali, veloci, gratuite e supplementari; blocca ogni nuovo guadagno, anche da skill, critici, rimbalzi, mecha, Fuga o altre fonti. Durata = 1d3 turni personali + un turno ogni 160 Potenza totale per difetto. Non viene annullato da Stato di Forza. Le Azioni continuano a funzionare. Nuova attivazione sostituisce il colpo in attesa e non accorcia lo Sfinimento. Le Reazioni eliminate non vengono restituite alla scadenza; riprendono i normali nuovi recuperi.

Impostazioni iniziali scelte sulla delega al bilanciamento: costo 5 Oculum per Scarica, 5 Volontà per Impeto; CD tre turni. Nomi, descrizioni, costi, cooldown, formula del bonus, dadi e durata base sono modificabili tramite editor e JSON; le definizioni salvate non vengono sovrascritte.

Online: nessuna nuova connessione usa implicitamente la stanza «test». Il giocatore inserisce il codice del Master; un Master senza codice riceve un codice nuovo. Le stanze già salvate conservano il codice esplicito. Stanze private e approvazione del Master restano operative.

Distribuzione GitHub: Windows normale e Windows Test in ZIP e artifact di cartella separati. Le versioni precedenti restano conservate.
''',
    contentEn:
        r'''Merchants also use total power for suitable offers. Total Discharge (5 Oculum) and Total Impetus (5 Will), cooldown three turns, add total power to ONE attack's damage. Your next to-hit roll and the first enemy to-hit roll against you gain max(2, 10 - Adaptation). Exhaustion immediately clears ALL normal, fast, free and extra reactions and blocks every new reaction, including skills and other sources, for 1d3 + floor(total power/160) personal turns. Actions remain usable. Saved customization is preserved. New players must enter the Master's room code; a Master without a code gets a fresh one. Windows and Windows Test downloads remain separate.''',
  ),

  ManualSection(
    titleIt: 'Fuga, Role, creature del ciclo e Scudo del provocatore',
    titleEn: 'Escape, Role, cycle creatures and Provoker Shield',
    contentIt: r'''
Modifiche successive alla build `b917217d98d16861a5bbaf1706d78825d883c970`, run `40242640717`, incluse quelle del commit `12cbe566`. Il codice presente non certifica la pubblicazione: verifiche e pacchetti sono riportati separatamente nel resoconto finale.

## Creature e tecniche

Alle 24 specie delle dodici fasi, con 48 tecniche, si aggiungono 11 creature del ciclo e due Giganti, con 29 tecniche: 37 specie e 77 tecniche dopo la build di riferimento. Restano forme I/II/III, costi, requisiti, cooldown, anatomia, punti deboli, materiali, scroll e Open. Fase, luogo e ricerca sono combinabili. Le soglie personalizzate delle scroll restano rispettate; naturale 18/19 assegna una tecnica e 20 entrambe per le specie con due tecniche, senza duplicati. L'Ultimo Ciclo conserva le due specie precedenti.

- Riccio dei Sentieri Quieti: pacifico, tre tecniche di utilità/protezione. Cinghiale del Fango: Fango, Terra e Roccia in questo ordine. Uomo Cactus: escrescenze carnose spinose che conservano liquidi, perdita del senno e caccia ai corpi per reidratarsi.
- La Follia: +1 Follia sul critico riuscito; una Reazione veloce extra al proprio turno se è vivo un alleato dell'Illness. Gigante Goblin: −5 ai tiri d'attacco; una Reazione normale al primo turno personale degli altri Goblin, una volta per scontro.
- Forest Demon Blu dalle Corna Rosa: Nuvola/Sogno. Nube con −3 Movimento fino a fine fight, senza sovrapposizioni; probabilità di impedire la difesa 5% per ogni suo critico nello scontro, massimo 100%. Scudi critici proteggono dai debuff critici.
- Solare della Siccità: infligge e riceve +50% Danni contro Lunari, ali danneggiabili separatamente. Identità Solare/Lunare distinta da Fato/Chaos; Mhunan Lunari di base, altre razze senza appartenenza fino alla scelta.
- Lupo Lunare: Pedata Manifestazione del Potere contro Resistenza, −6 a tutti i tiri per un turno a chi perde, CD iniziale 4. Morso Lunare/Ombra secondo la maggiore efficacia sul bersaglio, casuale a parità.
- Marmocchi del Fato: durante The Fate, ai membri Fato +1 alle quattro statistiche nel 75% dei casi, +2 nel 25%. Tre donatori distinti al massimo, nessun dono ripetuto dallo stesso: totale +3…+6. Uscire dalla fase azzera doni e conteggio; compreso Oculum.
- Melma di The Null: oblio narrativo dell'identità, schede e progressi conservati. Orso dagli Aculei Ghiacciati: 1d8+2 colpi; ogni precedente colpo riuscito sul medesimo bersaglio dà +5% Danni, su un altro +10%. Critico: Gelo un turno, stadio crescente con applicazioni ripetute.
- Gigante comune: fino a tre bersagli; danno base ripartito, poi +15 +5×livello a ciascuno. Gigante Scheletro: Vita Afona per 1d3 turni con naturale 19–20 riuscito. Telecinesi: metri = attacco−difesa−2 su naturale 1–17, attacco−difesa su 18–20. Ripresa gratuita: superare l'attacco su 1–17, DT 13+metri su 18, DT 16+metri su 19. Su 20 si spende Azione/Reazione e serve almeno il doppio dell'attacco, senza successo automatico del naturale 20. Ripresa riuscita: solo Danno base. Altrimenti +2 Danni per metro, bonus Schianto dal 19, normali effetti critici al 20.

## Fuga, rientro e Role

Utility Fuga: 1d20 + Movimento + max(Riflessi, Velo). Costa Azione nel proprio turno, Reazione fuori turno. Chi nota blocca con 1d20 + Movimento + Riflessi. Parità: Movimento maggiore; se pari, Fuga riuscita. Con Velo, visibilità = naturale + Velo contro Percezione passiva senza +10; l'ultimo attaccante ha +3 per notare salvo sia stato attaccato successivamente. Visibilità correggibile dal Master.

L'ultimo aggressore che ha tolto Vita ha un tentativo gratuito di colpire oppure bloccare solo se nota. Il colpo non ferma la Fuga salvo critico riuscito o Precisione con totale almeno quattro quinti del tiro di Fuga. Gli aiutanti spendono Azione/Reazione: +3 se nell'ultimo colpo, +2 altrimenti. Dal lato di chi fugge, il compagno con il più alto precedente Aiuto ha un tentativo gratuito.

Gli attacchi d’intercettazione contro chi fugge usano1d16 per colpire, anziché1d20. I modificatori e le condizioni per fermare la fuga non cambiano. Il tiro di blocco resta1d20 + Movimento + Riflessi; gli attacchi ordinari non cambiano dado.

Fuori fight: non attaccabile, ma conserva il turno; una Azione e due Reazioni, con singola estrazione al 50% che converte una in veloce. Fuga critica: tre Reazioni veloci al primo turno fuori fight. Solo cure, riparazioni e utilità su di sé oppure rientro, che costa una Azione. Rientro con Velo: +3 al prossimo tiro per colpire e +Velo ai Danni contro ciascun bersaglio con Percezione passiva non superiore al Velo; possono aiutare solo coloro che percepiscono chi rientra. I membri Fato dello stesso party si percepiscono sempre. Rientro con Riflessi: visibile, una Reazione veloce ora e nel successivo turno. Reinvii senza duplicazione dei benefici.

Tutto il party vivo fuggito conclude il fight. EXP personale = max(Vita reale persa personalmente, Vita reale tolta ai nemici ÷ membri per difetto − propria statistica Danni). Scudi esclusi; ricevute duplicate non ricontano Vita. Nessun nuovo bonus prima sconfitta o Chained Fate su questa ricompensa.

Ogni scontro ha una cartella apribile Role, rinominabile dal Master: accoglie chi fugge e il party rimasto a fine fight. Master la vede anche vuota, altri solo se contiene qualcuno. Pressione prolungata sul partecipante: il Master lo sposta in Role. Nome e appartenenze persistono nella turnistica; iniziare un nuovo fight ripristina la partecipazione.

## Scudo del provocatore

Nuova skill di Difesa con forme I/II/III, livelli iniziali 0/3/6. Costo 5/10/20 Oculum, durata tre turni, CD tre turni. Probabilità di attirare attacchi 60%/75%/90%; Scudo 30/40/60×livello. Difesa iniziale scelta su delega dell'utente: +5/+10/+15. Riserva separata dagli Scudi esistenti, nuova attivazione sostituisce la precedente, scadenza elimina il residuo.

Solo il colpo che rompe la barriera riflette il 50%/75%/100% dei danni da essa assorbiti in quel colpo più il 50%/75%/100% della propria statistica Danni, totale per difetto. Valgono le normali Difesa e protezioni dell'attaccante; reinvio senza doppio danno. Fra più barriere attive la selezione usa la probabilità maggiore; contrattacchi e intercettazioni con bersaglio obbligato mantengono il bersaglio.

## Interfaccia, editor e compatibilità

Statistiche e pulsanti inferiori: trasparenza indipendente 0–40%, consigliata 24%; GUI generale 34%. Controlli affiancati su desktop e impilati sul telefono; testi/icone pieni, hover sul controllo. Valori personalizzati conservati; precedenti valori di default aggiornati una sola volta.

Modificabili: nomi, descrizioni, statistiche, anatomia, punti deboli, resistenze, materiali/drop, skill/Open, forme, costi, risorse, livelli, bersagli, quantità, durata, cooldown, formule, dadi e percentuali della nuova skill. Persistono identità, trasparenza e nome Role. Nuove definizioni senza sovrascrivere personalizzazioni JSON. Nessun nuovo tipo generale di parser: effetti strutturati esistenti con nuovi bersagli specifici; condizione dedicata Pressione del Lupo Lunare.

Download automatici dal commit realmente compilato, versioni precedenti conservate, verifiche anonime degli archivi separate da suite locale, Supabase e prova con app indipendenti. L'istruzione corrente richiede anche EXE con runtime, ZIP e APK, Windows e Windows Test in cartelle normali.

## Slime Roccioso e bilanciamento

Conferme dell’utente: la voce Monster Book e il relativo pool comprendono Palla di roccia slime, Rimbalzo, Indurimento e Apertura Masso Slime. I cuccioli attaccano tutto, gli adulti sono neutrali buoni; Gradi Senza Grado/I/II. Il drop raro Indurimento è identico alla tecnica del mostro.

- Palla I: Oculum immesso +15 Danni, costo 1–4, livello 0. II: Danni pari all’Oculum immesso oppure blocco con Vita Oculum immesso ×3 e Reazione contro il bersaglio, costo 5–10, livello 5. III: blocco ×10, costo 11–20, livello 13. Cooldown iniziali scelti per bilanciamento: 2/3/4.
- Rimbalzo I/II: una Reazione e +25%/+50% Danni per la prossima azione, costo 1–3/4–6, livello 1/6. III: un solo tiro 1d3 determina rimbalzi, Reazioni e +50% Danni ciascuno per il turno, costo 7–10, livello 12. Cooldown iniziali 2/3/5.
- Indurimento I: Scudo 10 + Oculum immesso, Difesa 5 + Oculum immesso; costo 1–2, livello 0. II: Scudo 25 + Oculum immesso ×1,5, Difesa 6 + Oculum immesso ×1,5; costo 3–4, livello 3. III: Scudo 1d250 +50 + Oculum immesso ×3, Difesa 15 + Oculum immesso ×3; costo 5–10, livello 10. Difesa sei turni, Scudo fino a esaurimento, cooldown iniziali 3/4/6.
- Masso Slime, livello 15: colpo iniziale Oculum ×5, separato da Schiaccio. Buff Open +5 a tutte le statistiche e +9 ai tiri. Ultima scelta esplicita dell’utente: Schiaccio ×3 totale, riutilizzabile con CD 3; sostituisce la precedente conferma ×4. L’amplificazione Open è già inclusa nel ×3.
- Drop: Roccia Slime 250 g; Indurimento dal totale 15; Rimbalzo sul naturale 20.

Audit del catalogo: 1.157 voci, 8.352 forme, 4.611 forme distinte. Quindici forme attive a pagamento che danno cure, Scudo o Reazioni avevano CD zero: ai soli nuovi modelli sono assegnati CD 3/4/5 per forma. Cooldown espliciti e passivi prevalgono; nessuna riscrittura delle skill salvate. L’audit verifica economia e definizioni, non dimostra da solo il bilanciamento di ogni combattimento.

## Nuvola, Golem e stanze inattive

Vita della Nuvola attira i mostri: gli attacchi dei mostri danno priorità alle forme nuvola nemiche disponibili. Il pugno del Golem di Roccia Nuvola sceglie fra Nuvola, Roccia e Fulmine in base alla resistenza del bersaglio; parità casuale. La barriera colpita nello Scudo effettua un tiro automatico gratuito di Manifestazione +5; un critico riuscito colpisce anche gli altri nemici e stordisce per un’Azione. Le scariche non innescano altre scariche; ricevute duplicate non ripetono gli effetti.

Inattività: 30 minuti senza input di alcun partecipante, poi avviso al Master di 60 secondi con «Resta online». Mouse, tocco, scorrimento e tastiera di chiunque annullano la chiusura; presenza di rete automatica non conta come attività. La stanza inattiva disconnette le sessioni senza eliminare schede o salvataggi. Gli input sono aggregati alla presenza periodica, senza un messaggio per ogni movimento del mouse.

## Potere totale e rilevatori

Conferme dell’utente: Potere totale = Resilienza + Volontà + Materia + Oculum + Livello + Grado ×3. Da Lettura dell’aura +20 la tua Potenza esatta e i numeri già scoperti si aggiornano automaticamente; gli altri rimangono un confronto qualitativo fino alla scoperta. Una lettura mirata riuscita di Percezione o del migliore sottotratto di osservazione ha probabilità 5% per ogni punto oltre 20 se il bersaglio ha Potenza inferiore a 100, oppure oltre 40 da 100 in su; massimo 100%. La lettura del numero è distinta da livello, probabilità e punto debole.

I rilevatori funzionano anche sugli altri personaggi. Gli alchimisti vendono amuleti, bracciali e cavigliere in legno magico con cristalli che riflettono il cielo anche senza vederlo. A Postea sono gadget cyberpunk. Portata = 50 + livello oggetto ×30. La lettura è una stima entro ±10%; oltre portata mostra solo «oltre la portata» senza il valore reale. Il destinatario online calcola il risultato senza trasmettere le proprie statistiche.

- Alchimisti: 1d9 +6 utilizzi (7–15), tirati una sola volta all’acquisto.
- Postea: ultima correzione confermata 1d23 +12 utilizzi (13–35), prezzo sei volte tanto allo stesso livello.
- Prezzo iniziale scelto su delega: 30 +15 × livello in Obser; Postea sei volte questa cifra.
- Uso: selezione del bersaglio dall’inventario; una normale Azione/Reazione in combattimento. Una carica per scansione, anche oltre la portata; annullare la selezione non consuma. Riaprire negozio o JSON non ritira gli utilizzi.
- Nome, note, livello e utilizzi residui sono modificabili nell’editor oggetto e conservati nel JSON. Portata ricalcolata dal livello modificato, quantità degli acquisti separate. Costi/offerte restano modificabili dal mercante.
''',
    contentEn: r'''
The update adds 13 more creatures to the earlier 24, including two Giants, with 29 additional techniques. All forms, costs, cooldowns and structured effects remain editable and persist in JSON. Solar/Lunar identity is separate from Fate/Chaos. Escape uses movement plus the greater of Reflexes and Veil; ties compare movement, with remaining ties favoring escape. An escaped participant keeps self-care turns and moves to the encounter's renameable Role folder. Returning costs an action, with stealth or reflex benefits. A full-party escape awards experience from actual enemy HP damage minus personal Damage, with a floor equal to personal HP lost. Provoker Shield has three forms costing 5/10/20 Oculum, three-turn duration and cooldown, 60/75/90 percent taunt, +5/+10/+15 Defense and 30/40/60 times level shield points. On break, it reflects 50/75/100 percent of that hit's absorbed damage plus the same percentage of personal Damage. Saved customized definitions remain unchanged. Statistics and lower controls have independent transparency, with recommended values of 24 percent and 34 percent for the general GUI. Saved customized values are preserved.
''',
  ),
  ManualSection(
    titleIt: 'Creature delle dodici fasi del ciclo',
    titleEn: 'Creatures of the twelve cycle phases',
    contentIt: r'''
Il Monster Book include due specie per ciascuna delle dodici fasi del ciclo: 24 creature, 48 tecniche con forme I/II/III, materiali e Open propri. Nel selettore puoi combinare fase, luogo e nome; il dossier mostra l’affinità della creatura. Il Master può usarla anche fuori dalla fase: l’affinità non cambia le regole del calendario.
Safe Monster: Lepre del Guscio Quieto e Cervo delle Radure Miti, pacifici con ripari e cure.
Illness: Falena del Delirio e Scrutatore delle Febbri, pulviscolo e impulsi psichici.
Little Breath: Rondine del Respiro Lieve e Custode dei Nastri Sospesi, cure, mobilità e protezioni.
Piogge Fertilizzanti: Porcello del Fango Grasso e Rospo delle Gronde Marce, fango e secrezioni.
The Sun: Scarabeo del Sigillo Ardente e Araldo delle Sei Albe, ostili e legati al Sole.
Mezzo Ciclo: Airone del Guado Quieto e Tartaruga della Pioggia Chiara, abitanti delle acque tornate miti.
The Moon: Cerbiatto dei Voti Lunari e Gufo delle Stelle Alleate, reliquie della Luna scomparsa e protezione degli ospiti.
The Fate: Ragno dei Fili Giurati e Cavaliere del Filo d’Oro, nodi magici e guardie guidate dai fili.
Caldo Infernale: Scorpione delle Cisterne Secche e Mantide della Vampa, predatori di luoghi aridi.
The Null: Larva del Nome Vuoto e Viandante dei Ricordi Spenti, Vuoto e Oblio.
Ghiaccio Imponente: Lepre del Fiato di Vetro e Golem della Brina Profonda, schegge e ripari di ghiaccio.
Ultimo Ciclo: Volpe delle Lanterne Spente e Guardiano dei Dodici Rintocchi, raccolta delle lanterne e protezione dei cortei.
Valori iniziali modificabili: tecniche 1/2/3 Oculum, requisiti al livello base della creatura e poi +3/+6, recupero 2/2/3 turni personali oppure 3/3/4 per le cure. Drop naturale 18/19: una delle due scroll; naturale 20: entrambe, con normale apprendimento. La soglia delle scroll è modificabile nei dati della creatura; i materiali mantengono la propria probabilità e le normali regole Drop. Buff e Skill Open sono separati; il Buff aumenta realmente la Skill. Statistiche, nomi, descrizioni, anatomia, resistenze, materiali, costi, livelli, durata e cooldown restano negli editor e nel JSON. Le voci personalizzate già salvate non vengono riscritte.
''',
    contentEn: r'''
The Monster Book includes two distinct species for each of the twelve cycle phases: 24 creatures and 48 three-form techniques, with their own materials and Opens. Search combines phase, habitat and name. Phase affinity appears in the dossier and does not impose a spawn restriction or alter calendar rules.
Safe Monster creatures are peaceful and have protective or healing powers. The Moon creatures commemorate the absent Moon and allied Stars; there is no Moon in the current sky. Null powers do not erase a character’s saved identity. Initial editable costs are 1/2/3 Oculum; later forms require base level +3/+6. Cooldowns are 2/2/3 personal turns, or 3/3/4 for healing. Open Buff and Skill remain separate and linked. Saved customizations retain precedence.
''',
  ),
  ManualSection(
    titleIt: 'Precisione, catalogo NPC e creazione — 25 ottobre 2026',
    titleEn: 'Precision, NPC catalogue and crafting — October 25, 2026',
    contentIt: r'''
Precisione sceglie prima la parte del corpo e poi il singolo arto, solo se esistono più parti dello stesso tipo: Braccia → Destra 1, Sinistra 1, Destra 2, Sinistra 2. L'anatomia deriva dalla descrizione fisica, non dalle appendici evocate da una skill; conserva quantità diverse di braccia, ali, code, teste e zampe. I punti deboli già definiti nel Monster Book prevalgono sulle deduzioni. Colpire un punto debole lo rivela. Il Master può usare Punto debole scoperto per rivelarlo per tutti gli esemplari della stessa voce, senza sbloccare le varianti.
Punti delle Art del personaggio: Oculum occhi; Martial piccola sfera nei legamenti, Precisione −2; Emblem posizione scelta dell'emblema; Illness testa; Rune basso ventre; Defiled nessuno. Un colpo riuscito al punto dell'Art applica −3 ai tiri della sola Art per una Azione. I mostri usano esclusivamente i punti del proprio Monster Book. Il riepilogo resta sotto i log.
I disegni confermati completano l’anatomia del catalogo: Mosca Campana ha sei zampe e quattro ali, Topino due braccia e due gambe, Pawn due mani sospese senza arti aggiunti, Bramble quattro tentacoli locomotori. Il simbolo oculare sull’elmo chiuso dei Solari è una visiera metallica, non un occhio biologico esposto. I cristalli lunari restano parti separate con le proprie regole. Il Gigante di sabbia non possiede un nucleo anatomico da mirare. Integrità e lesioni seguono il materiale: sabbia disgregata, fibre lacerate o meccanismi danneggiati, senza attribuire fratture ossee a ogni creatura. Anatomie e valori personalizzati dal Master continuano a prevalere.
Un critico mirato che danneggia la Vita di un'ala la danneggia: prima ala dimezza i bonus del volo, due ali diverse impediscono di volare e causano 1d60 − bonus Riflessi della creatura che cade, minimo zero, poi le normali protezioni. Le ali si recuperano al Riposo Lungo o con intervento del Master. Colpire nuovamente la stessa ala non conta come una seconda ala.
Un critico mirato agli arti con perdita di Vita applica Frattura a un nuovo arto, massimo tre arti distinti. Il malus ai tiri che usano gli arti fratturati è −1/−2/−3; nessun effetto sui tiri non pertinenti. Sullo stesso arto non si applica una nuova Frattura. Una volta raggiunte tre Fratture, ogni successivo critico che toglie Vita aumenta il malus di un punto e sorteggia al 50% Danni oppure Difesa, riducendo quel valore del malus totale; il malus precedente sull'altro valore rimane. Esempio: quarto critico −4 Danni, quinto −5 Difesa: restano entrambi e i tiri pertinenti hanno −5. Ogni tiro sostituisce solo il valore già presente dello stesso tipo. Serve la cura appropriata della condizione, non un reset della battaglia.
Scudi critici: mentre proteggono il colpo impediscono Fratture e gli altri debuff che richiedono un critico, anche se quel colpo spezza l’ultima carica. Non bloccano gli effetti ordinari della tecnica. Gli editor degli effetti consentono Solo su colpo critico, salvato nel JSON.
Zombie dello Sbocco Acido: getto e presa corrosivi, corpo irrigidito, Open Gola corrosiva, sacca acida come punto debole; abilità Materia/Volontà e cooldown. Cavaliere del Non Ritorno: difficile, armatura nera opaca spinata, vortice nel petto che termina in un occhio viola, spadone, tre Scudi critici e due Schivate Oculum iniziali. Fendente, guardia, passo difensivo e Open dedicata. Materiali, scroll e ricette restano separati e modificabili.
Fate Golem adulto: scegliere Nucleo con fata rimanda il danno all'attaccante senza tiro contrapposto, consumando comunque l'Azione o Reazione usata. Si applicano le normali protezioni dell'attaccante. Il Mini Fate Golem conserva la propria regola distinta.

Creazione rapida NPC: scelta dell'elemento, proposta di una skill Attacco, una Supporto e una Difesa senza nomi ripetuti. Puoi sostituirle nel catalogo grande con ricerca e filtri. Le forme rispettano il livello; il catalogo ordina le singole skill per livello richiesto, non per livello di maestria. Mostra la forma utilizzabile e la prossima: Nome I · prossima II, lvl 6. Dopo 0,9 secondi di hover o una pressione prolungata mostra evoluzioni, livelli, costi, effetti e cooldown. I costi passano attraverso il pagamento strutturato e restano risorse consumate realmente, non semplici descrizioni.
Creazione e forgiatura di tutti gli indossabili: una sola estrazione per oggetto, conservata nel JSON, chance 10% + Fortuna, massimo 90%; Rebirth massimo 100%. Il bonus usa il livello dell'oggetto: +livello Danni se offensivo, +livello Difesa se difensivo, entrambi se ibrido. Ogni forgiatura riuscita aumenta il livello di uno. Ripetere la lettura del salvataggio non ripete l'estrazione. Aggiunte 19 ricette da drop delle nuove creature e tre abiti di seta magica; questi ultimi applicano resistenze reali solo mentre equipaggiati, modificabili nell'editor.
Scroll Rebirth: contributo Fortuna ×1,5 arrotondato per eccesso; restano i tetti 75% sotto Grado IX e 90% da Grado IX. Affinità elementale +15 punti comprende le armi equipaggiate.

Aspetto: trasparenza delle superfici regolabile 0–40%, valore consigliato 18%, con ripristino. Testi, icone e bersagli restano pieni e cliccabili. Hover/focus ripristinano le superfici; nel gruppo Tiri e azioni si evidenziano tutti i tasti entrando nel pannello, poi soltanto quello sotto il mouse. I colori dei temi seguono elemento e ambiente, mantenendo distinguibili le risorse. Sul telefono le quattro azioni principali sono in due colonne; gli altri tiri sono nella sezione espandibile. Il tema riguarda lo sfondo dell'intera pagina, non solo il simbolo decorativo.
''',
    contentEn: r'''
Precision chooses a body group and then a side/number only when multiple matching parts exist. Physical descriptions determine anatomy; established Monster Book weaknesses take precedence. Master reveals target the exact catalogue entry, never its variants. Character Art weak points follow their Art type; Martial targeting has −2 Precision, and an Art-core hit gives −3 only to that Art for one Action.
Critical HP damage to a wing halves flight bonuses; two different injured wings ground the creature and deal max(0, 1d60 − its Reflexes bonus) before normal protections. Long Rest or a Master intervention restores wings. Limb fractures are limited to three distinct limbs, imposing −1/−2/−3 on relevant rolls. Further HP-damaging critical hits increase that penalty and randomly apply the total to Damage or Defense; previous penalties on the other value remain. Adult Fate Golem fairy-core attacks reflect automatically, still spending their Action or Reaction.
Quick NPC creation selects an element and three distinct attack/support/defense skills, editable through the large filtered catalogue. Skill cards sort by learning level, display the next evolution, and preview forms after 0.9 seconds. Structured costs consume real resources.
Crafted wearables have one persistent 10% + Luck bonus roll, capped at 90%, or 100% for Rebirth. Bonuses use item level and offensive/defensive role. Each successful forging adds one item level. Nineteen creature-material recipes and three magic-silk garments are included. Rebirth scroll Luck is multiplied by 1.5 and rounded up; learning caps remain 75%/90% by character Grade.
Surface transparency is adjustable from 0 to 40%, with a recommended 18%. Text, icons and input remain visible. Hover/focus highlights controls; phone actions use a two-column layout and expandable secondary rolls. Full-page backgrounds and distinct palettes follow the selected theme.
''',
  ),
  ManualSection(
    titleIt: 'Nuove creature e apprendimento — 25 ottobre 2026',
    titleEn: 'New creatures and learning — October 25, 2026',
    contentIt: r'''
Le skill elencate sotto una creatura appartengono anche alla creatura. Le condizioni di uccisione indicano come ottenerne le scroll, non come abilitarle sul mostro. Le forme I/II/III rispettano il livello del singolo utilizzatore e conservano costo, risorse, bersagli, effetti e cooldown modificabili nel JSON. Le forme in cooldown non compaiono nei pannelli rapidi Attacco, Difesa e Utility; restano consultabili negli editor. Le scroll apprese conservano i costi e gli effetti della tecnica originale. Armi, armature e scudi possono contenere le stesse tecniche, con l’estetica del loro habitat.

Apprendimento: serve 20 naturale e totale almeno 30 + 10×Grado scroll + 2×max(0, livello richiesto dalla skill − tuo livello). La percentuale base resta 20/15/10/5% per difficoltà Facile/Normale/Difficile/Oculum; si aggiunge un punto percentuale per punto di Fortuna, +15 punti se l’elemento è già utilizzabile dalla scheda, comprese Art e armi equipaggiate, e l’eventuale +1–3 in fight. Limite finale 75% sotto il Grado IX del PERSONAGGIO, 90% dal IX. L’elemento e i bonus non garantiscono il tiro richiesto. Prima del consumo si mostra la percentuale effettiva: rosso fino a 20, arancione 21–40, giallo 41–55, giallo-verde 56–74, verde acceso da 75. Il livello richiesto è salvato nelle nuove pergamene; le vecchie prive di tale dato mantengono il requisito precedente.

Bramble: cuore debole, vulnerabile al Fuoco. Scudo di rovi I/II/III iniziale 12/18/24, ritorsione ravvicinata 2/4/6, costo 2/3/4 Oculum e CD 3; dura tre turni o fino a consumo. Non protegge da Fuoco, Lava o Plasma. Naturale 20 Drop dà la scroll dello Scudo; finisher Acqua e naturale 10–19 dà Sfida Ardua. La passiva concede +1 Oculum e +1 Resilienza temporanei per critico contro Resistenza, fino a fine fight; contro Fragilità concede Ricordo Vitale per sei turni.
ThunderBird: testa debole, Volo Elettrico Riflessi +5. Tre uccisioni danno TP elettrico; finisher Fulmine con naturale 15–19 dà Artiglio di Fulmine, con piccole scosse soltanto ai compagni del bersaglio.
Scostubanditi: non letali, lasciano a una Vita e sottraggono il 75% degli Obser personali; disarmati fanno metà Danni. GranScostumato può uccidere, ha colpi di Schianto e cannone. Il cannone premio dà priorità a uno Scudo critico; altrimenti rimuove fino a 150 Scudi, incluso Scudo Oculum, poi infligge il suo colpo con +50% Danni agli Scudi. Le tecniche premio richiedono le condizioni registrate nel Monster Book.
Varianti Empatiche: 10% iniziale alla creazione delle due specie, +6 Empatia, nome completo solo nella scheda. Entrambe sono non letali e sottraggono il 50% degli Obser personali. Ucciderle SOTTRAE all’uccisore 10 + 3×livello del mostro Obser, una volta e fino a zero; non tocca la cassa comune. L’uccisore riceve fino al Riposo Lungo un marchio: Scostubanditi e GranScostumati vedono il teschio, lo considerano prioritario e gli infliggono +25% Danni. Gli Empatici restano non letali.

Fuocherelli: Acqua blocca le tecniche Fuoco per una sua Azione. Dieci uccisioni danno Dardo di fuoco, costo 2 Oculum, critico Fuoco per 1d4 turni. Seconda Vita: una volta per Riposo Lungo, alla morte non da Acqua esplode entro tre metri contro entrambi gli schieramenti per 10+2×livello Danni Fuoco; torna con 5% Vita massima, minimo 20 e non oltre il massimo. Scudo I 1d120, II 1d200+livello, III 1d250+3×livello. Naturale 20 dà la scroll Open; finisher Acqua senza rinascita dà Rianimazione. Quest’ultima cede Vita reale a un compagno prima del suo primo turno dopo la morte; puoi cederla tutta, ma oltre il 75% viene richiesta conferma con perdita e residuo.
Feralis è Mini Boss: normale resistenza al primo elemento ricevuto diverso dai propri; separatamente Resistenza elementale guadagna +15 per colpo per Fuoco/Acqua/Gelo/Terra/Vento/Fulmine, fino a 150%, azzerata a fine fight. A 100 è immune, oltre cura il residuo fino al 50%. Furia Primordiale a metà Vita: Danni doppi, danni ricevuti dimezzati, recupero di un quarto dell’Oculum massimo una sola volta; dal secondo turno paga 3 Oculum e ottiene altri +5 Danni/+2 Difesa. Puoi terminarla; finisce se non paghi. Feralis Ancestrale è una variante distinta, di livello iniziale 10, con placche scure, artigli e ruggito propri. Cinque uccisioni danno la passiva che recupera metà Vita e Oculum correnti dopo una propria uccisione, entro i massimi.
Sempre Verde: maschera debole. Foglie Lama, Drop totale almeno 36: I 1–4 / II 5–10 / III 11–40 Oculum; (1d20 + Oculum speso) foglie da due Danni in un unico pacchetto. Cinque uccisioni danno Schivata rapida, Vantaggio alto a Difesa Riflessi, 1 Oculum/CD 2. Finisher soltanto Anima conserva il costume: 50% per mostro/turno di non sceglierti finché non attacchi un mostro.
Lavastrello: ali deboli, Attacco di Fuoco 1 Oculum e Manifestazione del Potere aggiunta ai Danni; critico brucia per un turno. La tana è una roccia lavica aperta, inizialmente 30+5×livello Vita, modificabile; genera un esemplare per giro fino a cinque totali, poi basta. Distruggerla prima della quinta uscita dà Intuito lavastrellesco. Percepire l’area con totale >15 la scopre; quando nota compare Cerca tana con Vantaggio, più il +3 dell’Intuito. Venti uccisioni dimezzano i Danni ricevuti dalla specie e varianti.

Teschio Monaco: due Schivate Oculum. Ki Mortale è verde sopra la barra Oculum: quantità pari all’Oculum ATTUALE diviso 6; un critico all’attivazione migliora ogni volta il divisore di uno fino a 3. Il Ki resta fino a spesa e può sostituire Oculum nei costi. Ogni Reazione veloce extra costa 5 Ki; l’attivazione gratuita concede una sola Azione extra, CD 2 sessioni. Meno di 5 Ki diventa invece bonus alle quattro statistiche per una Azione. Le ricompense speciali sono scroll, incluso il potenziamento da caccia che dà +5/+10 Ki alle attivazioni secondo 1d10.
Teschio Quattro Lame: Quattro Slash sono quattro difese separate; rompere tutte le braccia prima di ucciderlo dà Spada Osso, +2 Volontà/+1 Resilienza equipaggiata e spuntoni su massimo quattro bersagli con −4 ai tiri per un turno. Regen per kill: +1 Oculum/+5 Vita alla propria uccisione e +2 Vita agli assist registrati, senza duplicare il nemico.
Ogor: nucleo viola; corazza dimezza i colpi tranne Precisione al nucleo individuato. Tre colpi riusciti lo rompono e bloccano il Raggio. Il Raggio Open somma ai Danni normali 1d90+50 nella I; costo e forme superiori modificabili. Nucleo di Oculum intatto, equipaggiato: +1 Oculum dopo un tiro riuscito, cinque recuperi per Riposo Breve o Lungo; tre colpi al punto debole del portatore lo rompono. Ripristina energia rimuove il blocco del flusso e recupera 3 Oculum, una volta per Riposo Lungo.
Teirak Mini Boss: rune, magie proprie; al 60% Vita o meno Ricordo Vitale sei turni, una volta per fight. Un critico applica Vita Afona per tre turni: «Le rune velano la tua Vitalità: non riesci a percepirla».
Laer: +15 Riflessi; Spada = 1d20 + metà Volontà per difetto +10, totale aggiunto ai Danni. Il +10 è della sua maestria e non si copia come bonus dell’arma. Torretta Oculum: nucleo del colore dell’elemento, +9 al tiro per colpire e −9 CM. Manichino della Spada: Tagli rapidi, Difesa aumentata e Spada al 100%, tre turni con +20% Danni/Difesa, +3 alle quattro statistiche e +4 Riflessi, senza aumentare automaticamente Vita corrente.
DeadlySins Boss: 13 Oculum anche al livello 0. Colpo potenziato iniziale I +Forza, II/III +2×Forza sui colpi base, costo 9/13/16, durata 3 turni/CD condiviso 9. Regen usa una tua Azione e Resistenza, CD 4, senza costo statistico: recupera metà Vita persa nell’ultimo attacco, tutta con critico positivo o negativo, una volta per quell’attacco. Arma trasformabile: Spada corta +6 colpire/+3 Difesa; Katana +1 Danno per attacco eseguito, un terzo del guadagno permanente per difetto a fine sessione; Spadone onda d’urto contro massimo dieci vicini. Dopo nove Riposi Lunghi di uso effettivo si adatta e ottiene +3 Danni.

Monster Book: contatori party per campagna, variante separata e totale specie; mostri uccisi effettivamente registrati, senza duplicati per lo stesso corpo. La fine del fight conserva party e NPC alleati e distribuisce il bottino dei nemici uccisi.
Animazioni: la variante Viva aggiunge una lieve atmosfera al lato della scena; braci, neve e foschia dipendono dal tema. Nessuna deformazione dell’illustrazione o spostamento dei controlli. Rispetta movimento ridotto/disattivato e sospensione dell’app.
''',
    contentEn: r'''
Monster techniques belong to their creature; kill requirements govern scroll rewards. Forms use the acting creature's own level. Costs, resources, targets, durations, cooldowns, effects and item abilities remain editable in the existing JSON editors. Cooling abilities are hidden from Attack, Defense and Utility shortcuts.
Scroll learning requires natural 20 and total at least 30 + 10×scroll Grade + 2×max(0, required skill level − character level). Add one percentage point per Luck, 15 for an element already usable through abilities or equipped weapons, and the existing 1–3 combat bonus. Cap the final probability at 75% below character Grade IX and 90% from IX. The confirmation shows the exact coloured probability before consumption.
Empathic Scostubandit and GranScostumato variants use nonlethal attacks, +6 Empathy and steal 50% of personal Obser. Initiative conceals the variant. Killing one deducts 10 + 3×monster level personal Obser once, never below zero; the party chest is excluded. Until Long Rest, bandits recognise the killer's skull mark, prioritise that target and deal 25% more damage, retaining nonlethal rules where applicable.
The catalogue includes separate authored entries for Bramble, ThunderBird, Scostubandits, Fuocherelli, Feralis and its Ancestral variant, GranScostumato, Sempre Verde, Lavastrello and its nest, Beast Worshippers, Bone Monk, Four-Blade Skull, Monstrous Skull, Ogor, Teirak, Laer, Oculum Turret, Sword Mannequin and DeadlySins. Every entry documents its own techniques, weaknesses, Open and conditional loot. Monster Book kill counts distinguish exact variants and species totals. Loot follows confirmed deaths without removing friendly actors at fight end.
Alive theme mode uses restrained scene-specific embers, snow or mist near the scenic edge. It preserves readable controls, reduced-motion settings and application lifecycle suspension.
''',
  ),
  ManualSection(
    titleIt: 'Maschere, Percezione e temi — 25 ottobre 2026',
    titleEn: 'Masks, scouting and themes — October 25, 2026',
    contentIt: r'''
Elementi: Demoniaco e Diabolico restano distinti anche nei nomi inglesi. Difesa Diabolica riduce del 75% i danni Demoniaci, senza requisito di Vita e senza riduzione reciproca automatica. Demoniaco, Nuvola e Roccia sono disponibili con temi propri: gli elementi selezionabili sono 61. Le resistenze già salvate non vengono rinominate o sovrascritte.
Consultazione Monster Book: aspetto e comportamento, habitat, statistiche base, punto debole, resistenze, abilità, Buff Open, Skill Open e drop sono separati. Ogni skill mostra le tre forme, requisiti, costo effettivo, cooldown, bersagli dichiarati ed effetti. Le attivazioni gratuite sono indicate chiaramente; nessun costo statistico viene mostrato come un finto 0/0. Nel Party le informazioni ancora ignote restano protette. La consultazione non cambia gli effetti o il JSON personalizzato.
Uomo con la maschera: quattro colori, Verde (Resilienza e Ricordo Vitale permanente secondo la condizione esistente), Rosso (Volontà), Blu (Materia), Viola (Oculum). Pugno serio è gratuito in Azioni/Reazioni, CD condiviso 3 turni: tira Schianto e aggiunge il totale al danno, poi +10/20/50% secondo la forma. Concatenazione blu usa una sola Azione o Reazione, CD condiviso 2 turni. Riflessi +5: 1d5+1 / 1d6+3 / 1d8+5 colpi, ciascuno da un terzo dei Danni; Precisione, disponibile solo dopo la scoperta del punto debole: 1d3+1 / 1d5+2 / 1d6+3 colpi, ciascuno da tre settimi dei Danni e con la normale Fragilità di Precisione applicata prima del singolo colpo. Puoi distribuire la raffica fra bersagli fino al numero di colpi; il danno si divide fra loro e aumenta del 5% per bersaglio. Inizia l’ultimo aggressore, se selezionato, altrimenti l’ordine è casuale. Una difesa critica positiva che supera l’attacco ferma tutti i colpi futuri; dal terzo colpo basta il critico positivo di un bersaglio selezionato, anche prima che venga il suo colpo. I danni già subiti restano. Il Viola recupera 2 Oculum al proprio turno; se già pieno ha il 20% di ricevere 1 temporaneo.
L’Ombra Ignota è una variante separata: maschera nera a spirale con un solo foro a mandorla e un occhio viola. L’Art L’Ombra rende immune al Fisico e aggiunge +5 ai tiri di Attacco e Difesa: forma I una propria azione, II fino alla fine del turno corrente, III fino al prossimo turno personale. Se prima in iniziativa, +3 Danni e +1 Difesa ogni 10 livelli, minimo +2 e +1. Teletrasporto nell’ombra: +9 al prossimo Attacco oppure +10 alla prossima Difesa, senza doppio consumo di Azione/Reazione; chance 10/15/30% di una Reazione veloce extra secondo l’ultima forma dell’Art.
Assassini Solari: maschera d’oro con sole inciso, raggi, piccoli soli e arco con due frecce solari, +3 al tiro. Assassini Angelici: arco con tre frecce angeliche, +9 al tiro, fino a tre bersagli; +25% Danni contro Chaos. Ogni tre colpi che tolgono Vita recuperano il 5% della Vita corrente per eccesso, senza risorgere a zero. Contatore azzerato a fine fight. Costi, forme, cooldown ed effetti restano modificabili e salvati.
Cinque creature comuni di livello iniziale 1: Vèndulo, Rascalume, Brumìlio, Gùravo e Mìrula; nessun bonus straordinario alle statistiche, due tecniche e materiali coerenti per ciascuna. Il catalogo planare comprende ora 380 voci fra specie e varianti.
Percezione, Investigazione, Furbizia e Valutazione: con dado naturale almeno 18 e lettura riuscita, il confronto di Livello + somma delle quattro statistiche dà solo un giudizio narrativo. Entro ±10% siete alla pari o quasi; fra 10 e 35% leggermente più forte/debole, oltre 35% nettamente; avversario almeno doppio: impossibile da battere. Non rivela il punteggio. Se la lettura fallisce, il log indica solo la statistica più alta che ostacola la percezione.
Temi e reliquie: comprare la pagina del mostro sblocca il suo aspetto per il party; una lettura riuscita che lo identifica ha il 90% di sbloccarlo, ritentabile con una nuova lettura riuscita. Varianti separate richiedono il proprio sblocco. La campagna condivide gli sblocchi, ogni scheda sceglie il proprio tema. Mostri ed evocazioni conservano l’aspetto della propria variante; i piani cambiano automaticamente il tema salvo scelta manuale della scheda. Colore e scelta restano nel JSON. Il selettore reliquie ha ricerca e righe da quattro.
Finché ricopre il ruolo Master, il Master ha accesso a tutti i temi e le reliquie, anche non ancora scoperti. Per assegnarli apre la scheda destinataria e clicca sulla reliquia: il selettore indica il nome della scheda. L’assegnazione sblocca soltanto quel tema e la sua reliquia, nel colore scelto, per quella scheda; resta salvata nel suo JSON e segue la normale sincronizzazione online delle modifiche del Master. Non rivela il mostro né sblocca il resto del catalogo al party. Tornando giocatore l’accesso completo termina: restano solo gli sblocchi normali e le assegnazioni ricevute. Automatico rimuove la scelta manuale senza cancellare i temi ricevuti. Le schede ricevute in sola lettura non si modificano.
Home: “Immagini Home” mantiene la scelta manuale o il casuale di sessione; la seconda opzione “Usa il tema attuale” mostra la stessa illustrazione del tema della scheda. Rame fatato originale è conservato. I campi colore accettano HEX #RGB, #RRGGBB e 0xAARRGGBB; i valori non validi non sostituiscono il colore.
Canone visivo: Luna buona, morta e assente dal cielo; Sole malvagio con l’occhio oro/arancio e pupilla scura del tema Benedict. Lunari e Stelle alleati, Solari nemici; fate generalmente malvagie, mai associate alla Luna. La maggioranza dei diavoli è lunare e il castello nero con luna rossa è una roccaforte alleata. Benedict è l’eroina solare eccezionale, la statua di marmo e oro protegge la città bassa di Lost Town. Obser: pietra grigia crepata con occhio centrale inciso. Dettagli in docs/OCULUM_LORE_VISIVA.md.
''',
    contentEn: r'''
Monster Book dossiers separate appearance, behaviour, habitat, base stats, weakness, resistances, skills, Open Buff, Open Skill and drops. Each skill presents its forms, actual costs, requirements, cooldowns, declared targets and effects. Explicitly free costs are labelled clearly. Unknown party discoveries remain hidden and reading never rewrites custom effects or JSON.
Demonic and Diabolic remain distinct, including English aliases. Diabolic defence reduces Demonic damage by 75% without an HP threshold or automatic reciprocal resistance. Demonic, Cloud and Rock have their own themes among 61 selectable elements. Existing saved resistance keys are preserved.
Masked men have four base colours: green (Resilience and permanent Vital Memory), red (Will), blue (Matter), purple (Oculum). Serious Punch costs no Action or Reaction, shares a three-turn cooldown, and adds its Slam roll to damage before the form's 10/20/50% increase. Blue volleys spend exactly one Action or Reaction with a shared two-turn cooldown. Reflexes +5 gives 1d5+1 / 1d6+3 / 1d8+5 hits at one third damage; Precision requires a discovered weak point and gives 1d3+1 / 1d5+2 / 1d6+3 hits at three sevenths damage, with normal per-hit Precision fragility. Split damage among selected targets and add 5% per target. The last attacker goes first if selected, otherwise order is random. A winning positive critical defence stops future hits; from the third hit any selected target's positive critical can stop the remaining volley. Purple restores two Oculum each personal turn or has a 20% chance of one temporary Oculum when already full.
The Unknown Shadow has one almond opening and a single violet eye in a matte black spiral mask. Its Shadow Art grants physical immunity and +5 attack/defence rolls for one own Action / the current turn / until the next own turn. Shadow Teleport grants the next attack +9 or defence +10 without a second Action/Reaction payment and can grant a Fast Reaction at 10/15/30%. Solar assassins shoot two solar arrows at +3; angelic assassins shoot three angelic arrows at +9, deal 25% more damage to Chaos, and heal 5% of current HP after every three HP-damaging hits, never reviving.
Five ordinary level-one creatures add distinct materials and techniques without extraordinary stat bonuses: Vendulo, Rascalume, Brumilio, Guravo and Mirula. The planar catalogue now contains 380 species and variants.
A successful scouting read with natural 18+ compares level plus four stats and reveals only a narrative power category: within 10% near-equal, 10-35% slightly stronger/weaker, above 35% clearly stronger/weaker, enemy at least twice as powerful impossible. A failed read names only the highest blocking stat.
Purchasing a Monster Book page unlocks its appearance for the campaign party. Successful identification has a repeatable 90% unlock chance; variants unlock separately. Each sheet chooses its own appearance. Planes select themes automatically unless manually overridden; summoned monsters keep their own variant theme. The Home's second option follows the current theme artwork. Colour fields accept #RGB, #RRGGBB and 0xAARRGGBB without applying invalid input. Original Fairy Copper artwork is preserved.
While holding the Master role, the Master can use every theme and relic. Open the recipient sheet and click its relic to assign the chosen appearance and colour only to that sheet. The assignment is saved in its JSON and uses normal online Master sheet-edit synchronization. It reveals no Monster Book data and unlocks nothing for other sheets. Full access ends when the Master becomes a player; ordinary unlocks and received assignments remain. Automatic clears the manual choice without deleting received assignments. Read-only shared sheets cannot be changed.
Visual canon: the good Moon is dead and absent from current skies; the evil Sun carries Benedict's gold/orange iris and dark pupil. Lunar and star factions are allies. Fairies are generally malevolent and never lunar. Most devils are lunar and the black castle with a red moon crest is an allied stronghold. Benedict is the heroic solar exception. Obser are cracked grey stone discs with an engraved central eye.
''',
  ),
  ManualSection(
    titleIt: 'Controattacco e risorse personali — 25 ottobre 2026',
    titleEn: 'Counterattacks and personal resources — October 25, 2026',
    contentIt: r'''
Turnistica di sessione: resta utilizzabile per le azioni di roleplay anche fuori combattimento. Il Master usa Inizia fight per ritirare tutte le iniziative e iniziare il giro 0; il comando diventa Fine combattimento durante lo scontro. Alla fine vengono assegnati i drop e restano party e alleati, con turnistica ancora utilizzabile. Il consumo di Azioni e Reazioni segue la turnistica anche fuori fight; gli effetti riservati al combattimento restano separati.
Inventario di Volontà: non è gestito da borse, ma da uno spazio generato dalla tua Volontà, sempre più ampio e capace di reggere peso. A 15 Volontà è una stanzetta, da 25 una stanza sempre più grande; a 500 puoi creare un intero regno. La capacità meccanica resta Volontà totale ×3 kg. Il regno occupa il 25% della capacità, limitato allo spazio libero se inferiore; cambia dimensione con lo spazio e la Volontà. Ogni kg effettivamente occupato dà +0,01% Danni e Difesa e +0,005% ai sottotratti, nessun aumento alle quattro statistiche. I risultati finali si arrotondano per difetto. Esempio: 375 kg → +3,75% Danni/Difesa e +1,875% sottotratti. Il bonus dura finché il regno esiste; in Inventario puoi crearlo o distruggerlo, liberando peso e rimuovendo il bonus.

Nuvì è il nome confermato della creatura soffice e normalmente pacifica. Ogni esemplare riceve un colore nel nome (Avorio, Lavanda, Pesca, Celeste, Menta), conservato nel JSON. Ha soltanto il volo naturale permanente: +3 Difesa e +3 Movimento, nessun costo o tecnica offensiva; questa richiesta specifica prevale sull’Open generica per tutti i mostri.
Coniglio Prestigiatore: Mezzano, livello base 3, telecinesi e tre affinità elementali casuali scelte alla creazione e salvate, ognuna con la propria tecnica. Cappello magico costa 2/3/4 Oculum secondo la forma, cooldown condiviso 4 turni. La prima Azione prepara Instabile (−2, un colpo); ogni successiva Azione personale può caricare Stabile (+1, due colpi) e Perfetto (+5, tre colpi). Il lancio è incluso nell’ultima Azione, senza doppia spesa. Puoi scegliere fino a tre bersagli; con meno bersagli i colpi si ripetono fino al numero previsto. Ogni nuovo bersaglio dopo il primo aggiunge +25% del danno base, ogni colpo aggiuntivo sullo stesso +30%; ogni colpo estrae indipendentemente il 60% di usare l’elemento cui il proprio bersaglio è più fragile. Se non ha fragilità, l’elemento resta casuale. Il danno base iniziale del raggio è Danni della scheda +12 +6×Forma; conserva buff e protezioni normali.
Coniglio al Plasma: variante robot di Postea, livello base 3, zero Oculum, raggi runici al plasma e telecinesi alimentati da Materia. L’oggetto Catene runiche d’intrappolamento immobilizza dopo il colpo riuscito fino a una prova di Forza o Riflessi pari o superiore al tiro originale; nessuna scadenza a turni. La liberazione usa la normale risorsa del tiro.
Coniglio al Plasma: Ricarica di Materia I/II/III recupera 1d4 / 1d8+3 / 1d12+6, senza costo statistico, con Azione nel proprio turno o Reazione fuori turno e CD condiviso 4 turni. Riempie prima la Materia mancante; metà dell'eccesso per difetto diventa Materia temporanea, spesa prima della normale e rimossa a fine scontro.
Pupazzo Vivente Artigliato: forma magica del Regno Mezzano, vuota all'interno e animata dalla magia, con colori variabili, maniche lunghe, artigli e gambe corte a molla. Artigli +15/+22/+30 danni Taglio. Fuoco ×2; danni spirituali e all'Anima non lo danneggiano. Scatto a molla costa Materia 1/2/3, CD condiviso 4 turni, +3 ai tiri di Attacco/Difesa per un turno e 90% di una Reazione veloce extra. Costume del Pupazzo: totale Drop ≥43, una tecnica casuale diversa dal salto più Scatto a molla, entrambi con costo e cooldown.
Robot Artigliato a Molla: variante di Postea, tecniche Plasma, Energia e Fulmine; Fulmine rigenera il 100%, Taglio/Fuoco −50%, Contundente ×2. Gli Scarti robotici consentono tre tentativi con Meccanica o Crafting −2: supera strettamente DT 26 + livello robot + max(0, livello robot − tuo livello). Critico positivo deve comunque superarla: statistiche 100%; successo normale 80%, stessa Vita e resistenze. Critico negativo esaurisce i tentativi. I rottami distrutti danno un solo tiro al 65% per un nucleo rotto del livello del robot.
Mecha: Azione personale per entrare o uscire. Il corpo del robot assorbe prima i danni con Vita propria. Il pilota mantiene le proprie risorse e riceve una Reazione del mecha al proprio turno, veloce con costruzione critica. Da solo il robot ha una sola Reazione (veloce se critico), nessuna Azione e infligge il 40% dei danni. Il tasto Esci dal mecha resta visibile; uscendo spariscono statistiche, resistenze, abilità ed effetti del robot e si ripristinano quelli del pilota. Danni e cooldown del robot restano salvati nel suo corpo, senza guarire entrando e uscendo.
Distruzione del mecha: 30% di esplodere. Fuga senza Reazioni = 1d24 + Riflessi/2 + livello pilota/3; con Reazione = 1d20 + Riflessi +5 + livello/2; veloce dà altri +5 e riduce del 25% i danni se fallisce. Divisioni per difetto; serve superare 16 + livello macchina. Fuga riuscita evita tutto. Danno Esplosivo iniziale modificabile 20 +3×livello macchina, +150% danni agli Scudi, con le normali protezioni del pilota.
Medusa di Vetro (Affogato, livello 2): Puntura erosiva infligge 8/12/16% delle riserve correnti del bersaglio con Difesa e Scudi normali; Campana chiusa aggiunge +20/30/40% Difesa per un turno. Nocciolo Corazzato (Foresta elementale/Mezzano, livello 1): Guscio elastico passivo riduce ogni colpo del 15% prima di Difesa e Scudi, senza tiro né costo; Guscio serrato aggiunge +20/30/40% Difesa per un turno. Valori, costi, forme e cooldown rimangono modificabili; i nuovi materiali e le scroll seguono i drop del catalogo, le catene si ottengono come oggetto su naturale 18+.

Skill e forme Art possono configurare fino a quattro risorse consumabili, ciascuna con minimo e massimo. Le risorse aggiuntive si pagano insieme, con verifica completa prima del consumo; sono salvate nel JSON senza rimuovere il costo precedente. Il pagamento alternativo di Observer’s Tear resta distinto.
Le Open mancanti dei mostri ricevono buff coerenti sulla creatura, una Skill separata e cooldown modificabili. Il bonus `monster_open_bonus` collega il Buff ai valori reali della Skill Open; lo Scudo protettivo iniziale proposto è 50 + Livello ×3. Le Open personalizzate salvate non vengono sostituite.
Danno percentuale contro il bersaglio: base = Vita attuale + HP temporanei + Scudo + Scudo Oculum. Il 30% di 100+20+30+10 è 48 prima della normale Difesa. Oltre Scudi esclude i due Scudi dalla base (120 → 36) e li ignora nell’applicazione; Oltre Difesa salta soltanto la Difesa. Il bonus percentuale ai propri danni conserva il significato precedente.

Observer’s Tear è la forma normale viola, più forte: livello base 6, statistiche iniziali 10/16/10/6, Manifestazione del Potere +18, 80–200 Obser e 6 Oculum. Mani invisibili (costo totale 3/5/7) e tentacoli (2/3/4) si pagano liberamente in Obser, Oculum o entrambi; aggiungono Manifestazione del Potere e somma delle risorse spese ai danni. ObserSunshine è la variante solare dorata: livello 3, statistiche 5/10/6/0, Manifestazione +10, 20–100 Obser, zero Oculum; mani 6/9/12 e tentacoli 4/6/8, esclusivamente Obser. I tentacoli immobilizzano per un turno dopo un colpo riuscito. CD mani 3/3/4, tentacoli 3/4/4. Il controattacco contro entrambe riceve +120% Danni prima delle protezioni se vinto, pareggiato o perso di massimo 3 punti. Gli Obser non spesi del nemico ucciso vanno in cassa comune una sola volta per sconfitta, esclusi gli evocati.
Il pagamento misto mostra cinque piccoli suggerimenti sulla stessa riga: Oculum, ¼ Obser, ½ Obser, ¾ Obser, Obser. Tooltip dopo 0,8 secondi di hover e pressione prolungata mostrano quantità esatte. Gli scarti vanno alla quota maggiore; a 50/50 si sceglie casualmente una volta per finestra. I valori restano modificabili manualmente. Sunshine non mostra pagamenti Oculum.
Saltalungo Maculato: Mezzano/Foresta elementale, livello base 2, braccia allungabili e salti enormi, Riflessi +6 da coda integra. Un critico mirato alla coda con perdita di Vita rimuove il +6 e dà −3 Iniziativa fino a fine scontro, senza cumulare. Famelico dell’Oblio: Oblio/Shadow Hell, livello base 4, assalto con tiro Forza o Riflessi e danni aggiuntivi pari alla loro somma; Morso avvia uno stadio di memoria incrinata, controllo con Resistenza, Canalizzazione, Memoria, Controllo corporeo o Crepa contro il totale del Morso. Riuscita rimuove uno stadio, fallimento ne aggiunge uno; al quinto stadio 50% di perdere la Reazione normale al proprio turno, log «cosa stavo facendo?». Riposo Lungo azzera gli stadi. La morte causata dal Famelico nasconde l’identità nei riferimenti del party, conservando scheda, progressi e premi. Tutte e quattro le voci hanno materiali distinti, scroll su naturale 18+ e reliquia su 20; livelli, statistiche, costi, cooldown e tecniche sono modificabili negli editor e nei JSON.

Catalogo Skill e Art: carte adattabili a desktop, tablet e telefono, con tecniche delle creature e delle Art iniziali e salvate. Il bordo indica il costo, il nome la statistica potenziata: Oculum viola, Fortuna oro, Obser grigio sfumato Oculum, materiali e oggetti nero opaco. Volontà, Materia e Resilienza mantengono i colori della scheda. Le sfumature combinano risorse e beneficio; forme, costi ed effetti rimangono modificabili.
Tre nuove creature: Lepre Scattobrina delle Terre di ghiaccio (Volontà 1/2/3), Geco Turbina di Postea (Materia 1/2/3), Mantide Sanguescatto della Foresta elementale (Vita 5/8/12). Condividono Aumento di velocità: nessuna Azione o Reazione per attivarla, anche a risorse di turno esaurite, ma costo statistico proprio. CD 6/4/3 personali condiviso fra le forme; I/II danno una normale extra al prossimo turno, III una veloce immediata cumulabile con quella iniziale. II/III aggiungono +10% Attacco e Difesa per un turno. Iniziativa +1/+3/+6 per un turno. Costi, valori, durata e cooldown sono modificabili; ogni specie ha anche un attacco e materiali propri.
Questa sezione sostituisce le precedenti indicazioni sul rinnovo della Reazione veloce. Giro 0: tutti ricevono una Reazione veloce dopo l’iniziativa e l’Azione al proprio turno. Dal giro 1: Azione e Reazione normale al proprio turno; la normale sostituisce la veloce iniziale, che non si rigenera. Una veloce iniziale conservata fino al proprio turno del giro 1 scade e dà +9 al prossimo tiro e +5 ai prossimi Danni o Difesa. Nessun premio al primo turno personale. Utility, Percezione e varianti consumano il +9 ma conservano il +5. Le normali inutilizzate danno il precedente +3; massimo +12 al tiro dalle reazioni conservate. Le risorse si rinnovano al turno del proprietario, non al cambio del giro globale.
Una Reazione veloce spesa dà +3 al tiro per cui viene usata, incluso attacco, difesa, Utility e Percezione o varianti; il primo nella turnistica ha +6 nel solo giro 0. A risorse esaurite non puoi agire fino al tuo turno; la prima difesa contro ogni attacco rimane gratuita.
Controattacco contro un colpo ancora da difendere: vincendo infliggi danni pieni e non li ricevi; parità 50% a entrambi; perdendo di 1–3 ricevi 75% e infliggi 25%; da 4 punti di sconfitta ricevi danni pieni senza infliggerne. Percentuali per difetto prima di Difesa, resistenze e Scudi. Usa una sola Azione se è il tuo turno o se sei immediatamente il prossimo (in tal caso la anticipi e arrivi con Azione già consumata), altrimenti una Reazione normale o veloce. La difesa ordinaria continua a vincere le parità.
''',
    contentEn: r'''
Round zero grants everyone one initial Fast Reaction and an Action on their own turn. From round one onward, their own turn grants an Action and a normal Reaction, replacing the initial Fast Reaction. It does not regenerate. An unused initial Fast Reaction expires on the second personal turn, granting +9 to the next roll and +5 to the next damage or defense consequence. Utility and Perception consume the roll bonus but preserve the consequence bonus. Unused normal Reactions still grant +3, with a combined unused-reaction roll cap of +12. Spending a Fast Reaction grants +3 to its attack, defense, utility or perception roll, or +6 for the first initiative participant during round zero only. Resource exhaustion blocks actions except the first free defense against each incoming attack.
Counterattack an incoming attacker: win deals full own damage with none received; tie deals half each; losing by one to three deals 25% own damage and receives 75%; losing by four or more receives full damage with none dealt. Round down before each target’s Defense, resistances and shields. Spend exactly one resource: an Action on your turn, the next Action in advance if you are immediately next, or a normal/Fast Reaction otherwise. Ordinary attack versus defense ties still favor defense.
''',
  ),
  ManualSection(
    titleIt: 'Bestiario, quest e aggiornamenti — 24 ottobre 2026',
    titleEn: 'Bestiary, quests and updates — October 23, 2026',
    contentIt: r'''
Specie base e varianti del Monster Book: Lupo, Goblin, Coboldo e Gnoll hanno ciascuno la propria voce base; Lupo comune e Lupo Gigante restano specie distinte. Varianti nuove: Goblin Incendiario, Coboldo Minatore, Coboldo Runico di Postea, Gnoll delle Nevi e Gnoll Diabolico. Ogni variante ha descrizione e punto debole propri, un drop materiale distintivo e due skill non condivise con le altre voci. Minatore: piccozza e riparo di scisto; Runico: Fulmine e paratia; Gnoll delle Nevi: falce e rallentamento nelle forme superiori; Gnoll Diabolico: lancia e passo della brace; Goblin Incendiario: pece e fumo. Gli habitat corrispondono ai piani. Le skill hanno forme I–III, costi Oculum 1/2/3 e cooldown; i valori si possono modificare.
Nuovo catalogo: 80 creature base, dieci per ciascuno di otto habitat (Mezzano, Sotterraneo, Terre di ghiaccio, Nuvole rocciose, Regno affogato, Foresta elementale, Postea e Regno Caramella). Hanno statistiche iniziali contenute, descrizione anatomica, punto debole, drop materiale e due tecniche specifiche con forme, costo e cooldown modificabili. Le loro tecniche apprendibili compaiono nel catalogo Skill e nell’indice delle pergamene; ogni skill mantiene il proprio costo dichiarato in Oculum, statistiche, oggetti o materiali.
Cristalli di Ascension Dust: Piccolo 1d3 (40–60 Obser), Medio 1d6+2 (90–120), Grande 1d10+2 (150–200). Si conservano come materiali crafting o si rompono a scelta. Drop aggiuntivo: nemico ucciso almeno tre livelli sopra chi tira, totale Drop almeno 20 + livello nemico + 2×Grado, poi estrazione unica 25/15/6/54% per piccolo/medio/grande/nulla. Fusione I/II/III visibile solo possedendo la taglia: consuma un cristallo, +1/+2/+3 a tutte le statistiche e +10/+20/+30% agli effetti positivi Art e Skill per 1d3/1d6+1/1d10+2 Riposi Lunghi; +5/+10/+15% a Danni e Difesa personali. Una fusione attiva alla volta, sostituibile; in fight usa Azione propria. A fine scontro party e NPC buoni rimangono sulla board, conservando tutti i drop assegnati.
Parassita larvale: 1/0/0/0 statistiche, Riflessi +9–15 e Vita fissa. Unico attacco Infiltrazione, con Azione e Riflessi. Ospite controllato dal Master, parassita non colpibile dentro di esso. Il proprietario tenta Resistenza o Volontà una volta per turno spendendo Azione, contro il tiro precedente del parassita; penalità crescente −3 fino a −9. Fallire entro cinque toglie una Reazione al controllore; fallire di uno dà anche −4 al suo prossimo tiro. Critico che danneggia la Vita dell’ospite: +5 al prossimo tentativo. Medicina naturale 14 con Riflessi9/10,15 con11/12,16 con13,17 con14,18 con15 uccide il parassita. Una Open dell’ospite lo uccide e libera il personaggio; il controllore non può usarla.
Martire Mortale dà metà EXP e alla morte potenzia massimo tre alleati scelti dal Master: +10% a tutte le statistiche, +10% ogni dieci livelli, durata livello/5 per difetto (minimo uno).
Rusty a Postea vende Anti malus (50 Obser, prima copia omaggio), Curatore vivente (Medicina propria 150/100/75/50% del compratore, prezzi proposti 95/80/70/60), Pawn Postea (250), Core autoriparabile (90 + Livello + Grado ×2), Katana del Fato (200), Guanti da combattimento (60) e Runa d’impatto (+20 Danni, 50 Obser, 20 utilizzi modificabili). Le creature entrano in iniziativa; il Curatore cura il proprietario ogni proprio turno, il Core recupera al Riposo Lungo e il Pawn cresce dopo rinascita soltanto a vittoria. Anti malus consente di scegliere la condizione rimossa e la blocca fino alla fine del fight corrente o prossimo. Katana e Guanti rinnovano i benefici per sessione dal comando Nuova sessione. Bonus e limiti restano modificabili.
Identità Fato / Chaos: Fato è predefinito. A ogni nuovo Grado un solo tiro: 6% niente, 14% una Ispirazione normale, 30% normale e Super, 40% normale/Super/Oculum, 9% le tre più una Schivata Oculum, 1% le tre più Schivata, Scudo pari al 20% della Vita attuale e Scudo Oculum aggiuntivo pari al 25% di quello Scudo, per eccesso. Cambiare identità o abbassare il Grado non ripete i premi; nessun premio retroattivo.
Se hai identità Chaos raccogli 1,8 volte i grammi dei materiali estratti, arrotondati per eccesso. Il bonus sostituisce quello del Raccoglitore, non si somma e non moltiplica i drop dei mostri.
Chaos: a inizio fight e a ogni turno personale estrae indipendentemente da −3 a +3 sulle quattro statistiche; sostituisce i bonus precedenti e li rimuove a fine fight. Dopo un attacco riuscito o una difesa riuscita, 25% di infliggere −3 a tutti i tiri all’avversario per un turno, una sola estrazione per avversario nel proprio turno. I valori di base salvati non vengono alterati.
Il malus Chaos coinvolge anche chi ha aiutato l’avversario nello stesso confronto.
Gli occhi seguono il mouse muovendosi leggermente. Solo il clic sul ruolo Master li fa guardare dalla parte opposta in 0,4 secondi; a 0,6 secondi dal clic riprendono a seguire. La cornice del ritratto è più larga del 20%, con bordo proporzionato.
Alcune skill hanno carica crescente: 2 Oculum e una Azione per attivarle, +40% Danni al rilascio immediato; ogni successivo incremento costa 1 Oculum e una Azione in un tuo turno, fino a +80%, +120%, +180%. Puoi rilasciare prima del massimo con una normale Azione/Reazione. I controlli di concentrazione si applicano solo alla perdita di Vita. Le altre skill non acquisiscono questa carica automaticamente. Costi e progressione sono modificabili.
Solo le skill che lo dichiarano richiedono preparazione e rilascio: prima una Azione, poi un normale attacco o difesa con Azione/Reazione, senza una terza spesa. Il tiro di Concentrazione o Sussurro determina il bonus. Il mantenimento si controlla soltanto quando perdi Vita: bonus Concentrazione come percentuale, massimo 100%, meno 10 punti se il nemico supera il tuo Grado di due, meno 20 se di tre e così via. Solo durante l’uso della scroll si aggiunge +3 × Grado della scroll; la skill appresa non conserva il bonus.
Potenziamento è accessibile in Tiri e azioni quando sbloccato: clicca, scegli l’Oculum immesso e conferma. Valgono gli stessi limiti esistenti e il consumo avviene al prossimo tiro. Ogni punto dà +3 al tiro e, se attacchi, +2 Danni; nelle preparazioni aumenta anche il mantenimento della concentrazione. Gli altri tiri e le skill in una sola fase rimangono utilizzabili normalmente.
Nelle tecniche pagate con Volontà o Materia, i bonus numerici positivi hanno un potenziamento iniziale del 20%, arrotondato per eccesso e modificabile nella formula. Durate, Azioni e Reazioni non vengono moltiplicate.
Il bestiario contiene 380 voci planari fra specie e varianti canoniche, senza duplicati: include Piranha Mortale nel Regno Affogato e l’Araldo del Raggio Angelico nei Regni Angelico e Sacro. I Piranha attaccano coordinati con un solo tiro, possono applicare Sanguinante e richiamano al massimo due Piranha minori deboli, con iniziativa propria e senza altre abilità. Raggio Angelico aggiunge al danno base il Karma dell’attaccante e il valore assoluto del Karma negativo del bersaglio; poi infligge ×2 ai Demoni, ×1,5 ai Diavoli e ×1,3 agli Arcidiavoli. Costi, forme, durata, recupero e valori iniziali si possono modificare nell’editor della scheda. I costi espliciti in testo vengono letti prima degli altri numeri; se una tecnica non dichiara un costo, il Monster Book usa una risorsa positiva coerente con la creatura e altrimenti nessun costo, mai un costo Oculum o Materia presunto. Un costo variabile può superare il valore iniziale solo se l’effetto scala davvero con la risorsa spesa. Le varianti non contano come specie nuove. Goblin Assassino e Arciere hanno ruoli e skill differenti; a Postea si trovano Segugio runico Sentinella e Ragno saldatore Recuperatore; nel Regno Caramella il Marshmallow pacifico ha una variante Incenerita ostile. Ogni voce ha descrizione, punto debole, drop e due tecniche proprie con tre forme modificabili, senza ulteriori copie generiche. Il Thunder Bot di Postea è una sfera rotante senza Oculum, Art o Difesa: ha solo Autodistruzione a corona. Un solo attacco Fulmine contro tutti gli avversari, senza limite né divisione del danno: ogni bersaglio riceve Vita attuale + Danni inflitti della scheda. Il bot muore dopo il lancio; consuma una Azione e nessuna statistica. La famiglia del Lupo delle Nevi collega la forma delle Terre di ghiaccio al Lupo Infernale del Regno demoniaco, al Lupo d’Ombra dell’Oblio/Shadow Hell e al Lupo Runico di Postea. Le varianti condividono i progressi di specie, ma hanno skill, debolezze e materiali diversi: naturale 8+ dà il materiale, 18+ le scroll delle due skill, 20 una reliquia arma con skill e livello richiesto. Le mosse hanno costi, cooldown e requisiti di livello modificabili; forme II e III si sbloccano a +3 e +6 livelli. I materiali aggiungono Danni o Difesa quando fusi con un equipaggiamento compatibile. Ogle, Sharp, Topino Avventuroso e Mosca Campana aggiornano le voci esistenti. I filtri per luogo sono disponibili nel Monster Book e nella scelta delle creature; habitat, statistiche, regole speciali, abilità ed equipaggiamento rimangono modificabili e salvati.
Raggio Angelico e Richiamo dei Piranha si acquistano come pergamene apprendibili rispettivamente nei mercati Angelico/Sacro e Affogato, con prezzi e regole normali delle scroll. A Postea è disponibile Meccanio, robot compagno permanente: si autoripara con Meccanica al posto di Medicina e anche il padrone può ripararlo con il proprio tiro di Meccanica (cura pari al totale, doppia su 20 naturale, entro il massimo). Valori iniziali modificabili: RES4/VOL2/MAT4/OCU0, livello 0, prezzo 120 Obser, peso 6 kg.

Meccanio possiede tre skill casuali (almeno una offensiva), Protezioni di Emergenza sempre disponibile e una sola Open casuale. Non ha Oculum né Art; usa Reazioni, salvo l'Azione dedicata al lancio di Sfera elettro nel turno dopo la carica. Forme I–III hanno cooldown separati. I bonus di rigenerazione con Scudo Oculum sono limitati dalle statistiche del padrone e terminano al suo Riposo Lungo. Le varianti selvatiche sono Malconcio (metà Scudo, skill al 75%), Primitivo (+3 Difesa, Scudo 120% Vita e Scudo Oculum 10% Vita) ed Élite (skill al 125%). I valori iniziali sono modificabili nel JSON della singola creatura. Per queste varianti: per addestrarne uno senza padrone, Meccanica deve pareggiare o superare 13 + livello + 3 × Grado. Puoi possederne uno solo. Aggredirlo imposta il rifiuto comandi al 60%; ogni tuo Riposo Breve sottrae 20 punti percentuali e ogni Lungo 50. In Supporto e utilità, Empatia sottrae il totale del tiro in punti percentuali dal rifiuto, minimo zero; puoi usarla una sola volta, recuperandola con un Riposo Breve o Lungo. Inganno è una alternativa con lo stesso unico uso: con dado naturale sotto 12 aumenta il rifiuto di 10 punti percentuali (massimo 100%), altrimenti lo riduce del totale come Empatia. Se il padrone protegge Meccanio con Aiuto in una difesa riuscita, il rifiuto scende di 5–30 punti percentuali casuali, minimo zero, una sola volta per attacco. Anche la difesa fallita riduce il rifiuto di 2–40 punti: 2 + 38 × frazione della Vita massima persa dal padrone durante la protezione, arrotondati; Scudi e HP temporanei non contano.
Fluttuare è una versione ridotta delle Ali di Fata: volo per 1d4 turni, +3 Difesa e +3 Movimento, costo fisso 2 Oculum e CD 3 turni personali. Azione nel proprio turno o Reazione fuori turno. Nessuna immunità automatica; durata e bonus scadono insieme. Sono valori confermati e modificabili.
Bringi è pacifico/neutrale, simile a uno scoiattolo con guance sempre piene. Risponde alla prima aggressione con 1d20 semi, ciascuno da 1 Vita; dopo tre colpi ricevuti spara 1d100+20 semi e ricomincia il conteggio. Vive nel Regno Mezzano e nella Foresta elementale.
Il party ha tre quest contemporanee nella barra superiore. Le uccisioni iniziano a contare dalla comparsa della quest, escludono le evocazioni e richiedono nemici di livello almeno pari al riferimento del party. Gli obiettivi considerano il luogo corrente; la crescita del Velo parte dal valore migliore attuale del party. Le ricompense in Obser vanno nella cassa comune. Un unico tiro assegna al responsabile del completamento: 25% Ispirazione, 10% Super Ispirazione, 5% Ispirazione Oculum, 3% Schivata Oculum, 1% tutte e tre le Ispirazioni e una Schivata, 56% soltanto Obser. Le ricevute impediscono doppie assegnazioni; una quest completata viene sostituita.
I premi speciali dei mostri assegnano scroll con apprendimento normale. Sharp usa il dado naturale almeno 18 per le scroll rare; Mosca Campana usa naturale almeno 15 per la polvere e almeno 18 per la campanella; Topino usa naturale 20 per il coltello avvelenato. Annichilimento crea un Titolo Malanno @res-30% che dura tre Riposi Lunghi.
Gli aggiornamenti controllano i download pubblici GitHub, senza traffico Supabase, e riconoscono il commit della build. La stessa versione, una versione precedente o un ramo divergente non sostituiscono automaticamente l’app installata. Prima di installare viene salvata e verificata una copia JSON dei salvataggi. Windows mantiene anche il runtime precedente per il ripristino. Android usa la stessa firma e richiede la conferma del sistema; una firma diversa interrompe l’aggiornamento senza disinstallare.
''',
    contentEn: r'''
The planar bestiary contains 380 entries including authored variants without duplicates, including Piranha Mortale and the Angelic Ray herald. Piranha attack as a coordinated group, can inflict Bleeding, and summon up to two weak minions with their own initiative. Angelic Ray adds the attacker's Karma and the absolute value of a target's negative Karma to base damage, then deals ×2 to Demons, ×1.5 to Devils, and ×1.3 to Archdevils. Skill costs, forms, duration, cooldown and starting values remain editable on the saved sheet. Explicit costs in skill text are parsed before other numbers; when no cost is specified, Monster Book uses a positive resource appropriate to the creature or no cost, never an assumed Oculum or Materia cost. Variable maximum costs are allowed only when the effect scales with the spent resource. Fluttuare grants flight for 1d4 turns, +3 Defence and +3 Movement, costs two Oculum and has a three-personal-turn cooldown. It uses an Action on your turn or a Reaction outside it, without automatic immunity.
Three campaign quests pay Obser into the party chest and use one confirmed percentile draw for the personal reward. Historical kills and summons do not count; receipts prevent duplicate rewards. Special monster rewards grant scrolls using normal learning rules. Annihilation lasts three Long Rests as a @res-30% Ailment Title.
Updates use public GitHub downloads, check source ancestry and archive integrity, and verify a JSON save backup before installation. Android preserves its signing identity and uses the system installation confirmation. Failed or older builds never automatically replace the installed app.
''',
  ),

  ManualSection(
    titleIt: 'Revisione confermata — 22 ottobre 2026',
    titleEn: 'Confirmed review — October 22, 2026',
    contentIt: r'''
Padrone della Corruzione richiede un numero di colpi pieni pari alla differenza positiva di livello fra mostro e personaggio. PG livello 5 contro mostro livello 8: tre colpi pieni. Mezzi successi e colpi durante la ricarica non contano. Ogni tentativo spende il conteggio; se il mostro resiste, servono altri tre colpi. Il bonus passivo di resistenza +50 punti percentuali rimane valido anche in ricarica.
Occhi del Mercato Nero: base casuale salvata 36–69 Obser al livello 0, crescita lineare fino a 115 al livello 10 e stesso incremento oltre il 10. Alla base si aggiungono statistiche totali del mostro ×2. Ogni blocco completo di 20 statistiche del mostro oltre il totale del personaggio aggiunge +25% al prezzo, sommando le percentuali e arrotondando per difetto. Con 18 statistiche, livello 10 e nessun surplus: 151 Obser prima del modificatore del mercante. Le offerte già salvate conservano il proprio prezzo.
Raccoglitore è una famiglia di tredici oggetti, Grado 0–XII: ciascuno raddoppia la raccolta di Grado pari o inferiore. Non richiede livello 12. I prezzi e i dati rimangono modificabili; oggetti personalizzati già salvati non vengono riscritti.
I Boss danno EXP ×2 in Normale e Oculum, ×2,1 in Facile e ×1,9 in Difficile. Mini Boss invariati. Fragilità Assoluta +90%, Distruttiva +100%, Semi Letale +250%, Letale +500%: Letale significa danno ×6. Queste correzioni prevalgono sulle descrizioni precedenti.
''',
    contentEn: r'''
Corruption Mastery needs as many full hits as the positive monster/player level difference. Level 5 versus level 8 needs three full hits. Grazes and hits during cooldown do not count. Each infection attempt spends the count; a resisted attempt requires three new full hits. Passive resistance still adds 50 percentage points during cooldown.
Black Market Fallen Eyes have a saved random level-zero base of 36–69 Obser, growing linearly to 115 at level ten and at the same rate beyond. Add twice the monster's total stats. Every full block of twenty monster stats above the owner's total adds 25 percent to the price, additively, rounded down. Eighteen stats at level ten without a surplus cost 151 before the merchant modifier. Existing saved offers retain their prices.
Collectors have thirteen grades, zero through XII, and double materials collected at or below their own grade. They do not require level twelve. Saved custom items remain intact.
Boss XP multipliers: Normal/Oculum 2, Easy 2.1, Hard 1.9. Mini Bosses are unchanged. Absolute Fragility is +90%, Destructive +100%, Semi Lethal +250%, Lethal +500%, meaning six times damage. These corrections override older descriptions.
''',
  ),
  ManualSection(
    titleIt: 'Mercanti, cibi e bevande — 22 ottobre 2026',
    titleEn: 'Merchants, food and drinks — October 22, 2026',
    contentIt: r'''
Ogni banco mostra a ogni personaggio la propria scorta di 6–9 offerte casuali, con una probabilità del 16% di mostrarne 12. In online la scorta resta personale e non viene trasferita agli altri con la scheda; gli oggetti acquistati restano nell’inventario del personaggio e si sincronizzano normalmente. Il banco presenta solo oggetti delle proprie categorie e cerca di non mostrare più offerte della stessa famiglia o con lo stesso effetto. La selezione resta salvata per mercante, banco e personaggio; favorisce il livello del personaggio e considera in misura minore il budget. Quando un oggetto monouso viene acquistato, la sua offerta esaurita può essere sostituita, conservando le altre offerte disponibili. Gli inventari completi e le personalizzazioni salvate restano conservati.
Il catalogo del cuoco contiene molti nuovi piatti e bevande: Ricordo Vitale, Vampirismo I–III, +30% Danni, +20% Difesa, Trasparenza, Invisibilità, Accelerato e Concentrato, oltre a pasti e infusi statistici. Le condizioni e i bonus a Danni e Difesa indicati come effetti da combattimento durano 3 turni. Vampirismo usa il normale calcolo Oculum e il suo stadio; Ricordo Vitale conserva anche il suo effetto di cura e il maggiore danno ricevuto. Effetti, stadi, costi, statistiche e durate sono modificabili nel JSON dell’offerta.
''',
    contentEn: r'''
Each stall shows 6–9 random offers, with a 16% chance to show 12. It only displays items from its own categories and avoids multiple offers from the same family or with the same effect. Selection persists per merchant and stall; it favors character level and considers budget more lightly. When a single-use item is bought, its exhausted offer may be replaced while other available offers remain. Full inventories and saved customizations are preserved.
The Chef catalog includes many new meals and drinks: Vital Memory, Vampirism I–III, +30% Damage, +20% Defense, Transparency, Invisibility, Haste and Focus, as well as stat meals and infusions. Conditions and Damage/Defense bonuses marked as combat effects last three turns. Vampirism uses the normal Oculum calculation and stage; Vital Memory retains both its healing and increased-damage effects. Effects, stages, costs, stats and durations remain editable in the saved offer JSON.
''',
  ),
  ManualSection(
    titleIt: 'Vampirismo automatico online — 22 ottobre 2026',
    titleEn: 'Automatic online Vampirism — October 22, 2026',
    contentIt: r'''
Nei fight online Vampirismo recupera automaticamente Vita dopo la ricevuta dei danni effettivi del bersaglio. La base resta 3% per stadio I–XII, applicata alla Vita realmente sottratta: Scudi, HP temporanei e danni oltre la Vita rimasta non contano. Impostazioni iniziali modificabili: fattore Facile 1,25, Normale 1, Difficile 0,75, Oculum 0,5; limite per attacco pari al 3% della Vita massima per stadio, con lo stesso fattore. Tutti i bersagli del medesimo attacco condividono il limite. La cura arrotonda per difetto, minimo 1 soltanto con danno Vita e limite sufficiente; non supera la Vita sottratta né quella mancante. Maledetto e gli altri modificatori di cura restano validi.
Ricevute duplicate o riprodotte non curano due volte. La cura raggiunge la scheda che ha attaccato anche se hai aperto un'altra scheda. Colpito manuale durante il fight online resta un resoconto e non assegna altra Vita. Senza una ricevuta della perdita effettiva non si usa il danno dichiarato come ripiego. Percentuali, limite e fattori sono modificabili nell'editor della condizione e salvati nel JSON. Offline resta il recupero precedente (3% dichiarato per stadio, minimo 3); resta il recupero pari allo stadio a inizio turno.
''',
    contentEn: r'''
During online encounters, Vampirism automatically heals after the target confirms actual HP loss. The baseline remains 3% per stage I–XII, applied to HP actually lost; shields, temporary HP and overkill do not count. Editable defaults: Easy/Normal/Hard/Oculum factors 1.25/1/0.75/0.5, and a shared per-attack cap of 3% maximum HP per stage with the same factor. Multiple targets share the cap. Healing rounds down, minimum one only with actual HP damage and a sufficient cap, and never exceeds HP lost or missing HP. Existing healing modifiers still apply.
Duplicate or replayed receipts do not heal twice; healing reaches the attacking sheet even after switching sheets. Manual Hit reports during online combat grant no extra healing. Receipts without actual HP loss never fall back to declared damage. Percentages, cap and factors remain editable and persist in JSON. Offline healing and stage-based turn-start healing retain their prior rules.
''',
  ),
  ManualSection(
    titleIt: 'Padrone della Corruzione — 22 ottobre 2026',
    titleEn: 'Corruption Mastery — October 22, 2026',
    contentIt: r'''
La passiva Padrone della Corruzione aggiunge +50 punti percentuali alla resistenza alla Corruzione già presente: 20% diventa 70%, 50% diventa 100%. Il bonus si somma, non sostituisce la resistenza precedente. Rimane modificabile nell'editor della skill e conservato nel JSON, senza riscrivere le personalizzazioni salvate.
Il bersaglio di livello pari o superiore alla fonte può tentare di resistere usando Crepa o Fermezza (Volontà): deve pareggiare o superare il tiro dell'attacco o della pergamena. A livello pari subisce −3 a questo tiro; a livello superiore non ha questa penalità. A livello inferiore non può effettuare questo tentativo. La resistenza percentuale passiva resta distinta e valida.
Per il contagio, una resistenza totale del 70% riduce una probabilità iniziale del 100% al 30%; se la probabilità iniziale è 60%, la riduce al 18%. La probabilità non può scendere sotto zero; i valori salvati non vengono ridotti per applicare questo limite.
''',
    contentEn: r'''
Corruption Mastery adds 50 percentage points to existing Corruption resistance: 20% becomes 70%, and 50% becomes 100%. The bonus adds to existing resistance instead of replacing it. It remains editable in the skill editor and persists in JSON without overwriting saved customizations.
Targets at or above the source's level may resist with Crack or Steadfastness (Will), matching or exceeding the attack or scroll roll. Equal-level targets take −3 on this roll; higher-level targets have no penalty. Lower-level targets cannot attempt this roll. Passive percentage resistance remains separate.
For infection, 70% total resistance reduces an initial 100% chance to 30%; an initial 60% chance becomes 18%. Infection chance cannot fall below zero; saved resistance values are preserved when enforcing this limit.
''',
  ),
  ManualSection(
    titleIt: 'Turnistica online e condizioni — 22 ottobre 2026',
    titleEn: 'Online turn order and conditions — October 22, 2026',
    contentIt: r'''
La barra indica il fight della scheda, il partecipante attivo e le Reazioni in corso: «Fight I | Reazione/Reazione Veloce [Nome] | turno di [Nome]». Distingue la risorsa realmente spesa; una Reazione normale, veloce o gratuita non passa al turno seguente. La risoluzione o cancellazione della richiesta rimuove l'indicatore corrispondente. Le Azioni e i comandi del Master continuano a gestire l'avanzamento della turnistica.
Al primo giro di iniziativa ogni partecipante riceve 1 Azione di base e 1 Reazione veloce; la Reazione normale di base non è ancora disponibile. Nei giri successivi, a inizio di ogni nuovo giro completo, si rinnova 1 Reazione veloce. Quando arriva il turno personale nel nuovo giro, si rinnova 1 Reazione normale di base. Le Reazioni veloci scadono a inizio giro; le normali scadono al successivo turno personale. Ogni reazione scaduta e non usata dà +3 al prossimo tiro, fino a un bonus in attesa massimo di +12. Le Azioni si rinnovano al turno personale. Usare una Reazione non avanza il turno attivo. Attacco, Aiuta compagno e difesa usano l’Azione durante il proprio turno oppure una Reazione disponibile fuori turno. Il primo tiro di difesa è gratuito; contro lo stesso attacco è consentito al massimo un secondo tentativo, spendendo una Reazione prima dei danni. La Reazione gratuita ottenuta con doppia difesa può essere spesa anche per le altre azioni e utility di combattimento che accettano una risorsa di turno, non soltanto per il contrattacco. Le richieste consumano prima una Reazione gratuita disponibile; altrimenti usano l’Azione nel turno personale o una Reazione normale/veloce fuori turno. Il Master approva soltanto l’ingresso di nuovi partecipanti. Le Reazioni ottenute contro un nemico sono utilizzabili anche per utility.
Trasparenza: Velo +6 + livello. Invisibilità: Velo +18 + livello. Trasparenza non nasconde ai Gradi superiori: chi individua il corpo, anche automaticamente per Grado, ha +1 Difesa per proprio livello contro i suoi attacchi. Invisibilità di Grado 0–2 è vista da Grado 3+, 3–5 da 6+, 6–8 da 9+, 9–11 da 12+. Dopo una lettura utile di Percezione il bonus attivo si dimezza per difetto fino a fine fight. Bonus e durata restano modificabili nelle condizioni e nel JSON.
Corrosione acida è una condizione elementale: danno diretto alla Vita a fine turno, oltre Difesa e Scudi. Lo Sputatore Corrosivo applica 2/3/6 danni nelle forme ai livelli 0/3/6; durata 2/3/5/6 turni in Facile/Normale/Difficile/Oculum, modificabile. Il Drop ottiene +3 in Difficile e +6 in Oculum.
Doppio critico: 20 naturale e totale almeno doppio del tiro opposto; danni aggiuntivi 3×livello +6×Grado, minimo2, e +10 punti percentuali di fragilità. Doppia difesa: +9 al contrattacco di reazione contro l’attaccante. Medicina cura il totale del tiro, doppio sul critico naturale.
Il Goblin Kamikaze ha soltanto Esplosione suicida: CD iniziale 2 turni, Vita massima danni a ogni avversario corrente, 150% danni Scudo e morte del goblin. Come Occhio dei Caduti segue lo schieramento del proprietario. Costi, effetti, formule e ricariche restano modificabili.
Le schede ricevute dal Master sono copie online separate in fondo alle cartelle. Nome account o titolo possono cambiare senza creare un duplicato. L’aggiornamento periodico confronta le firme locali per evitare invii invariati.
''',
    contentEn: r'''
At the first initiative round, every participant receives one base Action and one Fast Reaction; the base normal Reaction is not available yet. At the start of each later full round, one Fast Reaction refreshes. At each participant’s own turn in that new round, one base normal Reaction refreshes. Unused Fast Reactions expire at the start of a round; unused normal Reactions expire at that participant’s next turn. Each expired unused reaction grants +3 to their next roll, up to a pending +12. Actions refresh on the participant’s turn. Spending a Reaction never advances the active turn. Attacks, help and defense use an Action on the owner’s turn or an available Reaction outside it. The first defense roll is free; one retry against the same attack may spend a Reaction before damage. Manual approval is needed only when a new participant joins. Granted enemy reactions can also fund utility.
Transparency adds 6 + level to Veil; Invisibility adds 18 + level. A useful Percezione reading halves the active bonus, rounding down, until the fight ends; a reading that reveals too little leaves it unchanged. Acid corrosion is an elemental condition dealing direct HP damage at end of turn. Hard/Oculum Drop bonuses are +3/+6. Natural twenty plus at least twice the opposing total is a double critical: 3×level +6×Grade damage, minimum2, and ten fragility percentage points. Double defense grants +9 to the reaction attack. Medicine heals its roll total, doubled on a natural critical.
The Kamikaze Goblin has only a suicide explosion: two initial cooldown turns, maximum-HP damage to every current opponent, 150 percent shield damage and death. Fallen Eyes follow their owner’s side. Effects, costs and durations remain editable and saved.
''',
  ),
  ManualSection(
    titleIt: 'Negozi e Potenziamento — 22 ottobre 2026',
    titleEn: 'Shops and Potentiation — October 22, 2026',
    contentIt: r'''
POTENZIAMENTO
Il vecchio nome «Oculum nei tiri fight» diventa «Potenziamento». Restano le soglie e i limiti di spesa già previsti per Livello e Grado. Ogni Oculum speso dà +3 al tiro; se il tiro è un attacco, dà anche +2 Danni per ogni punto speso.

RACCOGLITORE
Il Fabbro offre il Raccoglitore Grado 0/XII (Livello XII, Grado 0): tenendolo nell’inventario raddoppia i materiali da raccolta di Grado pari o inferiore al suo. È una passiva, non spende risorse durante la raccolta.

MERCATO NERO
L’Art «Archivio delle Scorie» costa inizialmente 18.000 Obser; «Colpo di Brace» costa 8.000 (+20 Danni Fuoco, recupero 3 turni) e «Taglio di Gelo» 12.000 (+30 Danni Ghiaccio, recupero 4 turni). Il banco può offrire Art Oculum e Skill del Monster Book, armi reliquia dei mostri, pergamene e al massimo tre pagine Monster Book diverse, dedicate a creature Erranti o Aberrazioni. Le pagine costano rispettivamente 56 e 90 Obser e rivelano nome, punto debole e resistenze. Le Art e le Skill mostro possono richiedere il livello attuale o fino a due livelli in più; sono acquistabili e conservano il requisito prima di essere utilizzabili. Anche i personaggi di livello 0 ricevono Skill e pergamene di Grado 0.
L’Ascension Dust è acquistabile fino a tre volte per Riposo Lungo: la prima dose costa 30–50 Obser, le successive aumentano di 10 e la terza non supera 69. Per l’Occhio dei Caduti del Mercato Nero, la base salvata è casuale fra 36 e 69 Obser al livello 0, cresce in linea retta fino a 115 al livello 10 e prosegue con lo stesso incremento oltre il 10. Si aggiungono statistiche totali del mostro ×2 e +25% per ogni blocco completo di 20 statistiche oltre il totale del personaggio. Per esempio, al livello 10 con 18 statistiche il prezzo prima del modificatore del mercante è 151 Obser.
Prezzi, effetti, forme, requisiti, quantità, formule e ricariche sono modificabili negli editor/offerta e conservati nel JSON.

INFERMIERA EROICA
• Cura delle ferite: 1 Obser ogni 10 HP mancanti; Scudo Oculum: 2 Obser per punto da ripristinare.
• I pacchetti singoli iniziali costano 1 Obser per +1 Volontà o +1 Materia, 2 per +15 HP temporanei o +10 Scudo normale, e 3 per +1 Oculum attuale. I limiti della scheda restano rispettati.
• Vitalium Grezzo, Vitalium Ridefinito e Fiala Depurante Eroica sono acquistabili e utilizzabili. Il Refull offre insieme ciò che manca di HP, statistiche attuali, Oculum, Scudo Oculum già sbloccato e integrità delle Art, e rimuove le condizioni negative. Il prezzo iniziale calcola HP a 1 Obser ogni 10, Scudo Oculum a 2 per punto, statistiche a 1 per punto, integrità Art a 1 ogni 10 e debuff a 5 ciascuno; applica il 15% di sconto e poi aggiunge il prezzo del buff.
• Il Refull aggiunge gratuitamente +20 Scudo normale. All’apertura del banco il buff della prossima battaglia viene estratto fra +10%, +15%, +20%, +25% e +30% a Danni e Difesa; costa 1 Obser ogni 5 punti percentuali. Dura 9 turni in Facile, 6 in Medio, 3 in Difficile e 1 in Oculum.
• Con probabilità iniziale modificabile dell’1%, l’offerta dà invece +40% o +60% a Danni e Difesa e aggiunge gratuitamente Scudo pari a un quarto degli HP massimi del personaggio, arrotondato per difetto. Gli HP temporanei casuali hanno tre fasce modificabili: 1% di 5 × Livello, 2% della metà del massimale per eccesso e 5% della metà per difetto.

Il tasto Refull nella pagina Statistiche ripristina statistiche attuali, HP, Oculum e Scudo Oculum se già disponibile; non ricarica lo Scudo normale. Le quantità, probabilità, prezzi iniziali, buff, durate e formule del negozio sono salvati con l’offerta e restano modificabili.
''',
    contentEn: r'''
POTENTIATION
The former “Oculum in fight rolls” label becomes “Potentiation.” Existing Level and Grade unlock/spending limits remain. Each Oculum spent grants +3 to the roll; an attack also gains +2 Damage per point spent.

GATHERING COLLECTOR
The Blacksmith sells the Grade 0/XII Gathering Collector (Level XII, Grade 0). Keeping it in inventory doubles gathered materials whose Grade is equal to or below its own. It is passive and costs no resources while gathering.

BLACK MARKET
The Scoria Archive Art starts at 18,000 Obser; Ember Strike starts at 8,000 (+20 Fire damage, 3-turn cooldown) and Frost Cut at 12,000 (+30 Ice damage, 4-turn cooldown). The stall can offer Monster Book Oculum Arts and skills, monster relic weapons, scrolls, and up to three distinct Monster Book pages for Wandering Creatures or Aberrations. Pages cost 56 and 90 Obser respectively and reveal the name, weak point and resistances. Monster Arts and skills can require the current level or up to two levels more; they can be bought early but retain their unlock requirement. Level-0 characters can get skills and Grade-0 scrolls.
Black Market Fallen Eyes use a saved random base of 36–69 Obser at level 0, grow linearly to 115 at level 10, and continue at the same rate beyond level 10. Add twice the monster’s total stats and 25% for every full block of 20 stats above the character’s total. At level 10 with 18 stats, the price is 151 Obser before the merchant modifier.
Prices, effects, forms, requirements, quantities, formulas and cooldowns remain editable in the offer/editors and are saved in JSON.

HEROIC NURSE
• Wound treatment costs 1 Obser per 10 missing HP; Oculum Shield costs 2 per point restored.
• Initial single packages cost 1 Obser for +1 Will or +1 Materia, 2 for +15 temporary HP or +10 normal Shield, and 3 for +1 current Oculum, subject to sheet limits.
• Raw Vitalium, Refined Vitalium and the Heroic Cleanser can be bought and used. Refull restores missing HP, current stats, Oculum, unlocked Oculum Shield and Art integrity, and clears negative conditions. Initial pricing is 1 Obser per 10 HP, 2 per Oculum Shield point, 1 per missing stat point, 1 per 10 Art integrity, and 5 per negative condition; apply a 15% discount, then add the buff price.
• Refull grants +20 normal Shield for free. When the shop opens, the next-battle damage/defense buff is rolled from +10%, +15%, +20%, +25% or +30%, costing 1 Obser per 5 percentage points. It lasts 9 Easy, 6 Normal, 3 Hard or 1 Oculum turn.
• At an initially editable 1% chance, the offer instead grants +40% or +60% damage and defense and free Shield equal to one quarter of the character’s maximum HP, rounded down. Random temporary HP gifts use three editable tiers: 1% of 5 × Level, 2% of half the maximum rounded up, and 5% of half rounded down.

The Stats page Refull restores current stats, HP, Oculum, and already-unlocked Oculum Shield; it does not restore normal Shield. Shop prices, values, chances, buffs, durations and formulas are saved with each offer and remain editable.
''',
  ),
  ManualSection(
    titleIt: '1. Fondamento di Oculum',
    titleEn: '1. Core of Oculum',
    contentIt: r'''
Maestria (conferma 19 ottobre 2026): i primi sei punti dei Sottotratti richiedono 100/200/350/500/700/850 EXP; poi sempre 1000. VC, CM e Aiuta compagno richiedono 250/500/750, poi 1000; Iniziativa 200/400/600/800, poi 1000. Si contano solo i punti guadagnati tramite Maestria, con avanzo conservato. Punti base, assegnazioni manuali e buff non anticipano le soglie. Il guadagno EXP per tiro resta legato alla difficoltà.

I Sottotratti in sé si possono sempre usare: le soglie di Maestria regolano i progressi e i benefici della Maestria, non sbloccano il permesso di effettuare il tiro. In combattimento i sottotratti utilizzabili come attacco o difesa restano selezionabili anche nei salvataggi precedenti; Strategia è proposta anche fra le difese.

Quando usi Manifestazione del Potere per attaccare con totale almeno +6, aggiungi +3 danni per ogni tuo livello a ciascun bersaglio colpito. Negli attacchi multipli il bonus si applica per bersaglio, insieme agli altri bonus piatti.

Aiuta compagno: scegli l'alleato prima del tiro. Il totale, anche negativo, resta come aiuto per il suo prossimo tiro, compare nella formula e nel log e si consuma una volta. Online scegli fra i partecipanti vivi dello scontro; offline fra le altre schede locali. Per gli attacchi multipli scegli i bersagli entro i limiti della tecnica: ognuno risolve la propria difesa ed i propri danni, mentre costo e cooldown della tecnica si pagano una volta.

In Oculum il potere passa dagli occhi. Un occhio può custodire un ricordo, portare i segni di un trauma o dare forma a ciò che desideri. Le sue capacità si intrecciano con la storia di chi lo possiede.

La scheda descrive il personaggio attraverso quattro statistiche: Resilienza, Volontà, Materia e Oculum. Le usi in combattimento e nelle altre scene. Prima di tirare, racconta che cosa vuoi fare: se il modo in cui agisci lo giustifica, puoi proporre un uso diverso dal solito della tua statistica.
''',
    contentEn: r'''
Oculum is a world where strength is not measured by muscles or by the number of allies, but by the power of the eyes.

Subtraits can always be used. Mastery thresholds govern Mastery progress and benefits; they do not unlock permission to roll the subtrait. Combat-eligible subtraits remain selectable for attack or defense, including in older saves; Strategy is also offered as a defense roll.

When Manifestazione del Potere is used as an attack with a total of at least +6, add +3 damage per character level to each target hit. For multi-target attacks the bonus applies to each target, like other flat bonuses.

Your eye carries traces of what you have lived through.

Eyes are identity, power, memory, trauma, will, and fate. Every individual is defined by four main stats:

• Resilience
• Will
• Materia
• Oculum

Each stat can also be used creatively in roleplay, if the scene justifies it.
''',
  ),

  ManualSection(
    titleIt: '2. Resilienza',
    titleEn: '2. Resilience',
    contentIt: r'''
La Resilienza misura quanto riesci a sopportare: una ferita, la fatica di un viaggio, uno sforzo mentale o spirituale. Da questa statistica dipende la tua Vita massima.

Vita massima = Resilienza × (10 + Grado ×5).

Quando la Resilienza raggiunge valori molto alti, usa queste equivalenze:
• 100 Resilienza = 1 Vera Resilienza;
• 10 Vera Resilienza = 1 Resilius;
• 10 Resilius = 1 Resilium.
''',
    contentEn: r'''
Resilience represents physical, mental, and spiritual endurance.

Main effect:
• maximum health is Resilience x (10 + Grade x5).

Higher Resilience scale:
• 100 Resilience = 1 True Resilience
• 10 True Resilience = 1 Resilius
• 10 Resilius = 1 Resilium

Resilience is not only “how much health you have”.
It is how much you can remain standing when body, mind, or soul are under pressure.
''',
  ),

  ManualSection(
    titleIt: '3. Volontà',
    titleEn: '3. Will',
    contentIt: r'''
Usi Volontà per sostenere un attacco, imporre la tua presenza e continuare ad agire sotto pressione. In una scena può esprimersi come determinazione, forza d’animo o capacità di affrontare qualcuno.

In scheda, Volontà potenzia l’attacco e contribuisce alla Difesa insieme a Materia. Ogni 3 punti aumentano il tiro d’attacco; ogni punto permette inoltre di trasportare 3 kg di inventario.
''',
    contentEn: r'''
Will represents determination, offensive pressure, inner strength, and the ability to impose yourself.

Main effects:
• empowers attacks;
• contributes to half of Defense;
• every 3 points increases the attack roll;
• every 1 point of Will equals 3 kg of carrying capacity.

Will is the stat of those who continue when they should stop.
In combat, it becomes pressure.
In roleplay, it becomes presence.
In pain, it becomes inner resistance.
''',
  ),

  ManualSection(
    titleIt: '4. Materia',
    titleEn: '4. Materia',
    contentIt: r'''
Materia entra in gioco quando contano il corpo, la precisione e il lavoro delle mani. La usi per forgiare, costruire, maneggiare un oggetto, reggere un impatto o eseguire un gesto tecnico.

Contribuisce alla Difesa insieme a Volontà. Ogni 2 punti aumentano la CM e ogni 5 punti aumentano l’Iniziativa.
''',
    contentEn: r'''
Materia represents body, technique, structure, precision, and the ability to give shape to things.

Main effects:
• contributes to half of Defense;
• every 2 points increases CM;
• every 5 points increases Initiative.

Materia is useful for:
• physical resistance;
• forging;
• crafting;
• manipulating objects;
• enduring impacts;
• technical or material actions.

Materia is what makes will become real.
''',
  ),

  ManualSection(
    titleIt: '5. Oculum',
    titleEn: '5. Oculum',
    contentIt: r'''
Oculum è il potere magico del tuo occhio. Alimenta le Arti e può manifestarsi attraverso magia, percezione, ricordi, rituali o trasformazioni, secondo le capacità del personaggio.

Ogni punto aumenta di +2 la potenza delle Arti. Puoi anche usare Oculum per aumentare il bonus di un tiro, quando riesci a spiegare come il tuo potere interviene nella scena.
''',
    contentEn: r'''
Oculum represents the personal magical power of the eye.

Main effects:
• each point increases the power of Arts by +2;
• it can be used in rolls to increase the “+”, if the scene justifies it.

Oculum is the most personal stat.
It does not only show how much magic you have, but how strongly your eye can impose your existence on the world.

It can manifest as:
• eye power;
• magic;
• perception;
• fate;
• memory;
• ritual;
• transformation.
''',
  ),

  ManualSection(
    titleIt: '6. Crescita delle Statistiche',
    titleEn: '6. Stat Growth',
    contentIt: r'''
Quando sali di livello, guarda quali statistiche hai usato durante la storia. La crescita segue quelle azioni:
• +3 alla statistica più utilizzata;
• +2 alla seconda;
• +1 a ciascuna delle altre;
• +6 Scudo.

Per i tiri che non sono attacco o difesa, il bonus è Statistica / 2 + Livello + Grado ×6.

Per esempio, con Resilienza 20, livello 10 e Grado I tiri 1d20 + 26: 10 dalla statistica, 10 dal livello e 6 dal Grado.

CREARE UN MOSTRO

Nel tutorial e nel Monster Book scegli il livello: il Grado viene calcolato automaticamente con le soglie del capitolo 9. Ogni Grado raggiunto aggiunge punti al totale da distribuire:
• Mostro comune: +10;
• Mini-Boss: +12;
• Boss: +15.

La crescita per livello è di 9, 11 o 13 punti, rispettivamente. La generazione aggiunge i 3 punti per livello di compensazione dei Titoli già previsti. Un Boss di livello 30, Grado II, ha quindi 30 ×16 + 2 ×15 = 510 punti.

Senza peculiarità la distribuzione segue Resilienza, Volontà, Oculum, Materia in ordine decrescente. Senza Oculum Art i punti di Oculum vanno alle altre tre statistiche. Redistribuisci punti posseduti conserva il totale e varia le proporzioni della creatura senza inventare punti.

Al livello 0 si redistribuisce il totale delle statistiche base del Book, senza bonus di Grado. Per una creatura con poteri, la base minima è di 4 punti; senza poteri è di 3. I mostri già salvati conservano i propri valori.
''',
    contentEn: r'''
When a character levels up, growth follows what they truly used in the story.

At each level up:
• +3 to the most used stat;
• +2 to the second most used stat;
• +1 to all other stats;
• +6 Shield.

This makes growth narrative:
you do not become strong “randomly”; you become strong where you lived, fought, failed, endured, or insisted.

For rolls that are not attack or defense:
• the roll bonus is Stat / 2 + Level + Grade x6.

Example:
With 20 Resilience, level 10 and Grade I, roll 1d20 + 26.

Monster creation derives Grade from level. Each Grade adds 10 stat points for a common monster, 12 for a Mini-Boss and 15 for a Boss. Level growth is 9/11/13 points respectively, plus the existing 3-point Title compensation. A level 30, Grade II Boss therefore receives 510 points.

A creature with any Skill or Oculum Art receives Oculum. Resilience and Oculum take priority, with Will and Matter brought to useful thresholds. Without either power, distribute points among Resilience, Will and Matter only. Existing saved stats are preserved.
''',
  ),

  ManualSection(
    titleIt: '7. Valori di Combattimento',
    titleEn: '7. Combat Values',
    contentIt: r'''
Quando risolvi un’azione, questi valori ti dicono cosa tirare e quale soglia superare.

• DT, Difficoltà Tiro: la soglia di un’azione difficile.
• CM, Classe Materia: la soglia da superare per colpire un bersaglio.
• VC, Volontà Combattiva: il bonus principale al tiro d’attacco.

DT, CM, VC, Danno, Difesa, Iniziativa e tiri di statistica contano anche Livello + Grado ×6.

Iniziativa: 1d20 + Materia / 5 + Livello + Grado ×6.
Movimento: 30 + Materia / 6 metri, più gli eventuali bonus @Movimento.

Per il Danno totale somma danno base, bonus delle armi equipaggiate e Livello + Grado ×6. Puoi equipaggiare al massimo 3 + Grado ×5 armi. La più forte dà il proprio bonus completo; ogni altra arma dà un terzo del proprio bonus, arrotondato per difetto se ha sia livello sia Grado inferiori alla principale, altrimenti per eccesso. Arrotonda ciascuna secondaria separatamente e poi somma. Il bonus potenzia il danno inflitto senza richiedere un’aggiunta manuale della singola arma; i valori degli oggetti restano modificabili e salvati.

La Difesa parte da (Volontà + Materia) / 2 + Livello + Grado ×6. Si aggiungono i bonus Difesa e Scudo degli oggetti equipaggiati che proteggono.
''',
    contentEn: r'''
DT = Roll Difficulty.
It is the threshold to overcome in order to succeed at a difficult action.

CM = Materia Class.
It is the threshold to overcome in order to hit a target.

VC = Combat Will.
It is the main “+” to attack.

DT, CM, VC, Damage, Defense, Initiative, and stat rolls also count:
• Level;
• Grade x6.

Initiative:
• 1d20 + Materia / 5 + Level + Grade x6.

Movement:
• 30 + Materia / 6 meters;
• @Movement bonuses are added to the final result.

Total damage:
• counts base damage;
• counts the equipped weapon bonus;
• counts Level + Grade x6;
• equip at most 3 + Grade ×5 weapons. The strongest contributes its full damage bonus. Each secondary contributes one third, rounded down if both its level and Grade are lower than the main weapon, otherwise rounded up; round each secondary separately before adding.

Defense:
• (Will + Materia) / 2 + Level + Grade x6.
''',
  ),

  ManualSection(
    titleIt: '8. Gradi',
    titleEn: '8. Grades',
    contentIt: r'''
Raggiungi un nuovo Grado quando arrivi alla soglia di livello indicata nel capitolo seguente. A ogni passaggio ottieni +36 Scudo e +1 Scudo Critico.

Puoi inoltre livellare un numero di Titoli pari al Grado raggiunto, scegliendo soltanto quelli già evoluti. Questo passaggio è la riforgiatura: il Titolo riceve una nuova quest, può sviluppare nuove Skill e prosegue in una forma legata alle tue azioni e a ciò che vuoi ottenere.

Per i punti statistica dei mostri usa il bonus del loro tipo: +10 per comune, +12 per Mini-Boss e +15 per Boss a ogni Grado.
''',
    contentEn: r'''
Grade represents a jump in scale.

When you reach a new Grade:
• you gain +36 Shield;
• you gain +1 Critical Shield;
• you may level a number of Titles equal to the Grade reached;
• you may only level Titles that are already evolved.

Leveling an already evolved Title means reforging it.

A reforged Title:
• receives a new quest;
• continues beyond its previous form;
• may gain new skills;
• evolves based on your will and your actions.

The new quest ties this growth to what your character does next.
''',
  ),

  ManualSection(
    titleIt: '9. Soglie dei Gradi',
    titleEn: '9. Grade Thresholds',
    contentIt: r'''
Leggi la colonna normale per un personaggio o un mostro senza Rebirth. Se hai effettuato il Rebirth, usa la seconda soglia. Sotto la prima soglia sei Senza Grado.

• Grado I — livello 10 / Rebirth 8
• Grado II — livello 30 / Rebirth 20
• Grado III — livello 40 / Rebirth 30
• Grado IV — livello 50 / Rebirth 40
• Grado V — livello 60 / Rebirth 50
• Grado VI — livello 70 / Rebirth 60
• Grado VII — livello 80 / Rebirth 70
• Grado VIII — livello 90 / Rebirth 80
• Grado IX — livello 100 / Rebirth 90
• Grado X — livello 120 / Rebirth 110
• Grado XI — livello 150 / Rebirth 130
• Grado XII — livello 200 / Rebirth 190

Per esempio, un mostro di livello 29 è di Grado I. Al livello 30 passa al Grado II; il Grado III arriva al livello 40.
''',
    contentEn: r'''
Normal thresholds and Rebirth thresholds:

• Grade I — level 10 / Rebirth 8
• Grade II — level 30 / Rebirth 20
• Grade III — level 40 / Rebirth 30
• Grade IV — level 50 / Rebirth 40
• Grade V — level 60 / Rebirth 50
• Grade VI — level 70 / Rebirth 60
• Grade VII — level 80 / Rebirth 70
• Grade VIII — level 90 / Rebirth 80
• Grade IX — level 100 / Rebirth 90
• Grade X — level 120 / Rebirth 110
• Grade XI — level 150 / Rebirth 130
• Grade XII — level 200 / Rebirth 190
''',
  ),

  ManualSection(
    titleIt: '10. Titoli del Fato Evoluti',
    titleEn: '10. Evolved Fate Titles',
    contentIt: r'''
Una volta al giorno puoi richiamare il potere di un Titolo del Fato evoluto. Scegli un momento in cui il significato di quel Titolo riguarda ciò che stai facendo.

Puoi aumentare il tiro di +1d10 oppure ottenere un Critico spirituale: dopo aver completato un tiro molto difficile, lo trasformi in un critico assicurato con ritiro.

Il Titolo resta fissato al personaggio, ma perde temporaneamente l’evoluzione per 9 ore.

Per esempio, [Saikai, L’Ultima Risorsa] riguarda la dedizione a finire ciò che si è iniziato. Può sostenere un ultimo atto anche da morto, per portare a termine il compito e raccoglierne i frutti.
''',
    contentEn: r'''
Each day you may use one evolved Fate Title.

When you use it:
• for 9 hours it temporarily loses its evolution;
• it still remains fixed to the character;
• the use must be justified by the scene.

You may use it for one of these effects:

1. Push the roll
• increase the roll by +1d10.

2. Spiritual critical
• if you complete a very difficult roll, you may turn it into a guaranteed critical with reroll.

Choose a moment that fits the meaning of the Title.

Example:
[Saikai, The Last Resource] is a Fate Title tied to dedication in finishing things.

It may be used to perform one final act even while dead:
complete the task and collect its fruits.
''',
  ),

  ManualSection(
    titleIt: '11. Moltiplicatori',
    titleEn: '11. Multipliers',
    contentIt: r'''
Somma i bonus percentuali prima di applicarli al valore di partenza.

Con +50% e +25% ottieni un unico bonus del 75%: 100 danni diventano 175. Non moltiplicare prima per 1,5 e poi per 1,25.
''',
    contentEn: r'''
General multiplier rule:

• all multipliers are added together;
• the result is applied at the end.

Apply the combined percentage once to the starting value.

Simple example:
If you have two multiplier bonuses:
• +50%
• +25%

You do not do:
damage × 1.5 × 1.25

You do:
damage +75%

So:
100 damage becomes 175 damage.
''',
  ),

  ManualSection(
    titleIt: '12. Danni, Resistenze e Fragilità',
    titleEn: '12. Damage, Resistances and Fragilities',
    contentIt: r'''
Risolvi il danno in questo ordine. Le capacità che ignorano Difesa o Scudi saltano soltanto il passaggio indicato dal loro effetto:

1. Parti dal danno in arrivo.
2. Applica la Difesa.
3. Applica resistenze, fragilità o rigenerazioni.
4. Applica eventuali moltiplicatori sommati.
5. Se hai Scudo Critico attivo, dimezza il danno finale.
6. Il danno colpisce in ordine:
   Scudo Oculum → Scudo → HP Temporanei → HP.

Il valore effettivo di ogni riserva di Scudo dipende dalla difficoltà:
• Facile: Scudo ×1,5, arrotondato per difetto. Il punto extra compare quindi ogni 2 punti Scudo.
• Normale: Scudo ×1.
• Difficile: Scudo ×0,5, arrotondato per eccesso.
• Oculum: Scudo ×0,2, arrotondato per difetto.
Questa conversione determina quanto danno assorbono Scudo e Scudo Oculum, senza aumentare i punti mostrati sulla scheda.

Ogni nuova scheda parte con 3 Ispirazioni, 2 Super Ispirazioni e 1 Ispirazione Oculum. La prima volta che quella scheda viene impostata su Facile riceve inoltre +5 Scudo; il premio non viene ripetuto tornando nuovamente a Facile.

Da Difficile si attiva la Sfortuna, controllata separatamente per ogni danno ricevuto:
• Difficile: 1% che il danno diventi critico e 2% che infligga +50% danni allo Scudo normale.
• Oculum: 3% che il danno diventi critico e 5% che infligga +100% danni sia allo Scudo sia allo Scudo Oculum.
I due controlli di Sfortuna sono indipendenti e, quando si attivano, vengono dichiarati nel log del danno.

Ogni danno può inoltre essere completamente parato dall'Oculum attuale. Quando accade, il log racconta che il tuo Oculum si concentra nel punto di impatto per difenderti. Su Normale ogni punto fino a 5 aggiunge 0,1%: 1 punto vale 0,1% e 5 punti valgono 0,5%. Dopo il quinto punto la crescita rallenta: il successivo +0,1% richiede 2 punti, quello dopo 3 punti, poi 4 e così via. La probabilità risultante viene moltiplicata per ×1,5 su Facile, ×1 su Normale, ×0,5 su Difficile e ×0,2 su Oculum.

Solo dopo una parata riuscita viene controllata la dispersione. Può essere perso al massimo 1 Oculum attuale. La probabilità cresce con l'Oculum posseduto ed è maggiore su Difficile e Oculum, ma i primi 20 punti sono protetti da una crescita lenta: a 20 Oculum la dispersione è 2% su Facile, 4% su Normale, 7% su Difficile e 10% su Oculum. Oltre 20 cresce più rapidamente, con un limite massimo del 75%.

Un danno critico aggiunge prima un bonus che dipende dalla difficoltà e dal livello del nemico, selezionati nella finestra aperta dal pulsante Critico:
• Facile: +3 danni per livello del nemico
• Normale/Medio: +2 danni per livello del nemico
• Difficile: +1 danno per livello del nemico
• Oculum: +1 danno ogni due livelli del nemico, arrotondato per difetto
Poi il critico peggiora di uno stadio Resistenze, Normale o Fragilità prima di applicare Difesa e Scudi.

Resistenze:
• Leggera: -10%
• Normale: -25%
• Alta: -50%
• Semi Perfetta: -75%
• Impenetrabile: -90%
• Immunità: -100%

Fragilità:
• Bassa: +10%
• Normale: +25%
• Alta: +50%
• Estrema: +75%
• Assoluta: +90%
• Distruttiva: +100%
• Semi Letale: +250%
• Letale: +500%

Rigenerazioni:
• Leggera: cura 10%
• Normale: cura 25%
• Alta: cura 50%
• Molto Forte: cura 75%
• Semi Perfetta: cura 90%
• Perfetta: cura 100%

LO SCHIANTO

I metri di volo sono pari alla differenza positiva tra la Volontà di chi attacca e quella del bersaglio. Una Skill può aumentare questa distanza. Schianto è un sottotratto di Volontà: il suo bonus è metà Volontà + Livello. Può essere usato per scagliare un nemico contro una parete o gettarlo da un’altura. Quando usi Schianto, il danno è il tuo Danno + metà Volontà + durezza della superficie.

Quando un attacco ti scaglia in volo e colpisci una parete o un ostacolo, il danno da schianto dipende dai metri percorsi e dalla solidità della superficie:
• Muri e strutture fragili: danno = metri percorsi ÷ 2.
• Muri ordinari: danno = metri percorsi.
• Muri rinforzati o armati: danno = metri percorsi × 2.

Puoi riprendere il controllo da un volo forzato lungo fino a un numero di metri pari al tuo Livello, anche all'ultimo istante prima dell'urto. A Livello 50 puoi liberarti da un volo di 50 metri. Se la distanza supera il tuo Livello, non basta questa capacità a fermare lo schianto: più lontano vieni scagliato, maggiore è la forza dell'attacco subito e più alto deve essere il Livello necessario a contrastarla.

Se l'impatto avviene, usa tutta la distanza percorsa, senza sottrarre il Livello. Un volo di 60 metri infligge 30 danni contro una struttura fragile, 60 contro un muro ordinario e 120 contro un muro rinforzato o armato.
''',
    contentEn: r'''
When you take damage, follow this order:

1. Start from incoming damage.
2. Apply Defense.
3. Apply resistances, fragilities, or regenerations.
4. Apply any summed multipliers.
5. If Critical Shield is active, halve the final damage.
6. Damage is applied in this order:
   Oculum Shield → Shield → Temporary HP → HP.

The effective value of each Shield pool depends on difficulty:
• Easy: Shield ×1.5, rounded down. The extra point therefore appears every 2 Shield points.
• Normal: Shield ×1.
• Hard: Shield ×0.5, rounded up.
• Oculum: Shield ×0.2, rounded down.
This conversion determines how much damage Shield and Oculum Shield absorb without increasing the points shown on the sheet.

Every new sheet starts with 3 Inspirations, 2 Super Inspirations, and 1 Oculum Inspiration. The first time that sheet is set to Easy it also receives +5 Shield; switching back to Easy later does not repeat the reward.

Misfortune becomes active from Hard difficulty and is checked separately for every incoming damage event:
• Hard: 1% for the damage to become critical and 2% for +50% damage to normal Shield.
• Oculum: 3% for the damage to become critical and 5% for +100% damage to both Shield and Oculum Shield.
The two Misfortune checks are independent and are declared in the damage log whenever they trigger.

Each incoming damage event rolls 1d1000 against the character's current Oculum: on Normal, current Oculum is the success threshold (for example, 20 Oculum gives 20/1000). Difficulty modifies that threshold, rounded to the nearest whole result: Easy ×1.5, Normal ×1, Hard ×0.5, and Oculum ×0.2. The threshold is capped at 1000. When the check succeeds, the log says that your Oculum concentrated to weaken the blow and reports the difficulty-adjusted chance. A separate 1d20 manifestation/control check still determines whether the parry reduces damage.

Dispersion is checked only after a successful parry. At most 1 current Oculum can be lost. Its chance increases with current Oculum and is higher on Hard and Oculum, but the first 20 points use a protected slow growth: at 20 Oculum the chance is 2% on Easy, 4% on Normal, 7% on Hard, and 10% on Oculum. Above 20 it grows faster, up to a maximum of 75%.

Before the usual damage steps, a critical hit adds a flat bonus based on campaign difficulty:
• Easy: +3 damage
• Normal: +5 damage
• Hard: +8 damage
• Oculum: +12 damage
The critical then worsens Resistance, Normal or Fragility by one stage before Defense and Shields apply.

Resistances:
• Light: -10%
• Normal: -25%
• High: -50%
• Semi-Perfect: -75%
• Impenetrable: -90%
• Immunity: -100%

Fragilities:
• Low: +10%
• Normal: +25%
• High: +50%
• Extreme: +75%
• Absolute: +90%
• Destructive: +100%
• Semi-Lethal: +250%
• Lethal: +500%

Regenerations:
• Light: heals 10%
• Normal: heals 25%
• High: heals 50%
• Very Strong: heals 75%
• Semi-Perfect: heals 90%
• Perfect: heals 100%

THE CRASH

Flight distance equals the positive difference between the attacker’s Will and the target’s Will. A Skill may increase this distance. Crash is a Will subtrait: its bonus is half Will + Level. Use it to throw an enemy against a wall or off a height. When using Crash, damage equals your Damage + half Will + surface hardness.

When an attack launches you through the air and you strike a wall or obstacle, crash damage depends on the distance travelled and the strength of the surface:
• Fragile walls and structures: damage = metres travelled ÷ 2.
• Ordinary walls: damage = metres travelled.
• Reinforced or armoured walls: damage = metres travelled × 2.

You can recover control from forced flight over a distance up to your Level in metres, even at the last moment before impact. At Level 50 you can break free from a 50-metre flight. If the distance exceeds your Level, this ability alone cannot prevent the crash: being thrown farther represents a stronger attack, requiring a higher Level to counter it.

If impact occurs, use the entire distance travelled without subtracting Level. A 60-metre flight causes 30 damage against a fragile structure, 60 against an ordinary wall, and 120 against a reinforced or armoured wall.
''',
  ),

  ManualSection(
    titleIt: '13. Arti, Skill e Titoli del Fato',
    titleEn: '13. Arts, Skills and Fate Titles',
    contentIt: r'''
Le Arti danno forma al potere dell’Oculum. La Prima Art è legata ai Titoli del Fato: li ottieni raggiungendo queste soglie con le sue Skill.

• Primo Titolo del Fato: prima Skill della Prima Art al livello 1.
• Secondo Titolo del Fato: seconda Skill della Prima Art al livello 2.
• Terzo Titolo del Fato: terza Skill della Prima Art al livello 3.

Conta la crescita dell’Art, quindi puoi ottenere un Titolo del Fato anche quando il livello del personaggio è ancora basso.

Le tecniche dei mostri vengono create sulla forma 0: nessuna forma è ancora in uso. Il nome descrive ciò che fai, per esempio «Testata con rinculo». Selezioni I, II o III quando vuoi attivare quella versione. Una Skill passiva rimane sempre equipaggiata.

Gli Occhi dei Caduti conservano le tecniche della creatura selezionata. La rarità permette di usare 0 Art per Comune, 1 per Non Comune, 2 per Raro e 3 per Oculum. Le altre rimangono conservate e diventano disponibili con il Reforge. Gli oggetti e i Titoli del proprietario non vengono copiati.
''',
    contentEn: r'''
Arts are the way Oculum power takes shape.

The first Art is special because it is connected to Fate Titles.

Fate Title thresholds:
• First Fate Title:
  first Skill of the first Art at level 1.

• Second Fate Title:
  second Skill of the first Art at level 2.

• Third Fate Title:
  third Skill of the first Art at level 3.

These Titles do not directly depend on character level.
They depend on the growth of the Art.

A character may still be low level, but gain a Fate Title if their Art truly awakens.
''',
  ),

  ManualSection(
    titleIt: '14. Risorse e Diario',
    titleEn: '14. Resources and Diary',
    contentIt: r'''
Gli Obser sono pietre o monete con inciso un occhio. Li spendi come valuta, ma possono anche essere un pegno, una ricompensa o un oggetto dal valore rituale, secondo lo scambio che rappresentano.

L’Ascension Dust è una polvere usata nella forgia, nei potenziamenti, nei rituali e nei cerchi magici. Può far ascendere oggetti, armi o poteri.

Nel Diario puoi annotare un ricordo, una promessa, una paura, un sogno o ciò che ti è rimasto di una sessione. Una pagina può dare Ispirazione quando racconta qualcosa che conta per il personaggio.
''',
    contentEn: r'''
Obser:
they are not simple money.
They are stones or coins engraved with an eye.

They can represent:
• currency;
• pledge;
• reward;
• memory of exchange;
• ritual value.

Ascension Dust:
a powder used to:
• forge;
• empower;
• ritualize;
• create circles;
• ascend items, weapons, or powers.

Diary:
writing a page may grant Inspiration if it has narrative weight.

A page can be:
• a memory;
• a promise;
• a fear;
• a confession;
• a dream;
• a wound;
• a thought after a session.
''',
  ),

  ManualSection(
    titleIt: '15. Riposo, Bisogni e Cenere',
    titleEn: '15. Rest, Needs and Ash',
    contentIt: r'''
La Cenere si accumula quando ti affatichi o trascuri i tuoi bisogni. Segnala in scheda per sapere quando lo sforzo comincia a pesare sui tiri e sulla coscienza.

Fatica:
• i primi 3 + Grado stati di Cenere non danno malus ai tiri;
• ogni stato di Cenere oltre quella soglia dà -1 a VC, CM, Iniziativa e tiri di statistica.

Svenimento da Cenere:
• fuori dal combattimento, da 3 Cenere in poi ogni aumento impone un tiro per restare cosciente;
• durante un combattimento i controlli avvengono solo a 6, 9, 12… Cenere; una prova fallita applica Vista appannata (-1 ai tiri fino alla fine del prossimo turno);
• solo da 12 Cenere in combattimento, dopo una prova fallita, c'è l'1% di probabilità di svenire;
• il tiro parte da 1d120 + Resilienza/3 + Livello + Grado x6;
• a ogni nuovo controllo il dado scende lungo la scala dei dadi dell'app, mentre la difficoltà è 20 + Cenere x3;
• se il tiro supera la difficoltà, resti cosciente e il log riporta che riesci a non svenire nonostante la fatica;
• fuori dal combattimento, se il tiro fallisce diventi Incosciente finché non usi Sveglia o una regola esplicita ti rimette cosciente;
• il dettaglio del tiro resta nei log completi e non appare come tiro centrale.

Puoi ottenere Cenere quando:
• non mangi;
• non bevi;
• non dormi;
• fai attività pesanti;
• forgi;
• raccogli, peschi o cacci;
• usi troppo potere sotto stress.

Dopo 3 sessioni senza mangiare, bere o dormire:
• -1 Resilienza temporanea;
• -1 Oculum temporaneo.

Un giorno senza cibo o acqua:
• +3 Cenere;
• -1 temporaneo casuale a una statistica.

Riposo breve:
• recupera 25% Cenere, minimo 1;
• recupera metà penalità temporanee;
• recupera metà stats spese per raccolta o creazione.

Riposo lungo:
• recupera 50% Cenere, minimo 3;
• recupera metà Resilienza negativa;
• recupera tutto Oculum negativo;
• recupera tutte le stats spese;
• porta gli HP ad almeno il 75% del massimale.
''',
    contentEn: r'''
Ash represents physical, mental, and spiritual exhaustion.

Fatigue:
• the first 3 + Grade Ash states do not penalize rolls;
• each Ash state beyond that threshold gives -1 to VC, CM, Initiative and stat rolls.

Ash fainting:
• outside combat, each increase from 3 Ash onward checks whether you remain conscious;
• in combat, checks happen only at 6, 9, 12… Ash; failure applies Blurred vision (-1 to rolls until the end of your next turn);
• only from 12 Ash in combat, a failed check has a 1% chance to cause unconsciousness;
• the roll starts at 1d120 + Resilience/3 + Level + Grade x6;
• at each new check the die moves down the app's die scale, while difficulty is 20 + Ash x3;
• if the roll beats the difficulty, you remain conscious and the log says you manage not to faint despite the fatigue;
• outside combat, a failed roll makes you Unconscious until Wake Up or an explicit rule restores consciousness;
• the roll detail stays in the full logs and does not appear as the central die roll.

You may gain Ash when:
• you do not eat;
• you do not drink;
• you do not sleep;
• you perform heavy activities;
• you forge;
• you gather, fish, or hunt;
• you use too much power under stress.

After 3 sessions without eating, drinking, or sleeping:
• -1 temporary Resilience;
• -1 temporary Oculum.

A day without food or water:
• +3 Ash;
• -1 temporary random stat.

Short rest:
• recovers 25% Ash, minimum 1;
• recovers half temporary penalties;
• recovers half stats spent for gathering or crafting.

Long rest:
• recovers 50% Ash, minimum 3;
• recovers half negative Resilience;
• recovers all negative Oculum;
• recovers all spent stats;
• brings HP to at least 75% of maximum.
''',
  ),
  ManualSection(
    titleIt: '16. Armi, EXP e Villaggi',
    titleEn: '16. Weapons, EXP and Villages',
    contentIt: r'''
Il bonus dell’arma dipende dal suo tipo:
- arma semplice: +5 danni;
- arma con Titolo: +10 danni;
- arma con Titolo gradato: +20 danni per Grado dell'arma.

Recupero da EXP:
- ogni 100 EXP realmente ottenuti recuperi 6 HP e 1 Oculum;
- i guadagni inferiori a 100 si accumulano e il resto prosegue verso la soglia successiva;
- il recupero non supera i massimi di HP e Oculum e continua a funzionare attraversando un level-up.

EXP da mostri:
- conta il livello superiore al tuo;
- conta le statistiche maggiori delle tue;
- ogni Grado del mostro superiore al tuo aggiunge x1.2;
- i Mini-Boss danno x1.3 EXP;
- i Boss danno x2 EXP;
- a fine scontro si tira il Drop di ciascun mostro ucciso presente nella turnistica e si distribuisce al party partecipante.

EXP da NPC:
- conta il livello superiore al tuo e le statistiche maggiori delle tue;
- la ricompensa va a te e a tutto il party;
- ogni Grado dell'NPC superiore al tuo aggiunge x1.3.

Villaggi:
- dopo 3 fight conviene visitare un villaggio o una taverna;
- ogni fight oltre il terzo senza visita dimezza ulteriormente l'EXP ottenuta.

Summon:
- i mostri evocati danno al massimo 5 + Grado EXP;
- la ricompensa vale una sola volta per evocazione;
- una Summon tua non dona EXP, salvo che il Fato la renda realmente ostile.
''',
    contentEn: r'''
Weapons:
- simple weapon: +5 damage;
- titled weapon: +10 damage;
- graded titled weapon: +20 damage per weapon Grade.

EXP recovery:
- every 100 EXP actually gained restores 6 HP and 1 Oculum;
- gains below 100 accumulate and any remainder carries toward the next threshold;
- recovery cannot exceed maximum HP or Oculum and continues across a level-up.

Monster EXP:
- count levels above yours;
- count stats higher than yours;
- each monster Grade above yours adds x1.2;
- Mini-Bosses grant x1.3 EXP;
- Bosses grant x2 EXP;
- at the end of the encounter, roll each killed monster's Drop from the initiative order and distribute it among participating party members.
- A natural 20 on a monster's Drop roll creates at most one Fallen Eye per kill. It keeps the defeated creature's body and techniques, falls back to its Monster Book preset if its sheet is unavailable, and is assigned once to a participant.

NPC EXP:
- count levels above yours and stats higher than yours;
- the reward goes to you and the whole party;
- each NPC Grade above yours adds x1.3.

Villages:
- after 3 fights, visit a village or tavern;
- each fight after the third without a visit halves gained EXP again.

Summons:
- summoned monsters grant at most 5 + Grade EXP;
- this reward applies once per summon;
- your own Summon grants no EXP unless Fate makes it truly hostile.
''',
  ),
  ManualSection(
    titleIt: '17. Critici, Fragilità ed EXP dei tiri',
    titleEn: '17. Criticals, Fragility and Roll EXP',
    contentIt: r'''
Guarda prima il risultato naturale del dado, poi applica il modificatore critico:
- ogni dado può crittare sul suo massimo naturale;
- 1 naturale è critico negativo;
- critico positivo: aggiungi metà dado + Livello + Grado x6 al tiro;
- critico negativo: togli metà dado + Livello + Grado x3 dal tiro.
- se il tiro nemico viene raddoppiato, quel tiro conta come critico positivo.

EXP dei tiri riusciti:
- la regola vale soltanto per i tiri di gioco su d20, non per il lanciatore separato da d2 a d120;
- il tiro deve riuscire dopo avere applicato bonus, malus e DT;
- con un risultato naturale di 18 ottieni 9 EXP;
- con un risultato naturale di 19 ottieni 10 EXP;
- con un 20 naturale, quindi un critico positivo, ottieni 20 + metà faccia: 30 EXP;
- il valore aggiunto all'EXP dipende dal dado naturale e non comprende alcun bonus.

Critico in Attacco:
- applichi una Fragilità nella zona bersagliata;
- aggiungi +5 danni.

Critico in Difesa:
- ottieni una Reazione contro il bersaglio che ti ha attaccato.

Critico in Iniziativa:
- ottieni una Reazione.

Catena di Fragilità:
- si parte da Fragilità Leggera al primo critico;
- ogni critico successivo nello stesso fight aumenta lo stadio;
- lo stadio massimo è Fragilità Letale;
- un colpo di sorpresa al punto debole può partire direttamente da stadi più alti.

Danno letale:
- con Fragilità Letale fai x6 danni (+500%); i bonus critici restano distinti.
''',
    contentEn: r'''
Base rule:
- each die can crit on its natural maximum;
- natural 1 is a negative critical;
- positive critical adds half die + Level + Grade x6 to the roll;
- negative critical subtracts half die + Level + Grade x3 from the roll.

EXP from successful rolls:
- this rule applies only to gameplay d20 rolls, never to the separate d2-d120 roller;
- the roll must succeed after bonuses, penalties and DT are applied;
- a natural 18 grants 9 EXP;
- a natural 19 grants 10 EXP;
- a natural 20, therefore a positive critical, grants 20 + half the die: 30 EXP;
- EXP uses the natural die result and never includes bonuses.

Attack Critical:
- apply Fragility to the targeted zone;
- add +5 damage.

Defense Critical:
- gain one Reaction against the attacker.

Initiative Critical:
- gain one Reaction.

Fragility chain:
- the first critical applies Light Fragility;
- each consecutive critical in the same fight increases the stage;
- the maximum stage is Lethal Fragility;
- a surprise attack against a weak point may start from higher stages.

Lethal damage:
- with Lethal Fragility, deal x6 damage (+500%); critical bonuses remain separate.
''',
  ),
  ManualSection(
    titleIt: '18. Cerchi Magici',
    titleEn: '18. Magic Circles',
    contentIt: r'''
Per tracciare un cerchio magico decidi a cosa serve, quale emozione lo sostiene e quale energia sei disposto a cedere. Lo attivi con polveri, Materia, Oculum o Varianti.

Creazione in 3 fasi:
1. Tipo: Difesa, Attacco, Alterazione, Potenziamento, Sigillo, Rito complesso.
2. Emozione: paura, colpa, rabbia, amore, determinazione, ambizione.
3. Energia consumata permanentemente: Oculum, Rune, Null, Resilienza, Materia, Volontà, Follia.

Per finalizzare il cerchio serve:
- una scroll magica da cui prendere una magia;
- oppure polveri alchemiche.

Se usi una scroll, una parte dell'effetto della scroll entra nel cerchio in forma indebolita.
Esempio: una scroll che dona +3 Volontà per alcuni turni può creare un cerchio di auto-rigenerazione con un piccolo bonus Volontà associato.
''',
    contentEn: r'''
Magic circles are activated with powders, Materia, Oculum, or Variants.

Creation has 3 phases:
1. Type: Defense, Attack, Alteration, Empowerment, Seal, Complex Rite.
2. Emotion: fear, guilt, anger, love, determination, ambition.
3. Permanently consumed energy: Oculum, Runes, Null, Resilience, Materia, Will, Madness.

To finalize the circle, use:
- a magic scroll to extract a spell;
- or alchemical powders.

If a scroll is used, part of the scroll effect enters the circle in weakened form.
Example: a scroll that grants +3 Will for a few turns can create a self-regeneration circle with a small linked Will bonus.
''',
  ),
  ManualSection(
    titleIt: '19. Open, Oculum e Sistema Plus',
    titleEn: '19. Opens, Oculum and Plus System',
    contentIt: r'''
Un’Open richiama il potere del personaggio per un effetto più ampio. Tieni conto dei suoi tempi di recupero:
- un’Open si può usare una volta ogni 3 ore;
- ogni nuova sessione riduce il tempo di 1 ora se sei alleato del Fato;
- il buff dell'Open rimane fino al recupero dell'Open;
- le Open Skill sono versioni ridotte usabili con pochi limiti;
- dopo l'uso dell'Open, le Open Skill collegate restano potenziate per 1 ora.

Ogni Open dei mostri comprende due capacità distinte. Quando attivi l’Open, il Buff Open si applica subito. La Skill Open ha un proprio pulsante e un proprio Cooldown: usarla non riattiva il buff né azzera il recupero dell’Open. Le nuove Skill Open dei mostri hanno un recupero iniziale di 3 turni; puoi modificarne effetto e durata nella scheda. Le capacità già personalizzate conservano i propri testi e tempi.

EXP di evoluzione:
- quando un Titolo sblocca la prima Open ricevi 25 EXP, una sola volta;
- il totale riconosciuto dal Titolo diventa 125 EXP quando possiede 2 Open e 175 EXP quando ne possiede 3;
- dalla terza Open in poi, ogni nuova Open aumenta il totale di 50 EXP;
- disattivare l'evoluzione, eliminare una Open o duplicare il Titolo non permette di riscuotere di nuovo l'EXP già assegnata.

Oculum:
- è l'energia dell'oculus, l'Occhio;
- serve per Oculum Art, cerchi magici e item specifici;
- si ricarica dormendo, riposando o con oggetti.

Sistema Plus:
- puoi spendere Oculum per aumentare l'esito di un tiro;
- puoi immettere 1 Oculum ogni 3 livelli;
- massimo 3 punti ogni 3 Gradi raggiunti;
- al livello 9 senza Grado hai già accesso a 3 punti;
- ogni punto speso così dona +3 ai tiri in fight.
''',
    contentEn: r'''
Opens:
- an Open can be used once every 3 hours;
- each new session reduces the time by 1 hour if you are allied with Fate;
- the Open buff lasts until the Open is recovered;
- Open Skills are reduced versions usable with few limits;
- after using the Open, linked Open Skills stay empowered for 1 hour.

Each monster Open has a Buff Open applied upon activation and a separate Skill Open with its own cooldown. New monster Open Skills start with a three-turn cooldown. Their effects and recovery times remain editable; existing custom abilities are preserved.

Evolution EXP:
- when a Title unlocks its first Open, you gain 25 EXP once;
- that Title's recognized total becomes 125 EXP at 2 Opens and 175 EXP at 3 Opens;
- from the third Open onward, each new Open increases the total by 50 EXP;
- disabling evolution, deleting an Open or duplicating the Title cannot award already claimed EXP again.

Oculum:
- it is the energy of the oculus, the Eye;
- it fuels Oculum Arts, magic circles, and specific items;
- it recharges through sleep, rest, or items.

Plus System:
- you may spend Oculum to increase a roll outcome;
- you may invest 1 Oculum every 3 levels;
- maximum 3 points every 3 reached Grades;
- at level 9 with no Grade, 3 points are already available;
- each point spent this way grants +3 to fight rolls.
''',
  ),
  ManualSection(
    titleIt: '20. Titoli, Razze e Art',
    titleEn: '20. Titles, Races and Arts',
    contentIt: r'''
Un Titolo racconta ciò che hai fatto o ciò che ti è accaduto. Per usarlo in scheda, scegli la categoria e compila benefici e limiti:
- categorie: Azione, Item, Fato, Apprendimento, Malanno/Benessere, Alchimia/Magia, Chaos, Attributo;
- ogni Titolo ha buff, Punto Cieco, Leggenda e possibile Titolo Evoluto;
- ogni 3 Titoli indossati se ne mostra uno, con priorità agli Evoluti;
- al Grado III, VI e IX ottieni uno slot Titolo aggiuntivo;
- i Titoli Evoluti possono essere livellati quando sali di Grado.
- in fight i Titoli non possono essere cambiati; ciò che e stato consumato o attivato resta comunque contato fino alla fine del fight.

Titoli del Fato:
- prima forma della prima skill: primo Titolo del Fato;
- seconda forma della seconda skill: secondo Titolo del Fato;
- terza forma della terza skill: terzo Titolo del Fato.

Titoli Attributo:
- danno da +1 a +3 ai tiri, fino a +6 se Evoluti, +7 se Reforgiati, +9 se Evoluti e Reforgiati;
- aumentano di +1 per Grado;
- massimale normale del Plus: 12;
- tre parole attivate dello stesso Titolo danno +25% al Plus.

Razze:
- la razza iniziale non occupa slot;
- in storia puoi ottenere altre 3 razze;
- ogni razza può avere 3 sottorazze;
- completare 12 Razze/Sottorazze rivela la vera identità e permette una terza Art.

Tipi di Art:
- Oculum, Illness, Emblem, Martial, Null, Rune, Defiled;
- ogni evoluzione di una Skill Art può consumare Oculum, Materia, Volontà, Resilienza oppure nessuna statistica;
- Min e Max stabiliscono quanto della statistica scelta può essere investito all'attivazione;
- le Rune Art hanno combo al 25%;
- le Rune Art arrivano alla IV forma e usano parole componibili;
- le Defiled Art hanno 5 stadi e la loro Open non esclude le altre.

Rune Art:
- una formula nasce scegliendo parole di Target, Verbo, Aspetto, Mod, Intensità, Durata e Trigger;
- Self / Ally e Pulse sono le prime parole obbligatorie; Intensità I e 1 azione sono sempre parole base;
- ogni Libro Runico insegna esattamente sei parole nuove e non viene consumato se non ce ne sono abbastanza;
- Intensità e Durata sono sequenziali: devi conoscere il grado precedente prima del successivo;
- il costo e la DT della formula sono la somma delle parole scelte;
- il master può aggiungere parole custom, con costo e DT propri, senza cancellare le parole ufficiali.
''',
    contentEn: r'''
Titles:
- categories: Action, Item, Fate, Learning, Illness/Wellness, Alchemy/Magic, Chaos, Attribute;
- each Title has buffs, a Blind Spot, Legend, and possible Evolved Title;
- every 3 equipped Titles reveal one, prioritizing Evolved ones;
- at Grade III, VI, and IX you gain one extra Title slot;
- Evolved Titles can be leveled when you gain Grade.
- during a fight, Titles cannot be changed; anything consumed or activated still counts until the fight ends.

Fate Titles:
- first form of the first skill: first Fate Title;
- second form of the second skill: second Fate Title;
- third form of the third skill: third Fate Title.

Attribute Titles:
- grant +1 to +3 to rolls, up to +6 if Evolved, +7 if Reforged, +9 if both;
- increase by +1 per Grade;
- normal Plus cap: 12;
- three activated words from the same Title grant +25% to the Plus.

Races:
- the starting race uses no slot;
- during the story you can obtain 3 more races;
- each race can have 3 subraces;
- completing 12 Races/Subraces reveals true identity and allows a third Art.

Art types:
- Oculum, Illness, Emblem, Martial, Null, Rune, Defiled;
- each Art Skill evolution may consume Oculum, Matter, Will, Resilience, or no stat;
- Min and Max define how much of the selected stat may be invested on activation;
- Rune Art combos count as 25%;
- Rune Arts reach form IV and use modular words;
- Defiled Arts have 5 stages and their Open does not exclude the others.

Rune Art:
- a formula is built by choosing Target, Verb, Aspect, Mod, Intensity, Duration and Trigger words;
- Self / Ally and Pulse are the first required words; Intensity I and 1 action are always base words;
- each Runic Book teaches exactly six new words and is not consumed if fewer are available;
- Intensity and Duration are sequential: you must know the previous grade before the next one;
- formula cost and DT are the sum of the selected words;
- the master can add custom words with their own cost and DT without deleting official words.
''',
  ),
  ManualSection(
    titleIt: '21. Minigioco, Skin e Shortcut',
    titleEn: '21. Minigame, Skins and Shortcuts',
    contentIt: r'''
Durante uno scontro in Oculum Dungeon, parti da questi comandi:
- Attacca apre Azioni Attacco: VC, CM, AoE e Tecnica Art;
- Difenditi apre Azioni Difesa: Difesa, Counter, Fuga e Riposo fuori fight;
- Azioni Art apre Skill Oculum, Skill Reliquia, Open Reliquia e Titoli Run;
- Achievement e informazioni apre achievement, alleati, skin, pagina sprite e sblocchi.

Slot Art:
- un personaggio normale può usare fino a 2 Art;
- un Oculiano con 2 Oculum può arrivare a 3 Art.

Sprite vivi:
- fuori fight possono mostrarsi barre grandi/classiche;
- in fight vivo si usano mini barre compatte;
- arma e armatura sono indicate anche da badge W/A;
- la skin Pawn non mostra arma o armatura per evitare bug visivi.

Skin:
- le skin base sono sempre disponibili;
- alcune skin extra si sbloccano con achievement, reliquie o costumi;
- Pawn può diventare skin quando la reliquia Pawn e sbloccata;
- skin Oculiane e simili possono arrivare da achievement e costumi Oculiani.

Probabilità di vittoria:
- conta HP, Scudo, alleati, Pawn, danno, difesa, Oculum, Skill Oculum e Open disponibili;
- e una stima rapida da interfaccia, non sostituisce le scelte del fight.

Versione compatta:
- su telefono i comandi sono raggruppati in shortcut;
- su schermi larghi la fight viva può mostrare più dettagli senza rompere la disposizione.
''',
    contentEn: r'''
Fight-style actions:
- Attack opens Attack Actions: VC, CM, AoE, and Art Technique;
- Defend opens Defense Actions: Defense, Counter, Flee, and out-of-fight Rest;
- Art Actions opens Oculum Skill, Relic Skill, Relic Open, and Run Titles;
- Achievements and info opens achievements, allies, skins, sprite page, and unlocks.

Art slots:
- a normal character can use up to 2 Arts;
- an Oculian with 2 Oculum can reach 3 Arts.

Live sprites:
- out of fight, large/classic bars may be shown;
- in live fight, compact mini bars are used;
- weapon and armor are also marked with W/A badges;
- Pawn skin does not display weapon or armor to avoid visual bugs.

Skins:
- base skins are always available;
- some extra skins unlock through achievements, relics, or costumes;
- Pawn can become a skin when the Pawn relic is unlocked;
- Oculian-like skins may come from Oculian achievements and costumes.

Win chance:
- counts HP, Shield, allies, Pawn, damage, defense, Oculum, Oculum Skills, and available Opens;
- it is a quick UI estimate, not a replacement for fight choices.

Compact version:
- on phones, commands are grouped into shortcuts;
- on wide screens, the live fight can show more detail without breaking layout.
''',
  ),
  ManualSection(
    titleIt: '22. Guida app: scheda, zone e click',
    titleEn: '22. App guide: sheet, areas and taps',
    contentIt: r'''
Apri la Scheda per leggere le risorse e agire. Usa Modifica rapida per correggere un valore durante la sessione; le pagine dedicate raccolgono invece Titoli, Art, Skill e inventario.

MODALITA INTERFACCIA

- Modalità Mobile:
  usa una colonna compatta. Le cose più importanti stanno prima: Centro partita, immagine, identità, razza, Oculum, EXP, Vita, Danno/Cura, Combattimento, riepilogo, statistiche e valori modificabili.

- Modalità Desktop:
  usa colonne diverse. A sinistra trovi identità, immagine, razza, Oculum ed EXP. Al centro trovi comandi, combattimento, vita, danno, statistiche e modifiche. A destra trovi borsa rapida, Art/Skill modificate, party e risultato dadi.

- Modalità Veloce:
  nasconde spiegazioni e blocchi ripetuti. Le funzioni non spariscono: restano raggiungibili da Modifica rapida, Cerca, menu pagina e tendine.

Puoi cambiare Mobile/Desktop e Veloce dalle Impostazioni.

COMBATTIMENTO E CENTRO PARTITA

Nel Centro partita trovi le azioni più frequenti:

- HP: porta alla zona vita.
- Scudo: porta al campo Scudo.
- VC: porta ai valori legati a Volontà e attacco.
- CM: porta ai valori legati a Materia e soglia per colpirti.
- Movimento: indica quanti metri puoi muovere, pari a 30 + Materia / 6.
- Danno: apre la zona Danno/Cura.
- Difesa: porta al bonus difesa o ai valori difensivi.
- Tira VC e Tira CM: tirano subito senza cercare la statistica.
- Modifica: apre Modifica rapida.

Puoi tornare al Centro partita dalla pagina Scheda.

IMMAGINE E ASPETTO

La zona immagine e il riquadro grande con l'occhio.
Da qui puoi:

- aggiungere una immagine;
- trascinare un file immagine da desktop;
- aprire il crop;
- rimuovere l'immagine;
- vedere tipo scheda, razza visibile e numero scheda.

Se annulli il crop, l'immagine precedente resta salva.

IDENTITA

Identita contiene:

- Tipo scheda: Personaggio, Mostro, NPC, Boss o Alleato.
- Nome Scheda.
- Livello.
- Grado.
- Rebirth.

Livello e Grado sono importanti per quasi tutto: VC, CM, tiri statistica, danni, difesa e iniziativa contano Livello + Grado x6.

RAZZA E TRATTI RAZZIALI

La zona Razza mostra la razza visibile.
Se il campo Razza è vuoto, l'app usa il primo Tratto Razziale creato nella pagina Titoli.

Nella creazione Titoli:

- Tipo = Tratto razziale;
- Tipo = Razza;
- Tipo = Sottorazza;

vanno automaticamente nei Tratti Razziali, non nei Titoli normali.
I Tratti Razziali hanno 13 slot totali tra razze e sottorazze e funzionano come titoli veri per i bonus.

OCULUM

La zona Oculum mostra Oculum attuale e massimo.
Puoi:

- aggiungere o togliere Oculum;
- resettare al massimo;
- scrivere il valore attuale manualmente.

Oculum alimenta Art, Open, Skill Oculum e comandi magici.

EXP

La zona EXP serve per aggiungere esperienza senza calcoli manuali.
Scegli la fonte:

- Nemico normale: x1.
- Mini-Boss: x1.3.
- Boss: x2.

Se il nemico ha Grado superiore al tuo, l'app applica il moltiplicatore previsto.
L'anteprima ti fa capire cosa verrà aggiunto prima di applicarlo.

VITA, SCUDO E DANNO/CURA

Vita mostra HP, HP temporanei, Scudo e Scudo Critico.
L'ordine pratico e:

1. Lo Scudo assorbe prima.
2. Gli HP temporanei proteggono gli HP reali.
3. Gli HP reali sono la vita effettiva.
4. Lo Scudo Critico dimezza il danno finale mentre è attivo.

Danno/Cura serve per inserire un numero e applicarlo.
Il danno usa il tipo dominante: Fuoco, Gelo, Taglio, Maledizione, Malanno o qualunque tipo scritto nei comandi.
Se scrivi un tipo nuovo in un comando, l'app lo rileva e lo rende colorabile dalle Impostazioni.
Il pulsante Refull Vita riporta gli HP attuali al massimo, rimargina HP Temp dinamici e Scudo Oculum. Lo Scudo normale consumato resta consumato e lo Scudo Critico non cambia.

TIPI DANNO LIBERI

Nel campo Tipo danno / protezione puoi scrivere liberamente.
Esempi validi: Cenere, Malanno, Maledizione, Gravità, Sangue Antico.
Premendo Tab l'app prova a completare un tipo noto, ma un tipo nuovo resta comunque valido e viene mostrato nei colori finché esiste in arma, protezione, titolo, art o skill.

SKILL E COMANDI @

Le Skill scritte non sono solo testo.
Se sono equipaggiate, i comandi scritti in Nome, Tipo, Costo, Cooldown o Descrizione entrano nei calcoli.

Esempi:

- @Danni+15 Malanno aggiunge danno Malanno.
- @Difesa+10 Cenere aggiunge difesa Cenere.
- @Volonta+3 modifica Volontà mentre la skill resta equipaggiata.
- @Materia+2 modifica Materia mentre la skill resta equipaggiata.
- @VC+1 e @CM+1 aggiungono bonus diretti a VC e CM.
- @Movimento+3 aggiunge metri al movimento.
- @Stats+1 o @AllStats+1 aumentano Resilienza, Volontà, Materia e Oculum.
- @OtherStats+1 o @AltreStats+1 aumentano le altre statistiche rispetto alla risorsa/stat consumata dal trigger.
- @Difesa-¼ applica un malus minimo di 1 anche se la frazione è piccola.
- @Danni+1OnHit si attiva quando sei stato colpito e hai HP sotto il massimo.
- @Vol+1=-10HP aggiunge +1 Volontà per ogni 10 HP persi.
- @HP+1=Vol-1 aggiunge HP quando la Volontà attuale scende rispetto al valore base.
- @HP-10=Stats+1 significa: ogni 10 HP persi, +1 a Volontà, Materia e Oculum, ma non a Resilienza per evitare loop sugli HP.
- @Vol-1=AltreStats+1 significa: ogni Volontà persa, +1 a Resilienza, Materia e Oculum, ma non a Volontà.
- La sezione Buff/Malus @ in Riposo/Stati accetta questi stessi comandi senza creare un Titolo.

COMBATTIMENTO

La zona Combattimento mostra:

- VC: bonus di attacco.
- CM: soglia da superare per colpirti.
- Iniziativa.
- Movimento.
- Danno.
- Difesa.
- Bonus Livello/Grado.

Toccare un riquadro apre la modifica o la zona collegata.
I pulsanti Tira VC e Tira CM tirano subito.

RIEPILOGO RAPIDO

Il Riepilogo rapido serve per leggere la scheda in pochi secondi.
Mostra HP, Temp, Scudo, Scudo Critico, Karma, Difesa, Danno e formula difesa.
In modalità non compressa mostra anche Movimento quando serve.

Toccare i riquadri porta alla zona utile:

- HP apre Vita.
- Scudo apre il campo Scudo.
- Difesa apre il campo Difesa.
- Danno apre Danno/Cura.
- Formula DIF porta ai valori modificabili.

STATISTICHE

Le quattro statistiche sono Resilienza, Volontà, Materia e Oculum.
Nella nuova scheda compatta:

- tocca una statistica per modificarla;
- tocca il piccolo dado sul riquadro per tirarla;
- tieni premuto il riquadro per tirarla rapidamente;
- il numero grande mostra attuale/massimo quando esiste un massimo;
- il badge 1d20 mostra il bonus usato nel tiro.

Il numero mostra la risorsa; il dado accanto esegue il tiro.

VALORI MODIFICABILI

Questa tendina contiene i campi che cambiano durante la sessione:

- Livello e Grado.
- HP, HP Temp, Scudo e Scudo Critico.
- Bonus Attacco/VC.
- Bonus Difesa.
- statistiche base.
- statistiche attuali.

Se un riquadro della scheda ti manda in modifica, di solito finisci qui.

BORSA RAPIDA

Su desktop la borsa rapida sta a lato.
Mostra i primi oggetti e permette di aumentare o ridurre la quantità senza aprire tutto l'inventario.
Per modifiche complete usa Apri borsa completa.

ART E SKILL MODIFICATE

Su desktop il pannello laterale Art e Skill mostra solo testo modificato o compilato.
Serve per vedere subito cosa e davvero personalizzato, senza rileggere tutte le Art base.

MODIFICA RAPIDA

Il pulsante con l'occhio nella barra alta apre Modifica rapida.
Usalo quando vuoi cambiare valori senza scorrere:

- nome;
- razza;
- livello;
- grado;
- HP;
- scudi;
- VC;
- CM;
- risorse.

Chiudi la modifica per tornare alla scena.

RICERCA

Il pulsante Cerca trova pagine, funzioni, regole, titoli, skill, art, inventario e testo.
La ricerca prova a ignorare accenti, maiuscole e piccoli errori.
Puoi cercare anche tratti razziali, tipi danno rilevati, note, descrizioni, partecipanti dell'iniziativa Master e note turno.

INIZIATIVA MASTER

Nella pagina Master trovi il tracker iniziativa.
Puoi aggiungere partecipanti manuali o usare schede già salvate nel party Master.
Durante un fight usa prima il riquadro Turno attivo: mostra chi agisce ora, totale iniziativa e round.
Il pulsante Pubblica invia ai player la turnistica compatta; resta visibile finché premi Chiudi player o invii un nuovo aggiornamento.
Se la turnistica e pubblicata, cambi turno, roll, riordino e rimozioni vengono reinviati automaticamente.
L'aggiunta manuale e a scomparsa per non occupare spazio mentre combatti.
Ogni partecipante ha:

- nome;
- tipo: player, NPC, neutrale, mostro, boss o summon;
- tiro iniziativa;
- bonus;
- totale;
- stato: da agire, attivo, agito, saltato, morto/KO;
- note.

Rolla tutti ordina dal totale più alto al più basso.
Rolla mostri/NPC tira solo nemici, neutrali e NPC.
Prossimo e Precedente cambiano turno, Nuovo round resetta chi non e KO, Sposta su/giu blocca l'ordine manuale.

MENU LATERALE DESKTOP

In Modalità Desktop una piccola freccia a sinistra apre il menu laterale.
Da li puoi cambiare pagina e scheda senza coprire il contenuto: il menu spinge la scheda verso destra.
Il reset layout nelle Impostazioni chiude il menu e ripristina le tendine principali.

COLORI E ASPETTO GOTICO

In Impostazioni puoi cambiare:

- colore primario;
- colore secondario;
- colore terziario;
- colore extra per tipi danno nuovi.

Il colore extra non cambia lo sprite dell'occhio: serve come fallback per tipi danno nuovi o rilevati nei testi.
''',
    contentEn: r'''
This section explains the app as if you were opening a sheet for the first time.
The goal is simple: know where to look, where to edit, and what happens when you tap a card.

INTERFACE MODES

- Mobile Mode:
  uses one compact column. The most important things come first: Play center, image, identity, race, Oculum, EXP, HP, Damage/Healing, Combat, summary, stats and editable values.

- Desktop Mode:
  uses different columns. Left side has identity, image, race, Oculum and EXP. Center has commands, combat, HP, damage, stats and edits. Right side has quick bag, edited Arts/Skills, party and dice result.

- Fast Mode:
  hides explanations and repeated blocks. Functions do not disappear: they remain reachable from Quick edit, Search, page menu and dropdowns.

You can switch Mobile/Desktop and Fast Mode from Settings.

COMBAT AND PLAY CENTER

The unified Combat and Play center is the sheet dashboard.
It is for actions used often during a session:

- HP: jumps to life.
- Shield: jumps to Shield.
- VC: jumps to Will and attack values.
- CM: jumps to Materia and the threshold to hit you.
- Damage: opens Damage/Healing.
- Defense: jumps to defense bonus or defensive values.
- Roll VC and Roll CM: roll immediately.
- Edit: opens Quick edit.

If you do not know where to go, start from the Play center.

IMAGE AND LOOK

The image area is the large eye box.
From here you can add an image, drag an image from desktop, crop, remove the image, and see sheet type, visible race and sheet number.
If you cancel crop, the previous image stays saved.

IDENTITY

Identity contains sheet type, sheet name, level, grade and Rebirth.
Level and Grade matter for almost everything: VC, CM, stat rolls, damage, defense and initiative count Level + Grade x6.

RACE AND RACIAL TRAITS

The Race area shows the visible race.
If the Race field is empty, the app uses the first Racial Trait created in the Titles page.

In Title creation, Type = Racial Trait, Race or Subrace automatically goes into Racial Traits, not normal Titles.
Racial Traits have 13 total slots between races and subraces and work like real titles for bonuses.

OCULUM

The Oculum area shows current and maximum Oculum.
You can add, remove, reset to max or write the current value manually.
Oculum fuels Arts, Opens, Oculum Skills and magical commands.

EXP

The EXP area adds experience without manual math.
Choose Normal enemy x1, Mini-Boss x1.3 or Boss x2. Easy adds 0.1; Hard subtracts 0.1 from Mini-Boss and Boss.
If enemy Grade is higher than yours, the app applies the expected multiplier.
Preview helps you understand what will be added before applying it.

HP, SHIELD AND DAMAGE/HEALING

HP shows real HP, temporary HP, Shield and Critical Shield.
Practical order:

1. Shield absorbs first.
2. Temporary HP protects real HP.
3. Real HP is actual life.
4. Critical Shield halves final damage while active.

Damage/Healing lets you enter a number and apply it.
Damage uses the dominant type. If you write a new damage type in a command, the app detects it and lets you color it from Settings.
Refill HP restores only current HP to maximum: it does not change Shield, Temp HP or Critical Shield.

FREE DAMAGE TYPES

The weapon damage type field is free text.
Valid examples: Ash, Illness, Curse, Gravity, Ancient Blood.
Pressing Tab tries to complete a known type, but a new type remains valid and appears in color settings while it exists in a weapon, title, art or skill.

SKILLS AND @ COMMANDS

Written Skills are not only text.
When equipped, commands written in Name, Type, Cost, Cooldown or Description are included in calculations.

Examples:

- @Danni+15 Malanno adds Illness damage.
- @Difesa+10 Cenere adds Ash defense.
- @Volonta+3 modifies Will while the skill remains equipped.
- @Materia+2 modifies Materia while the skill remains equipped.
- @VC+1 and @CM+1 add direct VC and CM bonuses.
- @Defense-¼ applies at least a 1 point penalty even when the fraction is small.
- @Damage+1OnHit activates after you have been hit and current HP is below maximum.
- @Will+1=-10HP adds +1 Will for every 10 HP lost.
- @HP+1=Will-1 adds HP when current Will drops below its base value.
- The unified @ Buffs/Debuffs area in Rest/Conditions accepts the same commands without creating a Title.

COMBAT

Combat shows VC, CM, Initiative, Damage, Defense and Level/Grade bonus.
Tapping a card opens the linked edit or area.
Roll VC and Roll CM roll immediately.

QUICK SUMMARY

Quick summary lets you read the sheet in seconds.
It shows HP, Temp, Shield, Critical Shield, Karma, Defense, Damage and defense formula.
Tapping cards jumps to useful areas: HP opens life, Shield opens Shield, Defense opens Defense, Damage opens Damage/Healing, DEF formula opens editable values.

STATS

The four stats are Resilience, Will, Materia and Oculum.
In the compact sheet:

- tap a stat to edit it;
- tap the small dice on the card to roll it;
- long press the card to roll quickly;
- the large number shows current/max when a maximum exists;
- the 1d20 badge shows the roll bonus.

This avoids the old problem: stat cards no longer feel only informational, they are tools.

EDITABLE VALUES

This dropdown contains fields that change during play:
Level, Grade, HP, Temp HP, Shield, Critical Shield, Attack/VC bonus, Defense bonus, base stats and current stats.
If a sheet card sends you to edit, it usually sends you here.

QUICK BAG

On desktop the quick bag sits on the side.
It shows first items and lets you change quantity without opening the whole inventory.
Use Open full bag for complete edits.

EDITED ARTS AND SKILLS

On desktop the side panel shows only edited or filled Art/Skill text.
It helps you see what is truly customized without rereading every base Art.

QUICK EDIT

The eye button in the top bar opens Quick edit.
Use it to change values without scrolling: name, race, level, grade, HP, shields, VC, CM and resources.

SEARCH

Search finds pages, functions, rules, titles, skills, arts, inventory and text.
It tries to ignore accents, uppercase/lowercase and small typos.
It also searches racial traits, detected damage types, notes, descriptions, Master initiative participants and turn notes.

MASTER INITIATIVE

The Master page includes the initiative tracker.
You can add manual participants or use sheets already saved in the Master party.
During a fight, start from the Active turn box: it shows who acts now, initiative total and round.
Publish sends players the compact turn order; it remains visible until you press Close players or send a new update.
If the turn order is published, turn changes, rolls, reorder and removals are resent automatically.
Manual add is collapsible so it does not consume fight space.
Each participant has name, type, initiative roll, bonus, total, state and notes.
States are ready, active, acted, skipped and dead/KO.
Roll all sorts from highest total to lowest.
Roll monsters/NPCs rolls only enemies, neutrals and NPCs.
Next and Previous change active turn, New round resets everyone not KO, Move up/down locks manual order.

DESKTOP SIDE MENU

In Desktop Mode a small arrow on the left opens the side menu.
From there you can switch page and sheet without covering the content: the menu pushes the sheet to the right.
Reset layout in Settings closes the menu and restores the main dropdowns.

GOTHIC LOOK AND COLORS

Settings let you change primary, secondary, tertiary and extra damage-type color.
The extra color does not change the eye sprite: it is a fallback for new or detected damage types.
''',
  ),

  ManualSection(
    titleIt: '23. Dadi, riserve, oggetti e condivisione',
    titleEn: '23. Dice, resources, equipment and sharing',
    contentIt: r'''
Qui trovi le procedure per dadi, riserve temporanee, Schivata Oculum, oggetti e condivisione. Consulta il paragrafo che riguarda ciò che stai facendo.

DADI SU TELEFONO E PC

Su telefono la schermata Dadi e organizzata a tendina:
- Setup tiro: contiene Numero dadi e Bonus.
- Dadi classici: d4, d6, d8, d10, d12, d20, d100.
- Set extra: d2, d3, d5, d7, d16, d24, d30, d50, d60.

Le tendine servono a tenere la pagina corta e più leggera su schermi piccoli. Su PC resta una griglia più larga, pensata per mouse e schermo grande.
Nella pagina Scheda anche "Dadi rapidi" e una tendina: puoi aprirla solo quando ti serve e richiuderla per liberare spazio.

Critici dei dadi:
- se tiri un solo dado e fai 1, il risultato è critico negativo e diventa rosso;
- se tiri un solo dado e fai il massimo di quel dado, il risultato è critico positivo brillante;
- il critico positivo vale per tutti i dadi: d2, d3, d4, d5, d6, d7, d8, d10, d12, d16, d20, d24, d30, d50, d60 e d100;
- critico positivo: aggiungi metà dado + Livello + Grado x6;
- critico negativo: togli metà dado + Livello + Grado x3;
- se il tiro nemico viene raddoppiato, quel tiro conta come critico positivo;
- se tiri più dadi insieme, ogni dado può aggiungere o togliere il proprio modificatore critico.

Il lanciatore pone un limite alla quantità di dadi. Per un tiro di gioco usa il comando della statistica o della capacità interessata.

SCUDO OCULUM

Lo Scudo Oculum è una barriera legata all'occhio. Compare solo quando serve:
- se hai Scudo Oculum attuale maggiore di 0;
- se hai massimo Scudo Oculum maggiore di 0;
- se un comando attivo come @ScudoOculum+5 lo concede;
- oppure se abiliti "Mostra sempre Scudo Oculum" nelle Impostazioni.

Dove compare:
- nella Barra della Vita, insieme a HP, HP temporanei, Scudo e Scudo Critico;
- sotto Vita, in una piccola tabella a tendina chiamata Scudo Oculum;
- nella Modifica rapida, così puoi cambiarlo senza scorrere tutta la scheda.

Colori:
- nella barra vita usa una sfumatura tra colore dell'occhio e colore Oculum/formula;
- questo lo distingue dallo Scudo normale e dagli HP temporanei.

Valori modificabili:
- Scudo Oculum attuale: quanto scudo hai adesso;
- Massimo base: massimo scritto manualmente;
- @ScudoOculum: bonus massimo dato da Titoli, Open, Art o Skill attivi/equipaggiati.

Pulsanti disponibili:
- -1: abbassa lo Scudo Oculum attuale di 1;
- +1: aumenta lo Scudo Oculum attuale di 1;
- Ricarica: porta lo Scudo Oculum al massimo.

Ricarica automatica:
- si ricarica con il riposo breve;
- si ricarica con il riposo lungo;
- con l'EXP recupera soltanto la quota ridotta prevista dalla difficoltà; non viene ricaricato completamente.
- il pulsante Refull Vita ricarica HP, HP temporanei dinamici e Scudo Oculum. Lo Scudo normale consumato non torna.

OCULUM TEMPORANEO E HP TEMPORANEI

Quando ottieni Oculum oltre il massimo normale, l'eccesso diventa temporaneo entro il limite della difficoltà: +6 in Facile, +5 in Normale, +3 in Difficile e +3 in Oculum. Il massimo normale non cambia. La durata viene gestita internamente attraverso i tiri validi del personaggio: dado, durata e tiri residui non vengono mostrati. Un cambio di difficoltà riduce subito l'eccesso se il nuovo limite e inferiore, ma non regala Oculum se il limite aumenta.

Le cure riempiono prima gli HP normali; l'eccesso diventa HP temporanei fino a un massimo di 20. Il danno consuma prima Scudo Oculum, Scudo normale, HP temporanei e infine HP normali, salvo le opzioni che ignorano gli scudi.

Ordine dei danni:
1. Scudo Oculum
2. Scudo
3. HP temporanei
4. HP reali

Passa alla riserva successiva soltanto quando quella precedente è esaurita.

SCHIVATA OCULUM

La Schivata Oculum è una difesa gratuita, limitata e consumabile. Ne ottieni una ogni terzo Grado:
- Grado III: 1 Schivata Oculum.
- Grado VI: 2 Schivate Oculum.
- Grado IX: 3 Schivate Oculum.
- Grado XII: 4 Schivate Oculum.

Puoi aggiungere cariche extra con il parser, per esempio @SchivataOculum+1.
Le cariche non si rigenerano con il turno, con il riposo o con il Refull: quando ne spendi una resta consumata finché non ottieni una nuova carica.

Quando la usi, scegli dal menu rapido:
- Inferiore: immunità ai danni dell'azione.
- Al tuo pari: riduzione del 90%.
- Forte: riduzione del 75%, pensata per minacce fino a tre Gradi sopra di te.
- Impossibile: riduzione del 50% contro minacce oltre quel limite.

La riduzione si applica al prossimo danno subito, dopo avere contato eventuali bonus critici del danno in arrivo e prima di Difesa, Scudo Oculum, Scudo, HP temporanei e HP. La carica viene consumata quando prepari la Schivata Oculum e le cariche usate restano tracciate nella scheda.

SCRIVERE UN EFFETTO CON @

Puoi scrivere questi comandi dentro Titoli, Open, Art, Skill, Buff @ Oggetto e testi supportati dal parser.
Sono dinamici: valgono solo mentre la cosa che li contiene è equipaggiata o attiva.

Comandi principali:
- @Iniziativa+5: aggiunge +5 all'Iniziativa.
- @HP+5: aumenta la vita massima di +5.
- @Vita+5: uguale a @HP+5.
- @HPTemp+Vol1/6: aggiunge HP temporanei pari a un sesto della Volontà.
- @ScudoOculum+5: aggiunge +5 al massimo Scudo Oculum.
- @SchivataOculum+1: aggiunge una Schivata Oculum extra.
- @TiroAttacco+1: aggiunge +1 ai tiri d'attacco.
- @TiroDifesa+1: aggiunge +1 ai tiri difensivi.
- @TiroVolontà+1: aggiunge +1 solo al tiro di Volontà, non alla Volontà base.
- @TiroStats+1: aggiunge +1 ai tiri di Resilienza, Volontà, Materia e Oculum.
- @TiroVC+1 e @TiroCM+1: alias diretti dei bonus tiro di VC e CM.

Un bonus equipaggiato dura finché tieni attivo ciò che lo concede. Togliendo il Titolo perdi il bonus; rimettendolo lo recuperi una sola volta. La statistica base rimane quella della scheda.

Oggetti con buff @:
- in Inventario ogni oggetto ha un campo "Buff @ Oggetto";
- il buff vale solo se l'oggetto e equipaggiato;
- puoi usarlo per reliquie, armature, focus o item speciali;
- esempi validi: @HP+5, @HPTemp+Vol1/6, @Scudo+3, @ScudoOculum+5, @TiroAttacco+1, @TiroVolontà+1, @TiroStats+1.

Grado oggetto:
- ogni grado aggiunto ad armi o armature aumenta di +5 Attacco, +5 Scudo e +2 Difesa;
- il massimo è Grado XII;
- se un oggetto richiede un grado superiore al tuo, non puoi equipaggiarlo.

Putrefazione oggetti:
- il valore PUT indica dopo quanti giorni l'oggetto marcisce;
- esempio: una mela ottenuta al giorno 10 con PUT 5 diventa marcia al giorno 15;
- carne e cibo diventano "Carne marcia";
- materiali e metalli diventano "Materiale putrefatto";
- lo Slime diventa "Slime putrefatto";
- gli altri oggetti diventano "Oggetto putrefatto";
- più oggetti putrefatti dello stesso tipo si uniscono nello stesso stack.

HP temporanei dinamici:
- @HPTemp+Vol1/6 può dipendere dalla Volontà attuale;
- se la Volontà cambia, il bonus si aggiorna;
- se il danno consuma quegli HP temporanei, l'app tiene memoria della parte consumata;
- quando il bonus non e più attivo, non resta appiccicato come valore permanente.

Scudo dinamico:
- @Scudo+X funziona come riserva dinamica;
- se il danno lo consuma, la parte consumata resta consumata;
- Refull Vita non azzera il consumo dello Scudo normale: se lo perdi, resta perso finché non ottieni nuovo Scudo da una regola, oggetto o bonus.

FORMULE E ALIAS UTILI

Alias riconosciuti:
- HP, Vita, Life, Health;
- HPTemp, HPTemporanei, TempHP;
- ScudoOculum, ScudoOcu, OculumShield, EyeShield;
- SchivataOculum, SchivataOcu, OculumDodge, EyeDodge;
- Iniziativa, Ini, Initiative;
- TiroAttacco, TiroDiAttacco, AttackRoll;
- TiroDifesa, TiroDifensivo, DefenseRoll.
- TiroRes, TiroResilienza, TiroVolonta, TiroVolontà, TiroMateria, TiroOculum, TiroStats, TiroVC, TiroCM.

Esempi:
- @HP+5 e @Vita+5 danno lo stesso risultato;
- @HPTemp+Vol1/6 usa una formula;
- @ScudoOculum+5 crea o aumenta la barriera dell'occhio;
- @SchivataOculum+1 aggiunge una carica extra di Schivata Oculum;
- @TiroAttacco+1, @TiroDifesa+1, @TiroVolontà+1 e @TiroStats+1 si sommano ai bonus rapidi già presenti, ma non modificano le statistiche base.

PERMESSI SCHEDA AGLI AMICI

Nella parte Online/Amici puoi togliere o ridare l'accesso alla tua scheda.

Cosa puoi fare:
- Revoca scheda: impedisce a quell'amico di ricevere la tua scheda corrente;
- Riabilita scheda: permette di nuovo la condivisione;
- se un amico e revocato, l'invio manuale e la sincronizzazione realtime non lo includono;
- la lista dei revocati resta locale alla tua scheda e non viene inviata agli altri.

Uso pratico:
- se vuoi giocare con un gruppo ma nascondere temporaneamente una scheda a un giocatore, revoca quell'amico;
- se poi vuoi riaprire la scheda, premi Riabilita scheda;
- la revoca riguarda la scheda corrente, quindi puoi gestire permessi diversi per schede diverse.

ANNULLA E TORNA AVANTI

Nella barra in alto ci sono due pulsanti:
- Annulla ultima modifica;
- Torna avanti.

Annulla:
- salva prima lo stato corrente se ci sono modifiche non ancora salvate;
- torna allo stato precedente della scheda;
- funziona su modifiche della scheda salvate nella memoria interna dell'app.

Torna avanti:
- riapplica una modifica appena annullata;
- si svuota se fai una nuova modifica dopo aver annullato.

Limiti:
- la cronologia e pensata per la sessione corrente;
- non e un backup storico infinito;
- per salvataggi di sicurezza restano comunque i backup protetti dell'app.

MODIFICA RAPIDA

Il pulsante con l'occhio nella barra in alto apre Modifica rapida.
Da qui puoi cambiare:
- Scudo Oculum attuale;
- Massimo Scudo Oculum;
- HP, HP temporanei, Scudo e Scudo Critico;
- valori rapidi di attacco, difesa, VC e CM;
- risorse principali.

Serve quando devi cambiare valori durante una scena senza cercare la casella nel mezzo della scheda.

IMPOSTAZIONI UTILI

Mostra sempre Scudo Oculum:
- se spento, Scudo Oculum compare solo quando hai valore, massimo o comando attivo;
- se acceso, la sezione resta visibile anche a 0, utile per preparare una build o controllare la regola.

Modalità Desktop:
- su PC puoi usare menu laterale e layout più largo;
- su telefono l'app privilegia tendine, pannelli compatti e ombre più leggere.

MINIGIOCO OCULUM DUNGEON

In Oculum Dungeon trovi:
- indicatore Karma nella HUD;
- Scudo Oculum della run, mostrato come SO attuale/massimo;
- eventi rari dello Scudo Oculum;
- eventi a scelta multipla con scelte buone, rischiose e sbagliate;
- sblocchi a soglie di Karma positivo e negativo;
- turni nemici da 3 secondi con comandi bloccati mentre i mostri agiscono;
- difesa automatica con tiro CM durante il turno nemico;
- skill nemiche di attacco, cura e difesa, anche per mostri procedurali;
- sprite dedicati per alcuni mostri, NPC e reliquie generati dalle descrizioni;
- nuovi temi sbloccabili: Fioritura di Postea, Bilancia del Karma e Lanterna dei Mostri.

Karma nel minigioco:
- le scelte gentili o corrette aumentano il Karma;
- furto, forzature e scelte sbagliate lo abbassano;
- a Karma +6 si sblocca la Guida della Bilancia;
- a Karma -6 si sblocca la Candela Nera del Debito;
- a Karma +12 o -12 si sblocca la reliquia Occhio dello Scudo Oculum per le run future.
- a Karma positivo o negativo viene sbloccato anche il tema Bilancia del Karma.

Scudo Oculum nel minigioco:
- viene consumato prima dello Scudo normale quando subisci danno;
- gli eventi rari possono aumentare Scudo Oculum attuale e massimo;
- alcuni NPC/eventi legati al Karma lo concedono o lo modificano.

Reliquia Occhio dello Scudo Oculum:
- quando la scegli, parti con 50 Scudo Oculum;
- tutto lo Scudo normale guadagnato durante quella run diventa Scudo Oculum;
- la vita massima viene ridotta del 60%;
- lo Scudo Oculum assorbe prima dello Scudo normale.

LEGGERE E MODIFICARE I VALORI

Tocca un valore compatto di Vita o Scudo Oculum per aprirne la modifica. Sul telefono puoi richiudere i gruppi di dadi quando hai finito. Il risultato naturale massimo del dado viene evidenziato come critico positivo.
''',
    contentEn: r'''
Use these procedures when rolling dice, managing temporary resources, editing equipment or sharing a sheet.

DICE ON PHONE AND PC

On phone, the Dice page is organized as dropdown sections:
- Roll setup: Dice amount and Bonus.
- Classic dice: d4, d6, d8, d10, d12, d20, d100.
- Extra set: d2, d3, d5, d7, d16, d24, d30, d50, d60.

Dropdowns keep the page shorter and lighter on small screens. On PC, the page keeps a wider grid made for mouse and large screens.
On the Sheet page, "Quick dice" is also collapsible: open it only when needed and close it to free space.

Dice criticals:
- if you roll one die and it lands on 1, it is a negative critical and turns red;
- if you roll one die and it lands on that die maximum, it is a bright positive critical;
- positive critical works for every die: d2, d3, d4, d5, d6, d7, d8, d10, d12, d16, d20, d24, d30, d50, d60 and d100;
- positive critical adds half die + Level + Grade x6;
- negative critical subtracts half die + Level + Grade x3;
- if you roll multiple dice together, every die can add or subtract its own critical modifier.

To avoid accidental freezes, dice amount is capped to a manageable maximum. Dice drawing is lighter and isolated, so the rest of the screen does not repaint unnecessarily.

OCULUM SHIELD

Oculum Shield is a barrier tied to the eye. It appears only when needed:
- current Oculum Shield is above 0;
- maximum Oculum Shield is above 0;
- an active command like @ScudoOculum+5 grants it;
- or "Always show Oculum Shield" is enabled in Settings.

Where it appears:
- inside the Health Bar, together with HP, temporary HP, Shield and Critical Shield;
- below Health, in a small dropdown table called Oculum Shield;
- in Quick edit, so you can change it without scrolling through the sheet.

Colors:
- in the health bar it uses a gradient between eye color and Oculum/formula color;
- this separates it from normal Shield and temporary HP.

Editable values:
- Current Oculum Shield: how much you have now;
- Base maximum: manual maximum;
- @ScudoOculum: maximum bonus granted by active/equipped Titles, Opens, Arts or Skills.

Available buttons:
- -1: lowers current Oculum Shield by 1;
- +1: increases current Oculum Shield by 1;
- Recharge: sets Oculum Shield to maximum.

Automatic recharge:
- recharges on short rest;
- recharges on long rest;
- recharges after fight when EXP/end combat is applied.
- the Refill Life button restores HP, dynamic temporary HP and Oculum Shield. Spent normal Shield does not come back.

Damage order:
1. Oculum Shield
2. Shield
3. Temporary HP
4. Real HP

So when you take damage, Oculum Shield is consumed first. Only when it is empty does damage move to normal Shield, then temporary HP, then real HP.

OCULUM DODGE

Oculum Dodge is a free, limited and consumable defense. You gain one charge every third Grade:
- Grade III: 1 Oculum Dodge.
- Grade VI: 2 Oculum Dodges.
- Grade IX: 3 Oculum Dodges.
- Grade XII: 4 Oculum Dodges.

Extra charges can be added through the parser, for example @SchivataOculum+1.
Charges do not regenerate with the turn, rest or Refill: once spent, a charge stays consumed until you gain a new one.

When you use it, choose from the quick menu:
- Inferiore: immunity to that action's damage.
- Al tuo pari: 90% reduction.
- Forte: 75% reduction, intended for threats up to three Grades above you.
- Impossibile: 50% reduction against threats beyond that limit.

The reduction applies to the next damage taken, after any incoming critical damage bonus has been counted and before Defense, Oculum Shield, Shield, temporary HP and HP. The charge is consumed when you prepare Oculum Dodge, and used charges remain tracked on the sheet.

NEW DYNAMIC @ COMMANDS

The new commands work inside Titles, Opens, Arts, Skills, Item @ Buff and supported parsed text.
They are dynamic: they count only while the thing containing them is equipped or active.

Main commands:
- @Iniziativa+5: adds +5 Initiative.
- @HP+5: increases max HP by +5.
- @Vita+5: same as @HP+5.
- @HPTemp+Vol1/6: adds temporary HP equal to one sixth of Will.
- @ScudoOculum+5: adds +5 maximum Oculum Shield.
- @SchivataOculum+1: adds one extra Oculum Dodge.
- @TiroAttacco+1: adds +1 to attack rolls.
- @TiroDifesa+1: adds +1 to defense rolls.
- @TiroVolontà+1: adds +1 only to the Will roll, not to base Will.
- @TiroStats+1: adds +1 to Resilience, Will, Materia and Oculum rolls.
- @TiroVC+1 and @TiroCM+1: direct aliases for VC and CM roll bonuses.

Anti-duplicate rule:
- the command does not permanently write into the base stat;
- if you equip a Title, the bonus appears;
- if you remove that Title, the bonus disappears;
- if you equip it again, the bonus returns once;
- this avoids duplicated stats and excessive removals.

Items with @ buffs:
- every inventory item has an "Item @ Buff" field;
- the buff counts only while the item is equipped;
- use it for relics, armor, focuses or special items;
- valid examples: @HP+5, @HPTemp+Vol1/6, @Scudo+3, @ScudoOculum+5, @TiroAttacco+1, @TiroVolontà+1, @TiroStats+1.

Item rot:
- PUT means how many days pass before the item rots;
- example: an apple gained on day 10 with PUT 5 rots on day 15;
- meat and food become "Carne marcia";
- materials and metals become "Materiale putrefatto";
- Slime becomes "Slime putrefatto";
- other items become "Oggetto putrefatto";
- multiple rotten items with the same type merge into one stack.

Dynamic temporary HP:
- @HPTemp+Vol1/6 can depend on current Will;
- if Will changes, the bonus updates;
- if damage consumes those temporary HP, the app remembers the consumed part;
- when the bonus is no longer active, it does not remain as a permanent value.

Dynamic Shield:
- @Scudo+X works as a dynamic reserve;
- if damage consumes it, the consumed part stays consumed;
- Refill Life does not clear spent normal Shield: once lost, it stays lost until a rule, item or bonus grants new Shield.

FORMULAS AND USEFUL ALIASES

Recognized aliases:
- HP, Vita, Life, Health;
- HPTemp, HPTemporanei, TempHP;
- ScudoOculum, ScudoOcu, OculumShield, EyeShield;
- SchivataOculum, SchivataOcu, OculumDodge, EyeDodge;
- Iniziativa, Ini, Initiative;
- TiroAttacco, TiroDiAttacco, AttackRoll;
- TiroDifesa, TiroDifensivo, DefenseRoll.
- TiroRes, TiroResilienza, TiroVolonta, TiroVolontà, TiroMateria, TiroOculum, TiroStats, TiroVC, TiroCM.

Examples:
- @HP+5 and @Vita+5 do the same thing;
- @HPTemp+Vol1/6 uses a formula;
- @ScudoOculum+5 creates or increases the eye barrier;
- @SchivataOculum+1 adds one extra Oculum Dodge charge;
- @TiroAttacco+1, @TiroDifesa+1, @TiroVolontà+1 and @TiroStats+1 stack with existing quick bonuses, but do not change base stats.

SHEET PERMISSIONS FOR FRIENDS

In Online/Friends you can remove or restore access to your sheet.

What you can do:
- Revoke sheet: prevents that friend from receiving your current sheet;
- Re-enable sheet: allows sharing again;
- if a friend is revoked, manual sending and realtime sync skip them;
- the revoked list stays local to your sheet and is not sent to others.

Practical use:
- if you want to play with a group but temporarily hide a sheet from one player, revoke that friend;
- if you later want to reopen the sheet, press Re-enable sheet;
- revocation applies to the current sheet, so different sheets can have different permissions.

UNDO AND REDO

The top bar has two buttons:
- Undo last change;
- Redo.

Undo:
- first stores the current state if there are unsaved changes;
- returns to the previous sheet state;
- works on sheet changes stored in the app internal memory.

Redo:
- reapplies a change that was just undone;
- clears if you make a new change after undoing.

Limits:
- history is designed for the current session;
- it is not an infinite historical backup;
- protected save backups still exist for safety saves.

QUICK EDIT

The eye button in the top bar opens Quick edit.
It now also includes:
- current Oculum Shield;
- maximum Oculum Shield;
- HP, temporary HP, Shield and Critical Shield;
- attack, defense, VC and CM quick values;
- main resources.

Use it when you need to change values during a scene without searching for the field inside the full sheet.

USEFUL SETTINGS

Always show Oculum Shield:
- when off, Oculum Shield appears only when you have value, maximum or active command;
- when on, the section stays visible even at 0, useful when preparing a build or checking the rule.

Desktop Mode:
- on PC you can use the side menu and wider layout;
- on phone the app prioritizes dropdowns, compact panels and lighter shadows.

OCULUM DUNGEON MINIGAME

The minigame now includes:
- Karma indicator in the HUD;
- run Oculum Shield, shown as current/maximum OS;
- rare Oculum Shield events;
- multiple-choice events with good, risky and wrong choices;
- unlocks at positive and negative Karma thresholds;
- 3-second enemy turns with player commands locked while monsters act;
- automatic CM defense rolls during enemy turns;
- enemy attack, heal and defense skills, including procedural monsters;
- dedicated sprites for some monsters, NPCs and relics generated from their descriptions;
- new unlockable themes: Postea Bloom, Karma Scales and Monster Lantern.

Minigame Karma:
- kind or correct choices increase Karma;
- theft, forcing and wrong choices lower it;
- at Karma +6, Scale Guide unlocks;
- at Karma -6, Black Debt Candle unlocks;
- at Karma +12 or -12, Oculum Shield Eye unlocks as a future starting relic.
- positive or negative Karma also unlocks the Karma Scales theme.

Oculum Shield in the minigame:
- it is consumed before normal Shield when you take damage;
- rare events can increase current and maximum Oculum Shield;
- some Karma-linked NPCs/events grant or alter it.

Oculum Shield Eye relic:
- when chosen, you start with 50 Oculum Shield;
- all normal Shield gained during that run becomes Oculum Shield;
- max HP is reduced by 60%;
- Oculum Shield absorbs before normal Shield.

PERFORMANCE

The app has been made lighter for phone and PC:
- phone panels use lighter shadows;
- Health and Oculum Shield dropdown values edit through compact dialogs, avoiding TextField runtime errors inside collapsible panels;
- dice are graphically isolated to reduce unnecessary repaints;
- the health bar calculates segments once instead of repeatedly calling ratio functions;
- phone dice sets live in collapsible dropdowns;
- accidental huge rolls are capped to avoid blocking the UI;
- bright positive critical is calculated simply: natural result equal to die maximum.
''',
  ),

  ManualSection(
    titleIt: 'Regole aggiornate: giorni, crisi e dungeon',
    titleEn: 'Updated rules: days, crisis and dungeon',
    contentIt: r'''
Questa sezione riassume le regole automatizzate nell'app.

VITA E GRADO

La vita massima non usa più un x10 fisso.
Formula:
- Vita massima = Resilienza x (10 + Grado x5).

Esempi:
- Grado 0: Resilienza x10.
- Grado 1: Resilienza x15.
- Grado 2: Resilienza x20.

DADI E CRITICI

Ogni dado può generare un critico:
- 1 naturale: critico negativo;
- massimo naturale del dado: critico positivo.

Il modificatore critico si applica a ogni dado, anche quando tiri più dadi insieme.
- Critico positivo: aggiungi meta del dado + Livello + Grado x6.
- Critico negativo: togli meta del dado + Livello + Grado x3.
- Se il tiro nemico viene raddoppiato, quel tiro conta come critico positivo.

Risveglio al 50% Vita:
- ogni creatura tenta una sola volta quando scende a meta vita;
- 9% Risveglio Piccolo: +2 Resilienza, +2 Oculum;
- 6% Risveglio Parziale: +3 Resilienza, +3 Oculum;
- 3% Risveglio Totale: +5 a tutte le stats;
- 1% Fatica: +1 Cenere, solo se oggi hai usato almeno il 75% dell'Oculum o una schivata Oculum;
- negli altri casi non succede nulla.

Il campo Danno / Cura accetta anche formule semplici. Per esempio:
- 10+100-20 viene letto come 90.

Dopo il calcolo restano attive tutte le altre regole: Difesa, Scudo Oculum, Scudo, HP temporanei, HP, modificatori di danno e critici.

VANTAGGIO E SVANTAGGIO

La scheda può applicare un modificatore globale ai tiri senza cambiare le statistiche base.
La scala va da Svantaggio Oculum (-12) a Vantaggio Oculum (+12), passando per svantaggi e vantaggi minori, normali, veri, super e ultra.
Il valore scelto si somma ai tiri di statistica, VC, CM e Iniziativa. Serve per condizioni temporanee, terreno, posizione, aiuti narrativi o pressione della scena.

DT - DIFFICOLTA TIRO

Ogni scheda ha un campo DT modificabile scrivendo un numero. Il valore 0 e neutro. Un DT positivo viene sottratto dal totale di tutti i tiri della scheda, rendendoli più difficili; un DT negativo facilita i tiri. La formula visualizzata mostra sempre la DT applicata. Un 1 o il massimo naturale del dado restano comunque critici naturali.

MODIFICATORI DI DANNO E CURA

Il menu Danno / Cura segue questa scala, dall'esposizione peggiore alla rigenerazione completa:
- Fragilita Letale +500%.
- Fragilita Semi Letale +250%.
- Fragilita Distruttiva +100%.
- Fragilita Assoluta +90%.
- Fragilita Estrema +75%.
- Alta Fragilita +50%.
- Fragilita +25%.
- Bassa Fragilita +10%.
- Normale.
- Resistenza Leggera -10%.
- Resistenza -25%.
- Alta Resistenza -50%.
- Resistenza Semi Perfetta -75%.
- Resistenza Impenetrabile -90%.
- Immunita -100%.
- Rigenerazione Leggera: rigenera il 10% del danno totale.
- Rigenerazione: rigenera il 25% del danno totale.
- Alta Rigenerazione: rigenera il 50% del danno totale.
- Rigenerazione Molto Forte: rigenera il 75% del danno totale.
- Rigenerazione Semi Perfetta: rigenera il 90% del danno totale.
- Rigenerazione Perfetta: rigenera il 100% del danno totale.

Opzioni impatto nel pannello Danno / Cura:
- Oltre difesa: il danno non viene ridotto dalla Difesa.
- Oltre scudi: il danno salta Scudo Oculum e Scudo, ma continua a rispettare HP temporanei, HP e le altre regole.
- Bonus danno agli scudi %: aumenta solo il danno consumato dagli scudi. L'eccesso non diventa danno extra alla vita.

I recuperi EXP dipendono dalla difficoltà e non superano mai i massimali naturali. Facile: ogni 100 EXP recuperi fino a 4 HP e 1 Oculum; alla soglia 369 recuperi un quinto degli HP massimi, un quarto dell'Oculum massimo è un decimo dello Scudo Oculum. Normale: ogni 150 EXP recuperi fino a 3 HP e 1 Oculum; alla soglia 369 recuperi un sesto HP, un quinto Oculum e un quindicesimo dello Scudo Oculum. Difficile: ogni 200 EXP recuperi fino a 2 HP e 1 Oculum; alla soglia 369 recuperi un ottavo HP, un sesto Oculum e un ventesimo dello Scudo Oculum. Oculum: ogni 300 EXP recuperi fino a 1 HP e 1 Oculum; alla soglia 369 recuperi un decimo HP, un ottavo Oculum e un trentesimo dello Scudo Oculum. Il resto di EXP viene conservato verso il recupero successivo.

SCUDO DI SALVATAGGIO

Lo Scudo di Salvataggio e un consumabile difensivo usato con Azione Gratuita, al massimo una volta per turno.
Quando e attivo, se il prossimo danno rompe il tuo ultimo scudo, il danno in eccesso non passa a HP temporanei o vita.
Non sostituisce Difesa, Scudo Oculum, Scudo normale, HP temporanei o altre riduzioni: interviene solo dopo la rottura dell'ultimo scudo e viene consumato quando blocca l'overflow.

GIORNI E CICLO OCULUM

Le sessioni di riposo e putrefazione sono gestite come giorni.
Un Giorno dura 9 ore.

Unita del calendario:
- Tremana: 3 giorni.
- Semana: 6 giorni.
- Dodemana: 12 giorni.
- Nuova Fase: stagione mutevole, 36 giorni o meno.
- Ciclo Pieno: 369 giorni.

Le 12 Nuove Fasi del Ciclo Pieno:
- Safe Monster, giorni 1-36: molti mostri perdono il Grado, diventano pacifici, danno karma negativo se uccisi e non hanno drop oltre quelli base o rari.
- Illness, giorni 37-72: la Follia ricevuta raddoppia, gli "altri" diventano visibili e si può ottenere Illness Art.
- Little Breath, giorni 73-108: il Fato concede più Titoli, soprattutto ai rebirthati; clima e sentore delle aree sono più deboli.
- Piogge Fertilizzanti, giorni 109-144: piove fango nauseante, i malanni sono più facili e il cibo può causare Nausea.
- The Sun, giorni 145-150: i Solari ricevono +25% alle stats, non piove e il cibo sotto Grado VI marcisce entro massimo 2 giorni.
- Mezzo Ciclo, giorni 151-183: il meteo diventa reggibile quasi ovunque e le piogge tornano principalmente non magiche.
- The Moon, giorni 184-189: si festeggia l'accettazione di ogni razza; i Lunari ricevono +10%.
- The Fate, giorni 190-225: chi possiede un Fato e potenziato contro chi non ne possiede uno.
- Caldo Infernale, giorni 226-261: il caldo pesa molto di più; senza bere si subiscono debuff a Volontà in base alla fatica.
- The Null, giorni 262-297: il vuoto prende parte dei caduti e li fa rinascere Senza Fato, con ricordi assenti o falsati.
- Ghiaccio Imponente, giorni 298-344: il freddo pesa molto di più; senza calore si perde Materia e si rischia il congelamento.
- Ultimo Ciclo, giorni 334-369: si festeggia il ciclo passato, senza peculiarita meccaniche forti.

RIPOSO

La pagina Riposo mostra:
- giorno corrente del Ciclo Oculum;
- Nuova Fase corrente;
- giorno interno alla fase;
- Tremana, Semana e Dodemana;
- pulsanti per avanzare o retrocedere di un giorno.

Il riposo lungo porta gli HP ad almeno il 75% del massimale e ricarica lo Scudo Oculum quando presente. Lo Scudo normale consumato resta consumato.

PUTREFAZIONE

La putrefazione degli oggetti in borsa si basa sul giorno corrente.
Quando un oggetto viene aggiunto, l'app segna il giorno in cui e stato ottenuto.

Esempio:
- sei al giorno 10;
- ottieni una mela con PUT 5;
- al giorno 15 la mela diventa Carne marcia.

Risultati standard:
- carne o cibo: Carne marcia;
- materiali: Materiale putrefatto;
- slime: Slime putrefatto;
- altro: Oggetto putrefatto.

Oggetti putrefatti dello stesso tipo si uniscono nello stesso stack.

STATO DI FORZA

Lo Stato di Forza si controlla automaticamente quando gli HP scendono a un quarto o meno della vita massima.
L'app pesca uno stato casuale. Gli stati più forti sono più rari, ma non impossibili.

Possibili risultati:
- Corpo non Mollare: +20 + Livello + Grado HP temporanei, +3 Volontà, +2 Materia.
- Occhi Attenti: +5 + Livello + Grado ai tiri di attacco e difesa.
- Esplosione di Oculum: +25 HP, Oculum attuale pari alla vita anche oltre il massimo, danni pari a Livello + Grado, difesa pari alla meta di Livello + Grado e durata minima 9 tiri, inclusi i sottotratti.
- Adrenalina: +1 Reazione veloce e +5 + Livello + Grado iniziativa.
- Azzeramento delle vulnerabilita: resistenza ai colpi, rimozione dei malus temporanei negativi e della fatica oltre soglia.
- Tenacia: rimuove tutti i malus temporanei e tutte le condizioni negative, poi applica Rigenerazione per 3 turni.
- Stanchezza: -2 ai tiri per colpire e difendersi, -5 - Livello - Grado ai danni.
- Niente: nessun effetto.

Lo stato si applica da solo quando subisci danni o modifichi gli HP. Quando Esplosione di Oculum finisce, tira l'esito automatico: 56% -1 ai tiri Oculum fino al prossimo riposo breve o lungo, 36% +1 Cenere, 9% +3 Cenere. Quando torni sopra la soglia dopo la durata minima, l'app lo resetta e si prepara alla prossima crisi.

MAPPA E TOKEN

Nella mappa non online puoi usare token derivati dalle schede o creati da immagini già generate.
Il token può essere ridimensionato rapidamente con i pulsanti + e - direttamente sulla mappa.
Con tasto destro o pressione lunga puoi gestire opzioni e turnistica.

I token collegati alla turnistica riprendono le loro statistiche. A ogni nuovo turno il movimento disponibile viene resettato.
Gli utenti possono muovere solo i propri token, salvo permessi del Master.

DUNGEON

Il tema "Giorno di scuola" si sblocca automaticamente se arrivi al piano 3 con l'Art Scolastica Moderna scelta nella run.
Il tema resta anche acquistabile dagli sblocchi del dungeon, così le progressioni più vecchie possono recuperarlo.

Kitty Slime si sblocca selezionando l'Art Hoshy o avendo una scheda chiamata Hoshy almeno di livello 5.
Ha moltissima vita e pochi danni. Quando subisce un attacco ha il 50% di probabilità di generare una copia, fino a due copie.
Le copie hanno meta delle sue statistiche, sono più facili da colpire rispetto al personaggio principale e attaccano insieme a lui.

EQUIPAGGIAMENTO DELLA RUN

Nel dungeon puoi cambiare arma, costume e Oculus solo con cose trovate o comprate nella run corrente.
Le armi possono apparire negli eventi e nei negozi. Alcune armi bloccate possono comparire raramente, ma quelle sbloccate sono più comuni.
I costumi seguono la stessa regola: li puoi indossare solo dopo averli trovati nella run, anche quando appartengono a contenuti già sbloccati.

Gli Oculus permettono di aggiungere Skill Oculum da altre Art Oculum, fino a un massimo di 9 skill attive nella run.
Quando installi un Oculus, la scena viene descritta così: "Togli un tuo occhio, fa male, lo sostituisci con un oculus pieno di potere."
Gli Oculus delle Art già sbloccate sono più frequenti; quelli non sbloccati sono rari.

NPC EVOCABILI

Gli NPC trovati nella run non entrano nel party permanente.
Vanno in una coda di evocazione e possono sostituire automaticamente un alleato quando qualcuno muore o sparisce.
Se li rimuovi manualmente, non vengono evocati di nuovo automaticamente finché non li riaggiungi.

COSTUME: CUORE DI RICAMBIO SBAGLIATO

Cuore di Ricambio Sbagliato e un costume rischioso.
Quando lo indossi, riduce molto la vita massima, concede una Rinascita e rigenera tra 20 e 150 HP a ogni turno di combattimento.
Il bonus e forte, ma il taglio alla vita rende pericolosi i colpi grossi e le stanze con danni improvvisi.

Dal Grado VI può comparire l'evento Occhio di Pietra e Bilancia.
L'occhio di pietra osserva una bilancia vuota. Puoi appoggiare tutti i drop e tutto il Metallo Runico Postea posseduto nella run.
La stanza fonde tutto in una volta come un fabbro più forte:
- aumenta danno arma;
- aumenta difesa arma;
- aggiunge resistenze dagli elementi dei drop;
- può generare Dust, critico run, Scudo Oculum e favore del fabbro.

Se non hai oggetti da fondere, l'evento non blocca la run e concede Scudo Oculum.

PRESTAZIONI

L'app deve restare fluida su telefono, desktop e macOS.
Le ottimizzazioni devono alleggerire calcoli e ridisegni senza rimuovere decorazioni, painter, temi o funzioni già presenti.
''',
    contentEn: r'''
This section summarizes the rules automated by the app.

LIFE AND GRADE

Maximum life no longer uses a fixed x10.
Formula:
- Maximum life = Resilience x (10 + Grade x5).

Examples:
- Grade 0: Resilience x10.
- Grade 1: Resilience x15.
- Grade 2: Resilience x20.

DICE AND CRITICALS

Every die can generate a critical:
- natural 1: negative critical;
- natural maximum of that die: positive critical.

The critical modifier applies to every die, even when several dice are rolled together.
- Positive critical: add half die + Level + Grade x6.
- Negative critical: subtract half die + Level + Grade x3.

The Damage / Healing field also accepts simple formulas. For example:
- 10+100-20 is read as 90.

After the calculation, all other rules still apply: Defense, Oculum Shield, Shield, temporary HP, HP, damage modifiers and criticals.

ADVANTAGE AND DISADVANTAGE

The sheet can apply a global roll modifier without changing base stats.
The scale goes from Oculum Disadvantage (-12) to Oculum Advantage (+12), including minor, normal, true, super and ultra steps.
The selected value is added to stat rolls, VC, CM and Initiative. It is meant for temporary conditions, terrain, positioning, narrative help or scene pressure.

DT - ROLL DIFFICULTY

Every sheet has a DT field that accepts a typed number. 0 is neutral. A positive DT is subtracted from the total of every roll made by that sheet, making rolls harder; a negative DT makes them easier. The displayed formula always includes the applied DT. A natural 1 or the die's natural maximum still remains a natural critical.

DAMAGE AND HEALING MODIFIERS

The Damage / Healing menu follows this scale, from worst exposure to full regeneration:
- Lethal Fragility +500%.
- Semi-lethal Fragility +250%.
- Destructive Fragility +100%.
- Absolute Fragility +90%.
- Extreme Fragility +75%.
- High Fragility +50%.
- Fragility +25%.
- Low Fragility +10%.
- Normal.
- Light Resistance -10%.
- Resistance -25%.
- High Resistance -50%.
- Semi-perfect Resistance -75%.
- Impenetrable Resistance -90%.
- Immunity -100%.
- Light Regeneration: regenerates 10% of total damage.
- Regeneration: regenerates 25% of total damage.
- High Regeneration: regenerates 50% of total damage.
- Very Strong Regeneration: regenerates 75% of total damage.
- Semi-perfect Regeneration: regenerates 90% of total damage.
- Perfect Regeneration: regenerates 100% of total damage.

Impact options in the Damage / Healing panel:
- Beyond defense: damage is not reduced by Defense.
- Beyond shields: damage skips Oculum Shield and Shield, while temporary HP, HP and the other rules still apply.
- Shield damage bonus %: increases only the damage consumed by shields. Overflow does not become extra life damage.

EXP recovery depends on difficulty and never exceeds natural caps. Easy: every 100 EXP restores up to 4 HP and 1 Oculum; at threshold 369 it restores one fifth maximum HP, one quarter maximum Oculum and one tenth Oculum Shield. Normal: every 150 EXP restores up to 3 HP and 1 Oculum; at threshold 369 it restores one sixth HP, one fifth Oculum and one fifteenth Oculum Shield. Hard: every 200 EXP restores up to 2 HP and 1 Oculum; at threshold 369 it restores one eighth HP, one sixth Oculum and one twentieth Oculum Shield. Oculum: every 300 EXP restores up to 1 HP and 1 Oculum; at threshold 369 it restores one tenth HP, one eighth Oculum and one thirtieth Oculum Shield. Remaining EXP is preserved toward the next recovery.

SAVING SHIELD

Saving Shield is a defensive consumable used with a Free Action, at most once per turn.
When active, if the next damage breaks your last shield, overflow damage does not pass to temporary HP or life.
It does not replace Defense, Oculum Shield, normal Shield, temporary HP or other reductions: it triggers only after the last shield breaks and is consumed when it blocks overflow.

DAYS AND OCULUM CYCLE

Rest and rot tracking are managed as days.
One Day lasts 9 hours.

Calendar units:
- Tremana: 3 days.
- Semana: 6 days.
- Dodemana: 12 days.
- New Phase: mutable season, 36 days or less.
- Full Cycle: 369 days.

The 12 New Phases of the Full Cycle:
- Safe Monster, days 1-36: many monsters lose Grade, become peaceful, give negative karma if killed and have only basic or rare drops.
- Illness, days 37-72: Madness received is doubled, "the others" become visible and Illness Art can be obtained.
- Little Breath, days 73-108: Fate grants more Titles, especially to reborn characters; weather and area pressure are weaker.
- Fertilizing Rains, days 109-144: nauseating mud rains down, sickness is easier to catch and food may cause Nausea.
- The Sun, days 145-150: Solar beings gain +25% stats, rain stops and food below Grade VI rots within at most 2 days.
- Half Cycle, days 151-183: weather becomes bearable almost everywhere and rain is mostly non-magical.
- The Moon, days 184-189: every race is celebrated and accepted; Lunar beings gain +10%.
- The Fate, days 190-225: characters with a Fate are empowered against those without one.
- Infernal Heat, days 226-261: heat is harsher; without drinking, Will is debuffed based on exertion.
- The Null, days 262-297: the void takes some of the fallen and returns them Fate-less, with missing or false memories.
- Overwhelming Ice, days 298-344: cold is harsher; without heat, Materia is lost and freezing becomes a risk.
- Last Cycle, days 334-369: the past cycle is celebrated, without strong mechanical traits.

REST

The Rest page shows:
- current day of the Oculum Cycle;
- current New Phase;
- day inside the phase;
- Tremana, Semana and Dodemana;
- buttons to move one day forward or backward.

Long rest brings HP to at least 75% of maximum and refills Oculum Shield when present.

ROT

Item rot in the bag is based on the current day.
When an item is added, the app records the day it was obtained.

Example:
- you are on day 10;
- you obtain an apple with PUT 5;
- on day 15 the apple becomes Rotten meat.

Standard results:
- meat or food: Rotten meat;
- materials: Rotted material;
- slime: Rotted slime;
- anything else: Rotted item.

Rotted items of the same type merge into one stack.

FORCE STATE

Force State is checked automatically when HP drop to one quarter or less of maximum life.
The app rolls a random state. Stronger states are rarer, but never impossible.

Possible results:
- Body, Do Not Give Up: +20 + Level + Grade temporary HP, +3 Will, +2 Materia.
- Sharp Eyes: +5 + Level + Grade to attack and defense rolls.
- Oculum Burst: +25 HP, current Oculum equal to life even above the maximum, damage equal to Level + Grade, defense equal to half Level + Grade and minimum duration 9 rolls, including subtraits.
- Adrenaline: +1 fast Reaction and +5 + Level + Grade initiative.
- Vulnerability Reset: resistance to hits, removal of negative temporary penalties and fatigue above threshold.
- Tenacity: removes all temporary penalties and all negative conditions, then applies Regeneration for 3 turns.
- Exhaustion: -2 to attack and defense rolls, -5 - Level - Grade to damage.
- Nothing: no effect.

The state applies automatically when you take damage or edit HP. When Oculum Burst ends, the automatic outcome is rolled: 56% -1 to Oculum rolls until the next short or long rest, 36% +1 Ash, 9% +3 Ash. When HP rise above the threshold after the minimum duration, the app resets it and prepares for the next crisis.

MAP AND TOKENS

On the offline map you can use tokens derived from sheets or created from already generated images.
Token size can be changed quickly with + and - buttons directly on the map.
Right-click or long press opens options and turn order tools.

Tokens linked to turn order use their stats. At each new turn, available movement resets.
Players can move only their own tokens unless the Master allows otherwise.

DUNGEON

The "School day" theme unlocks automatically if you reach floor 3 with Modern School Art chosen in the run.
It also remains purchasable from dungeon unlocks, so older progressions can still recover it.

Kitty Slime unlocks by selecting Hoshy Art or by having a sheet named Hoshy at level 5 or higher.
It has very high life and low damage. When it receives an attack, it has a 50% chance to create a copy, up to two copies.
Copies have half its stats, are easier to hit than the main character and attack with it.

RUN EQUIPMENT

Inside the dungeon, you can change weapon, costume and Oculus only with things found or bought during the current run.
Weapons can appear in events and shops. Some locked weapons can appear rarely, while unlocked ones are more common.
Costumes follow the same rule: you can wear them only after finding them in the run, even when they belong to already unlocked content.

Oculus items let you add Oculum Skills from other Oculum Arts, up to 9 active skills in the run.
When you install an Oculus, the scene is described this way: "Togli un tuo occhio, fa male, lo sostituisci con un oculus pieno di potere."
Oculus items from already unlocked Arts are more common; locked ones are rare.

SUMMONABLE NPCS

NPCs found during the run do not join the permanent party.
They enter a summon queue and can automatically replace an ally when someone dies or disappears.
If you remove them manually, they are not summoned automatically again until you add them back.

COSTUME: WRONG SPARE HEART

Wrong Spare Heart is a risky costume.
When worn, it greatly reduces maximum life, grants one Rebirth and regenerates 20 to 150 HP each combat turn.
The bonus is strong, but the life reduction makes heavy hits and sudden-damage rooms dangerous.

From Grade VI, the Stone Eye and Scale event can appear.
The stone eye watches an empty scale. You can place every drop and all Postea Runic Metal owned in the run.
The room fuses everything at once like a stronger blacksmith:
- increases weapon damage;
- increases weapon defense;
- adds resistances from drop elements;
- may generate Dust, run critical, Oculum Shield and blacksmith favor.

If you have nothing to fuse, the event does not block the run and grants Oculum Shield.

PERFORMANCE

The app must stay smooth on phone, desktop and macOS.
Optimizations must reduce calculations and redraws without removing decorations, painters, themes or existing features.
''',
  ),
  ManualSection(
    titleIt: 'Aggiornamento — Costrutto Rinsecchito, Larva Bianca e cartelle',
    titleEn: 'Update — Withered Construct, White Larva and folders',
    contentIt: r'''
Costrutto Rinsecchito e Larva Bianca sono mostri iniziali di Grado 0–I. Il punto debole della Larva Bianca è il ventre inferiore esposto mentre striscia. I loro punti base restano distinti dalla crescita per livello. La Patalpa evocata usa il budget di statistiche previsto per il suo livello, distribuito 20% Resilienza, 50% Volontà e 30% Materia; non avendo Oculum, nel 75% degli spawn non ottiene il punto extra di Resilienza per livello, mentre nel 25% lo ottiene. La scheda conserva distribuzione ed esito. Il Richiamo si usa una volta ogni tre fight completati, conteggiati dalla turnistica senza duplicare uno stesso scontro; fuori da uno scontro attivo, online o offline, il tasto tematico «CD ripristinata» azzera il cooldown.

Il Costrutto parte con Resilienza 2, Volontà 3, Materia 1 e Oculum 3. Usa scudi e Ricordo Vitale: 1 Oculum all’attivazione e 1 a ogni successivo inizio turno, per tanti turni quanto Oculum prima dell’attivazione. Se non può mantenere il costo, l’effetto termina. Ramo spezzato aggiunge +4/+12/+34 e Oculum; nella seconda forma il bonus complessivo è ×1,5, nella terza ×2. Gli arrotondamenti sono per difetto. Il nucleo rotto debole copre Grado 0–III; i rami sono materiale. Il cuore raro cura il 90% della Vita massima, senza superarla, e concede Ricordo Vitale per 1d9 turni senza costo di mantenimento.

La Larva parte con Resilienza 1, Volontà 2, Materia 0 e Oculum 0. Le sue mosse sono gratuite e hanno cooldown. Assalto aggiunge +5/+15/+45, più Oculum ×1/×1,5/×2. Infestazione genera 1d100 / 1d200+20 / 1d250+100 larve da 1 Vita e mostra la riserva come barra Vita rossa sotto quella del personaggio. Dopo Scudi e HP temporanei, una larva si sacrifica per ogni danno; il danno rimanente raggiunge il padrone. Una nuova Nidiata sostituisce quella precedente. Anche chi apprende Infestazione con una scroll può generare la barra; l'apprendimento dalla pergamena è raro e segue le probabilità della difficoltà. La scroll si consuma quando la tecnica viene usata. I ranghi della scroll aggiungono il Livello dell'utilizzatore: I 1d50+20+livello; II 1d100+30+livello; III 1d120+50+livello; IV 1d200+60+livello; V 1d200+100+livello; VI 1d250+120+livello; VII 1d250+150+livello; VIII 1d250+200+livello; IX 2d250+200+livello. Scavata permette di scegliere fuga con tiro Velo oppure svantaggio alto al bersaglio. Il terreno deve permettere di scavare, secondo il Master.

Un 20 naturale sul Drop della Larva dà una scroll Nidiata nella forma disponibile al mostro. La scroll si consuma usando la mossa; apprenderla resta raro secondo le regole delle scroll e la difficoltà. Non assegna automaticamente la skill.

Impostazioni iniziali del catalogo, modificabili: forme ai livelli 0/3/6; CD Assalto 2/3/4, Nidiata 4/6/8, Scavata 3/4/5; svantaggio alto di Scavata −6 per un tiro; probabilità del cuore 3%. Questi sono valori di bilanciamento iniziali, distinti dalle conferme numeriche dell’utente. Gli editor conservano costi, cooldown, effetti e usi alternativi nel JSON.

Le Schede possono essere organizzate in cartelle e sottocartelle rinominabili. Tieni premuta una scheda per creare una cartella, scegliere dove spostarla o attivare lo spostamento libero; tieni premuta una cartella per rinominarla o crearvi una sottocartella. L’organizzazione si salva nella campagna e non cambia gli identificativi usati da turnistica, mappe e condivisioni.

I parser delle formule riconoscono floor(...), ceil(...) e round(...). Gli effetti possono avere usi alternativi separati: scegli la modalità e vengono applicati soltanto i suoi effetti, più quelli comuni.
''',
    contentEn: r'''
Initial Grade 0–I monsters retain separate base and level stats. The construct has Resilience 2, Will 3, Materia 1 and Oculum 3. Vital Memory costs 1 Oculum per turn. Its rare heart restores 90% maximum HP, capped, and grants 1d9 turns of Vital Memory without upkeep.
The larva has Resilience 1, Will 2, Materia 0 and Oculum 0. Its free cooldown skills include Assault, a sacrificial brood and Burrow with a Veil escape option. Infestation displays generated larvae as a red health bar beneath the character's health; after shields and temporary HP, each damage point sacrifices one larva before the remaining damage reaches the owner. A new brood replaces the previous one. A scroll learner uses the same red pool; learning is rare and follows the difficulty chance, and the scroll is consumed on use. Scroll ranks add the user's level: I 1d50+20+level; II 1d100+30+level; III 1d120+50+level; IV 1d200+60+level; V 1d200+100+level; VI 1d250+120+level; VII 1d250+150+level; VIII 1d250+200+level; IX 2d250+200+level.
Sheet folders are nested, renameable and saved per campaign without changing sheet IDs. Formula functions floor, ceil and round and alternate activation modes remain editable in JSON.
''',
  ),
];

const ManualSection oculumCycleCrisisDungeonManualSection = ManualSection(
  titleIt: '24. Ciclo, crisi, mappa e dungeon',
  titleEn: '24. Cycle, Crisis, Map and Dungeon',
  contentIt: r'''
Queste regole descrivono il tempo di Oculum, le crisi automatiche e le attività di esplorazione. Le formule generali di vita, danno, critici ed EXP restano nelle sezioni precedenti e qui non vengono ripetute.

GIORNI E CICLO OCULUM

Un Giorno dura 9 ore. Tre Giorni formano una Tremana, sei una Semana e dodici una Dodemana. Un Ciclo Pieno dura 369 Giorni ed è diviso in dodici Nuove Fasi:
- Safe Monster, Giorni 1-36: molti mostri perdono il Grado, diventano pacifici e non offrono drop oltre quelli base o rari; ucciderli assegna Karma negativo;
- Illness, Giorni 37-72: la Follia ricevuta raddoppia, gli "altri" diventano visibili e può emergere una Illness Art;
- Little Breath, Giorni 73-108: il Fato concede più Titoli, soprattutto ai personaggi con Rebirth, mentre clima e pressione delle aree si attenuano;
- Piogge Fertilizzanti, Giorni 109-144: piove fango, i malanni sono più facili e il cibo può causare Nausea;
- The Sun, Giorni 145-150: i Solari ottengono +25% alle statistiche, non piove e il cibo sotto Grado VI marcisce entro 2 Giorni;
- Mezzo Ciclo, Giorni 151-183: il clima torna più sostenibile e le piogge sono soprattutto naturali;
- The Moon, Giorni 184-189: si celebra l'accettazione delle razze e i Lunari ottengono +10%;
- The Fate, Giorni 190-225: chi possiede un Fato è avvantaggiato contro chi ne è privo;
- Caldo Infernale, Giorni 226-261: senza bere, il caldo riduce la Volontà in base alla fatica;
- The Null, Giorni 262-297: il vuoto può restituire alcuni caduti Senza Fato, con ricordi mancanti o falsi;
- Ghiaccio Imponente, Giorni 298-344: senza calore si perde Materia e si rischia il congelamento;
- Ultimo Ciclo, Giorni 334-369: si celebra il ciclo trascorso senza un modificatore meccanico dominante.

RIPOSO E PUTREFAZIONE

La pagina Riposo mostra Giorno, Nuova Fase, Tremana, Semana e Dodemana. Il riposo lungo porta gli HP ad almeno il 75% del massimale e ricarica lo Scudo Oculum quando presente; lo Scudo normale consumato non ritorna. Ogni oggetto conserva il Giorno di ottenimento: raggiunta la sua durata PUT, diventa Carne marcia, Materiale putrefatto, Slime putrefatto oppure Oggetto putrefatto. Risultati uguali si uniscono nello stesso stack.

STATO DI FORZA

Quando gli HP scendono a un quarto o meno del massimo, la scheda esegue un solo controllo di crisi. Il risultato può essere Corpo non Mollare, Occhi Attenti, Esplosione di Oculum, Adrenalina, Azzeramento delle Vulnerabilità, Tenacia, Stanchezza oppure nessun effetto. Tenacia rimuove i malus e applica Rigenerazione percentuale per 3 turni. Esplosione di Oculum dura almeno 9 tiri, compresi quelli dei sottotratti. Al termine applica il proprio esito automatico; lo Stato di Forza si azzera soltanto quando la durata minima è conclusa e gli HP tornano sopra la soglia.

MAPPA, TOKEN E TURNISTICA

I token possono provenire dalle schede o da immagini, essere ridimensionati e collegati alla turnistica. All'inizio di ogni turno il movimento disponibile viene ripristinato. Un giocatore muove i propri token; il Master può concedere permessi diversi. Barre, stati, rotazione, visibilità e condizioni seguono i dati del token condiviso.

OCULUM DUNGEON

Armi, costumi e Oculus utilizzabili in una run devono essere trovati o acquistati durante quella run. Gli sblocchi permanenti aumentano la frequenza dei contenuti ma non li equipaggiano automaticamente. Un Oculus può aggiungere Skill provenienti da altre Oculum Art fino a 9 Skill attive. Gli NPC incontrati entrano nella coda di evocazione, non nel party permanente; se vengono rimossi manualmente non tornano finché non sono riaggiunti.

Il tema Giorno di scuola si sblocca raggiungendo il piano 3 con Art Scolastica Moderna. Kitty Slime si sblocca con Art Hoshy o con una scheda Hoshy almeno di livello 5; quando subisce un attacco ha il 50% di probabilità di generare una copia, fino a due copie, ciascuna con metà statistiche.

Dal Grado VI può comparire Occhio di Pietra e Bilancia. L'evento fonde drop e Metallo Runico Postea della run per migliorare l'arma e può generare Dust, critico run, Scudo Oculum o favore del fabbro. Se non esiste nulla da fondere, concede Scudo Oculum e non blocca la run.

STATI OCULUM AL RISVEGLIO

Oculum addormentato azzera immediatamente l'Oculum disponibile quando viene ottenuto. Finche resta attivo, ogni fonte che dona, recupera o rigenera Oculum concede la meta arrotondata per difetto; costi e consumi non vengono dimezzati. Il personaggio si risveglia dopo due riposi lunghi oppure dopo due riposi brevi e un riposo lungo. Il risveglio rimuove soltanto la condizione: Oculum attuale, temporaneo e massimo, caratteristiche e potenziamenti permanenti restano invariati.

I tiri non consumano statistiche quando Consumo elevato è disattivato, salvo le eccezioni speciali già indicate: il tiro Fortuna spende Fortuna se disponibile, i costi espliciti di Skill, Art, Open e Titoli restano validi e la dispersione Oculum segue la propria regola. Quando Consumo elevato è attivo consuma 1 punto della statistica principale collegata a ogni tiro valido. Un tiro su una statistica usa quella statistica; un tiro su un sottotratto usa la statistica principale del suo gruppo. Riflessi usa Materia e Percezione usa Oculum. Resilienza e Volontà non scendono sotto 1; Materia e Oculum non scendono sotto 0. Entrambi gli stati possono essere attivati da una Skill. Al riposo lungo possono comparire in base alla fase, alla Fortuna nelle Risorse e alla difficoltà della campagna; durante le Piogge fertilizzanti la probabilità base è 50%.

MODALITA GUIDATA, VELOCE E ASPETTO

La modalità guidata mostra spiegazioni semplici ed esempi accanto ai comandi principali. La modalità veloce nasconde queste spiegazioni ma non elimina funzioni. In Impostazioni, Aspetto e modalità raccoglie design, temi old school, caratteri e stili della Vita con anteprima. Cuori Occhio Oculum rappresenta la percentuale di HP con cinque cuori-occhio compatti; il misuratore Oculum conserva l'occhio centrale e usa dieci fiammelle per la percentuale disponibile. Le altre barre hanno forme e segni realmente distinti. Queste opzioni cambiano soltanto la presentazione e non i dati di gioco.
''',
  contentEn: r'''
These rules cover Oculum time, automatic crises and exploration activities. General life, damage, critical and EXP formulas remain in the previous sections and are not repeated here.

DAYS AND THE OCULUM CYCLE

One Day lasts 9 hours. Three Days make a Tremana, six a Semana and twelve a Dodemana. A Full Cycle lasts 369 Days and contains twelve New Phases:
- Safe Monster, Days 1-36: many monsters lose Grade, become peaceful and offer only basic or rare drops; killing them grants negative Karma;
- Illness, Days 37-72: received Madness doubles, the "others" become visible and an Illness Art may emerge;
- Little Breath, Days 73-108: Fate grants more Titles, especially to Rebirth characters, while weather and area pressure weaken;
- Fertilizing Rains, Days 109-144: mud rains down, illnesses spread more easily and food may cause Nausea;
- The Sun, Days 145-150: Solar beings gain +25% stats, rain stops and food below Grade VI rots within 2 Days;
- Half Cycle, Days 151-183: weather becomes more sustainable and rain is mostly natural;
- The Moon, Days 184-189: races are celebrated and Lunar beings gain +10%;
- The Fate, Days 190-225: those who possess a Fate are empowered against those without one;
- Infernal Heat, Days 226-261: without drinking, heat reduces Will according to fatigue;
- The Null, Days 262-297: the void may return some fallen without Fate and with missing or false memories;
- Overwhelming Ice, Days 298-344: without heat, Materia is lost and freezing becomes a risk;
- Last Cycle, Days 334-369: the past cycle is celebrated without one dominant mechanical modifier.

REST AND ROT

The Rest page shows Day, New Phase, Tremana, Semana and Dodemana. A long rest brings HP to at least 75% of maximum and refills Oculum Shield when present; spent normal Shield does not return. Every item records the Day it was obtained. When its PUT duration expires, it becomes Rotten Meat, Rotted Material, Rotted Slime or Rotted Item. Equal results merge into one stack.

FORCE STATE

When HP fall to one quarter or less of maximum, the sheet makes one crisis check. The result may be Body, Do Not Give Up; Sharp Eyes; Oculum Burst; Adrenaline; Vulnerability Reset; Tenacity; Exhaustion; or no effect. Tenacity removes penalties and applies percentage Regeneration for 3 turns. Oculum Burst lasts at least 9 rolls, including subtrait rolls. Its automatic aftermath is resolved at the end; Force State resets only after the minimum duration ends and HP rise above the threshold.

MAP, TOKENS AND TURN ORDER

Tokens may come from sheets or images, can be resized and linked to turn order. Available movement resets at the start of each turn. Players move their own tokens unless the Master grants different permissions. Bars, states, rotation, visibility and conditions follow the shared token data.

OCULUM DUNGEON

Weapons, costumes and Oculus items used in a run must be found or bought during that run. Permanent unlocks increase content frequency but never equip it automatically. An Oculus can add Skills from other Oculum Arts up to 9 active Skills. Encountered NPCs enter the summon queue rather than the permanent party; manually removed NPCs do not return until added again.

The School Day theme unlocks by reaching floor 3 with Modern School Art. Kitty Slime unlocks through Hoshy Art or a level 5 or higher Hoshy sheet; when attacked, it has a 50% chance to create a copy, up to two copies, each with half its stats.

From Grade VI, the Stone Eye and Scale event may appear. It fuses run drops and Postea Runic Metal to improve a weapon and may produce Dust, a run critical, Oculum Shield or blacksmith favor. If nothing can be fused, it grants Oculum Shield and never blocks the run.

OCULUM STATES ON WAKING

Sleeping Oculum immediately clears available Oculum when acquired. While active, every source that grants, recovers or regenerates Oculum gives half rounded down; costs and spending are not halved. The character wakes after two long rests or after two short rests and one long rest. Waking only removes the condition: current, temporary, and maximum Oculum, traits, and permanent upgrades remain unchanged.

Rolls do not consume stats while High Consumption is disabled, except for the stated special cases: a Luck roll spends Luck when available, explicit Skill, Art, Open and Title costs still apply, and Oculum dispersion follows its own rule. While High Consumption is active it spends 1 point from the linked main stat for every valid roll. A stat roll uses that stat; a subtrait roll uses the main stat of its group. Reflexes uses Matter and Perception uses Oculum. Resilience and Will cannot fall below 1; Matter and Oculum cannot fall below 0. Both states can be activated by a Skill. They may appear after a long rest according to phase, Luck in Resources and campaign difficulty; during Fertilizing Rains the base chance is 50%.

GUIDED MODE, FAST MODE AND APPEARANCE

Guided mode shows simple explanations and examples beside the main controls. Fast mode hides these explanations without removing features. In Settings, Appearance and modes groups designs, old-school themes and Health styles with a preview. Oculum Eye Hearts represents HP percentage with ten eye-hearts; the Oculum meter keeps the central eye and uses ten flames for the available percentage. These options change presentation only, never game data.
''',
);

final List<ManualSection> activeManualSections =
    List<ManualSection>.unmodifiable(<ManualSection>[
      ...oculumManualSections,
      oculumCycleCrisisDungeonManualSection,
    ]);

String oculumManualPdfText(String value) {
  final normalized = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('•', '- ')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('→', '->')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...')
      .replaceAll('¼', '1/4')
      .replaceAll('½', '1/2')
      .replaceAll('¾', '3/4')
      .replaceAll('⅓', '1/3')
      .replaceAll('⅔', '2/3');
  final out = StringBuffer();
  for (final rune in normalized.runes) {
    if (rune == 10 || rune == 9 || (rune >= 32 && rune <= 126)) {
      out.writeCharCode(rune);
      continue;
    }
    if (rune >= 160 && rune <= 255) {
      out.writeCharCode(rune);
      continue;
    }
    out.write('?');
  }
  return out.toString();
}

bool _oculumManualPdfLooksLikeHeading(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty || trimmed.length > 82) return false;
  final letters = trimmed.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
  return letters.length >= 4 && letters == letters.toUpperCase();
}

List<pw.Widget> _oculumManualPdfBodyWidgets(
  String value, {
  required pw.TextStyle bodyStyle,
  required pw.TextStyle subheadingStyle,
}) {
  final text = oculumManualPdfText(value).trim();
  if (text.isEmpty) return const <pw.Widget>[];
  final widgets = <pw.Widget>[];
  for (final paragraph in text.split(RegExp(r'\n{2,}'))) {
    final lines = paragraph
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) continue;

    if (lines.length == 1 && _oculumManualPdfLooksLikeHeading(lines.first)) {
      widgets.add(pw.SizedBox(height: 5));
      widgets.add(pw.Text(lines.first, style: subheadingStyle));
      widgets.add(pw.SizedBox(height: 3));
      continue;
    }

    for (final line in lines) {
      if (line.startsWith('- ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 10, child: pw.Text('-', style: bodyStyle)),
                pw.Expanded(
                  child: pw.Text(
                    line.substring(2).trim(),
                    style: bodyStyle,
                    textAlign: pw.TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(
              line,
              style: bodyStyle,
              textAlign: pw.TextAlign.left,
            ),
          ),
        );
      }
    }
    widgets.add(pw.SizedBox(height: 3));
  }
  return widgets;
}

Future<Uint8List> oculumBuildManualPdf({required bool english}) async {
  final document = pw.Document(
    title: english ? 'Oculum Rulebook' : 'Manuale di Oculum',
    author: 'Oculum',
    subject: english
        ? 'Complete rules exported by the Oculum app'
        : 'Regolamento completo esportato dall app Oculum',
  );
  final baseFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'),
  );
  final italicFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Poppins-Italic.ttf'),
  );
  final theme = pw.ThemeData.withFont(
    base: baseFont,
    bold: boldFont,
    italic: italicFont,
    boldItalic: italicFont,
  );
  final titleStyle = pw.TextStyle(
    font: boldFont,
    fontSize: 29,
    color: PdfColor.fromHex('#392719'),
  );
  final sectionStyle = pw.TextStyle(
    font: boldFont,
    fontSize: 17,
    color: PdfColor.fromHex('#392719'),
  );
  final subheadingStyle = pw.TextStyle(
    font: boldFont,
    fontSize: 11.5,
    color: PdfColor.fromHex('#85602D'),
  );
  final bodyStyle = pw.TextStyle(
    font: baseFont,
    fontSize: 10.2,
    lineSpacing: 2.2,
    color: PdfColors.grey900,
  );
  final smallStyle = pw.TextStyle(
    font: baseFont,
    fontSize: 8.5,
    color: PdfColors.grey700,
  );

  document.addPage(
    pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(46),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Spacer(flex: 2),
          pw.Container(
            width: 58,
            height: 5,
            color: PdfColor.fromHex('#85602D'),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            english ? 'OCULUM RULEBOOK' : 'MANUALE DI OCULUM',
            style: titleStyle,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            english
                ? 'Rules, progression and play procedures'
                : 'Regole, progressione e procedure di gioco',
            style: pw.TextStyle(
              font: italicFont,
              fontSize: 15,
              color: PdfColor.fromHex('#705634'),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            english
                ? 'A complete reference generated from the same manual used by the app. Read the core chapters in order, then use the operational chapters during play.'
                : 'Per cominciare, leggi le statistiche, i tiri e la crescita. Durante la partita torna ai capitoli su danni, risorse e poteri; la guida alla scheda ti aiuta a trovare i comandi.',
            style: bodyStyle,
            textAlign: pw.TextAlign.left,
          ),
          pw.Spacer(flex: 3),
          pw.Text(
            english
                ? 'Updated rules edition'
                : 'Edizione con regole aggiornate',
            style: smallStyle,
          ),
        ],
      ),
    ),
  );

  document.addPage(
    pw.MultiPage(
      maxPages: 100,
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(38, 42, 38, 40),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.deepPurple200, width: 0.6),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('OCULUM', style: smallStyle),
            pw.Text(english ? 'RULEBOOK' : 'MANUALE', style: smallStyle),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${context.pageNumber}', style: smallStyle),
      ),
      build: (context) {
        final widgets = <pw.Widget>[
          pw.Text(english ? 'Contents' : 'Indice', style: sectionStyle),
          pw.SizedBox(height: 12),
          for (final section in activeManualSections)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(
                oculumManualPdfText(
                  english ? section.titleEn : section.titleIt,
                ),
                style: bodyStyle.copyWith(font: boldFont),
              ),
            ),
        ];

        for (final section in activeManualSections) {
          widgets.add(
            section == activeManualSections.first
                ? pw.NewPage()
                : pw.NewPage(freeSpace: 140),
          );
          widgets.add(pw.SizedBox(height: 16));
          widgets.add(
            pw.Text(
              oculumManualPdfText(english ? section.titleEn : section.titleIt),
              style: sectionStyle,
            ),
          );
          widgets.add(pw.SizedBox(height: 10));
          widgets.addAll(
            _oculumManualPdfBodyWidgets(
              english ? section.contentEn : section.contentIt,
              bodyStyle: bodyStyle,
              subheadingStyle: subheadingStyle,
            ),
          );
        }
        return widgets;
      },
    ),
  );

  return document.save();
}

// Kept as a compact fallback draft, but the app renders the canonical manual
// above so rule updates have one source of truth.
const List<ManualSection> legacyActiveManualSections = [
  ManualSection(
    titleIt: '1. Fondamento di Oculum',
    titleEn: '1. Core of Oculum',
    contentIt: r'''
Oculum e un mondo dove la forza non si misura nei muscoli o nel numero di alleati, ma nella potenza degli occhi.

Le quattro statistiche principali definiscono ogni individuo:
- Resilienza
- Volontà
- Materia
- Oculum

Le statistiche possono essere usate anche in modo creativo nel roleplay, quando la scena lo permette.
''',
    contentEn: r'''
Oculum is a world where strength is not measured by muscles or by the number of allies, but by the power of the eyes.

The four main stats define every individual:
- Resilience
- Will
- Materia
- Oculum

Stats may also be used creatively in roleplay when the scene allows it.
''',
  ),
  ManualSection(
    titleIt: '2. Statistiche',
    titleEn: '2. Stats',
    contentIt: r'''
Resilienza:
- ogni punto di Resilienza aumenta la vita massima di 10 HP, a ogni Grado;
- rappresenta tenuta fisica e mentale;
- 100 Resilienza = 1 Vera Resilienza;
- 10 Vera Resilienza = 1 Resilius;
- 10 Resilius = 1 Resilium.

Volontà:
- potenzia l'attacco;
- contribuisce a metà Difesa;
- ogni 3 punti aumenta il tiro d'attacco;
- 1 Volontà equivale a 3 kg di inventario.

Materia:
- contribuisce a metà Difesa;
- ogni 2 punti aumenta la CM;
- ogni 5 punti aumenta l'Iniziativa.

Oculum:
- e il potere magico personale;
- ogni punto di Oculum ottenuto aggiunge 1 Oculum utilizzabile;
- ogni punto aumenta di +2 la potenza delle Arti;
- può essere usato nei tiri per aumentare il bonus, se contestualizzato.
''',
    contentEn: r'''
Resilience:
- each Resilience point adds 10 maximum HP at every Grade;
- represents physical and mental endurance;
- 100 Resilience = 1 True Resilience;
- 10 True Resilience = 1 Resilius;
- 10 Resilius = 1 Resilium.

Will:
- empowers attacks;
- contributes to half Defense;
- every 3 points increases the attack roll;
- 1 Will equals 3 kg of carrying capacity.

Materia:
- contributes to half Defense;
- every 2 points increases CM;
- every 5 points increases Initiative.

Oculum:
- is personal magical power;
- each Oculum point gained adds 1 usable Oculum;
- each point increases Art power by +2;
- it can be used in rolls to increase the bonus, if contextualized.
''',
  ),
  ManualSection(
    titleIt: '3. Crescita',
    titleEn: '3. Growth',
    contentIt: r'''
Al passaggio di livello:
- +3 punti alla statistica più utilizzata;
- +2 punti alla seconda statistica più utilizzata;
- +1 punto a tutte le altre;
- +6 Scudo.

Nei tiri che non sono attacco o difesa, il bonus e pari a Statistica / 2 + Livello + Grado x6.

Esempio:
20 Resilienza in un tiro normale, con livello 2 e Grado I, diventa 1d20 + 18.
''',
    contentEn: r'''
On level up:
- +3 points to the most used stat;
- +2 points to the second most used stat;
- +1 point to all the others;
- +6 Shield.

For rolls that are not attack or defense, the bonus is Stat / 2 + Level + Grade x6.

Example:
20 Resilience on a normal roll, with level 2 and Grade I, becomes 1d20 + 18.
''',
  ),
  ManualSection(
    titleIt: '4. DT, CM e VC',
    titleEn: '4. DT, CM and VC',
    contentIt: r'''
DT = Difficoltà Tiro.
E la soglia da superare per riuscire in un'azione.

CM = Classe Materia.
E la soglia da superare per colpire un bersaglio.

VC = Volontà Combattiva.
E il bonus principale all'attacco.

In DT, CM, VC, Danno, Difesa, Iniziativa e tiri statistica vanno sempre contati:
- Livello;
- Grado x6.

Scala DT:
- 1 estremamente facile, critico invariato;
- 3 molto facile;
- 5 facile;
- 8 medio facile;
- 10 normale;
- 12 medio difficile;
- 15 difficile;
- 18 molto difficile;
- 20 impossibile, critico invariato.

La DT aumenta di +1 per ogni Livello in più del nemico o della cosa, e di +6 per ogni Grado.
In compenso ogni Livello dona +1 ai tiri e ogni Grado dona +6.

Nel calcolo dell'app:
- VC = Livello + Grado x6 + Volontà / 3;
- CM = Livello + Grado x6 + Materia / 2;
- Danno = Volontà + arma migliore + Livello + Grado x6;
- Iniziativa = Materia / 5 + Livello + Grado x6;
- Difesa = (Materia + Volontà) / 2 + Livello + Grado x6.
''',
    contentEn: r'''
DT = Roll Difficulty.
It is the threshold to overcome for an action.

CM = Materia Class.
It is the threshold to overcome in order to hit a target.

VC = Combat Will.
It is the main attack bonus.

DT, CM, VC, Damage, Defense, Initiative, and stat rolls always count:
- Level;
- Grade x6.

DT scale:
- 1 extremely easy, critical unchanged;
- 3 very easy;
- 5 easy;
- 8 medium easy;
- 10 normal;
- 12 medium hard;
- 15 hard;
- 18 very hard;
- 20 impossible, critical unchanged.

DT increases by +1 for each extra Level of the enemy or thing, and by +6 for each Grade.
In return, each Level gives +1 to rolls and each Grade gives +6.

In the app:
- VC = Level + Grade x6 + Will / 3;
- CM = Level + Grade x6 + Materia / 2;
- Damage = Will + weapon bonus (strongest in full, each secondary at one third with its confirmed rounding) + Level + Grade x6;
- Initiative = Materia / 5 + Level + Grade x6;
- Defense = (Materia + Will) / 2 + Level + Grade x6.
''',
  ),
  ManualSection(
    titleIt: '5. Gradi',
    titleEn: '5. Grades',
    contentIt: r'''
Ogni Grado concede:
- +36 Scudo;
- +1 Scudo Critico;
- la possibilità di livellare Titoli pari al Grado raggiunto.

Puoi livellare solo Titoli già evoluti. Livellarli li riforgia:
- ricevono una nuova quest;
- proseguono oltre la forma precedente;
- possono ottenere nuove skill;
- evolvono in base al tuo volere e alle tue azioni.
''',
    contentEn: r'''
Each Grade grants:
- +36 Shield;
- +1 Critical Shield;
- the ability to level Titles equal to the reached Grade.

You may only level Titles that are already evolved. Leveling them reforges them:
- they receive a new quest;
- they continue beyond their previous form;
- they may gain new skills;
- they evolve based on your will and actions.
''',
  ),
  ManualSection(
    titleIt: '6. Soglie dei Gradi',
    titleEn: '6. Grade Thresholds',
    contentIt: r'''
Grado I: livello 10, Rebirth 8
Grado II: livello 30, Rebirth 20
Grado III: livello 40, Rebirth 30
Grado IV: livello 50, Rebirth 40
Grado V: livello 60, Rebirth 50
Grado VI: livello 70, Rebirth 60
Grado VII: livello 80, Rebirth 70
Grado VIII: livello 90, Rebirth 80
Grado IX: livello 100, Rebirth 90
Grado X: livello 120, Rebirth 110
Grado XI: livello 150, Rebirth 130
Grado XII: livello 200, Rebirth 190
''',
    contentEn: r'''
Grade I: level 10, Rebirth 8
Grade II: level 30, Rebirth 20
Grade III: level 40, Rebirth 30
Grade IV: level 50, Rebirth 40
Grade V: level 60, Rebirth 50
Grade VI: level 70, Rebirth 60
Grade VII: level 80, Rebirth 70
Grade VIII: level 90, Rebirth 80
Grade IX: level 100, Rebirth 90
Grade X: level 120, Rebirth 110
Grade XI: level 150, Rebirth 130
Grade XII: level 200, Rebirth 190
''',
  ),
  ManualSection(
    titleIt: '7. Titoli del Fato Evoluti',
    titleEn: '7. Evolved Fate Titles',
    contentIt: r'''
Ogni giorno puoi usare un Titolo del Fato evoluto.

Per 9 ore perde momentaneamente l'evoluzione, ma resta fissato al personaggio.

Effetti possibili:
- aumentare un tiro di 1d10;
- fare un critico spirituale, trasformando un tiro molto difficile completato in un critico assicurato con ritiro.

L'uso deve sempre essere contestualizzato.
''',
    contentEn: r'''
Each day you may use one evolved Fate Title.

For 9 hours it temporarily loses its evolution, but remains fixed to the character.

Possible effects:
- increase a roll by 1d10;
- make a spiritual critical, turning a completed very difficult roll into a guaranteed critical with reroll.

The use must always be contextualized.
''',
  ),
  ManualSection(
    titleIt: '8. Morte e Rialzarsi',
    titleEn: '8. Death and Rising',
    contentIt: r'''
Ogni turno una persona caduta in battaglia deve fare un tiro contro la morte.

Ogni fallimento dona una Ferita. A tre Ferite si muore.
Ogni vittoria dona una Volontà di Vita. A tre Volontà di Vita ci si rialza.

Se ti rialzi senza Ferite, con un critico positivo o con più successi del necessario, torni col massimo delle forze.
Altrimenti torni con metà HP e metà Oculum.

Aiutare un compagno caduto richiede un'azione e non può fargli del male, eccetto con 1 critico:
- 1 critico: gli dai una Ferita;
- 2-7: niente;
- 8-15: gli doni 1 Volontà di Vita;
- 16-19: gli doni 2 Volontà di Vita;
- 20: lo rialzi al massimo delle sue forze.
''',
    contentEn: r'''
Every turn, a person fallen in battle must make a death roll.

Each failure gives one Wound. At three Wounds, they die.
Each success gives one Will to Live. At three Will to Live, they rise.

If they rise with no Wounds, with a positive critical, or with more successes than needed, they return at full strength.
Otherwise they return with half HP and half Oculum.

Helping a fallen companion requires an action and cannot harm them, except on a critical 1:
- critical 1: you give them one Wound;
- 2-7: nothing;
- 8-15: you give 1 Will to Live;
- 16-19: you give 2 Will to Live;
- 20: they rise at full strength.
''',
  ),
  ManualSection(
    titleIt: '9. Moltiplicatori',
    titleEn: '9. Multipliers',
    contentIt: r'''
Tutti i moltiplicatori si sommano e si applicano alla fine.

Esempio:
+50% e +25% non diventano x1.5 x1.25.
Diventano +75% finale.
''',
    contentEn: r'''
All multipliers are added together and applied at the end.

Example:
+50% and +25% do not become x1.5 x1.25.
They become a final +75%.
''',
  ),
  ManualSection(
    titleIt: '10. Karma',
    titleEn: '10. Karma',
    contentIt: r'''
Il Karma e la sensazione a pelle che provi guardando qualcuno.

Non e una verità assoluta:
- può indicare pericolo, fiducia, peso del Fato o una presenza storta;
- può essere alterato, nascosto o illuso;
- fidarsi solo del Karma può portare a errori.

Il Karma e un segnale narrativo, non una prova.
Serve a dare atmosfera, sospetto e lettura istintiva della scena.
''',
    contentEn: r'''
Karma is the gut feeling you get when looking at someone.

It is not an absolute truth:
- it may suggest danger, trust, the weight of Fate, or a twisted presence;
- it can be altered, hidden, or deceived;
- trusting only Karma can lead to mistakes.

Karma is a narrative signal, not proof.
It gives atmosphere, suspicion, and instinctive reading to a scene.
''',
  ),
  ManualSection(
    titleIt: '11. Mastery delle Skill',
    titleEn: '11. Skill Mastery',
    contentIt: r'''
Alcune skill migliorano usandole.

Quando usi una skill adatta alla crescita:
- aumenti di 1 l'Oculum spendibile su quella skill;
- se la tiri al massimo della potenza, l'Oculum spendibile aumenta di 2.

Masterare una skill dona:
- un Titolo d'Apprendimento relativo a quella skill;
- la possibilità di usare la forma successiva dell'abilità;
- il massimale di Oculum usabile della forma successiva, cioe il massimo Oculum della prossima forma.

La Mastery deve seguire l'uso reale della skill nella storia, non solo il numero segnato.
''',
    contentEn: r'''
Some skills improve by being used.

When you use a skill that can grow:
- the spendable Oculum for that skill increases by 1;
- if you roll it at maximum power, the spendable Oculum increases by 2.

Mastering a skill grants:
- a Learning Title tied to that skill;
- the ability to use the next form of the ability;
- the usable Oculum maximum of the next form, meaning the next form's Oculum cap.

Mastery must follow the real use of the skill in the story, not only the number written down.
''',
  ),
  ManualSection(
    titleIt: '12. Allenamento',
    titleEn: '12. Training',
    contentIt: r'''
In allenamento si ottiene EXP in base a come finisce lo scontro.

Se perdi:
- ottieni EXP pari ai danni subiti meno le stats concordate dal Master.

Se vinci:
- ottieni EXP pari ai danni fatti.

La ricompensa di allenamento può essere ricevuta una volta ogni 3 ore.
Prima delle 3 ore puoi continuare ad allenarti, ma non ricevi nuovamente EXP.
''',
    contentEn: r'''
Training grants EXP based on how the fight ends.

If you lose:
- you gain EXP equal to damage taken minus the stats agreed by the Master.

If you win:
- you gain EXP equal to damage dealt.

Training EXP can be received once every 3 hours.
Before 3 hours pass, you may keep training, but you do not gain EXP again.
''',
  ),
  ManualSection(
    titleIt: '13. Risorse e Riposo',
    titleEn: '13. Resources and Rest',
    contentIt: r'''
Obser:
pietre o monete con inciso un occhio. Sono valuta, memoria, pegno e valore rituale.

Ascension Dust:
polvere usata per forgiare, potenziare, ritualizzare, creare cerchi e far ascendere oggetti o poteri.

Cenere:
rappresenta fame, sete, stress, stanchezza e corrosione dell'Oculum.

Riposo breve:
- recupera 25% Cenere, minimo 1;
- recupera metà penalità temporanee;
- recupera metà stats spese.

Riposo lungo:
- recupera 50% Cenere, minimo 3;
- recupera metà Resilienza negativa;
- recupera tutto Oculum negativo;
- recupera tutte le stats spese;
- porta gli HP ad almeno il 75% del massimale.
''',
    contentEn: r'''
Obser:
stones or coins engraved with an eye. They are currency, memory, pledge, and ritual value.

Ascension Dust:
powder used to forge, empower, ritualize, create circles, and ascend items or powers.

Ash:
represents hunger, thirst, stress, exhaustion, and Oculum corrosion.

Short rest:
- recovers 25% Ash, minimum 1;
- recovers half temporary penalties;
- recovers half spent stats.

Long rest:
- recovers 50% Ash, minimum 3;
- recovers half negative Resilience;
- recovers all negative Oculum;
- recovers all spent stats;
- brings HP to at least 75% of maximum.
''',
  ),
  ManualSection(
    titleIt: '14. Stili di Vita',
    titleEn: '14. Ways of Life',
    contentIt: r'''
"In Oculum, cio che provi si vede. Anche se non lo dici, anche se non vuoi. Non e un mondo che premia i duri: e un mondo che li spezza. E poi, a volte, li ricostruisce."

I Due Stili di Vita:

Stile Cittadino, Sicurezza Relativa:
- le citta sono luoghi parzialmente sicuri, protetti da barriere percettive alimentate da antichi Oculi Dormienti;
- si può commerciare, riposare, apprendere e creare legami;
- la pressione psicologica e minore, ma la dipendenza dai più forti e alta;
- i Titoli si manifestano più lentamente, ma si può osservare e pianificare senza pericolo immediato.

Stile Errante, Vita di Grado:
- vivere fuori significa affrontare zone pericolose;
- ogni incontro può essere fatale;
- ogni Titolo può essere condanna o salvezza;
- sopravvivenza, ingegno e coraggio contano più della comodità;
- i mostri sentono il Grado e altri sentono l'Oculum: chi brilla troppo viene cercato.
''',
    contentEn: r'''
"In Oculum, what you feel can be seen. Even if you do not say it, even if you do not want it. It is not a world that rewards the tough: it breaks them. And then, sometimes, rebuilds them."

The Two Ways of Life:

Citizen Style, Relative Safety:
- cities are partially safe places, protected by perceptive barriers powered by ancient Sleeping Oculi;
- people can trade, rest, learn, and form bonds;
- psychological pressure is lower, but dependence on the strong is high;
- Titles manifest more slowly, but one can observe and plan without immediate danger.

Wandering Style, Grade Life:
- living outside means facing dangerous zones;
- every encounter can be fatal;
- every Title can be condemnation or salvation;
- survival, wit, and courage matter more than comfort;
- monsters feel Grade and others feel Oculum: those who shine too brightly are sought.
''',
  ),
  ManualSection(
    titleIt: '15. Calendario di Oculum',
    titleEn: '15. Oculum Calendar',
    contentIt: r'''
Misure del tempo:
- Giorno: 9 ore;
- Tremana: 3 giorni;
- Semana: 6 giorni;
- Dodemana: 12 giorni;
- Nuova Fase: stagione mutevole, 36 giorni o meno;
- Ciclo Pieno: fine dell'anno, 369 giorni.

Le 12 Nuove Fasi:
- Safe Monster, giorni 1-36: molti mostri perdono il Grado, diventano pacifici, danno karma negativo se uccisi e non hanno drop oltre base/rari.
- Illness, giorni 37-72: la Follia raddoppia e gli "altri" diventano visibili; possibile Illness Art.
- Little Breath, giorni 73-108: il Fato dona più Titoli, specialmente ai rebirthati; clima e sentori sono più deboli.
- Piogge Fertilizzanti, giorni 109-144: fango nauseante, malanni più facili, cibo contaminato, maiali di fango aggressivi.
- The Sun, giorni 145-150: Solari +25%, niente pioggia, cibo putrefatto entro massimo 2 giorni se sotto Grado VI.
- Mezzo Ciclo, giorni 151-183: meteo reggibile e piogge principalmente non magiche.
- The Moon, giorni 184-189: festa e accettazione; Lunari +10%.
- The Fate, giorni 190-225: possessori di Fato potenziati contro chi non lo possiede.
- Caldo Infernale, giorni 226-261: caldo estremo, bere spesso o debuff Volontà in base alla fatica.
- The Null, giorni 262-297: il vuoto prende parte dei caduti e li rende Senza Fato con ricordi falsati.
- Ghiaccio Imponente, giorni 298-344: freddo estremo, serve calore o si perde Materia e si rischia congelamento.
- Ultimo Ciclo, giorni 334-369: festa del ciclo passato, senza peculiarita forti.
''',
    contentEn: r'''
Time measures:
- Day: 9 hours;
- Tremana: 3 days;
- Semana: 6 days;
- Dodemana: 12 days;
- New Phase: mutable season, 36 days or less;
- Full Cycle: end of the year, 369 days.

The 12 New Phases:
- Safe Monster, days 1-36: many monsters lose Grade, become peaceful, give negative Karma if killed, and have only base/rare drops.
- Illness, days 37-72: Madness doubles and the "others" become visible; Illness Art can appear.
- Little Breath, days 73-108: Fate grants more Titles, especially to rebirthed people; climate and area feeling are weaker.
- Fertilizing Rains, days 109-144: nauseating mud, easier sickness, contaminated food, aggressive mud pigs.
- The Sun, days 145-150: Solar beings +25%, no rain, food rots within 2 days if below Grade VI.
- Half Cycle, days 151-183: bearable weather and mostly non-magical rain.
- The Moon, days 184-189: celebration and acceptance; Lunar beings +10%.
- The Fate, days 190-225: Fate holders are empowered against non-holders.
- Infernal Heat, days 226-261: extreme heat; drink often or suffer Will debuffs based on effort.
- The Null, days 262-297: the void takes some fallen and returns them Fate-less with false memories.
- Imposing Ice, days 298-344: extreme cold; warmth is needed or Materia drops and freezing begins.
- Last Cycle, days 334-369: celebration of the past cycle, with no strong peculiarities.
''',
  ),
  ManualSection(
    titleIt: '16. Armi, EXP e Villaggi',
    titleEn: '16. Weapons, EXP and Villages',
    contentIt: r'''
Armi: semplice +5, con Titolo +10, con Titolo gradato +20 per Grado.

EXP mostri: conta livello e statistiche sopra le tue. Ogni Grado sopra il tuo aggiunge x1.2. Mini-Boss x1.3, Boss x2; Facile aggiunge 0.1 e Difficile sottrae 0.1 a entrambi.

EXP NPC: conta livello e statistiche sopra le tue, va a te e a tutto il party. Ogni Grado sopra il tuo aggiunge x1.3.

Villaggi: dopo 3 fight visita un villaggio o una taverna. Ogni fight oltre il terzo senza visita dimezza di nuovo l'EXP.

Summon: massimo 5 + Grado EXP, una volta per evocazione. Una Summon tua non da EXP salvo tradimento reale voluto dal Fato.
''',
    contentEn: r'''
Weapons: simple +5, titled +10, graded titled +20 per Grade.

Monster EXP: count levels and stats above yours. Each Grade above yours adds x1.2. Mini-Boss x1.3, Boss x2; Easy adds 0.1 and Hard subtracts 0.1 from both.

NPC EXP: count levels and stats above yours, rewarded to you and the whole party. Each Grade above yours adds x1.3.

Villages: after 3 fights, visit a village or tavern. Each fight after the third without a visit halves EXP again.

Summons: maximum 5 + Grade EXP, once per summon. Your own Summon grants no EXP unless Fate makes it truly betray you.
''',
  ),
  ManualSection(
    titleIt: '17. Critici e Fragilità',
    titleEn: '17. Criticals and Fragility',
    contentIt: r'''
Ogni dado può crittare: il massimo naturale è critico positivo, 1 naturale è critico negativo.
Critico positivo: aggiungi Livello + Grado x6 al tiro.
Critico negativo: togli Livello + Grado x3 dal tiro.

Attacco: applichi Fragilità nella zona bersagliata e +5 danni.
Difesa: ottieni una Reazione contro chi ti ha attaccato.
Iniziativa: ottieni una Reazione.

Catena: primo critico Fragilità Leggera; ogni critico successivo nello stesso fight aumenta lo stadio fino a Fragilità Letale. Un attacco di sorpresa al punto debole può partire da stadi più alti.

Danno letale: x6 danni (+500%); i bonus critici restano distinti.
''',
    contentEn: r'''
Every die can crit: natural maximum is a positive critical, natural 1 is a negative critical.
Positive critical adds half die + Level + Grade x6 to the roll.
Negative critical subtracts half die + Level + Grade x3 from the roll.

Attack: apply Fragility to the targeted zone and +5 damage.
Defense: gain one Reaction against the attacker.
Initiative: gain one Reaction.

Chain: first critical applies Light Fragility; each consecutive critical in the same fight increases the stage up to Lethal Fragility. A surprise weak-point attack may start from higher stages.

Lethal damage: x6 damage (+500%); critical bonuses remain separate.
''',
  ),
  ManualSection(
    titleIt: '18. Cerchi Magici',
    titleEn: '18. Magic Circles',
    contentIt: r'''
I cerchi magici si attivano con polveri, Materia, Oculum o Varianti.

Creazione:
1. Tipo: Difesa, Attacco, Alterazione, Potenziamento, Sigillo, Rito complesso.
2. Emozione: paura, colpa, rabbia, amore, determinazione, ambizione.
3. Energia consumata permanentemente: Oculum, Rune, Null, Resilienza, Materia, Volontà, Follia.

Per finalizzare serve una scroll magica qualsiasi o polveri alchemiche. Se usi una scroll, parte dell'effetto entra nel cerchio in forma indebolita.
''',
    contentEn: r'''
Magic circles are activated with powders, Materia, Oculum, or Variants.

Creation:
1. Type: Defense, Attack, Alteration, Empowerment, Seal, Complex Rite.
2. Emotion: fear, guilt, anger, love, determination, ambition.
3. Permanently consumed energy: Oculum, Runes, Null, Resilience, Materia, Will, Madness.

To finalize one, use any magic scroll or alchemical powders. If a scroll is used, part of its effect enters the circle in weakened form.
''',
  ),
  ManualSection(
    titleIt: '19. Open, Oculum e Sistema Plus',
    titleEn: '19. Opens, Oculum and Plus System',
    contentIt: r'''
Open: usabile una volta ogni 3 ore; ogni nuova sessione riduce il tempo di 1 ora se sei alleato del Fato. Il buff resta fino al recupero. Le Open Skill sono versioni ridotte e restano potenziate per 1 ora dopo l'Open.

Oculum: energia dell'oculus, usata per Oculum Art, cerchi magici e item specifici. Si ricarica dormendo, riposando o con oggetti.

Potenziamento: spendi Oculum entro gli stessi limiti di sblocco di Livello e Grado del sistema precedente. Ogni punto dona +3 al tiro; negli attacchi aggiunge anche +2 Danni per punto speso.
''',
    contentEn: r'''
Open: usable once every 3 hours; each new session reduces the time by 1 hour if allied with Fate. The buff lasts until recovery. Open Skills are reduced versions and stay empowered for 1 hour after the Open.

Oculum: energy of the oculus, used for Oculum Arts, magic circles, and specific items. It recharges through sleep, rest, or items.

Potentiation: spend Oculum within the previous Level and Grade unlock limits. Each point grants +3 to the roll; attacks also gain +2 Damage per point spent.
''',
  ),
  ManualSection(
    titleIt: '20. Titoli, Razze e Art',
    titleEn: '20. Titles, Races and Arts',
    contentIt: r'''
Titoli: Azione, Item, Fato, Apprendimento, Malanno/Benessere, Alchimia/Magia, Chaos, Attributo. Ogni Titolo ha buff, Punto Cieco, Leggenda e possibile Evoluzione. Ogni 3 Titoli indossati se ne mostra uno, priorita agli Evoluti. Grado III, VI e IX danno slot extra. In fight i Titoli non possono essere cambiati; cio che e stato consumato o attivato resta comunque contato fino alla fine del fight.

Titoli del Fato: prima forma della prima skill, seconda forma della seconda skill, terza forma della terza skill.

Titoli Attributo: +1/+3, fino a +6 Evoluti, +7 Reforgiati, +9 Evoluti e Reforgiati; +1 per Grado; massimale Plus 12; tre parole attivate danno +25%.

Razze: razza iniziale senza slot, fino ad altre 3 in storia; ogni razza ha 3 sottorazze. Completare 12 Razze/Sottorazze rivela la vera identita e permette una terza Art.

Art: Oculum, Illness, Emblem, Martial, Null, Rune, Defiled. Rune Art combo al 25%, IV forma, parole componibili, Libri Runici da sei parole, Intensita e Durata sequenziali; Defiled Art a 5 stadi e Open compatibile con le altre. Il master puo aggiungere parole Rune custom con costo e DT propri.
''',
    contentEn: r'''
Titles: Action, Item, Fate, Learning, Illness/Wellness, Alchemy/Magic, Chaos, Attribute. Each Title has buffs, Blind Spot, Legend, and possible Evolution. Every 3 equipped Titles reveal one, prioritizing Evolved ones. Grade III, VI, and IX grant extra slots. During a fight, Titles cannot be changed; anything consumed or activated still counts until the fight ends.

Fate Titles: first form of the first skill, second form of the second skill, third form of the third skill.

Attribute Titles: +1/+3, up to +6 Evolved, +7 Reforged, +9 Evolved and Reforged; +1 per Grade; Plus cap 12; three activated words grant +25%.

Races: starting race uses no slot, up to 3 more in story; each race has 3 subraces. Completing 12 Races/Subraces reveals true identity and allows a third Art.

Arts: Oculum, Illness, Emblem, Martial, Null, Rune, Defiled. Rune Art combos count as 25%, reach form IV, use modular words, Runic Books teach six words, and Intensity/Duration are sequential; Defiled Art has 5 stages and compatible Open. The master can add custom Rune words with their own cost and DT.
''',
  ),

  ManualSection(
    titleIt: '21. Funzionamento dell’app, elementi e ricerca',
    titleEn: '21. App functions, elements and search',
    contentIt: r'''
L’app gestisce schede, salvataggi, immagini, HP, HP temporanei, Scudo, Scudo Oculum, Scudo Critico, Titoli, Open, Skill, Art, inventario, armi, risorse, diario, modalità Master, condivisione online quando disponibile, permessi degli amici, annulla/ripristina, impostazioni colore e ricerca interna.

Danni, protezioni ed elementi:
• ogni arma, armatura o scudo può avere un Tipo danno/protezione;
• se un oggetto vecchio non ha tipo, usa Fisico/Sconosciuto come fallback;
• le formule possono scrivere il tipo vicino al valore, per esempio @Danni+13Fulmine, @Danni+Vol/2 Fuoco, @Danni+⅓Mat Gelo, @Danni+25%Ocu Lunare;
• se più elementi partecipano allo stesso danno, l’elemento dominante è quello con più danno totale;
• il numero del danno usa il colore dell’elemento dominante;
• sotto al danno vengono mostrati gli elementi coinvolti senza duplicati;
• elementi sconosciuti non bloccano il calcolo e usano un colore bianco/grigiastro.

Buff e debuff rapidi:
• sono validi comandi come @Mat-1/3Vol, @Mat-⅓Vol, @Mat-Vol*2, @Difesa+Resilienza e @Danni+Scudo;
• sono validi anche @HP+5, @Vita+5, @HPTemp+Vol1/6, @ScudoOculum+5, @Iniziativa+5, @Movimento+3, @TiroAttacco+1, @TiroDifesa+1, @TiroVolontà+1, @TiroRes+1, @TiroOculum+1 e @TiroStats+1;
• Titoli, Open, Art, Skill, Buff/Malus @ in Riposo/Stati e il campo Buff @ Oggetto dell'Inventario possono contenere comandi @;
• sono validi trigger come @Danni+1OnHit, @Vol+1=-10HP, @HP+1=Vol-1, @HP-10=Stats+1 e @Vol-1=AltreStats+1;
• @Stats e @AllStats agiscono sulle 4 statistiche base; se il trigger consuma HP o una stat, l'app esclude automaticamente cio che rigenererebbe il costo;
• / indica divisione normale, mentre frazioni speciali come ⅓, ¼, ½ e ¾ restano riconosciute;
• i buff @ degli oggetti valgono solo quando l'oggetto e equipaggiato, senza duplicarsi quando lo togli e lo rimetti;
• Refull Vita ricarica HP, HP temporanei dinamici e Scudo Oculum; lo Scudo normale consumato resta consumato;
• il parser non usa eval e rifiuta calcoli impossibili come divisioni per zero, formule vuote, variabili sconosciute o risultati infiniti.

EXP:
• l’EXP può arrivare da Nemico normale, Mini-Boss o Boss;
• Normale = x1, Mini-Boss = x1.3, Boss = x2;
• se il nemico ha Grado superiore al personaggio, ogni Grado sopra aggiunge x1.2;
• l’anteprima mostra l’EXP finale prima dell’applicazione.

Ricerca e navigazione:
• il cerca trova pagine, regole, funzioni, Titoli, Open, Skill, Art, inventario, background e diario;
• la ricerca ignora maiuscole/minuscole, accenti e piccoli errori di scrittura;
• cambiando pagina, la posizione di scorrimento resta conservata per ogni pagina finché la schermata rimane aperta.

Immagini:
• se il crop viene annullato, l’immagine precedente non deve essere cancellata;
• immagini vuote o non valide non devono sostituire una immagine già salvata.
''',
    contentEn: r'''
The app manages sheets, saves, images, HP, temporary HP, Shield, Oculum Shield, Critical Shield, Titles, Opens, Skills, Arts, inventory, weapons, resources, diary, Master mode, online sharing when available, friend permissions, undo/redo, color settings and internal search.

Damage, protections and elements:
• each weapon, armor or shield can have a damage/protection type;
• if an old item has no type, Physical/Unknown is used as safe fallback;
• formulas can write the type next to the value, for example @Danni+13Fulmine, @Danni+Vol/2 Fuoco, @Danni+⅓Mat Gelo, @Danni+25%Ocu Lunare;
• if several elements are involved, the dominant element is the one with the highest total damage;
• the damage number uses the dominant element color;
• involved elements are shown below the damage without duplicates;
• unknown elements never block damage calculation and use a white/grey fallback color.

Quick buffs and debuffs:
• commands such as @Mat-1/3Vol, @Mat-⅓Vol, @Mat-Vol*2, @Difesa+Resilienza and @Danni+Scudo are valid;
• @HP+5, @Vita+5, @HPTemp+Vol1/6, @ScudoOculum+5, @Iniziativa+5, @Movimento+3, @TiroAttacco+1, @TiroDifesa+1, @TiroVolontà+1, @TiroRes+1, @TiroOculum+1 and @TiroStats+1 are valid too;
• Titles, Opens, Arts, Skills, the Rest/Conditions @ Buffs/Debuffs field and the Inventory Item @ Buff field can contain @ commands;
• triggers such as @Damage+1OnHit, @Will+1=-10HP, @HP+1=Will-1, @HP-10=Stats+1 and @Will-1=OtherStats+1 are valid;
• @Stats and @AllStats affect the 4 base stats; if the trigger spends HP or a stat, the app automatically excludes what would regenerate that cost;
• / is normal division, while special fractions such as ⅓, ¼, ½ and ¾ remain recognized;
• item @ buffs count only while the item is equipped, without duplicating when you remove and equip it again;
• Refill Life restores HP, dynamic temporary HP and Oculum Shield; spent normal Shield stays spent;
• the parser does not use eval and rejects impossible calculations such as division by zero, empty formulas, unknown variables or infinite results.

EXP:
• EXP can come from Normal enemy, Mini-Boss or Boss;
• Normal = x1, Mini-Boss = x1.3, Boss = x2;
• if the enemy Grade is higher than the character Grade, each Grade above adds x1.2;
• preview shows final EXP before applying it.

Search and navigation:
• search finds pages, rules, functions, Titles, Opens, Skills, Arts, inventory, background and diary;
• search ignores case, accents and small typing mistakes;
• when switching page, scroll position is preserved per page while the screen stays open.

Images:
• if crop is cancelled, the previous image must not be deleted;
• empty or invalid images must not replace an already saved image.
''',
  ),

  ManualSection(
    titleIt: '22. Guida speciale: uso dell’app e comandi @',
    titleEn: '22. Special guide: app usage and @ commands',
    contentIt: r'''
Questa sezione spiega come usare l’app, dove si trovano gli spazi principali e come scrivere i comandi con @.
Nella pagina Regole trovi anche il pannello “Guida speciale dell’app”: ogni pulsante porta direttamente alla casella o alla sezione corrispondente.

SPAZI PRINCIPALI DELL’APP

• Immagine scheda / drop Windows:
  è lo spazio grande in alto nella Scheda. Puoi premere Aggiungi oppure trascinare direttamente un file immagine da Windows nello spazio. Dopo il rilascio si apre il crop. Se annulli il crop, l’immagine precedente resta salva.

• Centro comandi scheda:
  contiene le azioni rapide più usate. Serve per arrivare velocemente a danno, cura, HP, scudi e parti operative della scheda.

• Identità:
  contiene tipo scheda, nome, livello, grado e Rebirth. Toccare il pulsante “Nome, tipo, livello e grado” nella guida ti porta qui.

• EXP:
  contiene EXP base, fonte dell’EXP e grado nemico. Normale = x1, Mini-Boss = x1.3, Boss = x2. Ogni grado del nemico sopra il tuo aggiunge x1.2.

• HP / Scudi:
  contiene HP correnti, HP temporanei, Scudo, Scudo Oculum e Scudo Critico. Serve per gestire la resistenza della scheda senza perdere dati.

• Danno / Cura / Tipo danno:
  contiene il campo dove inserire danni o cure, il modificatore danno e il tipo danno. Qui vengono mostrati anche elemento dominante e tipo coinvolto.
  Il campo accetta anche formule semplici: 10+100-20 viene calcolato come 90. Dopo il calcolo restano attive difesa, scudi, HP temporanei, Scudo Oculum, critici e modificatori.

• Valori modificabili:
  contiene le statistiche e i valori rapidi modificabili della scheda.

• Party scheda:
  serve per salvare alleati, compagni, NPC vicini o membri collegati alla scheda.

• Titoli:
  contiene Titoli, Open, Punti Ciechi, buff, debuff, comandi @ e bonus condizionali.

• Inventario / armi / protezioni:
  contiene oggetti, peso, quantità, note, Buff @ Oggetto, armi, armature, scudi, bonus Danno, Difesa, Scudo e Tipo danno/protezione.

• Storia / diario:
  contiene background, note, diario e pagine narrative.

COMANDI @ BASE

I comandi @ servono per scrivere buff, debuff, bonus rapidi e formule dentro Titoli, Open, Skill o testi supportati dal parser.
Il formato generale è:

@Campo+Valore
@Campo-Valore

Esempi semplici:
• @Res+3 = aggiunge 3 Resilienza.
• @Vol+2 = aggiunge 2 Volontà.
• @Mat+1 = aggiunge 1 Materia.
• @Ocu+1 = aggiunge 1 Oculum.
• @Difesa+5 = aggiunge 5 Difesa rapida.
• @Danni+10 = aggiunge 10 Danni rapidi.
• @Scudo+15 = aggiunge 15 Scudo se il punto del codice lo supporta.
• @HP+5 o @Vita+5 = aumenta la vita massima finche il comando resta attivo.
• @HPTemp+Vol1/6 = aggiunge HP temporanei calcolati dalla Volonta.
• @ScudoOculum+5 = aggiunge massimo Scudo Oculum.
• @Iniziativa+5 = aggiunge Iniziativa.
• @Movimento+3 = aggiunge 3 metri al Movimento.
• @TiroAttacco+1 = aumenta i tiri d'attacco.
• @TiroDifesa+1 = aumenta i tiri difensivi.
• @TiroVolontà+1 = aumenta solo il tiro di Volontà.
• @TiroStats+1 = aumenta i tiri di Resilienza, Volontà, Materia e Oculum.
• @Stats+1 = aggiunge 1 a Resilienza, Volonta, Materia e Oculum.
• @HP-10=Stats+1 = ogni 10 HP persi aggiunge 1 alle statistiche che non generano HP.
• @Vol-1=AltreStats+1 = ogni Volonta persa aggiunge 1 alle altre statistiche base.

STATISTICHE RICONOSCIUTE

• Res, Resilienza
• Vol, Volontà
• Mat, Materia
• Ocu, Oculum
• Difesa
• Danni
• Scudo
• HP, Vita
• HPTemp, HP Temporanei
• ScudoOculum
• Iniziativa
• Movimento
• TiroAttacco
• TiroDifesa
• TiroVC, TiroCM
• TiroRes, TiroResilienza
• TiroVol, TiroVolonta, TiroVolontà
• TiroMat, TiroMateria
• TiroOcu, TiroOculum
• TiroStats
• VC
• CM
• Stats, AllStats
• OtherStats, AltreStats

AUTOCOMPLETAMENTO CON TAB

Nei campi che accettano comandi, TAB completa il comando o il tipo elemento piu probabile.
Esempi:
- @Dif + TAB diventa @Difesa;
- @Dan + TAB diventa @Danni;
- @HPTe + TAB diventa @HPTemp;
- @ScudoOc + TAB diventa @ScudoOculum;
- @Mov + TAB diventa @Movimento;
- @Danni+15 Ful + TAB diventa @Danni+15 Fulmine;
- @Difesa+5 Cen + TAB diventa @Difesa+5 Cenere;
- @Danni+10 Vap + TAB diventa @Danni+10 Vapium.

Se non stai scrivendo un comando @, TAB resta libero per la normale navigazione del campo.

FORMULE SUPPORTATE

• @Mat-1/3Vol = toglie a Materia un terzo della Volontà.
• @Mat-⅓Vol = uguale a sopra, ma con frazione speciale.
• @Mat-Vol*2 = toglie a Materia il doppio della Volontà.
• @Difesa+Resilienza = aggiunge alla Difesa il valore di Resilienza.
• @Danni+Scudo = aggiunge ai Danni il valore dello Scudo.
• @Ocu+25%Mat = aggiunge a Oculum il 25% di Materia.
• @Vol-Res/2 = toglie a Volontà metà Resilienza.

• @Difesa-¼ = malus frazionario, arrotondato ad almeno -1.
• @Danni+1OnHit = +1 Danni quando gli HP attuali sono sotto il massimo.
• @Vol+1=-10HP = +1 Volonta ogni 10 HP persi.
• @HP+1=Vol-1 = +1 HP ogni punto di Volonta attuale perso rispetto alla base.
• @HP-10=Stats+1 = ogni 10 HP persi dona +1 a Volonta, Materia e Oculum, ma non Resilienza.
• @Vol-1=AltreStats+1 = ogni punto Volonta perso dona +1 a Resilienza, Materia e Oculum.

TRIGGER NELLE FORMULE

Dopo il valore puoi aggiungere un trigger.
OnHit si attiva quando il personaggio ha subito colpi e gli HP attuali sono sotto il massimo.
La forma =Stat-Numero conta quante volte quella statistica o risorsa e scesa.
La forma =-NumeroHP conta quante volte gli HP sono scesi di quella soglia.
La forma costo=bonus, per esempio @HP-10=Stats+1, e pensata per scrivere sacrifici e buff in modo naturale.
L'app evita i loop: se perdi HP non ricevi Resilienza da quel comando; se perdi Volonta non ricevi Volonta dallo stesso comando.
Le divisioni con / restano valide e non bloccano le frazioni speciali come ⅓, ¼, ½ e ¾.

REGOLE ANTI-CALCOLI IMPOSSIBILI

Il parser deve rifiutare o ignorare in sicurezza:
• divisioni per zero;
• formule vuote;
• variabili inesistenti;
• risultati infiniti;
• NaN;
• valori troppo assurdi che potrebbero rompere la scheda.

COMANDI @DANNI CON TIPO DANNO

Puoi scrivere l’elemento vicino al danno.

Esempi:
• @Danni+13Fulmine = aggiunge 13 danni Fulmine.
• @Danni+13 Fulmine = uguale, con spazio.
• @Danni+Vol/2 Fuoco = aggiunge metà Volontà come danno Fuoco.
• @Danni+⅓Mat Gelo = aggiunge un terzo di Materia come danno Gelo.
• @Danni+25%Ocu Lunare = aggiunge il 25% di Oculum come danno Lunare.
• @Danni+10 Vapium, @Danni+8 Slime, @Danni+12 Cristallo, @Danni+5 Postea e @Danni+7 Radice usano gli stessi tipi del dungeon.

Se più tipi partecipano al danno, il tipo dominante è quello con più danno totale.
I tipi ripetuti non vengono mostrati due volte.
Gli elementi sconosciuti non bloccano il calcolo: vengono mostrati come Sconosciuto o con il nome scritto, usando colore bianco/grigiastro.

La Difesa supporta gli stessi tipi:
• @Difesa+15 Cenere aumenta comunque la Difesa totale di 15 e collega l’etichetta Cenere.
• @Difesa+10 Osso @Difesa+5 Cenere somma +15 Difesa.
• se più tipi difensivi sono presenti, in scheda si vede solo il predominante; gli altri restano nel dettaglio breve.

Per non deformare la UI, danni e difese mostrano massimo 3 elementi e poi +N.

TIPI DANNO E SINONIMI UTILI

• Fisico / Normale
• Taglio / Lama / Slash
• Perforante / Perforazione / Pierce
• Contundente / Botta / Blunt
• Fuoco / Fiamma / Bruciatura
• Gelo / Ghiaccio / Freddo
• Fulmine / Elettrico / Elettro / Tuono
• Sonoro / Suono / Sonico / Sonic / Acustico
• Veleno / Tossico / Toxin
• Acido / Corrosivo
• Oscuro / Ombra / Tenebra
• Sacro / Luce / Santo
• Lunare / Luna / Moon
• Solare / Sole / Sun
• Diabolico / Demoniaco / Demon
• Angelico / Angelo / Angel
• Psichico / Mentale / Mind
• Necrotico / Necrosi / Morte
• Vapium
• Slime
• Cristallo / Crystal
• Postea
• Radice / Flora / Root
• Osso / Bone
• Cenere / Ash
• Null / Vuoto / Nullum
• Sogno / Dream
• Metallo / Metal
• Stella / Star
• Corrotto / Corrupted
• Non morto / Undead

COME USARE LA GUIDA CLICCABILE

Nella pagina Regole apri “Guida speciale dell’app”.
Tocca un pulsante come “EXP”, “Danno / Cura”, “Inventario / armi” o “Immagine scheda / drop Windows”.
L’app cambia pagina e prova a scorrere direttamente fino alla casella o alla sezione scelta.
Se una sezione non è ancora caricata, l’app non deve crashare: mostra solo che quella funzione non è collegata.
''',
    contentEn: r'''
This section explains how to use the app, where the main areas are, and how to write @ commands.
In the Rules page you also find the “Special app guide” panel: each button jumps directly to the matching field or section.

MAIN APP AREAS

• Sheet image / Windows drop:
  this is the large area at the top of the Sheet. You can press Add or drag an image file directly from Windows into the space. After dropping, crop opens. If you cancel crop, the previous image stays saved.

• Sheet command center:
  contains the most used quick actions. It helps you reach damage, healing, HP, shields and operative sheet areas quickly.

• Identity:
  contains sheet type, name, level, grade and Rebirth. Pressing “Name, type, level and grade” in the guide jumps here.

• EXP:
  contains base EXP, EXP source and enemy grade. Normal = x1, Mini-Boss = x1.3, Boss = x2. Each enemy grade above yours adds x1.2.

• HP / Shields:
  contains current HP, temporary HP, Shield, Oculum Shield and Critical Shield. It manages endurance without losing data.

• Damage / Heal / Damage type:
  contains the field for damage or healing, damage modifier and damage type. Dominant element and involved type are shown here.
  The field also accepts simple formulas: 10+100-20 is calculated as 90. After that calculation, defense, shields, temporary HP, Oculum Shield, criticals and modifiers still apply.

• Editable values:
  contains editable stats and quick values.

• Sheet party:
  stores allies, companions, nearby NPCs or members linked to the sheet.

• Titles:
  contains Titles, Opens, Blind Spots, buffs, debuffs, @ commands and conditional bonuses.

• Inventory / weapons / protections:
  contains items, weight, quantity, notes, weapons, armor, shields, Damage, Defense, Shield bonuses and damage/protection type.

• Story / diary:
  contains background, notes, diary and narrative pages.

BASIC @ COMMANDS

@ commands are used for buffs, debuffs, quick bonuses and formulas inside Titles, Opens, Skills or supported text fields.
General format:

@Field+Value
@Field-Value

Simple examples:
• @Res+3 = adds 3 Resilience.
• @Vol+2 = adds 2 Will.
• @Mat+1 = adds 1 Materia.
• @Ocu+1 = adds 1 Oculum.
• @Difesa+5 = adds 5 quick Defense.
• @Danni+10 = adds 10 quick Damage.
• @Scudo+15 = adds 15 Shield when supported by that code area.
• @HP+5 or @Vita+5 = increases max HP while the command stays active.
• @HPTemp+Vol1/6 = adds temporary HP calculated from Will.
• @ScudoOculum+5 = adds Oculum Shield maximum.
• @Iniziativa+5 = adds Initiative.
• @Movimento+3 = adds 3 meters to Movement.
• @TiroAttacco+1 = increases attack rolls.
• @TiroDifesa+1 = increases defense rolls.
• @TiroVolontà+1 = increases only the Will roll.
• @TiroStats+1 = increases Resilience, Will, Materia and Oculum rolls.
• @Stats+1 = adds 1 to Resilience, Will, Materia and Oculum.
• @HP-10=Stats+1 = every 10 HP lost adds 1 to stats that do not generate HP.
• @Will-1=OtherStats+1 = every Will point lost adds 1 to the other base stats.

RECOGNIZED STATS

• Res, Resilienza
• Vol, Volontà
• Mat, Materia
• Ocu, Oculum
• Difesa
• Danni
• Scudo
• HP, Vita
• HPTemp, Temporary HP
• ScudoOculum
• Iniziativa
• Movimento / Movement
• TiroAttacco
• TiroDifesa
• TiroVC, TiroCM
• TiroRes, TiroResilienza
• TiroVol, TiroVolonta, TiroVolontà
• TiroMat, TiroMateria
• TiroOcu, TiroOculum
• TiroStats
• VC
• CM
• Stats, AllStats
• OtherStats

TAB AUTOCOMPLETE

In fields that accept commands, TAB completes the most likely command or element type.
Examples:
- @Dif + TAB becomes @Difesa;
- @Dan + TAB becomes @Danni;
- @HPTe + TAB becomes @HPTemp;
- @ScudoOc + TAB becomes @ScudoOculum;
- @Mov + TAB becomes @Movimento;
- @Danni+15 Ful + TAB becomes @Danni+15 Fulmine;
- @Difesa+5 Cen + TAB becomes @Difesa+5 Cenere;
- @Danni+10 Vap + TAB becomes @Danni+10 Vapium.

If you are not writing an @ command, TAB remains available for normal field navigation.

SUPPORTED FORMULAS

• @Mat-1/3Vol = subtracts one third of Will from Materia.
• @Mat-⅓Vol = same, with special fraction.
• @Mat-Vol*2 = subtracts twice Will from Materia.
• @Difesa+Resilienza = adds Resilience value to Defense.
• @Danni+Scudo = adds Shield value to Damage.
• @Ocu+25%Mat = adds 25% of Materia to Oculum.
• @Vol-Res/2 = subtracts half Resilience from Will.

• @Defense-¼ = fractional penalty, rounded to at least -1.
• @Damage+1OnHit = +1 Damage while current HP is below maximum.
• @Will+1=-10HP = +1 Will for every 10 HP lost.
• @HP+1=Will-1 = +1 HP for each current Will point lost below base.
• @HP-10=Stats+1 = every 10 HP lost grants +1 to Will, Materia and Oculum, but not Resilience.
• @Will-1=OtherStats+1 = every Will point lost grants +1 to Resilience, Materia and Oculum.

FORMULA TRIGGERS

After the value you can add a trigger.
OnHit activates when the character has been hit and current HP is below maximum.
=Stat-Number counts how many times that stat or resource dropped.
=-NumberHP counts how many times HP dropped by that threshold.
The cost=bonus form, for example @HP-10=Stats+1, is made for natural sacrifice/buff writing.
The app prevents loops: if you lose HP you do not gain Resilience from that command; if you lose Will you do not gain Will from the same command.
Division with / remains valid and does not conflict with special fractions such as ⅓, ¼, ½ and ¾.

ANTI-IMPOSSIBLE-CALCULATION RULES

The parser must safely reject or ignore:
• division by zero;
• empty formulas;
• unknown variables;
• infinite results;
• NaN;
• absurd values that could break the sheet.

@DANNI COMMANDS WITH DAMAGE TYPE

You can write the element next to the damage.

Examples:
• @Danni+13Fulmine = adds 13 Lightning damage.
• @Danni+13 Fulmine = same, with spacing.
• @Danni+Vol/2 Fuoco = adds half Will as Fire damage.
• @Danni+⅓Mat Gelo = adds one third of Materia as Ice damage.
• @Danni+25%Ocu Lunare = adds 25% of Oculum as Lunar damage.
• @Danni+10 Vapium, @Danni+8 Slime, @Danni+12 Cristallo, @Danni+5 Postea and @Danni+7 Radice use the same types as the dungeon.

If multiple types are involved, the dominant type is the one with the highest total damage.
Repeated types are not shown twice.
Unknown elements do not block calculation: they are shown as Unknown or with the written name, using a white/grey color.

Defense supports the same types:
• @Difesa+15 Cenere still increases total Defense by 15 and links the Ash label.
• @Difesa+10 Osso @Difesa+5 Cenere adds +15 Defense.
• if multiple defense types are present, the sheet shows only the dominant one; the others remain in the short detail.

To keep the UI stable, damage and defense show at most 3 elements, then +N.

USEFUL DAMAGE TYPES AND SYNONYMS

• Physical / Normal
• Cutting / Blade / Slash
• Piercing / Pierce
• Blunt
• Fire / Flame / Burn
• Ice / Frost / Cold
• Lightning / Electric / Thunder
• Sound / Sonic / Acoustic
• Poison / Toxic / Toxin
• Acid / Corrosive
• Dark / Shadow / Tenebra
• Holy / Light / Saint
• Lunar / Moon
• Solar / Sun
• Diabolic / Demonic / Demon
• Angelic / Angel
• Psychic / Mental / Mind
• Necrotic / Necrosis / Death
• Vapium
• Slime
• Crystal / Cristallo
• Postea
• Root / Flora / Radice
• Bone / Osso
• Ash / Cenere
• Null / Void / Nullum
• Dream / Sogno
• Metal / Metallo
• Star / Stella
• Corrupted / Corrotto
• Undead / Non morto

HOW TO USE THE CLICKABLE GUIDE

Open “Special app guide” in the Rules page.
Tap a button like “EXP”, “Damage / Heal”, “Inventory / weapons” or “Sheet image / Windows drop”.
The app changes page and tries to scroll directly to the selected field or section.
If a section is not loaded yet, the app must not crash: it only reports that the function is not linked.
''',
  ),
  ManualSection(
    titleIt: 'Attacco contrapposto — conferme del 18 ottobre 2026',
    titleEn: 'Opposed attacks — rules confirmed October 18, 2026',
    contentIt: r'''
Indica con A il totale del tiro di attacco e D quello del tiro di difesa. Questi totali sono distinti dalla Difesa numerica della scheda.

ATTACCO QUASI RIUSCITO
• Facile: A supera D da 1 a 6.
• Medio/Normale: A supera D da 1 a 5.
• Difficile: A supera D da 1 a 3.
• Oculum: A è pari a D oppure inferiore di 1. Esempio D=10: A=9 o 10 quasi riuscito, A≥11 pieno, A≤8 evitato.
In un quasi riuscito la Difesa numerica contro il colpo vale ×1,5, arrotondata per eccesso (7 diventa 11). La durata degli effetti in turni o azioni è dimezzata per difetto, minimo 0: 1 diventa 0, 3 diventa 1. Durata 0 significa che l'effetto non si applica, non che diventa permanente. Il danno base non si dimezza.
Negli altri casi, fuori dall'eccezione Oculum, D≥A evita l'attacco; un vantaggio di A oltre la fascia indicata dà esito pieno.

TIRO DOPPIO E CRITICO
Se A raggiunge almeno il doppio di D ottiene un critico positivo, con precedenza sulla fascia quasi riuscita. Se D raggiunge almeno il doppio di A il difensore ottiene una reazione gratuita su chi ha provato a colpirlo. Il contrattacco è critico.
Si raddoppia soltanto il bonus del danno critico, non il danno totale. Il bonus ordinario per livello del nemico è +3 Facile, +2 Medio, +1 Difficile, +1 ogni due livelli Oculum. Esempio: danno base 51, nemico livello 10 Medio, critico da tiro doppio → 51+40=91 prima delle protezioni. Il critico modifica gli stadi di Resistenza/Fragilità secondo le regole del danno critico.
Normalmente gli arrotondamenti sono per difetto; il ×1,5 della Difesa quasi riuscita è l'eccezione esplicitamente confermata.

LARVA BIANCA
La modalità fuga di Scavata usa il sottotratto Velo. Questa scelta non modifica il tiro della modalità di attacco sotterraneo.

CLONE D'OMBRA E SCROLL OMBRA VIVA
La creazione diretta del Clone d'ombra crea una scheda alleata vera: copia le statistiche del proprietario tranne Resilienza, ha 10 Vita e dura un numero di turni pari all'Oculum del proprietario. La scheda mantiene l'identità del proprietario e può partecipare alla turnistica.
La scroll Ombra viva crea lo stesso tipo di scheda, ma assegna 5 × livello del proprietario in Vita e dura `grado della scroll × 2 + 3` turni. Anche qui copia tutte le altre statistiche tranne Resilienza.
Se il proprietario è già in uno scontro, il clone viene aggiunto alla stessa turnistica. Offline si aggiunge alla turnistica locale. Online la scheda viene condivisa con il Master e il suo inserimento passa dalla turnistica autorizzata del Master. Quando finisce la durata, il clone si dissolve e non può più agire.

PERGAMENE MONOUSO
L'uso consuma una pergamena ed esegue la tecnica; non assegna automaticamente una skill permanente. Anche un tiro fallito consuma la pergamena. Con 20 naturale e totale almeno 30 + 10 × grado si verifica separatamente l'apprendimento: Facile 20%, Medio 15%, Difficile 10%, Oculum 5%. La skill eventualmente appresa conserva costi e cooldown, non è evolvibile e non viene duplicata.

BERSAGLI, SUPPORTI E OSSERVAZIONE — 19 OTTOBRE
La fascia di bersagli/colpi è modificabile nell'editor degli effetti. Negli attacchi a più bersagli si divide il danno base fra i colpi scelti, arrotondando ogni quota per eccesso; i bonus piatti, per esempio «Danni +8», si aggiungono per intero a ciascun bersaglio. Ognuno tira la propria difesa e applica le proprie resistenze. Se la forma richiede più colpi dei bersagli distinti selezionati, quelli mancanti vengono assegnati casualmente ai bersagli già scelti; lo stesso nemico può essere colpito più volte. Costo e cooldown si pagano una volta. Ogni mostro non-NPC e non Pawn riceve alla generazione una tecnica ad area casuale, salvata e modificabile nella scheda, oltre alla variante individuale. Anche cure e supporti possono scegliere più destinatari, compresi se stessi; Aiuta compagno può dare un modificatore positivo o negativo al prossimo tiro e viene consumato una volta.
Percezione, Investigazione, Furbizia e Valutazione sono azioni di osservazione: possono essere lanciate senza bersaglio per una lettura generale oppure su un partecipante. Nel pannello Tiri e azioni viene proposto il migliore fra questi quattro sottotratti. Per una lettura individuale, il totale Oculum deve raggiungere Livello + Velo; pari basta per rivelare livello esatto e probabilità. Se manca di al massimo 5, mostra una lettura approssimata con un livello ridotto dello scarto, minimo 0, ma dello stesso Grado; oltre 5 mostra solo «Non senti abbastanza». Solo una lettura esatta dimezza per difetto il bonus Velo attivo di Invisibilità o Trasparenza; il valore resta ridotto fino alla fine del fight per chi ha individuato il bersaglio e i suoi alleati, e si applica anche ai bonus personalizzati e alla crescita per livello. Le letture approssimate e «Non senti abbastanza» non lo modificano. Un critico scopre il punto debole e concede a sé e alleati Fragilità Semi Letale verso quel nemico fino a fine fight. Gli scontri restano distinti, salvo unione esplicita del Master.

Il Monster Book mostra «Punto debole: ???» finché il party non ha scoperto la creatura o acquistato una pagina. Un critico di Percezione/Investigazione rivela un punto anatomico specifico e concede a sé e agli alleati Fragilità Semi Letale (+250 punti percentuali) contro quel bersaglio fino a fine scontro; il +250% si somma alla percentuale di danno già impostata. Quando il party conosce il punto debole, in combattimento si può scegliere «Precisione · punto debole»: usa il tiro Precisione e la sua progressione normale, quindi non garantisce il colpo. Una pagina del Mercato Nero rivela anche il nome della creatura, oltre al punto debole e alle resistenze, e sblocca il tiro mirato, senza applicare Semi Letale. Le scoperte sono permanenti nel Monster Book Party e si sincronizzano con un evento leggero per campagna. I preset distinguono anatomia e resistenze: ad esempio, un guscio riduce Taglio e Perforante e aumenta Contundente; i valori personalizzati del Master prevalgono. Il Mercato Nero offre al massimo tre pagine diverse di mostri erranti e aberrazioni vicine al livello e alle statistiche del personaggio, al costo di 56 Obser per gli erranti e 90 per le aberrazioni.

In combattimento, Concentrazione si attiva con un tiro di sottotratto almeno 10 e dado naturale maggiore di 10: il prossimo attacco riceve +10% danni oppure la prossima difesa +12%, consumando il beneficio una sola volta. Adattamento, attivabile in Utility con sottotratto almeno 10, sul dado naturale sopra 10 riduce il prossimo danno ricevuto di 1 + (dado − 10), consumando la riduzione su un singolo evento di danno. Precisione da +6 applica al colpo una probabilità 80/15/5 di avanzare la Fragilità di uno/due/tre stadi; ogni punto oltre +6 sposta 1% da +1 a +2 fino a 50/45/5, poi da +2 a +3 fino a 50/40/10. Da +20 si ritaglia un 5% dalla fascia +1 per un esito speciale con danno ricevuto casuale dal 260% al 350%. Il valore massimo resta Fragilità Letale.

Gli oggetti, le Skill, le Art e i Titoli possono aggiungere ai danni una frazione del tiro d'attacco con il parser `@Danni+1/2dadoriflessi` (sono validi anche `dadoforza`, `dadoschianto` e gli altri sottotratti). La frazione si calcola sul totale del tiro, arrotonda per difetto e si attiva solo se l'attacco usa il sottotratto indicato. Negli attacchi multipli questo bonus si applica a ciascun bersaglio. Esempio: Stocco dell'Eco Riflessa aggiunge 1/4 del tiro di Riflessi; Martello della Faglia 1/3 del tiro di Forza. Il testo resta modificabile nel campo buff dell'oggetto.

Ogni arma, armatura e scudo mostra il proprio livello. La skill dell'oggetto richiede almeno quel livello del personaggio; una singola forma può richiederne uno maggiore. Il requisito viene verificato nell'elenco di combattimento e di nuovo quando si attiva la skill. Gli oggetti più alti del proprio Grado non si possono acquistare; quelli del proprio Grado o inferiore restano acquistabili anche se il loro livello skill non è ancora raggiunto.

Il tiro Drop è il dado più il bonus Drop. Per la Fata Cacciatrice un totale pari o superiore a 50 garantisce entrambe le Mezze ali di fata; sotto 50 non le lascia. Il catalogo delle reliquie contiene almeno 500 armi, armature e scudi rari derivati dalle Art o Skill dei mostri: gli oggetti non copiano le statistiche base della creatura, mantengono elemento, grado e livello affrontato e bloccano le abilità fino al livello richiesto. Una uccisione può assegnare al massimo una reliquia, non l'intero catalogo; la soglia standard è 25 + 2 × Grado. I materiali hanno probabilità indipendenti, predefinita al 35% quando il mostro non ne specifica una. Le creature commestibili hanno il 45% di lasciare Carne di mostro cruda da cuocere; costrutti, golem e non morti non danno carne. È possibile ottenere solo carne o nessun bottino. L'Elmetto-scudo di melma blu usa l'elemento Slime e dà Scudo Oculum pari a 10 + il livello del mostro; i valori restano modificabili nel JSON dell'oggetto.

Ogni reliquia equipaggiabile mostra un prezzo Obser e una probabilità di affisso al ritrovamento. Impostazione iniziale modificabile: 20% per un affisso +1 e 5% per il raro +2; il bersaglio casuale può essere una delle quattro statistiche o un sottotratto da combattimento. Il risultato e il comando @ effettivo vengono salvati nell'oggetto. I materiali e gli altri drop manuali hanno un prezzo iniziale basso, crescente con livello e Grado; prezzi e probabilità si possono modificare senza cambiare gli oggetti già salvati.

L'Armatura del Patalpa mantiene +5 Difesa e ha Scudo `6 + 6 × livello dell’oggetto + 4 × Grado × livello dell’oggetto`: parte da 6, ogni livello aggiunge 6 e ogni Grado aggiunge altri 4 per livello. Conserva anche +2 Materia, +1 Volontà, +1 Resilienza e Richiamo del Patalpa. Il valore calcolato resta modificabile nel JSON dell'oggetto.

Il Patalpa richiamato usa il budget del suo livello: 20% Resilienza, 50% Volontà, 30% Materia. Non avendo Oculum, nel 75% degli spawn non riceve il punto extra di Resilienza per livello; nel 25% lo riceve. Le statistiche restano editabili sulla scheda evocata.

Quando un Titolo o un equipaggiamento viene graduato di un grado, si assegnano 10 punti fra Resilienza, Volontà, Materia e Oculum. Il selettore rapido usa − / valore / + e conferma solo quando tutti i punti sono distribuiti. Il grado e la distribuzione restano salvati nel JSON; sui Titoli valgono quando equipaggiati, sugli oggetti quando equipaggiati e il loro buff è attivo. I vecchi oggetti e Titoli senza distribuzione mantengono i loro bonus.

Il Fabbro propone altre formule per sottotratto: Lancia della Soglia Velata (1/5 Velo), Pugnale della Misura Esatta (1/4 Precisione), oltre a corazza e scudo con skill difensive legate al loro livello. I minimi iniziali degli equipaggiamenti sono 50 Obser al Grado 0 e +70 per Grado (I 120, II 190, III 260, IV 330); sopra il livello base di 5 × Grado si aggiungono 10 Obser per livello. Le statistiche possono alzare il prezzo. Gli oggetti mostrano livello e grado in negozio e inventario; bonus, descrizioni, skill, costi, cooldown e formule restano modificabili nel JSON.

Il Collezionista di Elementi è un boss-clown di livello 0 con RES 10, VOL 10, MAT 5, OCU 15, +15 Danni e +5 Difesa. Ha la Resistenza standard contro ogni elemento; dopo ogni colpo accumula per l'elemento ricevuto +6 punti percentuali di Resistenza fino al 75%, separatamente per ciascun elemento. Registra gli elementi che lo colpiscono e può riusarli con il Martello del Collezionista. Il martello è evocato per il singolo colpo e non può essere usato da altre creature: I aggiunge 20 + 2×Oculum speso (1–4), II 40 + 2×Oculum (5–10), III 64 + 3×Oculum (11–50). Ogni forma si somma al danno base normale. Chi para un suo attacco con lo stesso elemento subisce −2 al tiro difensivo.

Riflessi concede una Reazione aggiuntiva contro l'attaccante con naturale 20 a +6 soltanto se il movimento dell'attaccante non supera il proprio; a +12 basta 19 o 20, a +20 basta 18, 19 o 20 senza confronto di movimento. Le reazioni non si accumulano oltre i limiti delle Skill.

EMBLEMA, MERCANTI ED EDITOR — 20 OTTOBRE
L'alchimista vende l'Emblema di evocazione dello Slime custode: prezzo base modificabile 200 Obser, più costoso di Pawn. Per l'intero scontro evoca un guardiano con 120 HP condivisi che protegge fino a tre partecipanti scelti, anche se stessi. Dopo le difese personali, il danno destinato alla Vita viene assorbito dallo slime; l'eccedenza prosegue sul bersaglio. Finché è vivo dona +3 a ciascuna delle quattro statistiche e +2 a tutti i sottotratti dei protetti. Non riceve la rigenerazione di Pawn. I bonus non alterano permanentemente le statistiche e terminano con l'evocazione o lo scontro. Il menu dell'oggetto permette di modificare Vita, destinatari, bonus e durata (0 turni significa fino a fine fight); i valori sono conservati nel JSON.
L'alchimista può trovare anche un Occhio dei Caduti medio raro (probabilità iniziale 20%) o raro (5%): la presenza viene estratta una sola volta per mercante e resta salvata. La creatura è casuale fra quelle del Monster Book, esclusi gli NPC; le statistiche base non superano il totale delle tue e vengono scelte quanto più vicine possibile alla metà del tuo totale. Il medio raro è di livello pari al tuo meno un terzo arrotondato per eccesso, minimo 0; costa 56–89 + il tuo livello + Grado ×3 Obser. Il raro è di livello pari alla metà del tuo arrotondata per eccesso; somma alle tue quattro statistiche le statistiche base del mostro e costa 230–450 + metà del tuo livello arrotondata per difetto + Grado ×4 Obser. L'acquisto crea l'Occhio dei Caduti e consuma l'offerta; i prezzi e la scheda sorgente restano salvati.
I prezzi dei mercanti sono personali e persistenti: ordinariamente ±5%; per nuovo negozio il 3% applica +25% e l'1% −15%, senza avviso al giocatore. Le percentuali si applicano al prezzo base, arrotondando per difetto con minimo 1 Obser. Riaprire o filtrare non cambia il prezzo. Il Segno del Chaos considera la spesa reale.
Il catalogo Master nell'inventario offre filtri combinati per Grado e categoria. Un oggetto ibrido può comparire in più categorie. Le Open già usate sono nascoste dalle scorciatoie di combattimento fino al prossimo Riposo Lungo; le skill della Open conservano i propri comandi. Attivare una Open applica il suo Open Buff, compresi gli effetti riconosciuti dal testo. Gli editor consentono la scelta del pannello e mostrano gli effetti avanzati soltanto quando aperti; tipi, elementi e personalizzazioni restano salvati.

TITOLI E CHAINED FATE — 19 OTTOBRE
DISPONIBILITÀ IN COMBATTIMENTO — 20 OTTOBRE
Attacco, Difesa e Supporto e utilità mostrano le sole abilità utilizzabili: recupero pronto, requisiti soddisfatti e risorse sufficienti per almeno una forma. La scelta della forma nasconde quelle non disponibili; i sottotratti restano utilizzabili come tiri.
Le Open mancanti dei mostri vengono completate senza riscrivere capacità già personalizzate: nei gradi iniziali aggiungono 1d50+25 al danno ordinario, nei profili più forti da 1d90+60 fino a 1d250+400. Il Buff Open aumenta tutte le statistiche, inizialmente di 4; la capacità ridotta ha un recupero autonomo iniziale di tre turni. Sblocco, effetti, costi e recupero restano modificabili negli editor e salvati nel JSON.

Sei slot standard iniziali, sette al Grado III, otto al VI e nove al IX. Apprendimento: uno slot iniziale più uno per Grado; con Rebirth i primi tre Evoluti non occupano slot. Alchimia/Magia usa slot distinti pari al Grado, con uno già utilizzabile al Grado 0 per Rebirth. Chaos: uno slot ogni −10 Karma. Malanno: uno ogni sei Resilienza; non si rimuove volontariamente. Benessere non occupa slot.
La Prima Art assegna uno slot Fato alla prima forma della prima skill, uno alla seconda forma della seconda skill e uno alla terza forma della terza skill. Ogni traguardo si ottiene una sola volta.
Il Master avvia il Chained Fate e sceglie i partecipanti. Nei primi tre dungeon EXP ×2; ogni completamento dà uno slot Fato dedicato. Dai successivi EXP ×3 e nessuno slot aggiuntivo. Completare lo stesso dungeon due volte non ripete il premio.

PARSER E MODIFICHE
Il riconoscimento del testo prepara formule, dadi, durata e destinatari; le frasi non riconosciute restano manuali. «Da 2 a 4 bersagli», «2 nemici» e «fino a Oculum bersagli» configurano la fascia. Effetti e parametri rimangono modificabili e salvati nel JSON; i valori risolti dal lanciatore non si ritirano a ogni reinvio online. Il testo scritto della motivazione è facoltativo: può essere spiegata a voce al Master.
Le Reputazioni possono essere organizzate in cartelle e sottocartelle senza limite fisso, conservando valori, descrizioni e influenza del Karma.

ONLINE E OFFLINE
Online, in una turnistica, dichiari il bersaglio. VC è il tiro di attacco ordinario: per un tiro alternativo basta descrivere l'attacco e motivarlo a voce al Master; scrivere è facoltativo. Il bersaglio riceve la richiesta di difendersi con CM, Riflessi, Resistenza o Manifestazione del Potere secondo la tecnica. Offline tutto rimane utilizzabile, con scelta di bersaglio, confronto dei tiri ed esito gestibili manualmente.

La presenza online dichiara tutte le schede possedute dalla sessione: cambiare scheda aggiorna subito la presenza, quindi una richiesta di attacco non viene persa durante il cambio. Master e Co-Master condividono il registro in sola lettura delle schede dei partecipanti nella stessa turnistica; dal partecipante puoi aprire «Apri scheda». Le copie online non trasferiscono la proprietà della scheda al personale.

Master e Co-Master possono modificare soltanto le schede condivise e autorizzate. Le modifiche a Vita, Scudo e HP temporanei raggiungono il proprietario mantenendo il tag originale; le copie di consultazione non acquisiscono la proprietà. L'invio o la richiesta della scheda attiva funziona anche senza amicizia fra i tag. In caso di conflitto di proprietà serve l'account originale oppure una copia esplicita con un nuovo tag.

Le modifiche autorizzate seguono l'ordine delle revisioni confermate dal server: un autosalvataggio locale non annulla una modifica online più recente, le revisioni già applicate non vengono ripetute e i dati privati non modificati restano conservati.
''',
    contentEn: r'''
Let A be the attack roll total and D the defense roll total, distinct from the sheet Defense value.
Partial hit bands: Easy A-D=1..6; Normal 1..5; Hard 1..3. In Oculum, A=D or A=D-1 is partial; A>D is full; A≤D-2 is avoided.
A partial hit uses sheet Defense ×1.5 rounded UP. Effect durations in turns/actions are halved rounded DOWN, minimum zero. A zero-duration effect does not apply. Base damage is not halved.
Double the opposing total grants a positive critical. Double defense grants a free critical counterattack against the attacker. Only the difficulty/level critical damage bonus doubles, never base damage. Existing resistance/fragility critical rules remain in force.
Rounding is normally down; partial-hit Defense ×1.5 is the explicitly confirmed exception.
Items, Skills, Arts, and Titles may add a fraction of the attack roll to damage with `@Danni+1/2dadoriflessi` (other subtraits such as `dadoforza` are supported). The fraction uses the total attack roll, rounds down, and activates only when that subtrait made the attack. Multi-target attacks add it to each target. The Stocco dell’Eco Riflessa adds one quarter of a Reflexes roll; the Martello della Faglia adds one third of a Strength roll. The parser text remains editable in the item buff field.

The Element Collector is a level-zero clown boss with RES 10, WILL 10, MAT 5, OCU 15, +15 Damage, and +5 Defense. It starts with standard Resistance against every element; each hit adds 6 percentage points of Resistance to that element up to 75%, tracked separately by element. It records elements that hit it and can replay them with its Hammer. The Hammer is conjured for one attack and cannot be wielded by other creatures: I adds 20 + 2×Oculum spent (1–4), II 40 + 2×Oculum (5–10), III 64 + 3×Oculum (11–50). Every form stacks on ordinary base damage. A target parrying one of its attacks with the same element takes −2 to the defense roll.
The Patalpa Armor keeps +5 Defense and grants Shield `6 + 6 × item level + 4 × Grade × item level`: it starts at 6, each item level adds 6, and each Grade adds 4 more per level. It also keeps +2 Materia, +1 Will, +1 Resilience and its Patalpa summon skill. The calculated value remains editable in item JSON. A summoned Patalpa uses its level-based stat budget split into 20% Resilience, 50% Will and 30% Materia. It has no Oculum; 75% of summons lack the extra +1 Resilience per level and 25% receive it. The distribution and roll are saved on the summoned sheet. The summon skill is usable once per three completed fights; the themed “CD ripristinata” button resets it outside an active fight, online or offline.
The Alchemist sells a Summoning Emblem for an editable base price of 200 Obser. It summons a Slime Guardian with a shared 120 HP pool for the encounter and protects up to three selected participants, including the user. It intercepts damage reaching their HP after personal defenses, with overflow continuing to the target. While alive, it grants each protected participant +3 to all four stats and +2 to every subtrait, without Pawn regeneration. Bonuses expire with the summon or encounter; HP, targets, bonuses and duration remain editable in item JSON.
Merchant prices persist per shop: normally within five percent of base; a three percent chance increases prices by 25 percent, and a one percent chance reduces them by 15 percent, without revealing the modifier. Filtering or reopening does not reroll prices. The Master inventory catalog filters by grade and category. Used Opens disappear from combat panels until Long Rest; their skills keep their own controls. Activating an Open applies its Open Buff. Editors offer panel placement and collapsed advanced effects while preserving elements and saved custom data.
Online attacks declare a target and justify any attack roll other than VC. Defenders respond with the appropriate defense. Offline abilities remain usable with manual targeting, rolls and resolution.
Direct Shadow Clone creates a real allied sheet that copies the owner's statistics except Resilience, has 10 HP, and lasts for the owner's Oculum turns. The Shadow Alive scroll creates the same sheet with 5 × owner level HP and lasts for scroll grade × 2 + 3 turns. If the owner is already in initiative, the clone joins that encounter; online the Master receives the sheet and controls its authorized addition. Expired clones dissolve and cannot act.
''',
  ),
];

// =====================================================
