# Install and Upgrade

> **Placeholder** — full content will be migrated from
> [ai-firewall-services PR #5810](https://github.com/cisco-aispg/ai-firewall-services/pull/5810)
> (`aid_cli/docs/install-upgrade.md`) after the CLI source lands in this repository.

## Planned topics

- Download latest or pinned version from GitHub Releases
- Verify SHA256 checksums (`checksums.txt`)
- Install paths and `PATH` setup (Linux, macOS)
- Upgrade and rollback procedures
- CI/CD examples (pinned version, fail-on/block-on gates)
- Reading `manifest.json` for version, commit, and artifact metadata

## Until releases are available

Build from source after cloning this repository:

```bash
go build -o aid-cisco-cli .
./aid-cisco-cli version
```
