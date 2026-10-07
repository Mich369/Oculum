# Titoli visibili, statistiche e critici

## Cosa puoi modificare nell'app

- Nei Titoli e nei Tratti razziali: nome, leggenda, equipaggiamento, stato Evoluto/Open e interruttore Titolo sempre visibile. Solo un titolo è visibile: scegliere un altro disattiva il precedente. Se esiste un titolo evoluto equipaggiato, la selezione dei non evoluti è bloccata.
- Nome e titolo vengono mostrati come `Rose | Tutto pur di Salvarla`, nelle schede locali, nella turnistica e nelle schede online. Il nome originale rimane modificabile separatamente.
- Grado della scheda: il bonus visibile vale 6 punti totali a grado 0 e aumenta di 6 a ogni grado. Viene ripartito uniformemente fra RES, VOL, MAT e OCU; i resti vanno nell'ordine indicato. A grado 0: +2/+2/+1/+1. A grado I: +3/+3/+3/+3.
- I punti statistica assegnati con livelli, gradi, titoli e skill aumentano anche le risorse attuali della quantità esatta. Il bonus strutturale Oculum non è più trattato come una cura, quindi non viene dimezzato da Oculum addormentato né consuma prima la riserva temporanea quando viene rimosso. Le restrizioni sull'utilizzo di Oculum addormentato restano attive fino al risveglio.
- Alla prima selezione visibile di ciascun titolo evoluto: +9 punti temporaneamente legati a quel titolo (+3 RES, +2 VOL, +2 MAT, +2 OCU). Cambiare titolo o rimuoverlo disattiva questi nove punti; riselezionarlo non li assegna nuovamente. L'informazione è conservata nei salvataggi.
- Senza una scelta valida: titolo evoluto unico, oppure uno fra quelli evoluti con preferenza per i tratti razziali. La scelta casuale resta stabile fra le ricostruzioni della schermata. Senza evoluti: tratto razziale primario equipaggiato; se assente, primo titolo equipaggiato disponibile.
- Il precedente incremento pubblico ×1,3 dei bonus propri del titolo resta applicato solo a quei bonus; i nuovi punti visibili non sono moltiplicati.
- Pulsante Critico nel pannello Danno/Cura: scegli difficoltà e livello del nemico. Il bonus è +3 per livello in Facile, +2 in Normale/Medio, +1 in Difficile e +1 ogni due livelli in Oculum (arrotondato per difetto). Livello 0 dà bonus 0. Il log riporta il profilo e il bonus applicato.
- La finestra dei critici e il menu della difficoltà seguono il tema Oculum selezionato: stesso font, colori, sfondo, bordi e pulsanti della scheda.
- Pulsante Ripristina tutto · Stats e HP: ripristina RES, VOL, MAT, OCU e HP ai massimali. Il precedente ripristino della Vita continua a ricaricare HP temporanei dinamici e Scudo Oculum secondo le regole già presenti. Lo scudo ordinario consumato segue le sue regole proprie.
- Cenere: il log mostra valore precedente/nuovo, soglia senza penalità, malus precedente/nuovo e turno di decorrenza. Il malus ai tiri non consuma le statistiche attuali. Vista appannata da Cenere decorre subito nel turno di ricezione e dura fino alla fine di quel turno.
- Ritratti PNG nella scheda: il contenitore non impone più uno sfondo nero e l'anteprima di ritaglio segue il tema. La trasparenza del PNG rimane conservata. Il controllo «Mantieni l'occhio dietro il ritratto» permette di mostrare il disegno dell'occhio attraverso le zone trasparenti.

## Distribuzione

La pagina Web `https://mich369.github.io/Oculum/` viene ricostruita e pubblicata automaticamente a ogni push su `main`, con la stessa configurazione Supabase delle app. I salvataggi locali del browser restano nel suo archivio IndexedDB; l'online usa il progetto Supabase esistente. La schermata di caricamento segue lo stile Oculum e permette di riprovare se il caricamento fallisce.

`build/distribution` contiene esclusivamente artefatti GitHub del commit indicato in `BUILD-VERIFICATE.json`, i runtime Windows completi nelle cartelle `windows` e `windows-test`, e questo riepilogo. La versione Windows Test usa il profilo salvataggi isolato `test`. Nessun APK Test.
