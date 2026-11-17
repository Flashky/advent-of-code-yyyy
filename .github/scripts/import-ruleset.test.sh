#!/bin/bash
# =================================================================================
# Usage:       ./import-ruleset.test.sh
# Description: A ruleset with the same name is updated in place, a new one is
#              created, and a missing file stops the script. The stub answers only
#              the paginated lookup, so a wrong endpoint fails here; any other call
#              is unexpected. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
RULESET_EXISTS=""
export GH_TOKEN RULESET_EXISTS

RULESET_FILE="$TEST_WORK_DIR/ruleset.json"
printf '%s' '{"name":"Master branch protection","source_type":"Repository","target":"branch"}' > "$RULESET_FILE"

gh_handler() {
  case "$*" in
    "api --paginate --slurp repos/Flashky/repo/rulesets")
      printf '%s' "$RULESET_EXISTS"
      ;;
    api\ repos/Flashky/repo/rulesets\ --method\ POST\ --input\ *)
      ;;
    api\ repos/Flashky/repo/rulesets/*\ --method\ PUT\ --input\ -)
      ;;
    *)
      echo "gh: unexpected call: $*" >&2
      return 1
      ;;
  esac
}
export -f gh_handler

run_script "$SCRIPT_DIR/import-ruleset.sh" Flashky repo "$RULESET_FILE"
expect_status "ruleset nuevo" 0
expect_stdout "ruleset nuevo" "Importing branch protection ruleset into repo..."
expect_call "ruleset nuevo" "api --paginate --slurp repos/Flashky/repo/rulesets"
expect_call "ruleset nuevo" "api repos/Flashky/repo/rulesets --method POST --input $RULESET_FILE"

: > "$GH_CALLS"
RULESET_EXISTS='[[{"name":"Master branch protection","id":7}]]'
run_script "$SCRIPT_DIR/import-ruleset.sh" Flashky repo "$RULESET_FILE"
expect_status "ruleset existente" 0
expect_stdout "ruleset existente" "Ruleset 'Master branch protection' already exists (id 7); updating it..."
expect_call "ruleset existente" "api --paginate --slurp repos/Flashky/repo/rulesets"
expect_call "ruleset existente" "api repos/Flashky/repo/rulesets/7 --method PUT --input -"
expect_no_call "ruleset existente" "--method POST"
# source_type is read-only: the update endpoint rejects the body if it is still there.
expect_stdin "ruleset existente" '.source_type == null and .name == "Master branch protection"'

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/import-ruleset.sh" Flashky repo "$TEST_WORK_DIR/missing.json"
expect_status "fichero ausente" 1
expect_stdout "fichero ausente" "Ruleset file not found at $TEST_WORK_DIR/missing.json."
expect_no_call "fichero ausente" "api"

finish
