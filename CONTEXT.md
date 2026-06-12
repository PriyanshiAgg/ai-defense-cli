# AI Defense CLI — Project Context

Last updated: 2026-06-12

## Purpose

**ai-defense-cli** is the public open-source repository for the Cisco AI Defense
command-line tool (`aid-cisco-cli`). It answers:

- How clients **download** the CLI (versioned releases, checksums, platforms)
- How they **upgrade** or **pin** versions in CI/CD
- How to run **model-scan**, **mcp-scan**, and **ai-bom** with deterministic exit codes

This repo contains **CLI code only** — no UI, database, or backend services.

## Migration source

CLI work currently lives in the internal monorepo
[ai-firewall-services](https://github.com/cisco-aispg/ai-firewall-services) on branch stack:

| PR | Content | Monorepo path |
|----|---------|---------------|
| [#5789](https://github.com/cisco-aispg/ai-firewall-services/pull/5789) | Go CLI source, SDK, docs, Dockerfile | `aid_cli/` |
| [#5790](https://github.com/cisco-aispg/ai-firewall-services/pull/5790) | CI/CD, release workflows, bake files | `.github/workflows/`, `builder/`, `Makefile` |
| [#5810](https://github.com/cisco-aispg/ai-firewall-services/pull/5810) | Install/upgrade docs | `aid_cli/docs/install-upgrade.md` |

**Target:** flatten or preserve `aid_cli/` layout at repo root (decision pending during migration).

## Repository structure (current)

```
.cursor/rules/        # Always-on: cli-project, go-cli, embedded-python
.cursor/skills/       # spec-driven-dev, debug-and-fix, pr-review, address-review-comments
.cursor/plans/        # Local Plan Mode output (gitignored)
.github/prompts/      # Five CLI-focused review personas
docs/
  architecture/       # (stub) ai-defense-cli.md
  specs/              # (stub) CLI requirements and design
Makefile, scripts/    # build-go vs build-embed; Python bundle script
LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
CONTEXT.md            # This file
README.md
```

## CLI architecture (from source PR)

- **Commands:** `model-scan`, `mcp-scan`, `ai-bom` (Cobra)
- **Config:** flags > env > TOML; tenant-scoped auth header for AI Defense APIs
- **Exit codes:** `internal/clierror` — ops 1–5, policy 10 (fail) / 20 (block)
- **Output:** `internal/verdict` unified JSON/text envelope; `--fail-on` / `--block-on`
- **SDK:** `sdk/aidefense/` HTTP clients for scan-manager, mcp-scanning, ai-bom
- **Embedded Python:** relocatable CPython + packaged `cisco-aibom` in `internal/embedded/python/` (stub build for tests without full bundle)

## What needs to be done next

- [x] Bootstrap repo on `feature/repo-bootstrap` (OSS files, rules, skills, review personas)
- [ ] Migrate CLI source from PR #5789
- [ ] Adapt CI/CD from PR #5790 (standalone workflows; drop monorepo Jenkins/bake deps)
- [ ] Add install/upgrade docs from PR #5810
- [ ] Create `go.mod` at repo root (module: `github.com/cisco-ai-defense/ai-defense-cli`)
- [ ] Add GitHub Actions: test, build matrix, release with versioned artifacts + checksums
- [ ] Publish first public release and document download URLs in `docs/install-upgrade.md`
- [ ] Fill `docs/specs/` and `docs/architecture/ai-defense-cli.md`

## Conventions

- **Branching:** feature branches off `main`; avoid direct commits to `main`
- **Rules:** `.cursor/rules/` (project + Go + embedded Python); plans stay local (`.cursor/plans/` gitignored)
- **Specs first:** `.cursor/skills/spec-driven-dev` (persona gates after SPEC and after IMPLEMENT)
- **Final review:** `.cursor/skills/pr-review` before merge (full branch PRS)
- **Fix review feedback:** `.cursor/skills/address-review-comments`
- **Versioning:** semantic versioning; breaking CLI contract = major bump

## References

- Public SDK (OSS template): [ai-defense-python-sdk](https://github.com/cisco-ai-defense/ai-defense-python-sdk)
- Internal CLI PR stack: #5789 → #5790 → #5810 on ai-firewall-services
