# Oculum — registro delle regole confermate

Ultimo aggiornamento: 19 ottobre 2026. Documento da consultare prima di modificare il regolamento.

## Fonti e precedenza

1. Correzione esplicita più recente dell'utente, registrata qui con un esempio.
2. [Manuale integrale consultabile](manuale-consultazione.md), esportato dal manuale interno `lib/src/main/oculum_manual_sections.dart` con `dart run scripts/export_manual_reference.dart`.
3. Codice e test indicano il comportamento implementato: non dimostrano da soli che una regola sia corretta.

Non considerare questo registro la prova che ogni regola è già implementata e verificata. Per l'esito della patch consulta il suo rapporto di verifica. Non inventare regole mancanti: chiedi all'utente, registrane la risposta e aggiungi esempi e test.

## Conferme del 18 ottobre 2026: attacco e difesa

**Arrotondamento generale confermato:** normalmente per difetto. Una regola può dichiarare un'eccezione: la Difesa ×1,5 del quasi riuscito arrotonda per eccesso. Non estendere automaticamente questa eccezione ad altri valori.

Indichiamo con A il totale del tiro d'attacco e con D il totale del tiro difensivo. La Difesa numerica della scheda è una grandezza distinta da D.

| Difficoltà | Quasi riuscito | Pieno ordinario | Evitato ordinario |
|---|---|---|---|
| Facile | A − D da 1 a 6 | A − D da 7 in su | A ≤ D |
| Medio/Normale | A − D da 1 a 5 | A − D da 6 in su | A ≤ D |
| Difficile | A − D da 1 a 3 | A − D da 4 in su | A ≤ D |
| Oculum | A = D oppure A = D − 1 | A > D | A ≤ D − 2 |

