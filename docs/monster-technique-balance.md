# Tecniche dei mostri: revisione del 15 ottobre 2026

## Ambito

Il catalogo delle tecniche concrete alimenta sia la descrizione nel Monster Book sia gli effetti strutturati importati nella scheda. Le tecniche con regole specifiche già scritte, fra cui lo Slime Roccioso, mantengono le proprie formule. Non vengono cambiate le statistiche base, gli ID e i drop con questa revisione del bilanciamento.

## Recupero delle tecniche concrete

| Funzione | Forma I | Forma II | Forma III |
| --- | --- | --- | --- |
| Cura | 3 turni | 4 turni | 5 turni |
| Costrutto | 3 turni | 4 turni | 5 turni |
| Scudo | 2 turni | 3 turni | 4 turni |
| Movimento o richiamo | 2 turni | 2 turni | 3 turni |
| Bonus a un attacco | 1 turno | 1 turno | 2 turni |

I timer usano il sistema di cooldown delle Art. Sono inizialmente pronti. Il costo viene pagato ad ogni attivazione; l'investimento di Oculum resta variabile quando influenza l'effetto.

## Modifiche ai bonus generati

- I richiami aumentano VC; la scelta tra VC e CM non dipende più dall'hash dell'ID.
- I normali bonus al prossimo attacco sono Oculum immesso, Oculum immesso +3, Oculum immesso +6. Restano esclusi gli attacchi che hanno già formule proprie.
- È eliminato il punto VC aggiuntivo assegnato casualmente ad alcuni attacchi di forma III in base all'ID.
- Costi minimi e massimi della scheda vengono letti dalla stessa definizione che genera la descrizione, evitando divergenze.
- I sei demoni restano distinti: minore/intermedio/maggiore e fuoco/ghiaccio.

## Esempio

Un bonus generato al prossimo attacco, forma II con 7 Oculum immessi, aggiunge 10 Danni una sola volta e ha CD 1. Una cura generata di forma II con 7 Oculum recupera 11 Vita, senza superare il massimo, e ha CD 4. Le formule e i recuperi dedicati delle mosse specifiche prevalgono sempre su questi valori generali.

## Cosa si può personalizzare

## Skill naturali e Art

Le nuove schede ricevono le capacità senza Oculum nella sezione Skill. Questo vale anche per le capacità naturali di una creatura che possiede altre mosse nell'Art. Le mosse naturali hanno tre forme, costo fisso in Volontà e gli stessi effetti strutturati dell'importazione; la componente prima dipendente dall'Oculum immesso usa invece Materia. Le passive non consumano risorse. Le capacità Pawn mantengono il proprio pannello automatico.

La separazione viene applicata alla creazione dal catalogo, alla creazione guidata e alle nuove creature per gli Occhi dei Caduti. Nessuna capacità viene rimossa: ogni tecnica ha una sola destinazione tra Skill e Art.

Alcuni kit hanno anche differenze tattiche esplicite: apertura sporca del Goblin (precisione in cambio di CM), carica dell'Orco (danni percentuali con esposizione), contrattacco (reazione e danni ridotti), copertura del Kobold (CM e Difesa), picchiata (danni e precisione con esposizione), ricomposizione (cura con guardia ridotta). Il resto del catalogo usa ancora famiglie di effetti condivise; la revisione di ogni kit non è da considerare conclusa con questa prima versione.

Nell'editor delle Art restano modificabili nome, descrizioni delle forme, costi, cooldown ed effetti strutturati. Nel codice le definizioni condivise sono in `concrete_monster_techniques.dart`; il collegamento alle schede è in `oculum_starter_creation.dart`.

Questa revisione riguarda le nuove importazioni dal catalogo: non riscrive le Art già salvate e personalizzate nelle schede esistenti.

## Limiti delle verifiche

I test automatici confrontano catalogo e schede, costi, effetti, passivi e timer. Non sostituiscono un playtest completo del bilanciamento in campagne reali, né dimostrano la sincronizzazione online fra due dispositivi.
