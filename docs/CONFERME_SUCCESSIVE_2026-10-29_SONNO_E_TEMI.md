# Conferme successive del 29 ottobre — sonno, bisogni e temi

**PER IL PROSSIMO INTERVENTO.** Fonte: ultime risposte esplicite dell’utente in chat, riportate dal coordinamento della lavorazione. Le correzioni più recenti prevalgono nei rispettivi ambiti; i documenti e le versioni precedenti restano storico. Questo documento registra regole e approvazioni visive, senza attestare implementazione, nuovi test o distribuzione.

Base corrente su main: `dcb5bb4e`, che aggiunge soltanto la correzione della fixture di test dal vivo alla base app `73e08420`. Per quest’ultima sono già riportati **1.690 test passati, 6 saltati e 4 prove autenticate passate**. La CI di `dcb5bb4e`, run **`40904083210`, è riuscita per tutte le piattaforme**; pubblicazione automatica `40913133550` e Pages `40913133658` riuscite; **11 download pubblici verificati senza login e commit web corretto**. Installazione locale **completata**: **binari attivi `dcb5bb4e`**, 16.088 file senza differenze, firma APK e avvio normale/Test verificati; precedente `e188eafe` conservata nel backup. Queste evidenze riguardano la base precedente, non le conferme future qui sotto. Questa consegna della base è verificata; le nuove regole qui sotto restano future e nessuna nuova riga è chiusa al 100% senza conferma.

Collegamenti: [regole confermate](OCULUM_REGOLE_CONFERMATE.md), [canone visivo](OCULUM_LORE_VISIVA.md), [diciture dell’utente](DICITURE_UTENTE_2026-10-27.md), [attività](DA_FARE_PATCH_E_SUCCESSIVI.md), [conferme precedenti del 29 ottobre](CONFERME_2026-10-29_PREMI_GUARDIANI.md).

## Tempo condiviso e sonno — regole confermate, da implementare

- I **giorni avanzano automaticamente** con l’orologio di campagna; resta la giornata Oculum di nove ore già confermata. L’orologio è condiviso dal party e dal Master nella campagna pertinente.
- La **dormita lunga rispetta la durata scelta**, con almeno **90 minuti dormiti** e il passaggio della **prima Mattina** prima del risveglio. Non viene troncata al primo Mattino se la durata scelta è maggiore: può terminare nel Pomeriggio o nella Notte successiva, purché quella prima Mattina sia già passata. Se manca meno di 90 minuti alla Mattina, il sonno continua oltre il cambio di fase fino al minimo. Esempio esplicito, senza una durata maggiore scelta: addormentarsi un’ora prima della Mattina fa dormire 90 minuti, con risveglio **30 minuti dopo** l’inizio della Mattina.
- **Più minuti effettivamente dormiti danno più recupero.** Il bilanciamento della quantità recuperata è delegato e deve restare modificabile; qui non si fissa una formula, un nuovo tetto o un arrotondamento non approvato.
- Un unico episodio di sonno valido produce **un solo evento di Riposo Lungo** per Open, recupero degli usi e altri contatori collegati. Il recupero maggiore dovuto alla durata non diventa una sequenza di Riposi Lunghi.
- Il Master deve poter usare **«Fai passare tempo»**, indicando ore e minuti per la campagna e il party interessati. Il normale trascorrere del tempo o la semplice attesa **non assegnano automaticamente il recupero di un riposo**: durata trascorsa e sonno effettuato sono informazioni distinte.

Salvataggi, assegnazioni online e personalizzazioni devono conservarsi. La futura implementazione dovrà distinguere durata del sonno, avanzamento dell’orologio e singolo evento di Riposo Lungo, senza duplicare eventi ricevuti online. Questi sono requisiti per la verifica successiva, non prove già eseguite.

## Fame, sete e sonno — malus separati

I malus per **fame**, **sete** e **mancanza di sonno** devono applicarsi automaticamente e restare separati. Soddisfare un bisogno rimuove i malus dovuti **a quello specifico bisogno**: mangiare non risolve automaticamente la sete o la mancanza di sonno, e dormire non sostituisce cibo e acqua. Non cancellare per questo effetti diversi o personalizzazioni della scheda.

