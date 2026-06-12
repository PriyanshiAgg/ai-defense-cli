# AI Defense CLI — Architecture

> Stub — expand when CLI source is migrated from ai-firewall-services PR #5789.

## Overview

`aid-cisco-cli` is a standalone Go binary that calls Cisco AI Defense backend APIs
(auth-manager fronts scan-manager, mcp-scanning, ai-bom). It is optimized for
interactive use and CI/CD automation.

## Components

| Package | Role |
|---------|------|
| `cmd/` | Cobra command tree: `model-scan`, `mcp-scan`, `ai-bom` |
| `internal/config` | Auth and endpoint resolution (flags > env > TOML) |
| `internal/clierror` | Exit-code contract |
| `internal/verdict` | Scan result envelope and severity thresholds |
| `internal/cmdutil` | Shared scan flags (`--fail-on`, `--block-on`, `--output`) |
| `internal/embedded/python` | Relocatable CPython + `cisco-aibom` for local analysis |
| `sdk/aidefense/` | HTTP client and service-specific APIs |
| `scripts/` | Python bundle requirements and build helpers |

## Embedded Python (AIBOM)

`ai-bom analyze` runs locally using a **relocatable CPython** embedded in the CLI binary
(not the host's system Python). The bundle includes the `cisco-aibom` analyzer and its
pinned dependencies (`scripts/requirements-bundle.txt`).

```
Go command (cmd/aibom)
  → internal/embedded/python (embed.go — extract/run embedded interpreter)
  → cisco-aibom (Python, inside bundle)
```

**Build modes:**

| Mode | Purpose |
|------|---------|
| Full embed | Release binaries; CPython + aibom packaged at build time |
| Stub (`stub.go` + build tag) | Fast `go test` / dev without full bundle download |

Embed artifacts (`internal/embedded/python/bin/`) and staging (`.build/`) are not committed.

## Build (Makefile)

| Target | `BUILD_MODE` | Embedded Python |
|--------|--------------|-----------------|
| `make build-go` | `go` (default) | No — `stub.go` (`!embed_python`) |
| `make build-embed` | `full` | Yes — `embed.go` (`embed_python`) |

```bash
make build-go test vet                    # daily dev / CI unit tests
make bundle && make build-embed           # release-style binary
make build BUILD_MODE=full                # same as build-embed
```

`make bundle` runs `scripts/build-python-bundle.sh` (relocatable CPython + `cisco-aibom[all]` from `scripts/requirements-bundle.txt`).

For local aibom dev without a full embed: `make build-go` and set `AID_CLI_PYTHON` to a venv with `cisco-aibom[all]` installed.

## Exit-code contract

| Code | Category |
|------|----------|
| 0 | Success / policy pass |
| 1 | Unexpected error |
| 2 | Usage error |
| 3 | Auth or config error |
| 4 | Connectivity / timeout |
| 5 | Scan operation failed |
| 10 | Policy fail (`--fail-on` threshold) |
| 20 | Policy block (`--block-on` threshold) |

## Release and distribution

Versioned binaries published via GitHub Releases (see `docs/install-upgrade.md` after migration).
Artifacts include per-OS/arch binaries (with embedded Python where required), `checksums.txt`,
and `manifest.json`. Release CI builds the full embed path, not stub-only.
