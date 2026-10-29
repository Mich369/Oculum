# Prossima patch: sonno, bisogni, coda e artwork — verifiche

Base precedente distribuita e approvata: dcb5bb4e. Questo rapporto riguarda le modifiche successive e distingue le prove locali da CI, pacchetti e trasporto autenticato. Nessuna riga del registro viene chiusa al100%senza conferma dell'utente.

## Stato locale prima della compilazione pubblica

Ultima suite completa: **1.830 passati, 2 falliti, 6 saltati**, in 27 minuti 56 secondi (`build/next-patch-final-full-v2.log`). I due errori erano nella cattura PNG bloccata da Windows e nella fixture del nucleo con mitigazione casuale ancora attiva. Dopo le correzioni dei soli test, **12/12 prove dei due file sono passate** (`build/next-patch-final-two-retest.log`). Non sono presentati come una singola suite locale verde; la CI ripeterà integralmente il commit. Analisi del codice app senza problemi, 332,8 secondi (`build/next-patch-final-analyze-v2.log`).

- Prima suite completa:1818passati,6falliti,6saltati in46minuti1secondo (`build/next-patch-full-suite.log`). Non è una suite verde.
- Analisi finale dopo le correzioni: nessun problema,196secondi (`build/next-patch-release-analyze.log`).
- Ultimo gruppo mirato:67/67passati (`build/next-patch-regression-retest2.log`), comprende calendario, sabbia, riferimenti catalogo e39casi sonno/bisogni. Gli altri casi della prima ripetizione sono riportati nel log intermedio, non sommati come prove uniche.
- Copie dei33PNGapprovati: identiche perSHA. Renderer/Book/trasparenza:62casi nella suite completa, nessun fallimento in quel file; i controlli sono widget automatici, non una nuova sessione grafica indipendente.
- Tre prove autenticate di Auth, isolamento cloud e consegna/ripresa passate. Anche la quarta prova combattimento/riposo è passata in2minuti6secondi (`build/next-patch-authenticated-rest-final2.log`): quattro identità, richiesta senza cura, Master89rifiutato/90confermato, consegna anche su HTTPS, ricaricamento JSON e replay senza altra cura/tempo. Non sono quattro dispositivi fisici. Nessuna nuova migrazione database.

## Problemi isolati e correzioni

1. Il mantello senza tiro forzava l'esito riuscito ma ricalcolava ancora la difesa contrapposta: Danni annullati sotto Resistenza. Ora bypassa quel confronto come la coda e conserva tutti gli strati successivi. Due regressioni Azione/Reazione passate, con pagamento una volta e replay senza doppio danno.
2. Mappe Dart ristrette nei runtime di clone/Ki non accettavano i nuovi registri dei bisogni. Normalizzate una volta al confine di caricamento, preservando le chiavi personalizzate; le due fixture strette sono rimaste tali e ora passano.
3. Il calendario migrato bloccava la modifica nel runtime ma lasciava attivi i controlli del player. Campo, selettori e pulsanti rispettano l'autorità Master; i nomi lunghi non escono dal menu. Il test riproduce il tentativo di cambiare fase e poi il cambio autorizzato a190.
4. Il test del nucleo lunare subiva un risveglio casuale separato con cura dopo il danno: la fixture ora marca il risveglio già tentato e conserva le aspettative corpo60/nucleo20/ricevuta30. Nessuna modifica alla proporzione di danno o al Risveglio di gioco.
5. Il test del mercante usa la nuova etichetta Dormire e quello delle Skill di sabbia considera le due mosse coda aggiunte. Non sono stati rimossi costi, cooldown o asserzioni di idempotenza.
6. I default automatici Costrutto venivano salvati come esenzioni permanenti. Ora sono separati dalla configurazione esplicita; il cambio di corpo ricalcola i soli default e non addebita fame retroattiva per il tempo esente. Tre nuove regressioni modello/JSON/scheda passate.
7. Il test autenticato ha rilevato un errore reale di protocollo: il backend vieta initiative_control ai giocatori. Riposi, viaggi e visite del player ora usano permission_request con azione world_clock; clock e grant restano sul canale staff.56prove locali sul protocollo passate, più la prova autenticata completa. Le richieste non possono veicolare snapshot/grant.
8. I massimi naturali delle risorse compensano solo i modificatori temporanei previsti: bisogni e bonus notturni non alterano il limite permanente. Le eccezioni preesistenti del plasma restano.
9. Due nuove regressioni hanno riprodotto un aggiramento dello Sfinimento tramite la coda gratuita, sia sul Mostro sia sul Gigante di sabbia. La disponibilità della coda ora rispetta il blocco delle Skill da Sfinimento, anche se la parata era già preparata; gratuità e recupero condiviso restano invariati. Riproduzione precedente: due fallimenti; dopo la correzione, 23/23 prove coda e PT passate (`build/next-patch-tail-exhaustion-fixed2.log`). La fixture isola anche lo Stato di Forza casuale al quarto di Vita, senza modificare quella meccanica.

## Contenuti ancora da valutare

La galleria locale contiene proposte A/B/C e storico. Le cinque scelte desktop e i dieci derivati sono canonici; gli altri disegni restano proposte. Il nuovo export ha1200voci,43desktop,22telefoni e23reliquie mappati:21setcompleti,1179voci con almeno un asset mancante. Non equivale ad aver completato tutto il catalogo.

La revisione di Nuvola in bottiglia ha trovato meccaniche dichiarate ma non collegate: fase/bottiglia, Open e interruzione. Le scelte NU01–NU04 restano aperte. Il candidato parziale è conservato separatamente e non viene pubblicato come funzione funzionante. Pinepine e nucleo del Costrutto Minore mantengono le regole attuali in attesa delle scelte AN01–AN02. Vedi DOMANDE_ARTWORK_PROSSIMA_PATCH.md.

## Campi personalizzabili

Costi, durate, recuperi, bersagli e cooldown negli editor e nel JSON. sleepRecoveryRules e personalNeedsRules definiscono recupero e bisogni per scheda; sandRules mantiene percentuale, recupero e risoluzione Lava. precisionBodyParts conserva parti, materiali, soglie e lesioni personali. I temi non sostituiscono immagini o ritratti salvati.

Le due fixture finali conservano tutte le asserzioni: il nucleo deve restare a 20 Vita e il corpo a 60, senza una nuova mitigazione passiva casuale; le catture usano il fallback esistente solo per Windows 1224. La ripetizione precedente interrotta per il difetto della coda non viene conteggiata. I 32 test Python di pubblicazione/updater/swap/firma e il comando PowerShell di pubblicazione simulata sono passati; nessun dispatch reale è stato eseguito da quelle prove.

CI, distribuzione EXE/ZIP/APK, firma, download anonimi e avvio della nuova versione verranno registrati soltanto dopo il loro completamento.
