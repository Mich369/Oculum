# Oculum Visual Bible

La scheda è un oggetto costruito nel mondo di Oculum. Il tema è puramente decorativo: posizione, dimensioni e disposizione di pulsanti e funzioni restano identiche. Identità e ritratto, Vita/Scudi/Oculum, quattro statistiche e combattimento non ricevono padding, spazi o riordini aggiuntivi.

## Oculum Core Identity
Goth fantasy inciso, materiali consumati e piccoli bagliori locali. Cinzel per sigilli e titoli, i font già scelti dal giocatore per contenuti e numeri. La grafica incornicia la lettura.

## Theme Identity
Gli ID e i nomi dei 62 temi esistenti rimangono invariati. `docs/design/theme-art-bible.json` conserva motivi e materiali; `design/themes/<id>/composition.json` definisce la composizione riproducibile. Ogni illustrazione originale resta in `assets/themes/<id>/overlays/relic.png`.

## Materials / Shapes / Frame Language
Radici: ramificazioni, foglie, asimmetria. Cristallo: facce appuntite e giunzioni spezzate. Ferro: placche interrotte e rivetti. Astrale: orbite incomplete e costellazioni. Abisso: curve correnti e ventose. Cenere: archi bruciati e scintille. Cattedrale: archi, nervature e sigilli. Il motivo specifico del tema determina tagli, densità e disposizione, oltre alla famiglia.

## Icon Language / Rune Language
Simboli incisi piccoli, bordi sottili e rune incompiute. Nessuna icona ornamentale sostituisce un'azione. Le icone funzionali esistenti conservano significato e area cliccabile.

## Creature Language
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
