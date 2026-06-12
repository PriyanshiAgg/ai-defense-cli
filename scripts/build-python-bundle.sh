#!/usr/bin/env bash
# Build relocatable CPython + cisco-aibom[all] and stage embed artifacts for Go.
#
# Output (gitignored):
#   internal/embedded/python/bin/aid-py-bundle.tar.gz
#   internal/embedded/python/bin/aid-py-bundle.id
#
# Requires: curl, tar, gzip, sha256sum (or shasum), python3 with pip (build host only)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/internal/embedded/python/bin"
REQ_FILE="${ROOT}/scripts/requirements-bundle.txt"
STAGING="${ROOT}/.build/aid-py-bundle"

# Pinned python-build-standalone (https://github.com/astral-sh/python-build-standalone)
PBS_RELEASE="${PBS_RELEASE:-20250723}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.11}"
PBS_SHA256="${PBS_SHA256:-e5e828ba2c1a55400cdb07ff5f052908c46d5deb4f62d8b5825f8c24aeffcccb}"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  PBS_TRIPLE="${PBS_TRIPLE:-x86_64-unknown-linux-gnu}" ;;
  Linux-aarch64|Linux-arm64) PBS_TRIPLE="${PBS_TRIPLE:-aarch64-unknown-linux-gnu}" ;;
  Darwin-x86_64) PBS_TRIPLE="${PBS_TRIPLE:-x86_64-apple-darwin}" ;;
  Darwin-arm64)  PBS_TRIPLE="${PBS_TRIPLE:-aarch64-apple-darwin}" ;;
  *)
    echo "Unsupported platform for bundle build: $(uname -s) $(uname -m)" >&2
    echo "Set PBS_TRIPLE and PBS_SHA256 for your python-build-standalone asset." >&2
    exit 1
    ;;
esac

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

if [[ ! -f "${REQ_FILE}" ]]; then
  echo "Missing ${REQ_FILE} — migrate scripts/ from CLI source (PR #5789)" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}" "${STAGING}"

asset="cpython-${PYTHON_VERSION}+${PBS_RELEASE}-${PBS_TRIPLE}-install_only.tar.gz"
base="https://github.com/astral-sh/python-build-standalone/releases/download/${PBS_RELEASE}"
archive="${STAGING}/${asset}"

echo "Downloading relocatable CPython: ${asset}"
curl -fsSL --retry 5 --retry-all-errors -o "${archive}" "${base}/${asset}"
echo "${PBS_SHA256}  ${archive}" | sha256_file -c -

rm -rf "${STAGING}/python"
mkdir -p "${STAGING}/python"
tar -xzf "${archive}" -C "${STAGING}/python"

PYBIN="${STAGING}/python/bin/python3"
if [[ ! -x "${PYBIN}" ]]; then
  echo "Expected interpreter at ${PYBIN}" >&2
  exit 1
fi

echo "Installing Python deps from ${REQ_FILE}"
"${PYBIN}" -m pip install --no-warn-script-location \
  --timeout 60 --retries 10 \
  -r "${REQ_FILE}"

find "${STAGING}/python" -depth -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true

bundle_tar="${OUT_DIR}/aid-py-bundle.tar.gz"
bundle_id="${OUT_DIR}/aid-py-bundle.id"

tar -czf "${bundle_tar}" -C "${STAGING}" python
sha256_file "${bundle_tar}" | cut -c1-16 > "${bundle_id}"

echo "Wrote ${bundle_tar} ($(wc -c < "${bundle_tar}") bytes)"
echo "Wrote ${bundle_id} (id: $(cat "${bundle_id}"))"
