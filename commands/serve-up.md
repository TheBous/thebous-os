---
description: Detect how this project runs (docker compose, Dockerfile, or package.json) and start it in the background on localhost so the current change can be tested
---

## Goal

Bring the project up on localhost to test what was just implemented, without the user having to know or type the run command. Detection is automatic; the service starts **detached** so the session stays usable — this workflow must never block on a foreground process.

Pairs with `serve-down`, which tears down whatever this workflow started.

## Steps

### 1. Detect the runtime

Check the repo root in this order and stop at the first match:

```bash
ls docker-compose.yml docker-compose.yaml compose.yml compose.yaml Dockerfile package.json 2>/dev/null
```

| Found | Runtime | Why it wins |
|---|---|---|
| any compose file | **compose** | It orchestrates the app *plus* its dependencies (db, cache) — always prefer it over a bare Dockerfile |
| `Dockerfile` only | **docker** | Single container, build then run |
| `package.json` with a `dev` or `start` script | **node** | No containers in this project |
| none of the above | — | Stop and ask the user how the project is started |

For the **node** runtime, read the scripts to pick one:
```bash
grep -A20 '"scripts"' package.json
```
Prefer `dev` over `start`. If both are missing, ask the user.

### 2. Resolve the port

| Runtime | Where to read it |
|---|---|
| compose | the `ports:` mapping of the app service — take the **host** side of `"HOST:CONTAINER"` |
| docker | `grep EXPOSE Dockerfile` — publish it as `-p PORT:PORT` |
| node | a `-p`/`--port` flag in the script, else `PORT` in `.env`, else the framework default (Next/Nest/CRA `3000`, Vite `5173`, Astro `4321`) |

Also check for an override:
```bash
grep -s '^PORT=' .env .env.local 2>/dev/null
```

If the port still can't be determined, ask the user instead of guessing.

### 3. Preflight

For docker runtimes, confirm the daemon is up:
```bash
docker info >/dev/null 2>&1 || echo "Docker daemon is not running"
```
If it isn't, tell the user to start Docker Desktop and stop here.

Check the port is free:
```bash
lsof -ti :<PORT>
```
If something is already listening, show the user what it is and ask whether to reuse it, pick another port, or run `serve-down` first. **Do not kill a foreign process.**

### 4. Start detached

Run the command for the detected runtime. Every path is background — never foreground.

**compose**
```bash
docker compose up -d --build
```

**docker** — the fixed container name is what makes `serve-down` stateless, always use it:
```bash
docker build -t jira-git-sync-serve . && \
docker run -d --name jira-git-sync-serve -p <PORT>:<PORT> jira-git-sync-serve
```

**node** — detach and record the pid so `serve-down` can find it:
```bash
nohup npm run <script> > /tmp/jira-git-sync-serve.log 2>&1 &
echo $! > /tmp/jira-git-sync-serve.pid
```

### 5. Wait until it answers

Poll instead of assuming it booted:
```bash
curl -sf --retry 30 --retry-delay 1 --retry-connrefused -o /dev/null "http://localhost:<PORT>"
```

If it never answers, show the logs and stop — do not report success:
```bash
docker compose logs --tail 50    # compose
docker logs --tail 50 jira-git-sync-serve    # docker
tail -50 /tmp/jira-git-sync-serve.log        # node
```

### 6. Report the URLs

Resolve the LAN address so the service is reachable from a phone on the same network:
```bash
ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}'
```

Show the user:
```
🚀 Service up (<runtime>)
   Local:   http://localhost:<PORT>
   Network: http://<LAN_IP>:<PORT>
   Logs:    <log command from step 5>

→ Tear it down with /thebous-jira-git-sync:serve-down
```

## Common pitfalls to avoid

- Don't start in the foreground. A blocking process makes the session unusable — this matters most on mobile, where the user can't send an interrupt.
- Don't prefer a bare `Dockerfile` when a compose file exists — you'd start the app without its database.
- Don't report success on the start command's exit code alone. A container that exits one second later still returns 0 from `docker run -d`; only step 5's poll proves it's serving.
- Don't kill whatever already holds the port. Ask first.
- Don't rename the `jira-git-sync-serve` container — `serve-down` looks it up by that exact name.
