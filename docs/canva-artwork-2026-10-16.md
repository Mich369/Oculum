# Artwork Canva per Oculum

## Produzione effettiva

Il riferimento è il progetto Canva `DAHX-kQUyBo`, **Oculum Materiali HUD**. Sono state generate tre nuove cornici e poi rimosso lo sfondo con Canva. I PNG originali scaricati dall'interfaccia Canva sono conservati in `design/materials/canva-20261016`, a **1776×896 pixel**, con canale alpha. Non sono le miniature da 200 pixel restituite dal connettore.

| Tema | Immagine generata | PNG con sfondo rimosso |
| --- | --- | --- |
| Ghiaccio | MAHYIlRKaTY | MAHYIjPQqpM |
| Spirituale | MAHYImHjagQ | MAHYIrXYxZA |
| Fisico | MAHYIrIgKG4 | MAHYIp4_Ams |

La generazione è guidata dal riferimento e dalle regole artistiche Oculum; non è stata passata al generatore una copia pixel per pixel del progetto originale.

## Integrazione reale

- `assets/themes/canva_ice`, `canva_spirit`, `canva_physical`: PNG caricati dal sistema grafico condiviso.
- Registro elementale: Gelo/Ghiaccio, Spirituale e Fisico puntano ai nuovi pacchetti.
- Cornici per pannello, telefono, ritratto, statistiche e separatori.
- Cinque stati del pulsante e varianti di luminosità ferma/viva.
- Scene decorative per desktop e telefono.
- Esportazione ripetibile: `scripts/build_canva_theme_frames.cjs`.
- Originali, riferimenti Canva e dati di esportazione restano nel progetto.

L'esportatore ricompone angoli e binari nel margine esterno di 24 pixel, conservando trasparente il centro. Il livello grafico continua a usare `IgnorePointer`, così le azioni rimangono cliccabili. Non cambia posizione ai comandi né regole di combattimento. Il movimento usa il sistema dell'app già presente; i PNG non contengono animazioni proprie.

## Personalizzazione

Si possono scegliere il tema elementale oppure il pacchetto illustrato manuale, cambiare i colori e regolare variante, intensità e movimento con le impostazioni esistenti. Gli altri 55 elementi hanno ora motivi vettoriali originali esportati in PNG, materiali locali e movimenti sui bordi. La texture Cenere `MAHYIisE_WI`, esportata realmente da Canva, è inclusa nel pacchetto Cenere e conservata fra i sorgenti.

## Altri plugin controllati

- Adobe: l'inizializzazione restituisce un errore interno; nessun asset Adobe viene dichiarato prodotto.
- Magnific: l'account collegato risulta Free, con zero crediti. Non sono state avviate generazioni a pagamento.

Nessun abbonamento, piano o impostazione di pagamento è stato modificato.
