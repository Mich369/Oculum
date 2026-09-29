# Push e avvio GitHub Actions

Pubblicare una patch selezionata e seguirne le build:

```powershell
.\scripts\publish_patch_to_github.ps1 -Message "Descrizione patch" -Path @("lib/file.dart", "test/file_test.dart") -SubmitActions -WaitForActions
```

Ripetere push e avvio anche senza nuove modifiche:

```powershell
.\scripts\publish_patch_to_github.ps1 -Message "Avvio build" -SubmitActions -WaitForActions
```

Lo script riusa le build in corso o riuscite per lo stesso commit. Se non ce ne sono avvia i workflow `build_distribution.yml` e `build_macos.yml`, mostra i link e, con `-WaitForActions`, restituisce un errore se la build fallisce. Senza attesa conferma solo l'avvio, non il completamento.

I file gia staged bloccano la pubblicazione per evitare commit misti. `-Branch` deve coincidere con il branch aperto. `-All` include esplicitamente tutte le modifiche; preferire `-Path` per una patch mirata.

Punti modificabili: lista dei workflow e attesa nello script; piattaforme e artifact in `.github/workflows/build_distribution.yml`; test e release Apple in `.github/workflows/build_macos.yml`. `-BuildLocalDistribution` prepara anche la distribuzione locale; `-WaitForAppleArtifacts` attende gli artifact Apple.
