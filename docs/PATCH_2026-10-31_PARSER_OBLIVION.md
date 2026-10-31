# Patch del 31 ottobre — parser, Senka e Oblivion Shield

## Riparazione dei controlli CI e nuova verifica completa

La run41196964717 del commit3a76ceeb si è fermata con1917test passati,20falliti e6saltati. Le build native della distribuzione coordinata sono state saltate e quella run non è stata pubblicata. Diciotto controlli conservavano l'aspettativa di derivati assenti per sei creature già approvate: ora verificano davvero telefono, reliquia, alpha, margini e clic; quattro desktop con derivati ancora da votare mantengono il controllo di esclusione. Il catalogo passa correttamente da380a381 con la nuova variante Baghest, senza indebolire i controlli su duplicati e tecniche.

L'ultimo fallimento dipendeva dalla riduzione casuale indipendente di Fortuna/Resistenza nella fixture della parata. Isolati quei passivi soltanto nel test: nessuna modifica alla regola produttiva del65%. Confermato separatamente il riferimento Resistenza per il doppio critico. Il caso della parata con tiro d'attacco inferiore al riferimento è passato in cinque ripetizioni indipendenti.

**Verifica locale:**150riprove mirate passate, poi suite completa **1959passati/6saltati/0falliti** in26min41s; analisi finale senza problemi in136,6s. Log `build/patch_31_ci_repairs_targeted.log`, `build/patch_31_ci_repairs_full.log`, `build/tail_parry_deterministic_1.log`–`5.log` e `build/patch_31_ci_repairs_analyze.log`. I gruppi si sovrappongono: non sommare i conteggi. NuovaCI, pacchetti, pubblicazione e prove online restano passi successivi; nessuna chiusura100% dalla sola suite.

## Revisione successiva a3fe20e43 — verifiche distinte

- Ultimo controllo: riprodotto e corretto il parser anatomico che ignorava «Non ha occhi» nella Torretta Oculum. Conservati i due occhi laterali del Mostro Solare e gli override del Master; nessun occhio aggiunto alle nuove proposte della Torretta.

- Nuova correzione destinatari ad area: `nemico` e `bersaglio` mantengono la preparazione sul bersaglio, senza diventare bonus personali dopo l’editor.
-19desktop approvati e16derivati approvati copiati senza cambiare i pixel; mapping e SHA in `design/approved-monster-desktops-2026-10-31.json` e `design/approved-monster-derivatives-2026-10-31.json`. Rendering e clic su320/834/1440px nei test mirati. I nuovi derivati di oggi restano da approvare.
- Due Manichini separati, Corruzione Rossa iniziale3Notti per Baghest e purificazione dal menu Master. Un’Azione, pietra solo al successo, confronto confermato; nessuna morte/ricompensa da uccisione. La pietra è nel catalogo assegnabile dal Master, non è una dose alchemica. La regola generale delle dosi resta invariata finché l’utente chiarisce l’eventuale altra via.
- Corretto il salvataggio dell’ultima condizione: viene serializzata esplicitamente la lista vuota, evitando che la fusione col precedente JSON ripristini il malus rimosso. La prova comprende salvataggio e riapertura. Individuato e corretto nei test anche il consumo di un riferimento inventario precedente al cambio di scheda: l’ultima pietra ora viene consumata sull’istanza effettiva.
- **135test mirati locali passati**, log `build/patch_31_followup_verified.log`: parser, runtime, menu Master, anatomie, temi, condizioni, salvataggi, patch online e guardiano salvataggi updater. Altri30test successivi passati su temi, hash, purificazione, log offline e inventario con catalogo differito;12prove Python dei download passate. Questi gruppi si sovrappongono, non sommare i conteggi. Analisi finale senza problemi (136,1s), log build/patch_31_followup_analyze_final.log. La CI della nuova revisione segue separatamente; non sommare i gruppi sovrapposti.

**CI del solo precedente3fe20e43:** run41187167236 riuscita su tutti i job,1920test passati/6saltati, analisi senza problemi e4prove autenticate passate; questi numeri non certificano già le nuove modifiche successive. Nessuna nuova sessione su tre dispositivi fisici attestata.


