# Oculum Visual Bible

La scheda è un oggetto costruito nel mondo di Oculum. Il tema è puramente decorativo: posizione, dimensioni e disposizione di pulsanti e funzioni restano identiche. Identità e ritratto, Vita/Scudi/Oculum, quattro statistiche e combattimento non ricevono padding, spazi o riordini aggiuntivi.

## Oculum Core Identity
Goth fantasy inciso, materiali consumati e piccoli bagliori locali. Cinzel per sigilli e titoli, i font già scelti dal giocatore per contenuti e numeri. La grafica incornicia la lettura.

## Theme Identity
I 62 temi esistenti conservano ID, nome e identità; il preset Sogno aggiunge una nuova identità senza rinominarli. `docs/design/theme-art-bible.json` conserva motivi e materiali; `design/themes/<id>/composition.json` definisce la composizione riproducibile. Ogni illustrazione originale resta in `assets/themes/<id>/overlays/relic.png`.

## Materials / Shapes / Frame Language
Radici: ramificazioni, foglie, asimmetria. Cristallo: facce appuntite e giunzioni spezzate. Ferro: placche interrotte e rivetti. Astrale: orbite incomplete e costellazioni. Abisso: curve correnti e ventose. Cenere: archi bruciati e scintille. Cattedrale: archi, nervature e sigilli. Sogno: profili morbidi sovrapposti dal blu al viola e al rosa pastello. Il motivo specifico del tema determina tagli, densità e disposizione, oltre alla famiglia.

Natura dispone di due composizioni selezionabili: steli secchi con petali caduti, oppure tralci vivi con foglie e fiori viola. Sogno usa nubi stratificate blu, viola e rosa pastello; il trattamento quieto è rarefatto, quello cromatico aggiunge strati e piccoli astri. La selezione è salvata e vale per cornici, scene, pannelli e incisioni dei controlli.

## Icon Language / Rune Language
Simboli incisi piccoli, bordi sottili e rune incompiute. Nessuna icona ornamentale sostituisce un'azione. Le icone funzionali esistenti conservano significato e area cliccabile.

## Creature Language

Precisazione del 6 novembre: la terza alternativa C, con piccoli redesign e variazione pittorica (guazzo/tempera opaca, contorni anime secchi, pennellate più visibili), vale soltanto per creature ancora senza scelta. I canoni e i voti precedenti escludono nuove proposte per quella creatura; A/B restano conservate. Nessuna modifica dell'anatomia, dell'elemento o dei poteri per ottenere la variazione. Ogni nuova C va controllata per numero degli arti e margini e rimane una proposta finché l'utente la sceglie. Archivio e revisioni su G, con collegamenti compatibili dai percorsi del progetto su C.

Precisazione esplicita del 2 novembre: Oculum resta un **dark fantasy**, nonostante le stranezze. Per le prossime proposte, soprattutto i mostri ostili devono risultare più mostruosi e minacciosi. Nuovo riferimento allegato: tratto anime scuro, ombre profonde, profili espressivi, colori controllati e pittura opaca. Rame fatato resta la base materica, senza obbligo di dolcezza o toni pastello. Il riferimento non impone il soggetto umano raffigurato e non annulla le immagini canoniche già approvate. [Richieste e applicazione](../docs/DIREZIONE_DARK_FANTASY_2026-11-02.md).

Conferma del 28 ottobre 2026: ogni mostro e variante ha un tema e una reliquia visiva specifici, in stile Rame fatato. Materiali, anatomia, colori ed ambiente devono renderli riconoscibili, evitando il riuso di un generico segnaposto come lavoro definitivo. La reliquia visiva è decorativa e non attribuisce da sola nuovi drop. Mostri e reliquie rispettano i margini e gli spazi dei controlli; nel Monster Book niente ritratto imposto.
Le illustrazioni originali dei temi possono emergere nei margini e negli spazi scenografici. Nessuna creatura invade i valori o si sovrappone alle etichette. Classic Oculum mantiene il sigillo inciso senza reintrodurre l'occhio nel reliquiario.

