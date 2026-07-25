# Kit ChatGPT per personaggi prefabbricati Oculum

Questo kit permette a ChatGPT di creare personaggi importabili in Oculum senza generare backup completi e senza toccare le schede gia presenti.

## File da dare a ChatGPT

1. `CHATGPT_PROMPT.md`: prompt pronto da incollare.
2. `oculum_prefab_subset.schema.json`: contratto JSON dei campi usati.
3. `prefab_character_template.json`: modello neutro da personalizzare.
4. `example_prefab_character.json`: esempio completo e importabile.

## Formato da richiedere

ChatGPT deve restituire esclusivamente JSON UTF-8 con questa radice:

```json
{
  "kind": "oculum_sheets",
  "version": 1,
  "createdAt": "DATA_ISO_8601",
  "sheets": []
}
```

Ogni elemento di `sheets` e una nuova scheda. Il decoder dell'app accetta sia questo JSON sia il codice testuale con prefisso `OCULUM-SHEETS-v1:`.

## Importazione nell'app

1. Aprire le impostazioni di Oculum e la sezione dei codici scheda.
2. Incollare il contenuto JSON nel riquadro del codice.
3. Premere `Importa codice`.

L'import normalizza la scheda, rimuove identificativi privati, genera nuovi `id` e `sheetTag`, assegna un nome `Copy` in caso di duplicato e aggiunge la scheda senza cancellare quelle esistenti.

Non usare `Ripristina tutto` del backup completo per i prefabbricati.

## Regola del primo Titolo del Fato

- La prima Art deve essere l'Oculum Art del personaggio.
- La prima Skill della prima Art deve avere `"livello": 1`.
- Il Titolo deve essere in `titoli` e avere `"tipo": "Titolo del Fato"`.
- Il requisito leggibile va nel campo `richiede` del Titolo.
- Usare `"chiaveSistema": "fate_title_1_first_art_skill_1_lvl_1"` per evitare che il controllo automatico crei un duplicato.
- Non aggiungere `richiede` dentro una `ArtSkill`: quel campo non esiste nel modello e verrebbe ignorato.

## Tipi importanti

- I valori base della scheda come `livello`, `grado`, `exp`, statistiche e HP sono stringhe numeriche.
- `ArtSkill.livello` e i bonus dei Titoli sono interi.
- Flag come `equipaggiato`, `evoluto`, `sbloccata` e `openAttiva` sono booleani.
- Gli array Oculum delle Skill Art hanno sempre cinque posizioni, una per ogni possibile evoluzione.
- `risorseCostoPerLivello` sceglie la statistica consumata da ogni evoluzione: `oculum`, `materia`, `volonta`, `resilienza` oppure `nessuna`.
- Il vecchio campo `costoOculumDisabilitatoPerLivello` resta presente per compatibilita: vale `false` soltanto quando la risorsa corrispondente e `oculum`.

Nell'esempio la prima Skill consuma Oculum, la seconda Materia e la terza Volonta. Lo stesso formato puo essere usato per una Art con `"tipo": "Martial Art"`.

Il personaggio di esempio contiene un Titolo del Fato, un Tratto Razziale e una Oculum Art completa con tre Skill, di cui la prima e gia al livello 1.