## Modifiche

- Danno/Cura accetta `25%` della Vita attuale e `25%Tot` della massima, senza usare gli HP temporanei come base. Restano Difesa, resistenze, Scudi e le due opzioni indipendenti Oltre Difesa/Oltre Scudi. I pacchetti automatici conservano gli importi propri.
- Parser comune: costi leggibili con intervallo minimo/massimo, effetti secondari su critico e con Danni alla Vita, anteprime Bonus/Malus e collocazione Attacco corretta. Le personalizzazioni strutturate nel JSON restano prioritarie. Il punto che chiude una frase non viene più inglobato nella formula delle note; decimali ed errori matematici reali restano riconoscibili.
- Oblivion Shield conserva l'ID del Famelico. Fiammata del non ricordo prepara il proprio effetto all'attivazione; un critico con perdita di Vita verifica Memoria e, per il Fato, Fortuna. L'effetto fa perdere la prima A/R/RV successiva tentata, senza pagare anche costi di statistiche o avviare l'abilità; log «cosa stavo facendo?». Replay e consegne duplicate non moltiplicano la perdita. Scudi critici e contrasto vincente contro la Fiammata proteggono.
- Senka esportata con100EXP già inclusi, un Vitalium Ridefinito e coltellino equipaggiato+3Tagliente. Maschera non equipaggiata; Danni e Difesa nei campi numerici corretti, senza duplicarli in comandi eseguibili nelle note. Nessun salvataggio esistente riscritto.
- Anatomie approvate: Saltalungo e Bestia delle Nuvole con due braccia/due gambe e una sola coda; Oblivion e Forest Demon quadrupedi senza braccia aggiuntive generate dal testo. Override del Master conservati.
- Lupo Infernale del Ghiaccio corretto come creatura delle zone ghiacciate dell'Inferno: morso/carica Ghiaccio, resistenza Ghiaccio, Rallentamento nelle forme superiori del Morso, materiale rinominato Scheggia di gelo infernale. Numeri, limiti e ID legacy conservati; nessun soffio aggiunto. Le cinque nuove proposte artistiche sono una valutazione separata.

## Cosa resta modificabile

Editor e JSON conservano costi/minimi/massimi, statistiche, tipi di danno, bersagli, critico richiesto, Danni Vita richiesti, durata, recupero, forme, effetti, equipaggiamento, anatomie e temi. Gli effetti non riconosciuti automaticamente restano visibili da controllare: non diventano bonus gratuiti.

## Evidenze locali

**Ripetizione finale al commit3fe20e43:**1920test passati,6saltati, nessun fallimento,30min23s, con concorrenza2. Sorgenti congelati durante la suite; log `build/patch_31_full_final.log`. Analisi finale locale senza problemi in240,9s, log `build/patch_31_analyze_verified.log`. Sono prove locali: nessuna distribuzione pubblica o sessione multi-dispositivo dedotta da questo risultato.

La prima suite completa ha terminato con1916test passati,6saltati e1fallito: la fixture delle percentuali lasciava riattivare la Resistenza passiva casuale. Isolata la fixture senza cambiare la regola;85riprove passate. Successivamente40prove su Lupo/anatomie/catalogo e41su attivazione reale/parser/Senka passate; i gruppi si sovrappongono e non si sommano. Una prova nuova ha individuato il filtro Vita prematuro sull'effetto ostile: corretta la preparazione prima del colpo.

Analisi completa pulita prima dell'ultima correzione glaciale e del controllo d'attivazione; ripetizione finale richiesta. Dodici prove Python dei download pubblici passate usando una cartella temporanea nel progetto; il primo tentativo era bloccato dai permessi della cartella temporanea sandbox.

Suite finale, CI GitHub, prove autenticate, pacchetti installati, download pubblici e UI su dispositivi separati restano verifiche distinte. Questa nota non certifica automaticamente i passi successivi né chiude righe al100%.
