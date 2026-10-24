# Meccanio e pubblicazione

## Regole e personalizzazioni

- Le abilità conservate nella scheda hanno forme I–III: livello richiesto, costo, recupero, descrizione ed effetti restano nei normali editor e nel JSON. Meccanio non usa Oculum né Art.
- Il carico casuale, il colore, la Open, il proprietario e il rapporto di fiducia sono salvati per singola creatura: riaprire la scheda non estrae nuovamente le abilità.
- Il JSON `meccanio` permette di cambiare `maximumHp`, `skillPowerPercent`, `initialShieldPercent`, `repairShieldPercentI`, `repairShieldPercentII`, `defenseBonus` e `oculumShieldPercent`. I valori iniziali si applicano alla creazione e non sovrascrivono una configurazione esistente.
- Malconcio: metà Scudo iniziale e dei limiti di riparazione, potenza delle skill 75%. Primitivo: +3 Difesa, Scudo 120% della Vita, Scudo Oculum 10%. Élite: skill 125%. Gli ID storici `meccanio_ammaccato` e `meccanio_primordiale` restano validi.
- Empatia e Inganno condividono un uso tra due riposi. Empatia sottrae il totale in punti percentuali; Inganno con dado sotto 12 aggiunge 10 punti, massimo 100%, altrimenti riduce il rifiuto. I riposi recuperano l'uso e riducono il rifiuto di 20/50 punti.
- Aiuto difensivo del padrone: difesa riuscita, riduzione casuale di 5–30 punti; fallita, 2–40 proporzionali alla Vita persa dal padrone durante la protezione. Ogni attacco viene premiato una sola volta. I valori non diventano negativi.
- Prezzo, peso e descrizione dell'offerta Postea restano personalizzabili nel mercato. Le pergamene Raggio Angelico e Richiamo dei Piranha si trovano rispettivamente nei mercati Angelico/Sacro e Affogato.

## Build GitHub da PowerShell

Da un checkout con modifiche già committate e `gh` autenticato:

```powershell
Set-Location 'C:\Oculum App\oculum'
.\scripts\build_and_publish_github.ps1
```

Lo script invia il branch, avvia la distribuzione e attende il catalogo pubblico relativo allo stesso commit. Un errore interrompe il percorso: non considerare pubblicata una build fallita.

Per rigenerare e verificare i pacchetti locali, conservando la distribuzione precedente:

```powershell
Set-Location 'C:\Oculum App\oculum'
.\scripts\build_combat_distribution.ps1
```

Lo script prepara Web, Windows, Windows Test e APK, verifica ZIP e hash e sostituisce `build\distribution` solo alla fine. Chiudere l'app avviata da quella cartella prima della sostituzione. I salvataggi non vengono cancellati. macOS e Linux si verificano nelle rispettive build GitHub.

La pubblicazione effettiva richiede controllare separatamente: test, CI, commit dei pacchetti, release pubblica `oculum-downloads`, download anonimi e sito Pages. La presenza del solo commit non prova questi passaggi.
