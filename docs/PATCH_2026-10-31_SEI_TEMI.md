# Sei temi canonici e Cavaliere Morto

## Ambito

Richiesta successiva: Cuore Filo rifiutato come contenuto del manuale. Base e varianti ritirati dalle liste attive, conservando definizioni/ID legacy per vecchie schede, customizzazioni e varianti personali. Nessun PNG del lotto scartato entra nell’app. Inventario aggiornato a 1.204 voci attive; 76 desktop, 41 telefoni, 42 reliquie e 40 set completi. La costruzione delle varianti precede il filtro di ritiro, così gli stili degli altri mostri non cambiano.

Sei pacchetti approvati separatamente dall’utente: Specchio Mangiavoce D2, Teschio Mostruoso D1, Torretta Oculum C1, Adoratore della Bestia C3, Cavaliere Morto E2 e Scheletro Bombarolo C1. Per ogni creatura: desktop, telefono e reliquia. Le due conferme di sei derivati ciascuna restano riferite ai dodici file precisi. Ricevuta in `design/approved-six-monster-packs-2026-10-31.json`:18asset e SHA256. Copia senza ricampionamento o altri ritocchi; originali, prompt e revisioni conservati nella cartella artwork locale.

I nuovi temi usano l’immagine intera, così un telefono alto non taglia il soggetto laterale. La pagina acquistata del Book contiene l’immagine entro i margini; nessun ritratto obbligatorio. Le reliquie restano decorative e non creano nuovi oggetti o bonus.

Il Cavaliere conserva ID, valori, tecniche e regole di danno. Il punto debole confermato è la sfera nascosta alla base della vita, con bersaglio anatomico distinto. L’eventuale donna evocata non viene interpretata come parti del corpo del Cavaliere. Precedenza agli override del Master, anche dopo salvataggio JSON. Il disegno non rivela un nuovo nucleo aperto sul petto e non introduce soglie aggiuntive di esposizione.

Allineate le descrizioni dello stand dell’Adoratore e della cresta del Teschio; nessun nuovo partecipante, attacco, resistenza o drop dedotto dalla figura.

## Verifiche

- La revisione 8f121262 ha completato la suite locale: 1.995 passati, 6 saltati, zero fallimenti. Dopo la successiva richiesta di ritiro: 57 test mirati passati su catalogo, salvataggi, viaggio e temi (`build/six-packs-retirement-final.log`). La nuova CI deve verificare l’intero commit finale; questi gruppi si sovrappongono e non vanno sommati.
-197test locali mirati passati: caricamento degli asset, confronto SHA delle18copie, trasparenza e margini delle reliquie, scelta telefono/desktop, layout e clic a320/834/1440px, anatomie, fratture, personalizzazioni JSON. Log locale: `build/six-packs-focused-final.log`.
-Analisi e suite completa, CI GitHub, pacchetti installati, download pubblici e sessioni online reali sono evidenze distinte. Questa nota non certifica da sola tali passaggi né una prova completa su tre dispositivi fisici.

## Personalizzazioni preservate

Selezione del tema e della reliquia, colori, punti deboli, parti anatomiche e loro valori; nessun salvataggio o immagine personale viene sovrascritto. Restano modificabili costi, forme, bersagli e durata delle capacità esistenti; questa patch non cambia quei valori.

## Riga da approvare a consegna verificata

ART43 — Integrare i sei set canonici desktop/telefono/reliquia, correggere la sfera del Cavaliere Morto e preservare personalizzazioni e leggibilità. Implementazione locale verificata; la chiusura al100% richiede la conferma dell’utente dopo il riepilogo dei risultati effettivi della consegna.

La selezione di Precisione non mostra la sfera del Cavaliere prima della scoperta effettiva del punto debole. La scoperta la rende selezionabile; le anatomie esplicite del Master restano prioritarie. Test widget prima/dopo e prova di non-mutazione inclusi nei 197 test mirati finali. La prima suite completa e le prime run dc4a6ad5 sono state interrotte intenzionalmente per includere questa correzione; non sono presentate come verifiche complete.
