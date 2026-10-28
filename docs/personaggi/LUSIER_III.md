# Lusier III

Guardia Solare Élite, livello13 e Grado I. Base56 più il budget di livello/Grado calcolato dal generatore. Volontà primaria, Oculum secondario; 1 Scudo critico e 150 Scudo Oculum.

L’artwork approvato è `assets/oculum/home_art/character_lusier_iii_v1.png`: pelle calda olivastra, capelli castani mossi non troppo lunghi e occhi d’oro eccezionalmente intenso. Le sete avorio e bordò ricamate d’oro, il colletto alto e la stola recano occhi solari e formano l’abito protettivo. Rimane bello e inquietante, senza aggiungere caratteristiche non approvate.

Equipaggiamento: abito del comando, spada sacra +20 Danni Solari, mazzo personale di carte esplosive II con recupero speciale3/turno e un Vitalium Ridefinito. **Le sue carte sono dorate**, eccezione personale confermata il28 ottobre; il mazzo generico acquistabile rimane non d'oro. Massimo10 presenti e5 lanciate; ogni carta1d25 + un quinto per difetto dei Danni attuali. Il suo mazzo viene incluso nei drop della morte confermata; vendita soltanto al Mercato Nero, incasso iniziale215 Obser, modificabile nella fascia180–250.

Raggio del comando solare e Velo del sigillo aureo usano costi, cooldown ed effetti strutturati. Derisione segue i margini e i critici confermati nel registro: non infligge Danni diretti e i suoi premi per colpirlo sono limitati a lui.

La morte dei genitori di Senka è raccontata nell’incubo in [SENKA_INCUBO.txt](SENKA_INCUBO.txt). Lusier è il responsabile; Haniel raccoglie e protegge le due sorelle e prepara Kamaria alla vendetta. La soglia pronunciata da Haniel si aggiorna dalla misurazione effettiva della scheda in `output/characters/lusier_iii/potenza.json`.

Tutti i valori, effetti, costi, CD, descrizioni, materiali, peso, capienza e recupero del mazzo sono conservati nel JSON e modificabili. Un test locale non certifica una build pubblicata.


## Titolo confermato il 28 ottobre — in verifica

- Titolo equipaggiato, con Open già sbloccata per Lusier. Buff: Difesa +1×livello e 15% di evitare maledizioni/condizioni negative altrimenti riuscite, aggiuntivo al normale tiro difensivo. Con la propria Open: protezione 30% e un ulteriore +1×livello Difesa.
- Skill con un'arma equipaggiata: ai DANNI aggiunge il maggiore fra Riflessi e Precisione, non al tiro per colpire. Se colpisce ottiene Scudo Oculum pari a 5 + metà per difetto del sottotratto scelto, anche oltre il massimo (150 +12 →162).
- Punto cieco: mania di grandezza; −5 al tiro per colpire chi è a metà Vita o meno mentre lui è sopra metà Vita. Non è pietà: non vuole perdere altro tempo.
- Open: dalla mano aperta un raggio solare spesso, capace di inseguire e bersagliare TUTTI gli avversari del fight; +5 per colpire. Danni attuali +1d100+45 Solari. Con 91–100 sul dado, il danno di QUEL raggio aumenta del 25%; nessun aumento permanente dei Danni di Lusier.
- Open Buff insieme alla Open: un Vitalium Solare per fight. All'uso cura il 65% della Vita attuale +10% della Vita massima, aggiunti alla Vita attuale e fermandosi al massimo; l'arrotondamento resta per eccesso. Recupera metà per eccesso delle altre risorse e dell'integrità Art mancanti e concede +1 Scudo critico; non riduce riserve già oltre il massimo. Ultima correzione esplicita del 28 ottobre: sostituisce la cura precedente e la proposta intermedia 50% attuale +25% massima. L'oggetto si consuma all'uso.
- Skill Open dal dito: Danni attuali +1d25+15 Solari; con la propria Open diventa Danni attuali +1d50+25 e può colpire fino a due bersagli. Su uno solo NON raddoppia i Danni: usa Precisione +10; se conosce il punto debole lo mira e, se lo centra, aggiunge 15 Danni DOPO il raggio, ignorando soltanto la Difesa e rispettando gli Scudi.
- Senka: soltanto la maschera inizia non equipaggiata; il coltello è equipaggiato. Lusier indossa abito, spada e mazzo; il Vitalium è un consumabile nell'inventario.
- Simulazione richiesta: copia separata di Senka a livello12 con la stessa PT effettiva di Lusier, tutte le evoluzioni compatibili e Open sbloccata. Non sostituisce il codice originale di Senka livello1. Riportare scenari e risultati effettivamente verificati, senza dichiarare assenza assoluta di bug.
