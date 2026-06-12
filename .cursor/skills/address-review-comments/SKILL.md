---
name: address-review-comments
description: Fix findings from reviews/{branch}-review.md. Lighter than spec-driven-dev — triage, fix, verify, update CONTEXT. Use when addressing PR review feedback.
---

# Address Review Comments

Input: `reviews/{branch}-review.md` from the **pr-review** skill.

## Workflow

```
1. READ    → Review file + cited source files
2. TRIAGE  → P0 BLOCKER, P1 MAJOR, P2 MINOR, P3 NIT
3. FIX     → P0/P1 first (spec update if contract changes)
4. VERIFY  → go build, vet, test
5. CONTEXT → Update CONTEXT.md; note deferred P2/P3
```

## Triage

| Priority | Fix before merge? |
|----------|-------------------|
| BLOCKER | Yes |
| MAJOR | Yes |
| MINOR | Prefer yes; can defer with note |
| NIT | Optional |

## Quality gates

```bash
go build ./...
go vet ./...
go test ./...
```

Re-run **pr-review** when the user wants an updated score.
