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

Il comando Vista Web nella barra superiore permette di scegliere Automatica, Desktop o Mobile. La scelta viene conservata nel browser. Automatica mostra la pagina mobile in verticale (anche 9:16 e iPad) e la pagina desktop in orizzontale; ruotando lo schermo cambia la vista senza cambiare scheda o salvataggio. Desktop resta selezionabile su un telefono e Mobile su un computer. Le aree sicure e la tastiera vengono adattate alla scala della pagina.

## Nuovi mostri deboli

Creature originali ispirate alle atmosfere di Isaac, Darkest Dungeon e Fear & Hunger, disponibili nel Monster Book e nel selettore per creare una scheda. Tutte sono livello 0, grado 0 e senza varianti potenziate automatiche. I quattro valori sono RES/VOL/MAT/OCU.

| Mostro | Stats | Totale | Attacco / Difesa | Drop (60% / 35%) |
| --- | --- | --- | --- | --- |
| Lacrimante | 2/1/2/1 | 6 | Lacrima nera / Palpebra serrata | Nebrin / Pelle di mostro |
| Ciste Errante | 3/1/2/1 | 7 | Urto molle / Cartilagine raccolta | Pelle di mostro / Ambril |
| Moscerino degli Occhi | 1/1/3/1 | 6 | Puntura della pupilla / Ali sovrapposte | Nacrel / Thornil |
| Sagrestano Cavo | 2/2/3/1 | 8 | Campana scheggiata / Maniche annodate | Feralis / Tessarin |
| Portalanterna Spento | 2/3/2/2 | 9 | Ultima brace / Sportello di ferro | Cendril / Feralis |
| Mastino della Cripta | 3/1/4/1 | 9 | Morso della soglia / Costole raccolte | Pelle di mostro / Osserin |
| Affamato delle Fosse | 3/2/4/1 | 10 | Unghie del digiuno / Braccia sul ventre | Pelle di mostro / Thornil |
| Cucitore di Stracci | 2/2/3/1 | 8 | Ago storto / Toppa ripiegata | Tessarin / Feralis |
| Larva del Pozzo | 2/1/2/2 | 7 | Getto del fondo / Maschera ossea | Tessarin / Virdel |

Ogni creatura ha due tecniche con effetti numerici: attacco Danni +1/+2/+3 dopo un tiro riuscito contro un solo bersaglio; difesa personale +1/+2/+3 per un turno. Le forme I/II/III richiedono livello 0/3/6, costano esattamente 1/2/3 Oculum e hanno CD 3 turni. Non infliggono mutilazioni, svenimenti, paralisi o perdite permanenti. I drop sono materiali di grado 0 già presenti nel catalogo. Nel Book puoi modificare nomi, descrizioni, statistiche, skill e drop delle tue voci personalizzate.

## Capibranco e Occhi dei Caduti

- Sei Mini Boss originali di livello 0: Papera Ranocchio Colossale, Goblin Caposcavo, Matriarca delle Arpie, Patriarca del Fango Verde, Mastino Capocripta e Affamato Capofossa. Ogni statistica base vale tre volte quella della specie +2; conservano skill e drop della specie. Non ricevono varianti automatiche.
- A Vita positiva pari o inferiore al 50% si attiva una sola fase: Ricordo vitale (cura del 75% della Vita massima entro il massimo e condizione per 9 turni personali), 200% (bonus pari alle statistiche, per 3 turni personali) e Scudo del 10% della Vita massima precedente alla fase, arrotondato per eccesso. La fase è salvata e registrata nei log; non si ripete dopo una cura, un cambio scheda o un riavvio. Nessuna resurrezione automatica. Il Riposo Lungo ricarica la fase.
- La stessa regola funziona nella scheda attiva e nei danni rapidi del Master. Le statistiche aggiuntive sono effetti temporanei: le statistiche base rimangono conservate. Se 200% o Ricordo vitale sono già attivi, non viene assegnata una seconda copia del medesimo potenziamento o della cura.
- Quando un mostro del Book diventa Occhio dei Caduti, conserva l'identificativo della specie e la sua Art innata completa, con gli stessi effetti, costi e cooldown, anche se comune. I limiti di rarità sulle altre Art restano quelli esistenti. Un capobranco conserva anche la fase a metà Vita: copiare un Occhio vivo non ricarica una fase già usata; ottenere l'Occhio da una creatura morta crea un corpo con la fase disponibile.

`build/distribution` contiene esclusivamente artefatti GitHub del commit indicato in `BUILD-VERIFICATE.json`, i runtime Windows completi nelle cartelle `windows` e `windows-test`, e questo riepilogo. La versione Windows Test usa il profilo salvataggi isolato `test`. Nessun APK Test.
