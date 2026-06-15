# Hostare il relay online di Oculum

Il relay è il piccolo server che permette a Master e giocatori di connettersi anche da reti diverse.

## Prova locale sul tuo PC

1. Avvia `tool/hosting/AVVIA_RELAY_LOCALE.cmd`.
2. Nell'app, come server relay usa:

```text
ws://IP_DEL_TUO_PC:8787
```

Funziona fuori casa solo se apri/inoltri la porta `8787` del router verso il tuo PC. Per usarlo sempre con amici da reti diverse è meglio un VPS o hosting Docker.

## Hosting Docker su VPS

Sul server:

```bash
docker build -f Dockerfile.relay -t oculum-relay .
docker run -d --name oculum-relay --restart unless-stopped -p 8787:8787 -e PORT=8787 oculum-relay
```

Nell'app usa:

```text
ws://IP_DEL_SERVER:8787
```

Se metti un reverse proxy con HTTPS, usa invece:

```text
wss://tuo-dominio.it
```

## Hosting con Docker Compose

```bash
docker compose -f docker-compose.relay.yml up -d --build
```

## Hosting Fly.io

1. Copia `fly.relay.toml.example` in `fly.toml`.
2. Cambia `app = "oculum-relay"` con un nome unico.
3. Esegui:

```bash
fly launch --no-deploy
fly deploy
```

Nell'app usa l'URL `wss://NOME-APP.fly.dev`.

## Hosting Render

1. Carica il progetto su GitHub.
2. Crea un Web Service Docker.
3. Usa `Dockerfile.relay`.
4. Render deve usare la variabile `PORT`, già supportata dal relay.

Nell'app usa l'URL `wss://...onrender.com`.

## Dentro l'app

Master:

1. Vai su `Online`.
2. Inserisci il server relay.
3. Premi `Crea stanza rapida`.
4. Manda ai giocatori l'invito copiato automaticamente.

Giocatore:

1. Copia l'invito ricevuto.
2. Vai su `Online`.
3. Premi `Incolla invito ed entra`.