## Background Language
Centro trasparente, bordi materici e separatori ariosi. I PNG sono locali e disponibili senza connessioni ai plugin. I sorgenti SVG e il manifest restano modificabili in `design/themes/`.

## Animation Language
Movimento lento con pausa nella maggior parte del ciclo. Un solo elemento scenografico animato per composizione; nessun rebuild delle funzioni. Complete, Ridotte e Disattivate usano le impostazioni esistenti. Disattivate conserva tutta l'identità statica. Lifecycle, TickerMode e riduzione movimento del sistema fermano il movimento.

## Forbidden Styles
Dashboard generica; pannelli riempiti di immagini dietro il testo; asset opachi; neon indiscriminato; rettangoli identici soltanto ricolorati; animazioni continue senza pause; decorazioni che intercettano input; dipendenze runtime da Figma/Adobe/Canva.

## Responsive e zona protetta
Desktop: bordo spezzato con ornamentazione laterale estesa. Tablet: angoli e rilievi ridotti. Telefono: cornice dedicata compatta e scena più bassa. Le cornici occupano i margini esistenti; il centro ha alpha zero. La scena è uno sfondo sotto i pannelli e non occupa spazio nel flusso della pagina. Ritratto e pannelli usano livelli distinti con IgnorePointer. Non modificare salvataggi, statistiche, autorizzazioni o costi delle skill per il redesign.

## Plugin e provenienza
Figma: file `Dw1F8sR6bzTCuGkaH2CEeS`, struttura e Art Bible modificabile. Canva: concept botanico `MAHX5OhB8Ts`. Creative Production: board `f6cee63f-2d3d-4c56-8089-0d44f7d23c45`. Adobe: inizializzazione fallita due volte con errore interno; nessun asset viene attribuito ad Adobe. Il concept Canva è una reference, non un PNG con alpha verificato.
## Stile predefinito delle nuove immagini dei mostri

Usare **Expressive Ink**, il tratto a inchiostro approvato il 14 novembre 2026. Contorni scuri marcati, ombre nette, campiture spigolose, silhouette leggibile a schermo piccolo, grana discreta e palette dark fantasy. Prendere il soggetto dai riferimenti e progettare posa, sagoma, dettagli, costumi e ambiente originali. Dal 15 novembre, l’ambiente e i suoi dettagli continuano fino al bordo destro della tavola. Nelle zone dietro i controlli usare il contrasto della scena e la sovrapposizione dell’interfaccia. Il simbolo lunare va inciso o rappresentato come emblema quando richiesto dal canone. Per una revisione facoltativa mostrare l’originale e sei nuove scelte. Usare WebP senza perdita quando verificato e più leggero, preservando originali e ricevute.

Riferimenti visivi scelti dall’utente. [Osservatore del Sole](next_patch_art/solgaze-style-reference-20261114.webp) · [Re Goblin](../assets/oculum/home_art_authored/theme_goblin_king_canon_20261114_v2.webp) · [Combattente dell’Anima](next_patch_art/combattente-dell-anima-20261114.webp)

Dopo la correzione di direzione del 15 novembre, usare la tavola approvata del Re Goblin come riferimento visivo diretto. Definire soggetto e ambiente con grandi campiture opache, contorni irregolari, ombre quasi nere e pochi riflessi netti. L’utente richiede un po’ più di dettaglio a pennello sul soggetto. Concentrarlo su muso, materiali e forme caratteristiche e distinguere il profilo della creatura dalla roccia e dallo sfondo anche in miniatura. Disegnare il fondo fino al bordo destro con pochi piani leggibili. Controllare una nuova tavola a fianco del Re Goblin prima di estendere la stessa resa al lotto.

