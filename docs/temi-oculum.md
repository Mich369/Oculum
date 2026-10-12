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

## Skill con effetti che usano dadi

- Nel valore dell'effetto puoi scrivere `1d6+@Danni`, `2*(1d6+1d4)` oppure `1d6+OculumSpeso*2`. Puoi continuare a usare il campo Dadi separato.
- Un effetto composto soltanto dal campo Dadi può essere salvato senza aggiungere un valore manuale: la base viene impostata a zero.
- Anche la durata accetta formule come `1d4+2`. Il campo Dadi può continuare ad aumentare la durata invece del valore.
- I dadi vengono tirati all'attivazione. Valore e durata risolti sono conservati per i turni successivi: i tick non effettuano altri tiri. I risultati sono riportati nei log degli effetti.
- I gruppi di dadi mantengono i limiti esistenti: da 1 a 20 dadi, da 2 a 1000 facce per dado.
- Conferma della skill ed editor degli effetti mantengono i controller dei campi di testo fino alla fine della chiusura del dialogo, evitando l'errore di utilizzo di un controller già liberato.

Esempio: un bonus a Riflessi con valore `1d6` e durata `1d4+2`, se ottiene 4 e 2, applica +4 Riflessi per 4 turni. Al turno seguente resta +4 e la durata scende a 3: non vengono ritirati i dadi.
