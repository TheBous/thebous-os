---
name: morning-briefing
description: Genera il briefing mattutino dell'utente su richiesta o quando gira come task schedulato delle 9:00 - copre PR GitHub da revieware richieste durante la notte, PR review ancora aperte da prima, nuovi commenti sulle PR aperte dall'utente, task Jira in scadenza nei prossimi 3 giorni, task Jira che iniziano oggi, e gli impegni/call del giorno dal calendario. Usa SEMPRE questa skill quando l'utente dice "buongiorno", "situazione della giornata", "cosa ho oggi", "com'è la giornata", "briefing mattutino", "morning briefing", "run morning briefing", "riassunto di ieri e oggi", o quando viene invocata dal task schedulato giornaliero - anche se l'utente non nomina esplicitamente PR/Jira/calendario, perché il punto della skill è raccogliere tutto per lui.
---

# Morning Briefing

Raccoglie in un colpo solo lo stato di sei fonti (PR GitHub in due direzioni, commenti,
scadenze Jira, task Jira in partenza, calendario) e presenta un unico report. Non è un
riassunto generico: ogni sezione ha una fonte dati precisa e una finestra temporale
precisa — segui gli step così come sono, non improvvisare query diverse da quelle qui sotto.

## Configurazione (solo la prima volta)

Questa skill ha bisogno di due valori, salvati in `${CLAUDE_PLUGIN_DATA}/.env`:

```
GITHUB_REPOS=<lista separata da virgole, es. TheBous/thebous-os,TheBous/altro-repo — vuoto = tutti i repo a cui l'utente ha accesso>
OBSIDIAN_VAULT_PATH=<path assoluto del vault Obsidian — vuoto = non salvare la daily note>
```

Se il file non esiste ancora, chiedi questi due valori all'utente (uno alla volta, entrambi
opzionali — invio vuoto è una risposta valida), poi salvali:

```bash
mkdir -p "${CLAUDE_PLUGIN_DATA}"
cat > "${CLAUDE_PLUGIN_DATA}/.env" <<EOF
GITHUB_REPOS=<valore o vuoto>
OBSIDIAN_VAULT_PATH=<valore o vuoto>
EOF
```

Se il file esiste già, caricalo e basta:
```bash
source "${CLAUDE_PLUGIN_DATA}/.env"
```

## Step 1: Calcola le finestre temporali

Tutto è in fuso `Europe/Rome`. Calcola una sola volta e riusa questi valori in tutti gli step:

```bash
export TZ="Europe/Rome"
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date +%Y-%m-%d)
# Finestra "notte": da ieri 20:00 a adesso. Usata sia per le review richieste
# a te sia per i nuovi commenti sulle tue PR (stessa finestra per entrambe).
NIGHT_START_ISO=$(date -v-1d -v20H -v0M -v0S -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -d "yesterday 20:00" -u +%Y-%m-%dT%H:%M:%SZ)
# Finestra "prossimi 3 giorni" per le scadenze Jira: oggi, domani, dopodomani.
DUE_END=$(date -v+2d +%Y-%m-%d 2>/dev/null || date -d "+2 days" +%Y-%m-%d)
# Soglia per lo step 3: ignora le tue PR aperte non toccate da 14+ giorni (repo
# vecchi/personali accumulano PR di bot tipo Snyk che non interessano mai a nessuno).
STALE_PR_CUTOFF=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d "-14 days" +%Y-%m-%d)
```

(Il doppio comando con `||` copre sia `date` di macOS/BSD sia quello GNU/Linux — usa
quello che funziona sul sistema, non serve capire quale sei, prova il primo e se fallisce
il secondo scatta da solo.)

## Step 2: PR review — richieste a te

```bash
REPO_FILTER=""
if [ -n "${GITHUB_REPOS:-}" ]; then
  REPO_FILTER=$(echo "$GITHUB_REPOS" | tr ',' '\n' | sed 's/^/--repo=/' | tr '\n' ' ')
fi
gh search prs --review-requested=@me --state=open $REPO_FILTER \
  --json number,title,url,repository,createdAt --limit 50
```

