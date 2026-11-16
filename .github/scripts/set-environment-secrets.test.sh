#!/bin/bash
# =================================================================================
# Usage:       ./set-environment-secrets.test.sh
# Description: The two App credentials land on the workshop environment, and a
#              missing value stops the script before it touches the API.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
AOC_APP_CLIENT_ID=client
AOC_APP_PRIVATE_KEY=key
export GH_TOKEN AOC_APP_CLIENT_ID AOC_APP_PRIVATE_KEY

run_script "$SCRIPT_DIR/set-environment-secrets.sh" Flashky repo
expect_status "ambos credenciales" 0
expect_output "ambos credenciales" "Setting secrets for Workshop..."
expect_call "ambos credenciales" "secret set AOC_APP_CLIENT_ID --env workshop --repo Flashky/repo --body client"
expect_call "ambos credenciales" "secret set AOC_APP_PRIVATE_KEY --env workshop --repo Flashky/repo --body key"

: > "$GH_CALLS"
unset AOC_APP_PRIVATE_KEY
run_script "$SCRIPT_DIR/set-environment-secrets.sh" Flashky repo
expect_status "sin clave privada" 1
expect_output "sin clave privada" "AOC_APP_PRIVATE_KEY is not set"
expect_no_call "sin clave privada" "secret set"

finish
