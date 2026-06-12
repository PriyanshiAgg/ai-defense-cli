#!/usr/bin/env python3
"""Extract a version section from CHANGELOG.md for GitHub Release notes."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def extract(changelog: str, version: str) -> str:
    pattern = (
        rf"^## \[{re.escape(version)}\]"
        rf"(?:\s+-\s+[^\n]*)?"
        rf"\s*\n(.*?)(?=\n## \[|\Z)"
    )
    match = re.search(pattern, changelog, re.MULTILINE | re.DOTALL)
    if not match:
        raise SystemExit(f"CHANGELOG.md has no section for [{version}]")
    body = match.group(1).strip()
    if not body:
        raise SystemExit(f"CHANGELOG.md section [{version}] is empty")
    return body


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Semver without v prefix (e.g. 0.1.1)")
    parser.add_argument(
        "--changelog",
        type=Path,
        default=Path("CHANGELOG.md"),
        help="Path to CHANGELOG.md",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Write notes to file (default: stdout)",
    )
    args = parser.parse_args()

    text = args.changelog.read_text(encoding="utf-8")
    body = extract(text, args.version)

    if args.output:
        args.output.write_text(body + "\n", encoding="utf-8")
    else:
        sys.stdout.write(body + "\n")


if __name__ == "__main__":
    main()
