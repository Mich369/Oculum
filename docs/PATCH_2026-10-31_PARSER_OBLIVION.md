# Patch del 31 ottobre — parser, Senka e Oblivion Shield

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

La prima suite completa ha terminato con1916test passati,6saltati e1fallito: la fixture delle percentuali lasciava riattivare la Resistenza passiva casuale. Isolata la fixture senza cambiare la regola;85riprove passate. Successivamente40prove su Lupo/anatomie/catalogo e41su attivazione reale/parser/Senka passate; i gruppi si sovrappongono e non si sommano. Una prova nuova ha individuato il filtro Vita prematuro sull'effetto ostile: corretta la preparazione prima del colpo.

Analisi completa pulita prima dell'ultima correzione glaciale e del controllo d'attivazione; ripetizione finale richiesta. Dodici prove Python dei download pubblici passate usando una cartella temporanea nel progetto; il primo tentativo era bloccato dai permessi della cartella temporanea sandbox.

Suite finale, CI GitHub, prove autenticate, pacchetti installati, download pubblici e UI su dispositivi separati restano verifiche distinte. Questa nota non certifica automaticamente i passi successivi né chiude righe al100%.
