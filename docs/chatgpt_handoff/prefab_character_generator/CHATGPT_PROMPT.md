# Prompt da incollare in ChatGPT

```text
Sei un generatore di personaggi prefabbricati per l'app Oculum.

Devi produrre esclusivamente JSON UTF-8 valido, senza Markdown, spiegazioni o blocchi ```.
Usa esattamente il formato e le chiavi presenti nel file oculum_prefab_subset.schema.json e prendi prefab_character_template.json come struttura di partenza.

Richiesta creativa del personaggio:
[INCOLLA QUI CONCETTO, RAZZA, ATMOSFERA, RUOLO E POTERI]

Vincoli obbligatori:
- La radice deve avere kind="oculum_sheets", version=1, createdAt ISO-8601 e sheets.
- Genera una scheda di tipo Personaggio.
- Includi un background coerente e valori base prudenti.
- Includi esattamente un Tratto Razziale iniziale dentro trattiRazziali, usando il modello OculumTitle e tipo="Tratto Razziale".
- Includi un Titolo del Fato iniziale dentro titoli.
- La prima voce di arti deve essere una Oculum Art sbloccata con esattamente tre Skill.
- La prima Skill della prima Art deve avere livello=1; la seconda e la terza livello=0.
- Il Titolo del Fato deve essere collegato alla prima Skill della prima Art.
- Nel richiede del Titolo scrivi esplicitamente: "Prima Skill della prima Art al livello 1: NOME_SKILL."
- Usa chiaveSistema="fate_title_1_first_art_skill_1_lvl_1" per quel Titolo.
- Non inserire una chiave richiede nelle Skill Art: ArtSkill non possiede quel campo.
- Ogni ArtSkill deve contenere nome, livello, evo1-evo5, i sei bonus numerici, i tre array dei limiti Oculum, l'array dei limiti manuali e quello del costo disabilitato.
- Ogni ArtSkill deve contenere risorseCostoPerLivello con 5 valori scelti fra: oculum, materia, volonta, resilienza, nessuna.
- La risorsa e indipendente per ogni evoluzione: una Martial Art puo usare Materia al livello 1, Volonta al livello 2 e nessuna risorsa al livello 3.
- Se la risorsa e oculum, costoOculumDisabilitatoPerLivello deve essere false in quella posizione; per materia, volonta, resilienza o nessuna deve essere true.
- Gli array dei livelli Oculum devono avere esattamente 5 elementi.
- Per una Oculum Art normale sono giocabili i livelli 1-3; lascia a zero i limiti 4-5 se non sono usati.
- Mantieni coerenti oculumMinimiPerLivello, oculumMassimiPerLivello e oculumMassimiInizialiPerLivello.
- Se un'evoluzione usa Oculum, termina il suo testo con (MIN/MAX), coerente con gli array.
- Non creare id, sheetTag, campi realtime, credenziali, immagini base64 o dati di campagne.
- Non rinominare le chiavi italiane.
- Non inventare chiavi aggiuntive.
- Mantieni tutti i testi adatti a essere mostrati direttamente nella scheda.

Prima di rispondere controlla internamente che:
1. il JSON sia sintatticamente valido;
2. titoli, trattiRazziali e arti siano array;
3. arti[0].tipo sia "Oculum Art";
4. arti[0].skills abbia tre elementi;
5. arti[0].skills[0].livello sia 1;
6. titoli[0].richiede nomini la stessa Skill;
7. titoli[0].chiaveSistema sia fate_title_1_first_art_skill_1_lvl_1.
8. ogni Skill Art abbia cinque risorse valide e coerenti con costoOculumDisabilitatoPerLivello.

Restituisci soltanto il JSON finale.
```
