# Configurazione dell’accesso Google

Oculum usa il flusso OAuth di Supabase con PKCE. L’accesso usa gli scope OpenID, email e profilo. Il client usa soltanto la chiave pubblicabile Supabase. Il segreto del client OAuth resta nel pannello Supabase.

## Google Cloud

1. Apri Google Auth Platform. In Branding e Audience compila la schermata di consenso. Durante le prove aggiungi solo gli account di test autorizzati.
2. In Clients crea un OAuth client di tipo Web application.
3. In Authorized redirect URIs aggiungi esattamente `https://jgpxdlkbuxhriltxezdc.supabase.co/auth/v1/callback`. Se usi un progetto Supabase separato per le prove, crea un client separato con il callback HTTPS di quel progetto.
4. Copia il Client ID e il Client secret nella dashboard Supabase. [Guida Google di Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)

## Supabase

1. In Authentication → Sign In / Providers → Google abilita Google. Incolla Client ID e Client secret nei campi corrispondenti e salva.
2. In Authentication → URL Configuration mantieni l’URL ufficiale del sito `https://mich369.github.io/Oculum/`. In Redirect URLs aggiungi solo gli URL delle edizioni che distribuisci:

   - `https://mich369.github.io/Oculum/` per il web.
   - `com.mich.oculum://login-callback` per Windows normale, Android, iOS e macOS.
   - `com.mich.oculum.test://login-callback` per Windows Test, se l’edizione ha l’accesso online abilitato.

   Usa localhost e gli indirizzi temporanei solo nell’ambiente di sviluppo. [Configurazione URL](https://supabase.com/docs/guides/auth/redirect-urls)
3. In Authentication → General Configuration abilita **Allow manual linking** per mostrare una procedura funzionante a chi usa già email, Apple o un profilo ospite autenticato. Prima si accede all’account esistente e poi si sceglie **Collega account Google**. Il collegamento mantiene l’ID Supabase originale. Supabase gestisce il proprio collegamento automatico quando l’email verificata coincide. Con email diverse si usa il collegamento esplicito. Un’identità già associata a un altro account produce un errore, senza trasferire schede o ruoli. [Collegamento delle identità](https://supabase.com/docs/guides/auth/auth-identity-linking)

## Verifiche in ambiente di test

Verifica prima accesso e logout sul web e su ogni app distribuita. Ripeti con una copia di un salvataggio, spuntando e deselezionando **Mantieni l’accesso su questo dispositivo**. Chiudi l’app mentre il browser è aperto e prova anche il ritorno con l’app già aperta. Controlla annullamento, sessione scaduta, riavvio offline e rientro online. Prova due account autorizzati e un terzo estraneo alla stanza. Verifica che il cambio account disconnetta dalla stanza precedente e che il collegamento con lo stesso ID conservi i permessi.

Il web conserva la sessione nel profilo del browser sullo stesso origin quando l’opzione è attiva. Le piattaforme native usano lo storage sicuro del sistema. Il logout agisce sull’autenticazione del dispositivo e conserva schede, inventari, progressi e backup locali.

## Recupero password per email

1. In Supabase, apri Authentication → Emails. In **SMTP Settings** abilita il server SMTP personalizzato e inserisci mittente, host, porta, utente e password forniti dal servizio email. Mantieni le credenziali nella dashboard. Il mittente deve essere verificato presso il servizio email. Il servizio predefinito di Supabase consegna soltanto agli indirizzi del team del progetto. [Configurazione SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
2. In **Email Templates → Reset password** conserva il collegamento `{{ .ConfirmationURL }}`. Gli indirizzi di ritorno sono quelli elencati sopra. Disattiva il tracciamento dei link presso il fornitore SMTP per evitare riscritture degli URL di conferma. [Modelli email](https://supabase.com/docs/guides/auth/auth-email-templates)
3. In Oculum, inserisci l’email e scegli **Hai dimenticato la password?**. Apri l’ultimo link ricevuto nello stesso profilo del browser per il web o nella stessa app per il desktop o il telefono. Un’altra richiesta di accesso via link può sostituire il verificatore PKCE.
4. Prova con un account di test e una copia del profilo. Controlla arrivo dell’email, link valido, link scaduto, riapertura del link usato, annullamento, doppio invio e accesso con la nuova password dopo il logout. Verifica la riapertura con **Mantieni l’accesso su questo dispositivo** attivo e disattivo.

## Profilo account

Applica la migrazione `20261114091431_oculum_account_profiles.sql` a un progetto di test prima della produzione. Il nome scelto resta fisso. Con un indirizzo verificato si può scegliere un codice pubblico univoco da 3 a 24 caratteri, con lettere, numeri, trattini e underscore. Il profilo resta associato all’UUID Supabase. La scelta del nome e del codice è indipendente da stanze e salvataggi.