**Eccezione confermata: i Costrutti non biologici sono esenti dai bisogni di cibo e acqua, ma richiedono comunque riposo.** Non attribuire loro malus da fame o sete e non estendere questa esenzione al sonno/riposo.

Numeri richiamati dal manuale e confermati per il prossimo intervento:

| Condizione | Effetto da conservare |
|---|---|
| Un giorno senza cibo o acqua | **+3 Cenere** e **−1 temporaneo a una statistica casuale**. |
| Tre giorni senza soddisfare i bisogni | **−1 Resilienza e −1 Oculum temporanei**. La nuova indicazione parla di giorni; il manuale storico diceva «3 sessioni». |

Queste soglie non autorizzano a inventare ulteriori penalità, ad applicare due volte lo stesso evento o a rendere permanenti le riduzioni. I parametri devono rimanere modificabili e salvabili tramite gli strumenti esistenti.

### Riposo Breve — scelta esplicita di un quarto

L’utente ha scelto esplicitamente **«Un quarto, come il codice attuale»**. Il Riposo Breve recupera quindi **un quarto del mancante delle statistiche correnti**, come `oculumShortRestQuarterRecovery`, richiamato da `recuperaStatsAttualiConRiposoBreve`. Il **recupero di Vita di 1d100 è separato**: non diventa un quarto della Vita e non viene sostituito dal recupero delle statistiche.

La scelta chiude il conflitto precedente con la metà riportata nel manuale: **non è più una domanda aperta**. La vecchia formulazione resta storico; allineamento del manuale e verifiche sono demandati al prossimo intervento. Il conteggio separato delle statistiche spese per raccolta, già trattato a metà dal codice, e il recupero del 25% della Cenere non vanno confusi con questo recupero delle statistiche correnti.

Fonti dello stato precedente: [manuale, bisogni e riposi](manuale-consultazione.md), `lib/src/main/oculum_helpers.dart`, `lib/src/main/oculum_home_calculations.dart`, `lib/src/main/oculum_home_resources_rest_titles_data.dart`. Il manuale e il codice non sono modificati da questo documento.

## Ultimi 30 minuti della Notte — Sole e bonus delle creature

Il Sole **risbuca scendendo dall’Oblio che lo copre, presso le Isole volanti**. Non è un’alba terrestre con il Sole che sale dall’orizzonte. Questo chiarimento non introduce un nuovo modello astronomico, non riporta la Luna nel cielo e non autorizza corpi celesti nelle scene sotterranee.

Ultimo chiarimento meccanico **approvato dall’utente**: negli **ultimi 30 minuti della Notte**, il bonus notturno delle creature **cala gradualmente fino a zero all’inizio della Mattina**. Esempio confermato per un bonus iniziale di +10:

| Tempo restante della Notte | Bonus dell’esempio |
|---|---|
| 30 minuti | +10 |
| 15 minuti | +5 |
| Inizio della Mattina | 0 |

È un calo del bonus temporaneo, non delle statistiche base. Resta la portata già confermata per le creature mostruose, comprese alleate, PG ed evocazioni. La futura implementazione dovrà mantenere separati valori base e bonus di fase; arrotondamenti e parametri di bilanciamento non specificati restano modificabili. Il passaggio precedente con bonus pieno fino al cambio di fase è superato da questa conferma, senza riscriverne lo storico.

## Corruzione — ultima risposta, Notti effettive confermate

**L’utente ha confermato le Notti effettive della campagna**, anche se il personaggio rimane sveglio. **Dormire di giorno non aggiunge una Notte.** Il conteggio della corruzione non è quindi il numero di eventi di Riposo Lungo: avanzamento delle Notti e recupero degli usi devono restare distinti. Questa ultima risposta chiude la domanda precedente, che resta storico; la sua implementazione e verifica appartengono al prossimo intervento.

## Artwork desktop approvati — integrazione futura

