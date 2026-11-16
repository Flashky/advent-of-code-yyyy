#!/bin/bash
# =================================================================================
# Usage:       ./enable-auto-merge.test.sh
# Description: The repository is patched with allow_auto_merge. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
export GH_TOKEN

run_script "$SCRIPT_DIR/enable-auto-merge.sh" Flashky repo
expect_status "auto-merge" 0
expect_output "auto-merge" "Enabling auto-merge for repo..."
expect_call "auto-merge" "api repos/Flashky/repo -X PATCH -F allow_auto_merge=true"

finish
