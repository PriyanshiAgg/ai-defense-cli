# ai-defense-cli

**Cisco AI Defense CLI** (`aid-cisco-cli`)

Command-line tool for AI Defense scanning and inventory: **model-scan**, **mcp-scan**, and **ai-bom**. Designed for local development and CI/CD pipelines with deterministic exit codes and machine-readable output.

> This repository is the public home for the Go CLI previously developed in [ai-firewall-services](https://github.com/cisco-aispg/ai-firewall-services). CLI source, CI/CD, and install docs are being migrated from PRs [#5789](https://github.com/cisco-aispg/ai-firewall-services/pull/5789), [#5790](https://github.com/cisco-aispg/ai-firewall-services/pull/5790), and [#5810](https://github.com/cisco-aispg/ai-firewall-services/pull/5810).

---

## Status

| Area | Status |
|------|--------|
| Repository bootstrap | In progress (`feature/repo-bootstrap`) |
| CLI source migration | Pending |
| Release / versioned downloads | Pending (see `docs/install-upgrade.md` after migration) |
| Public GitHub releases | Pending |

See [CONTEXT.md](/CONTEXT.md) for the current migration plan.

---

## Features (planned)

- **model-scan** — trigger and retrieve AI/ML model security scans
- **mcp-scan** — register and scan MCP servers
- **ai-bom** — generate and manage AI Bill of Materials (embedded analyzer)
- **Deterministic exit codes** — operational failures (1–5) vs policy verdicts (10, 20)
- **CI-friendly output** — JSON verdict envelope, `--fail-on` / `--block-on` thresholds
- **Versioned releases** — pinned downloads with checksum verification

---

## Installation

Installation and upgrade instructions (versioned downloads, checksums, rollback) will be documented in:

- [docs/install-upgrade.md](docs/install-upgrade.md) *(after CLI migration)*

For now, build from source once the Go module is present:

```bash
git clone https://github.com/cisco-ai-defense/ai-defense-cli.git
cd ai-defense-cli
go build -o aid-cisco-cli .
```

---

## Quick start

```bash
# Configure (flags > env > TOML)
export AIDEFENSE_API_KEY="your-api-key"
export AIDEFENSE_BASE_URL="https://your-region.ai.defense.cisco.com"

# Example (after migration)
aid-cisco-cli model-scan trigger --model-uri "hf://org/model"
aid-cisco-cli model-scan result --scan-id <id> --output json
```

---

## Repository layout (target)

```
cmd/              # Cobra command groups
internal/         # config, exit codes, verdict, embedded Python
sdk/aidefense/    # AI Defense HTTP client
docs/             # specs, install, getting started
.github/workflows/  # build, test, release
```

---

## Development

```bash
make build-go          # Go CLI only (stub embedded Python)
make test vet

# Full CLI with embedded cisco-aibom (release-style):
make bundle build-embed
```

See `Makefile` and `scripts/README.md` for build modes (`BUILD_MODE=go|full`).

The CLI is primarily Go and embeds a relocatable CPython runtime for local AIBOM analysis (`cisco-aibom`). See `docs/architecture/ai-defense-cli.md` for details.

---

## Related projects

- [ai-defense-python-sdk](https://github.com/cisco-ai-defense/ai-defense-python-sdk) — Python SDK for AI Defense APIs

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [SECURITY.md](SECURITY.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