L’utente approva la V5 del Segugio delle scorie vive partendo dall’allegato, identico alla V3, con una profondità appena più marcata. Separare i piani distanti con leggere differenze di tonalità e contrasto. Il Re Goblin G resta il riferimento principale. La V5 è il riferimento aggiuntivo per pennellate e profondità. [Prova V5 approvata per lo stile](next_patch_art/segugio-scorie-vive-style-reference-v5-20261115.webp) · [Prova V4 precedente](next_patch_art/segugio-scorie-vive-style-reference-20261115.webp).

Preferire un tratto irregolare e intenzionale, con peso della linea variabile, ombre in campiture e tratteggio selettivo. Limitare bagliori, microtexture e motivi ripetuti. Differenziare materiali e silhouette. Controllare mani, arti, occhi e giunture prima di mostrare l’immagine.

Nel Regno Sommerso ogni scena si svolge nell’Eiva respirabile. Disegnare anche le zone abitate immerse, con coralli sulle strutture, fronde acquatiche magiche mosse dalla corrente e riflessi localizzati sui profili. Usare le grandi ombre opache del Re Goblin e separare le figure dagli edifici con la profondità leggera della V5.

**Re Goblin come riferimento artistico principale dei mostri.** L’utente ha ribadito il 15 novembre di usare sempre lo stile della sua tavola canonica. Riprendere le campiture opache ampie, i contorni energici, le ombre spigolose e i riflessi localizzati. L’Osservatore del Sole aiuta con il tratteggio delle membrane e la luce sul bronzo. Il Golem di Terra guida la stratificazione dei materiali, la Combattente dell’Anima le forme spettrali e il Lupo delle Nevi il pelo inciso e le palette fredde. Il Corvo della Morte aiuta con piumaggio e drappeggio. Per ogni mostro rispettare l’anatomia e progettare una composizione originale attiva anche sul lato destro.

Tavole da consultare. [Re Goblin](../assets/oculum/home_art_authored/theme_goblin_king_canon_20261114_v2.webp) · [Osservatore del Sole](next_patch_art/solgaze-style-reference-20261114.webp) · [Golem di Terra](next_patch_art/terramaund-style-reference-20261114.webp) · [Combattente dell’Anima](next_patch_art/combattente-dell-anima-20261114.webp) · [Lupo delle Nevi](next_patch_art/glayswuolf-style-reference-20261114.webp)

Per il nuovo giro includere tutti i mostri, anche quelli già confermati. Ogni scheda di scelta presenta sei reinterpretazioni distinte in Expressive Ink con priorità al Re Goblin, la scelta già approvata al settimo posto se esiste e la versione precedente all’ottavo se è disponibile e distinta. Per i posti senza uno storico usare una variante più distante al settimo e un trattamento di stile o palette alternativo all’ottavo. Collegare i file d’archivio già presenti e conservare gli sfondi attivi fino a nuova scelta. Le nuove tavole si consegnano in WebP.

Mostrare in chat ogni panoramica appena il lotto ha passato il controllo visivo. Presentare due scelte separate per tavola e nome. Accompagnare i nomi alternativi con radici e significato e consentire un nome personale. Per telefono e reliquia mantenere indipendenti le due scelte. Aggiornare la galleria delle scelte aperte con le ricevute confermate e i lotti già mostrati.

**Pose delle nuove varianti.** Variare molto la postura, il gesto, l’azione e il punto di vista tra le tavole dello stesso mostro. Disegnare sagome ben distinte cambiando appoggi, torsione del corpo e orientamento della testa secondo l’anatomia della creatura. Usare lo stile del Re Goblin in tutte le reinterpretazioni e sviluppare l’ambiente fino al bordo destro.

**Nomi da scegliere.** Prima della scelta spiegare sempre anche il nome attuale e ciascuna alternativa. Scrivere la pronuncia, le radici inglesi o latine, il significato e a quale tratto del mostro si riferisce. Consentire il nome personale e conservare le grafie utili alla ricerca.

Per ogni variante Veterana, aggiungere una proposta in cui **Vis** (latino *vis*, «forza») si leghi con naturalezza al resto del nome. Per ogni variante Rituale, aggiungere una proposta che integri **Mirus** (latino *mirus*, «prodigioso»). Ad esempio, **Visbunnys** (*vis-bàn-nis*) conserva il nome della specie e richiama la forza della Veterana.

