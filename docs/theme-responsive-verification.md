# Verifica adattamento temi — 14 ottobre 2026

I 63 temi sono verificati sulla scheda reale e sui dialoghi a 1920×1080 e
1080×1920 pixel logici. Restano coperti anche desktop 1440×900, tablet 834×1194
e telefono 390×844 dalla suite precedente.

La modalità web automatica segue l'orientamento: desktop in orizzontale,
mobile in verticale. Le scelte manuali Desktop e Mobile mantengono la priorità.
Flutter dimensiona la UI in pixel logici: su un telefono 1080×1920 fisici con
densità 3, l'area logica è 360×640.

Comando mirato eseguito:

```powershell
flutter test --no-pub test/oculum_all_themes_test.dart test/oculum_web_layout_test.dart --name '1920|rotation|Auto view'
```

Risultato: 4 test passati; 63 temi verificati in ciascuna risoluzione Full HD.
Controlli: contrasto, assenza di overflow, dialoghi, navigazione e rotazione web.
Le schermate Vervain delle due risoluzioni sono state ispezionate visivamente.

Le build locali già presenti contengono lo stesso codice dell'app: questa
verifica aggiunge casi di test senza richiedere una nuova compilazione.
Windows Test: `windows-test/Oculum-Test.exe` e `Oculum-Test-Windows.zip`.
