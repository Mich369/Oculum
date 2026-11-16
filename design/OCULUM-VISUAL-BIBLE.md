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
