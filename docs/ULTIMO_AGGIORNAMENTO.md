# Aggiornamento cumulativo dal 25–26 ottobre 2026

Tutte le modifiche successive alla build `b917217d98d16861a5bbaf1706d78825d883c970` (run `40242640717`), incluse quelle di `12cbe566` e `73cce878`.

- 37 specie e 77 tecniche dopo la build di riferimento; 231 equipaggiamenti derivati (77 armi, 77 armature, 77 scudi), 693 forme delle skill sugli oggetti. Monster Book 1.157 voci, ordinate per Potenza crescente nella vista Master. Fasi, luoghi, anatomie, drop, scroll e Open; regole Slime Roccioso, Nuvola, Golem, Fuga e Role aggiornate.
- Scudo del provocatore I/II/III con attrazione, riserva separata e riflesso; tecniche speciali in Attacco senza doppio consumo della risorsa, compatibilità Morso Lunare salvato; risoluzione online di attacchi, difese e aiuti, ordinamento turni e conservazione delle schede.
- Aura +20: Potenza nota accanto ai nomi e nella turnistica, confronti e valori scoperti aggiornati automaticamente; letture facilitate sotto 100 e probabilità sottotratto% di osservazione gratuita (max95%). Mercanti: offerte adatte anche alla Potenza totale; rilevatori alchemici e Postea con cariche persistenti, portata e letture stimate.
- Scarica totale e Impeto totale: +Potenza totale ai Danni di un singolo colpo; +max(2,10−Adattamento) al prossimo tiro per colpire e al primo tiro nemico contro di te. Sfinimento azzera e blocca tutte le Reazioni per 1d3 + Potenza/160 per difetto turni personali.
- Connessioni nuove con codice stanza esplicito e nuovo codice per il Master; eliminato il collegamento implicito alla stanza test. Restano approvazione del Master, privacy e codici già salvati.
- 61 temi elemento, 162 scene e Impostazioni riordinate con ricerca; trasparenza separata per statistiche e comandi, personalizzazioni e JSON conservati.
- Log completo soltanto al primo avvio di ogni nuova versione, chiudibile con clic fuori dalla finestra. Avvio web e build Windows più robusti, menu download pubblico aggiornato dal commit compilato. Windows normale e Windows Test separati anche negli artifact delle cartelle.
- Nomi, costi, cooldown, formule, effetti, bersagli, oggetti, mercanti, temi e impostazioni restano modificabili negli editor esistenti. Verifiche e pacchetti effettivamente consegnati sono indicati separatamente nel resoconto.

## Consegna online con tag salvati

Corretto il confronto tra il tag autenticato restituito in maiuscolo dal server e i tag salvati con maiuscole/minuscole: attacchi, difese, aiuti, risposte Aura e conferme di consegna mantengono la stessa identità. Anche i frammenti delle schede confrontano l’identità senza cambiare il tag salvato. Ruoli, sessioni, proprietari, approvazione del Master e controlli contro mittenti falsificati restano verificati. La prova con quattro profili e il test Supabase autenticato includono ora tag con maiuscole/minuscole.

Le schede ricevute mantengono il tag originale anche oltre il terzo posto nell’archivio del Master. L’installazione locale riutilizza gli artifact di cartella verificati per evitare copie temporanee dei runtime, preservando la distribuzione precedente fino alla verifica finale.
