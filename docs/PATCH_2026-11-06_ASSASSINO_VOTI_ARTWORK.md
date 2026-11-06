# Assassino NPC nemico e nuovo lotto canonico — 6 novembre 2026

L’Assassino sostituisce il nome predefinito Duellante Senza Palpebre ed è generato come **NPC nemico**. Mantiene il proprio kit e il precedente profilo di crescita: cambiare ruolo non ne riduce le statistiche. Il vecchio identificativo rimane compatibile con schede, personalizzazioni e sorgenti degli Occhi. Le definizioni personali del Master conservano la precedenza.

Armaiolo della Fila Lunga diventa **Armaiolo della spada e scudo**, con la variante Rituale distinta. Ritirati dalle nuove selezioni soltanto il Duellante Senza Palpebre Errante e la famiglia del Sagrestano Cavo. I lookup delle schede storiche restano disponibili; il fallback delle varianti non deve riproporli negli incontri attivi.

Sono collegati nel sorgente **55 desktop nativi esatti**, inclusi gli ultimi sei approvati nella ricevuta09. Le revisioni conservano lo Scarabeo del Sigillo Ardente di circa due metri, i due Demoni Intermedi più massicci, il Lacrimante B con due braccia collegate e locomotorie e il Ciclope v4 descritto sotto. Il Guardiano usa la revisione con dodici campanelle, sei sopra e sei sotto; l’originale con dieci rimane nello storico e non è usato come nuovo sfondo.

Il Ciclope del Fato usa la v4 approvata, con pelle grigio-verde, drappo bordò, occhio violetto e corta cresta di spine. La variante del Bandito della maschera di corteccia è scelta; il voto della variante non sceglie automaticamente la sua base. Le alternative, le immagini personali e gli originali su G sono conservati. Il desktop rimane intero sui telefoni con il fallback esistente: questo lotto non dichiara nuove immagini native telefono o reliquie.

## Personalizzazione

Restano modificabili dagli editor e conservabili nel JSON nomi, ruolo e lato, livello e Grado, statistiche, anatomie e punti deboli, Skill/Art/Open, forme, elementi, requisiti, costi, bersagli, effetti, durate e recuperi, oggetti, temi, colori, sfondi e preferenze della singola scheda. Le dimensioni artistiche dello Scarabeo non aggiungono bonus numerici. L’aggiornamento del catalogo non riscrive le schede salvate o le definizioni personali.

## Stato delle verifiche

La copia dei 55 PNG verifica gli SHA256 dei nativi e delle anteprime selezionate, senza ricompressione. Voti e revisioni sono collegati alle rispettive ricevute; il rapporto precedente di 44 copie resta come snapshot. Ricevute: [voti del lotto](CONFERME_UTENTE_ARTWORK_2026-11-06_06.json), [quattro revisioni approvate](CONFERME_UTENTE_ARTWORK_2026-11-06_07.json), [asset collegati](../design/approved-monster-desktops-2026-11-06-votes2.json).

Passati **75 test Flutter** in nove suite: generazione reale NPC nemico, crescita precedente, kit nativo, record salvati, ritiri e lookup storici, manuale/PDF e SHA dei desktop nel bundle. Analisi di lib/test senza problemi. Il primo run aveva 68 passati e due fallimenti nelle fixture; il secondo 69 e un fallimento nella selezione del record legacy da ricaricare. Corrette le fixture e l’invariante della variante ora intenzionalmente ritirata, senza alterare il comportamento per far passare i test. Il terzo run era verde sul primo sorgente; il riesame indipendente ha poi richiesto le correzioni aggiuntive descritte sotto. Il gruppo finale aggiornato è verde; corretto anche un import superfluo segnalato dall’analisi, poi rieseguita senza problemi.

Passate **44 regressioni Python** dei percorsi e delle etichette delle gallerie. I 106 voti non vengono riproposti; le revisioni approvate prevalgono sui vecchi blocchi. Resta un confronto A/B/C per il Bandito Corteccia base; il Ciclope v4 è approvato come redesign da riferimento, senza attribuirgli una falsa lettera A/B/C. Snapshot del catalogo attivo: 1.200 ID, 964 ancora senza scelta definitiva; i conteggi storici rimangono riferiti alle loro date.

Il riesame indipendente ha isolato e fatto correggere tre regressioni del passaggio a NPC: classificazione nemico nelle statistiche del party, kit completo al posto del campione di tre tecniche ed etichetta dei punti per Grado. Un ulteriore test ha riprodotto la ridistribuzione casuale di Oculum quando le tre tecniche estratte sono tutte naturali: per il profilo dell’Assassino l’Art dichiarata dal catalogo rimane presente anche con sole Open. La regressione deterministica con seed 0 conserva RES27/VOL21/MAT24/OCU17, senza cambiare le formule delle altre specie o le copie personalizzate. Confrontati sedici seed e conservati i kit fissi degli altri NPC. L’ultimo gruppo da 72 casi e i tre test separati dei download sono verdi sul runtime finale.

Passati separatamente anche i quattro test del log (prima apertura, corrispondenza asset/registro e chiusura a 320/1440 px), portando a 79 i casi Flutter locali distinti.

Passati anche 14 test locali del publisher: sono fixture e non una pubblicazione reale. Un primo tentativo confinato è fallito per accesso alla cartella temporanea; la riesecuzione nell’ambiente host è passata. Il confronto di Art personalizzate esclude soltanto gli ID interni degli effetti creati dal timestamp; costi, valori, durata, effetti e recuperi restano confrontati.

CI, prove online autenticate, pacchetti installati e download pubblici saranno registrati separatamente. La distribuzione attiva rimane quella compilata da 5f89ea2b finché i nuovi pacchetti non sono verificati. Nessuna riga viene chiusa al 100% da questi voti artistici.

## Primo CI e tentativo aggiornato

Il CI274 del commit 5aa6bbec termina con **2.303 passati, un fallito e sei saltati**: l’unico test fallito manteneva il conteggio storico di nove weak horror attivi, mentre il Sagrestano richiesto è ritirato e ne rimangono otto. Il test aggiornato verifica sia gli otto attivi sia i dati originali del Sagrestano tramite lookup storico. Nessun mostro è stato riattivato per far passare il test. Packaging saltato, nessun artifact pubblicato o installato, distribuzione 5f conservata. Le quattro prove online autenticate successive alla suite non sono state eseguite in quel run.

Il tentativo successivo include anche le sei nuove approvazioni: Cane dei Ghiacci A, le C di Cervo dal Fiato Bianco, Cervo di Linfa Verde, Cinghiale Muschioso e Cervo di Brumalba, e Baby Rock Rhino derivato dal disegno della Veterana ma meno colossale. Base e Veterana conservano statistiche distinte. [Ricevuta esatta](CONFERME_UTENTE_ARTWORK_2026-11-06_09.json).

Passati 23 test mirati dopo il nuovo lotto e la correzione dell’invariante, analisi nuovamente senza problemi. Ventidue riprendono casi del gruppo precedente; il caso weak horror porta a 80 i casi locali distinti coperti complessivamente, senza sommare le riesecuzioni come nuovi test. Rieseguiti e passati anche i quattro test del log dopo il sync del registro aggiornato. Le 44 regressioni Python delle gallerie includono sei nuovi casi locali sul redesign di riferimento del Rhino. Il nuovo CI, i suoi pacchetti e le prove pubbliche restano separati dal CI274 fallito.