**Effetti di combattimento.** Le animazioni si estendono sullo schermo e usano forme riconoscibili. I Danni alla Vita tracciano tre tagli scuri con quello centrale più lungo. Le gocce di sangue scendono ai due lati. Il bordeaux ai bordi si intensifica con la percentuale di Vita perduta. La rottura degli Scudi usa fratture e schegge di vetro con ombre scure. Le scene di Senka e dei Solari riprendono il tratto spezzato e le campiture opache del Re Goblin.

La resa bordeaux del primo colpo grave mostrato è quella del **60%** di Vita massima persa. Al **70%** il bordo è più scuro e denso. Sono approvati il confronto finale e gli altri effetti della galleria.

**Scelte del lotto 01, 15 novembre.** Sanguifeng G usa uno scorcio frontale in volo, ali viola aperte, occhio rosso e squame verde oliva. Aculotide G è più compatto e quasi di tre quarti, con placche verde oliva, aculei avorio, fori ventrali leggibili e accenti bordeaux sott’acqua. Il Custode della Campana Cieca H ha una postura eretta e sottile, metallo annerito, campana in bronzo e arcate fredde in indaco e violetto. Mantenere queste differenze di colore, volume e movimento nelle immagini delle rispettive creature.

**Solgheiz e variante del Santuario Allagato.** La scelta è conclusa per entrambe le tavole. L’originale canonico resta il riferimento Expressive Ink per il contorno delle ali e il tratteggio delle membrane. La variante verde riprende il disco solare e le piastre di bronzo fra il muschio e l’acqua del santuario. Il nuovo giro di proposte passa alle altre creature. [Originale](../assets/oculum/home_art_authored/theme_solgaze_canon_20261114.webp) · [Santuario Allagato](../assets/oculum/home_art_authored/theme_solgaze_variante_muschiosa_canon_20261114.webp)

**Oculiath base.** La variante G è la scelta registrata. L’occhio chiaro è racchiuso in un guscio indaco. Si vedono due ali membranose brune e un solo uncino sotto al corpo. L’ambiente è una grotta fossile. [Scelta G](next_patch_art/oculiath-canon-20261114.webp) · [Ricevuta del voto](../output/artwork/expressive_ink_lotto_01/OCULIATH_SCELTA_G.json).

**Oculiath minore.** La tavola D nell’acquedotto, con iride rossa, due ali verdi e un uncino, rappresenta la variante più debole. [Scelta D](next_patch_art/oculiath-minore-20261114.webp).

**Bushilva.** Il potenziamento del Frutibush è visibile nel rivestimento di erba magica resistente. La palette della proposta è bluastra, con indaco e violetto pastello. [Tavola proposta](next_patch_art/bushilva-20261114.webp)

**Priorità dei temi, 17 novembre.** L’utente chiede di rifare tutti i temi dell’app privi della nuova impronta, dando precedenza a quelli dei giocatori. Verificare gli abbinamenti delle schede e gli sfondi Home manuali, che possono prevalere sul preset. Re Goblin G resta il riferimento primario per segno, campiture e ombre; V5 per la profondità leggera. Le revisioni conservano identità, palette, anatomia, posa e scena approvate e mostrano l’originale accanto a sei proposte A–F. Senka e le altre superfici già confermate nel nuovo stile restano i canoni attivi. Telefono, reliquie e cornici sono superfici distinte da armonizzare; la scelta dello sfondo non certifica automaticamente quelle superfici. I piani e le proposte sono registrati in [inventario dei giocatori](../output/artwork/PIANO-TEMI-INK-20261117-PLAYER.json), [inventario degli altri temi](../output/artwork/PIANO-TEMI-INK-20261117-NONPLAYER.json) e [galleria delle proposte](../output/artwork/expressive_ink_player_20261117/GALLERIA.html).

