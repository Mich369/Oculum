# Catalogo, pergamene, resistenze e tiri

## Dove trovarli

- Master → Catalogo completo del Master.
- Inventario e crafting → Catalogo completo del Master (aperto per il Master).
- Resistenze → Cerca elemento; la ricerca include elementi personalizzati salvati.
- Il pulsante dadi apre i tiri nella schermata attuale. L'animazione di ogni tiro appare sopra la schermata, il dettaglio o il dialogo attuale.

## Pergamene

Il catalogo contiene dardi, vincoli e egide per ogni elemento, dal grado 0 al XII.
Un Drop con totale almeno 18 dà sempre una pergamena: 18–27 grado 0,
28–37 grado I, e un grado in più ogni 10, fino al XII. L'elemento e la famiglia sono casuali.

Usare una pergamena richiede conferma e consuma una sola copia, anche quando il tiro fallisce.
Annullare non consuma nulla. La skill usa Volontà, i suoi bonus al tiro,
il modificatore globale, l'Oculum preparato e la difficoltà esistenti.
Un 1 naturale fallisce. I risultati e il testo completo della skill sono inviati al Master online attraverso il normale canale dei tiri.
Il Master conferma i bersagli, i danni ricevuti, il rallentamento e Gelo;
gli effetti sui nemici non vengono applicati al personaggio che usa la pergamena.

Gli effetti sul proprio personaggio sono temporanei e salvati: l'egida dà Difesa,
il vincolo dà vantaggio ai tiri. Riutilizzare la stessa famiglia dello stesso elemento
sostituisce il buff precedente, anche se di grado diverso.
La durata scade con i propri turni; non modifica le statistiche base.

Con 20 naturale e totale almeno `30 + 10 × grado`, un d100 da 1 a 20 permette
di apprendere la skill. Quindi grado I richiede totale 40.
La skill appresa resta nelle Skill, non richiede altre pergamene, non può evolvere,
e la stessa skill dello stesso grado non viene duplicata.

## Valori modificabili

Nelle normali schede restano modificabili oggetti, quantità, nome, note, peso,
elemento, gradi, bonus e proprietà già esposti dagli editor. Il Master sceglie
destinazione locale/online e quantità dal catalogo. Le resistenze per elemento
mantengono preset e percentuale personalizzata anche durante la ricerca.

Le regole delle nuove pergamene sono centralizzate in `lib/src/main/oculum_scrolls.dart`:

| Parametro | Valore attuale |
| --- | --- |
| Primo Drop utile | 18 sul totale |
| Incremento di grado | ogni 10 sul totale |
| Grado massimo | XII, oltre al grado base 0 |
| Valore nominale | 300 × (grado + 1)² Obser |
| Rivendita al mercante | un sesto del valore per copia |
| Dado del dardo | d(8 + 6 × grado) + propri danni |
| Bonus critico contro lo scudo | +20% × grado |
| Bersagli del vincolo | 1 + grado |
| Danni del vincolo | 50% × grado dei propri danni; nessuno al grado 0 |
| Vantaggio del vincolo | +2 + grado ai tiri |
| Difesa dell'egida | +3 + 3 × grado |
| Durata dei buff | 2 + grado dei propri turni |
| Soglia per apprendere | 20 naturale e totale ≥ 30 + 10 × grado |
| Probabilità di apprendere | 20% |

Nomi, descrizioni e parametri delle pergamene sono conservati in `craftData.scroll`.
Le Skill apprese conservano `scrollData`, aggiunto senza cambiare i campi dei vecchi salvataggi.
Le verifiche automatiche coprono soglie, copertura elementi/gradi, compatibilità JSON,
consumo, annullamento, scadenza dei buff e stabilità delle statistiche durante la ricerca.
Non costituiscono una verifica su due dispositivi collegati.

## Pawn

Pawn è acquistabile dal Master nel Catalogo completo per 100 Obser. Parte al livello 0
con 3 Resilienza, 3 Volontà, 5 Materia, 0 Oculum e 30 HP. Si possono selezionare una o più
schede locali o online da proteggere. Il danno viene deviato dopo che il bersaglio ha
consumato i propri scudi, Scudo Oculum, Scudo di Salvataggio e HP temporanei: Pawn interviene
solo sulla quota che altrimenti raggiungerebbe gli HP. I danni diretti da condizioni sono
anch'essi deviati, ma conservano le regole proprie della condizione.

Alla fine di ogni turno Pawn recupera 10 HP fino al massimo di 30; se era già al massimo,
ottiene 5 Scudo. Raggiunti 20 Scudo ottiene uno Scudo di Salvataggio, che si consuma quando
il suo Scudo viene esaurito da un colpo e annulla l'eccedenza di quel colpo. Un turno già
conteggiato non può essere ripetuto; Pawn a 0 HP è inattivo. I dati e i bersagli sono salvati
nella campagna e le richieste online hanno un ID stabile per i tentativi ripetuti.

I valori regolabili di Pawn sono centralizzati in `lib/src/main/oculum_pawn.dart`:

| Parametro | Valore |
| --- | --- |
| Prezzo | 100 Obser |
| Livello iniziale | 0 |
| Resilienza / Volontà / Materia / Oculum | 3 / 3 / 5 / 0 |
| HP iniziali e massimi | 30 |
| Cura per turno | 10 HP |
| Scudo per turno a vita piena | 5 |
| Soglia Scudo di Salvataggio | 20 Scudo |

### Progressione di Pawn

Ogni turno completato concede 25 EXP a Pawn. Ogni livello richiede metà dell'EXP
standard della difficoltà attiva: 500 in Normale (anziché 1000) e 685 in Oculum
(anziché 1369). Ogni livello concede 9 punti statistica, come un Mostro standard;
quindi Pawn raggiunge la stessa crescita statistica con metà EXP. I punti si
assegnano a Resilienza, Volontà, Materia o Oculum. Ogni punto Resilienza aumenta
gli HP massimi di 10 e cura altrettanti HP al momento dell'assegnazione. Livello,
EXP, statistiche e punti non assegnati sono salvati nella campagna.