Resta obbligatorio lo stile pittorico **Rame fatato**: opaco, pennellate morbide e materiche, centro leggibile, figura intera entro i margini; nessun testo, interfaccia o cornice dipinti. Il riferimento `amber_shore.png` stabilisce la tecnica, non impone di copiarne la scena. Nessun nuovo potere o drop deriva da un’immagine; nessun ritratto viene imposto nel Monster Book.

Le approvazioni seguenti riguardano i **desktop selezionati**, non approvano automaticamente telefono o reliquia. Tutti i percorsi sono relativi al repository.

| Creatura | Desktop canonico approvato | Dettagli da mantenere |
|---|---|---|
| Funghetto Cappuccio Rosso | `output/artwork/drafts_2026-10-29/funghetto_cappuccio_rosso_background_draft_v1.png` | Corpo crema, due occhi e cappello rosso; conservare il design approvato. |
| Costrutto Minore | `output/artwork/drafts_2026-10-29/costrutto_minore_background_draft_v1.png` | Piccolo costrutto a scatola, bronzo/oro, **20–50 cm**, spada e grande scudo. |
| Shadow Devil | `output/artwork/drafts_2026-10-29/shadow_devil_background_draft_v1.png` | **Nessun occhio**, due corna, filamenti d’ombra e denti; la gratitudine trasmessa alla morte non autorizza un nuovo potere visivo. |
| Mostro di Sabbia | `output/artwork/drafts_2026-10-29/mostro_sabbia_background_draft_v2.png` | L’utente accetta esplicitamente il quadrupede affusolato: **quattro arti, due corna e grande coda**. Non correggerlo verso un’anatomia precedente non più richiesta. |
| Sharp | `output/artwork/drafts_2026-10-29/sharp_background_draft_v3.png` | Versione3 approvata: **quattro zampe e occhi visibili**, corpo bianco a sacco, enorme bocca verde con denti triangolari, calotta nera con due razzetti rossi e spuntoni metallici sul dorso. Buono e curioso; scena sotterranea senza cielo o astri. |
| Topino Avventuroso | `output/artwork/drafts_2026-10-29/topino_avventuroso_background_draft_v2.png` | Circa **25 cm**, pelliccia miele, due braccia e due gambe, stessa posa e fiaccola più alta di lui. **Mantellino tortora**, senza identità lunare o solare; resta sfrangiato. La v2 è la versione attuale approvata con «confermo». |
| Mosca Campana | `output/artwork/drafts_2026-10-29/mosca_campana_background_draft_v3.png` | Versione3 approvata: **sei zampe, quattro ali, due campane di bronzo e occhi bianchi senza pupille**; corpo nero peloso. |

### Topino — correzione più recente e provenienza

Il desktop v1 era stato approvato, poi l’utente ha chiesto un mantellino **«grigio o colore più carino non lunare né solare»**. Il coordinamento ha prodotto con ImageGen la v2 tortora; l’utente ha risposto **«confermo»**. La nuova approvazione sostituisce soltanto il colore del mantello e conserva posa, anatomia, pelliccia miele, scala di 25 cm, fiaccola alta e altri dettagli del design. La descrizione storica del catalogo e il prompt v1 con mantello verde restano fonti della versione precedente, non il colore canonico attuale.

Provenienza registrata nel [manifest Sharp/Topino/Mosca](../output/artwork/drafts_2026-10-29/manifest_sharp_topino_mosca.json), senza pubblicare percorsi privati locali. V2: **1586×992 px**, **2.162.188 byte**, SHA256 `2d75cb4e8e3d71f67ddc22b8e63fb8855dc86999070c9c5f65a411e5f6574890`. La copia nel repository coincide per SHA256 con l’immagine generata indicata dal coordinamento; questa è una verifica del file, non della UI.

Altri manifest di provenienza: [Funghetto/Costrutto](../output/artwork/drafts_2026-10-29/manifest_funghetto_costrutto.json), [Shadow/Sabbia](../output/artwork/drafts_2026-10-29/manifest_shadow_sabbia.json).

### Otto derivati telefono/reliquia — tutti approvati separatamente

