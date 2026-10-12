# Temi Oculum: funzionamento e opzioni

## Correzioni

- Il tema della scheda viene applicato anche al navigatore: le nuove finestre, i menu e i pannelli inferiori usano la palette e il font attivi.
- Campi di testo, cursore, selezione, pulsanti, icone, tooltip, messaggi, card, chip e separatori ricevono i colori della palette. Le dimensioni compatte dei pulsanti restano quelle dell'app.
- I menu principali non impongono più lo sfondo del tema classico.
- Il contrasto tiene conto della trasparenza effettiva del testo. Se un colore non è leggibile, viene corretta la luminosità mantenendo la tonalità, quando possibile; il colore corretto diventa opaco per garantire il contrasto.
- Il cambio di palette o font aggiorna il tema generale al frame successivo senza riaprire la scheda. Non cambia statistiche, skill, regole o salvataggi.

## Cosa puoi modificare

In Impostazioni puoi scegliere il tema completo, applicare solo la palette, scegliere una GUI separata, scegliere o disattivare le decorazioni e cambiare il carattere dell'app. Restano disponibili i colori personalizzati e le impostazioni di intensità, opacità e luminosità delle decorazioni.

Esempio: applicando Vetro strega, una nuova finestra usa la superficie verde scura e i colori della stessa palette. Cambiando solo il font, anche il testo delle nuove finestre usa il carattere scelto. I colori degli elementi e dell'Oculum restano le impostazioni specifiche della scheda.

## Verifiche automatiche

`test/oculum_all_themes_test.dart` attraversa tutte le palette disponibili nella scheda a 1440×900 e 390×844, verifica la propagazione al navigatore, apre e chiude finestre, menu e pannelli inferiori, controlla il contrasto del testo e dei pulsanti e verifica anche una palette personalizzata chiara e il caso del testo trasparente.

Questi controlli non sostituiscono una prova manuale su tutti i dispositivi o una verifica online fra due persone.

## Revisione goth della nuova visuale

I pannelli della nuova scheda seguono la palette scelta: superfici, colori del testo, accenti e selezioni non restano fissati alla vecchia combinazione scura.
Anche le cornici cambiano insieme al tema. La cornice originale resta disponibile nei temi senza decorazioni.

Le decorazioni seguono l’identità del tema:

- Botanici e Vervain: liane curve, foglie con nervature, fiori a cinque petali e petali cadenti nelle tonalità del tema, viola per Vervain.
- Ghiaccio e tempesta: cristalli sfaccettati.
- Metallo, Kingi, Postea e fortezze: incisioni, rivetti e montanti metallici.
- Luna, sigilli e astrale: stelle, costellazioni e segni luminosi.
- Mare: onde, riccioli e perle.
- Brace: candele rituali e scintille.
- Altri temi goth: archi a sesto acuto e rosoni.

I dettagli sono confinati ai margini, non ricevono clic e non alterano il contenuto o le dimensioni dei controlli.
Le parti statiche sono separate dalle particelle animate, così l’animazione non ricostruisce la scheda.
Le animazioni richiedono la grafica attiva; modalità leggera, modalità veloce e riduzione delle animazioni le fermano. Le decorazioni restano disponibili anche statiche.
Opacità e intensità usano le impostazioni delle decorazioni già presenti.

Le catture desktop e telefono sono incluse nell’artefatto GitHub `Oculum-UI-Catture`, nella cartella `temi-goth`.

## Dadi degli effetti

- Nel valore dell'effetto puoi scrivere `1d6+@Danni`, `2*(1d6+1d4)` oppure `1d6+OculumSpeso*2`. Puoi continuare a usare il campo Dadi separato.
- Un effetto composto soltanto dal campo Dadi può essere salvato senza aggiungere un valore manuale: la base viene impostata a zero.
- Anche la durata accetta formule come `1d4+2`. Il campo Dadi può continuare ad aumentare la durata invece del valore.
- I dadi vengono tirati all'attivazione. Valore e durata risolti sono conservati per i turni successivi: i tick non effettuano altri tiri. I risultati sono riportati nei log degli effetti.
- I gruppi di dadi mantengono i limiti esistenti: da 1 a 20 dadi, da 2 a 1000 facce per dado.
- Conferma della skill ed editor degli effetti mantengono i controller dei campi di testo fino alla fine della chiusura del dialogo, evitando l'errore di utilizzo di un controller già liberato.

Esempio: un bonus a Riflessi con valore `1d6` e durata `1d4+2`, se ottiene 4 e 2, applica +4 Riflessi per 4 turni. Al turno seguente resta +4 e la durata scende a 3: non vengono ritirati i dadi.

## HUD dark: seconda revisione estetica

- Pannelli con sfumature discrete, bordi meno invadenti e sigilli agli angoli; il centro resta libero.
- Le liane esterne hanno foglie più distanziate e lati asimmetrici. Le cornici dei pannelli non ripetono l'intera liana.
- Le quattro statistiche hanno icone coerenti con il significato: cuore, fiamma, scudo e occhio. Il colore segue la statistica e la palette attiva.
- Vita e Oculum hanno indicatori incorniciati con valori invariati; Vita mantiene la sovrapposizione degli scudi.
- Pulsanti, menu e conferme condividono cornici e stati di pressione, focus e hover.
- Nessuna modifica a costi, statistiche, danni, salvataggi o durata delle abilità.

Restano modificabili tema, colori della palette, colore Oculum, intensità delle decorazioni e modalità grafica. Gli accenti di combattimento distinguono le azioni senza sostituire testo e icone.
