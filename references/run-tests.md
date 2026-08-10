# How to run the project's tests

Look for available test runners in the project in this order:

**JavaScript/TypeScript** — read `package.json` and collect all scripts whose name contains `test`, `lint`, `check`, or `typecheck`:
```bash
cat package.json | python3 -c "
import sys, json
scripts = json.load(sys.stdin).get('scripts', {})
for k, v in scripts.items():
    if any(w in k for w in ['test', 'lint', 'check', 'typecheck']):
        print(k)
"
```

**Fallback** — if there's no `package.json`, check in order:
- `Makefile`: look for `test`, `lint`, `check` targets with `grep -E '^(test|lint|check):' Makefile`
- `pyproject.toml` / `setup.py`: use `pytest`
- `go.mod`: use `go test ./...`

Run all the scripts found. If one fails:
- Analyze the error output
- Fix the code
- Rerun only the failed script
- Repeat until it passes (max 3 attempts per script, then report the failure to the user)