Sono generati **otto derivati selezionati**, due per ciascuna delle prime quattro creature, e **tutti e otto sono ora approvati separatamente**. Dopo le conferme per Funghetto e Costrutto Minore, l’utente ha risposto **«Sì, entrambi canonici»** per Shadow Devil e **«Sì, entrambi canonici»** per Mostro di Sabbia. Sono conferme delle coppie mostrate telefono v1/reliquia v2, senza attribuire verifiche alla UI.

| Creatura | Telefono proposto | Reliquia proposta | Stato alla presente conferma |
|---|---|---|---|
| Funghetto Cappuccio Rosso | `funghetto_cappuccio_rosso_phone_draft_v1.png` | `funghetto_cappuccio_rosso_relic_draft_v2.png` | **Entrambi approvati canonici**, risposta successiva dell’utente. |
| Costrutto Minore | `costrutto_minore_phone_draft_v1.png` | `costrutto_minore_relic_draft_v2.png` | **Entrambi approvati canonici**, risposta successiva dell’utente. |
| Shadow Devil | `shadow_devil_phone_draft_v1.png` | `shadow_devil_relic_draft_v2.png` | **Entrambi approvati canonici**, «Sì, entrambi canonici». |
| Mostro di Sabbia | `mostro_sabbia_phone_draft_v1.png` | `mostro_sabbia_relic_draft_v2.png` | **Entrambi approvati canonici**, «Sì, entrambi canonici». |

Cartella comune: `output/artwork/drafts_2026-10-29/`. [Manifest dei derivati](../output/artwork/drafts_2026-10-29/manifest_phone_relic_derivatives.json). I relic v1 restano revisioni storiche, esclusi dal conteggio degli otto selezionati. Sharp, Topino e Mosca non ricevono con questa nota approvazioni implicite per derivati mancanti.

**Stato di consegna:** canone dei sette desktop e degli otto derivati dei quattro pack approvato; integrazione da effettuare e verificare. Nessun nuovo asset runtime, test renderer, pacchetto o download è certificato da questo documento.

## Gigante di sabbia — nuova specie e desktop v6 approvato

Il **Gigante di sabbia** è distinto dal Mostro di Sabbia quadrupede già approvato: **umanoide massiccio e bestiale, con la stessa grande coda**. I desktop **v1, v2, v3, v4 e v5 sono rifiutati** e conservati come storico. **V6 è approvata canonica**, risposta esplicita «Sì, questa è canonica».

Ultima direzione del volto: ispirazione alla **trasformazione parziale di Gaara/Shukaku in Naruto**, con struttura del viso diversa dalle bozze precedenti, resa anime meno plastica, denti **grigio-neri**, espressione intelligente e inquietante. L’ispirazione non richiede tatuaggi, capelli o segni di Naruto; mantenere un design originale coerente con Oculum e lo stile Rame fatato.

Desktop canonico: `output/artwork/drafts_2026-10-29/gigante_sabbia_background_draft_v6.png`; [manifest v6 e prompt](../output/artwork/drafts_2026-10-29/manifest_gigante_sabbia_partial_v6.json). Testa compatta e muso corto, segni blu-neri attorno agli occhi e denti carbone. Anche telefono v1 e reliquia v1 del Gigante sono stati successivamente approvati con «Sì, entrambi canonici»: `gigante_sabbia_mobile_draft_v1.png` e `gigante_sabbia_relic_draft_v1.png`. Integrazione e prove UI non ancora eseguite.

## Coda e Gigante di sabbia — meccaniche nuove, NON implementate

Le regole seguenti sono conferme per il prossimo intervento; **non sono ancora implementate o verificate dal motore**.

