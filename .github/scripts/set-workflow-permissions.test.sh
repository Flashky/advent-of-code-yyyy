#!/bin/bash
# =================================================================================
# Usage:       ./set-workflow-permissions.test.sh
# Description: Workflows are allowed to write and to approve pull requests.
#              `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
export GH_TOKEN

run_script "$SCRIPT_DIR/set-workflow-permissions.sh" Flashky repo
expect_status "permisos de workflow" 0
expect_output "permisos de workflow" "Configuring workflow permissions for repo..."
expect_call "permisos de workflow" "api --method PUT repos/Flashky/repo/actions/permissions/workflow -F default_workflow_permissions=write -F can_approve_pull_request_reviews=true"

finish
