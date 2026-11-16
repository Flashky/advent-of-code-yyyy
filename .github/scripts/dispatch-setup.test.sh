#!/bin/bash
# =================================================================================
# Usage:       ./dispatch-setup.test.sh
# Description: The Setup workflow is dispatched in the target repository, not in
#              the one running the script. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
export GH_TOKEN

run_script "$SCRIPT_DIR/dispatch-setup.sh" Flashky repo
expect_status "dispara Setup" 0
expect_output "dispara Setup" "Triggering 'Setup' workflow in Flashky/repo..."
expect_call "dispara Setup" "workflow run Setup --repo Flashky/repo"

finish
