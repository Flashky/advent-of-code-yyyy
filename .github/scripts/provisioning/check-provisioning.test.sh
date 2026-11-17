#!/bin/bash
# =================================================================================
# Usage:       ./check-provisioning.test.sh
# Description: The answer the caller captures is `true`/`false` on stdout and
#              nothing else; warnings and errors go to stderr. A Setup run that is
#              still going stops the caller, exactly like one that already
#              succeeded. `gh` is stubbed and rejects any call it does not expect.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"

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
    *)
      echo "gh: unexpected call: $*" >&2
      return 1
      ;;
  esac
}
export -f gh_handler

check() {
  : > "$GH_CALLS"
  run_script "$SCRIPT_DIR/check-provisioning.sh" Flashky repo
}

REPO_STATE=missing check
expect_status "repo ausente: exit" 0
expect_stdout_is "repo ausente: stdout exacto" "false"
expect_no_stderr "repo ausente: no avisa"
expect_no_call "repo ausente: no consulta Setup" "actions/runs"

REPO_STATE=exists check
expect_status "repo existente sin Setup: exit" 0
expect_stdout_is "repo existente sin Setup: stdout exacto" "true"
expect_stderr "repo existente sin Setup: avisa por stderr" "::warning title=Repository Already Exists::"

printf '%s' '[{"workflow_runs":[{"path":".github/workflows/setup.yml","status":"completed","conclusion":"success"}]}]' > "$RUNS_FILE"
REPO_STATE=exists check
expect_status "repo ya aprovisionado: exit" 1
expect_stdout "repo ya aprovisionado: se niega" "already ran Setup successfully"
expect_no_stdout "repo ya aprovisionado: no responde true" "true"

printf '%s' '[{"workflow_runs":[{"path":".github/workflows/setup.yml","status":"in_progress","conclusion":null}]}]' > "$RUNS_FILE"
REPO_STATE=exists check
expect_status "Setup en curso: exit" 1
expect_stdout "Setup en curso: se niega" "has a Setup run in progress"
expect_no_stdout "Setup en curso: no responde true" "true"

printf '%s' '[{"workflow_runs":[{"path":".github/workflows/setup.yml","status":"completed","conclusion":"failure"}]}]' > "$RUNS_FILE"
REPO_STATE=exists check
expect_status "Setup fallido: exit" 0
expect_stdout_is "Setup fallido: reanuda" "true"
expect_stderr "Setup fallido: avisa" "resuming its provisioning"

REPO_STATE=broken check
expect_status "lookup roto: exit" 1
expect_stdout "lookup roto: falla" "Could not check Flashky/repo: gh: Internal Server Error (HTTP 500)"

: > "$GH_CALLS"
unset GH_TOKEN
run_script "$SCRIPT_DIR/check-provisioning.sh" Flashky repo
expect_status "sin token: exit" 1
expect_stderr "sin token: lo dice" "GH_TOKEN is not set"
expect_no_call "sin token: no llama" "api"

finish
