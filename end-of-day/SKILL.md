---
name: end-of-day
description: Genera il recap di fine giornata dell'utente su richiesta o quando gira come task schedulato serale - riassume il lavoro di oggi dalla daily note Obsidian (o da GitHub/Jira se la daily note non c'è), e riporta le sessioni Claude Code e OpenCode toccate oggi con titolo e progetto. Usa SEMPRE questa skill quando l'utente dice "fine giornata", "recap di oggi", "cosa ho fatto oggi", "com'è andata la giornata", "riepilogo giornaliero", "end of day", "run end of day", o quando viene invocata dal task schedulato serale - anche se non nomina esplicitamente Obsidian/GitHub/sessioni, perché il punto della skill è mettere tutto insieme.
---

# End of Day Recap

Il contrario della morning-briefing: invece di guardare avanti (PR da revieware,
scadenze), guarda indietro a cosa è successo oggi. Due dimensioni distinte, non
confonderle nell'output:
1. **Lavoro svolto** — cosa hai fatto (branch, PR, review, task Jira)
2. **Attività AI** — su quali sessioni Claude Code/OpenCode hai lavorato oggi, e dove

## Configurazione (solo la prima volta)

Stessa idea di morning-briefing, salvata in `${CLAUDE_PLUGIN_DATA}/.env`:

```
OBSIDIAN_VAULT_PATH=<path assoluto del vault Obsidian — vuoto = niente lettura/scrittura Obsidian>
GITHUB_REPOS=<lista separata da virgole — vuoto = tutti i repo a cui l'utente ha accesso, usato solo come fallback>
```

Se il file non esiste, chiedi questi due valori (entrambi opzionali) e salvali:

```bash
mkdir -p "${CLAUDE_PLUGIN_DATA}"
cat > "${CLAUDE_PLUGIN_DATA}/.env" <<EOF
OBSIDIAN_VAULT_PATH=<valore o vuoto>
GITHUB_REPOS=<valore o vuoto>
EOF
```

Altrimenti caricalo:
```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

## Step 1: Finestra di oggi

```bash
export TZ="Europe/Rome"
TODAY=$(date +%Y-%m-%d)
TODAY_START_ISO=$(date -v0H -v0M -v0S -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "today 00:00" -u +%Y-%m-%dT%H:%M:%SZ)
```

## Step 2: Lavoro di oggi — Obsidian, con fallback

Se `OBSIDIAN_VAULT_PATH` è configurata, cerca `Dev/Daily/<TODAY>.md`:

```bash
DAILY_NOTE="${OBSIDIAN_VAULT_PATH}/Dev/Daily/${TODAY}.md"
[ -f "$DAILY_NOTE" ] && cat "$DAILY_NOTE"
```

Se il file esiste e ha contenuto oltre al solo header (`# <data>`), quello **è**
il riepilogo del lavoro di oggi — i comandi thebous-jira-git-sync (new-branch,
cook, review-pr, address-review, create-pr) ci scrivono già durante il giorno.
Non serve altro: presentalo riorganizzato in un elenco leggibile, non incollarlo
grezzo.

**Fallback** (Obsidian non configurato, file assente, o solo l'header senza
contenuto — significa che oggi non hai usato nessun comando thebous-jira-git-sync,
non che non hai lavorato): query dirette, stesso stile di morning-briefing.

```bash
REPO_FILTER=""
if [ -n "${GITHUB_REPOS:-}" ]; then
  REPO_FILTER=$(echo "$GITHUB_REPOS" | tr ',' '\n' | sed 's/^/--repo=/' | tr '\n' ' ')
fi
gh search prs --author=@me --created=">=${TODAY}" $REPO_FILTER --json number,title,url,repository,state --limit 30
gh search prs --author=@me --merged-at=">=${TODAY}" $REPO_FILTER --json number,title,url,repository --limit 30
```

Per Jira, stesso `cloudId` da risolvere come in morning-briefing
(`getAccessibleAtlassianResources`), poi:

```
jql: assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC
fields: ["summary", "status", "project"]
```

## Step 3: Sessioni Claude Code di oggi

Usa `list_sessions` (limit alto, es. 50) e tieni solo quelle con
`lastActivityAt` nella data di oggi (confronta solo la parte `YYYY-MM-DD` di
`lastActivityAt` con `$TODAY` — è un timestamp ISO in UTC, per uso quotidiano
personale il confronto sulla sola data è sufficientemente preciso, non serve
convertire fusi orari per un recap).

**Nota**: `list_sessions` esclude sempre la sessione corrente (quella che sta
girando il recap in questo momento) — è previsto, la sessione del recap stesso
non è "lavoro fatto oggi" da riportare.

Per ogni sessione trovata, mostra `title` (se assente, usa `sessionId`
troncato) e `cwd`.

## Step 4: Sessioni OpenCode di oggi

```bash
if [ -n "${OPENCODE_BIN:-}" ] || command -v opencode >/dev/null 2>&1; then
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/opencode_sessions_today.sh"
fi
```

Lo script è autosufficiente: avvia un server OpenCode temporaneo su una porta
libera, interroga `/api/session`, filtra per oggi, lo spegne. Ritorna `[]`
(non un errore) se OpenCode non è installato — è una fonte opzionale, la sua
assenza non deve bloccare il resto del recap.

Per ogni sessione nell'array risultante, mostra `title`, `location.directory`,
e se vuoi anche `cost`/`tokens` per un rapido senso di quanto è stata pesante.
Ordina per `time.updated` decrescente (le più recenti prima).

## Step 5: Componi il report

```markdown
# 🌙 End of Day Recap — <TODAY>

## 📋 Lavoro di oggi
<contenuto della daily note riorganizzato, oppure risultati del fallback>

## 🤖 Sessioni Claude Code
- <titolo o sessionId troncato> — <cwd>

## 💻 Sessioni OpenCode
- <titolo> — <location.directory>
```

Se una sezione non ha risultati, scrivi "Nessuna" — non saltarla. Mostra in
chat, in italiano.

## Step 6: Salva nella daily note di Obsidian (solo se configurato)

Stesso script bundled di morning-briefing (append, mai sovrascrive):

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/append_daily_note.sh" "${OBSIDIAN_VAULT_PATH}" "<percorso del file con il report generato allo step 5>"
fi
```

## Step 7: Conferma finale

Una riga sola: `📓 Salvato anche in Obsidian` o `📓 Obsidian non configurato — solo qui in chat`.
