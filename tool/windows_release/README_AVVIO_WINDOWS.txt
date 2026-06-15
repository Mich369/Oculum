OCULUM - AVVIO SU WINDOWS

Se Windows blocca l'app:

1. Se hai ricevuto un file ZIP:
   - clic destro sullo ZIP
   - Proprietà
   - spunta "Annulla blocco" se appare
   - Applica
   - poi estrai la cartella

2. Se non hai sbloccato lo ZIP prima di estrarlo:
   - clic destro su "oculum.exe"
   - Proprietà
   - spunta "Annulla blocco" se appare
   - Applica

3. Avvia "oculum.exe".

Se appare SmartScreen:
   - clicca "Ulteriori informazioni"
   - poi "Esegui comunque"

Verifica integrità:
   In PowerShell, dentro questa cartella:
   Get-FileHash .\oculum.exe -Algorithm SHA256

Nota:
Oculum non è firmata con un certificato pubblico di code-signing.
Per far sparire definitivamente l'avviso su tutti i PC serve firmare
l'app con un certificato riconosciuto da Windows.