## Conferme artistiche e stato di applicazione — 18 novembre 2026

### Trenta scelte desktop dei temi: confermate e collegate nei sorgenti

L’utente conferma le trenta tavole elencate sotto. Sono ventotto pack e due immagini Home dedicate; le note su Kingi e sul Reliquiario dei sussurri sono richieste separate e non aggiungono due tavole approvate. La ricevuta [SCELTE-TEMI-PLAYER-20261118.json](../output/artwork/SCELTE-TEMI-PLAYER-20261118.json) conserva ID, lettere e SHA del voto.

**Implementato nei sorgenti, non ancora verificato in una build:** la ricevuta [INTEGRAZIONE-TEMI-PLAYER-20261118.json](../output/artwork/INTEGRAZIONE-TEMI-PLAYER-20261118.json) registra i trenta canoni WebP e i collegamenti del resolver. Riporta corrispondenza degli SHA fra voto, fonte scelta e copia canonica, con gli originali stock conservati. Test Flutter, interazioni reali, avvio nativo e build non sono stati eseguiti durante il fermo coordinato della pulizia; questa registrazione non attesta una distribuzione o una prova online.

Le selezioni mantengono ID, nomi stock, palette, posa e scena. Re Goblin G resta il riferimento primario di segno, campiture e ombre; V5 aggiunge soltanto profondità leggera. Un eventuale override esplicito della scena mantiene la precedenza. Gli alias Home `cathedral_eye`, `canva_spirit_duelist` e `benedict` restano invariati. Senka e i suoi derivati approvati non vengono sostituiti.

