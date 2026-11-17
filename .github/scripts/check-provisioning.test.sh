#!/bin/bash
# =================================================================================
# Usage:       ./check-provisioning.test.sh
# Description: The answer the caller captures is `true`/`false` on stdout and
#              nothing else; warnings and errors go to stderr. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
REPO_STATE=exists
RUNS_FILE="$TEST_WORK_DIR/runs.json"
printf '%s' '[{"workflow_runs":[]}]' > "$RUNS_FILE"
export GH_TOKEN REPO_STATE RUNS_FILE

gh_handler() {
  case "$*" in
    "api repos/Flashky/repo --silent")
      case "$REPO_STATE" in
        missing)
          echo "gh: Not Found (HTTP 404)" >&2
          return 1
          ;;
        broken)
          echo "gh: Internal Server Error (HTTP 500)" >&2
          return 1
          ;;
        *) return 0 ;;
      esac
      ;;
    "api --paginate --slurp repos/Flashky/repo/actions/runs?per_page=100")
      cat "$RUNS_FILE"
      return 0
      ;;
    *) return 0 ;;
  esac
}
export -f gh_handler

check() {
  : > "$GH_CALLS"
  run_script "$SCRIPT_DIR/check-provisioning.sh" Flashky repo
}

REPO_STATE=missing check
expect_status "repo ausente: exit" 0
expect_output "repo ausente: imprime false" "false"
expect_no_output "repo ausente: no imprime true" "true"
expect_no_call "repo ausente: no consulta Setup" "actions/runs"

REPO_STATE=exists check
expect_status "repo existente sin Setup: exit" 0
expect_output "repo existente sin Setup: imprime true" "true"
expect_output "repo existente sin Setup: avisa que reanuda" "::warning title=Repository Already Exists::"
expect_no_call "repo existente sin Setup: no crea" "repo create"

printf '%s' '[{"workflow_runs":[{"path":".github/workflows/setup.yml","conclusion":"success"}]}]' > "$RUNS_FILE"
REPO_STATE=exists check
expect_status "repo ya aprovisionado: exit" 1
expect_output "repo ya aprovisionado: se niega" "already ran Setup successfully"
expect_no_output "repo ya aprovisionado: no responde true/false" "true"

REPO_STATE=broken check
expect_status "lookup roto: exit" 1
expect_output "lookup roto: falla" "Could not check Flashky/repo: gh: Internal Server Error (HTTP 500)"

: > "$GH_CALLS"
unset GH_TOKEN
run_script "$SCRIPT_DIR/check-provisioning.sh" Flashky repo
expect_status "sin token: exit" 1
expect_output "sin token: lo dice" "GH_TOKEN is not set"
expect_no_call "sin token: no llama" "api"

finish