- **Entrambe le specie**, Mostro di Sabbia e Gigante di sabbia, possono usare gratuitamente la coda per **attaccare oppure parare**. La **parata non richiede tiro**. I due impieghi condividono lo **stesso recupero di due turni personali**, non due recuperi indipendenti.
- Precisazione successiva: l’attacco gratuito si può usare **anche fuori turno**. Per critico/doppio critico della parata senza dado si confronta **Resistenza**, come il mantello dell’Aberrazione, non CM passiva.
- La parata fa ricevere il **65% dei Danni calcolati dopo la Difesa e prima degli Scudi**. Il 65% è la quota ricevuta, non la riduzione da sottrarre. Gli Scudi si applicano dopo questo passaggio.
- **Soltanto il Gigante** non ha un punto debole anatomico e ha **fragilità al Fuoco**. Non estendere queste proprietà al Mostro di Sabbia quadrupede e non assegnare una percentuale di fragilità non specificata.
- Un **doppio critico Lava valido sulla Vita, in assenza di Scudo critico**, ha **50% di uccidere il Gigante trasformandolo in vetro**. Non applicare questa risoluzione a un colpo che non soddisfa le condizioni.
- Se il Gigante sopravvive a quel colpo, la sua **Materia è dimezzata per tre turni personali**. Una nuova applicazione valida **rinnova la durata senza dimezzare ulteriormente** la Materia già ridotta; nessuna penalità cumulativa.

Costi, durata, recupero, bersagli ed effetti devono restare modificabili dagli editor esistenti e conservabili nel JSON senza sovrascrivere personalizzazioni. La conferma delle meccaniche non equivale all’approvazione visiva del desktop v5.

## Conferma precedente da preservare — D29

La riga **D29 resta approvata al 100%** per il duello effettivamente svolto: Senka mascherata **135/135 Vita**, **14 Scudo** e **20 Oculum** all’avvio. Si tratta della prova fra i due codici personali già documentata, distinta dalla simulazione a pari PT. Le nuove richieste su sonno e artwork non riaprono quella conferma e non attribuiscono nuove verifiche online.

## Passi futuri, ancora da verificare

| Ambito | Verifica richiesta nel prossimo intervento |
|---|---|
| Sonno e orologio | Durata scelta rispettata anche fino al Pomeriggio/Notte successiva, minimo 90 minuti e prima Mattina sempre trascorsa; caso un’ora prima → risveglio 30 minuti dopo senza durata maggiore scelta; giorni coerenti nella campagna condivisa. |
| Recuperi | Durata maggiore con recupero maggiore secondo bilanciamento modificabile; un solo evento di Riposo Lungo per episodio, anche per Open e usi. |
| Bisogni | Malus distinti, soglie in giorni e rimozione soltanto soddisfacendo il bisogno corrispondente; Costrutti non biologici esenti da cibo/acqua, ma non dal riposo; conservazione del JSON personalizzato. |
| Tempo Master e bonus | Ore/minuti applicati alla sola campagna/party prevista, nessun riposo da semplice attesa; bonus notturno in calo negli ultimi 30 minuti fino a 0. |
| Corruzione | Contare le Notti effettive anche da svegli; sonno diurno senza nuove Notti; preservare lo stato salvato e distinguere i contatori dai Riposi Lunghi. |
| Riposo Breve | Scelta di un quarto del mancante delle statistiche correnti, con 1d100 Vita separato; allineamento del manuale successivo, senza riaprire la domanda risolta. |
| Artwork | Integrare gli otto derivati approvati e verificare con controlli reali a 320/834/1440 px; Gigante desktop v6, telefono e reliquia v1 approvati, v1–v5 desktop rifiutati; conservare gli asset precedenti finché i sostituti non sono verificati. |
| Specie di sabbia | Coda gratuita attacco/parata, recupero condiviso due turni personali, quota 65% dopo Difesa e prima Scudi; proprietà esclusive del Gigante, doppio critico Lava e dimezzamento MAT senza accumuli. Tutto da implementare e testare. |

I dettagli privati di gestione degli archivi non fanno parte del canone di gioco o visivo e non sono riprodotti qui.

## Ulteriori derivati generati — approvazione ancora da raccogliere

Sharp: `sharp_phone_draft_v1.png` e `sharp_relic_draft_v1.png`; Topino tortora: `topino_avventuroso_phone_draft_v1.png` e `topino_avventuroso_relic_draft_v1.png`; Mosca Campana: `mosca_campana_phone_draft_v1.png` e `mosca_campana_relic_draft_v2.png`. Tutti in `output/artwork/drafts_2026-10-29/`, con manifest `manifest_sharp_topino_mosca_derivatives.json`. **Sei bozze non ancora mostrate per approvazione**, nessuna integrazione o prova UI. La v1 della reliquia Mosca resta storico.
