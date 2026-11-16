#!/bin/bash
# =================================================================================
# Usage:       ./ensure-repository.test.sh
# Description: Covers the four outcomes of the existence lookup: create, resume,
#              refuse and fail. `gh` is stubbed.
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

create_repository() {
  : > "$GH_CALLS"
  run_script "$SCRIPT_DIR/ensure-repository.sh" Flashky repo Flashky/template public
}

REPO_STATE=missing create_repository
expect_status "repo ausente: crea" 0
expect_output "repo ausente: crea" "Creating repository Flashky/repo from template Flashky/template..."
expect_call "repo ausente: crea" "repo create repo --template Flashky/template --public"
expect_no_call "repo ausente: crea" "actions/runs"

REPO_STATE=exists create_repository
expect_status "repo existente sin Setup: reanuda" 0
expect_output "repo existente sin Setup: reanuda" "already exists; resuming its provisioning."
expect_no_call "repo existente sin Setup: reanuda" "repo create"

RUNS_FILE="$TEST_WORK_DIR/runs.json"
printf '%s' '[{"workflow_runs":[{"path":".github/workflows/setup.yml","conclusion":"success"}]}]' > "$RUNS_FILE"
REPO_STATE=exists create_repository
expect_status "repo ya aprovisionado: se niega" 1
expect_output "repo ya aprovisionado: se niega" "already ran Setup successfully"
expect_no_call "repo ya aprovisionado: se niega" "repo create"

REPO_STATE=broken create_repository
expect_status "lookup roto: falla" 1
expect_output "lookup roto: falla" "Could not check Flashky/repo: gh: Internal Server Error (HTTP 500)"

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/ensure-repository.sh" Flashky repo Flashky/template internal
expect_status "visibilidad inválida: falla" 1
expect_output "visibilidad inválida: falla" "Visibility must be 'public' or 'private'"
expect_no_call "visibilidad inválida: falla" "api"

finish
