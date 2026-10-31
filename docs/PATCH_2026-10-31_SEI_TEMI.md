# Sei temi canonici e Cavaliere Morto

## Ambito

Sei pacchetti approvati separatamente dall’utente: Specchio Mangiavoce D2, Teschio Mostruoso D1, Torretta Oculum C1, Adoratore della Bestia C3, Cavaliere Morto E2 e Scheletro Bombarolo C1. Per ogni creatura: desktop, telefono e reliquia. Le due conferme di sei derivati ciascuna restano riferite ai dodici file precisi. Ricevuta in `design/approved-six-monster-packs-2026-10-31.json`:18asset e SHA256. Copia senza ricampionamento o altri ritocchi; originali, prompt e revisioni conservati nella cartella artwork locale.

I nuovi temi usano l’immagine intera, così un telefono alto non taglia il soggetto laterale. La pagina acquistata del Book contiene l’immagine entro i margini; nessun ritratto obbligatorio. Le reliquie restano decorative e non creano nuovi oggetti o bonus.

Il Cavaliere conserva ID, valori, tecniche e regole di danno. Il punto debole confermato è la sfera nascosta alla base della vita, con bersaglio anatomico distinto. L’eventuale donna evocata non viene interpretata come parti del corpo del Cavaliere. Precedenza agli override del Master, anche dopo salvataggio JSON. Il disegno non rivela un nuovo nucleo aperto sul petto e non introduce soglie aggiuntive di esposizione.

Allineate le descrizioni dello stand dell’Adoratore e della cresta del Teschio; nessun nuovo partecipante, attacco, resistenza o drop dedotto dalla figura.

## Verifiche

-195test locali mirati passati: caricamento degli asset, confronto SHA delle18copie, trasparenza e margini delle reliquie, scelta telefono/desktop, layout e clic a320/834/1440px, anatomie, fratture, personalizzazioni JSON. Log locale: `build/six-packs-focused-tests.log`.
-Analisi e suite completa, CI GitHub, pacchetti installati, download pubblici e sessioni online reali sono evidenze distinte. Questa nota non certifica da sola tali passaggi né una prova completa su tre dispositivi fisici.

## Personalizzazioni preservate

Selezione del tema e della reliquia, colori, punti deboli, parti anatomiche e loro valori; nessun salvataggio o immagine personale viene sovrascritto. Restano modificabili costi, forme, bersagli e durata delle capacità esistenti; questa patch non cambia quei valori.

## Riga da approvare a consegna verificata

ART43 — Integrare i sei set canonici desktop/telefono/reliquia, correggere la sfera del Cavaliere Morto e preservare personalizzazioni e leggibilità. Implementazione locale verificata; la chiusura al100% richiede la conferma dell’utente dopo il riepilogo dei risultati effettivi della consegna.
