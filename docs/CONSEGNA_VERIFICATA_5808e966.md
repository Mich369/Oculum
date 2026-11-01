# Consegna verificata — 31 ottobre 2026

Applicazione compilata dal commit **5808e9661c394761a1824e8446c63d0793977fbc**. Questo rapporto è stato scritto dopo le verifiche finali e non cambia il commit dei binari.

## Risultati verificati

| Ambito | Evidenza |
|---|---|
| Suite locale completa | 1.959 test passati, 6 saltati, zero fallimenti; 26 min 41 s |
| Analisi locale | Nessun problema; 136,6 s |
| Riprove mirate | 150 passate; cinque ripetizioni della parata di coda e quattro test del log passati. Gruppi sovrapposti alla suite: non sommarli |
| CI coordinata | [Run 41202245421](https://github.com/Mich369/Oculum/actions/runs/41202245421): 1.959 passati, 6 saltati; analisi pulita; tutte le build delle piattaforme riuscite |
| Online autenticato | Quattro prove passate su trasporto, isolamento, consegna e applicazione del combattimento |
| Pubblicazione | [Run 41205273566](https://github.com/Mich369/Oculum/actions/runs/41205273566) riuscita; 11 archivi raggiungibili senza credenziali, dimensioni e digest coerenti con gli artifact GitHub |
| Sito | [Pages 41205273408](https://github.com/Mich369/Oculum/actions/runs/41205273408) riuscita; commit verificato in index, bootstrap e codice compilato. Tre PNG pubblicati campionati corrispondono ai file approvati |
| Installazione locale | 16.469 file, manifesto compreso; nessun file extra o mancante e zero differenze nella verifica finale |
| Artwork nei pacchetti | 385 confronti SHA riusciti: 35 PNG approvati, in tre runtime e otto pacchetti. Il Web usa il proprio percorso assets, diverso da flutter_assets dei pacchetti nativi |
| Android | APK firmato, package com.mich.oculum, versionCode 100262, versionName 1.0.0; certificato previsto confermato |
| Avvio Windows | EXE normale e Test rimasti attivi per 8 secondi ciascuno. Backup preventivo di 62 file del profilo, zero file cambiati; terminati soltanto i processi creati dalla prova |

Le quattro prove online autenticate non equivalgono a una sessione completa su tre dispositivi fisici. La prova di avvio Windows non certifica tutti i controlli grafici interattivi.

## Contenuto della patch

- Mostro Solare con **due occhi laterali, uno per lato** nell'anatomia predefinita; le anatomie personalizzate del Master conservano la precedenza.
- 19 desktop canonici e 16 adattamenti telefono/reliquia approvati collegati; copie identiche ai file confermati. Gli altri disegni da votare non sono stati promossi automaticamente a canone.
- Manichino della Spada e Manichino di Baghest distinti. Quest'ultimo nasce con Corruzione Rossa a tre Notti; procedura della pietra dal menu Master, con Azione reale, confronto confermato, pietra consumata solo al successo e sconfitta pacifica senza premi da uccisione.
- Corretto il salvataggio dell'ultima condizione rimossa e il destinatario degli effetti ad area dopo l'editor. Corretto il riconoscimento anatomico di creature descritte senza occhi.
- Danno/Cura accetta 25% della Vita attuale e 25%Tot della massima; restano protezioni, opzioni Oltre Difesa/Scudi e pacchetti automatici.
- Parser e costi leggibili, condizioni su critico e perdita di Vita; Fiammata del non ricordo di Oblivion Shield, con Memoria e Fortuna per il Fato, perdita della prima A/R/RV successiva e log richiesto.
- Codice Senka con 100 EXP, un Vitalium Ridefinito e coltello equipaggiato +3 Tagliente. Maschera inizialmente non equipaggiata, bonus nei campi corretti e senza comandi duplicati nelle note.

## Cosa resta personalizzabile

| Area | Campi conservati negli editor e nel JSON |
|---|---|
| Scheda | Statistiche, sottotratti, EXP, valori di Vita e Scudi, inventario ed equipaggiamento |
| Skill e Art | Forme, costo e risorsa, minimo/massimo, formule, tiro, elemento, bersagli, durata, cooldown ed effetti strutturati |
| Titoli e Open | Bonus, requisiti, Skill, Open Buff ed effetti, mantenendo le regole di disponibilità e recupero |
| Oggetti | Nome, descrizione, quantità, peso, Grado, bonus, tipo di danno/protezione e abilità collegate |
| Anatomie | Definizioni personalizzate delle parti, materiale, Vita e punti deboli; precedenza agli override del Master |
| Aspetto | Tema, colori, caratteri, opacità, reliquie e immagini personalizzate già supportate |

Le personalizzazioni salvate non vengono sostituite dalle nuove definizioni del catalogo. Testo non riconosciuto ed effetti condizionati non diventano bonus automatici gratuiti.

## Recupero e limiti ancora aperti

Il primo scaricamento locale si è fermato per un errore DNS verso api.github.com. La distribuzione attiva è rimasta intatta. Sono stati ricontrollati 11.011 file di otto artifact conservati e recuperati i tre mancanti; tutti i controlli finali su archivi, runtime, manifesto e sostituzione sono stati mantenuti. La vecchia distribuzione è conservata in backup.

Il workflow macOS separato [41202245493](https://github.com/Mich369/Oculum/actions/runs/41202245493) ha raggiunto il limite di 45 minuti durante i test, senza fallimenti di test registrati prima dell'interruzione. Il pacchetto macOS consegnato proviene dalla build coordinata riuscita. Non si dichiara completata quella verifica macOS separata.

Restano da chiarire la possibile via alchemica alternativa per il Manichino di Baghest e alcune anatomie ancora in votazione. Sono inoltre registrate tre incongruenze di sprite legacy; non sono state dichiarate nuove regressioni né sostituite con disegni non approvati. Trenta nuove proposte desktop sono pronte per sei voti distinti. Queste voci non sono chiuse al 100%.

**Riga QA31-R, approvata al 100% dall’utente il 31 ottobre 2026 («Sì, consegna approvata»):** consegna della patch5808e966 con CI coordinata, pacchetti Windows normale/Test separati, EXE completo, ZIP, APK, download pubblici e verifiche descritte sopra. La conferma di questa consegna non chiude i temi o le regole ancora aperti.
