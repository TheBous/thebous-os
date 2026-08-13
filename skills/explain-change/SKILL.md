---
name: explain-change
description: Explain a pull request, diff, code, implementation change, file, or arbitrary text in simple step-by-step business and technical language, using a clear visual HTML artifact instead of a wall of text, and save every produced document in the corresponding Obsidian Jira task. Use when the user asks what changed, how something works, why it was implemented, or requests an easy, graphical walkthrough.
---

# Explain Change

## Obiettivo

Spiegare un argomento in modo progressivo, leggibile e visivo. L'output deve aiutare
l'utente a capire sia il risultato di business sia come funziona l'implementazione,
senza trasformarsi in un testo lungo e non strutturato.

## Skill preferenziale

Prima di iniziare, verificare se nell'ambiente attivo è disponibile una skill chiamata
`ce-explain`, anche se esposta con namespace come `compound-engineering:ce-explain`:

- se è disponibile, invocarla sempre e seguirne il flusso completo;
- se non è disponibile, usare il flusso di questa skill;
- non eseguire entrambi i flussi in parallelo e non dichiarare di aver usato
  `ce-explain` se non è stata effettivamente invocata.

## 1. Definire l'oggetto della spiegazione

Identificare l'oggetto e raccogliere solo il contesto necessario:

- PR: titolo, descrizione, diff, file modificati, test e commenti rilevanti;
- diff o modifica locale: `git diff`, stato del repository, commit e file coinvolti;
- codice o file: contenuto esatto, chiamanti, dipendenze e punti di ingresso;
- testo o requisito: struttura, concetti, conseguenze e termini da chiarire.

Se l'oggetto è ambiguo, chiedere una sola precisazione. Non inventare intenzioni,
comportamenti, dati o motivazioni: distinguere sempre tra evidenza, inferenza e
informazione non verificata.

## 2. Costruire la spiegazione

Organizzare il materiale in questo ordine, riducendo o unendo le sezioni quando non
sono pertinenti:

1. **In una frase** — cosa stiamo guardando e qual è il risultato principale.
2. **Perché esiste** — problema o bisogno di business risolto.
3. **Prima e dopo** — cosa succedeva prima e cosa cambia dopo.
4. **Flusso step-by-step** — sequenza concreta dall'input al risultato.
5. **Implementazione tecnica** — file, funzioni, dati, stati, API, dipendenze e
   responsabilità coinvolte, con riferimenti `file:line` quando disponibili.
6. **Casi limite e rischi** — errori, autorizzazioni, dati mancanti e comportamenti
   non verificati.
7. **Verifica** — test esistenti, controlli eseguiti e cosa resta da verificare.
8. **Riassunto finale** — massimo tre messaggi da ricordare.

Per ogni step spiegare prima **cosa succede**, poi **perché**, poi **come viene
realizzato tecnicamente**. Usare frasi brevi, una sola idea per blocco e liste corte.
Espandere acronimi e termini tecnici alla prima occorrenza.

## 3. Creare l'artefatto HTML

Creare sempre almeno un file HTML autocontenuto, salvo richiesta esplicita dell'utente
di ricevere solo una risposta in chat.

1. Usare una directory temporanea dedicata, per esempio:
   `"${TMPDIR:-/tmp}/thebous-os-explain-<slug>-<timestamp>"`.
2. Per una spiegazione piccola creare `index.html`.
3. Per una feature grande creare `index.html` come indice e più pagine collegate,
   una per flusso, dominio o area tecnica. Non separare arbitrariamente ogni
   paragrafo in una pagina.
4. Se l'utente indica una directory di destinazione, usare quella directory invece
   della directory temporanea.
5. Riportare sempre il percorso assoluto degli artefatti creati e, quando il provider
   lo consente, offrire di aprire `index.html` nel browser.

### Requisiti visivi

- usare CSS inline o file locali; non dipendere da CDN, font esterni o JavaScript
  remoto;
- usare card, timeline, step numerati, callout e tabelle brevi;
- rappresentare flussi e relazioni con diagrammi inline SVG o HTML/CSS, usando frecce,
  nodi e colori coerenti;
- mostrare separatamente il percorso business e quello tecnico, collegandoli quando
  un passaggio tecnico implementa una decisione di business;
- includere snippet di codice brevi e annotati solo quando chiariscono il punto;
- mantenere una larghezza leggibile, contrasto accessibile, titoli chiari e layout
  responsive;
- non usare un unico blocco di testo lungo, un diagramma ornamentale o una visualizzazione
  che nasconda le informazioni essenziali.

L'HTML deve contenere una breve intestazione con soggetto, data, fonti consultate e
livello di certezza. Etichettare le inferenze come tali e le parti non controllate come
`Non verificato`.

## 4. Salvare tutti gli artefatti nel task Obsidian

Prima della risposta finale, identificare il task Jira corrispondente (`<KEY>`) dal
contesto della PR, del branch, del commit o della richiesta. Se il task non è
determinabile, chiedere una sola precisazione e non inventare la chiave.

Tutti i file prodotti dalla spiegazione devono essere salvati nella cartella del task,
non solo `index.html`. Questo include eventuali pagine HTML aggiuntive, CSS, immagini,
asset locali e altri file necessari a mantenere funzionante l'artefatto. Usare il
percorso standard `Dev/Tickets/<KEY>` e una sottocartella unica per ogni spiegazione:
`docs/explain-change/<slug>-<timestamp>/`. Non sovrascrivere una spiegazione precedente.

Seguire `references/obsidian-log.md` per caricare la configurazione e usare gli helper
condivisi, senza ricostruire il percorso o la logica di copia nella skill:

```bash
source "scripts/helpers.sh"
if [ -f "$ENV_FILE" ]; then load_env; fi

if [ -z "${OBSIDIAN_VAULT_PATH:-}" ] || [ ! -d "${OBSIDIAN_VAULT_PATH}" ]; then
  echo "Impossibile salvare la spiegazione: Obsidian non è configurato o il vault non esiste."
  # Chiedere all'utente di configurare il vault prima di dichiarare il lavoro completato.
else
  DEST_DIR=$(obsidian_copy_ticket_docs "${OBSIDIAN_VAULT_PATH}" "<KEY>" "explain-change/<slug>-<timestamp>" <ARTIFACT_DIR>)

  PLAN_FILE=$(obsidian_ensure_ticket_file "${OBSIDIAN_VAULT_PATH}" "<KEY>" "plan.md")
  obsidian_append_section "$PLAN_FILE" "Spiegazione visuale: [apri index.html](docs/explain-change/<slug>-<timestamp>/index.html)"
fi
```

Per gli artefatti creati da `ce-explain`, usare i percorsi restituiti da quella skill
come `<ARTIFACT_DIR>` o come insieme di file da copiare, preservando la struttura
relativa tra le pagine. Non dichiarare il salvataggio se la copia non è riuscita.

## 5. Risposta finale

Presentare in chat solo una sintesi navigabile:

- una frase di orientamento;
- da tre a sette step principali;
- il percorso assoluto all'artefatto HTML;
- eventuali punti non verificati o domande aperte.

Non incollare integralmente l'HTML in chat e non produrre un wall of text. Non modificare
il codice, la PR o documenti del repository: questa skill spiega e crea artefatti di
spiegazione, ma non implementa correzioni.
