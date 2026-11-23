# Preparazione della grande espansione · 23 novembre 2026

## Prima candidata

- La build del 22 novembre contiene la tavola C del Senza Volto e la Potenza base al livello 0 sulle pagine acquistate del Monster Book Party.
- La candidata successiva aggiunge la memoria del colpo finale e il ridimensionamento dei nodi nella Mappa degli Occhi. La scheda EXP descrive ora l'Allenamento non letale e i bonus confermati. La protezione non letale segue la stanza del bersaglio.
- In questa espansione il registro del giocatore resta cumulativo dalla build `b917217d98d16861a5bbaf1706d78825d883c970`, run `40242640717`. Il registro offline è una copia del [registro cumulativo](REGISTRO_AGGIORNAMENTI.md). Dalla patch successiva partirà il registro per versione, con accesso anche alle versioni intermedie saltate.

## Illustrazioni e Bestiario

| Voce | Ultima scelta | Passaggio ancora aperto |
| --- | --- | --- |
| Rupnyr · gole di scisto | B «Graffi e pennello più ruvido» | Definire la scheda di gioco. È una delle 20 nuove specie. |
| Angryss · portali corallini | B | Definire la scheda di gioco. È una delle 20 nuove specie. |
| Rasvyr · Deserto Divoratore | G «La chela verso di te» | Definire la scheda, conservando le sei appendici: due chele e quattro zampe. |
| Orbryx · Orea Zalira | G «Il piede verso di te» | Definire la scheda con tre occhi e tre zampe. Usare per i lavori futuri l'ambiente rosa e lilla con due soli senza occhi. |
| Scostubanditi Empatico | Nome protetto | Completare la versione in inchiostro della forma ordinaria. Il GranScostumato Empatico ha già la tavola D approvata. |

Le quattro tavole B, B, G e G corrispondono alle impronte delle rispettive ricevute. I 10 temi nel registro di preparazione hanno brief A–F e riferimenti verificati. Il piano delle 20 specie prevede sei varianti aggiuntive per ciascuna, per un totale di 140 forme e 1.120 tavole. Il registro di quel lotto documenta 16 tavole base prodotte per due forme e tre revisioni extra. Restano da illustrare le altre 138 forme. Le tavole di Rasvyr e Orbryx sono nel lotto separato per le aree con meno mostri.

Fonti: [registro delle regole](OCULUM_REGOLE_CONFERMATE.md), [canone visivo](OCULUM_LORE_VISIVA.md), [registro delle attività iniziate](../output/artwork/ATTIVITA-INIZIATE-NON-COMPLETE-20261118.json), [coda dei temi](../output/artwork/PREPARAZIONE-PROSSIMI-10-LOTTI.json), [roster delle 20 specie](../output/artwork/nuove_specie_comuni_20261118/ROSTER-PROPOSTO.json), [roster delle aree meno popolate](../output/artwork/nuovi_mostri_aree_povere_20261118/ROSTER-E-CANONE.json).

## Prima della pubblicazione

1. Chiudere l'integrazione delle tavole e dei nomi che entrano nell'espansione. Per ciascuna creatura confrontare parte mirabile, forma ed elemento con la scheda.
2. Provare la candidata su copie dei salvataggi, compresi un Fight con più nemici, l'Allenamento, i Drop e la riapertura di una campagna. Verificare i flussi online su sessioni distinte e la leggibilità a 1920×1080 e 1080×1920.
3. Compilare il commit selezionato con GitHub Actions, firmare l'APK Release con l'identità già distribuita e verificare Windows normale e Windows Test come download separati. Verificare versione web, menu download, associazione al commit e scaricabilità senza login.
