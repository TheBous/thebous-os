---
name: serve-down
description: Stop and clean up the local service started by serve-up — compose stack, container, or background dev process
---

## Goal

Tear down whatever `serve-up` started and confirm the port is actually free. Detection mirrors `serve-up`, so no state has to be carried between the two.

## Steps

### 1. Find what is running

Check each source; more than one may match if the project was started several ways:

| Check | Command | Means |
|---|---|---|
| compose stack | `docker compose ps -q 2>/dev/null` | non-empty output → a stack is up |
| container | `docker ps -q -f name=jira-git-sync-serve` | non-empty output → the container is up |
| dev process | `cat /tmp/jira-git-sync-serve.pid 2>/dev/null` | a pid file exists |

If nothing matches, check the port directly before declaring there's nothing to do:
```bash
lsof -ti :<PORT>
```
A hit here means something is listening that `serve-up` did not start. Report it and stop — **do not kill a process this workflow didn't start.**

### 2. Stop it

Run the teardown for each source that matched.

**compose** — `down` also removes the network and the dependency containers:
```bash
docker compose down
```

**docker**
```bash
docker stop jira-git-sync-serve && docker rm jira-git-sync-serve
```

**node** — check the pid is alive before signalling, a stale pid file can point at an unrelated process:
```bash
PID=$(cat /tmp/jira-git-sync-serve.pid)
kill -0 "$PID" 2>/dev/null && kill "$PID"
rm -f /tmp/jira-git-sync-serve.pid
```

### 3. Verify the port is free

Stopping is not the same as stopped — confirm it:
```bash
lsof -ti :<PORT>
```

Empty output means the teardown worked. If something is still listening, report what it is and ask the user how to proceed rather than escalating to `kill -9` on your own.

### 4. Ask about volumes (compose only)

Only when a compose stack was torn down and it declares named volumes:
```bash
grep -A5 '^volumes:' docker-compose.yml 2>/dev/null
```

If any exist, ask:
```
The stack has named volumes (database data persists across restarts).
Remove them too? This deletes local data. (yes/no)
```

Run `docker compose down -v` **only** on an explicit yes. Default to keeping the data.

### 5. Confirmation

Show the user:
- Stopped: `<compose stack | container | dev process>`
- Port `<PORT>`: free
- Volumes: kept / removed (only if step 4 ran)

## Common pitfalls to avoid

- Don't run `docker compose down -v` by default — it wipes the local database, and the user rarely wants that just to stop a service.
- Don't kill a process on the port that `serve-up` didn't start. Report it instead.
- Don't trust a pid file without `kill -0`. The pid may have been recycled by an unrelated process.
- Don't skip step 3. `docker stop` can time out, and reporting "stopped" on an unverified teardown sends the user into a confusing port conflict on the next `serve-up`.