| Tema | ID stabile | Tavola desktop |
| --- | --- | --- |
| Marea abissale | `abyssal_tide` | [D](../assets/oculum/theme_stories/webp/abyssal_tide_canon_20261118_d_dc86d375.webp) |
| Benedict · Il sole non crea solo mostri | `benedict` | [A](../assets/oculum/theme_stories/webp/benedict_canon_20261118_a_8007de51.webp) |
| Corte di sangue | `blood_court` | [A](../assets/oculum/theme_stories/webp/blood_court_canon_20261118_a_e614e427.webp) |
| Metallo nero bullonato | `bolted_black_iron` | [D](../assets/oculum/theme_stories/webp/bolted_black_iron_canon_20261118_d_d59878f7.webp) |
| Santo d’osso | `bone_saint` | [A](../assets/oculum/theme_stories/webp/bone_saint_canon_20261118_a_45867a79.webp) |
| Cella cremisi | `cell_crimson_run` | [F](../assets/oculum/theme_stories/webp/cell_crimson_run_canon_20261118_f_b398b69c.webp) |
| Vetro che cola | `element_pack_acido` | [B](../assets/oculum/theme_stories/webp/element_pack_acido_canon_20261118_b_ac4df5ae.webp) |
| Angelico · Ali del santuario | `element_pack_angelico` | [D](../assets/oculum/theme_stories/webp/element_pack_angelico_canon_20261118_d_db1a1e09.webp) |
| Raggi dello scoppio | `element_pack_esplosivo` | [D](../assets/oculum/theme_stories/webp/element_pack_esplosivo_canon_20261118_d_8ccf2c04.webp) |
| Circuiti del ritorno | `element_pack_postea` | [B](../assets/oculum/theme_stories/webp/element_pack_postea_canon_20261118_b_2ebd66f1.webp) |
| Bossoli del baluardo | `element_pack_proiettile` | [A](../assets/oculum/theme_stories/webp/element_pack_proiettile_canon_20261118_a_4e398923.webp) |
| Fissione del vetro | `element_pack_radiazione` | [D](../assets/oculum/theme_stories/webp/element_pack_radiazione_canon_20261118_d_21ace57d.webp) |
| Radice · Radici del sepolcro | `element_pack_radice` | [D](../assets/oculum/theme_stories/webp/element_pack_radice_canon_20261118_d_2a24b130.webp) |
| Portali del firmamento | `element_pack_spazio` | [D](../assets/oculum/theme_stories/webp/element_pack_spazio_canon_20261118_d_a7620466.webp) |
| Clessidra del lutto | `element_pack_tempo` | [B](../assets/oculum/theme_stories/webp/element_pack_tempo_canon_20261118_b_62c9fe85.webp) |
| Veleno del serpente | `element_pack_veleno` | [B](../assets/oculum/theme_stories/webp/element_pack_veleno_canon_20261118_b_a5cef015.webp) |
| Duellante spirituale | `home_canva_spirit_duelist` | [B](../assets/oculum/theme_stories/webp/home_canva_spirit_duelist_canon_20261118_b_89d19026.webp) |
| Occhio della cattedrale | `home_cathedral_eye` | [E](../assets/oculum/theme_stories/webp/home_cathedral_eye_canon_20261118_e_41839ab5.webp) |
| Hoshy gatto cosmico | `hoshy_cosmic_cat` | [D](../assets/oculum/theme_stories/webp/hoshy_cosmic_cat_canon_20261118_d_9802ff9d.webp) |
| Bilancia del karma | `karma_duality` | [B](../assets/oculum/theme_stories/webp/karma_duality_canon_20261118_b_b7cd5b14.webp) |
| Eclissi lunare | `lunar_eclipse` | [F](../assets/oculum/theme_stories/webp/lunar_eclipse_canon_20261118_f_89c62655.webp) |
| Folletto di prato | `meadow_sprite` | [B](../assets/oculum/theme_stories/webp/meadow_sprite_canon_20261118_b_20ad125a.webp) |
| Ferro lunare | `moon_iron` | [E](../assets/oculum/theme_stories/webp/moon_iron_canon_20261118_e_4ab89f48.webp) |
| Sigillo ossidiana | `obsidian_sigil` | [E](../assets/oculum/theme_stories/webp/obsidian_sigil_canon_20261118_e_91693ee8.webp) |
| Phobia | `phobia_dark` | [D](../assets/oculum/theme_stories/webp/phobia_dark_canon_20261118_d_9fc04a9f.webp) |
| Lume | `restyle_lume` | [B](../assets/oculum/theme_stories/webp/restyle_lume_canon_20261118_b_5200a706.webp) |
| Sogno | `restyle_sogno` | [A](../assets/oculum/theme_stories/webp/restyle_sogno_canon_20261118_a_f2f4d724.webp) |
| Reliquiario solare | `solar_reliquary` | [B](../assets/oculum/theme_stories/webp/solar_reliquary_canon_20261118_b_81f72337.webp) |
| Vervain | `vervain_gothic` | [B](../assets/oculum/theme_stories/webp/vervain_gothic_canon_20261118_b_97839b7a.webp) |
| Liturgia del vuoto | `void_liturgy` | [B](../assets/oculum/theme_stories/webp/void_liturgy_canon_20261118_b_65550dd8.webp) |

Questi voti approvano gli sfondi desktop. Telefono, reliquie, cornici e prefissi di identità sono superfici distinte: non ricevono una nuova approvazione implicita. Resta il comportamento mobile precedente, con l’eventuale scena mobile esplicita prima del fallback desktop. Gli ID delle schede e delle reliquie salvate e i JSON custom non vengono migrati.

### Reliquiario dei sussurri: ritiro esplicito, legacy conservato

Alla nota «cancella» per `whispering_reliquary`, l’utente precisa «Rimuovi anche il tema dall’app». Il ritiro dalle nuove selezioni e acquisizioni è confermato. I filtri nei sorgenti impediscono nuove applicazioni, assegnazioni e sblocchi anche al Master; gli acquisti rifiutati non devono addebitare risorse. Definizioni, ID e asset restano disponibili per leggere e rappresentare i vecchi salvataggi e le personalizzazioni già esistenti, senza riscriverli. Un tema legacy già attivo non viene automaticamente sostituito. Il [filtro di disponibilità](../lib/widgets/oculum_theme_availability.dart) e i [test dedicati](../test/oculum_retired_themes_test.dart) sono scritti; le prove non sono ancora eseguite. Nessuna tavola nuova di questo tema è approvata dalle due note.

