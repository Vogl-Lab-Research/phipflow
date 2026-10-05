#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Check that a finished smoke-test run produced every file listed in
# tests/expected_outputs.txt, and that none of them is empty.
#
# Usage:
#   tests/check_outputs.sh <project_dir>
# ------------------------------------------------------------------------------
set -euo pipefail

project_dir="${1:?usage: check_outputs.sh <project_dir>}"
expected="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/expected_outputs.txt"

missing=0

while IFS= read -r rel || [[ -n "${rel}" ]]; do
  [[ -z "${rel}" || "${rel}" == \#* ]] && continue

  if [[ -s "${project_dir}/${rel}" ]]; then
    echo "ok       ${rel}"
  else
    echo "MISSING  ${rel}"
    missing=$((missing + 1))
  fi
done < "${expected}"

if [[ "${missing}" -gt 0 ]]; then
  echo "${missing} expected output(s) missing or empty." >&2
  exit 1
fi

echo "All expected outputs present."
