# Oculum Visual Bible

La scheda è un oggetto costruito nel mondo di Oculum. Il tema è puramente decorativo: posizione, dimensioni e disposizione di pulsanti e funzioni restano identiche. Identità e ritratto, Vita/Scudi/Oculum, quattro statistiche e combattimento non ricevono padding, spazi o riordini aggiuntivi.

## Oculum Core Identity
Goth fantasy inciso, materiali consumati e piccoli bagliori locali. Cinzel per sigilli e titoli, i font già scelti dal giocatore per contenuti e numeri. La grafica incornicia la lettura.

## Theme Identity
I 62 temi esistenti conservano ID, nome e identità; il preset Sogno aggiunge una nuova identità senza rinominarli. `docs/design/theme-art-bible.json` conserva motivi e materiali; `design/themes/<id>/composition.json` definisce la composizione riproducibile. Ogni illustrazione originale resta in `assets/themes/<id>/overlays/relic.png`.

## Materials / Shapes / Frame Language
Radici: ramificazioni, foglie, asimmetria. Cristallo: facce appuntite e giunzioni spezzate. Ferro: placche interrotte e rivetti. Astrale: orbite incomplete e costellazioni. Abisso: curve correnti e ventose. Cenere: archi bruciati e scintille. Cattedrale: archi, nervature e sigilli. Sogno: profili morbidi sovrapposti dal blu al viola e al rosa pastello. Il motivo specifico del tema determina tagli, densità e disposizione, oltre alla famiglia.

Natura dispone di due composizioni selezionabili: steli secchi con petali caduti, oppure tralci vivi con foglie e fiori viola. Sogno usa nubi stratificate blu, viola e rosa pastello; il trattamento quieto è rarefatto, quello cromatico aggiunge strati e piccoli astri. La selezione è salvata e vale per cornici, scene, pannelli e incisioni dei controlli.

## Icon Language / Rune Language
Simboli incisi piccoli, bordi sottili e rune incompiute. Nessuna icona ornamentale sostituisce un'azione. Le icone funzionali esistenti conservano significato e area cliccabile.

## Creature Language

Precisazione del 6 novembre: la terza alternativa C, con piccoli redesign e variazione pittorica (guazzo/tempera opaca, contorni anime secchi, pennellate più visibili), vale soltanto per creature ancora senza scelta. I canoni e i voti precedenti escludono nuove proposte per quella creatura; A/B restano conservate. Nessuna modifica dell'anatomia, dell'elemento o dei poteri per ottenere la variazione. Ogni nuova C va controllata per numero degli arti e margini e rimane una proposta finché l'utente la sceglie. Archivio e revisioni su G, con collegamenti compatibili dai percorsi del progetto su C.

Precisazione esplicita del 2 novembre: Oculum resta un **dark fantasy**, nonostante le stranezze. Per le prossime proposte, soprattutto i mostri ostili devono risultare più mostruosi e minacciosi. Nuovo riferimento allegato: tratto anime scuro, ombre profonde, profili espressivi, colori controllati e pittura opaca. Rame fatato resta la base materica, senza obbligo di dolcezza o toni pastello. Il riferimento non impone il soggetto umano raffigurato e non annulla le immagini canoniche già approvate. [Richieste e applicazione](../docs/DIREZIONE_DARK_FANTASY_2026-11-02.md).

Conferma del 28 ottobre 2026: ogni mostro e variante ha un tema e una reliquia visiva specifici, in stile Rame fatato. Materiali, anatomia, colori ed ambiente devono renderli riconoscibili, evitando il riuso di un generico segnaposto come lavoro definitivo. La reliquia visiva è decorativa e non attribuisce da sola nuovi drop. Mostri e reliquie rispettano i margini e gli spazi dei controlli; nel Monster Book niente ritratto imposto.
Le illustrazioni originali dei temi possono emergere nei margini e negli spazi scenografici. Nessuna creatura invade i valori o si sovrappone alle etichette. Classic Oculum mantiene il sigillo inciso senza reintrodurre l'occhio nel reliquiario.

## Background Language
Centro trasparente, bordi materici e separatori ariosi. I PNG sono locali e disponibili senza connessioni ai plugin. I sorgenti SVG e il manifest restano modificabili in `design/themes/`.

## Animation Language
Movimento lento con pausa nella maggior parte del ciclo. Un solo elemento scenografico animato per composizione; nessun rebuild delle funzioni. Complete, Ridotte e Disattivate usano le impostazioni esistenti. Disattivate conserva tutta l'identità statica. Lifecycle, TickerMode e riduzione movimento del sistema fermano il movimento.

## Forbidden Styles
Dashboard generica; pannelli riempiti di immagini dietro il testo; asset opachi; neon indiscriminato; rettangoli identici soltanto ricolorati; animazioni continue senza pause; decorazioni che intercettano input; dipendenze runtime da Figma/Adobe/Canva.

## Responsive e zona protetta
Desktop: bordo spezzato con ornamentazione laterale estesa. Tablet: angoli e rilievi ridotti. Telefono: cornice dedicata compatta e scena più bassa. Le cornici occupano i margini esistenti; il centro ha alpha zero. La scena è uno sfondo sotto i pannelli e non occupa spazio nel flusso della pagina. Ritratto e pannelli usano livelli distinti con IgnorePointer. Non modificare salvataggi, statistiche, autorizzazioni o costi delle skill per il redesign.

## Plugin e provenienza
Figma: file `Dw1F8sR6bzTCuGkaH2CEeS`, struttura e Art Bible modificabile. Canva: concept botanico `MAHX5OhB8Ts`. Creative Production: board `f6cee63f-2d3d-4c56-8089-0d44f7d23c45`. Adobe: inizializzazione fallita due volte con errore interno; nessun asset viene attribuito ad Adobe. Il concept Canva è una reference, non un PNG con alpha verificato.