### Kingi: revisione Postea preparata, senza nuova tavola approvata

Indicazioni confermate dell’utente: «più futuristico kingi viene da postea» e «deve apparire futuristico le rune spesso sono tra il metallo interno e quello esterno». La revisione deve rendere leggibile il futuro di Postea con le rune tra il metallo del chassis interno e la corazza esterna, non soltanto come decorazioni sulla superficie. Rimane la resa a inchiostro del Re Goblin G con profondità leggera V5.

Il [brief di revisione Postea](../output/artwork/expressive_ink_player_20261117/kingi_wrong_future/REVISIONE-POSTEA-BRIEF.json) e il [prompt preparato](../output/artwork/expressive_ink_player_20261117/kingi_wrong_future/REVISIONE-POSTEA-PROMPT.md) restano preparazione: zero nuove immagini della revisione generate, nessuna lettera scelta e nessuna nuova approvazione o applicazione runtime. Le precedenti proposte A–F e gli originali sono conservati. Sfondo, robot e reliquia rimangono superfici distinte; da questa richiesta non si deducono nuove anatomie, capacità o regole.

### Giro 1205: dieci tavole e dieci nomi confermati, integrazione in attesa

La ricevuta [SCELTE-GIRO1205-20261118.json](../output/artwork/SCELTE-GIRO1205-20261118.json) raccoglie tutte le conferme artistiche e nominative seguenti, senza nomi ancora da scegliere. Il suo stato è `scelte_e_nomi_verificati_da_integrare`, con `appModified: false`: al momento di questa annotazione i dieci nuovi abbinamenti non sono ancora integrati nei sorgenti.

| Nome confermato | ID stabile | Tavola desktop |
| --- | --- | --- |
| Dulcycrust | `habitat_caramella_rospo_di_crema_variante_veterana` | B |
| Oblyravyn | `habitat_oblio_divoratore_degli_ultimi_nomi_variante_errante` | B |
| Vyridblade | `mantide_sanguescatto` | G |
| Quadrilame | `teschio_quattro_lame` | G |
| Vagafloss | `habitat_caramella_falena_di_zucchero_filato_variante_errante` | A |
| Ventyscute | `habitat_isole_razza_del_cielo_basso_variante_corazzata` | G |
| Runycrick | `base_postea_02` | G |
| Cynyscarn | `weak_horror_mastino` | F |
| Senza Volto Errante | `pellegrino_senza_volto_variante_errante` | H |
| Ensypuppet | `manichino_spada` | C |

Sono conferme della tavola desktop e del nome, non una prova di funzionamento nel gioco. Non assegnano nuove anatomie, parti mirabili, statistiche, abilità o regole. Le approvazioni di telefono e reliquia e le verifiche di integrazione restano separate. Tutto lo storico delle scelte precedenti rimane conservato.


## GranScostumato G — scelta del 18 novembre 2026

Nuovo canone desktop: roditore della famiglia Scostubanditi molto muscoloso, cannone a una mano e forte scorcio verso chi guarda. [G approvata](../assets/oculum/home_art_authored/theme_granscostumato_canon_20261118_v3.webp). Conservare il nome. Il tema mantiene l’intera tavola nelle superfici alte. Il disegno non aggiunge poteri o bersagli.

Anche Errati, Empatici e Forest Demon Baby/adulto sono esclusi dalle nuove rinomine, comprese le forme già nominate dall’autrice. Per gli altri mostri le nuove opzioni sono da 4 a 9 lettere, con pronuncia, radici e significato. L’autrice richiede tre rese ink distinte: contorni spezzati/ombre ampie, graffi marcati, ombre sporche con soggetto definito. Per Rupnyr sceglie B, graffi e pennello più ruvido; il nome sostituisce Rupygnash nella nuova proposta senza creare automaticamente statistiche di catalogo.