Questa lista contiene **tutte** le PR dove sei ancora un reviewer richiesto (GitHub ti
toglie da questa lista automaticamente appena sottometti una review — quindi tutto ciò
che compare qui è, per definizione, "non ancora chiuso da te").

Per ciascuna PR, scopri **quando** ti è stata chiesta la review (non basta `createdAt`
della PR, che è quando è stata aperta — a volte la review viene richiesta molto dopo):

```bash
gh api repos/<owner>/<repo>/issues/<number>/timeline --paginate \
  --jq '.[] | select(.event == "review_requested") | select(.requested_reviewer.login == "<tuo-username>") | .created_at' \
  | tail -1
```

(`tail -1` prende la richiesta più recente, se te l'hanno richiesta più volte.)

Dividi le PR in due gruppi confrontando quel timestamp con `NIGHT_START_ISO`:
- **Richieste stanotte**: timestamp >= `NIGHT_START_ISO`
- **Ancora in sospeso da prima**: timestamp < `NIGHT_START_ISO` (le hai già viste ieri o
  prima, non le hai ancora chiuse)

Se `gh api .../timeline` non trova nessun evento `review_requested` per una PR (capita se
la richiesta è arrivata da un team, non da un utente singolo), mettila nel gruppo "ancora
in sospeso da prima" per default — meglio segnalarla come vecchia che perderla.

## Step 3: Nuovi commenti sulle PR che hai aperto tu

```bash
gh search prs --author=@me --state=open --updated=">=${STALE_PR_CUTOFF}" $REPO_FILTER \
  --json number,title,url,repository --limit 50
```

Il filtro `--updated` è importante: senza, questa ricerca torna anche PR di anni fa (spesso
bot come Snyk su repo vecchi/personali) che nessuno commenterà mai più — controllarle ogni
mattina è tempo sprecato e chiamate API inutili. Limitarsi alle PR toccate di recente
tiene la lista pertinente senza dover mantenere un elenco manuale.

Per ciascuna, controlla commenti e review arrivati nella stessa finestra notturna
(`NIGHT_START_ISO` → adesso), scritti da qualcun altro (non da te):

```bash
gh api repos/<owner>/<repo>/issues/<number>/comments \
  --jq --arg since "$NIGHT_START_ISO" --arg me "<tuo-username>" \
  '.[] | select(.created_at >= $since) | select(.user.login != $me) | {author: .user.login, body, url: .html_url}'

gh api repos/<owner>/<repo>/pulls/<number>/comments \
  --jq --arg since "$NIGHT_START_ISO" --arg me "<tuo-username>" \
  '.[] | select(.created_at >= $since) | select(.user.login != $me) | {author: .user.login, body, url: .html_url}'

gh api repos/<owner>/<repo>/pulls/<number>/reviews \
  --jq --arg since "$NIGHT_START_ISO" --arg me "<tuo-username>" \
  '.[] | select(.submitted_at >= $since) | select(.user.login != $me) | select(.body != "") | {author: .user.login, state, body, url: .html_url}'
```

Tieni solo le PR che hanno almeno un risultato in una di queste tre chiamate.

## Step 4: Task Jira in scadenza (oggi, domani, dopodomani)

Prima risolvi il `cloudId` una sola volta (serve a tutte le chiamate Jira di questo step
e del prossimo): usa lo strumento MCP `getAccessibleAtlassianResources` e prendi l'`id`
del sito Jira dell'utente (se ce n'è uno solo, è quello; se ce ne sono più, chiedi
all'utente quale usare — succede raramente, ma non indovinare).

Poi cerca con `searchJiraIssuesUsingJql`:

```
jql: assignee = currentUser() AND duedate >= startOfDay() AND duedate <= "<DUE_END> 23:59" AND statusCategory != Done ORDER BY duedate ASC
fields: ["summary", "duedate", "status", "project"]
```

`statusCategory != Done` esclude i task già chiusi che magari hanno ancora una duedate
passata/futura ma non ti interessano più.

## Step 5: Task Jira che iniziano oggi

```
jql: assignee = currentUser() AND "Start date" = startOfDay() ORDER BY key ASC
fields: ["summary", "status", "project"]
```

**Nota**: il campo "Start date" è un custom field e il nome esatto dipende da come è
configurata la Jira dell'utente — su alcune istanze si chiama diversamente o non esiste
proprio. Se questa query fallisce con un errore di campo non riconosciuto, prova a
listare i campi disponibili (`getJiraIssueTypeMetaWithFields` su un ticket recente) e
chiedi all'utente quale campo usa per la data di inizio, poi aggiorna questo file con il
nome corretto una volta scoperto — è più veloce chiederlo una volta che indovinare ogni
mattina.

## Step 6: Impegni/call di oggi

Usa lo strumento MCP calendario (`list_events` sul calendario primario, nessun
`calendarId` esplicito), con:
- `startTime`: oggi a mezzanotte, ISO, fuso Europe/Rome
- `endTime`: domani a mezzanotte, ISO, fuso Europe/Rome
- `orderBy`: `startTime`

Il calendario dell'utente contiene sia vere call sia promemoria personali che lui stesso
si crea (es. "Paga affitto", "Scrivi a X per Y") — questi ultimi non hanno altri
partecipanti né un link videocall e non vanno mai mostrati come "chiamate". Tieni solo
gli eventi che soddisfano **almeno una** di queste condizioni:
- hanno un `conferenceUrl` (Meet/Zoom/Teams), oppure
- hanno più di un partecipante (`attendees.length > 1` — cioè oltre all'utente stesso
  c'è almeno un altro invitato)

Per ciascun evento tenuto, mostra titolo, orario di inizio/fine, e il `conferenceUrl` se
presente.

## Step 7: Componi il report

Usa esattamente questa struttura (se una sezione non ha risultati, scrivi "Nessuna" — non
saltare la sezione, l'utente deve sapere che è stata controllata):

```markdown
# 🌅 Morning Briefing — <TODAY>

## 🌙 PR review richieste stanotte
- [<repo>#<num>] <titolo> — <url>

## ⏳ PR review ancora in sospeso da prima
- [<repo>#<num>] <titolo> — richiesta il <data> — <url>

## 💬 Nuovi commenti sulle tue PR
- [<repo>#<num>] <titolo> — <autore>: "<estratto breve>" — <url>

## 📅 Task Jira in scadenza (oggi–dopodomani)
- <KEY> <summary> — scade <duedate> — <status>

## 🚀 Task Jira che iniziano oggi
- <KEY> <summary> — <status>

## 📞 Impegni di oggi
- <HH:MM>–<HH:MM> <titolo> <link se presente>
```

Mostra questo report in chat, nella lingua dell'utente (italiano).

## Step 8: Salva nella daily note di Obsidian (solo se configurato)

Se `OBSIDIAN_VAULT_PATH` è impostata e la cartella esiste, appendi il report di sopra
alla daily note di oggi usando lo script già pronto (crea la nota se non esiste,
non sovrascrive mai contenuto esistente — se lanci il briefing due volte in un giorno,
trovi due sezioni, non una sovrascritta):

```bash
if [ -n "${OBSIDIAN_VAULT_PATH:-}" ] && [ -d "${OBSIDIAN_VAULT_PATH}" ]; then
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/append_daily_note.sh" "${OBSIDIAN_VAULT_PATH}" "<percorso del file con il report generato allo step 7>"
fi
```

Se `OBSIDIAN_VAULT_PATH` non è configurata, salta questo step senza dirlo come se fosse
un errore — è una scelta valida non salvare nulla.

## Step 9: Conferma finale

Dopo aver mostrato il report, aggiungi una riga sola:
- `📓 Salvato anche in Obsidian` (se lo step 8 ha scritto qualcosa)
- oppure `📓 Obsidian non configurato — solo qui in chat` (se non era configurato)
