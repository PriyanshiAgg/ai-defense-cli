Synthesize persona reviews into one advisory report.

## Personas and weights (sum = 100)

| Persona | Weight |
|---------|--------|
| Engineer | 25 |
| Security | 25 |
| CLI Contract | 20 |
| Release | 15 |
| Docs | 15 |

## PRS

```
PRS = Σ(score × weight) / 5
```

Scores are 0–5 per persona. PRS is 0–100.

## Readiness bands

| Band | PRS |
|------|-----|
| Ready | 85–100 |
| Needs work | 70–84 |
| Not ready | < 70 |

## Hard gate

**Not ready** if any persona scores 0 or reports a BLOCKER finding.

## Report sections

1. **Summary** — what changed (2–4 sentences)
2. **PRS table** — persona, score, weight, weighted contribution
3. **Readiness** — band + hard-gate status
4. **Must fix** — BLOCKER and MAJOR (deduplicated)
5. **Should fix** — MINOR
6. **Praise** — optional, brief
7. **Persona details** — one subsection per persona

Deduplicate findings across personas. Cite primary persona; note `(also: X)` for duplicates.
