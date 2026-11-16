#!/bin/bash
# =================================================================================
# Usage:       ./ensure-environment.test.sh
# Description: The environment is always written, while the branch policy is only
#              created when it is missing. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
POLICY_ID=""
export GH_TOKEN POLICY_ID

gh_handler() {
  printf '%s' "$POLICY_ID"
  return 0
}
export -f gh_handler

run_script "$SCRIPT_DIR/ensure-environment.sh" Flashky repo
expect_status "sin política previa" 0
expect_output "sin política previa" "Setting branch policies to workshop..."
expect_output "sin política previa" "Setting restrictions to master branch..."
expect_call "sin política previa" "api --method PUT repos/Flashky/repo/environments/workshop -F deployment_branch_policy[custom_branch_policies]=true -F deployment_branch_policy[protected_branches]=false"
expect_call "sin política previa" "api --method POST repos/Flashky/repo/environments/workshop/deployment-branch-policies -f name=master -f type=branch"

: > "$GH_CALLS"
POLICY_ID=42
run_script "$SCRIPT_DIR/ensure-environment.sh" Flashky repo
expect_status "con política previa" 0
expect_output "con política previa" "The master branch policy already exists (id 42); leaving it untouched."
expect_call "con política previa" "api --method PUT repos/Flashky/repo/environments/workshop -F deployment_branch_policy[custom_branch_policies]=true -F deployment_branch_policy[protected_branches]=false"
expect_no_call "con política previa" "--method POST"

finish
