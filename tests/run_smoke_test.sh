#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# End-to-end smoke test: run phipflow on the synthetic CI-Test project.
#
# Usage (from anywhere, needs nextflow + docker):
#   tests/run_smoke_test.sh [extra nextflow args...]
#
# Examples:
#   tests/run_smoke_test.sh
#   tests/run_smoke_test.sh --container phipflow-latest:local
#
# The fixture is copied to a temporary base_dir so the repository stays clean.
# Set SMOKE_DIR to choose that directory (default: a new mktemp dir).
# ------------------------------------------------------------------------------
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
smoke_dir="${SMOKE_DIR:-$(mktemp -d)}"
smoke_dir="$(mkdir -p "${smoke_dir}" && cd "${smoke_dir}" && pwd)"

echo "phipflow repo : ${repo_dir}"
echo "smoke dir     : ${smoke_dir}"

cp -r "${repo_dir}/tests/fixture/CI-Test" "${smoke_dir}/"

cd "${smoke_dir}"

nextflow run "${repo_dir}/main.nf" \
  -profile docker,ci \
  --base_dir "${smoke_dir}" \
  -ansi-log false \
  "$@"

"${repo_dir}/tests/check_outputs.sh" "${smoke_dir}/CI-Test"
