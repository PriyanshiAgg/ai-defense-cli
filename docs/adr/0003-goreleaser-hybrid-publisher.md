# ADR 0003: GoReleaser OSS as a hybrid release publisher

## Status

Accepted (2026-07-31)

## Context

The CLI release workflow already produces three platform-specific binaries:
Linux amd64 through Docker and macOS amd64/arm64 on native runners. Each binary
contains a relocatable CPython distribution and `cisco-aibom`, so the build is not
a normal pure-Go cross-compile.

GoReleaser can standardize GitHub Release publication, but its prebuilt importer
and split/merge support are Pro-only. Replacing all existing builds with one OSS
GoReleaser matrix would either require cross-platform embedded-Python artifacts or
change the proven release build path.

## Decision

Use GoReleaser OSS as the final publisher while retaining the existing build and
metadata jobs:

1. Keep Make/Docker/native platform builds and smoke tests authoritative.
2. Keep `checksums.txt`, `manifest.json`, and curated release-note generation.
3. Configure GoReleaser with a skipped build, disabled checksum generation, and
   `release.extra_files` for the exact five existing release artifacts.
4. Use a GoReleaser dist directory outside `dist/`, allowing `release --clean`
   without deleting the downloaded artifacts.
5. Pin the GoReleaser binary version in CI and grant `contents: write` only to the
   final publish job.

## Consequences

- Public artifact names, checksums, manifest schema, release notes, and the
  self-update contract remain unchanged.
- GoReleaser owns GitHub Release creation/upload but does not yet own compilation,
  packaging, checksums, signing, or SBOM generation.
- The workflow uses only GoReleaser OSS. No license secret or long-lived GitHub
  token is introduced.
- A future end-to-end GoReleaser migration must first prove embedded-Python parity
  and choose between Pro split/merge/prebuilt support and a redesigned build.
- Rollback is limited to restoring the previous GitHub Release publisher step;
  build artifacts and metadata generation are unaffected.

## Alternatives considered

| Option | Pros | Cons |
|--------|------|------|
| GoReleaser OSS single-runner build | One release command | Cannot safely produce all target-native Python bundles today |
| GoReleaser Pro split/merge or prebuilt | Full artifact lifecycle across runners | Paid license and secret; procurement/operations overhead |
| Keep the custom publisher | No change | Does not integrate GoReleaser or centralize release configuration |
| **GoReleaser OSS hybrid publisher (chosen)** | Low-risk integration; preserves contracts; no license | Build/checksum ownership remains custom |

## References

- Spec 003 REQ-10
- `docs/install-upgrade.md`
- <https://goreleaser.com/customization/publish/scm/>
- <https://goreleaser.com/customization/builds/builders/prebuilt/>
- <https://goreleaser.com/customization/general/partial/>