Quasi riuscito: la Difesa numerica contro quel colpo vale ×1,5, **arrotondata per eccesso** (conferma dell'utente: Difesa 7 → 11). Il danno base non viene dimezzato. La durata degli effetti in turni/azioni è dimezzata, arrotondata per difetto, minimo 0: 1 diventa 0, 3 diventa 1, 6 diventa 3. Un effetto con durata risultante 0 non viene applicato; 0 non significa durata infinita.

Esempio Oculum, D=10: A=9 o 10 quasi riuscito; A=11 pieno; A=8 evitato.

### Critico positivo da tiro doppio

- A almeno doppio di D: critico positivo dell'attacco.
- D almeno doppio di A: difesa critica positiva e una reazione gratuita contro chi ha provato a colpire. Il log deve dire **«reazione gratuita su chi ha provato a colpirti»**; il contrattacco è critico.
- Esempio confermato: A=4, D=8 dà la reazione gratuita al difensore.
- Il raddoppio del danno riguarda **solo il bonus critico**, non il danno totale. Il critico interagisce con gli stadi di resistenza/Fragilità secondo il manuale.
- L'eccezione del critico da tiro doppio ha precedenza sulla fascia ordinaria del quasi riuscito.

Bonus critico ordinario ricevuto, in base al livello L del nemico:

| Difficoltà | Bonus ordinario | Bonus nel critico da tiro doppio |
|---|---|---|
| Facile | 3 × L | 6 × L |
| Medio/Normale | 2 × L | 4 × L |
| Difficile | L | 2 × L |
| Oculum | L diviso 2, per difetto | doppio del bonus ordinario già arrotondato |

Esempio: 51 danni base, nemico livello 10, Medio: bonus ordinario 20; tiro doppio → 51+40=91 prima di Difesa, resistenze e Scudi. Non 102.

### Online e offline

- Conferma del 18 ottobre 2026: il danno al partecipante selezionato, dopo il confronto dei tiri, passa per Difesa, Scudo Oculum, Scudo normale, HP temporanei e infine Vita. Il quasi riuscito mantiene la Difesa ×1,5 arrotondata per eccesso; un attacco evitato non consuma protezioni. Restano le eccezioni esplicite già definite per abilità, Resistenza, Scudo di Salvataggio e Pawn. Un duplicato della stessa risoluzione non applica di nuovo il danno.

- Online, in una turnistica, scegli il bersaglio e il tiro d'attacco. VC è il tiro ordinario; Schianto, Forza, Riflessi o altri tiri alternativi richiedono una descrizione e una motivazione al Master.
- Il log del bersaglio richiede una difesa con CM, Riflessi, Resistenza o Manifestazione del Potere, secondo la mossa. Non pubblicare statistiche nascoste per calcolare probabilità.
- Offline le abilità devono continuare a funzionare. Scelta del bersaglio, tiro difensivo ed esito possono essere manuali, senza autorizzazione del Master online.
- Gli effetti su un nemico non devono diminuire per errore le statistiche di chi li attiva.

## Conferme precedenti da conservare

- Vita massima: Resilienza × (10 + 5 × Grado). Le statistiche di base del mostro non devono essere conteggiate come punti guadagnati salendo di livello. Un Mostro guadagna 9 punti per livello aggiuntivi alla base.
- Costi: `5/5` è un esempio di costo fisso, non il costo universale. Un intervallo `1/5` ha senso quando l'investimento aumenta realmente danno, difesa, durata, statistiche o altro effetto dichiarato. Le passive non devono richiedere una spesa attiva fittizia.
- Le tecniche hanno un'identità concreta; evitare descrizioni generiche come «attacco tematico». Conservare identità, statistiche, drop e personalizzazioni dei mostri.
- Le pergamene possono essere apprese: devono avere costi e cooldown utilizzabili anche come skill apprese. Non clonare ogni tecnica in ogni elemento.
- Nei Libri Runici, le parole conosciute permettono di inventare skill. Le parole composte generano una Rune Art usabile; le skill si scrivono con il Master, concordando costi, DT, durata, bersagli ed effetti.
- Pawn protegge la Vita dopo gli Scudi del protetto. Si deve contare anche la Difesa del Pawn e scrivere chiaramente nel log chi prende danno e quanta Vita perde. Lo Scudo di Salvataggio blocca l'overflow del colpo che esaurisce l'ultimo Scudo, poi si disattiva.
- Luna e Sole sono nemici. La grafica dei temi è decorativa e coerente con l'elemento; non deve cambiare la disposizione dei tasti o coprire testi e zone cliccabili.

## Larva Bianca — conferma del 18 ottobre 2026

- La modalità fuga di **Scavata** usa il sottotratto **Velo** (`velo`). Questa indicazione riguarda la fuga; non cambia il tiro della modalità di attacco sotterraneo.
- Fonte: correzione esplicita dell'utente «il tiro per la fuga della larva deve essere su velo».

## Pergamene — aggiornamento del 18 ottobre 2026

- Usare una pergamena esegue la tecnica e consuma un esemplare; non assegna automaticamente una skill permanente. Il consumo avviene anche se il tiro fallisce.
- Apprendimento separato: resta necessario 20 naturale e totale almeno `30 + 10 × grado`. Solo allora si effettua un controllo percentuale: Facile 20%, Medio 15%, Difficile 10%, Oculum 5%.
- La scelta delle percentuali è delegata dall'utente. Il 20% precedente viene mantenuto in Facile e ridotto progressivamente nelle difficoltà maggiori. Un doppione non genera una seconda skill. La skill appresa mantiene costi e cooldown e non è evolvibile.
- Colori delle abilità nella barra combattimento: Oculum usa il colore Oculum personalizzato; Resilienza verde, Volontà rosso, Materia blu. Il colore dipende dalla risorsa, non dalla categoria Attacco/Difesa/Supporto.

## Dettagli da chiedere prima di introdurre nuove regole

### IA dei mostri — conferma del 18 ottobre 2026

- Il mostro agisce con l'IA quando il Master passa il suo turno senza avere compiuto azioni per quel mostro. Un'azione già effettuata manualmente impedisce un secondo intervento automatico a fine turno.
- Correzione più recente: **nessun debito sul prossimo turno**. Ogni creatura ha una Reazione, salvo Skill che ne concedano altre. Le Reazioni si ripristinano a ogni nuovo turno proprio senza accumularsi. L'IA può usare una Reazione ancora disponibile prima del ripristino, invece di sprecarla; non ne crea altre e non ne sottrae al turno seguente.
- Questa è una regola confermata; la sua presenza nel registro non certifica che il nuovo gestore IA sia già implementato.

- Eccezioni specifiche di una tecnica alla scelta del tiro difensivo.
- Effetti senza durata, multibersaglio e condizionali non descritti dal manuale: non assegnare valori o condizioni arbitrarie.
- Confronti di raddoppio con totali nulli/negativi: non introdurre premi infiniti o catene automatiche; chiedere la regola se il caso deve essere regolato diversamente.

## Come aggiornare il riferimento

Registra la nuova conferma con data, esempio e fonte. Aggiorna il manuale interno; riesporta il manuale consultabile; aggiungi test sui limiti della regola. Non cancellare una decisione precedente senza indicare quale nuova decisione la sostituisce.

## Conferma del 19 ottobre 2026: Maestria iniziale

Le soglie dipendono esclusivamente dai punti ottenuti tramite Maestria, non dai punti base, manuali o dai buff. Sottotratti: 100, 200, 350, 500, 700, 850; dopo sei punti guadagnati la soglia resta 1000. VC, CM e Aiuta compagno: 250, 500, 750; dal quarto punto 1000. Iniziativa: 200, 400, 600, 800; dal quinto punto 1000. L'avanzo si conserva. Le difficoltà mantengono i diversi guadagni EXP per tiro; non modificano queste soglie. I salvataggi precedenti non contengono il conteggio separato: si preservano valori e progresso, iniziando il nuovo contatore da zero senza attribuire aumenti retroattivi al caricamento.
