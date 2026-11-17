#!/bin/bash
# =================================================================================
# Usage:       ./provision-environment.test.sh
# Description: The environment is always written, while the branch policy is only
#              created when it is missing. The stub answers the policy lookup with
#              a canned API response and applies the `--jq` filter the script
#              passes, so a broken filter fails here instead of in production.
#              `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
POLICIES_FILE="$TEST_WORK_DIR/policies.json"
printf '%s' '{"branch_policies":[{"name":"develop","id":7}]}' > "$POLICIES_FILE"
export GH_TOKEN POLICIES_FILE

gh_handler() {
  local expression=""
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--jq" ]; then
      expression="$2"
      shift 2
    else
      shift
    fi
  done
  [ -n "$expression" ] || return 0
  jq -r "$expression" "$POLICIES_FILE"
}
export -f gh_handler

run_script "$SCRIPT_DIR/provision-environment.sh" Flashky repo
expect_status "sin política previa" 0
expect_output "sin política previa" "Setting branch policies to workshop..."
expect_output "sin política previa" "Setting restrictions to master branch..."
expect_call "sin política previa" "api --method PUT repos/Flashky/repo/environments/workshop -F deployment_branch_policy[custom_branch_policies]=true -F deployment_branch_policy[protected_branches]=false"
expect_call "sin política previa" "api --method POST repos/Flashky/repo/environments/workshop/deployment-branch-policies -f name=master -f type=branch"

: > "$GH_CALLS"
printf '%s' '{"branch_policies":[{"name":"develop","id":7},{"name":"master","id":42}]}' > "$POLICIES_FILE"
run_script "$SCRIPT_DIR/provision-environment.sh" Flashky repo
expect_status "con política previa" 0
expect_output "con política previa" "The master branch policy already exists (id 42); leaving it untouched."
expect_call "con política previa" "api --method PUT repos/Flashky/repo/environments/workshop -F deployment_branch_policy[custom_branch_policies]=true -F deployment_branch_policy[protected_branches]=false"
expect_no_call "con política previa" "--method POST"

finish
