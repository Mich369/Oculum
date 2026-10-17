# Identità dei temi Oculum — 17 ottobre 2026

## Cosa cambia nell'app

Tutti i 127 pacchetti hanno una nuova cornice con rilievi dedicati, una superficie incisa e cinque stati del pulsante. I motivi provengono dall'identità del tema: falene, ruote, pergamene, radici, corna, fiale, catene, cristalli, rune e così via. Non sono soltanto cambi di colore. Il registro completo è in `docs/design/theme-identities.json`.

Il livello condiviso collega le cornici a pulsanti e pannelli senza cambiare posizione, dimensioni, azioni, focus o tastiera. Il centro delle cornici resta trasparente. Le animazioni usano il clock decorativo già esistente, sono limitate ai bordi e rispettano movimento ridotto, pausa e disattivazione. Anche i pacchetti non elementali hanno un movimento coerente: ingranaggi, petali, polvere, anime, stelle o risacca.

**Luna e Sole sono nemici:** argento astrale, falci e orbite per Luna; materiale bruciato, disco e raggi per Sole. Il Solare non usa più la famiglia visiva Lunare. Il simbolo solare delle risorse pulsa con raggi, mentre quello lunare mantiene l'orbita. Queste differenze sono grafiche e non cambiano le regole di danno.

## Artwork reali prodotti

| Artwork | Generazione | PNG trasparente |
| --- | --- | --- |
| Legno intagliato | [Open generated image](https://www.canva.com/M/MAHYP4b9TqM?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_create_image_asset_opened) | [Open generated image](https://www.canva.com/M/MAHYPzohums?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_image_remove_background_asset_opened) |
| Cenere | [Open generated image](https://www.canva.com/M/MAHYPy6Ua-A?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_create_image_asset_opened) | [Open generated image](https://www.canva.com/M/MAHYPzZ6NMs?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_image_remove_background_asset_opened) |
| Sogno | [Open generated image](https://www.canva.com/M/MAHYP2v4A-0?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_create_image_asset_opened) | [Open generated image](https://www.canva.com/M/MAHYP33G5GY?utm_source=OC-AaBlKrqBJJNF&utm_campaign=agent_connector_image_remove_background_asset_opened) |

Canva ha generato gli originali a 1776×896; l'esportazione dall'anteprima originale del sito ha fornito PNG a 1600×807. Non sono state usate le miniature da 200 pixel. Gli originali esportati sono conservati in `design/materials/canva-20261017`.

Adobe Firefly ha prodotto la cornice vulcanica a 2688×1536, seguita dal ritaglio trasparente con Photoshop. Sono conservati sia originale sia risultato. Nell'esportazione per l'interfaccia viene riservata geometricamente l'area di lettura anche se il centro dell'artwork originale contiene una campitura scura.

Fonti Adobe: [originale Firefly](https://photoshop-api.adobe.io/v2/short-url/urn:aaid:ps:US:d1fe0e65-9c74-408d-ab70-e43f15076bf6), [PNG Photoshop](https://photoshop-api.adobe.io/v2/short-url/urn:aaid:ps:US:d28fbdf2-4701-4447-8de1-2de1b424439c).

Gli artwork Canva già presenti di Ghiaccio, Spirituale e Fisico vengono conservati e integrati con i nuovi rilievi. Non viene dichiarata una verifica del piano commerciale Canva: le operazioni usano l'account collegato, senza cambiare abbonamenti.

## Cosa resta modificabile

- Tema e pacchetto artistico manuale: i pulsanti adottano la superficie del pacchetto effettivamente scelto.
- Colori personalizzati delle statistiche, Oculum e interfaccia.
- Variante ferma/viva, intensità, dimensione e movimento completo/ridotto/disattivato.
- Tutti i contenuti della scheda, immagini personalizzate e comandi esistenti.

## Sorgenti riproducibili

`scripts/build_theme_identities.cjs` esporta SVG modificabili, PNG locali, registro Dart e manifest degli hash. I 127 rilievi hanno sagome alpha distinte. Gli asset aggiunti occupano circa 16 MiB. L'app funziona offline e non contatta Canva o Adobe durante l'uso.

## Verifiche e manutenzione

- `flutter analyze --no-pub`: nessun problema rilevato.
- `flutter test --no-pub --concurrency=2`: 793 test superati, 2 esclusi; due file simultanei per contenere il consumo di memoria delle catture su Windows. La stessa impostazione è usata nella validazione GitHub. Il test live con due client Supabase richiede un'attivazione separata.
- I test controllano tutte le cornici, i cinque stati, la trasparenza dell'area di lettura, l'unicità delle sagome e la distinzione Sole/Luna.
- La galleria `build/theme-identity-gallery.png` usa componenti Flutter reali ed è inclusa nell'artefatto GitHub delle catture. È una tavola di confronto, non una verifica manuale di ogni pagina su ogni dispositivo.
- I file diagnostici PDF e JSON usano il salvataggio alternativo già presente nei test quando Windows mantiene aperta una precedente anteprima. Le asserzioni restano invariate.
